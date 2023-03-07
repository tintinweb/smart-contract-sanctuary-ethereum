/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
     constructor()  {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner,"{code:501,msg:'No Right'}");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint32);
}

contract Otc is Ownable{
	using SafeMath for uint;

	IERC20 public paymentToken; //订单支付的token
	IERC20 public arbiterToken; //监管凭证所需token
	uint32 public buyerFeePercentOf1000; //买家手续费规则千分比 >=0  <=1000
	uint32 public sellerFeePercentOf1000;//卖家手续费规则千分比 >=0  <=1000
	uint32 public arbiterCommissionPercentOf1000;//监管人所能分到的佣金千分比 eg: 等于500时说明和平台一人一半
	address public platformCommissionAddress; //平台接收佣金账户

	mapping(uint => Order) orders; //订单存储
	uint public orderIndex;  //订单总数


	enum OrderStatus {
        Init,
        Succeed,
        Failed
    }

	struct Order {
		uint  orderId;
		string  name;
		uint  tokenPrice;
		address  buyer;
		address  seller;
		// 托管人
		address  arbiter;
		uint  sellerFee;
		uint  buyerFee;
		OrderStatus orderStatus;
		bool buyerPaid;
		bool sellerPaid;
	 }

	event CreateOrder(
		uint _orderId,
		string _name,
		uint _tokenPrice,
		address  _buyer,
		address  _seller,
		address  _arbiter,
		uint  _sellerFee,
		uint  _buyerFee
	 );

	event BuyerPay(
		uint _orderId
	 );

	event SellerPay(
		uint _orderId
	 );

	event OrderSuccess(
		uint _orderId
	 );

	event OrderFail(
		uint _orderId
	 );


	constructor(IERC20 _paymentToken,IERC20 _arbiterToken,uint32  _buyerFeePercentOf1000,uint32  _sellerFeePercentOf1000,uint32 _arbiterCommissionPercentOf1000,address _platformCommissionAddress) {
		paymentToken = _paymentToken;
		arbiterToken = _arbiterToken;
		buyerFeePercentOf1000 = _buyerFeePercentOf1000;
		sellerFeePercentOf1000 = _sellerFeePercentOf1000;
		arbiterCommissionPercentOf1000 = _arbiterCommissionPercentOf1000;
		platformCommissionAddress = _platformCommissionAddress;
		orderIndex = 0;
	}

	function createOrder(string memory _name,uint _tokenPrice,address _buyer,address _seller) public returns(uint  orderId){
		require(arbiterToken.balanceOf(msg.sender) > 0,"{code:501,msg:'No Right'}");
		require(msg.sender != _buyer && msg.sender != _seller && _buyer != _seller,"{code:500,msg:'Param Error'}");
		require(_tokenPrice > 0 && _buyer > 0x0000000000000000000000000000000000000000 && _seller > 0x0000000000000000000000000000000000000000,"{code:500,msg:'Param Error'}");
		orderIndex += 1;
		Order storage order = orders[orderIndex];
		order.orderId = orderIndex;
		order.name = _name;
		order.tokenPrice = _tokenPrice;
		order.buyer = _buyer;
		order.seller = _seller;
		order.arbiter = msg.sender;
		uint _sellerFee = _tokenPrice.mul(sellerFeePercentOf1000).div(1000);
		uint _buyerFee = _tokenPrice.mul(buyerFeePercentOf1000).div(1000);
		order.sellerFee = _sellerFee;
		order.buyerFee = _buyerFee;
		order.orderStatus = OrderStatus.Init;
		order.buyerPaid = false;
		order.sellerPaid = false;
		emit CreateOrder(orderIndex,_name,_tokenPrice,_buyer,_seller,msg.sender,_sellerFee,_buyerFee);
		orderId = orderIndex;
	}

	function getOrder(uint _orderId) public view returns(uint  orderId, string memory name,uint  tokenPrice,address  buyer,address  seller,address  arbiter,uint  sellerFee,uint  buyerFee,OrderStatus orderStatus,bool buyerPaid,bool sellerPaid){
		Order memory order = orders[_orderId];
		require(order.buyer > 0x0000000000000000000000000000000000000000,"{code:500,msg:'Param Error'}");
		orderId = order.orderId;
		name = order.name;
		tokenPrice = order.tokenPrice;
		buyer = order.buyer;
		seller = order.seller;
		arbiter = order.arbiter;
		sellerFee = order.sellerFee;
		buyerFee = order.buyerFee;
		orderStatus = order.orderStatus;
		buyerPaid = order.buyerPaid;
		sellerPaid = order.sellerPaid;
	}

	function buyerPay(uint _orderId) public returns(bool){
		Order memory order = orders[_orderId];
		require(order.buyer == msg.sender,"{code:501,msg:'No Right'}");
		require(order.orderStatus == OrderStatus.Init, "{code:502,msg:'Order Already Succeed Or Failed'}");
		require(order.buyerPaid == false,"{code:503,'Already Paid'}");
		uint amount = order.tokenPrice.add(order.buyerFee);
		require(paymentToken.balanceOf(msg.sender) >= amount,"{code:504,'payment token not enough'}");
		paymentToken.transferFrom(msg.sender,address(this),amount);
		orders[_orderId].buyerPaid = true;
		emit BuyerPay(_orderId);
		return true;
	}

	function sellerPay(uint _orderId) public returns(bool){
		Order memory order = orders[_orderId];
		require(order.seller == msg.sender,"{code:501,msg:'No Right'}");
		require(order.orderStatus == OrderStatus.Init, "{code:502,msg:'Order Already Succeed Or Failed'}");
		require(order.sellerPaid == false,"{code:503,'Already Paid'}");
		uint amount = order.tokenPrice.add(order.sellerFee);
		require(paymentToken.balanceOf(msg.sender) >= amount,"{code:504,'Payment Token Not Enough'}");
		paymentToken.transferFrom(msg.sender,address(this),amount);
		orders[_orderId].sellerPaid = true;
		emit SellerPay(_orderId);
		return true;
	}

	function orderSuccess(uint _orderId) public returns(bool){
		Order memory order = orders[_orderId];
		require(order.arbiter == msg.sender,"{code:501,msg:'No Right'}");
		require(order.orderStatus == OrderStatus.Init, "{code:502,msg:'Order Already Succeed Or Failed'}");
		require(order.buyerPaid == true, "{code:505,msg:'Buyer Has Not Paid'}");
		require(order.sellerPaid == true, "code:506,msg:'Seller Has Not Paid'}");
		paymentToken.transfer(order.seller,order.tokenPrice.mul(2));
		uint totalFee = order.buyerFee.add(order.sellerFee);
		uint arbiterCommission = totalFee.mul(arbiterCommissionPercentOf1000).div(1000);
		if(arbiterCommission > 0){
			paymentToken.transfer(order.arbiter,arbiterCommission);
		}
		uint platformCommission = totalFee - arbiterCommission;
		if(platformCommission > 0){
			paymentToken.transfer(platformCommissionAddress,totalFee.sub(arbiterCommission));
		}
		orders[_orderId].orderStatus = OrderStatus.Succeed;
		emit OrderSuccess(_orderId);
		return true;
	}

	function orderFail(uint _orderId) public returns(bool){
		Order memory order = orders[_orderId];
		require(order.arbiter == msg.sender,"{code:501,msg:'No Right'}");
		require(order.orderStatus == OrderStatus.Init, "{code:502,msg:'Order Already Succeed Or Failed'}");
		if(order.buyerPaid == true){
			paymentToken.transfer(order.buyer,order.tokenPrice.add(order.buyerFee));
		}
		if(order.sellerPaid == true){
			paymentToken.transfer(order.seller,order.tokenPrice.add(order.sellerFee));
		}
		orders[_orderId].orderStatus = OrderStatus.Failed;
		emit OrderFail(_orderId);
		return true;
	}

	function setBuyerFeePercentOf1000(uint32 _buyerFeePercentOf1000) public onlyOwner returns(bool){
		require(_buyerFeePercentOf1000 >=0 && _buyerFeePercentOf1000 <= 1000,"{code:500,msg:'Param Error'}");
		buyerFeePercentOf1000 = _buyerFeePercentOf1000;
		return true;
	}

	function setSellerFeePercentOf1000(uint32 _sellerFeePercentOf1000) public onlyOwner returns(bool){
		require(_sellerFeePercentOf1000 >=0 && _sellerFeePercentOf1000 <= 1000,"{code:500,msg:'Param Error'}");
		sellerFeePercentOf1000 = _sellerFeePercentOf1000;
		return true;
	}

	function setArbiterCommissionPercentOf1000(uint32 _arbiterCommissionPercentOf1000) public onlyOwner returns(bool){
		require(_arbiterCommissionPercentOf1000 >=0 && _arbiterCommissionPercentOf1000 <= 1000,"{code:500,msg:'Param Error'}");
		arbiterCommissionPercentOf1000 = _arbiterCommissionPercentOf1000;
		return true;
	}

	function setPlatformCommissionAddress(address _platformCommissionAddress) public onlyOwner returns(bool){
		require(_platformCommissionAddress > 0x0000000000000000000000000000000000000000,"{code:500,msg:'Param Error'}");
		platformCommissionAddress = _platformCommissionAddress;
		return true;
	}

}