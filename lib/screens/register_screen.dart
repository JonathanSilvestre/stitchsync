import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _selectedCountry;

  static const List<String> _countries = [
    'Mexico',
    'United States',
    'Spain',
    'Argentina',
    'Colombia',
    'Chile',
    'Peru',
  ];

  static const Color _bg = Color(0xFF060E20);
  static const Color _surface = Color(0xFF131E33);
  static const Color _surfaceHigh = Color(0xFF1E2E50);
  static const Color _title = Color(0xFFDEE5FF);
  static const Color _muted = Color(0xFFA3AAC4);
  static const Color _primary = Color(0xFF74B1FF);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los terminos para continuar.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _auth.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        country: _selectedCountry ?? '',
      );

      if (!mounted) {
        return;
      }

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta creada. Verifica tu correo y luego inicia sesión.',
            ),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_auth.getReadableAuthError(e))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not complete sign up.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A1730),
                    _bg,
                    const Color(0xFF030B17),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pets,
                        color: Color(0xFF74B1FF),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'StitchSync',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFAED0FF),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.question_mark,
                            size: 20, color: Color(0xFF0B1220)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 12, 30, 0.46),
                          blurRadius: 42,
                          offset: Offset(0, 24),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFF20345B),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF33568B),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.pets,
                                size: 46,
                                color: Color(0xFF74B1FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _title,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start your collaborative journey today',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildFieldLabel('USERNAME'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _usernameController,
                            hint: 'johndoe',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre de usuario';
                              }

                              if (value.trim().length < 3) {
                                return 'El usuario debe tener al menos 3 caracteres';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('EMAIL'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _emailController,
                            hint: 'john@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu correo';
                              }

                              if (!value.contains('@')) {
                                return 'Ingresa un correo valido';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('PASSWORD'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _passwordController,
                            hint: '........',
                            icon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A0B7),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }

                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('CONFIRM PASSWORD'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _confirmPasswordController,
                            hint: '........',
                            icon: Icons.shield_outlined,
                            obscureText: _obscureConfirmPassword,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A0B7),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirma tu contraseña';
                              }

                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('ADDRESS'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _addressController,
                            hint: '123 Bark Street, NYC',
                            icon: Icons.location_on_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu direccion';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('AGE'),
                                    const SizedBox(height: 8),
                                    _buildInput(
                                      controller: _ageController,
                                      hint: '25',
                                      icon: Icons.cake_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Edad';
                                        }

                                        final age =
                                            int.tryParse(value.trim());
                                        if (age == null || age < 13) {
                                          return 'Min. 13';
                                        }

                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('COUNTRY'),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedCountry,
                                      isExpanded: true,
                                      items: _countries
                                          .map(
                                            (country) => DropdownMenuItem(
                                              value: country,
                                              child: Text(
                                                country,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCountry = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Pais';
                                        }

                                        return null;
                                      },
                                      decoration: _dropdownDecoration(),
                                      dropdownColor: const Color(0xFF203258),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFFA0ABC2),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFFD8DFF2),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF74B1FF),
                                checkColor: const Color(0xFF041326),
                                side: const BorderSide(
                                  color: Color(0xFF4B5A78),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                      children: [
                                        TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: TextStyle(
                                            color: Color(0xFF8DC0FF),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: Color(0xFF8DC0FF),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFA8CBFF),
                                  Color(0xFF67A8F0),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(68, 124, 207, 0.28),
                                  blurRadius: 22,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: const Color(0xFF0E2C52),
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFF0E2C52),
                                      ),
                                    )
                                  : const Text('Register'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFFE6AAFF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '© 2024 STITCHSYNC GLOBAL SYSTEMS. BUILT FOR BETTER COMPANIONSHIP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3A4862),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.7,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFAAB4C8),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        color: Color(0xFFD8DFF2),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF76829A),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9AA5BE)),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      hintText: 'Select',
      hintStyle: const TextStyle(
        color: Color(0xFF76829A),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
    );
  }
}