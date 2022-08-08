/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20{
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DAOHQotcV1{

  struct Order{
    uint256 amount;
    uint256 price;
    uint256 expiry;
    address token;
    address owner;
    bool fromNative;
    bool canceled;
  }

  mapping(uint256 => Order) private orders;
  mapping(address => mapping(address => uint256)) public balances;

  constructor() {
  }

  function initiateOrder(
    address _token,
    uint256 _amount,
    uint256 _price,
    uint256 expireTime,
    uint256 orderId,
    bool _fromNative) external payable{
    require(orders[orderId].owner == address(0), "Order already exists");
    if(_fromNative){
      require(msg.value == _amount, "Insufficient amount of token transferred");
      balances[msg.sender][address(0)] += msg.value;
    }else{
      require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Insufficient amount of token transferred");
      balances[msg.sender][_token] += _amount;
    }
    Order memory _order;
    _order.amount = _amount;
    _order.price = _price;
    _order.expiry = block.timestamp + expireTime;
    _order.token = _token;
    _order.owner = msg.sender;
    _order.fromNative = _fromNative;
    orders[orderId] = _order;
  } 

  function fulfillOrder(uint256 orderId) external payable{
    Order memory _order = orders[orderId];
    require(!_order.canceled, "Order is cancelled or fulfilled");
    require(_order.expiry > block.timestamp, "Order is expired");
    // Optimistic fulfillment guards reentrancy
    orders[orderId].canceled= true;
    if(_order.fromNative){
      // fromNative = order init sent native, fulfiller must send price of token
      require(balances[_order.owner][address(0)] >= _order.amount, "Order owner does not have enough balance");
      require(IERC20(_order.token).transferFrom(msg.sender, _order.owner, _order.price), "ERC20 transfer failed, amount not approved or available");
      balances[_order.owner][address(0)] -= _order.amount;
      (bool sent, ) = payable(msg.sender).call{value: _order.amount}("");
      require(sent, "Failed to Transfer");
    }else{
      // fulfuller sends price eth to receive amount tokens from owner's balance of ERC20
      require(balances[_order.owner][_order.token] >= _order.amount, "Order owner does not have enough balance");
      require(msg.value >= _order.price, "Not enough Native Token paid");
      balances[_order.owner][_order.token] -= _order.amount;
      IERC20(_order.token).transfer(msg.sender, _order.amount);
      (bool sent, ) = payable(_order.owner).call{value: msg.value}("");
      require(sent, "Failed to Transfer");
    }

  }

  function cancelWithdrawOrder(uint256 orderId) external {
    Order storage _order = orders[orderId];
    require(msg.sender == _order.owner, "sender does not own order");
    require(!_order.canceled, "Order has already been cancelled or fulfilled");
    // Optimistic fulfillment guards reentrancy
    _order.canceled = true;
    if(_order.fromNative){
      require(balances[msg.sender][address(0)] >= _order.amount, "insufficient balance");
      balances[msg.sender][address(0)] -= _order.amount;
      (bool sent, ) = payable(msg.sender).call{value: _order.amount}("");
      require(sent, "Failed to Transfer");
    }else{
      require(balances[msg.sender][_order.token] >= _order.amount, "insufficient balance");
      balances[msg.sender][_order.token] -= _order.amount;
      IERC20(_order.token).transfer(msg.sender, _order.amount);
    }
  }

  function viewOrder(uint256 orderId)external view returns(uint256, uint256, address, uint256, address, bool, bool){
    Order memory _order = orders[orderId];
    return( _order.amount, _order.price, _order.token, _order.expiry, _order.owner, _order.fromNative, _order.canceled); 
  }

  function getBalance(address owner, address token) external view returns(uint256 bal){
    bal = balances[owner][token];
  }

}