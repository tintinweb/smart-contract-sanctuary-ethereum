/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.12;

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


// File contracts/app/constant/ErrorType.sol


pragma solidity ^0.8.12;

error ZeroAddress();
error ZeroAmount();
error ZeroSize();
error ZeroBalance();
error ZeroTime();
error ZeroPayment();
error ExistentToken();
error NonexistentToken();
error LengthMismatch();
error NotAdmin();
error NotOwner();
error NotUser();
error NotMinter();
error IncorrectOwner();
error SameAddress();
error InvalidState();
error NotOwnerNorApproved();
error ToCurrentOwner();
error MustGreaterThan(uint256 value);
error MustLessThan(uint256 value);
error Insufficient();
error Overflows();
error AmountExceeds();
error TimeNotYet();
error IndexOutOfBounds();

contract ErrorType {}


// File contracts/app/access/IAdminable.sol


pragma solidity ^0.8.12;

interface IAdminable {
    /**
     * @dev
     */    
    function setAdmin(address newAdmin) external;

    /**
     * @dev
     */    
    function setMinter(address newMinter) external;

}


// File contracts/app/access/Adminable.sol


pragma solidity ^0.8.12;
contract Adminable is IAdminable {
    address private _admin;
    address private _minter;

    constructor() {
        _admin = msg.sender;
        _minter = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // require(_admin == msg.sender, "Ownable: caller is not the owner");
        if (msg.sender != _admin) revert NotAdmin();
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != _minter) revert NotMinter();
        _;
    }    

    function setAdmin(address newAdmin) external override onlyAdmin {
        // require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setAdmin(newAdmin);
    }

    function _setAdmin(address newAdmin) internal virtual {
        // require(newOwner != address(0), "Ownable: new owner is the zero address");
        if (newAdmin == address(0)) revert ZeroAddress();
        _admin = newAdmin;
    }

    function setMinter(address newMinter) external override onlyAdmin {
        _setMinter(newMinter);
    }

    function _setMinter(address newMinter) internal virtual {
        _minter = newMinter;
    }        
}


// File contracts/app/uri/URIContract.sol


pragma solidity ^0.8.12;
// import "hardhat/console.sol";

contract URIContract is Adminable {
    using Strings for uint256;

    string private _name;
    string private _symbol;
    string private _baseURI;
    string private _suffix;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory suffix_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _suffix = suffix_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }

    function setBaseURI(string memory baseURI) external onlyAdmin {
        _setBaseURI(baseURI);
    }

    function _setSuffix(string memory suffix) internal virtual {
        _suffix = suffix;
    }

    function setSuffix(string memory suffix) external onlyAdmin {
        _setSuffix(suffix);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return
            bytes(_baseURI).length > 0
                ? string(
                    abi.encodePacked(_baseURI, tokenId.toString(), _suffix)
                )
                : "";
    }
}