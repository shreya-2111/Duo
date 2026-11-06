from rest_framework import permissions

class IsOwner(permissions.BasePermission):
    """
    Object-level permission to only allow owners of an object to access or edit it.
    """
    def has_object_permission(self, request, view, obj):
        if hasattr(obj, 'owner'):
            return obj.owner == request.user
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'creator'):
            return obj.creator == request.user
        return False

