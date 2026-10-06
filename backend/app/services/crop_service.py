"""
HarvestLink Backend - Crop Information Service.

Provides crop data from the database for the AI assistant.
"""

from typing import Optional
from app.core.database import get_supabase_client
from app.core.logging import get_logger

logger = get_logger(__name__)

# Seed crop data for initial deployment
# This data is stored in the database and retrieved from there
SEED_CROPS = [
    {
        "name_en": "Rice (Paddy)",
        "name_ta": "நெல்",
        "category": "Cereal",
        "season": "Kharif (June-July), Rabi (November-December)",
        "soil_type": "Clay, loamy, alluvial",
        "water_requirement": "High — requires standing water",
        "growing_period_days": 120,
        "description_en": "Rice is the staple food crop of Tamil Nadu. It thrives in warm, humid climates with abundant water supply. Major rice-growing districts include Thanjavur, Tiruvarur, and Nagapattinam.",
        "description_ta": "நெல் தமிழ்நாட்டின் முக்கிய உணவுப் பயிர். சூடான, ஈரப்பதமான காலநிலையில் அதிக நீர் வழங்கலுடன் நன்கு வளரும். தஞ்சாவூர், திருவாரூர், நாகப்பட்டினம் ஆகியவை முக்கிய நெல் பயிரிடும் மாவட்டங்கள்.",
    },
    {
        "name_en": "Tomato",
        "name_ta": "தக்காளி",
        "category": "Vegetable",
        "season": "Year-round (best: June-September, December-March)",
        "soil_type": "Well-drained loamy, sandy loam",
        "water_requirement": "Moderate — regular irrigation",
        "growing_period_days": 90,
        "description_en": "Tomato is a major vegetable crop grown across Tamil Nadu. It requires well-drained soil, adequate sunlight, and regular watering. Common diseases include early blight, late blight, and leaf curl virus.",
        "description_ta": "தக்காளி தமிழ்நாடு முழுவதும் வளரும் முக்கிய காய்கறிப் பயிர். நல்ல வடிகால் மண், போதுமான சூரிய ஒளி, தொடர்ச்சியான நீர்ப்பாசனம் தேவை. ஆரம்ப கருகல், தாமத கருகல், இலை சுருள் வைரஸ் ஆகியவை பொதுவான நோய்கள்.",
    },
    {
        "name_en": "Banana",
        "name_ta": "வாழை",
        "category": "Fruit",
        "season": "Year-round planting",
        "soil_type": "Rich loamy, well-drained",
        "water_requirement": "High — requires frequent irrigation",
        "growing_period_days": 300,
        "description_en": "Banana is one of the most important fruit crops in Tamil Nadu. Major varieties include Poovan, Rasthali, Nendran, and Robusta. Trichy, Theni, and Erode are major production districts.",
        "description_ta": "வாழை தமிழ்நாட்டின் மிக முக்கியமான பழப் பயிர்களில் ஒன்று. பூவன், ரஸ்தாலி, நேந்திரன், ரோபஸ்டா போன்றவை முக்கிய ரகங்கள். திருச்சி, தேனி, ஈரோடு ஆகியவை முக்கிய உற்பத்தி மாவட்டங்கள்.",
    },
    {
        "name_en": "Sugarcane",
        "name_ta": "கரும்பு",
        "category": "Cash Crop",
        "season": "January-March (main), October-November (late)",
        "soil_type": "Deep, rich loamy",
        "water_requirement": "Very High",
        "growing_period_days": 365,
        "description_en": "Sugarcane is a major cash crop in Tamil Nadu, grown primarily in the Cauvery delta region. It requires abundant water and is closely linked to dam/canal water availability.",
        "description_ta": "கரும்பு தமிழ்நாட்டின் முக்கிய பணப்பயிர், முதன்மையாக காவிரி டெல்டா பகுதியில் பயிரிடப்படுகிறது. அதிக நீர் தேவைப்படுகிறது மற்றும் அணை/கால்வாய் நீர் கிடைப்பதுடன் நெருங்கிய தொடர்புடையது.",
    },
    {
        "name_en": "Groundnut",
        "name_ta": "நிலக்கடலை",
        "category": "Oilseed",
        "season": "Kharif (June-July), Rabi (December-January)",
        "soil_type": "Sandy loam, well-drained",
        "water_requirement": "Low to moderate",
        "growing_period_days": 110,
        "description_en": "Groundnut is an important oilseed crop in Tamil Nadu. It grows well in light, well-drained soils. It is drought-tolerant and suitable for areas with limited water availability.",
        "description_ta": "நிலக்கடலை தமிழ்நாட்டின் முக்கிய எண்ணெய் வித்துப் பயிர். லேசான, நல்ல வடிகால் மண்ணில் நன்கு வளரும். வறட்சியைத் தாங்கும் மற்றும் குறைந்த நீர் கிடைக்கும் பகுதிகளுக்கு ஏற்றது.",
    },
    {
        "name_en": "Cotton",
        "name_ta": "பருத்தி",
        "category": "Cash Crop",
        "season": "June-August",
        "soil_type": "Black cotton soil, heavy loam",
        "water_requirement": "Moderate",
        "growing_period_days": 180,
        "description_en": "Cotton is a significant commercial crop in Tamil Nadu. Major growing districts include Virudhunagar, Ramanathapuram, and Madurai. It requires warm temperatures and moderate rainfall.",
        "description_ta": "பருத்தி தமிழ்நாட்டின் முக்கிய வணிகப் பயிர். விருதுநகர், ராமநாதபுரம், மதுரை ஆகியவை முக்கிய பயிரிடும் மாவட்டங்கள். சூடான வெப்பநிலை மற்றும் மிதமான மழை தேவை.",
    },
]


class CropService:
    """Provides crop information from the database."""

    def __init__(self):
        self.db = get_supabase_client()

    async def get_all_crops(self) -> list[dict]:
        """Get all crop information from the database."""
        try:
            result = self.db.table("crop_information").select("*").execute()
            if result.data:
                return result.data
        except Exception as e:
            logger.warning("crop_db_fetch_failed", error=str(e))

        # Fallback to seed data if DB is empty or unavailable
        return SEED_CROPS

    async def get_crop_by_name(self, name: str) -> Optional[dict]:
        """Find crop information by name (English or Tamil)."""
        try:
            # Search English name
            result = (
                self.db.table("crop_information")
                .select("*")
                .ilike("name_en", f"%{name}%")
                .execute()
            )
            if result.data:
                return result.data[0]

            # Search Tamil name
            result = (
                self.db.table("crop_information")
                .select("*")
                .ilike("name_ta", f"%{name}%")
                .execute()
            )
            if result.data:
                return result.data[0]

        except Exception as e:
            logger.warning("crop_search_failed", name=name, error=str(e))

        # Fallback to seed data
        name_lower = name.lower()
        for crop in SEED_CROPS:
            if name_lower in crop["name_en"].lower() or name in crop["name_ta"]:
                return crop

        return None

    async def seed_database(self) -> None:
        """Seed the crop_information table with initial data if empty."""
        try:
            result = self.db.table("crop_information").select("id").limit(1).execute()
            if not result.data:
                for crop in SEED_CROPS:
                    self.db.table("crop_information").insert(crop).execute()
                logger.info("crop_data_seeded", count=len(SEED_CROPS))
        except Exception as e:
            logger.warning("crop_seeding_failed", error=str(e))
