// Firebase konfigürasyonu
const firebaseConfig = {
    apiKey: "AIzaSyD4Ctku43bicOCBN4QXXvPXEjWJUNsp25k",
    authDomain: "bullbearnews-4eff4.firebaseapp.com",
    projectId: "bullbearnews-4eff4",
    storageBucket: "bullbearnews-4eff4.firebasestorage.app",
    messagingSenderId: "211885957058",
    appId: "1:211885957058:web:77687c09d9925b9e87405b",
    measurementId: "G-61J961L6H5"
};

// Firebase başlatma
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();

// Cloudinary API ayarları
const cloudinaryConfig = {
    cloudName: 'dh7lpyg7t',  // Cloudinary Cloud Name
    apiKey: '395487784973678',  // Cloudinary API Key
    apiSecret: '3pitWEdmr5Qbvm6TOspCj1PH8JE',  // Cloudinary API Secret
};

// DOM elemanları
const loginButton = document.getElementById('login-button');
const logoutButton = document.getElementById('logout-button');
const loginContainer = document.getElementById('login-container');
const userInfo = document.getElementById('user-info');
const userEmail = document.getElementById('user-email');
const authRequired = document.getElementById('auth-required');
const adminContent = document.getElementById('admin-content');
const newsForm = document.getElementById('news-form');
const titleInput = document.getElementById('title');
const contentInput = document.getElementById('content');
const categorySelect = document.getElementById('category');
const authorInput = document.getElementById('author');
const imageInput = document.getElementById('image');
const imagePreview = document.getElementById('image-preview');
const submitButton = document.getElementById('submit-button');
const uploadProgress = document.getElementById('upload-progress');
const progressBar = document.querySelector('.progress-bar');
const refreshButton = document.getElementById('refresh-button');
const newsList = document.getElementById('news-list');
const loadingNews = document.getElementById('loading-news');
const noNews = document.getElementById('no-news');
const deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));
const confirmDeleteButton = document.getElementById('confirm-delete');

// DOM elemanları - Chat Odaları
const chatRoomForm = document.getElementById('chat-room-form');
const roomNameInput = document.getElementById('room-name');
const roomDescriptionInput = document.getElementById('room-description');
const addRoomButton = document.getElementById('add-room-button');
const refreshChatRoomsButton = document.getElementById('refresh-chat-rooms');
const chatRoomsList = document.getElementById('chat-rooms-list');
const loadingChatRooms = document.getElementById('loading-chat-rooms');
const noChatRooms = document.getElementById('no-chat-rooms');
const deleteRoomModal = new bootstrap.Modal(document.getElementById('deleteRoomModal'));
const confirmDeleteRoomButton = document.getElementById('confirm-delete-room');
const clearMessagesModal = new bootstrap.Modal(document.getElementById('clearMessagesModal'));
const confirmClearMessagesButton = document.getElementById('confirm-clear-messages');

// DOM elemanları - Anketler
const pollForm = document.getElementById('poll-form');
const pollQuestionInput = document.getElementById('poll-question');
const pollOptionsContainer = document.getElementById('poll-options-container');
const addOptionButton = document.getElementById('add-option');
const addPollButton = document.getElementById('add-poll-button');
const refreshPollsButton = document.getElementById('refresh-polls');
const pollsList = document.getElementById('polls-list');
const loadingPolls = document.getElementById('loading-polls');
const noPolls = document.getElementById('no-polls');
const deletePollModal = new bootstrap.Modal(document.getElementById('deletePollModal'));
const confirmDeletePollButton = document.getElementById('confirm-delete-poll');

// DOM elemanları - Duyurular
const announcementForm = document.getElementById('announcement-form');
const announcementTitleInput = document.getElementById('announcement-title');
const announcementContentInput = document.getElementById('announcement-content');
const announcementImageInput = document.getElementById('announcement-image');
const announcementPreview = document.getElementById('announcement-preview');
const announcementsList = document.getElementById('announcements-list');
const refreshAnnouncementsButton = document.getElementById('refresh-announcements');
const loadingAnnouncements = document.getElementById('loading-announcements');
const noAnnouncements = document.getElementById('no-announcements');
const deleteAnnouncementModal = new bootstrap.Modal(document.getElementById('deleteAnnouncementModal'));
const confirmDeleteAnnouncementButton = document.getElementById('confirm-delete-announcement');


