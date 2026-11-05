const courses = {
  basic: { title: "انگلیسی از پایه", lessons: ["معرفی و احوال‌پرسی", "جمله‌های ساده", "ضمیرها و فعل to be", "سؤال ساختن"] },
  talk: { title: "مکالمه روزمره", lessons: ["سلام و آشنایی", "سفارش در کافه", "پرسیدن آدرس", "صحبت درباره علایق"] },
  grammar: { title: "گرامر کاربردی", lessons: ["ساختار جمله", "حال ساده", "حال استمراری", "گذشته ساده"] }
};

const modal = document.getElementById("modal");
const modalTitle = document.getElementById("modalTitle");
const modalBody = document.getElementById("modalBody");

function openModal(title, html) {
  modalTitle.textContent = title;
  modalBody.innerHTML = html;
  modal.classList.add("open");
  modal.setAttribute("aria-hidden", "false");
}
function closeModal() {
  modal.classList.remove("open");
  modal.setAttribute("aria-hidden", "true");
}
document.getElementById("closeBtn")?.addEventListener("click", closeModal);
modal?.addEventListener("click", e => { if (e.target === modal) closeModal(); });

document.querySelectorAll("[data-course]").forEach(button => {
  button.addEventListener("click", () => {
    const course = courses[button.dataset.course];
    const rows = course.lessons.map((lesson, index) => {
      const free = index < 2;
      return '<li class="lesson-row"><span>' + (index + 1) + '. ' + lesson +
        '</span><span class="lesson-state">' + (free ? "رایگان" : "🔒 قفل") + '</span></li>';
    }).join("");
    openModal(course.title, '<p class="muted">دو درس اول رایگان هستند. دسترسی پولی پس از راه‌اندازی حساب کاربری و پرداخت امن فعال می‌شود.</p><ol class="lesson-list">' + rows + '</ol>');
  });
});

document.getElementById("loginBtn")?.addEventListener("click", () => {
  openModal("ورود و ثبت‌نام", '<p class="muted">فرم حساب کاربری در نسخه نمایشی فعال نیست. برای ورود واقعی باید سرویس احراز هویت و پایگاه داده متصل شود.</p><label>ایمیل</label><input type="email" placeholder="name@example.com" disabled><label>رمز عبور</label><input type="password" placeholder="پس از اتصال سامانه فعال می‌شود" disabled>');
});

document.querySelectorAll("[data-open-ai]").forEach(button => {
  button.addEventListener("click", () => openModal("دستیار زبان‌یار", '<p class="muted">اتصال هوش مصنوعی هنوز انجام نشده است. کلید سرویس باید فقط در تنظیمات امن سرور قرار بگیرد، نه داخل کد مرورگر.</p>'));
});