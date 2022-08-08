//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
 *  ChainpassRegistry V1.0
 */
contract ChainpassRegistry_1_0 is Ownable {
    using Strings for uint256;

    constructor() Ownable() {
        chainpassWallet = msg.sender;
    }

    /*
     *  Base URI
     */
    string public baseUri;

    function eventTicketTokenURI(address ticketContractAddress, uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(baseUri, "/event/", Address.toAsciiString(ticketContractAddress), "/token/", tokenId.toString(), "/metadata"));
    }

    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    /*
     *  Chainpass Default Fee
     */
    uint32 public chainpassDefaultFee;

    function getChainpassDefaultFee() public view returns (uint32) {
        return chainpassDefaultFee;
    }

    function setChainpassDefaultFee(uint32 feeBps) external onlyOwner {
        require(feeBps < 10_000, "BPS must be less than 10000");
        chainpassDefaultFee = feeBps;
    }

    /*
     *  Event Factory Contract
     */
    address public eventFactoryContractAddress;

    function getEventFactoryContractAddress() public view returns (address) {
        return eventFactoryContractAddress;
    }

    function setEventFactoryContractAddress(address addr) external onlyOwner {
        eventFactoryContractAddress = addr;
    }

    /*
     *  Tickets Base Contract
     */
    address public ticketsBaseContractAddress;

    function getTicketsBaseContractAddress() public view returns (address) {
        return ticketsBaseContractAddress;
    }

    function setTicketsBaseContractAddress(address addr) external onlyOwner {
        ticketsBaseContractAddress = addr;
    }

    /*
     *  Chainpass Wallet
     */
    address public chainpassWallet = owner();

    function getChainpassWallet() public view returns (address) {
        return chainpassWallet;
    }

    function setChainpassWallet(address addr) external onlyOwner {
        chainpassWallet = addr;
    }

    /*
     *  Marketplace Contract
     */
    address public marketplaceContractAddress;

    function getMarketplaceContractAddress() external view returns (address) {
        return marketplaceContractAddress;
    }

    function setMarketplaceContractAddress(address addr) external onlyOwner {
        marketplaceContractAddress = addr;
    }
        
    /*
     *  USDC Contract
     */
    address public splitsBaseContractAddress;

    function getSplitsBaseContractAddress() public view returns (address) {
        return splitsBaseContractAddress;
    }

    function setSplitsBaseContractAddress(address addr) external onlyOwner {
        splitsBaseContractAddress = addr;
    }

    /*
     *  USDC Contract
     */
    address public usdcContractAddress;

    function getUSDCContractAddress() public view returns (address) {
        return usdcContractAddress;
    }

    function setUSDCContractAddress(address addr) external onlyOwner {
        usdcContractAddress = addr;
    }
}

library Address {
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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