// Auth durum değişikliğini izle
auth.onAuthStateChanged(user => {
    if (user) {
        loginContainer.classList.add('d-none');
        userInfo.classList.remove('d-none');
        userEmail.textContent = user.email;
        authRequired.classList.add('d-none');
        adminContent.classList.remove('d-none');
        loadNews();
        loadChatRooms();
    } else {
        loginContainer.classList.remove('d-none');
        userInfo.classList.add('d-none');
        authRequired.classList.remove('d-none');
        adminContent.classList.add('d-none');
    }
});

// Giriş yap butonu
loginButton.addEventListener('click', () => {
    auth.signInWithPopup(new firebase.auth.GoogleAuthProvider())
        .catch(error => {
            console.error('Giriş hatası:', error);
            alert('Giriş yapılırken bir hata oluştu: ' + error.message);
        });
});

// Çıkış yap butonu
logoutButton.addEventListener('click', () => {
    auth.signOut()
        .catch(error => {
            console.error('Çıkış hatası:', error);
            alert('Çıkış yapılırken bir hata oluştu: ' + error.message);
        });
});

// Resim önizleme
imageInput.addEventListener('change', event => {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = e => {
            imagePreview.src = e.target.result;
            imagePreview.classList.remove('d-none');
        };
        reader.readAsDataURL(file);
    } else {
        imagePreview.classList.add('d-none');
    }
});


