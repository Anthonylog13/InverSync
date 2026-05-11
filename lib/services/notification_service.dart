import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales (push locales).
///
/// SOLID — Responsabilidad Única: solo gestiona la programación y cancelación
/// de notificaciones locales del dispositivo.
/// SOLID — Inversión de Dependencias: [FlutterLocalNotificationsPlugin] puede
/// sustituirse por un mock en tests.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _androidChannel = AndroidNotificationChannel(
    'payment_reminders',
    'Recordatorios de pago',
    description: 'Notificaciones de cobros y pagos próximos de InverSync',
    importance: Importance.max,     // heads-up en pantalla bloqueada
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // ---------------------------------------------------------------------------
  // Inicialización
  // ---------------------------------------------------------------------------

  /// Inicializa zonas horarias y el plugin de notificaciones para todas las
  /// plataformas.
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Crear el canal de Android 8+ para que las notificaciones tengan prioridad
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  // ---------------------------------------------------------------------------
  // Permisos
  // ---------------------------------------------------------------------------

  /// Solicita permisos al usuario (iOS y Android 13+).
  /// En Android < 13 esto es no-op.
  Future<void> requestPermissions() async {
    // iOS: solicita los tres permisos explícitamente
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,   // muestra banners y notificaciones en pantalla de bloqueo
          badge: true,   // badge numérico en el ícono de la app
          sound: true,   // reproduce el sonido de notificación
        );

    // Android 13+ (API 33+): permiso POST_NOTIFICATIONS obligatorio
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Android 12+ (API 31+): permiso de alarmas exactas
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ---------------------------------------------------------------------------
  // Programación
  // ---------------------------------------------------------------------------

  /// Programa una notificación para [scheduledDate] a las 9:00 AM.
  ///
  /// [id]    — ID único (debe ser consistente para evitar duplicados).
  /// [title] — Título de la notificación.
  /// [body]  — Cuerpo descriptivo.
  Future<void> schedulePaymentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Forzar la hora a 9:00 AM del día programado
    final targetDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      9,
      0,
      0,
    );

    // Convertir a TZDateTime usando la zona local del dispositivo
    final tzDate = tz.TZDateTime.from(targetDate, tz.local);

    // Si el momento ya pasó, no programar
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'payment_reminders',
      'Recordatorios de pago',
      channelDescription:
          'Notificaciones de cobros y pagos próximos de InverSync',
      importance: Importance.max,   // muestra heads-up aunque la pantalla esté apagada
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,       // salta incluso en pantalla de bloqueo
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Intento 1: alarma exacta (requiere SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM).
    // Intento 2: si el permiso no fue concedido en tiempo de ejecución,
    //            cae en alarma inexacta — la notificación se mostrará con algo
    //            de retraso pero no crashea la app.
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Fallback: alarma inexacta — no requiere permiso especial.
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cancelación
  // ---------------------------------------------------------------------------

  /// Cancela todas las notificaciones programadas y pendientes.
  /// Útil para limpiar el stack antes de reprogramar desde cero.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
