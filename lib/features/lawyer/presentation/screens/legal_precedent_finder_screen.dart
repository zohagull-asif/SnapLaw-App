import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../services/rag_api_service.dart';

class LegalPrecedentFinderScreen extends ConsumerStatefulWidget {
  const LegalPrecedentFinderScreen({super.key});

  @override
  ConsumerState<LegalPrecedentFinderScreen> createState() =>
      _LegalPrecedentFinderScreenState();
}

class _LegalPrecedentFinderScreenState
    extends ConsumerState<LegalPrecedentFinderScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PrecedentResult> _searchResults = [];
  bool _isSearching = false;
  bool _isExtracting = false;
  bool _backendAvailable = true;
  String? _errorMessage;
  String _selectedFilter = 'All Courts';
  String _selectedYear = 'All Years';
  String? _uploadedFileName;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkBackend();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final available = await RagApiService.isBackendAvailable();
    if (mounted) {
      setState(() => _backendAvailable = available);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final response = await RagApiService.searchPrecedents(
        query: query,
        topK: 10,
        courtFilter: _selectedFilter != 'All Courts' ? _selectedFilter : null,
        yearFilter: _selectedYear != 'All Years' ? _selectedYear : null,
      );

      setState(() {
        _searchResults = response.results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _isExtracting = true;
        _uploadedFileName = file.name;
        _errorMessage = null;
        _searchResults = [];
      });

      // Send file to backend for text extraction and precedent search
      final analysisResponse = await RagApiService.analyzeContract(file: file);

      // Collect all unique precedents from all clauses
      final Map<String, PrecedentResult> uniquePrecedents = {};
      for (final clause in analysisResponse.clauses) {
        for (final precedent in clause.precedents) {
          final key = precedent.caseTitle;
          if (!uniquePrecedents.containsKey(key)) {
            uniquePrecedents[key] = PrecedentResult(
              id: '',
              title: precedent.caseTitle,
              caseNumber: precedent.caseNumber,
              court: precedent.court,
              year: precedent.year,
              summary: precedent.summary,
              judgment: precedent.decision,
              decision: precedent.decision,
              keywords: precedent.keywords,
              category: precedent.category,
              relevanceScore: precedent.similarityScore,
              reason: precedent.reason,
            );
          }
        }
      }

      // If no precedents from clauses, search using the contract text preview
      if (uniquePrecedents.isEmpty && analysisResponse.contractTextPreview != null) {
        final response = await RagApiService.searchPrecedents(
          query: analysisResponse.contractTextPreview!,
          topK: 5,
          courtFilter: _selectedFilter != 'All Courts' ? _selectedFilter : null,
          yearFilter: _selectedYear != 'All Years' ? _selectedYear : null,
        );
        setState(() {
          _searchResults = response.results;
          _isExtracting = false;
        });
        return;
      }

      // Sort by relevance score
      final sortedResults = uniquePrecedents.values.toList()
        ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      setState(() {
        _searchResults = sortedResults;
        _isExtracting = false;
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _errorMessage = 'Failed to process document: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Legal Precedent Finder',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_backendAvailable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.cloud_off, color: Colors.orange),
                tooltip: 'Backend unavailable',
                onPressed: _checkBackend,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildResultsSection()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(color: Color(0xFF1E3A5F)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Pakistani Legal Cases & Precedents',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Powered by LegalBERT semantic search',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Tab bar for Search / Upload
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: const Color(0xFF1E3A5F),
              unselectedLabelColor: Colors.white.withOpacity(0.8),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 16),
                      SizedBox(width: 6),
                      Text('Text Search'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 16),
                      SizedBox(width: 6),
                      Text('Upload Document'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab content
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Text search
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Describe your legal issue or question...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A5F)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _errorMessage = null;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                // Tab 2: Upload document
                _buildUploadArea(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filters + Search button row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    dropdownColor: const Color(0xFF1E3A5F),
                    underline: const SizedBox(),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: [
                      'All Courts',
                      'Supreme Court of Pakistan',
                      'Lahore High Court',
                      'Islamabad High Court',
                      'Sindh High Court',
                      'Peshawar High Court',
                      'Balochistan High Court',
                    ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedFilter = newValue);
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    dropdownColor: const Color(0xFF1E3A5F),
                    underline: const SizedBox(),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: [
                      'All Years', '2022', '2021', '2020', '2019', '2018',
                    ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedYear = newValue);
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _tabController.index == 0
                    ? () => _performSearch(_searchController.text)
                    : _pickAndUploadDocument,
                icon: Icon(_tabController.index == 0 ? Icons.search : Icons.upload_file, size: 18),
                label: Text(_tabController.index == 0 ? 'Search' : 'Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A5F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    if (_isExtracting) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing ${_uploadedFileName ?? "document"}...',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Extracting clauses & finding precedents',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _pickAndUploadDocument,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _uploadedFileName != null ? Icons.description : Icons.cloud_upload_outlined,
                color: Colors.white.withOpacity(0.8),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _uploadedFileName ?? 'Tap to upload contract document',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: _uploadedFileName != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (_uploadedFileName == null) ...[
                const SizedBox(height: 4),
                Text(
                  'PDF, TXT, DOC, DOCX supported',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isSearching || _isExtracting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isExtracting
                  ? 'Analyzing document with LegalBERT...'
                  : 'Searching with LegalBERT embeddings...',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              _isExtracting
                  ? 'Extracting clauses and finding similar cases'
                  : 'Finding semantically similar cases',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty && _uploadedFileName == null) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty && (_searchController.text.isNotEmpty || _uploadedFileName != null)) {
      return _buildNoResultsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Text(
                '${_searchResults.length} results found',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              if (_uploadedFileName != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description, size: 12, color: Color(0xFF1E3A5F)),
                      const SizedBox(width: 4),
                      Text(
                        _uploadedFileName!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) => _buildCaseCard(_searchResults[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Semantic Legal Search',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by text or upload a contract document.\nLegalBERT will find semantically similar cases.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('breach of contract penalty'),
                _buildSuggestionChip('arbitration clause dispute'),
                _buildSuggestionChip('unfair employment termination'),
                _buildSuggestionChip('limitation of liability'),
                _buildSuggestionChip('indemnification clause'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Results Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Try different keywords or remove filters', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _tabController.animateTo(0);
        _searchController.text = text;
        _performSearch(text);
      },
      backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
      labelStyle: const TextStyle(color: Color(0xFF1E3A5F), fontSize: 12),
    );
  }

  Widget _buildCaseCard(PrecedentResult case_) {
    final double clampedScore = case_.relevanceScore.clamp(0.0, 99.9);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.gavel, color: Color(0xFF1E3A5F), size: 24),
        ),
        title: Text(
          case_.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    case_.caseNumber,
                    style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${case_.court} \u2022 ${case_.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRelevanceColor(clampedScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 12, color: _getRelevanceColor(clampedScore)),
                      const SizedBox(width: 4),
                      Text(
                        '${clampedScore.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getRelevanceColor(clampedScore),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Category badge
            if (case_.category.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  case_.category,
                  style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.w600),
                ),
              ),
            // Reason for match
            if (case_.reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  case_.reason,
                  style: TextStyle(fontSize: 11, color: Colors.teal[700], fontStyle: FontStyle.italic),
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: case_.keywords.take(4).map((keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(keyword, style: const TextStyle(fontSize: 10, color: Colors.purple)),
                );
              }).toList(),
            ),
          ],
        ),
        children: [
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailSection('Summary', case_.summary),
          const SizedBox(height: 16),
          if (case_.decision.isNotEmpty) ...[
            _buildDecisionSection(case_.decision),
            const SizedBox(height: 16),
          ],
          _buildDetailSection('Full Judgment', case_.judgment),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final text = '${case_.title}\n${case_.caseNumber}\n${case_.court} (${case_.year})\n\n${case_.summary}\n\n${case_.decision}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Case details copied to clipboard'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A5F),
                    side: const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionSection(String decision) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A5F).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, size: 16, color: Color(0xFF1E3A5F)),
              SizedBox(width: 6),
              Text(
                'Court Decision',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            decision,
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
      ],
    );
  }

  Color _getRelevanceColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
