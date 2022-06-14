// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;
//import "hardhat/console.sol"; ///REMOVE BEFORE DEPLOYMENT
//v 1.0.3
import "./EldersDataStructures.sol";
import "./Interfaces.sol";

contract EldersInventoryManager {

    using EldersDataStructures for EldersDataStructures.EldersMeta;
    struct EldersInventoryItem {
           string folder;
           string name;          
    }

    string public constant header = '<svg id="elf" width="100%" height="100%" version="1.1" viewBox="0 0 160 160" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = "<style>#elf{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";
    
    string[6] public CLASS;
    string[6] public LAYERS;
    string[8] public ATTRIBUTES;
    string[5] public DISPLAYTYPES;
    uint256[6] public RACE_CODE;
    uint256[6] public BODY_CODE;
    uint256[6] public HEAD_CODE;
    uint256[6] public PRIMARY_WEAPON_CODE;
    uint256[6] public SECONDARY_WEAPON_CODE;
    uint256[6] public ARMOR_CODE;

    //layer code, followed by itemId
    mapping(uint256 => EldersInventoryItem) public EldersInventory;    
    
    bool isInitialized;
    address admin;
    string ipfsBase;
    
function initialize() public {
    admin = msg.sender;
    isInitialized = true;
    CLASS = ["Druid", "Sorceress", "Ranger", "Assassin", "Berserker", "Mauler"];
    LAYERS = ["Primary Weapon","Race", "Body", "Head", "Armor", "Secondary Weapon"];
    ATTRIBUTES = ["Strength", "Agility", "Intellegence", "Attack Points","Health Points","Mana"];
    DISPLAYTYPES = ["boost_number", "boost_percentage", "date", "number", ""];
    
    RACE_CODE = [700,800,900,1000,1100,1200];
    BODY_CODE = [1300,1400,1500,1600,1700,1800];
    HEAD_CODE = [1900,2000,2100,2200,2300,2400];
    PRIMARY_WEAPON_CODE = [2500,2600,2700,2800,2900,3000];
    SECONDARY_WEAPON_CODE =[3100,3200,3300,3400,3500,3600];
    ARMOR_CODE = [3700,3800,3900,4000,4100,4200];

    ipfsBase = "https://huskies.mypinata.cloud/ipfs/";
}

function setIPFSBase (string calldata _ipfsBase) public {
    onlyOwner();
    ipfsBase = _ipfsBase;
}


function addItem(uint256 [] calldata itemId, string[] memory name, string calldata folder ) public {    
    onlyOwner();    
    for(uint i = 0; i < itemId.length; i++) {       
  
        EldersInventory[itemId[i]].folder = folder;
        EldersInventory[itemId[i]].name = name[i];       
        
    }    

}

 
function getTokenURI(uint16 id_, uint256 elder, bool isRevealed)
        external
        view
        returns (string memory)
    {

        //
        //
        bytes memory imageSvg = abi.encodePacked('"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(elder))),'",');
        bytes memory imagePng = abi.encodePacked('"image": "https://imagedelivery.net/UsEuOeZz7eUzV1E1xlJ0hw/d34b45a8-fe1f-488d-e0d6-3cb6941a0600/public",');
        bytes memory name = abi.encodePacked( '"name":"Elder #', toString(id_),'",');
        bytes memory description = abi.encodePacked('"description":"Etherna Elves Elders is a collection of 2222 Heroes roaming the Elvenverse in search of the Mires. Play Ethernal Elves to upgrade your abilities and grow your army. !onward",');
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                name,
                                description,
                                isRevealed ? imageSvg : imagePng,                                
                                isRevealed ? getAttributes(elder) : '"attributes": [{"trait_type":"DNA","value":"',toString(elder), '"}]',                                                                   
                                '}'
                            )
                        )
                    )
                )
            );
    }

     function getSVG(uint256 elder) public view returns (string memory) {
      
      EldersDataStructures.EldersMeta memory item = EldersDataStructures.getElder(elder);
      uint256 elderClass = item.elderClass; 

      string memory elder =  string(
                abi.encodePacked(
                    header,
                    get(PRIMARY_WEAPON_CODE[elderClass], uint(item.primaryWeapon)),
                    get(RACE_CODE[elderClass], uint(item.race) ),
                    get(BODY_CODE[elderClass], uint(item.body) ),
                    get(HEAD_CODE[elderClass], uint(item.head) ),
                    get(ARMOR_CODE[elderClass], uint(item.armor)),
                    get(SECONDARY_WEAPON_CODE[elderClass], uint(item.secondaryWeapon)),                                  
                    footer
                )
            );

        return elder;          
    }

     function getAttributes(uint256 elder) internal view returns (string memory) {
        
        EldersDataStructures.EldersMeta memory item = EldersDataStructures.getElder(elder);
        return
            string(
                abi.encodePacked(
                    '"attributes": [',
                    string.concat('{"trait_type":"Class","value":"',CLASS[item.elderClass], '"}'),
                    ",",
                    getLayerAttributes(elder),                    
                    ",",
                    getValueAttributes(elder),                 
                    "]"
                )
            );
        
    }

     function getLayerAttributes(uint256 elder) internal view returns (string memory) {
        EldersDataStructures.EldersMeta memory item = EldersDataStructures.getElder(elder);       
        return
            string(
                abi.encodePacked(
                    getLayerAttribute(0, uint8(item.primaryWeapon), PRIMARY_WEAPON_CODE[item.elderClass]),
                    ",",
                    getLayerAttribute(1, uint8(item.race), RACE_CODE[item.elderClass]),                    
                    ",",
                    getLayerAttribute(2, uint8(item.body), BODY_CODE[item.elderClass]),                    
                    ",",
                    getLayerAttribute(3, uint8(item.head), HEAD_CODE[item.elderClass]),                    
                    ",",
                    getLayerAttribute(4, uint8(item.armor), ARMOR_CODE[item.elderClass]),
                    ",",
                    getLayerAttribute(5, uint8(item.secondaryWeapon), SECONDARY_WEAPON_CODE[item.elderClass])                
                )
            );            
    }

    function getValueAttributes(uint256 elder) internal view returns (string memory) {
        EldersDataStructures.EldersMeta memory item = EldersDataStructures.getElder(elder);
        return
            string(
                abi.encodePacked(
                    getValueAttribute(0, uint8(item.strength), 3),                   
                    ",",
                    getValueAttribute(1, uint8(item.agility), 3),                   
                    ",",
                    getValueAttribute(2, uint8(item.intellegence), 3),                   
                    ",",
                    getValueAttribute(3, uint8(item.attackPoints), 0),                   
                    ",",
                    getValueAttribute(4, uint8(item.healthPoints), 0),                   
                    ",",
                    getValueAttribute(5, uint8(item.mana), 0)
                )
            );
            
    }

    function getItem(uint256 itemId) external returns(EldersInventoryItem memory item) {
        return EldersInventory[itemId];
    }

   function getLayerAttribute(uint256 layerId, uint256 code, uint256 itemId)
        internal
        view
        returns (string memory)
    {
        uint256 identifier = code + itemId;
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    LAYERS[layerId],
                    '","value":"',
                    EldersInventory[identifier].name,
                    '"}'                    
                )
            );
    }

    function getValueAttribute(uint8 attributeId, uint8 value, uint8 displayType)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    ATTRIBUTES[attributeId],
                    '","value":"',
                    toString(value),
                    '", "display_type":"',
                    DISPLAYTYPES[displayType],
                    '"}'                    
                )
            );
    }

