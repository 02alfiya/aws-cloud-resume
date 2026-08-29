const api_url = "https://opgpp9eqqh.execute-api.us-east-2.amazonaws.com/count";

async function getVisitorCount() {
    try {
        const response = await fetch(api_url);
        const data = await response.json();
        watchAndAnimate(data.visitor_count);
        console.log("Visitor count updated successfully");
    }
    catch (error) {
        console.error("Error fetching visitor count:", error);
    }
}

// Waits until the counter actually scrolls into view before animating.
// Without this, the animation finishes before anyone sees it happen.
function watchAndAnimate(finalCount) {
    const numberEl = document.getElementById("visitor-count");
    const barEl = document.getElementById("stat-bar-fill");

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCount(numberEl, finalCount);
                barEl.style.width = "100%"; // triggers the CSS transition on the color bar
                observer.unobserve(entry.target); // only animate once, not every scroll
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
        const eased = 1 - Math.pow(1 - progress, 3); // ease-out cubic
        const currentValue = Math.floor(eased * finalCount);
        element.innerText = currentValue;

        if (progress < 1) {
            requestAnimationFrame(update);
        } else {
            element.innerText = finalCount; // lands exactly on the real number
        }
    }

    requestAnimationFrame(update);
}

getVisitorCount();