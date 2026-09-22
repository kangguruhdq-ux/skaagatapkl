import re
from typing import Dict, Any, List

KEYWORD_SKILL_MAP = [
    (r"vlan|802\.1q|trunking", "VLAN 802.1Q", 98),
    (r"switch|l2|broadcast domain", "L2 Switching", 95),
    (r"stp|spanning-tree|loop", "STP Protocol", 92),
    (r"troubleshoot|debug|analisis kendala|error", "Troubleshooting", 96),
    (r"routing|ospf|bgp|static route", "IP Routing & OSPF", 94),
    (r"python|script|automation", "Python Automation", 89),
    (r"docker|container|podman", "Containerization", 88),
    (r"kabel|crimping|fluke|tester|fiber|splicing", "Physical Layer & Cabling", 93),
    (r"mikrotik|routeros|winbox", "MikroTik Routing", 91),
    (r"linux|ubuntu|debian|server|bash", "Linux System Administration", 90),
    (r"keamanan|firewall|acl|security", "Network Security & ACL", 92),
    (r"wifi|access point|wlan|hotspot", "Wireless Infrastructure", 89),
]

TOOL_KEYWORD_MAP = [
    (r"cisco|catalyst", "Cisco Catalyst 3850"),
    (r"putty|console|terminal", "PuTTY Console"),
    (r"fluke|cable tester|tester", "Fluke Cable Tester"),
    (r"wireshark|packet capture", "Wireshark Protocol Analyzer"),
    (r"winbox", "Winbox GUI"),
    (r"splicer|fusion splicer", "Fujikura Fusion Splicer"),
    (r"otdr", "Anritsu OTDR Tester"),
    (r"vs code|vscode", "VS Code IDE"),
    (r"postman", "Postman API Tester"),
]

def analyze_journal_entry(text: str) -> Dict[str, Any]:
    """
    Semantic parser analyzing student's logbook text to determine competency standard,
    extracted technical skills, confidence ratings, and detected hardware/software tools.
    """
    lower_text = text.lower()
    
    extracted_skills = []
    for pattern, skill_name, base_score in KEYWORD_SKILL_MAP:
        if re.search(pattern, lower_text):
            extracted_skills.append({"name": skill_name, "score": base_score})

    # Default fallback skills if text is brief or generic
    if not extracted_skills:
        extracted_skills = [
            {"name": "Administrasi Jaringan", "score": 88},
            {"name": "Dokumentasi Teknis", "score": 90}
        ]

    detected_tools = []
    for pattern, tool_name in TOOL_KEYWORD_MAP:
        if re.search(pattern, lower_text):
            detected_tools.append(tool_name)

    if not detected_tools:
        detected_tools = ["Terminal Console", "Logbook Editor"]

    # Compute match percentage based on matched competencies
    match_pct = round(min(99.4, 91.0 + len(extracted_skills) * 1.8), 1)

    return {
        "match_percentage": match_pct,
        "standard_competency": "Admin Jaringan Lv. 2",
        "competency_category": "SKKNI Kategori J.61",
        "complexity_level": "INTERMEDIATE",
        "complexity_tier": "Tier: Teknisi Madya",
        "extracted_skills": extracted_skills[:5],
        "detected_tools": detected_tools[:4]
    }
