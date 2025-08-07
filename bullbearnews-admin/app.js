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
    cloudName: 'dh7lpyg7t',
    apiKey: '395487784973678',
    apiSecret: '3pitWEdmr5Qbvm6TOspCj1PH8JE',
};

// Crypto tags database - Crypto ile alakalı İngilizce taglar
const cryptoTags = [
    // Major Cryptocurrencies
    'Bitcoin', 'BTC', 'Ethereum', 'ETH', 'Binance', 'BNB', 'Cardano', 'ADA',
    'Solana', 'SOL', 'XRP', 'Ripple', 'Polkadot', 'DOT', 'Dogecoin', 'DOGE',
    'Avalanche', 'AVAX', 'Polygon', 'MATIC', 'Chainlink', 'LINK', 'Cosmos', 'ATOM',
    'Algorand', 'ALGO', 'Tezos', 'XTZ', 'Litecoin', 'LTC', 'Monero', 'XMR',
    
    // DeFi Ecosystem
    'DeFi', 'Decentralized Finance', 'Uniswap', 'UNI', 'SushiSwap', 'SUSHI',
    'PancakeSwap', 'CAKE', 'Aave', 'Compound', 'COMP', 'MakerDAO', 'MKR',
    'Yearn Finance', 'YFI', 'Curve', 'CRV', 'Balancer', 'BAL', 'Synthetix', 'SNX',
    'Liquidity Pool', 'Yield Farming', 'Liquidity Mining', 'AMM', 'DEX',
    
    // NFT & Gaming
    'NFT', 'Non-Fungible Token', 'OpenSea', 'Rarible', 'SuperRare', 'Foundation',
    'Async Art', 'KnownOrigin', 'GameFi', 'Play2Earn', 'P2E', 'Metaverse',
    'Axie Infinity', 'The Sandbox', 'Decentraland', 'MANA', 'CryptoPunks',
    
    // Technology & Infrastructure
    'Blockchain', 'Smart Contract', 'Web3', 'dApp', 'Protocol', 'Layer 2',
    'Layer2', 'Scaling', 'Rollups', 'Sidechain', 'Cross-chain', 'Bridge',
    'Interoperability', 'Oracle', 'Consensus', 'PoS', 'PoW', 'Validator',
    'Node', 'Mining', 'Staking', 'Delegated Proof of Stake', 'DPoS',
    
    // Market & Trading
    'Trading', 'Investment', 'Portfolio', 'Bull Market', 'Bear Market',
    'HODL', 'FOMO', 'FUD', 'Diamond Hands', 'Paper Hands', 'Whale',
    'Market Cap', 'Volume', 'Volatility', 'Correlation', 'Technical Analysis',
    'Fundamental Analysis', 'Sentiment Analysis', 'Arbitrage', 'MEV',
    
    // Governance & DAO
    'DAO', 'Governance', 'Token', 'Governance Token', 'Voting', 'Proposal',
    'Treasury', 'Community', 'Decentralized Autonomous Organization',
    
    // Finance & Investment
    'ICO', 'IDO', 'IEO', 'Token Sale', 'Airdrop', 'Vesting', 'Tokenomics',
    'Market Making', 'Flash Loan', 'Lending', 'Borrowing', 'Collateral',
    'Liquidation', 'Interest Rate', 'APY', 'TVL', 'Total Value Locked',
    
    // Infrastructure & Services
    'Wallet', 'Exchange', 'CEX', 'Centralized Exchange', 'Hardware Wallet',
    'Cold Storage', 'Hot Wallet', 'Custody', 'Security', 'Private Key',
    'Public Key', 'Seed Phrase', 'Multi-sig', 'KYC', 'AML',
    
    // Development & Updates
    'Fork', 'Hard Fork', 'Soft Fork', 'Upgrade', 'Mainnet', 'Testnet',
    'Alpha', 'Beta', 'Launch', 'Deployment', 'Gas Fee', 'Transaction Fee',
    'Block', 'Block Time', 'Confirmation', 'Network Effect',
    
    // Regulation & Adoption
    'Regulation', 'Compliance', 'SEC', 'CFTC', 'Legal', 'Institutional',
    'Retail', 'Adoption', 'Mass Adoption', 'Enterprise', 'Corporate',
    'ETF', 'Futures', 'Derivatives', 'Central Bank Digital Currency', 'CBDC',
    
    // Trends & News
    'Breaking News', 'Analysis', 'Research', 'Report', 'Survey', 'Study',
    'Trend', 'Innovation', 'Partnership', 'Integration', 'Announcement',
    'Launch', 'Development', 'Milestone', 'Achievement', 'Growth'
];

// DOM Elements
const loginButton = document.getElementById('login-button');
const logoutButton = document.getElementById('logout-button');
const loginContainer = document.getElementById('login-container');
const userInfo = document.getElementById('user-info');
const userEmail = document.getElementById('user-email');
const authRequired = document.getElementById('auth-required');
const adminContent = document.getElementById('admin-content');

// Modals
const deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));
const deleteVideoModal = new bootstrap.Modal(document.getElementById('deleteVideoModal'));
const deleteRoomModal = new bootstrap.Modal(document.getElementById('deleteRoomModal'));
const deletePollModal = new bootstrap.Modal(document.getElementById('deletePollModal'));
const deleteAnnouncementModal = new bootstrap.Modal(document.getElementById('deleteAnnouncementModal'));
const clearMessagesModal = new bootstrap.Modal(document.getElementById('clearMessagesModal'));

// Section Management
function showSection(sectionName) {
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.classList.add('d-none');
    });
    
    // Show selected section
    document.getElementById(sectionName + '-section').classList.remove('d-none');
    
    // Update nav active state
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    event.target.classList.add('active');
    
    // Close mobile sidebar
    if (window.innerWidth <= 768) {
        document.getElementById('sidebar').classList.remove('show');
    }
}

function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('show');
}

// Tag Management System
class TagManager {
    constructor(containerId, inputId, suggestionsId, tags = []) {
        this.container = document.getElementById(containerId);
        this.input = document.getElementById(inputId);
        this.suggestions = document.getElementById(suggestionsId);
        this.selectedTags = new Set();
        this.availableTags = tags;
        
        this.init();
    }
    
    init() {
        this.input.addEventListener('input', (e) => this.handleInput(e));
        this.input.addEventListener('keydown', (e) => this.handleKeydown(e));
        this.container.addEventListener('click', () => this.input.focus());
        
        // Close suggestions when clicking outside
        document.addEventListener('click', (e) => {
            if (!this.container.contains(e.target)) {
                this.hideSuggestions();
            }
        });
    }
    
    handleInput(e) {
        const value = e.target.value.trim();
        if (value.length > 0) {
            this.showSuggestions(value);
        } else {
            this.hideSuggestions();
        }
    }
    
    handleKeydown(e) {
        if (e.key === 'Enter' || e.key === ',') {
            e.preventDefault();
            const value = this.input.value.trim();
            if (value) {
                this.addTag(value);
                this.input.value = '';
                this.hideSuggestions();
            }
        } else if (e.key === 'Backspace' && this.input.value === '') {
            this.removeLastTag();
        }
    }
    
    showSuggestions(query) {
        const filtered = this.availableTags.filter(tag => 
            tag.toLowerCase().includes(query.toLowerCase()) && 
            !this.selectedTags.has(tag)
        ).slice(0, 8);
        
        if (filtered.length > 0) {
            this.suggestions.innerHTML = filtered.map(tag => 
                `<div class="tag-suggestion-item" onclick="tagManagers['${this.container.id}'].addTag('${tag}')">${tag}</div>`
            ).join('');
            this.suggestions.classList.remove('d-none');
        } else {
            this.hideSuggestions();
        }
    }
    