// Haber formunu gönder
newsForm.addEventListener('submit', async event => {
    event.preventDefault();
    
    if (!auth.currentUser) {
        alert('Haber eklemek için giriş yapmalısınız.');
        return;
    }
    
    // Form verilerini al
    const title = titleInput.value.trim();
    const content = contentInput.value.trim();
    const category = categorySelect.value;
    const author = authorInput.value.trim();
    const imageFile = imageInput.files[0];
    
    if (!title || !content || !category || !author || !imageFile) {
        alert('Lütfen tüm alanları doldurun.');
        return;
    }
    
    try {
        // UI güncellemeleri
        submitButton.disabled = true;
        uploadProgress.classList.remove('d-none');
        
        // Görseli Cloudinary'ye yükle
        const imageUrl = await uploadImageToCloudinary(imageFile);  // Cloudinary'ye yükleme

        // Firestore'a haberi ekle
        await db.collection('news').add({
            title,
            content,
            category,
            author,
            imageUrl,  // Cloudinary URL'yi kaydet
            publishDate: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        alert('Haber başarıyla eklendi.');
        
        // Formu sıfırla
        newsForm.reset();
        imagePreview.classList.add('d-none');
        
        // UI'ı güncelle
        submitButton.disabled = false;
        uploadProgress.classList.add('d-none');
        progressBar.style.width = '0%';

        // Haber listesini yenile
        loadNews();
    } catch (error) {
        console.error('Haber ekleme hatası:', error);
        alert('Haber eklenirken bir hata oluştu: ' + error.message);
        submitButton.disabled = false;
        uploadProgress.classList.add('d-none');
    }
});

// Haberleri yükle
async function loadNews() {
    if (!auth.currentUser) return;
    
    loadingNews.classList.remove('d-none');
    noNews.classList.add('d-none');
    newsList.innerHTML = '';
    
    try {
        const snapshot = await db.collection('news')
            .orderBy('publishDate', 'desc')
            .get();
        
        if (snapshot.empty) {
            noNews.classList.remove('d-none');
        } else {
            snapshot.forEach(doc => {
                const news = doc.data();
                news.id = doc.id;
                
                // Tarih formatla
                let formattedDate = 'Tarih bilgisi yok';
                if (news.publishDate) {
                    const date = news.publishDate.toDate();
                    formattedDate = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
                }
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>
                        <img src="${news.imageUrl}" alt="${news.title}" class="news-thumbnail" 
                        style="width: 80px; height: 60px; object-fit: cover; border-radius: 4px; max-width: 80px;"
                        onerror="this.src='https://via.placeholder.com/60?text=Resim'">
                    </td>
                    <td>${news.title}</td>
                    <td>${news.category}</td>
                    <td>${formattedDate}</td>
                    <td>${news.author}</td>
                    <td>
                        <button class="btn btn-sm btn-danger delete-news" data-id="${news.id}">Sil</button>
                    </td>
                `;
                
                newsList.appendChild(row);
            });
            
            // Silme butonlarına event listener ekle
            document.querySelectorAll('.delete-news').forEach(button => {
                button.addEventListener('click', event => {
                    const newsId = event.target.getAttribute('data-id');
                    confirmDeleteButton.setAttribute('data-id', newsId);
                    deleteModal.show();
                });
            });
        }
    } catch (error) {
        console.error('Haber yükleme hatası:', error);
        alert('Haberler yüklenirken bir hata oluştu: ' + error.message);
    } finally {
        loadingNews.classList.add('d-none');
    }
}

// Yenile butonuna tıklama
refreshButton.addEventListener('click', loadNews);

// Haber silme işlemi
confirmDeleteButton.addEventListener('click', async () => {
    const newsId = confirmDeleteButton.getAttribute('data-id');
    
    if (!newsId) {
        deleteModal.hide();
        return;
    }
    
    try {
        await db.collection('news').doc(newsId).delete();
        alert('Haber başarıyla silindi.');
        loadNews();
    } catch (error) {
        console.error('Haber silme hatası:', error);
        alert('Haber silinirken bir hata oluştu: ' + error.message);
    } finally {
        deleteModal.hide();
    }
});


// Chat odalarını yükle
async function loadChatRooms() {
    if (!auth.currentUser) return;
    
    loadingChatRooms.classList.remove('d-none');
    noChatRooms.classList.add('d-none');
    chatRoomsList.innerHTML = '';
    
    try {
        const snapshot = await db.collection('chatRooms')
            .orderBy('createdAt', 'desc')
            .get();
        
        if (snapshot.empty) {
            noChatRooms.classList.remove('d-none');
        } else {
            for (const doc of snapshot.docs) {
                const room = doc.data();
                room.id = doc.id;
                
                // Tarih formatla
                let formattedDate = 'Tarih bilgisi yok';
                if (room.createdAt) {
                    const date = room.createdAt.toDate();
                    formattedDate = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
                }
                
                // Mesaj sayısını al
                const messagesSnapshot = await db.collection('chatRooms')
                    .doc(room.id)
                    .collection('messages')
                    .get();
                
                const messageCount = messagesSnapshot.size;
                
                // Odanın aktiflik durumu (yoksa varsayılan olarak true)
                const isActive = room.isActive !== undefined ? room.isActive : true;
                const statusClass = isActive ? 'bg-success' : 'bg-danger';
                const statusText = isActive ? 'Aktif' : 'Pasif';
                const toggleBtnText = isActive ? 'Devre Dışı Bırak' : 'Aktifleştir';
                const toggleBtnClass = isActive ? 'btn-warning' : 'btn-success';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${room.name}</td>
                    <td>${room.description}</td>
                    <td>${formattedDate}</td>
                    <td>${messageCount}</td>
                    <td>
                        <span class="badge ${statusClass}">${statusText}</span>
                    </td>
                    <td>
                        <div class="btn-group btn-group-sm">
                            <button class="btn btn-sm ${toggleBtnClass} toggle-room-status" data-id="${room.id}" data-status="${isActive}">
                                ${toggleBtnText}
                            </button>
                            <button class="btn btn-sm btn-info clear-messages" data-id="${room.id}" data-name="${room.name}">
                                Mesajları Temizle
                            </button>
                            <button class="btn btn-sm btn-danger delete-room" data-id="${room.id}">
                                Odayı Sil
                            </button>
                        </div>
                    </td>
                `;
                
                chatRoomsList.appendChild(row);
            }
            
            // Silme butonlarına event listener ekle
            document.querySelectorAll('.delete-room').forEach(button => {
                button.addEventListener('click', event => {
                    const roomId = event.target.getAttribute('data-id');
                    confirmDeleteRoomButton.setAttribute('data-id', roomId);
                    deleteRoomModal.show();
                });
            });
            
            // Aktiflik durumu değiştirme butonlarına event listener ekle
            document.querySelectorAll('.toggle-room-status').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const roomId = event.target.getAttribute('data-id');
                    const currentStatus = event.target.getAttribute('data-status') === 'true';
                    
                    try {
                        // Odanın durumunu güncelle
                        await db.collection('chatRooms').doc(roomId).update({
                            isActive: !currentStatus
                        });
                        
                        alert(`Oda durumu başarıyla ${!currentStatus ? 'aktif' : 'pasif'} olarak güncellendi.`);
                        loadChatRooms(); // Listeyi yenile
                    } catch (error) {
                        console.error('Oda durumu güncelleme hatası:', error);
                        alert('Oda durumu güncellenirken bir hata oluştu: ' + error.message);
                    }
                });
            });
            
            // Mesajları temizleme butonlarına event listener ekle
            document.querySelectorAll('.clear-messages').forEach(button => {
                button.addEventListener('click', event => {
                    const roomId = event.target.getAttribute('data-id');
                    const roomName = event.target.getAttribute('data-name');
                    
                    // Modal içeriğini güncelle
                    document.getElementById('room-name-for-clear').textContent = roomName;
                    confirmClearMessagesButton.setAttribute('data-id', roomId);
                    clearMessagesModal.show();
                });
            });
        }
    } catch (error) {
        console.error('Sohbet odası yükleme hatası:', error);
        alert('Sohbet odaları yüklenirken bir hata oluştu: ' + error.message);
    } finally {
        loadingChatRooms.classList.add('d-none');
    }
}

