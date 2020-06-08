// doc.vala
// Copyright (c) 2020 Christopher White.  All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

/**
 * A document to be rendered.
 *
 * This class holds the contents of a parsed document.
 */
public class Doc {
    /**
     * The document
     */
    public GenericArray<unowned Snapd.MarkdownNode> content;

    /**
     * Basic constructor
     * @param document The new document to store
     */
    public Doc(GenericArray<unowned Snapd.MarkdownNode> document)
    {
        content = document;
    }

    /**
     * Return a string representation of Doc.content
     */
    public string as_string()
    {
        if(content == null) return "";
        if(content.length == 0) return "";
        var sb = new StringBuilder();
        sb.append_printf("Document with %d nodes:\n", content.length);
        content.foreach( (node)=>{ dump_node(sb, node, "  "); });
        return sb.str;
    } // as_string

    private static void dump_node(StringBuilder sb, Snapd.MarkdownNode node, string indent = "")
    {
        sb.append_printf("%sNode: type %s, text -%s-\n",
                         indent, node.get_node_type().to_string(), node.get_text());
        var kids = node.get_children();
        if(kids != null) {
            kids.foreach( (kid)=>{ dump_node(sb, kid, indent+"  "); });
        }
    }

}