    hideSuggestions() {
        this.suggestions.classList.add('d-none');
    }
    
    addTag(tag) {
        const formattedTag = tag.charAt(0).toUpperCase() + tag.slice(1);
        if (!this.selectedTags.has(formattedTag)) {
            this.selectedTags.add(formattedTag);
            this.renderTags();
            this.input.value = '';
            this.hideSuggestions();
        }
    }
    
    removeTag(tag) {
        this.selectedTags.delete(tag);
        this.renderTags();
    }
    
    removeLastTag() {
        const tags = Array.from(this.selectedTags);
        if (tags.length > 0) {
            this.removeTag(tags[tags.length - 1]);
        }
    }
    
    renderTags() {
        const tagElements = Array.from(this.selectedTags).map(tag => 
            `<div class="tag-item">
                ${tag}
                <button type="button" class="tag-remove" onclick="tagManagers['${this.container.id}'].removeTag('${tag}')">×</button>
            </div>`
        ).join('');
        
        // Clear container and add tags + input
        this.container.innerHTML = tagElements + '<input type="text" class="tag-input" placeholder="Type to add crypto tags..." autocomplete="off">';
        
        // Reattach input element
        this.input = this.container.querySelector('.tag-input');
        this.input.addEventListener('input', (e) => this.handleInput(e));
        this.input.addEventListener('keydown', (e) => this.handleKeydown(e));
    }
    
    getTags() {
        return Array.from(this.selectedTags);
    }
    
    setTags(tags) {
        this.selectedTags = new Set(tags);
        this.renderTags();
    }
    
    clear() {
        this.selectedTags.clear();
        this.renderTags();
    }
}

// Initialize tag managers
const tagManagers = {};

// Auth state management
auth.onAuthStateChanged(user => {
    if (user) {
        loginContainer.classList.add('d-none');
        userInfo.classList.remove('d-none');
        userEmail.textContent = user.email;
        authRequired.classList.add('d-none');
        adminContent.classList.remove('d-none');
        
        // Initialize tag managers after auth
        tagManagers['news-tag-container'] = new TagManager('news-tag-container', 'news-tag-input', 'news-tag-suggestions', cryptoTags);
        tagManagers['video-tag-container'] = new TagManager('video-tag-container', 'video-tag-input', 'video-tag-suggestions', cryptoTags);
        
        // Load all data
        loadDashboardStats();
        loadNews();
        loadVideos();
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

// Login/Logout
loginButton.addEventListener('click', () => {
    auth.signInWithPopup(new firebase.auth.GoogleAuthProvider())
        .catch(error => {
            console.error('Login error:', error);
            alert('Login failed: ' + error.message);
        });
});

logoutButton.addEventListener('click', () => {
    auth.signOut().catch(error => {
        console.error('Logout error:', error);
        alert('Logout failed: ' + error.message);
    });
});

// Dashboard Stats
async function loadDashboardStats() {
    try {
        // Önce chatRooms koleksiyonunu al
        const [newsSnap, videosSnap, roomsSnap, pollsSnap] = await Promise.all([
            db.collection('news').get(),
            db.collection('videos').get(),
            db.collection('chatRooms').get(),
            db.collection('polls').where('isActive', '==', true).get()
        ]);

        // Tüm mesaj sayısını hesapla
        let totalMessages = 0;
        for (const roomDoc of roomsSnap.docs) {
            const messagesSnap = await db
                .collection('chatRooms')
                .doc(roomDoc.id)
                .collection('messages')
                .get();

            totalMessages += messagesSnap.size;
        }

        // Dashboard'a yaz
        document.getElementById('total-news').textContent = newsSnap.size;
        document.getElementById('total-videos').textContent = videosSnap.size;
        document.getElementById('total-rooms').textContent = roomsSnap.size;
        document.getElementById('total-polls').textContent = pollsSnap.size;
        document.getElementById('total-messages').textContent = totalMessages;

    } catch (error) {
        console.error('Error loading dashboard stats:', error);
    }
}


// Image preview handlers
document.getElementById('image').addEventListener('change', event => {
    const file = event.target.files[0];
    const preview = document.getElementById('image-preview');
    if (file) {
        const reader = new FileReader();
        reader.onload = e => {
            preview.src = e.target.result;
            preview.classList.remove('d-none');
        };
        reader.readAsDataURL(file);
    } else {
        preview.classList.add('d-none');
    }
});

document.getElementById('announcement-image').addEventListener('change', event => {
    const file = event.target.files[0];
    const preview = document.getElementById('announcement-preview');
    if (file) {
        const reader = new FileReader();
        reader.onload = e => {
            preview.src = e.target.result;
            preview.classList.remove('d-none');
        };
        reader.readAsDataURL(file);
    } else {
        preview.classList.add('d-none');
    }
});

// Video preview
document.getElementById('video-url').addEventListener('input', () => {
    const videoID = extractYouTubeID(document.getElementById('video-url').value.trim());
    const container = document.getElementById('video-preview-container');
    const preview = document.getElementById('video-preview');
    
    if (videoID) {
        const embedHtml = `<iframe width="100%" height="100%" src="https://www.youtube.com/embed/${videoID}" frameborder="0" allowfullscreen></iframe>`;
        preview.innerHTML = embedHtml;
        container.classList.remove('d-none');
    } else {
        container.classList.add('d-none');
    }
});

function extractYouTubeID(url) {
    if (!url) return null;
    if (url.length === 11) return url;
    
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return (match && match[7].length === 11) ? match[7] : null;
}

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
        .then(response => response.json())
        .then(data => {
            if (data.secure_url) {
                resolve(data.secure_url);
            } else {
                reject('Error uploading image');
            }
        })
        .catch(error => reject(error));
    });
};

// News form submission
document.getElementById('news-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Please login to add news');
        return;
    }
    
    const title = document.getElementById('title').value.trim();
    const content = document.getElementById('content').value.trim();
    const category = document.getElementById('category').value;
    const author = document.getElementById('author').value.trim();
    const imageFile = document.getElementById('image').files[0];
    const tags = tagManagers['news-tag-container'].getTags();
    
    if (!title || !content || !category || !author || !imageFile) {
        alert('Please fill all required fields');
        return;
    }
    
    try {
        const submitButton = document.getElementById('submit-button');
        const progress = document.getElementById('upload-progress');
        const progressBar = progress.querySelector('.progress-bar');
        
        submitButton.disabled = true;
        progress.classList.remove('d-none');
        
        // Upload image
        const imageUrl = await uploadImageToCloudinary(imageFile);
        
        // Add to Firestore with tags
        await db.collection('news').add({
            title,
            content,
            category,
            author,
            imageUrl,
            tags: tags, // Add tags array
            publishDate: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        alert('News article published successfully!');
        
        // Reset form
        document.getElementById('news-form').reset();
        document.getElementById('image-preview').classList.add('d-none');
        tagManagers['news-tag-container'].clear();
        
        submitButton.disabled = false;
        progress.classList.add('d-none');
        progressBar.style.width = '0%';
        
        loadNews();
        loadDashboardStats();
    } catch (error) {
        console.error('Error adding news:', error);
        alert('Error adding news: ' + error.message);
        document.getElementById('submit-button').disabled = false;
        document.getElementById('upload-progress').classList.add('d-none');
    }
});

