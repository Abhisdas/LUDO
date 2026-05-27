import 'dart:js' as js;

void initJsVoiceChat(void Function(String base64) onAudioData) {
  js.context['VoiceChat']?.callMethod('init', [js.allowInterop(onAudioData)]);
}

void startJsRecording() {
  js.context['VoiceChat']?.callMethod('startRecording');
}

void stopJsRecording() {
  js.context['VoiceChat']?.callMethod('stopRecording');
}

void playJsAudioChunk(String color, String base64) {
  js.context['VoiceChat']?.callMethod('playAudioChunk', [color, base64]);
}
