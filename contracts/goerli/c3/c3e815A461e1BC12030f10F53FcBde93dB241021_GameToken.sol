//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GameToken is Ownable {
    uint tokenPrice;
    uint exchangeRate;
    mapping(address => bool) approved;

    constructor() {
        tokenPrice = 0.001 ether;
        exchangeRate = 1 * tokenPrice;
    }

    function changeTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    event PurchaseTokens(uint256 amountOfTokensPurchased);

    function purchaseTokens(uint256 amount) public payable {
        require(msg.value == amount * tokenPrice, "Inusffucient payment");

        emit PurchaseTokens(amount);
    }

    function swapTokensForEth(address[] calldata clients, uint256[] calldata amounts) public onlyOwner {
        for (uint i = 0; i < clients.length; i++) {
            (bool success, ) = clients[i].call{value: amounts[i] * exchangeRate}("");
            require(success, "Exchange failed");
        }
    }

    // function swapTokensForEth(address withdrawTo, uint256 tokenAmount) external payable {
    //     require(approved[msg.sender] == true, "You aren't approved");
    //     require(tokenAmount > 0, "You don't have enough tokens");
    //     require(address(this).balance >= tokenAmount * exchangeRate, "Not enough ETH to exchange");

    //     delete approved[msg.sender];

    //     (bool success, ) = withdrawTo.call{value: tokenAmount * exchangeRate}("");
    //     require(success, "Exchange failed");
    // }

    function getContractBalanceEth() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawEther() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawl failed");
    }

    receive() external payable {}
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