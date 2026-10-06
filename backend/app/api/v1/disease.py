"""
HarvestLink Backend - Disease Detection API.

Endpoints for crop image upload and disease analysis.
"""

import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from app.core.security import get_optional_user
from app.core.database import get_supabase_client
from app.core.logging import get_logger
from app.services.disease_service import DiseaseDetectionService
from app.core.exceptions import ImageValidationException, DiseaseDetectionException
from app.models.schemas import DiseaseAnalysisResponse
from app.models.enums import AnalysisStatus, Language

logger = get_logger(__name__)

router = APIRouter(prefix="/disease", tags=["Disease Detection"])


@router.post("/analyze", response_model=DiseaseAnalysisResponse)
async def analyze_crop_image(
    file: UploadFile = File(..., description="Crop leaf image (JPEG, PNG, WebP, max 10MB)"),
    language: str = "ta",
    user: dict = Depends(get_optional_user),
):
    """
    Upload a crop image for disease detection.

    The image is:
    1. Validated (type, size)
    2. Uploaded to Supabase Storage
    3. Analyzed by the ML model
    4. Results stored in database
    5. Explanation generated in Tamil or English
    """
    db = get_supabase_client()
    analysis_id = str(uuid.uuid4())
    user_id = user["user_id"] if user else "test_farmer_dev_mode"

    try:
        # Read image bytes
        image_bytes = await file.read()
        content_type = file.content_type or "image/jpeg"

        # Initialize disease service
        disease_service = DiseaseDetectionService()

        # Validate image
        try:
            disease_service.validate_image(image_bytes, content_type)
        except ImageValidationException as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=e.user_message,
            )

        # Upload to Supabase Storage
        file_ext = content_type.split("/")[-1] if content_type else "jpg"
        storage_path = f"{user_id}/{analysis_id}.{file_ext}"

        try:
            db.storage.from_("crop-images").upload(
                storage_path,
                image_bytes,
                file_options={"content-type": content_type},
            )
            image_url = db.storage.from_("crop-images").get_public_url(storage_path)
        except Exception as e:
            logger.error("image_upload_failed", error=str(e))
            image_url = None

        # Save analysis record
        try:
            db.table("disease_analyses").insert({
                "id": analysis_id,
                "user_id": user_id,
                "image_url": image_url or storage_path,
                "image_size_bytes": len(image_bytes),
                "status": AnalysisStatus.PROCESSING.value,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }).execute()
        except Exception as e:
            logger.error("analysis_record_failed", error=str(e))

        # Run ML analysis
        try:
            prediction = await disease_service.analyze(image_bytes, content_type)
        except DiseaseDetectionException as e:
            # Update status to failed
            try:
                db.table("disease_analyses").update(
                    {"status": AnalysisStatus.FAILED.value}
                ).eq("id", analysis_id).execute()
            except Exception:
                pass
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=e.user_message,
            )

        # Get language-specific results
        lang = language if language in ("ta", "en") else "ta"
        crop = prediction.get(f"crop_{lang}") or prediction.get("crop_en")
        disease = prediction.get(f"disease_{lang}") or prediction.get("disease_en")
        symptoms = prediction.get(f"symptoms_{lang}") or prediction.get("symptoms_en")
        recommendations = prediction.get(f"recommendations_{lang}") or prediction.get("recommendations_en")

        # Warning message
        if lang == "ta":
            warning = "இது AI அடிப்படையிலான படப் பகுப்பாய்வு மட்டுமே. வேளாண் நிபுணரின் ஆலோசனையை மாற்றாது."
        else:
            warning = "This is an AI-based image assessment only. It should not replace advice from an agricultural expert."

        # Save prediction
        try:
            db.table("disease_predictions").insert({
                "id": str(uuid.uuid4()),
                "analysis_id": analysis_id,
                "crop": prediction.get("crop_en"),
                "disease": prediction.get("disease_en"),
                "confidence": prediction["confidence"],
                "status": prediction["prediction_status"],
                "symptoms_en": prediction.get("symptoms_en"),
                "symptoms_ta": prediction.get("symptoms_ta"),
                "recommendations_en": prediction.get("recommendations_en"),
                "recommendations_ta": prediction.get("recommendations_ta"),
                "model_version": prediction.get("model_version"),
                "created_at": datetime.now(timezone.utc).isoformat(),
            }).execute()

            # Update analysis status
            db.table("disease_analyses").update(
                {"status": AnalysisStatus.COMPLETED.value}
            ).eq("id", analysis_id).execute()
        except Exception as e:
            logger.error("prediction_save_failed", error=str(e))

        logger.info("disease_analysis_completed", analysis_id=analysis_id, disease=disease)

        return DiseaseAnalysisResponse(
            analysis_id=analysis_id,
            status=AnalysisStatus.COMPLETED,
            crop=crop,
            disease=disease,
            confidence=prediction["confidence"],
            prediction_status=prediction["prediction_status"],
            symptoms=symptoms,
            recommendations=recommendations,
            warning=warning,
            language=Language(lang),
            image_url=image_url,
            model_version=prediction.get("model_version"),
            created_at=datetime.now(timezone.utc).isoformat(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error("disease_endpoint_failed", analysis_id=analysis_id, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Disease analysis failed. Please try again.",
        )


@router.get("/{analysis_id}", response_model=DiseaseAnalysisResponse)
async def get_analysis(
    analysis_id: str,
    language: str = "ta",
    user: dict = Depends(get_optional_user),
):
    """Get the result of a previous disease analysis."""
    db = get_supabase_client()

    try:
        # Get analysis record
        analysis_result = (
            db.table("disease_analyses")
            .select("*")
            .eq("id", analysis_id)
            .eq("user_id", user["user_id"] if user else "test_farmer_dev_mode")
            .execute()
        )

        if not analysis_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Analysis not found.",
            )

        analysis = analysis_result.data[0]

        # Get prediction
        prediction_result = (
            db.table("disease_predictions")
            .select("*")
            .eq("analysis_id", analysis_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )

        lang = language if language in ("ta", "en") else "ta"

        if prediction_result.data:
            pred = prediction_result.data[0]

            if lang == "ta":
                warning = "இது AI அடிப்படையிலான படப் பகுப்பாய்வு மட்டுமே."
            else:
                warning = "This is an AI-based image assessment only."

            return DiseaseAnalysisResponse(
                analysis_id=analysis_id,
                status=analysis["status"],
                crop=pred.get("crop"),
                disease=pred.get("disease"),
                confidence=pred.get("confidence"),
                prediction_status=pred.get("status"),
                symptoms=pred.get(f"symptoms_{lang}") or pred.get("symptoms_en"),
                recommendations=pred.get(f"recommendations_{lang}") or pred.get("recommendations_en"),
                warning=warning,
                language=Language(lang),
                image_url=analysis.get("image_url"),
                model_version=pred.get("model_version"),
                created_at=analysis.get("created_at"),
            )
        else:
            return DiseaseAnalysisResponse(
                analysis_id=analysis_id,
                status=analysis["status"],
                language=Language(lang),
                image_url=analysis.get("image_url"),
                created_at=analysis.get("created_at"),
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error("analysis_fetch_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve analysis results.",
        )
