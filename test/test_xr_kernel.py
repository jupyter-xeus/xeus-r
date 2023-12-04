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
    completion_samples = [{"text": "H", "matches": {"Hello", "Hey", "Howdy"}}]
    code_execute_result = [{"code": "6*7", "result": ["[1] 42"]}]
    
    # code_page_something = "?cat"
    # code_inspect_sample = "print"

    complete_code_samples = ["fun()", "1 + 2", "a %>% b", "a |> b()", "a |> b(c = _)"]
    incomplete_code_samples = ["fun(", "1 + "]
    invalid_code_samples = ["fun())", "a |> b", "a |> b(_)", "a |> b(c(_))"]

    def test_stdout(self):
        self.flush_channels()
        reply, output_msgs = self.execute_helper(code="cat('hello, world')")
        self.assertEqual(output_msgs[0]["msg_type"], "stream")
        self.assertEqual(output_msgs[0]["content"]["name"], "stdout")
        self.assertEqual(output_msgs[0]["content"]["text"], "hello, world")

    def test_stderr(self):
        self.flush_channels()
        reply, output_msgs = self.execute_helper(code="message('error')")
        self.assertEqual(output_msgs[0]["msg_type"], "stream")
        self.assertEqual(output_msgs[0]["content"]["name"], "stderr")

#########################################################################################
#########################################################################################

if __name__ == "__main__":
    unittest.main()
