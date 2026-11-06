from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class DeprecatedConnectionView(APIView):
    def get(self, request, *args, **kwargs):
        return Response({'message': 'Connection and shared spaces have been deprecated.'}, status=status.HTTP_410_GONE)

    def post(self, request, *args, **kwargs):
        return Response({'message': 'Connection and shared spaces have been deprecated.'}, status=status.HTTP_410_GONE)
