#!/usr/bin/env python3
"""Convert a Sentinel Ultra Hub tab's rendered innerHTML into the Markdown
convention used by the docs/ export.

Usage:  python3 html2md.py raw/glossary.html "Glossary" > out/glossary.md
"""

import re
import sys
from html.parser import HTMLParser

SOURCE_URL = "https://snorkel-ai.github.io/Sentinel_Ultra_Hub/"

# tab id (as used in href="#tab-<id>") -> exported file name
TAB_FILES = {
    "whatsnew": "whats-new.md",
    "guide": "guidelines.md",
    "tasking": "tasking-guide.md",
    "reviewer-rubric": "reviewer-rubric.md",
    "harbor": "harbor-framework.md",
    "glossary": "glossary.md",
    "faq": "faq.md",
    "quicklinks": "quick-links.md",
    "changelog": "changelog.md",
}

# tab label (as passed on the command line) -> tab id
LABEL_TABS = {
    "What's New": "whatsnew",
    "Guidelines": "guide",
    "Tasking Guide": "tasking",
    "Reviewer Rubric": "reviewer-rubric",
    "The Harbor Framework": "harbor",
    "Glossary": "glossary",
    "FAQ": "faq",
    "Quick Links": "quicklinks",
    "Changelog": "changelog",
}

VOID = {"img", "br", "hr", "input", "meta", "link", "source", "col", "area"}

# elements whose entire subtree is discarded
DROP = {"img", "svg"}

# --------------------------------------------------------------------------
# minimal DOM
# --------------------------------------------------------------------------

class Node:
    __slots__ = ("tag", "attrs", "children", "parent", "text")

    def __init__(self, tag, attrs=None, text=None, parent=None):
        self.tag = tag
        self.attrs = attrs or {}
        self.children = []
        self.parent = parent
        self.text = text

    def get(self, name, default=""):
        return self.attrs.get(name, default)

    def classes(self):
        return self.get("class", "").split()


class DOMBuilder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("#root")
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = Node(tag, dict(attrs), parent=self.stack[-1])
        self.stack[-1].children.append(node)
        if tag not in VOID:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        node = Node(tag, dict(attrs), parent=self.stack[-1])
        self.stack[-1].children.append(node)

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                return

    def handle_data(self, data):
        self.stack[-1].children.append(Node("#text", text=data, parent=self.stack[-1]))


def parse(html):
    b = DOMBuilder()
    b.feed(html)
    b.close()
    return b.root


# --------------------------------------------------------------------------
# inline rendering
# --------------------------------------------------------------------------

# Markdown-significant characters are escaped in ordinary prose. Text already
# sitting inside a Markdown construct (a code span, bold, italics) is left
# alone, because the construct already protects it.
def escape_text(text):
    """Escape Markdown-significant characters in a bare text node."""
    # A text node may itself contain literal backticks (content the site failed
    # to render as code). Those spans become code spans in the output, so what
    # is inside them needs no escaping.
    parts = re.split(r"(`+[^`]*`+)", text)
    for i in range(0, len(parts), 2):
        parts[i] = (parts[i].replace("[", r"\[")
                            .replace("]", r"\]")
                            .replace("*", r"\*"))
    out = "".join(parts)
    if out.startswith("-"):
        out = "\\" + out
    return out


# chunks are (protected, text); protected chunks skip whitespace collapsing
def inline_chunks(node, ctx, out, escapable=True):
    for ch in node.children:
        if ch.tag == "#text":
            out.append((False, escape_text(ch.text) if escapable else ch.text))
        elif ch.tag in DROP:
            continue
        elif ch.tag == "code":
            out.append((True, "`" + raw_text(ch) + "`"))
        elif ch.tag == "strong" or ch.tag == "b":
            out.append((True, "**"))
            inline_chunks(ch, ctx, out, escapable=False)
            out.append((True, "**"))
        elif ch.tag == "em" or ch.tag == "i":
            out.append((True, "*"))
            inline_chunks(ch, ctx, out, escapable=False)
            out.append((True, "*"))
        elif ch.tag == "a":
            href = rewrite_href(ch.get("href"), ctx)
            inner = []
            inline_chunks(ch, ctx, inner, escapable)
            label = collapse(inner)
            out.append((True, "[" + label + "](" + href + ")"))
        elif ch.tag == "br":
            out.append((True, "<br>" if ctx.get("in_table") else "\n"))
        else:
            inline_chunks(ch, ctx, out, escapable)


def raw_text(node):
    """Concatenated text of a subtree, entities already decoded."""
    if node.tag == "#text":
        return node.text
    if node.tag in DROP:
        return ""
    return "".join(raw_text(c) for c in node.children)


