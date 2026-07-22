import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class ManageTripDialog extends StatefulWidget {
  final Trip trip;

  const ManageTripDialog({super.key, required this.trip});

  @override
  State<ManageTripDialog> createState() => _ManageTripDialogState();
}

class _ManageTripDialogState extends State<ManageTripDialog> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _helpers = [];
  List<Map<String, dynamic>> _vehicles = [];
  
  int? _selectedDriverId;
  int? _selectedHelperId;
  int? _selectedVehicleId;
  
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await _apiService.getTripStaffInfo();

      if (mounted) {
        setState(() {
          _drivers = info['drivers'] ?? [];
          _helpers = info['helpers'] ?? [];
          _vehicles = info['vehicles'] ?? [];
          
          // Pre-select current assignments if they exist in the lists
          _selectedDriverId = _findIdInList(_drivers, widget.trip.driverName);
          _selectedHelperId = _findIdInList(_helpers, widget.trip.helperName);
          _selectedVehicleId = _findIdInList(_vehicles, widget.trip.vehicleNo, nameKey: 'vehicleNo');
          
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load management data: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  int? _findIdInList(List<Map<String, dynamic>> items, String? name, {String nameKey = 'name'}) {
    if (name == null || name.isEmpty) return null;
    final normalizedSearch = name.trim().toLowerCase();
    
    for (var item in items) {
      final itemName = (item[nameKey] ?? item['displayName'] ?? item['name'] ?? '').toString().toLowerCase();
      if (itemName == normalizedSearch) {
        return int.tryParse(item['id']?.toString() ?? '');
      }
    }
    return null;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final success = await context.read<TripProvider>().updateTripAssignments(
      tripId: widget.trip.id,
      driverId: _selectedDriverId,
      helperId: _selectedHelperId,
      vehicleId: _selectedVehicleId,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = context.read<TripProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to update trip'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSearchablePicker({
    required String label,
    required List<Map<String, dynamic>> items,
    required int? currentValue,
    required Function(int?) onSelected,
    required IconData icon,
    String nameKey = 'name',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchablePickerSheet(
        label: label,
        items: items,
        initialValue: currentValue,
        icon: icon,
        nameKey: nameKey,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _isLoadingData
          ? const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Manage Trip',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Update driver, helper or vehicle assignments',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Trip Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${widget.trip.coachCode ?? "N/A"}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${widget.trip.fromStation} ➔ ${widget.trip.toStation}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  _buildSearchableSelector(
                    label: 'ASSIGN DRIVER',
                    value: _selectedDriverId,
                    items: _drivers,
                    icon: Icons.person_outline_rounded,
                    onTap: () => _showSearchablePicker(
                      label: 'Driver',
                      items: _drivers,
                      currentValue: _selectedDriverId,
                      icon: Icons.person_outline_rounded,
                      onSelected: (val) => setState(() => _selectedDriverId = val),
                    ),
                    onClear: () => setState(() => _selectedDriverId = null),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSearchableSelector(
                    label: 'ASSIGN HELPER',
                    value: _selectedHelperId,
                    items: _helpers,
                    icon: Icons.group_outlined,
                    onTap: () => _showSearchablePicker(
                      label: 'Helper',
                      items: _helpers,
                      currentValue: _selectedHelperId,
                      icon: Icons.support_agent_rounded,
                      onSelected: (val) => setState(() => _selectedHelperId = val),
                    ),
                    onClear: () => setState(() => _selectedHelperId = null),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSearchableSelector(
                    label: 'ASSIGN VEHICLE',
                    value: _selectedVehicleId,
                    items: _vehicles,
                    icon: Icons.local_shipping_outlined,
                    nameKey: 'vehicleNo',
                    onTap: () => _showSearchablePicker(
                      label: 'Vehicle',
                      items: _vehicles,
                      currentValue: _selectedVehicleId,
                      icon: Icons.directions_bus_rounded,
                      nameKey: 'vehicleNo',
                      onSelected: (val) => setState(() => _selectedVehicleId = val),
                    ),
                    onClear: () => setState(() => _selectedVehicleId = null),
                  ),
                  
                  const SizedBox(height: 35),
                  
                  // Info note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEBEE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Updates will be applied immediately and visible on the dashboard.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'SAVE CHANGES',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchableSelector({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
    String nameKey = 'name',
  }) {
    String displayText = 'Not Assigned';
    String? mobile;
    String? erpId;
    final isStaff = label.toLowerCase().contains('driver') || label.toLowerCase().contains('helper');

    if (value != null) {
      final item = items.firstWhere(
        (i) => int.tryParse(i['id']?.toString() ?? '') == value,
        orElse: () => {},
      );
      displayText = (item[nameKey] ?? item['displayName'] ?? item['name'] ?? 'Not Assigned').toString();
      
      if (isStaff) {
        erpId = (item['erpId'] ?? item['staff_id'] ?? item['staffId'])?.toString();
        mobile = (item['mobile'] ?? item['phone'])?.toString();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayText.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: value == null ? Colors.grey[400] : Colors.black87,
                        ),
                      ),
                      if (isStaff && value != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'EMP-ID: ${erpId != null && erpId.toLowerCase() != 'null' ? erpId : "N/A"}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (mobile != null && mobile.isNotEmpty && mobile.toLowerCase() != 'null')
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_android_rounded, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  mobile,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[600]),
                    ),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchablePickerSheet extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final int? initialValue;
  final IconData icon;
  final String nameKey;
  final Function(int?) onSelected;

  const _SearchablePickerSheet({
    required this.label,
    required this.items,
    required this.initialValue,
    required this.icon,
    required this.nameKey,
    required this.onSelected,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  late List<Map<String, dynamic>> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          final name = (item[widget.nameKey] ?? item['displayName'] ?? item['name'] ?? '').toString().toLowerCase();
          final id = (item['id'] ?? '').toString().toLowerCase();
          final erpId = (item['erpId'] ?? item['staff_id'] ?? item['staffId'] ?? '').toString().toLowerCase();
          final phone = (item['phone'] ?? item['mobile'] ?? '').toString().toLowerCase();
          final manufacturer = (item['manufacturer'] ?? item['make'] ?? item['type'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) || 
                 id.contains(query.toLowerCase()) || 
                 erpId.contains(query.toLowerCase()) ||
                 phone.contains(query.toLowerCase()) ||
                 manufacturer.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget? _buildSubtitle(Map<String, dynamic> item, String label) {
    if (label.toLowerCase().contains('vehicle')) {
      final manufacturer = (item['manufacturer'] ?? item['make'] ?? item['type'] ?? '').toString();
      if (manufacturer.isNotEmpty && manufacturer.toLowerCase() != 'null') {
        return Text(
          manufacturer.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        );
      }
      return null;
    }

    // Robust method to match UserId
    final erpId = item['erpId'] ??
                  item['staff_no'] ?? 
                  item['staffNo'] ?? 
                  item['employee_no'] ?? 
                  item['employeeNo'] ?? 
                  item['staff_id'] ?? 
                  item['staffId'] ?? 
                  item['employeeId'] ?? 
                  item['empId'] ?? 
                  item['staff_code'] ??
                  item['code'] ?? 
                  item['userId'];
                  
    final mobile = item['mobile'] ?? item['phone'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'EMP-ID: ${erpId != null && erpId.toString().toLowerCase() != 'null' ? erpId.toString() : "N/A"}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (mobile != null && mobile.toString().isNotEmpty && mobile.toString().toLowerCase() != 'null')
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_android_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  mobile.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select ${widget.label}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              autofocus: true,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search by name, ID or mobile...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filteredItems.isEmpty 
              ? Center(
                  child: Text('No results found', style: GoogleFonts.inter(color: Colors.grey)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 40),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final id = int.tryParse(item['id']?.toString() ?? '');
                    final name = (item[widget.nameKey] ?? item['displayName'] ?? item['name'] ?? 'Unknown').toString();
                    final isSelected = id == widget.initialValue;

                    return ListTile(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelected(id);
                        Navigator.pop(context);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                      title: Text(
                        name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      subtitle: _buildSubtitle(item, widget.label),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
