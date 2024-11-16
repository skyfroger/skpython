local function writeEnvironments()
  if quarto.doc.is_format("html:js") then
    quarto.doc.add_html_dependency({
      name = "alpine",
      version = "3.12",
      scripts = {
        { path = "alpine.min.js", afterBody = "true" } },
    })
    quarto.doc.add_html_dependency({
      name = "sbs",
      version = "1",
      stylesheets = { "sbs.css" }
    })
  end
end

function RandomStringID(length)
  local res = ""
  for i = 1, length do
    res = res .. string.char(math.random(97, 122))
  end
  return res
end

function createStep(stepNumber, all, header, stepTable)
  table.insert(all, pandoc.RawBlock('html', [[
  <div x-show="currentStep === ]] .. stepNumber .. [[" x-transition >]]))
  table.insert(all, header)
  for i, el in ipairs(stepTable) do
    table.insert(all, el)
  end
  table.insert(all, pandoc.RawBlock("html", [[</div>]]))
end

function createSbs(div)
  writeEnvironments()        -- убеждаемся, что скрипты и стили добавлены в окружение
  local scrollId = RandomStringID(8)
  local tutorialContent = {} -- разметка всего туториала
  local currentStep = {}
  local currentHeader = nil
  local allSteps = {}

  local stepsCount = 0

  for i, el in ipairs(div.content) do
    if el.t == "Header" and currentHeader == nil then
      -- Сохраняем первый заголовок
      currentHeader = el
    elseif el.t == "Header" and el.level == 3 then
      -- Встретили очередной заголовок
      createStep(stepsCount, allSteps, currentHeader, currentStep)
      currentHeader = el
      currentStep = {}
      stepsCount = stepsCount + 1
    elseif el.t ~= "Header" and i == #div.content then
      -- Сохраняем разметку последнего шага
      table.insert(currentStep, el)
      createStep(stepsCount, allSteps, currentHeader, currentStep)
    else
      -- Сохраняем разметку одного шага
      table.insert(currentStep, el)
    end
  end

  table.insert(tutorialContent, pandoc.RawBlock("html", [[<div x-data="{
      currentStep: 0
    }">
  <div x-ref="]] .. scrollId .. [["></div>
]]))

  for i, el in ipairs(allSteps) do
    table.insert(tutorialContent, el)
  end

  table.insert(tutorialContent, pandoc.RawBlock("html", [[
      <div class="controls">
      <button
        x-on:click="
        currentStep--;
        $refs.]] .. scrollId .. [[.scrollIntoView({ behavior: 'smooth'})"
      >
        prev
      </button>
      <button
        x-on:click="
        currentStep++;
        $refs.]] .. scrollId .. [[.scrollIntoView({ behavior: 'smooth'})"
      >
        next
      </button>
    </div>
  </div>]]))

  return pandoc.Div(tutorialContent, { class = "sbs__ready" })
end

function createSbsAction(div)
  writeEnvironments() -- подключаем библиотеки и стили

  local labelId = RandomStringID(8)
  local actionContent = {}

  table.insert(actionContent, pandoc.RawBlock("html", [[<div
    class="sbs__action"
    x-data="{
      isCompleted: false
    }"
    x-on:reset-actions.window="isCompleted = false"
    >
  <div :class="isCompleted ? 'sbs__completed': ''" class="sbs__data">
]]))
  table.insert(actionContent, div)
  table.insert(actionContent, pandoc.RawBlock("html", [[
  </div>
    <div class="sbs__completion__container" style="text-align: right">
      <div class="checkbox-wrapper-19">
        <input type="checkbox" id="]] .. labelId .. [[" x-model="isCompleted"/>
        <label for="]] .. labelId .. [[" class="check-box">
      </div>
    </div>
</div>
]]))
  return pandoc.Div(actionContent)
end

function createSbsTask(div)
  writeEnvironments() -- подключаем библиотеки и стили

  local labelId = RandomStringID(8)
  local actionContent = {}

  table.insert(actionContent, pandoc.RawBlock("html", [[<div
    :class="isCompleted ? 'sbs__task__completed': ''"
    class="sbs__task"
    x-data="{
      isCompleted: false,
      get caption(){
        return this.isCompleted ? '👏 Сделано' : '✍️ Сделайте самостоятельно';
      }
    }"
    x-on:reset-actions.window="isCompleted = false"
    >
    <div class="badge__container">
        <span class="sbs__badge" x-text="caption"></span>
    </div>
]]))
  table.insert(actionContent, div)
  table.insert(actionContent, pandoc.RawBlock("html", [[
    <div class="sbs__completion__container" style="text-align: right">
      <div class="checkbox-wrapper-19">
        <input type="checkbox" id="]] .. labelId .. [[" x-model="isCompleted"/>
        <label for="]] .. labelId .. [[" class="check-box">
      </div>
    </div>
</div>
]]))
  return pandoc.Div(actionContent)
end

if quarto.doc.isFormat("html:js") then
  Div = function(div)
    if div.classes:includes("stepbystep") then -- если div содержит нужный стиль - обрабатываем разметку
      return createSbs(div)
    end

    if div.classes:includes("sbsaction") then -- если div содержит нужный стиль - обрабатываем разметку
      return createSbsAction(div)
    end

    if div.classes:includes("sbstask") then -- если div содержит нужный стиль - обрабатываем разметку
      return createSbsTask(div)
    end

    return nil
  end
end
