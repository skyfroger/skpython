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
            }
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

function createAceEditor(element, content) {
    // Создаем новый div для редактора
    var editorDiv = document.createElement("div");
    element.appendChild(editorDiv);

    // Создаем редактор Ace
    var editor = ace.edit(editorDiv);
    editor.setTheme("ace/theme/nord");
    editor.session.setMode("ace/mode/python");
    editor.setValue(content);

    // Отключаем перенос строк для точного подсчета
    editor.session.setUseWrapMode(false);

    editor.setOptions({
        fontSize: "0.95rem",
        highlightActiveLine: false,
        highlightGutterLine: false,
        enableBasicAutocompletion: true,
        enableSnippets: true,
        enableLiveAutocompletion: false,
    });

    editor.setValue(content, -1); // -1 перемещает курсор в начало

    // Функция для обновления высоты редактора
    function updateEditorHeight() {
        var lineHeight = editor.renderer.lineHeight;
        var lines = editor.session.getLength();
        var newHeight = (lines + 0.5) * lineHeight;

        // Добавляем небольшой отступ
        newHeight += editor.renderer.scrollBar.getWidth();
        // максимальная высота - 350px, минимальная  - 45px
        if (newHeight > 40) {
            editorDiv.style.height = (newHeight < 350 ? newHeight : 350) + "px";
        } else {
            editorDiv.style.height = "40px";
        }
        editor.resize();
    }

    // Обновляем высоту изначально
    updateEditorHeight();

    // Обновляем высоту при изменении содержимого
    editor.session.on("change", updateEditorHeight);

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
    ace.require("ace/ext/language_tools"); // простое автодополнение кода

    var ideElements = document.querySelectorAll("div.ide");

    ideElements.forEach(function (element) {
        var preElement = element.querySelector("pre");

        if (preElement) {
            var content = preElement.textContent;
            preElement.remove();
            createAceEditor(element, content);
        }
    });
};
