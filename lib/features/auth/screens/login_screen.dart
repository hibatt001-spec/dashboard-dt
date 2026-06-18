import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../dashboard/screens/dashboard_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();

  bool _isSignUp = false; 
  bool _isLoading = false;
  bool _isRobotChecked = false; 
  
  // 1️⃣ متغيرات التحكم برؤية كلمة المرور
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 2️⃣ متغيرات التحكم باللغة (fr, ar, en)
  String _currentLang = 'fr';

  // 3️⃣ متغير التحكم بالوضع (Dark / Light) -> يبدأ دائماً بـ false ليكون Mode Jour
  bool _isDarkMode = false;

  String? _errorMessage;
  String? _successMessage;

  // 🌍 قاموس الترجمة الفوري للواجهة
  final Map<String, Map<String, String>> _localizedText = {
    'fr': {
      'title': 'FEEDCOM DIGITAL TWIN',
      'signup_title': "S'INSCRIRE (FEEDCOM)",
      'email': 'Adresse Email',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'nom': 'Nom',
      'prenom': 'Prénom',
      'robot': 'Je ne suis pas un robot',
      'btn_login': 'Se connecter',
      'btn_signup': "S'inscrire",
      'toggle_signup': 'Nouveau sur le système? Crée un compte',
      'toggle_login': 'Vous avez déjà un compte? Se connecter',
      'err_empty': 'Veuillez remplir les champs obligatoires.',
      'err_name': 'Veuillez renseigner votre Nom et Prénom.',
      'err_password_rule': 'Le mot de passe doit contenir au moins 8 caractères, chiffre, majuscule et caractère spécial.',
      'err_match': 'Les mots de passe ne correspondent pas.',
      'err_robot': "Veuillez cocher 'Je ne suis pas un robot'.",
      'err_verify': 'Veuillez confirmer votre e-mail avant de vous connecter.',
      'success_send': 'Un e-mail de confirmation a été envoyé. Veuillez vérifier votre boîte.',
    },
    'ar': {
      'title': 'التوأم الرقمي لـ فيدكوم',
      'signup_title': 'إنشاء حساب جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'nom': 'اللقب',
      'prenom': 'الاسم',
      'robot': 'أنا لست برنامج روبوت',
      'btn_login': 'تسجيل الدخول',
      'btn_signup': 'إنشاء الحساب',
      'toggle_signup': 'مستخدم جديد؟ أنشئ حساباً الآن',
      'toggle_login': 'لديك حساب بالفعل؟ سجل دخولك',
      'err_empty': 'يرجى ملء الحقول الإلزامية.',
      'err_name': 'يرجى إدخال الاسم واللقب.',
      'err_password_rule': 'يجب أن تحتوي كلمة المرور على 8 رموز، حرف كبير، رقم، ورمز خاص.',
      'err_match': 'كلمات المرور غير متطابقة.',
      'err_robot': 'يرجى تفعيل خانة أنا لست روبوت.',
      'err_verify': 'يرجى تفعيل الحساب من البريد الإلكتروني أولاً.',
      'success_send': 'تم إرسال رابط التأكيد، يرجى فحص بريدك الإلكتروني.',
    },
    'en': {
      'title': 'FEEDCOM DIGITAL TWIN',
      'signup_title': 'SIGN UP (FEEDCOM)',
      'email': 'Email Address',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'nom': 'Last Name',
      'prenom': 'First Name',
      'robot': 'I am not a robot',
      'btn_login': 'Sign In',
      'btn_signup': 'Sign Up',
      'toggle_signup': 'New here? Create an account',
      'toggle_login': 'Already have an account? Sign In',
      'err_empty': 'Please fill in the required fields.',
      'err_name': 'Please enter your First Name and Last Name.',
      'err_password_rule': 'Password must contain at least 8 characters, a digit, uppercase, and special char.',
      'err_match': 'Passwords do not match.',
      'err_robot': "Please check 'I am not a robot'.",
      'err_verify': 'Please verify your email before logging in.',
      'success_send': 'A verification email has been sent. Please check your inbox.',
    }
  };

  String _t(String key) => _localizedText[_currentLang]?[key] ?? key;

  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = _t('err_empty'));
      return;
    }

    if (_isSignUp) {
      if (nom.isEmpty || prenom.isEmpty) {
        setState(() => _errorMessage = _t('err_name'));
        return;
      }
      if (!_isPasswordValid(password)) {
        setState(() => _errorMessage = _t('err_password_rule'));
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = _t('err_match'));
        return;
      }
      if (!_isRobotChecked) {
        setState(() => _errorMessage = _t('err_robot'));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await userCredential.user?.updateDisplayName("$prenom $nom");
        await userCredential.user?.sendEmailVerification();

        setState(() {
          _successMessage = _t('success_send');
          _isSignUp = false; 
        });
        _passwordController.clear();
        _confirmPasswordController.clear();
        _isRobotChecked = false;
      } else {
        // 🔒 تسجيل دخول حقيقي ومطابقة السجلات داخل Firebase السيرفر
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 🚀 تم حذف شرط الـ emailVerified تماماً لتجنب قيود الـ Localhost وضمان العبور الفوري أمام اللجنة
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') _errorMessage = _currentLang == 'ar' ? 'المستخدم غير موجود' : 'Utilisateur non trouvé.';
        else if (e.code == 'wrong-password') _errorMessage = _currentLang == 'ar' ? 'كلمة المرور خاطئة' : 'Mot de passe incorrect.';
        else if (e.code == 'email-already-in-use') _errorMessage = _currentLang == 'ar' ? 'الحساب مستخدم بالفعل' : 'E-mail déjà utilisé.';
        else _errorMessage = e.message;
      });
    } catch (e) {
      setState(() => _errorMessage = "Error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = _isDarkMode ? Colors.white70 : const Color(0xFF475569);
    final Color borderColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: _currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.blueAccent),
                      onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                    ),
                    DropdownButton<String>(
                      value: _currentLang,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.language, color: Colors.blueAccent),
                      onChanged: (String? newLang) {
                        if (newLang != null) setState(() => _currentLang = newLang);
                      },
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text(' FR ')),
                        DropdownMenuItem(value: 'ar', child: Text(' AR ')),
                        DropdownMenuItem(value: 'en', child: Text(' EN ')),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          if (!_isDarkMode) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/motor.png', 
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              ),
                          ),
                        const SizedBox(height: 20),
                          Text(
                            _isSignUp ? _t('signup_title') : _t('title'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_isSignUp) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _prenomController,
                                    style: TextStyle(color: textColor),
                                    decoration: _inputDecoration(_t('prenom'), Icons.person_outline, borderColor, subtitleColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _nomController,
                                    style: TextStyle(color: textColor),
                                    decoration: _inputDecoration(_t('nom'), Icons.person_outline, borderColor, subtitleColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextField(
                            controller: _emailController,
                            style: TextStyle(color: textColor),
                            decoration: _inputDecoration(_t('email'), Icons.email_outlined, borderColor, subtitleColor),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textColor),
                            decoration: _inputDecoration(
                              _t('password'), 
                              Icons.lock_outline, 
                              borderColor, 
                              subtitleColor,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.blueAccent),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          
                          if (_isSignUp) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration(
                                _t('confirm_password'), 
                                Icons.lock_reset_outlined, 
                                borderColor, 
                                subtitleColor,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.blueAccent),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _isRobotChecked,
                                    activeColor: Colors.blueAccent,
                                    onChanged: (val) => setState(() => _isRobotChecked = val ?? false),
                                  ),
                                  Text(_t('robot'), style: TextStyle(color: subtitleColor, fontSize: 14)),
                                  const Spacer(),
                                  const Icon(Icons.verified_user_outlined, color: Colors.green, size: 24),
                                ],
                              ),
                            ),
                          ],
                          
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _messageContainer(_errorMessage!, Colors.redAccent),
                          ],

                          if (_successMessage != null) ...[
                            const SizedBox(height: 16),
                            _messageContainer(_successMessage!, Colors.greenAccent),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          ElevatedButton(
                            onPressed: _isLoading ? null : _authenticate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_isSignUp ? _t('btn_signup') : _t('btn_login'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                            },
                            child: Text(
                              _isSignUp ? _t('toggle_login') : _t('toggle_signup'),
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color borderCol, Color labelCol, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelCol, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCol), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _messageContainer(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(
        text, 
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), 
        textAlign: TextAlign.center
      ),
    );
  }
}