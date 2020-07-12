import json
import sys


class Helper:

    @staticmethod
    def exit(exit_code: int, message: str):
        print(message)
        sys.exit(exit_code)

    @staticmethod
    def json_to_object(string_to_convert: str):
        try:
            converted = json.loads(string_to_convert.replace('\n', ''))
            return converted
        except ValueError:
            print(string_to_convert)

    @staticmethod
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
