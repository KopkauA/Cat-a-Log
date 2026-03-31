# makes it easy to validate incoming data and to return JSON for the frontend. 
# use_url=True makes the image field return a URL (if request context exists)

from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import CatReport, OfferHelp

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "username", "email")

class CatReportSerializer(serializers.ModelSerializer):
    reporter = UserSerializer(read_only=True)
    offers_count = serializers.IntegerField(source='offers.count', read_only=True)
    image = serializers.ImageField(use_url=True, required=True)

    class Meta:
        model = CatReport
        fields = "__all__"
        read_only_fields = ("reporter", "created_at", "offers_count")

class OfferHelpSerializer(serializers.ModelSerializer):
    helper = UserSerializer(read_only=True)
    class Meta:
        model = OfferHelp
        fields = "__all__"
        read_only_fields = ("helper", "created_at")