// Oda ekleme formu
chatRoomForm.addEventListener('submit', async event => {
    event.preventDefault();
    
    if (!auth.currentUser) {
        alert('Sohbet odası eklemek için giriş yapmalısınız.');
        return;
    }
    
    // Form verilerini al
    const name = roomNameInput.value.trim();
    const description = roomDescriptionInput.value.trim();
    
    if (!name || !description) {
        alert('Lütfen tüm alanları doldurun.');
        return;
    }
    
    try {
        // UI güncellemeleri
        addRoomButton.disabled = true;
        
        // Oda adının benzersiz olduğundan emin ol
        const roomSnapshot = await db.collection('chatRooms')
            .where('name', '==', name)
            .get();
        
        if (!roomSnapshot.empty) {
            alert('Bu isimde bir sohbet odası zaten mevcut. Lütfen farklı bir isim seçin.');
            addRoomButton.disabled = false;
            return;
        }
        
        // Firestore'a odayı ekle
        await db.collection('chatRooms').add({
            name,
            description,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            createdBy: auth.currentUser.uid,
            createdByEmail: auth.currentUser.email,
            isActive: true // Varsayılan olarak aktif
        });
        
        alert('Sohbet odası başarıyla eklendi.');
        
        // Formu sıfırla
        chatRoomForm.reset();
        
        // UI'ı güncelle
        addRoomButton.disabled = false;

        // Oda listesini yenile
        loadChatRooms();
    } catch (error) {
        console.error('Sohbet odası ekleme hatası:', error);
        alert('Sohbet odası eklenirken bir hata oluştu: ' + error.message);
        addRoomButton.disabled = false;
    }
});

// Yenile butonuna tıklama
refreshChatRoomsButton.addEventListener('click', loadChatRooms);

// Oda silme işlemi
confirmDeleteRoomButton.addEventListener('click', async () => {
    const roomId = confirmDeleteRoomButton.getAttribute('data-id');
    
    if (!roomId) {
        deleteRoomModal.hide();
        return;
    }
    
    try {
        // Önce odaya ait tüm mesajları sil
        const messagesSnapshot = await db.collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .get();
        
        const batch = db.batch();
        messagesSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        // Batch işlemi gerçekleştir
        await batch.commit();
        
        // Sonra odanın kendisini sil
        await db.collection('chatRooms').doc(roomId).delete();
        
        alert('Sohbet odası başarıyla silindi.');
        loadChatRooms();
    } catch (error) {
        console.error('Sohbet odası silme hatası:', error);
        alert('Sohbet odası silinirken bir hata oluştu: ' + error.message);
    } finally {
        deleteRoomModal.hide();
    }
});

// Oda mesajlarını temizleme işlemi
confirmClearMessagesButton.addEventListener('click', async () => {
    const roomId = confirmClearMessagesButton.getAttribute('data-id');
    
    if (!roomId) {
        clearMessagesModal.hide();
        return;
    }
    
    try {
        // Odaya ait tüm mesajları al
        const messagesSnapshot = await db.collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .get();
        
        if (messagesSnapshot.empty) {
            alert('Bu odada silinecek mesaj bulunmuyor.');
            clearMessagesModal.hide();
            return;
        }
        
        // Batch işlemi oluştur
        const batch = db.batch();
        messagesSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        // Batch işlemi gerçekleştir
        await batch.commit();
        
        alert('Sohbet odasındaki tüm mesajlar başarıyla temizlendi.');
        loadChatRooms(); // Listeyi yenile
    } catch (error) {
        console.error('Mesaj temizleme hatası:', error);
        alert('Mesajlar temizlenirken bir hata oluştu: ' + error.message);
    } finally {
        clearMessagesModal.hide();
    }
});

// Auth durum değişikliğinde chat odalarını da yükle
auth.onAuthStateChanged(user => {
    if (user) {
        loginContainer.classList.add('d-none');
        userInfo.classList.remove('d-none');
        userEmail.textContent = user.email;
        authRequired.classList.add('d-none');
        adminContent.classList.remove('d-none');
        loadNews();
        loadChatRooms(); // Chat odalarını da yükle
    } else {
        loginContainer.classList.remove('d-none');
        userInfo.classList.add('d-none');
        authRequired.classList.remove('d-none');
        adminContent.classList.add('d-none');
    }
});

