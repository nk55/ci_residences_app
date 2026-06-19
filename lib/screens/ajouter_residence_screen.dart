import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AjouterResidenceScreen extends StatefulWidget {
  const AjouterResidenceScreen({super.key});

  @override
  State<AjouterResidenceScreen> createState() => _AjouterResidenceScreenState();
}

class _AjouterResidenceScreenState extends State<AjouterResidenceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _capaciteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

  String _typeBien = 'Appartement';
  bool _isSubmitting = false;

  final List<String> _typesBien = const [
    'Appartement',
    'Studio',
    'Villa',
    'Maison',
    'Chambre',
    'Hôtel',
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _telephoneController.dispose();
    _whatsappController.dispose();
    _capaciteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isEmpty) return;

      final newFiles = pickedFiles.map((file) => File(file.path)).toList();

      setState(() {
        for (final file in newFiles) {
          final alreadyExists =
              _selectedImages.any((image) => image.path == file.path);
          if (!alreadyExists) {
            _selectedImages.add(file);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de sélectionner les images : $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedImages.isEmpty
                ? 'Résidence prête à être publiée'
                : 'Résidence prête avec ${_selectedImages.length} image(s)',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      // ICI PLUS TARD :
      // await ApiService().addResidence(
      //   token: token,
      //   titre: _titreController.text,
      //   description: _descriptionController.text,
      //   type: _typeBien,
      //   prix: _prixController.text,
      //   ville: _villeController.text,
      //   quartier: _quartierController.text,
      //   telephone: _telephoneController.text,
      //   whatsapp: _whatsappController.text,
      //   capacite: _capaciteController.text,
      //   images: _selectedImages,
      // );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF3047A5),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final bool isMultiline = maxLines > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
        textInputAction:
            isMultiline ? TextInputAction.newline : TextInputAction.next,
        textCapitalization:
            isMultiline ? TextCapitalization.sentences : TextCapitalization.none,
        decoration: _inputDecoration(
          label: label,
          icon: icon,
          hint: hint,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownType() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: _typeBien,
        isExpanded: true,
        decoration: _inputDecoration(
          label: 'Type de bien',
          icon: Icons.home_work_rounded,
        ),
        items: _typesBien.map((type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(
              type,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _typeBien = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildImagesPreview() {
    if (_selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final image = _selectedImages[index];

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    image,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD9E1F2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 32,
              color: Color(0xFF3047A5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ajouter des images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedImages.isEmpty
                ? 'Choisis une ou plusieurs images pour ta résidence.'
                : '${_selectedImages.length} image(s) sélectionnée(s)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _selectedImages.isEmpty
                  ? 'Choisir des images'
                  : 'Ajouter d’autres images',
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          _buildImagesPreview(),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.add_business_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Publier une nouvelle résidence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Renseignez les informations principales du bien pour préparer sa publication.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text('Ajouter une résidence'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF6F7FB),
          surfaceTintColor: const Color(0xFFF6F7FB),
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 22),

                _buildSectionTitle('Informations principales'),
                _buildTextField(
                  controller: _titreController,
                  label: 'Titre',
                  icon: Icons.title_rounded,
                  hint: 'Ex: Appartement meublé à Cocody',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    return null;
                  },
                ),
                _buildDropdownType(),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description_outlined,
                  hint: 'Décrivez la résidence...',
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _prixController,
                  label: 'Prix',
                  icon: Icons.payments_outlined,
                  hint: 'Ex: 25000',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un prix';
                    }

                    final prix = int.tryParse(value.trim());
                    if (prix == null || prix <= 0) {
                      return 'Veuillez entrer un prix valide';
                    }

                    return null;
                  },
                ),
                _buildTextField(
                  controller: _capaciteController,
                  label: 'Capacité',
                  icon: Icons.people_alt_outlined,
                  hint: 'Ex: 2',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final capacite = int.tryParse(value.trim());
                    if (capacite == null || capacite <= 0) {
                      return 'Veuillez entrer une capacité valide';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),
                _buildSectionTitle('Localisation'),
                _buildTextField(
                  controller: _villeController,
                  label: 'Ville',
                  icon: Icons.location_city_outlined,
                  hint: 'Ex: Abidjan',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer la ville';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _quartierController,
                  label: 'Quartier',
                  icon: Icons.place_outlined,
                  hint: 'Ex: Cocody Angré',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer le quartier';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                _buildSectionTitle('Contact'),
                _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  hint: 'Ex: 0700000000',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un numéro de téléphone';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _whatsappController,
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  hint: 'Ex: 0700000000',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 8),
                _buildSectionTitle('Images'),
                _buildImagePickerCard(),

                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Publication...'
                          : 'Publier la résidence',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3047A5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
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