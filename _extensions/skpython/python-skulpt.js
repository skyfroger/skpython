// Глобальный ID активного редактора (Skulpt не поддерживает параллельность)
window.skulptRunningId = null;

function builtinRead(x) {
    if (
        Sk.builtinFiles === undefined ||
        Sk.builtinFiles["files"][x] === undefined
    )
        throw "File not found: '" + x + "'";
    return Sk.builtinFiles["files"][x];
}

function registerSkulptAlpine() {
    Alpine.data("skulptEditor", (editorId) => ({
        editorId: editorId,
        editor: null,
        originalCode: "",
        isRunning: false,
        isWaitingForInput: false,
        hasError: false,
        status: "ready", // ready | running | waiting-input | error | finished | stopped
        statusImages: {
            ready: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiM1MTU3NmQiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1zcXVpcmNsZS1kYXNoZWQtaWNvbiBsdWNpZGUtc3F1aXJjbGUtZGFzaGVkIj48cGF0aCBkPSJNMTMuNzcgMy4wNDNhMzQgMzQgMCAwIDAtMy41NCAwIi8+PHBhdGggZD0iTTEzLjc3MSAyMC45NTZhMzMgMzMgMCAwIDEtMy41NDEuMDAxIi8+PHBhdGggZD0iTTIwLjE4IDE3Ljc0Yy0uNTEgMS4xNS0xLjI5IDEuOTMtMi40MzkgMi40NCIvPjxwYXRoIGQ9Ik0yMC4xOCA2LjI1OWMtLjUxLTEuMTQ4LTEuMjkxLTEuOTI5LTIuNDQtMi40MzgiLz48cGF0aCBkPSJNMjAuOTU3IDEwLjIzYTMzIDMzIDAgMCAxIDAgMy41NCIvPjxwYXRoIGQ9Ik0zLjA0MyAxMC4yM2EzNCAzNCAwIDAgMCAuMDAxIDMuNTQxIi8+PHBhdGggZD0iTTYuMjYgMjAuMTc5Yy0xLjE1LS41MDgtMS45My0xLjI5LTIuNDQtMi40MzgiLz48cGF0aCBkPSJNNi4yNiAzLjgyYy0xLjE0OS41MS0xLjkzIDEuMjkxLTIuNDQgMi40NCIvPjwvc3ZnPg==",
            running:
                "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNxdWFyZS1jaGV2cm9uLXJpZ2h0LWljb24gbHVjaWRlLXNxdWFyZS1jaGV2cm9uLXJpZ2h0Ij48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIi8+PHBhdGggZD0ibTEwIDggNCA0LTQgNCIvPjwvc3ZnPg==",
            "waiting-input":
                "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiMwMGE2ZWQiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1rZXlib2FyZC1pY29uIGx1Y2lkZS1rZXlib2FyZCI+PHBhdGggZD0iTTEwIDhoLjAxIi8+PHBhdGggZD0iTTEyIDEyaC4wMSIvPjxwYXRoIGQ9Ik0xNCA4aC4wMSIvPjxwYXRoIGQ9Ik0xNiAxMmguMDEiLz48cGF0aCBkPSJNMTggOGguMDEiLz48cGF0aCBkPSJNNiA4aC4wMSIvPjxwYXRoIGQ9Ik03IDE2aDEwIi8+PHBhdGggZD0iTTggMTJoLjAxIi8+PHJlY3Qgd2lkdGg9IjIwIiBoZWlnaHQ9IjE2IiB4PSIyIiB5PSI0IiByeD0iMiIvPjwvc3ZnPg==",
            error: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNlMzRhNmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1iYWRnZS1hbGVydC1pY29uIGx1Y2lkZS1iYWRnZS1hbGVydCI+PHBhdGggZD0iTTMuODUgOC42MmE0IDQgMCAwIDEgNC43OC00Ljc3IDQgNCAwIDAgMSA2Ljc0IDAgNCA0IDAgMCAxIDQuNzggNC43OCA0IDQgMCAwIDEgMCA2Ljc0IDQgNCAwIDAgMS00Ljc3IDQuNzggNCA0IDAgMCAxLTYuNzUgMCA0IDQgMCAwIDEtNC43OC00Ljc3IDQgNCAwIDAgMSAwLTYuNzZaIi8+PGxpbmUgeDE9IjEyIiB4Mj0iMTIiIHkxPSI4IiB5Mj0iMTIiLz48bGluZSB4MT0iMTIiIHgyPSIxMi4wMSIgeTE9IjE2IiB5Mj0iMTYiLz48L3N2Zz4=",
            finished:
                "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiM2MGE1NjEiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1iYWRnZS1jaGVjay1pY29uIGx1Y2lkZS1iYWRnZS1jaGVjayI+PHBhdGggZD0iTTMuODUgOC42MmE0IDQgMCAwIDEgNC43OC00Ljc3IDQgNCAwIDAgMSA2Ljc0IDAgNCA0IDAgMCAxIDQuNzggNC43OCA0IDQgMCAwIDEgMCA2Ljc0IDQgNCAwIDAgMS00Ljc3IDQuNzggNCA0IDAgMCAxLTYuNzUgMCA0IDQgMCAwIDEtNC43OC00Ljc3IDQgNCAwIDAgMSAwLTYuNzZaIi8+PHBhdGggZD0ibTkgMTIgMiAyIDQtNCIvPjwvc3ZnPg==",
            stopped:
                "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiM1MTU3NmQiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1oYW5kLWljb24gbHVjaWRlLWhhbmQiPjxwYXRoIGQ9Ik0xOCAxMVY2YTIgMiAwIDAgMC0yLTJhMiAyIDAgMCAwLTIgMiIvPjxwYXRoIGQ9Ik0xNCAxMFY0YTIgMiAwIDAgMC0yLTJhMiAyIDAgMCAwLTIgMnYyIi8+PHBhdGggZD0iTTEwIDEwLjVWNmEyIDIgMCAwIDAtMi0yYTIgMiAwIDAgMC0yIDJ2OCIvPjxwYXRoIGQ9Ik0xOCA4YTIgMiAwIDEgMSA0IDB2NmE4IDggMCAwIDEtOCA4aC0yYy0yLjggMC00LjUtLjg2LTUuOTktMi4zNGwtMy42LTMuNmEyIDIgMCAwIDEgMi44My0yLjgyTDcgMTUiLz48L3N2Zz4=",
        },
        shouldStop: false,
        inputResolve: null,
        activeInputElement: null,

        // ─── Инициализация ───
        init() {
            this.originalCode = this.$refs.original.textContent;
            this.$nextTick(() => this.initAce());
        },

        initAce() {
            const container = this.$refs.editorContainer;
            this.editor = ace.edit(container);
            this.editor.setTheme("ace/theme/github_light_default");
            this.editor.session.setMode("ace/mode/python");
            this.editor.setValue(this.originalCode, -1);

            ace.require("ace/ext/language_tools");

            if (window.LanguageProvider) {
                try {
                    const provider = LanguageProvider.fromCdn(
                        "https://www.unpkg.com/ace-linters@latest/build/",
                    );
                    provider.registerEditor(this.editor);
                } catch (e) {
                    /* ignore */
                }
            }

            this.editor.session.setUseWrapMode(false);
            this.editor.setOptions({
                fontSize: "0.95rem",
                highlightActiveLine: false,
                highlightGutterLine: false,
                enableBasicAutocompletion: true,
                enableSnippets: true,
                enableLiveAutocompletion: false,
            });

            const updateHeight = () => {
                const lineHeight = this.editor.renderer.lineHeight || 16;
                let h = (this.editor.session.getLength() + 0.5) * lineHeight;
                if (this.editor.renderer.scrollBar)
                    h += this.editor.renderer.scrollBar.getWidth();
                container.style.height =
                    (h > 40 ? Math.min(h, 350) : 40) + "px";
                this.editor.resize();
            };

            this.editor.session.on("change", updateHeight);
            updateHeight();
        },

        getCode() {
            return this.editor ? this.editor.getValue() : "";
        },

        // ─── Вывод ───
        addOutput(text) {
            const out = this.$refs.output;
            out.style.display = "block";
            out.appendChild(document.createTextNode(text));
            out.scrollTop = out.scrollHeight;
        },

        clearOutput() {
            this.$refs.output.innerHTML = "";
            this.$refs.output.style.display = "none";
        },

        // ─── Запуск ───
        run() {
            if (this.isRunning) return;

            // Прерываем другой редактор, если он крутится
            if (
                window.skulptRunningId !== null &&
                window.skulptRunningId !== this.editorId
            ) {
                Sk.execLimit = 1;
            }

            window.skulptRunningId = this.editorId;
            this.shouldStop = false;
            this.isRunning = true;
            this.isWaitingForInput = false;
            this.hasError = false;
            this.status = "running";
            this.activeInputElement = null;

            this.clearOutput();

            const prog = this.getCode();
            const myId = this.editorId;

            Sk.configure({
                __future__: Sk.python3,
                output: (text) => this.addOutput(text),
                read: builtinRead,
                inputfun: (prompt) => this.handleInput(prompt),
                inputfunTakesPrompt: true,
                yieldLimit: 200,
                execLimit: 180000,
                killableWhile: true,
                killableFor: true,
            });

            Sk.pre = this.$refs.output.id;
            (Sk.TurtleGraphics || (Sk.TurtleGraphics = {})).target =
                this.$refs.canvas.id;
            (Sk.TurtleGraphics || (Sk.TurtleGraphics = {})).width = 400;
            (Sk.TurtleGraphics || (Sk.TurtleGraphics = {})).height = 300;

            Sk.timeoutMsg = () => "Программа остановлена";

            Sk.misceval
                .asyncToPromise(
                    () => Sk.importMainWithBody("<stdin>", false, prog, true),
                    {
                        "*": () => {
                            if (
                                window.skulptRunningId !== myId ||
                                this.shouldStop
                            ) {
                                throw new Error("Execution interrupted");
                            }
                        },
                    },
                )
                .then(() => {
                    if (window.skulptRunningId === myId && !this.shouldStop) {
                        this.status = "finished";
                    }
                })
                .catch((err) => {
                    if (window.skulptRunningId === myId && !this.shouldStop) {
                        this.hasError = true;
                        this.status = "error";
                        this.addOutput(err.toString() + "\n");
                    }
                })
                .finally(() => {
                    if (window.skulptRunningId === myId) {
                        window.skulptRunningId = null;
                    }
                    this.isRunning = false;
                    this.isWaitingForInput = false;
                    this.shouldStop = false;
                    this.inputResolve = null;
                    this.activeInputElement = null;
                });
        },

        // ─── Остановка ───
        stop() {
            this.shouldStop = true;
            Sk.execLimit = 1;

            // Если сейчас ждём ввода — убираем input из DOM и разблокируем Promise
            if (this.activeInputElement && this.activeInputElement.parentNode) {
                this.activeInputElement.parentNode.removeChild(
                    this.activeInputElement,
                );
                this.activeInputElement = null;
            }
            if (this.inputResolve) {
                this.inputResolve(""); // пустая строка, чтобы Skulpt продолжил
                this.inputResolve = null;
            }

            this.isRunning = false;
            this.isWaitingForInput = false;
            this.status = "stopped";

            if (window.skulptRunningId === this.editorId) {
                window.skulptRunningId = null;
            }
        },

        // ─── Ввод (input) внутри окна вывода ───
        handleInput(prompt) {
            return new Promise((resolve) => {
                this.inputResolve = resolve;
                this.isWaitingForInput = true;
                this.status = "waiting-input";

                // Выводим prompt в консоль
                this.addOutput(prompt);

                const out = this.$refs.output;
                const inputEl = document.createElement("input");
                inputEl.type = "text";
                inputEl.style.cssText = `width: calc(100% - ${prompt.length}ch);`;

                inputEl.onkeydown = (e) => {
                    if (e.key === "Enter") {
                        e.preventDefault();
                        const value = inputEl.value;

                        // Отображаем введённое значение в выводе
                        this.addOutput(value + "\n");
                        out.removeChild(inputEl);
                        this.activeInputElement = null;

                        out.scrollTop = out.scrollHeight;

                        this.isWaitingForInput = false;
                        this.inputResolve = null;
                        if (!this.shouldStop) this.status = "running";

                        resolve(value);
                    }
                };

                out.appendChild(inputEl);
                this.activeInputElement = inputEl;
                inputEl.focus();
            });
        },

        // ─── Утилиты ───
        resetCode() {
            if (this.editor) this.editor.setValue(this.originalCode, -1);
        },

        copyCode() {
            navigator.clipboard.writeText(this.getCode());
        },

        saveToFile() {
            const blob = new Blob([this.getCode().replace(/\n/g, "\r\n")], {
                type: "plain/text",
            });
            const a = document.createElement("a");
            a.href = window.URL.createObjectURL(blob);
            a.download = "script.py";
            a.style.display = "none";
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        },
    }));
}

if (window.Alpine) {
    registerSkulptAlpine();
} else {
    document.addEventListener("alpine:init", registerSkulptAlpine);
}
