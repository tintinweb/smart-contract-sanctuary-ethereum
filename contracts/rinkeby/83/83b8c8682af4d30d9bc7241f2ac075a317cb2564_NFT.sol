// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

interface ERC20_interface {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ERC721_interface{
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFT is ERC721,Ownable,ReentrancyGuard{
    struct user_settings_struct{
        string text;
        string background_color;
        string text_color;
        bool can_change;
        uint number_of_changes;
    }

    // address public owner = 0x5F0bC7Aa98c15d1eA8C7e3a7AD3eE81D1f3DC260; 
    uint private id = 0;

    // mapping(uint=>string[4]) private user_settings;
    mapping(uint=>user_settings_struct) private user_settings;

    mapping(string=>bool) public is_use;
    // uint public mint_people = 0;

    mapping(string => string) public morse_code_dictionary;

    bool public can_mint = true;
    bool public eth_can_mint = false;
    bool public free_can_mint = true;

    mapping(address => bool) public already_mint_people;

    // uint number_of_changes = 0;
    
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

        // create_nft(0x75D5fAaDFe17024CEfcC0A9d245B8fEBbCAA7cD4,"murphys law means whatever can happen will happen");
        
        // create_nft(0xBe13Ceeb2d8E3ebe1B7619c0Cd8382a983582fE8,"tian xing jian jun zi yi zi qiang bu xi di shi kun jun zi yi hou de zai wu");

        // create_nft(0xBe13Ceeb2d8E3ebe1B7619c0Cd8382a983582fE8,"20090103181505");
        
        // create_nft(0xb0836AeD27ECc2DCD6F69B532D2D6f86E47FD4b4,"The light cannot exist without the dark.");
        
        // create_nft(0xBDAc31258715b1CFC2979AE5C7C3b14386c3095f,"0  0 1101 001 01 0100 000  11 1010  000 1101 001 01 010 0");
        // create_nft(0xBDAc31258715b1CFC2979AE5C7C3b14386c3095f,"101010");

        // create_nft(0x7Dcc799A2941B0BBB7e5dbaeC5c668469A5d4A61,"time will tell how much i love you huang zheng");
    }


//    function uint_to_str(uint256 _i) pure internal returns (string memory str){
//        if(_i == 0){
//            return "0";
//        }

//         uint256 j = _i;
//         uint256 length;
//         while (j != 0){
//             length++;
//             j /= 10;
//         }

//         bytes memory bstr = new bytes(length);
//         j = _i;
//         while (j != 0){
//             bstr[--length] = bytes1(uint8(48 + j % 10));
//             j /= 10;
//         }
//         str = string(bstr);
//     }

    function create_morse(string memory text) public view returns(string memory){
        string memory morse_code_text = '';
        for(uint i=0;i<bytes(text).length;i++){
            string memory word = string(abi.encodePacked(bytes(text)[i]));

            if(keccak256(abi.encode(morse_code_dictionary[word])) != keccak256(abi.encode(" "))){
                morse_code_text = string(abi.encodePacked(morse_code_text, morse_code_dictionary[word]," "));
                // morse_code_text = string(abi.encodePacked(morse_code_text, " "));

            }
            else{
                morse_code_text = string(abi.encodePacked(morse_code_text, "  "));
            }

        }
    
        return morse_code_text;

    }
    function create_img(string memory morse_code,string memory background_color,string memory text_color) pure public returns(string memory){

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

        string memory svg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' width='800' height='500'><foreignObject style='background:",background_color,"' width='800' height='500'><body xmlns='http://www.w3.org/1999/xhtml'>"));

            for (uint i=0;i <= line;i++){

                svg = string(abi.encodePacked(svg,"<p style='top:194.5px; left:",Strings.toString(x),
                "px; position: absolute; color: ",text_color,"; font-weight: bold; white-space: pre; writing-mode: vertical-rl; text-orientation: upright;'>",
                now_morse_text_list[i], "</p>"));

                x += add_x;
            
            }

        svg = string(abi.encodePacked("data:image/svg+xml,",svg, "</body> </foreignObject> </svg>"));

        return svg;


    }

    function return_json_url(string memory svg) public view returns(string memory){
        string memory json_url = "";
        json_url = string(abi.encodePacked("data:application/json;utf8,",json_url,"{\"name\":\"","mooorse",Strings.toString(id-1),"\",\"image\":\"",svg,"\"}"));
        return json_url;
    }

