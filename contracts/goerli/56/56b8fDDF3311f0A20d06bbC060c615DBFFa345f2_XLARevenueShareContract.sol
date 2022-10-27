// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract XLARevenueShareContract is Ownable {
    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;
    uint256 public numberOfRecipients = 0;

    event AddRecipient(address recipient, uint256 percentage, string name);
    event RemoveAll(address payable [] recipients);
    event UpdateRecipient(address recipient, uint256 percentage);

    fallback() external payable {
        _redistributeEth();
    }

    receive() external payable {
        _redistributeEth();
    }

    /**
     * @notice Internal function to redistribute ETH based on percentages assign to the recipients
     */
    function _redistributeEth() internal {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength > 0, "empty recipients");

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = msg.value / 10000 * percentage;
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            require(success, "Token transfer failed");
            unchecked{i++;}
        }
    }

    /**
     * @notice Internal function to check whether percentages are equal to 100%
     * @return valid boolean indicating whether sum of percentage == 100%
     */
    function _percentageIsValid() internal view returns (bool valid){
        uint256 recipientsLength = recipients.length;
        uint256 percentageSum;

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            percentageSum += recipientsPercentage[recipient];
            unchecked {i++;}
        }

        return percentageSum == 10000;
    }

    /**
     * @notice Internal function for adding recipient to revenue share
     * @param _recipient Fixed amount of token user want to buy
     * @param _percentage code of the affiliation partner
     */
    function _addRecipient(address payable _recipient, uint256 _percentage, string calldata _name) internal {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(recipientsPercentage[_recipient] == 0, "Recipient already added");
        recipients.push(_recipient);
        recipientsPercentage[_recipient] = _percentage;
        numberOfRecipients += 1;
        emit AddRecipient(_recipient, _percentage, _name);
    }

    /**
     * @notice function for removing all recipients
     */
    function removeAll() public onlyOwner {
        if (numberOfRecipients == 0) {
            return;
        }

        emit RemoveAll(recipients);
        for (uint256 i = 0; i < numberOfRecipients;) {
            address recipient = recipients[i];
            recipientsPercentage[recipient] = 0;
            unchecked{i++;}
        }
        delete recipients;
        numberOfRecipients = 0;
    }

    /**
     * @notice Set recipients in one TX
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for
     */
    function setRecipients(
        address[] calldata _newRecipients,
        uint256[] calldata _percentages,
        string[] calldata _names
    ) external onlyOwner {
        uint256 newRecipientsLength = _newRecipients.length;
        require(newRecipientsLength == _percentages.length, "Recipients length does not much percentages");

        removeAll();

        for (uint256 i = 0; i < newRecipientsLength;) {
            _addRecipient(payable(_newRecipients[i]), _percentages[i], _names[i]);
            unchecked{i++;}
        }

        require(_percentageIsValid(), "Percentage Sum is not equal 100");
    }


    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     */
    function redistributeToken(address token) external {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength > 0, "empty recipients");

        IERC20 erc20Token = IERC20(token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));
        require(contractBalance > 0, "Nothing to distribute");

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = contractBalance / 10000 * percentage;
            erc20Token.transfer(recipient, amountToReceive);
            unchecked{i++;}
        }

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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