// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


contract XLARevenueShareContract is Ownable {
    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;

    event AddRecipient(address recipient, uint256 percentage);
    event RemoveRecipient(address recipient);
    event UpdateRecipient(address recipient, uint256 percentage);

    fallback() external payable {
        _redistributeEth();
    }

    receive() external payable {
        _redistributeEth();
    }

    /**
     * @notice Internal function to redistribute Eth
     * When msg.value is provided it will redistribute this value else it will redistribute contract balance
     */
    function _redistributeEth() internal {
        uint256 recipientsLength = recipients.length;
        uint256 contractEth = address(this).balance;
        for (uint256 i = 0; i < recipientsLength; i++) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];

            if (msg.value > 0) {
                uint256 amountToReceive = msg.value / 100 * percentage;
                payable(recipient).transfer(amountToReceive);
            } else {
                uint256 amountToReceive =  contractEth / 100 * percentage;
                payable(recipient).transfer(amountToReceive);
            }

        }
    }

    /**
     * @notice Internal function to check whether all percentages are no more that 100
     * @param _percentage percentage to check
     */
    function _checkPercentage(uint256 _percentage) internal view returns (bool valid){
        uint256 recipientsLength = recipients.length;
        uint256 percentageSum = _percentage;
        for (uint256 i = 0; i < recipientsLength; i++) {
            address recipient = recipients[i];
            percentageSum += recipientsPercentage[recipient];
        }
        if (percentageSum > 100) {
            valid = false;
        } else {
            valid = true;
        }
    }

    /**
     * @notice Add recipient to revenue share
     * @param _recipient Fixed amount of token user want to buy
     * @param _percentage code of the affiliation partner
     */
    function addRecipient(address payable _recipient, uint256 _percentage) external onlyOwner {
        require(recipientsPercentage[_recipient] == 0, "Recipient already added");
        require(_checkPercentage(_percentage), "Percentage exceeded 100");
        recipients.push(_recipient);
        recipientsPercentage[_recipient] = _percentage;
        emit AddRecipient(_recipient, _percentage);
    }

    /**
     * @notice Update recipients percentage
     * @param _recipient Address to be removed
     * @param _percentage New percentage for recipient
     */
    function updateRecipient(address payable _recipient, uint256 _percentage) external onlyOwner {
        require(recipientsPercentage[_recipient] != 0, "Recipient doesnt exists");
        recipientsPercentage[_recipient] = 0;
        require(_checkPercentage(_percentage), "Percentage exceeded 100");
        recipientsPercentage[_recipient] = _percentage;
        emit UpdateRecipient(_recipient, _percentage);
    }

    /**
     * @notice Remove recipient from revenue share
     * @param _recipient Address to be removed
     */
    function removeRecipient(address payable _recipient) external onlyOwner {
        require(recipientsPercentage[_recipient] != 0, "Recipient doesnt exists");
        recipientsPercentage[_recipient] = 0;

        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength; i++) {
            if (recipients[i] == _recipient) {
                recipients[i] = recipients[recipientsLength-1];
                recipients.pop();
                break;
            }
        }
        emit RemoveRecipient(_recipient);
    }

    /**
     * @notice Redistribute ETH that is kept in this contract
     (it can happen when sum of all recipients percentage is less than 100)
     */
    function withdraw() external {
        _redistributeEth();
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