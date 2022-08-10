/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

pragma solidity ^0.4.18;

contract Marketing {
    struct BuyOrder {
        address sellerToken;
        uint256 cost;
        uint256 amount;
        address token;
    }

    struct SellOrder {
        address token;
        uint256 cost;
        uint256 amount;
    }

    struct MarketingRecord {
        SellOrder sellOrder;

        // buyerToken => BuyOrder
        mapping (address => BuyOrder) buyOrders;
    }

    // sellerToken => Sell
    mapping (address => MarketingRecord) private marketingPlace;

    function listToken (address _token, uint256 _cost, uint256 _amount) public {

        SellOrder memory _sellOrder = SellOrder({
            token: _token,
            cost: _cost,
            amount: _amount
        });
        marketingPlace[_token].sellOrder = _sellOrder;
    }

    function buyToken (address _sellerToken, uint256 _cost, uint256 _amount, address _token) public {
      
      BuyOrder memory _buyOrder = BuyOrder({
        sellerToken: _sellerToken,
        cost: _cost,
        amount: _amount,
        token: _token
      });
      marketingPlace[_sellerToken].buyOrders[_token] = _buyOrder;
    }

    function getList(address sellerToken) public view returns (uint256 sellerTokenAmount) {
        return (marketingPlace[sellerToken].sellOrder.amount);
    }
}

// listtoken