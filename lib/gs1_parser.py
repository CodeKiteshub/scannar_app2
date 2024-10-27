from enum import Enum
import re
import time

# Group separator characters
SEPARATORS = [chr(23), chr(29), chr(30), "\GS", "\RS", "\ETB", "{GS}", "<GS>", "↔", "FNC1", "\F", "/F"]
SINGLE_CODES = ['EAN', 'UPCA']


class AIType(Enum):
    SERIAL_NUMBER_AI = "21"
    LOT_NUMBER_AI = "10"
    EXPR_DATE_AI = "17"
    GTIN_AI = "01"
    QTY_AI = "30"
    SSCC_AI = "00"
    GLN_AI = "414"


AI_LIST = {
    "21": {"fixedLength": False, "maxLength": 20},
    "10": {"fixedLength": False, "maxLength": 20},
    "30": {"fixedLength": False, "maxLength": 8},
    "17": {"fixedLength": True, "maxLength": 6},
    "01": {"fixedLength": True, "maxLength": 14},
    "00": {"fixedLength": True, "maxLength": 18},
    "02": {"fixedLength": True, "maxLength": 14},
    "03": {"fixedLength": True, "maxLength": 14},
    "04": {"fixedLength": True, "maxLength": 16},
    "11": {"fixedLength": True, "maxLength": 6},
    "12": {"fixedLength": True, "maxLength": 6},
    "13": {"fixedLength": True, "maxLength": 6},
    "14": {"fixedLength": True, "maxLength": 6},
    "15": {"fixedLength": True, "maxLength": 6},
    "16": {"fixedLength": True, "maxLength": 6},
    "18": {"fixedLength": True, "maxLength": 6},
    "19": {"fixedLength": True, "maxLength": 6},
    "20": {"fixedLength": True, "maxLength": 2},
    "31": {"fixedLength": True, "maxLength": 8},
    "32": {"fixedLength": True, "maxLength": 8},
    "33": {"fixedLength": True, "maxLength": 8},
    "34": {"fixedLength": True, "maxLength": 8},
    "35": {"fixedLength": True, "maxLength": 8},
    "36": {"fixedLength": True, "maxLength": 8},
    "414": {"fixedLength": True, "maxLength": 11},
}

ILPN_PATTERN_LIST = [
    "0190",
    "0191",
    "0192",
    "0193",
    "0194",
    "0195",
    "0196",
    "0197",
    "0198",
    "0199",
]
GLN_PATTERN_LIST = [
    "414"
]


class BarcodeDetails:
    def __init__(self):
        self.tempSerial = None
        self.tempLot = None
        self.tempExp = None
        self.tempNDC = None
        self.tempGTIN = None
        self.tempQTY = None
        self.tempSSCC = None
        self.tempGLN = None
        self.expDateCheck = None
        self.isExpValid = None


