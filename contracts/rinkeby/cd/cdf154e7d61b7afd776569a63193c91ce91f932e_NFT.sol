// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./base64.sol";

interface ERC20 {
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}

contract NFT is ERC721{

    address owner = msg.sender; 
    uint private id = 1;

    mapping(uint=>string) public user_text;

    mapping(string=>bool) public is_use;
    uint public mint_people = 0;

    mapping(string => string) morse_code_dictionary;

    // uint money = 0.021 ether;
    // uint money;
    // uint rnd_money = 150000000 ether;
    // uint rnd_money;

    address public rnd_contract = address(0xC444126fAfd9FC4Cee9A5c55946E309102D03733);

    bool can_mint = true;
    bool rnd_can_mint = false;
    bool eth_can_mint = true;

    
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

        // morse_code_dictionary["n"] = "11";
        // morse_code_dictionary["m"] = "10";
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
        // for(uint i=1;i<=bytes(text).length;i++){
            string memory world = string(abi.encodePacked(bytes(text)[i]));

            if(keccak256(abi.encode(morse_code_dictionary[world])) != keccak256(abi.encode(" "))){
                morse_code_text = string(abi.encodePacked(morse_code_text, morse_code_dictionary[world]));
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
    // function create_img(string memory morse_code) view public returns(string[] memory){
        // # 每到多少换行
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
        // string[] memory now_morse_text_list = new string[](100);

        while (remain >= number_of_newline){
              
            // for(uint i=first;i<end;i++){
            for(uint i=first;i<end;i++){
                morse_text = string(abi.encodePacked(morse_text,string(abi.encodePacked(bytes(morse_code)[i]))));
            }
            now_morse_text_list[line] = morse_text;
            line += 1;
            remain -= number_of_newline;
            // first = end + 1;
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

        // string memory svg = " <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";
        // string memory svg = " <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject style='background:black' width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";
        string memory svg;
        if(mint_people % 1010 == 0 || mint_people == 0){
            svg = " <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject style='background:black' width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";

            for (uint i=0;i <= line;i++){

                svg = string(abi.encodePacked(svg,"<p style='top:194.5px; left:",uint_to_str(x),
                "px; position: absolute; color: rgb(19, 184, 19); font-weight: bold; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
                // "px; position: absolute; font-weight: bold; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
                now_morse_text_list[i], "</p>"));

                x += add_x;
            
            }
        }

        else{
            svg = " <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";
            for (uint i=0;i <= line;i++){

                svg = string(abi.encodePacked(svg,"<p style='top:194.5px; left:",uint_to_str(x),
                // "px; position: absolute; color: rgb(19, 184, 19); font-weight: bold; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
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
        json_url = string(abi.encodePacked(json_url,"{\"name\":\"","morse",uint_to_str(id),"\",\"image\":\"",svg,"\"}"));
        // json_url = string(Base64.encode(bytes(json_url)));
        json_url = string(abi.encodePacked("data:application/json;utf8,",json_url));
        // json_url = string(abi.encodePacked("data:application/json;base64,",json_url));
        return json_url;
    }

    function return_is_use(string memory svg) public view returns(bool){
        return is_use[svg];
    }

    function return_mint_people() public view returns(uint){
        return mint_people;
    }

    function return_money() public view returns(uint){
        return 0.021 ether * ((mint_people/1010)+1);
        // return 0.021 ether * ((mint_people/1010)+1);
    }

    function return_rnd_money() public view returns(uint){
        // return 150000000 ether * ((mint_people/1010)+1);
        return 150000000 ether * ((mint_people/1010)+1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return user_text[tokenId];
    }


    function eth_create_nft(string memory svg) public payable{
    // function eth_create_nft(string memory svg,string memory json_url) public payable{
        require(msg.sender == tx.origin);
        //记得将2改未42
        require(can_mint == true);
        
        require(eth_can_mint == true);
        // money = return_money();
        // uint money = return_money();

        require(is_use[svg] == false);
        require(msg.value >= return_money());

        create_nft(svg);
        // create_nft(json_url);
    }

    function rnd_create_nft(string memory svg) public payable{
        require(msg.sender == tx.origin);
        require(can_mint == true);
        require(rnd_can_mint == true);
        //记得将2改未42
        // rnd_money = return_rnd_money();
        // uint money = return_rnd_money();

        require(is_use[svg] == false);
        // bool is_transfer = ERC20(rnd_contract).transferFrom(msg.sender,0x0000000000000000000000000000000000000001,rnd_money);
        bool is_transfer = ERC20(rnd_contract).transferFrom(msg.sender,0x0000000000000000000000000000000000000001,return_rnd_money());

        require(is_transfer == true);

        create_nft(svg);
    }

    function create_nft(string memory svg) private{
        require(msg.sender == tx.origin);

        string memory json_url = return_json_url(svg);
        user_text[id] = json_url;

        _mint(msg.sender, id);
        id++;
    
        is_use[svg] = true;
        mint_people += 1;
    }



    function withdrawal() public{
        require(msg.sender == tx.origin);
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function change_can_mint(bool _bool) public{
        require(msg.sender == tx.origin);
        require(msg.sender == owner);
        can_mint = _bool;
    } 

    function change_rnd_can_mint(bool _bool) public{
        require(msg.sender == tx.origin);
        require(msg.sender == owner);
        rnd_can_mint = _bool;
    } 

    function change_eth_can_mint(bool _bool) public{
        require(msg.sender == tx.origin);
        require(msg.sender == owner);
        eth_can_mint = _bool;
    } 
}