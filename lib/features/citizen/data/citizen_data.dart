/// All Citizen Portal data — hardcoded, no backend needed.

// ─── GUIDANCE ARTICLES ───────────────────────────────────────────────
class GuidanceCategory {
  final String key;
  final String label;
  final String icon;
  final int color;
  final List<GuidanceArticle> articles;
  const GuidanceCategory({required this.key, required this.label, required this.icon, required this.color, required this.articles});
}

class GuidanceArticle {
  final String title;
  final String content;
  final String relevantLaw;
  const GuidanceArticle({required this.title, required this.content, required this.relevantLaw});
}

const List<GuidanceCategory> kGuidanceCategories = [
  GuidanceCategory(
    key: 'marriage_family',
    label: 'Marriage & Family',
    icon: '👫',
    color: 0xFFe74c3c,
    articles: [
      GuidanceArticle(
        title: 'Right to Marry with Consent',
        content: 'Under Pakistani law, every adult has the right to marry a person of their choice. Marriage without consent is legally invalid. A woman cannot be forced into marriage by family or guardians. The Muslim Family Laws Ordinance 1961 requires that both parties consent freely. Forced marriages can be challenged in court and declared void.',
        relevantLaw: 'Muslim Family Laws Ordinance 1961 | Pakistan Penal Code S. 498-B',
      ),
      GuidanceArticle(
        title: 'Divorce Rights (Khula & Talaq)',
        content: 'Both men and women have the right to divorce. A man may pronounce Talaq and must register it with the Union Council within 90 days. A woman can seek Khula through the court if the husband refuses to divorce. The court will dissolve the marriage in exchange for returning the dower (mehr). Custody of children under 7 (boys) and 16 (girls) typically stays with the mother.',
        relevantLaw: 'Muslim Family Laws Ordinance 1961 S.7 | Dissolution of Muslim Marriages Act 1939',
      ),
      GuidanceArticle(
        title: 'Child Custody Rights',
        content: 'Pakistani law gives custody priority based on the best interests of the child. Mothers generally have custody of young children. Fathers are the natural guardians for property matters. Courts can override any arrangement if the child\'s welfare demands it. Both parents retain visitation rights regardless of custody arrangements.',
        relevantLaw: 'Guardian and Wards Act 1890 | Muslim Family Laws Ordinance 1961',
      ),
      GuidanceArticle(
        title: 'Mehr (Dower) Rights',
        content: 'Mehr is a mandatory gift from husband to wife upon marriage. It becomes the wife\'s exclusive property. The husband cannot take it back. If unpaid, the wife can sue for it in court. Even after divorce, the wife retains the right to collect unpaid mehr. Courts regularly grant orders to recover mehr amounts.',
        relevantLaw: 'Muslim Family Laws Ordinance 1961 | Muslim Personal Law (Shariat) Application Act 1962',
      ),
      GuidanceArticle(
        title: 'Maintenance (Nafaqah) Rights',
        content: 'A husband is legally obligated to pay maintenance (Nafaqah) to his wife regardless of her financial status. This includes food, clothing, shelter, and medical expenses. After divorce, the husband must pay maintenance during the Iddat period (approximately 3 months). Children\'s maintenance is a separate obligation. If the husband fails to pay, the wife can file a case in the Family Court and the court can order attachment of the husband\'s salary or property.',
        relevantLaw: 'Muslim Family Laws Ordinance 1961 | Family Courts Act 1964 S.9',
      ),
      GuidanceArticle(
        title: 'Guardianship & Visiting Rights',
        content: 'Even when a mother has custody, the father retains the right to visit his children at reasonable times. Courts strongly discourage parents from using children as weapons in matrimonial disputes. Denying access to children without court order can be held in contempt. Either parent can apply to the Guardian Court for visitation schedules. The welfare and opinion of the child (if old enough) are key factors in court decisions.',
        relevantLaw: 'Guardian and Wards Act 1890 | Family Courts Act 1964',
      ),
    ],
  ),
  GuidanceCategory(
    key: 'property_rights',
    label: 'Property Rights',
    icon: '🏠',
    color: 0xFF3498db,
    articles: [
      GuidanceArticle(
        title: 'Women\'s Inheritance Rights',
        content: 'Under Pakistani law, women have a legally guaranteed right to inherit property. A daughter receives half the share of a son. A wife receives 1/8th of husband\'s estate if there are children, 1/4th if none. Depriving women of inheritance is a criminal offence under the Criminal Law Amendment Act 2019. Women can file a case to claim their rightful share.',
        relevantLaw: 'Muslim Personal Law (Shariat) Application Act 1962 | Criminal Law Amendment Act 2019',
      ),
      GuidanceArticle(
        title: 'Tenant Rights',
        content: 'Tenants in Pakistan have strong legal protections. A landlord cannot evict a tenant without proper legal notice and court proceedings. Rent increases must follow agreed terms. Tenants have the right to a safe and habitable dwelling. Arbitrary eviction without notice is illegal and can be challenged in Rent Controller courts.',
        relevantLaw: 'Rent Restriction Ordinance 2001 | Transfer of Property Act 1882',
      ),
      GuidanceArticle(
        title: 'Land Registration & Ownership',
        content: 'All property transfers in Pakistan must be registered with the Sub-Registrar\'s office. An unregistered sale deed is not legally enforceable. The buyer should verify title through Revenue Department records (Fard). Fraudulent property transfers are punishable under the Pakistan Penal Code. Always obtain a registered sale deed and mutation (Intiqal) in land records.',
        relevantLaw: 'Registration Act 1908 | Land Revenue Act 1967 | Transfer of Property Act 1882',
      ),
      GuidanceArticle(
        title: 'Protection from Illegal Encroachment',
        content: 'If someone encroaches on your land without legal authority, you have strong legal remedies. File a civil suit for possession in the Civil Court. Simultaneously, register an FIR for criminal trespass under PPC Section 447. You can also apply for an injunction (stay order) to stop construction immediately. The court can order demolition of illegal construction. Revenue Department officials (Patwari/Tehsildar) can also be notified for revenue record correction.',
        relevantLaw: 'Transfer of Property Act 1882 | Pakistan Penal Code S.447-448 | Civil Procedure Code Order 39',
      ),
      GuidanceArticle(
        title: 'Mortgage & Loan Rights',
        content: 'When a property is mortgaged, the mortgagor (borrower) retains possession and right to use the property unless agreed otherwise. The mortgagee (lender) cannot forcibly take possession without a court decree. If you default on a loan, the bank must follow the legal foreclosure process through courts or Banking Courts. You have the right to redeem your mortgage by paying the debt at any time before sale. Usurious (extremely high) interest rates can be challenged in court.',
        relevantLaw: 'Transfer of Property Act 1882 Ch.IV | Banking Courts (Recovery of Loans) Ordinance 2001',
      ),
    ],
  ),
  GuidanceCategory(
    key: 'cybercrime_online',
    label: 'Cybercrime & Online',
    icon: '💻',
    color: 0xFF9b59b6,
    articles: [
      GuidanceArticle(
        title: 'Online Harassment & Cyberstalking',
        content: 'Pakistan\'s PECA 2016 criminalizes online harassment, cyberstalking, and sending threatening messages. Punishment is up to 3 years imprisonment and/or fine up to Rs. 1 million. Victims can report to FIA Cyber Crime Wing online or in person. Collect screenshots and preserve evidence before reporting. Courts can issue restraining orders against harassers.',
        relevantLaw: 'Prevention of Electronic Crimes Act (PECA) 2016 S.24 & S.25',
      ),
      GuidanceArticle(
        title: 'Non-Consensual Image Sharing',
        content: 'Sharing someone\'s intimate images without consent is a serious crime in Pakistan. PECA 2016 Section 20 specifically addresses this. The offender faces up to 5 years imprisonment and Rs. 5 million fine. Victims should report immediately to FIA Cyber Crime Wing. The FIA can take down content and arrest offenders. Do not pay blackmailers — report instead.',
        relevantLaw: 'PECA 2016 S.20 | Pakistan Penal Code S.292',
      ),
      GuidanceArticle(
        title: 'Online Financial Fraud',
        content: 'Online scams, fraudulent banking apps, and phishing are crimes under PECA 2016 and the Pakistan Penal Code. If you\'ve been defrauded online, immediately contact your bank to freeze the transaction. File an FIR at the nearest police station and report to FIA Cyber Crime Wing at complaint.fia.gov.pk. Keep all transaction records as evidence.',
        relevantLaw: 'PECA 2016 S.36 | Pakistan Penal Code S.420',
      ),
      GuidanceArticle(
        title: 'Social Media Defamation Rights',
        content: 'Spreading false information about someone on social media is both a civil wrong (defamation) and potentially a crime under PECA 2016. The victim can file a civil suit for damages. Additionally, posting false statements that damage reputation is an offence under Section 20 of PECA. Screenshots and URLs are valid evidence. The FIA can request social media platforms to take down defamatory content and unmask anonymous accounts.',
        relevantLaw: 'PECA 2016 S.20 | Pakistan Penal Code S.499-500 | Defamation Ordinance 2002',
      ),
      GuidanceArticle(
        title: 'SIM Fraud & Identity Theft',
        content: 'Getting a SIM issued in your name without your knowledge is a serious crime. If you discover unauthorized SIMs registered against your CNIC, immediately report to PTA at complaint.pta.gov.pk or call 0800-55055. File an FIR at your local police station. SIM fraud is used for financial crimes and blackmail — early reporting is critical. NADRA can also verify which SIMs are registered against your identity at any NADRA office.',
        relevantLaw: 'PECA 2016 S.14-16 | Pakistan Telecommunication (Re-organization) Act 1996',
      ),
    ],
  ),
  GuidanceCategory(
    key: 'harassment_rights',
    label: 'Harassment Rights',
    icon: '⚠️',
    color: 0xFFe67e22,
    articles: [
      GuidanceArticle(
        title: 'Workplace Harassment Rights',
        content: 'The Protection Against Harassment of Women at Workplace Act 2010 protects all women employees. Every organization must have an Inquiry Committee. Victims can file a complaint directly with the Ombudsman if the employer fails to act. Harassment includes verbal, physical, and online conduct. Retaliation against a complainant is also illegal.',
        relevantLaw: 'Protection Against Harassment of Women at Workplace Act 2010',
      ),
      GuidanceArticle(
        title: 'Street Harassment & Eve Teasing',
        content: 'Street harassment is a criminal offence under the Pakistan Penal Code. Catcalling, following, and touching are all punishable. You can file an FIR at the nearest police station. The Criminal Law Amendment Act 2021 strengthened protections. Women do not need a male witness to file a harassment complaint. Your testimony is sufficient.',
        relevantLaw: 'Pakistan Penal Code S.509 | Criminal Law Amendment Act 2021',
      ),
      GuidanceArticle(
        title: 'Domestic Violence Rights',
        content: 'Domestic violence is illegal in Pakistan. The Punjab Protection of Women Against Violence Act 2016 allows courts to issue protection orders, residence orders, and monetary orders within 24 hours. Victims can apply directly to the court or through the Violence Against Women Centre (VAWC). Police are legally required to respond to domestic violence calls.',
        relevantLaw: 'Punjab Protection of Women Against Violence Act 2016 | PPC S.337',
      ),
      GuidanceArticle(
        title: 'Child Marriage Prevention',
        content: 'Child marriage (below 18 years) is illegal under federal law. Anyone who conducts, facilitates, or participates in a child marriage can be punished with up to 6 months imprisonment and a fine. Parents who arrange child marriages are also liable. You can report child marriages to the local police, district social welfare officer, or directly to the Child Protection Bureau. Courts can declare child marriages void and take custody of the child.',
        relevantLaw: 'Child Marriage Restraint (Amendment) Act 2019 | Child Protection Bureaus Act 2004',
      ),
      GuidanceArticle(
        title: 'Protection Against Acid Attacks',
        content: 'Acid attacks are among the most severely punished crimes in Pakistan. Under the Acid Control and Acid Crime Prevention Act 2011, perpetrators face imprisonment of 14 years to life and heavy fines. The victim is entitled to government-funded medical treatment and compensation. Purchase of acid is regulated — sellers must record buyer details. Victims should immediately report to police and seek medical attention. DNA evidence and witness statements are critical for prosecution.',
        relevantLaw: 'Acid Control and Acid Crime Prevention Act 2011 | Pakistan Penal Code S.336-B',
      ),
    ],
  ),
  GuidanceCategory(
    key: 'labor_employment',
    label: 'Labor & Employment',
    icon: '💼',
    color: 0xFF27ae60,
    articles: [
      GuidanceArticle(
        title: 'Minimum Wage Rights',
        content: 'Pakistan\'s federal minimum wage is Rs. 32,000/month (2024). Employers paying less are violating labour law. Workers can file a complaint with the Labour Department. Unpaid wages can be recovered through the Labour Court. The employer cannot deduct wages without lawful cause. All workers — formal and informal — are entitled to minimum wage protection.',
        relevantLaw: 'Minimum Wages Ordinance 1961 | Payment of Wages Act 1936',
      ),
      GuidanceArticle(
        title: 'Wrongful Termination',
        content: 'An employer cannot fire a permanent worker without proper cause and due process. Workers are entitled to a show-cause notice and hearing before termination. Wrongfully terminated employees can file a complaint with the Labour Court for reinstatement or compensation. Contract employees have rights defined in their employment agreement. Termination during maternity leave is illegal.',
        relevantLaw: 'Industrial Relations Act 2012 | Employment of Workmen Act 2010',
      ),
      GuidanceArticle(
        title: 'Leave Entitlements',
        content: 'Pakistani workers are legally entitled to: 14 days annual leave, 10 days casual leave, 8 days sick leave per year. Female workers get 12 weeks paid maternity leave. Workers cannot be forced to forfeit earned leave. Leaves not taken can be encashed at the time of leaving employment. Part-time workers also have proportional leave rights.',
        relevantLaw: 'Factories Act 1934 | West Pakistan Shops and Establishments Ordinance 1969',
      ),
      GuidanceArticle(
        title: 'Workers\' Compensation for Injuries',
        content: 'If you are injured at the workplace, the employer is legally obligated to pay compensation under the Workmen\'s Compensation Act. The amount depends on the nature and severity of injury. Fatal accidents entitle the deceased\'s family to substantial compensation. Employers cannot force workers to sign away their compensation rights. Medical expenses incurred due to workplace injury must also be covered by the employer. File a claim with the Labour Court if the employer refuses.',
        relevantLaw: 'Workmen\'s Compensation Act 1923 | Factories Act 1934 S.24-42',
      ),
      GuidanceArticle(
        title: 'Right to Form Trade Unions',
        content: 'Workers in Pakistan have the constitutional right to form and join trade unions. An employer cannot threaten, dismiss, or demote a worker for union activities. At least 20% of workers must be members to register a union with the NIRC. Collective bargaining agreements negotiated by unions are legally binding on employers. Anti-union practices by employers are punishable under the Industrial Relations Act. Workers can report violations to the National Industrial Relations Commission (NIRC).',
        relevantLaw: 'Industrial Relations Act 2012 | Constitution of Pakistan Art.17',
      ),
    ],
  ),
  GuidanceCategory(
    key: 'criminal_justice',
    label: 'Criminal Justice',
    icon: '⚖️',
    color: 0xFF2c3e50,
    articles: [
      GuidanceArticle(
        title: 'Your Rights When Arrested',
        content: 'When arrested, you have the right to: be told the reason for arrest, remain silent (you cannot be forced to confess), contact a lawyer immediately, be produced before a magistrate within 24 hours, not be tortured or ill-treated. Police cannot keep you in custody beyond 24 hours without a court order. A confession made to police is not admissible as evidence in court.',
        relevantLaw: 'Code of Criminal Procedure 1898 S.50,54,61 | Constitution of Pakistan Art.10',
      ),
      GuidanceArticle(
        title: 'Filing an FIR',
        content: 'You have the right to register a First Information Report (FIR) at any police station. Police cannot refuse to register a cognizable offence. If they refuse, you can complain to the DSP/SP or file a private complaint directly in court. Always keep a copy of the FIR. FIRs are public documents — you can obtain a copy from the court. Online FIR registration is available in some provinces.',
        relevantLaw: 'Code of Criminal Procedure 1898 S.154 | Police Order 2002',
      ),
      GuidanceArticle(
        title: 'Bail Rights',
        content: 'Bail is a right, not a privilege in Pakistan. For bailable offences, bail must be granted. For non-bailable offences, you can apply to the Sessions Court. The Supreme Court has held that bail should not be refused merely due to severity of charge. Bail applications must be decided within reasonable time. You can apply for bail at each court level — Magistrate, Sessions, High Court, Supreme Court.',
        relevantLaw: 'Code of Criminal Procedure 1898 S.496-499 | Constitution Art.10A',
      ),
      GuidanceArticle(
        title: 'Rights Against Police Torture',
        content: 'Torture by police officers is constitutionally prohibited and a criminal offence in Pakistan. Article 14 of the Constitution guarantees dignity of the person. A confession obtained through torture is inadmissible in court. If you are tortured in custody, you can file a complaint with the Human Rights Cell of the High Court or Supreme Court. The National Commission for Human Rights (NCHR) also investigates such complaints. Medical examination upon arrest can document injuries and protect against false charges.',
        relevantLaw: 'Constitution Art.14 | Pakistan Penal Code S.330-331 | Police Order 2002 Art.156',
      ),
      GuidanceArticle(
        title: 'Right to Free Legal Aid',
        content: 'Every person facing criminal charges who cannot afford a lawyer has the right to free legal representation in Pakistan. Courts are constitutionally required to ensure this. The Legal Aid Society, Pakistan Bar Council, and provincial bar councils provide free legal assistance. High Courts have free legal aid panels. For women: organizations like AGHS Legal Aid Cell and Dastak provide free help. Simply inform the court that you cannot afford a lawyer — the court will assign one. This right applies from the earliest stages of criminal proceedings.',
        relevantLaw: 'Constitution Art.10A | Legal Aid Act (proposed) | High Court rules on legal aid',
      ),
    ],
  ),
];

