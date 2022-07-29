// SPDX-License-Identifier: UNLICENSED

pragma solidity ^ 0.8.15.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

/**
 * @title MultiSender, support ETH and ERC20 Tokens, send ether or erc20 token to multiple addresses in batch
 */

interface ERC20 {
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  //function transfer(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external;
  function transferFrom(address from, address to, uint value) external returns (bool); 
}

contract BulkSender is Ownable {
    // NULL ADDRESS: 0x0000000000000000000000000000000000000000

    // Payout from contract address
    // NOTE: owner by default
    address private _receiverAddress;

    /**
     * @notice Set receiver address
     * @dev Can not be zero address
     * @param newReceiverAddress new receiver address
     */
    function setReceiverAddress(address newReceiverAddress) public onlyOwner  {
        require(newReceiverAddress != address(0), "receiverAddress can not be set as zero address");
        _receiverAddress = newReceiverAddress;
    }
    
    /**
     * Get receiver address
     */
    function getReceiverAddress() public view returns(address) {
        if (_receiverAddress == address(0)) {
            return owner();
        }
        return _receiverAddress;
    }

    /**
     *  Withdraw asset from contract
     */
    function withdrawBalance(address tokenAddress) public onlyOwner  {
        address receiverAddress = getReceiverAddress();
        if (tokenAddress == address(0)) {
            payable(receiverAddress).transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract balance is 0");

        token.transfer(receiverAddress, balance);
    }
    
    function ethMultiSendSameAmount(address payable[] calldata to, uint256 amount) public payable onlyOwner {

        uint256 sendAmount = to.length - 1 * amount;
        uint256 totalBalance = msg.value + address(this).balance;

        require(totalBalance >= sendAmount, "send amount greater than total balance");

        for (uint256 i = 0; i < to.length; i++) {
            to[i].transfer(amount); // TODO: test then recepient with infinitie fallback function
        }
    }

    function ethMultiSendDifferentAmount(address payable[] calldata to, uint256[] calldata amounts) public payable onlyOwner {
        uint256 sendAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            sendAmount += amounts[i];
        }
        uint256 totalBalance = msg.value + address(this).balance;

        require(totalBalance >= sendAmount, "Send amount greater than total balance");
        for (uint256 i = 0; i < to.length; i++) {
            to[i].transfer(amounts[i]); // TODO: test then recepient with infinitie fallback function
        }

    }

    function erc20MultiSendSameAmountFromExternal(address tokenAddress, address payable[] calldata to, address from, uint256 amount) public onlyOwner {
        require(from != address(0), "'from' can not be zero address");
        require(tokenAddress != address(0), "'tokenAddress' can not be zero address");

        ERC20 token = ERC20(tokenAddress);
        for (uint256 i = 0; i < to.length; i++) {
            // TODO: test is 'transfer' for this will be cheaper
            // TODO: test require in this place
            token.transferFrom(from, to[i], amount);
        }

    }

    function erc20MultiSendSameAmountFromContract(address tokenAddress, address payable [] calldata to, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "'tokenAddress' can not be zero address");

        ERC20 token = ERC20(tokenAddress);
        for (uint256 i = 0; i < to.length; i++) {
            // TODO: test is 'transfer' for this will be cheaper
            // TODO: test require in this place
            token.transfer( to[i], amount);
        }

    }

    function erc20MultiSendDifferentAmountFromExternal(address tokenAddress, address payable[] calldata to, address from, uint[] calldata amounts) public onlyOwner {

        require(from != address(0), "'from' can not be zero address");
        require(tokenAddress != address(0), "'tokenAddress' can not be zero address");

        ERC20 token = ERC20(tokenAddress);

        for (uint256 i = 0; i < to.length; i++) {
            // TODO: test require in this place
            token.transferFrom(from, to[i], amounts[i]);
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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