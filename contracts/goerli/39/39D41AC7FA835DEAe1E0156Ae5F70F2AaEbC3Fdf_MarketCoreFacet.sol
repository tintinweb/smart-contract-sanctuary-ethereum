// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./base/EternalStorage.sol";
import "./base/IMarketCoreFacet.sol";
import "./base/IMarketObserver.sol";
import "./base/IMarketOfferStates.sol";
import "./base/IParent.sol";
import "./base/IChild.sol";
import "./base/IDiamondFacet.sol";
import "./base/Controller.sol";
import "./base/IERC20.sol";
import "./base/ReentrancyGuard.sol";
import "./MarketFacetBase.sol";

/**
 * Forked from https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol
 */
contract MarketCoreFacet is EternalStorage, Controller, MarketFacetBase, IDiamondFacet, IMarketCoreFacet, IMarketOfferStates, ReentrancyGuard {
    modifier assertIsActive(uint256 _offerId) {
        require(dataUint256[__i(_offerId, "state")] == OFFER_STATE_ACTIVE, "offer not active");
        _;
    }

    /**
     * Constructor
     */
    constructor(address _settings) Controller(_settings) {}

    // IDiamondFacet

    function getSelectors() public pure override returns (bytes memory) {
        return
            abi.encodePacked(
                IMarketCoreFacet.executeLimitOffer.selector,
                IMarketCoreFacet.executeMarketOffer.selector,
                IMarketCoreFacet.buy.selector,
                IMarketCoreFacet.cancel.selector
            );
    }

    // IMarketCoreFacet

    function cancel(uint256 _offerId) external override assertIsActive(_offerId) nonReentrant {
        address creator = dataAddress[__i(_offerId, "creator")];
        require(creator == msg.sender, "only creator can cancel");
        dataUint256[__i(_offerId, "state")] = OFFER_STATE_CANCELLED;
        _cancel(_offerId);
    }

    function buy(uint256 _offerId, uint256 _amount) external override assertIsActive(_offerId) nonReentrant {
        _buyWithObserver(_offerId, _amount, address(0), "");
    }

    function executeLimitOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule,
        address _notify,
        bytes memory _notifyData
    ) public override nonReentrant returns (uint256) {
        _assertValidOffer(_sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        _calculateFee(_sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        uint256 remainingBuyAmount_;
        uint256 remainingSellAmount_;

        (remainingBuyAmount_, remainingSellAmount_, ) = _matchToExistingOffers(_sellToken, _sellAmount, _buyToken, _buyAmount, _notify, _notifyData, false);

        // if still some left
        if (remainingBuyAmount_ > 0 && remainingSellAmount_ > 0 && remainingSellAmount_ >= dataUint256["dust"]) {
            // new offer should be created
            uint256 id = _createOffer(_sellToken, remainingSellAmount_, _buyToken, remainingBuyAmount_, _feeSchedule, _notify, _notifyData, false);

            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(id);

            return id;
        }

        return 0; // no limit offer created, fully matched
    }

    function executeMarketOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken
    ) external override nonReentrant {
        _assertValidOffer(_sellToken, _sellAmount, _buyToken, 1, FEE_SCHEDULE_STANDARD);

        uint256 remainingBuyAmount_;
        uint256 remainingSellAmount_;
        uint256 boughtAmount_;

        (remainingBuyAmount_, remainingSellAmount_, boughtAmount_) = _matchToExistingOffers(_sellToken, _sellAmount, _buyToken, 0, address(0), "", true);

        require(remainingSellAmount_ == 0, "not enough orders in market");

        // market offer settled, create record for history
        uint256 marketOfferId = _createOffer(_sellToken, _sellAmount, _buyToken, boughtAmount_, FEE_SCHEDULE_STANDARD, msg.sender, "", true);
        // `_sellAmount` is used above for setting the initial sell amount on the offer,
        // then it's updated to the actual remaining sell amount after offer execution
        dataUint256[__i(marketOfferId, "sellAmount")] = remainingSellAmount_;
    }

    // Private
    function _insertOfferIntoSortedList(uint256 _offerId) private {
        // check that offer is NOT in the sorted list
        require(!_isOfferInSortedList(_offerId), "offer not in sorted list");

        address sellToken = dataAddress[__i(_offerId, "sellToken")];
        address buyToken = dataAddress[__i(_offerId, "buyToken")];

        uint256 prevId;

        // find position of next highest offer
        uint256 top = dataUint256[__iaa(0, sellToken, buyToken, "bestOfferId")];
        uint256 oldTop = 0;

        while (top != 0 && _isOfferPricedLtOrEq(_offerId, top)) {
            oldTop = top;
            top = dataUint256[__i(top, "rankPrev")];
        }

        uint256 pos = oldTop;

        // insert offer at position
        if (pos != 0) {
            prevId = dataUint256[__i(pos, "rankPrev")];
            dataUint256[__i(pos, "rankPrev")] = _offerId;
            dataUint256[__i(_offerId, "rankNext")] = pos;
        }
        // else this is the new best offer, so insert at top
        else {
            prevId = dataUint256[__iaa(0, sellToken, buyToken, "bestOfferId")];
            dataUint256[__iaa(0, sellToken, buyToken, "bestOfferId")] = _offerId;
        }

        if (prevId != 0) {
            // requirement below is satisfied by statements above
            // require(!_isOfferPricedLtOrEq(_offerId, prevId));
            dataUint256[__i(prevId, "rankNext")] = _offerId;
            dataUint256[__i(_offerId, "rankPrev")] = prevId;
        }

        dataUint256[__iaa(0, sellToken, buyToken, "span")] += 1;
    }

    function _removeOfferFromSortedList(uint256 _offerId) private {
        // check that offer is in the sorted list
        require(_isOfferInSortedList(_offerId), "offer not in sorted list");

        address sellToken = dataAddress[__i(_offerId, "sellToken")];
        address buyToken = dataAddress[__i(_offerId, "buyToken")];

        require(dataUint256[__iaa(0, sellToken, buyToken, "span")] > 0, "token pair sorted list does not exist");

        // if offer is not the highest offer
        if (_offerId != dataUint256[__iaa(0, sellToken, buyToken, "bestOfferId")]) {
            uint256 nextId = dataUint256[__i(_offerId, "rankNext")];
            require(dataUint256[__i(nextId, "rankPrev")] == _offerId, "sort check failed");
            dataUint256[__i(nextId, "rankPrev")] = dataUint256[__i(_offerId, "rankPrev")];
        }
        // if offer is the highest offer
        else {
            dataUint256[__iaa(0, sellToken, buyToken, "bestOfferId")] = dataUint256[__i(_offerId, "rankPrev")];
        }

        // if offer is not the lowest offer
        if (dataUint256[__i(_offerId, "rankPrev")] != 0) {
            uint256 prevId = dataUint256[__i(_offerId, "rankPrev")];
            require(dataUint256[__i(prevId, "rankNext")] == _offerId, "sort check failed");
            dataUint256[__i(prevId, "rankNext")] = dataUint256[__i(_offerId, "rankNext")];
        }

        // nullify
        dataUint256[__i(_offerId, "rankNext")] = 0;
        dataUint256[__i(_offerId, "rankPrev")] = 0;

        dataUint256[__iaa(0, sellToken, buyToken, "span")] -= 1;
    }

    function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) private view returns (bool) {
        uint256 lowSellAmount = dataUint256[__i(_lowOfferId, "sellAmount")];
        uint256 lowBuyAmount = dataUint256[__i(_lowOfferId, "buyAmount")];

        uint256 highSellAmount = dataUint256[__i(_highOfferId, "sellAmount")];
        uint256 highBuyAmount = dataUint256[__i(_highOfferId, "buyAmount")];

        return lowBuyAmount * highSellAmount >= highBuyAmount * lowSellAmount;
    }

    function _isOfferInSortedList(uint256 _offerId) private view returns (bool) {
        address sellToken = dataAddress[__i(_offerId, "sellToken")];
        address buyToken = dataAddress[__i(_offerId, "buyToken")];

        return dataUint256[__i(_offerId, "rankNext")] != 0 || dataUint256[__i(_offerId, "rankPrev")] != 0 || dataUint256[__iaa(0, sellToken, buyToken, "bestOfferId")] == _offerId;
    }

    function _matchToExistingOffers(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        address _notify,
        bytes memory _notifyData,
        bool marketOffer
    )
        private
        returns (
            uint256 remainingBuyAmount_,
            uint256 remainingSellAmount_,
            uint256 matchedAmount_
        )
    {
        remainingBuyAmount_ = _buyAmount;
        remainingSellAmount_ = _sellAmount;
        matchedAmount_ = 0;

        while (remainingSellAmount_ != 0 && (remainingBuyAmount_ != 0 || marketOffer)) {
            // there is at least one offer stored for token pair
            uint256 bestOfferId = dataUint256[__iaa(0, _buyToken, _sellToken, "bestOfferId")];
            if (bestOfferId == 0) {
                break;
            }

            uint256 bestBuyAmount = dataUint256[__i(bestOfferId, "buyAmount")];
            uint256 bestSellAmount = dataUint256[__i(bestOfferId, "sellAmount")];

            if (marketOffer) {
                // market offer pay_amt is smaller than 1 wei of the other token
                if (remainingSellAmount_ * 1 ether < wdiv(bestBuyAmount, bestSellAmount)) {
                    break; // We consider that all amount is sold
                }
            }
            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `bestSellAmount` at +1 away from
            // their "correct" values and `bestBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            //
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            //
            else if (bestBuyAmount * remainingBuyAmount_ > remainingSellAmount_ * bestSellAmount + bestBuyAmount + remainingBuyAmount_ + remainingSellAmount_ + bestSellAmount) {
                break;
            }

            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.

            // avoid stack-too-deep
            {
                // do the buy
                uint256 finalSellAmount = bestBuyAmount < remainingSellAmount_ ? bestBuyAmount : remainingSellAmount_;
                matchedAmount_ += finalSellAmount;

                _buyWithObserver(bestOfferId, finalSellAmount, _notify, _notifyData);

                // calculate how much is left to buy/sell
                uint256 sellAmountOld = remainingSellAmount_;
                remainingSellAmount_ = remainingSellAmount_ - finalSellAmount;
                remainingBuyAmount_ = (remainingSellAmount_ * remainingBuyAmount_) / sellAmountOld;
            }
        }
    }

    function _createOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule,
        address _notify,
        bytes memory _notifyData,
        bool marketOffer
    ) private returns (uint256) {
        dataUint256["lastOfferId"] += 1;
        uint256 id = dataUint256["lastOfferId"];

        dataAddress[__i(id, "creator")] = msg.sender;
        dataAddress[__i(id, "sellToken")] = _sellToken;
        dataUint256[__i(id, "sellAmount")] = _sellAmount;
        dataUint256[__i(id, "sellAmountInitial")] = _sellAmount;
        dataAddress[__i(id, "buyToken")] = _buyToken;
        dataUint256[__i(id, "buyAmount")] = _buyAmount;
        dataUint256[__i(id, "buyAmountInitial")] = _buyAmount;
        dataUint256[__i(id, "feeSchedule")] = _feeSchedule;
        dataAddress[__i(id, "notify")] = _notify;
        dataBytes[__i(id, "notifyData")] = _notifyData;

        if (marketOffer) {
            // market offers are only created for historical reasons, no need to escrow
            dataUint256[__i(id, "state")] = OFFER_STATE_FULFILLED;
        } else {
            dataUint256[__i(id, "state")] = OFFER_STATE_ACTIVE;
            // escrow the tokens for limit offers
            require(IERC20(_sellToken).transferFrom(msg.sender, address(this), _sellAmount), "unable to escrow tokens");
        }

        return id;
    }

    function _buyWithObserver(
        uint256 _offerId,
        uint256 _requestedBuyAmount,
        address _buyNotify,
        bytes memory _buyNotifyData
    ) private {
        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        // (a / b) * c = c * a / b  -> do multiplication first to avoid underflow
        uint256 thisSaleSellAmount = (_requestedBuyAmount * offerSell.amount) / offerBuy.amount;

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, thisSaleSellAmount, _requestedBuyAmount);

        // calculate and take out fees
        (uint256 finalSellAmount, TokenAmount memory fee) = _takeFees(
            offerBuy.token,
            _requestedBuyAmount,
            offerSell.token,
            thisSaleSellAmount,
            dataUint256[__i(_offerId, "feeSchedule")]
        );

        // do the transfer
        require(IERC20(offerBuy.token).transferFrom(msg.sender, dataAddress[__i(_offerId, "creator")], _requestedBuyAmount), "sender -> creator transfer failed");
        require(IERC20(offerSell.token).transfer(msg.sender, finalSellAmount), "market -> sender transfer failed");

        // notify observers
        _notifyObserversOfTrade(_offerId, thisSaleSellAmount, _requestedBuyAmount, fee, _buyNotify, _buyNotifyData);

        // cancel offer if it has become dust
        if (dataUint256[__i(_offerId, "sellAmount")] < dataUint256["dust"]) {
            dataUint256[__i(_offerId, "state")] = OFFER_STATE_FULFILLED;
            _cancel(_offerId);
        }
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) private {
        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        require(uint128(_buyAmount) == _buyAmount, "buy amount exceeds int limit");
        require(uint128(_sellAmount) == _sellAmount, "sell amount exceeds int limit");

        require(_buyAmount > 0, "requested buy amount is 0");
        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount > 0, "calculated sell amount is 0");
        require(_sellAmount <= offerSell.amount, "calculated sell amount too large");

        // update balances
        dataUint256[__i(_offerId, "sellAmount")] = offerSell.amount - _sellAmount;
        dataUint256[__i(_offerId, "buyAmount")] = offerBuy.amount - _buyAmount;
    }

    function _takeFees(
        address _buyToken,
        uint256 _buyAmount,
        address _sellToken,
        uint256 _sellAmount,
        uint256 _feeSchedule
    ) private returns (uint256 finalSellAmount_, TokenAmount memory fee_) {
        address feeBank = _getFeeBank();

        finalSellAmount_ = _sellAmount;

        fee_ = _calculateFee(_buyToken, _buyAmount, _sellToken, _sellAmount, _feeSchedule);

        if (fee_.token == _buyToken) {
            // if fee is to be paid in the buy token then it must be paid on top of buy amount
            require(IERC20(_buyToken).transferFrom(msg.sender, feeBank, fee_.amount), "sender -> feebank fee transfer failed");
        } else {
            // if fee is to be paid in the sell token then it must be paid from the received amount
            finalSellAmount_ = finalSellAmount_ - fee_.amount;
            require(IERC20(_sellToken).transfer(feeBank, fee_.amount), "market -> feebank fee transfer failed");
        }
    }

    function _notifyObserversOfTrade(
        uint256 _offerId,
        uint256 _soldAmount,
        uint256 _boughtAmount,
        TokenAmount memory _fee,
        address _buyNotify,
        bytes memory _buyNotifyData
    ) private {
        address offerNotify = dataAddress[__i(_offerId, "notify")];
        bytes memory offerNotifyData = dataBytes[__i(_offerId, "notifyData")];

        if (_buyNotify != address(0)) {
            IMarketObserver(_buyNotify).handleTrade(_offerId, _soldAmount, _boughtAmount, _fee.token, _fee.amount, msg.sender, _buyNotifyData);
        }

        if (offerNotify != address(0)) {
            IMarketObserver(offerNotify).handleTrade(_offerId, _soldAmount, _boughtAmount, _fee.token, _fee.amount, msg.sender, offerNotifyData);
        }
    }

    function _cancel(uint256 _offerId) private {
        if (_isOfferInSortedList(_offerId)) {
            _removeOfferFromSortedList(_offerId);
        }

        address creator = dataAddress[__i(_offerId, "creator")];
        address sellToken = dataAddress[__i(_offerId, "sellToken")];
        uint256 sellAmount = dataUint256[__i(_offerId, "sellAmount")];
        uint256 buyAmount = dataUint256[__i(_offerId, "buyAmount")];
        address notify = dataAddress[__i(_offerId, "notify")];
        bytes memory notifyData = dataBytes[__i(_offerId, "notifyData")];

        // transfer remaining sell amount back to creator
        if (sellAmount > 0) {
            require(IERC20(sellToken).transfer(creator, sellAmount), "refund creator failed");
        }

        // notify observers
        if (notify != address(0)) {
            IMarketObserver(notify).handleClosure(_offerId, sellAmount, buyAmount, notifyData);
        }
    }

    function _assertValidOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) private view {
        require(uint128(_sellAmount) == _sellAmount, "sell amount must be uint128");
        require(uint128(_buyAmount) == _buyAmount, "buy amount must be uint128");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_sellToken != address(0), "sell token must be valid");
        require(_buyAmount > 0, "buy amount must be >0");
        require(_buyToken != address(0), "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");

        // if caller requested the 'platform action' fee schedule then check that they're allowed to do so
        if (_feeSchedule == FEE_SCHEDULE_PLATFORM_ACTION) {
            // get and check parent
            address parent = IChild(msg.sender).getParent();
            require(IParent(parent).hasChild(msg.sender), "fee schedule: bad parent");

            // get entity deployer
            address entityDeployer = settings().getRootAddress(SETTING_ENTITY_DEPLOYER);

            // if parent is NOT the entity deployer then the grandparent must be
            if (parent != entityDeployer) {
                // the caller must be a policy, in which case let's goto the grandparent
                address grandparent = IChild(parent).getParent();
                require(IParent(grandparent).hasChild(parent), "fee schedule: bad grandparent");
                require(grandparent == entityDeployer, "fee schedule: bad deployment");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Base contract for any upgradeable contract that wishes to store data.
 */
contract EternalStorage {
    // scalars
    mapping(string => address) dataAddress;
    mapping(string => bytes32) dataBytes32;
    mapping(string => int256) dataInt256;
    mapping(string => uint256) dataUint256;
    mapping(string => bool) dataBool;
    mapping(string => string) dataString;
    mapping(string => bytes) dataBytes;
    // arrays
    mapping(string => address[]) dataManyAddresses;
    mapping(string => bytes32[]) dataManyBytes32s;
    mapping(string => int256[]) dataManyInt256;
    mapping(string => uint256[]) dataManyUint256;

    // helpers
    function __i(uint256 i1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, s));
    }

    function __a(address a1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, s));
    }

    function __aa(
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, a2, s));
    }

    function __b(bytes32 b1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(b1, s));
    }

    function __ii(
        uint256 i1,
        uint256 i2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, i2, s));
    }

    function __ia(
        uint256 i1,
        address a1,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, s));
    }

    function __iaa(
        uint256 i1,
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, s));
    }

    function __iaaa(
        uint256 i1,
        address a1,
        address a2,
        address a3,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, a3, s));
    }

    function __ab(address a1, bytes32 b1) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, b1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IMarketCoreFacet {
    /**
     * @dev Execute a limit offer with an observer attached.
     *
     * The observer must implement `IMarketObserver`. It will be notified when the order
     * trades and/or gets cancelled.
     *
     * @param _sellToken token to sell.
     * @param _sellAmount amount to sell.
     * @param _buyToken token to buy.
     * @param _buyAmount Amount to buy.
     * @param _feeSchedule Requested fee schedule, one of the `FEE_SCHEDULE_...` constants.
     * @param _notify `IMarketObserver` to notify when a trade takes place and/or order gets cancelled.
     * @param _notifyData Data to pass through to the notified contract.
     *
     * @return >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the
     * return value is the created offer's id.
     */
    function executeLimitOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule,
        address _notify,
        bytes memory _notifyData
    ) external returns (uint256);

    /**
     * @dev Execute a market offer, ensuring the full amount gets sold.
     *
     * This will revert if the full amount could not be sold.
     *
     * @param _sellToken token to sell.
     * @param _sellAmount amount to sell.
     * @param _buyToken token to buy.
     *
     */
    function executeMarketOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken
    ) external;

    /**
     * @dev Buy an offer
     *
     * @param _offerId offer id.
     * @param _amount amount (upto the offer's `buyAmount`) of offer's `buyToken` to buy with.
     */
    function buy(uint256 _offerId, uint256 _amount) external;

    /**
     * @dev Cancel an offer.
     *
     * This will revert the offer is not longer active.
     *
     * @param _offerId offer id.
     */
    function cancel(uint256 _offerId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * A `IMarket` observer which receives notifications of trades and cancellations.
 */
abstract contract IMarketObserver {
    /**
     * @dev Handle a trade notification.
     *
     * @param _offerId Order id.
     * @param _soldAmount Amount sold.
     * @param _boughtAmount Amount bought.
     * @param _feeToken Fee token.
     * @param _feeAmount Fee paid.
     * @param _buyer Order buyer.
     * @param _data Extra metadata that is being passed through.
     */
    function handleTrade(
        uint256 _offerId,
        uint256 _soldAmount,
        uint256 _boughtAmount,
        address _feeToken,
        uint256 _feeAmount,
        address _buyer,
        bytes memory _data
    ) external virtual {}

    /**
     * @dev Handle an order cancellation or closure.
     *
     * @param _offerId Order id.
     * @param _unsoldAmount Amount remaining unsold.
     * @param _unboughtAmount Amount remaining unbought.
     * @param _data Extra metadata that is being passed through.
     */
    function handleClosure(
        uint256 _offerId,
        uint256 _unsoldAmount,
        uint256 _unboughtAmount,
        bytes memory _data
    ) external virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Type constants for market offer states.
 */
abstract contract IMarketOfferStates {
    /**
     * @dev Offer is active
     */
    uint256 public constant OFFER_STATE_ACTIVE = 1;
    /**
     * @dev Offer is cancelled
     */
    uint256 public constant OFFER_STATE_CANCELLED = 2;
    /**
     * @dev Offer is fulfilled
     */
    uint256 public constant OFFER_STATE_FULFILLED = 3;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Interface for contracts that create other contracts and wish to keep track of them.
 */
interface IParent {
    /**
     * @dev Get the no. of children created.
     */
    function getNumChildren() external view returns (uint256);

    /**
     * @dev Get child at given 1-based index.
     *
     * @param _index index starting at 1.
     *
     * @return The child contract address.
     */
    function getChild(uint256 _index) external view returns (address);

    /**
     * @dev Get whether this contract is the parent/creator of given child.
     *
     * @param _child potential child contract.
     *
     * @return true if so, false otherwise.
     */
    function hasChild(address _child) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev The complement to `IParent`.
 */
interface IChild {
    /**
     * @dev Get the parent/creator of this contract.
     */
    function getParent() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IDiamondFacet {
    function getSelectors() external pure returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./SettingsControl.sol";
import "./AccessControl.sol";

/**
 * @dev Base contract for interacting with the ACL and Settings contracts.
 */
contract Controller is AccessControl, SettingsControl {
    /**
     * @dev Constructor.
     * @param _settings Settings address.
     */
    constructor(address _settings) AccessControl(_settings) SettingsControl(_settings) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

// From OpenZeppellin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

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
    uint256 private _status = _NOT_ENTERED;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./base/IMarketFeeSchedules.sol";
import "./base/EternalStorage.sol";
import "./base/Controller.sol";
import "./base/Utils.sol";

/**
 * @dev Market facet base class
 */
abstract contract MarketFacetBase is EternalStorage, Controller, IMarketFeeSchedules {
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    function _getFeeBank() internal view returns (address) {
        return settings().getRootAddress(SETTING_FEEBANK);
    }

    function _getBestOfferId(address _sellToken, address _buyToken) internal view returns (uint256) {
        return dataUint256[__iaa(0, _sellToken, _buyToken, "bestOfferId")];
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        sell_.token = dataAddress[__i(_offerId, "sellToken")];
        sell_.amount = dataUint256[__i(_offerId, "sellAmount")];
        buy_.token = dataAddress[__i(_offerId, "buyToken")];
        buy_.amount = dataUint256[__i(_offerId, "buyAmount")];
    }

    function _calculateFee(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) internal view returns (TokenAmount memory fee_) {
        // are we selling a platform token
        bool sellTokenIsPlatformToken = Utils.isNaymsPlatformToken(_sellToken);
        bool buyTokenIsPlatformToken = Utils.isNaymsPlatformToken(_buyToken);

        // XOR: trade is valid iff one token is platform token
        require((sellTokenIsPlatformToken || buyTokenIsPlatformToken) && !(sellTokenIsPlatformToken && buyTokenIsPlatformToken), "must be one platform token");

        uint256 feeBP = dataUint256["feeBP"];

        if (sellTokenIsPlatformToken) {
            fee_.token = _buyToken;
            fee_.amount = (feeBP * _buyAmount) / 10000;
        } else {
            fee_.token = _sellToken;
            fee_.amount = (feeBP * _sellAmount) / 10000;
        }

        // if fee schedule is "platform action" then no fee is to be charged
        if (_feeSchedule == FEE_SCHEDULE_PLATFORM_ACTION) {
            fee_.amount = 0;
        }
    }

    // These are from https://github.com/nayms/maker-otc/blob/master/contracts/math.sol
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * 10**18) + (y / 2)) / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./EternalStorage.sol";
import "./ISettings.sol";
import "./ISettingsControl.sol";
import "./ISettingsKeys.sol";

/**
 * @dev Base contract for interacting with Settings.
 */
contract SettingsControl is EternalStorage, ISettingsControl, ISettingsKeys {
    /**
     * @dev Constructor.
     * @param _settings Settings address.
     */
    constructor(address _settings) {
        dataAddress["settings"] = _settings;
    }

    /**
     * @dev Get Settings reference.
     * @return Settings reference.
     */
    function settings() public view override returns (ISettings) {
        return ISettings(dataAddress["settings"]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./Address.sol";
import "./EternalStorage.sol";
import "./ISettings.sol";
import "./IACL.sol";
import "./IAccessControl.sol";
import "./IACLConstants.sol";

/**
 * @dev Base contract for interacting with the ACL.
 */
contract AccessControl is EternalStorage, IAccessControl, IACLConstants {
    using Address for address;

    /**
     * @dev Constructor.
     * @param _settings Address of Settings.
     */
    constructor(address _settings) {
        dataAddress["settings"] = _settings;
        dataBytes32["aclContext"] = acl().generateContextFromAddress(address(this));
    }

    /**
     * @dev Check that sender is an admin.
     */
    modifier assertIsAdmin() {
        require(isAdmin(msg.sender), "must be admin");
        _;
    }

    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) public view override returns (bool) {
        return acl().isAdmin(_addr);
    }

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) public view override returns (bool) {
        return inRoleGroupWithContext(aclContext(), _addr, _roleGroup);
    }

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) public view override returns (bool) {
        return acl().hasRoleInGroup(_ctx, _addr, _roleGroup);
    }

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() public view override returns (IACL) {
        return ISettings(dataAddress["settings"]).acl();
    }

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() public view override returns (bytes32) {
        return dataBytes32["aclContext"];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./ISettingsKeys.sol";
import "./IACL.sol";

/**
 * @dev Settings.
 */
abstract contract ISettings is ISettingsKeys {
    /**
     * @dev Get ACL.
     */
    function acl() public view virtual returns (IACL);

    /**
     * @dev Get an address.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getAddress(address _context, bytes32 _key) public view virtual returns (address);

    /**
     * @dev Get an address in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootAddress(bytes32 _key) public view virtual returns (address);

    /**
     * @dev Set an address.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setAddress(
        address _context,
        bytes32 _key,
        address _value
    ) external virtual;

    /**
     * @dev Get an address.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getAddresses(address _context, bytes32 _key) public view virtual returns (address[] memory);

    /**
     * @dev Get an address in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootAddresses(bytes32 _key) public view virtual returns (address[] memory);

    /**
     * @dev Set an address.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setAddresses(
        address _context,
        bytes32 _key,
        address[] calldata _value
    ) external virtual;

    /**
     * @dev Get a boolean.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getBool(address _context, bytes32 _key) public view virtual returns (bool);

    /**
     * @dev Get a boolean in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootBool(bytes32 _key) public view virtual returns (bool);

    /**
     * @dev Set a boolean.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setBool(
        address _context,
        bytes32 _key,
        bool _value
    ) external virtual;

    /**
     * @dev Get a number.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getUint256(address _context, bytes32 _key) public view virtual returns (uint256);

    /**
     * @dev Get a number in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootUint256(bytes32 _key) public view virtual returns (uint256);

    /**
     * @dev Set a number.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setUint256(
        address _context,
        bytes32 _key,
        uint256 _value
    ) external virtual;

    /**
     * @dev Get a string.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getString(address _context, bytes32 _key) public view virtual returns (string memory);

    /**
     * @dev Get a string in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootString(bytes32 _key) public view virtual returns (string memory);

    /**
     * @dev Set a string.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setString(
        address _context,
        bytes32 _key,
        string memory _value
    ) external virtual;

    /**
     * @dev Get current block time.
     *
     * @return Block time.
     */
    function getTime() external view virtual returns (uint256);

    // events

    /**
     * @dev Emitted when a setting gets updated.
     * @param context The context.
     * @param key The key.
     * @param caller The caller.
     * @param keyType The type of setting which changed.
     */
    event SettingChanged(address indexed context, bytes32 indexed key, address indexed caller, string keyType);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./ISettings.sol";

interface ISettingsControl {
    /**
     * @dev Get Settings reference.
     * @return Settings reference.
     */
    function settings() external view returns (ISettings);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Settings keys.
 */
contract ISettingsKeys {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant SETTING_MARKET = 0x6f244974cc67342b1bd623d411fd8100ec9eddbac05348e71d1a9296de6264a5;
    bytes32 public constant SETTING_FEEBANK = 0x6a4d660b9f1720511be22f039683db86d0d0d207c2ad9255325630800d4fb539;
    bytes32 public constant SETTING_ETHER_TOKEN = 0xa449044fc5332c1625929b3afecb2f821955279285b4a8406a6ffa8968c1b7cf;
    bytes32 public constant SETTING_ENTITY_IMPL = 0x098afcb3a137a2ba8835fbf7daecb275af5afb3479f12844d5b7bfb8134e7ced;
    bytes32 public constant SETTING_POLICY_IMPL = 0x0e8925aa0bfe65f831f6c9099dd95b0614eb69312630ef3497bee453d9ed40a9;
    bytes32 public constant SETTING_MARKET_IMPL = 0xc72bfe3e0f1799ce0d90c4c72cf8f07d0cfa8121d51cb05d8c827f0896d8c0b6;
    bytes32 public constant SETTING_FEEBANK_IMPL = 0x9574e138325b5c365da8d5cc75cf22323ed6f3ce52fac5621225020a162a4c61;
    bytes32 public constant SETTING_ENTITY_DEPLOYER = 0x1bf52521006d8a3718b0692b7f32c8ee781bfed9e9215eb5b8fc3b34749fb5b5;
    bytes32 public constant SETTING_ENTITY_DELEGATE = 0x063693c9545b949ff498535f9e0aa95ada8e88c062d28e2f219b896e151e1266;
    bytes32 public constant SETTING_POLICY_DELEGATE = 0x5c6c7d4897f0ae38084370e7a61ea386e95c7f54629c0b793a0ac47751f12405;
    // END: Generated by script outputConstants.js
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev ACL (Access Control List).
 */
interface IACL {
    // admin

    /**
     * @dev Check if given address has the admin role.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Assign admin role to given address.
     * @param _addr Address to assign to.
     */
    function addAdmin(address _addr) external;

    /**
     * @dev Remove admin role from given address.
     * @param _addr Address to remove from.
     */
    function removeAdmin(address _addr) external;

    // contexts

    /**
     * @dev Get the no. of existing contexts.
     * @return no. of contexts
     */
    function getNumContexts() external view returns (uint256);

    /**
     * @dev Get context at given index.
     * @param _index Index into list of all contexts.
     * @return context name
     */
    function getContextAtIndex(uint256 _index) external view returns (bytes32);

    /**
     * @dev Get the no. of addresses belonging to (i.e. who have been assigned roles in) the given context.
     * @param _context Name of context.
     * @return no. of addresses
     */
    function getNumUsersInContext(bytes32 _context) external view returns (uint256);

    /**
     * @dev Get the address at the given index in the list of addresses belonging to the given context.
     * @param _context Name of context.
     * @param _index Index into the list of addresses
     * @return the address
     */
    function getUserInContextAtIndex(bytes32 _context, uint256 _index) external view returns (address);

    // users

    /**
     * @dev Get the no. of contexts the given address belongs to (i.e. has an assigned role in).
     * @param _addr Address.
     * @return no. of contexts
     */
    function getNumContextsForUser(address _addr) external view returns (uint256);

    /**
     * @dev Get the contexts at the given index in the list of contexts the address belongs to.
     * @param _addr Address.
     * @param _index Index of context.
     * @return Context name
     */
    function getContextForUserAtIndex(address _addr, uint256 _index) external view returns (bytes32);

    /**
     * @dev Get whether given address has a role assigned in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @return true if so
     */
    function userSomeHasRoleInContext(bytes32 _context, address _addr) external view returns (bool);

    // role groups

    /**
     * @dev Get whether given address has a role in the given rolegroup in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roleGroup The role group.
     * @return true if so
     */
    function hasRoleInGroup(
        bytes32 _context,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Set the roles for the given role group.
     * @param _roleGroup The role group.
     * @param _roles List of roles.
     */
    function setRoleGroup(bytes32 _roleGroup, bytes32[] calldata _roles) external;

    /**
     * @dev Get whether given given name represents a role group.
     * @param _roleGroup The role group.
     * @return true if so
     */
    function isRoleGroup(bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Get the list of roles in the given role group
     * @param _roleGroup The role group.
     * @return role list
     */
    function getRoleGroup(bytes32 _roleGroup) external view returns (bytes32[] memory);

    /**
     * @dev Get the list of role groups which contain given role
     * @param _role The role.
     * @return rolegroup list
     */
    function getRoleGroupsForRole(bytes32 _role) external view returns (bytes32[] memory);

    // roles

    /**
     * @dev Get whether given address has given role in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     * @return either `DOES_NOT_HAVE_ROLE` or one of the `HAS_ROLE_...` constants
     */
    function hasRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external view returns (uint256);

    /**
     * @dev Get whether given address has any of the given roles in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roles The role list.
     * @return true if so
     */
    function hasAnyRole(
        bytes32 _context,
        address _addr,
        bytes32[] calldata _roles
    ) external view returns (bool);

    /**
     * @dev Assign a role to the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     */
    function assignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

    /**
     * @dev Assign a role to the given address in the given context and id.
     * @param _context Context name.
     * @param _id Id.
     * @param _addr Address.
     * @param _role The role.
     */
    // function assignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

    /**
     * @dev Remove a role from the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role to unassign.
     */
    function unassignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

    /**
     * @dev Remove a role from the given address in the given context.
     * @param _context Context name.
     * @param _id Id.
     * @param _addr Address.
     * @param _role The role to unassign.
     */
    // function unassignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

    /**
     * @dev Get all role for given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @return list of roles
     */
    function getRolesForUser(bytes32 _context, address _addr) external view returns (bytes32[] memory);

    /**
     * @dev Get all addresses for given role in the given context.
     * @param _context Context name.
     * @param _role Role.
     * @return list of roles
     */
    function getUsersForRole(bytes32 _context, bytes32 _role) external view returns (address[] memory);

    // who can assign roles

    /**
     * @dev Add given rolegroup as an assigner for the given role.
     * @param _roleToAssign The role.
     * @param _assignerRoleGroup The role group that should be allowed to assign this role.
     */
    function addAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;

    /**
     * @dev Remove given rolegroup as an assigner for the given role.
     * @param _roleToAssign The role.
     * @param _assignerRoleGroup The role group that should no longer be allowed to assign this role.
     */
    function removeAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;

    /**
     * @dev Get all rolegroups that are assigners for the given role.
     * @param _role The role.
     * @return list of rolegroups
     */
    function getAssigners(bytes32 _role) external view returns (bytes32[] memory);

    /**
   * @dev Get whether given address can assign given role within the given context.

   * @param _context Context name.
   * @param _assigner Assigner address.
   * @param _assignee Assignee address.
   * @param _role The role to assign.
   * @return one of the `CANNOT_ASSIGN...` or `CAN_ASSIGN_...` constants
   */
    function canAssign(
        bytes32 _context,
        address _assigner,
        address _assignee,
        bytes32 _role
    ) external view returns (uint256);

    // utility methods

    /**
     * @dev Generate the context name which represents the given address.
     *
     * @param _addr Address.
     * @return context name.
     */
    function generateContextFromAddress(address _addr) external pure returns (bytes32);

    /**
     * @dev Emitted when a role group gets updated.
     * @param roleGroup The rolegroup which got updated.
     */
    event RoleGroupUpdated(bytes32 indexed roleGroup);

    /**
     * @dev Emitted when a role gets assigned.
     * @param context The context within which the role got assigned.
     * @param addr The address the role got assigned to.
     * @param role The role which got assigned.
     */
    event RoleAssigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

    /**
     * @dev Emitted when a role gets unassigned.
     * @param context The context within which the role got assigned.
     * @param addr The address the role got assigned to.
     * @param role The role which got unassigned.
     */
    event RoleUnassigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

    /**
     * @dev Emitted when a role assigner gets added.
     * @param role The role that can be assigned.
     * @param roleGroup The rolegroup that will be able to assign this role.
     */
    event AssignerAdded(bytes32 indexed role, bytes32 indexed roleGroup);

    /**
     * @dev Emitted when a role assigner gets removed.
     * @param role The role that can be assigned.
     * @param roleGroup The rolegroup that will no longer be able to assign this role.
     */
    event AssignerRemoved(bytes32 indexed role, bytes32 indexed roleGroup);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Collection of functions related to the address type
 *
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
library Address {
    /**
     * @dev Returns true if `_account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address _account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(_account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function toPayable(address _account) internal pure returns (address payable) {
        return payable(address(uint160(_account)));
    }

    /**
     * @dev Converts an `address` into `string` hex representation.
     * From https://ethereum.stackexchange.com/a/58341/56159
     */
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IACL.sol";

interface IAccessControl {
    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() external view returns (IACL);

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev ACL Constants.
 */
abstract contract IACLConstants {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant ROLE_APPROVED_USER = 0x9c259f9342405d034b902fd5e1bba083f008e305ea4eb6a0dce9ac9a6256b63a;
    bytes32 public constant ROLE_PENDING_UNDERWRITER = 0xad56f8a5432d383c3e2c11b7b248f889e6ec544090486b3623f0f4ae1fad763b;
    bytes32 public constant ROLE_PENDING_BROKER = 0x3bd41a6d84c7de1e9d18694bd113405090439b9e32d5ab69d575821d513d83b5;
    bytes32 public constant ROLE_PENDING_INSURED_PARTY = 0x052b977cd6067e43b9140f08c53a22b88418f4d3ab7bd811716130d5a20cd8a3;
    bytes32 public constant ROLE_PENDING_CLAIMS_ADMIN = 0x325a96ceff51ae6b22de25dd7b4c8b9532dddf936add8ef16fc99219ff666a84;
    bytes32 public constant ROLE_UNDERWRITER = 0x8858a0dfcbfa158449ee0a3b5dae898cecc0746569152b05bbab9526bcc16864;
    bytes32 public constant ROLE_CAPITAL_PROVIDER = 0x428fa9969c6b3fab7bbdac20b73706f1f670a386be0a76d4060c185898b2aa22;
    bytes32 public constant ROLE_BROKER = 0x2623111b4a77e415ab5147aeb27da976c7a27950b6ec4022b4b9e77176266992;
    bytes32 public constant ROLE_INSURED_PARTY = 0x737de6bdef2e959d9f968f058e3e78b7365d4eda8e4023ecac2d51e3dbfb1401;
    bytes32 public constant ROLE_CLAIMS_ADMIN = 0x391db9b692991836c38aedfd24d7f4c9837739d4ee0664fe4ee6892a51e025a7;
    bytes32 public constant ROLE_ENTITY_ADMIN = 0x0922a3d5a8713fcf92ec8607b882fd2fcfefd8552a3c38c726d96fcde8b1d053;
    bytes32 public constant ROLE_ENTITY_MANAGER = 0xcfd13d23f7313d54f3a6d98c505045c58749561dd04531f9f2422a8818f0c5f8;
    bytes32 public constant ROLE_ENTITY_REP = 0xcca1ad0e9fb374bbb9dc3d0cbfd073ef01bd1d01d5a35bd0a93403fbee64318d;
    bytes32 public constant ROLE_POLICY_OWNER = 0x7f7cc8b2bac31c0e372310212be653d159f17ff3c41938a81446553db842afb6;
    bytes32 public constant ROLE_POLICY_CREATOR = 0x1d60d7146dec74c1b1a9dc17243aaa3b56533f607c16a718bcd78d8d852d6e52;
    bytes32 public constant ROLE_SYSTEM_ADMIN = 0xd708193a9c8f5fbde4d1c80a1e6f79b5f38a27f85ca86eccac69e5a899120ead;
    bytes32 public constant ROLE_SYSTEM_MANAGER = 0x807c518efb8285611b15c88a7701e4f40a0e9a38ce3e59946e587a8932410af8;
    bytes32 public constant ROLEGROUP_APPROVED_USERS = 0x9c687089ee5ebd0bc2ba9c954ebc7a0304b4046890b9064e5742c8c6c7afeab2;
    bytes32 public constant ROLEGROUP_CAPITAL_PROVIDERS = 0x2db57b52c5f263c359ba92194f5590b4a7f5fc1f1ca02f10cea531182851fe28;
    bytes32 public constant ROLEGROUP_POLICY_CREATORS = 0xdd53f360aa973c3daf7ff269398ced1ce7713d025c750c443c2abbcd89438f83;
    bytes32 public constant ROLEGROUP_BROKERS = 0x8d632412946eb879ebe5af90230c7db3f6d17c94c0ecea207c97e15fa9bb77c5;
    bytes32 public constant ROLEGROUP_INSURED_PARTYS = 0x65d0db34d07de31cfb8ca9f95dabc0463ce6084a447abb757f682f36ae3682e3;
    bytes32 public constant ROLEGROUP_CLAIMS_ADMINS = 0x5c7c2bcb0d2dfef15c423063aae2051d462fcd269b5e9b8c1733b3211e17bc8a;
    bytes32 public constant ROLEGROUP_ENTITY_ADMINS = 0x251766d8c7c7a6b927647b0f20c99f490db1c283eb0c482446085aaaa44b5e73;
    bytes32 public constant ROLEGROUP_ENTITY_MANAGERS = 0xa33a59233069411012cc12aa76a8a426fe6bd113968b520118fdc9cb6f49ae30;
    bytes32 public constant ROLEGROUP_ENTITY_REPS = 0x610cf17b5a943fc722922fc6750fb40254c24c6b0efd32554aa7c03b4ca98e9c;
    bytes32 public constant ROLEGROUP_POLICY_OWNERS = 0xc59d706f362a04b6cf4757dd3df6eb5babc7c26ab5dcc7c9c43b142f25da10a5;
    bytes32 public constant ROLEGROUP_SYSTEM_ADMINS = 0xab789755f97e00f29522efbee9df811265010c87cf80f8fd7d5fc5cb8a847956;
    bytes32 public constant ROLEGROUP_SYSTEM_MANAGERS = 0x7c23ac65f971ee875d4a6408607fabcb777f38cf73b3d6d891648646cee81f05;
    bytes32 public constant ROLEGROUP_TRADERS = 0x9f4d1dc1107c7d9d9f533f41b5aa5dbbb3b830e3b597338a8aee228ab083eb3a;
    bytes32 public constant ROLEGROUP_UNDERWRITERS = 0x18ecf8d2173ca8a5766fd7dde3bdb54017dc5413dc07cd6ba1785b63e9c62b82;
    // END: Generated by script outputConstants.js

    // used by canAssign() method
    uint256 public constant CANNOT_ASSIGN = 0;
    uint256 public constant CANNOT_ASSIGN_USER_NOT_APPROVED = 100;
    uint256 public constant CAN_ASSIGN_IS_ADMIN = 1;
    uint256 public constant CAN_ASSIGN_IS_OWN_CONTEXT = 2;
    uint256 public constant CAN_ASSIGN_HAS_ROLE = 3;

    // used by hasRole() method
    uint256 public constant DOES_NOT_HAVE_ROLE = 0;
    uint256 public constant HAS_ROLE_CONTEXT = 1;
    uint256 public constant HAS_ROLE_SYSTEM_CONTEXT = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Market fee schedules
 */
abstract contract IMarketFeeSchedules {
    /**
     * @dev Standard fee is charged.
     */
    uint256 public constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 public constant FEE_SCHEDULE_PLATFORM_ACTION = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./PlatformToken.sol";

/**
 * @dev Nayms utils.
 */
library Utils {
    /**
     * @dev Get whether given token is a Nayms platform token.
     * @return true if so, false otherwise.
     */
    function isNaymsPlatformToken(address _token) internal view returns (bool) {
        try PlatformToken(_token).isNaymsPlatformToken() returns (bool v) {
            return v;
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Base class for all of our platform tokens.
 */
abstract contract PlatformToken {
    bool public isPlatformToken = true;

    /**
     * @dev Get whether this is a Nayms platform token.
     */
    function isNaymsPlatformToken() public view returns (bool) {
        return isPlatformToken;
    }
}