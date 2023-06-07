// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Market Fees v0.4
 * @author DeployLabs.io
 *
 * @notice This contract manages market fees for a platform that supports royalty distribution.
 */
contract MarketFees is Ownable {
	/**
	 * @notice Represents information about the royalty fees distribution for a collection.
	 * @param reciever The address that will receive the royalty fees.
	 * @param share The percentage of royalty fees the receiver gets. (1 share = 0.01%)
	 */
	struct RoyaltyConfig {
		address payable receiver;
		uint16 share;
	}

	uint16 private constant BASIS_POINTS_PER_HUNDREED_PERCENT = 10000;
	uint16 private constant MAX_FEE_BASIS_POINTS = 100 * 10;

	mapping(address => RoyaltyConfig[]) private s_royaltyConfigs;
	mapping(address => uint256) private s_accumulatedRoyaltyFees;

	uint256 private s_accumulatedMarketFees;

	// Fee related events
	event FeesContributed(
		address indexed collection,
		uint256 royaltyFeesAmount,
		uint256 marketFeesAmount
	);

	// Royalty related events
	event RoyaltyConfigsSet(address indexed collection, RoyaltyConfig[] royaltyConfigs);
	event RoyaltiesWithdrawn(address indexed collection, address indexed receiver, uint256 amount);

	// Input related errors
	error MarketFees__ZeroAddressProhibited();

	// Ownership related errors
	error MarketFees__NotTheCollectionOwner();

	// Fee and royalty related errors
	error MarketFees__FeeIsOverTheLimit();
	error MarketFees__NotARoyaltyReceiver();

	// ETH amount related errors
	error MarketFees__NotEnoughEth();
	error MarketFees__EthAmountIsIncorrect();
	error MarketFees__TransferFundsFailed();

	/**
	 * @notice Contribute fees for a given collection.
	 * @param collection The collection address to contribute fees to.
	 * @param fromAmount The amount used to calculate fees.
	 * @param marketPartBasisPoints The market fees part in basis points.
	 */
	function contributeFees(
		address collection,
		uint256 fromAmount,
		uint16 marketPartBasisPoints
	) external payable {
		uint256 marketFees = (fromAmount * marketPartBasisPoints) /
			BASIS_POINTS_PER_HUNDREED_PERCENT;
		uint256 royaltyFees = (fromAmount * getTotalRoyaltyBasisPoints(collection)) /
			BASIS_POINTS_PER_HUNDREED_PERCENT;

		uint256 totalFees = marketFees + royaltyFees;
		if (totalFees > msg.value) revert MarketFees__EthAmountIsIncorrect();

		emit FeesContributed(collection, royaltyFees, marketFees);
		s_accumulatedMarketFees += marketFees;
		s_accumulatedRoyaltyFees[collection] += royaltyFees;
	}

	/**
	 * @notice Set royalty configuration for a collection.
	 * @param collection The address of the collection.
	 * @param royaltyConfigs The royalty configuration to be set.
	 */
	function setRoyaltyConfig(
		address collection,
		RoyaltyConfig[] calldata royaltyConfigs
	) external {
		if (Ownable(collection).owner() != msg.sender) revert MarketFees__NotTheCollectionOwner();

		uint16 totalShares = 0;
		for (uint256 i = 0; i < royaltyConfigs.length; i++) totalShares += royaltyConfigs[i].share;
		if (totalShares > MAX_FEE_BASIS_POINTS) revert MarketFees__FeeIsOverTheLimit();

		delete s_royaltyConfigs[collection];
		for (uint256 i = 0; i < royaltyConfigs.length; i++) {
			s_royaltyConfigs[collection].push(royaltyConfigs[i]);
		}

		emit RoyaltyConfigsSet(collection, royaltyConfigs);
	}

	/**
	 * @notice Withdraw accumulated market fees.
	 * @param to The address to send the funds to.
	 * @param amount The amount to withdraw.
	 */
	function withdrawMarketFees(address payable to, uint256 amount) external onlyOwner {
		if (to == address(0)) revert MarketFees__ZeroAddressProhibited();
		if (amount > address(this).balance) revert MarketFees__NotEnoughEth();

		s_accumulatedMarketFees -= amount;

		_transferFunds(amount, payable(msg.sender));
	}

	/**
	 * @notice Withdraw royalties for a collection.
	 * @param collection The address of the collection to withdraw royalties from.
	 */
	function withdrawRoyalties(address collection) external {
		RoyaltyConfig[] memory royaltyConfigs = s_royaltyConfigs[collection];

		uint256 amount = s_accumulatedRoyaltyFees[collection];
		s_accumulatedRoyaltyFees[collection] = 0;

		bool isOneOfTheReceivers = false;
		for (uint256 i = 0; i < royaltyConfigs.length; i++) {
			address payable reciever = royaltyConfigs[i].receiver;
			uint256 ethShare = (amount * royaltyConfigs[i].share) /
				BASIS_POINTS_PER_HUNDREED_PERCENT;

			if (reciever == msg.sender) isOneOfTheReceivers = true;

			_transferFunds(ethShare, reciever);
			emit RoyaltiesWithdrawn(collection, reciever, ethShare);
		}

		if (!isOneOfTheReceivers) revert MarketFees__NotARoyaltyReceiver();
	}

	/**
	 * @notice Get royalty configurations for a collection.
	 * @param collection The address of the collection.
	 * @return The royalty configurations for the collection.
	 */
	function getRoyaltyConfigs(address collection) external view returns (RoyaltyConfig[] memory) {
		return s_royaltyConfigs[collection];
	}

	/**
	 * @notice Calculate fees amount for a given collection and base amount.
	 * @param collection The address of the collection.
	 * @param fromAmount The base amount to calculate fees from.
	 * @param marketPartBasisPoints The market fees part in basis points.
	 * @return The calculated fees amount.
	 */
	function getFeesAmount(
		address collection,
		uint256 fromAmount,
		uint16 marketPartBasisPoints
	) external view returns (uint256) {
		uint256 marketFees = (fromAmount * marketPartBasisPoints) /
			BASIS_POINTS_PER_HUNDREED_PERCENT;
		uint256 royaltyFees = (fromAmount * getTotalRoyaltyBasisPoints(collection)) /
			BASIS_POINTS_PER_HUNDREED_PERCENT;

		return marketFees + royaltyFees;
	}

	/**
	 * @notice Get the accumulated market fees.
	 * @return The accumulated market fees.
	 */
	function getAccumulatedMarketFees() external view returns (uint256) {
		return s_accumulatedMarketFees;
	}

	/**
	 * @notice Get the accumulated fees for a specific collection.
	 * @param collection The address of the collection.
	 * @return The accumulated fees for the collection.
	 */
	function getAccumulatedRoyaltyFees(address collection) external view returns (uint256) {
		return s_accumulatedRoyaltyFees[collection];
	}

	/**
	 * @notice Get the total royalty basis points for a collection.
	 * @param collection The address of the collection.
	 * @return totalShares The total royalty basis points for the collection.
	 */
	function getTotalRoyaltyBasisPoints(
		address collection
	) public view returns (uint16 totalShares) {
		RoyaltyConfig[] memory royaltyConfigs = s_royaltyConfigs[collection];
		for (uint256 i = 0; i < royaltyConfigs.length; i++) totalShares += royaltyConfigs[i].share;
	}

	function _transferFunds(uint256 amount, address payable to) internal {
		(bool success, ) = to.call{ value: amount }("");
		if (!success) revert MarketFees__TransferFundsFailed();
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