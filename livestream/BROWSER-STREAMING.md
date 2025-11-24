# 📹 Browser Streaming - Go Live từ Trình duyệt

Tính năng stream trực tiếp từ browser mà không cần cài đặt OBS hay app bên ngoài.

## ✨ Tính năng

- ✅ Mở camera/mic trực tiếp từ browser
- ✅ Preview trước khi live
- ✅ Click "Go Live" để bắt đầu
- ✅ Real-time chat tích hợp
- ✅ Viewer count real-time
- ✅ Chọn camera/microphone
- ✅ Điều chỉnh chất lượng (720p, 480p, 360p)
- ✅ Share link ngay lập tức
- ✅ Hoạt động trên cả mobile và desktop

## 🎯 So sánh với OBS/Larix

| Tính năng | Browser Streaming | OBS/Larix |
|-----------|-------------------|-----------|
| Cài đặt | Không cần | Phải cài app |
| Độ khó | Rất dễ | Trung bình |
| Thời gian setup | < 30 giây | 5-10 phút |
| Chất lượng | Tốt (720p) | Rất tốt (1080p+) |
| Tính năng | Cơ bản | Đầy đủ |
| Overlay/Effects | Không | Có |
| Scene switching | Không | Có |
| Multiple sources | Không | Có |
| Mobile-friendly | ✅ Rất tốt | ⚠️ Cần app |

## 🚀 Cách sử dụng

### Bước 1: Truy cập Dashboard

```
http://your-domain:3000/dashboard
```

### Bước 2: Click "Go Live từ Browser"

Hoặc truy cập trực tiếp:
```
http://your-domain:3000/go-live
```

### Bước 3: Cho phép truy cập Camera/Mic

Trình duyệt sẽ yêu cầu quyền truy cập camera và microphone. Click "Allow/Cho phép".

### Bước 4: Cấu hình (optional)

- **Tiêu đề Stream**: Nhập tiêu đề cho stream
- **Mô tả**: Mô tả ngắn về nội dung
- **Camera**: Chọn camera (nếu có nhiều)
- **Microphone**: Chọn mic
- **Chất lượng**: Chọn 720p, 480p, hoặc 360p

### Bước 5: Click "Go Live"

Stream sẽ bắt đầu ngay lập tức!

### Bước 6: Share link

Copy link từ phần "Chia sẻ Stream" và gửi cho người xem.

### Bước 7: Dừng Stream

Click "Dừng Stream" khi muốn kết thúc.

## 🎨 Features

### Camera Controls

- **Mở Camera**: Bật camera và microphone
- **Đổi Camera**: Chuyển giữa camera trước/sau (mobile) hoặc nhiều webcam (desktop)
- **Preview**: Xem trước trước khi live

### Stream Settings

- **Tiêu đề và mô tả**: Tùy chỉnh thông tin stream
- **Chất lượng**:
  - **720p HD**: 1280x720, 2.5 Mbps (khuyên dùng cho WiFi/4G tốt)
  - **480p SD**: 854x480, 1.5 Mbps (khuyên dùng cho mạng trung bình)
  - **360p Low**: 640x360, 1.0 Mbps (cho mạng yếu)

### Live Stats

- **Duration**: Thời gian đã stream
- **Viewers**: Số người đang xem
- **Quality**: Chất lượng hiện tại

## 💻 Yêu cầu Trình duyệt

### Desktop:

| Browser | Version | Support |
|---------|---------|---------|
| **Chrome** | 74+ | ✅ Full |
| **Firefox** | 66+ | ✅ Full |
| **Edge** | 79+ | ✅ Full |
| **Safari** | 13+ | ⚠️ Limited |
| **Opera** | 62+ | ✅ Full |

### Mobile:

| Browser | OS | Support |
|---------|-----|---------|
| **Chrome Mobile** | Android 5+ | ✅ Full |
| **Safari iOS** | iOS 14+ | ⚠️ Limited |
| **Firefox Mobile** | Android 5+ | ✅ Full |
| **Samsung Internet** | Android 5+ | ✅ Full |

### Khuyến nghị:

- **Desktop**: Chrome, Firefox, hoặc Edge (Chromium)
- **Mobile**: Chrome Mobile (Android) hoặc Safari (iOS 14+)

## ⚙️ Cách hoạt động (Technical)

### Client Side (Browser):

```javascript
1. getUserMedia() → Lấy camera/mic stream
2. MediaRecorder → Record video/audio
3. Socket.IO → Send chunks to server real-time
4. Display preview trong video element
```

### Server Side (Node.js):

```javascript
1. Socket.IO handlers nhận stream data
2. Lưu metadata vào database
3. Broadcast viewer count real-time
4. Track analytics (duration, viewers, etc.)
```

### Flow:

```
Browser (Camera)
    ↓ getUserMedia
LocalStream
    ↓ MediaRecorder
Chunks (WebM)
    ↓ Socket.IO
Server (Node.js)
    ↓ Store/Process
Database + Analytics
    ↓ Broadcast
Viewers (HLS/WebRTC)
```

## 🔧 Configuration

### Quality Presets

File: `go-live.html`

```javascript
const qualitySettings = {
  '720p': {
    width: 1280,
    height: 720,
    bitrate: 2500000
  },
  '480p': {
    width: 854,
    height: 480,
    bitrate: 1500000
  },
  '360p': {
    width: 640,
    height: 360,
    bitrate: 1000000
  }
};
```

### MediaRecorder Options

```javascript
const options = {
  mimeType: 'video/webm;codecs=vp8,opus',
  videoBitsPerSecond: 2500000,
  audioBitsPerSecond: 128000
};
```

