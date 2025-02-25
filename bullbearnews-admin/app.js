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

// Auth durum değişikliğini izle
auth.onAuthStateChanged(user => {
    if (user) {
        loginContainer.classList.add('d-none');
        userInfo.classList.remove('d-none');
        userEmail.textContent = user.email;
        authRequired.classList.add('d-none');
        adminContent.classList.remove('d-none');
        loadNews();
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

// Cloudinary'ye görsel yükleme
const uploadImageToCloudinary = (file) => {
    return new Promise((resolve, reject) => {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('upload_preset', 'upload_image');  // Cloudinary'deki upload preset
        formData.append('api_key', cloudinaryConfig.apiKey);
        
        // Cloudinary API URL
        const cloudinaryUrl = `https://api.cloudinary.com/v1_1/${cloudinaryConfig.cloudName}/image/upload`;

        // Fetch ile görseli Cloudinary'ye yükle
        fetch(cloudinaryUrl, {
            method: 'POST',
            body: formData,
        })
        .then((response) => response.json())
        .then((data) => {
            if (data.secure_url) {
                resolve(data.secure_url); // Yüklenen görselin URL'si
            } else {
                reject('Görsel yüklenirken bir hata oluştu');
            }
        })
        .catch((error) => {
            reject(error);
        });
    });
};

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