def collapse(chunks):
    """Join chunks, collapsing whitespace runs in unprotected text only."""
    parts = []
    for protected, text in chunks:
        if protected:
            parts.append(text)
        else:
            parts.append(re.sub(r"\s+", " ", text))
    s = "".join(parts)
    return s.strip()


def inline(node, ctx, escapable=True):
    out = []
    inline_chunks(node, ctx, out, escapable)
    return collapse(out)


def rewrite_href(href, ctx):
    if not href:
        return ""
    if href.startswith("#tab-"):
        rest = href[len("#tab-"):]
        if "::" in rest:
            tab, anchor = rest.split("::", 1)
        else:
            tab, anchor = rest, ""
        if tab == ctx["tab"]:
            return "#" + anchor if anchor else TAB_FILES.get(tab, "")
        target = TAB_FILES.get(tab, "")
        return target + ("#" + anchor if anchor else "")
    return href


# --------------------------------------------------------------------------
# block rendering
# --------------------------------------------------------------------------

HR = "* * *"


def blockquote(text, label):
    """Callout box: a blockquote whose first line carries a bold label.

    The box's own text sometimes opens with that same label in bold; keep it
    once rather than twice.
    """
    dup = "**%s:**" % label
    if text == dup:
        text = ""
    elif text.startswith(dup + " "):
        text = text[len(dup) + 1:]
    lines = text.split("\n")
    head = "> **%s:** %s" % (label, lines[0]) if lines[0] else "> **%s:**" % label
    return "\n".join([head] + [("> " + l if l else ">") for l in lines[1:]])


def heading(node, ctx, level):
    text = inline(node, ctx)
    anchor = node.get("id")
    if anchor:
        text += ' <a id="%s"></a>' % anchor
    return "#" * level + " " + text


def render_table(node, ctx):
    rows = []
    header = None
    for tr in iter_tags(node, "tr"):
        cells = []
        is_header = False
        for cell in tr.children:
            if cell.tag in ("th", "td"):
                if cell.tag == "th":
                    is_header = True
                ctx["in_table"] = True
                try:
                    cells.append(inline(cell, ctx))
                finally:
                    ctx["in_table"] = False
        if is_header and header is None:
            header = cells
        else:
            rows.append(cells)
    lines = []
    if header is None:
        header = rows.pop(0) if rows else []
    lines.append("| " + " | ".join(header) + " |")
    lines.append("| " + " | ".join(["---"] * len(header)) + " |")
    for r in rows:
        lines.append("| " + " | ".join(r) + " |")
    return "\n".join(lines)


def iter_tags(node, tag):
    for ch in node.children:
        if ch.tag == tag:
            yield ch
        elif ch.tag not in DROP and ch.tag != "#text":
            for x in iter_tags(ch, tag):
                yield x


def render_li(li, ctx):
    """Blocks of one <li>, each tagged with the kind of thing that produced it.

    The kind decides the blank lines: a paragraph-like block is surrounded by
    them, a nested list is not, and a bare run of inline content is not either.
    """
    out = []
    pending = []

    def flush():
        if pending:
            t = collapse(pending)
            del pending[:]
            if t:
                out.append((t, "inline"))

    for ch in li.children:
        if ch.tag in DROP:
            continue
        if ch.tag in ("ul", "ol"):
            flush()
            t = render_list(ch, ctx)
            if t:
                out.append((t, "list"))
        elif ch.tag in BLOCK_LEVEL:
            flush()
            for t in render_block(ch, ctx):
                if t:
                    out.append((t, "para"))
        else:
            inline_chunks(Wrapper(ch), ctx, pending)
    flush()
    return out


def render_list(node, ctx):
    ordered = node.tag == "ol"
    lines = []
    n = int(node.get("start") or 1) - 1
    for li in node.children:
        if li.tag != "li":
            continue
        n += 1
        # bullets are "-" + 3 spaces; ordered items are "N." + 2 spaces
        prefix = ("%d.  " % n) if ordered else "-   "
        cont = " " * len(prefix)
        pieces = render_li(li, ctx)
        if not pieces:
            lines.append(prefix.rstrip())
            continue
        for i, (text, kind) in enumerate(pieces):
            if i:
                # a blank line whenever a paragraph-like block is on either side
                if kind == "para" or pieces[i - 1][1] == "para":
                    lines.append("")
            body = text.split("\n")
            if i == 0:
                lines.append(prefix + body[0])
                body = body[1:]
            for bl in body:
                lines.append((cont + bl) if bl else "")
        if pieces[-1][1] == "para":
            lines.append("")
    return "\n".join(lines)


