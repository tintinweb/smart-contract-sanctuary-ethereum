// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";
interface IERC721{
    function ownerOf(uint256) external view returns(address);
    function totalSupply() external view returns(uint256);
    function tokenURI(uint256) external view returns(string[] memory);
}

contract CountContractmain {
    event Log(uint);
    event Address(uint, address);


    function getAll(IERC721 _erc721address) public view returns(address[] memory ret) {
        uint minid = getFirstTokenId(_erc721address);
        uint maxid = getLastTokenId(_erc721address);
        for (uint i = minid; i <= maxid; i++) {
            // ret[i] = toString(_erc721address.ownerOf(i));
            // ret[i] = Strings.toHexString(uint256(uint160(address(_erc721address.ownerOf(i)))), 20);
            ret[i] = address(_erc721address.ownerOf(i));
        }
    }

    function getaAll(IERC721 _erc721address) public {
        uint minid = getFirstTokenId(_erc721address);
        uint maxid = getLastTokenId(_erc721address);
        for (uint i = minid; i <= maxid; i++) {
            emit Address(i, _erc721address.ownerOf(i));
        }
    }

    // function getbAll(IERC721 _erc721address) public view returns(string[] memory ret) {
    //     ret = Strings.toHexString(uint256(uint160(address(_erc721address))), 20);
    // }


    function getFirstTokenId(IERC721 nft) public view returns(uint) {
        try nft.ownerOf(0) {
            return 0;
        } catch {
            return 1;
        }
    }

    function getLastTokenId(IERC721 nft) public view returns(uint rep) {
        uint256 min = 0;
        uint256 max = 1000000;
        uint256 cur;
        while (min <= max){
            cur = (min + max) / 2;
            try nft.tokenURI(cur) {
                min = cur;
            } catch {
                try nft.tokenURI(cur - 1) {
                    rep = cur - 1;
                    return rep;
                } catch {
                     max = cur; 
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}