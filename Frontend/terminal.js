/* Animated terminal card — replays a DevOps session on loop.
   Pure JS, no dependencies. Respects prefers-reduced-motion. */

(function () {
    const card = document.getElementById("terminal-card");
    const body = document.getElementById("terminal-body");
    if (!card || !body) return;

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const SESSION = [
        {
            cmd: "whoami",
            out: ["alfiya-javed — devops & cloud engineer"],
        },
        {
            cmd: "terraform apply -auto-approve",
            out: [
                "aws_dynamodb_table.visit_counter: Creating...",
                "aws_cloudfront_distribution.resume_cdn: Creating...",
                "Apply complete! 14 added, 0 changed, 0 destroyed.",
            ],
        },
        {
            cmd: "aws lambda invoke --function-name visitor_count_function out.json",
            out: ['{"visitor_count": 1204}', "200 OK · 38 ms"],
        },
        {
            cmd: "aws s3 sync ./Frontend s3://alfiyajaved.in --delete",
            out: ["upload: Frontend/index.html → s3://alfiyajaved.in/index.html"],
        },
        {
            cmd: "git push origin main",
            out: [
                "→ GitHub Actions: deploy-backend, deploy-frontend",
                "✔ tests passed   ✔ site live",
            ],
        },
    ];

    const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    function scrollBottom() {
        body.scrollTop = body.scrollHeight; // overflow:hidden still scrolls programmatically
    }

    function commandRow(cmd, withCursor) {
        const row = document.createElement("div");
        row.className = "t-line";

        const prompt = document.createElement("span");
        prompt.className = "t-prompt";
        prompt.textContent = "$ ";

        const text = document.createElement("span");
        text.className = "t-cmd";
        text.textContent = cmd;

        row.append(prompt, text);
        if (withCursor) {
            const cursor = document.createElement("span");
            cursor.className = "t-cursor";
            row.append(cursor);
        }
        body.appendChild(row);
        scrollBottom();
        return row;
    }

    function outputRow(text) {
        const row = document.createElement("div");
        row.className = "t-out";
        row.textContent = text;
        body.appendChild(row);
        scrollBottom();
    }

    async function typeCommand(cmd) {
        const row = commandRow("", true);
        const textEl = row.querySelector(".t-cmd");

        for (const char of cmd) {
            textEl.textContent += char;
            scrollBottom();
            await sleep(24 + Math.random() * 46); // human-ish jitter
        }

        const cursor = row.querySelector(".t-cursor");
        if (cursor) cursor.remove();
    }

    function renderStatic() {
        SESSION.forEach((step) => {
            commandRow(step.cmd, false);
            step.out.forEach(outputRow);
        });
    }

    async function playLoop() {
        for (;;) {
            body.innerHTML = "";
            for (const step of SESSION) {
                await typeCommand(step.cmd);
                await sleep(280);
                for (const line of step.out) {
                    outputRow(line);
                    await sleep(160);
                }
                await sleep(700);
            }
            await sleep(4000);
        }
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            observer.unobserve(card);
            if (reduceMotion) {
                renderStatic();
            } else {
                playLoop();
            }
        });
    }, { threshold: 0.35 });

    observer.observe(card);
})();