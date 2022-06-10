// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./MarsBase.sol";
import "./MarsBaseCommon.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title MarsBaseExchange
/// @author dOTC Marsbase
/// @notice This contract contains the public facing elements of the marsbase exchange. 
contract MarsBaseExchange {
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

    address marsBaseOffersAddress;
    address marsBaseMinimumOffersAddress;
    address owner;

    uint256 nextOfferId;

    uint256 minimumFee = 10;

    address commissionWallet;
    address commissionExchanger;

    bool locked;

    mapping(uint256 => MarsBaseCommon.MBOffer) public offers;

    /// Constructor sets owner and commission wallet to the contract creator initially.
    constructor() {
        owner = msg.sender;
        commissionWallet = msg.sender;
        locked = false;
    }

    struct MBAddresses {
        address offersContract;
        address minimumOffersContract;
    }

    modifier unlocked {
        require(locked == false, "S9");
        _;
    }

    /// Updates the address where the commisions are sent
    /// Can only be called by the owner
    function setCommissionAddress(address wallet) unlocked public {
        require(msg.sender == owner, "S7");

        commissionWallet = wallet;
    }

    /// Updates the address where the commisions are exchanged
    /// Can only be called by the owner
    function setExchangerAddress(address exchangeContract) unlocked public {
        require(msg.sender == owner, "S7");

        commissionExchanger = exchangeContract;
    }

    /// Updates the minimum fee amount
    /// Can be only called by the owner
    /// Is in the format of an integer, with a maximum of 1000.
    /// For example, 1% fee is 10, 100% is 1000 and 0.1% is 1.
    function setMinimumFee(uint256 _minimumFee) unlocked public {
        require(msg.sender == owner, "S7");

        minimumFee = _minimumFee;
    }

    function setNextOfferId(uint256 _nextOfferId) unlocked public {
        require(msg.sender == owner, "S7");

        nextOfferId = _nextOfferId;
    }

    /// Gets an offer by its id
    function getOffer(uint256 offerId)
        public
        view
        returns (MarsBaseCommon.MBOffer memory)
    {
        return offers[offerId];
    }

    /// Gets the next offer ID
    /// This should return the amount of offers that have ever been created, including those that are no longer active.
    function getNextOfferId() public view returns (uint256) {
        return nextOfferId;
    }


    /// Return the address of the current owner.
    function getOwner() public view returns (address) {
        return owner;
    }

    /// Change the owner address
    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "S7");
        require(newOwner != address(0), "T0");

        owner = newOwner;
    }

    /// Swaps commission for a token to USDT and sends it to the commission wallet
    /// If no exchange contract is set the commission is sent to the commsiion wallet
    function swapCommission(uint256 amount, address token) internal {

        if (amount == 0 || commissionWallet == address(0)) {
            return;
        }

        if (token != address(0)) {
            uint256 balance = IERC20(token).balanceOf(address(this));

            if (balance < amount) {
               amount = balance;
            }
        }

        if (commissionExchanger != address(0)) {
            IERC20(token).approve(commissionExchanger, amount);
            IMarsbaseSink(commissionExchanger).liquidateToken(msg.sender, token, amount, commissionWallet);
        } else {
            if (token != address(0)) {
                IERC20(token).transfer(commissionWallet, amount);
            } else {
                commissionWallet.call{value: amount};
            }
        }
    }

    // Gets a list of all active offers
    function getAllOffers()
        public
        view
        returns (MarsBaseCommon.MBOffer[] memory)
    {
        MarsBaseCommon.MBOffer[]
            memory openOffers = new MarsBaseCommon.MBOffer[](nextOfferId);
        uint256 counter = 0;

        for (uint256 index = 0; index < nextOfferId; index++) {
            if (getOffer(index).active == true) {
                openOffers[counter] = getOffer(index);
                counter++;
            }
        }

        return openOffers;
    }


    /// Creates an offer
    /// tokenAlice - the address of the token that will be put up for sale
    /// tokenBob - a list of tokens that we are willing to accept in exchange for token alice.
    /// NOTE: If the user would like to accept native ether, token bob should have an element with a zero address. This indicates that we accept native ether.
    /// amountAlice - the amount of tokenAlice we are putting for sale, in wei.
    /// amountBob - a list of the amounts we are willing to accept for each token bob. This is then compared with amountAlice to generate a fixed exchange rate.
    /// offerParamaters - The configureation parameters for the offer to set the conditions for the sale. 
    function createOffer(
        address tokenAlice,
        address[] calldata tokenBob,
        uint256 amountAlice,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) unlocked public payable {
        require(
            offerParameters.feeAlice + offerParameters.feeBob >= minimumFee,
            "M0"
        );

        offers[nextOfferId] = MarsBase.createOffer(
            nextOfferId,
            tokenAlice,
            tokenBob,
            amountAlice,
            amountBob,
            offerParameters
        );
        emit OfferCreated(
            nextOfferId,
            msg.sender,
            block.timestamp,
            offers[nextOfferId]
        );

        nextOfferId++;
    }

    /// Cancels the offer at the provided ID
    /// Must be the offer creator.
    function cancelOffer(uint256 offerId) public {
        offers[offerId] = MarsBase.cancelOffer(offers[offerId]);
        emit OfferCancelled(offerId, msg.sender, block.timestamp);
        emit OfferClosed(offerId, MarsBaseCommon.OfferCloseReason.CancelledBySeller, block.timestamp);
    }

    /// Calculate the price for a given situarion
    function price(
        uint256 amountAlice,
        uint256 offerAmountAlice,
        uint256 offerAmountBob
    ) public pure returns (uint256) {
        return MarsBase.price(amountAlice, offerAmountAlice, offerAmountBob);
    }

    /// Accepts an offer
    /// This can be either in full or partially. Uses the provided token and amount.
    /// NOTE: for native ether, tokenBob should be a zero address. amountBob is set by the transaction value automatically, but should match the amount provided when calling.
    /// The proper function to handle the proccess is selected automatically.
    function acceptOffer(
        uint256 offerId,
        address tokenBob,
        uint256 amountBob
    ) unlocked public payable {
        MarsBaseCommon.MBOffer memory offer = offers[offerId];
        MarsBaseCommon.OfferType offerType = offer.offerType;

        bool shouldSwap = true;

        if (tokenBob == address(0)) {
            amountBob = msg.value;
        }

        if (
            MarsBase.contractType(offerType) ==
            MarsBaseCommon.ContractType.Offers
        ) {
            if (
                offerType == MarsBaseCommon.OfferType.FullPurchase ||
                offerType == MarsBaseCommon.OfferType.LimitedTime
            ) {
                offers[offerId] = MarsBase.acceptOffer(
                    offer,
                    tokenBob,
                    amountBob
                );
            } else {
                offers[offerId] = MarsBase.acceptOfferPart(
                    offer,
                    tokenBob,
                    amountBob
                );
            }
        } else {
            offers[offerId] = MarsBase.acceptOfferPartWithMinimum(
                offer,
                tokenBob,
                amountBob
            );

            shouldSwap = offers[offerId].minimumMet;
        }

        uint256 amountTransacted = offer.amountRemaining - offers[offerId].amountRemaining;
        uint256 feeAlice = amountTransacted - (amountTransacted * (1000-offer.feeAlice) / 1000);
        uint256 feeBob = amountBob - (amountBob * (1000-offer.feeBob) / 1000);

        if (shouldSwap == true) {
            swapCommission(feeAlice, offer.tokenAlice);
            swapCommission(feeBob, tokenBob);
        }

        emit OfferAccepted(
            offerId,
            msg.sender,
            block.timestamp,
            amountTransacted,
            amountBob,
            offer.tokenAlice,
            tokenBob,
            offerType,
            feeAlice,
            feeBob
        );

        if (offers[offerId].active == false) {
            emit OfferClosed(offerId, MarsBaseCommon.OfferCloseReason.Success, block.timestamp);
        }
    }

    /// Allows the offer creator to set the offer parameters after creation.
    function changeOfferParams(
        uint256 offerId,
        address[] calldata tokenBob,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) unlocked public {
        offers[offerId] = MarsBase.changeOfferParams(
            offers[offerId],
            tokenBob,
            amountBob,
            offerParameters
        );

        emit OfferModified(
            offerId,
            msg.sender,
            block.timestamp,
            offerParameters
        );
    }

    /// Allows the buyer to cancel his bid in situations where the exchange has not occured yet.
    /// This applys only to offers where minimumSize is greater than zero and the minimum has not been met.
    function cancelBid(uint256 offerId) public {
        offers[offerId] = MarsBase.cancelBid(offers[offerId]);

        emit BidCancelled(offerId, msg.sender, block.timestamp);
    }

    /// A function callable by the contract owner to cancel all offers where the time has expired.
    function cancelExpiredOffers() public payable {
        require(msg.sender == owner, "S8");

        for (uint256 index = 0; index < nextOfferId; index++) {
            if (
                block.timestamp >= offers[index].deadline &&
                offers[index].deadline != 0 &&
                MarsBase.contractType(offers[index].offerType) == MarsBaseCommon.ContractType.Offers
            ) {
                offers[index] = MarsBase.cancelExpiredOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);
            } else {
                offers[index] = MarsBase.cancelExpiredMinimumOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);

            }
        }
    }

    function migrateContract() unlocked public payable {
        require(msg.sender == owner, "S8");

        for (uint256 index = 0; index < nextOfferId; index++) {
            if (
                offers[index].active == true &&
                MarsBase.contractType(offers[index].offerType) == MarsBaseCommon.ContractType.Offers
            ) {
                offers[index] = MarsBase.cancelExpiredOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);
            } else if (offers[index].active == true) {
                offers[index] = MarsBase.cancelExpiredMinimumOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);
            }
        }

        locked = true;

        emit ContractMigrated();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MarsBaseCommon.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMarsbaseSink.sol";

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

    offer.capabilities = new bool[](3);

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

    require(block.timestamp < offer.deadline || offer.deadline == 0, "M2");

    address acceptedTokenBob = address(0);
    uint256 acceptedAmountBob = 0;
    for (uint256 index = 0; index < offer.tokenBob.length; index++) {
      if (offer.tokenBob[index] == tokenBob) {
        acceptedTokenBob = offer.tokenBob[index];
        acceptedAmountBob = offer.amountBob[index];
      }
    }

    // if (acceptedTokenBob == address(0)) {
    //   acceptedAmountBob = msg.value;
    // }

    uint256 partialAmountAlice = price(amountBob, acceptedAmountBob, offer.amountAlice);
    uint256 partialAmountBob = price(partialAmountAlice, offer.amountAlice, acceptedAmountBob);

    uint256 amountAfterFeeAlice = partialAmountBob * (1000-offer.feeBob) / 1000;
    uint256 amountAfterFeeBob = partialAmountAlice * (1000-offer.feeAlice) / 1000;

    require(acceptedTokenBob == tokenBob, "T3");

    require(partialAmountBob >= 0, "M6");

    require(partialAmountAlice >= offer.smallestChunkSize, "M1");
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
          (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index]}("");
          require(success, "t1b");
        }
      }
    }

    require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountAlice), "T1b");

    delete offer;

    return offer;
  }

  function payMinimumOffer(MarsBaseCommon.MBOffer memory offer, uint256 tokensSold, address acceptedTokenBob, uint256 amountAfterFeeAlice, uint256 amountAfterFeeBob, uint256 partialAmountAlice, uint256 partialAmountBob) private returns (MarsBaseCommon.MBOffer memory) {
    if ((tokensSold >= offer.minimumSize && offer.capabilities[2] == false) ||
      (tokensSold == offer.amountAlice && offer.capabilities[2] == true) || 
      (tokensSold >= offer.minimumSize && offer.capabilities[2] == true && offer.deadline < block.timestamp)) {
      if (acceptedTokenBob != address(0)) {
        require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeAlice), "T2a");
        require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeBob), "T5");
        require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), partialAmountAlice - amountAfterFeeAlice), "T1a");
      } else {
        require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeBob), "T5");
        (bool success, bytes memory data) = offer.payoutAddress.call{value: amountAfterFeeAlice}("");
        require(success, "t1b");
      }
      for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
        if (offer.minimumOrderAmountsAlice[index] != 0) {
          if (offer.minimumOrderTokens[index] != address(0)) {
            require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.payoutAddress, offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob) / 1000), "T2b");
            require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeAlice) / 1000), "T1b");
            // require(IERC20(offer.minimumOrderTokens[index]).transfer(address(this), offer.minimumOrderAmountsBob[index] - (offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob))), "T1a");
          } else {
            (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index] * (1000-offer.feeAlice) / 1000}("");
            require(success, "t1b");
            require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeBob) / 1000), "T1b");
          }
        }

        offer.minimumMet = true;
      }

      delete offer.minimumOrderAddresses;
      delete offer.minimumOrderAmountsBob;
      delete offer.minimumOrderAmountsAlice;
      delete offer.minimumOrderTokens;

      if (offer.amountRemaining > 0 && (((offer.amountRemaining * 1000) / (offer.amountAlice) <= 10) || offer.smallestChunkSize > offer.amountRemaining)) {
        require(IERC20(offer.tokenAlice).transfer(offer.payoutAddress, offer.amountRemaining), "T1b");
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
        (bool success, bytes memory data) = offer.offerer.call{value: offer.amountRemaining}("");
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
            (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index]}("");
            require(success, "t1b");
          }
        }

        require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountRemaining), "T1b");
      } else {
        for (uint256 index = 0; index < offer.minimumOrderAddresses.length; index++) {
          if (offer.minimumOrderAmountsAlice[index] != 0) {
            if (offer.minimumOrderTokens[index] != address(0)) {
              require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeAlice) / 1000), "T2b");
              require(IERC20(offer.minimumOrderTokens[index]).transfer(offer.payoutAddress, offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob) / 1000), "T1b");
              // require(IERC20(offer.minimumOrderTokens[index]).transfer(commissionWallet, offer.minimumOrderAmountsBob[index] - (offer.minimumOrderAmountsBob[index] * (1000-offer.feeBob))), "T1a");
            } else {
              (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index] * (1000-offer.feeAlice) / 1000}("");
              require(success, "t1b");
              require(IERC20(offer.tokenAlice).transfer(offer.minimumOrderAddresses[index], offer.minimumOrderAmountsAlice[index] * (1000-offer.feeBob) / 1000), "T1b");
            }
          }
        }

        require(IERC20(offer.tokenAlice).transfer(offer.offerer, offer.amountRemaining), "T1b");
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
          (bool success, bytes memory data) = offer.minimumOrderAddresses[index].call{value: offer.minimumOrderAmountsBob[index]}("");
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

    if (acceptedTokenBob != address(0)) {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), amountFeeDex), "T5");
    } else {
      //send ether
      (bool success, bytes memory data) = offer.payoutAddress.call{value: amountAfterFeeBob}("");
      require(success, "t1b");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
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

    uint256 amountAfterFeeAlice = partialAmountAlice * (1000-offer.feeAlice) / 1000;
    uint256 amountAfterFeeBob = partialAmountBob * (1000-offer.feeBob) / 1000;
    uint256 amountFeeDex = partialAmountBob - amountAfterFeeBob;

    require(amountAfterFeeBob >= 0, "M8");
    require(amountFeeDex >= 0, "M7");

    require(partialAmountAlice >= offer.smallestChunkSize, "M1");
    require(amountAfterFeeAlice <= offer.amountRemaining, "M10");

    if (acceptedTokenBob != address(0)) {
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, offer.payoutAddress, amountAfterFeeBob), "T2a");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
      require(IERC20(acceptedTokenBob).transferFrom(msg.sender, address(this), amountFeeDex), "T5");
    } else {
      //send ether
      (bool success, bytes memory data) = offer.payoutAddress.call{value: amountAfterFeeBob}("");
      require(success, "t1b");
      require(IERC20(offer.tokenAlice).transfer(msg.sender, amountAfterFeeAlice), "T1b");
    }

    offer.amountRemaining -= partialAmountAlice;

    if (offer.amountRemaining > 0 && (((offer.amountRemaining * 1000) / (offer.amountAlice) < 10) || offer.smallestChunkSize > offer.amountRemaining)) {
      require(IERC20(offer.tokenAlice).transfer(offer.payoutAddress, offer.amountRemaining), "T1b");
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
      (bool success, bytes memory data) = offer.offerer.call{value: offer.amountRemaining}("");
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
    bool[] capabilities;
    uint256[] amountBob;
    uint256[] minimumOrderAmountsAlice;
    uint256[] minimumOrderAmountsBob;
    address[] minimumOrderAddresses;
    address[] minimumOrderTokens;
    address[] tokenBob;
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