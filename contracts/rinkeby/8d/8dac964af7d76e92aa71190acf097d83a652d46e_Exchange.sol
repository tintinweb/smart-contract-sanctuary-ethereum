/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
 
interface IERC20 {
    function transferFrom(address _from , address _to , uint256 _value)external returns(bool success);
    function transfer(address _to,uint256 _value)external returns(bool success);
}


contract Exchange {

    address public feesAccount = 0x32E811EB6639eA25fE932D788363418eb5D0078C;//adress for fees (rinkeby)
    uint256 public feesRate = 10;
    address public constant ETH = 0x3EC9E2D682155AeE352B005F0432C96CFD464D08;//Address wher user gonna send ETH on the DEX(rinkeby adress)
    uint idIndex;

    //MAPPINGS
    //mapping of the address of holders who deposit tokens on the DEX
    mapping(address => mapping(address => uint256)) public tokens;
    //mapping for orders;
    mapping(uint256 => order) public Orders;
    //mapping for cancelled orders
    mapping(uint256 => bool) public CancelledOrders;
    //mapping completed orders
    mapping (uint256 => bool) public Completed;
    


    //EVENTS
    event deposit(address indexed token , address indexed user , uint256 amount , uint256 balance);
    event withdraw(address indexed token , address indexed user , uint256 amount , uint256 balance);
    event orderEmitted(uint256 id,address user,address tokenA,address tokenB,uint256 amountA, uint256 amountB,uint256 timestamp);
    event cancellationEmitted(uint256 id,address user,address tokenA,address tokenB,uint256 amountA, uint256 amountB,uint256 timestamp);
    event tradeEvent(uint256 id,address user,address tokenA,address tokenB,uint256 amountA, uint256 amountB,uint256 timestamp);
    //STRUCTS
    //struct for orders
    struct order {
        uint256 id;
        address user;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 timestamp;
    }
    //========================FALLBACK FUNCTION================================================================
    receive() external payable {
        revert("Not now");
    }
    //========================DEPOSIT & WITHDRAW FUNCTIONS================================================================
    //function to deposit ETH on the dex
    function depositETH() external payable {
        tokens[ETH][msg.sender]+=msg.value;
        emit deposit(ETH , msg.sender , msg.value,tokens[ETH][msg.sender]);
    }
    
    //function to deposit tokens on the DEX
    function depositTokens(address _tokenAddress , uint256 _amount) external payable {
        require(_tokenAddress!=ETH , "This is not the right address");
        require(IERC20(_tokenAddress).transferFrom(msg.sender , address(this), _amount));
        tokens[_tokenAddress][msg.sender]+=_amount;

        emit deposit(_tokenAddress , msg.sender , _amount ,tokens[_tokenAddress][msg.sender] );
    }

    //function to withdraw ETH
    function withdrawETH(uint256 _amount) external  {
        require(tokens[ETH][msg.sender]>= _amount , "Not enough ETH in your balance");
        tokens[ETH][msg.sender]-=_amount;

        payable(msg.sender).transfer(_amount);
        
        emit withdraw(ETH , msg.sender , _amount , tokens[ETH][msg.sender]);
    }

    //function to withdraw tokens
    function withdrawToken(address _tokenAddress , uint256 _amount)external {
        require(_tokenAddress!=ETH , "This is not the right address");
        require(tokens[_tokenAddress][msg.sender]>=_amount , "not enought tokens to withdraw");
        require(IERC20(_tokenAddress).transfer(msg.sender , _amount));
        tokens[_tokenAddress][msg.sender]-=_amount;
        emit withdraw(_tokenAddress , msg.sender , _amount , tokens[_tokenAddress][msg.sender]);
    }


    //========================CREATE ORDERS FUNCTIONS================================================================
    //function to Create an order
    function createOrders(address _tokenA , uint256 _amountA ,address _tokenB , uint256 _amountB) external {
    idIndex++;
    Orders[idIndex] = order(idIndex , msg.sender , _tokenA , _tokenB , _amountA , _amountB , block.timestamp);
    emit orderEmitted(idIndex , msg.sender , _tokenA , _tokenB , _amountA , _amountB , block.timestamp);
    }

    //function to cancel an Order
    function cancelOrder(uint256 _id) external {
    require(msg.sender == Orders[_id].user , "Not the user who did the order");
    require(_id == Orders[_id].id, "Not the user who did the order");
    CancelledOrders[_id] == true;
    emit cancellationEmitted(Orders[_id].id , Orders[_id].user , Orders[_id].tokenA , Orders[_id].tokenB , Orders[_id].amountA , Orders[_id].amountB ,block.timestamp);
    }

    //function to Trade
    function _trade(uint256 _id ,address _user, address _tokenA , uint256 _amountA ,address _tokenB , uint256 _amountB) internal {
      uint fee =(_amountA*feesRate)/100;

      tokens[_tokenA][msg.sender]-=_amountA + fee;
      tokens[_tokenA][_user]+=_amountA;

      tokens[_tokenA][feesAccount]+=fee;
      
      tokens[_tokenB][msg.sender]+=_amountB;
      tokens[_tokenB][_user]-=_amountB;

      emit tradeEvent(_id , _user , _tokenA , _tokenB , _amountA , _amountB , block.timestamp);
    }

    //function to completed order
    function completedOrder(uint256 _id) external {
      require(_id >0 && _id <= idIndex);
      require(!CancelledOrders[_id] , "Cancelled Order");
      require(!Completed[_id] , "Completed Order");
      _trade(Orders[_id].id , Orders[_id].user , Orders[_id].tokenA, Orders[_id].amountA  , Orders[_id].tokenB ,  Orders[_id].amountB);
      Completed[Orders[_id].id ]= true;
    }
}