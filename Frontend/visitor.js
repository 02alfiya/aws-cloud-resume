const api_url = "https://opgpp9eqqh.execute-api.us-east-2.amazonaws.com/count";


const MILESTONE_STEP = 100; // keep in sync with Terraform's milestone_step

async function getVisitorCount() {
    try {
        const response = await fetch(api_url);
        const data = await response.json();
        watchAndAnimate(data.visitor_count);

        if (data.visitor_count % MILESTONE_STEP === 0) {
            showMilestoneToast(data.visitor_count);
        }

        console.log("Visitor count updated successfully");
    }
    catch (error) {
        console.error("Error fetching visitor count:", error);
    }
}

function showMilestoneToast(count) {
    const toast = document.createElement("div");
    toast.className = "toast";
    toast.setAttribute("role", "status");
    toast.textContent = `🎉 Milestone — you are visitor #${count.toLocaleString()}!`;
    document.body.appendChild(toast);

    requestAnimationFrame(() => toast.classList.add("show"));
    setTimeout(() => {
        toast.classList.remove("show");
        setTimeout(() => toast.remove(), 400);
    }, 6000);
}

function watchAndAnimate(finalCount) {
    const numberEl = document.getElementById("visitor-count");
    const barEl = document.getElementById("stat-bar-fill");

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCount(numberEl, finalCount);
                barEl.style.width = "100%";
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    observer.observe(numberEl);
}

function animateCount(element, finalCount, duration = 1500) {
    const startTime = performance.now();

    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        const currentValue = Math.floor(eased * finalCount);
        element.innerText = currentValue;

        if (progress < 1) {
            requestAnimationFrame(update);
        } else {
            element.innerText = finalCount;
        }
    }

    requestAnimationFrame(update);
}

getVisitorCount();