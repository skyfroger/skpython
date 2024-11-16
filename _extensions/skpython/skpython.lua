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
      startTime(){
        this.timer = setTimeout(()=>{
          this.open = true;
        }, 1500);
      },
      stopTimer(){
        clearTimeout(this.timer);
        this.open = false;
      },
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
    <div class="sk__dropdown"
            x-on:mouseleave="stopTimer">
      <button
        :class="{ 'expanded': open }"
        x-on:mouseenter="startTime"
        class="sk__dropdown-button run"
        type="button"
        x-on:click="runit(editorId, `skulpt-output${editorId}`, `skulpt-canvas${editorId}`); open=false; "
      >
        <span>▷</span>
        <span x-show="open" x-transition x-cloak>
          Запустить
        </span>
      </button>
      <div x-show="open" x-cloak x-transition class="sk__dropdown-menu">
            <button class="stop" type="button" x-on:click="stopit(`skulpt-output${editorId}`); open=false;">▢ Остановить</button>
            <button class="general" type="button" x-on:click="
              editors[editorId].setValue($refs.original.innerText);
              open=false;
            ">↻ Восстановить</button>
            <button class="general" type="button" x-on:click="
              navigator.clipboard.writeText(editors[editorId].getValue());
              open=false;
            ">✎ Скопировать</button>
            <button class="general" type="button" x-on:click="
              saveToFile(editorId);
              open=false;
            ">🖪 Сохранить</button>
      </div>
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
  quarto.doc.include_text("in-header",
    [[<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ace.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ext-language_tools.js"></script>]])
  CodeBlock = function(block)
    -- # Вопрос с одним правильным ответом # --
    if block.classes:includes("sk-python") then -- если div содержит нужный стиль - обрабатываем разметку
      writeEnvironments()
      return createSkulptIDE(block)
    end
    return nil
  end
end
