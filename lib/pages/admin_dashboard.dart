import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/services/admin_service.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';
import 'package:kreisel_frontend/pages/login_page.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const List<String> LOCATIONS = [
    'PASING',
    'KARLSTRASSE',
    'LOTHSTRASSE',
  ];
  static const List<String> GENDERS = ['UNISEX', 'HERREN', 'DAMEN'];
  static const List<String> CATEGORIES = ['EQUIPMENT', 'KLEIDUNG'];
  static const Map<String, List<String>> SUBCATEGORIES = {
    'EQUIPMENT': ['HELME', 'SKI', 'SNOWBOARDS', 'BRILLEN', 'FLASCHEN'],
    'KLEIDUNG': [
      'JACKEN',
      'HOSEN',
      'HANDSCHUHE',
      'MUETZEN',
      'SCHALS',
      'STIEFEL',
      'WANDERSCHUHE',
    ],
  };
  static const List<String> CONDITIONS = ['NEU', 'GEBRAUCHT'];

  int _selectedTab = 0;
  String _selectedLocation = 'PASING'; // Default location
  bool _isLoading = false;
  List<Item> _items = [];
  List<Rental> _rentals = [];
  List<User> _users = [];
  final _searchController = TextEditingController();
  bool _canCreateItems = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    _loadPermissions();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Check if admin is still authenticated
    final isAuthenticated = await AdminService.isAdminAuthenticated();
    if (!isAuthenticated) {
      _logout();
      return;
    }
    _loadData();
  }

  Future<void> _loadPermissions() async {
    try {
      _canCreateItems = await AdminService.canCreateItems();
      setState(() {}); // Update UI with new permissions
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load permissions')));
    }
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSegmentedControl<String>(
        children: {
          'PASING': Padding(padding: EdgeInsets.all(8), child: Text('Pasing')),
          'KARLSTRASSE': Padding(
            padding: EdgeInsets.all(8),
            child: Text('Karlstraße'),
          ),
          'LOTHSTRASSE': Padding(
            padding: EdgeInsets.all(8),
            child: Text('Lothstraße'),
          ),
        },
        onValueChanged: (String value) {
          setState(() {
            _selectedLocation = value;
          });
          _loadData(); // Reload items with new location
        },
        groupValue: _selectedLocation,
      ),
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Ensure we're still authenticated before making requests
      final isAuth = await AdminService.ensureAuthenticated();
      if (!isAuth) {
        _logout();
        return;
      }

      switch (_selectedTab) {
        case 0:
          _items = await AdminService.getAllItems(_selectedLocation);
          break;
        case 1:
          _rentals = await AdminService.getAllRentals();
          break;
        case 2:
          _users = await AdminService.getAllUsers();
          break;
      }
    } catch (e) {
      print('DEBUG: Load data error: $e');
      // Check if it's an authentication error
      if (e.toString().contains('Token') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        _logout();
        return;
      }
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildNavButton('Items', 0),
                SizedBox(width: 8),
                _buildNavButton('Rentals', 1),
                SizedBox(width: 8),
                _buildNavButton('Users', 2),
              ],
            ),
          ),

          // Location Selector (only show for items tab)
          if (_selectedTab == 0) _buildLocationSelector(),

          // Search Bar (only show for rentals and users)
          if (_selectedTab > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onChanged: (value) {
                  // Debounce search to avoid too many requests
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _handleSearch(value);
                    }
                  });
                },
                onSubmitted: _handleSearch,
                placeholder: 'Suche...',
                style: TextStyle(color: Colors.white),
              ),
            ),

          Expanded(
            child:
                _isLoading
                    ? Center(child: CupertinoActivityIndicator())
                    : _buildContent(),
          ),
        ],
      ),
      floatingActionButton:
          _selectedTab ==
                  0 // Wenn Items-Tab ausgewählt ist
              ? FloatingActionButton(
                backgroundColor: Color(0xFF007AFF),
                child: Icon(Icons.add, color: Colors.white),
                onPressed: _createItem,
              )
              : null,
    );
  }

  Widget _buildNavButton(String title, int index) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.all(12),
        color: _selectedTab == index ? Color(0xFF007AFF) : Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
        onPressed: () {
          setState(() => _selectedTab = index);
          _searchController.clear();
          _loadData();
        },
        child: Text(title, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildItemsList();
      case 1:
        return _buildRentalsList();
      case 2:
        return _buildUsersList();
      default:
        return Container();
    }
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Keine Items für $_selectedLocation gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder:
            (context, index) => Card(
              color: Color(0xFF1C1C1E),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  _items[index].name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Standort: ${_items[index].location}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'Status: ${_items[index].available ? "Verfügbar" : "Nicht verfügbar"}',
                      style: TextStyle(
                        color:
                            _items[index].available ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      'Kategorie: ${_items[index].category} - ${_items[index].subcategory}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    if (_items[index].brand?.isNotEmpty ?? false)
                      Text(
                        'Marke: ${_items[index].brand}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    if (_items[index].size?.isNotEmpty ?? false)
                      Text(
                        'Größe: ${_items[index].size}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    SizedBox(height: 4),
                  ],
                ),
                trailing: Container(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF007AFF)),
                        onPressed: () => _showItemDialog(_items[index]),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(_items[index].id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildRentalsList() {
    if (_rentals.isEmpty) {
      return Center(
        child: Text(
          'Keine Rentals gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _rentals.length,
        itemBuilder:
            (context, index) => Card(
              color: Color(0xFF1C1C1E),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  'Rental #${_rentals[index].id}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'User: ${_rentals[index].user.fullName}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'Email: ${_rentals[index].user.email}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'Item: ${_rentals[index].item.name}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'Status: ${_rentals[index].status}',
                      style: TextStyle(
                        color: _getStatusColor(_rentals[index].status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      case 'RETURNED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'Keine Users gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder:
            (context, index) => Card(
              color: Color(0xFF1C1C1E),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  _users[index].fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _users[index].email,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.info_outline, color: Color(0xFF007AFF)),
                  onPressed: () => _showUserDetails(_users[index]),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _createItem() async {
    await _showItemDialog(null);
  }

  Future<void> _showItemDialog(Item? item) async {
    final isCreating = item == null;

    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final brandController = TextEditingController(text: item?.brand ?? '');
    final sizeController = TextEditingController(text: item?.size ?? '');

    // For location, use current selected location for new items
    String selectedLocation =
        isCreating ? _selectedLocation : (item?.location ?? LOCATIONS.first);
    String selectedGender = item?.gender ?? GENDERS.first;
    String selectedCategory = item?.category ?? CATEGORIES.first;
    String selectedSubcategory =
        item?.subcategory ?? SUBCATEGORIES[CATEGORIES.first]!.first;
    String selectedZustand = item?.zustand ?? CONDITIONS.first;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: Color(0xFF1C1C1E),
                  title: Text(
                    isCreating ? 'Neues Item erstellen' : 'Item bearbeiten',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabeledTextField('Name:', nameController),
                        _buildLabeledTextField(
                          'Beschreibung:',
                          descriptionController,
                        ),
                        _buildLabeledTextField('Marke:', brandController),
                        _buildLabeledTextField('Größe:', sizeController),

                        // Location Dropdown
                        _buildLabeledDropdown(
                          'Standort:',
                          selectedLocation,
                          LOCATIONS,
                          (value) =>
                              setDialogState(() => selectedLocation = value!),
                        ),

                        // Gender Dropdown
                        _buildLabeledDropdown(
                          'Gender:',
                          selectedGender,
                          GENDERS,
                          (value) =>
                              setDialogState(() => selectedGender = value!),
                        ),

                        // Category Dropdown
                        _buildLabeledDropdown(
                          'Kategorie:',
                          selectedCategory,
                          CATEGORIES,
                          (value) {
                            setDialogState(() {
                              selectedCategory = value!;
                              // Reset subcategory when category changes
                              selectedSubcategory = SUBCATEGORIES[value]!.first;
                            });
                          },
                        ),

                        // Subcategory Dropdown
                        _buildLabeledDropdown(
                          'Unterkategorie:',
                          selectedSubcategory,
                          SUBCATEGORIES[selectedCategory]!,
                          (value) => setDialogState(
                            () => selectedSubcategory = value!,
                          ),
                        ),

                        // Zustand Dropdown
                        _buildLabeledDropdown(
                          'Zustand:',
                          selectedZustand,
                          CONDITIONS,
                          (value) =>
                              setDialogState(() => selectedZustand = value!),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text(
                        isCreating ? 'Erstellen' : 'Speichern',
                        style: TextStyle(color: Color(0xFF007AFF)),
                      ),
                      onPressed: () async {
                        // Validate required fields
                        if (nameController.text.trim().isEmpty) {
                          _showError('Name ist erforderlich');
                          return;
                        }

                        try {
                          final updatedItem = Item(
                            id: item?.id ?? 0,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            brand: brandController.text.trim(),
                            size: sizeController.text.trim(),
                            available: item?.available ?? true,
                            location: selectedLocation,
                            gender: selectedGender,
                            category: selectedCategory,
                            subcategory: selectedSubcategory,
                            zustand: selectedZustand,
                          );

                          if (isCreating) {
                            try {
                              await AdminService.createItem(updatedItem);
                              Navigator.pop(context, true);
                            } catch (e) {
                              print('DEBUG: Item creation failed: $e');
                              _showError(e.toString());
                            }
                          } else {
                            await AdminService.updateItem(
                              item!.id,
                              updatedItem,
                            );
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          print('DEBUG: Item save error: $e');
                          if (e.toString().contains('Token') ||
                              e.toString().contains('401') ||
                              e.toString().contains('403')) {
                            Navigator.pop(context, false);
                            _logout();
                            return;
                          }
                          _showError(e.toString());
                        }
                      },
                    ),
                  ],
                ),
          ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Color(0xFF2C2C2E) : Color(0xFF1C1C1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    // Ensure value exists in options
    if (!options.contains(value)) {
      print(
        'DEBUG: Invalid value "$value" for $label. Defaulting to first option.',
      );
      value = options.first;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              onChanged: onChanged,
              items:
                  options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              dropdownColor: Color(0xFF2C2C2E),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      switch (_selectedTab) {
        case 1: // Rentals
          _rentals = await AdminService.getAllRentals();
          _rentals =
              _rentals
                  .where(
                    (rental) =>
                        rental.id.toString().contains(query) ||
                        rental.user.fullName.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        rental.user.email.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        rental.item.name.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                  )
                  .toList();
          break;
        case 2: // Users
          _users = await AdminService.getAllUsers();
          _users =
              _users
                  .where(
                    (user) =>
                        user.fullName.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        user.email.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
          break;
      }
    } catch (e) {
      print('DEBUG: Search error: $e');
      if (e.toString().contains('Token') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        _logout();
        return;
      }
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    try {
      await AdminService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('DEBUG: Logout error: $e');
      // Force navigation even if logout fails
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Item löschen'),
            content: Text('Möchten Sie dieses Item wirklich löschen?'),
            actions: [
              CupertinoDialogAction(
                child: Text('Abbrechen'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('Löschen'),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await AdminService.deleteItem(id);
                    _loadData();
                  } catch (e) {
                    print('DEBUG: Delete item error: $e');
                    if (e.toString().contains('Token') ||
                        e.toString().contains('401') ||
                        e.toString().contains('403')) {
                      _logout();
                      return;
                    }
                    _showError(e.toString());
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showUserDetails(User user) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF1C1C1E),
            title: Text('User Details', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${user.fullName}',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Email: ${user.email}',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                Text('ID: ${user.id}', style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  'Schließen',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Fehler'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