BLOCK_LEVEL = ("ul", "ol", "p", "pre", "table", "hr", "div", "section",
               "details", "header", "blockquote", "article", "aside", "main",
               "h1", "h2", "h3", "h4", "h5", "h6")


def render_children(node, ctx):
    """Blocks for a container's children, in source order.

    A run of inline children collapses into one block; every block-level
    child renders as its own block.
    """
    blocks = []
    pending = []

    def flush():
        if pending:
            s = collapse(pending)
            del pending[:]
            if s:
                blocks.append(s)

    for ch in node.children:
        if ch.tag in DROP:
            continue
        if ch.tag in BLOCK_LEVEL:
            flush()
            blocks.extend(render_block(ch, ctx))
        else:
            inline_chunks(Wrapper(ch), ctx, pending)
    flush()
    return [b for b in blocks if b != ""]


class Wrapper:
    """Adapts a single node so inline_chunks can process it as a child list."""
    def __init__(self, node):
        self.children = [node]


def render_pre(node, ctx):
    code = node
    for ch in node.children:
        if ch.tag == "code":
            code = ch
            break
    text = raw_text(code)
    text = text.strip("\n")
    text = re.sub(r"[ \t]+$", "", text, flags=re.M)
    lang = ""
    for c in code.classes():
        if c.startswith("language-"):
            lang = c[len("language-"):]
    return "```" + lang + "\n" + text + "\n```"


def find_class(node, cls):
    """First descendant carrying the given class."""
    for ch in node.children:
        if ch.tag == "#text":
            continue
        if cls in ch.classes():
            return ch
        found = find_class(ch, cls)
        if found is not None:
            return found
    return None


def render_quicklinks(node, ctx):
    """div.quicklink-list -> a tight bullet list of "[title](href) — desc"."""
    lines = []
    for card in node.children:
        if card.tag != "a":
            continue
        title = find_class(card, "quicklink-title")
        desc = find_class(card, "quicklink-desc")
        label = inline(title, ctx) if title is not None else ""
        item = "[" + label + "](" + rewrite_href(card.get("href"), ctx) + ")"
        if desc is not None:
            item += " — " + inline(desc, ctx)
        lines.append("- " + item)
    return "\n".join(lines)


def render_block(node, ctx):
    """Return a list of markdown blocks for one element."""
    tag = node.tag
    cls = node.classes()

    if tag in DROP or tag == "#text":
        return []

    if tag == "header":
        return render_children(node, ctx)

    if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
        return [heading(node, ctx, int(tag[1]))]

    if tag == "p":
        text = inline(node, ctx)
        if not text:
            return []
        if "note" in cls:
            return [blockquote(text, "Note")]
        return [text]

    if tag == "table":
        return [render_table(node, ctx)]

    if tag in ("ul", "ol"):
        s = render_list(node, ctx)
        return [s] if s else []

    if tag == "pre":
        return [render_pre(node, ctx)]

    if tag == "hr":
        return [HR]

    if tag == "details":
        blocks = []
        for ch in node.children:
            if ch.tag == "summary":
                text = inline(ch, ctx)
                anchor = node.get("id")
                if anchor:
                    text += ' <a id="%s"></a>' % anchor
                blocks.append("#### " + text)
            elif ch.tag not in DROP:
                blocks.extend(render_block(ch, ctx))
        return blocks

    if tag == "div" and "quicklink-list" in cls:
        return [render_quicklinks(node, ctx)]

    if tag in ("div", "section", "details", "main", "article", "aside"):
        return render_children(node, ctx)

    # unknown / inline-ish element sitting at block level
    text = inline(Wrapper(node), ctx)
    return [text] if text else []


def convert(html, label):
    tab = LABEL_TABS[label]
    ctx = {"tab": tab}
    root = parse(html)
    blocks = render_children(root, ctx)
    head = "<!-- Source: %s — tab: %s -->" % (SOURCE_URL, label)
    doc = head + "\n\n" + "\n\n".join(blocks)
    return doc.rstrip() + "\n"


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: html2md.py <tab.html> <Tab Label>")
    path, label = sys.argv[1], sys.argv[2]
    if label not in LABEL_TABS:
        sys.exit("unknown tab label %r; expected one of: %s"
                 % (label, ", ".join(sorted(LABEL_TABS))))
    with open(path, encoding="utf-8") as fh:
        html = fh.read()
    sys.stdout.write(convert(html, label))


if __name__ == "__main__":
    main()
