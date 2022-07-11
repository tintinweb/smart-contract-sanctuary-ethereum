// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "InterfaceERC7772.sol";
import "IERC777.sol";
import "IERC777Sender.sol";
import "IERC777Recipient.sol";
import "IERC1820Registry.sol";
import "ERC1820Implementer.sol";

contract OrderBookSensor2 is
    InterfaceERC7772,
    IERC777Sender,
    IERC777Recipient,
    ERC1820Implementer
{
    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");
    bytes32 public constant TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");

    address public token;
    mapping(address => uint256) public userToHolding;

    constructor(address this_token) {
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        token = this_token;
    }

    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) external override {
        require(
            msg.sender == token,
            "the calling ERC777 token must match supported token"
        );
        // like approve + transferFrom, but only one tx
        userToHolding[_from] += _amount;

        emit TokensReceived(
            msg.sender,
            _operator,
            _from,
            _to,
            _amount,
            _userData,
            _operatorData
        );
    }

    function tokensToSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) external override {
        require(_amount > 0, "zero amount");
        emit TokensToSend(
            msg.sender,
            _operator,
            _from,
            _to,
            _amount,
            _userData,
            _operatorData
        );
    }

    function withdrawAccidental(uint256 _amount) external {
        require(_amount > 0, "zero amount");
        require(userToHolding[msg.sender] >= _amount, "insufficient funds");
        require(
            IERC777(token).balanceOf(address(this)) >= _amount,
            "contract insufficient funds"
        );

        userToHolding[msg.sender] -= _amount;
        IERC777(token).send(msg.sender, _amount, "");
    }

    struct Order {
        uint256 id;
        uint256 limitPrice; //price for each interval
        uint256 amount;
        uint256 entryTime;
        address addressOf;
        string dataAccess;
    }

    struct ActiveStreams {
        address streamingTo;
        uint256 startDataOfStream;
        uint256 endDataOfStream;
        uint256 agreedPrice;
    }

    Order[] private sellList;
    Order[] private buyList;
    uint256 public id;
    uint256 public current_price;
    uint256 public streamingDuration = 5; //here the streaming duration can be defined in seconds
    uint256 public streamingInterval = 1; //here the streaming payout Intervall can be defined in seconds

    mapping(address => ActiveStreams[]) public tradePartners; //stores active dataStreams between buyer and seller, so that no multiple trades of the same dataAccess with the same buyer is not possible
    mapping(address => uint256) public buyerHolding; //stores ScToken of each individual buyer
    mapping(address => uint256) public sellerHolding; //stores ScToken of each individual seller

    event sendData(
        string access_point,
        address seller,
        address buyer,
        uint256 time
    ); //event with hashed information which can be read from outside of the blockchain

    //Sell side of the orderbook
    function getIndexSellList(uint256 _price)
        internal
        view
        returns (uint256 i)
    {
        for (i = 0; i < sellList.length; ) {
            if (sellList[i].limitPrice > _price) {
                i++;
            } else {
                return i;
            }
        }
    }

    function checkSeller(address _check) internal view returns (bool listed) {
        if (sellList.length == 0) {
            return false;
        }
        for (uint256 i = 0; i <= sellList.length - 1; i++) {
            if (sellList[i].addressOf == _check) {
                return true;
            }
        }
        return false;
    }

    function addSellOrder(
        string memory _dataAccess,
        uint256 _amount,
        uint256 _limitPrice
    ) public {
        require(
            checkSeller(msg.sender) == false,
            "remove old order before you make a new one"
        ); //network members are only allowed to have one active Order
        require(_amount > 0, "amount must be bigger than 0"); //network members are only allowed to have one active Order
        Order memory newOrder;
        newOrder.id = id;
        newOrder.limitPrice = _limitPrice;
        newOrder.amount = _amount;
        newOrder.dataAccess = _dataAccess;
        newOrder.entryTime = block.timestamp;
        newOrder.addressOf = msg.sender;
        uint256 rest;
        if (buyList.length == 0) {
            //no Buy Orders -> No trade -> New Order goes into the BuyList
            rest = newOrder.amount;
        } else {
            //checks in the BuyList for possible trades
            //for(uint y = 0; y <= buyList.length;y++){
            rest = priceMatchingNewSell(
                newOrder.limitPrice,
                newOrder.amount,
                newOrder.dataAccess
            );
            //}
        }
        if (rest <= 0) {
            //the requested amount is already fullfilled -> Order wont be stored in the Orderbook
        } else {
            //there was no matching Order in the SellList or the Order was not completly fullfilled the rest amount will be stored in the SellList for future trades
            newOrder.amount = rest;
            if (sellList.length == 0) {
                sellList.push(newOrder);
            } else if (sellList.length == 1) {
                if (sellList[0].limitPrice < newOrder.limitPrice) {
                    sellList.push(sellList[0]);
                    sellList[0] = newOrder;
                } else if (sellList[0].limitPrice >= newOrder.limitPrice) {
                    sellList.push(newOrder);
                }
            } else {
                uint256 position = getIndexSellList(newOrder.limitPrice);
                if (position >= sellList.length) {
                    sellList.push(newOrder);
                } else {
                    uint256 last = sellList.length - 1;
                    sellList.push(sellList[last]);
                    Order memory copyOrder;
                    Order memory copyOrder2;
                    copyOrder = newOrder;

                    for (uint256 i = position; i < sellList.length; i++) {
                        copyOrder2 = sellList[i];
                        sellList[i] = copyOrder;
                        copyOrder = copyOrder2;
                    }
                }
            }
            id++;
        }
    }

    function priceMatchingNewSell(
        uint256 _limitPrice,
        uint256 _amount,
        string memory _dataAccess
    ) internal returns (uint256) {
        uint256 units = 0;
        uint256 accumulated_price = 0;
        for (uint256 i = buyList.length - 1; i >= 0; ) {
            if (
                buyList[i].limitPrice >= _limitPrice &&
                buyList[i].addressOf != msg.sender &&
                checkPartnerNewSell(buyList[i].addressOf) == false
            ) {
                //trade happens if price matches, seller and buyer address no the same, parters didn't trade yet
                ActiveStreams memory newStream;
                newStream.streamingTo = buyList[i].addressOf;
                newStream.startDataOfStream = block.timestamp;
                newStream.endDataOfStream = block.timestamp + streamingDuration;
                newStream.agreedPrice = buyList[i].limitPrice;
                if (buyList[i].amount >= _amount) {
                    //update  buyList
                    buyList[i].amount -= _amount;
                    //current price calculation
                    units = units + _amount;
                    accumulated_price += (buyList[i].limitPrice * _amount);
                    current_price = accumulated_price / units;
                    //regrister active stream from the seller to buyer and make entry for the seller address
                    addPartnerToSeller(newStream);
                    //transfer tokens and data
                    //from buyer to seller _amount* buyList[i].limitPrice

                    emit sendData(
                        _dataAccess,
                        msg.sender,
                        buyList[i].addressOf,
                        block.timestamp
                    );
                    //_amount = 0;
                    //update  buyList
                    if (buyList[i].amount == 0) {
                        internalRemoveBuyOder(i);
                    }
                    if (buyList.length == 0) {
                        return _amount;
                    }
                    if (i == 0) {
                        return _amount;
                    }
                    i--;
                } else if (buyList[i].amount < _amount) {
                    //regrister active stream from the seller to buyer and make entry for the seller address
                    addPartnerToSeller(newStream);
                    //transfer tokens
                    //from buyer to seller  buyList[i].amount* buyList[i].limitPrice
                    emit sendData(
                        _dataAccess,
                        msg.sender,
                        buyList[i].addressOf,
                        block.timestamp
                    );
                    //current price calculation
                    units = units + buyList[i].amount;
                    accumulated_price += (buyList[i].limitPrice *
                        buyList[i].amount);
                    //_amount = _amount - buyList[i].amount;
                    buyList[i].amount == 0;
                    internalRemoveBuyOder(i);
                    if (buyList.length == 0) {
                        current_price = accumulated_price / units;
                        return _amount;
                    }
                    if (i == 0) {
                        return _amount;
                    }
                    i--;
                }
            } else if (
                buyList[i].limitPrice >= _limitPrice &&
                buyList[i].addressOf == msg.sender &&
                checkPartnerNewSell(buyList[i].addressOf) == true
            ) {
                i--;
            } else {
                return _amount;
            }
        }
        return _amount; //NO TRADE with entry -> no price change
    }

    function internalRemoveSellOder(uint256 _index) internal {
        //remove function of the smart contract
        require(_index < sellList.length, "index to high");
        for (uint256 i = _index; i < sellList.length - 1; i++) {
            sellList[i] = sellList[i + 1];
        }
        sellList.pop();
    }

    function removeYourSellOrder() public returns (uint256) {
        require(sellList.length > 0, "no Order places yet");
        require(
            checkSeller(msg.sender) == true,
            "no order from you places yet"
        );
        for (uint256 i = 0; i <= sellList.length - 1; i++) {
            if (sellList[i].addressOf == msg.sender) {
                removeSellOder(i);
                return i;
            }
        }
        return 0;
    }

    function removeSellOder(uint256 _index) internal {
        //manual remove function only the seller is alowed to delete his own order
        Order storage copy = sellList[_index];
        require(_index < sellList.length, "index to high");
        require(
            checkSeller(msg.sender) == true,
            "place an order before you can remove it"
        );
        require(copy.addressOf == msg.sender, "only seller can remove order");
        for (uint256 i = _index; i < sellList.length - 1; i++) {
            sellList[i] = sellList[i + 1];
        }
        sellList.pop();
    }

    function getSellOrder(uint256 _index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        require(sellList.length > 0, "No sell orders in this orderbook");
        require(
            _index <= sellList.length - 1,
            "No entry in the sell side of the orderbook, index too high"
        );
        Order storage i = sellList[_index];
        require(i.addressOf != address(0), "no such order"); // not exists
        return (i.id, i.limitPrice, i.amount, i.entryTime, i.addressOf);
    }

    //Buy side of the orderbook
    function addBuyOrder(uint256 _amount, uint256 _limitPrice) public {
        //checks requiries before any gas fees are paid
        require(
            checkBuyer(msg.sender) == false,
            "remove old order before you submit a new one"
        ); //network members are only allowed to have one active Order
        require(_amount > 0, "amount must be bigger than 0"); //network members are only allowed to have one active Order
        require(_limitPrice > 0, "amount must be bigger than 0"); //network members are only allowed to have one active Order
        require(
            IERC777(token).balanceOf(msg.sender) >=
                _limitPrice * _amount * (streamingDuration / streamingInterval),
            "insufficient funds for the buy oder"
        );
        uint256 required_amount = _limitPrice *
            _amount *
            (streamingDuration / streamingInterval);
        //deposit tokens on smart contract
        IERC777(token).operatorSend(
            msg.sender,
            address(this),
            required_amount,
            "",
            ""
        );
        //safe tokens to buyer address
        buyerHolding[msg.sender] = required_amount;
        Order memory newOrder;
        //saving new buy order in buyList
        newOrder.id = id;
        newOrder.limitPrice = _limitPrice;
        newOrder.amount = _amount;
        newOrder.entryTime = block.timestamp;
        newOrder.addressOf = msg.sender;
        uint256 rest;
        if (sellList.length == 0) {
            //no Sell Orders -> No trade -> New Order goes into the BuyList
            rest = newOrder.amount;
        } else {
            //checks in the SellList for possible trades
            rest = priceMatchingNewBuy(newOrder.limitPrice, newOrder.amount);
        }
        if (rest <= 0) {
            //the requested amount is already fullfilled -> Order wont be stored in the Orderbook
        } else {
            //there was no matching Order in the SellList or the Order was not completly fullfilled the rest amount will be stored in the BuyList for future trades
            newOrder.amount = rest;
            if (buyList.length == 0) {
                buyList.push(newOrder);
            } else if (buyList.length == 1) {
                if (buyList[0].limitPrice <= newOrder.limitPrice) {
                    buyList.push(newOrder);
                } else if (buyList[0].limitPrice > newOrder.limitPrice) {
                    buyList.push(buyList[0]);
                    buyList[0] = newOrder;
                }
            } else {
                uint256 position = getIndexBuyList(newOrder.limitPrice);
                if (position >= buyList.length) {
                    buyList.push(newOrder);
                } else {
                    uint256 last = buyList.length - 1;
                    buyList.push(buyList[last]);
                    Order memory copyOrder;
                    Order memory copyOrder2;
                    copyOrder = newOrder;

                    for (uint256 i = position; i < buyList.length; i++) {
                        copyOrder2 = buyList[i];
                        buyList[i] = copyOrder;
                        copyOrder = copyOrder2;
                    }
                }
            }

            id++;
        }
    }

    function priceMatchingNewBuy(uint256 _limitPrice, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 units = 0;
        uint256 accumulated_price = 0;
        for (uint256 i = sellList.length - 1; i >= 0; ) {
            if (
                sellList[i].limitPrice <= _limitPrice &&
                sellList[i].addressOf != msg.sender &&
                checkPartnerNewSell(sellList[i].addressOf) == false
            ) {
                //TRADE HAPPENS if price matches, seller and buyer address no the same, parters didn't trade yet
                ActiveStreams memory newStream;
                newStream.streamingTo = sellList[i].addressOf;
                newStream.startDataOfStream = block.timestamp;
                newStream.endDataOfStream = block.timestamp + streamingDuration;
                newStream.agreedPrice = sellList[i].limitPrice;
                if (sellList[i].amount >= _amount) {
                    //update sellList
                    //sellList[i].amount = sellList[i].amount - _amount;
                    //current price calculation
                    units = units + _amount;
                    accumulated_price =
                        accumulated_price +
                        (sellList[i].limitPrice * _amount);
                    current_price = accumulated_price / units;
                    //regrister active stream from the seller to buyer and make entry for the seller address
                    addPartnerToSellerNewBuy(newStream);
                    //transfer tokens and data
                    //from buyer to seller _amount*sellList[i].limitPrice userHolding[sellList[i].addressOf] to userHolding[msg.sender]
                    //addPartner(sellList[i].addressOf);
                    emit sendData(
                        sellList[i].dataAccess,
                        sellList[i].addressOf,
                        msg.sender,
                        block.timestamp
                    );
                    _amount = 0;
                    //update sellList
                    //if(sellList[i].amount == 0){
                    //    internalRemoveSellOder(i);
                    //}
                    return _amount;
                } else if (sellList[i].amount < _amount) {
                    //regrister active stream from the seller to buyer and make entry for the seller address
                    addPartnerToSellerNewBuy(newStream);
                    //transfer tokens
                    //from buyer to seller sellList[i].amount*sellList[i].limitPrice
                    //addPartner(sellList[i].addressOf);
                    //from buyer to seller _amount*sellList[i].limitPrice userHolding[sellList[i].addressOf] to userHolding[msg.sender]
                    emit sendData(
                        sellList[i].dataAccess,
                        sellList[i].addressOf,
                        msg.sender,
                        block.timestamp
                    );
                    //current price calculation
                    units = units + sellList[i].amount;
                    accumulated_price += (sellList[i].limitPrice *
                        sellList[i].amount);
                    _amount = _amount - sellList[i].amount;
                    //sellList[i].amount == 0;
                    //internalRemoveSellOder(i);
                    if (_amount == 0) {
                        current_price = accumulated_price / units;
                        return _amount;
                    }
                    //if(sellList.length == 0){
                    //    current_price = accumulated_price/units;
                    //    return _amount;
                    //}
                    if (i == 0) {
                        return _amount;
                    }
                    i--;
                }
            } else if (
                sellList[i].limitPrice <= _limitPrice &&
                sellList[i].addressOf == msg.sender &&
                checkPartnerNewSell(sellList[i].addressOf) == true
            ) {
                if (sellList.length == 1) {
                    return _amount;
                } else {
                    i--;
                }
            } else {
                return _amount;
            }
        }
        return _amount; //NO TRADE with entry -> no price change
    }

    function getIndexBuyList(uint256 _price) internal view returns (uint256 i) {
        for (i = 0; i < buyList.length; ) {
            if (buyList[i].limitPrice >= _price) {
                i++;
            } else {
                return i;
            }
        }
    }

    function checkBuyer(address _check) internal view returns (bool listed) {
        if (buyList.length == 0) {
            return false;
        }
        for (uint256 i = 0; i <= buyList.length - 1; i++) {
            if (buyList[i].addressOf == _check) {
                return true;
            }
        }
        return false;
    }

    function removeYourBuyOrder() public returns (uint256) {
        require(buyList.length > 0, "no Order places yet");
        require(checkBuyer(msg.sender) == true, "no order from you places yet");

        for (uint256 i = 0; i <= buyList.length - 1; i++) {
            if (buyList[i].addressOf == msg.sender) {
                uint256 remainingAmount = buyList[i].limitPrice *
                    buyList[i].amount *
                    (streamingDuration / streamingInterval);
                buyerHolding[msg.sender] -= remainingAmount;
                IERC777(token).operatorSend(
                    address(this),
                    msg.sender,
                    remainingAmount,
                    "",
                    ""
                );
                //transferTokensBack buyList[i].limitPrice*buyList[i].amount the rest needs to stay in the holdingsto Paycurrent streaming contracts
                removeBuyOder(i);
                return i;
            }
        }
        return 0;
    }

    function removeBuyOder(uint256 _index) internal {
        Order storage copy = buyList[_index];
        require(_index < buyList.length, "index to high");
        require(
            checkBuyer(msg.sender) == true,
            "place an order before you can remove it"
        );
        require(copy.addressOf == msg.sender, "only buyer can remove order");
        //withdraw Buyer UserHoldings to back to buyer safed in userHolding[msg.sender]
        for (uint256 i = _index; i < buyList.length - 1; i++) {
            buyList[i] = buyList[i + 1];
        }
        buyList.pop();
    }

    function internalRemoveBuyOder(uint256 _index) internal {
        require(_index < buyList.length, "index to high");
        for (uint256 i = _index; i < buyList.length - 1; i++) {
            buyList[i] = buyList[i + 1];
        }
        buyList.pop();
    }

    function getBuyOrder(uint256 _index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        require(buyList.length > 0, "No Buy Orders in this Orderbook");
        require(
            _index <= buyList.length - 1,
            "No entry in the buy side of the orderbook, index too high"
        );
        Order storage i = buyList[_index];
        require(i.addressOf != address(0), "no such order"); // not exists
        return (i.id, i.limitPrice, i.amount, i.entryTime, i.addressOf);
    }

    //Active Streams
    function addPartner(ActiveStreams memory _tradedWith) internal {
        tradePartners[msg.sender].push(_tradedWith);
    }

    function addPartnerToSeller(ActiveStreams memory _tradedWith) internal {
        tradePartners[msg.sender].push(_tradedWith);
    }

    function addPartnerToSellerNewBuy(ActiveStreams memory _tradedWith)
        internal
    {
        address seller = _tradedWith.streamingTo;
        _tradedWith.streamingTo = msg.sender;
        tradePartners[seller].push(_tradedWith);
    }

    function getPartner(uint256 _index)
        public
        view
        returns (ActiveStreams memory)
    {
        return tradePartners[msg.sender][_index];
    }

    function checkPartnerNewSell(address _check)
        public
        view
        returns (bool traded)
    {
        if (tradePartners[msg.sender].length == 0) {
            return false;
        }
        for (uint256 i = 0; i <= tradePartners[msg.sender].length - 1; i++) {
            if (_check == tradePartners[msg.sender][i].streamingTo) {
                return true;
            }
        }
        return false;
    }

    function checkPartnerNewBuy(address _check)
        public
        view
        returns (bool traded)
    {
        if (tradePartners[_check].length == 0) {
            return false;
        }
        for (uint256 i = 0; i <= tradePartners[_check].length - 1; i++) {
            if (msg.sender == tradePartners[_check][i].streamingTo) {
                return true;
            }
        }
        return false;
    }

    function removePartner(uint256 _index) public {
        uint256 length = tradePartners[msg.sender].length;
        if (length == 0) {} else if (length == 1) {
            tradePartners[msg.sender].pop();
        } else {
            tradePartners[msg.sender][_index] = tradePartners[msg.sender][
                length - 1
            ];
            tradePartners[msg.sender].pop();
        }
    }

    function getPartnerLength() public view returns (uint256) {
        return tradePartners[msg.sender].length;
    }

    //UserToHolding
    function getBalanceBuyer() public view returns (uint256) {
        return buyerHolding[msg.sender];
    }

    function getBalanceSeller() public view returns (uint256) {
        return sellerHolding[msg.sender];
    }

    function withdrawEarningSeller() public {
        require(
            tradePartners[msg.sender].length > 0,
            "No current or future holdings on this smart contract"
        );
        uint256 currentTime = block.timestamp;
        uint256 totalAmount = 0;
        uint256 remainingTime;
        uint256 remaingIntervalls;
        uint256 timeToPayout;
        uint256 payoutIntervals;
        for (uint256 i = 0; i <= tradePartners[msg.sender].length - 1; i++) {
            uint256 endStream = tradePartners[msg.sender][i].endDataOfStream;
            uint256 startStream = tradePartners[msg.sender][i]
                .startDataOfStream;
            uint256 agreedPrice = tradePartners[msg.sender][i].agreedPrice;
            remainingTime = endStream - startStream;
            remaingIntervalls = remainingTime / streamingInterval;
            if (currentTime >= endStream) {
                //hier liegt der fehler
                totalAmount = remaingIntervalls * agreedPrice;
                buyerHolding[
                    tradePartners[msg.sender][i].streamingTo
                ] -= totalAmount;
                sellerHolding[msg.sender] += totalAmount;
                removePartner(i);
                if (tradePartners[msg.sender].length == 0) {
                    break;
                }
            } else {
                timeToPayout = currentTime - startStream;
                if (timeToPayout < streamingInterval) {} else {
                    uint256 modulo = timeToPayout % streamingInterval;
                    timeToPayout = timeToPayout - modulo;
                    tradePartners[msg.sender][i]
                        .startDataOfStream += timeToPayout;
                    payoutIntervals = timeToPayout / streamingInterval;
                    totalAmount = payoutIntervals * agreedPrice;
                    buyerHolding[
                        tradePartners[msg.sender][i].streamingTo
                    ] -= totalAmount;
                    sellerHolding[msg.sender] += totalAmount;
                    if (
                        tradePartners[msg.sender][i].startDataOfStream >=
                        endStream
                    ) {
                        removePartner(i);
                        if (tradePartners[msg.sender].length == 0) {
                            break;
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InterfaceERC7772 {
    event TokensReceived(
        address sender,
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokensToSend(
        address sender,
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC1820Implementer.sol)

pragma solidity ^0.8.0;

import "IERC1820Implementer.sol";

/**
 * @dev Implementation of the {IERC1820Implementer} interface.
 *
 * Contracts may inherit from this and call {_registerInterfaceForAddress} to
 * declare their willingness to be implementers.
 * {IERC1820Registry-setInterfaceImplementer} should then be called for the
 * registration to be complete.
 */
contract ERC1820Implementer is IERC1820Implementer {
    bytes32 private constant _ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");

    mapping(bytes32 => mapping(address => bool)) private _supportedInterfaces;

    /**
     * @dev See {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _supportedInterfaces[interfaceHash][account] ? _ERC1820_ACCEPT_MAGIC : bytes32(0x00);
    }

    /**
     * @dev Declares the contract as willing to be an implementer of
     * `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer} and
     * {IERC1820Registry-interfaceHash}.
     */
    function _registerInterfaceForAddress(bytes32 interfaceHash, address account) internal virtual {
        _supportedInterfaces[interfaceHash][account] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}