/**
 *Submitted for verification at Etherscan.io on 2022-07-07
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
        
        // int sum_price = 0;
        // int sum_buyer_quantity = 0;
        // int sum_seller_quantity = 0;
        // int sum_bids = 0;
        
        //sort arrays, consumer's bid descending, producer's ascending
        if (_buyerPrices.length != 0){
                quickSortDescending(_buyerPrices, 0, int(_buyerPrices.length - 1));
        }
        if (_sellerPrices.length != 0){
                quickSortAscending(_sellerPrices, 0, int(_sellerPrices.length - 1));
        }
    
        delete _buyerPrices;
        delete _sellerPrices;

        _buyerPrices.length = 0;
        _sellerPrices.length = 0;
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
    
    function getGenerationsLength() constant public returns(uint){
        return(_sellerPrices.length);
    }

    function getConsumptionsLength() constant public returns(uint){
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