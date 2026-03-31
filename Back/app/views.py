from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import permissions
from .models import CatReport, OfferHelp
from .serializers import CatReportSerializer, OfferHelpSerializer
from .permissions import IsOwnerOrReadOnly

class CatReportViewSet(viewsets.ModelViewSet):
    queryset = CatReport.objects.all().order_by('-created_at')
    serializer_class = CatReportSerializer
    permission_classes = [IsOwnerOrReadOnly]
    parser_classes = (MultiPartParser, FormParser)
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['location_text', 'color', 'description']
    ordering_fields = ['created_at']

    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def stats(self, request):
        total = CatReport.objects.count()
        neutered = CatReport.objects.filter(neuter_status='neutered').count()
        unresolved = CatReport.objects.filter(is_rescued=False).count()
        return Response({'total': total, 'neutered': neutered, 'unresolved': unresolved})

class OfferHelpViewSet(viewsets.ModelViewSet):
    queryset = OfferHelp.objects.all().order_by('-created_at')
    serializer_class = OfferHelpSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        serializer.save(helper=self.request.user)