// ─── JUSTICE TRACKER DATA ─────────────────────────────────────────────
class CourtStat {
  final String courtType;
  final String city;
  final int totalPendingCases;
  final int avgResolutionDays;
  final int casesResolvedThisMonth;
  const CourtStat({required this.courtType, required this.city, required this.totalPendingCases, required this.avgResolutionDays, required this.casesResolvedThisMonth});
  String get status {
    if (totalPendingCases < 20000) return 'Manageable';
    if (totalPendingCases < 100000) return 'Backlogged';
    return 'Severely Backlogged';
  }
  int get statusColor {
    if (totalPendingCases < 20000) return 0xFF27ae60;
    if (totalPendingCases < 100000) return 0xFFf39c12;
    return 0xFFe74c3c;
  }
}

class CaseTypeStat {
  final String caseType;
  final int avgDaysToResolve;
  final int successRatePercent;
  final int totalCases2023;
  const CaseTypeStat({required this.caseType, required this.avgDaysToResolve, required this.successRatePercent, required this.totalCases2023});
}

const List<CourtStat> kCourtStats = [
  CourtStat(courtType: 'Supreme Court of Pakistan', city: 'Islamabad', totalPendingCases: 52341, avgResolutionDays: 730, casesResolvedThisMonth: 312),
  CourtStat(courtType: 'Lahore High Court', city: 'Lahore', totalPendingCases: 187654, avgResolutionDays: 820, casesResolvedThisMonth: 1243),
  CourtStat(courtType: 'Islamabad High Court', city: 'Islamabad', totalPendingCases: 31209, avgResolutionDays: 610, casesResolvedThisMonth: 287),
  CourtStat(courtType: 'Sindh High Court', city: 'Karachi', totalPendingCases: 143876, avgResolutionDays: 890, casesResolvedThisMonth: 876),
  CourtStat(courtType: 'Peshawar High Court', city: 'Peshawar', totalPendingCases: 67432, avgResolutionDays: 740, casesResolvedThisMonth: 523),
  CourtStat(courtType: 'Sessions Court Lahore', city: 'Lahore', totalPendingCases: 43210, avgResolutionDays: 540, casesResolvedThisMonth: 734),
  CourtStat(courtType: 'Family Court Karachi', city: 'Karachi', totalPendingCases: 18760, avgResolutionDays: 420, casesResolvedThisMonth: 412),
  CourtStat(courtType: 'Labour Court Islamabad', city: 'Islamabad', totalPendingCases: 7320, avgResolutionDays: 380, casesResolvedThisMonth: 198),
];

