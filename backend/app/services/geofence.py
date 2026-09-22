import math
from typing import Tuple

def calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points on earth in meters.
    """
    R = 6371000.0  # Earth's radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2.0) ** 2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

    distance = R * c
    return round(distance, 1)

def verify_geofence(
    user_lat: float,
    user_lon: float,
    target_lat: float,
    target_lon: float,
    max_radius_meters: float = 100.0
) -> Tuple[bool, float]:
    """
    Check if user coordinates fall within the maximum allowed radius of the placement location.
    Returns (is_in_radius, distance_in_meters).
    """
    distance = calculate_haversine_distance(user_lat, user_lon, target_lat, target_lon)
    is_in_radius = distance <= max_radius_meters
    return is_in_radius, distance
