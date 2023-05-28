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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
        
 ________      _______       _______       ________      ________      
|\   ____\    |\  ___ \     |\  ___ \     |\   ____\    |\   ____\     
\ \  \___|    \ \   __/|    \ \   __/|    \ \  \___|    \ \  \___|_    
 \ \  \  ___   \ \  \_|/__   \ \  \_|/__   \ \  \  ___   \ \_____  \   
  \ \  \|\  \   \ \  \_|\ \   \ \  \_|\ \   \ \  \|\  \   \|____|\  \  
   \ \_______\   \ \_______\   \ \_______\   \ \_______\    ____\_\  \ 
    \|_______|    \|_______|    \|_______|    \|_______|   |\_________\
                                                           \|_________|
                                                                       
                                    
*/

/// @title FeeStructure @ Geegs
/// @author rektt (https://twitter.com/aceplxx)

contract FeeStructure is Ownable {
    bool public dynamicFee;
    uint256 public platformFee;
    uint256 public disputeFee;

    constructor(uint256 pFee, uint256 dFee) {
        platformFee = pFee;
        disputeFee = dFee;
    }

    /// @notice set platform fee
    /// @param feePercent the fee in percent
    function setPlatformFee(uint256 feePercent) external onlyOwner {
        platformFee = feePercent;
    }

    /// @notice set dispute resolver fee incentive
    /// @param feePercent the fee in percent
    function setDisputeFee(uint256 feePercent) external onlyOwner {
        disputeFee = feePercent;
    }

    function toggleDynamicFee() external onlyOwner {
        dynamicFee = !dynamicFee;
    }

    function calculateFee(
        uint256 wage,
        uint256 feePercent
    ) external view returns (uint256, uint256) {
        uint256 feeBasis = dynamicFee ? feePercent : platformFee;
        uint256 fees = feeBasis > 0 ? (wage * feeBasis) / 100 : 0;
        return (fees, feeBasis);
    }

    function calculateDisputeFee(uint256 wage) external view returns (uint256) {
        uint256 fees = disputeFee > 0 ? (wage * disputeFee) / 100 : 0;
        return fees;
    }
}