const List<CaseTypeStat> kCaseTypeStats = [
  CaseTypeStat(caseType: 'Civil / Property Disputes', avgDaysToResolve: 912, successRatePercent: 61, totalCases2023: 124500),
  CaseTypeStat(caseType: 'Family / Divorce Cases', avgDaysToResolve: 487, successRatePercent: 74, totalCases2023: 89200),
  CaseTypeStat(caseType: 'Criminal Cases', avgDaysToResolve: 763, successRatePercent: 48, totalCases2023: 213700),
  CaseTypeStat(caseType: 'Labour Disputes', avgDaysToResolve: 321, successRatePercent: 69, totalCases2023: 31400),
  CaseTypeStat(caseType: 'Constitutional Petitions', avgDaysToResolve: 584, successRatePercent: 55, totalCases2023: 18600),
  CaseTypeStat(caseType: 'Cybercrime Cases', avgDaysToResolve: 274, successRatePercent: 72, totalCases2023: 8900),
];

// ─── QUIZ DATA ─────────────────────────────────────────────────────────
class QuizQuestion {
  final int level;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final String explanation;
  const QuizQuestion({required this.level, required this.question, required this.optionA, required this.optionB, required this.optionC, required this.optionD, required this.correctAnswer, required this.explanation});
}

const List<QuizQuestion> kQuizQuestions = [
  // Level 1 — Beginner
  QuizQuestion(level: 1, question: 'What is the minimum age for marriage in Pakistan?', optionA: '14 years', optionB: '16 years', optionC: '18 years', optionD: '21 years', correctAnswer: 'c', explanation: 'Under the Child Marriage Restraint (Amendment) Act 2019 (federal), 18 years is the minimum age for marriage.'),
  QuizQuestion(level: 1, question: 'Which document is required to start a court case?', optionA: 'CNIC', optionB: 'Petition or Plaint', optionC: 'Passport', optionD: 'Tax return', correctAnswer: 'b', explanation: 'A court case begins with a Petition (in superior courts) or a Plaint (in civil courts) filed by the complainant.'),
  QuizQuestion(level: 1, question: 'What does FIR stand for?', optionA: 'First Investigation Report', optionB: 'Final Information Record', optionC: 'First Information Report', optionD: 'Federal Inquiry Report', correctAnswer: 'c', explanation: 'FIR stands for First Information Report — the initial complaint registered at a police station.'),
  QuizQuestion(level: 1, question: 'Within how many hours must an arrested person be produced before a magistrate?', optionA: '12 hours', optionB: '24 hours', optionC: '48 hours', optionD: '72 hours', correctAnswer: 'b', explanation: 'Article 10 of the Constitution requires that an arrested person be produced before the nearest magistrate within 24 hours.'),
  QuizQuestion(level: 1, question: 'What is Mehr in Islamic law?', optionA: 'Monthly maintenance', optionB: 'A mandatory gift from husband to wife', optionC: 'Inheritance share', optionD: 'Property tax', correctAnswer: 'b', explanation: 'Mehr (Dower) is a mandatory gift from the groom to the bride. It becomes her exclusive property upon marriage.'),
  QuizQuestion(level: 1, question: 'Who can register a property sale in Pakistan?', optionA: 'Local police', optionB: 'Deputy Commissioner', optionC: 'Sub-Registrar', optionD: 'Union Council', correctAnswer: 'c', explanation: 'Property sales must be registered with the Sub-Registrar office under the Registration Act 1908.'),
  QuizQuestion(level: 1, question: 'What is the federal minimum wage in Pakistan (2024)?', optionA: 'Rs. 20,000', optionB: 'Rs. 25,000', optionC: 'Rs. 30,000', optionD: 'Rs. 32,000', correctAnswer: 'd', explanation: 'The federal minimum wage was increased to Rs. 32,000 per month in the 2024 federal budget.'),
  QuizQuestion(level: 1, question: 'Which law protects women from workplace harassment in Pakistan?', optionA: 'Women Protection Act 2006', optionB: 'Protection Against Harassment of Women at Workplace Act 2010', optionC: 'Gender Equality Act 2015', optionD: 'Labour Rights Act 2012', correctAnswer: 'b', explanation: 'The Protection Against Harassment of Women at Workplace Act 2010 mandates inquiry committees and provides the Ombudsman mechanism.'),
  QuizQuestion(level: 1, question: 'What is Khula?', optionA: 'Husband\'s right to divorce', optionB: 'A form of inheritance', optionC: 'Woman\'s right to seek divorce through court', optionD: 'Engagement contract', correctAnswer: 'c', explanation: 'Khula is the right of a Muslim woman to seek divorce through the court in exchange for returning the dower (mehr).'),
  QuizQuestion(level: 1, question: 'Which government body handles cybercrime complaints in Pakistan?', optionA: 'NADRA', optionB: 'FIA Cyber Crime Wing', optionC: 'PEMRA', optionD: 'SECP', correctAnswer: 'b', explanation: 'The Federal Investigation Agency (FIA) Cyber Crime Wing handles all cybercrime complaints under PECA 2016.'),

  // Level 2 — Easy
  QuizQuestion(level: 2, question: 'Under PECA 2016, what is the punishment for cyberstalking?', optionA: 'Fine only', optionB: 'Up to 1 year imprisonment', optionC: 'Up to 3 years imprisonment and/or Rs. 1 million fine', optionD: 'Community service', correctAnswer: 'c', explanation: 'Section 24 of PECA 2016 prescribes up to 3 years imprisonment and/or a fine of up to Rs. 1 million for cyberstalking.'),
  QuizQuestion(level: 2, question: 'How many weeks of maternity leave is a female employee entitled to?', optionA: '6 weeks', optionB: '8 weeks', optionC: '12 weeks', optionD: '16 weeks', correctAnswer: 'c', explanation: 'Female workers in Pakistan are entitled to 12 weeks (3 months) of paid maternity leave under the Maternity Benefit Ordinance.'),
  QuizQuestion(level: 2, question: 'A wife\'s share in her husband\'s estate (if they have children) under Islamic law is:', optionA: '1/4', optionB: '1/8', optionC: '1/6', optionD: '1/3', correctAnswer: 'b', explanation: 'Under Islamic inheritance law, a wife receives 1/8th of her husband\'s estate when there are children, and 1/4th when there are no children.'),
  QuizQuestion(level: 2, question: 'Which court handles rent disputes in Pakistan?', optionA: 'Civil Court', optionB: 'Sessions Court', optionC: 'Rent Controller Court', optionD: 'High Court', correctAnswer: 'c', explanation: 'Rent disputes between landlords and tenants are handled by the Rent Controller Court under the Rent Restriction Ordinance.'),
  QuizQuestion(level: 2, question: 'What does "Intiqal" refer to in land records?', optionA: 'Property tax', optionB: 'Mutation — transfer of ownership in revenue records', optionC: 'Boundary demarcation', optionD: 'Land survey certificate', correctAnswer: 'b', explanation: 'Intiqal (Mutation) is the process of recording a change of ownership in the Revenue Department\'s land records (Fard).'),
  QuizQuestion(level: 2, question: 'Under the Guardian and Wards Act, who is the natural guardian for a child\'s property?', optionA: 'Mother', optionB: 'Maternal grandparents', optionC: 'Father', optionD: 'State', correctAnswer: 'c', explanation: 'The father is the natural guardian for a child\'s property under the Guardian and Wards Act 1890, though courts decide custody based on the child\'s best interest.'),
  QuizQuestion(level: 2, question: 'Which act criminalizes depriving women of inheritance in Pakistan?', optionA: 'Family Courts Act 1964', optionB: 'Criminal Law Amendment Act 2019', optionC: 'Muslim Personal Law Act 1962', optionD: 'Women Protection Act 2006', correctAnswer: 'b', explanation: 'The Criminal Law Amendment Act 2019 made depriving women of their inheritance a criminal offence.'),
  QuizQuestion(level: 2, question: 'Can a police confession be used as evidence in a Pakistani court?', optionA: 'Yes, always', optionB: 'Yes, if witnessed', optionC: 'No, it is not admissible', optionD: 'Only in terrorism cases', correctAnswer: 'c', explanation: 'Under the Qanun-e-Shahadat Order 1984, a confession made to a police officer is not admissible as evidence in court.'),
  QuizQuestion(level: 2, question: 'What is the notice period for Talaq (divorce by husband) under Muslim Family Laws?', optionA: '30 days', optionB: '60 days', optionC: '90 days', optionD: '120 days', correctAnswer: 'c', explanation: 'The husband must notify the Union Council within 90 days of pronouncing Talaq. The divorce takes effect after 90 days.'),
  QuizQuestion(level: 2, question: 'An employee can take how many days of annual leave per year in Pakistan?', optionA: '7 days', optionB: '10 days', optionC: '14 days', optionD: '21 days', correctAnswer: 'c', explanation: 'The Factories Act and Shops Ordinance entitle employees to 14 days of annual leave per year after completing one year of service.'),

  // Level 3 — Medium
  QuizQuestion(level: 3, question: 'Which section of PECA 2016 deals with non-consensual sharing of intimate images?', optionA: 'Section 10', optionB: 'Section 20', optionC: 'Section 30', optionD: 'Section 40', correctAnswer: 'b', explanation: 'Section 20 of PECA 2016 criminalizes sharing someone\'s intimate images without their consent, with punishment up to 5 years and Rs. 5 million fine.'),
  QuizQuestion(level: 3, question: 'What type of bail must be granted as a right for bailable offences?', optionA: 'Discretionary bail', optionB: 'Anticipatory bail', optionC: 'Bail as a right', optionD: 'Surety bail only', correctAnswer: 'c', explanation: 'For bailable offences listed in the Code of Criminal Procedure, bail must be granted as a right — police or courts have no discretion to refuse it.'),
  QuizQuestion(level: 3, question: 'Under the Punjab Protection of Women Against Violence Act 2016, how quickly can a protection order be issued?', optionA: '7 days', optionB: '3 days', optionC: 'Within 24 hours', optionD: '30 days', correctAnswer: 'c', explanation: 'Courts can issue interim protection orders within 24 hours of receiving an application under the Punjab Protection of Women Against Violence Act 2016.'),
  QuizQuestion(level: 3, question: 'What does the Industrial Relations Act 2012 protect workers against?', optionA: 'Only wage theft', optionB: 'Wrongful termination and union rights', optionC: 'Workplace accidents only', optionD: 'Foreign workers only', correctAnswer: 'b', explanation: 'The Industrial Relations Act 2012 governs collective bargaining, trade union rights, and protects workers from wrongful termination and unfair labour practices.'),
  QuizQuestion(level: 3, question: 'Which court would you approach first for a bail application in a non-bailable case?', optionA: 'High Court', optionB: 'Supreme Court', optionC: 'Magistrate Court, then Sessions Court', optionD: 'Federal Shariat Court', correctAnswer: 'c', explanation: 'For non-bailable offences, the hierarchy is: Magistrate → Sessions Court → High Court → Supreme Court. You start at the lowest competent court.'),
  QuizQuestion(level: 3, question: 'What is the key difference between Talaq and Khula?', optionA: 'No difference, both are the same', optionB: 'Talaq is by husband, Khula is by wife through court', optionC: 'Khula is only for non-Muslims', optionD: 'Talaq requires court approval', correctAnswer: 'b', explanation: 'Talaq is the husband\'s unilateral right to divorce. Khula is the wife\'s right to seek divorce through the court, usually by returning the mehr.'),
  QuizQuestion(level: 3, question: 'Under the Registration Act, property sale deeds must be registered within:', optionA: '30 days of execution', optionB: '4 months of execution', optionC: '1 year of execution', optionD: 'Any time before dispute', correctAnswer: 'b', explanation: 'Under the Registration Act 1908, documents must be presented for registration within 4 months of execution.'),
  QuizQuestion(level: 3, question: 'What is the legal basis for the right to silence when arrested?', optionA: 'Pakistan Penal Code Section 100', optionB: 'Constitution Article 13 (protection against self-incrimination)', optionC: 'Code of Criminal Procedure Section 200', optionD: 'Evidence Act Section 50', correctAnswer: 'b', explanation: 'Article 13 of the Constitution protects citizens against compelled self-incrimination — you cannot be forced to be a witness against yourself.'),
  QuizQuestion(level: 3, question: 'Which body can a woman approach if her employer ignores a workplace harassment complaint?', optionA: 'Labour Court', optionB: 'FIA', optionC: 'Federal / Provincial Ombudsman for Harassment', optionD: 'NADRA', correctAnswer: 'c', explanation: 'Under the Harassment at Workplace Act 2010, women can escalate complaints to the Federal or Provincial Ombudsperson for Protection Against Harassment if the employer fails to act.'),
  QuizQuestion(level: 3, question: 'A daughter\'s share in Islamic inheritance compared to a son is:', optionA: 'Equal to son', optionB: 'Double of son', optionC: 'Half of son', optionD: 'One-third of son', correctAnswer: 'c', explanation: 'Under Islamic inheritance law (and Muslim Personal Law in Pakistan), a daughter receives half the share of a son from the deceased parent\'s estate.'),

  // Level 4 — Hard
  QuizQuestion(level: 4, question: 'Which doctrine allows Pakistani courts to review laws inconsistent with fundamental rights?', optionA: 'Ultra vires doctrine', optionB: 'Judicial review under Article 199 (High Court) and Article 184(3) (Supreme Court)', optionC: 'Rule of Law doctrine', optionD: 'Separation of powers', correctAnswer: 'b', explanation: 'High Courts exercise judicial review under Article 199 (writ jurisdiction). The Supreme Court exercises original jurisdiction under Article 184(3) for fundamental rights violations of public importance.'),
  QuizQuestion(level: 4, question: 'What is the difference between cognizable and non-cognizable offences?', optionA: 'Cognizable offences need a warrant; non-cognizable do not', optionB: 'Police can arrest without warrant for cognizable offences; non-cognizable require a magistrate\'s order', optionC: 'Only cognizable offences go to trial', optionD: 'Non-cognizable means the FIR cannot be filed', correctAnswer: 'b', explanation: 'For cognizable offences (serious crimes), police can arrest without a warrant and investigate. For non-cognizable offences, police need a magistrate\'s order before investigating.'),
  QuizQuestion(level: 4, question: 'What is "Qisas" in Pakistani criminal law?', optionA: 'Financial compensation for crime', optionB: 'Retaliation in kind — equal punishment matching the crime', optionC: 'Imprisonment for violent crimes', optionD: 'Community rehabilitation', correctAnswer: 'b', explanation: 'Qisas means equal retaliation — e.g., in murder cases, the victim\'s heirs can demand the death penalty. It is governed by the Qisas and Diyat Ordinance incorporated in the PPC.'),
  QuizQuestion(level: 4, question: 'Under Article 10A of Pakistan\'s Constitution, what right is guaranteed?', optionA: 'Right to vote', optionB: 'Right to fair trial and due process', optionC: 'Right to education', optionD: 'Right to privacy', correctAnswer: 'b', explanation: 'Article 10A (added by 18th Amendment 2010) guarantees the right to a fair trial and due process for all citizens facing criminal charges.'),
  QuizQuestion(level: 4, question: 'What is the legal status of an unregistered property sale deed?', optionA: 'Fully valid if witnessed', optionB: 'Enforceable only between parties', optionC: 'Not admissible as evidence of title transfer', optionD: 'Valid if notarized', correctAnswer: 'c', explanation: 'Under Section 49 of the Registration Act 1908, a document that is compulsorily registrable (like a property sale deed) is not admissible as evidence of the transaction if unregistered.'),
  QuizQuestion(level: 4, question: 'In Pakistan, which court has exclusive jurisdiction over constitutional questions about federal and provincial legislative competence?', optionA: 'Islamabad High Court', optionB: 'Supreme Court under Article 184', optionC: 'Federal Shariat Court', optionD: 'Supreme Court under Article 186 and High Courts under Article 199', correctAnswer: 'd', explanation: 'Constitutional questions on legislative competence can be raised in High Courts (Article 199) or referred to the Supreme Court (Article 186 for advisory opinions). Original human rights jurisdiction is Article 184(3).'),
  QuizQuestion(level: 4, question: 'What is "Diyat" in the context of Pakistani criminal law?', optionA: 'Imprisonment term', optionB: 'Blood money/financial compensation paid to victim\'s heirs', optionC: 'Whipping punishment', optionD: 'Court fine paid to state', correctAnswer: 'b', explanation: 'Diyat is blood money — financial compensation paid by the offender to the victim\'s family in cases of murder or bodily harm. The heirs can accept Diyat in lieu of Qisas.'),
  QuizQuestion(level: 4, question: 'Which provision allows the Supreme Court to take suo motu notice of public interest matters?', optionA: 'Article 187', optionB: 'Article 184(3)', optionC: 'Article 199', optionD: 'Article 175', correctAnswer: 'b', explanation: 'Article 184(3) gives the Supreme Court original jurisdiction to take up matters of public importance involving fundamental rights, including suo motu (on its own motion) proceedings.'),
  QuizQuestion(level: 4, question: 'Under the PECA 2016, the National Response Centre for Cyber Crime is better known as:', optionA: 'FIA Cyber Patrol', optionB: 'NR3C', optionC: 'CERT-PK', optionD: 'Cyber Shield Pakistan', correctAnswer: 'b', explanation: 'NR3C (National Response Centre for Cyber Crime) is the specialized unit within the FIA responsible for cybercrime investigation under PECA 2016.'),
  QuizQuestion(level: 4, question: 'What is the maximum term of preventive detention allowed under the Constitution without judicial review?', optionA: '24 hours', optionB: '3 months, extendable by Review Board', optionC: '6 months', optionD: 'Indefinite during emergency', correctAnswer: 'b', explanation: 'Article 10(4) allows preventive detention for up to 3 months. Any extension beyond 3 months requires a Review Board under Article 10(5) to approve the continued detention.'),

  // Level 5 — Expert
  QuizQuestion(level: 5, question: 'What is the doctrine of "basic structure" and has it been accepted in Pakistani constitutional law?', optionA: 'Accepted fully — Parliament cannot amend the Constitution at all', optionB: 'Partially recognized — Supreme Court has held certain fundamental features cannot be destroyed by amendment', optionC: 'Completely rejected — Parliament has unlimited amendment power', optionD: 'Only applies to financial laws', correctAnswer: 'b', explanation: 'In Sindh High Court Bar Association v. Federation (2009) and subsequent cases, the Supreme Court recognized that certain fundamental features (like independence of judiciary, parliamentary democracy) form a "basic structure" that cannot be abrogated.'),
  QuizQuestion(level: 5, question: 'Under the Limitation Act, what is the limitation period for a suit to recover immovable property?', optionA: '3 years', optionB: '6 years', optionC: '12 years', optionD: '30 years', correctAnswer: 'c', explanation: 'Under the Limitation Act 1908, Article 144, the period of limitation for suits for possession of immovable property is 12 years from when the right to sue accrues.'),
  QuizQuestion(level: 5, question: 'Which case established the principle of "public interest litigation" (PIL) in Pakistan?', optionA: 'Federation v. Iftikhar Chaudhry', optionB: 'Benazir Bhutto v. Federation', optionC: 'Darshan Masih v. State (1990)', optionD: 'Asma Jilani v. Punjab Government', correctAnswer: 'c', explanation: 'Darshan Masih v. State (1990) PLD 1990 SC 513 is a landmark case where the Supreme Court accepted a telegram as a petition and established PIL, allowing the court to address bonded labor issues without formal standing requirements.'),
  QuizQuestion(level: 5, question: 'What is the legal effect of "adverse possession" on property rights in Pakistan?', optionA: 'No legal effect — possession cannot defeat title', optionB: 'After 12 years of open, continuous, hostile possession, the possessor acquires title and the original owner\'s right is extinguished', optionC: 'Only applies to government land', optionD: 'Possessor gets right to use but not ownership', correctAnswer: 'b', explanation: 'The Limitation Act 1908 provides that after 12 years of open, continuous, hostile, and exclusive adverse possession, the possessor acquires title as the original owner\'s right of suit becomes time-barred.'),
  QuizQuestion(level: 5, question: 'In the context of labour law, what is a "wildcat strike" and is it protected in Pakistan?', optionA: 'An authorized union strike — fully protected', optionB: 'An unauthorized strike without following legal notice requirements — not protected under Industrial Relations Act', optionC: 'A strike in essential services — protected if peacefully conducted', optionD: 'A sympathy strike — conditionally protected', correctAnswer: 'b', explanation: 'Under the Industrial Relations Act 2012, strikes must follow a prescribed notice period and procedure. Wildcat strikes (unauthorized, spontaneous) do not follow this procedure and workers can face disciplinary action.'),
  QuizQuestion(level: 5, question: 'What constitutional provision governs the Federal Shariat Court\'s jurisdiction to examine laws for compliance with Islamic injunctions?', optionA: 'Article 228', optionB: 'Article 203-D', optionC: 'Article 227', optionD: 'Article 31', correctAnswer: 'b', explanation: 'Article 203-D empowers the Federal Shariat Court to examine and declare any law repugnant to Quran and Sunnah. The Court can strike down such laws, subject to appeal to the Shariat Appellate Bench of the Supreme Court.'),
  QuizQuestion(level: 5, question: 'What is the legal significance of a "consent order" in Pakistani litigation?', optionA: 'It is unenforceable as parties cannot bind the court', optionB: 'It has the force of a court decree and can be enforced through execution proceedings', optionC: 'It expires after 90 days', optionD: 'Only binding on one party', correctAnswer: 'b', explanation: 'A consent order (compromise decree under CPC Order 23 Rule 3) is an agreement between parties recorded by the court as a decree. It has full enforceability through execution proceedings like any other court decree.'),
  QuizQuestion(level: 5, question: 'Under which constitutional article can a High Court issue a writ of Habeas Corpus?', optionA: 'Article 184', optionB: 'Article 185', optionC: 'Article 199', optionD: 'Article 203', correctAnswer: 'c', explanation: 'Article 199 grants High Courts writ jurisdiction including Habeas Corpus (for illegal detention), Mandamus (to compel public duty), Certiorari (to quash illegal orders), Prohibition, and Quo Warranto.'),
  QuizQuestion(level: 5, question: 'What is the "Doctrine of Proportionality" in Pakistan\'s administrative law?', optionA: 'Courts cannot review executive decisions', optionB: 'Government action must be proportionate to the objective — excessive measures infringing rights are unlawful', optionC: 'Punishments must match the exact value of damage', optionD: 'Only applies to taxation matters', correctAnswer: 'b', explanation: 'The Doctrine of Proportionality requires that state action must not go beyond what is necessary to achieve its legitimate aim. Courts use it to review whether fundamental rights infringements are proportionate to the public interest served.'),
  QuizQuestion(level: 5, question: 'In Pakistani succession law, who qualifies as a "residuary" (Asaba) heir?', optionA: 'Daughters only', optionB: 'Agnatic (paternal-line) male relatives who inherit what remains after Quranic sharers', optionC: 'The state, when no other heirs exist', optionD: 'Wife and mother of deceased', correctAnswer: 'b', explanation: 'Asaba (residuaries) are agnatic heirs who inherit what remains of the estate after Quranic sharers (daughters, wife, mother) have taken their fixed shares. Sons are the primary residuaries.'),
];

