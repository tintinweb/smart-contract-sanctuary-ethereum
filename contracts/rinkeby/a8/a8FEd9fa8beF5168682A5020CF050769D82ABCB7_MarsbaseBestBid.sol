pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

// import "hardhat/console.sol";

interface IMarsbaseBestBid
{
	struct BBBid
	{
		uint256 offerId;
		uint256 bidIdx;

		address bobAddress;

		address tokenBob;
		uint256 amountBob;
		// uint256 depositedBob;
	}
	struct BBOffer
	{
		bool active;
		uint256 id;

		address aliceAddress;

		BBOfferParams params;

		uint256 totalBidsCount;
		uint256 activeBidsCount;
	}
	struct BBOfferParams
	{
		address tokenAlice;
		uint256 amountAlice;
		// uint256 depositedAlice;

		address[] tokensBob;

		uint256 feeAlice;
		uint256 feeBob;

		// uint256 deadline;
	}

	event OfferCreated(
		uint256 indexed id,
        address indexed aliceAddress,
		address indexed tokenAlice,
        BBOfferParams params
	);
	event BidCreated(
		uint256 indexed offerId,
		address indexed bobAddress,
		address indexed tokenBob,
		uint256 bidIdx,
		bytes32 bidId,
		BBBid bid
	);
	enum OfferCloseReason {
		Success,
		CancelledBySeller,
		ContractMigrated
	}
	enum BidCancelReason {
		OfferClosed,
		CancelledByBidder,
		ContractMigrated
	}
	event OfferClosed(
		uint256 indexed id,
		address indexed aliceAddress,
		OfferCloseReason indexed reason,
		BBOffer offer
	);
	event BidAccepted(
		uint256 indexed id,
		address indexed aliceAddress,
		uint256 aliceReceivedTotal,
		uint256 aliceFeeTotal,
		uint256 bobReceivedTotal,
		uint256 bobFeeTotal,
		BBOffer offer,
		BBBid bid
	);
	event BidCancelled(
		uint256 indexed offerId,
		address indexed bobAddress,
		address indexed tokenBob,
		BidCancelReason reason,
		uint256 bidIdx,
		bytes32 bidId,
		BBBid bid
	);

	function createOffer(BBOfferParams calldata offer) external payable;
	function createBid(uint256 offerId, address tokenBob, uint256 amountBob) external payable;
	function acceptBid(uint256 offerId, uint256 bidIdx) external;
	function cancelBid(uint256 offerId, uint256 bidIdx) external;
	function cancelOffer(uint256 offerId) external;

