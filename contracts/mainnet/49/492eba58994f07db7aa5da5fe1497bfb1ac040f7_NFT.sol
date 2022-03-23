// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

contract NFT is ERC721{

    address public owner = 0x5F0bC7Aa98c15d1eA8C7e3a7AD3eE81D1f3DC260; 
    uint private id = 0;

    mapping(uint=>string) private user_text;

    mapping(string=>bool) public is_use;
    uint public mint_people = 0;

    mapping(string => string) public morse_code_dictionary;

    bool public can_mint = true;
    
    constructor() ERC721("Mooorse", "Mooorse"){
        morse_code_dictionary["a"] = "01";
        morse_code_dictionary["b"] = "1000";
        morse_code_dictionary["c"] = "1010";
        morse_code_dictionary["d"] = "100";
        morse_code_dictionary["e"] = "0";
        morse_code_dictionary["f"] = "0010";
        morse_code_dictionary["g"] = "110";
        morse_code_dictionary["h"] = "0000";
        morse_code_dictionary["i"] = "00";
        morse_code_dictionary["j"] = "0111";
        morse_code_dictionary["k"] = "101";
        morse_code_dictionary["l"] = "0100";
        morse_code_dictionary["m"] = "11";
        morse_code_dictionary["n"] = "10";
        morse_code_dictionary["o"] = "111";
        morse_code_dictionary["p"] = "0110";
        morse_code_dictionary["q"] = "1101";
        morse_code_dictionary["r"] = "010";
        morse_code_dictionary["s"] = "000";
        morse_code_dictionary["t"] = "1";
        morse_code_dictionary["u"] = "001";
        morse_code_dictionary["v"] = "0001";
        morse_code_dictionary["w"] = "011";
        morse_code_dictionary["x"] = "1001";
        morse_code_dictionary["y"] = "1011";
        morse_code_dictionary["z"] = "1100";

        morse_code_dictionary["0"] = "11111";
        morse_code_dictionary["1"] = "01111";
        morse_code_dictionary["2"] = "00111";
        morse_code_dictionary["3"] = "00011";
        morse_code_dictionary["4"] = "00001";
        morse_code_dictionary["5"] = "00000";
        morse_code_dictionary["6"] = "10000";
        morse_code_dictionary["7"] = "11000";
        morse_code_dictionary["8"] = "11100";
        morse_code_dictionary["9"] = "11110";

        create_nft(0x75D5fAaDFe17024CEfcC0A9d245B8fEBbCAA7cD4,"murphys law means whatever can happen will happen");
        
        create_nft(0xBe13Ceeb2d8E3ebe1B7619c0Cd8382a983582fE8,"tian xing jian jun zi yi zi qiang bu xi di shi kun jun zi yi hou de zai wu");

        create_nft(0xBe13Ceeb2d8E3ebe1B7619c0Cd8382a983582fE8,"20090103181505");
        
        create_nft(0xb0836AeD27ECc2DCD6F69B532D2D6f86E47FD4b4,"The light cannot exist without the dark.");
        
        create_nft(0xBDAc31258715b1CFC2979AE5C7C3b14386c3095f,"0  0 1101 001 01 0100 000  11 1010  000 1101 001 01 010 0");
        create_nft(0xBDAc31258715b1CFC2979AE5C7C3b14386c3095f,"101010");

        create_nft(0x7Dcc799A2941B0BBB7e5dbaeC5c668469A5d4A61,"time will tell how much i love you huang zheng");
    }


   function uint_to_str(uint256 _i) pure internal returns (string memory str){
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

    function create_morse(string memory text) public view returns(string memory){
        string memory morse_code_text = '';
        for(uint i=0;i<bytes(text).length;i++){
            string memory word = string(abi.encodePacked(bytes(text)[i]));

            if(keccak256(abi.encode(morse_code_dictionary[word])) != keccak256(abi.encode(" "))){
                morse_code_text = string(abi.encodePacked(morse_code_text, morse_code_dictionary[word]));
                morse_code_text = string(abi.encodePacked(morse_code_text, " "));

            }
            else{
                morse_code_text = string(abi.encodePacked(morse_code_text, " "));
                morse_code_text = string(abi.encodePacked(morse_code_text, " "));
            }

        }
    
        return morse_code_text;

    }
    function create_img(string memory morse_code) view public returns(string memory){

        uint number_of_newline = 7;
        uint remain = bytes(morse_code).length;

        uint line_number = 1;
        while (remain >= number_of_newline){
            line_number += 1;
            remain -= number_of_newline;                        
        }

        uint first = 0;
        uint end = number_of_newline;
        uint line = 0;
        string memory morse_text = "";
        remain = bytes(morse_code).length;

        string[] memory now_morse_text_list = new string[](line_number);

        while (remain >= number_of_newline){
              
            for(uint i=first;i<end;i++){
                morse_text = string(abi.encodePacked(morse_text,string(abi.encodePacked(bytes(morse_code)[i]))));
            }
            now_morse_text_list[line] = morse_text;
            line += 1;
            remain -= number_of_newline;
            first = end;
            end = first + number_of_newline;  
            morse_text = "";                                  
        }

        remain = bytes(morse_code).length-first;
        while (remain != 0){
            
            morse_text = string(abi.encodePacked(morse_text,string(abi.encodePacked(bytes(morse_code)[first]))));
            first += 1;
            remain -= 1;
        }
        now_morse_text_list[line] = morse_text;


        uint add_x = 15;
        uint x = uint(363 -7*uint(line));

        string memory svg;
        if(mint_people == 1009 || mint_people == 0){
            svg = " <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject style='background:black' width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";

            for (uint i=0;i <= line;i++){

                svg = string(abi.encodePacked(svg,"<p style='top:194.5px; left:",uint_to_str(x),
                "px; position: absolute; color: rgb(19, 184, 19); font-weight: bold; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
                now_morse_text_list[i], "</p>"));

                x += add_x;
            
            }
        }

        else{
            svg = " <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";
            for (uint i=0;i <= line;i++){

                svg = string(abi.encodePacked(svg,"<p style='top:194.5px; left:",uint_to_str(x),
                "px; position: absolute; font-weight: bold; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
                now_morse_text_list[i], "</p>"));

                x += add_x;
            
            }

        }

        svg = string(abi.encodePacked(svg, "</body> </foreignObject> </svg>"));
        svg = string(abi.encodePacked("data:image/svg+xml,",svg));

        return svg;


    }

    function return_json_url(string memory svg) public view returns(string memory){
        string memory json_url = "";
        json_url = string(abi.encodePacked(json_url,"{\"name\":\"","mooorse",uint_to_str(id),"\",\"image\":\"",svg,"\"}"));
        json_url = string(abi.encodePacked("data:application/json;utf8,",json_url));
        return json_url;
    }

    function return_is_use(string memory text) public view returns(bool){
        return is_use[text];
    }

    function return_mint_people() public view returns(uint){
        return mint_people;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return user_text[tokenId];
    }

    function create_nft(address _address,string memory text) public{
        require(msg.sender == tx.origin);
        require(is_use[text] == false);
        require(can_mint == true);
        require(mint_people <= 1010);

        string memory json_url = return_json_url(create_img(create_morse(text)));
        user_text[id] = json_url;

        _mint(_address, id);
        id++;
    
        is_use[text] = true;
        mint_people += 1;
    }

    function withdrawal() public{
        require(msg.sender == tx.origin);
        require(msg.sender == owner);
        payable(0x5412D63d9802F7964511105eBEB1B66934659eF1).transfer(address(this).balance);
    }

    function change_can_mint(bool _bool) public{
        require(msg.sender == tx.origin);
        require(msg.sender == owner);
        can_mint = _bool;
    } 
}