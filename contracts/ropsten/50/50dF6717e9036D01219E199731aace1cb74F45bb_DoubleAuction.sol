/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.4.19;

contract DoubleAuction {

    address public market;
    mapping(int => int) buyerBids;
    int[] _buyerPrices;
    mapping(int => int) sellerOffers;
    int[] _sellerPrices;
    Clearing public clearing;
    CES public ces;
    uint public blockNumberNow;

    
    struct Bid {
        int quantity;
        int price;
    }
    
    struct Clearing {
        int clearingQuantity;
        int clearingPrice;
        int clearingType; // marginal_seller = 1, marginal_buyer = 2, marginal_price = 3, exact = 4, failure = 5, null = 6
    }

    struct CES {
        int cesQuantity;
        int cesPrice;
    }

    function DoubleAuction() public{
        market = msg.sender;
        blockNumberNow = block.number;
        clearing.clearingPrice = 0;
        clearing.clearingQuantity = 0;
        clearing.clearingType = 0;
    }

        
    function addBuyerBid(int _quantity, int _price) public{
        if(buyerBids[_price]==0){
        _buyerPrices.push(_price);
        buyerBids[_price] = _quantity;
        } else {
        buyerBids[_price] = buyerBids[_price] + _quantity;
        }
    }

    function addSellerOffer(int _quantity, int _price) public{
        if(sellerOffers[_price]==0){
        _sellerPrices.push(_price);
        sellerOffers[_price] = _quantity;
        }else{
            sellerOffers[_price] = sellerOffers[_price] + _quantity;
        }
    }
    
    function getPriceCap() pure private returns(int){
        return 9999;
    }
    
    function getAvg(int a, int b) pure private returns(int){
        return (a + b)/2;
    }
    
    function quickSortDescending(int[] storage arr, int left, int right) internal {
        int i = left;
        int j = right;
        uint pivotIndex = uint(left + (right - left) / 2);
        int pivot = arr[pivotIndex];
        while (i <= j) {
            while (arr[uint(i)] > pivot) i++;
            while (arr[uint(j)] < pivot) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortDescending(arr, left, j);
        if (i < right)
            quickSortDescending(arr, i, right);
    }
    
    function quickSortAscending(int[] storage arr, int left, int right) internal {
        int i = left;
        int j = right;
        uint pivotIndex = uint(left + (right - left) / 2);
        int pivot = arr[pivotIndex];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (arr[uint(j)] > pivot) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortAscending(arr, left, j);
        if (i < right)
            quickSortAscending(arr, i, right);
    }

    function marketClearing() public{
        if(_buyerPrices.length > 340 || _sellerPrices.length > 100){
            deleteMapArrays();
        }
        else{
            computeClearing();
        }
    
    }
  
    function computeClearing() private{
        
        bool check = false;
        int a = getPriceCap();
        int b = -getPriceCap();
        int demand_quantity = 0;
        int supply_quantity = 0;
        int buy_quantity = 0;
        int sell_quantity = 0;
        uint i = 0;  
        uint j = 0;
        
        //sort arrays, consumer's bid descending, producer's ascending
        if (_buyerPrices.length != 0){
                quickSortDescending(_buyerPrices, 0, int(_buyerPrices.length - 1));
        }
        if (_sellerPrices.length != 0){
                quickSortAscending(_sellerPrices, 0, int(_sellerPrices.length - 1));
        }
        
        if(_buyerPrices.length > 0 && _sellerPrices.length > 0){
            
            Bid memory buy = Bid({
                quantity: buyerBids[_buyerPrices[i]],
                price: _buyerPrices[i]
            });
            Bid memory sell = Bid({
                quantity: sellerOffers[_sellerPrices[j]],
                price: _sellerPrices[j]
            });
            clearing.clearingType = 6;  
            while(i<_buyerPrices.length && j<_sellerPrices.length && buy.price>=sell.price){
                buy_quantity = demand_quantity + buy.quantity;
                sell_quantity = supply_quantity + sell.quantity;
                if (buy_quantity > sell_quantity){
                    supply_quantity = sell_quantity;
                    clearing.clearingQuantity = sell_quantity;
                    b = buy.price;
                    a = buy.price;
                    ++j;
                    
                    if(j < _sellerPrices.length){
                    sell.price =  _sellerPrices[j];
                    sell.quantity = sellerOffers[_sellerPrices[j]];
                    }
                    check = false;
                    clearing.clearingType = 2;
                }
                else if (buy_quantity < sell_quantity){
                    demand_quantity = buy_quantity;
                    clearing.clearingQuantity = buy_quantity;
                    b = sell.price;
                    a = sell.price;
                    i++;
                    
                    if(i < _buyerPrices.length){
                        buy.price =  _buyerPrices[i];
                        buy.quantity = buyerBids[_buyerPrices[i]];
                    }
                    check = false;
                    clearing.clearingType = 1;
                }
                else{
                    supply_quantity = buy_quantity;
                    demand_quantity = buy_quantity;
                    clearing.clearingQuantity = buy_quantity;
                    a = buy.price;
                    b = sell.price;
                    i++;
                    j++;
                    
                    if(i < _buyerPrices.length){
                        buy.price =  _buyerPrices[i];
                        buy.quantity = buyerBids[_buyerPrices[i]];
                    }
                    
                    if(j < _sellerPrices.length){
                    sell.price =  _sellerPrices[j];
                    sell.quantity = sellerOffers[_sellerPrices[j]];
                    }
                    
                    check = true;
                }
                
            }
            if(a == b){
                clearing.clearingPrice = a;
            }
            if(check){ /* there was price agreement or quantity disagreement */
                clearing.clearingPrice = a;
                if(supply_quantity == demand_quantity){
                    if(i == _buyerPrices.length || j ==  _sellerPrices.length){
                        if(i == _buyerPrices.length && j == _sellerPrices.length){ // both sides exhausted at same quantity
                            if(a == b){
                                clearing.clearingType = 4;
                            } else {
                                clearing.clearingType = 3;
                            }
                        } else if (i == _buyerPrices.length && b == sell.price){ // exhausted buyers, sellers unsatisfied at same price
                            clearing.clearingType = 1;
                        } else if (j == _sellerPrices.length && a == buy.price){ // exhausted sellers, buyers unsatisfied at same price
                            clearing.clearingType = 2;
                        } else { // both sides satisfied at price, but one side exhausted
                            if(a == b){
                                clearing.clearingType = 4;
                            } else {
                                clearing.clearingType = 3;
                            }
                        }
                    }else {
                        if(a != buy.price && b != sell.price && a == b){
                            clearing.clearingType = 4; // price changed in both directions
                        } else if (a == buy.price && b != sell.price){
                            // sell price increased ~ marginal buyer since all sellers satisfied
                            clearing.clearingType = 2;
                        } else if (a != buy.price && b == sell.price){
                            // buy price increased ~ marginal seller since all buyers satisfied
                            clearing.clearingType = 1;
                            clearing.clearingPrice = b; // use seller's price, not buyer's price
                        } else if(a == buy.price && b == sell.price){
                            // possible when a == b, q_buy == q_sell, and either the buyers or sellers are exhausted
                            if(i == _buyerPrices.length && j == _sellerPrices.length){
                                clearing.clearingType = 4;
                            } else if (i ==  _buyerPrices.length){ // exhausted buyers
                                clearing.clearingType = 1;
                            } else if (j == _sellerPrices.length){ // exhausted sellers
                                clearing.clearingType = 2;
                            }
                        } else {
                            clearing.clearingType = 3; // marginal price
                        }
                    }
                }
                if(clearing.clearingType == 3){
                    // needs to be just off such that it does not trigger any other bids
                //clearing.clearingPrice = getClearingPriceType3(i, j, a, b, buy, sell);
                    if(a == getPriceCap() && b != -getPriceCap()){
                        if(buy.price > b){
                            clearing.clearingPrice =  buy.price + 1;
                        }else{
                            clearing.clearingPrice =  b;
                        }
                    } else if(a != getPriceCap() && b == -getPriceCap()){
                        if(sell.price < a){
                            clearing.clearingPrice =  sell.price - 1;
                        }else{
                            clearing.clearingPrice =  a;
                        }
                    } else if(a == getPriceCap() && b == -getPriceCap()){
                        if(i == _buyerPrices.length && j == _sellerPrices.length){
                            clearing.clearingPrice =  0; // no additional bids on either side
                        } else if(i == _buyerPrices.length){ // buyers left
                            clearing.clearingPrice =  buy.price + 1;
                        } else if(j == _buyerPrices.length){ // sellers left
                            clearing.clearingPrice =  sell.price - 1;
                        } else { // additional bids on both sides, just no clearing
                            if(i==_buyerPrices.length){
                                if(j==_sellerPrices.length){
                                    clearing.clearingPrice =  getAvg(a,  b);
                                }else{
                                    clearing.clearingPrice =  getAvg(a,  sell.price);
                                }
                            }else{
                                if(j==_sellerPrices.length){
                                    clearing.clearingPrice =  getAvg(buy.price, b);
                                }else{
                                    clearing.clearingPrice =  getAvg(buy.price, sell.price);
                                }
                            }
                        }
                    } else {
                        if(i != _buyerPrices.length && buy.price == a){
                            clearing.clearingPrice =  a;
                        } else if (j != _sellerPrices.length && sell.price == b){
                            clearing.clearingPrice =  b;
                        } else if(i != _buyerPrices.length && getAvg(a,  b) < buy.price){
                            if(i==_buyerPrices.length){
                                clearing.clearingPrice =  a + 1;
                            }else{
                                clearing.clearingPrice =  buy.price + 1;
                            }
                        } else if(j != _sellerPrices.length && getAvg(a,  b) > sell.price){
                            if(j==_sellerPrices.length){
                                clearing.clearingPrice =  b - 1;
                            }else{
                                clearing.clearingPrice =  sell.price - 1;
                            }
                        } else {
                            clearing.clearingPrice = getAvg(a,  b);
                        }
                    }
                }
            }
            /* check for zero demand but non-zero first unit sell price */
            if (clearing.clearingQuantity==0)
            {
                clearing.clearingType = 6;
                clearing.clearingPrice = getClearingPriceDemandZero();
                
            }else if(clearing.clearingQuantity < buyerBids[getPriceCap()]){
                clearing.clearingType = 5;
                clearing.clearingPrice = getPriceCap();
            }else if(clearing.clearingQuantity < sellerOffers[-getPriceCap()]){
                clearing. clearingType = 5;
                clearing.clearingPrice = -getPriceCap();
            }else if(clearing.clearingQuantity == buyerBids[getPriceCap()] && clearing.clearingQuantity == sellerOffers[-getPriceCap()]){
                clearing.clearingType = 3;
                clearing.clearingPrice = 0;
            }
            
        }else{
            clearing.clearingPrice =  getClearingPriceOneLengthZero();
            clearing.clearingQuantity = 0;
            clearing.clearingType = 6;
        }

        getCES();
        deleteMapArrays();
    }
  
    function getCES() private {
        int sum_price = 0;
        int sum_buyer_quantity = 0;
        int sum_seller_quantity = 0;
        int sum_bids = 0;

        for (uint _idx=0; _idx< _buyerPrices.length; _idx++){
            sum_price += _buyerPrices[_idx];
            sum_buyer_quantity += buyerBids[_buyerPrices[_idx]];
        }
        sum_bids += int(_buyerPrices.length);
        for (_idx=0; _idx< _sellerPrices.length; _idx++){
            sum_price += _sellerPrices[_idx];
            sum_seller_quantity += sellerOffers[_sellerPrices[_idx]];
        }
        sum_bids += int(_sellerPrices.length);
        if(sum_buyer_quantity == sum_seller_quantity){
            ces.cesQuantity = 0;
        } else {
            if( sum_buyer_quantity > sum_seller_quantity){
                ces.cesQuantity = sum_buyer_quantity - sum_seller_quantity;
                clearing.clearingQuantity = sum_buyer_quantity;
                sum_price += 70;
            } else{
                ces.cesQuantity = sum_seller_quantity - sum_buyer_quantity;
                clearing.clearingQuantity = sum_seller_quantity;
                sum_price += 50;
            }
            sum_bids += 1;
        }
        ces.cesPrice = sum_price / sum_bids;
        
    }
    function getClearingPriceOneLengthZero() view private returns(int){
        if( _sellerPrices.length > 0 && _buyerPrices.length == 0){
            return  _sellerPrices[0]-1;
        }else if( _sellerPrices.length == 0 && _buyerPrices.length > 0){
            return _buyerPrices[0]+1;
        }else if( _sellerPrices.length > 0 && _buyerPrices.length > 0){
            return _sellerPrices[0] + (_buyerPrices[0] - _sellerPrices[0]) / 2;
        }else if( _sellerPrices.length == 0 && _buyerPrices.length == 0){
            return 0;
        }
    }
    
    function getClearingPriceDemandZero() view private returns(int){
        if(_sellerPrices.length > 0 && _buyerPrices.length == 0){
            return _sellerPrices[0]-1;
        } else if(_sellerPrices.length == 0 && _buyerPrices.length > 0){
            return _buyerPrices[0]+1;
        } else {
            if(_sellerPrices[0] == getPriceCap()){
                return _buyerPrices[0]+1;
            } else if (_buyerPrices[0] == -getPriceCap()){
                return _sellerPrices[0]-1;
            } else {
                return _sellerPrices[0] + (_buyerPrices[0] - _sellerPrices[0]) / 2;
            }
        }
    }
    
    
    function getClearingPrice() constant public returns(int){
        return(clearing.clearingPrice);
    }
    
    function getClearingQuantity() constant public returns(int){
        return(clearing.clearingQuantity);
    }
    
    function getCESPrice() constant public returns(int){
        return(ces.cesPrice);
    }
    
    function getCESQuantity() constant public returns(int){
        return(ces.cesQuantity);
    }

    function getClearingType() constant public returns(int){
        return(clearing.clearingType);
    }
    
    function getSellerOffersLength() constant public returns(uint){
        return(_sellerPrices.length);
    }

    function getBuyerBidsLength() constant public returns(uint){
        return(_buyerPrices.length);
    }

    function deleteMapArrays() public{
        for (uint cleanConsumptionIndex = 0; cleanConsumptionIndex < _buyerPrices.length; cleanConsumptionIndex++){
        int consPrice = _buyerPrices[cleanConsumptionIndex];
        buyerBids[consPrice] = 0;
        }

        for (uint cleanGenerationIndex = 0; cleanGenerationIndex < _sellerPrices.length; cleanGenerationIndex++){
        int genPrice = _sellerPrices[cleanGenerationIndex];
        sellerOffers[genPrice] = 0;
        }

        delete _buyerPrices;
        delete _sellerPrices;

        _buyerPrices.length = 0;
        _sellerPrices.length = 0;
    }
}