// Seçenek ekleme butonu
addOptionButton.addEventListener('click', () => {
    const optionCount = pollOptionsContainer.querySelectorAll('.poll-option').length + 1;
    const optionDiv = document.createElement('div');
    optionDiv.className = 'input-group mb-2';
    optionDiv.innerHTML = `
        <input type="text" class="form-control poll-option" placeholder="Seçenek ${optionCount}" required>
        <button type="button" class="btn btn-outline-danger remove-option">×</button>
    `;
    pollOptionsContainer.appendChild(optionDiv);
});

// Seçenek silme
pollOptionsContainer.addEventListener('click', (e) => {
    if (e.target.classList.contains('remove-option')) {
        if (pollOptionsContainer.querySelectorAll('.poll-option').length > 2) {
            e.target.closest('.input-group').remove();
        } else {
            alert('En az iki seçenek olmalıdır.');
        }
    }
});

// Anket formunu gönder
pollForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Anket oluşturmak için giriş yapmalısınız.');
        return;
    }
    
    const question = pollQuestionInput.value.trim();
    const options = Array.from(pollOptionsContainer.querySelectorAll('.poll-option'))
        .map(input => ({
            text: input.value.trim(),
            votes: 0
        }));
    
    if (!question || options.some(opt => !opt.text)) {
        alert('Lütfen tüm alanları doldurun.');
        return;
    }
    
    if (options.length < 2) {
        alert('En az iki seçenek eklemelisiniz.');
        return;
    }
    
    try {
        addPollButton.disabled = true;
        
        await db.collection('polls').add({
            question,
            options,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            isActive: true,
            createdBy: auth.currentUser.uid,
            votedUserIds: [] // Boş array ile başlatın
        });
        
        alert('Anket başarıyla oluşturuldu.');
        pollForm.reset();
        
        // Seçenekleri varsayılana resetle (2 seçenek)
        pollOptionsContainer.innerHTML = `
            <div class="input-group mb-2">
                <input type="text" class="form-control poll-option" placeholder="Seçenek 1" required>
                <button type="button" class="btn btn-outline-danger remove-option">×</button>
            </div>
            <div class="input-group mb-2">
                <input type="text" class="form-control poll-option" placeholder="Seçenek 2" required>
                <button type="button" class="btn btn-outline-danger remove-option">×</button>
            </div>
        `;
        
        loadPolls();
    } catch (error) {
        console.error('Anket oluşturma hatası:', error);
        alert('Anket oluşturulurken bir hata oluştu: ' + error.message);
    } finally {
        addPollButton.disabled = false;
    }
});

// Anketleri yükle
async function loadPolls() {
    if (!auth.currentUser) return;
    
    loadingPolls.classList.remove('d-none');
    noPolls.classList.add('d-none');
    pollsList.innerHTML = '';
    
    try {
        const snapshot = await db.collection('polls')
            .orderBy('createdAt', 'desc')
            .get();
        
        if (snapshot.empty) {
            noPolls.classList.remove('d-none');
        } else {
            snapshot.forEach(doc => {
                const poll = doc.data();
                poll.id = doc.id;
                
                const row = document.createElement('tr');
                row.innerHTML = `
                  <td>${poll.question}</td>
                  <td>
                    <ul class="mb-0">
                      ${poll.options.map(opt => `
                        <li>${opt.text} (${opt.votes} oy - ${poll.votedUserIds?.length || 0} katılımcı)</li>
                      `).join('')}
                    </ul>
                  </td>
                  <td>
                    <span class="badge ${poll.isActive ? 'bg-success' : 'bg-danger'}">
                      ${poll.isActive ? 'Aktif' : 'Pasif'}
                    </span>
                  </td>
                  <td>
                    <div class="btn-group btn-group-sm">
                      <button class="btn btn-sm ${poll.isActive ? 'btn-warning' : 'btn-success'} toggle-poll-status" 
                              data-id="${poll.id}" data-status="${poll.isActive}">
                        ${poll.isActive ? 'Pasif Yap' : 'Aktif Yap'}
                      </button>
                      <button class="btn btn-sm btn-danger delete-poll" 
                              data-id="${poll.id}">
                        Sil
                      </button>
                    </div>
                  </td>
                `;
                
                pollsList.appendChild(row);
              });
            // Silme butonlarına event listener ekle
            document.querySelectorAll('.delete-poll').forEach(button => {
                button.addEventListener('click', event => {
                    const pollId = event.target.getAttribute('data-id');
                    confirmDeletePollButton.setAttribute('data-id', pollId);
                    deletePollModal.show();
                });
            });
            
            // Durum değiştirme butonlarına event listener ekle
            document.querySelectorAll('.toggle-poll-status').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const pollId = event.target.getAttribute('data-id');
                    const currentStatus = event.target.getAttribute('data-status') === 'true';
                    
                    try {
                        await db.collection('polls').doc(pollId).update({
                            isActive: !currentStatus
                        });
                        
                        alert(`Anket durumu başarıyla ${!currentStatus ? 'aktif' : 'pasif'} olarak güncellendi.`);
                        loadPolls();
                    } catch (error) {
                        console.error('Anket durumu güncelleme hatası:', error);
                        alert('Anket durumu güncellenirken bir hata oluştu: ' + error.message);
                    }
                });
            });
        }
    } catch (error) {
        console.error('Anket yükleme hatası:', error);
        alert('Anketler yüklenirken bir hata oluştu: ' + error.message);
    } finally {
        loadingPolls.classList.add('d-none');
    }
}