// ─── FAQs ──────────────────────────────────────────────────────────────
class FaqItem {
  final String question;
  final String answer;
  final String category;
  const FaqItem({required this.question, required this.answer, required this.category});
}

const List<FaqItem> kFaqs = [
  FaqItem(question: 'How do I file an FIR if the police refuse?', answer: 'If police refuse to register your FIR, you have several options:\n1. Approach the DSP/SP of the area and submit a written complaint.\n2. Send a written complaint by registered post to the Station House Officer (SHO) — it then becomes a deemed FIR.\n3. File a private complaint directly before a Magistrate under Section 200 of the Code of Criminal Procedure.\n4. Submit a complaint to the Human Rights Cell of the Supreme Court or High Court online.', category: 'Criminal Justice'),
  FaqItem(question: 'Can I hire a lawyer if I cannot afford one?', answer: 'Yes! Pakistan has free legal aid available:\n1. Pakistan Bar Council and provincial bar councils run legal aid programs.\n2. The Legal Aid Society operates free clinics in major cities.\n3. High Courts have free legal aid panels for indigent persons.\n4. For women: Dastak, WAR (Women Against Rape), and AGHS Legal Aid Cell provide free help.\n5. File an application before the court stating inability to pay — the court can appoint a lawyer.', category: 'General'),
  FaqItem(question: 'What should I do immediately if I\'m a victim of cybercrime?', answer: 'Act quickly:\n1. Take screenshots of all evidence immediately.\n2. Do NOT delete messages, emails, or posts — preserve everything.\n3. Report online at complaint.fia.gov.pk or visit your nearest FIA Cyber Crime Circle.\n4. If it involves financial fraud, call your bank immediately to freeze the transaction.\n5. File an FIR at your local police station simultaneously.\n6. Never pay blackmailers — it encourages more extortion. Report instead.', category: 'Cybercrime'),
  FaqItem(question: 'How can a woman get a divorce in Pakistan?', answer: 'Women have multiple ways to divorce:\n1. Khula: Apply to the Family Court. The court will dissolve the marriage. You may need to return the Mehr.\n2. Talaq-e-Tafweedh: If the husband delegated divorce rights in the Nikahnama, you can divorce without going to court.\n3. Dissolution of Muslim Marriage: Courts can dissolve marriage on grounds like cruelty, desertion, impotence, imprisonment of husband.\n4. Contact a family lawyer or the nearest District Court Family Division.', category: 'Family Law'),
  FaqItem(question: 'My landlord is threatening to evict me without notice. What are my rights?', answer: 'You have strong protections as a tenant:\n1. A landlord CANNOT evict you without a court order from the Rent Controller.\n2. Forcible eviction without a court order is illegal and the landlord can be prosecuted.\n3. The Rent Controller must give you a fair hearing before any eviction order.\n4. Legal grounds for eviction are limited: non-payment of rent, tenant causing damage, landlord\'s personal need with proper notice.\n5. File a counter-complaint with the Rent Controller if threatened.', category: 'Property'),
  FaqItem(question: 'How do I report workplace harassment?', answer: 'Steps to report workplace harassment:\n1. File a written complaint with your organization\'s Inquiry Committee (all organizations must have one).\n2. The Committee must complete inquiry within 30 days.\n3. If the organization fails to act, complain to the Federal or Provincial Ombudsperson for Protection Against Harassment at mohtasib.gov.pk.\n4. You can also report to the Labour Department.\n5. For criminal harassment, file an FIR at the police station under PPC Section 509.', category: 'Harassment'),
  FaqItem(question: 'Can I claim my inheritance share if my family refuses to give it?', answer: 'Yes, inheritance is your legal right:\n1. Under the Criminal Law Amendment Act 2019, depriving a woman of inheritance is a criminal offence punishable by up to 5 years imprisonment.\n2. File a civil suit for "declaration of rights" in the Civil Court to have your share declared.\n3. File a criminal complaint at the police station if family members are denying your share.\n4. Contact the local Moonsif/Civil Judge court — they handle inheritance matters.\n5. Seek help from legal aid organizations if you cannot afford a lawyer.', category: 'Property'),
  FaqItem(question: 'What are my rights if my employer does not pay salary on time?', answer: 'Non-payment of wages is illegal:\n1. Under the Payment of Wages Act 1936, wages must be paid by the 7th of the following month (for establishments with <1000 workers) or 10th (for larger ones).\n2. File a complaint with the Labour Department / Labour Inspector of your area.\n3. File an application before the Labour Court for recovery of unpaid wages.\n4. The court can order payment with penalty — up to 10 times the delayed amount.\n5. Document all evidence: appointment letter, pay slips, bank records.', category: 'Labour'),
  FaqItem(question: 'How do I verify land ownership before buying property?', answer: 'Essential steps before buying property:\n1. Obtain "Fard" (ownership record) from the Revenue Department/Patwari office — it shows the current owner.\n2. Check for encumbrances: mortgage, litigation, or government acquisition notices.\n3. Verify no court stay orders exist against the property — check with civil courts.\n4. Ensure the seller\'s CNIC matches the Fard.\n5. Get a "Non-Encumbrance Certificate" from the Sub-Registrar office.\n6. Always execute a registered sale deed — never rely on an agreement to sell alone.\n7. Get the Mutation (Intiqal) done in your name after purchase.', category: 'Property'),
  FaqItem(question: 'What is a suo motu notice and how does it affect me?', answer: 'Suo motu means "on its own motion":\n1. Pakistani superior courts (Supreme Court, High Courts) can take notice of issues without anyone filing a formal case.\n2. Courts use this power for matters of public interest: illegal arrests, environmental issues, corruption, etc.\n3. As a citizen, you can write to the Human Rights Cell of the Supreme Court — they may convert it to suo motu.\n4. Suo motu proceedings can result in binding orders on government officials.\n5. This is a powerful tool for public interest matters that might otherwise go unaddressed.', category: 'General'),
];