// Video form submission
document.getElementById('video-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Please login to add videos');
        return;
    }
    
    const title = document.getElementById('video-title').value.trim();
    const url = document.getElementById('video-url').value.trim();
    const description = document.getElementById('video-description').value.trim();
    const category = document.getElementById('video-category').value;
    const tags = tagManagers['video-tag-container'].getTags();
    
    const videoID = extractYouTubeID(url);
    
    if (!title || !videoID || !category) {
        alert('Please fill required fields and provide valid YouTube URL');
        return;
    }
    
    try {
        const addButton = document.getElementById('add-video-button');
        addButton.disabled = true;
        
        await db.collection('videos').add({
            title,
            videoID,
            description,
            category,
            tags: tags, // Add tags array
            thumbnailUrl: `https://img.youtube.com/vi/${videoID}/mqdefault.jpg`,
            publishDate: firebase.firestore.FieldValue.serverTimestamp(),
            addedBy: auth.currentUser.uid,
            addedByEmail: auth.currentUser.email
        });
        
        alert('Video added successfully!');
        document.getElementById('video-form').reset();
        document.getElementById('video-preview-container').classList.add('d-none');
        tagManagers['video-tag-container'].clear();
        
        loadVideos();
        loadDashboardStats();
    } catch (error) {
        console.error('Error adding video:', error);
        alert('Error adding video: ' + error.message);
    } finally {
        document.getElementById('add-video-button').disabled = false;
    }
});

