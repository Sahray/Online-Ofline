import 'package:app_inspections/providers/login_form_provider.dart';
import 'package:app_inspections/services/services.dart';
import 'package:app_inspections/src/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 400),
              CardContainer(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Inicio de Sesión',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: MediaQuery.of(context).size.width * 0.05,
                          ),
                    ),
                    const SizedBox(height: 20),
                    ChangeNotifierProvider(
                      create: (_) => LoginFormProvider(),
                      child: _LoginForm(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              // Botón "Crear una nueva cuenta"
              /*TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, 'registro');
                },
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(
                    const Color.fromARGB(255, 169, 181, 63).withOpacity(0.1),
                  ),
                  shape: MaterialStateProperty.all(const StadiumBorder()),
                ),
                child: Text(
                  'Crear una nueva cuenta',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.02,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(169, 27, 96, 1),
                  ),
                ),
              ), */
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final loginForm = Provider.of<LoginFormProvider>(context);

    return Form(
      key: loginForm.formkey,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextFormField(
              autocorrect: false,
              keyboardType: TextInputType.name,
              onChanged: (value) => loginForm.usuario = value,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Escribe tu usuario';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Nombre de Usuario',
                labelText: 'Usuario',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(169, 27, 96, 1),
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(169, 27, 96, 1),
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextFormField(
              obscureText: _obscurePassword,
              onChanged: (value) => loginForm.password = value,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                return (value != null && value.length >= 6)
                    ? null
                    : 'La contraseña debe tener al menos 6 caracteres';
              },
              decoration: InputDecoration(
                hintText: '***********',
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color.fromRGBO(6, 6, 68, 1),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(169, 27, 96, 1),
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(169, 27, 96, 1),
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledColor: Colors.grey,
            elevation: 0,
            color: const Color.fromRGBO(6, 6, 68, 1),
            onPressed: loginForm.isLoading
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    final authService =
                        Provider.of<AuthService>(context, listen: false);

                    if (!loginForm.isValidForm()) return;

                    loginForm.isLoading = true;

                    final String? errorMessage = await authService.login(
                        loginForm.usuario, loginForm.password);
                    if (errorMessage == null) {
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(
                          // ignore: use_build_context_synchronously
                          context,
                          'inicioInsp');
                    } else {
                      const snackBar = SnackBar(
                        content: Text('La contraseña o correo no coinciden'),
                        backgroundColor: Color.fromARGB(255, 1, 25, 66),
                      );
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      loginForm.isLoading = false;
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              child: Text(
                loginForm.isLoading ? 'Espere' : 'Ingresar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