### Audio Settings

```javascript
audio: {
  echoCancellation: true,    // Loại bỏ echo
  noiseSuppression: true,     // Giảm nhiễu
  autoGainControl: true       // Tự động điều chỉnh âm lượng
}
```

## 🐛 Troubleshooting

### Camera không mở được

**Nguyên nhân:**
- Không có camera
- Quyền bị từ chối
- Camera đang được app khác sử dụng

**Giải pháp:**
```
1. Check camera settings trong browser
2. Reload page và cho phép quyền lại
3. Đóng các app khác đang dùng camera
4. Try trên browser khác
```

### Chất lượng stream kém

**Nguyên nhân:**
- Mạng yếu
- CPU quá tải
- Bitrate quá cao

**Giải pháp:**
```
1. Chọn chất lượng thấp hơn (480p or 360p)
2. Đóng các tab/app khác
3. Dùng WiFi thay vì 4G
4. Check network speed
```

### Stream bị lag/giật

**Nguyên nhân:**
- Network không ổn định
- Browser performance issues
- Too many viewers (server overload)

**Giải pháp:**
```
1. Kiểm tra network speed: speedtest.net
2. Reload browser
3. Clear browser cache
4. Upgrade server resources
```

### Audio không có

**Nguyên nhân:**
- Mic bị mute
- Không có quyền microphone
- Mic lỗi

**Giải pháp:**
```
1. Check mic permissions
2. Test mic trong system settings
3. Try khác mic (nếu có)
4. Reload page
```

## 📊 Best Practices

### Cho Streamer:

1. **Test trước khi live**: Click "Mở Camera" và kiểm tra preview
2. **Chọn chất lượng phù hợp**:
   - WiFi tốt: 720p
   - 4G: 480p
   - Mạng yếu: 360p
3. **Ánh sáng tốt**: Đảm bảo đủ sáng
4. **Background đẹp**: Chú ý background
5. **Mic quality**: Dùng mic tốt nếu có

### Cho Performance:

1. **Close unused tabs**: Giảm tải CPU
2. **Use wired connection**: Tốt hơn WiFi
3. **Stable position**: Giữ camera ổn định
4. **Battery**: Cắm sạc khi stream từ mobile

### Cho Viewers:

1. **Share link sớm**: Cho viewer time để join
2. **Tương tác**: Đọc chat và reply
3. **Duration**: Không quá ngắn (ít nhất 15-30 phút)

## 🔒 Security & Privacy

### HTTPS Required

Browser streaming **chỉ hoạt động trên HTTPS** (hoặc localhost). Đảm bảo:

```bash
# Setup SSL certificate
sudo certbot --nginx -d your-domain.com
```

### Permissions

Browser sẽ yêu cầu quyền:
- 📷 Camera
- 🎤 Microphone

User có thể từ chối hoặc revoke bất cứ lúc nào.

### Privacy

- Stream chỉ visible khi có link
- Không record nếu không enable
- User có full control over camera/mic

## 🚀 Future Enhancements

Các tính năng có thể thêm:

- [ ] **Screen sharing**: Stream màn hình thay vì camera
- [ ] **Virtual backgrounds**: Blur/thay background
- [ ] **Filters/Effects**: Beauty filters, stickers
- [ ] **Picture-in-Picture**: Mini preview window
- [ ] **Multi-camera**: Nhiều góc quay cùng lúc
- [ ] **Recording**: Auto save stream
- [ ] **Transcoding**: Convert sang HLS real-time
- [ ] **WebRTC**: Peer-to-peer for lower latency
- [ ] **Mobile app**: Native app wrapper

## 📱 Mobile Specific

### Android (Chrome):

1. Open Chrome
2. Visit go-live page
3. Allow camera/mic
4. Works perfectly! ✅

### iOS (Safari):

1. Open Safari
2. Visit go-live page
3. Allow camera/mic
4. ⚠️ Limitations:
   - Some codecs not supported
   - May have quality issues
   - Test before important streams

### Tips:

- **Hold phone horizontally** for landscape
- **Use back camera** for better quality
- **Ensure good lighting**
- **Stable internet** (4G/5G or WiFi)

## 🎓 Technical Details

### MediaRecorder API

```javascript
// Create recorder
const mediaRecorder = new MediaRecorder(stream, options);

// Handle data
mediaRecorder.ondataavailable = (event) => {
  if (event.data.size > 0) {
    sendChunkToServer(event.data);
  }
};

// Start recording in chunks
mediaRecorder.start(1000); // 1 chunk/second
```

### Socket.IO Communication

```javascript
// Client
socket.emit('browser-stream-start', {
  streamKey, title, description
});

socket.emit('stream-chunk', {
  streamKey, chunk: blob
});

// Server
socket.on('browser-stream-start', (data) => {
  // Create stream record
  // Update database
});

socket.on('stream-chunk', (data) => {
  // Process chunk
  // Forward to viewers (future)
});
```

## 📚 Resources

- [MediaRecorder API](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder)
- [getUserMedia API](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)
- [WebRTC](https://webrtc.org/)
- [Socket.IO](https://socket.io/)

## ✅ Summary

Browser streaming cho phép user:
1. ✅ Không cần cài app
2. ✅ Stream chỉ trong < 30 giây
3. ✅ Hoạt động trên mọi device
4. ✅ Easy to use
5. ✅ No technical knowledge required

Perfect cho:
- 🎤 Quick streams
- 📱 Mobile streaming
- 🎉 Casual/impromptu streams
- 👥 Beginners
- 🚀 Fast setup

---

**Enjoy streaming! 🎥**
