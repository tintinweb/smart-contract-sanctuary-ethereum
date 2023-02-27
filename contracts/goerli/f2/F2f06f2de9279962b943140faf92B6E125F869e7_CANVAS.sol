// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./ERC721.sol";
import "./Registry.sol";

interface iReplicart {
    function mintREPLICART(address, uint256) external;
}

// author: jolan.eth
contract CANVAS is ERC721, Registry {
    iReplicart Replicart;

    mapping(uint256 => string) Metadata;

    constructor(address _Replicart) {
        Replicart = iReplicart(_Replicart);
    }

    function name() public pure returns (string memory) {
        return "CANVAS";
    }

    function symbol() public pure returns (string memory) {
        return "CANVAS";
    }

    function mintCANVAS(
        address receiver
    ) public {
        require(receiver != address(0), "CANVAS::mintCANVAS() - address is 0");
        ERC721._mint(receiver, 1);
    }

    function clearCanvasMetadata(uint256 id) public {
        require(ERC721.exist(id), "CANVAS::setCanvasMetadata() - id does not exist");
        require(ERC721.ownerOf(id) == msg.sender, "CANVAS::setCanvasMetadata - msg.sender is not owner");
        Metadata[id] = '';
    }

    function setCanvasMetadata(
        uint256 id, 
        string memory _name, string memory description, 
        string memory image, string memory interactive
    ) public {
        require(ERC721.exist(id), "CANVAS::setCanvasMetadata() - id does not exist");
        require(ERC721.ownerOf(id) == msg.sender, "CANVAS::setCanvasMetadata - msg.sender is not owner");
        Metadata[id] = string(abi.encodePacked(
                'data:application/json;base64,',
                encode(
                    bytes (
                        string(
                            abi.encodePacked(
                                "{",
                                '"name":"',_name,'",',
                                '"description":"',description,'",',
                                '"image":"',image,'"',
                                (
                                    bytes(interactive).length != 0 ? 
                                    string(abi.encode(',"animation_url":"',interactive,'"')) : ""
                                ),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        require(ERC721.exist(id), "CANVAS::uri() - id does not exist");
        return bytes(Metadata[id]).length != 0 ? 
            Metadata[id] : string(abi.encodePacked(
                'data:application/json;base64,',
                encode(
                    bytes (
                        string(
                            abi.encodePacked(
                                "{",
                                '"name":"Canvas #',toString(id),'",',
                                '"description":"This canvas is empty actually you cannot replicate it",',
                                '"image":"EMPTY CANVAS URL"',
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function owner() public pure returns (address) {
        return address(0);
    }

    function _transfer(address from, address to, uint256 id)
    internal override  {
        require(bytes(Metadata[id]).length > 0, "ERC721::_transfer :: canvas is empty");
        uint256 replicationIdentifier = uint256(keccak256(abi.encodePacked(from, id)));
        Registry.setReplikRegistration(replicationIdentifier, from, Metadata[id], id);
        Replicart.mintREPLICART(to, replicationIdentifier);
    }
    
    function toString(uint256 value) private pure returns (string memory) {
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