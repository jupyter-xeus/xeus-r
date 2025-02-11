#############################################################################
# Copyright (c) 2023, QuantStack
#
# Distributed under the terms of the GNU General Public License v3.
#
# The full license is in the file LICENSE, distributed with this software.
#############################################################################

import tempfile
import unittest
import jupyter_kernel_test

class KernelTests(jupyter_kernel_test.KernelTests):

    kernel_name = "xr"
    language_name = "R"

    code_hello_world = "cat('hello, world')"
    code_stderr = "message('error')"

    completion_samples = [
        {"text": "rnorm(",   "matches": {"n=", "mean=", "sd="}}
    ]
    code_execute_result = [
        {"code": "6*7"       , "result": ["[1] 42"]}, 
        {"code": "is_xeusr()", "result": ["[1] TRUE"]}
    ]
    #code_display_data = [
    #    {"code": "plot(0)", "mime": "image/png"}, 
    #    {"code": "ggplot2::ggplot(iris, ggplot2::aes(Sepal.Length, Sepal.Width)) + ggplot2::geom_point()", "mime": "image/png"}, 
    #    {"code": "View(head(iris))", "mime": "text/html"}
    #]
    
    # code_page_something = "?cat"
    code_clear_output = "clear_output()"
    code_generate_error = "stop('ouch')"
    code_inspect_sample = "print"
    
    complete_code_samples = ["fun()", "1 + 2", "a %>% b", "a |> b()", "a |> b(c = 1)"]
    incomplete_code_samples = ["fun(", "1 + "]
    invalid_code_samples = ["fun())", "a |> b", "a |> b(_)", "a |> b(c(_))"]

    def test_htmlwidget(self):
        self.flush_channels()
        reply, output_msgs = self.execute_helper(code="library('htmltools'); h1('hello')")
        data = output_msgs[0]['content']['data']
        self.assertEqual(len(data), 2, data.keys())
        self.assertIn("<html>", data["text/html"][0])
        self.assertIn("<h1>hello</h1>", data["text/html"][0])

#########################################################################################
#########################################################################################

if __name__ == "__main__":
    unittest.main()
