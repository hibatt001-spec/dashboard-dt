import 'package:digital_twin_control_center/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../dashboard/screens/dashboard_screen.dart'; // 🟢 الشاشة التي سيتم الانتقال إليها

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool isLoading = false;

  String email = '';
  String password = '';
  String nom = '';
  String prenom = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        if (isLogin) {
          // 1️⃣ تسجيل الدخول عبر Firebase Auth
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // 🚀 التعديل الجوهري: الانتقال الفوري والمباشر إلى الـ Dashboard عند نجاح الـ Login
          if (userCredential.user != null && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          // 2️⃣ إنشاء حساب جديد (Inscription)
          UserCredential userCredential = await _auth
              .createUserWithEmailAndPassword(email: email, password: password);

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'nom': nom,
            'prenom': prenom,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 🚀 الانتقال الفوري والمباشر إلى الـ Dashboard أيضاً بعد إتمام عملية التسجيل بنجاح
          if (userCredential.user != null && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      } catch (e) {
        String errorMessage = "Une erreur est survenue";
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            errorMessage = "Utilisateur non trouvé";
          }
          if (e.code == 'wrong-password') {
            errorMessage = "Mot de passe incorrect";
          }
          if (e.code == 'email-already-in-use') {
            errorMessage = "Cet email est déjà utilisé";
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyanColor = const Color(0xFF00F0FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.4)
        : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ☀️ 🌙 زر تبديل الثيم
          Positioned(
            top: 20,
            right: 20,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                return IconButton(
                  icon: Icon(
                    currentMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  onPressed: () {
                    themeNotifier.value = currentMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                  },
                );
              },
            ),
          ),

          // محتوى الصفحة الرئيسي
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    width: 460,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Digital Twin',
                            style: GoogleFonts.outfit(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'CONTROL CENTER',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 4.0,
                            ),
                          ),
                          const SizedBox(height: 30),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.25),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                "assets/images/motor.png",
                                width: 440,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 440,
                                    height: 200,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey[300],
                                    child: Icon(
                                      Icons.developer_board,
                                      color: Theme.of(context).primaryColor,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),

                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (!isLogin) ...[
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Nom',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    validator: (v) => v!.isEmpty
                                        ? 'Veuillez entrer votre nom'
                                        : null,
                                    onSaved: (v) => nom = v!.trim(),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Prénom',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (v) => v!.isEmpty
                                        ? 'Veuillez entrer votre prénom'
                                        : null,
                                    onSaved: (v) => prenom = v!.trim(),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => !v!.contains('@')
                                      ? 'Email invalide'
                                      : null,
                                  onSaved: (v) => email = v!.trim(),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Mot de passe',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  obscureText: true,
                                  validator: (v) => v!.length < 6
                                      ? 'Minimum 6 caractères'
                                      : null,
                                  onSaved: (v) => password = v!,
                                ),
                                const SizedBox(height: 28),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: isDark
                                          ? const Color(0xFF0F172A)
                                          : Colors.white,
                                      shadowColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.4),
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isLoading ? null : _submitForm,
                                    child: isLoading
                                        ? CircularProgressIndicator(
                                            color: isDark
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                          )
                                        : Text(
                                            isLogin
                                                ? 'SE CONNECTER'
                                                : 'S\'INSCRIRE',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                TextButton(
                                  onPressed: () =>
                                      setState(() => isLogin = !isLogin),
                                  child: Text(
                                    isLogin
                                        ? "Créer un compte (Inscription)"
                                        : "J'ai déjà un compte (Connexion)",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}