class GS1DataParser:
    def parse(self, barcode, barcode_format=""):
        barcode = barcode.strip()
        isGroupSeparatorAvailable = False
        isBuggyCodeWithoutGs = False
        barcode = self.convert_barcode_escape_sequences(barcode)

        # Check if barcode is in HRI format
        if '(' in barcode and ')' in barcode:
            return self.parse_hri(barcode)

        parsed_data = {
            "gtin": None,
            "lot": None,
            "serial": None,
            "expiry": None,
            "qty": None,
            "lpnNumber": None,
            "gln": None,
        }

        if barcode_format:
            found_single_code = False
            for f in SINGLE_CODES:
                print("Parser", barcode_format, f)
                if str(barcode_format).find(f) != -1:
                    parsed_data['gtin'] = barcode
                    found_single_code = True
                    break
            if found_single_code:
                return parsed_data

        # Initial check for ILPN number
        if barcode[:4] in ILPN_PATTERN_LIST:
            parsed_data["lpnNumber"] = barcode
            return parsed_data

        # GLN number
        if barcode[:3] in GLN_PATTERN_LIST:
            parsed_data["gln"] = barcode
            return parsed_data

        barcode_details = BarcodeDetails()
        parse_cursor = 0
        try:
            while parse_cursor < len(barcode) - 2:
                if barcode[parse_cursor] in SEPARATORS:
                    parse_cursor += 1

                if parse_cursor > len(barcode) - 2:
                    break

                ai = barcode[parse_cursor: parse_cursor + 2]
                if ai in AI_LIST.keys():
                    parse_cursor += 2
                    bt = AI_LIST[ai]
                    if bt["fixedLength"]:
                        if len(barcode) >= (parse_cursor + bt["maxLength"]):
                            value = barcode[parse_cursor: parse_cursor + bt["maxLength"]]
                            parse_cursor += bt["maxLength"]

                            # Find the maximum separator length
                            max_sep_length = max(len(sep) for sep in SEPARATORS)

                            # Look for a separator in the characters immediately following the fixed length value
                            next_chars = barcode[
                                         parse_cursor: parse_cursor + max_sep_length
                                         ]

                            for sep in SEPARATORS:
                                if next_chars.startswith(sep):
                                    parse_cursor += len(sep)
                                    isGroupSeparatorAvailable = True
                                    break
                        else:
                            break
                    else:
                        length = bt["maxLength"]
                        value = barcode[parse_cursor:]
                        separator_lengths = [len(sep) for sep in SEPARATORS if sep in value]
                        if separator_lengths:
                            length = min(
                                value.index(sep) for sep in SEPARATORS if sep in value
                            )
                            value = value[:length]
                            separator_length = min(separator_lengths)
                            parse_cursor += length + separator_length
                            isGroupSeparatorAvailable = True
                        else:

                            if not isGroupSeparatorAvailable:
                                # isBuggyCodeWithoutGs = True
                                print("Code without GS")
                                break
                            else:
                                parse_cursor += length

                    if ai == AIType.SERIAL_NUMBER_AI.value:
                        barcode_details.tempSerial = value
                    elif ai == AIType.LOT_NUMBER_AI.value:
                        barcode_details.tempLot = value
                    elif ai == AIType.EXPR_DATE_AI.value:
                        barcode_details.tempExp = value
                        # add the logic for date validation
                    elif ai == AIType.GTIN_AI.value:
                        barcode_details.tempNDC = value[3:13]
                        barcode_details.tempGTIN = value
                    elif ai == AIType.QTY_AI.value:
                        barcode_details.tempQTY = value
                    elif ai == AIType.SSCC_AI.value:
                        barcode_details.tempSSCC = value
                else:
                    length = len(barcode) - parse_cursor
                    value = barcode[parse_cursor: parse_cursor + length]
                    if any(sep in value for sep in SEPARATORS):
                        length = min(value.index(sep) for sep in SEPARATORS if sep in value)
                        value = value[:length]
                        parse_cursor += length + 1
                    else:
                        parse_cursor += length
        except Exception as ex:
            print("Exception in parsing", ex)
        if not isBuggyCodeWithoutGs:
            parsed_data["gtin"] = barcode_details.tempGTIN
            parsed_data["lot"] = barcode_details.tempLot
            parsed_data["serial"] = barcode_details.tempSerial
            parsed_data["expiry"] = barcode_details.tempExp
            parsed_data["lpnNumber"] = barcode_details.tempSSCC
            parsed_data["qty"] = barcode_details.tempQTY
        else:
            parsed_data = self.getParsedDataFromCodeWithoutGS(barcode)

        if parsed_data.get("lpnNumber", None):
            parsed_data["lpnNumber"] = f'00{parsed_data["lpnNumber"]}'
        return parsed_data

    def parse_hri(self, barcode):
        parsed_data = {
            "gtin": None,
            "lot": None,
            "serial": None,
            "expiry": None,
            "qty": None,
            "lpnNumber": None,
        }

        # Split barcode elements based on brackets
        barcode_elements = barcode.split('(')

        for element in barcode_elements[1:]:  # Skip the first element as it will be empty
            ai, value = 'NA', 0
            # print("ai, value", ai, value)
            if element.split(')').__len__() == 2:
                ai, value = element.split(')')
            # Assigning value to parsed_data based on AI
            if ai == '01':
                parsed_data["gtin"] = value
            elif ai == '21':
                parsed_data["serial"] = value
            elif ai == '17':
                parsed_data["expiry"] = value
            elif ai == '10':
                parsed_data["lot"] = value
            elif ai == '30':
                parsed_data["qty"] = value
            elif ai == '00':
                parsed_data["lpnNumber"] = value
            # Add more elif statements for other AIs as needed

        # print("After HRI Parsing", parsed_data)
        return parsed_data

    def getParsedDataFromCodeWithoutGS(self, barcode):
        parsed_data = {
            "gtin": None,
            "lot": None,
            "serial": None,
            "expiry": None,
            "qty": None,
            "lpnNumber": None,
        }
        found_ais = []
        barcode_details = BarcodeDetails()
        parse_cursor = 0
        while parse_cursor < len(barcode) - 2:

            if parse_cursor > len(barcode) - 2:
                break

            ai = barcode[parse_cursor: parse_cursor + 2]
            # print("AI In Buggy Code", ai)
            if ai in AI_LIST.keys():
                parse_cursor += 2
                bt = AI_LIST[ai]
                if bt["fixedLength"]:
                    if len(barcode) >= (parse_cursor + bt["maxLength"]):
                        value = barcode[parse_cursor: parse_cursor + bt["maxLength"]]
                        parse_cursor += bt["maxLength"]
                    else:
                        break

                else:
                    tracking_ai_list = [AIType.SERIAL_NUMBER_AI.value, AIType.LOT_NUMBER_AI.value,
                                        AIType.EXPR_DATE_AI.value, AIType.GTIN_AI.value, AIType.QTY_AI.value]
                    value = barcode[parse_cursor:]
                    variable_cursor = parse_cursor
                    # print("Variable Length AI Found In Buggy Code", value)
                    current_ai_value = ""
                    ai_at_index = 0
                    for i in range(0, len(value), 2):
                        potential_ai = value[i:i + 2]
                        variable_cursor += 2
                        ai_at_index += 2
                        # print("Potential AIs", potential_ai, "Variable Cursor", variable_cursor, "I", i)
                        if potential_ai in tracking_ai_list and potential_ai not in found_ais and ai_at_index > 6:
                            # print("potential_ai Correct", value)
                            pai = AI_LIST[potential_ai]
                            if pai["fixedLength"]:
                                # print("PAI is fixed", pai["fixedLength"])
                                search_cursor = i + 2
                                # print("search", search_cursor)
                                # Check if there are enough characters for the fixed length AI
                                if len(value) >= (search_cursor + pai["maxLength"]):
                                    potential_value_1 = value[search_cursor:search_cursor + pai["maxLength"]]
                                    # print("potential_value_1", potential_value_1)
                                    # Check if the potential AI is followed by another valid AI or the end of the string
                                    remaining = value[search_cursor + pai["maxLength"]:]
                                    # print("PAI is fixed remaining", remaining)
                                    # if not self.validate_potential_ai_value(potential_value_1, potential_ai):
                                    #     continue
                                    if (remaining == '' or any(remaining.startswith(ai) for ai in AI_LIST.keys())):
                                        if remaining.startswith(potential_ai):
                                            continue
                                        # value = value[0:search_cursor+1]
                                        value = current_ai_value
                                        parse_cursor = variable_cursor - 2
                                        variable_cursor = 0
                                        current_ai_value = ""
                                        break
                                    # else:
                                    #     current_ai_value += value[i:i+2]
                                    #     print("Current AI Value", current_ai_value)
                                    # # Start Second Ocurrence Search
                                    # for j in range(search_cursor, len(remaining), 2):
                                    #     potential_ai_2 = value[j:j+2]
                                    #     print("Searching 2nd Occurence Of Potential AIs", potential_ai_2)
                                    #     if potential_ai_2 == potential_ai:
                                    #         second_search_cursor = j+2
                                    #         print("Found 2nd Occurence Of ", potential_ai)
                                    #         if len(remaining) >= (second_search_cursor + pai["maxLength"]):
                                    #             potential_value_2 = value[second_search_cursor:second_search_cursor+pai["maxLength"]]
                                    #             print("potential_value_2", potential_value_2)
                                    #             if(len(potential_value_2) == pai["maxLength"] and remaining[j:j+2] in AI_LIST.keys()): 
                                    #                 print("Second ONe is also valid")
                                    #             else: print("Second ONe is invalid")
                                current_ai_value += value[i:i + 2]
                            else:
                                # The potential AI is variable length, handle it accordingly
                                # You will need to add your logic here to handle variable length AIs
                                print("variable length potential AI found", potential_ai)
                                # check if one more 10 exists and find the last 10 fo
                                current_ai_value += value[i:i + 2]
                                continue
                        else:
                            current_ai_value += value[i:i + 2]
                            # print("Current AI Value", current_ai_value)
                            # print("Length in else", i, len(value), variable_cursor, parse_cursor, len(barcode))
                            if (i == len(value) - 1 or i == len(value) - 2):
                                value = value[0:len(value) + 1]
                                parse_cursor = variable_cursor
                                break

                if ai == AIType.SERIAL_NUMBER_AI.value:
                    barcode_details.tempSerial = value
                    found_ais.append(AIType.SERIAL_NUMBER_AI.value)
                elif ai == AIType.LOT_NUMBER_AI.value:
                    barcode_details.tempLot = value
                    found_ais.append(AIType.LOT_NUMBER_AI.value)
                elif ai == AIType.EXPR_DATE_AI.value:
                    barcode_details.tempExp = value
                    found_ais.append(AIType.EXPR_DATE_AI.value)
                    # add the logic for date validation
                elif ai == AIType.GTIN_AI.value:
                    barcode_details.tempNDC = value[3:13]
                    barcode_details.tempGTIN = value
                    found_ais.append(AIType.GTIN_AI.value)
                elif ai == AIType.QTY_AI.value:
                    barcode_details.tempQTY = value
                    found_ais.append(AIType.QTY_AI.value)
                elif ai == AIType.SSCC_AI.value:
                    barcode_details.tempSSCC = value
                    found_ais.append(AIType.SSCC_AI.value)

            # time.sleep(5)

        parsed_data["gtin"] = barcode_details.tempGTIN
        parsed_data["lot"] = barcode_details.tempLot
        parsed_data["serial"] = barcode_details.tempSerial
        parsed_data["expiry"] = barcode_details.tempExp
        parsed_data["lpnNumber"] = barcode_details.tempSSCC
        parsed_data["qty"] = barcode_details.tempQTY
        # print("parsed_data In Buggy Code", parsed_data)
        return parsed_data

    def validate_potential_ai_value(self, potential_value_1, potential_ai):
        if potential_ai == AIType.EXPR_DATE_AI.value:
            # Check the data is valid
            return True
        else:
            return True

    def convert_escape_sequences(self, string):
        if string.startswith("\\x"):
            return bytes.fromhex(string[2:]).decode("utf-8")
        else:
            return string

    def convert_barcode_escape_sequences(self, barcode):
        # Find all escape sequences in the barcode
        escape_sequences = re.findall(r"\\x..", barcode)

        # Replace each escape sequence with its actual control character
        for seq in escape_sequences:
            barcode = barcode.replace(seq, self.convert_escape_sequences(seq))

        return barcode


def main():
    parser = GS1DataParser()
    with open("sample_barcodes.txt", "r", encoding="utf8") as f:
        barcodes = f.readlines()

    for barcode in barcodes:
        print("barcode Found", barcode)
        print("parsed COde", parser.parse(barcode))


if __name__ == "__main__":
    main()