/*

█▀▄▀█ █▀█ █▀▄ █ █▀▀ █ █▀▀ █▀█ █▀
█░▀░█ █▄█ █▄▀ █ █▀░ █ ██▄ █▀▄ ▄█
*/

    function onlyOwner() internal view {    
        require(admin == msg.sender, "not admin");
    }

   
/*

█░█ █▀▀ █░░ █▀█ █▀▀ █▀█ █▀
█▀█ ██▄ █▄▄ █▀▀ ██▄ █▀▄ ▄█
*/

function get(uint256 code, uint256 itemId) internal view returns (string memory data_)
{       
        uint256 identifier = code + itemId;    

        string memory folderName = EldersInventory[identifier].folder;
        string memory fileName = string.concat(toString(identifier), ".png"); 
        string memory ipfs = string.concat(ipfsBase,folderName,"/",fileName);

        data_ = string(
                abi.encodePacked(
                    '<image x="1" y="1" width="160" height="160" image-rendering="pixelated" preserveAspectRatio="xMidYMid" href="',
                    ipfs,
                    '"/>'
                )
            );
         
        return data_;
}

function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERNAL ELVES TEAM.
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

library EldersDataStructures {

struct EldersMeta {
            uint256 strength;
            uint256 agility;
            uint256 intellegence;
            uint256 healthPoints;
            uint256 attackPoints; 
            uint256 mana;
            uint256 primaryWeapon; 
            uint256 secondaryWeapon; 
            uint256 armor; 
            uint256 level;
            uint256 head;                       
            uint256 body;  
            uint256 race;  
            uint256 elderClass;                                     
}

  
function getElder(uint256 _elder) internal pure returns(EldersMeta memory elder) {

    elder.strength =         uint256(uint16(_elder));
    elder.agility =          uint256(uint16(_elder>>16));
    elder.intellegence =     uint256(uint16(_elder>>32));
    elder.attackPoints =     uint256(uint16(_elder>>48));
    elder.healthPoints =     uint256(uint16(_elder>>64));
    elder.mana =             uint256(uint16(_elder>>80));
    elder.primaryWeapon =    uint256(uint16(_elder>>96));
    elder.secondaryWeapon =  uint256(uint16(_elder>>112));
    elder.armor =            uint256(uint16(_elder>>128));
    elder.level =            uint256(uint16(_elder>>144));
    elder.head =             uint256(uint16(_elder>>160));
    elder.body =             uint256(uint16(_elder>>176));
    elder.race =             uint256(uint16(_elder>>192));
    elder.elderClass =       uint256(uint16(_elder>>208));    

} 

function setElder(
                uint256 strength,
                uint256 agility,
                uint256 intellegence,                
                uint256 attackPoints,
                uint256 healthPoints, 
                uint256 mana,
                uint256 primaryWeapon, 
                uint256 secondaryWeapon,
                uint256 armor,
                uint256 level,
                uint256 head,
                uint256 body,
                uint256 race,
                uint256 elderClass )

    internal pure returns (uint256 character) {

    character = uint256(strength);
    
    character |= agility<<16;
    character |= intellegence<<32;
    character |= attackPoints<<48;
    character |= healthPoints<<64;
    character |= mana<<80;
    character |= primaryWeapon<<96;
    character |= secondaryWeapon<<112;
    character |= armor<<128;
    character |= level<<144;
    character |= head<<160;
    character |= body<<176;
    character |= race<<192;
    character |= elderClass<<208;
    
    return character;
}


}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface IEldersMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel, bool isRevealed) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface IERC1155Lite {
    function burn(address from,uint256 id, uint256 value) external;
    function balanceOf(address _owner, uint256 _id) external returns (uint256); 
}

 
//1155
interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}