	function getActiveOffers() external returns (BBOffer[] memory);
}
contract MarsbaseBestBid is IMarsbaseBestBid
{
	address public owner;

	uint256 public nextOfferId = 0;
	uint256 public activeOffersCount = 0;

	uint256 public minimumFee = 0;

	address public commissionWallet;
	// address public commissionExchanger;

	bool public locked = false;

	mapping(uint256 => BBOffer) public offers;
	mapping(bytes32 => BBBid) public offerBids;

	constructor(uint256 startOfferId)
	{
		owner = msg.sender;
		commissionWallet = msg.sender;
		nextOfferId = startOfferId;
	}

	// onlyOwner modifier
	modifier onlyOwner {
		require(msg.sender == owner, "403");
		_;
	}
	modifier unlocked {
		require(!locked, "409");
		_;
	}
	function setCommissionAddress(address wallet) onlyOwner public
	{
		commissionWallet = wallet;
	}
	function setMinimumFee(uint256 _minimumFee) onlyOwner public
	{
		minimumFee = _minimumFee;
	}
	function changeOwner(address newOwner) onlyOwner public
	{
		owner = newOwner;
	}

	function getActiveOffers() external view returns (BBOffer[] memory)
	{
		BBOffer[] memory activeOffers = new BBOffer[](activeOffersCount);
		uint256 i = 0;
		for (uint256 offerId = 0; offerId < nextOfferId; offerId++)
		{
			if (offers[offerId].active)
			{
				activeOffers[i] = offers[offerId];
				i++;
			}
		}
		return activeOffers;
	}
	function getBidId(uint256 offerId, uint256 bidIdx) public pure returns (bytes32 bidId)
	{
		return keccak256(abi.encode(offerId, bidIdx));
	}
	function getActiveBidsForOffer(uint256 offerId) external view returns (BBBid[] memory)
	{
		BBOffer memory offer = offers[offerId];
		BBBid[] memory bids = new BBBid[](offer.activeBidsCount);
		uint256 i = 0;
		for (uint256 bidIdx = 0; bidIdx < offer.totalBidsCount; bidIdx++)
		{
			if (offerBids[getBidId(offerId, bidIdx)].amountBob > 0)
			{
				bids[i] = offerBids[getBidId(offerId, bidIdx)];
				i++;
			}
		}
		return bids;
	}
	function getOffer(uint256 offerId) public view returns (BBOffer memory)
	{
		return offers[offerId];
	}

	function createOffer(BBOfferParams calldata offer) public payable unlocked
	{
		// basic checks
		require(offer.amountAlice > 0, "400-AAL");
		require(offer.tokensBob.length > 0, "400-BE");
		// require(offer.depositedAlice > offer.amountAlice / 10, "400-DAL");
		require(offer.feeAlice + offer.feeBob >= minimumFee, "400-FL");

		// transfer deposit
		if (offer.tokenAlice == address(0))
			require(offer.amountAlice == msg.value, "402-E");
		else
			IERC20(offer.tokenAlice).safeTransferFrom(msg.sender, address(this), offer.amountAlice);

		uint256 offerId = nextOfferId++;
		activeOffersCount++;

		offers[offerId] = BBOffer({
			active: true,
			id: offerId,
			aliceAddress: msg.sender,
			params: offer,
			totalBidsCount: 0,
			activeBidsCount: 0
		});

		emit OfferCreated({
			id: offerId,
			aliceAddress: msg.sender,
			tokenAlice: offer.tokenAlice,
			params: offer
		});
	}
	function createBid(uint256 offerId, address tokenBob, uint256 amountBob) public payable unlocked
	{
		// basic checks
		require(amountBob > 0, "400-ABL");
		require(offers[offerId].active, "400-OI");

		//
		// this check is temporary disabled to make bidding with unknown tokens possible
		// frontend is expected to filter out garbage if needed
		//
		// { // split to block to prevent solidity stack issues
		// 	bool accepted = false;
		// 	address[] memory tokensBob = offers[offerId].params.tokensBob;
		// 	for (uint256 i = 0; i < tokensBob.length; i++)
		// 	{
		// 		if (tokensBob[i] == tokenBob)
		// 		{
		// 			accepted = true;
		// 			break;
		// 		}
		// 	}
		// 	require(accepted, "404-TBI"); // Token Bob is Incorrect
		// }

		// transfer deposit
		if (tokenBob == address(0))
			require(amountBob == msg.value, "402-E");
		else
			IERC20(tokenBob).safeTransferFrom(msg.sender, address(this), amountBob);

		uint256 bidIdx = offers[offerId].totalBidsCount++;
		bytes32 bidId = getBidId(offerId, bidIdx);
		offers[offerId].activeBidsCount++;
		
		offerBids[bidId] = BBBid({
			offerId: offerId,
			bidIdx: bidIdx,
			bobAddress: msg.sender,
			tokenBob: tokenBob,
			amountBob: amountBob
			// depositedBob: amountBob
		});

		emit BidCreated({
			offerId: offerId,
			bobAddress: msg.sender,
			tokenBob: tokenBob,
			bidIdx: bidIdx,
			bidId: bidId,
			bid: offerBids[bidId]
		});
	}
	function sendEth(address to, uint256 amount) private
	{
		(bool success, ) = to.call{value: amount, gas: 30000}("");
		require(success, "404-C1");
	}
	function cancelBid(uint256 offerId, uint256 bidIdx) public unlocked
	{
		require(offers[offerId].active, "400-OI");

		bytes32 bidId = getBidId(offerId, bidIdx);

		require(offerBids[bidId].amountBob > 0, "400-BI");
		require(offerBids[bidId].bobAddress == msg.sender, "403-BI");

		_cancelBid(offerId, bidIdx, bidId, BidCancelReason.CancelledByBidder);
	}
	function _cancelBid(uint256 offerId, uint256 bidIdx, bytes32 bidId, BidCancelReason reason) private
	{
		BBBid memory bid = offerBids[bidId];
		
		// disable bid
		delete offerBids[bidId];

		offers[offerId].activeBidsCount--;

		// transfer deposit back
		if (bid.tokenBob == address(0))
			sendEth(bid.bobAddress, bid.amountBob);
		else
			IERC20(bid.tokenBob).safeTransfer(bid.bobAddress, bid.amountBob);
		
		emit BidCancelled({
			offerId: offerId,
			bobAddress: bid.bobAddress,
			tokenBob: bid.tokenBob,
			bidIdx: bidIdx,
			bidId: bidId,
			reason: reason,
			bid: bid
		});
	}
	function _cancelAllBids(uint256 offerId, BidCancelReason reason) private
	{
		uint256 length = offers[offerId].totalBidsCount;
		for (uint256 bidIdx = 0; bidIdx < length; bidIdx++)
		{
			bytes32 bidId = getBidId(offerId, bidIdx);
			if (offerBids[bidId].amountBob > 0)
			{
				_cancelBid(offerId, bidIdx, bidId, reason);
			}
		}
	}
	
	uint256 constant MAX_UINT256 = type(uint256).max;
	// max safe uint256 constant that can be calculated for 1e6 fee
	uint256 constant MAX_SAFE_TARGET_AMOUNT = MAX_UINT256 / (1e6);

	function afterFee(uint256 amountBeforeFee, uint256 feePercent) public pure returns (uint256 amountAfterFee, uint256 fee)
	{
		if (feePercent == 0)
			return (amountBeforeFee, 0);
		
		return _afterFee(amountBeforeFee, feePercent, 1e5, MAX_SAFE_TARGET_AMOUNT);
	}
	function _afterFee(uint256 amountBeforeFee, uint256 feePercent, uint256 scale, uint256 safeAmount) public pure returns (uint256 amountAfterFee, uint256 fee)
	{
		if (feePercent >= scale)
			return (0, amountBeforeFee);

		if (amountBeforeFee < safeAmount)
			fee = (amountBeforeFee * feePercent) / scale;
		else
			fee = (amountBeforeFee / scale) * feePercent;

		amountAfterFee = amountBeforeFee - fee;
		return (amountAfterFee, fee);
	}

	function _sendTokensAfterFeeFrom(
		address token,
		uint256 amount,
		address from,
		address to,
		uint256 feePercent
	) private returns (uint256 /* amountAfterFee */, uint256 /* fee */)
	{
		if (commissionWallet == address(0))
			feePercent = 0;

		(uint256 amountAfterFee, uint256 fee) = afterFee(amount, feePercent);

		// send tokens to receiver
		if (from == address(this))
			IERC20(token).safeTransfer(to, amountAfterFee);
		else
			IERC20(token).safeTransferFrom(from, to, amountAfterFee);

		if (fee > 0)
		{
			// send fee to commission wallet
			if (from == address(this))
				IERC20(token).safeTransfer(commissionWallet, fee);
			else
				IERC20(token).safeTransferFrom(from, commissionWallet, fee);
		}
		return (amountAfterFee, fee);
	}
	function _sendEthAfterFee(
		uint256 amount,
		address to,
		uint256 feePercent
	) private returns (uint256 /* amountAfterFee */, uint256 /* fee */)
	{
		if (commissionWallet == address(0))
			feePercent = 0;
		
		(uint256 amountAfterFee, uint256 fee) = afterFee(amount, feePercent);

		sendEth(to, amountAfterFee);

		if (fee > 0)
		{
			// send fee to commission wallet
			sendEth(commissionWallet, fee);
		}
		return (amountAfterFee, fee);
	}

	function _acceptBid(BBOffer memory offer, BBBid memory bid) private
	{
		uint256 aliceReceivedTotal;
		uint256 aliceFeeTotal;
		uint256 bobReceivedTotal;
		uint256 bobFeeTotal;

		// send $BOB tokens to Alice
		if (bid.tokenBob == address(0))
			(bobReceivedTotal, bobFeeTotal) = _sendEthAfterFee(bid.amountBob, offer.aliceAddress, offer.params.feeAlice);
		else
			(bobReceivedTotal, bobFeeTotal) = _sendTokensAfterFeeFrom(bid.tokenBob, bid.amountBob, address(this), offer.aliceAddress, offer.params.feeAlice);
		
		// send $ALICE tokens to Bob
		if (offer.params.tokenAlice == address(0))
			(aliceReceivedTotal, aliceFeeTotal) = _sendEthAfterFee(offer.params.amountAlice, bid.bobAddress, offer.params.feeBob);
		else
			(aliceReceivedTotal, aliceFeeTotal) = _sendTokensAfterFeeFrom(offer.params.tokenAlice, offer.params.amountAlice, address(this), bid.bobAddress, offer.params.feeBob);

		// emit accept event
		emit BidAccepted({
			id: offer.id,
			aliceAddress: offer.aliceAddress,
			aliceReceivedTotal: aliceReceivedTotal,
			aliceFeeTotal: aliceFeeTotal,
			bobReceivedTotal: bobReceivedTotal,
			bobFeeTotal: bobFeeTotal,
			offer: offer,
			bid: bid
		});
	}
	function acceptBid(uint256 offerId, uint256 bidIdx) public unlocked
	{
		// basic checks
		require(offers[offerId].active, "400-OI");
		require(offers[offerId].aliceAddress == msg.sender, "403-AI");

		BBOffer memory offer = offers[offerId];
		// get bid
		BBBid memory bid = offerBids[getBidId(offerId, bidIdx)];
		require(bid.amountBob > 0, "400-BI");

		offers[offerId].active = false;
		delete offerBids[getBidId(offerId, bidIdx)];

		_acceptBid(offer, bid);

		// cancel all other bids
		_cancelAllBids(offerId, BidCancelReason.OfferClosed);
		
		// destroy offer
		delete offers[offerId];
		activeOffersCount--;

		// emit offer closed event
		emit OfferClosed({
			id: offerId,
			aliceAddress: offer.aliceAddress,
			reason: OfferCloseReason.Success,
			offer: offer
		});
	}
	function cancelOffer(uint256 offerId) public unlocked
	{
		// basic checks
		require(offers[offerId].active, "400-OI");
		require(offers[offerId].aliceAddress == msg.sender, "403-AI");
		
		_cancelOffer(offerId, BidCancelReason.OfferClosed, OfferCloseReason.CancelledBySeller);
	}
	function _cancelOffer(uint256 offerId, BidCancelReason bidReason, OfferCloseReason offerReason) private
	{
		offers[offerId].active = false;

		BBOffer memory offer = offers[offerId];
		
		// cancel all other bids
		_cancelAllBids(offerId, bidReason);

		// return $ALICE tokens to Alice
		if (offer.params.tokenAlice == address(0))
			sendEth(offer.aliceAddress, offer.params.amountAlice);
		else
			IERC20(offer.params.tokenAlice).safeTransfer(offer.aliceAddress, offer.params.amountAlice);
		
		delete offers[offerId];
		activeOffersCount--;
		
		// emit offer closed event
		emit OfferClosed({
			id: offerId,
			aliceAddress: offers[offerId].aliceAddress,
			reason: offerReason,
			offer: offer
		});
	}
	function lockContract() onlyOwner public
	{
		locked = true;
	}
	function cancelBids(uint256 offerId, uint256 from, uint256 to) onlyOwner public payable
	{
		for (uint256 bidIdx = from; bidIdx < to; bidIdx++)
		{
			bytes32 bidId = getBidId(offerId, bidIdx);
			if (offerBids[bidId].amountBob > 0)
			{
				_cancelBid(offerId, bidIdx, bidId, BidCancelReason.ContractMigrated);
			}
		}
	}
	function cancelOffers(uint256 from, uint256 to) onlyOwner public payable
	{
		for (uint256 offerId = from; offerId < to; offerId++)
		{
			BBOffer memory offer = offers[offerId];
			if (offer.active)
			{
				_cancelOffer(offerId, BidCancelReason.ContractMigrated, OfferCloseReason.ContractMigrated);
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title MarsBase Common
/// @author dOTC Marsbase
/// @notice This library contains struct and enum definitions for the MarsBase Exchange and MarsBase Contracts.
library MarsBaseCommon {

  enum OfferType {
    FullPurchase,
    LimitedTime,
    ChunkedPurchase,
    LimitedTimeChunkedPurchase,
    MinimumChunkedPurchase,
    LimitedTimeMinimumPurchase,
    LimitedTimeMinimumChunkedPurchase,
    LimitedTimeMinimumChunkedDeadlinePurchase
  }

  enum OfferCloseReason {
    Success,
    CancelledBySeller,
    DeadlinePassed
  }

  /// @dev Offers is a simple offer type, that does the exchange immediately in all cases.
  /// @dev Minimum Offers can hold tokens until certain criteria are met.
  enum ContractType {
    Offers,
    MinimumOffers
  }

  struct OfferParams {
    bool cancelEnabled;
    bool modifyEnabled;
    bool holdTokens;
    uint256 feeAlice;
    uint256 feeBob;
    uint256 smallestChunkSize;
    uint256 deadline;
    uint256 minimumSize;
  }

/// @notice Primary Offer Data Structure
/// @notice Primary Offer Data Structure
/// @notice smallestChunkSize - Smallest amount that may be purchased in one transaction
  struct MBOffer {
    bool active;
    bool minimumMet;
    OfferType offerType;
    uint256 offerId;
    uint256 amountAlice;
    uint256 feeAlice;
    uint256 feeBob;
    uint256 smallestChunkSize;
    uint256 minimumSize;
    uint256 deadline;
    uint256 amountRemaining;
    address offerer;
    address payoutAddress;
    address tokenAlice;
	
	// capabilities[0] = Modifiable
	// capabilities[1] = Cancel Enabled
	// capabilities[2] = Should not distribute tokens until deadline (for minimum Offers)
    bool[3] capabilities;
    uint256[] amountBob;
    uint256[] minimumOrderAmountsAlice;
    uint256[] minimumOrderAmountsBob;
    address[] minimumOrderAddresses;
    address[] minimumOrderTokens;
    address[] tokenBob;
  }
  /// Emitted when an offer is created
    event OfferCreated(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        MarsBaseCommon.MBOffer offer
    );
	
	/// Emitted when an offer has it's parameters or capabilities modified
    event OfferModified(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        MarsBaseCommon.OfferParams offerParameters
    );

    /// Emitted when an offer is accepted.
    /// This includes partial transactions, where the whole offer is not bought out and those where the exchange is not finallized immediatley.
    event OfferAccepted(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        uint256 amountAliceReceived,
        uint256 amountBobReceived,
        address tokenAddressAlice,
        address tokenAddressBob,
        MarsBaseCommon.OfferType offerType,
        uint256 feeAlice,
        uint256 feeBob
    );

    /// Emitted when the offer is cancelled either by the creator or because of an unsuccessful auction
    event OfferCancelled(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp
    );

    event OfferClosed(
        uint256 offerId,
        MarsBaseCommon.OfferCloseReason reason,
        uint256 blockTimestamp
    );

    event ContractMigrated();

    /// Emitted when a buyer cancels their bid for a offer were tokens have not been exchanged yet and are still held by the contract.
    event BidCancelled(uint256 offerId, address sender, uint256 blockTimestamp);

    /// Emitted only for testing usage
    event Log(uint256 log);
	
    struct MBAddresses {
        address offersContract;
        address minimumOffersContract;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}