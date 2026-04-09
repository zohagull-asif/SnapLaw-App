"""Seed all data into citizen SQLite database."""
from citizen_db import init_db, SessionLocal, GuidanceArticle, JusticeStat, CaseTypeStat, QuizQuestion, FAQ
from datetime import datetime

def seed_all():
    init_db()
    db = SessionLocal()

    # Clear existing data
    db.query(GuidanceArticle).delete()
    db.query(JusticeStat).delete()
    db.query(CaseTypeStat).delete()
    db.query(QuizQuestion).delete()
    db.query(FAQ).delete()
    db.commit()

    # ─── GUIDANCE ARTICLES ───
    articles = [
        # Marriage & Family
        GuidanceArticle(category="marriage_family", title="Your Rights in Marriage (Nikah)",
            content="In Pakistan, every person has the right to marry with their own free consent. No one can force you into a marriage. Key rights: (1) Haq Mehr is mandatory — husband must pay the agreed amount. (2) Wife has the right to include conditions in the Nikah Nama. (3) Both husband and wife must sign the Nikah Nama.",
            relevant_law="Muslim Family Laws Ordinance 1961"),
        GuidanceArticle(category="marriage_family", title="Your Rights in Divorce",
            content="Husband can give Talaq but must give written notice to Union Council within 30 days. Wife can seek Khula through Family Court. After divorce, wife is entitled to: unpaid Mehr, maintenance during iddat (3 months), and custody of young children.",
            relevant_law="Muslim Family Laws Ordinance 1961, Family Courts Act 1964"),
        GuidanceArticle(category="marriage_family", title="Child Custody Rights",
            content="Mother has the right to custody of sons up to age 7 and daughters up to puberty. After these ages, father gets custody but child's welfare is the primary consideration. Either parent can apply to Family Court for custody.",
            relevant_law="Guardians and Wards Act 1890"),
        GuidanceArticle(category="marriage_family", title="Inheritance Rights in Pakistan",
            content="Under Islamic law applied in Pakistan: Son gets double the share of daughter. Wife gets 1/8 share if children exist, 1/4 if no children. Daughter gets half of son's share. No one can be deprived of inheritance — it is their legal right.",
            relevant_law="Muslim Personal Law (Shariat) Application Act 1962"),

        # Property Rights
        GuidanceArticle(category="property_rights", title="Your Right to Own Property",
            content="Every citizen of Pakistan has the right to own property. Women have equal property rights under Pakistani law. No one can take your property without legal process and court order. If someone occupies your land illegally it is called Qabza — file FIR under PPC Section 441.",
            relevant_law="Transfer of Property Act 1882, PPC Section 441"),
        GuidanceArticle(category="property_rights", title="Protection Against Illegal Sale of Your Property",
            content="No one can sell your property without your written consent — not even a family member. Illegal sale = fraud under PPC Section 420 (up to 7 years) and forgery under PPC 467 (up to 10 years). Immediately file FIR + apply for stay order in civil court to stop further transfer.",
            relevant_law="PPC 420, PPC 467, Specific Relief Act 1877"),
        GuidanceArticle(category="property_rights", title="Tenant Rights Against Illegal Eviction",
            content="Your landlord CANNOT evict you without a proper court order. Forceful eviction without notice is illegal. You are entitled to proper written notice before eviction. If landlord forcefully evicts you, file FIR under PPC 441 (Criminal Trespass). Go to Rent Controller court for protection.",
            relevant_law="Rent Restriction Ordinance 1959"),

        # Cybercrime
        GuidanceArticle(category="cybercrime_online", title="Protection Against Cyber Harassment",
            content="It is a crime to harass, stalk, or threaten someone online in Pakistan. This includes sending threatening messages, sharing someone's private photos without consent, or creating fake profiles. Report to FIA Cyber Crime Wing: www.fia.gov.pk or call 1991.",
            relevant_law="PECA 2016 Section 20 — up to 1 year imprisonment"),
        GuidanceArticle(category="cybercrime_online", title="Your Right Against Online Blackmail",
            content="If someone threatens to share your private photos or videos to extort money — this is a serious crime. Do NOT pay the blackmailer. Immediately report to FIA Cyber Crime Wing (1991). Save all evidence (screenshots). The blackmailer faces up to 7 years imprisonment.",
            relevant_law="PECA 2016 Section 21"),
        GuidanceArticle(category="cybercrime_online", title="Protection Against Identity Theft",
            content="Using someone else's CNIC, creating fake accounts in their name, or stealing personal data online is a crime. Victims can file complaint with NADRA and FIA Cyber Crime Wing.",
            relevant_law="PECA 2016 Section 16 — up to 3 years imprisonment"),

        # Harassment
        GuidanceArticle(category="harassment_rights", title="Protection Against Workplace Harassment",
            content="Every employee in Pakistan is protected from harassment at workplace. Your employer must have an Inquiry Committee. You can file complaint with the Ombudsperson for Protection Against Harassment. Harasser faces fine and dismissal.",
            relevant_law="Protection Against Harassment of Women at Workplace Act 2010"),
        GuidanceArticle(category="harassment_rights", title="Street Harassment is a Crime",
            content="Passing remarks, following, or making indecent gestures toward any person in public is illegal. Victims can file FIR at nearest police station.",
            relevant_law="PPC Section 509 — up to 3 years imprisonment + fine"),
        GuidanceArticle(category="harassment_rights", title="Domestic Violence Rights",
            content="Physical, emotional, or financial abuse by a family member is domestic violence and is illegal. Victims can apply for a protection order from the court. Police must respond to domestic violence calls. Shelter homes are available.",
            relevant_law="Punjab Protection of Women Against Violence Act 2016"),

        # Labor
        GuidanceArticle(category="labor_employment", title="Right to Timely Salary Payment",
            content="Your employer must pay your salary within 7 days after the end of each month. Non-payment is a criminal offense. File complaint with Labor Department or directly with Payment of Wages Authority.",
            relevant_law="Payment of Wages Act 1936 Section 5"),
        GuidanceArticle(category="labor_employment", title="Protection Against Unfair Dismissal",
            content="Your employer cannot fire you without proper notice or reason. You are entitled to: 1 month notice OR 1 month salary in lieu of notice. If wrongfully terminated, file case in Labour Court.",
            relevant_law="Industrial Relations Act 2012"),
        GuidanceArticle(category="labor_employment", title="Right to EOBI Pension",
            content="Every worker in Pakistan registered with EOBI is entitled to pension after retirement. Your employer must register you and pay monthly contributions. If employer is not paying EOBI, report to EOBI office.",
            relevant_law="Employees Old Age Benefits Act 1976"),

        # Criminal Justice
        GuidanceArticle(category="criminal_justice", title="Your Rights When Arrested",
            content="When arrested you have the right to: (1) Know the reason for arrest. (2) Remain silent. (3) Contact a lawyer immediately. (4) Not be tortured or mistreated. (5) Be presented before a magistrate within 24 hours. If police refuses lawyer access — file complaint with DIG/IGP.",
            relevant_law="CrPC Section 50, Article 10 Constitution of Pakistan"),
        GuidanceArticle(category="criminal_justice", title="How to File an FIR",
            content="Step 1: Go to the police station in whose area the crime occurred. Step 2: Tell the SHO (Station House Officer) what happened. Step 3: Police must register FIR — they CANNOT refuse. Step 4: Get a free copy of the FIR — it is your legal right. If police refuses FIR: go to DSP/SP office or directly to court under CrPC Section 200.",
            relevant_law="CrPC Section 154"),
        GuidanceArticle(category="criminal_justice", title="Right to Bail",
            content="For bailable offenses: police must grant bail. For non-bailable offenses: apply to Sessions Court or High Court for bail. Bail cannot be refused without valid reason. If bail denied — file bail revision petition in higher court.",
            relevant_law="CrPC Sections 496-502"),
    ]
    db.add_all(articles)

    # ─── JUSTICE STATS ───
    courts = [
        JusticeStat(court_type="Supreme Court of Pakistan", city="Islamabad", total_pending_cases=52847, avg_resolution_days=1825, cases_resolved_this_month=312, cases_filed_this_month=445),
        JusticeStat(court_type="Lahore High Court", city="Lahore", total_pending_cases=189432, avg_resolution_days=912, cases_resolved_this_month=1847, cases_filed_this_month=2103),
        JusticeStat(court_type="Sindh High Court", city="Karachi", total_pending_cases=145231, avg_resolution_days=876, cases_resolved_this_month=1234, cases_filed_this_month=1567),
        JusticeStat(court_type="Peshawar High Court", city="Peshawar", total_pending_cases=67834, avg_resolution_days=743, cases_resolved_this_month=892, cases_filed_this_month=1023),
        JusticeStat(court_type="Sessions Court Lahore", city="Lahore", total_pending_cases=43291, avg_resolution_days=456, cases_resolved_this_month=567, cases_filed_this_month=634),
        JusticeStat(court_type="Sessions Court Karachi", city="Karachi", total_pending_cases=38847, avg_resolution_days=423, cases_resolved_this_month=489, cases_filed_this_month=521),
        JusticeStat(court_type="Sessions Court Islamabad", city="Islamabad", total_pending_cases=12456, avg_resolution_days=398, cases_resolved_this_month=234, cases_filed_this_month=267),
        JusticeStat(court_type="Family Court Lahore", city="Lahore", total_pending_cases=28432, avg_resolution_days=365, cases_resolved_this_month=423, cases_filed_this_month=478),
        JusticeStat(court_type="Family Court Karachi", city="Karachi", total_pending_cases=24891, avg_resolution_days=334, cases_resolved_this_month=389, cases_filed_this_month=412),
        JusticeStat(court_type="Labour Court Punjab", city="Lahore", total_pending_cases=8432, avg_resolution_days=289, cases_resolved_this_month=156, cases_filed_this_month=178),
    ]
    db.add_all(courts)

    case_types = [
        CaseTypeStat(case_type="Criminal Cases", avg_days_to_resolve=547, success_rate_percent=68, total_cases_2023=145000),
        CaseTypeStat(case_type="Property Disputes", avg_days_to_resolve=892, success_rate_percent=54, total_cases_2023=89000),
        CaseTypeStat(case_type="Family Cases (Divorce)", avg_days_to_resolve=312, success_rate_percent=89, total_cases_2023=67000),
        CaseTypeStat(case_type="Labor Disputes", avg_days_to_resolve=234, success_rate_percent=71, total_cases_2023=34000),
        CaseTypeStat(case_type="Cybercrime Cases", avg_days_to_resolve=456, success_rate_percent=43, total_cases_2023=12000),
        CaseTypeStat(case_type="Bail Applications", avg_days_to_resolve=12, success_rate_percent=76, total_cases_2023=98000),
        CaseTypeStat(case_type="FIR Registration Issues", avg_days_to_resolve=45, success_rate_percent=82, total_cases_2023=23000),
    ]
    db.add_all(case_types)

    # ─── QUIZ QUESTIONS ───
    questions = [
        # Level 1 — Beginner
        QuizQuestion(level=1, question="What does FIR stand for?", option_a="Final Investigation Report", option_b="First Information Report", option_c="Federal Investigation Record", option_d="Formal Inquiry Report", correct_answer="b", explanation="FIR stands for First Information Report. It is filed at a police station to report a crime under CrPC Section 154.", category="Criminal Justice"),
        QuizQuestion(level=1, question="Which court handles divorce cases in Pakistan?", option_a="Supreme Court", option_b="High Court", option_c="Family Court", option_d="Sessions Court", correct_answer="c", explanation="Family Courts handle divorce, maintenance, custody cases under Family Courts Act 1964.", category="Family Law"),
        QuizQuestion(level=1, question="What is the punishment for theft under PPC?", option_a="1 year imprisonment", option_b="Up to 3 years imprisonment", option_c="5 years imprisonment", option_d="Only fine, no imprisonment", correct_answer="b", explanation="PPC Sections 378-382 cover theft. Maximum punishment is 3 years imprisonment.", category="Criminal Law"),
        QuizQuestion(level=1, question="Where do you report cybercrime in Pakistan?", option_a="Local police station only", option_b="NADRA office", option_c="FIA Cyber Crime Wing", option_d="Ministry of IT", correct_answer="c", explanation="FIA Cyber Crime Wing handles online crimes. Call 1991 or visit www.fia.gov.pk to file complaint.", category="Cybercrime"),
        QuizQuestion(level=1, question="What is Haq Mehr?", option_a="A type of divorce", option_b="Mandatory payment from husband to wife at marriage", option_c="Child custody right", option_d="Property inheritance share", correct_answer="b", explanation="Haq Mehr is the mandatory payment or gift from husband to wife as part of Nikah. It is her exclusive right under Islamic law.", category="Family Law"),
        QuizQuestion(level=1, question="How many hours does police have to present an arrested person before a magistrate?", option_a="12 hours", option_b="48 hours", option_c="24 hours", option_d="72 hours", correct_answer="c", explanation="Under Article 10 of Constitution and CrPC, police must present arrested person before magistrate within 24 hours.", category="Criminal Justice"),
        QuizQuestion(level=1, question="What is PECA 2016?", option_a="Property and Estate Control Act", option_b="Prevention of Electronic Crimes Act", option_c="Pakistan Economic Crimes Authority", option_d="Public Employment Code Act", correct_answer="b", explanation="PECA 2016 is Pakistan's cybercrime law covering online harassment, hate speech, cyber fraud.", category="Cybercrime"),
        QuizQuestion(level=1, question="Can police refuse to register an FIR?", option_a="Yes, if they think crime is minor", option_b="Yes, if no evidence", option_c="No, they must register it", option_d="Only if senior officer approves", correct_answer="c", explanation="Under CrPC Section 154, police MUST register an FIR. Refusal is illegal and you can complain to DSP or go directly to court.", category="Criminal Justice"),
        QuizQuestion(level=1, question="What is the minimum age for marriage in Pakistan?", option_a="14 years", option_b="16 years for girls, 18 for boys", option_c="18 years for everyone", option_d="21 years", correct_answer="b", explanation="Child Marriage Restraint Act sets minimum age at 16 for girls and 18 for boys.", category="Family Law"),
        QuizQuestion(level=1, question="What does Article 25 of Pakistan's Constitution guarantee?", option_a="Right to education", option_b="Freedom of speech", option_c="Equality of citizens before law", option_d="Right to property", correct_answer="c", explanation="Article 25 states all citizens are equal before law and entitled to equal protection.", category="Constitutional Law"),

        # Level 2 — Easy
        QuizQuestion(level=2, question="Under which law is workplace harassment addressed?", option_a="PPC Section 354", option_b="Protection Against Harassment of Women at Workplace Act 2010", option_c="PECA 2016", option_d="Labor Relations Act", correct_answer="b", explanation="The Protection Against Harassment of Women at Workplace Act 2010 requires organizations to have an Inquiry Committee for harassment complaints.", category="Labor Law"),
        QuizQuestion(level=2, question="What is Khula?", option_a="Type of property transfer", option_b="Divorce initiated by wife through court", option_c="Child custody agreement", option_d="Inheritance claim", correct_answer="b", explanation="Khula is the right of a wife to seek divorce through Family Court by returning her Mehr. The court can grant Khula even if husband disagrees.", category="Family Law"),
        QuizQuestion(level=2, question="Which section of PPC covers criminal intimidation/threats?", option_a="PPC 420", option_b="PPC 302", option_c="PPC 506", option_d="PPC 379", correct_answer="c", explanation="PPC Section 506 covers criminal intimidation — threatening someone with harm. Punishment up to 7 years imprisonment.", category="Criminal Law"),
        QuizQuestion(level=2, question="What is the time limit to file a wage complaint?", option_a="3 months", option_b="6 months", option_c="1 year", option_d="2 years", correct_answer="c", explanation="Under Payment of Wages Act 1936 Section 15, workers must file claim for unpaid wages within 1 year of the violation.", category="Labor Law"),
        QuizQuestion(level=2, question="What does Benami property mean?", option_a="Property owned by a woman", option_b="Property registered in someone else's name to hide true ownership", option_c="Government owned property", option_d="Inherited property", correct_answer="b", explanation="Benami means property held in another person's name while actual benefits go to someone else. Prohibited under Benami Transactions Act 2017.", category="Property Law"),
        QuizQuestion(level=2, question="Which court hears murder cases?", option_a="Family Court", option_b="Magistrate Court", option_c="Sessions Court", option_d="High Court", correct_answer="c", explanation="Sessions Court has jurisdiction over serious criminal cases including murder under PPC 302.", category="Criminal Justice"),
        QuizQuestion(level=2, question="What is the punishment for cyber harassment under PECA?", option_a="Only fine", option_b="6 months imprisonment", option_c="Up to 1 year + fine", option_d="Up to 5 years", correct_answer="c", explanation="PECA 2016 Section 20 provides punishment of up to 1 year imprisonment and/or fine for cyber harassment.", category="Cybercrime"),
        QuizQuestion(level=2, question="Can a tenant be evicted without court order?", option_a="Yes, if landlord gives 1 month notice", option_b="Yes, if rent is unpaid", option_c="No, court order is always required", option_d="Yes, if landlord owns the property", correct_answer="c", explanation="Under Rent Restriction Ordinance 1959, landlord must get court order before evicting tenant. Forceful eviction is illegal.", category="Property Law"),
        QuizQuestion(level=2, question="What is the right of a daughter in father's property?", option_a="No right — only sons inherit", option_b="Equal share as son", option_c="Half share of what son receives", option_d="One third share", correct_answer="c", explanation="Under Islamic inheritance law applied in Pakistan, daughter receives half the share of a son from father's property.", category="Family Law"),
        QuizQuestion(level=2, question="Where to complain if police refuse to register FIR?", option_a="Only to the same police station", option_b="Supreme Court directly", option_c="DSP/SP office or directly to Magistrate Court", option_d="NADRA office", correct_answer="c", explanation="If police refuse FIR, you can complain to District SP, or file complaint directly to Magistrate under CrPC Section 200.", category="Criminal Justice"),

        # Level 3 — Medium
        QuizQuestion(level=3, question="What is PPC Section 302?", option_a="Robbery with violence", option_b="Qatl-e-Amd — intentional murder", option_c="Causing death by negligence", option_d="Attempt to murder", correct_answer="b", explanation="PPC 302 is Qatl-e-Amd (intentional murder). Punishment is death penalty or life imprisonment under Qisas and Diyat law.", category="Criminal Law"),
        QuizQuestion(level=3, question="What is the limitation period to file a civil property suit?", option_a="1 year", option_b="6 years", option_c="12 years", option_d="No time limit", correct_answer="c", explanation="Under Limitation Act 1908, the general limitation for property suits is 12 years from the date the right to sue accrues.", category="Property Law"),
        QuizQuestion(level=3, question="What does CrPC Section 154 require?", option_a="Police to make arrests", option_b="Mandatory FIR registration when cognizable offense reported", option_c="Bail conditions", option_d="Court fees payment", correct_answer="b", explanation="CrPC 154 requires police to record information about any cognizable offense and register an FIR — it is not discretionary.", category="Criminal Justice"),
        QuizQuestion(level=3, question="What is Diyat in Pakistani law?", option_a="Type of property tax", option_b="Financial compensation paid to victim's family in murder cases", option_c="Court fee for filing cases", option_d="Divorce payment", correct_answer="b", explanation="Diyat is blood money — financial compensation paid to victim's heirs in Qatl cases. Amount is fixed by government each year.", category="Criminal Law"),
        QuizQuestion(level=3, question="Which section covers forgery of property documents?", option_a="PPC 406", option_b="PPC 420", option_c="PPC 467", option_d="PPC 380", correct_answer="c", explanation="PPC Section 467 covers forgery of valuable security, will, or property document. Punishment up to 10 years imprisonment.", category="Property Law"),
        QuizQuestion(level=3, question="What is a Stay Order?", option_a="Police order to stop someone leaving country", option_b="Court order temporarily stopping a legal action", option_c="Order to stay in custody", option_d="Bail condition", correct_answer="b", explanation="Stay order is an interim court order that temporarily prevents a party from taking action until the court hears the full case.", category="Civil Law"),
        QuizQuestion(level=3, question="Under MFLO 1961, how many days does a husband have to notify Union Council after giving Talaq?", option_a="7 days", option_b="15 days", option_c="30 days", option_d="90 days", correct_answer="c", explanation="Muslim Family Laws Ordinance 1961 Section 7 requires written notice to Chairman of Union Council within 30 days of Talaq.", category="Family Law"),
        QuizQuestion(level=3, question="What crime is committed when someone makes a fake sale deed for property?", option_a="Only civil wrong", option_b="Forgery under PPC 467 and fraud under PPC 420", option_c="Only PPC 420", option_d="Not a crime if registered", correct_answer="b", explanation="Fake sale deed involves both forgery (PPC 467 — up to 10 years) and cheating (PPC 420 — up to 7 years). Both apply simultaneously.", category="Property Law"),
        QuizQuestion(level=3, question="What is the Anti Terrorism Act 1997 mainly for?", option_a="Cybercrime only", option_b="Drug trafficking", option_c="Acts of terrorism and sectarian violence", option_d="White collar crime", correct_answer="c", explanation="ATA 1997 covers terrorism, sectarian violence, and acts intended to create fear in the public.", category="Criminal Law"),
        QuizQuestion(level=3, question="What is the role of NADRA in legal matters?", option_a="Handles property disputes", option_b="Issues and verifies national identity documents", option_c="Registers marriages", option_d="Issues driving licenses", correct_answer="b", explanation="NADRA (National Database and Registration Authority) issues CNICs and verifies identity documents which are crucial in many legal proceedings.", category="Administrative Law"),

        # Level 4 — Hard
        QuizQuestion(level=4, question="What is Qatl-bis-sabab under PPC?", option_a="Intentional murder", option_b="Death caused indirectly through negligent or unlawful act", option_c="Assisted suicide", option_d="Death during robbery", correct_answer="b", explanation="PPC Section 320 covers Qatl-bis-sabab — indirect killing through an unlawful act. Punishment is Diyat (financial compensation).", category="Criminal Law"),
        QuizQuestion(level=4, question="Under which constitutional article can a citizen directly approach High Court?", option_a="Article 10", option_b="Article 184", option_c="Article 199", option_d="Article 25", correct_answer="c", explanation="Article 199 gives High Court jurisdiction to issue writs (Habeas Corpus, Mandamus, etc.) for enforcement of fundamental rights.", category="Constitutional Law"),
        QuizQuestion(level=4, question="What is Habeas Corpus?", option_a="Type of property deed", option_b="Court order to produce a detained person before court", option_c="Divorce decree", option_d="Search warrant", correct_answer="b", explanation="Habeas Corpus (Latin: produce the body) is a writ requiring a person under arrest to be brought before a judge. Used against illegal detention.", category="Constitutional Law"),
        QuizQuestion(level=4, question="What does the Specific Relief Act 1877 allow?", option_a="Only monetary damages in disputes", option_b="Court to order specific performance of a contract or return of property", option_c="Criminal punishment for fraud", option_d="Automatic property transfer", correct_answer="b", explanation="Specific Relief Act allows courts to order the actual thing promised (return of property, performance of contract) rather than just money damages.", category="Civil Law"),
        QuizQuestion(level=4, question="What is the difference between cognizable and non-cognizable offense?", option_a="No difference", option_b="Cognizable = police can arrest without warrant; non-cognizable = needs court warrant", option_c="Cognizable = minor crime; non-cognizable = major crime", option_d="Cognizable = civil; non-cognizable = criminal", correct_answer="b", explanation="For cognizable offenses (murder, robbery), police can arrest and investigate without court warrant. For non-cognizable, prior magistrate permission needed.", category="Criminal Justice"),
        QuizQuestion(level=4, question="What is the limitation period for filing a criminal complaint?", option_a="No limit for serious crimes", option_b="6 months for minor offenses, no limit for serious crimes like murder", option_c="Always 1 year", option_d="Always 2 years", correct_answer="b", explanation="Under Limitation Act, minor criminal complaints must be filed within 6 months. Serious crimes like murder have no limitation period.", category="Criminal Justice"),
        QuizQuestion(level=4, question="What protection does Article 10-A of Constitution provide?", option_a="Right to education", option_b="Right to fair trial", option_c="Freedom of religion", option_d="Right to vote", correct_answer="b", explanation="Article 10-A (added by 18th Amendment) guarantees the right to a fair trial and due process of law for every citizen.", category="Constitutional Law"),
        QuizQuestion(level=4, question="Under Transfer of Property Act, what is required for valid sale of immovable property?", option_a="Only verbal agreement", option_b="Written agreement only", option_c="Written agreement + registration at Sub-Registrar office", option_d="Witness signatures only", correct_answer="c", explanation="Transfer of Property Act 1882 requires immovable property sale to be in writing AND registered at Sub-Registrar office to be legally valid.", category="Property Law"),
        QuizQuestion(level=4, question="What is the Benami Transactions (Prohibition) Act 2017?", option_a="Prohibits selling property to foreigners", option_b="Prohibits holding property in another person's name to hide true ownership", option_c="Bans overseas property purchase", option_d="Controls property prices", correct_answer="b", explanation="Benami Act 2017 prohibits and punishes holding property in fake/other names. Benami property can be confiscated by government.", category="Property Law"),
        QuizQuestion(level=4, question="What is Shajjah under Pakistani law?", option_a="Type of property dispute", option_b="Grievous hurt causing injury to bone or brain", option_c="Financial fraud", option_d="Type of divorce", correct_answer="b", explanation="PPC Section 337 defines Shajjah as causing hurt that reaches or exposes bone or causes brain injury. More serious than ordinary hurt.", category="Criminal Law"),

        # Level 5 — Expert
        QuizQuestion(level=5, question="What is the doctrine of res judicata?", option_a="Right to appeal in higher court", option_b="A matter already judicially decided cannot be tried again", option_c="Evidence gathered illegally is inadmissible", option_d="Judge must recuse from conflict of interest", correct_answer="b", explanation="Res judicata prevents the same dispute between same parties from being litigated again once finally decided. Prevents endless litigation.", category="Civil Procedure"),
        QuizQuestion(level=5, question="What is the difference between Section 302 and Section 304 PPC?", option_a="No difference", option_b="302 is intentional murder (Qatl-e-Amd); 304 is culpable homicide not amounting to murder", option_c="302 is robbery; 304 is theft", option_d="302 is attempt; 304 is completion", correct_answer="b", explanation="PPC 302 requires intention to kill. PPC 304 covers deaths where intention was to cause harm but not necessarily death — lesser punishment applies.", category="Criminal Law"),
        QuizQuestion(level=5, question="What constitutional provision protects against double jeopardy?", option_a="Article 10", option_b="Article 12", option_c="Article 13", option_d="Article 15", correct_answer="c", explanation="Article 13 of Constitution protects against double jeopardy — no person shall be prosecuted twice for the same offense.", category="Constitutional Law"),
        QuizQuestion(level=5, question="What is a Writ of Mandamus?", option_a="Order to release a prisoner", option_b="Order to a public authority to perform its legal duty", option_c="Order prohibiting lower court action", option_d="Order to transfer case to higher court", correct_answer="b", explanation="Mandamus compels a government body or official to perform a mandatory duty they are legally obligated to perform but have refused.", category="Constitutional Law"),
        QuizQuestion(level=5, question="What does PPC Section 499 cover?", option_a="Robbery", option_b="Defamation", option_c="Forgery", option_d="Kidnapping", correct_answer="b", explanation="PPC Section 499 defines defamation as making or publishing any imputation about a person intending to harm their reputation. Punishment under Section 500: up to 2 years.", category="Criminal Law"),
        QuizQuestion(level=5, question="What is the Qanun-e-Shahadat Order 1984?", option_a="Pakistan's criminal procedure code", option_b="Pakistan's law of evidence", option_c="Family law ordinance", option_d="Property registration law", correct_answer="b", explanation="Qanun-e-Shahadat Order 1984 is Pakistan's law of evidence — it governs what evidence is admissible in courts and how witnesses are examined.", category="Evidence Law"),
        QuizQuestion(level=5, question="What is the role of Diyat in compromise of murder cases?", option_a="No role — murder cannot be compromised", option_b="Heirs of victim can forgive killer in exchange for Diyat payment, ending criminal case", option_c="Only reduces sentence by half", option_d="Only applies to accidental death", correct_answer="b", explanation="Under Qisas and Diyat law, heirs of murder victim can forgive the killer (Afw) in exchange for Diyat payment. This legally ends the criminal case under PPC.", category="Criminal Law"),
        QuizQuestion(level=5, question="What is the Prevention of Corruption Act 1947 used for?", option_a="Drug trafficking", option_b="Prosecuting public officials for bribery and corruption", option_c="Tax evasion", option_d="Electoral fraud", correct_answer="b", explanation="Prevention of Corruption Act 1947 punishes public servants who accept bribes or misuse their position. NAB also prosecutes under NAB Ordinance 1999.", category="Administrative Law"),
        QuizQuestion(level=5, question="What is Suo Motu action?", option_a="Filing appeal in Supreme Court", option_b="Court takes action on its own without anyone filing a case", option_c="Government prosecution power", option_d="Police investigation power", correct_answer="b", explanation="Suo Motu (Latin: on its own motion) means a court, especially Supreme Court, takes notice of a matter without anyone filing a petition — based on news reports or public interest.", category="Constitutional Law"),
        QuizQuestion(level=5, question="What is the key difference between High Court and Supreme Court jurisdiction?", option_a="No difference", option_b="High Court hears first appeals and original jurisdiction; Supreme Court is final court of appeal", option_c="Supreme Court only handles criminal cases", option_d="High Court handles federal matters only", correct_answer="b", explanation="High Courts handle first appeals from lower courts and have original jurisdiction in their province. Supreme Court is Pakistan's final court of appeal — its decisions bind all courts in the country.", category="Constitutional Law"),
    ]
    db.add_all(questions)

    # ─── FAQs ───
    faqs = [
        FAQ(question="Can police arrest me without a warrant?", answer="For cognizable offenses (murder, robbery, theft), police CAN arrest without warrant. For non-cognizable offenses, they need a magistrate's warrant. You must be told the reason for arrest.", category="Criminal Justice"),
        FAQ(question="What should I do if someone threatens me online?", answer="(1) Screenshot all evidence immediately. (2) Do NOT delete the messages. (3) Report to FIA Cyber Crime Wing — call 1991 or visit fia.gov.pk. (4) File FIR at local police under PECA 2016.", category="Cybercrime"),
        FAQ(question="My employer hasn't paid salary for 2 months. What to do?", answer="(1) Send a written demand notice to employer. (2) File complaint with Labor Department of your province. (3) Apply to Payment of Wages Authority. (4) File case in Labour Court. Law: Payment of Wages Act 1936.", category="Labor Law"),
        FAQ(question="My landlord wants to forcefully evict me. What are my rights?", answer="Landlord CANNOT evict you without a court order. If he tries forceful eviction: call police and file FIR under PPC 441. Go to Rent Controller court for protection order. Law: Rent Restriction Ordinance 1959.", category="Property Law"),
        FAQ(question="How long does a typical court case take in Pakistan?", answer="It varies greatly. Family cases: 6 months to 2 years. Property disputes: 2-5 years. Criminal cases: 1-4 years. Supreme Court appeals: 3-7 years. These are averages — complex cases take much longer.", category="General"),
        FAQ(question="Can I represent myself in court without a lawyer?", answer="Yes. In Pakistan you have the right to represent yourself (called appearing 'in person'). However for serious criminal cases or complex matters, hiring an advocate is strongly recommended.", category="General"),
        FAQ(question="What is the difference between bail and parole?", answer="Bail is temporary release during trial before conviction. Parole is early release after conviction after serving part of sentence with conditions. Both require court approval.", category="Criminal Justice"),
        FAQ(question="My CNIC was used to take a loan without my knowledge. What to do?", answer="(1) Immediately report to NADRA. (2) File FIR for identity theft and fraud. (3) Report to FIA Cyber Crime Wing. (4) Notify the bank/institution where loan was taken. Law: PECA 2016 Section 16.", category="Cybercrime"),
        FAQ(question="Can a woman file for divorce in Pakistan?", answer="Yes. (1) Khula — wife can seek divorce through Family Court by returning Mehr. Court can grant even if husband disagrees. (2) Talaq-e-Tafwiz — if husband delegated divorce right in Nikah Nama. Law: Family Courts Act 1964, MFLO 1961.", category="Family Law"),
        FAQ(question="What is the process to get a Stay Order?", answer="(1) Hire an advocate. (2) File suit in Civil Court with application for temporary injunction. (3) Explain urgency to judge. (4) Court can issue ex-parte stay order same day in urgent cases. (5) Pay court fee and submit evidence of imminent harm.", category="Civil Law"),
    ]
    db.add_all(faqs)

    db.commit()
    db.close()
    print("✅ All seed data inserted successfully!")
    print(f"   - {len(articles)} guidance articles")
    print(f"   - {len(courts)} court statistics")
    print(f"   - {len(case_types)} case type statistics")
    print(f"   - {len(questions)} quiz questions (50 total)")
    print(f"   - {len(faqs)} FAQs")


if __name__ == "__main__":
    seed_all()
