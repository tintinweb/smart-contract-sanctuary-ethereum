// SPDX-License-Identifier: MIT

/// ~~^~~^^^^^^^^~^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~77!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~^^^^~^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!77!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~~^~~^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~!!~~~~~~~~~~~!777!!~~~~~~~~~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~^^~~~^^~^^^^^^^~~~^~~~~~~7~~~~~~~~~7!!~~~~~~~~~!7777!~~~~~~~!!!!!!!~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~~~^~^^^^^^^^~~~~~~~~~~~~~!!!~~~~~!~!77!~~~~~~~~~~!!!!~~~~~~~!777!!!~!~~!~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~~~~~~~~^^~^~^~~~~~~~~~~~~~~7?!~~~~~~77!~~~~~~~~~!!~~~~~~~~~~~!77!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!77!~~~~~!~~~~~!!77!!!7!!7777!!!!~~~~~~~~~~~~~~~~~~~~~~~~!?!~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!77777777777777777!!~~~~~~~~~~~~~~~~~~~~~~!J!~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~!!!~~~~~~~~~~~!!!!!!!!!777777777777777777777!~~~~!!!!!!!!!~~~~~~~~~~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~!!7777!~~~~!!!7!!!7777777777777777777777777777!~~!7777!!~~~~~~~!~?GY5!~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~!777~~~~7777777777!77777777777777777777777777!!~!!!~~~~~~~~~7G??5J5!~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~!!~~~!7777777777777777777777777777777777777777!~~~~~~~~~~~~~!~~~!~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!777777777777777777777777777777777777777777!~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~!~!!!!!!!!!!77777!777777777777777777777777777777~~~~!~~~~~~~~~~~~~~~~PB7~~
/// ~~~~~~~~~~~~~~~~~!!!!!~~!~^:.    ..:^^~!!!!!!!!!!!77777!77!77777777777777!~~~~777!!!!!~~~~~~~~~JJ!~~
/// ~~~~~~~~~~~~~~~~~!!777777                ...::^^~~~!!!!!!!!!!!!777777777!~~~~~!77!!!!!!~~!~~77?77!~~
/// ~~~~~~~~~~~~~~~~~~~~!!77~    !5                        ....:::^~7777???7!!!!~~~~~~~~~~~~~~!5#BYJJBJ~
/// ~~~~~~~~~~~~~~~~~~~~~~~!.    [email protected] ~JPY                            .:^^^^^::::~~~~~~~~~~~~~~PY&G~~~!G?
/// ~~~~~~~~~~~~~~~~~~~~~~~!.   Y#@@@PJ~.              !#~   ..        ........:~~~~~~~~~~~~~~5Y!~~~!5G!
/// ~~~~~~~~~~~~~~~~~~~~~~~~:   5!.:&?                  [email protected]#G&@&.     .~777777777!~~~~~~~!??!~~!Y5Y555J~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~.       .!       .~.      ~5#@&&@?      .!777777!77!~~~~7?7!!PG7~~~~~!!!~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~                :!!~.     !!^.  ?#.     ^77777!7?YY?~~~7777!!~~~~~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~!!!~.  .           !!!!:                  .777!!!?G#PJ5B!~~~~~~~~~~~~~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~!!!~~~:. .^^~~~.!!!!~^..               ^?7!!!~5P5Y~~#7~~~~~~~~~~~~~~~!!~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!7!~!!7777777777777!^::..       .^!!!!!!~7PYJJ5P~~~~~~~75YYJJ7~~7P!~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~!~7!!!!7~~~~!!!!!7777777777777!~~!!!!!!!~~!!~~~~!7??!~~~~~~7#&#?7?G!~~!~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~!!~!!!!!!!~~~~~~!~!7777777777!!!7!777!!!!~~!~~!~~~~~~~!~~~~~7BP7~~7G!~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7!57!!~!!!!!!!!!!!!!!!!!~~!!!!77~~~~~~~~^^~~~~7P55YPJ~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7YPB&@@[email protected]@&&Y~~~~~~~~~~~~~~~^^~~~7Y57!!7?YY5Y!^^~~~~~~!!!!~~~~~~~~~~
/// ~~~~~~~~~~~~~~~~~~~~~~~^~~~!7YPG#@@@@@@@@@&&&57~~~~~~~~~~~^~?G&[email protected]@@&J5&G&@@@7::^^~~~~!!~~~~~Y5JJ~~~
/// ~~~~~~~~~~~~~~~~~~~~~~^^[email protected]@@&@@@@@@@@@@@@&&#PJXCOPY77!Y&@@@@@#@&@@[email protected]&@@@&^~Y!~!~~!?!~!!~PBJ7&?~~
/// ~~~~~~~~~~~~~~~~~~~~~!~~~G5~#@@@@@@@@@@@@@@&@&&&&@@[email protected]@@@@@@@&[email protected]@@@@@@@@@@#[email protected]~~~!!~!~JY?55!~~
/// ~~~~~~~~~~~~~~~~~!?BBG!?~BJ^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@&@@@@@@@@@&@[email protected]&!!7~~~!~~!!~~~~~
/// ~~~~~~~~~~~~~^^?##Y5#&75!GY^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P5&@PYG5J#@@@@@B#@@[email protected]@&&@PJY7JY77~!!~~
/// [email protected]@@@&##~7~BG^@@@@@@@@@@@@@@@@@@@@@@@@@@&&B755P&@@@@@7#@@@@B&@&#[email protected]@@@@@G&!5Y~~75YY~
/// [email protected]@@@@@@@J!!&&^&@@@@@@@&#J5555G#BPPY?JYJYJ7!5&^^~~5&@@[email protected]@@@@@@@&&7!!#@@@@@@&&J?~~~!YY7~
/// [email protected]@@@@@@@@57~&@^#@@@@@@@@B:?#B&&@@&&&PJJ5&&[email protected]@~~~^^^Y&@@@@@@@@@[email protected]@&&&&@@@Y~~~~~~~~~
/// ~~~~~~~~~^~~&@@@@@@@@@J?~&@^[email protected]@@@@@@@5:[email protected]@@@@@@#PPB!B#[email protected]@@PJ77~^^~?G&@@@@@@&&[email protected]@@@B&@@@7!!!~~~~~
/// [email protected]@@@@@@@@@JJ^&@^[email protected]@@@@@@@Y^[email protected]@@@@[email protected]@@##&@@@@@@@@[email protected]@@@@@@@@[email protected]@&&&&@@@#GJ77!~~~~
/// ~~~~~~~~^~^[email protected]@@@@@@@@@Y?^&@[email protected]@@@@@@@5^!Y&@@@[email protected]@@@@@@@@@[email protected]@&7&[email protected]@@@@@@@@[email protected]@@@@@@@&#&7~!Y~~~~

