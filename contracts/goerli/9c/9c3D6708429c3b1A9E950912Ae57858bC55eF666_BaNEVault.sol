//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaNEVault is Ownable {
    mapping(address => bool) private nodeOperators;
    uint256 internal vaultBalance;
    uint256 public paymentAmount;
    uint256 public operatorCount;

    /**
        @dev The address that creates this contract automatically becomes an unapproved node operator.
        @param _amount The initial allowance amount to operators.
    */
    constructor(uint256 _amount) {
        nodeOperators[msg.sender] = false;
        operatorCount++;
        paymentAmount += _amount;
    }

    /**
        @dev Let owner of this contract set the amount that will be paid to approved node operators.
        @param _amount New allowance for active node operators.
    */
    function setPaymentAmount(uint256 _amount) external onlyOwner {
        paymentAmount = _amount;
    }

    /** 
        @dev The address that calls this function will be registered as a node operator
    */
    function becomeNodeOperator() external payable {
        // We can add a buy-in to become operator ? require(msg.value == ??);
        // vaultBalance += msg.value;
        nodeOperators[msg.sender] = false;
        operatorCount++;
    }

    /** 
        @dev Remove a node operator from the contract.
    */
    function removeNodeOperator(address addressToRemove) external onlyOwner {
        delete nodeOperators[addressToRemove];
        operatorCount--;
    }

    /** 
        @dev Approve a wallet address to be eligible for payment. Only callable by the contract owner.
        @param addressToApprove Wallet address of the node operator that is to be approved.
    */
    function approveWallet(address addressToApprove) external onlyOwner {
        nodeOperators[addressToApprove] = true;
    }

    /** 
        @dev Reset approval value of a node operator to false.
    */
    function resetApproval(address addressToReset) external onlyOwner {
        nodeOperators[addressToReset] = false;
    }

    /** 
        @dev Let an approved node operator withdraw his allowance.
    */
    function withdraw() external payable {
        require(
            nodeOperators[msg.sender],
            "BaNEVault: Not allowed to withdraw."
        );
        payable(msg.sender).transfer(paymentAmount);
    }

    /** 
        @dev Transfer ownership of this contract.
    */
    function changeOwnership(address newOwner) external onlyOwner {
        address prevOwner = owner();
        transferOwnership(newOwner);
        emit OwnershipTransferred(prevOwner, newOwner);
    }

    /** 
        @dev Renounce ownership such that the contract has no owner.
    */
    function deleteOwnership() external onlyOwner {
        renounceOwnership();
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