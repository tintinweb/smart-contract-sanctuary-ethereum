// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/Ownable.sol";
import "./Warden.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IBoostV2.sol";
import "./utils/Errors.sol";

/** @title WardenMultiBuy contract  */
/**
    This contract's purpose is to allow easier purchase of multiple Boosts at once
    Can either:
        - Buy blindly from the Offers list, without sorting,
            with the parameters : maximum Price, and clearExpired (if false: will skip Delegators that could be available 
            after canceling their expired Boosts => less gas used)
        - Buy using a presorted array of Offers index (with the same parameters available)
        - Buy by performing a quickSort over the Offers, to start with the cheapest ones (with the same parameters available)
 */
/// @author Paladin
contract WardenMultiBuy is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant UNIT = 1e18;
    uint256 public constant MAX_PCT = 10000;
    uint256 public constant WEEK = 7 * 86400;

    /** @notice ERC20 used to pay for DelegationBoost */
    IERC20 public feeToken;
    /** @notice Address of the votingToken */
    IVotingEscrow public votingEscrow;
    /** @notice Address of the Delegation Boost contract */
    IBoostV2 public delegationBoost;
    /** @notice Address of the Warden contract */
    Warden public warden;


    // Constructor :
    /**
     * @dev Creates the contract, set the given base parameters
     * @param _feeToken address of the token used to pay fees
     * @param _votingEscrow address of the voting token to delegate
     * @param _delegationBoost address of the veBoost contract
     * @param _warden address of Warden
     */
    constructor(
        address _feeToken,
        address _votingEscrow,
        address _delegationBoost,
        address _warden
    ) {
        feeToken = IERC20(_feeToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        delegationBoost = IBoostV2(_delegationBoost);
        warden = Warden(_warden);
    }


    struct MultiBuyVars {
        // Duration of the Boosts in seconds
        uint256 boostDuration;
        // Total count of Offers in the Warden Offer List
        uint256 totalNbOffers;
        // Timestamp of the end of Boosts
        uint256 boostEndTime;
        // Expiry Timestamp for the veBoost
        uint256 expiryTime;
        // Balance of this contract before the execution
        uint256 previousBalance;
        // Balance of this contract after the execution
        uint256 endBalance;
        // Amount of veToken still needed to buy to fill the Order
        uint256 missingAmount;
        // Amount of veToken Boosts bought
        uint256 boughtAmount;
        // Minimum Percent of veBoost given by the Warden contract
        uint256 wardenMinRequiredPercent;
    }

    // Variables used in the For looping over the Offers
    struct OfferVars {
        // Total amount of Delegator's veCRV available for veBoost creation
        uint256 availableUserBalance;
        // Amount to buy from the current Offer
        uint256 toBuyAmount;
        // Address of the Delegator issuing the Boost
        address delegator;
        // Price listed in the Offer
        uint256 offerPrice;
        // Maximum duration for veBoost on this Offer
        uint256 offerMaxDuration;
        // Minimum required percent for veBoost on this Offer
        uint256 offerminPercent;
        // Amount of fees to pay for the veBoost creation
        uint256 boostFeeAmount;
        // Size in percent of the veBoost to create
        uint256 boostPercent;
        // ID of the newly created veBoost token
        uint256 newTokenId;
    }

    /**
     * @notice Loops over Warden Offers to purchase veBoosts depending on given parameters
     * @dev Using given parameters, loops over Offers given from the basic Warden order, to purchased Boosts that fit the given parameters
     * @param receiver Address of the veBoosts receiver
     * @param duration Duration (in weeks) for the veBoosts to purchase
     * @param boostAmount Total Amount of veCRV boost to purchase
     * @param maxPrice Maximum price for veBoost purchase (price is in feeToken/second, in wei), any Offer with a higher price will be skipped
     * @param minRequiredAmount Minimum size of the Boost to buy, smaller will be skipped
     * @param totalFeesAmount Maximum total amount of feeToken available to pay to for veBoost purchases (in wei)
     * @param acceptableSlippage Maximum acceptable slippage for the total Boost amount purchased (in BPS)
     */
    function simpleMultiBuy(
        address receiver,
        uint256 duration, //in number of weeks
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount,
        uint256 totalFeesAmount,
        uint256 acceptableSlippage //BPS
    ) external returns (bool) {
        // Checks over parameters
        if(receiver == address(0)) revert Errors.ZeroAddress();
        if(boostAmount == 0 || totalFeesAmount == 0 || acceptableSlippage == 0) revert Errors.NullValue();
        if(maxPrice == 0) revert Errors.NullPrice();

        MultiBuyVars memory vars;

        // Calculate the duration of veBoosts to purchase
        vars.boostDuration = duration * 1 weeks;
        if(vars.boostDuration < warden.minDelegationTime()) revert Errors.DurationTooShort();

        // Fetch the total number of Offers to loop over
        vars.totalNbOffers = warden.offersIndex();

        // Calculate the expiryTime of veBoosts to create (used for later check over Seller veCRV lock__end)
        // For detailed explanation, see Warden _buyDelegationBoost() comments
        vars.boostEndTime = block.timestamp + vars.boostDuration;
        vars.expiryTime = (vars.boostEndTime / WEEK) * WEEK;
        vars.expiryTime = (vars.expiryTime < vars.boostEndTime)
            ? ((vars.boostEndTime + WEEK) / WEEK) * WEEK
            : vars.expiryTime;
        // Check the max total amount of fees to pay (using the maxPrice given as argument, Buyer should pay this amount or less in the end)
        if(((boostAmount * maxPrice * (vars.expiryTime - block.timestamp)) / UNIT) > totalFeesAmount) revert Errors.NotEnoughFees();

        // Get the current fee token balance of this contract
        vars.previousBalance = feeToken.balanceOf(address(this));

        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(msg.sender, address(this), totalFeesAmount);

        //Set the approval to 0, then set it to totalFeesAmount (CRV : race condition)
        if(feeToken.allowance(address(this), address(warden)) != 0) feeToken.safeApprove(address(warden), 0);
        feeToken.safeApprove(address(warden), totalFeesAmount);

        // The amount of veCRV to purchase through veBoosts
        // & the amount currently purchased, updated at every purchase
        vars.missingAmount = boostAmount;
        vars.boughtAmount = 0;

        vars.wardenMinRequiredPercent = warden.minPercRequired();

        // Loop over all the Offers
        for (uint256 i = 1; i < vars.totalNbOffers;) { //since the offer at index 0 is useless

            // Break the loop if the target veCRV amount is purchased
            if(vars.missingAmount == 0) break;

            OfferVars memory varsOffer;

            // Get the available amount of veCRV for the Delegator
            varsOffer.availableUserBalance = _availableAmount(i, maxPrice, vars.expiryTime);
            //Offer is not available or not in the required parameters
            if (varsOffer.availableUserBalance == 0) {
                unchecked{ ++i; }
                continue;
            }
            //Offer has an available amount smaller than the required minimum
            if (varsOffer.availableUserBalance < minRequiredAmount) {
                unchecked{ ++i; }
                continue;
            }

            // If the available amount if larger than the missing amount, buy only the missing amount
            varsOffer.toBuyAmount = varsOffer.availableUserBalance > vars.missingAmount ? vars.missingAmount : varsOffer.availableUserBalance;

            // Fetch the Offer data
            (varsOffer.delegator, varsOffer.offerPrice, varsOffer.offerMaxDuration,, varsOffer.offerminPercent,) = warden.getOffer(i);

            //If the asked duration is over the max duration for this offer, we skip
            if(duration > varsOffer.offerMaxDuration) {
                unchecked{ ++i; }
                continue;
            }

            // Calculate the amount of fees to pay for that Boost purchase
            varsOffer.boostFeeAmount = (varsOffer.toBuyAmount * varsOffer.offerPrice * (vars.expiryTime - block.timestamp)) / UNIT;

            // Calculate the size of the Boost to buy in percent (BPS)
            varsOffer.boostPercent = (varsOffer.toBuyAmount * MAX_PCT) / votingEscrow.balanceOf(varsOffer.delegator);
            // Offer available percent is under Warden's minimum required percent
            if(varsOffer.boostPercent < vars.wardenMinRequiredPercent || varsOffer.boostPercent < varsOffer.offerminPercent) {
                unchecked{ ++i; }
                continue;
            }

            // Purchase the Boost, retrieve the tokenId
            varsOffer.newTokenId = warden.buyDelegationBoost(varsOffer.delegator, receiver, varsOffer.toBuyAmount, duration, varsOffer.boostFeeAmount);

            // New tokenId should never be 0, if we receive a null ID, purchase failed
            if(varsOffer.newTokenId == 0) revert Errors.FailBoostPurchase();

            // Update the missingAmount, and the total amount purchased, with the last purchased executed
            vars.missingAmount -= varsOffer.toBuyAmount;
            vars.boughtAmount += varsOffer.toBuyAmount;

            unchecked{ ++i; }
        }

        // Compare the total purchased amount (sum of all veBoost amounts) with the given target amount
        // If the purchased amount does not fall in the acceptable slippage, revert the transaction
        if(vars.boughtAmount < ((boostAmount * (MAX_PCT - acceptableSlippage)) / MAX_PCT)) 
            revert Errors.CannotMatchOrder();

        //Return all unused feeTokens to the Buyer
        vars.endBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(msg.sender, (vars.endBalance - vars.previousBalance));

        return true;
    }

    /**
     * @notice Loops over a given Array of Warden Offers (pre-sorted if possible) to purchase veBoosts depending on given parameters
     * @dev Using given parameters, loops over Offers using the given Index array, to purchased Boosts that fit the given parameters
     * @param receiver Address of the veBoosts receiver
     * @param duration Duration (in weeks) for the veBoosts to purchase
     * @param boostAmount Total Amount of veCRV boost to purchase
     * @param maxPrice Maximum price for veBoost purchase (price is in feeToken/second, in wei), any Offer with a higher price will be skipped
     * @param minRequiredAmount Minimum size of the Boost to buy, smaller will be skipped
     * @param totalFeesAmount Maximum total amount of feeToken available to pay to for veBoost purchases (in wei)
     * @param acceptableSlippage Maximum acceptable slippage for the total Boost amount purchased (in BPS)
     * @param sortedOfferIndexes Array of Warden Offer indexes (that can be sorted/only containing a given set or Orders)
     */
    function preSortedMultiBuy(
        address receiver,
        uint256 duration,
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount,
        uint256 totalFeesAmount,
        uint256 acceptableSlippage, //BPS
        uint256[] memory sortedOfferIndexes
    ) external returns (bool) {
        return _sortedMultiBuy(
        receiver,
        duration,
        boostAmount,
        maxPrice,
        minRequiredAmount,
        totalFeesAmount,
        acceptableSlippage,
        sortedOfferIndexes
        );
    }

    /**
     * @notice Loops over Warden Offers sorted through the Quicksort method, sorted by price, to purchase veBoosts depending on given parameters
     * @dev Using given parameters, loops over Offers using the order given through the Quicksort method, to purchased Boosts that fit the given parameters
     * @param receiver Address of the veBoosts receiver
     * @param duration Duration (in weeks) for the veBoosts to purchase
     * @param boostAmount Total Amount of veCRV boost to purchase
     * @param maxPrice Maximum price for veBoost purchase (price is in feeToken/second, in wei), any Offer with a higher price will be skipped
     * @param minRequiredAmount Minimum size of the Boost to buy, smaller will be skipped
     * @param totalFeesAmount Maximum total amount of feeToken available to pay to for veBoost purchases (in wei)
     * @param acceptableSlippage Maximum acceptable slippage for the total Boost amount purchased (in BPS)
     */
    function sortingMultiBuy(
        address receiver,
        uint256 duration,
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount,
        uint256 totalFeesAmount,
        uint256 acceptableSlippage //BPS
    ) external returns (bool) {
        // Get the sorted Offers through Quicksort 
        uint256[] memory sortedOfferIndexes = _quickSortOffers();

        return _sortedMultiBuy(
        receiver,
        duration,
        boostAmount,
        maxPrice,
        minRequiredAmount,
        totalFeesAmount,
        acceptableSlippage,
        sortedOfferIndexes
        );
    }



    function _sortedMultiBuy(
        address receiver,
        uint256 duration,
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount, //minimum size of the Boost to buy, smaller will be skipped
        uint256 totalFeesAmount,
        uint256 acceptableSlippage, //BPS
        uint256[] memory sortedOfferIndexes
    ) internal returns(bool) {
        // Checks over parameters
        if(receiver == address(0)) revert Errors.ZeroAddress();
        if(boostAmount == 0 || totalFeesAmount == 0 || acceptableSlippage == 0) revert Errors.NullValue();
        if(maxPrice == 0) revert Errors.NullPrice();


        MultiBuyVars memory vars;

        // Calculate the duration of veBoosts to purchase
        vars.boostDuration = duration * 1 weeks;
        if(vars.boostDuration < warden.minDelegationTime()) revert Errors.DurationTooShort();

        // Fetch the total number of Offers to loop over
        if(sortedOfferIndexes.length == 0) revert Errors.EmptyArray();

        // Calculate the expiryTime of veBoosts to create (used for later check over Seller veCRV lock__end)
        // For detailed explanation, see Warden _buyDelegationBoost() comments
        vars.boostEndTime = block.timestamp + vars.boostDuration;
        vars.expiryTime = (vars.boostEndTime / WEEK) * WEEK;
        vars.expiryTime = (vars.expiryTime < vars.boostEndTime)
            ? ((vars.boostEndTime + WEEK) / WEEK) * WEEK
            : vars.expiryTime;
        // Check the max total amount of fees to pay (using the maxPrice given as argument, Buyer should pay this amount or less in the end)
        if(((boostAmount * maxPrice * (vars.expiryTime - block.timestamp)) / UNIT) > totalFeesAmount) revert Errors.NotEnoughFees();

        // Get the current fee token balance of this contract
        vars.previousBalance = feeToken.balanceOf(address(this));

        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(msg.sender, address(this), totalFeesAmount);

        //Set the approval to 0, then set it to totalFeesAmount (CRV : race condition)
        if(feeToken.allowance(address(this), address(warden)) != 0) feeToken.safeApprove(address(warden), 0);
        feeToken.safeApprove(address(warden), totalFeesAmount);

        // The amount of veCRV to purchase through veBoosts
        // & the amount currently purchased, updated at every purchase
        vars.missingAmount = boostAmount;
        vars.boughtAmount = 0;

        vars.wardenMinRequiredPercent = warden.minPercRequired();

        // Loop over all the sorted Offers
        for (uint256 i = 0; i < sortedOfferIndexes.length;) {

            // Check that the given Offer Index is valid & listed in Warden
            if(sortedOfferIndexes[i] == 0 || sortedOfferIndexes[i] >= warden.offersIndex()) revert Errors.InvalidBoostOffer();

            // Break the loop if the target veCRV amount is purchased
            if(vars.missingAmount == 0) break;

            OfferVars memory varsOffer;

            // Get the available amount of veCRV for the Delegator
            varsOffer.availableUserBalance = _availableAmount(sortedOfferIndexes[i], maxPrice, vars.expiryTime);
            //Offer is not available or not in the required parameters
            if (varsOffer.availableUserBalance == 0) {
                unchecked{ ++i; }
                continue;
            }
            //Offer has an available amount smaller than the required minimum
            if (varsOffer.availableUserBalance < minRequiredAmount) {
                unchecked{ ++i; }
                continue;
            }

            // If the available amount if larger than the missing amount, buy only the missing amount
            varsOffer.toBuyAmount = varsOffer.availableUserBalance > vars.missingAmount ? vars.missingAmount : varsOffer.availableUserBalance;

            // Fetch the Offer data
            (varsOffer.delegator, varsOffer.offerPrice, varsOffer.offerMaxDuration,, varsOffer.offerminPercent,) = warden.getOffer(sortedOfferIndexes[i]);

            //If the asked duration is over the max duration for this offer, we skip
            if(duration > varsOffer.offerMaxDuration) {
                unchecked{ ++i; }
                continue;
            }

            // Calculate the amount of fees to pay for that Boost purchase
            varsOffer.boostFeeAmount = (varsOffer.toBuyAmount * varsOffer.offerPrice * (vars.expiryTime - block.timestamp)) / UNIT;

            // Calculate the size of the Boost to buy in percent (BPS)
            varsOffer.boostPercent = (varsOffer.toBuyAmount * MAX_PCT) / votingEscrow.balanceOf(varsOffer.delegator);
            // Offer available percent is under Warden's minimum required percent
            if(varsOffer.boostPercent < vars.wardenMinRequiredPercent || varsOffer.boostPercent < varsOffer.offerminPercent) {
                unchecked{ ++i; }
                continue;
            } 

            // Purchase the Boost, retrieve the tokenId
            varsOffer.newTokenId = warden.buyDelegationBoost(varsOffer.delegator, receiver, varsOffer.toBuyAmount, duration, varsOffer.boostFeeAmount);

            // New tokenId should never be 0, if we receive a null ID, purchase failed
            if(varsOffer.newTokenId == 0) revert Errors.FailBoostPurchase();

            // Update the missingAmount, and the total amount purchased, with the last purchased executed
            vars.missingAmount -= varsOffer.toBuyAmount;
            vars.boughtAmount += varsOffer.toBuyAmount;

            unchecked{ ++i; }
        }

        // Compare the total purchased amount (sum of all veBoost amounts) with the given target amount
        // If the purchased amount does not fall in the acceptable slippage, revert the transaction
        if(vars.boughtAmount < ((boostAmount * (MAX_PCT - acceptableSlippage)) / MAX_PCT)) 
            revert Errors.CannotMatchOrder();

        //Return all unused feeTokens to the Buyer
        vars.endBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(msg.sender, (vars.endBalance - vars.previousBalance));

        return true;
    }

    // Method used for Tests to get the sorted array of Offers
    function getSortedOffers() external view returns(uint[] memory) {
        return _quickSortOffers();
    }

    struct OfferInfos {
        address user;
        uint256 price;
    }

    function _quickSortOffers() internal view returns(uint[] memory){
        //Need to build up an array with values from 1 to OfferIndex => Need to find a better way to do it
        //To then sort the offers by price
        uint256 totalNbOffers = warden.offersIndex();

        // Fetch all the Offers listed in Warden, in memory using the OfferInfos struct
        OfferInfos[] memory offersList = new OfferInfos[](totalNbOffers - 1);
        uint256 length = offersList.length;
        for(uint256 i = 0; i < length;){ //Because the 0 index is an empty Offer
            (offersList[i].user, offersList[i].price,,,,) = warden.getOffer(i + 1);

            unchecked{ ++i; }
        }

        // Sort the list using the recursive method
        _quickSort(offersList, int(0), int(offersList.length - 1));

        // Build up the OfferIndex array used buy the MultiBuy method
        uint256[] memory sortedOffers = new uint256[](totalNbOffers - 1);
        uint256 length2 = offersList.length;
        for(uint256 i = 0; i < length2;){
            sortedOffers[i] = warden.userIndex(offersList[i].user);

            unchecked{ ++i; }
        }

        return sortedOffers;
    }

    // Quicksort logic => sorting the Offers based on price
    function _quickSort(OfferInfos[] memory offersList, int left, int right) internal view {
        int i = left;
        int j = right;
        if(i==j) return;
        OfferInfos memory pivot = offersList[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (offersList[uint(i)].price < pivot.price) i++;
            while (pivot.price < offersList[uint(j)].price) j--;
            if (i <= j) {
                (offersList[uint(i)], offersList[uint(j)]) = (offersList[uint(j)], offersList[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quickSort(offersList, left, j);
        if (i < right)
            _quickSort(offersList, i, right);
    }

    function _availableAmount(
        uint256 offerIndex,
        uint256 maxPrice,
        uint256 expiryTime
    ) internal view returns (uint256) {
        (
            address delegator,
            uint256 offerPrice,
            ,
            uint256 offerExpiryTime,
            uint256 minPerc,
            uint256 maxPerc
        ) = warden.getOffer(offerIndex);

        // Price of the Offer is over the maxPrice given
        if (offerPrice > maxPrice) return 0;

        // The Offer is expired
        if (block.timestamp > offerExpiryTime) return 0;

        // veCRV locks ends before wanted duration
        if (expiryTime >= votingEscrow.locked__end(delegator)) return 0;

        uint256 userBalance = votingEscrow.balanceOf(delegator);
        uint256 delegableBalance = delegationBoost.delegable_balance(delegator);

        // Percent of delegator balance not allowed to delegate (as set by maxPerc in the BoostOffer)
        uint256 blockedBalance = (userBalance * (MAX_PCT - maxPerc)) / MAX_PCT;
        // If the current delegableBalance is the the part of the balance not allowed for this market
        if(delegableBalance < blockedBalance) return 0;

        // Available Balance to delegate = Current Undelegated Balance - Blocked Balance
        uint256 availableBalance = delegableBalance - blockedBalance;

        // Minmum amount of veCRV for the boost for this Offer
        uint256 minBoostAmount = (userBalance * minPerc) / MAX_PCT;

        if(delegableBalance >= minBoostAmount) {
            // Warden cannot create the Boost
            if (delegationBoost.allowance(delegator, address(warden)) < availableBalance) return 0;

            return availableBalance;
        }

        return 0; //fallback => not enough availableBalance to propose the minimum Boost Amount allowed

    }

    function recoverERC20(address token, uint256 amount) external onlyOwner returns(bool) {
        IERC20(token).safeTransfer(owner(), amount);

        return true;
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

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../utils/Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
pragma solidity 0.8.10;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./utils/Owner.sol";
import "./oz/utils/Pausable.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IBoostV2.sol";
import "./utils/Errors.sol";

/** @title Warden contract V2 */
/// @author Paladin
/*
    Delegation market based on Curve VotingEscrowDelegation contract
*/
contract Warden is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants :
    uint256 public constant UNIT = 1e18;
    uint256 public constant MAX_PCT = 10000;
    uint256 public constant WEEK = 7 * 86400;
    uint256 public constant MAX_UINT = 2**256 - 1;

    // Storage :

    /** @notice Offer made by an user to buy a given amount of his votes 
    user : Address of the user making the offer
    pricePerVote : Price per vote per second, set by the user
    minPerc : Minimum percent of users voting token balance to buy for a Boost (in BPS)
    maxPerc : Maximum percent of users total voting token balance available to delegate (in BPS)
    */
    struct BoostOffer {
        // Address of the user making the offer
        address user;
        // Price per vote per second, set by the user
        uint256 pricePerVote;
        // Max duration a Boost from this offer can last
        uint64 maxDuration;
        // Timestamp of expiry of the Offer
        uint64 expiryTime;
        // Minimum percent of users voting token balance to buy for a Boost
        uint16 minPerc; //bps
        // Maximum percent of users total voting token balance available to delegate
        uint16 maxPerc; //bps
        // Use the advised price instead of the Offer one
        bool useAdvicePrice;
    }

    /** @notice ERC20 used to pay for DelegationBoost */
    IERC20 public feeToken;
    /** @notice Address of the votingToken to delegate */
    IVotingEscrow public votingEscrow;
    /** @notice Address of the Delegation Boost contract */
    IBoostV2 public delegationBoost;

    /** @notice ratio of fees to be set as Reserve (in BPS) */
    uint256 public feeReserveRatio; //bps
    /** @notice Total Amount in the Reserve */
    uint256 public reserveAmount;
    /** @notice Address allowed to withdraw from the Reserve */
    address public reserveManager;

    /** @notice Min Percent of delegator votes to buy required to purchase a Delegation Boost (in BPS) */
    uint256 public minPercRequired; //bps

    /** @notice Minimum delegation time, taken from veBoost contract */
    uint256 public minDelegationTime = 1 weeks;

    /** @notice List of all current registered users and their delegation offer */
    BoostOffer[] public offers;

    /** @notice Index of the user in the offers array */
    mapping(address => uint256) public userIndex;

    /** @notice Amount of fees earned by users through Boost selling */
    mapping(address => uint256) public earnedFees;

    bool private _claimBlocked;

    /** @notice Price per vote advised by the managers for users that don't handle their pricing themselves */
    uint256 public advisedPrice;

    /** @notice Address approved to manage the advised price */
    mapping(address => bool) public approvedManagers;

    /** @notice Next period to update for the Reward State */
    uint256 public nextUpdatePeriod;

    /** @notice Reward Index by period */
    mapping(uint256 => uint256) public periodRewardIndex;

    /** @notice Base amount of reward to distribute weekly for each veCRV purchased */
    uint256 public baseWeeklyDropPerVote;

    /** @notice Minimum amount of reward to distribute weekly for each veCRV purchased */
    uint256 public minWeeklyDropPerVote;

    /** @notice Target amount of veCRV Boosts to be purchased in a period */
    uint256 public targetPurchaseAmount;

    /** @notice Amount of reward to distribute for the period */
    mapping(uint256 => uint256) public periodDropPerVote;

    /** @notice Amount of veCRV Boosts pruchased for the period */
    mapping(uint256 => uint256) public periodPurchasedAmount;

    /** @notice Decrease of the Purchased amount at the end of the period (since veBoost amounts decrease over time) */
    mapping(uint256 => uint256) public periodEndPurchasedDecrease;

    /** @notice Changes in the periodEndPurchasedDecrease for the period */
    mapping(uint256 => uint256) public periodPurchasedDecreaseChanges;

    /** @notice Amount of rewards paid in extra during last periods */
    uint256 public extraPaidPast;

    /** @notice Reamining rewards not distributed from last periods */
    uint256 public remainingRewardPastPeriod;

    struct PurchasedBoost {
        uint256 amount;
        uint256 startIndex;
        uint128 startTimestamp;
        uint128 endTimestamp;
        address buyer;
        bool claimed;
    }

    /** @notice Mapping of a Boost purchase info, stored by the Boost token ID */
    mapping(uint256 => PurchasedBoost) public purchasedBoosts;

    /** @notice List of the Boost purchased by an user */
    mapping(address => uint256[]) public userPurchasedBoosts;

    /** @notice ID for the next purchased Boost */
    uint256 public nextBoostId = 1; // because we use ID 0 as an invalid one in the MultiBuy system
    
    /** @notice Reward token to distribute to buyers */
    IERC20 public rewardToken;


    // Events :

    event Registred(address indexed user, uint256 price);

    event UpdateOffer(address indexed user, uint256 newPrice);
    event UpdateOfferPrice(address indexed user, uint256 newPrice);

    event Quit(address indexed user);

    event BoostPurchase(
        address indexed delegator,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 paidFeeAmount,
        uint256 expiryTime
    );

    event Claim(address indexed user, uint256 amount);

    event ClaimReward(uint256 boostId, address indexed user, uint256 amount);

    event NewAdvisedPrice(uint256 newPrice);


    modifier onlyAllowed(){
        if(msg.sender != reserveManager && msg.sender != owner()) revert Errors.CallerNotAllowed();
        _;
    }

    // Constructor :
    /**
     * @dev Creates the contract, set the given base parameters
     * @param _feeToken address of the token used to pay fees
     * @param _votingEscrow address of the voting token to delegate
     * @param _delegationBoost address of the contract handling delegation
     * @param _feeReserveRatio Percent of fees to be set as Reserve (bps)
     * @param _minPercRequired Minimum percent of user
     * @param _advisedPrice Starting advised price
     */
    constructor(
        address _feeToken,
        address _votingEscrow,
        address _delegationBoost,
        uint256 _feeReserveRatio, //bps
        uint256 _minPercRequired, //bps
        uint256 _advisedPrice
    ) {
        feeToken = IERC20(_feeToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        delegationBoost = IBoostV2(_delegationBoost);

        require(_advisedPrice > 0);
        advisedPrice = _advisedPrice;

        require(_feeReserveRatio <= 5000);
        require(_minPercRequired > 0 && _minPercRequired <= 10000);
        feeReserveRatio = _feeReserveRatio;
        minPercRequired = _minPercRequired;

        // fill index 0 in the offers array
        // since we want to use index 0 for unregistered users
        offers.push(BoostOffer(address(0), 0, 0, 0, 0, 0, false));
    }

    // Modifiers :

    modifier rewardStateUpdate() {
        if(!updateRewardState()) revert Errors.FailRewardUpdate();
        _;
    }

    // Functions :

    /**
     * @notice Amount of Offer listed in this market
     * @dev Amount of Offer listed in this market
     */
    function offersIndex() external view returns(uint256){
        return offers.length;
    }

    /**
     * @notice Returns the current period
     * @dev Calculates and returns the current period based on current timestamp
     */
    function currentPeriod() public view returns(uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    /**
     * @notice Updates the reward state for all past periods
     * @dev Updates the reward state for all past periods
     */
    function updateRewardState() public whenNotPaused returns(bool){
        if(nextUpdatePeriod == 0) return true; // Reward distribution not initialized
        // Updates once a week
        // If last update is less than a week ago, simply return
        uint256 _currentPeriod = currentPeriod();
        if(_currentPeriod <= nextUpdatePeriod) return true;

        uint256 period = nextUpdatePeriod;

        // Only update 100 period at a time
        for(uint256 i; i < 100;){
            if(period >= _currentPeriod) break;

            uint256 nextPeriod = period + WEEK;

            // Calculate the expected amount ot be distributed for the week (the period)
            // And how much was distributed for that period (based on purchased amounts & period drop per vote)
            uint256 weeklyDropAmount = (baseWeeklyDropPerVote * targetPurchaseAmount) / UNIT;
            uint256 periodRewardAmount = (periodPurchasedAmount[period] * periodDropPerVote[period]) / UNIT;

            // In case we distributed less than the objective
            if(periodRewardAmount <= weeklyDropAmount){
                uint256 undistributedAmount = weeklyDropAmount - periodRewardAmount;
                
                // Remove any extra amount distributed from past periods
                // And set any remaining rewards to be distributed as surplus for next period
                if(extraPaidPast != 0){
                    if(undistributedAmount >= extraPaidPast){
                        undistributedAmount -= extraPaidPast;
                        extraPaidPast = 0;
                    } else{
                        extraPaidPast -= undistributedAmount;
                        undistributedAmount = 0;
                    }
                }
                remainingRewardPastPeriod += undistributedAmount;
            } else { // In case we distributed more than the objective
                uint256 overdistributedAmount = periodRewardAmount - weeklyDropAmount;

                // Remove the extra distributed from the remaining rewards from past period (if there is any)
                // And set the rest of the extra distributed rewards to be accounted for next period
                if(remainingRewardPastPeriod != 0){
                    if(overdistributedAmount >= remainingRewardPastPeriod){
                        overdistributedAmount -= remainingRewardPastPeriod;
                        remainingRewardPastPeriod = 0;
                    } else{
                        remainingRewardPastPeriod -= overdistributedAmount;
                        overdistributedAmount = 0;
                    }
                }
                extraPaidPast += overdistributedAmount;
            }

            // Calculate nextPeriod new drop
            // Based on the basic weekly drop, and any extra reward paid past periods, or remaining rewards from last period
            // In case remainingRewardPastPeriod > 0, then the nextPeriodDropPerVote should be higher than the base one
            // And in case there is extraPaidPast >0, the nextPeriodDropPerVote should be less
            // But nextPeriodDropPerVote can never be less than minWeeklyDropPerVote
            // (In that case, we expected the next period to have extra rewards paid again, and to reach back the objective on future periods)
            uint256 nextPeriodDropPerVote;
            if(extraPaidPast >= weeklyDropAmount + remainingRewardPastPeriod){
                nextPeriodDropPerVote = minWeeklyDropPerVote;
            } else {
                uint256 tempWeeklyDropPerVote = ((weeklyDropAmount + remainingRewardPastPeriod - extraPaidPast) * UNIT) / targetPurchaseAmount;
                nextPeriodDropPerVote = tempWeeklyDropPerVote > minWeeklyDropPerVote ? tempWeeklyDropPerVote : minWeeklyDropPerVote;
            }
            periodDropPerVote[nextPeriod] = nextPeriodDropPerVote;

            // Update the index for the period, based on the period DropPerVote
            periodRewardIndex[nextPeriod] = periodRewardIndex[period] + periodDropPerVote[period];

            // Make next period purchased amount decrease changes
            if(periodPurchasedAmount[period] >= periodEndPurchasedDecrease[period]){
                periodPurchasedAmount[nextPeriod] += periodPurchasedAmount[period] - periodEndPurchasedDecrease[period];
                // Else, we consider the current period purchased amount as  totally removed
            }
            if(periodEndPurchasedDecrease[period] >= periodPurchasedDecreaseChanges[nextPeriod]){
                periodEndPurchasedDecrease[nextPeriod] += periodEndPurchasedDecrease[period] - periodPurchasedDecreaseChanges[nextPeriod];
                // Else the decrease from the current period does not need to be kept for the next period
            }

            // Go to next period
            period = nextPeriod;
            unchecked{ ++i; }
        }

        // Set the period where we stopped (and not updated), as the next period to be updated
        nextUpdatePeriod = period;

        return true;
    }

    /**
     * @notice Registers a new user wanting to sell its delegation
     * @dev Regsiters a new user, creates a BoostOffer with the given parameters
     * @param pricePerVote Price of 1 vote per second (in wei)
     * @param maxDuration Maximum duration (in weeks) that a Boost can last when taken from this Offer
     * @param expiryTime Timestamp when this Offer is not longer valid
     * @param minPerc Minimum percent of users voting token balance to buy for a Boost (in BPS)
     * @param maxPerc Maximum percent of users total voting token balance available to delegate (in BPS)
     * @param useAdvicePrice True to use the advice Price instead of the given pricePerVote
     */
    function register(
        uint256 pricePerVote,
        uint64 maxDuration,
        uint64 expiryTime,
        uint16 minPerc,
        uint16 maxPerc,
        bool useAdvicePrice
    ) external whenNotPaused rewardStateUpdate returns(bool) {
        address user = msg.sender;
        if(userIndex[user] != 0) revert Errors.AlreadyRegistered();
        if(delegationBoost.allowance(user, address(this)) != MAX_UINT) revert Errors.WardenNotOperator();

        if(pricePerVote == 0) revert Errors.NullPrice();
        if(maxPerc > 10000) revert Errors.MaxPercTooHigh();
        if(minPerc > maxPerc) revert Errors.MinPercOverMaxPerc();
        if(minPerc < minPercRequired) revert Errors.MinPercTooLow();
        if(maxDuration == 0) revert Errors.NullMaxDuration();
        if(expiryTime != 0 && expiryTime < (block.timestamp + WEEK)) revert Errors.IncorrectExpiry();

        if(expiryTime == 0) expiryTime = uint64(votingEscrow.locked__end(user));

        // Create the BoostOffer for the new user, and add it to the storage
        userIndex[user] = offers.length;
        offers.push(BoostOffer(user, pricePerVote, maxDuration, expiryTime, minPerc, maxPerc, useAdvicePrice));

        emit Registred(user, pricePerVote);

        return true;
    }

    /**
     * @notice Updates an user BoostOffer parameters
     * @dev Updates parameters for the user's BoostOffer
     * @param pricePerVote Price of 1 vote per second (in wei)
     * @param maxDuration Maximum duration (in weeks) that a Boost can last when taken from this Offer
     * @param expiryTime Timestamp when this Offer is not longer valid
     * @param minPerc Minimum percent of users voting token balance to buy for a Boost (in BPS)
     * @param maxPerc Maximum percent of users total voting token balance available to delegate (in BPS)
     * @param useAdvicePrice True to use the advice Price instead of the given pricePerVote
     */
    function updateOffer(
        uint256 pricePerVote,
        uint64 maxDuration,
        uint64 expiryTime,
        uint16 minPerc,
        uint16 maxPerc,
        bool useAdvicePrice
    ) external whenNotPaused rewardStateUpdate returns(bool) {
        // Fetch the user index, and check for registration
        address user = msg.sender;
        uint256 index = userIndex[user];
        if(index == 0) revert Errors.NotRegistered();

        // Fetch the BoostOffer to update
        BoostOffer storage offer = offers[index];

        if(offer.user != msg.sender) revert Errors.NotOfferOwner();

        if(pricePerVote == 0) revert Errors.NullPrice();
        if(maxPerc > 10000) revert Errors.MaxPercTooHigh();
        if(minPerc > maxPerc) revert Errors.MinPercOverMaxPerc();
        if(minPerc < minPercRequired) revert Errors.MinPercTooLow();
        if(maxDuration == 0) revert Errors.NullMaxDuration();
        if(expiryTime != 0 && expiryTime < (block.timestamp + WEEK)) revert Errors.IncorrectExpiry();

        if(expiryTime == 0) expiryTime = uint64(votingEscrow.locked__end(user));

        // Update the parameters
        offer.pricePerVote = pricePerVote;
        offer.maxDuration = maxDuration;
        offer.expiryTime = expiryTime;
        offer.minPerc = minPerc;
        offer.maxPerc = maxPerc;
        offer.useAdvicePrice = useAdvicePrice;

        emit UpdateOffer(user, useAdvicePrice ? advisedPrice : pricePerVote);

        return true;
    }

    /**
     * @notice Updates an user BoostOffer price parameters
     * @dev Updates an user BoostOffer price parameters
     * @param pricePerVote Price of 1 vote per second (in wei)
     * @param useAdvicePrice Bool: use advised price
     */
    function updateOfferPrice(
        uint256 pricePerVote,
        bool useAdvicePrice
    ) external whenNotPaused rewardStateUpdate returns(bool) {
        // Fet the user index, and check for registration
        address user = msg.sender;
        uint256 index = userIndex[user];
        if(index == 0) revert Errors.NotRegistered();

        // Fetch the BoostOffer to update
        BoostOffer storage offer = offers[index];

        if(offer.user != msg.sender) revert Errors.NotOfferOwner();

        if(pricePerVote == 0) revert Errors.NullPrice();

        // Update the parameters
        offer.pricePerVote = pricePerVote;
        offer.useAdvicePrice = useAdvicePrice;

        emit UpdateOfferPrice(user, useAdvicePrice ? advisedPrice : pricePerVote);

        return true;
    }

    /**
     * @notice Returns the Offer data
     * @dev Returns the Offer struct from storage
     * @param index Index of the Offer in the list
     */
    function getOffer(uint256 index) external view returns(
        address user,
        uint256 pricePerVote,
        uint64 maxDuration,
        uint64 expiryTime,
        uint16 minPerc,
        uint16 maxPerc
    ) {
        BoostOffer storage offer = offers[index];
        return(
            offer.user,
            offer.useAdvicePrice ? advisedPrice : offer.pricePerVote,
            offer.maxDuration,
            offer.expiryTime,
            offer.minPerc,
            offer.maxPerc
        );
    }

    /**
     * @notice Remove the BoostOffer of the user, and claim any remaining fees earned
     * @dev User's BoostOffer is removed from the listing, and any unclaimed fees is sent
     */
    function quit() external whenNotPaused nonReentrant rewardStateUpdate returns(bool) {
        address user = msg.sender;
        if(userIndex[user] == 0) revert Errors.NotRegistered();

        // Check for unclaimed fees, claim it if needed
        if (earnedFees[user] > 0) {
            _claim(user, earnedFees[user]);
        }

        // Find the BoostOffer to remove
        uint256 currentIndex = userIndex[user];
        // If BoostOffer is not the last of the list
        // Replace last of the list with the one to remove
        if (currentIndex < offers.length) {
            uint256 lastIndex = offers.length - 1;
            address lastUser = offers[lastIndex].user;
            offers[currentIndex] = offers[lastIndex];
            userIndex[lastUser] = currentIndex;
        }
        //Remove the last item of the list
        offers.pop();
        userIndex[user] = 0;

        emit Quit(user);

        return true;
    }

    /**
     * @notice Checks if the delegator has enough available balance & the Offer allows to delegate the given amount
     * @dev Checks if the delegator has enough available balance & the Offer allows to delegate the given amount
     * @param delegator Address of the delegator for the Boost
     * @param amount Amount ot delegate
     */
    function canDelegate(address delegator, uint256 amount) external view returns(bool) {
        uint256 userMaxPercent = (offers[userIndex[delegator]]).maxPerc;

        return _canDelegate(delegator, amount, userMaxPercent);
    }

    /**
     * @notice Checks if the delegator has enough available balance & the Offer allows to delegate the given amount
     * @dev Checks if the delegator has enough available balance & the Offer allows to delegate the given amount
     * @param delegator Address of the delegator for the Boost
     * @param percent Percent of the delegator balance to delegate (in BPS)
     */
    function canDelegatePercent(address delegator, uint256 percent) external view returns(bool) {
        uint256 userMaxPercent = (offers[userIndex[delegator]]).maxPerc;

        if(percent > userMaxPercent) return false;

        uint256 amount = (votingEscrow.balanceOf(delegator) * percent) / MAX_PCT;

        return _canDelegate(delegator, amount, userMaxPercent);
    }

    /**
     * @notice Gives an estimate of fees to pay for a given Boost Delegation
     * @dev Calculates the amount of fees for a Boost Delegation with the given amount (through the percent) and the duration
     * @param delegator Address of the delegator for the Boost
     * @param amount Amount ot delegate
     * @param duration Duration (in weeks) of the Boost to purchase
     */
    function estimateFees(
        address delegator,
        uint256 amount,
        uint256 duration //in weeks
    ) external view returns (uint256) {
        if(delegator == address(0)) revert Errors.ZeroAddress();
        if(userIndex[delegator] == 0) revert Errors.NotRegistered();

        uint256 percent = (amount * MAX_PCT) / votingEscrow.balanceOf(delegator);

        BoostOffer storage offer = offers[userIndex[delegator]];
        if(percent < minPercRequired) revert Errors.PercentUnderMinRequired();
        if(percent > MAX_PCT) revert Errors.PercentOverMax();

        if(percent < offer.minPerc || percent > offer.maxPerc) 
            revert Errors.PercentOutOfferBonds();

        return _estimateFees(delegator, amount, duration);
    }

    /**
     * @notice Gives an estimate of fees to pay for a given Boost Delegation
     * @dev Calculates the amount of fees for a Boost Delegation with the given amount (through the percent) and the duration
     * @param delegator Address of the delegator for the Boost
     * @param percent Percent of the delegator balance to delegate (in BPS)
     * @param duration Duration (in weeks) of the Boost to purchase
     */
    function estimateFeesPercent(
        address delegator,
        uint256 percent,
        uint256 duration //in weeks
    ) external view returns (uint256) {
        if(delegator == address(0)) revert Errors.ZeroAddress();
        if(userIndex[delegator] == 0) revert Errors.NotRegistered();
        if(percent < minPercRequired) revert Errors.PercentUnderMinRequired();
        if(percent > MAX_PCT) revert Errors.PercentOverMax();

        // Fetch the BoostOffer for the delegator
        BoostOffer storage offer = offers[userIndex[delegator]];

        if(percent < offer.minPerc || percent > offer.maxPerc) 
            revert Errors.PercentOutOfferBonds();

        uint256 amount = (votingEscrow.balanceOf(delegator) * percent) / MAX_PCT;

        return _estimateFees(delegator, amount, duration);
    }

    /**
     * @notice Buy a Delegation Boost for a Delegator Offer
     * @dev If all parameters match the offer from the delegator, creates a Boost for the caller
     * @param delegator Address of the delegator for the Boost
     * @param receiver Address of the receiver of the Boost
     * @param amount  Amount to delegate
     * @param duration Duration (in weeks) of the Boost to purchase
     * @param maxFeeAmount Maximum amount of feeToken available to pay to cover the Boost Duration (in wei)
     * returns the id of the new veBoost
     */
    function buyDelegationBoost(
        address delegator,
        address receiver,
        uint256 amount,
        uint256 duration, //in weeks
        uint256 maxFeeAmount
    ) external nonReentrant whenNotPaused rewardStateUpdate returns(uint256) {
        if(delegator == address(0) || receiver == address(0)) revert Errors.ZeroAddress();
        if(userIndex[delegator] == 0) revert Errors.NotRegistered();
        if(maxFeeAmount == 0) revert Errors.NullFees();
        if(amount == 0) revert Errors.NullValue();

        uint256 percent = (amount * MAX_PCT) / votingEscrow.balanceOf(delegator);

        BoostOffer storage offer = offers[userIndex[delegator]];
        if(percent < minPercRequired) revert Errors.PercentUnderMinRequired();
        if(percent > MAX_PCT) revert Errors.PercentOverMax();
        if(percent < offer.minPerc || percent > offer.maxPerc) revert Errors.PercentOutOfferBonds();

        return _buyDelegationBoost(delegator, receiver, amount, duration, maxFeeAmount);
    }

    /**
     * @notice Buy a Delegation Boost for a Delegator Offer
     * @dev If all parameters match the offer from the delegator, creates a Boost for the caller
     * @param delegator Address of the delegator for the Boost
     * @param receiver Address of the receiver of the Boost
     * @param percent Percent of the delegator balance to delegate (in BPS)
     * @param duration Duration (in weeks) of the Boost to purchase
     * @param maxFeeAmount Maximum amount of feeToken available to pay to cover the Boost Duration (in wei)
     * returns the id of the new veBoost
     */
    function buyDelegationBoostPercent(
        address delegator,
        address receiver,
        uint256 percent,
        uint256 duration, //in weeks
        uint256 maxFeeAmount
    ) external nonReentrant whenNotPaused rewardStateUpdate returns(uint256) {
        if(delegator == address(0) || receiver == address(0)) revert Errors.ZeroAddress();
        if(userIndex[delegator] == 0) revert Errors.NotRegistered();
        if(maxFeeAmount == 0) revert Errors.NullFees();
        if(percent < minPercRequired) revert Errors.PercentUnderMinRequired();
        if(percent > MAX_PCT) revert Errors.PercentOverMax();

        BoostOffer storage offer = offers[userIndex[delegator]];
        if(percent < offer.minPerc || percent > offer.maxPerc) revert Errors.PercentOutOfferBonds();

        uint256 amount = (votingEscrow.balanceOf(delegator) * percent) / MAX_PCT;

        return _buyDelegationBoost(delegator, receiver, amount, duration, maxFeeAmount);
    }

    /**
     * @notice Returns the amount of fees earned by the user that can be claimed
     * @dev Returns the value in earnedFees for the given user
     * @param user Address of the user
     */
    function claimable(address user) external view returns (uint256) {
        return earnedFees[user];
    }

    /**
     * @notice Claims all earned fees
     * @dev Send all the user's earned fees
     */
    function claim() external nonReentrant rewardStateUpdate returns(bool) {
        if(earnedFees[msg.sender] == 0) revert Errors.NullClaimAmount();
        return _claim(msg.sender, earnedFees[msg.sender]);
    }

    /**
     * @notice Get all Boosts purchased by an user
     * @dev Get all Boosts purchased by an user
     * @param user Address of the buyer
     */
    function getUserPurchasedBoosts(address user) external view returns(uint256[] memory) {
        return userPurchasedBoosts[user];
    }

    /**
     * @notice Get the Purchased Boost data
     * @dev Get the Purchased Boost struct from storage
     * @param boostId Id of the veBoost
     */
    function getPurchasedBoost(uint256 boostId) external view returns(PurchasedBoost memory) {
        return purchasedBoosts[boostId];
    }

    /**
     * @notice Get the amount of rewards for a Boost
     * @dev Get the amount of rewards for a Boost
     * @param boostId Id of the veBoost
     */
    function getBoostReward(uint256 boostId) external view returns(uint256) {
        if(boostId >= nextBoostId) revert Errors.InvalidBoostId();
        return _getBoostRewardAmount(boostId);
    }

    /**
     * @notice Claim the rewards for a purchased Boost
     * @dev Claim the rewards for a purchased Boost
     * @param boostId Id of the veBoost
     */
    function claimBoostReward(uint256 boostId) external nonReentrant rewardStateUpdate returns(bool) {
        if(boostId >= nextBoostId) revert Errors.InvalidBoostId();
        return _claimBoostRewards(boostId);
    }

    /**
     * @notice Claim the rewards for multiple Boosts
     * @dev Claim the rewards for multiple Boosts
     * @param boostIds List of veBoost Ids
     */
    function claimMultipleBoostReward(uint256[] calldata boostIds) external nonReentrant rewardStateUpdate returns(bool) {
        uint256 length = boostIds.length;
        for(uint256 i; i < length;) {
            if(boostIds[i] >= nextBoostId) revert Errors.InvalidBoostId();
            require(_claimBoostRewards(boostIds[i]));

            unchecked{ ++i; }
        }

        return true;
    }

    function _estimateFees(
        address delegator,
        uint256 amount,
        uint256 duration //in weeks
    ) internal view returns (uint256) {
        // Fetch the BoostOffer for the delegator
        BoostOffer storage offer = offers[userIndex[delegator]];

        //Check that the duration is less or equal to Offer maxDuration
        if(duration > offer.maxDuration) revert Errors.DurationOverOfferMaxDuration();
        if(block.timestamp > offer.expiryTime) revert Errors.OfferExpired();
        // Get the duration in seconds, and check it's more than the minimum required
        uint256 boostDuration = duration * WEEK;
        if(boostDuration < minDelegationTime) revert Errors.DurationTooShort();

        // Because the BoostV2 expects end_timestamps to be rounded by week,
        // and we want to round up instead of down (so user purchasing the minimal duration (1 week)
        // have at least than minimal duration). Since the Boost cannot be canceled, we expect the user to pay
        // for the effective duration of the boost
        uint256 expiryTime = ((block.timestamp + boostDuration) / WEEK) * WEEK;
        expiryTime = (expiryTime < block.timestamp + boostDuration) ?
            ((block.timestamp + boostDuration + WEEK) / WEEK) * WEEK :
            expiryTime;
        if(expiryTime > votingEscrow.locked__end(delegator)) revert Errors.LockEndTooShort();
        // Real Boost duration (for fees)
        boostDuration = expiryTime - block.timestamp;

        // Choose between the Offer price or the advised one based on delegator choice
        uint256 pricePerVote = offer.useAdvicePrice ? advisedPrice : offer.pricePerVote;

        // Return estimated max price for the whole Boost duration at this block
        return (amount * pricePerVote * boostDuration) / UNIT;
    }

    struct BuyVars {
        uint256 boostDuration;
        uint256 expiryTime;
        uint256 pricePerVote;
        uint256 realFeeAmount;
        uint256 newTokenId;
        uint256 currentPeriod;
        uint256 currentRewardIndex;
        uint256 boostWeeklyDecrease;
        uint256 nextPeriod;
    }

    function _buyDelegationBoost(
        address delegator,
        address receiver,
        uint256 amount,
        uint256 duration, //in weeks
        uint256 maxFeeAmount
    ) internal returns(uint256) {

        BuyVars memory vars;

        // Fetch the BoostOffer for the delegator
        BoostOffer storage offer = offers[userIndex[delegator]];

        //Check that the duration is less or equal to Offer maxDuration
        if(duration > offer.maxDuration) revert Errors.DurationOverOfferMaxDuration();
        if(block.timestamp > offer.expiryTime) revert Errors.OfferExpired();

        // Get the duration of the wanted Boost in seconds
        vars.boostDuration = duration * WEEK;
        if(vars.boostDuration < minDelegationTime) revert Errors.DurationTooShort();

        // Calcualte the expiry time for the Boost = now + duration
        vars.expiryTime = ((block.timestamp + vars.boostDuration) / WEEK) * WEEK;

        // Hack needed because veBoost contract expects end_timestamp rounded by week
        // We don't want buyers to receive less than they pay for
        // So an "extra" week is added if needed to get an expire_time covering the required duration
        // Because the BoostOffer V2 does not allow to cancel Boosts, we expect the user to pay
        // for the effective duration of the boost
        vars.expiryTime = (vars.expiryTime < block.timestamp + vars.boostDuration) ?
            ((block.timestamp + vars.boostDuration + WEEK) / WEEK) * WEEK :
            vars.expiryTime;
        if(vars.expiryTime > votingEscrow.locked__end(delegator)) revert Errors.LockEndTooShort();
        // Real Boost duration (for fees)
        vars.boostDuration = vars.expiryTime - block.timestamp;

        // Check if delegator can delegate the amount, without exceeding the maximum percent allowed by the delegator
        // _canDelegate will also try to cancel expired Boosts of the deelgator to free more tokens for delegation
        delegationBoost.checkpoint_user(delegator);
        if(!_canDelegate(delegator, amount, offer.maxPerc)) revert Errors.CannotDelegate();

        // Choose between the Offer price or the advised one based on delegator choice
        vars.pricePerVote = offer.useAdvicePrice ? advisedPrice : offer.pricePerVote;

        // Calculate the price for the given duration, get the real amount of fees to pay,
        // and check the maxFeeAmount provided (and approved beforehand) is enough.
        vars.realFeeAmount = (amount * vars.pricePerVote * vars.boostDuration) / UNIT;
        if(vars.realFeeAmount > maxFeeAmount) revert Errors.FeesTooLow();

        // Pull the tokens from the buyer, setting it as earned fees for the delegator (and part of it for the Reserve)
        _pullFees(msg.sender, vars.realFeeAmount, delegator);

        // Get the id for the new Boost
        vars.newTokenId = nextBoostId;
        nextBoostId++;

        // Creates the DelegationBoost
        delegationBoost.boost(
            receiver,
            amount,
            vars.expiryTime,
            delegator
        );


        // If rewards were started, otherwise no need to write for that Boost
        if(nextUpdatePeriod != 0) { 

            // Find the current reward index
            vars.currentPeriod = currentPeriod();
            vars.currentRewardIndex = periodRewardIndex[vars.currentPeriod] + (
                (periodDropPerVote[vars.currentPeriod] * (block.timestamp - vars.currentPeriod)) / WEEK
            );

            // Add the amount purchased to the period purchased amount (& the decrease + decrease change)
            vars.boostWeeklyDecrease = (amount * WEEK) / vars.boostDuration;
            vars.nextPeriod = vars.currentPeriod + WEEK;
            periodPurchasedAmount[vars.currentPeriod] += amount;
            periodEndPurchasedDecrease[vars.currentPeriod] += (vars.boostWeeklyDecrease * (vars.nextPeriod - block.timestamp)) / WEEK;
            periodPurchasedDecreaseChanges[vars.nextPeriod] += (vars.boostWeeklyDecrease * (vars.nextPeriod - block.timestamp)) / WEEK;

            if(vars.expiryTime != vars.nextPeriod){
                periodEndPurchasedDecrease[vars.nextPeriod] += vars.boostWeeklyDecrease;
                periodPurchasedDecreaseChanges[vars.expiryTime] += vars.boostWeeklyDecrease;
            }

            // Write the Purchase for rewards
            purchasedBoosts[vars.newTokenId] = PurchasedBoost(
                amount,
                vars.currentRewardIndex,
                uint128(block.timestamp),
                uint128(vars.expiryTime),
                receiver,
                false
            );
            userPurchasedBoosts[receiver].push(vars.newTokenId);
        }

        emit BoostPurchase(
            delegator,
            receiver,
            vars.newTokenId,
            amount,
            vars.pricePerVote,
            vars.realFeeAmount,
            vars.expiryTime
        );

        return vars.newTokenId;

    }

    function _pullFees(
        address buyer,
        uint256 amount,
        address seller
    ) internal {
        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(buyer, address(this), amount);

        // Split fees between Boost offerer & Reserve
        earnedFees[seller] += (amount * (MAX_PCT - feeReserveRatio)) / MAX_PCT;
        reserveAmount += (amount * feeReserveRatio) / MAX_PCT;
    }

    function _canDelegate(
        address delegator,
        uint256 amount,
        uint256 delegatorMaxPerc
    ) internal view returns (bool) {
        // Handles both the case where user just approved a given amount to this contract
        // or approved for the MAX_UINT256 (which is the easiest setting in our case)
        if (delegationBoost.allowance(delegator, address(this)) < amount)
            return false;

        // Delegator current balance
        uint256 balance = votingEscrow.balanceOf(delegator);

        // Percent of delegator balance not allowed to delegate (as set by maxPerc in the BoostOffer)
        uint256 blockedBalance = (balance * (MAX_PCT - delegatorMaxPerc)) / MAX_PCT;
        uint256 delegableBalance = delegationBoost.delegable_balance(delegator);

        // If the current delegableBalance is the the part of the balance not allowed for this market
        if(delegableBalance < blockedBalance) return false;

        // Available Balance to delegate = Current Undelegated Balance - Blocked Balance
        uint256 availableBalance = delegableBalance - blockedBalance;

        if (amount <= availableBalance) return true;

        return false;
    }

    function _claim(address user, uint256 amount) internal returns(bool) {
        if(_claimBlocked) revert Errors.ClaimBlocked();
        if(amount > feeToken.balanceOf(address(this))) revert Errors.InsufficientCash();

        if(amount == 0) return true; // nothing to claim, but used in claimAndCancel()

        // If fees to be claimed, update the mapping, and send the amount
        unchecked{
            // Should not underflow, since the amount was either checked in the claim() method, or set as earnedFees[user]
            earnedFees[user] -= amount;
        }

        feeToken.safeTransfer(user, amount);

        emit Claim(user, amount);

        return true;
    }

    function _getBoostRewardAmount(uint256 boostId) internal view returns(uint256) {
        PurchasedBoost memory boost = purchasedBoosts[boostId];
        if(boost.buyer == address(0)) revert Errors.BoostRewardsNull();
        if(boost.claimed) return 0;
        if(currentPeriod() <= boost.endTimestamp) return 0;
        if(nextUpdatePeriod <= boost.endTimestamp) revert Errors.RewardsNotUpdated();

        uint256 boostAmount = boost.amount;
        uint256 boostDuration = boost.endTimestamp - boost.startTimestamp;
        uint256 boostDecreaseStep = boostAmount / (boostDuration);
        uint256 boostPeriodDecrease = boostDecreaseStep * WEEK;

        uint256 rewardAmount;

        uint256 indexDiff;
        uint256 periodBoostAmount;
        uint256 endPeriodBoostAmount;

        uint256 period = (boost.startTimestamp / WEEK) * WEEK;
        uint256 nextPeriod = period + WEEK;

        // 1st period (if incomplete)
        if(boost.startTimestamp > period) {
            indexDiff = periodRewardIndex[nextPeriod] - boost.startIndex;
            uint256 timeDiff = nextPeriod - boost.startTimestamp;

            endPeriodBoostAmount = boostAmount - (boostDecreaseStep * timeDiff);

            periodBoostAmount = endPeriodBoostAmount + ((boostDecreaseStep + (boostDecreaseStep * timeDiff)) / 2);

            rewardAmount += (indexDiff * periodBoostAmount) / UNIT;

            boostAmount = endPeriodBoostAmount;
            period = nextPeriod;
            nextPeriod = period + WEEK;
        }

        uint256 nbPeriods = boostDuration / WEEK;
        // all complete periods
        for(uint256 j; j < nbPeriods;){
            indexDiff = periodRewardIndex[nextPeriod] - periodRewardIndex[period];

            endPeriodBoostAmount = boostAmount - (boostDecreaseStep * WEEK);

            periodBoostAmount = endPeriodBoostAmount + ((boostDecreaseStep + boostPeriodDecrease) / 2);

            rewardAmount += (indexDiff * periodBoostAmount) / UNIT;

            boostAmount = endPeriodBoostAmount;
            period = nextPeriod;
            nextPeriod = period + WEEK;

            unchecked{ ++j; }
        }

        return rewardAmount;
    }

    function _claimBoostRewards(uint256 boostId) internal returns(bool) {
        if(nextUpdatePeriod == 0) revert Errors.RewardsNotStarted();
        PurchasedBoost storage boost = purchasedBoosts[boostId];
        if(boost.buyer == address(0)) revert Errors.BoostRewardsNull();

        if(msg.sender != boost.buyer) revert Errors.NotBoostBuyer();
        if(boost.claimed) revert Errors.AlreadyClaimed();
        if(currentPeriod() <= boost.endTimestamp) revert Errors.CannotClaim();

        uint256 rewardAmount = _getBoostRewardAmount(boostId);

        if(rewardAmount == 0) return true; // nothing to claim, return

        if(rewardAmount > rewardToken.balanceOf(address(this))) revert Errors.InsufficientRewardCash();

        boost.claimed = true;

        rewardToken.safeTransfer(msg.sender, rewardAmount);

        emit ClaimReward(boostId, msg.sender, rewardAmount);

        return true;
    }

    // Manager methods:

    /**
     * @notice Updates the advised price
     * @param newPrice New price perv ote per second (in wei)
     */
    function setAdvisedPrice(uint256 newPrice) external {
        if(!approvedManagers[msg.sender]) revert Errors.CallerNotManager();
        if(newPrice == 0) revert Errors.NullValue();
        advisedPrice = newPrice;

        emit NewAdvisedPrice(newPrice);
    }

    // Admin Functions :

    /**
     * @notice Set the start parameters for reward distribution, and start accruint rewards to boost purchases
     * @param _rewardToken Address of the token to use as rewards
     * @param _baseWeeklyDropPerVote Base amount of weekly rewards to be distributed for the week (in wei)
     * @param _minWeeklyDropPerVote Minimum amount of reward to be distributed for the week (in wei)
     * @param _targetPurchaseAmount Target amount of veCRV in Boost to be purchased weekly (in wei)
     */
    function startRewardDistribution(
        address _rewardToken,
        uint256 _baseWeeklyDropPerVote,
        uint256 _minWeeklyDropPerVote,
        uint256 _targetPurchaseAmount
    ) external onlyOwner {
        if(_rewardToken == address(0)) revert Errors.ZeroAddress();
        if(_baseWeeklyDropPerVote == 0 || _minWeeklyDropPerVote == 0 ||  _targetPurchaseAmount == 0) revert Errors.NullValue();
        if(_baseWeeklyDropPerVote < _minWeeklyDropPerVote) revert Errors.BaseDropTooLow();
        if(nextUpdatePeriod != 0) revert Errors.RewardsAlreadyStarted();

        rewardToken = IERC20(_rewardToken);

        baseWeeklyDropPerVote = _baseWeeklyDropPerVote;
        minWeeklyDropPerVote = _minWeeklyDropPerVote;
        targetPurchaseAmount = _targetPurchaseAmount;

        // Initial period and initial index
        uint256 startPeriod = ((block.timestamp + WEEK) / WEEK) * WEEK;
        periodRewardIndex[startPeriod] = 0;
        nextUpdatePeriod = startPeriod;

        //Initial drop
        periodDropPerVote[startPeriod] = baseWeeklyDropPerVote;
    }

    /**
     * @notice Updates the base amount of weekly rewards to be distributed for the week
     * @param newBaseWeeklyDropPerVote New base amount (in wei)
     */
    function setBaseWeeklyDropPerVote(uint256 newBaseWeeklyDropPerVote) external onlyOwner {
        if(newBaseWeeklyDropPerVote == 0) revert Errors.NullValue();
        if(newBaseWeeklyDropPerVote < minWeeklyDropPerVote) revert Errors.BaseDropTooLow();
        baseWeeklyDropPerVote = newBaseWeeklyDropPerVote;
    }

    /**
     * @notice Updates the minimum amount of weekly rewards to be distributed for the week
     * @param newMinWeeklyDropPerVote New min amount (in wei)
     */
    function setMinWeeklyDropPerVote(uint256 newMinWeeklyDropPerVote) external onlyOwner {
        if(newMinWeeklyDropPerVote == 0) revert Errors.NullValue();
        if(baseWeeklyDropPerVote < newMinWeeklyDropPerVote) revert Errors.MinDropTooHigh();
        minWeeklyDropPerVote = newMinWeeklyDropPerVote;
    }

    /**
     * @notice Updates the target amount of veCRV to be purchased weekly through Boosts
     * @param newTargetPurchaseAmount New target amount (in wei)
     */
    function setTargetPurchaseAmount(uint256 newTargetPurchaseAmount) external onlyOwner {
        if(newTargetPurchaseAmount == 0) revert Errors.NullValue();
        targetPurchaseAmount = newTargetPurchaseAmount;
    }

    /**
     * @notice Updates the minimum percent required to buy a Boost
     * @param newMinPercRequired New minimum percent required to buy a Boost (in BPS)
     */
    function setMinPercRequired(uint256 newMinPercRequired) external onlyOwner {
        if(newMinPercRequired == 0 || newMinPercRequired > 10000) revert Errors.InvalidValue();
        minPercRequired = newMinPercRequired;
    }

        /**
     * @notice Updates the minimum delegation time
     * @param newMinDelegationTime New minimum deelgation time (in seconds)
     */
    function setMinDelegationTime(uint256 newMinDelegationTime) external onlyOwner {
        if(newMinDelegationTime == 0) revert Errors.NullValue();
        minDelegationTime = newMinDelegationTime;
    }

    /**
     * @notice Updates the ratio of Fees set for the Reserve
     * @param newFeeReserveRatio New ratio (in BPS)
     */
    function setFeeReserveRatio(uint256 newFeeReserveRatio) external onlyOwner {
        if(newFeeReserveRatio > 5000) revert Errors.InvalidValue();
        feeReserveRatio = newFeeReserveRatio;
    }

    /**
     * @notice Updates the Delegation Boost (veBoost)
     * @param newDelegationBoost New veBoost contract address
     */
    function setDelegationBoost(address newDelegationBoost) external onlyOwner {
        delegationBoost = IBoostV2(newDelegationBoost);
    }

    /**
     * @notice Updates the Reserve Manager
     * @param newReserveManager New Reserve Manager address
     */
    function setReserveManager(address newReserveManager) external onlyOwner {
        reserveManager = newReserveManager;
    }

    /**
    * @notice Approves a new address as manager 
    * @dev Approves a new address as manager
    * @param newManager Address to add
    */
    function approveManager(address newManager) external onlyOwner {
        if(newManager == address(0)) revert Errors.ZeroAddress();
        approvedManagers[newManager] = true;
    }
   
    /**
    * @notice Removes an address from the managers
    * @dev Removes an address from the managers
    * @param manager Address to remove
    */
    function removeManager(address manager) external onlyOwner {
        if(manager == address(0)) revert Errors.ZeroAddress();
        approvedManagers[manager] = false;
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Block user fee claims
     */
    function blockClaim() external onlyOwner {
        if(_claimBlocked) revert Errors.ClaimBlocked();
        _claimBlocked = true;
    }

    /**
     * @notice Unblock user fee claims
     */
    function unblockClaim() external onlyOwner {
        if(!_claimBlocked) revert Errors.ClaimNotBlocked();
        _claimBlocked = false;
    }

    /**
     * @dev Withdraw either a lost ERC20 token sent to the contract (expect the feeToken)
     * @param token ERC20 token to withdraw
     * @param amount Amount to transfer (in wei)
     */
    function withdrawERC20(address token, uint256 amount) external onlyOwner returns(bool) {
        if(!_claimBlocked && token == address(feeToken)) revert Errors.CannotWithdrawFeeToken(); //We want to be able to recover the fees if there is an issue
        IERC20(token).safeTransfer(owner(), amount);

        return true;
    }

    /**
     * @notice Deposit fee token in the reserve
     * @param from Address to pull the tokens from
     * @param amount Amount of token to deposit
     */
    function depositToReserve(address from, uint256 amount) external onlyAllowed returns(bool) {
        reserveAmount = reserveAmount + amount;
        feeToken.safeTransferFrom(from, address(this), amount);

        return true;
    }

    /**
     * @notice Withdraw fee tokens from the reserve to send to the Reserve Manager
     * @param amount Amount of token to withdraw
     */
    function withdrawFromReserve(uint256 amount) external onlyAllowed returns(bool) {
        if(amount > reserveAmount) revert Errors.ReserveTooLow();
        reserveAmount = reserveAmount - amount;
        feeToken.safeTransfer(reserveManager, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve VotingEscrow contract  */
interface IVotingEscrow {

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }
    
    function balanceOf(address _account) external view returns (uint256);

    function locked(address _account) external view returns (LockedBalance memory);

    function create_lock(uint256 _value, uint256 _unlock_time) external returns (uint256);

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function locked__end(address _addr) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve BoostV2 contract  */
interface IBoostV2 {

    function balanceOf(address _user) external view returns(uint256);
    function allowance(address _user, address _spender) external view returns(uint256);

    function adjusted_balance_of(address _user) external view returns(uint256);
    function delegated_balance(address _user) external view returns(uint256);
    function received_balance(address _user) external view returns(uint256);
    function delegable_balance(address _user) external view returns(uint256);

    function checkpoint_user(address _user) external;
    function approve(address _spender, uint256 _value) external;
    function boost(address _to, uint256 _amount, uint256 _endtime, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {

    // Access Errors
    error CallerNotAllowed();
    error CallerNotManager();

    // Common Errors
    error ZeroAddress();
    error NullValue();
    error InvalidValue();

    // Update Errors
    error FailRewardUpdate();

    // Offers Errors
    error AlreadyRegistered();
    error WardenNotOperator();
    error NotRegistered();
    error NotOfferOwner();

    // Registration Errors
    error NullPrice();
    error NullMaxDuration();
    error IncorrectExpiry();
    error MaxPercTooHigh();
    error MinPercOverMaxPerc();
    error MinPercTooLow();

    // Purchase Errors
    error PercentUnderMinRequired();
    error PercentOverMax();
    error DurationOverOfferMaxDuration();
    error OfferExpired();
    error DurationTooShort();
    error PercentOutOfferBonds();
    error LockEndTooShort();
    error CannotDelegate();
    error NullFees();
    error FeesTooLow();
    error FailDelegationBoost();

    // Cancel Errors
    error CannotCancelBoost();

    // Claim Fees Errors
    error NullClaimAmount();
    error AmountTooHigh();
    error ClaimBlocked();
    error ClaimNotBlocked();
    error InsufficientCash();

    // Rewards Errors
    error InvalidBoostId();
    error RewardsNotStarted();
    error RewardsAlreadyStarted();
    error BoostRewardsNull();
    error RewardsNotUpdated();
    error NotBoostBuyer();
    error AlreadyClaimed();
    error CannotClaim();
    error InsufficientRewardCash();

    // Admin Errors
    error CannotWithdrawFeeToken();
    error ReserveTooLow();
    error BaseDropTooLow();
    error MinDropTooHigh();

    // MultiBuy Errors
    error NotEnoughFees();
    error FailBoostPurchase();
    error CannotMatchOrder();
    error EmptyArray();
    error InvalidBoostOffer();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
pragma solidity 0.8.10;

import "../oz/utils/Ownable.sol";

/** @title Extend OZ Ownable contract  */
/// @author Paladin

contract Owner is Ownable {

    address public pendingOwner;

    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);

    error CannotBeOwner();
    error CallerNotPendingOwner();
    error OwnerZeroAddress();

    function transferOwnership(address newOwner) public override virtual onlyOwner {
        if(newOwner == address(0)) revert OwnerZeroAddress();
        if(newOwner == owner()) revert CannotBeOwner();
        address oldPendingOwner = pendingOwner;

        pendingOwner = newOwner;

        emit NewPendingOwner(oldPendingOwner, newOwner);
    }

    function acceptOwnership() public virtual {
        if(msg.sender != pendingOwner) revert CallerNotPendingOwner();
        address newOwner = pendingOwner;
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);

        emit NewPendingOwner(newOwner, address(0));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}