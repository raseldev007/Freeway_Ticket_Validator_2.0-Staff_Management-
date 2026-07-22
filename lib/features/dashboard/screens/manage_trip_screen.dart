import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/api_service.dart';
import 'how_to_use_screen.dart';

class ManageTripScreen extends StatefulWidget {
  final Trip trip;
  const ManageTripScreen({super.key, required this.trip});

  @override
  State<ManageTripScreen> createState() => _ManageTripScreenState();
}

class _ManageTripScreenState extends State<ManageTripScreen> {
  final ApiService _apiService = ApiService();
  
  List<StaffDetails> _drivers = [];
  List<StaffDetails> _helpers = [];
  List<VehicleDetails> _vehicles = [];
  
  StaffDetails? _selectedDriver;
  StaffDetails? _selectedHelper;
  VehicleDetails? _selectedVehicle;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDriver = widget.trip.driver;
    _selectedHelper = widget.trip.helper;
    _selectedVehicle = widget.trip.vehicle;
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final info = await _apiService.getTripStaffInfo();
      
      if (mounted) {
        setState(() {
          _drivers = (info['drivers'] as List)
              .map((e) => StaffDetails.fromJson(e))
              .toList();
          _helpers = (info['helpers'] as List)
              .map((e) => StaffDetails.fromJson(e))
              .toList();
          _vehicles = (info['vehicles'] as List)
              .map((e) => VehicleDetails.fromJson(e))
              .toList();
          
          // Match current selections with loaded items to ensure we have the all of complete datas

          if (_selectedDriver != null && _drivers.isNotEmpty) {
            final match = _drivers.where((d) => 
              d.id.toString() == _selectedDriver?.id.toString() || 
              (d.erpId != null && d.erpId == _selectedDriver?.erpId)
            );
            if (match.isNotEmpty) _selectedDriver = match.first;
          }
          
          if (_selectedHelper != null && _helpers.isNotEmpty) {
            final match = _helpers.where((h) => 
              h.id.toString() == _selectedHelper?.id.toString() || 
              (h.erpId != null && h.erpId == _selectedHelper?.erpId)
            );
            if (match.isNotEmpty) _selectedHelper = match.first;
          }

          if (_selectedVehicle != null && _vehicles.isNotEmpty) {
            final match = _vehicles.where((v) => 
              v.id.toString() == _selectedVehicle?.id.toString() || 
              v.vehicleNo == _selectedVehicle?.vehicleNo
            );
            if (match.isNotEmpty) _selectedVehicle = match.first;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resources: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('hh:mm a').format(dateTime.toUtc().add(const Duration(hours: 6)));
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(dateTime.toUtc().add(const Duration(hours: 6)));
  }

  Future<void> _handleSave() async {
    if (_selectedDriver == null || _selectedHelper == null || _selectedVehicle == null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all fields (Driver, Helper, and Vehicle).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<TripProvider>();
    
    try {
      final success = await provider.updateTripAssignments(
        tripId: widget.trip.id,
        driverId: _selectedDriver?.id,
        helperId: _selectedHelper?.id,
        vehicleId: _selectedVehicle?.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip updated successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context, true); // Return true ,, signal change
      } else if (mounted) {
        _showErrorDialog(provider.errorMessage ?? 'Failed to update trip assignments. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Update Failed',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading 
          ? _buildShimmerLoading()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Trip',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Update driver, helper or vehicle assignments',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTripSummaryCard(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Assign Driver'),
                  _buildSearchSelector<StaffDetails>(
                    value: _selectedDriver,
                    items: _drivers,
                    hint: 'Select Driver',
                    icon: Icons.person,
                    onTap: () => _openSearchPicker<StaffDetails>(
                      title: 'SELECT DRIVER',
                      items: _drivers,
                      onSelected: (val) => setState(() => _selectedDriver = val),
                      itemBuilder: (d) => d.displayName ?? 'Unknown Staff',
                      subTitleBuilder: (d) => 'EMP-ID: ${d.erpId ?? "N/A"}|MOBILE: ${d.mobile ?? ""}',
                    ),
                    itemLabel: (d) => d.displayName ?? 'Unknown Staff',
                    subLabel: (d) => 'EMP-ID: ${d.erpId ?? "N/A"}|MOBILE: ${d.mobile ?? ""}',
                    onClear: () => setState(() => _selectedDriver = null),
                  ),
                  
                  const SizedBox(height: 14),
                  _buildSectionTitle('Assign Helper'),
                  _buildSearchSelector<StaffDetails>(
                    value: _selectedHelper,
                    items: _helpers,
                    hint: 'Select Helper',
                    icon: Icons.group_outlined,
                    onTap: () => _openSearchPicker<StaffDetails>(
                      title: 'SELECT HELPER',
                      items: _helpers,
                      onSelected: (val) => setState(() => _selectedHelper = val),
                      itemBuilder: (h) => h.displayName ?? 'Unknown Staff',
                      subTitleBuilder: (h) => 'EMP-ID: ${h.erpId ?? "N/A"}|MOBILE: ${h.mobile ?? ""}',
                    ),
                    itemLabel: (h) => h.displayName ?? 'Unknown Staff',
                    subLabel: (h) => 'EMP-ID: ${h.erpId ?? "N/A"}|MOBILE: ${h.mobile ?? ""}',
                    onClear: () => setState(() => _selectedHelper = null),
                  ),
                  
                  const SizedBox(height: 14),
                  _buildSectionTitle('Assign Vehicle'),
                  _buildSearchSelector<VehicleDetails>(
                    value: _selectedVehicle,
                    items: _vehicles,
                    hint: 'Select Vehicle',
                    icon: Icons.bus_alert,
                    onTap: () => _openSearchPicker<VehicleDetails>(
                      title: 'SELECT VEHICLE',
                      items: _vehicles,
                      onSelected: (val) => setState(() => _selectedVehicle = val),
                      itemBuilder: (v) => v.vehicleNo ?? v.registrationNo ?? 'Unknown',
                      subTitleBuilder: (v) {
                        final reg = v.registrationNo ?? '';
                        final manufacturer = v.manufacturer ?? '';
                        if (manufacturer.isNotEmpty && manufacturer.toLowerCase() != 'null') {
                          return '$reg${reg.isNotEmpty ? ' • ' : ''}${manufacturer.toUpperCase()}';
                        }
                        return reg;
                      },
                    ),
                    itemLabel: (v) => v.vehicleNo ?? v.registrationNo ?? 'Unknown',
                    subLabel: (v) => (v.manufacturer?.isNotEmpty ?? false) && v.manufacturer?.toLowerCase() != 'null' 
                        ? v.manufacturer?.toUpperCase() 
                        : null,
                    onClear: () => setState(() => _selectedVehicle = null),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildInfoBox(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      period: const Duration(seconds: 2),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 250,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 40),
            
            ...List.generate(3, (index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  margin: const EdgeInsets.only(bottom: 12, left: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            )),
            
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Manage Trip',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      foregroundColor: AppColors.textPrimary,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 22,
          color: AppColors.primary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'How to Use',
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HowToUseScreen()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFFEF5350)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('#', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            Text(
                              widget.trip.id.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.trip.fromCode} → ${widget.trip.toCode}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDate(widget.trip.departureTime)} • ${_formatDateTime(widget.trip.departureTime)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Colors.black,
        ),
      ),
    );
  }

  void _openSearchPicker<T>({
    required String title,
    required List<T> items,
    required Function(T) onSelected,
    required String Function(T) itemBuilder,
    String Function(T)? subTitleBuilder,
  }) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchablePickerSheet<T>(
        title: title,
        items: items,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        subTitleBuilder: subTitleBuilder,
      ),
    );
  }

  Widget _buildSearchSelector<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required String Function(T) itemLabel,
    String? Function(T)? subLabel,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value != null ? itemLabel(value) : hint,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: value != null ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (value != null && subLabel != null && subLabel(value) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: _buildSubLabelWithIcons(subLabel(value)!),
                    ),
                ],
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onClear();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.black),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Updates will be applied immediately and visible on the dashboard.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () {
          HapticFeedback.mediumImpact();
          _handleSave();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isSaving 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Widget _buildSubLabelWithIcons(String subLabel) {
    if (subLabel.contains('|')) {
      final parts = subLabel.split('|');
      final empId = parts[0];
      final mobile = parts.length > 1 ? parts[1].replaceAll('MOBILE: ', '') : '';

      return Wrap(
        spacing: 12,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                empId,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (mobile.isNotEmpty && mobile.toLowerCase() != 'null')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_android_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  mobile,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      );
    }
    
    return Text(
      subLabel,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Function(T) onSelected;
  final String Function(T) itemBuilder;
  final String Function(T)? subTitleBuilder;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.onSelected,
    required this.itemBuilder,
    this.subTitleBuilder,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() => _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        final queryLower = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          final label = widget.itemBuilder(item).toLowerCase();
          final subLabel = widget.subTitleBuilder?.call(item).toLowerCase() ?? '';
          
          // cast to dynamic to check for mobile field safely if it exists in object heree


          String mobileSearch = '';
          try {
             final dynamic dItem = item;
             mobileSearch = (dItem.mobile?.toString() ?? '').toLowerCase();
          } catch (_) {}

          return label.contains(queryLower) || 
                 subLabel.contains(queryLower) || 
                 mobileSearch.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEARCH & SELECT',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              autofocus: true,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: _filteredItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return InkWell(
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.itemBuilder(item),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (widget.subTitleBuilder != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: _buildSubLabelWithIcons(widget.subTitleBuilder!(item)),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
