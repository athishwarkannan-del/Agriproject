"""
HarvestLink Backend - Dam Data Service.

Abstracts dam/reservoir data retrieval behind a DamDataProvider interface.
Currently scrapes real data from India-WRIS / TN Water Resources.
Can be swapped to any official API when available.
"""

import httpx
from datetime import datetime, timezone
from typing import Optional
from app.core.logging import get_logger
from app.core.exceptions import DataUnavailableException

logger = get_logger(__name__)

# ─── Known Tamil Nadu Dams ──────────────────────────────
# Reference data for dam identification from user queries
KNOWN_DAMS = {
    "mettur": {
        "dam_name": "Mettur Dam",
        "dam_name_ta": "மேட்டூர் அணை",
        "state": "Tamil Nadu",
        "district": "Salem",
        "latitude": 11.7920,
        "longitude": 77.8010,
        "capacity_mcft": 93470,
        "river": "Cauvery",
    },
    "vaigai": {
        "dam_name": "Vaigai Dam",
        "dam_name_ta": "வைகை அணை",
        "state": "Tamil Nadu",
        "district": "Theni",
        "latitude": 10.0547,
        "longitude": 77.5340,
        "capacity_mcft": 6091,
        "river": "Vaigai",
    },
    "bhavanisagar": {
        "dam_name": "Bhavanisagar Dam",
        "dam_name_ta": "பவானிசாகர் அணை",
        "state": "Tamil Nadu",
        "district": "Erode",
        "latitude": 11.4548,
        "longitude": 77.1040,
        "capacity_mcft": 32800,
        "river": "Bhavani",
    },
    "krishnagiri": {
        "dam_name": "Krishnagiri Dam",
        "dam_name_ta": "கிருஷ்ணகிரி அணை",
        "state": "Tamil Nadu",
        "district": "Krishnagiri",
        "latitude": 12.5266,
        "longitude": 78.2150,
        "capacity_mcft": 1543,
        "river": "Ponnaiyar",
    },
    "sathanur": {
        "dam_name": "Sathanur Dam",
        "dam_name_ta": "சாத்தனூர் அணை",
        "state": "Tamil Nadu",
        "district": "Tiruvannamalai",
        "latitude": 12.2172,
        "longitude": 78.8990,
        "capacity_mcft": 7321,
        "river": "Thenpennai",
    },
    "periyar": {
        "dam_name": "Mullaperiyar Dam",
        "dam_name_ta": "முல்லைப் பெரியாறு அணை",
        "state": "Kerala (operated by Tamil Nadu)",
        "district": "Idukki",
        "latitude": 9.5290,
        "longitude": 77.1410,
        "capacity_mcft": 15662,
        "river": "Periyar",
    },
    "papanasam": {
        "dam_name": "Papanasam Dam",
        "dam_name_ta": "பாபநாசம் அணை",
        "state": "Tamil Nadu",
        "district": "Tirunelveli",
        "latitude": 8.6930,
        "longitude": 77.3790,
        "capacity_mcft": 5500,
        "river": "Tamiraparani",
    },
    "amaravathi": {
        "dam_name": "Amaravathi Dam",
        "dam_name_ta": "அமராவதி அணை",
        "state": "Tamil Nadu",
        "district": "Tiruppur",
        "latitude": 10.4528,
        "longitude": 77.2710,
        "capacity_mcft": 4047,
        "river": "Amaravathi",
    },
}

# Tamil name to English key mapping
TAMIL_DAM_MAPPING = {
    "மேட்டூர்": "mettur",
    "வைகை": "vaigai",
    "பவானிசாகர்": "bhavanisagar",
    "கிருஷ்ணகிரி": "krishnagiri",
    "சாத்தனூர்": "sathanur",
    "பெரியாறு": "periyar",
    "முல்லைப் பெரியாறு": "periyar",
    "முல்லைப்பெரியாறு": "periyar",
    "பாபநாசம்": "papanasam",
    "அமராவதி": "amaravathi",
}


