// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "./ERC721.sol";
import "./base64.sol";
// import "./string.sol";

    

contract NFT{

    struct morse_stuct{
        string morse_code;
        bool is_exist;
    } 

    // string a = Base64.encode('<svg width="794" height="488" xmlns="http://www.w3.org/2000/svg"><rect id="svg_11" height="794" width="488" y="0" x="0" fill="hsl(293,50%,25%)"/><text font-size="18" y="10%" x="5%" fill="hsl(90,100%,80%)">Some Text</text><text font-size="18" y="15%" x="5%" fill="hsl(90,100%,80%)">Some Text</text><text font-size="18" y="20%" x="5%" fill="hsl(90,100%,80%)">wo shi tian cai</text><text font-size="18" y="10%" x="80%" fill="hsl(90,100%,80%)">Token: 1</text><text font-size="18" y="50%" x="50%" text-anchor="middle" fill="hsl(90,100%,80%)">userText</text></svg>');
    mapping(string => morse_stuct) morse_code_dictionary;

    
    constructor(){
        morse_code_dictionary["a"].morse_code = "01";
        morse_code_dictionary["b"].morse_code = "1000";
        morse_code_dictionary["c"].morse_code = "1010";
        morse_code_dictionary["d"].morse_code = "100";
        morse_code_dictionary["e"].morse_code = "0";
        morse_code_dictionary["f"].morse_code = "0010";
        morse_code_dictionary["g"].morse_code = "110";
        morse_code_dictionary["h"].morse_code = "0000";
        morse_code_dictionary["i"].morse_code = "00";
        morse_code_dictionary["j"].morse_code = "0111";
        morse_code_dictionary["k"].morse_code = "101";
        morse_code_dictionary["l"].morse_code = "0100";
        morse_code_dictionary["n"].morse_code = "11";
        morse_code_dictionary["m"].morse_code = "10";
        morse_code_dictionary["o"].morse_code = "111";
        morse_code_dictionary["p"].morse_code = "0110";
        morse_code_dictionary["q"].morse_code = "1101";
        morse_code_dictionary["r"].morse_code = "010";
        morse_code_dictionary["s"].morse_code = "000";
        morse_code_dictionary["t"].morse_code = "1";
        morse_code_dictionary["u"].morse_code = "001";
        morse_code_dictionary["v"].morse_code = "0001";
        morse_code_dictionary["w"].morse_code = "011";
        morse_code_dictionary["s"].morse_code = "1001";
        morse_code_dictionary["y"].morse_code = "1011";
        morse_code_dictionary["z"].morse_code = "1100";

        morse_code_dictionary["a"].is_exist = true;
        morse_code_dictionary["b"].is_exist = true;
        morse_code_dictionary["c"].is_exist = true;
        morse_code_dictionary["d"].is_exist = true;
        morse_code_dictionary["e"].is_exist = true;
        morse_code_dictionary["f"].is_exist = true;
        morse_code_dictionary["g"].is_exist = true;
        morse_code_dictionary["h"].is_exist = true;
        morse_code_dictionary["i"].is_exist = true;
        morse_code_dictionary["j"].is_exist = true;
        morse_code_dictionary["k"].is_exist = true;
        morse_code_dictionary["l"].is_exist = true;
        morse_code_dictionary["n"].is_exist = true;
        morse_code_dictionary["m"].is_exist = true;
        morse_code_dictionary["o"].is_exist = true;
        morse_code_dictionary["p"].is_exist = true;
        morse_code_dictionary["q"].is_exist = true;
        morse_code_dictionary["r"].is_exist = true;
        morse_code_dictionary["s"].is_exist = true;
        morse_code_dictionary["t"].is_exist = true;
        morse_code_dictionary["u"].is_exist = true;
        morse_code_dictionary["v"].is_exist = true;
        morse_code_dictionary["w"].is_exist = true;
        morse_code_dictionary["s"].is_exist = true;
        morse_code_dictionary["y"].is_exist = true;
        morse_code_dictionary["z"].is_exist = true;
    }

    function slice(string memory string_data,uint start,uint len) pure public returns(string memory){
        bytes memory data=new bytes(len);
        for(uint i=0;i<len;i++){
            data[i]=bytes(string_data)[i+start];
        }
        return string(data);
    }

    function splicing(string memory str1, string memory str2) pure internal returns (string memory){
        bytes memory bstr1 = bytes(str1);
        bytes memory bstr2 = bytes(str2);

        string memory all_str = new string(bstr1.length + bstr2.length);
        bytes memory bytes_all_str = bytes(all_str);
        uint k = 0;
        for (uint i = 0; i < bstr1.length; i++){
            bytes_all_str[k++] = bstr1[i];
        }
        for (uint i = 0; i < bstr2.length; i++){
            bytes_all_str[k++] = bstr2[i];
        }
        return string(all_str);
   }

   function uint_to_str(uint256 _i) public pure returns (string memory str){
        uint256 j = _i;
        uint256 length;
        while (j != 0){
            length++;
            j /= 10;
        }


        bytes memory bstr = new bytes(length);
        j = _i;
        while (j != 0){
            bstr[--length] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
    
    function a(string calldata morse_code) public pure returns(string memory){
        
        string[100] memory now_morse_text_list;
        
        uint line_spacing_y = 15;
        // # 每到多少换行
        uint number_of_newline = 7;
        uint first = 0;
        uint end = number_of_newline;
        uint remain = bytes(morse_code).length;
        uint line = 0;

        while (remain >= number_of_newline){
            now_morse_text_list[line] = morse_code[first:end];
            line += 1;
            remain -= number_of_newline;
            first = end;
            end = first + number_of_newline;
        }

        now_morse_text_list[line] = morse_code[first:];

        uint first_y = 200;
        uint add_x = 15;
        uint x = uint(380 -7*uint(line));

        uint y = first_y;
        x += add_x;

        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" width="794" height="488"> <foreignObject width="794" height="488">';



        for (uint i=0;i <= now_morse_text_list.length;i++){

            svg = splicing(svg,"<p style='left:");
            svg = splicing(svg,uint_to_str(x));
            svg = splicing(svg, "px; position: absolute; width: 15px;line-height: 20px;word-wrap: break-word;'>");
            svg = splicing(svg,"</p>");

            // svg = splicing(svg,uint_to_str(x));

            x += add_x;
        }
    // }

    // svg = splicing(svg," </svg>");

    // return svg;

    }

    // function create(string memory text) public returns(string[] memory){
    function create(string memory text) public view returns(string memory){
        // string memory text = "hello i am huang zheng shi ge tiancai";
        // string calldata morse_code_text;
        string memory morse_code_text = '';
        for(uint i=1;i<=bytes(text).length;i++){
            

            string memory world = slice(text,i-1,1);

            // morse_code_text = splicing(morse_code_text,world);

            if (morse_code_dictionary[world].is_exist == true){
                morse_code_text = splicing(morse_code_text,morse_code_dictionary[world].morse_code);
                morse_code_text = splicing(morse_code_text," ");

            }
            else{
                morse_code_text = splicing(morse_code_text," ");
                morse_code_text = splicing(morse_code_text," ");
            }

        }
    
        return morse_code_text;

    }

}