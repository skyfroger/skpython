local function writeEnvironments()
  if quarto.doc.is_format("html:js") then
    quarto.doc.add_html_dependency({
      name = "skulpt",
      version = "1",
      scripts = {
        { path = "skulpt.min.js",    },
        { path = "skulpt-stdlib.js"  },
        { path = "python-skulpt.js"  }
      },
      stylesheets = { "skstyles.css" }
    })

    quarto.doc.add_html_dependency({
      name = "alpine",
      version = "3.12",
      scripts = {
        { path = "sort-alpine.min.js", afterBody = "true" },
        { path = "alpine.min.js", afterBody = "true" }
      }
    })
  end
end

local aceLibsAdded = false
local function addAceLibsOnce()
  if aceLibsAdded then return end
  aceLibsAdded = true
  quarto.doc.include_text("in-header", [[
<script src="https://www.unpkg.com/ace-builds@latest/src-noconflict/ace.js"></script>
<script src="https://www.unpkg.com/ace-builds@latest/src-noconflict/ext-language_tools.js"></script>
<script src="https://www.unpkg.com/ace-linters@latest/build/ace-linters.js"></script>
<style>[x-cloak] { display: none !important; }</style>
]])
end

idesCounter = 0

function createSkulptIDE(block)
  local elementContent = {}
  local id = idesCounter

  table.insert(elementContent, pandoc.RawBlock("html",
    [[<div class="skulpt-editor" x-data="skulptEditor(]] .. id .. [[)">
    <div class="sk__dropdown">
    <div class="sk__toolbar"> <!-- начало блока с кнопками -->
      <button class="sk__dropdown-button run" type="button"
        :disabled="isRunning"
        @click="run()"
        title="Запустить">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1wbGF5LWljb24gbHVjaWRlLXBsYXkiPjxwYXRoIGQ9Ik01IDVhMiAyIDAgMCAxIDMuMDA4LTEuNzI4bDExLjk5NyA2Ljk5OGEyIDIgMCAwIDEgLjAwMyAzLjQ1OGwtMTIgN0EyIDIgMCAwIDEgNSAxOXoiLz48L3N2Zz4=" />
      </button>

      <button class="sk__dropdown-button general" type="button"
        title="Остановить скрипт"
        :disabled="!isRunning"
        @click="stop()">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNlNzY1ODUiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1zcXVhcmUtaWNvbiBsdWNpZGUtc3F1YXJlIj48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIi8+PC9zdmc+" />
      </button>

      <button class="sk__dropdown-button general" type="button"
        title="Скрыть результат работы скрипта"
        @click="clearOutput()">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXBhbmVsLWJvdHRvbS1jbG9zZS1pY29uIGx1Y2lkZS1wYW5lbC1ib3R0b20tY2xvc2UiPjxyZWN0IHdpZHRoPSIxOCIgaGVpZ2h0PSIxOCIgeD0iMyIgeT0iMyIgcng9IjIiLz48cGF0aCBkPSJNMyAxNWgxOCIvPjxwYXRoIGQ9Im0xNSA4LTMgMy0zLTMiLz48L3N2Zz4=" />
      </button>

      <button class="sk__dropdown-button general" type="button"
        title="Восстановить исходный код"
        @click="resetCode()">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXJvdGF0ZS1jY3ctaWNvbiBsdWNpZGUtcm90YXRlLWNjdyI+PHBhdGggZD0iTTMgMTJhOSA5IDAgMSAwIDktOSA5Ljc1IDkuNzUgMCAwIDAtNi43NCAyLjc0TDMgOCIvPjxwYXRoIGQ9Ik0zIDN2NWg1Ii8+PC9zdmc+" />
      </button>

      <button class="sk__dropdown-button general" type="button"
        title="Скопировать код"
        @click="copyCode()">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWZpbGVzLWljb24gbHVjaWRlLWZpbGVzIj48cGF0aCBkPSJNMTUgMmgtNGEyIDIgMCAwIDAtMiAydjExYTIgMiAwIDAgMCAyIDJoOGEyIDIgMCAwIDAgMi0yVjgiLz48cGF0aCBkPSJNMTYuNzA2IDIuNzA2QTIuNCAyLjQgMCAwIDAgMTUgMnY1YTEgMSAwIDAgMCAxIDFoNWEyLjQgMi40IDAgMCAwLS43MDYtMS43MDZ6Ii8+PHBhdGggZD0iTTUgN2EyIDIgMCAwIDAtMiAydjExYTIgMiAwIDAgMCAyIDJoOGEyIDIgMCAwIDAgMS43MzItMSIvPjwvc3ZnPg==" />
      </button>

      <button class="sk__dropdown-button general" type="button"
        title="Сохранить скрипт в файл"
        @click="saveToFile()">
        <img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNhdmUtaWNvbiBsdWNpZGUtc2F2ZSI+PHBhdGggZD0iTTE1LjIgM2EyIDIgMCAwIDEgMS40LjZsMy44IDMuOGEyIDIgMCAwIDEgLjYgMS40VjE5YTIgMiAwIDAgMS0yIDJINWEyIDIgMCAwIDEtMi0yVjVhMiAyIDAgMCAxIDItMnoiLz48cGF0aCBkPSJNMTcgMjF2LTdhMSAxIDAgMCAwLTEtMUg4YTEgMSAwIDAgMC0xIDF2NyIvPjxwYXRoIGQ9Ik03IDN2NGExIDEgMCAwIDAgMSAxaDciLz48L3N2Zz4=" />
      </button>
    </div> <!-- конец блока с кнопками -->

      <img :title="statusImages[status].title" :src="statusImages[status].icon"/>
    </div>

    <div>
      <div class="ide" x-ref="editorContainer"></div>

      <pre id="skulpt-output]] .. id .. [[" x-ref="output" class="output__container"></pre>
      <div id="skulpt-canvas]] .. id .. [[" x-ref="canvas" class="output__turtle"></div>
      <pre style="display:none" x-ref="original">]] .. block.text .. [[</pre>
    </div>

    <div class="sk__editor__func" x-show="functionNames.length !== 0" x-transition>
    <img title="Список используемых функций" style="height: 18px;" src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiM1MTU3NmQiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBjbGFzcz0ibHVjaWRlIGx1Y2lkZS1ib29rLW1hcmtlZC1pY29uIGx1Y2lkZS1ib29rLW1hcmtlZCI+PHBhdGggZD0iTTEwIDJ2OGwzLTMgMyAzVjIiLz48cGF0aCBkPSJNNCAxOS41di0xNUEyLjUgMi41IDAgMCAxIDYuNSAySDE5YTEgMSAwIDAgMSAxIDF2MThhMSAxIDAgMCAxLTEgMUg2LjVhMSAxIDAgMCAxIDAtNUgyMCIvPjwvc3ZnPg=="/>
    <template x-for="(func, index) in functionNames" :key="index">
      <code x-text="func"></code>
    </template>
    </div>
</div>]]))

  idesCounter = idesCounter + 1
  return pandoc.Div(elementContent)
end

if quarto.doc.isFormat("html:js") then
  CodeBlock = function(block)
    if block.classes:includes("sk-python") then
      addAceLibsOnce()
      writeEnvironments()
      return createSkulptIDE(block)
    end
    return nil
  end
end