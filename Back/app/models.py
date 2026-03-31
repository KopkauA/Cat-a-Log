# defines the DB tables (reports and offers). 
# ImageField stores path and saves file in MEDIA_ROOT/cat_photos/.

from django.db import models
from django.conf import settings

class CatReport(models.Model):
    NEUTER_CHOICES = [
        ('unknown', 'Unknown'),
        ('neutered', 'Neutered'),
        ('not_neutered', 'Not Neutered'),
    ]

    reporter = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    title = models.CharField(max_length=150, blank=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=100, blank=True)
    neuter_status = models.CharField(max_length=20, choices=NEUTER_CHOICES, default='unknown')
    contact_info = models.CharField(max_length=200, blank=True)
    location_text = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    image = models.ImageField(upload_to="cat_photos/")
    is_rescued = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title or 'CatReport'} ({self.id})"

class OfferHelp(models.Model):
    report = models.ForeignKey(CatReport, on_delete=models.CASCADE, related_name="offers")
    helper = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    message = models.TextField()
    contact_info = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
