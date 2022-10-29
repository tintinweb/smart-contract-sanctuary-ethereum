// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";
import "./IMarsbaseExchange.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

// import "hardhat/console.sol";

/// @title MarsBaseExchange
/// @author dOTC Marsbase
/// @notice This contract contains the public facing elements of the marsbase exchange. 
contract MarsBaseExchange //is IMarsbaseExchange
{
    address owner;

    uint256 nextOfferId = 0;
	uint256 activeOffersCount = 0;

    uint256 minimumFee = 0;

    address commissionWallet;
    address commissionExchanger;
	
    bool locked = false;

    mapping(uint256 => MarsBaseCommon.MBOffer) public offers;

    constructor(uint256 startOfferId) {
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
	function getCommissionAddress() public view returns (address)
	{
		return commissionWallet;
	}
	function setExchangerAddress(address exchangeContract) onlyOwner public
	{
		commissionExchanger = exchangeContract;
	}
	function getExchangerAddress() public view returns (address)
	{
		return commissionExchanger;
	}
	function setMinimumFee(uint256 _minimumFee) onlyOwner public
	{
		minimumFee = _minimumFee;
	}
	function getMinimumFee() public view returns (uint256)
	{
		return minimumFee;
	}
	function setNextOfferId(uint256 _nextOfferId) onlyOwner public
	{
		nextOfferId = _nextOfferId;
	}
	function getNextOfferId() public view returns (uint256)
	{
		return nextOfferId;
	}
	function getOffer(uint256 offerId) public view returns (MarsBaseCommon.MBOffer memory)
	{
		return offers[offerId];
	}
	function getOwner() public view returns (address)
	{
		return owner;
	}
	function changeOwner(address newOwner) onlyOwner public
	{
		owner = newOwner;
	}

	uint256 constant MAX_UINT256 = type(uint256).max;

	uint256 constant POW_2_128 = 2**128;
	uint256 constant POW_2_64 = 2**64;
	uint256 constant POW_2_32 = 2**32;
	uint256 constant POW_2_16 = 2**16;
	uint256 constant POW_2_8 = 2**8;
	uint256 constant POW_2_4 = 2**4;
	uint256 constant POW_2_2 = 2**2;
	uint256 constant POW_2_1 = 2**1;
	
	function log2(uint256 x) public pure returns (uint8 n)
	{
		if (x >= POW_2_128) { x >>= 128; n += 128; }
		if (x >= POW_2_64) { x >>= 64; n += 64; }
		if (x >= POW_2_32) { x >>= 32; n += 32; }
		if (x >= POW_2_16) { x >>= 16; n += 16; }
		if (x >= POW_2_8) { x >>= 8; n += 8; }
		if (x >= POW_2_4) { x >>= 4; n += 4; }
		if (x >= POW_2_2) { x >>= 2; n += 2; }
		if (x >= 2) { n += 1; }
	}

	/**
		Price calculation is approximate, but it's good enough for our purposes.
		We don't need the exact amount of tokens, we just need a close enough approximation.
	*/
	function price(
		uint256 amountAlice,
		uint256 offerAmountAlice,
		uint256 offerAmountBob
	) public pure returns (uint256)
	{
		uint16 amountAliceLog2 = log2(amountAlice);
		uint16 offerAmountBobLog2 = log2(offerAmountBob);

		if ((amountAliceLog2 + offerAmountBobLog2) < 240) // TODO: check bounds for 255 instead of 240
		{
			return (amountAlice * offerAmountBob) / offerAmountAlice;

			// uint256 numerator = amountAlice * offerAmountBob;
			// uint256 finalPrice = numerator / offerAmountAlice;
			// return finalPrice;
		}

		// otherwise, just divide the bigger value
		if (amountAlice >= offerAmountBob)
		{
			// return (amountAlice * offerAmountBob) / offerAmountAlice;
			// return amountAlice * offerAmountBob / offerAmountAlice;
			// return amountAlice / offerAmountAlice * offerAmountBob;
			// return (amountAlice / offerAmountAlice) * offerAmountBob;
			return (amountAlice / offerAmountAlice) * offerAmountBob;
		}
		else
		{
			// return (amountAlice * offerAmountBob) / offerAmountAlice;
			// return amountAlice * offerAmountBob / offerAmountAlice;
			// return amountAlice * offerAmountBob / offerAmountAlice;
			// return amountAlice * (offerAmountBob / offerAmountAlice);
			return amountAlice * (offerAmountBob / offerAmountAlice);
		}
	}

	// max safe uint256 constant that can be calculated for 1e4 fee
	uint256 constant MAX_SAFE_TARGET_AMOUNT = MAX_UINT256 / (1e4);

	function afterFee(uint256 amountBeforeFee, uint256 feePercent) public pure returns (uint256 amountAfterFee, uint256 fee)
	{
		return _afterFee(amountBeforeFee, feePercent, 1e3, MAX_SAFE_TARGET_AMOUNT);
	}
	function _afterFee(uint256 amountBeforeFee, uint256 feePercent, uint256 scale, uint256 safeAmount) public pure returns (uint256 amountAfterFee, uint256 fee)
	{
		if (feePercent == 0)
			return (amountBeforeFee, 0);

		if (feePercent >= scale)
			return (0, amountBeforeFee);

		if (amountBeforeFee < safeAmount)
			fee = (amountBeforeFee * feePercent) / scale;
		else
			fee = (amountBeforeFee / scale) * feePercent;

		amountAfterFee = amountBeforeFee - fee;
		return (amountAfterFee, fee);
	}

	// TODO: rename to `getAllActiveOffers`
	function getAllOffers() public view returns (MarsBaseCommon.MBOffer[] memory)
	{
		MarsBaseCommon.MBOffer[] memory offersArray = new MarsBaseCommon.MBOffer[](activeOffersCount);
		uint256 i = 0;
		for (uint256 offerId = 0; offerId < nextOfferId; offerId++)
		{
			if (offers[offerId].active)
			{
				offersArray[i] = offers[offerId];
				i++;
			}
		}
		return offersArray;
	}
	function limitMinimumSize9999(uint256 minimumSize, uint256 amountAlice) public pure returns (uint256)
	{
		if (minimumSize == 0)
			return minimumSize;
		
		(uint256 amountAfterFee, ) = _afterFee(amountAlice, 1, 1e4, MAX_UINT256 / 1e5);
		if (minimumSize > amountAfterFee)
		{
			minimumSize = amountAfterFee;
		}
		return minimumSize;
	}
	function createOffer(
        address tokenAlice,
        address[] calldata tokenBob,
        uint256 amountAlice,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) unlocked public payable
	{
		// require(!offerParameters.cancelEnabled, "NI - cancelEnabled");
		require(!offerParameters.modifyEnabled, "NI-ME"); // Modify Enabled
		// require(!offerParameters.holdTokens, "NI - holdTokens");
		// require(offerParameters.feeAlice == 0, "NI - feeAlice");
		// require(offerParameters.feeBob == 0, "NI - feeBob");
		// require(offerParameters.smallestChunkSize == 0, "NI - smallestChunkSize");
		// require(offerParameters.deadline == 0, "NI - deadline");
		// require(offerParameters.minimumSize == 0, "NI - minimumSize");
		if (offerParameters.deadline > 0)
			require(offerParameters.deadline > block.timestamp, "405-OD");
		
		// require(tokenAlice != address(0), "NI - tokenAlice ETH");
		require(amountAlice > 0, "400-AAL");

		require(tokenBob.length > 0, "400-BE");
		require(amountBob.length == tokenBob.length, "400-BLMM"); // Bob Length MisMatch
		// for (uint256 i = 0; i < tokenBob.length; i++)
		// {
		// 	require(tokenBob[i] != address(0), "NI - tokenBob ETH");
		// }

		// take tokens from alice
		if (tokenAlice == address(0))
			require(amountAlice == msg.value, "402-E");
		else
			IERC20(tokenAlice).safeTransferFrom(msg.sender, address(this), amountAlice);

		// create offer object
		uint256 offerId = nextOfferId++;
		activeOffersCount++;

		offers[offerId] = MarsBaseCommon.MBOffer(
			true,
			false,
			MarsBaseCommon.OfferType.MinimumChunkedPurchase,
			offerId,
			amountAlice,
			offerParameters.feeAlice,
			offerParameters.feeBob,
			limitMinimumSize9999(offerParameters.smallestChunkSize, amountAlice),
			limitMinimumSize9999(offerParameters.minimumSize, amountAlice),
			offerParameters.deadline,
			amountAlice,
			msg.sender,
			msg.sender,
			tokenAlice,
			[offerParameters.modifyEnabled, offerParameters.cancelEnabled, offerParameters.holdTokens],
			amountBob,
			new uint256[](0),
			new uint256[](0),
			new address[](0),
			new address[](0),
			tokenBob
		);

		// console.log(amountAlice);

		emit MarsBaseCommon.OfferCreated(offerId, msg.sender, block.timestamp, offers[offerId]);
	}
	function sendTokensAfterFeeFrom(
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
			require(commissionExchanger == address(0), "NI - commissionExchanger");

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

		(bool success, ) = to.call{value: amountAfterFee, gas: 30000}("");
		require(success, "404-C1");

		if (fee > 0)
		{
			require(commissionExchanger == address(0), "NI - commissionExchanger");

			// send fee to commission wallet
			(bool success2, ) = commissionWallet.call{value: fee, gas: 30000}("");
			require(success2, "404-C2");
		}
		return (amountAfterFee, fee);
	}
	function acceptOffer(
        uint256 offerId,
        address tokenBob,
        uint256 amountBob
    ) unlocked public payable
	{
		require(amountBob > 0, "400-ABL");
		MarsBaseCommon.MBOffer memory offer = offers[offerId];
		require(offer.active, "404");

		// check that deadline has not passed
		if (offer.deadline > 0)
			require(offer.deadline >= block.timestamp, "405-D"); // deadline has passed

		// check that tokenBob is accepted in the offer
		uint256 offerAmountBob = 0;
		{ // split to block to prevent solidity stack issues
			bool accepted = false;
			for (uint256 i = 0; i < offer.tokenBob.length; i++)
			{
				if (offer.tokenBob[i] == tokenBob)
				{
					accepted = true;
					offerAmountBob = offer.amountBob[i];
					break;
				}
			}
			require(accepted, "404-TBI"); // Token Bob is Incorrect
		}
		
		// calculate how much tokenAlice should be sent
		uint256 amountAlice = price(amountBob, offerAmountBob, offer.amountAlice);

		// check that amountAlice is not too low (if smallestChunkSize is 0 it's also okay)
		require(amountAlice >= min(offer.smallestChunkSize, offer.amountRemaining), "400-AAL");

		// check that amountAlice is not too high
		require(amountAlice <= offer.amountRemaining, "400-AAH"); // Amount Alice is too High
		// we don't throw here so it's possible to "overspend"
		// e.g.:
		// swap 100 $ALICE to 33 $BOB
		// 1 $BOB = 3.333 $ALICE (rounded to 3 due to integer arithmetics)
		// minbid is 11 $BOB
		// Bob buys 33 $ALICE for 11 $BOB (67 $ALICE remaining)
		// Charlie buys 33 $ALICE for 11 $BOB (34 $ALICE remaining)
		// David wants to buy all 34 $ALICE, but:
		// if he tries to send 11 $BOB he will receive only 33 $ALICE
		// if he tries to send 12 $BOB, amountAlice will be 36 $ALICE and tx will revert
		// so we need to let David send a little more $BOB than the limit
		// if (amountAlice > offer.amountRemaining)
		// 	amountAlice = offer.amountRemaining;
		// unfortunately, to prevent front-running we need to make sure
		// that the bidder really expects to get less tokens
		// TODO: we can enable this functionality by providing expected amountAlice into this method (dex-style)


		// update offer
		offers[offerId].amountRemaining -= amountAlice;
		
		offer = offers[offerId];

		// send tokens to participants or schedule for sending later
		bool holdTokens = offer.capabilities[2];

		if (!holdTokens && minimumCovered(offer))
		{
			// console.log("instant");
			// console.log(amountBob);
			// console.log(amountAlice);
			_swapAllHeldTokens(offers[offerId]);
			_swapInstantTokens(offer, tokenBob, amountBob, amountAlice);
		}
		else
		{
			// console.log("hold");
			// console.log(amountBob);
			// console.log(amountAlice);
			_scheduleTokenSwap(offer, tokenBob, amountBob, amountAlice, msg.sender);
		}
		
		offer = offers[offerId];

		if (offer.amountRemaining <= (offer.amountAlice / 10000))
		{
			_swapAllHeldTokens(offers[offerId]);
			_destroyOffer(offerId, MarsBaseCommon.OfferCloseReason.Success);
		}
	}
	function max(uint256 a, uint256 b) public pure returns (uint256)
	{
		return a >= b ? a : b;
	}
	function min(uint256 a, uint256 b) public pure returns (uint256)
	{
		return a >= b ? b : a;
	}
	function minimumCovered(MarsBaseCommon.MBOffer memory offer) pure public returns (bool result)
	{
		uint256 amountSold = offer.amountAlice - offer.amountRemaining;
		result = amountSold >= offer.minimumSize;
	}
	function isEligibleToPayout(MarsBaseCommon.MBOffer memory offer) pure public returns (bool eligible)
	{
		return minimumCovered(offer);
	}
	function cancelOffer(uint256 offerId) unlocked public payable
	{
		MarsBaseCommon.MBOffer memory offer = offers[offerId];
		require(offer.active, "404");
		require(offer.capabilities[1], "400-CE");
		require(offer.offerer == msg.sender, "403");

		if (isEligibleToPayout(offer))
			_swapAllHeldTokens(offer);

		_destroyOffer(offerId, MarsBaseCommon.OfferCloseReason.CancelledBySeller);
	}
	function _emitOfferAcceptedForScheduledSwap(
		MarsBaseCommon.MBOffer memory offer,
		uint256 i
	) private
	{
		(uint256 aliceSentToBob, uint256 feeAliceDeducted) = afterFee(offer.minimumOrderAmountsAlice[i], offer.feeAlice);
		(uint256 bobSentToAlice, uint256 feeBobDeducted) = afterFee(offer.minimumOrderAmountsBob[i], offer.feeBob);

		// emit event
		emit MarsBaseCommon.OfferAccepted(
			// uint256 offerId,
			offer.offerId,
			// address sender,
			offer.minimumOrderAddresses[i],
			// uint256 blockTimestamp,
			block.timestamp,
			// uint256 amountAliceReceived,
			aliceSentToBob,
			// uint256 amountBobReceived,
			bobSentToAlice,
			// address tokenAddressAlice,
			offer.tokenAlice,
			// address tokenAddressBob,
			offer.minimumOrderTokens[i],
			// MarsBaseCommon.OfferType offerType,
			offer.offerType,
			// uint256 feeAlice,
			feeAliceDeducted,
			// uint256 feeBob
			feeBobDeducted
		);
	}
	function _scheduleTokenSwap(
		MarsBaseCommon.MBOffer memory offer,
		address tokenBob,
		uint256 amountBob,
		uint256 amountAlice,
		address bob
	) private
	{
		uint256 index = offers[offer.offerId].minimumOrderAddresses.length;

		// console.log("_scheduleTokenSwap");
		// console.log(amountBob);

		if (tokenBob == address(0))
		{
			require(msg.value == amountBob, "403-C1");
		}
		else
		{
			IERC20(tokenBob).safeTransferFrom(bob, address(this), amountBob);
		}

		offers[offer.offerId].minimumOrderAmountsAlice.push(amountAlice);
		offers[offer.offerId].minimumOrderAmountsBob.push(amountBob);
		offers[offer.offerId].minimumOrderAddresses.push(bob);
		offers[offer.offerId].minimumOrderTokens.push(tokenBob);

		_emitOfferAcceptedForScheduledSwap(offers[offer.offerId], index);
	}
	function _swapInstantTokens(
		MarsBaseCommon.MBOffer memory offer,
		address tokenBob,
		uint256 amountBob,
		uint256 amountAlice
	) private
	{
		// send Bob tokens to Alice
		uint256 bobSentToAlice;
		uint256 feeBobDeducted;
		if (tokenBob == address(0))
		{
			(bobSentToAlice, feeBobDeducted) = _sendEthAfterFee(amountBob, offer.offerer, offer.feeBob);
		}
		else
		{
			(bobSentToAlice, feeBobDeducted) = sendTokensAfterFeeFrom(
				// address token,
				tokenBob,
				// uint256 amount,
				amountBob,
				// address from,
				msg.sender,
				// address to,
				offer.offerer,
				// uint256 feePercent
				offer.feeBob
			);
		}

		// send Alice tokens to Bob
		uint256 aliceSentToBob;
		uint256 feeAliceDeducted;
		if (offer.tokenAlice == address(0))
		{
			(aliceSentToBob, feeAliceDeducted) = _sendEthAfterFee(amountAlice, msg.sender, offer.feeAlice);
		}
		else
		{
			(aliceSentToBob, feeAliceDeducted) = sendTokensAfterFeeFrom(
				// address token,
				offer.tokenAlice,
				// uint256 amount,
				amountAlice,
				// address from,
				address(this),
				// address to,
				msg.sender,
				// uint256 feePercent
				offer.feeAlice
			);
		}

		// emit event
		emit MarsBaseCommon.OfferAccepted(
			// uint256 offerId,
			offer.offerId,
			// address sender,
			msg.sender,
			// uint256 blockTimestamp,
			block.timestamp,
			// uint256 amountAliceReceived,
			aliceSentToBob,
			// uint256 amountBobReceived,
			bobSentToAlice,
			// address tokenAddressAlice,
			offer.tokenAlice,
			// address tokenAddressBob,
			tokenBob,
			// MarsBaseCommon.OfferType offerType,
			offer.offerType,
			// uint256 feeAlice,
			feeAliceDeducted,
			// uint256 feeBob
			feeBobDeducted
		);
	}
	function _swapAllHeldTokens(MarsBaseCommon.MBOffer memory offer) private
	{
		uint256 offerId = offer.offerId;

		// trade all remaining tokens
		for (uint256 i = 0; i < offer.minimumOrderTokens.length; i++)
		{
			// address tokenBob = offer.minimumOrderTokens[i];
			// uint256 amountBob = offer.minimumOrderAmountsBob[i];
			uint256 amountAlice = offer.minimumOrderAmountsAlice[i];

			require(amountAlice > 0, "500-AAL"); // Amount Alice is too Low
			
			// just to future-proof double entry protection in case of refactoring
			offers[offerId].minimumOrderAmountsAlice[i] = 0;

			_swapHeldTokens(offer, i);
		}
		// drop used arrays
		offers[offerId].minimumOrderAmountsAlice = new uint256[](0);
		offers[offerId].minimumOrderAmountsBob = new uint256[](0);
		offers[offerId].minimumOrderAddresses = new address[](0);
		offers[offerId].minimumOrderTokens = new address[](0);
	}
	function _swapHeldTokens(MarsBaseCommon.MBOffer memory offer, uint256 i) private
	{
		// send Bob tokens to Alice
		if (offer.minimumOrderTokens[i] == address(0))
		{
			_sendEthAfterFee(offer.minimumOrderAmountsBob[i], offer.offerer, offer.feeBob);
		}
		else
		{
			sendTokensAfterFeeFrom(
				// address token,
				offer.minimumOrderTokens[i],
				// uint256 amount,
				offer.minimumOrderAmountsBob[i],
				// address from,
				address(this),
				// address to,
				offer.offerer,
				// uint256 feePercent
				offer.feeBob
			);
		}

		// send Alice tokens to Bob
		if (offer.tokenAlice == address(0))
		{
			_sendEthAfterFee(offer.minimumOrderAmountsAlice[i], offer.minimumOrderAddresses[i], offer.feeAlice);
		}
		else
		{
			sendTokensAfterFeeFrom(
				// address token,
				offer.tokenAlice,
				// uint256 amount,
				offer.minimumOrderAmountsAlice[i],
				// address from,
				address(this),
				// address to,
				offer.minimumOrderAddresses[i],
				// uint256 feePercent
				offer.feeAlice
			);
		}

		// do not emit event (it was emit before)

		// // emit event
		// emit OfferAccepted(
		// 	// uint256 offerId,
		// 	offer.offerId,
		// 	// address sender,
		// 	msg.sender,
		// 	// uint256 blockTimestamp,
		// 	block.timestamp,
		// 	// uint256 amountAliceReceived,
		// 	aliceSentToBob,
		// 	// uint256 amountBobReceived,
		// 	bobSentToAlice,
		// 	// address tokenAddressAlice,
		// 	offer.tokenAlice,
		// 	// address tokenAddressBob,
		// 	offer.minimumOrderTokens[i],
		// 	// MarsBaseCommon.OfferType offerType,
		// 	offer.offerType,
		// 	// uint256 feeAlice,
		// 	feeAliceDeducted,
		// 	// uint256 feeBob
		// 	feeBobDeducted
		// );
	}
	function closeExpiredOffer(uint256 offerId) unlocked public
	{
		MarsBaseCommon.MBOffer memory offer = offers[offerId];
		require(offer.active, "404");

		// require offer to be expired
		require((offer.deadline > 0) && (offer.deadline < block.timestamp), "400-NE"); // Not Expired
		
		// if minimum covered
		// uint256 amountSold = offer.amountAlice - offer.amountRemaining;
		// bool minimumCovered = amountSold >= offer.minimumSize;
		// bool minimumCovered = (offer.amountAlice - offer.amountRemaining) >= offer.minimumSize;
		if ((offer.amountAlice - offer.amountRemaining) < offer.minimumSize)
		{
			_destroyOffer(offerId, MarsBaseCommon.OfferCloseReason.DeadlinePassed);
			return;
		}

		// if any tokens are still held in the offer
		if (offer.minimumOrderTokens.length > 0)
		{
			_swapAllHeldTokens(offer);
		}

		_destroyOffer(offerId, MarsBaseCommon.OfferCloseReason.Success);
	}
	function _destroyOffer(uint256 offerId, MarsBaseCommon.OfferCloseReason reason) private
	{
		MarsBaseCommon.MBOffer memory offer = offers[offerId];

		require(offer.active, "404");

		// require(offer.minimumSize == 0, "NI - offer.minimumSize");

		// is this excessive for double-entry prevention?
		offers[offerId].active = false;

		// send remaining tokens to Alice
		if (offer.amountRemaining > 0)
		{
			if (offer.tokenAlice == address(0))
				_sendEthAfterFee(offer.amountRemaining, offer.offerer, 0);
			else
				IERC20(offer.tokenAlice).safeTransfer(offer.offerer, offer.amountRemaining);
		}

		// if any tokens are still held in the offer
		if (offer.minimumOrderTokens.length > 0)
		{
			// revert all tokens to their owners
			for (uint256 i = 0; i < offer.minimumOrderTokens.length; i++)
			{
				if (offer.minimumOrderTokens[i] == address(0))
					_sendEthAfterFee(offer.minimumOrderAmountsBob[i], offer.minimumOrderAddresses[i], 0);
				else
					IERC20(offer.minimumOrderTokens[i]).safeTransfer(offer.minimumOrderAddresses[i], offer.minimumOrderAmountsBob[i]);
				
				if (offer.tokenAlice == address(0))
					_sendEthAfterFee(offer.minimumOrderAmountsAlice[i], offer.offerer, 0);
				else
					IERC20(offer.tokenAlice).safeTransfer(offer.offerer, offer.minimumOrderAmountsAlice[i]);
			}
		}

		delete offers[offerId];
		activeOffersCount--;
		
		emit MarsBaseCommon.OfferClosed(
			// uint256 offerId,
			offerId,
			// MarsBaseCommon.OfferCloseReason reason,
			reason,
			// uint256 blockTimestamp
			block.timestamp
		);
	}
	// function changeOfferParams(
    //     uint256 offerId,
    //     address[] calldata tokenBob,
    //     uint256[] calldata amountBob,
    //     MarsBaseCommon.OfferParams calldata offerParameters
    // ) unlocked public
	// {
	// 	require(false, "NI - changeOfferParams");
	// }
	// function cancelBid(uint256 offerId) unlocked public
	// {
	// 	require(false, "NI - cancelBid");
	// }
	// function cancelExpiredOffers() public payable
	// {
	// 	require(false, "NI - cancelExpiredOffers");
	// }
	function migrateContract() onlyOwner unlocked public payable
	{
		lockContract();
		cancelOffers(0, nextOfferId);
	}
	function lockContract() onlyOwner public
	{
		locked = true;
	}
	function cancelOffers(uint256 from, uint256 to) onlyOwner public payable
	{
		for (uint256 i = from; i < to; i++)
		{
			MarsBaseCommon.MBOffer memory offer = offers[i];
			if (offer.active)
			{
				if (isEligibleToPayout(offer))
					_swapAllHeldTokens(offer);
					
				_destroyOffer(i, MarsBaseCommon.OfferCloseReason.CancelledBySeller);
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

pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";

interface IMarsbaseExchange {

	function setCommissionAddress(address wallet) external;
	function setExchangerAddress(address exchangeContract) external;
	function setMinimumFee(uint256 _minimumFee) external;
	function getMinimumFee() external view returns (uint256);
	function setNextOfferId(uint256 _nextOfferId) external;
	function getOffer(uint256 offerId) external view returns (MarsBaseCommon.MBOffer memory);
	function getNextOfferId() external view returns (uint256);
	function getOwner() external view returns (address);
	function changeOwner(address newOwner) external;
	function getAllOffers() external view returns (MarsBaseCommon.MBOffer[] memory);
	function createOffer(
        address tokenAlice,
        address[] calldata tokenBob,
        uint256 amountAlice,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) external payable;
	function cancelOffer(uint256 offerId) external payable;
	function price(
        uint256 amountAlice,
        uint256 offerAmountAlice,
        uint256 offerAmountBob
    ) external pure returns (uint256);
	function acceptOffer(
        uint256 offerId,
        address tokenBob,
        uint256 amountBob
    ) external payable;
	function changeOfferParams(
        uint256 offerId,
        address[] calldata tokenBob,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) external;
	function cancelBid(uint256 offerId) external;
	function cancelExpiredOffers() external payable;
	function migrateContract() external payable;
	function lockContract() external;
	function cancelOffers(uint256 from, uint256 to) external payable;
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