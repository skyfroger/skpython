// массив редакторов на странице
const editors = [];

// Глобальная переменная для отслеживания текущего выполняющегося редактора
let currentRunningEditor = null;

// Функция для остановки выполнения всех редакторов, кроме текущего
function stopAllOtherEditors(currentEditorIndex) {
    editors.forEach((editor, index) => {
        if (index !== currentEditorIndex) {
            stopit(`skulpt-output${index}`);
            //clearOutput(`skulpt-output${index}`);
        }
    });
}

// Функция для создания пользовательского обработчика вывода
function output(containerId) {
    // по-умолчанию скрываем окно вывода
    document.getElementById(containerId).style.display = "none";
    return (text) => {
        // если код вызывает print(), показываем окно вывода
        document.getElementById(containerId).style.display = "block";
        var outputDiv = document.getElementById(containerId);
        var textNode = document.createTextNode(text);
        outputDiv.appendChild(textNode);
        // Прокручиваем вывод вниз
        outputDiv.scrollTop = outputDiv.scrollHeight;
    };
}

// Функция для очистки вывода
function clearOutput(containerId) {
    const outputDiv = document.getElementById(containerId);
    if (outputDiv) {
        outputDiv.innerHTML = "";
    }
}

function builtinRead(x) {
    if (
        Sk.builtinFiles === undefined ||
        Sk.builtinFiles["files"][x] === undefined
    )
        throw "File not found: '" + x + "'";
    return Sk.builtinFiles["files"][x];
}

function input(containerId) {
    return (prompt) => {
        return new Promise((resolve) => {
            var outputDiv = document.getElementById(containerId);

            // Отображаем запрос на ввод
            const outf = output(containerId);
            outf(prompt);

            var inputElement = document.createElement("input");
            inputElement.type = "text";
            inputElement.style.cssText = `width: calc(100% - ${prompt.length}ch);`;

            inputElement.onkeydown = function (e) {
                if (e.key === "Enter") {
                    e.preventDefault(); // Предотвращаем стандартное поведение Enter
                    var inputValue = inputElement.value;
                    // Отображаем введенное значение
                    outf(inputValue + "\n");
                    outputDiv.removeChild(inputElement);
                    // Прокручиваем вывод вниз
                    outputDiv.scrollTop = outputDiv.scrollHeight;
                    resolve(inputValue);
                }
            };

            outputDiv.appendChild(inputElement);
            inputElement.focus();
        });
    };
}

// Обновленная функция stopit
function stopit(containerId) {
    // console.log(`Stopping execution for ${containerId}`);
    Sk.execLimit = 1;
}

// Обновленная функция runit
function runit(editorIndex, outputContainerId, canvasOutputId) {
    // Останавливаем все другие редакторы
    stopAllOtherEditors(editorIndex);
    // очищаем окно вывода
    clearOutput(outputContainerId);

    // Sk.builtinFiles["files"]["src/lib/adder.py"] = `def add(x, y):
    //   return x + y`;
    // console.log(Sk.builtinFiles);
    // изначально скрываем окно вывода
    document.getElementById(outputContainerId).style.display = "none";

    currentRunningEditor = editorIndex;
    const prog = getEditorContent(editorIndex);
    Sk.pre = outputContainerId;
    Sk.configure({
        __future__: Sk.python3,
        output: output(outputContainerId),
        read: builtinRead,
        inputfun: input(outputContainerId),
        inputfunTakesPrompt: true,
        yieldLimit: 200,
        execLimit: 180000,
        killableWhile: true,
        killableFor: true,
    });
    (Sk.TurtleGraphics || (Sk.TurtleGraphics = {})).target = canvasOutputId;
    (Sk.TurtleGraphics || (Sk.TurtleGraphics = {})).width = 400;
    (Sk.TurtleGraphics || (Sk.TurtleGraphics = {})).height = 300;
    Sk.timeoutMsg = function () {
        return "Программа остановлена";
    };
    Sk.misceval
        .asyncToPromise(
            () => {
                return Sk.importMainWithBody("<stdin>", false, prog, true);
            },
            {
                "*": () => {
                    if (currentRunningEditor !== editorIndex) {
                        throw new Error("Execution interrupted");
                    }
                },
            },
        )
        .catch((err) => {
            // показываем окно вывода, если обнаружена ошибка
            document.getElementById(outputContainerId).style.display = "block";
            const outputDiv = document.getElementById(outputContainerId);
            const textNode = document.createTextNode(err.toString() + "\n");
            outputDiv.appendChild(textNode);
            outputDiv.scrollTop = outputDiv.scrollHeight;
            console.log(err.toString());
        })
        .finally(() => {
            console.log("Код выполнился без ошибок");
            if (currentRunningEditor === editorIndex) {
                currentRunningEditor = null;
            }
        });
}

function createMonacoEditor(element, content) {
    const editorDiv = document.createElement("div"); // Создаем новый div для редактора
    editorDiv.style.maxHeight = "274px"; // максимальная высота редактора - 14 строк
    element.appendChild(editorDiv);

    var editor = monaco.editor.create(editorDiv, {
        value: content,
        language: "python",
        theme: "vs", // options: 'vs', 'vs-dark', 'hc-black'
        automaticLayout: true, // helps resizing
        scrollBeyondLastLine: false,
        quickSuggestions: false, // Отключает подсказки при сонаправленном вводе
        suggestOnTriggerCharacters: false, // Отключает подсказки при вводе спецсимволов (например, точки)
        wordBasedSuggestions: "off", // Отключает подсказки на основе уже введенных слов
        parameterHints: { enabled: false }, // Отключает подсказки по параметрам функций
        snippetSuggestions: "none",
        minimap: {
            enabled: false, // Полностью скрывает мини-карту справа
        },
        glyphMargin: false, // Отключает самое левое поле для иконок (брейкпоинты, варнинги)
        folding: false, // Отключает кнопки сворачивания кода (стрелочки [-] / [+])
        lineNumbersMinChars: 3,
    });
    function updateEditorHeight() {
        const contentHeight = editor.getContentHeight();
        editorDiv.style.height = `${contentHeight + 8}px`;
        editor.layout();
    }

    function validatePython() {
        const model = editor.getModel();
        if (!model) return;

        const code = model.getValue();
        console.log("validate logic", code);
    }

    // Вызываем при первой загрузке и при каждом изменении текста
    let validationTimeout = null;
    editor.onDidChangeModelContent(() => {
        updateEditorHeight();
        clearTimeout(validationTimeout);
        validationTimeout = setTimeout(validatePython, 2000);
    });

    validatePython();
    updateEditorHeight();
    editors.push(editor);
}

function getEditorContent(index) {
    // возвращаем исходный код из редактора с заданным индексом
    return index >= 0 && index < editors.length
        ? editors[index].getValue()
        : "";
}

// Создаём редакторы только после полной загрузки страницы
window.onload = function () {
    require.config({
        paths: { vs: "https://unpkg.com/monaco-editor@latest/min/vs" },
    });

    require(["vs/editor/editor.main"], function () {
        var ideElements = document.querySelectorAll("div.ide");

        ideElements.forEach(function (element) {
            var preElement = element.querySelector("pre");

            if (preElement) {
                var content = preElement.textContent;
                preElement.remove();
                createMonacoEditor(element, content);
            }
        });
    });
};
