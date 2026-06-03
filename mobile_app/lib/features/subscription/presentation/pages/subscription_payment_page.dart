import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/subscription_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/subscription_service.dart';

class SubscriptionPaymentPage extends StatefulWidget {
  const SubscriptionPaymentPage({super.key});

  @override
  State<SubscriptionPaymentPage> createState() => _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends State<SubscriptionPaymentPage> {
  static const _navy = Color(0xFF0F172A);

  final _senderName = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _proofBytes;
  String _proofFileName = '';
  bool _submitting = false;

  @override
  void dispose() {
    _senderName.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _proofBytes = bytes;
      _proofFileName = file.name;
    });
  }

  Future<void> _submit() async {
    final sender = _senderName.text.trim();
    const amount = SubscriptionConstants.proMonthlyAmount;

    if (sender.length < 2) {
      _showMessage('Enter sender name as shown on GCash.');
      return;
    }
    if (_proofBytes == null) {
      _showMessage('Upload proof of transaction.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await SubscriptionService.instance.submitPayment(
        senderName: sender,
        amount: amount,
        proofBytes: _proofBytes!,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Submitted'),
          content: const Text(
            'Your payment is pending review. Pro features unlock after the super admin approves your proof.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Subscription Plan',
          style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gray200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: QrImageView(
                          data: SubscriptionConstants.gcashQrPayload,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan the QR code to send payment via GCash',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _label('Enter Amount'),
                    _amountField(),
                    const SizedBox(height: 18),
                    _label("Sender's Name"),
                    _textField(_senderName, hint: 'Full name on GCash'),
                    const SizedBox(height: 18),
                    _label('Upload Proof of Transaction'),
                    _proofField(),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2EAD5C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _navy,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _amountField() {
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE8EDF2),
        enabled: false,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        prefixIcon: Container(
          width: 48,
          alignment: Alignment.center,
          child: const Text(
            '₱',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _navy),
          ),
        ),
      ),
      child: Text(
        '${SubscriptionConstants.proMonthlyAmount}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, {required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE8EDF2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Widget _proofField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _submitting ? null : _pickProof,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray700,
              side: const BorderSide(color: Color(0xFF94A3B8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text('Choose Photo', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _proofFileName.isEmpty ? 'No file chosen' : _proofFileName,
              style: TextStyle(
                color: _proofFileName.isEmpty ? AppColors.gray500 : AppColors.gray900,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
