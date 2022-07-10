// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OrderBookSensor {
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
        require(
            checkBuyer(msg.sender) == false,
            "remove old order before you submit a new one"
        ); //network members are only allowed to have one active Order
        require(_amount > 0, "amount must be bigger than 0"); //network members are only allowed to have one active Order
        //REQUIRE ENOUGH TOKENS FOR THIS ORDER _limitPrice*_amount
        buyerHolding[msg.sender] =
            _limitPrice *
            _amount *
            (streamingDuration / streamingInterval); //deposit tokens on smart contract
        Order memory newOrder;
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
                buyerHolding[msg.sender] -= (buyList[i].limitPrice *
                    buyList[i].amount);
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
        if (tradePartners[msg.sender].length == 1) {
            tradePartners[msg.sender].pop();
        } else if (tradePartners[msg.sender].length == 0) {} else {
            tradePartners[msg.sender][_index] = tradePartners[msg.sender][
                tradePartners[msg.sender].length - 1
            ];
            tradePartners[msg.sender].pop();
        }
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
        //uint thisAmount;
        for (uint256 i = 0; i <= tradePartners[msg.sender].length - 1; i++) {
            remainingTime =
                tradePartners[msg.sender][i].endDataOfStream -
                tradePartners[msg.sender][i].startDataOfStream;
            remaingIntervalls = remainingTime / streamingInterval;
            if (currentTime >= tradePartners[msg.sender][i].endDataOfStream) {
                //hier liegt der fehler
                totalAmount =
                    remaingIntervalls *
                    tradePartners[msg.sender][i].agreedPrice;
                buyerHolding[
                    tradePartners[msg.sender][i].streamingTo
                ] -= totalAmount;
                sellerHolding[msg.sender] += totalAmount;
                removePartner(i);
                if (tradePartners[msg.sender].length == 0) {
                    break;
                }
            } else {
                timeToPayout =
                    currentTime -
                    tradePartners[msg.sender][i].startDataOfStream;
                if (timeToPayout < streamingInterval) {} else {
                    uint256 modulo = timeToPayout % streamingInterval;
                    timeToPayout = timeToPayout - modulo;
                    tradePartners[msg.sender][i].startDataOfStream =
                        tradePartners[msg.sender][i].startDataOfStream +
                        timeToPayout;
                    payoutIntervals = timeToPayout / streamingInterval;
                    totalAmount =
                        payoutIntervals *
                        tradePartners[msg.sender][i].agreedPrice;
                    buyerHolding[
                        tradePartners[msg.sender][i].streamingTo
                    ] -= totalAmount;
                    sellerHolding[msg.sender] += totalAmount;
                    if (
                        tradePartners[msg.sender][i].startDataOfStream >=
                        tradePartners[msg.sender][i].endDataOfStream
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