    function return_is_use(string memory text) public view returns(bool){
        return is_use[text];
    }

    function return_money() public view returns(uint){
        return 0.21 ether * (id/1010 + 1);
    }

    function return_mint_people() public view returns(uint){
        return id;
    }
    

    function return_user_settings(uint token_id) public view returns(string memory,string memory,bool,uint){
        return (user_settings[token_id].background_color,
        user_settings[token_id].text_color,user_settings[token_id].can_change,user_settings[token_id].number_of_changes);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return return_json_url(
            create_img(
                create_morse(
                    user_settings[tokenId].text
                ),
                user_settings[tokenId].background_color,user_settings[tokenId].text_color
            )
            );
    }

    function verify(bytes32 root,address _address,bytes32[] calldata proof) public pure returns(bool){
        bytes32 leafs = keccak256(abi.encodePacked(_address));
        bool _verify = MerkleProof.verify(proof,root,leafs);
        return _verify;
    }

    // bytes32 tree = 0x5fd9a9d949b7d07d6a138ae512afc23025776a07d0001a4d3aac9e88eacd5228;
    bytes32 tree =  0x7e4b829f443715fd12cf0037c35514365ec59c7a786884b150b2a3a9b962cde6;
    uint star_time = block.timestamp;

    function free_create_nft(address _address,string memory text,bytes32[] calldata proof,bool can_change,string memory background_color,string memory text_color) public{
        require(free_can_mint == true);
        require(block.timestamp - star_time <= 5 days);
        require(already_mint_people[_address] == false);

        bool is_contains = verify(tree,_address,proof);
        require(is_contains == true);

        already_mint_people[msg.sender] = true;

        create_nft(_address,text,can_change,background_color,text_color);
    }

    function eth_create_nft(address _address,string memory text,bool can_change,string memory background_color,string memory text_color) payable public{
        require(msg.sender == tx.origin);
        require(eth_can_mint == true);
        require(msg.value >= return_money());

        create_nft(_address,text,can_change,background_color,text_color);

    }

    function create_nft(address _address,string memory text,bool can_change,string memory background_color,string memory text_color) private{
        require(msg.sender == tx.origin);
        require(is_use[text] == false);
        require(can_mint == true);
        require(id <= 10101);

        user_settings[id].text = text;
        user_settings[id].background_color = background_color;
        user_settings[id].text_color = text_color;
        user_settings[id].can_change = can_change;
        user_settings[id].number_of_changes = 0;
        
        id++;
        is_use[text] = true;

        _mint(_address, id-1);
    }

    function withdrawal() public onlyOwner{
        require(msg.sender == tx.origin);
        // require(msg.sender == owner);
        payable(owner()).transfer(address(this).balance);
    }

    function erc20_withdrawal(address erc20_address,uint amount) public onlyOwner{
        require(msg.sender == tx.origin);
        // require(msg.sender == owner);
        ERC20_interface(erc20_address).transfer(owner(),amount);
    }

    function change_can_mint(bool _bool) public onlyOwner{
        require(msg.sender == tx.origin);
        // require(msg.sender == owner);
        can_mint = _bool;
    }

    function change_eth_can_mint(bool _bool) public onlyOwner{
        require(msg.sender == tx.origin);
        // require(msg.sender == owner);
        eth_can_mint = _bool;
    }

    function change_free_can_mint(bool _bool) public onlyOwner{
        require(msg.sender == tx.origin);
        // require(msg.sender == owner);
        free_can_mint = _bool;
    }

    function change_tree(bytes32 _tree) public onlyOwner{
        require(msg.sender == tx.origin);
        // require(msg.sender == owner);
        tree = _tree;
        star_time = block.timestamp;
    }

    function change_text(uint token_id,string memory text) public{
        require(msg.sender == tx.origin);
        require(user_settings[token_id].can_change == true);
        require(user_settings[id].number_of_changes <= 42);

        // address nft_owner = ERC721_interface(address(this)).ownerOf(token_id);
        address nft_owner = ownerOf(token_id);
        require(nft_owner == msg.sender);
        
        user_settings[id].number_of_changes += 1;
        user_settings[token_id].text = text;
    }
}