// ====== CONFIG: fill these with YOUR values ======
const CONFIG = {
  API_URL: "https://5qah32e448.execute-api.us-east-1.amazonaws.com",
  USER_POOL_ID: "us-east-1_rgRaeJLmH",
  CLIENT_ID: "5vih0mcobule1mftgflbmf6i3r",
};
// =================================================

const pool = new AmazonCognitoIdentity.CognitoUserPool({
  UserPoolId: CONFIG.USER_POOL_ID,
  ClientId: CONFIG.CLIENT_ID,
});

let idToken = null;
let pendingUser = null;          // user waiting for email confirmation
let quiz = { questions: [], index: 0, score: 0, category: "" };

const $ = (id) => document.getElementById(id);
const show = (id) => $(id).classList.remove("hidden");
const hide = (id) => $(id).classList.add("hidden");
const msg = (t) => ($("auth-msg").textContent = t);

// ---------- API helper ----------
async function api(path, options = {}) {
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };
  if (idToken) headers["Authorization"] = idToken;   // ID token: its "aud" matches the JWT authorizer
  const res = await fetch(CONFIG.API_URL + path, { ...options, headers });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json();
}

// ---------- Auth ----------
function signUp() {
  const name = $("su-name").value.trim();
  const email = $("su-email").value.trim();
  const pass = $("su-pass").value;
  const attrs = [
    new AmazonCognitoIdentity.CognitoUserAttribute({ Name: "name", Value: name }),
    new AmazonCognitoIdentity.CognitoUserAttribute({ Name: "email", Value: email }),
  ];
  pool.signUp(email, pass, attrs, null, (err, result) => {
    if (err) return msg("⚠️ " + err.message);
    pendingUser = result.user;
    hide("form-signup"); show("form-confirm");
    msg("Account created. Enter the code from your email.");
  });
}

function confirmCode() {
  if (!pendingUser) return msg("Sign up first.");
  pendingUser.confirmRegistration($("conf-code").value.trim(), true, (err) => {
    if (err) return msg("⚠️ " + err.message);
    hide("form-confirm"); show("form-login");
    msg("✅ Confirmed! You can log in now (welcome email on its way).");
  });
}

function signIn() {
  const email = $("login-email").value.trim();
  const details = new AmazonCognitoIdentity.AuthenticationDetails({
    Username: email,
    Password: $("login-pass").value,
  });
  const user = new AmazonCognitoIdentity.CognitoUser({ Username: email, Pool: pool });
  user.authenticateUser(details, {
    onSuccess: (session) => onLogin(session),
    onFailure: (err) => msg("⚠️ " + err.message),
  });
}

function onLogin(session) {
  idToken = session.getIdToken().getJwtToken();
  const payload = session.getIdToken().decodePayload();
  $("user-name").textContent = "👤 " + (payload.name || payload.email);
  hide("view-auth"); show("view-game"); show("user-box");
  // QOTD banner only after login, and only if there is a question to show.
  loadQotd();
}

function signOut() {
  const u = pool.getCurrentUser();
  if (u) u.signOut();
  idToken = null;
  location.reload();
}

function restoreSession() {
  const u = pool.getCurrentUser();
  if (!u) return;
  u.getSession((err, session) => {
    if (!err && session.isValid()) onLogin(session);
  });
}

// ---------- QOTD (public) ----------
async function loadQotd() {
  try {
    const res = await api("/qotd");
    // The lambda returns the payload inside "body" as a JSON string — parse it.
    const data = typeof res.body === "string" ? JSON.parse(res.body) : res;
    if (data && data.question) {
      $("qotd-text").textContent = data.question;
      show("qotd-banner");   // only reveal the banner when there is a real question
    }
  } catch (_) { /* qotd is optional — silently skip */ }
}

// ---------- Quiz ----------
async function startQuiz(category) {
  const data = await api(`/questions?category=${category}`);
  const shuffled = data.questions.sort(() => Math.random() - 0.5);
  quiz = { questions: shuffled.slice(0, 5), index: 0, score: 0, category };
  hide("category-select"); hide("result-area"); show("quiz-area");
  renderQuestion();
}

function renderQuestion() {
  const q = quiz.questions[quiz.index];
  $("quiz-progress").textContent =
    `Question ${quiz.index + 1}/${quiz.questions.length} · ${quiz.category.toUpperCase()} · Score ${quiz.score}`;
  $("quiz-question").textContent = q.question;
  const box = $("quiz-options");
  box.innerHTML = "";
  q.options.forEach((opt, i) => {
    const b = document.createElement("button");
    b.textContent = opt;
    b.onclick = () => answer(i, b);
    box.appendChild(b);
  });
}

function answer(i, btn) {
  const q = quiz.questions[quiz.index];
  [...$("quiz-options").children].forEach((b) => (b.disabled = true));
  if (i === q.answer_index) {
    btn.classList.add("correct");
    quiz.score++;
  } else {
    btn.classList.add("wrong");
    $("quiz-options").children[q.answer_index].classList.add("correct");
  }
  setTimeout(() => {
    quiz.index++;
    quiz.index < quiz.questions.length ? renderQuestion() : finishQuiz();
  }, 900);
}

async function finishQuiz() {
  hide("quiz-area"); show("result-area");
  $("result-text").textContent = `You scored ${quiz.score}/${quiz.questions.length} 🎯`;
  $("result-status").textContent = "Submitting score…";
  try {
    await api("/scores", {
      method: "POST",
      body: JSON.stringify({
        score: quiz.score,
        total: quiz.questions.length,
        category: quiz.category,
      }),
    });
    $("result-status").textContent = "✅ Score queued (async pipeline at work)";
  } catch (e) {
    $("result-status").textContent = "⚠️ Could not submit: " + e.message;
  }
}

// ---------- Leaderboard (public) ----------
async function loadBoard() {
  const data = await api("/leaderboard");
  const list = $("board-list");
  list.innerHTML = "";
  (data.top || []).forEach((e) => {
    const li = document.createElement("li");
    li.innerHTML = `<b>${e.username}</b> — ${e.score} pts · ${e.category} · ${e.date}`;
    list.appendChild(li);
  });
  hide("view-game"); show("view-board");
}

// ---------- Wiring ----------
document.querySelectorAll(".tab").forEach((t) =>
  t.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach((x) => x.classList.remove("active"));
    t.classList.add("active");
    msg("");
    if (t.dataset.tab === "login") { show("form-login"); hide("form-signup"); hide("form-confirm"); }
    else { hide("form-login"); show("form-signup"); hide("form-confirm"); }
  })
);
document.querySelectorAll(".cat").forEach((b) =>
  b.addEventListener("click", () => startQuiz(b.dataset.cat))
);
$("btn-login").onclick = signIn;
$("btn-signup").onclick = signUp;
$("btn-confirm").onclick = confirmCode;
$("btn-logout").onclick = signOut;
$("btn-again").onclick = () => { hide("result-area"); show("category-select"); };
$("btn-show-board").onclick = loadBoard;
$("btn-board2").onclick = loadBoard;
$("btn-back").onclick = () => { hide("view-board"); show("view-game"); show("category-select"); };

// On page load: only restore an existing session. QOTD is loaded inside onLogin,
// so the banner never shows on the login screen.
restoreSession();