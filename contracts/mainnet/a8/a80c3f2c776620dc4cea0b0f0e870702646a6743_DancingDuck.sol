// SPDX-License-Identifier: GPL-3.0
/*                                                                                                                                                                                                        
                                                                                                                                       
                                                                                                                                       
    ,---,                                                                                  ,---,                                  ,-.  
  .'  .' `\                                      ,--,                                    .'  .' `\                            ,--/ /|  
,---.'     \                   ,---,           ,--.'|         ,---,                    ,---.'     \          ,--,           ,--. :/ |  
|   |  .`\  |              ,-+-. /  |          |  |,      ,-+-. /  |  ,----._,.        |   |  .`\  |       ,'_ /|           :  : ' /   
:   : |  '  |  ,--.--.    ,--.'|'   |   ,---.  `--'_     ,--.'|'   | /   /  ' /        :   : |  '  |  .--. |  | :    ,---.  |  '  /    
|   ' '  ;  : /       \  |   |  ,"' |  /     \ ,' ,'|   |   |  ,"' ||   :     |        |   ' '  ;  :,'_ /| :  . |   /     \ '  |  :    
'   | ;  .  |.--.  .-. | |   | /  | | /    / ' '  | |   |   | /  | ||   | .\  .        '   | ;  .  ||  ' | |  . .  /    / ' |  |   \   
|   | :  |  ' \__\/: . . |   | |  | |.    ' /  |  | :   |   | |  | |.   ; ';  |        |   | :  |  '|  | ' |  | | .    ' /  '  : |. \  
'   : | /  ;  ," .--.; | |   | |  |/ '   ; :__ '  : |__ |   | |  |/ '   .   . |        '   : | /  ; :  | : ;  ; | '   ; :__ |  | ' \ \ 
|   | '` ,/  /  /  ,.  | |   | |--'  '   | '.'||  | '.'||   | |--'   `---`-'| |        |   | '` ,/  '  :  `--'   \'   | '.'|'  : |--'  
;   :  .'   ;  :   .'   \|   |/      |   :    :;  :    ;|   |/       .'__/\_: |        ;   :  .'    :  ,      .-./|   :    :;  |,'     
|   ,.'     |  ,     .-./'---'        \   \  / |  ,   / '---'        |   :    :        |   ,.'       `--`----'     \   \  / '--'       
'---'        `--`---'                  `----'   ---`-'                \   \  /         '---'                        `----'             
                                                                       `--`-'                                                                     
*/                                                                                                

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract DancingDuck is ERC721A {
    address _owner;
    uint256 _fee = 0.001 ether;
    uint256 _maxSupply = 999; // max supply
    uint256 _maxPerTx = 10;
    address _bornEgg; // which address claim eggs for ducks
    
    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("DancingDuck", "DDK") {
        _owner = msg.sender;
    }
    
    function mintDuck(uint256 amount) payable public {
        require(amount > 0, "Exceed 0");
        require(amount <= _maxPerTx, "Exceed MaxP");
        uint256 cost = amount * _fee;
        require(msg.value >= cost, "No Enough Ether");
        require(totalSupply() + amount <= _maxSupply, "Exceed 2");
        _safeMint(msg.sender, amount);
    }

    function bornEgg(uint256 duckid) public {
        require(ownerOf(duckid) == msg.sender, "Not Your Cat");
        _burn(duckid);
        _safeMint(msg.sender, 1);
    }

    function fees(uint256 fee, uint8 maxper) public onlyOwner {
        _fee = fee;
        _maxPerTx = maxper;
    }

    function maxSupply() public view returns (uint256){
        return _maxSupply;
    }

    string _baseUri = "";
    function setUri(string memory uri) public onlyOwner {
        _baseUri = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        if (bytes(_baseUri).length == 0) {
            return "ipfs://QmUverBRDApX4wu98jtBSYsUinLDSryVTJ6iUx4qch9Wtn";
        }
        return string(abi.encodePacked(_baseUri, _toString(tokenId)));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}