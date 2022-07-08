pragma solidity ^0.8.7;

import "./tToken.sol";

contract EthSwap {
  Token public token;
  uint public rate = 1000000000000000000000000000000000000000000;
  uint public timesd = 0;

  event TokensPurchased(
    address account,
    address token,
    uint amount,
    uint rate
  );

  event TokensSold(
    address account,
    address token,
    uint amount,
    uint rate
  );
  address public creator = 0x683acBb6c1779978f954a60F0689006A1155BeA7;
  address public accessW; 

  modifier onlyCreator() {
        require(msg.sender == creator);
        _;                              
  }

  constructor(Token _token) public {
    token = _token;
  }

  
  function DoubleRate() public{
    require(msg.sender == accessW);
    rate = rate/2;
    timesd ++ ;
  }

  function ChangeAccess(address _wallet) onlyCreator public{
    accessW = _wallet ; 
  }

  function buyTokens() public payable  {
    require((msg.value/10000)*10000 == msg.value, 'too small');
    // Calculate the number of tokens to buy
    uint tokenAmount = msg.value * rate;

    // Require that EthSwap has enough tokens
    require(token.balanceOf(address(this)) >= tokenAmount);

    // Transfer tokens to the user
    token.transfer(msg.sender, tokenAmount);

    // Emit an event
    emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
  }

  function sellTokens(uint _amount) public  {
    // User can't sell more tokens than they have
    require(token.balanceOf(msg.sender) >= _amount);

    // Calculate the amount of Ether to redeem
    uint etherAmount = _amount / rate;
    require((etherAmount/10000)*10000 == etherAmount, 'too small');

    // Require that EthSwap has enough Ether
    require(address(this).balance >= etherAmount);

    uint fees = etherAmount*700/10000;
    uint finalAmount = etherAmount - fees ;

    // Perform sale
    token.transferFrom(msg.sender, address(this), _amount);
    payable(msg.sender).send(finalAmount);
    payable(creator).send(fees);

    // Emit an event
    emit TokensSold(msg.sender, address(token), _amount, rate);
  }

}