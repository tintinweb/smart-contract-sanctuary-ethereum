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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyWithdrawal.sol";

contract DeBridgesProxy is Ownable, ProxyWithdrawal {

    event SendDepositEvent(string hash, address from, address to, address tokenAddress, uint amount, bytes data);

    /**
     * Add coins
     */
    function addCoins() public payable {}

    /**
     * Send deposit
     */
    function sendDeposit(string memory hash, address from, address tokenAddress, uint amount, bytes calldata data, address to) public onlyOwner {
        if (tokenAddress == address(0)) {
            sendCoins(to, amount, data);
        } else {
            sendTokens(tokenAddress, to, amount, data);
        }

        emit SendDepositEvent(hash, from, to, tokenAddress, amount, data);
    }

    /**
     * Send coins
     */
    function sendCoins(address to, uint amount, bytes memory data) internal onlyOwner {
        require(getBalance() >= amount, "Balance not enough");
        (bool success, ) = to.call{value: amount}(data);
        require(success, "Transfer not sended");
    }

    /**
     * Send tokens
     */
    function sendTokens(address contractAddress, address to, uint amount, bytes memory data) internal onlyOwner {
        require(getTokenBalance(contractAddress) >= amount, "Not enough tokens");

        (bool success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        (success, ) = to.call(data);
        require(success, "transfer data request failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProxyWithdrawal is Ownable {
    
    event BalanceEvent(uint amount, address tokenAddress);
    event TransferEvent(address to, uint amount, address tokenAddress);

    /**
     * Return coins balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * Return tokens balance
     */
    function getTokenBalance(address tokenAddress) public returns(uint) {
        (bool success, bytes memory result) = tokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");

        uint amount = abi.decode(result, (uint));
        emit BalanceEvent(amount, tokenAddress);

        return amount;
    }

    /**
     * Transfer coins
     */
    function transfer(address payable to, uint amount) external onlyOwner {
        uint _balance = getBalance();
        require(_balance >= amount, "Balance not enough");
        to.transfer(amount);

        emit TransferEvent(to, amount, address(0));
    }

    /**
     * Transfer tokens
     */
    function transferToken(address to, uint amount, address tokenAddress) external onlyOwner {
        uint _balance = getTokenBalance(tokenAddress);
        require(_balance >= amount, "Not enough tokens");

        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        emit TransferEvent(to, amount, tokenAddress);
    }
}