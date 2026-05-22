local function writeEnvironments()
  if quarto.doc.is_format("html:js") then
    quarto.doc.add_html_dependency({
      name = "alpine",
      version = "3.12",
      scripts = {
        { path = "alpine.min.js", afterBody = "true" }
      }
    })
    quarto.doc.add_html_dependency({
      name = "skulpt",
      version = "1",
      scripts = {
        { path = "skulpt.min.js",    afterBody = "true" },
        { path = "skulpt-stdlib.js", afterBody = "true" },
        { path = "python-skulpt.js", afterBody = "true" }
      },
      stylesheets = { "skstyles.css" }
    })
  end
end

idesCounter = 0 -- количество обработанных блоков кода

function createSkulptIDE(block)
  local elementContent = {} -- разметка ide

  table.insert(elementContent, pandoc.RawBlock("html",
    [[<div class="skulpt-editor" x-data="{
      open: false,
      timer: null,
      editorId: ]] .. idesCounter .. [[,
      saveToFile(index){
        const element = document.createElement('a');

        let fileContent = getEditorContent(index);
        fileContent = fileContent.replace(/\n/g, '\r\n');

        const blob = new Blob([fileContent], { type: 'plain/text' });

        element.href = window.URL.createObjectURL(blob);
        element.download = 'script.py';
        element.style.display = 'none';

        document.body.appendChild(element);
        element.click();

        document.body.removeChild(element);
      }
    }">
    <div class="sk__dropdown">
      <button
        class="sk__dropdown-button run"
        type="button"
        x-on:click="runit(editorId, `skulpt-output${editorId}`, `skulpt-canvas${editorId}`);"
      >
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1wbGF5LWljb24gbHVjaWRlLXBsYXkiPjxwYXRoIGQ9Ik01IDVhMiAyIDAgMCAxIDMuMDA4LTEuNzI4bDExLjk5NyA2Ljk5OGEyIDIgMCAwIDEgLjAwMyAzLjQ1OGwtMTIgN0EyIDIgMCAwIDEgNSAxOXoiLz48L3N2Zz4=" />
      </button>
      
      <button class="sk__dropdown-button general" type="button" title="Остановить скрипт" x-on:click="stopit(`skulpt-output${editorId}`);">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNlNzY1ODUiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1zcXVhcmUtaWNvbiBsdWNpZGUtc3F1YXJlIj48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIi8+PC9zdmc+" />
      </button>
      
      <button class="sk__dropdown-button general" type="button" title="Восстановить исходный код" x-on:click="editors[editorId].setValue($refs.original.innerText);">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXJvdGF0ZS1jY3ctaWNvbiBsdWNpZGUtcm90YXRlLWNjdyI+PHBhdGggZD0iTTMgMTJhOSA5IDAgMSAwIDktOSA5Ljc1IDkuNzUgMCAwIDAtNi43NCAyLjc0TDMgOCIvPjxwYXRoIGQ9Ik0zIDN2NWg1Ii8+PC9zdmc+"/>
      </button>
      
      <button class="sk__dropdown-button general" type="button" title="Скопировать код" x-on:click="navigator.clipboard.writeText(editors[editorId].getValue());">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWZpbGVzLWljb24gbHVjaWRlLWZpbGVzIj48cGF0aCBkPSJNMTUgMmgtNGEyIDIgMCAwIDAtMiAydjExYTIgMiAwIDAgMCAyIDJoOGEyIDIgMCAwIDAgMi0yVjgiLz48cGF0aCBkPSJNMTYuNzA2IDIuNzA2QTIuNCAyLjQgMCAwIDAgMTUgMnY1YTEgMSAwIDAgMCAxIDFoNWEyLjQgMi40IDAgMCAwLS43MDYtMS43MDZ6Ii8+PHBhdGggZD0iTTUgN2EyIDIgMCAwIDAtMiAydjExYTIgMiAwIDAgMCAyIDJoOGEyIDIgMCAwIDAgMS43MzItMSIvPjwvc3ZnPg==" />
      </button>
      
      <button class="sk__dropdown-button general" type="button" title="Сохранить скрипт в файл" x-on:click="
        saveToFile(editorId);">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNhdmUtaWNvbiBsdWNpZGUtc2F2ZSI+PHBhdGggZD0iTTE1LjIgM2EyIDIgMCAwIDEgMS40LjZsMy44IDMuOGEyIDIgMCAwIDEgLjYgMS40VjE5YTIgMiAwIDAgMS0yIDJINWEyIDIgMCAwIDEtMi0yVjVhMiAyIDAgMCAxIDItMnoiLz48cGF0aCBkPSJNMTcgMjF2LTdhMSAxIDAgMCAwLTEtMUg4YTEgMSAwIDAgMC0xIDF2NyIvPjxwYXRoIGQ9Ik03IDN2NGExIDEgMCAwIDAgMSAxaDciLz48L3N2Zz4=" />
      </button>

    </div> <!-- конец блока с кнопками -->
    <div> <!-- Начало основного блока -->
      <div class="ide">
        <pre x-ref="editable">]]
    .. block.text ..
    [[</pre>
      </div>

      <pre id="skulpt-output]] .. idesCounter .. [[" class="output__container"></pre>
      <div id="skulpt-canvas]] .. idesCounter .. [[" class="output__turtle"></div>
      <pre style="display:none" x-ref="original">]]
    .. block.text ..
    [[</pre>
    </div> <!-- Конец основного блока -->
    </div>]]))


  idesCounter = idesCounter + 1

  return pandoc.Div(elementContent)
end

if quarto.doc.isFormat("html:js") then
  CodeBlock = function(block)
    -- # Вопрос с одним правильным ответом # --
    if block.classes:includes("sk-python") then -- если div содержит нужный стиль - обрабатываем разметку
      quarto.doc.include_text("in-header",
        [[<script src="https://www.unpkg.com/ace-builds@latest/src-noconflict/ace.js"></script>
<script src="https://www.unpkg.com/ace-builds@latest/src-noconflict/ext-language_tools.js"></script>
<script src="https://www.unpkg.com/ace-linters@latest/build/ace-linters.js"></script>]])
      writeEnvironments()
      return createSkulptIDE(block)
    end
    return nil
  end
end
