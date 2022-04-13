// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./TokenReceiver.sol";
import "./Ownable.sol";

// 77777!!!!!!!!!!!!!!!!!!!!!!~~^^^^^~!!!!!!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!^^:::^^^~~~~
// ~!!!!!!!!~!!~!!!!!!!!!!~~~~~~~~~~~~~~!!!!!!!!~~~~~~!!!!!!!!!!~~!!!!!!!!!!!~~!!~~~~~~~~!~~^^:::^^:::^
// !!!!~~~~~~^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!?7!?~~~~~~~~~~~^::^^^^^~~~~~~~~~~~~~^^^:::
// !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^~?^J5Y7!~~~~~~^^^^^^^^^^^~~~~~~~~!!~~~^^^^^
// !!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!~^~~^~^~~~???JY?~^~~~~~~~~~^~^^^^^^^^~~~~~~~~~~~~~
// !!!!!!!!!~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~J~:~7^~~~!7???J?JY7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~!!~~!~!~~~~~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^~?~^?!^^~::^~^~?YYY7!J?777!!!~!~~!~~!!!!~~!!!!!!!!!!!!!
// ??JJJYYYY5YJJ?JJJJJ???7????????JJJJJJJJJJ?7!!????77??77???7?JYYJ??J???JJJJJJYJJJJJJJJJJJJJJJJYJJJJYY
// JJJJJJJ???77?77????????JJYYJJ???JY555YYJJJ?77!!!!7???7??77777!777?JJJJY5YY55YYJYJ??JJJYYYYPP5YYYYYYY
// 77!!!!!!!~~~~~~~~~~~~!!!!!!!~~~~~~~~~^^^~77!~~!~^!!!!!7!7???????????JJJYJJJYJ!!!!!!!777???JJ?JJJJJJJ
// 77777!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~!??!!7?J?77~!7J?JJYY55JJJJJJJJYP5555J!7777!!7777???JJJJJYYYY
// 77777777!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~!J?!7YYYY?7~!!YYY555PP555YYYYPPPGGGGJ77777777777??JJJJJYYYYY
// ??7777777777777777!!!!!!!!!!!!!!!!!!!!~~~7?77YYYY??!!7YJYPPPGGGPPPPPPGGBBBBBJ77???????????JJJYYYYYY5
// ????77777777777777777777!!!!!!!!!!!!!!!!!~??!?5P5?J7~7JJYPPGGGGGGBBBGGBBBBBGY????????JJJJJJJYYYY5555
// ???????????7777777777777777777777!!!!!!!!7?JJJPP5JJ?!77JJ5GGGGGGBBBBBBBBBBGGJ?JJJJJJJJJJJJYYYY55555P
// J??????????????777777777777777777777777777??JY555PJJ77!JP?5GGGGBBBBBBBBBBG5GJJJJJJJJJJYYYYYYY5555PPP
// JJJJJJ?????????????????777777777777777777777Y5555G5??7!?PY?YPPGBBBBBBBBBBPJJJJJJJJYYYYYYYY5555555PPP
// JJJJJJJJJJJ?????????????????????7777777777??JJ??J5PJ77?JJ?JPGGGBBBBBBBBBGYJJJJYYYYYYYYY555555555PPPP
// YYJJJJJJJJJJJJJJ??????????????????????????????!7JJ5YJJ?YYY5YGBGBBBBBBBBB5JYYYYYYYYYYY5555555PPPPPPPP
// YYYYYYJJJJJJJJJJJJJJJJJ???????????????????????!J??55J5J??Y?PBBBBBBB#BBBPYYYYYYYYY555555555PPPPPPPPPG
// YYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?JJJJJJ7??75PYJY5?7?JGGGPBB#BBBGYYYYYYYY555555555PPPPPPPPPGGG
// 555YYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??7YG5JPPPJJY?5PPPPGBBB5YY555555555555PPPPPPPPPGGGGGG
// 55555555YYYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJYY??YPGY5YGP55555P5PGGGG55555555555PPPPPPPPPPPPGGGGGGG
// 5555555555555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ?55GPY5GGGPGPPP555GG555555555PPPPPPPPPPPPPGGGGGGGGG
// PP555555555555555555555YYYYYYYYYYYYYYYYYYYYYYYYYYJ??55P5G#BBBBBBGP55555555PPPPPPPPPPPPPGGGGGGGGGGGGB
// PPPPPPP555555555555555555555555555YYY5555555555555J7JYPPP#####BP555555PPPPPPPPPPPPPPGGGGGGGGGGGGGGBB
// PPPPPPPPPPPP5555555555555555555555555555555555555555?55JG#####B5PPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGBBB

// @author jolan.eth
contract ICEBERG is Owned {
    string public symbol = "ICEBERG";
    string public name = "ICEBERG";

    string CID = "QmSKzYaijnL6Y7SM15ErJ1spMDrS8fTD5i7w9yXWF3njWg";
    mapping (uint256 => string) EMERGED;
    mapping (uint256 => string) IMMERSED;
    mapping (uint256 => string) TOKEN;

    uint256 public tokenId = 0;

    mapping (uint256 => address) owners;
    mapping(address => uint256) balances;
    
    mapping(uint256 => address) approvals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {}
    
    function mintICEBERG(string memory _CID, string memory _EMERGED, string memory _IMMERSED)
    public onlyOwner {
        TOKEN[tokenId] = _CID;
        EMERGED[tokenId] = _EMERGED;
        IMMERSED[tokenId] = _IMMERSED;
        _mint(msg.sender, tokenId++);
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function totalSupply()
    public view returns (uint256) {
        return tokenId;
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
            encode(bytes (string(abi.encodePacked(
                "{",
                    '"name":"ICEBERG - ',EMERGED[id],'",',
                    '"image":"ipfs://',CID,'",',
                    '"attributes":[',
                        '{"trait_type":"EMERGED","value":"',EMERGED[id],'"},',
                        '{"trait_type":"IMMERSED","value":"',IMMERSED[id],'"}',
                    '],'
                    '"animation_url":"ipfs://',TOKEN[id],'"',
                "}"
            ))))
        ));
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
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(address(0), to, id);
        require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
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