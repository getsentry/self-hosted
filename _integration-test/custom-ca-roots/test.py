import unittest
import requests


class CustomCATests(unittest.TestCase):
    def test_valid_self_signed(self):
        self.assertEqual(requests.get("https://self.test").text, 'ok')

    def test_invalid_self_signed(self):
        with self.assertRaises(requests.exceptions.SSLError):
            requests.get("https://fail.test")


if __name__ == '__main__':
    unittest.main()
