window.VoiceChat = {
  mediaRecorder: null,
  stream: null,
  onAudioData: null,

  init: function(onAudioDataCallback) {
    this.onAudioData = onAudioDataCallback;
    console.log("VoiceChat JS initialized");
  },

  startRecording: function() {
    console.log("Requesting mic access...");
    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(s => {
        this.stream = s;
        let options = { mimeType: 'audio/webm;codecs=opus' };
        if (typeof MediaRecorder !== 'undefined' && !MediaRecorder.isTypeSupported(options.mimeType)) {
          options = { mimeType: 'audio/ogg;codecs=opus' };
        }
        if (typeof MediaRecorder !== 'undefined' && !MediaRecorder.isTypeSupported(options.mimeType)) {
          options = {};
        }
        
        this.mediaRecorder = new MediaRecorder(s, options);
        this.mediaRecorder.ondataavailable = (event) => {
          if (event.data.size > 0) {
            const reader = new FileReader();
            reader.onloadend = () => {
              const base64 = reader.result.split(',')[1];
              if (this.onAudioData) {
                this.onAudioData(base64);
              }
            };
            reader.readAsDataURL(event.data);
          }
        };
        // Record in 250ms time slices
        this.mediaRecorder.start(250);
        console.log("VoiceChat recording started");
      })
      .catch(err => {
        console.error("Error accessing microphone: ", err);
      });
  },

  stopRecording: function() {
    console.log("Stopping VoiceChat recording...");
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop();
    }
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
  },

  playAudioChunk: function(playerColor, base64Data) {
    try {
      const audioUrl = "data:audio/webm;codecs=opus;base64," + base64Data;
      const audio = new Audio(audioUrl);
      audio.volume = 1.0;
      audio.play().catch(err => {
        console.warn("Playback blocked or failed: ", err);
      });
    } catch (e) {
      console.error("Error playing audio chunk: ", e);
    }
  }
};
