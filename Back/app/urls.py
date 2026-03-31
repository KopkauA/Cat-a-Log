from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

# A simple test view function
def home(request):
    return HttpResponse("Hello! Django is working 🚀")

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home),  # route the root URL "/" to our home function
]



'''from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CatReportViewSet, OfferHelpViewSet

router = DefaultRouter()
router.register(r'reports', CatReportViewSet, basename='reports')
router.register(r'offers', OfferHelpViewSet, basename='offers')

urlpatterns = [
    path('', include(router.urls)),
]'''
