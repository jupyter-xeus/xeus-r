#############################################################################
# Copyright (c) 2023, QuantStack
#
# Distributed under the terms of the GNU General Public License v3.
#
# The full license is in the file LICENSE, distributed with this software.
#############################################################################

import os
import shutil
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
        {"code": "6*7"       , "result": "[1] 42"},
        {"code": "is_xeusr()", "result": "[1] TRUE"}
    ]
    code_display_data = [
        {"code": "plot(0)", "mime": "image/png"}, 
        {"code": "ggplot2::ggplot(iris, ggplot2::aes(Sepal.Length, Sepal.Width)) + ggplot2::geom_point()", "mime": "image/png"}, 
        {"code": "View(head(iris))", "mime": "text/html"}
    ]
    
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
        self.assertIn("<html>", data["text/html"])
        self.assertIn("<h1>hello</h1>", data["text/html"])


class StartupProfileTests(jupyter_kernel_test.KernelTests):
    """The kernel must source R's startup profiles in the documented order:
    the site profile (Rprofile.site) first, then the user profile (.Rprofile),
    so the user profile overrides the site profile."""

    kernel_name = "xr"
    language_name = "R"

    @classmethod
    def setUpClass(cls):
        cls._profile_dir = tempfile.mkdtemp()
        site = os.path.join(cls._profile_dir, "Rprofile.site")
        user = os.path.join(cls._profile_dir, ".Rprofile")
        # The site profile sets two options; the user profile overrides only
        # one of them. A correct load therefore leaves the untouched option at
        # its site value, which proves *both* files were sourced.
        with open(site, "w") as fh:
            fh.write('options(xeusr.startup.a = "site-a", xeusr.startup.b = "site-b")\n')
        with open(user, "w") as fh:
            fh.write('options(xeusr.startup.a = "user-a")\n')
        os.environ["R_PROFILE"] = site
        os.environ["R_PROFILE_USER"] = user
        super().setUpClass()

    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        for var in ("R_PROFILE", "R_PROFILE_USER"):
            os.environ.pop(var, None)
        shutil.rmtree(cls._profile_dir, ignore_errors=True)

    def test_startup_profiles_loaded_in_order(self):
        self.flush_channels()
        reply, output_msgs = self.execute_helper(
            code='cat(getOption("xeusr.startup.a", "<unset>"),'
                 ' getOption("xeusr.startup.b", "<unset>"))')
        out = "".join(m["content"]["text"] for m in output_msgs
                      if m.get("msg_type") == "stream")
        # "site-b" proves Rprofile.site was sourced (only it sets b); "user-a"
        # proves .Rprofile was sourced and overrides the site value. Under
        # --vanilla both would be "<unset>".
        self.assertEqual(out, "user-a site-b")

#########################################################################################
#########################################################################################

if __name__ == "__main__":
    unittest.main()
