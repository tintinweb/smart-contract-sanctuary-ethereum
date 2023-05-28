/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity ^0.8.17;

contract StringEscape {



   // This is the range when control characters stop in unicode
   uint8 constant CONTROL_CHAR_RANGE = 0x001F;
/*
    Backspace to be replaced with \b

    Form feed to be replaced with \f

    Newline to be replaced with \n

    Carriage return to be replaced with \r

    Tab to be replaced with \t

    Double quote to be replaced with \"

    Backslash to be replaced with \\

*/

    
    uint8 constant BACKSPACE = 0x08;
    uint8 constant FORM_FEED = 0x09;
    uint8 constant NEW_LINE = 0x0A;
    uint8 constant TAB = 0x0C;
    uint8 constant CARRIAGE_RETURN = 0x0D;


    /* These are non control characters that need to be escaped */
    uint8 constant BACK_SLASH = 0x005C; // '\'
    uint8 constant FORWARD_SLASH = 0x002F; // '/'
    uint8 constant QUOTE_CHAR = 0x0021; // '"'


    function _escapeString(string memory str) internal pure returns (string memory) {
        bytes memory convertedStr = bytes(str);
        // string[4] memory escapeChars = ['"', '<', '>', '\\'];
        string memory newStr = "";
        for ( uint pos = 0; pos < convertedStr.length; pos++  ) {
                uint8 char = uint8(convertedStr[pos]);
                bytes memory x;
                // newStr = string.concat("");
                            /* BACKSPACE */
                            // case 0x08 { x := "\\b"  }
                            // /* TAB */
                            // case 0x09 { x := "\\t " }
                            // /* LINE FEED */
                            // case 0x0A { x := "\\n" }
                            // /* FORM FEED */
                            // case 0x0C { x := "\\f" }
                            // /* CARRIAGE RETURN */
                            // case 0x0D { x := "\\r" }

                            // case 0x5C { x := "\\"  }
                            // case 0x2F { x := "\\/" }
                            // case 0x21 { x := "\"" }
                            // default   { x := char }    

                if (char == BACKSPACE) {
                    x = "\\b";
                } else if (char == TAB) {
                    x = "\\t";
                } else if (char == NEW_LINE) {
                     x = "\\n";
                } else if(char == FORM_FEED) {
                    x = "\\f";
                } else if (char == CARRIAGE_RETURN) {
                    x = "\\r";
                } else if (char == BACK_SLASH) {
                    x = "\\";
                } else if (char == FORWARD_SLASH) {
                    x = "\\/";
                } else if (char == QUOTE_CHAR) {
                    x = "\"";
                } else {
                    x = abi.encodePacked(convertedStr[pos]);
                }          
                    
                

                newStr = string.concat(newStr, string(x));
        }

        return newStr;
    } 

    function encodeTest(string memory str) external pure returns (string memory) {
        return string(abi.encodePacked('{"description":', '"', _escapeString(str), '"', '}'));
    }
}