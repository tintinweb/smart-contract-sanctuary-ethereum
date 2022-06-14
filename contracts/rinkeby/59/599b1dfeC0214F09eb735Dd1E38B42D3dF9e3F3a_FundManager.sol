//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of the Fund Manager contract that allows funds to split to contributors.
 */
contract FundManager is Ownable {
    
    /**
     * @dev Struct managing the receivers and their share (percentage basis points).
     */
    struct FundReceiver { 
        address payable receiver;
        uint96 sharePercentageBasisPoints;
    }
    /**
     * @dev Receivers whom FundManager are sending funds through withdraw function to.
     */
    FundReceiver[] private _fundReceivers;

    /**
     * @dev For receiving fund in case someone try to send it.
     */
    receive() external payable {}

    /**
     * @dev Register new receivers and their share.
     * @param receivers The list of new receivers and their share.
     */
    function setFeeReceivers(FundReceiver[] calldata receivers) external onlyOwner {
        uint256 receiversLength = receivers.length;
        require(receiversLength > 0, "at least one receiver is necessary");
        uint256 totalPercentageBasisPoints = 0;
        delete _fundReceivers;
        for(uint256 i = 0; i < receiversLength;) {
            require(receivers[i].receiver != address(0), "receiver address can't be null");
            require(receivers[i].sharePercentageBasisPoints != 0, "share percentage basis points can't be 0");
            _fundReceivers.push(FundReceiver(receivers[i].receiver, receivers[i].sharePercentageBasisPoints));

            totalPercentageBasisPoints += receivers[i].sharePercentageBasisPoints;

            unchecked { ++i; }
        }
        require(totalPercentageBasisPoints == 10000, "total share percentage basis point isn't 10000");
    }

    /**
     * @dev Send funds to registered receivers based on their share.
     *      If there is remainders, they are sent to the receiver registered at first (index 0).
     */
    function withdraw() external onlyOwner {
        require(_fundReceivers.length != 0, "receivers haven't been specified yet");

        uint256 sendingAmount = address(this).balance;
        uint256 receiversLength = _fundReceivers.length;
        uint256 totalSent = 0;
        if(receiversLength > 1) {
            for(uint256 i = 1; i < receiversLength;) {
                uint256 transferAmount = (sendingAmount * _fundReceivers[i].sharePercentageBasisPoints) / 10000;
                totalSent += transferAmount;
                require(_fundReceivers[i].receiver.send(transferAmount), "transfer failed");

                unchecked { ++i; }
            }
        }

        // Remainder is sent to the first receiver
        require(_fundReceivers[0].receiver.send(sendingAmount - totalSent), "transfer failed");
    }

    /**
     * @dev Allow owner to send funds directly to recipient. This is for emergency purpose and use regular withdraw.
     * @param recipient The address of the recipinet.
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");
        require(payable(recipient).send(address(this).balance), "failed to withdraw");
    }

    /**
     * @dev Do nothing for disable renouncing ownership.
     */ 
    function renounceOwnership() public override onlyOwner {}     
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