// Anket silme işlemi
confirmDeletePollButton.addEventListener('click', async () => {
    const pollId = confirmDeletePollButton.getAttribute('data-id');
    
    if (!pollId) {
        deletePollModal.hide();
        return;
    }
    
    try {
        await db.collection('polls').doc(pollId).delete();
        alert('Anket başarıyla silindi.');
        loadPolls();
    } catch (error) {
        console.error('Anket silme hatası:', error);
        alert('Anket silinirken bir hata oluştu: ' + error.message);
    } finally {
        deletePollModal.hide();
    }
});

// Yenile butonuna tıklama
refreshPollsButton.addEventListener('click', loadPolls);

// Auth durum değişikliğinde anketleri de yükle
auth.onAuthStateChanged(user => {
    if (user) {
        loadPolls();
    }
});


// Image preview for announcements
announcementImageInput.addEventListener('change', event => {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = e => {
            announcementPreview.src = e.target.result;
            announcementPreview.classList.remove('d-none');
        };
        reader.readAsDataURL(file);
    } else {
        announcementPreview.classList.add('d-none');
    }
});

// Upload image to Cloudinary
const uploadImageToCloudinary = (file) => {
    return new Promise((resolve, reject) => {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('upload_preset', 'upload_image');
        formData.append('api_key', cloudinaryConfig.apiKey);
        
        const cloudinaryUrl = `https://api.cloudinary.com/v1_1/${cloudinaryConfig.cloudName}/image/upload`;

        fetch(cloudinaryUrl, {
            method: 'POST',
            body: formData,
        })
        .then((response) => response.json())
        .then((data) => {
            if (data.secure_url) {
                resolve(data.secure_url);
            } else {
                reject('Error uploading image');
            }
        })
        .catch((error) => {
            reject(error);
        });
    });
};

// Announcement form submission
announcementForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Please login to create announcements');
        return;
    }
    
    const title = announcementTitleInput.value.trim();
    const content = announcementContentInput.value.trim();
    const imageFile = announcementImageInput.files[0];
    
    if (!title || !content) {
        alert('Please fill all required fields');
        return;
    }
    
    try {
        let imageUrl = null;
        
        if (imageFile) {
            imageUrl = await uploadImageToCloudinary(imageFile);
        }
        
        await db.collection('announcements').add({
            title,
            content,
            imageUrl,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            isActive: true,
            createdBy: auth.currentUser.uid
        });
        
        alert('Announcement created successfully!');
        announcementForm.reset();
        announcementPreview.classList.add('d-none');
        loadAnnouncements();
    } catch (error) {
        console.error('Error creating announcement:', error);
        alert('Error creating announcement: ' + error.message);
    }
});

