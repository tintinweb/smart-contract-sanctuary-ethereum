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

    // uint can_mint_people = 21000;

    // uint public can_mint_people = 4;
    uint public mint_people = 0;

    mapping(string => string) morse_code_dictionary;

    uint money = 0.021 ether;
    uint rnd_money = 150000000 ether;

    address public contra = address(0xC444126fAfd9FC4Cee9A5c55946E309102D03733);

    bool can_mint = true;

    
    constructor() ERC721("Morse", "Morse"){
        
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
        morse_code_dictionary["n"] = "11";
        morse_code_dictionary["m"] = "10";
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
    // function create_morse(string memory text) public view returns(uint){
        string memory morse_code_text = '';
        for(uint i=0;i<bytes(text).length;i++){
            string memory world = string(abi.encodePacked(bytes(text)[i]));

            if(keccak256(abi.encode(morse_code_dictionary[world])) != keccak256(abi.encode(" "))){
                morse_code_text = string(abi.encodePacked(morse_code_text, morse_code_dictionary[world]));
                morse_code_text = string(abi.encodePacked(morse_code_text, " "));
                // morse_code_text = string(abi.encodePacked(morse_code_text, "%20"));

            }
            else{
                morse_code_text = string(abi.encodePacked(morse_code_text, " "));
                morse_code_text = string(abi.encodePacked(morse_code_text, " "));
                // morse_code_text = string(abi.encodePacked(morse_code_text, "%20"));
                // morse_code_text = string(abi.encodePacked(morse_code_text, "%20"));
            }

        }
    
        return morse_code_text;

    }
    function create_img(string memory morse_code) pure public returns(string memory){
        // # 每到多少换行
        uint number_of_newline = 7;
        uint first = 0;
        uint end = number_of_newline;
        uint remain = bytes(morse_code).length;
        uint line = 0;
        string memory morse_text = "";

        uint line_number = 1;
        while (remain >= number_of_newline){
            line_number += 1;
            remain -= number_of_newline;                        
        }

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

        // x += add_x;

        string memory svg = "  <svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>";


        for (uint i=0;i <= line;i++){

            svg = string(abi.encodePacked(svg,"<p style='top:194.5px; left:",uint_to_str(x),
            "px; position: absolute; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
            now_morse_text_list[i], "</p>"));
            // svg = string(abi.encodePacked(svg,uint_to_str(x)));
            // svg = string(abi.encodePacked(svg,"px; position: absolute; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>"));
            // svg = string(abi.encodePacked(svg, now_morse_text_list[i]));
            // svg = string(abi.encodePacked(svg, "</p>"));

            x += add_x;
            
        }

        svg = string(abi.encodePacked("data:image/svg+xml,",svg, "</body> </foreignObject> </svg>"));

        return svg;
    }

    function return_json_url(string memory svg) public view returns(string memory){
        // string memory json_url = "";
        // json_url = string(abi.encodePacked(json_url,"{\"name\":\"","morse",uint_to_str(id),"\",\"image\":\"",svg,"\"}"));
        // json_url = string(Base64.encode(bytes(json_url)));
        // json_url = string(abi.encodePacked("data:application/json;base64,",json_url));
        // return json_url;

        string memory json_url = "";
        json_url = string(abi.encodePacked(json_url,"{\"name\":\"","morse",uint_to_str(id),"\",\"image\":\"",svg,"\"}"));
        json_url = string(abi.encodePacked("data:application/json;utf8,",json_url));
        return json_url;
    }

    // function return_exceeds_people() external view returns(bool){
    //     return mint_people<=can_mint_people;
    // }

    function return_is_use(string memory svg) public view returns(bool){
        return is_use[svg];
    }

    function return_money() public view returns(uint){
        return 0.021 ether * ((mint_people/2)+1);
    }

    function return_rnd_money() public view returns(uint){
        // return 150000000 ether * ((mint_people/1010)+1);
        return 15 ether * ((mint_people/2)+1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // require( bytes(create_morse(user_text[msg.sender].text)).length <= 200,"string out of picture size");
        // return user_text[tokenId];

        return "string:data:application/json;utf8,{\"name\":\"Censored #1050\",\"description\":\"PAKVERSE\",\"created_by\":\"Pak\",\"image\":\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 1000 1000'><style>@font-face {font-family: 'C';src: url('data:font/woff2;charset=utf-8;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') format('woff2');font-weight: 500; font-style: normal; font-display: swap;}.f { width: 100%; height: 100%; }.b { fill: whitesmoke; }.a { animation: o 2s ease-out forwards; }@keyframes o { 10% { opacity: 1; } 100% { opacity: 0; } }tspan { fill: black; font-family: 'C'; font-size: 70px; text-transform: uppercase; text-anchor: middle; }</style><rect class='b f' /><svg y='525' overflow='visible'><text><tspan x='500'>pakverse</tspan></text><text><tspan x='500'>--------</tspan></text></svg><rect class='b f a' /></svg>\"\"attributes\":[{\"trait_type\":\"Censored\",\"value\":\"True\"},{\"trait_type\":\"Initial Price\",\"value\":0.0000}]}";

    }

    // receive() external payable {


    function eth_create_nft(string memory svg) public payable{
        require(msg.sender == tx.origin);
        //记得将2改未42
        // money = 0.021 ether * ((mint_people/1010)+1);
        require(can_mint == true);
        money = return_money();
        // money = 0.021 ether * ((mint_people/2)+1);

        string memory json_url = return_json_url(svg);

        require(is_use[json_url] == false);
        require(msg.value >= money);
        // require(mint_people<=can_mint_people);

        // user_text[id] = json_url;

        // _mint(msg.sender, id);
        // id++;
    
        // is_use[svg] = true;
        // mint_people += 1;

        create_nft(svg);
    }

    function rnd_create_nft(string memory svg) public payable{
        require(msg.sender == tx.origin);
        require(can_mint == true);
        //记得将2改未42
        // rnd_money = 150000000 ether * ((mint_people/1010)+1);
        rnd_money = return_rnd_money();
        // money = 0.021 ether * ((mint_people/2)+1);

        string memory json_url = return_json_url(svg);

        require(is_use[json_url] == false);
        bool is_transfer = ERC20(contra).transferFrom(msg.sender,0x0000000000000000000000000000000000000001,rnd_money);
        // bool is_transfer = ERC20(contra).transferFrom(msg.sender,a,rnd_money);

        require(is_transfer == true);
        
        // require(mint_people<=can_mint_people);

        // user_text[id] = json_url;

        // _mint(msg.sender, id);
        // id++;
    
        // is_use[svg] = true;
        // mint_people += 1;

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
}