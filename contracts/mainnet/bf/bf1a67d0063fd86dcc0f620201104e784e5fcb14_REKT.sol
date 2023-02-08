// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./ERC1155.sol";
import "./Registry.sol";

interface iREKT {
    function exist(uint256) external view returns (bool);

    function uri(uint256) external view returns (string memory);

    function tokenURI(uint256) external view returns (string memory);

    function supportsInterface(bytes4) external view returns (bool);
}

/// RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEEKKKKKKKKK    KKKKKKKTTTTTTTTTTTTTTTTTTTTTTT
/// R::::::::::::::::R  E::::::::::::::::::::EK:::::::K    K:::::KT:::::::::::::::::::::T
/// R::::::RRRRRR:::::R E::::::::::::::::::::EK:::::::K    K:::::KT:::::::::::::::::::::T
/// RR:::::R     R:::::REE::::::EEEEEEEEE::::EK:::::::K   K::::::KT:::::TT:::::::TT:::::T
///   R::::R     R:::::R  E:::::E       EEEEEEKK::::::K  K:::::KKKTTTTTT  T:::::T  TTTTTT
///   R::::R     R:::::R  E:::::E               K:::::K K:::::K           T:::::T        
///   R::::RRRRRR:::::R   E::::::EEEEEEEEEE     K::::::K:::::K            T:::::T        
///   R:::::::::::::RR    E:::::::::::::::E     K:::::::::::K             T:::::T        
///   R::::RRRRRR:::::R   E:::::::::::::::E     K:::::::::::K             T:::::T        
///   R::::R     R:::::R  E::::::EEEEEEEEEE     K::::::K:::::K            T:::::T        
///   R::::R     R:::::R  E:::::E               K:::::K K:::::K           T:::::T        
///   R::::R     R:::::R  E:::::E       EEEEEEKK::::::K  K:::::KKK        T:::::T        
/// RR:::::R     R:::::REE::::::EEEEEEEE:::::EK:::::::K   K::::::K      TT:::::::TT      
/// R::::::R     R:::::RE::::::::::::::::::::EK:::::::K    K:::::K      T:::::::::T      
/// R::::::R     R:::::RE::::::::::::::::::::EK:::::::K    K:::::K      T:::::::::T      
/// RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEEKKKKKKKKK    KKKKKKK      TTTTTTTTTTT      
                                                                                     
// author: jolan.eth
contract REKT is ERC1155, Registry {
    constructor() {}

    function name() public pure returns (string memory) {
        return "REKT";
    }

    function symbol() public pure returns (string memory) {
        return "RCSA";
    }

    function mintRCSA(
        address source,
        uint256 id,
        uint256 amount
    ) public {
        require(
            source != address(0),
            "REKT::mintRCSA() - source does not exist"
        );

        require(amount > 0, "REKT::mintRCSA() - amount is 0");

        uint256 tokenId = uint256(
            keccak256(abi.encodePacked(uint256(uint160(address(source))), id))
        );

        if (ERC1155.totalSupply(tokenId) == 0) {
            Registry.setRCSARegistration(tokenId, address(source), id);
        }

        ERC1155._mint(msg.sender, tokenId, amount, "");
    }

    function uri(uint256 id) public view returns (string memory) {
        require(ERC1155.totalSupply(id) > 0, "REKT::uri() - id does not exist");
        Registry.RCSA memory Entry = Registry.getREKTRegistry(id);
        iREKT Reader = iREKT(Entry.NFTContract);
        if (Reader.supportsInterface(0x80ac58cd))
            return Reader.tokenURI(Entry.id);
        if (Reader.supportsInterface(0xd9b67a26)) return Reader.uri(Entry.id);
        return "REKT";
    }

    function owner() public pure returns (address) {
        return address(0);
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes
            memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

    function toString(uint256 value) internal pure returns (string memory) {
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