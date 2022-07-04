// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./MarsBase.sol";
import "./MarsBaseCommon.sol";
import "./IMarsbaseExchange.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "hardhat/console.sol";

/// @title MarsBaseExchange
/// @author dOTC Marsbase
/// @notice This contract contains the public facing elements of the marsbase exchange. 
contract MarsBaseExchange is IMarsbaseExchange
{
    address owner;

    uint256 nextOfferId = 0;
	uint256 activeOffersCount = 0;

    uint256 minimumFee = 0;

    address commissionWallet;
    address commissionExchanger;
	
    bool locked = false;

    mapping(uint256 => MarsBaseCommon.MBOffer) public offers;

    constructor() {
		owner = msg.sender;
		commissionWallet = msg.sender;
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
			require(IERC20(tokenAlice).transferFrom(msg.sender, address(this), amountAlice), "402");

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

		emit OfferCreated(offerId, msg.sender, block.timestamp, offers[offerId]);
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
			require(IERC20(token).transfer(to, amountAfterFee), "403-R1");
		else
			require(IERC20(token).transferFrom(from, to, amountAfterFee), "403-R2");

		if (fee > 0)
		{
			require(commissionExchanger == address(0), "NI - commissionExchanger");

			// send fee to commission wallet
			if (from == address(this))
				require(IERC20(token).transfer(commissionWallet, fee), "403-C1");
			else
				require(IERC20(token).transferFrom(from, commissionWallet, fee), "403-C2");
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
		emit OfferAccepted(
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
			IERC20(tokenBob).transferFrom(bob, address(this), amountBob);
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
		emit OfferAccepted(
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
				IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountRemaining);
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
					IERC20(offer.minimumOrderTokens[i]).transfer(offer.minimumOrderAddresses[i], offer.minimumOrderAmountsBob[i]);
				
				if (offer.tokenAlice == address(0))
					_sendEthAfterFee(offer.minimumOrderAmountsAlice[i], offer.offerer, 0);
				else
					IERC20(offer.tokenAlice).transfer(offer.offerer, offer.minimumOrderAmountsAlice[i]);
			}
		}

		delete offers[offerId];
		activeOffersCount--;
		
		emit OfferClosed(
			// uint256 offerId,
			offerId,
			// MarsBaseCommon.OfferCloseReason reason,
			reason,
			// uint256 blockTimestamp
			block.timestamp
		);
	}
	function changeOfferParams(
        uint256 offerId,
        address[] calldata tokenBob,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) unlocked public
	{
		require(false, "NI - changeOfferParams");
	}
	function cancelBid(uint256 offerId) unlocked public
	{
		require(false, "NI - cancelBid");
	}
	function cancelExpiredOffers() public payable
	{
		require(false, "NI - cancelExpiredOffers");
	}
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

import "./MarsBaseCommon.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMarsbaseSink.sol";

// import "hardhat/console.sol";

library MarsBase {
  // MarsBaseCommon.OfferType as int
  /*
    Full Purchase - 0
    Limited Time / Deadline - 1
    Chunked Purchase - 2
    Chunked Purchse with Minimum - 3
    Limited Time / Deadline with Minimum - 4
    Limited Time / Deaadline and Chunked - 5
    Limited Time / Deadline, Chunked with Minimum - 6
    Limited Time / Deadline, Chunked with Minimum with delyed distribution - 7
  */

  function contractType(MarsBaseCommon.OfferType offerType) public pure returns (MarsBaseCommon.ContractType) {
    if (uint8(offerType) < 4) {
      return MarsBaseCommon.ContractType.Offers;
    } else {
      return MarsBaseCommon.ContractType.MinimumOffers;
    }
  }


  function price(uint256 amountAlice, uint256 offerAmountAlice, uint256 offerAmountBob) public pure returns (uint256) {
    uint256 numerator = amountAlice * offerAmountBob;
    uint256 denominator = offerAmountAlice;
    uint256 finalPrice = numerator / denominator;
    return finalPrice;
  }

  function setOfferProperties (MarsBaseCommon.MBOffer memory offer, MarsBaseCommon.OfferParams calldata offerParams) public view returns (MarsBaseCommon.MBOffer memory) {
    require(offer.amountAlice >= offerParams.smallestChunkSize, "M1");
    require(block.timestamp < offerParams.deadline || offerParams.deadline == 0, "M2");

    offer.offerType = getOfferType(offer.amountAlice, offerParams);

    offer.smallestChunkSize = offerParams.smallestChunkSize;

    if (offerParams.cancelEnabled == true) {
      offer.capabilities[1] = true;
    }

    if (offerParams.modifyEnabled == true) {
      offer.capabilities[0] = true;
    }

    if (offerParams.minimumSize != 0) {
      offer.minimumSize = offerParams.minimumSize;

      if (offerParams.minimumSize != 0 && offerParams.holdTokens == true) {
        offer.capabilities[2] = true;
      }

    } else {
      offer.minimumSize = 0;
    }

    offer.deadline = offerParams.deadline;

    return offer;
  }

  function getOfferType (uint256 amountAlice, MarsBaseCommon.OfferParams calldata offerParameters) public pure returns (MarsBaseCommon.OfferType) {
    MarsBaseCommon.OfferType offerType = MarsBaseCommon.OfferType.FullPurchase;

    if (offerParameters.minimumSize == 0) {
      if (offerParameters.deadline > 0 && offerParameters.smallestChunkSize > 0 && offerParameters.smallestChunkSize != amountAlice) {
        offerType = MarsBaseCommon.OfferType.LimitedTimeChunkedPurchase;
      } else if (offerParameters.smallestChunkSize > 0 && offerParameters.smallestChunkSize != amountAlice) {
        offerType = MarsBaseCommon.OfferType.ChunkedPurchase;
      } else if (offerParameters.deadline > 0) {
        offerType = MarsBaseCommon.OfferType.LimitedTime;
      } else {
        offerType = MarsBaseCommon.OfferType.FullPurchase;
      }
    } else {
      if (offerParameters.deadline > 0 && offerParameters.smallestChunkSize > 0 && offerParameters.smallestChunkSize != amountAlice && offerParameters.holdTokens == true) {
        offerType = MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedDeadlinePurchase;
      } else if (offerParameters.deadline > 0 && offerParameters.smallestChunkSize > 0 && offerParameters.smallestChunkSize != amountAlice) {
        offerType = MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedPurchase;
      } else if (offerParameters.smallestChunkSize > 0 && offerParameters.smallestChunkSize != amountAlice) {
        offerType = MarsBaseCommon.OfferType.MinimumChunkedPurchase;
      } else if (offerParameters.deadline > 0) {
        offerType = MarsBaseCommon.OfferType.LimitedTimeMinimumPurchase;
      } else {
        offerType = MarsBaseCommon.OfferType.MinimumChunkedPurchase;
      }
    }

    return offerType;
  }

  function initOffer(uint256 nextOfferId, address tokenAlice, address[] calldata tokenBob, uint256 amountAlice, uint256[] calldata amountBob, MarsBaseCommon.OfferParams calldata offerParameters) public pure returns (MarsBaseCommon.MBOffer memory) {
    
    MarsBaseCommon.MBOffer memory offer;

    offer.offerId = nextOfferId;

    offer.tokenAlice = tokenAlice;
    offer.tokenBob = tokenBob;

    offer.amountAlice = amountAlice;
    offer.amountBob = amountBob;

    offer.feeAlice = offerParameters.feeAlice;
    offer.feeBob = offerParameters.feeBob;

    offer.amountRemaining = amountAlice;

    // offer.minimumOrderTokens = new address[](0);
    // offer.minimumOrderAddresses = new address[](0);
    // offer.minimumOrderAmountsAlice = new uint256[](0);
    // offer.minimumOrderAmountsBob = new uint256[](0);

    offer.capabilities = [offerParameters.modifyEnabled, offerParameters.cancelEnabled, offerParameters.holdTokens];

    offer.active = true;
    offer.minimumMet = false;

    return offer;
  }

  function createOffer(uint256 nextOfferId, address tokenAlice, address[] calldata tokenBob, uint256 amountAlice, uint256[] calldata amountBob, MarsBaseCommon.OfferParams calldata offerParameters) public returns (MarsBaseCommon.MBOffer memory) {
    MarsBaseCommon.MBOffer memory offer = initOffer(nextOfferId, tokenAlice, tokenBob, amountAlice, amountBob, offerParameters);
    offer = setOfferProperties(offer, offerParameters);
    offer.offerType = getOfferType(amountAlice, offerParameters);
    offer.feeAlice = offerParameters.feeAlice;
    offer.feeBob = offerParameters.feeBob;
    offer.payoutAddress = msg.sender;
    offer.offerer = msg.sender;

    require(amountAlice >= offerParameters.smallestChunkSize, "M1");
    require(amountAlice >= offerParameters.minimumSize, "M13");
    require(block.timestamp < offerParameters.deadline || offerParameters.deadline == 0, "M2");

    if (tokenAlice != address(0)) {
      require(IERC20(offer.tokenAlice).transferFrom(msg.sender, address(this), amountAlice), "T1a");
    } else {
      require(msg.value > 0, "M3");
      require(msg.value == offer.amountAlice, "T1a");
      offer.amountAlice = msg.value;
    }

    return offer;
  }

  function changeOfferParams(MarsBaseCommon.MBOffer memory offer, address[] calldata tokenBob, uint256[] calldata amountBob, MarsBaseCommon.OfferParams calldata offerParameters) public view returns (MarsBaseCommon.MBOffer memory) {
    require(offer.offerer == msg.sender, "S2");
    require(tokenBob.length == amountBob.length, "M5");

    require(offer.capabilities[0] == true, "S4");

    require(offerParameters.smallestChunkSize <= offer.amountAlice, "M1");

    offer.tokenBob = tokenBob;
    offer.amountBob = amountBob;
    offer.feeAlice = offerParameters.feeAlice;
    offer.feeBob = offerParameters.feeBob;
    offer.smallestChunkSize = offerParameters.smallestChunkSize;
    offer.deadline = offerParameters.deadline;

    return offer;
  }

  function acceptOfferPartWithMinimum(MarsBaseCommon.MBOffer memory offer, address tokenBob, uint256 amountBob) public returns (MarsBaseCommon.MBOffer memory) {
    require(offer.active == true, "S0");
    require(offer.offerType == MarsBaseCommon.OfferType.MinimumChunkedPurchase || 
      offer.offerType == MarsBaseCommon.OfferType.LimitedTimeMinimumPurchase || 
      offer.offerType == MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedPurchase ||
      offer.offerType == MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedDeadlinePurchase, "S5");

    require((block.timestamp < offer.deadline) || (offer.deadline == 0), "M2");

    address acceptedTokenBob = address(0);
    uint256 acceptedAmountBob = 0;
    for (uint256 index = 0; index < offer.tokenBob.length; index++) {
      if (offer.tokenBob[index] == tokenBob) {
        acceptedTokenBob = offer.tokenBob[index];
        acceptedAmountBob = offer.amountBob[index];
      }
    }

	require(acceptedAmountBob > 0, "M6b");

    // if (acceptedTokenBob == address(0)) {
    //   acceptedAmountBob = msg.value;
    // }

    uint256 partialAmountAlice = price(amountBob, acceptedAmountBob, offer.amountAlice);
    uint256 partialAmountBob = amountBob;

    uint256 amountAfterFeeAlice = partialAmountAlice * (1000-offer.feeAlice) / 1000;
    uint256 amountAfterFeeBob = partialAmountBob * (1000-offer.feeBob) / 1000;

    require(acceptedTokenBob == tokenBob, "T3");

    require(partialAmountBob >= 0, "M6");

    // require(partialAmountAlice >= offer.smallestChunkSize, "M1");
    require(partialAmountAlice <= offer.amountRemaining, "M10");
    
    offer.amountRemaining -= partialAmountAlice;

    uint256 tokensSold = offer.amountAlice - offer.amountRemaining;

    offer = payMinimumOffer(offer, tokensSold, acceptedTokenBob, amountAfterFeeAlice, amountAfterFeeBob, partialAmountAlice, partialAmountBob);

    if (offer.amountRemaining == 0) {
      delete offer;
    }

    return offer;
  }

  function cancelExpiredMinimumOffer(MarsBaseCommon.MBOffer memory offer) public returns (MarsBaseCommon.MBOffer memory) {
    require(offer.offerType != MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedDeadlinePurchase && offer.deadline < block.timestamp, "S1");
    require(offer.active == true, "S0");
    require(offer.amountAlice > 0, "M3");
    require(contractType(offer.offerType) == MarsBaseCommon.ContractType.MinimumOffers, "S5");

    for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
      if (offer.minimumOrderAmountsAlice[index] != 0) {
        if (offer.minimumOrderTokens[index] != address(0)) {
          require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsBob[index]), "T2b");
        } else {
          (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index], gas: 30000}("");
          require(success, "t1b");
        }
      }
    }

    require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountAlice), "T1b");

    delete offer;

    return offer;
  }

  function payMinimumOffer(MarsBaseCommon.MBOffer memory offer, uint256 tokensSold, address acceptedTokenBob, uint256 amountAfterFeeAlice, uint256 amountAfterFeeBob, uint256 partialAmountAlice, uint256 partialAmountBob) private returns (MarsBaseCommon.MBOffer memory) {
	require(partialAmountAlice >= amountAfterFeeAlice, "HH1a");
	require(partialAmountBob >= amountAfterFeeBob, "HH1b");

	// holdTokens is false and minimumSize is reached, meaning we can start payout
    if ((tokensSold >= offer.minimumSize && offer.capabilities[2] == false) ||
	// or holdTokens is true and all tokens are sold (no point in holding anymore)
      (tokensSold == offer.amountAlice && offer.capabilities[2] == true) || 
	// or holdTokens is true and minimumSize is reached, but the deadline is reached so no point in holding
      (tokensSold >= offer.minimumSize && offer.capabilities[2] == true && offer.deadline < block.timestamp)) {
      if (acceptedTokenBob != address(0) && offer.tokenAlice != address(0)) { // not ETH, tokens on both sides
	  	// send tokenBob to offer maker
        require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
		// send tokenAlice to bidder
        require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T5");
		// if amount after fee is lower than total (meaning there's a fee) we should send Bob's tokens to our contract for later fee extraction
		require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), partialAmountBob - amountAfterFeeBob), "T1a");
      } else if (acceptedTokenBob == address(0)) {
        require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeBob), "T5");
        (bool success, bytes memory data) = offer.payoutAddress.call{value: amountAfterFeeAlice, gas: 30000}("");
        require(success, "t1b");
      } else {
        require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeAlice), "T5");
        (bool success, bytes memory data) = msg.sender.call{value: amountAfterFeeBob, gas: 30000}("");
        require(success, "t1b");
      }
      for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
        if (offer.minimumOrderAmountsAlice[index] != 0) {
          if (offer.minimumOrderTokens[index] != address(0) && offer.tokenAlice != address(0)) {
            require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.payoutAddress, offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob) / 1000), "T2b");
            require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeAlice) / 1000), "T1b");
            // require(IERC20(offer.minimumOrderTokens[index]).transfer(address(this), offer.minimumOrderAmountsBob[index] - (offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob))), "T1a");
          } else if (offer.minimumOrderTokens[index] == address(0)) {
            (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsAlice[index] * (1000-offer.feeAlice) / 1000, gas: 30000}("");
            require(success, "t1b");
            require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob) / 1000), "T1b");
          } else {
            (bool success, bytes memory data) = offer.payoutAddress.call{value: offer.minimumOrderAmountsAlice[index] * (1000-offer.feeAlice) / 1000, gas: 30000}("");
            require(success, "t1b");
            require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.payoutAddress, offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob) / 1000), "T1b");
          }
        }

        offer.minimumMet = true;
      }

      delete offer.minimumOrderAddresses;
      delete offer.minimumOrderAmountsBob;
      delete offer.minimumOrderAmountsAlice;
      delete offer.minimumOrderTokens;

      if (offer.amountRemaining > 0 && (((offer.amountRemaining * 1000) / (offer.amountAlice) <= 10) || offer.smallestChunkSize > offer.amountRemaining)) {
        if (offer.tokenAlice != address(0)) {
          require(IERC20(offer.tokenAlice).transfer(offer.payoutAddress, offer.amountRemaining), "T1b");
        } else {
          (bool success, bytes memory data) = offer.payoutAddress.call{value: offer.amountRemaining}("");
          require(success, "t1b");
        }
        offer.amountRemaining = 0;
      }

    } else if (tokensSold < offer.minimumSize && offer.capabilities[2] == true && offer.offerType == MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedDeadlinePurchase && offer.deadline < block.timestamp) {
      cancelExpiredMinimumOffer(offer);
      return offer;
    } else {
      uint256 chunkAlicedex = offer.minimumOrderAddresses.length;

      if (chunkAlicedex > 0) {
        chunkAlicedex -= 1;
      }

      offer = setMinimumOrderHold(offer, acceptedTokenBob, partialAmountAlice, partialAmountBob);
    }

    return offer;
  }

  function setMinimumOrderHold(MarsBaseCommon.MBOffer memory offer, address acceptedTokenBob, uint256 partialAmountAlice, uint256 partialAmountBob) private returns (MarsBaseCommon.MBOffer memory) {
    uint count = offer.minimumOrderAddresses.length;
    count++;

    address[] memory minimumOrderAddresses = new address[](count);
    uint256[] memory minimumOrderAmountsBob = new uint256[](count);
    uint256[] memory minimumOrderAmountsAlice = new uint256[](count);
    address[] memory minimumOrderTokens = new address[](count);

    if (count > 1) {
      for (uint i = 0; i < count - 1; i++) {
        minimumOrderAddresses[i] = offer.minimumOrderAddresses[i];
        minimumOrderAmountsBob[i] = offer.minimumOrderAmountsBob[i];
        minimumOrderAmountsAlice[i] = offer.minimumOrderAmountsAlice[i];
        minimumOrderTokens[i] = offer.minimumOrderTokens[i];
      }
    }

    minimumOrderAddresses[count - 1] = msg.sender;
    minimumOrderAmountsBob[count - 1] = partialAmountBob;
    minimumOrderAmountsAlice[count - 1] = partialAmountAlice;
    minimumOrderTokens[count - 1] = acceptedTokenBob;

    offer.minimumOrderAddresses = minimumOrderAddresses;
    offer.minimumOrderAmountsBob = minimumOrderAmountsBob;
    offer.minimumOrderAmountsAlice = minimumOrderAmountsAlice;
    offer.minimumOrderTokens = minimumOrderTokens;

    if (acceptedTokenBob != address(0)) {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), partialAmountBob), "T2a");
    }

    return offer;
  }

  function cancelOffer(MarsBaseCommon.MBOffer memory offer) public returns (MarsBaseCommon.MBOffer memory) {
    require(msg.sender == offer.offerer, "S2");
    require(offer.active == true, "S0");
    require(offer.capabilities[1] == true, "S1");
    require(offer.amountAlice > 0, "M3");

    if (contractType(offer.offerType) == MarsBaseCommon.ContractType.Offers) {
      if (offer.tokenAlice == address(0)) {
        (bool success, bytes memory data) = offer.offerer.call{value: offer.amountRemaining, gas: 30000}("");
        require(success, "t1b");
      } else {
        require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountRemaining), "T1b");
      }
    } else {
      if (offer.minimumMet == true) {
        for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
          if (offer.minimumOrderTokens[index] != address(0)) {
            require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsBob[index]), "T2b");
          } else {
            (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index], gas: 30000}("");
            require(success, "t1b");
          }
        }
      } else {
        for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
          if (offer.minimumOrderAmountsAlice[index] != 0) {
            if (offer.minimumOrderTokens[index] != address(0)) {
              require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeAlice) / 1000), "T2b");
              require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.payoutAddress, offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob) / 1000), "T1b");
              // require(IERC20(offer.minimumOrderTokens[index]).transfer(commissionWallet, offer.minimumOrderAmountsBob[index] - (offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob))), "T1a");
            } else {
              (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index] * (1000-offer.feeAlice) / 1000, gas: 30000}("");
              require(success, "t1b");
              require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeBob) / 1000), "T1b");
            }
          }
        }

        if (offer.tokenAlice != address(0)) {
          require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountRemaining), "T1b");
        } else {
          (bool success, bytes memory data) = offer.offerer.call{value: offer.amountRemaining, gas: 30000}("");
          require(success, "t1b");
        }
        
      }
    }

    delete offer;

    return offer;
  }


  function cancelBid(MarsBaseCommon.MBOffer memory offer) public returns (MarsBaseCommon.MBOffer memory) {
    require(offer.active == true, "S0");
    require(offer.amountAlice > 0, "M3");

    require (contractType(offer.offerType) == MarsBaseCommon.ContractType.MinimumOffers, "S5");
    
    for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
      if (offer.minimumOrderAddresses[index] == msg.sender && offer.minimumOrderAmountsAlice[index] != 0) {
        require(IERC20(offer.tokenAlice).transfer(msg.sender, offer.minimumOrderAmountsAlice[index]), "T2b");
        if (offer.minimumOrderTokens[index] != address(0)) {
          require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.offerer, offer.minimumOrderAmountsBob[index]), "T1b");
        } else {
			// console.log(offer.minimumOrderAddresses[index]);
			// console.log(offer.minimumOrderTokens[index]);
			// console.log(offer.minimumOrderAmountsBob[index]);
          (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index], gas: 30000}("");
          require(success, "t1b");
        }

        offer.amountRemaining += offer.minimumOrderAmountsBob[index];

        delete offer.minimumOrderAddresses[index];
        delete offer.minimumOrderAmountsBob[index];
        delete offer.minimumOrderAmountsAlice[index];
        delete offer.minimumOrderTokens[index];
      }
    }

    return offer;
  }

  // MB Offers Normal

  function acceptOffer(MarsBaseCommon.MBOffer memory offer, address tokenBob, uint256 amountBob) public returns (MarsBaseCommon.MBOffer memory) {
    require(offer.active == true, "S0");
    require(block.timestamp < offer.deadline || offer.deadline == 0, "M2");

    address acceptedTokenBob = address(0);
    uint256 acceptedAmountBob = 0;
    for (uint256 index = 0; index < offer.tokenBob.length; index++) {
      if (offer.tokenBob[index] == tokenBob && offer.amountBob[index] == amountBob) {
        acceptedTokenBob = offer.tokenBob[index];
        acceptedAmountBob = offer.amountBob[index];
      }
    }

    require(acceptedTokenBob == tokenBob, "T3");
    require(acceptedAmountBob == amountBob, "T4");

    uint256 amountAfterFeeAlice = offer.amountRemaining * (1000-offer.feeAlice) / 1000;
    uint256 amountAfterFeeBob = acceptedAmountBob * (1000-offer.feeBob) / 1000;
    uint256 amountFeeDex = acceptedAmountBob - amountAfterFeeBob;

if (acceptedTokenBob != address(0) && offer.tokenAlice != address(0)) {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), amountFeeDex), "T5");
    } else if (acceptedTokenBob == address(0)) {
      //send ether
      (bool success, bytes memory data) = offer.payoutAddress.call{value: amountAfterFeeBob, gas: 30000}("");
      require(success, "t1b");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
    } else {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
      (bool success, bytes memory data) = msg.sender.call{value: amountAfterFeeAlice, gas: 30000}("");
      require(success, "t1b");
    }

    delete offer;

    return offer;
  }

  function acceptOfferPart(MarsBaseCommon.MBOffer memory offer, address tokenBob, uint256 amountBob) public returns (MarsBaseCommon.MBOffer memory) {

    require(offer.active == true, "S0");
    require(block.timestamp < offer.deadline || offer.deadline == 0, "M2");
    require(offer.offerType == MarsBaseCommon.OfferType.ChunkedPurchase || 
      offer.offerType == MarsBaseCommon.OfferType.LimitedTimeChunkedPurchase || 
      offer.offerType == MarsBaseCommon.OfferType.LimitedTimeMinimumChunkedPurchase || 
      offer.offerType == MarsBaseCommon.OfferType.MinimumChunkedPurchase, "S5");

    address acceptedTokenBob = address(0);
    uint256 acceptedAmountBob = 0;
    for (uint256 index = 0; index < offer.tokenBob.length; index++) {
      if (offer.tokenBob[index] == tokenBob) {
        acceptedTokenBob = offer.tokenBob[index];
        acceptedAmountBob = offer.amountBob[index];
      }
    }

    if (acceptedTokenBob == address(0)) {
      amountBob = msg.value;
    }

    uint256 partialAmountAlice = price(amountBob, acceptedAmountBob, offer.amountAlice);
    uint256 partialAmountBob = price(partialAmountAlice, offer.amountAlice, acceptedAmountBob);

	require(offer.amountRemaining >= partialAmountAlice, "M10");

    uint256 amountAfterFeeAlice = partialAmountAlice * (1000-offer.feeAlice) / 1000;
    uint256 amountAfterFeeBob = partialAmountBob * (1000-offer.feeBob) / 1000;
    uint256 amountFeeDex = partialAmountBob - amountAfterFeeBob;

    require(amountAfterFeeBob >= 0, "M8");
    require(amountFeeDex >= 0, "M7");

    // require(partialAmountAlice >= offer.smallestChunkSize, "M1");
    require(amountAfterFeeAlice <= offer.amountRemaining, "M10");

    if (acceptedTokenBob != address(0) && offer.tokenAlice != address(0)) {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), amountFeeDex), "T5");
    } else if (acceptedTokenBob == address(0)) {
      //send ether
      (bool success, bytes memory data) = offer.payoutAddress.call{value: amountAfterFeeBob, gas: 30000}("");
      require(success, "t1b");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
    } else {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
      (bool success, bytes memory data) = msg.sender.call{value: amountAfterFeeAlice, gas: 30000}("");
      require(success, "t1b");
    }

    offer.amountRemaining -= partialAmountAlice;

    if (offer.amountRemaining > 0 && (((offer.amountRemaining * 1000) / (offer.amountAlice) < 10) || offer.smallestChunkSize > offer.amountRemaining)) {
      if (offer.tokenAlice != address(0)) {
        require(IERC20(offer.tokenAlice).transfer(offer.payoutAddress, offer.amountRemaining), "T1b");
      } else {
        (bool success, bytes memory data) = offer.payoutAddress.call{value: offer.amountRemaining, gas: 30000}("");
        require(success, "t1b");
      }
      offer.amountRemaining = 0;
    }
    
    if (offer.amountRemaining == 0) {
      delete offer;
    }

    return offer;
  }

  function cancelExpiredOffer(MarsBaseCommon.MBOffer memory offer) public returns (MarsBaseCommon.MBOffer memory) {
    if (offer.capabilities[1] == false) {
      return offer;
    }

    require(offer.capabilities[1] == true, "S1");
    require(offer.active == true, "S0");
    require(offer.amountAlice > 0, "M3");

    if (offer.tokenAlice == address(0)) {
      (bool success, bytes memory data) = offer.offerer.call{value: offer.amountRemaining, gas: 30000}("");
      require(success, "t1b");
    } else {
      require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountRemaining), "T1b");
    }

    delete offer;

    return offer;
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
}

pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";

interface IMarsbaseExchange {
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
pragma solidity >=0.4.22 <0.9.0;

interface IMarsbaseSink {
    function liquidateToken(
        address from,
        address token,
        uint256 amount,
        address receiver
    ) external;
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