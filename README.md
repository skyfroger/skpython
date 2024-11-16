# SkPython

## Установка

```bash
quarto add skyfroger/skpython
```

## Применение

Чтобы блок с Python-кодом стал интерактивным нужно в качестве типа указать `sk-python`:

````markdown
```sk-python
for letter in "Привет, мир":
    print(letter)
```
````

Код внутри такого блока будет помещён внутрь среды разработки.