pragma solidity ^0.8;

import "./TokenReceiver.sol";

contract SUMMERJPG {
    string public symbol = "CC0";
    string public name = "SUMMER.JPG";

    address public XCOPY = 0x39Cc9C86E67BAf2129b80Fe3414c397492eA8026;
    string public CID = "QmX62bPNStkvrnv3mHMUsoKZ3hH7bDKQtvyFK5i7wKnx8d";

    uint256 public tokenId = 1;
    uint256 public totalSupply = 69;

    mapping (uint256 => address) owners;
    mapping(address => uint256) balances;
    
    mapping(uint256 => address) approvals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {}

    function SummerJPG() public {
        require (tokenId <= 69);
        while (tokenId <= 69)
            _mint(msg.sender, tokenId++);
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        require(address(0) != owner, "error address(0)");
        return balances[owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return owners[id];
    }

    function tokenURI(uint256 id)
    public view returns (string memory) {
        require(owners[id] != address(0), "error !exist");
        return string(abi.encodePacked(
                'data:application/json;base64,',
                encode(
                    bytes (
                        string(
                            abi.encodePacked(
                                "{",
                                '"name":"SUMMER.JPG CC0",',
                                '"description":"here we go - XCOPY",',
                                '"image":"ipfs://',
                                CID,
                                '"',
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function approve(address to, uint256 id)
    public {
        address owner = owners[id];
        require(to != owner, "error to");
        require(
            owner == msg.sender ||
            operatorApprovals[owner][msg.sender],
            "error owner"
        );
        approvals[id] = to;
        emit Approval(owner, to, id);
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return approvals[id];
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(operator != msg.sender, "error operator");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        require(owners[id] != address(0), "error !exist");
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );

        _transfer(owner, from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );
        _transfer(owner, from, to, id);
        require(_checkOnERC721Received(from, to, id, data), "error ERC721Receiver");
    }

    function _mint(address to, uint256 id)
    private {
        require(to != address(0), "error to");
        require(owners[id] == address(0), "error owners[id]");
        emit Transfer(address(0), XCOPY, id);

        balances[to]++;
        owners[id] = to;
        
        emit Transfer(XCOPY, to, id);
        require(_checkOnERC721Received(XCOPY, to, id, ""), "error ERC721Receiver");
    }

    function _transfer(address owner, address from, address to, uint256 id)
    private {
        require(owner == from, "errors owners[id]");
        require(address(0) != to, "errors address(0)");

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == ERC721TokenReceiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("error ERC721Receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }
    
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";

        uint256 digits;
        uint256 tmp = value;

        while (tmp != 0) {
            digits++;
            tmp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}