// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface InWriting {
    function mint_NFT(string memory str) external payable returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function get_minting_cost() external view returns (uint256);
}

contract _5x5guys is Ownable{
    address InWriting_address = 0x20111434640CDeD801f3C170FDe4a4934DEFb41a;
    InWriting write = InWriting(InWriting_address);
    uint16 max_supply = 5555;
    uint16 supply = 0;
    uint256 cost = 0;

    constructor(){
        // generate mappings
       
    }  


    function change_minting_cost(uint256 new_cost) public onlyOwner {
        cost = new_cost;
    }

    function withdraw(uint256 amt) public onlyOwner {
        require(amt <= address(this).balance);
        payable(owner()).transfer(amt);
    }

    function get_minting_cost() public view returns (uint256) {
        return cost + write.get_minting_cost();
    }

    function mint_5x5guy(string memory str) public payable returns (uint256) {
        require(msg.value >= (write.get_minting_cost() + cost), "payment not sufficient");
        require(supply < max_supply, "max supply has been reached! no more 5x5guys can be created");

        string[] memory chars = string_to_array(str);

        //require(chars.length == 71, "String is not the right length");

        require(keccak256(bytes(chars[0])) == keccak256(bytes(" ")), "Wrong string format 1");
        require(keccak256(bytes(chars[1])) == keccak256(bytes(" ")), "Wrong string format 2");
        require(keccak256(bytes(chars[7])) == keccak256(bytes(" ")), "Wrong string format 3");
        require(keccak256(bytes(chars[8])) == keccak256(bytes("\n")), "Wrong string format 4");
        require(keccak256(bytes(chars[9])) == keccak256(bytes(" ")), "Wrong string format 5");
        require(keccak256(bytes(chars[17])) == keccak256(bytes("\n")), "Wrong string format 6");
        require(keccak256(bytes(chars[26])) == keccak256(bytes("\n")), "Wrong string format 7");
        require(keccak256(bytes(chars[35])) == keccak256(bytes("\n")), "Wrong string format 8");
        require(keccak256(bytes(chars[39])) == keccak256(bytes(" ")), "Wrong string format 9");
        require(keccak256(bytes(chars[40])) == keccak256(bytes(" ")), "Wrong string format 10");
        require(keccak256(bytes(chars[41])) == keccak256(bytes(">")), "Wrong string format 11");
        require(keccak256(bytes(chars[44])) == keccak256(bytes("\n")), "Wrong string format 12");
        require(keccak256(bytes(chars[53])) == keccak256(bytes("\n")), "Wrong string format 13");
        require(keccak256(bytes(chars[56])) == keccak256(bytes("`")), "Wrong string format 14");
        require(keccak256(bytes(chars[61])) == keccak256(bytes(" ")), "Wrong string format 15");
        require(keccak256(bytes(chars[62])) == keccak256(bytes("\n")), "Wrong string format 16");
        require(keccak256(bytes(chars[63])) == keccak256(bytes(" ")), "Wrong string format 17");
        require(keccak256(bytes(chars[64])) == keccak256(bytes(" ")), "Wrong string format 18");
        require(keccak256(bytes(chars[65])) == keccak256(bytes(" ")), "Wrong string format 19");
        require(keccak256(bytes(chars[66])) == keccak256(bytes(" ")), "Wrong string format 20");
        require(keccak256(bytes(chars[69])) == keccak256(bytes(" ")), "Wrong string format 21");
        require(keccak256(bytes(chars[70])) == keccak256(bytes(" ")), "Wrong string format22");

        // require((keccak256(bytes(chars[0])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[1])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[7])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[8])) == keccak256(bytes("\n"))) ==
        //         (keccak256(bytes(chars[9])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[17])) == keccak256(bytes("\n"))) ==
        //         (keccak256(bytes(chars[26])) == keccak256(bytes("\n"))) == true, "Wrong string format");

        
        // require((keccak256(bytes(chars[35])) == keccak256(bytes("\n"))) ==
        //         (keccak256(bytes(chars[39])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[40])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[41])) == keccak256(bytes(">"))) ==
        //         (keccak256(bytes(chars[44])) == keccak256(bytes("\n"))) ==
        //         (keccak256(bytes(chars[53])) == keccak256(bytes("\n"))) ==
        //         (keccak256(bytes(chars[56])) == keccak256(bytes("`"))) == true, "Wrong string format");
        
        // require((keccak256(bytes(chars[61])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[62])) == keccak256(bytes("\n"))) ==
        //         (keccak256(bytes(chars[63])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[64])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[65])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[66])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[69])) == keccak256(bytes(" "))) ==
        //         (keccak256(bytes(chars[70])) == keccak256(bytes(" "))) == true, "Wrong string format");

        supply += 1;
        uint256 tokenId = write.mint_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), msg.sender, tokenId);
        return tokenId;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }


    function string_to_array(string memory str) public pure returns (string[] memory){
        bytes memory b = bytes(str);
        string[] memory return_array = new string[](b.length);
        uint index_subtractor = 0;


        for (uint i; i<b.length; i++){
            string memory converted = bytes32ToString(b[i]);
            if (keccak256(bytes(converted)) == keccak256(bytes("\\")))
            {
                if (keccak256(bytes(bytes32ToString(b[i+1]))) == keccak256(bytes("n"))){
                    return_array[i-index_subtractor] = converted;
                }
                //else if (index_subtractor%2 == 0){
                else if (keccak256(bytes(bytes32ToString(b[i+1]))) == keccak256(bytes("\\"))){
                    return_array[i-index_subtractor] = "hello";
                    index_subtractor += 1;
                } 
            }
            else {
                return_array[i-index_subtractor] = converted;
            }

            if (keccak256(bytes(return_array[i])) == keccak256(bytes(""))){
                return_array[i] = "\\";
            }
        }
        return return_array;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}