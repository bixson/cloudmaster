---

```
                                          .-~~~-.
                                  .- ~ ~-(       )_ _
                                 /                    ~ -.
                                |                          ',
                                 \                         .'
                                   ~- ._ ,. ,.,.,., ,.. -~
                                           '       '
   ______   __         ______   __    __  _______   __       __   ______    ______   ________  ________  _______
  /      \ /  |       /      \ /  |  /  |/       \ /  \     /  | /      \  /      \ /        |/        |/       \
 /$$$$$$  |$$ |      /$$$$$$  |$$ |  $$ |$$$$$$$  |$$  \   /$$ |/$$$$$$  |/$$$$$$  |$$$$$$$$/ $$$$$$$$/ $$$$$$$  |
 $$ |  $$/ $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$$  \ /$$$ |$$ |__$$ |$$ \__$$/    $$ |   $$ |__    $$ |__$$ |
 $$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$$$  /$$$$ |$$    $$ |$$      \    $$ |   $$    |   $$    $$<
 $$ |   __ $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ $$ $$/$$ |$$$$$$$$ | $$$$$$  |   $$ |   $$$$$/    $$$$$$$  |
 $$ \__/  |$$ |_____ $$ \__$$ |$$ \__$$ |$$ |__$$ |$$ |$$$/ $$ |$$ |  $$ |/  \__$$ |   $$ |   $$ |_____ $$ |  $$ |
 $$    $$/ $$       |$$    $$/ $$    $$/ $$    $$/ $$ | $/  $$ |$$ |  $$ |$$    $$/    $$ |   $$       |$$ |  $$ |
  $$$$$$/  $$$$$$$$/  $$$$$$/   $$$$$$/  $$$$$$$/  $$/      $$/ $$/   $$/  $$$$$$/     $$/    $$$$$$$$/ $$/   $$/

     Cloud Infrastructure + Security + Nginx  ─  Train for the Cloud exam
```
[![version](https://img.shields.io/badge/version-1.0.0-blue)](#)
[![bash](https://img.shields.io/badge/requires-bash%204.0%2B-lightgrey)](#)
[![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Git%20Bash-brightgreen)](#)
[![license](https://img.shields.io/badge/license-MIT-green)](#)
## What is this?

`cloudmaster` is an interactive, terminal-based training tool for learning **Cloud Infrastructure, Linux Security, and Web Deployment** specifically designed for the KEA Datamatiker Technology 2 Exam.

It runs entirely in your shell. No browser. No signup. No account.

You answer questions. Get them wrong and the script teaches you — shows you why, then asks again. Get them right and you move forward. Practical lab tasks in a simulated environment help you master the commands and configurations you'll need to demonstrate in your exam.

Finish all 5 zones and you'll understand the difference between IaaS and PaaS, know how to secure a cloud VM, manage SSH keys like a pro, and configure Nginx with TLS.

---

## Quick start

**Download and run:**

```bash
bash cloudmaster.sh
```

No installation needed. No dependencies beyond `bash 4.0+`.

---

## The 5 zones

| # | Zone | Topics covered | Live lab |
|---|------|---------------|----------|
| 1 | Cloud Models | IaaS, PaaS, SaaS, Shared Responsibility Model | — |
| 2 | Linux User Management | adduser, visudo, sudo, root security | **✓** |
| 3 | SSH Security & Keys | authorized_keys, chmod permissions, scp, key exchange | **✓** |
| 4 | Networking & Monitoring | netstat -atlpn, default ports, cloud firewalls | — |
| 5 | Web Deployment | Nginx config, nginx -t, TLS/SSL, Certbot | **✓** |

---

## What happens when you get an answer wrong

```
  Q: Why should you ALWAYS run 'nginx -t' before reloading the Nginx service?

    A) To speed up the reload process
    B) To check the config for syntax errors and prevent the server from crashing
    C) To update the TLS certificates automatically
    D) To clear the web cache

  Your answer [A/B/C/D]: A

  ✗  A syntax error can take down your whole site in production. 
     Always test first!

  [RETRY] One more try for half points [A/B/C/D]: B

  CORRECT  The answer is B.
```

First wrong answer shows exactly why *your specific choice* was wrong, then gives you one retry for half points. A second wrong answer reveals the correct answer, a teaching moment, and a memory tip. You always move forward — nothing blocks you.

---

## Scoring

| Score | Grade |
|-------|-------|
| 95%+ | A — Outstanding |
| 85–94% | B — Excellent |
| 70–84% | C — Good pass |
| 50–69% | E/D — Passing |
| Below 50% | F — Keep practicing |

Half points are awarded for correct answers on the second attempt. Zone progress is tracked in `~/.cloudmaster/`.

---

## Controls

| Key | Action |
|-----|--------|
| `A` `B` `C` `D` | Select multiple-choice answer (single keypress, no Enter needed) |
| `Enter` | Confirm typed answer / advance past a teaching screen |
| `Ctrl+N` | Skip question and mark it as correct |
| `Ctrl+B` | Go back one question (re-asks it with a clean screen) |
| `Ctrl+C` | Exit at any point |

---

## License

MIT

---

<div align="center">

Made for anyone learning Cloud Infrastructure from the command line.

If this helped you — consider leaving a star.

</div>
