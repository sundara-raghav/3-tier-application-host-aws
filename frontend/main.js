let apiBase = localStorage.getItem('API_BASE') || 'http://13.202.91.241:5000';
let currentTopic = '';
let quizData = null;
let timerInterval = null;
let timeRemaining = 0;

function setApiBase() {
  const input = prompt('Enter API Base URL:', apiBase);
  if (input) {
    apiBase = input;
    localStorage.setItem('API_BASE', apiBase);
    location.reload();
  }
}

function showSetup() {
  document.getElementById('setup').style.display = 'block';
  document.getElementById('quiz-area').style.display = 'none';
  document.getElementById('result').style.display = 'none';
  document.getElementById('scoreboard-panel').style.display = 'none';
  stopTimer();
  fetchTopics();
}

function showQuiz() {
  document.getElementById('setup').style.display = 'none';
  document.getElementById('quiz-area').style.display = 'block';
  document.getElementById('result').style.display = 'none';
  document.getElementById('scoreboard-panel').style.display = 'none';
}

function showResult() {
  document.getElementById('setup').style.display = 'none';
  document.getElementById('quiz-area').style.display = 'none';
  document.getElementById('result').style.display = 'block';
  document.getElementById('scoreboard-panel').style.display = 'none';
  stopTimer();
}

function showScoreboard() {
  document.getElementById('setup').style.display = 'none';
  document.getElementById('quiz-area').style.display = 'none';
  document.getElementById('result').style.display = 'none';
  document.getElementById('scoreboard-panel').style.display = 'block';
  stopTimer();
}

function startTimer(seconds) {
  timeRemaining = seconds;
  updateTimerDisplay();
  
  timerInterval = setInterval(() => {
    timeRemaining--;
    updateTimerDisplay();
    
    if (timeRemaining <= 0) {
      stopTimer();
      alert('Time is up! Submitting quiz...');
      submitQuiz();
    }
  }, 1000);
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

function updateTimerDisplay() {
  const timerEl = document.getElementById('timer');
  const minutes = Math.floor(timeRemaining / 60);
  const seconds = timeRemaining % 60;
  timerEl.textContent = `Time Remaining: ${minutes}:${seconds.toString().padStart(2, '0')}`;
  
  if (timeRemaining <= 60) {
    timerEl.classList.add('warning');
  } else {
    timerEl.classList.remove('warning');
  }
}

async function fetchTopics() {
  try {
    const resp = await fetch(`${apiBase}/scoreboard?format=json`);
    const data = await resp.json();
    
    const select = document.getElementById('topic');
    select.innerHTML = '';
    
    if (data.topics && data.topics.length > 0) {
      data.topics.forEach(t => {
        const option = document.createElement('option');
        option.value = t;
        option.textContent = t.charAt(0).toUpperCase() + t.slice(1);
        select.appendChild(option);
      });
    }
  } catch (error) {
    console.error('Failed to fetch topics:', error);
  }
}

async function startQuiz() {
  const username = document.getElementById('username').value.trim();
  const topic = document.getElementById('topic').value;
  
  if (!username) {
    alert('Please enter your name');
    return;
  }
  
  if (!topic) {
    alert('Please select a topic');
    return;
  }
  
  loadQuiz(topic);
}

async function loadQuiz(topic) {
  try {
    currentTopic = topic;
    const resp = await fetch(`${apiBase}/quiz/${topic}?format=json`);
    const data = await resp.json();
    quizData = data;
    
    const container = document.getElementById('questions-container');
    container.innerHTML = '';
    
    data.questions.forEach((q, idx) => {
      const div = document.createElement('div');
      div.className = 'question';
      div.innerHTML = `
        <h3>${idx+1}. ${q.question}</h3>
        ${q.options.map(opt => `
          <label class="option">
            <input type="radio" name="q${idx}" value="${opt}">
            <span>${opt}</span>
          </label>
        `).join('')}
      `;
      container.appendChild(div);
    });
    
    const timeLimit = data.time_limit || 900;
    startTimer(timeLimit);
    showQuiz();
  } catch (error) {
    alert('Failed to load quiz: ' + error.message);
  }
}

async function submitQuiz() {
  stopTimer();
  try {
    const answers = {};
    quizData.questions.forEach((q, idx) => {
      const selected = document.querySelector(`input[name="q${idx}"]:checked`);
      if (selected) answers[q.id] = selected.value;
    });
    
    const payload = {
      topic: currentTopic,
      username: document.getElementById('username').value,
      answers
    };
    
    const resp = await fetch(`${apiBase}/submit?format=json`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(payload)
    });
    
    const result = await resp.json();
    document.getElementById('result-text').innerHTML = `
      <p>Score: ${result.score}/${result.total}</p>
      <p>Percentage: ${result.percentage}%</p>
    `;
    showResult();
  } catch (error) {
    alert('Failed to submit quiz: ' + error.message);
  }
}

async function loadScoreboard(topic = null) {
  try {
    const timestamp = Date.now();
    const url = topic 
      ? `${apiBase}/scoreboard?topic=${topic}&format=json&_t=${timestamp}` 
      : `${apiBase}/scoreboard?format=json&_t=${timestamp}`;
    
    const resp = await fetch(url);
    const data = await resp.json();
    
    const container = document.getElementById('scoreboard-container');
    container.innerHTML = '';
    
    if (data.scores && data.scores.length > 0) {
      // Sort by score (descending), then by timestamp (ascending - earlier is better)
      const sorted = data.scores.sort((a, b) => {
        if (b.score !== a.score) {
          return b.score - a.score;
        }
        return (a.timestamp || 0) - (b.timestamp || 0);
      });
      
      sorted.forEach((s, idx) => {
        const div = document.createElement('div');
        div.className = 'score-row';
        const date = s.timestamp ? new Date(s.timestamp * 1000).toLocaleString() : 'N/A';
        div.innerHTML = `
          <div><strong>#${idx + 1}</strong> ${s.username} - ${s.topic}</div>
          <div><strong>${s.score}/${s.total}</strong> (${s.percentage}%) - ${date}</div>
        `;
        container.appendChild(div);
      });
    } else {
      container.innerHTML = '<p class="muted">No scores yet</p>';
    }
    
    showScoreboard();
  } catch (error) {
    alert('Failed to load scoreboard: ' + error.message);
  }
}

// Initialize
fetchTopics();