// Load news
async function loadNews() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-news');
    const noNews = document.getElementById('no-news');
    const newsList = document.getElementById('news-list');
    
    loading.classList.remove('d-none');
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
                
                // Format date
                let formattedDate = 'No date';
                if (news.publishDate) {
                    const date = news.publishDate.toDate();
                    formattedDate = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
                }
                
                // Format tags
                const tagsHtml = news.tags && news.tags.length > 0 
                    ? news.tags.map(tag => `<span class="badge bg-secondary me-1">${tag}</span>`).join('')
                    : '<span class="text-muted">No tags</span>';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>
                        <img src="${news.imageUrl}" alt="${news.title}" class="thumbnail" 
                        onerror="this.src='https://via.placeholder.com/80x60?text=Image'">
                    </td>
                    <td>
                        <strong>${news.title}</strong>
                        <br>
                        <small class="text-muted">${news.content.substring(0, 50)}...</small>
                    </td>
                    <td><span class="badge bg-primary">${news.category}</span></td>
                    <td>${tagsHtml}</td>
                    <td>${formattedDate}</td>
                    <td>${news.author}</td>
                    <td>
                        <button class="btn btn-sm btn-danger delete-news" data-id="${news.id}">
                            <i class="bi bi-trash"></i>
                        </button>
                    </td>
                `;
                
                newsList.appendChild(row);
            });
            
            // Add delete button listeners
            document.querySelectorAll('.delete-news').forEach(button => {
                button.addEventListener('click', event => {
                    const newsId = event.target.closest('button').getAttribute('data-id');
                    document.getElementById('confirm-delete').setAttribute('data-id', newsId);
                    deleteModal.show();
                });
            });
        }
    } catch (error) {
        console.error('Error loading news:', error);
        alert('Error loading news: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}

// Load videos
async function loadVideos() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-videos');
    const noVideos = document.getElementById('no-videos');
    const videosList = document.getElementById('videos-list');
    
    loading.classList.remove('d-none');
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
                
                // Format date
                let formattedDate = 'No date';
                if (video.publishDate) {
                    const date = video.publishDate.toDate();
                    formattedDate = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
                }
                
                // Format tags
                const tagsHtml = video.tags && video.tags.length > 0 
                    ? video.tags.map(tag => `<span class="badge bg-secondary me-1">${tag}</span>`).join('')
                    : '<span class="text-muted">No tags</span>';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>
                        <img src="${video.thumbnailUrl}" alt="${video.title}" class="thumbnail">
                    </td>
                    <td>
                        <strong>${video.title}</strong>
                        ${video.description ? `<br><small class="text-muted">${video.description.substring(0, 50)}...</small>` : ''}
                    </td>
                    <td><span class="badge bg-info">${video.category}</span></td>
                    <td>${tagsHtml}</td>
                    <td>${formattedDate}</td>
                    <td>
                        <button class="btn btn-sm btn-danger delete-video" data-id="${video.id}">
                            <i class="bi bi-trash"></i>
                        </button>
                    </td>
                `;
                
                videosList.appendChild(row);
            });
            
            // Add delete button listeners
            document.querySelectorAll('.delete-video').forEach(button => {
                button.addEventListener('click', event => {
                    const videoId = event.target.closest('button').getAttribute('data-id');
                    document.getElementById('confirm-delete-video').setAttribute('data-id', videoId);
                    deleteVideoModal.show();
                });
            });
        }
    } catch (error) {
        console.error('Error loading videos:', error);
        alert('Error loading videos: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}

// Load chat rooms
async function loadChatRooms() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-chat-rooms');
    const noChatRooms = document.getElementById('no-chat-rooms');
    const chatRoomsList = document.getElementById('chat-rooms-list');
    
    loading.classList.remove('d-none');
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
                
                // Format date
                let formattedDate = 'No date';
                if (room.createdAt) {
                    const date = room.createdAt.toDate();
                    formattedDate = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
                }
                
                // Get message count
                const messagesSnapshot = await db.collection('chatRooms')
                    .doc(room.id)
                    .collection('messages')
                    .get();
                
                const messageCount = messagesSnapshot.size;
                const isActive = room.isActive !== undefined ? room.isActive : true;
                const statusClass = isActive ? 'bg-success' : 'bg-danger';
                const statusText = isActive ? 'Active' : 'Inactive';
                const toggleBtnText = isActive ? 'Deactivate' : 'Activate';
                const toggleBtnClass = isActive ? 'btn-warning' : 'btn-success';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td><strong>${room.name}</strong></td>
                    <td>${room.description}</td>
                    <td>${formattedDate}</td>
                    <td><span class="badge bg-info">${messageCount}</span></td>
                    <td><span class="badge ${statusClass}">${statusText}</span></td>
                    <td>
                        <div class="btn-group btn-group-sm">
                            <button class="btn ${toggleBtnClass} toggle-room-status" data-id="${room.id}" data-status="${isActive}">
                                ${toggleBtnText}
                            </button>
                            <button class="btn btn-info clear-messages" data-id="${room.id}" data-name="${room.name}">
                                Clear
                            </button>
                            <button class="btn btn-danger delete-room" data-id="${room.id}">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </td>
                `;
                
                chatRoomsList.appendChild(row);
            }
            
            // Add event listeners
            document.querySelectorAll('.delete-room').forEach(button => {
                button.addEventListener('click', event => {
                    const roomId = event.target.closest('button').getAttribute('data-id');
                    document.getElementById('confirm-delete-room').setAttribute('data-id', roomId);
                    deleteRoomModal.show();
                });
            });
            
            document.querySelectorAll('.toggle-room-status').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const roomId = event.target.getAttribute('data-id');
                    const currentStatus = event.target.getAttribute('data-status') === 'true';
                    
                    try {
                        await db.collection('chatRooms').doc(roomId).update({
                            isActive: !currentStatus
                        });
                        
                        alert(`Room status updated to ${!currentStatus ? 'active' : 'inactive'}`);
                        loadChatRooms();
                    } catch (error) {
                        console.error('Error updating room status:', error);
                        alert('Error updating room status: ' + error.message);
                    }
                });
            });
            
            document.querySelectorAll('.clear-messages').forEach(button => {
                button.addEventListener('click', event => {
                    const roomId = event.target.getAttribute('data-id');
                    const roomName = event.target.getAttribute('data-name');
                    
                    document.getElementById('room-name-for-clear').textContent = roomName;
                    document.getElementById('confirm-clear-messages').setAttribute('data-id', roomId);
                    clearMessagesModal.show();
                });
            });
        }
    } catch (error) {
        console.error('Error loading chat rooms:', error);
        alert('Error loading chat rooms: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}


async function loadAllMessages() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-messages');
    const noMessages = document.getElementById('no-messages');
    const messagesList = document.getElementById('messages-list');
    
    loading.classList.remove('d-none');
    noMessages.classList.add('d-none');
    messagesList.innerHTML = '';
    
    try {
        // Tüm chat room'ları al
        const roomsSnapshot = await db.collection('chatRooms').get();
        let allMessages = [];
        
        // Her room için mesajları al
        for (const roomDoc of roomsSnapshot.docs) {
            const room = roomDoc.data();
            const messagesSnapshot = await db.collection('chatRooms')
                .doc(roomDoc.id)
                .collection('messages')
                .orderBy('timestamp', 'desc')
                .limit(100) // Her room'dan son 100 mesaj
                .get();
            
            messagesSnapshot.forEach(messageDoc => {
                const message = messageDoc.data();
                allMessages.push({
                    id: messageDoc.id,
                    roomId: roomDoc.id,
                    roomName: room.name,
                    ...message
                });
            });
        }
        
        // Tüm mesajları zaman sırasına göre sırala
        allMessages.sort((a, b) => b.timestamp.toDate() - a.timestamp.toDate());
        
        if (allMessages.length === 0) {
            noMessages.classList.remove('d-none');
        } else {
            allMessages.forEach(message => {
                const formattedDate = message.timestamp 
                    ? new Date(message.timestamp.toDate()).toLocaleString()
                    : 'No date';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>
                        <div class="user-info">
                            ${message.userProfileImage ? 
                                `<img src="${message.userProfileImage}" alt="Avatar" class="user-avatar">` : 
                                `<div class="user-avatar-placeholder">${message.username.charAt(0).toUpperCase()}</div>`
                            }
                            <div>
                                <strong>${message.username || 'Unknown User'}</strong>
                                <br>
                                <small class="text-muted">${message.userId}</small>
                            </div>
                        </div>
                    </td>
                    <td>
                        <span class="badge bg-info">${message.roomName}</span>
                    </td>
                    <td>
                        <div class="message-content" title="${message.content}">
                            ${message.content.length > 50 ? message.content.substring(0, 50) + '...' : message.content}
                        </div>
                    </td>
                    <td>
                        <small>${formattedDate}</small>
                    </td>
                    <td>
                        <span class="badge bg-secondary">${message.likes || 0} likes</span>
                    </td>
                    <td>
                        <div class="btn-group btn-group-sm">
                            <button class="btn btn-warning view-message" data-message='${JSON.stringify(message)}' title="View Full Message">
                                <i class="bi bi-eye"></i>
                            </button>
                            <button class="btn btn-danger delete-message" 
                                    data-room-id="${message.roomId}" 
                                    data-message-id="${message.id}" 
                                    title="Delete Message">
                                <i class="bi bi-trash"></i>
                            </button>
                            <button class="btn btn-dark ban-user" 
                                    data-user-id="${message.userId}" 
                                    data-room-id="${message.roomId}"
                                    data-username="${message.username}"
                                    title="Ban User from Room">
                                <i class="bi bi-person-x"></i>
                            </button>
                        </div>
                    </td>
                `;
                
                messagesList.appendChild(row);
            });
            
            // Event listeners ekle
            addMessageEventListeners();
        }
    } catch (error) {
        console.error('Error loading messages:', error);
        alert('Error loading messages: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}

function addMessageEventListeners() {
    // View message listeners
    document.querySelectorAll('.view-message').forEach(button => {
        button.addEventListener('click', (event) => {
            const messageData = JSON.parse(event.target.closest('button').getAttribute('data-message'));
            showMessageModal(messageData);
        });
    });
    
    // Delete message listeners
    document.querySelectorAll('.delete-message').forEach(button => {
        button.addEventListener('click', (event) => {
            const btn = event.target.closest('button');
            const roomId = btn.getAttribute('data-room-id');
            const messageId = btn.getAttribute('data-message-id');
            
            document.getElementById('confirm-delete-message').setAttribute('data-room-id', roomId);
            document.getElementById('confirm-delete-message').setAttribute('data-message-id', messageId);
            deleteMessageModal.show();
        });
    });
    
    // Ban user listeners
    document.querySelectorAll('.ban-user').forEach(button => {
        button.addEventListener('click', (event) => {
            const btn = event.target.closest('button');
            const userId = btn.getAttribute('data-user-id');
            const roomId = btn.getAttribute('data-room-id');
            const username = btn.getAttribute('data-username');
            
            document.getElementById('ban-username').textContent = username;
            document.getElementById('confirm-ban-user').setAttribute('data-user-id', userId);
            document.getElementById('confirm-ban-user').setAttribute('data-room-id', roomId);
            banUserModal.show();
        });
    });
}

function showMessageModal(message) {
    const modal = document.getElementById('messageModal');
    const modalTitle = modal.querySelector('.modal-title');
    const modalBody = modal.querySelector('.modal-body');
    
    modalTitle.innerHTML = `<i class="bi bi-chat-text"></i> Message Details`;
    
    const formattedDate = message.timestamp 
        ? new Date(message.timestamp.toDate()).toLocaleString()
        : 'No date';
    
    modalBody.innerHTML = `
        <div class="message-details">
            <div class="row mb-3">
                <div class="col-md-6">
                    <strong>User:</strong> ${message.username}
                </div>
                <div class="col-md-6">
                    <strong>Room:</strong> ${message.roomName}
                </div>
            </div>
            <div class="row mb-3">
                <div class="col-md-6">
                    <strong>Date:</strong> ${formattedDate}
                </div>
                <div class="col-md-6">
                    <strong>Likes:</strong> ${message.likes || 0}
                </div>
            </div>
            <div class="mb-3">
                <strong>User ID:</strong>
                <code>${message.userId}</code>
            </div>
            <div class="mb-3">
                <strong>Message Content:</strong>
                <div class="message-content-full p-3 mt-2" style="background: rgba(255,255,255,0.1); border-radius: 8px; white-space: pre-wrap;">
                    ${message.content}
                </div>
            </div>
        </div>
    `;
    
    new bootstrap.Modal(modal).show();
}

// Message filtering functions
function filterMessagesByRoom() {
    const selectedRoom = document.getElementById('room-filter').value;
    const rows = document.querySelectorAll('#messages-list tr');
    
    rows.forEach(row => {
        if (selectedRoom === '' || selectedRoom === 'all') {
            row.style.display = '';
        } else {
            const roomBadge = row.querySelector('.badge');
            if (roomBadge && roomBadge.textContent === selectedRoom) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        }
    });
}

function filterMessagesByUser() {
    const searchTerm = document.getElementById('user-search').value.toLowerCase();
    const rows = document.querySelectorAll('#messages-list tr');
    
    rows.forEach(row => {
        const username = row.querySelector('strong').textContent.toLowerCase();
        const userId = row.querySelector('.text-muted').textContent.toLowerCase();
        
        if (searchTerm === '' || username.includes(searchTerm) || userId.includes(searchTerm)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}

// Load room options for filter
async function loadRoomFilter() {
    try {
        const roomsSnapshot = await db.collection('chatRooms').get();
        const roomFilter = document.getElementById('room-filter');
        
        roomFilter.innerHTML = '<option value="all">All Rooms</option>';
        
        roomsSnapshot.forEach(doc => {
            const room = doc.data();
            const option = document.createElement('option');
            option.value = room.name;
            option.textContent = room.name;
            roomFilter.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading room filter:', error);
    }
}

// Delete message function
async function deleteMessage(roomId, messageId) {
    try {
        await db.collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .doc(messageId)
            .delete();
        
        alert('Message deleted successfully');
        loadAllMessages(); // Reload messages
    } catch (error) {
        console.error('Error deleting message:', error);
        alert('Error deleting message: ' + error.message);
    }
}

// Ban user function
async function banUserFromRoom(userId, roomId) {
    try {
        const roomRef = db.collection('chatRooms').doc(roomId);
        
        // Add user to banned list
        await roomRef.update({
            bannedUsers: firebase.firestore.FieldValue.arrayUnion(userId)
        });
        
        // Remove user from active users list
        await roomRef.update({
            users: firebase.firestore.FieldValue.arrayRemove(userId)
        });
        
        alert('User banned from room successfully');
        loadAllMessages(); // Reload messages
    } catch (error) {
        console.error('Error banning user:', error);
        alert('Error banning user: ' + error.message);
    }
}

// Load banned users
async function loadBannedUsers() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-banned-users');
    const noBannedUsers = document.getElementById('no-banned-users');
    const bannedUsersList = document.getElementById('banned-users-list');
    
    loading.classList.remove('d-none');
    noBannedUsers.classList.add('d-none');
    bannedUsersList.innerHTML = '';
    
    try {
        const roomsSnapshot = await db.collection('chatRooms').get();
        let allBannedUsers = [];
        
        for (const roomDoc of roomsSnapshot.docs) {
            const room = roomDoc.data();
            if (room.bannedUsers && room.bannedUsers.length > 0) {
                for (const userId of room.bannedUsers) {
                    // Get user info (you might need to implement user lookup)
                    allBannedUsers.push({
                        userId: userId,
                        roomId: roomDoc.id,
                        roomName: room.name,
                        bannedAt: new Date().toLocaleString() // You can store actual ban date
                    });
                }
            }
        }
        
        if (allBannedUsers.length === 0) {
            noBannedUsers.classList.remove('d-none');
        } else {
            allBannedUsers.forEach(bannedUser => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>
                        <code>${bannedUser.userId}</code>
                    </td>
                    <td>
                        <span class="badge bg-warning">${bannedUser.roomName}</span>
                    </td>
                    <td>
                        ${bannedUser.bannedAt}
                    </td>
                    <td>
                        <button class="btn btn-success btn-sm unban-user" 
                                data-user-id="${bannedUser.userId}" 
                                data-room-id="${bannedUser.roomId}">
                            <i class="bi bi-person-check"></i> Unban
                        </button>
                    </td>
                `;
                bannedUsersList.appendChild(row);
            });
            
            // Add unban listeners
            document.querySelectorAll('.unban-user').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const btn = event.target.closest('button');
                    const userId = btn.getAttribute('data-user-id');
                    const roomId = btn.getAttribute('data-room-id');
                    
                    try {
                        await db.collection('chatRooms').doc(roomId).update({
                            bannedUsers: firebase.firestore.FieldValue.arrayRemove(userId)
                        });
                        
                        alert('User unbanned successfully');
                        loadBannedUsers();
                    } catch (error) {
                        console.error('Error unbanning user:', error);
                        alert('Error unbanning user: ' + error.message);
                    }
                });
            });
        }
    } catch (error) {
        console.error('Error loading banned users:', error);
        alert('Error loading banned users: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}

// Modal instances (add these to your existing modal declarations)
const deleteMessageModal = new bootstrap.Modal(document.getElementById('deleteMessageModal'));
const banUserModal = new bootstrap.Modal(document.getElementById('banUserModal'));

// Event listeners for new modals
document.getElementById('confirm-delete-message').addEventListener('click', async () => {
    const btn = document.getElementById('confirm-delete-message');
    const roomId = btn.getAttribute('data-room-id');
    const messageId = btn.getAttribute('data-message-id');
    
    if (roomId && messageId) {
        await deleteMessage(roomId, messageId);
        deleteMessageModal.hide();
    }
});

document.getElementById('confirm-ban-user').addEventListener('click', async () => {
    const btn = document.getElementById('confirm-ban-user');
    const userId = btn.getAttribute('data-user-id');
    const roomId = btn.getAttribute('data-room-id');
    
    if (userId && roomId) {
        await banUserFromRoom(userId, roomId);
        banUserModal.hide();
    }
});

// Auto-refresh messages every 30 seconds
setInterval(() => {
    if (auth.currentUser && document.getElementById('messages-section').classList.contains('d-none') === false) {
        loadAllMessages();
    }
}, 30000);

// Add CSS for message management (add to your existing styles)
const messageManagementStyles = `
    .user-info {
        display: flex;
        align-items: center;
        gap: 10px;
    }
    
    .user-avatar {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        object-fit: cover;
    }
    
    .user-avatar-placeholder {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: linear-gradient(135deg, var(--secondary-color), var(--primary-color));
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: bold;
        font-size: 16px;
    }
    
    .message-content {
        max-width: 200px;
        word-wrap: break-word;
    }
    
    .message-details {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    
    .filters-section {
        background: rgba(255,255,255,0.05);
        padding: 20px;
        border-radius: 10px;
        margin-bottom: 20px;
    }
`;

// Inject the styles
const styleSheet = document.createElement('style');
styleSheet.textContent = messageManagementStyles;
document.head.appendChild(styleSheet);


async function loadReportedMessages() {
    if (!auth.currentUser) return;

    const loading = document.getElementById('loading-reported-messages');
    const noData = document.getElementById('no-reported-messages');
    const list = document.getElementById('reported-messages-list');

    loading.classList.remove('d-none');
    noData.classList.add('d-none');
    list.innerHTML = '';

    try {
        const snapshot = await db.collection('reportedMessages')
            .orderBy('timestamp', 'desc')
            .get();

        if (snapshot.empty) {
            noData.classList.remove('d-none');
            return;
        }

        snapshot.forEach(doc => {
            const data = doc.data();
            const date = data.timestamp?.toDate().toLocaleString() || '-';
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>
                    <input type="checkbox" class="form-check-input report-checkbox" 
                           data-report-id="${doc.id}" 
                           onchange="updateBulkActionButtons()">
                </td>
                <td>
                    <div>
                        <strong>${data.reportedByName}</strong><br>
                        <small class="text-muted">${data.reportedBy}</small>
                    </div>
                </td>
                <td>
                    <span class="badge bg-info">${data.roomId}</span>
                </td>
                <td>
                    <div>
                        <div class="message-content" style="max-width: 200px; word-wrap: break-word;">
                            ${data.messageContent.length > 50 ? 
                                data.messageContent.substring(0, 50) + '...' : 
                                data.messageContent}
                        </div>
                        <small class="text-warning">
                            <i class="bi bi-person"></i> 
                            User: <strong>${data.messageUserName}</strong>
                        </small><br>
                        <small class="text-muted">
                            <i class="bi bi-hash"></i> 
                            ID: <code>${data.messageUserId}</code>
                        </small>
                    </div>
                </td>
                <td>
                    <span class="badge bg-warning">${data.reason || '-'}</span>
                </td>
                <td>
                    <small>${date}</small>
                </td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-danger" onclick="deleteMessage('${data.roomId}','${data.messageId}')" title="Delete Message">
                            <i class="bi bi-trash"></i>
                        </button>
                        <button class="btn btn-warning ban-user" 
                                data-user-id="${data.messageUserId}" 
                                data-room-id="${data.roomId}"
                                data-username="${data.messageUserName}"
                                title="Ban User">
                            <i class="bi bi-person-x"></i>
                        </button>
                        <button class="btn btn-info view-full-message" 
                                data-content="${data.messageContent.replace(/"/g, '&quot;')}"
                                data-username="${data.messageUserName}"
                                data-userid="${data.messageUserId}"
                                data-reason="${data.reason || ''}"
                                data-date="${date}"
                                title="View Full Message">
                            <i class="bi bi-eye"></i>
                        </button>
                        <button class="btn btn-secondary delete-report" 
                                data-report-id="${doc.id}"
                                title="Remove Report">
                            <i class="bi bi-x-circle"></i>
                        </button>
                    </div>
                </td>
            `;
            list.appendChild(row);
        });

        // Ban user butonları için event listener ekle
        document.querySelectorAll('.ban-user').forEach(button => {
            button.addEventListener('click', (event) => {
                const btn = event.target.closest('button');
                const userId = btn.getAttribute('data-user-id');
                const roomId = btn.getAttribute('data-room-id');
                const username = btn.getAttribute('data-username');
                
                if (confirm(`Are you sure you want to ban user "${username}" from this room?`)) {
                    banUserFromRoom(userId, roomId).then(() => {
                        alert('User banned successfully');
                        loadReportedMessages(); // Refresh the list
                    }).catch(error => {
                        console.error('Error banning user:', error);
                        alert('Error banning user: ' + error.message);
                    });
                }
            });
        });

        // View full message butonları için event listener ekle
        document.querySelectorAll('.view-full-message').forEach(button => {
            button.addEventListener('click', (event) => {
                const btn = event.target.closest('button');
                const content = btn.getAttribute('data-content');
                const username = btn.getAttribute('data-username');
                const userid = btn.getAttribute('data-userid');
                const reason = btn.getAttribute('data-reason');
                const date = btn.getAttribute('data-date');
                
                showReportedMessageModal(content, username, userid, reason, date);
            });
        });

        // Delete report butonları için event listener ekle
        document.querySelectorAll('.delete-report').forEach(button => {
            button.addEventListener('click', (event) => {
                const btn = event.target.closest('button');
                const reportId = btn.getAttribute('data-report-id');
                
                if (confirm('Are you sure you want to remove this report?')) {
                    deleteReportedMessage(reportId);
                }
            });
        });

    } catch (error) {
        console.error('Error loading reported messages:', error);
        alert('Error loading reported messages: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}

// Tek bir raporu silme fonksiyonu
async function deleteReportedMessage(reportId) {
    try {
        await db.collection('reportedMessages').doc(reportId).delete();
        showSuccess('Report removed successfully');
        loadReportedMessages(); // Listeyi yenile
    } catch (error) {
        console.error('Error deleting report:', error);
        showError('Error removing report: ' + error.message);
    }
}

// Tüm raporları temizleme fonksiyonu
async function clearAllReports() {
    if (!confirm('Are you sure you want to clear ALL reported messages? This action cannot be undone.')) {
        return;
    }
    
    try {
        const snapshot = await db.collection('reportedMessages').get();
        
        if (snapshot.empty) {
            alert('No reports to clear');
            return;
        }
        
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        showSuccess(`${snapshot.size} reports cleared successfully`);
        loadReportedMessages();
    } catch (error) {
        console.error('Error clearing all reports:', error);
        showError('Error clearing reports: ' + error.message);
    }
}

// Eski raporları temizleme fonksiyonu (30 gün öncesini sil)
async function clearOldReports(days) {
    if (!confirm(`Are you sure you want to clear all reports older than ${days} days?`)) {
        return;
    }
    
    try {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - days);
        
        const snapshot = await db.collection('reportedMessages')
            .where('timestamp', '<', firebase.firestore.Timestamp.fromDate(cutoffDate))
            .get();
        
        if (snapshot.empty) {
            alert(`No reports older than ${days} days found`);
            return;
        }
        
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        showSuccess(`${snapshot.size} old reports cleared successfully`);
        loadReportedMessages();
    } catch (error) {
        console.error('Error clearing old reports:', error);
        showError('Error clearing old reports: ' + error.message);
    }
}

// Seçili raporları silme fonksiyonu
function deleteSelectedReports() {
    const checkedBoxes = document.querySelectorAll('.report-checkbox:checked');
    
    if (checkedBoxes.length === 0) {
        alert('Please select at least one report to delete');
        return;
    }
    
    if (!confirm(`Are you sure you want to delete ${checkedBoxes.length} selected reports?`)) {
        return;
    }
    
    const batch = db.batch();
    const reportIds = [];
    
    checkedBoxes.forEach(checkbox => {
        const reportId = checkbox.getAttribute('data-report-id');
        reportIds.push(reportId);
        batch.delete(db.collection('reportedMessages').doc(reportId));
    });
    
    batch.commit()
        .then(() => {
            showSuccess(`${reportIds.length} reports deleted successfully`);
            loadReportedMessages();
        })
        .catch(error => {
            console.error('Error deleting selected reports:', error);
            showError('Error deleting selected reports: ' + error.message);
        });
}

// Tümünü seç/seçme fonksiyonu
function toggleAllReports(selectAll) {
    const checkboxes = document.querySelectorAll('.report-checkbox');
    checkboxes.forEach(checkbox => {
        checkbox.checked = selectAll;
    });
    
    updateBulkActionButtons();
}

// Toplu işlem butonlarını güncelle
function updateBulkActionButtons() {
    const checkedCount = document.querySelectorAll('.report-checkbox:checked').length;
    const bulkActions = document.getElementById('bulk-actions');
    
    if (checkedCount > 0) {
        bulkActions.classList.remove('d-none');
        document.getElementById('selected-count').textContent = checkedCount;
    } else {
        bulkActions.classList.add('d-none');
    }
}

// Global olarak erişilebilir fonksiyonları tanımla
window.deleteReportedMessage = deleteReportedMessage;
window.clearAllReports = clearAllReports;
window.clearOldReports = clearOldReports;
window.deleteSelectedReports = deleteSelectedReports;
window.toggleAllReports = toggleAllReports;

// Ban user function for reported messages
async function banUserFromRoom(userId, roomId) {
    try {
        const roomRef = db.collection('chatRooms').doc(roomId);
        
        // Add user to banned list
        await roomRef.update({
            bannedUsers: firebase.firestore.FieldValue.arrayUnion(userId)
        });
        
        // Remove user from active users list
        await roomRef.update({
            users: firebase.firestore.FieldValue.arrayRemove(userId)
        });
        
        return true;
    } catch (error) {
        throw error;
    }
}

// Show reported message modal
function showReportedMessageModal(content, username, userid, reason, date) {
    const modal = document.getElementById('reportedMessageModal') || createReportedMessageModal();
    const modalTitle = modal.querySelector('.modal-title');
    const modalBody = modal.querySelector('.modal-body');
    
    modalTitle.innerHTML = `<i class="bi bi-flag"></i> Reported Message Details`;
    
    modalBody.innerHTML = `
        <div class="reported-message-details">
            <div class="row mb-3">
                <div class="col-md-6">
                    <strong>Reported User:</strong> ${username}
                </div>
                <div class="col-md-6">
                    <strong>Report Date:</strong> ${date}
                </div>
            </div>
            <div class="row mb-3">
                <div class="col-md-12">
                    <strong>User ID:</strong>
                    <code>${userid}</code>
                </div>
            </div>
            <div class="mb-3">
                <strong>Report Reason:</strong>
                <span class="badge bg-warning">${reason || 'No reason provided'}</span>
            </div>
            <div class="mb-3">
                <strong>Message Content:</strong>
                <div class="message-content-full p-3 mt-2" style="background: rgba(255,255,255,0.1); border-radius: 8px; white-space: pre-wrap; max-height: 300px; overflow-y: auto;">
                    ${content}
                </div>
            </div>
        </div>
    `;
    
    new bootstrap.Modal(modal).show();
}

// Create reported message modal if it doesn't exist
function createReportedMessageModal() {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.id = 'reportedMessageModal';
    modal.tabIndex = -1;
    modal.innerHTML = `
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body"></div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
    return modal;
}

// Load polls
async function loadPolls() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-polls');
    const noPolls = document.getElementById('no-polls');
    const pollsList = document.getElementById('polls-list');
    
    loading.classList.remove('d-none');
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
                    <td><strong>${poll.question}</strong></td>
                    <td>
                        <ul class="mb-0">
                            ${poll.options.map(opt => `
                                <li>${opt.text} (${opt.votes} votes)</li>
                            `).join('')}
                        </ul>
                    </td>
                    <td>
                        <span class="badge ${poll.isActive ? 'bg-success' : 'bg-danger'}">
                            ${poll.isActive ? 'Active' : 'Inactive'}
                        </span>
                    </td>
                    <td>
                        <div class="btn-group btn-group-sm">
                            <button class="btn ${poll.isActive ? 'btn-warning' : 'btn-success'} toggle-poll-status" 
                                    data-id="${poll.id}" data-status="${poll.isActive}">
                                ${poll.isActive ? 'Deactivate' : 'Activate'}
                            </button>
                            <button class="btn btn-danger delete-poll" data-id="${poll.id}">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </td>
                `;
                
                pollsList.appendChild(row);
            });
            
            // Add event listeners
            document.querySelectorAll('.delete-poll').forEach(button => {
                button.addEventListener('click', event => {
                    const pollId = event.target.closest('button').getAttribute('data-id');
                    document.getElementById('confirm-delete-poll').setAttribute('data-id', pollId);
                    deletePollModal.show();
                });
            });
            
            document.querySelectorAll('.toggle-poll-status').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const pollId = event.target.getAttribute('data-id');
                    const currentStatus = event.target.getAttribute('data-status') === 'true';
                    
                    try {
                        await db.collection('polls').doc(pollId).update({
                            isActive: !currentStatus
                        });
                        
                        alert(`Poll status updated to ${!currentStatus ? 'active' : 'inactive'}`);
                        loadPolls();
                    } catch (error) {
                        console.error('Error updating poll status:', error);
                        alert('Error updating poll status: ' + error.message);
                    }
                });
            });
        }
    } catch (error) {
        console.error('Error loading polls:', error);
        alert('Error loading polls: ' + error.message);
    } finally {
        loading.classList.add('d-none');
    }
}

// Load announcements
async function loadAnnouncements() {
    if (!auth.currentUser) return;
    
    const loading = document.getElementById('loading-announcements');
    const noAnnouncements = document.getElementById('no-announcements');
    const announcementsList = document.getElementById('announcements-list');
    
    loading.classList.remove('d-none');
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
                    : 'No date';
                
                const statusClass = announcement.isActive ? 'bg-success' : 'bg-danger';
                const statusText = announcement.isActive ? 'Active' : 'Inactive';
                const toggleBtnText = announcement.isActive ? 'Deactivate' : 'Activate';
                const toggleBtnClass = announcement.isActive ? 'btn-warning' : 'btn-success';
                
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td><strong>${announcement.title}</strong></td>
                    <td>${announcement.content.substring(0, 50)}${announcement.content.length > 50 ? '...' : ''}</td>
                    <td>${formattedDate}</td>
                    <td><span class="badge ${statusClass}">${statusText}</span></td>
                    <td>
                        <div class="btn-group btn-group-sm">
                            <button class="btn ${toggleBtnClass} toggle-announcement-status" 
                                    data-id="${announcement.id}" data-status="${announcement.isActive}">
                                ${toggleBtnText}
                            </button>
                            <button class="btn btn-danger delete-announcement" data-id="${announcement.id}">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </td>
                `;
                
                announcementsList.appendChild(row);
            });
            
            // Add event listeners
            document.querySelectorAll('.delete-announcement').forEach(button => {
                button.addEventListener('click', event => {
                    const announcementId = event.target.closest('button').getAttribute('data-id');
                    document.getElementById('confirm-delete-announcement').setAttribute('data-id', announcementId);
                    deleteAnnouncementModal.show();
                });
            });
            
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
        loading.classList.add('d-none');
    }
}

// Form submissions
document.getElementById('chat-room-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Please login to add chat rooms');
        return;
    }
    
    const name = document.getElementById('room-name').value.trim();
    const description = document.getElementById('room-description').value.trim();
    
    if (!name || !description) {
        alert('Please fill all fields');
        return;
    }
    
    try {
        const addButton = document.getElementById('add-room-button');
        addButton.disabled = true;
        
        // Check for duplicate room names
        const roomSnapshot = await db.collection('chatRooms')
            .where('name', '==', name)
            .get();
        
        if (!roomSnapshot.empty) {
            alert('A chat room with this name already exists');
            addButton.disabled = false;
            return;
        }
        
        await db.collection('chatRooms').add({
            name,
            description,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            createdBy: auth.currentUser.uid,
            createdByEmail: auth.currentUser.email,
            isActive: true
        });
        
        alert('Chat room added successfully!');
        document.getElementById('chat-room-form').reset();
        loadChatRooms();
        loadDashboardStats();
    } catch (error) {
        console.error('Error adding chat room:', error);
        alert('Error adding chat room: ' + error.message);
    } finally {
        document.getElementById('add-room-button').disabled = false;
    }
});

document.getElementById('poll-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Please login to create polls');
        return;
    }
    
    const question = document.getElementById('poll-question').value.trim();
    const options = Array.from(document.querySelectorAll('.poll-option'))
        .map(input => ({
            text: input.value.trim(),
            votes: 0
        }));
    
    if (!question || options.some(opt => !opt.text)) {
        alert('Please fill all fields');
        return;
    }
    
    if (options.length < 2) {
        alert('Please add at least 2 options');
        return;
    }
    
    try {
        const addButton = document.getElementById('add-poll-button');
        addButton.disabled = true;
        
        await db.collection('polls').add({
            question,
            options,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            isActive: true,
            createdBy: auth.currentUser.uid,
            votedUserIds: []
        });
        
        alert('Poll created successfully!');
        document.getElementById('poll-form').reset();
        
        // Reset options to default
        document.getElementById('poll-options-container').innerHTML = `
            <div class="input-group mb-2">
                <input type="text" class="form-control poll-option" placeholder="Option 1" required>
                <button type="button" class="btn btn-danger remove-option">×</button>
            </div>
            <div class="input-group mb-2">
                <input type="text" class="form-control poll-option" placeholder="Option 2" required>
                <button type="button" class="btn btn-danger remove-option">×</button>
            </div>
        `;
        
        loadPolls();
        loadDashboardStats();
    } catch (error) {
        console.error('Error creating poll:', error);
        alert('Error creating poll: ' + error.message);
    } finally {
        document.getElementById('add-poll-button').disabled = false;
    }
});

document.getElementById('announcement-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!auth.currentUser) {
        alert('Please login to create announcements');
        return;
    }
    
    const title = document.getElementById('announcement-title').value.trim();
    const content = document.getElementById('announcement-content').value.trim();
    const imageFile = document.getElementById('announcement-image').files[0];
    
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
        document.getElementById('announcement-form').reset();
        document.getElementById('announcement-preview').classList.add('d-none');
        loadAnnouncements();
    } catch (error) {
        console.error('Error creating announcement:', error);
        alert('Error creating announcement: ' + error.message);
    }
});

// Poll option management
document.getElementById('add-option').addEventListener('click', () => {
    const container = document.getElementById('poll-options-container');
    const optionCount = container.querySelectorAll('.poll-option').length + 1;
    const optionDiv = document.createElement('div');
    optionDiv.className = 'input-group mb-2';
    optionDiv.innerHTML = `
        <input type="text" class="form-control poll-option" placeholder="Option ${optionCount}" required>
        <button type="button" class="btn btn-danger remove-option">×</button>
    `;
    container.appendChild(optionDiv);
});

document.getElementById('poll-options-container').addEventListener('click', (e) => {
    if (e.target.classList.contains('remove-option')) {
        const container = document.getElementById('poll-options-container');
        if (container.querySelectorAll('.poll-option').length > 2) {
            e.target.closest('.input-group').remove();
        } else {
            alert('At least 2 options are required');
        }
    }
});

// Delete confirmations
document.getElementById('confirm-delete').addEventListener('click', async () => {
    const newsId = document.getElementById('confirm-delete').getAttribute('data-id');
    
    if (!newsId) {
        deleteModal.hide();
        return;
    }
    
    try {
        await db.collection('news').doc(newsId).delete();
        alert('News article deleted successfully');
        loadNews();
        loadDashboardStats();
    } catch (error) {
        console.error('Error deleting news:', error);
        alert('Error deleting news: ' + error.message);
    } finally {
        deleteModal.hide();
    }
});

document.getElementById('confirm-delete-video').addEventListener('click', async () => {
    const videoId = document.getElementById('confirm-delete-video').getAttribute('data-id');
    
    if (!videoId) {
        deleteVideoModal.hide();
        return;
    }
    
    try {
        await db.collection('videos').doc(videoId).delete();
        alert('Video deleted successfully');
        loadVideos();
        loadDashboardStats();
    } catch (error) {
        console.error('Error deleting video:', error);
        alert('Error deleting video: ' + error.message);
    } finally {
        deleteVideoModal.hide();
    }
});

document.getElementById('confirm-delete-room').addEventListener('click', async () => {
    const roomId = document.getElementById('confirm-delete-room').getAttribute('data-id');
    
    if (!roomId) {
        deleteRoomModal.hide();
        return;
    }
    
    try {
        // Delete all messages first
        const messagesSnapshot = await db.collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .get();
        
        const batch = db.batch();
        messagesSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        
        // Then delete the room
        await db.collection('chatRooms').doc(roomId).delete();
        
        alert('Chat room deleted successfully');
        loadChatRooms();
        loadDashboardStats();
    } catch (error) {
        console.error('Error deleting chat room:', error);
        alert('Error deleting chat room: ' + error.message);
    } finally {
        deleteRoomModal.hide();
    }
});

document.getElementById('confirm-delete-poll').addEventListener('click', async () => {
    const pollId = document.getElementById('confirm-delete-poll').getAttribute('data-id');
    
    if (!pollId) {
        deletePollModal.hide();
        return;
    }
    
    try {
        await db.collection('polls').doc(pollId).delete();
        alert('Poll deleted successfully');
        loadPolls();
        loadDashboardStats();
    } catch (error) {
        console.error('Error deleting poll:', error);
        alert('Error deleting poll: ' + error.message);
    } finally {
        deletePollModal.hide();
    }
});

document.getElementById('confirm-delete-announcement').addEventListener('click', async () => {
    const announcementId = document.getElementById('confirm-delete-announcement').getAttribute('data-id');
    
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

document.getElementById('confirm-clear-messages').addEventListener('click', async () => {
    const roomId = document.getElementById('confirm-clear-messages').getAttribute('data-id');
    
    if (!roomId) {
        clearMessagesModal.hide();
        return;
    }
    
    try {
        const messagesSnapshot = await db.collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .get();
        
        if (messagesSnapshot.empty) {
            alert('No messages to clear');
            clearMessagesModal.hide();
            return;
        }
        
        const batch = db.batch();
        messagesSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        
        alert('All messages cleared successfully');
        loadChatRooms();
    } catch (error) {
        console.error('Error clearing messages:', error);
        alert('Error clearing messages: ' + error.message);
    } finally {
        clearMessagesModal.hide();
    }
});

// Refresh buttons
document.getElementById('refresh-button').addEventListener('click', loadNews);
document.getElementById('refresh-videos').addEventListener('click', loadVideos);
document.getElementById('refresh-announcements').addEventListener('click', loadAnnouncements);

// Additional utility functions
function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}

function showSuccess(message) {
    // Create a simple toast notification
    const toast = document.createElement('div');
    toast.className = 'position-fixed top-0 end-0 p-3';
    toast.style.zIndex = '9999';
    toast.innerHTML = `
        <div class="toast show" role="alert">
            <div class="toast-header bg-success text-white">
                <i class="bi bi-check-circle me-2"></i>
                <strong class="me-auto">Success</strong>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast"></button>
            </div>
            <div class="toast-body">
                ${message}
            </div>
        </div>
    `;
    document.body.appendChild(toast);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        toast.remove();
    }, 3000);
}

function showError(message) {
    // Create a simple error toast notification
    const toast = document.createElement('div');
    toast.className = 'position-fixed top-0 end-0 p-3';
    toast.style.zIndex = '9999';
    toast.innerHTML = `
        <div class="toast show" role="alert">
            <div class="toast-header bg-danger text-white">
                <i class="bi bi-exclamation-triangle me-2"></i>
                <strong class="me-auto">Error</strong>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast"></button>
            </div>
            <div class="toast-body">
                ${message}
            </div>
        </div>
    `;
    document.body.appendChild(toast);
    
    // Auto remove after 5 seconds for errors
    setTimeout(() => {
        toast.remove();
    }, 5000);
}

// Initialize app on DOM load
document.addEventListener('DOMContentLoaded', () => {
    console.log('BullBearNews Admin Panel Loaded');
    
    // Add any initialization code here
    if (window.innerWidth <= 768) {
        document.getElementById('sidebar').classList.add('collapsed');
    }
});

// Handle window resize
window.addEventListener('resize', () => {
    if (window.innerWidth > 768) {
        document.getElementById('sidebar').classList.remove('show');
    }
});

// Export functions for global access
window.showSection = showSection;
window.toggleSidebar = toggleSidebar;
window.tagManagers = tagManagers;