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

    def _execute_code(self, code, tests=True, silent=False, store_history=True):
        self.flush_channels()

        reply, output_msgs = self.execute_helper(code, silent=silent, store_history=store_history)

        self.assertEqual(reply['content']['status'], 'ok', '{0}: {0}'.format(reply['content'].get('ename'), reply['content'].get('evalue')))
        if tests:
            self.assertGreaterEqual(len(output_msgs), 1)
            # xeusr does the same as irkernel: only sends display_data, not execute_result
            self.assertEqual(output_msgs[0]['msg_type'], 'display_data')
        return reply, output_msgs

    code_hello_world = "cat('hello, world')"
    completion_samples = [{"text": "H", "matches": {"Hello", "Hey", "Howdy"}}]
    code_execute_result = [{"code": "6*7", "result": "[1] 42"}]
    
    # code_page_something = "?cat"
    # code_inspect_sample = "print"

    complete_code_samples = ["fun()", "1 + 2", "a %>% b", "a |> b()", "a |> b(c = _)"]
    incomplete_code_samples = ["fun(", "1 + "]
    invalid_code_samples = ["fun())"]

    def test_stdout(self):
        self.flush_channels()
        reply, output_msgs = self.execute_helper(code="cat('hello, world')")
        self.assertEqual(output_msgs[0]["msg_type"], "stream")
        self.assertEqual(output_msgs[0]["content"]["name"], "stdout")
        self.assertEqual(output_msgs[0]["content"]["text"], "hello, world")

    def test_execute_result(self):
        self.flush_channels()
        reply, output_msgs = self._execute_code(code="6*7")
        data = output_msgs[0]['content']['data']
        self.assertEqual(data['text/plain'], ['[1] 42'])

    #def test_stderr(self):
        #self.flush_channels()
        #reply, output_msgs = self.execute_helper(code="error")
        #self.assertEqual(output_msgs[0]["msg_type"], "stream")
        #self.assertEqual(output_msgs[0]["content"]["name"], "stderr")

#########################################################################################
#########################################################################################

if __name__ == "__main__":
    unittest.main()
