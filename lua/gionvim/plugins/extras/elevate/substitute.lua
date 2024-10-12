return {

    {
        "chrisgrieser/nvim-rip-substitute",
        lazy = true,
        cmd = "RipSubstitute",
        keys = {
            {
                "<leader>sr",
                function()
                    require("rip-substitute").sub()
                end,
                mode = { "n", "x" },
                desc = " rip substitute",
            },
        },
        dependencies = { "dressing.nvim" },
    },
}
