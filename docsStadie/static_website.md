# HTML Beginner Notes

## 1. `<!DOCTYPE html>`

This tells the browser:

> This document uses HTML5.

It is called the **DOCTYPE declaration**.

```html
<!DOCTYPE html>
```

It is **not an HTML tag**. It tells the browser to use modern HTML standards.

---

## 2. `<html lang="en">`

This starts the main HTML document.

```html
<html lang="en">
```

- `<html>` → tells the browser that everything inside belongs to the HTML document.
- `lang="en"` → tells the browser that the page's language is **English**.
- `en` means English.

For example:

```html
<html lang="fr">
```

indicates that the page is in French.

The HTML document ends later with:

```html
</html>
```

You can think of it like this:

```html
<html>
    Everything on your webpage
</html>
```

---

## 3. `<head>`

```html
<head>
```

The `<head>` contains **information about the webpage**, rather than the content you normally see on the page.

For example, it can contain:

- Page title
- Character encoding
- CSS
- Links to fonts
- Metadata
- JavaScript files

The head ends with:

```html
</head>
```

---

## 4. `<meta charset="UTF-8">`

```html
<meta charset="UTF-8">
```

This tells the browser which **character encoding** to use.

`UTF-8` is a standard encoding that allows your page to display many characters correctly, including:

```text
Hello
é
€
©
你好
مرحبا
😀
```

Without the correct character encoding, some characters can appear incorrectly.

---

## Putting Everything Together

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
</head>

</html>
```

In simple terms:

| Code | Meaning |
|---|---|
| `<!DOCTYPE html>` | This is HTML5 |
| `<html lang="en">` | Start the HTML document; language is English |
| `<head>` | Start the page's information/settings |
| `<meta charset="UTF-8">` | Use UTF-8 characters |

### Simple Idea

Think of the beginning of an HTML file as **giving instructions to the browser before showing the actual webpage**.