// Load announcements
async function loadAnnouncements() {
    if (!auth.currentUser) return;
    
    loadingAnnouncements.classList.remove('d-none');
    noAnnouncements.classList.add('d-none');
    announcementsList.innerHTML = '';
    
    try {
        const snapshot = await db.collection('announcements')
            .orderBy('createdAt', 'desc')
            .get();
        
        if (snapshot.empty) {
            noAnnouncements.classList.remove('d-none');
        } else {
            snapshot.forEach(doc => {
                const announcement = doc.data();
                announcement.id = doc.id;
                
                const formattedDate = announcement.createdAt 
                    ? new Date(announcement.createdAt.toDate()).toLocaleDateString()
                    : 'N/A';
                
                const statusClass = announcement.isActive ? 'bg-success' : 'bg-danger';
                const statusText = announcement.isActive ? 'Active' : 'Inactive';
                const toggleBtnText = announcement.isActive ? 'Deactivate' : 'Activate';
                const toggleBtnClass = announcement.isActive ? 'btn-warning' : 'btn-success';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${announcement.title}</td>
                    <td>${announcement.content.substring(0, 50)}${announcement.content.length > 50 ? '...' : ''}</td>
                    <td>${formattedDate}</td>
                    <td><span class="badge ${statusClass}">${statusText}</span></td>
                    <td>
                        <div class="btn-group btn-group-sm">
                            <button class="btn btn-sm ${toggleBtnClass} toggle-announcement-status" 
                                    data-id="${announcement.id}" data-status="${announcement.isActive}">
                                ${toggleBtnText}
                            </button>
                            <button class="btn btn-sm btn-danger delete-announcement" 
                                    data-id="${announcement.id}">
                                Delete
                            </button>
                        </div>
                    </td>
                `;
                
                announcementsList.appendChild(row);
            });
            
            // Add event listeners for delete buttons
            document.querySelectorAll('.delete-announcement').forEach(button => {
                button.addEventListener('click', event => {
                    const announcementId = event.target.getAttribute('data-id');
                    confirmDeleteAnnouncementButton.setAttribute('data-id', announcementId);
                    deleteAnnouncementModal.show();
                });
            });
            
            // Add event listeners for status toggle buttons
            document.querySelectorAll('.toggle-announcement-status').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const announcementId = event.target.getAttribute('data-id');
                    const currentStatus = event.target.getAttribute('data-status') === 'true';
                    
                    try {
                        await db.collection('announcements').doc(announcementId).update({
                            isActive: !currentStatus
                        });
                        alert(`Announcement ${!currentStatus ? 'activated' : 'deactivated'} successfully`);
                        loadAnnouncements();
                    } catch (error) {
                        console.error('Error updating announcement status:', error);
                        alert('Error updating announcement status: ' + error.message);
                    }
                });
            });
        }
    } catch (error) {
        console.error('Error loading announcements:', error);
        alert('Error loading announcements: ' + error.message);
    } finally {
        loadingAnnouncements.classList.add('d-none');
    }
}

// Delete announcement
confirmDeleteAnnouncementButton.addEventListener('click', async () => {
    const announcementId = confirmDeleteAnnouncementButton.getAttribute('data-id');
    
    if (!announcementId) {
        deleteAnnouncementModal.hide();
        return;
    }
    
    try {
        await db.collection('announcements').doc(announcementId).delete();
        alert('Announcement deleted successfully');
        loadAnnouncements();
    } catch (error) {
        console.error('Error deleting announcement:', error);
        alert('Error deleting announcement: ' + error.message);
    } finally {
        deleteAnnouncementModal.hide();
    }
});

// Refresh announcements
refreshAnnouncementsButton.addEventListener('click', loadAnnouncements);

// Auth state listener
auth.onAuthStateChanged(user => {
    if (user) {
        loginContainer.classList.add('d-none');
        userInfo.classList.remove('d-none');
        userEmail.textContent = user.email;
        authRequired.classList.add('d-none');
        adminContent.classList.remove('d-none');
        
        // Load all data
        loadNews();
        loadChatRooms();
        loadPolls();
        loadAnnouncements();
    } else {
        loginContainer.classList.remove('d-none');
        userInfo.classList.add('d-none');
        authRequired.classList.remove('d-none');
        adminContent.classList.add('d-none');
    }
});


// DOM elemanları - YouTube Videoları
const videoForm = document.getElementById('video-form');
const videoTitleInput = document.getElementById('video-title');
const videoUrlInput = document.getElementById('video-url');
const videoDescriptionInput = document.getElementById('video-description');
const videoCategorySelect = document.getElementById('video-category');
const videoPreviewContainer = document.getElementById('video-preview-container');
const videoPreview = document.getElementById('video-preview');
const addVideoButton = document.getElementById('add-video-button');
const refreshVideosButton = document.getElementById('refresh-videos');
const videosList = document.getElementById('videos-list');
const loadingVideos = document.getElementById('loading-videos');
const noVideos = document.getElementById('no-videos');
const deleteVideoModal = new bootstrap.Modal(document.getElementById('deleteVideoModal'));
const confirmDeleteVideoButton = document.getElementById('confirm-delete-video');

// YouTube video ID çıkarma fonksiyonu
function extractYouTubeID(url) {
    if (!url) return null;
    
    // Eğer sadece ID girilmişse
    if (url.length === 11) return url;
    
    // Normal YouTube URL'sinden ID çıkarma
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return (match && match[7].length === 11) ? match[7] : null;
}

// Video URL'si değiştiğinde önizleme göster
videoUrlInput.addEventListener('input', () => {
    const videoID = extractYouTubeID(videoUrlInput.value.trim());
    
    if (videoID) {
        const embedHtml = `<iframe width="100%" height="100%" src="https://www.youtube.com/embed/${videoID}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>`;
        videoPreview.innerHTML = embedHtml;
        videoPreviewContainer.classList.remove('d-none');
    } else {
        videoPreviewContainer.classList.add('d-none');
    }
});

// Video formunu gönder
videoForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Video eklemek için giriş yapmalısınız.');
        return;
    }
    
    const title = videoTitleInput.value.trim();
    const url = videoUrlInput.value.trim();
    const description = videoDescriptionInput.value.trim();
    const category = videoCategorySelect.value;
    
    const videoID = extractYouTubeID(url);
    
    if (!title || !videoID || !category) {
        alert('Lütfen gerekli alanları doldurun ve geçerli bir YouTube URL\'si girin.');
        return;
    }
    
    try {
        addVideoButton.disabled = true;
        
        await db.collection('videos').add({
            title,
            videoID,
            description,
            category,
            thumbnailUrl: `https://img.youtube.com/vi/${videoID}/mqdefault.jpg`,
            publishDate: firebase.firestore.FieldValue.serverTimestamp(),
            addedBy: auth.currentUser.uid,
            addedByEmail: auth.currentUser.email
        });
        
        alert('Video başarıyla eklendi.');
        videoForm.reset();
        videoPreviewContainer.classList.add('d-none');
        loadVideos();
    } catch (error) {
        console.error('Video ekleme hatası:', error);
        alert('Video eklenirken bir hata oluştu: ' + error.message);
    } finally {
        addVideoButton.disabled = false;
    }
});

