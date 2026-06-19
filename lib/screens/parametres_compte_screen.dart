import 'package:flutter/material.dart';

class ParametresCompteScreen extends StatefulWidget {
  const ParametresCompteScreen({super.key});

  @override
  State<ParametresCompteScreen> createState() => _ParametresCompteScreenState();
}

class _ParametresCompteScreenState extends State<ParametresCompteScreen> {
  String nomComplet = 'Antoine Kakawah';
  String nomUtilisateur = 'antoinekakawah';
  String email = 'antoine@email.com';
  String telephone = '+225 07 00 00 00 00';

  bool notificationsActives = true;
  bool rappelActif = true;
  String langueSelectionnee = 'Français';

  void _ouvrirModificationProfil() async {
    final resultat = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierProfilScreen(
          nomComplet: nomComplet,
          nomUtilisateur: nomUtilisateur,
          email: email,
          telephone: telephone,
        ),
      ),
    );

    if (resultat != null) {
      setState(() {
        nomComplet = resultat['nomComplet'] as String;
        nomUtilisateur = resultat['nomUtilisateur'] as String;
        email = resultat['email'] as String;
        telephone = resultat['telephone'] as String;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informations mises à jour avec succès'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _ouvrirChoixLangue() async {
    final langue = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final langues = ['Français', 'English', 'Español'];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir la langue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              ...langues.map(
                (langueItem) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    langueSelectionnee == langueItem
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xFF3047A5),
                  ),
                  title: Text(langueItem),
                  onTap: () => Navigator.pop(context, langueItem),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (langue != null) {
      setState(() {
        langueSelectionnee = langue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Langue changée en $langue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _modifierMotDePasse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModifierMotDePasseScreen(),
      ),
    );
  }

  void _voirSecuriteCompte() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sécurité du compte'),
        content: const Text(
          'Tu peux ici vérifier l’état de sécurité du compte, '
          'mettre à jour ton mot de passe et renforcer la protection de ton accès.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _deconnexion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Veux-tu vraiment te déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Déconnexion effectuée'),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Ici tu pourras ajouter la vraie logique de déconnexion
              // Exemple FirebaseAuth.instance.signOut();
            },
            child: const Text('Oui, déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Paramètres du compte'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),

          _buildSectionTitle('Profil'),
          _buildProfileCard(),

          const SizedBox(height: 20),
          _buildSectionTitle('Sécurité'),
          _buildSecurityCard(),

          const SizedBox(height: 20),
          _buildSectionTitle('Préférences'),
          _buildPreferencesCard(),

          const SizedBox(height: 20),
          _buildSectionTitle('Session'),
          _buildSessionCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF233A91),
            Color(0xFF3557D6),
            Color(0xFF486BEE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33243B8F),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomComplet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gérez vos informations personnelles, votre sécurité et vos préférences.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Nom complet',
            value: nomComplet,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.alternate_email_rounded,
            label: 'Nom d’utilisateur',
            value: nomUtilisateur,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: telephone,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Modifier le mot de passe',
            subtitle: 'Renforce la sécurité de ton compte',
            onTap: _modifierMotDePasse,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.verified_user_outlined,
            title: 'Sécurité du compte',
            subtitle: 'Vérifie et protège tes accès',
            onTap: _voirSecuriteCompte,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _SwitchTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Activer ou désactiver les alertes',
            value: notificationsActives,
            onChanged: (value) {
              setState(() {
                notificationsActives = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            icon: Icons.alarm_rounded,
            title: 'Rappels',
            subtitle: 'Recevoir les rappels importants',
            value: rappelActif,
            onChanged: (value) {
              setState(() {
                rappelActif = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.language_rounded,
            title: 'Langue',
            subtitle: langueSelectionnee,
            onTap: _ouvrirChoixLangue,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _ouvrirModificationProfil,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier mes informations'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3047A5),
                side: const BorderSide(color: Color(0xFF3047A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _deconnexion,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD92D20),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModifierProfilScreen extends StatefulWidget {
  final String nomComplet;
  final String nomUtilisateur;
  final String email;
  final String telephone;

  const ModifierProfilScreen({
    super.key,
    required this.nomComplet,
    required this.nomUtilisateur,
    required this.email,
    required this.telephone,
  });

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  late final TextEditingController nomCompletController;
  late final TextEditingController nomUtilisateurController;
  late final TextEditingController emailController;
  late final TextEditingController telephoneController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nomCompletController = TextEditingController(text: widget.nomComplet);
    nomUtilisateurController =
        TextEditingController(text: widget.nomUtilisateur);
    emailController = TextEditingController(text: widget.email);
    telephoneController = TextEditingController(text: widget.telephone);
  }

  @override
  void dispose() {
    nomCompletController.dispose();
    nomUtilisateurController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    super.dispose();
  }

  void _enregistrer() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        {
          'nomComplet': nomCompletController.text.trim(),
          'nomUtilisateur': nomUtilisateurController.text.trim(),
          'email': emailController.text.trim(),
          'telephone': telephoneController.text.trim(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Modifier mes informations'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _CustomTextField(
                  controller: nomCompletController,
                  label: 'Nom complet',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom complet est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _CustomTextField(
                  controller: nomUtilisateurController,
                  label: 'Nom d’utilisateur',
                  icon: Icons.alternate_email_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom utilisateur est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _CustomTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L’email est requis';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _CustomTextField(
                  controller: telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le téléphone est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _enregistrer,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3047A5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModifierMotDePasseScreen extends StatefulWidget {
  const ModifierMotDePasseScreen({super.key});

  @override
  State<ModifierMotDePasseScreen> createState() =>
      _ModifierMotDePasseScreenState();
}

class _ModifierMotDePasseScreenState extends State<ModifierMotDePasseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController ancienMotDePasseController =
      TextEditingController();
  final TextEditingController nouveauMotDePasseController =
      TextEditingController();
  final TextEditingController confirmationMotDePasseController =
      TextEditingController();

  bool masquerAncien = true;
  bool masquerNouveau = true;
  bool masquerConfirmation = true;

  @override
  void dispose() {
    ancienMotDePasseController.dispose();
    nouveauMotDePasseController.dispose();
    confirmationMotDePasseController.dispose();
    super.dispose();
  }

  void _changerMotDePasse() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Modifier le mot de passe'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _PasswordField(
                  controller: ancienMotDePasseController,
                  label: 'Ancien mot de passe',
                  obscureText: masquerAncien,
                  onToggle: () {
                    setState(() {
                      masquerAncien = !masquerAncien;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: nouveauMotDePasseController,
                  label: 'Nouveau mot de passe',
                  obscureText: masquerNouveau,
                  onToggle: () {
                    setState(() {
                      masquerNouveau = !masquerNouveau;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nouveau mot de passe est requis';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: confirmationMotDePasseController,
                  label: 'Confirmer le mot de passe',
                  obscureText: masquerConfirmation,
                  onToggle: () {
                    setState(() {
                      masquerConfirmation = !masquerConfirmation;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La confirmation est requise';
                    }
                    if (value != nouveauMotDePasseController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _changerMotDePasse,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Mettre à jour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3047A5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF3047A5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3047A5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3047A5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF3047A5),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3047A5), width: 1.4),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3047A5), width: 1.4),
        ),
      ),
    );
  }
}