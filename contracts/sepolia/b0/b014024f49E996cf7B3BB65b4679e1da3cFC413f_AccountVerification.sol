// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Account Verification v0.1
 * @author DeployLabs.io
 *
 * @notice This contract is used for paying for account verification.
 */
contract AccountVerification is Ownable {
	uint256 private s_verificationPrice = 0.01 ether;
	mapping(address => string) private s_accountUrls;

	// Verification related events
	event AccountVerified(address indexed account, string accountUrl);

	// Verification related errors
	error AccountVerification__IncorrectUrl();

	// ETH related errors
	error AccountVerification__EthAmountIsIncorrect();
	error AccountVerification__NotEnoughEth();
	error AccountVerification__TransferFundsFailed();

	/**
	 * @notice Verify an account.
	 * @param accountUrl The URL to link to the account.
	 */
	function payForVerification(string memory accountUrl) external payable {
		if (msg.value != s_verificationPrice) revert AccountVerification__EthAmountIsIncorrect();
		if (bytes(accountUrl).length == 0) revert AccountVerification__IncorrectUrl();

		emit AccountVerified(msg.sender, accountUrl);
		s_accountUrls[msg.sender] = accountUrl;
	}

	/**
	 * @notice Set the price for account verification.
	 * @param verificationPrice The new price.
	 */
	function setVerificationPrice(uint256 verificationPrice) external onlyOwner {
		s_verificationPrice = verificationPrice;
	}

	/**
	 * @notice Withdraw accumulated market fees.
	 * @param to The address to send the funds to.
	 * @param amount The amount to withdraw.
	 */
	function withdrawFunds(address payable to, uint256 amount) external onlyOwner {
		if (amount > address(this).balance) revert AccountVerification__NotEnoughEth();

		_transferFunds(amount, to);
	}

	/**
	 * @notice Returns the price for account verification.
	 * @return The price in wei.
	 */
	function getVerificationPrice() external view returns (uint256) {
		return s_verificationPrice;
	}

	/**
	 * @notice Returns the URL linked to an account.
	 * @param account The account address.
	 * @return The URL.
	 */
	function getAccountUrl(address account) external view returns (string memory) {
		return s_accountUrls[account];
	}

	function _transferFunds(uint256 amount, address payable to) internal {
		(bool success, ) = to.call{ value: amount }("");
		if (!success) revert AccountVerification__TransferFundsFailed();
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