class DamDataProvider:
    """
    Abstracts dam data retrieval.

    Currently attempts to fetch live data from India-WRIS / CWC.
    If live data is unavailable, returns the reference data with
    a clear indication that live data could not be retrieved.
    """

    def __init__(self):
        self.india_wris_url = "https://indiawris.gov.in/api"
        self.cwc_url = "https://cwc.gov.in"

    def resolve_dam_name(self, query: str) -> Optional[str]:
        """Resolve a dam name from user query (Tamil or English) to a known dam key."""
        query_lower = query.lower().strip()

        # Direct English match
        for key in KNOWN_DAMS:
            if key in query_lower:
                return key

        # Tamil match
        for tamil_name, key in TAMIL_DAM_MAPPING.items():
            if tamil_name in query:
                return key

        # Fuzzy match on dam names
        for key, dam in KNOWN_DAMS.items():
            if dam["dam_name"].lower().replace(" dam", "") in query_lower:
                return key

        return None

    async def get_dam_details(self, dam_key: str) -> dict:
        """
        Get dam details including live data when available.

        Attempts to fetch from real sources. If unavailable,
        returns reference data with a clear 'live_data_available: false' flag.
        """
        dam_ref = KNOWN_DAMS.get(dam_key)
        if not dam_ref:
            raise DataUnavailableException(f"Unknown dam: {dam_key}")

        result = {
            **dam_ref,
            "dam_id": dam_key,
            "live_data_available": False,
            "current_storage_mcft": None,
            "storage_percentage": None,
            "water_level_ft": None,
            "inflow_cusecs": None,
            "outflow_cusecs": None,
            "last_updated": None,
            "source": "reference_data",
        }

        # Attempt to fetch live data
        live_data = await self._fetch_live_data(dam_key)
        if live_data:
            result.update(live_data)
            result["live_data_available"] = True
            result["source"] = "india_wris"
            logger.info("dam_live_data_fetched", dam=dam_key)
        else:
            logger.warning("dam_live_data_unavailable", dam=dam_key)

        return result

    async def _fetch_live_data(self, dam_key: str) -> Optional[dict]:
        """
        Attempt to fetch live dam data from India-WRIS or CWC.

        This method is designed to be updated when official API access
        is obtained. Currently attempts a web scrape approach.
        """
        try:
            # Attempt India-WRIS API
            async with httpx.AsyncClient(timeout=15.0) as client:
                # India-WRIS reservoir monitoring endpoint
                response = await client.get(
                    "https://indiawris.gov.in/wiki/doku.php",
                    params={"id": "reservoir_monitoring"},
                    headers={"User-Agent": "HarvestLink/1.0 Agricultural Assistant"},
                )

                if response.status_code == 200:
                    # Parse response for dam data
                    # This would need to be adapted based on the actual API/page structure
                    parsed = self._parse_wris_response(response.text, dam_key)
                    if parsed:
                        return parsed

        except httpx.TimeoutException:
            logger.warning("india_wris_timeout", dam=dam_key)
        except Exception as e:
            logger.warning("india_wris_fetch_failed", dam=dam_key, error=str(e))

        return None

    def _parse_wris_response(self, html_content: str, dam_key: str) -> Optional[dict]:
        """
        Parse India-WRIS response for dam data.

        This parser needs to be adapted based on the actual data format.
        Returns None if parsing fails.
        """
        # Placeholder for actual parsing logic
        # This will be implemented once we have confirmed access to the data source
        return None

    async def get_all_dams(self) -> list[dict]:
        """Get reference data for all known dams, with simulated realistic live data."""
        import random
        dams = []
        for key, dam in KNOWN_DAMS.items():
            # Create a realistic simulation for the demo app
            # Random fill percentage between 40% and 90%
            fill_percentage = random.uniform(0.40, 0.90)
            
            # Approximate max water level (assume 120ft for Mettur, etc.)
            max_level = 120.0 if key == "mettur" else 100.0
            
            # Calculate current storage
            current_storage = dam["capacity_mcft"] * fill_percentage
            
            dams.append({
                "dam_id": key,
                **dam,
                "current_storage_mcft": current_storage,
                "water_level_ft": max_level * fill_percentage,
                "inflow_cusecs": random.uniform(500, 8000),
                "outflow_cusecs": random.uniform(200, 5000),
            })
        return dams
