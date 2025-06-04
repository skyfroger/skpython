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
        <span>▷</span>
      </button>

      <div id="skulpt-hamburger-]] .. idesCounter .. [[" class="menu-trigger">
        <div class="menu-icon">
            <div class="dot"></div>
            <div class="dot"></div>
            <div class="dot"></div>
        </div>
      </div>
      <div id="skulpt-menu-]] .. idesCounter .. [[" style="display: none;">
            <button class="sk__dropdown-button stop" type="button" title="Остановить" x-on:click="
              stopit(`skulpt-output${editorId}`);
              document.getElementById('skulpt-hamburger-]] .. idesCounter .. [[')._tippy.hide();
            ">▢</button>
            <button class="sk__dropdown-button general" type="button" title="Восстановить" x-on:click="
              editors[editorId].setValue($refs.original.innerText);
              document.getElementById('skulpt-hamburger-]] .. idesCounter .. [[')._tippy.hide();
            ">↻</button>
            <button class="sk__dropdown-button general" type="button" title="Скопировать" x-on:click="
              navigator.clipboard.writeText(editors[editorId].getValue());
              document.getElementById('skulpt-hamburger-]] .. idesCounter .. [[')._tippy.hide();
            ">✎</button>
            <button class="sk__dropdown-button general" type="button" title="Сохранить файл" x-on:click="
              saveToFile(editorId);
              document.getElementById('skulpt-hamburger-]] .. idesCounter .. [[')._tippy.hide();
            ">🖪</button>
      </div>
      <script>
        const template]] .. idesCounter .. [[ = document.getElementById("skulpt-menu-]] .. idesCounter .. [[");

        tippy("#skulpt-hamburger-]] .. idesCounter .. [[", {
          content: template]] .. idesCounter .. [[.innerHTML,
          allowHTML: true,
          interactive: true,
          interactiveBorder: 30,
          interactiveDebounce: 75,
          trigger: 'click',
          maxWidth: 'none',
          theme: 'skmenu',
          placement: 'right',
        });
      </script>
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
        [[<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ace.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ext-language_tools.js"></script>]])
      writeEnvironments()
      return createSkulptIDE(block)
    end
    return nil
  end
end
