"""
Legal Knowledge Base for SnapLaw Legal Q&A.

Two-step AI approach:
  Step 1: AI classifies the question into the correct legal category
  Step 2: Retrieve ONLY laws from that category -> generate structured answer

27 categories covering ALL major Pakistani legal domains.
"""

import os
import re
import logging
from typing import Dict, List, Optional
import google.generativeai as genai

logger = logging.getLogger(__name__)

_gemini_model = None


def _get_gemini_model():
    global _gemini_model
    if _gemini_model is None:
        api_key = os.environ.get("GEMINI_API_KEY", "")
        if api_key:
            genai.configure(api_key=api_key)
            _gemini_model = genai.GenerativeModel("gemini-2.5-flash")
            logger.info("Gemini model initialized for AI classification")
        else:
            logger.warning("No GEMINI_API_KEY — falling back to keyword classification")
    return _gemini_model


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALID CATEGORIES (27 total)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VALID_CATEGORIES = [
    "traffic_accident", "theft_robbery", "land_property_fraud",
    "property_tenancy", "family_law", "labor_law",
    "murder_assault", "harassment", "domestic_violence",
    "sexual_offenses", "child_rights", "cyber_crime",
    "cheque_bounce", "contract_dispute", "consumer_protection",
    "defamation", "inheritance_succession", "debt_recovery",
    "medical_negligence", "kidnapping_abduction", "drug_offenses",
    "corruption_bribery", "corporate_business", "environmental",
    "police_misconduct", "bail_matters", "banking_fraud", "general_criminal",
]


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AI CLASSIFICATION PROMPT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CLASSIFICATION_PROMPT = """You are a Pakistani legal case classifier. Read the user's question and return ONLY one category from the list below. Reply with the category name only — no explanation, no punctuation.

Categories:
- traffic_accident: car/vehicle accident, hit and run, reckless driving, road crash, pedestrian hit
- theft_robbery: theft, robbery, snatching, dacoity, stolen items, burglary, pickpocket
- land_property_fraud: land grabbed, property sold without consent, fake deed, qabza, zameen fraud, forged documents, illegal property transfer, benami
- property_tenancy: landlord/tenant disputes, rent issues, eviction, lease problems
- family_law: divorce, talaq, khula, child custody, maintenance, marriage, nikah, mehr/dower, iddat, polygamy
- labor_law: salary not paid, unfair termination, overtime, EOBI, gratuity, workplace rights
- murder_assault: murder, attempt to murder, assault, physical attack, stabbing, shooting, grievous hurt, beating
- harassment: workplace harassment, sexual harassment, stalking, threatening, intimidation, acid attack
- domestic_violence: wife beaten, husband abuse, in-law violence, spouse torture, marital violence
- sexual_offenses: rape, sexual assault, molestation, child sexual abuse, gang rape, indecent exposure
- child_rights: child abuse, child labor, child trafficking, juvenile offenses, minor exploitation, child custody violation
- cyber_crime: hacking, online fraud, identity theft, phishing, data theft, social media impersonation, revenge porn, sextortion, blackmail with photos/videos
- cheque_bounce: dishonoured cheque, bounced check, payment by cheque refused
- contract_dispute: breach of contract, agreement broken, contract not honored, terms violated
- consumer_protection: defective product, warranty claim, overcharged, fake product, consumer fraud, poor service
- defamation: false accusation, character assassination, slander, libel, damaging reputation
- inheritance_succession: property inheritance dispute, will contest, heirship, ancestral property share, denial of share
- debt_recovery: money owed, loan not returned, someone not paying back, borrowed money
- medical_negligence: doctor negligence, wrong treatment, hospital malpractice, surgical error, wrong diagnosis
- kidnapping_abduction: kidnapping, abduction, missing person taken, ransom, child kidnap
- drug_offenses: drugs, narcotics, heroin, hashish, drug possession, drug trafficking, substance abuse
- corruption_bribery: bribery, government corruption, kickback, public servant abuse of power, misuse of authority
- corporate_business: company dispute, shareholder issue, partnership conflict, SECP complaint, business fraud
- environmental: pollution, illegal construction, noise complaint, water contamination, tree cutting, factory waste
- police_misconduct: false FIR, police torture, illegal detention, custodial abuse, police not filing FIR, police corruption
- bail_matters: bail application, how to get bail, pre-arrest bail, post-arrest bail, bail conditions
- banking_fraud: bank fraud, ATM fraud, unauthorized transaction, account hacked, loan fraud, credit card fraud

User question: {question}

Reply with ONLY the category name."""


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# KNOWLEDGE BASE — 27 CATEGORIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LEGAL_KNOWLEDGE_BASE: Dict[str, dict] = {

    # ─────────────────────────────────────────
    # 1. TRAFFIC ACCIDENT / HIT-AND-RUN
    # ─────────────────────────────────────────
    "traffic_accident": {
        "label": "Traffic Accident / Hit-and-Run",
        "sources": ["Motor Vehicles Ordinance 1965", "Pakistan Penal Code", "CrPC"],
        "laws": [
            {"section": "Motor Vehicles Ordinance 1965 Section 139", "title": "Reckless and Dangerous Driving", "description": "Driving rashly or at a speed or manner dangerous to the public", "penalty": "Up to 6 months imprisonment or fine up to Rs. 500 or both"},
            {"section": "Motor Vehicles Ordinance 1965 Section 140", "title": "Causing Death by Reckless Driving", "description": "Causing death by driving any motor vehicle rashly or negligently", "penalty": "Up to 5 years imprisonment and fine"},
            {"section": "Motor Vehicles Ordinance 1965 Section 141", "title": "Hit-and-Run / Leaving Scene of Accident", "description": "Driver who causes accident and fails to stop and report to nearest police station", "penalty": "Up to 1 year imprisonment and/or fine"},
            {"section": "PPC Section 279", "title": "Rash Driving on Public Way", "description": "Driving any vehicle rashly or negligently on a public road endangering human life", "penalty": "Up to 6 months imprisonment or fine up to Rs. 1,000 or both"},
            {"section": "PPC Section 304-A", "title": "Causing Death by Negligence", "description": "Causing death by doing any rash or negligent act not amounting to culpable homicide", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "PPC Sections 337-A to 337-L", "title": "Causing Hurt / Bodily Injury", "description": "Various categories of hurt caused by rash or negligent driving", "penalty": "Daman (compensation) + imprisonment depending on injury severity"},
        ],
        "procedure": [
            "File an FIR at the nearest police station immediately",
            "Get a Medico-Legal Certificate (MLC) from a government hospital",
            "Collect evidence: CCTV footage, eyewitness statements, vehicle number plate",
            "Police will investigate and file challan under MVO + PPC 304-A",
            "File a civil suit for compensation for damages and medical expenses",
            "If police refuses FIR, approach SP/SSP or file under Section 22-A CrPC",
        ],
    },

    # ─────────────────────────────────────────
    # 2. THEFT / ROBBERY / SNATCHING
    # ─────────────────────────────────────────
    "theft_robbery": {
        "label": "Theft / Robbery / Snatching",
        "sources": ["Pakistan Penal Code", "CrPC"],
        "laws": [
            {"section": "PPC Section 378-379", "title": "Theft", "description": "Dishonestly taking movable property out of possession without consent", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 380", "title": "Theft in Dwelling House", "description": "Theft in any building used for human dwelling", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 392", "title": "Robbery (Theft with Force/Fear)", "description": "Theft with use of force or fear of death/hurt", "penalty": "Up to 10 years imprisonment and fine"},
            {"section": "PPC Section 395", "title": "Dacoity (Gang Robbery by 5+ Persons)", "description": "When five or more persons conjointly commit robbery", "penalty": "Up to 14 years imprisonment (life if murder attempt)"},
            {"section": "PPC Section 397", "title": "Robbery with Attempt to Cause Death", "description": "Using deadly weapon or causing grievous hurt during robbery", "penalty": "Not less than 7 years, up to 14 years"},
            {"section": "PPC Section 411", "title": "Dishonestly Receiving Stolen Property", "description": "Whoever dishonestly receives or retains any stolen property", "penalty": "Up to 3 years imprisonment or fine or both"},
        ],
        "procedure": [
            "File an FIR at the nearest police station immediately",
            "Provide detailed description of stolen items with approximate value",
            "Describe suspect(s): appearance, clothing, vehicle used",
            "Provide evidence: CCTV footage, mobile IMEI number, witnesses",
            "If mobile stolen, block IMEI through PTA",
            "If police refuses FIR, apply to SP/SSP or under Section 22-A CrPC",
        ],
    },

    # ─────────────────────────────────────────
    # 3. LAND / PROPERTY FRAUD
    # ─────────────────────────────────────────
    "land_property_fraud": {
        "label": "Land / Property Fraud",
        "sources": ["Pakistan Penal Code", "Specific Relief Act 1877", "Transfer of Property Act 1882", "Benami Transactions Act 2017"],
        "laws": [
            {"section": "PPC Section 420", "title": "Cheating and Dishonestly Inducing Delivery of Property", "description": "Cheating and dishonestly inducing delivery of any property or valuable security", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 406", "title": "Criminal Breach of Trust", "description": "Dishonestly misappropriating property entrusted to a person", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 467", "title": "Forgery of Valuable Security or Deed", "description": "Forging a document purporting to be a valuable security, will, sale deed, mortgage, gift, or power of attorney", "penalty": "Up to 10 years imprisonment and fine"},
            {"section": "PPC Section 468", "title": "Forgery for Purpose of Cheating", "description": "Committing forgery intending the document be used for cheating", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 471", "title": "Using Forged Document as Genuine", "description": "Fraudulently using a document known to be forged", "penalty": "Same punishment as forgery of that document type"},
            {"section": "Specific Relief Act 1877 Section 8", "title": "Recovery of Specific Immovable Property", "description": "Person entitled to possession may recover it through civil suit", "penalty": "Court orders restoration + damages"},
            {"section": "Transfer of Property Act 1882", "title": "Property Transfer Requirements", "description": "All transfers require owner's free consent, writing, and registration", "penalty": "Transfer without consent is void and illegal"},
            {"section": "Benami Transactions (Prohibition) Act 2017", "title": "Prohibition of Benami Transfers", "description": "Holding property in another person's name (benami) is prohibited", "penalty": "Up to 3 years imprisonment + fine; property confiscated"},
        ],
        "procedure": [
            "File FIR at police station under PPC 420, 406, 467, 468",
            "Hire a property lawyer immediately",
            "File civil suit for cancellation of fraudulent sale deed",
            "Apply for stay order / injunction to stop further transfer",
            "File complaint with land records authority (Patwari / Registry office)",
            "File suit for declaration + permanent injunction in Civil Court",
            "Gather evidence: original ownership documents, Fard, witness statements",
        ],
    },

    # ─────────────────────────────────────────
    # 4. PROPERTY / TENANCY
    # ─────────────────────────────────────────
    "property_tenancy": {
        "label": "Property / Tenancy Law",
        "sources": ["Rent Restriction Ordinance 1959", "Pakistan Penal Code", "Transfer of Property Act 1882", "Illegal Dispossession Act 2005"],
        "laws": [
            {"section": "Rent Restriction Ordinance 1959", "title": "Protection of Tenants", "description": "Landlord cannot evict tenant without order from Rent Controller", "penalty": "Illegal eviction is punishable; landlord must follow legal process"},
            {"section": "PPC Section 441", "title": "Criminal Trespass", "description": "Entering property in another's possession with intent to commit offence or intimidate", "penalty": "Up to 3 months imprisonment or fine up to Rs. 500 or both"},
            {"section": "PPC Section 442", "title": "House Trespass", "description": "Criminal trespass in a building used as human dwelling", "penalty": "Up to 1 year imprisonment or fine up to Rs. 1,000 or both"},
            {"section": "Transfer of Property Act 1882", "title": "Property Transfer & Lease Rules", "description": "All property transfers and leases must be in writing and registered", "penalty": "Unregistered documents not admissible as evidence"},
            {"section": "Illegal Dispossession Act 2005", "title": "Protection Against Illegal Dispossession (Qabza)", "description": "No person shall illegally dispossess another from immovable property", "penalty": "Up to 3 years imprisonment and/or fine up to Rs. 500,000"},
        ],
        "procedure": [
            "Collect all documents: sale deed, registry, rent agreement, mutation records",
            "Send legal notice to opposing party through advocate",
            "For eviction: File petition before Rent Controller",
            "For illegal possession: File FIR under Illegal Dispossession Act 2005",
            "For trespass: File FIR under PPC 441/442",
            "Get stay order from court if someone is taking your property",
        ],
    },

    # ─────────────────────────────────────────
    # 5. FAMILY LAW
    # ─────────────────────────────────────────
    "family_law": {
        "label": "Family Law (Divorce, Custody, Maintenance)",
        "sources": ["Muslim Family Laws Ordinance 1961", "Family Courts Act 1964", "Guardians and Wards Act 1890"],
        "laws": [
            {"section": "Muslim Family Laws Ordinance 1961 Section 7", "title": "Talaq (Divorce by Husband)", "description": "Written notice to Chairman of Union Council required. Not effective until 90 days after notice", "penalty": "Talaq without notice: up to 1 year imprisonment or fine up to Rs. 5,000"},
            {"section": "Muslim Family Laws Ordinance 1961 Section 8", "title": "Dissolution of Marriage (Khula)", "description": "Muslim woman may obtain dissolution through court by filing suit for Khula", "penalty": "N/A — right of wife to seek dissolution"},
            {"section": "Muslim Family Laws Ordinance 1961 Section 9", "title": "Maintenance for Wife", "description": "If husband fails to maintain wife, she can apply to Arbitration Council for maintenance", "penalty": "Failure to pay: recovery as arrears of land revenue + up to 1 year imprisonment"},
            {"section": "Family Courts Act 1964", "title": "Jurisdiction of Family Courts", "description": "Exclusive jurisdiction for dissolution, dower, maintenance, custody, jactitation of marriage", "penalty": "N/A — jurisdictional provision"},
            {"section": "Guardians and Wards Act 1890", "title": "Child Custody", "description": "Welfare of minor is paramount. Mother has preferential custody (Hizanat) of sons under 7 and daughters until puberty", "penalty": "N/A — welfare-based court decision"},
            {"section": "West Pakistan Family Courts Act 1964 Section 17-A", "title": "Interim Maintenance", "description": "Court may grant interim maintenance during pendency of suit", "penalty": "Enforceable through attachment of property"},
        ],
        "procedure": [
            "Consult a family law advocate",
            "For divorce/khula: File suit in Family Court",
            "For maintenance: Apply to Arbitration Council under MFLO Section 9",
            "For custody: File under Guardians and Wards Act in Family Court",
            "Gather documents: Nikah Nama, birth certificates, financial records",
            "Family Court must decide within 6 months",
        ],
    },

    # ─────────────────────────────────────────
    # 6. LABOUR / EMPLOYMENT LAW
    # ─────────────────────────────────────────
    "labor_law": {
        "label": "Labour / Employment Law",
        "sources": ["Payment of Wages Act 1936", "Industrial Relations Act 2012", "Standing Orders Ordinance 1968", "Factories Act 1934"],
        "laws": [
            {"section": "Payment of Wages Act 1936 Section 5", "title": "Time of Payment of Wages", "description": "Wages must be paid before 7th day after wage period ends", "penalty": "Employer liable to pay with compensation up to Rs. 300"},
            {"section": "Payment of Wages Act 1936 Section 15", "title": "Recovery of Unpaid Wages", "description": "Employee may apply to Payment of Wages Authority within 1 year", "penalty": "Authority orders payment + compensation + penalty on employer"},
            {"section": "Industrial Relations Act 2012 Section 20", "title": "Unfair Labour Practices", "description": "Termination without just cause is unfair labour practice", "penalty": "Challenge in Labour Court; reinstatement possible"},
            {"section": "Standing Orders Ordinance 1968", "title": "Conditions of Employment", "description": "1 month notice or pay in lieu required before termination", "penalty": "Reinstatement with back pay if termination found illegal"},
            {"section": "Employees Old Age Benefits Act 1976", "title": "EOBI Pension", "description": "Employer must register employees with EOBI", "penalty": "Non-registration: fine up to Rs. 50,000"},
            {"section": "Factories Act 1934 Section 47", "title": "Working Hours and Overtime", "description": "Max 48 hours/week, 9 hours/day. Overtime at double rate", "penalty": "Fine for violation of working hour provisions"},
        ],
        "procedure": [
            "Send formal legal notice to employer demanding payment",
            "File complaint with Labour Department / Labour Inspector",
            "Apply to Payment of Wages Authority under Section 15 (within 1 year)",
            "If wrongfully terminated, file in Labour Court within 30 days",
            "Gather evidence: appointment letter, salary slips, bank statements",
        ],
    },

    # ─────────────────────────────────────────
    # 7. MURDER / ASSAULT
    # ─────────────────────────────────────────
    "murder_assault": {
        "label": "Murder / Assault / Physical Harm",
        "sources": ["Pakistan Penal Code", "CrPC"],
        "laws": [
            {"section": "PPC Section 302", "title": "Qatl-e-Amd (Intentional Murder)", "description": "Whoever intentionally causes death of another person", "penalty": "Death penalty or life imprisonment as Qisas, or Tazir, or Diyat (blood money)"},
            {"section": "PPC Section 307", "title": "Attempted Murder", "description": "Doing any act with intention of causing death", "penalty": "Up to 25 years imprisonment"},
            {"section": "PPC Section 324", "title": "Attempt to Cause Grievous Hurt", "description": "Act likely to cause hurt or grievous hurt", "penalty": "Up to 10 years imprisonment"},
            {"section": "PPC Section 334-337", "title": "Causing Hurt (Various Degrees)", "description": "Causing bodily injury — Shajjah (head/face), Jurh (body), fractures, disfigurement", "penalty": "Arsh (compensation) + imprisonment depending on severity"},
            {"section": "PPC Section 341", "title": "Wrongful Restraint", "description": "Voluntarily obstructing a person from proceeding", "penalty": "Up to 1 month imprisonment or fine Rs. 500 or both"},
            {"section": "PPC Section 352", "title": "Assault / Criminal Force", "description": "Using force or assault on any person", "penalty": "Up to 3 months imprisonment or fine up to Rs. 500 or both"},
        ],
        "procedure": [
            "Call Police 15 or Rescue 1122 if in immediate danger",
            "File FIR at nearest police station immediately",
            "Get Medico-Legal Certificate (MLC) from government hospital",
            "Preserve all evidence: photos, videos, witness statements",
            "Hire a qualified criminal advocate",
            "If police refuses FIR, approach SP/SSP or Section 22-A CrPC",
        ],
    },

    # ─────────────────────────────────────────
    # 8. HARASSMENT (WORKPLACE / GENERAL)
    # ─────────────────────────────────────────
    "harassment": {
        "label": "Harassment / Stalking / Threats",
        "sources": ["Protection Against Harassment Act 2010", "Pakistan Penal Code", "PECA 2016"],
        "laws": [
            {"section": "Protection Against Harassment of Women at Workplace Act 2010", "title": "Workplace Harassment", "description": "Every organization must have Inquiry Committee. Protects against unwelcome advances, requests for sexual favors, or verbal/physical conduct of sexual nature", "penalty": "Minor penalty to dismissal; appeal to Ombudsperson within 30 days"},
            {"section": "PPC Section 509", "title": "Insult to Modesty of Woman", "description": "Word, gesture, or act intended to insult the modesty of a woman", "penalty": "Up to 3 years imprisonment and/or fine up to Rs. 500,000"},
            {"section": "PPC Section 506", "title": "Criminal Intimidation", "description": "Threatening another with injury to person, reputation, or property", "penalty": "Up to 2 years (up to 7 years if threat of death/grievous hurt)"},
            {"section": "PPC Section 354", "title": "Assault or Criminal Force to Woman", "description": "Using criminal force on woman with intent to outrage modesty", "penalty": "Up to 2 years imprisonment and fine"},
            {"section": "PECA 2016 Section 24", "title": "Cyber Stalking", "description": "Following, contacting, monitoring, or spying on a person using information system", "penalty": "Up to 3 years imprisonment or fine up to Rs. 1 million or both"},
        ],
        "procedure": [
            "Document all incidents with dates, times, and witnesses",
            "For workplace: Report to organization's Inquiry Committee",
            "If no committee, complain to Ombudsperson for Harassment",
            "File FIR at police station for criminal harassment",
            "For online harassment: File with FIA Cyber Crime Wing",
            "Consult a lawyer specializing in harassment cases",
        ],
    },

    # ─────────────────────────────────────────
    # 9. DOMESTIC VIOLENCE
    # ─────────────────────────────────────────
    "domestic_violence": {
        "label": "Domestic Violence",
        "sources": ["Domestic Violence Act 2012", "Punjab Protection of Women Act 2016", "Pakistan Penal Code"],
        "laws": [
            {"section": "Domestic Violence (Prevention & Protection) Act 2012", "title": "Protection Against Domestic Violence", "description": "Covers physical, sexual, emotional, and psychological abuse within household. Victim can apply for protection order", "penalty": "Violation of protection order: up to 1 year imprisonment and fine up to Rs. 100,000"},
            {"section": "Punjab Protection of Women Against Violence Act 2016", "title": "Punjab Women Protection (District Authority)", "description": "District Women Protection Committee provides immediate protection, shelter, and legal aid", "penalty": "Violation of protection order: up to 6 months imprisonment and/or fine"},
            {"section": "PPC Section 337", "title": "Causing Hurt", "description": "Various degrees of bodily injury caused intentionally", "penalty": "Arsh (compensation) + imprisonment depending on severity of injury"},
            {"section": "PPC Section 354", "title": "Criminal Force Against Woman", "description": "Using criminal force to outrage modesty of woman", "penalty": "Up to 2 years imprisonment and fine"},
            {"section": "PPC Section 498-A (proposed)", "title": "Cruelty by Husband or Relatives", "description": "Subjecting a woman to cruelty by husband or in-laws", "penalty": "Varies by province; up to 3 years in certain jurisdictions"},
        ],
        "procedure": [
            "Ensure immediate safety — leave to a safe place if in danger",
            "Call Police 15 or Rescue 1122 in emergency",
            "File FIR at nearest police station",
            "Get Medico-Legal Certificate from government hospital",
            "Apply for protection order under Domestic Violence Act",
            "Contact Dar-ul-Aman (women's shelter) for temporary refuge",
            "Consult family law attorney for divorce, custody, and maintenance options",
        ],
    },

    # ─────────────────────────────────────────
    # 10. SEXUAL OFFENSES
    # ─────────────────────────────────────────
    "sexual_offenses": {
        "label": "Rape / Sexual Assault",
        "sources": ["Pakistan Penal Code", "Anti-Rape Act 2021", "CrPC"],
        "laws": [
            {"section": "PPC Section 375-376", "title": "Rape (Zina-bil-Jabr)", "description": "Sexual intercourse without consent or with consent obtained by force, threat, or deception", "penalty": "Death penalty or 10-25 years imprisonment + fine"},
            {"section": "PPC Section 376(2)", "title": "Gang Rape", "description": "Rape committed by two or more persons in furtherance of common intention", "penalty": "Death penalty or life imprisonment"},
            {"section": "PPC Section 377", "title": "Unnatural Offenses", "description": "Carnal intercourse against the order of nature", "penalty": "2 years to life imprisonment"},
            {"section": "Anti-Rape (Investigation and Trial) Act 2021", "title": "Special Anti-Rape Procedures", "description": "Mandatory investigation within 2 months. Special courts must decide within 4 months. Chemical castration provision", "penalty": "Enhanced punishments including chemical castration for repeat offenders"},
            {"section": "PPC Section 354-A", "title": "Assault with Intent to Outrage Modesty", "description": "Stripping or parading a woman naked in public", "penalty": "Death penalty or life imprisonment"},
        ],
        "procedure": [
            "Move to safety immediately",
            "Do NOT shower or change clothes — preserve physical evidence",
            "Seek immediate medical attention at hospital",
            "File FIR at police station — this is your legal right",
            "Request female police officer if more comfortable",
            "Get medico-legal examination within 72 hours",
            "Contact War Against Rape (WAR): 021-35682227",
            "Hire criminal/women's rights lawyer",
        ],
    },

    # ─────────────────────────────────────────
    # 11. CHILD RIGHTS / CHILD ABUSE
    # ─────────────────────────────────────────
    "child_rights": {
        "label": "Child Rights / Child Abuse",
        "sources": ["Zainab Alert Act 2020", "Employment of Children Act 1991", "Pakistan Penal Code", "Juvenile Justice System Act 2018"],
        "laws": [
            {"section": "Zainab Alert, Response and Recovery Act 2020", "title": "Child Abduction and Abuse Alert System", "description": "Mandatory reporting of missing/abused children. National alert system for missing children", "penalty": "Death penalty or life imprisonment for child sexual abuse; fine up to Rs. 1 million"},
            {"section": "Employment of Children Act 1991", "title": "Prohibition of Child Labor", "description": "No child under 14 shall be employed in any occupation. No child under 18 in hazardous work", "penalty": "Fine up to Rs. 20,000 on employer; imprisonment up to 1 year for repeat offense"},
            {"section": "Juvenile Justice System Act 2018", "title": "Protection of Juvenile Offenders", "description": "Children under 18 tried in Juvenile Courts. No death penalty for juveniles", "penalty": "N/A — protective legislation for minor offenders"},
            {"section": "PPC Section 328-A", "title": "Cruelty to Child", "description": "Whoever willfully assaults, ill-treats, or causes injury to any child", "penalty": "Up to 3 years imprisonment or fine up to Rs. 50,000 or both"},
            {"section": "PPC Section 364-A", "title": "Kidnapping for Ransom of Minor", "description": "Kidnapping any person under 14 for ransom", "penalty": "Death penalty or life imprisonment"},
        ],
        "procedure": [
            "Ensure the child's immediate safety",
            "Report to police — File FIR immediately",
            "Call Zainab Alert Helpline: 1099",
            "Seek medical attention for the child",
            "Contact Child Protection Bureau in your province",
            "Consult a child rights lawyer",
            "Seek counseling for the child from qualified psychologist",
        ],
    },

    # ─────────────────────────────────────────
    # 12. CYBER CRIME
    # ─────────────────────────────────────────
    "cyber_crime": {
        "label": "Cyber Crime / Online Fraud",
        "sources": ["Prevention of Electronic Crimes Act 2016", "Pakistan Penal Code"],
        "laws": [
            {"section": "PECA 2016 Section 3", "title": "Unauthorized Access to Information System", "description": "Hacking — accessing any information system without authorization", "penalty": "Up to 3 months imprisonment or fine up to Rs. 50,000 or both"},
            {"section": "PECA 2016 Section 4", "title": "Unauthorized Copying of Data", "description": "Copying or transmitting data from an information system without authorization", "penalty": "Up to 6 months imprisonment or fine up to Rs. 100,000 or both"},
            {"section": "PECA 2016 Section 14", "title": "Electronic Fraud", "description": "Using information system to commit fraud, obtain money or property by false representation", "penalty": "Up to 2 years imprisonment or fine up to Rs. 10 million or both"},
            {"section": "PECA 2016 Section 16", "title": "Offenses Against Identity", "description": "Identity theft — using another person's identity information without authorization", "penalty": "Up to 3 years imprisonment or fine up to Rs. 5 million or both"},
            {"section": "PECA 2016 Section 20", "title": "Offenses Against Dignity / Cyber Harassment", "description": "Transmitting information through information system that harms reputation or privacy", "penalty": "Up to 1 year imprisonment or fine up to Rs. 1 million or both"},
            {"section": "PECA 2016 Section 21", "title": "Offenses Against Modesty", "description": "Superimposing photograph on sexually explicit content", "penalty": "Up to 5 years imprisonment or fine up to Rs. 5 million or both"},
            {"section": "PECA 2016 Section 24", "title": "Cyber Stalking", "description": "Spying, monitoring, or following a person using information system", "penalty": "Up to 3 years imprisonment or fine up to Rs. 1 million or both"},
        ],
        "procedure": [
            "Screenshot and preserve ALL evidence — do NOT delete anything",
            "File complaint with FIA Cyber Crime Wing at nr3c.gov.pk or call 9911",
            "File FIR at local police station if threats are involved",
            "Block the abuser on all platforms",
            "Report content to the social media platform",
            "If financial fraud, inform your bank immediately and block cards",
            "Consult a cyber crime lawyer",
        ],
    },

    # ─────────────────────────────────────────
    # 13. CHEQUE BOUNCE
    # ─────────────────────────────────────────
    "cheque_bounce": {
        "label": "Cheque Bounce / Dishonoured Cheque",
        "sources": ["Negotiable Instruments Act 1881", "Financial Institutions (Recovery of Finances) Ordinance 2001"],
        "laws": [
            {"section": "Negotiable Instruments Act 1881 Section 138", "title": "Dishonour of Cheque for Insufficiency of Funds", "description": "If a cheque is returned by bank unpaid due to insufficient funds or if it exceeds the amount arranged to be paid", "penalty": "Up to 1 year imprisonment or fine up to twice the cheque amount or both"},
            {"section": "Negotiable Instruments Act 1881 Section 139", "title": "Presumption in Favour of Holder", "description": "Court presumes that the cheque was issued for discharge of a legal debt or liability", "penalty": "N/A — evidentiary presumption in holder's favor"},
            {"section": "Negotiable Instruments Act 1881 Section 141", "title": "Liability of Company Officers", "description": "If cheque issued on behalf of company, every director/officer responsible is also liable", "penalty": "Same as Section 138 — imprisonment and/or fine"},
            {"section": "PPC Section 489-F", "title": "Dishonestly Issuing Cheque", "description": "Whoever dishonestly issues a cheque towards repayment of a loan or obligation which is dishonoured on presentation", "penalty": "Up to 3 years imprisonment or fine or both, or both"},
        ],
        "procedure": [
            "Present the cheque to the bank and get it formally dishonoured (get memo from bank)",
            "Send a legal notice to the issuer within 30 days of dishonour demanding payment within 15 days",
            "If payment not made within 15 days of notice, file a criminal complaint under Section 489-F PPC",
            "File complaint in the court of Magistrate having jurisdiction",
            "Also file civil suit for recovery of the cheque amount",
            "Keep the original dishonoured cheque, bank memo, and legal notice as evidence",
        ],
    },

    # ─────────────────────────────────────────
    # 14. CONTRACT DISPUTE
    # ─────────────────────────────────────────
    "contract_dispute": {
        "label": "Contract Dispute / Breach of Agreement",
        "sources": ["Contract Act 1872", "Specific Relief Act 1877"],
        "laws": [
            {"section": "Contract Act 1872 Section 2(h)", "title": "Definition of Contract", "description": "An agreement enforceable by law. Requires free consent, lawful consideration, and competent parties", "penalty": "N/A — definitional provision"},
            {"section": "Contract Act 1872 Section 73", "title": "Compensation for Breach", "description": "Party who suffers by breach is entitled to compensation for loss or damage caused", "penalty": "Compensation for actual loss or damage proved"},
            {"section": "Contract Act 1872 Section 74", "title": "Penalty for Breach (Liquidated Damages)", "description": "When penalty is named in contract, party can claim reasonable compensation not exceeding penalty amount", "penalty": "Court awards reasonable compensation, not necessarily full penalty"},
            {"section": "Contract Act 1872 Section 75", "title": "Compensation for Rightful Rescission", "description": "Person who rightfully rescinds contract is entitled to compensation for non-fulfillment", "penalty": "Compensation for damages sustained"},
            {"section": "Specific Relief Act 1877 Section 12", "title": "Specific Performance", "description": "Court may order party to perform their contractual obligations specifically", "penalty": "Court-ordered performance; contempt of court if not complied"},
        ],
        "procedure": [
            "Review the contract terms and identify the specific breach",
            "Send legal notice to the breaching party demanding performance or compensation",
            "If no response within 30 days, file civil suit in Civil Court",
            "File suit for specific performance under Specific Relief Act if you want the contract fulfilled",
            "File suit for damages under Contract Act Section 73 if you want compensation",
            "Gather evidence: signed contract, correspondence, proof of breach, proof of loss",
        ],
    },

    # ─────────────────────────────────────────
    # 15. CONSUMER PROTECTION
    # ─────────────────────────────────────────
    "consumer_protection": {
        "label": "Consumer Protection / Product Complaints",
        "sources": ["Consumer Protection Acts (Provincial)", "Pakistan Penal Code"],
        "laws": [
            {"section": "Punjab Consumer Protection Act 2005", "title": "Consumer Rights Protection", "description": "Consumers have right to safety, information, choice, and redressal. Covers defective goods, deficient services, unfair trade practices", "penalty": "Compensation + replacement + refund as ordered by Consumer Court"},
            {"section": "Sindh Consumer Protection Ordinance 2007", "title": "Consumer Rights (Sindh)", "description": "Similar protections for Sindh province consumers", "penalty": "Compensation + penalties as ordered"},
            {"section": "Islamabad Consumer Protection Act 1995", "title": "Consumer Rights (ICT)", "description": "Consumer protection in Islamabad Capital Territory", "penalty": "Compensation to consumer + fine on trader"},
            {"section": "PPC Section 270-271", "title": "Sale of Adulterated Food/Drink", "description": "Selling food or drink that is noxious or adulterated", "penalty": "Up to 6 months imprisonment or fine up to Rs. 1,000 or both"},
            {"section": "PPC Section 420", "title": "Cheating by False Representation", "description": "Misrepresenting product quality, features, or price", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "Sale of Goods Act 1930", "title": "Implied Warranties", "description": "Goods must be of merchantable quality and fit for purpose", "penalty": "Buyer entitled to reject goods and claim refund"},
        ],
        "procedure": [
            "Keep all receipts, warranty cards, and product packaging",
            "First complain to the seller/manufacturer in writing",
            "If no response, file complaint in Consumer Court of your district",
            "Consumer Court filing is free or minimal fee",
            "Bring evidence: receipt, product, photos of defect, correspondence",
            "Court can order replacement, refund, or compensation",
        ],
    },

    # ─────────────────────────────────────────
    # 16. DEFAMATION
    # ─────────────────────────────────────────
    "defamation": {
        "label": "Defamation / False Accusation",
        "sources": ["Pakistan Penal Code", "Defamation Ordinance 2002"],
        "laws": [
            {"section": "PPC Section 499", "title": "Defamation (Definition)", "description": "Making or publishing any imputation concerning any person intending to harm reputation by words, signs, or visible representations", "penalty": "Defined in Section 500"},
            {"section": "PPC Section 500", "title": "Punishment for Defamation", "description": "Whoever defames another shall be punished", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "PPC Section 501", "title": "Printing Defamatory Matter", "description": "Whoever prints or engraves any matter knowing it to be defamatory", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "Defamation Ordinance 2002", "title": "Civil Defamation", "description": "Civil remedy for defamation — person can sue for damages in civil court for harm to reputation", "penalty": "Court can award damages/compensation for harm to reputation"},
            {"section": "PECA 2016 Section 20", "title": "Online Defamation", "description": "Transmitting information through information system to harm reputation or privacy", "penalty": "Up to 1 year imprisonment or fine up to Rs. 1 million or both"},
        ],
        "procedure": [
            "Collect and preserve all evidence of defamatory statements (screenshots, recordings, printed material)",
            "Send legal notice demanding retraction and apology",
            "For criminal defamation: File complaint under PPC 500 in Magistrate's court",
            "For civil defamation: File suit under Defamation Ordinance 2002 in Civil Court",
            "For online defamation: File with FIA Cyber Crime Wing under PECA 2016",
            "Claim damages for harm to reputation, mental anguish, and loss of business",
        ],
    },

    # ─────────────────────────────────────────
    # 17. INHERITANCE / SUCCESSION
    # ─────────────────────────────────────────
    "inheritance_succession": {
        "label": "Inheritance / Succession / Will Disputes",
        "sources": ["Muslim Personal Law (Shariat) Application Act 1962", "Succession Act 1925", "Pakistan Penal Code"],
        "laws": [
            {"section": "Muslim Personal Law (Shariat) Application Act 1962", "title": "Islamic Inheritance Rules", "description": "All inheritance for Muslims governed by Shariat. Fixed shares for sons (2x daughter share), daughters, wives, parents, etc.", "penalty": "N/A — mandatory application of Islamic law"},
            {"section": "West Pakistan Muslim Personal Law (Shariat) Application Act 1962 Section 4", "title": "Denial of Share to Women", "description": "Women cannot be deprived of their inheritance share. Any custom denying women's share is void", "penalty": "Criminal prosecution under PPC for fraud if share denied through deception"},
            {"section": "Succession Act 1925", "title": "Non-Muslim Succession", "description": "Succession for non-Muslims governed by this Act. Also covers wills and probate", "penalty": "N/A — governs distribution of estate"},
            {"section": "PPC Section 420", "title": "Cheating in Inheritance", "description": "Fraudulently depriving an heir of their lawful share through deception or forged documents", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "Specific Relief Act 1877", "title": "Partition of Property", "description": "Co-owners can file for partition of jointly owned inherited property", "penalty": "Court orders division of property according to legal shares"},
        ],
        "procedure": [
            "Obtain death certificate and succession certificate from court",
            "Get legal heir certificate from Union Council (Form B)",
            "Verify property records at land revenue office",
            "If heirs agree, execute a partition deed and get it registered",
            "If share denied, send legal notice demanding share",
            "File suit for declaration and partition in Civil Court",
            "For women denied share: File criminal complaint under PPC 420",
        ],
    },

    # ─────────────────────────────────────────
    # 18. DEBT RECOVERY
    # ─────────────────────────────────────────
    "debt_recovery": {
        "label": "Debt Recovery / Money Owed",
        "sources": ["Contract Act 1872", "Financial Institutions Ordinance 2001", "CPC (Code of Civil Procedure)"],
        "laws": [
            {"section": "Contract Act 1872 Section 73", "title": "Right to Recover Debt", "description": "Creditor entitled to recover amount owed plus compensation for loss caused by non-payment", "penalty": "Court orders repayment + interest + damages"},
            {"section": "Order XXXVII CPC", "title": "Summary Suit for Recovery", "description": "Expedited procedure for recovery of money on written instruments (promissory notes, cheques, contracts)", "penalty": "Court orders payment; attachment of debtor's property if not paid"},
            {"section": "Financial Institutions (Recovery of Finances) Ordinance 2001", "title": "Bank Loan Recovery", "description": "Banking courts have jurisdiction for recovery of bank finances", "penalty": "Court orders repayment; can attach and sell property"},
            {"section": "PPC Section 406", "title": "Criminal Breach of Trust", "description": "If money was entrusted and misappropriated", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 420", "title": "Cheating", "description": "If money obtained through deception or false promises", "penalty": "Up to 7 years imprisonment and fine"},
        ],
        "procedure": [
            "Gather evidence of the debt: written agreement, receipts, bank transfers, messages, witnesses",
            "Send formal legal notice demanding repayment within 30 days",
            "If unpaid, file civil suit for recovery in Civil Court",
            "For faster recovery, file Summary Suit under Order XXXVII CPC",
            "If cheque was given, follow cheque bounce procedure",
            "If fraud involved, also file criminal complaint under PPC 420",
        ],
    },

    # ─────────────────────────────────────────
    # 19. MEDICAL NEGLIGENCE
    # ─────────────────────────────────────────
    "medical_negligence": {
        "label": "Medical Negligence / Malpractice",
        "sources": ["Pakistan Penal Code", "Pakistan Medical and Dental Council Ordinance 1962"],
        "laws": [
            {"section": "PPC Section 304-A", "title": "Causing Death by Negligence", "description": "Doctor causing patient's death by rash or negligent act", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "PPC Section 337", "title": "Causing Hurt by Negligence", "description": "Causing bodily injury to patient by negligent treatment or surgery", "penalty": "Daman (compensation) + imprisonment depending on severity"},
            {"section": "PPC Section 338", "title": "Causing Miscarriage by Negligence", "description": "Medical negligence causing miscarriage", "penalty": "Imprisonment and/or fine"},
            {"section": "Pakistan Medical and Dental Council Ordinance 1962", "title": "Disciplinary Action Against Doctors", "description": "PMDC can take disciplinary action including suspension or cancellation of license for professional misconduct", "penalty": "License suspension or cancellation"},
            {"section": "Consumer Protection Acts (Provincial)", "title": "Medical Services as Consumer Service", "description": "Medical treatment is a 'service' under consumer law. Patient can claim compensation", "penalty": "Consumer Court can order compensation"},
        ],
        "procedure": [
            "Preserve all medical records: prescriptions, reports, bills, discharge summary",
            "Get an independent medical opinion from another qualified doctor",
            "File complaint with Pakistan Medical and Dental Council (PMDC)",
            "For death by negligence: File FIR under PPC 304-A",
            "For injury: File complaint under PPC 337",
            "File civil suit for compensation in Civil Court or Consumer Court",
            "Gather evidence: medical records, expert opinion, receipts, witness statements",
        ],
    },

    # ─────────────────────────────────────────
    # 20. KIDNAPPING / ABDUCTION
    # ─────────────────────────────────────────
    "kidnapping_abduction": {
        "label": "Kidnapping / Abduction",
        "sources": ["Pakistan Penal Code", "CrPC"],
        "laws": [
            {"section": "PPC Section 359-360", "title": "Kidnapping from Pakistan / Lawful Guardianship", "description": "Taking or enticing any person beyond Pakistan or any minor under 14 from lawful guardian without consent", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 362-363", "title": "Abduction", "description": "Compelling or inducing any person to go from any place by force or deceitful means", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 364-A", "title": "Kidnapping for Ransom", "description": "Kidnapping any person for the purpose of demanding ransom", "penalty": "Death penalty or life imprisonment"},
            {"section": "PPC Section 365", "title": "Kidnapping with Intent to Wrongfully Confine", "description": "Kidnapping with intention to cause person to be secretly and wrongfully confined", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 365-A", "title": "Kidnapping for Extortion", "description": "Kidnapping for purpose of extorting property or valuable security", "penalty": "Death penalty or life imprisonment and forfeiture of property"},
        ],
        "procedure": [
            "Call Police 15 immediately",
            "File FIR at nearest police station without delay",
            "Provide recent photograph and description of the missing person",
            "Share last known location, contacts, and any suspicious persons",
            "Inform family and community to help search",
            "If ransom demanded, inform police immediately — do NOT pay without police guidance",
            "Hire a criminal advocate for legal proceedings",
        ],
    },

    # ─────────────────────────────────────────
    # 21. DRUG OFFENSES
    # ─────────────────────────────────────────
    "drug_offenses": {
        "label": "Drug Offenses / Narcotics",
        "sources": ["Control of Narcotic Substances Act 1997"],
        "laws": [
            {"section": "CNSA 1997 Section 6", "title": "Prohibition of Narcotic Substances", "description": "No person shall produce, manufacture, possess, sell, purchase, or transport any narcotic substance", "penalty": "Varies by quantity and substance"},
            {"section": "CNSA 1997 Section 9(a)", "title": "Possession of Small Quantity", "description": "Possession of narcotic substance up to 100 grams", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "CNSA 1997 Section 9(b)", "title": "Possession of Intermediate Quantity", "description": "Possession of narcotic substance 100g to 1kg", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "CNSA 1997 Section 9(c)", "title": "Trafficking / Large Quantity", "description": "Possession or trafficking of narcotic substance exceeding 1 kg", "penalty": "Death penalty or life imprisonment and fine up to Rs. 1 million"},
            {"section": "CNSA 1997 Section 14", "title": "Financing Narcotic Operations", "description": "Financing or managing operations involving narcotic substances", "penalty": "Death penalty or life imprisonment and fine"},
        ],
        "procedure": [
            "If falsely accused: Hire a criminal lawyer immediately — do NOT make any statement without lawyer",
            "Request bail if arrested for small quantity (Section 9(a) is bailable)",
            "Challenge any illegal search or seizure",
            "For rehabilitation: Contact Anti-Narcotics Force helpline for treatment options",
            "If someone you know is addicted: Contact rehabilitation centers",
            "Challenge prosecution if mandatory weighing/testing procedures were not followed",
        ],
    },

    # ─────────────────────────────────────────
    # 22. CORRUPTION / BRIBERY
    # ─────────────────────────────────────────
    "corruption_bribery": {
        "label": "Corruption / Bribery / Government Misconduct",
        "sources": ["Pakistan Penal Code", "National Accountability Ordinance 1999", "Prevention of Corruption Act 1947"],
        "laws": [
            {"section": "PPC Section 161", "title": "Public Servant Taking Gratification (Bribery)", "description": "Public servant who accepts or obtains gratification other than legal remuneration as a motive for doing or forbearing to do an official act", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 162", "title": "Taking Gratification to Influence Public Servant", "description": "Whoever accepts gratification to influence a public servant", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 165", "title": "Public Servant Obtaining Valuable Thing Without Consideration", "description": "Public servant who accepts valuable thing without adequate consideration from a person with whom they have official dealings", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "National Accountability Ordinance 1999", "title": "NAB Jurisdiction (Major Corruption)", "description": "NAB handles corruption cases involving Rs. 500 million or more. Covers corruption, corrupt practices, and misuse of authority by public office holders", "penalty": "Up to 14 years imprisonment + fine + disqualification from public office + forfeiture of property"},
            {"section": "Prevention of Corruption Act 1947 Section 5", "title": "Criminal Misconduct by Public Servant", "description": "Public servant who uses corrupt or illegal means, obtains pecuniary advantage, or possesses assets beyond known income", "penalty": "1-7 years imprisonment and fine"},
        ],
        "procedure": [
            "Collect evidence: recordings, messages, witness statements, transaction records",
            "File complaint with Anti-Corruption Establishment of your province",
            "For federal government officials: File with NAB (National Accountability Bureau)",
            "File FIR at police station under PPC 161/162",
            "Use Pakistan Citizen Portal (citizenportal.gov.pk) to report corruption",
            "Contact the relevant Ombudsman (Federal/Provincial) for maladministration",
        ],
    },

    # ─────────────────────────────────────────
    # 23. CORPORATE / BUSINESS LAW
    # ─────────────────────────────────────────
    "corporate_business": {
        "label": "Corporate / Business / Partnership Disputes",
        "sources": ["Companies Act 2017", "Partnership Act 1932", "SECP"],
        "laws": [
            {"section": "Companies Act 2017 Section 253", "title": "Oppression of Minority Shareholders", "description": "Shareholders can petition court if company affairs conducted in oppressive manner prejudicial to interests of members", "penalty": "Court can order winding up, regulation of conduct, purchase of shares"},
            {"section": "Companies Act 2017 Section 132", "title": "Director's Duties and Liabilities", "description": "Directors must act in good faith, in interests of company, exercise due care and diligence", "penalty": "Personal liability for breach of duty; fine up to Rs. 25 million"},
            {"section": "Partnership Act 1932 Section 44", "title": "Dissolution of Partnership", "description": "Partnership dissolved by agreement, expiry of term, death, or court order", "penalty": "N/A — dissolution and settlement of accounts"},
            {"section": "Partnership Act 1932 Section 46", "title": "Settlement of Accounts", "description": "Upon dissolution, partnership property used to pay debts, then surplus distributed", "penalty": "Court-ordered settlement if partners disagree"},
            {"section": "SECP Regulations", "title": "SECP Complaints", "description": "SECP handles complaints against companies for non-compliance, fraud, and corporate governance issues", "penalty": "Fines, penalties, director disqualification"},
        ],
        "procedure": [
            "Review partnership deed or company articles of association",
            "Send legal notice to the other party/directors",
            "File complaint with SECP for corporate governance violations",
            "For partnership disputes: File suit in Civil Court under Partnership Act",
            "For shareholder oppression: Petition under Section 253 of Companies Act",
            "Gather documents: partnership deed, share certificates, financial statements, correspondence",
        ],
    },

    # ─────────────────────────────────────────
    # 24. ENVIRONMENTAL LAW
    # ─────────────────────────────────────────
    "environmental": {
        "label": "Environmental / Pollution / Illegal Construction",
        "sources": ["Pakistan Environmental Protection Act 1997", "Pakistan Penal Code"],
        "laws": [
            {"section": "Pakistan Environmental Protection Act 1997 Section 11", "title": "Prohibition of Pollution", "description": "No person shall discharge or emit any pollutant in amount exceeding prescribed standards", "penalty": "Fine up to Rs. 1 million; additional Rs. 100,000 per day for continuing offence"},
            {"section": "Pakistan Environmental Protection Act 1997 Section 12", "title": "Environmental Impact Assessment", "description": "No project likely to cause adverse environmental effects shall commence without EIA approval", "penalty": "Fine up to Rs. 1 million and/or imprisonment"},
            {"section": "PPC Section 268", "title": "Public Nuisance", "description": "Act or omission causing common injury, danger, or annoyance to public", "penalty": "Fine up to Rs. 200"},
            {"section": "PPC Section 269", "title": "Negligent Act Likely to Spread Infection", "description": "Unlawfully or negligently doing act likely to spread disease", "penalty": "Up to 6 months imprisonment or fine or both"},
            {"section": "Local Government Ordinances", "title": "Building Code Violations", "description": "Illegal construction, building without approval, encroachment on public land", "penalty": "Demolition order + fine as per local government rules"},
        ],
        "procedure": [
            "Document the pollution/violation with photos, videos, and dates",
            "File complaint with relevant Environmental Protection Agency (EPA)",
            "For illegal construction: Complain to local municipal/town committee",
            "File with Environmental Tribunal for enforcement",
            "Public Interest Litigation can be filed in High Court",
            "Contact Pakistan Environmental Protection Agency helpline",
        ],
    },

    # ─────────────────────────────────────────
    # 25. POLICE MISCONDUCT
    # ─────────────────────────────────────────
    "police_misconduct": {
        "label": "Police Misconduct / False FIR / Custody Abuse",
        "sources": ["Pakistan Penal Code", "Police Order 2002", "Constitution of Pakistan"],
        "laws": [
            {"section": "PPC Section 166", "title": "Public Servant Disobeying Law", "description": "Public servant who knowingly disobeys direction of law with intent to cause injury", "penalty": "Up to 1 year imprisonment or fine or both"},
            {"section": "PPC Section 167", "title": "Framing Incorrect Document", "description": "Public servant who frames an incorrect document with intent to cause injury", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 330", "title": "Voluntarily Causing Hurt to Extort Confession", "description": "Police officer causing hurt to extort confession or information", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 342", "title": "Wrongful Confinement", "description": "Wrongfully confining any person including illegal detention by police", "penalty": "Up to 1 year imprisonment or fine up to Rs. 1,000 or both"},
            {"section": "PPC Section 182", "title": "False Information to Public Servant", "description": "Filing false FIR or giving false information to police", "penalty": "Up to 6 months imprisonment or fine up to Rs. 1,000 or both"},
            {"section": "Article 10-A Constitution", "title": "Right to Fair Trial", "description": "Every person has right to fair trial and due process", "penalty": "N/A — fundamental right; violated rights can be enforced through High Court"},
        ],
        "procedure": [
            "Document all incidents of misconduct with dates, times, officer names",
            "File written complaint with the Station House Officer (SHO) or SP/SSP",
            "If police refuses FIR, file application under Section 22-A CrPC in Sessions Court",
            "File complaint with Police Complaint Authority of your province",
            "For torture: Get medical examination and file FIR against the officers",
            "File writ petition in High Court for violation of fundamental rights",
            "Contact Human Rights Commission or a human rights lawyer",
        ],
    },

    # ─────────────────────────────────────────
    # 26. BAIL MATTERS
    # ─────────────────────────────────────────
    "bail_matters": {
        "label": "Bail Application / Bail Procedure",
        "sources": ["Code of Criminal Procedure 1898", "Pakistan Penal Code"],
        "laws": [
            {"section": "CrPC Section 496", "title": "Bail in Bailable Offences", "description": "In bailable offences, bail is a right. Police must release on bail upon furnishing surety", "penalty": "N/A — accused has right to bail in bailable cases"},
            {"section": "CrPC Section 497", "title": "Bail in Non-Bailable Offences", "description": "Court may grant bail in non-bailable offences if there are reasonable grounds to believe accused is not guilty, or further inquiry is needed", "penalty": "N/A — discretionary bail; court considers flight risk, evidence, case severity"},
            {"section": "CrPC Section 498", "title": "Bail After Arrest by Police", "description": "High Court or Court of Session may direct that any person accused and in custody be released on bail", "penalty": "N/A — higher court bail provision"},
            {"section": "CrPC Section 497-A", "title": "Pre-Arrest Bail (Anticipatory Bail)", "description": "Person who apprehends arrest may apply for pre-arrest bail. Court may grant with conditions", "penalty": "N/A — protective bail before arrest; can have conditions attached"},
            {"section": "CrPC Section 499", "title": "Bail Bond Amount and Sureties", "description": "Court determines bail bond amount and number of sureties required", "penalty": "N/A — bail conditions set by court"},
        ],
        "procedure": [
            "Determine if the offence is bailable or non-bailable",
            "For bailable offence: Demand bail at police station itself as a right",
            "For non-bailable: File bail application through advocate in Sessions Court or High Court",
            "For pre-arrest bail: File application before arrest in Sessions Court or High Court",
            "Arrange surety (guarantor) and bail bond amount as directed by court",
            "After bail, comply with all conditions: attend hearings, don't leave jurisdiction",
            "If bail denied by Sessions Court, appeal to High Court",
        ],
    },

    # ─────────────────────────────────────────
    # 27. BANKING FRAUD
    # ─────────────────────────────────────────
    "banking_fraud": {
        "label": "Banking Fraud / ATM Fraud / Financial Scam",
        "sources": ["Prevention of Electronic Crimes Act 2016", "Pakistan Penal Code", "State Bank of Pakistan Regulations"],
        "laws": [
            {"section": "PECA 2016 Section 14", "title": "Electronic Fraud", "description": "Using information system to commit fraud or obtain money/property by false representation", "penalty": "Up to 2 years imprisonment or fine up to Rs. 10 million or both"},
            {"section": "PECA 2016 Section 16", "title": "Identity Theft / Unauthorized Use of Identity", "description": "Using another person's identity or financial information without authorization", "penalty": "Up to 3 years imprisonment or fine up to Rs. 5 million or both"},
            {"section": "PPC Section 420", "title": "Cheating and Fraud", "description": "Cheating and dishonestly inducing delivery of property/money", "penalty": "Up to 7 years imprisonment and fine"},
            {"section": "PPC Section 406", "title": "Criminal Breach of Trust", "description": "Bank employee or agent misappropriating entrusted funds", "penalty": "Up to 3 years imprisonment or fine or both"},
            {"section": "PPC Section 468", "title": "Forgery for Purpose of Cheating", "description": "Forging bank documents, signatures, or financial instruments", "penalty": "Up to 7 years imprisonment and fine"},
        ],
        "procedure": [
            "Contact your bank IMMEDIATELY to block the account/card",
            "File complaint with the bank's complaint cell in writing",
            "File FIR at nearest police station under PPC 420 and PECA 2016",
            "File complaint with FIA Cyber Crime Wing (nr3c.gov.pk) for online/ATM fraud",
            "File complaint with State Bank of Pakistan Banking Mohtasib (Ombudsman)",
            "Gather evidence: bank statements, transaction records, SMS alerts, screenshots",
            "Request CCTV footage from ATM location if ATM fraud",
        ],
    },

    "general_criminal": {
        "label": "General Criminal Law",
        "sources": ["Pakistan Penal Code 1860", "Code of Criminal Procedure 1898"],
        "laws": [
            {"section": "PPC Section 34", "title": "Common Intention", "description": "When a criminal act is done by several persons in furtherance of the common intention of all, each is liable as if done alone", "penalty": "Same as the principal offense"},
            {"section": "PPC Section 107", "title": "Abetment", "description": "Instigating, engaging in conspiracy, or intentionally aiding by act or illegal omission", "penalty": "Same as the abetted offense if committed"},
            {"section": "PPC Section 120-B", "title": "Criminal Conspiracy", "description": "Two or more persons agree to do or cause to be done an illegal act or legal act by illegal means", "penalty": "Same as abetment of the offense"},
            {"section": "PPC Section 182", "title": "False Information to Public Servant", "description": "Giving false information to a public servant to use their lawful power to injure another", "penalty": "Up to 6 months imprisonment or fine up to Rs. 1,000 or both"},
            {"section": "PPC Section 504", "title": "Intentional Insult / Provocation", "description": "Intentional insult with intent to provoke breach of peace", "penalty": "Up to 2 years imprisonment or fine or both"},
            {"section": "PPC Section 506", "title": "Criminal Intimidation", "description": "Threatening another with injury to person, reputation, or property", "penalty": "Up to 2 years imprisonment or fine or both; up to 7 years if threat of death or grievous hurt"},
        ],
        "procedure": [
            "Report the matter to the nearest police station",
            "File an FIR (First Information Report) under the relevant PPC section",
            "Gather and preserve all evidence (witnesses, documents, photos, recordings)",
            "Consult a criminal lawyer for legal advice",
            "If police refuse to file FIR, approach the Sessions Judge under CrPC Section 22-A",
            "Follow up with the Investigation Officer assigned to your case",
        ],
    },
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 1: AI CLASSIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def classify_question_ai(question: str) -> Optional[str]:
    """Use Gemini to classify into correct legal category."""
    model = _get_gemini_model()
    if model is None:
        return None
    try:
        response = model.generate_content(CLASSIFICATION_PROMPT.format(question=question))
        raw = response.text.strip().lower()
        category = re.sub(r'[^a-z_]', '', raw)
        if category in VALID_CATEGORIES:
            logger.info(f"AI classified '{question[:60]}' -> {category}")
            return category
        else:
            logger.warning(f"AI returned invalid category '{raw}', falling back")
            return None
    except Exception as e:
        logger.error(f"AI classification failed: {e}")
        return None


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# KEYWORD FALLBACK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

KEYWORD_MAP = {
    "traffic_accident": ["hit and run", "ran away after hitting", "car accident", "road accident", "reckless driving", "traffic accident", "traffic violation", "vehicle accident", "motorcycle accident", "bus accident", "truck accident", "crash", "collision", "knocked down", "pedestrian hit", "over speeding", "signal violation", "drunk driving", "hit someone with", "hit with my car", "hit by a car", "ran over"],
    "theft_robbery": ["theft", "stolen", "robbed", "robbery", "snatched", "dacoity", "burglary", "stole", "steal", "looted", "pickpocket", "mobile snatched", "phone stolen", "shoplifting", "house robbery", "armed robbery", "break in"],
    "land_property_fraud": ["land sold", "property sold", "sold without", "without consent", "fake deed", "forged deed", "qabza", "zameen", "illegal transfer", "took over my land", "uncle sold", "brother sold", "relative sold", "property fraud", "benami", "sell it to someone", "grabbed my land", "occupied my property", "encroached", "land grab", "land dispute", "property dispute", "land mafia"],
    "property_tenancy": ["tenant", "landlord", "rent", "evict", "eviction", "lease", "kicked out", "rented", "rental", "security deposit", "deposit not returned", "tenancy", "paying guest"],
    "family_law": ["divorce", "talaq", "khula", "custody", "maintenance", "marriage", "nikah", "dower", "mehr", "alimony", "iddat", "child custody", "family court", "separation", "nikkah", "rukhsati", "haq mehr"],
    "labor_law": ["salary", "wages", "fired", "terminated", "employer", "overtime", "worker", "eobi", "gratuity", "unpaid salary", "not paid salary", "fired without notice", "wrongful termination", "unfair dismissal", "work conditions", "labour", "labor rights", "employment", "pension"],
    "murder_assault": ["murder", "killed", "stabbed", "shot", "shooting", "attacked with", "attacked me", "assault", "attempt to murder", "qatl", "homicide", "manslaughter", "grievous hurt", "knife", "weapon", "beaten up", "beat up"],
    "harassment": ["harassment", "harass", "stalking", "threatening", "acid attack", "sexual harassment", "workplace harassment", "harassed at work", "being harassed", "intimidation", "threaten"],
    "domestic_violence": ["domestic violence", "wife beaten", "husband abuse", "in-law torture", "spouse torture", "beats me", "hits me", "marital violence", "husband beats", "wife beating", "tortured by in-laws", "dowry violence", "abused by husband", "abused by wife"],
    "sexual_offenses": ["rape", "raped", "sexual assault", "molestation", "molested", "gang rape", "sexually abused", "sexually assaulted", "sodomy", "indecent assault", "sexual abuse"],
    "child_rights": ["child abuse", "child labor", "child labour", "minor abuse", "child exploitation", "juvenile", "child abused", "abused by teacher", "child beaten", "underage", "child marriage", "child trafficking", "child neglect", "child protection", "child was abused", "abused child", "minor abused"],
    "cyber_crime": ["hacking", "hacked", "online fraud", "identity theft", "phishing", "social media", "fake account", "revenge porn", "sextortion", "blackmail", "blackmailing", "cyber bullying", "online harassment", "data theft", "cyber stalking", "email hack", "account hacked"],
    "cheque_bounce": ["cheque bounce", "bounced cheque", "dishonoured cheque", "check bounce", "cheque dishonour", "cheque", "bounced", "dishonored check", "bad cheque", "cheque returned"],
    "contract_dispute": ["breach of contract", "contract broken", "agreement broken", "contract dispute", "contract not honored", "terms violated", "breached", "agreement violated", "broke the agreement", "broke the contract", "violated terms", "contract violation", "agreement dispute", "breached our"],
    "consumer_protection": ["defective product", "warranty", "overcharged", "fake product", "consumer", "refund", "return policy", "faulty", "defective", "poor quality", "product complaint", "bought a defective", "misleading advertisement"],
    "defamation": ["defamation", "false accusation", "character assassination", "slander", "libel", "damaging reputation", "false rumors", "spread rumors", "false statement", "defaming", "maligned", "tarnished reputation", "false allegation", "rumors about me"],
    "inheritance_succession": ["inheritance", "will", "succession", "ancestral property", "share in property", "heir", "heirship", "denied share", "property after death", "divided after death", "wirasat", "jaidad", "property distribution", "death of father", "death of parent"],
    "debt_recovery": ["money owed", "loan not returned", "not paying back", "borrowed money", "debt", "recovery of money", "owes me money", "refuses to pay", "loan recovery", "unpaid loan", "not returning money", "lent money", "gave money"],
    "medical_negligence": ["doctor negligence", "wrong treatment", "medical malpractice", "hospital negligence", "surgical error", "wrong diagnosis", "died in hospital", "wrong operation", "wrong organ", "medical error", "doctor mistake", "hospital mistake", "patient died", "negligent doctor"],
    "kidnapping_abduction": ["kidnap", "kidnapped", "kidnapping", "abduct", "abducted", "abduction", "missing person", "ransom", "taken away", "snatched child", "child missing"],
    "drug_offenses": ["drugs", "narcotics", "heroin", "hashish", "charas", "drug possession", "drug trafficking", "drug found", "found drugs", "drug dealer", "drug peddler", "substance abuse", "controlled substance", "opium", "cocaine", "ice drug", "crystal meth"],
    "corruption_bribery": ["bribery", "bribe", "corruption", "kickback", "government corruption", "misuse of authority", "demanded bribe", "gave bribe", "corrupt official", "abuse of power", "nab", "ehtesab"],
    "corporate_business": ["company registration", "register a company", "company dispute", "shareholder", "partnership", "director", "secp", "business fraud", "company fraud", "incorporate", "business registration", "startup", "llc", "private limited", "firm registration"],
    "environmental": ["pollution", "illegal construction", "noise pollution", "water contamination", "factory waste", "tree cutting", "encroachment", "polluting", "waste dumping", "air pollution", "environmental damage", "river pollution", "deforestation"],
    "police_misconduct": ["false fir", "police torture", "illegal detention", "custodial abuse", "police not filing", "police corruption", "police beating", "police refused", "arrested without warrant", "without warrant", "without a warrant", "illegal arrest", "police brutality", "fake case by police", "police misconduct", "police arrested", "arrested me"],
    "bail_matters": ["bail", "bail application", "pre-arrest bail", "bail procedure", "how to get bail", "arrest bail", "anticipatory bail", "post-arrest bail", "bail bond", "apply for bail"],
    "banking_fraud": ["bank fraud", "atm fraud", "unauthorized transaction", "credit card fraud", "online banking fraud", "atm card cloned", "cloned card", "cloned my atm", "bank scam", "wire fraud", "debit card fraud", "banking scam", "money withdrawn"],
}


def classify_question_keywords(question: str) -> str:
    """Keyword-based fallback classification."""
    q = question.lower()
    scores: Dict[str, float] = {}
    for category, keywords in KEYWORD_MAP.items():
        score = 0.0
        for kw in keywords:
            if ' ' in kw and kw in q:
                score += 4.0
            elif ' ' not in kw and re.search(r'\b' + re.escape(kw) + r'\b', q):
                score += 2.0
        if score > 0:
            scores[category] = score

    if not scores:
        return "general_criminal"  # fallback when no keywords match

    PRIORITY = [
        "land_property_fraud", "traffic_accident", "murder_assault", "sexual_offenses",
        "domestic_violence", "kidnapping_abduction", "harassment", "cyber_crime",
        "cheque_bounce", "family_law", "labor_law", "property_tenancy",
        "theft_robbery", "medical_negligence", "drug_offenses", "consumer_protection",
        "contract_dispute", "defamation", "inheritance_succession", "debt_recovery",
        "corruption_bribery", "police_misconduct", "bail_matters", "banking_fraud",
        "corporate_business", "environmental", "general_criminal",
    ]

    max_score = max(scores.values())
    top = [c for c, s in scores.items() if s >= max_score - 2.0]
    if len(top) > 1:
        for p in PRIORITY:
            if p in top:
                return p
    return max(scores, key=scores.get)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def detect_category(question: str) -> str:
    """Two-step: AI classification first, keyword fallback if AI fails."""
    ai_result = classify_question_ai(question)
    if ai_result:
        return ai_result
    kw_result = classify_question_keywords(question)
    logger.info(f"Keyword fallback: '{question[:60]}' -> {kw_result}")
    return kw_result


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RETRIEVAL + ANSWER GENERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def get_laws_for_category(category: str) -> List[dict]:
    if category not in LEGAL_KNOWLEDGE_BASE:
        return LEGAL_KNOWLEDGE_BASE["murder_assault"]["laws"]
    return LEGAL_KNOWLEDGE_BASE[category]["laws"]


def get_procedure_for_category(category: str) -> List[str]:
    if category not in LEGAL_KNOWLEDGE_BASE:
        return LEGAL_KNOWLEDGE_BASE["murder_assault"]["procedure"]
    return LEGAL_KNOWLEDGE_BASE[category]["procedure"]


def get_category_label(category: str) -> str:
    if category not in LEGAL_KNOWLEDGE_BASE:
        return "Criminal Law"
    return LEGAL_KNOWLEDGE_BASE[category]["label"]


def get_category_sources(category: str) -> List[str]:
    if category not in LEGAL_KNOWLEDGE_BASE:
        return LEGAL_KNOWLEDGE_BASE["murder_assault"]["sources"]
    return LEGAL_KNOWLEDGE_BASE[category]["sources"]


def format_laws_for_prompt(laws: List[dict]) -> str:
    lines = []
    for law in laws:
        lines.append(f"- {law['section']}: {law['title']}")
        lines.append(f"  {law['description']}")
        lines.append(f"  Penalty: {law['penalty']}")
        lines.append("")
    return "\n".join(lines)


_ANALYSIS_INTROS = {
    "traffic_accident": "Traffic accidents including hit-and-run are governed by the Motor Vehicles Ordinance 1965 and the Pakistan Penal Code (PPC). The driver who caused the accident can be prosecuted under multiple laws.",
    "theft_robbery": "Theft, robbery, and snatching are cognizable criminal offences under the Pakistan Penal Code. Punishment severity depends on whether force or weapons were used.",
    "land_property_fraud": "Land/property fraud — illegal sale without owner's consent, forged documents, and fraudulent transfers — are serious criminal offences under the PPC. Both criminal prosecution and civil remedies are available.",
    "property_tenancy": "Property and tenancy disputes are governed by the Rent Restriction Ordinance 1959, Transfer of Property Act 1882, and relevant PPC sections.",
    "family_law": "Family matters including divorce, maintenance, and custody are governed by the Muslim Family Laws Ordinance 1961 and Family Courts Act 1964.",
    "labor_law": "Employment and wage disputes are governed by the Payment of Wages Act 1936, Industrial Relations Act 2012, and other labour statutes.",
    "murder_assault": "Murder, attempted murder, and assault are the most serious criminal offences under the Pakistan Penal Code 1860.",
    "harassment": "Harassment, stalking, and threats are punishable under the Protection Against Harassment Act 2010, PPC, and PECA 2016.",
    "domestic_violence": "Domestic violence is a criminal offence in Pakistan. Victims are protected under the Domestic Violence Act 2012 and provincial protection laws.",
    "sexual_offenses": "Sexual offences including rape are among the most serious crimes under Pakistani law. The Anti-Rape Act 2021 provides enhanced punishments and faster trial procedures.",
    "child_rights": "Child abuse, child labor, and offences against minors are dealt with severely under Pakistani law including the Zainab Alert Act 2020.",
    "cyber_crime": "Cyber crimes are governed by the Prevention of Electronic Crimes Act (PECA) 2016. The FIA Cyber Crime Wing handles investigation.",
    "cheque_bounce": "A dishonoured cheque is both a civil and criminal matter in Pakistan under the Negotiable Instruments Act 1881 and PPC Section 489-F.",
    "contract_dispute": "Contract disputes are governed by the Contract Act 1872 and Specific Relief Act 1877. Remedies include compensation and specific performance.",
    "consumer_protection": "Consumer rights are protected under provincial Consumer Protection Acts. Consumers can file complaints in Consumer Courts for defective products and unfair practices.",
    "defamation": "Defamation in Pakistan can be pursued as both a criminal offence (PPC 499-500) and a civil action (Defamation Ordinance 2002).",
    "inheritance_succession": "Inheritance for Muslims is governed by Islamic Shariat law. Women have a guaranteed right to inheritance share that cannot be denied by custom.",
    "debt_recovery": "Debt recovery can be pursued through civil courts, summary suits, and in cases of fraud, through criminal complaints.",
    "medical_negligence": "Medical negligence leading to death or injury can be prosecuted under PPC and addressed through PMDC complaints and consumer courts.",
    "kidnapping_abduction": "Kidnapping and abduction are serious offences under the PPC with severe penalties, especially when ransom is demanded.",
    "drug_offenses": "Drug offences are governed by the Control of Narcotic Substances Act 1997 with penalties ranging from fines to death penalty based on quantity.",
    "corruption_bribery": "Corruption and bribery by public servants are punishable under the PPC and NAB Ordinance 1999.",
    "corporate_business": "Corporate and business disputes are governed by the Companies Act 2017, Partnership Act 1932, and SECP regulations.",
    "environmental": "Environmental violations are addressed under the Pakistan Environmental Protection Act 1997 and can be reported to provincial EPAs.",
    "police_misconduct": "Police misconduct including false FIR, torture, and illegal detention are punishable under the PPC and can be challenged in court.",
    "bail_matters": "Bail in Pakistan is governed by CrPC. Bail is a right in bailable offences and discretionary in non-bailable offences.",
    "banking_fraud": "Banking and financial fraud are covered under PECA 2016 and PPC. Victims should immediately contact their bank and FIA Cyber Crime Wing.",
    "general_criminal": "General criminal matters in Pakistan are governed by the Pakistan Penal Code 1860 and procedural matters by the Code of Criminal Procedure 1898.",
}


def build_legal_answer(question: str, category: str) -> Dict:
    """Build structured legal answer using ONLY laws from detected category."""
    laws = get_laws_for_category(category)
    procedure = get_procedure_for_category(category)
    label = get_category_label(category)
    sources = get_category_sources(category)

    analysis = f"Your question falls under **{label}** in Pakistani law. "
    analysis += _ANALYSIS_INTROS.get(category, _ANALYSIS_INTROS["murder_assault"])

    law_lines = []
    for law in laws:
        law_lines.append(f"**{law['section']}** — {law['title']}")
        law_lines.append(f"   {law['description']}")
        if not law['penalty'].startswith("N/A"):
            law_lines.append(f"   Penalty: {law['penalty']}")
        law_lines.append("")

    steps_lines = [f"{i+1}. {step}" for i, step in enumerate(procedure)]

    penalty_lines = []
    for law in laws:
        p = law['penalty']
        if not p.startswith("N/A") and not p.startswith("Defined") and not p.startswith("Court"):
            penalty_lines.append(f"- **{law['section']}**: {p}")

    full_answer = f"**LEGAL ANALYSIS**\n{analysis}\n\n"
    full_answer += "**APPLICABLE LAW SECTIONS**\n" + "\n".join(law_lines) + "\n"
    full_answer += "**WHAT YOU MUST DO (Step by Step)**\n" + "\n".join(steps_lines) + "\n\n"
    if penalty_lines:
        full_answer += "**PUNISHMENT THE OFFENDER FACES**\n" + "\n".join(penalty_lines) + "\n\n"
    full_answer += (
        "**DISCLAIMER**\n"
        "This is general legal information under Pakistani law. "
        "For your specific case, consult a qualified advocate. "
        "Evidence and circumstances affect all outcomes."
    )

    return {
        "answer": full_answer,
        "category": category,
        "category_label": label,
        "sources": sources,
        "sections": [law['section'] for law in laws],
        "procedure": procedure,
        "confidence": 95.0,
    }
