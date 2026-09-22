import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skagata_pkl_mobile/features/auth/providers/auth_provider.dart';
import 'package:skagata_pkl_mobile/features/auth/screens/auth_swap_screen.dart';
import 'package:skagata_pkl_mobile/features/auth/screens/login_screen.dart';
import 'package:skagata_pkl_mobile/features/auth/screens/register_screen.dart';

void main() {
  testWidgets('LoginScreen renders SKAGATA branding and role options', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify school and platform branding
    expect(find.text('SMKN 3 YOGYAKARTA'), findsOneWidget);
    expect(find.text('SKAGATA PKL INTELLIGENCE'), findsOneWidget);
    expect(find.text('SISTEM OTENTIKASI TERPADU v2.4'), findsOneWidget);

    // Verify 3 roles exist
    expect(find.text('Siswa PKL'), findsOneWidget);
    expect(find.text('Guru Pembimbing'), findsOneWidget);
    expect(find.text('Admin PKL / Hubin'), findsOneWidget);

    // Verify login button
    expect(find.text('Masuk ke Sistem PKL'), findsOneWidget);

    // Tap on 'Guru Pembimbing' role tab
    await tester.tap(find.text('Guru Pembimbing'));
    await tester.pump();

    // Verify input label changes to NIP
    expect(find.text('NIP / NUPTK Guru'), findsOneWidget);
  });

  testWidgets('AuthSwapScreen renders swap tabs and quick demo chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: AuthSwapScreen(),
        ),
      ),
    );

    // Verify swap tabs exist
    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Daftar Baru'), findsOneWidget);

    // Verify Demo Quick Fill is present
    expect(find.text('AKUN UJI COBA DEMO SANDBOX'), findsOneWidget);
    expect(find.text('Siswa Fikri'), findsOneWidget);
    expect(find.text('Guru Wahyu'), findsOneWidget);
    expect(find.text('Admin Hubin'), findsOneWidget);

    // Tap on 'Daftar Baru'
    await tester.tap(find.text('Daftar Baru'));
    await tester.pumpAndSettle();

    // Verify register form shows up
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}