// Videoları yükle
async function loadVideos() {
    if (!auth.currentUser) return;
    
    loadingVideos.classList.remove('d-none');
    noVideos.classList.add('d-none');
    videosList.innerHTML = '';
    
    try {
        const snapshot = await db.collection('videos')
            .orderBy('publishDate', 'desc')
            .get();
        
        if (snapshot.empty) {
            noVideos.classList.remove('d-none');
        } else {
            snapshot.forEach(doc => {
                const video = doc.data();
                video.id = doc.id;
                
                // Tarih formatla
                let formattedDate = 'Tarih bilgisi yok';
                if (video.publishDate) {
                    const date = video.publishDate.toDate();
                    formattedDate = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
                }
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td class="align-middle">
                        <img src="${video.thumbnailUrl}" alt="${video.title}" class="video-thumbnail" 
                        style="width: 120px; height: 68px; object-fit: cover; border-radius: 4px;">
                    </td>
                    <td class="align-middle">
                        <strong>${video.title}</strong>
                        ${video.description ? `<p class="small text-muted mb-0">${video.description.substring(0, 80)}${video.description.length > 80 ? '...' : ''}</p>` : ''}
                    </td>
                    <td class="align-middle">${video.category}</td>
                    <td class="align-middle">${formattedDate}</td>
                    <td class="align-middle">
                        <button class="btn btn-sm btn-danger delete-video" data-id="${video.id}">Sil</button>
                    </td>
                `;
                
                videosList.appendChild(row);
            });
            
            // Silme butonlarına event listener ekle
            document.querySelectorAll('.delete-video').forEach(button => {
                button.addEventListener('click', event => {
                    const videoId = event.target.getAttribute('data-id');
                    confirmDeleteVideoButton.setAttribute('data-id', videoId);
                    deleteVideoModal.show();
                });
            });
        }
    } catch (error) {
        console.error('Video yükleme hatası:', error);
        alert('Videolar yüklenirken bir hata oluştu: ' + error.message);
    } finally {
        loadingVideos.classList.add('d-none');
    }
}

// Yenile butonuna tıklama
refreshVideosButton.addEventListener('click', loadVideos);

// Video silme işlemi
confirmDeleteVideoButton.addEventListener('click', async () => {
    const videoId = confirmDeleteVideoButton.getAttribute('data-id');
    
    if (!videoId) {
        deleteVideoModal.hide();
        return;
    }
    
    try {
        await db.collection('videos').doc(videoId).delete();
        alert('Video başarıyla silindi.');
        loadVideos();
    } catch (error) {
        console.error('Video silme hatası:', error);
        alert('Video silinirken bir hata oluştu: ' + error.message);
    } finally {
        deleteVideoModal.hide();
    }
});

// Auth durum değişikliğinde videoları da yükle
auth.onAuthStateChanged(user => {
    if (user) {
        loadVideos(); // Diğer yükleme işlemlerine ek olarak
    }
});