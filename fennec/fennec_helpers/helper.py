import json
import os
import sys
import subprocess
import shlex
from collections import namedtuple


class Helper:

    def exit(exit_code: int, message: str):
        print(message)
        sys.exit(exit_code)

    def json_to_object(string_to_convert: str):
        try:
            converted = json.loads(string_to_convert)
            return converted
        except:
            print(string_to_convert)

    def replace_in_file(source_file: str, output_file: str, strings_to_replace: dict, max=1):
        fin = open(source_file, "rt")
        fout = open(output_file, "wt")
        file_content = ""
        for line in fin:
            file_content += line
        for string_to_replace in strings_to_replace.keys():
            new_value = strings_to_replace[string_to_replace]
            file_content = file_content.replace(
                string_to_replace, new_value, max)
        fout.write(file_content)
        fin.close()
        fout.close()
        return file_content
