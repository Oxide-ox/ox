import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'btrapps/.dart';
import 'app_theme.dart';

final baseUrl = Api.api;

class DevPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const DevPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<DevPage> createState() => _DevPageState();
}

class _DevPageState extends State<DevPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = [
    'team',
    'staff',
    'owner',
    'admin',
    'vip',
    'reseller',
    'member'
  ];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  // Helpers Tema Dinamis
  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _subTextColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  bool get _isNeo => themeModeNotifier.value == 1;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  @override
  void dispose() {
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    deleteController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("Info", data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert("Error", "Gagal terhubung ke server.");
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList =
          fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("Peringatan", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);

      if (data['deleted'] == true) {
        _alert("Sukses", "User berhasil dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$baseUrl/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("Sukses",
            "Akun berhasil dibuat sebagai ${newUserRole.toUpperCase()}.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$baseUrl/editUser?key=$sessionKey&username=$u&addDays=$d',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _alert("Sukses", "Durasi berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal mengubah durasi.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          side: BorderSide(
            color: _isNeo ? Colors.black : theme.colorScheme.outline,
            width: _isNeo ? 3 : 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: _textColor)),
          ],
        ),
        content: Text(message, style: TextStyle(color: _subTextColor)),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                border:
                    _isNeo ? Border.all(color: Colors.black, width: 2) : null,
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: _isNeo && _isLight
                        ? Colors.black
                        : theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.primary),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
            borderSide: BorderSide(
              color: _isNeo
                  ? Colors.black
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
            borderSide: BorderSide(
              color: _isNeo
                  ? Colors.black
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: _isNeo ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
            borderSide: BorderSide(
              color: _isNeo ? Colors.black : theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
        border: Border.all(
          color: _isNeo
              ? Colors.black
              : theme.colorScheme.outline.withOpacity(0.3),
          width: _isNeo ? 3.0 : 1.0,
        ),
        boxShadow: _isNeo
            ? [
                const BoxShadow(
                    color: Colors.black, blurRadius: 0, offset: Offset(4, 4))
              ]
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
                  border:
                      _isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
        border: Border.all(
          color: _isNeo
              ? Colors.black
              : theme.colorScheme.outline.withOpacity(0.3),
          width: _isNeo ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border:
                  _isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
            ),
            child: Icon(Icons.person, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'] ?? '',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ROLE: ${user['role'].toString().toUpperCase()} | EXP: ${user['expiredDate']}",
                  style: TextStyle(color: _subTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isNeo ? Colors.black : Colors.redAccent.withOpacity(0.4),
                width: _isNeo ? 1.5 : 1.0,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
                      side: BorderSide(
                        color: _isNeo ? Colors.black : Colors.redAccent,
                        width: _isNeo ? 3 : 1.5,
                      ),
                    ),
                    title: Text("Konfirmasi", style: TextStyle(color: _textColor)),
                    content: Text("Hapus user ini?",
                        style: TextStyle(color: _subTextColor)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Batal",
                            style: TextStyle(color: theme.colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Hapus",
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final isSelected = currentPage == page;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            foregroundColor: isSelected
                ? (_isNeo && _isLight ? Colors.black : theme.colorScheme.onPrimary)
                : _textColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: BorderSide(
              color: _isNeo ? Colors.black : theme.colorScheme.outline.withOpacity(0.3),
              width: _isNeo ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
            ),
          ),
          child: Text("$page", style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: theme.colorScheme.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "DEV DASHBOARD",
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: BackgroundWrapper(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: _isNeo
                                  ? Border.all(color: Colors.black, width: 2.5)
                                  : null,
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: theme.colorScheme.primary,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "DEVELOPER MANAGEMENT",
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // SECTION 1: DELETE USER
                          _buildGlassCard(
                            title: "DELETE USER",
                            icon: FontAwesomeIcons.userSlash,
                            children: [
                              _buildInput(
                                label: "Username Target",
                                controller: deleteController,
                                icon: FontAwesomeIcons.user,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius:
                                      BorderRadius.circular(_isNeo ? 4 : 12),
                                  border: _isNeo
                                      ? Border.all(color: Colors.black, width: 2)
                                      : null,
                                  boxShadow: _isNeo
                                      ? [
                                          const BoxShadow(
                                            color: Colors.black,
                                            blurRadius: 0,
                                            offset: Offset(3, 3),
                                          )
                                        ]
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.redAccent.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _deleteUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(_isNeo ? 4 : 12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        "DELETE ACCOUNT",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // SECTION 2: CREATE ACCOUNT
                          _buildGlassCard(
                            title: "CREATE ACCOUNT",
                            icon: FontAwesomeIcons.userPlus,
                            children: [
                              _buildInput(
                                label: "Username",
                                controller: createUsernameController,
                                icon: FontAwesomeIcons.user,
                              ),
                              _buildInput(
                                label: "Password",
                                controller: createPasswordController,
                                icon: FontAwesomeIcons.lock,
                              ),
                              _buildInput(
                                label: "Durasi (Hari)",
                                controller: createDayController,
                                icon: FontAwesomeIcons.calendarDay,
                                type: TextInputType.number,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius:
                                      BorderRadius.circular(_isNeo ? 4 : 12),
                                  border: Border.all(
                                    color: _isNeo
                                        ? Colors.black
                                        : theme.colorScheme.outline
                                            .withOpacity(0.3),
                                    width: _isNeo ? 2 : 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: newUserRole,
                                    dropdownColor: theme.colorScheme.surface,
                                    style: TextStyle(color: _textColor),
                                    items: roleOptions.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(role.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(
                                        () => newUserRole = val ?? 'member'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(_isNeo ? 4 : 12),
                                  border: _isNeo
                                      ? Border.all(color: Colors.black, width: 2)
                                      : null,
                                  boxShadow: _isNeo
                                      ? [
                                          const BoxShadow(
                                            color: Colors.black,
                                            blurRadius: 0,
                                            offset: Offset(3, 3),
                                          )
                                        ]
                                      : [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _createAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(_isNeo ? 4 : 12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _isNeo && _isLight
                                                ? Colors.black
                                                : theme.colorScheme.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          "CREATE ACCOUNT",
                                          style: TextStyle(
                                            color: _isNeo && _isLight
                                                ? Colors.black
                                                : theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          // SECTION 3: EXTEND DURATION
                          _buildGlassCard(
                            title: "EXTEND DURATION",
                            icon: FontAwesomeIcons.clock,
                            children: [
                              _buildInput(
                                label: "Username Target",
                                controller: editUsernameController,
                                icon: FontAwesomeIcons.userPen,
                              ),
                              _buildInput(
                                label: "Tambah Hari",
                                controller: editDayController,
                                icon: FontAwesomeIcons.calendarPlus,
                                type: TextInputType.number,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius:
                                      BorderRadius.circular(_isNeo ? 4 : 12),
                                  border: _isNeo
                                      ? Border.all(color: Colors.black, width: 2)
                                      : null,
                                  boxShadow: _isNeo
                                      ? [
                                          const BoxShadow(
                                            color: Colors.black,
                                            blurRadius: 0,
                                            offset: Offset(3, 3),
                                          )
                                        ]
                                      : [
                                          BoxShadow(
                                            color: theme.colorScheme.secondary
                                                .withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _editUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(_isNeo ? 4 : 12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _isNeo && _isLight
                                                ? Colors.black
                                                : theme.colorScheme.onSecondary,
                                          ),
                                        )
                                      : Text(
                                          "ADD DAYS",
                                          style: TextStyle(
                                            color: _isNeo && _isLight
                                                ? Colors.black
                                                : theme.colorScheme.onSecondary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          // SECTION 4: USER LIST
                          _buildGlassCard(
                            title: "USER LIST",
                            icon: FontAwesomeIcons.users,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius:
                                      BorderRadius.circular(_isNeo ? 4 : 12),
                                  border: Border.all(
                                    color: _isNeo
                                        ? Colors.black
                                        : theme.colorScheme.outline
                                            .withOpacity(0.3),
                                    width: _isNeo ? 2 : 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    dropdownColor: theme.colorScheme.surface,
                                    style: TextStyle(color: _textColor),
                                    items: roleOptions.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(role.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        selectedRole = val;
                                        _filterAndPaginate();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        ..._getCurrentPageData()
                                            .map((u) => _buildUserItem(u))
                                            .toList(),
                                        const SizedBox(height: 20),
                                        _buildPagination(),
                                      ],
                                    ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
