pragma solidity >=0.7.3;

contract BatchSender {
  event FooBar(string status);
  event Multisended(uint256 total);
  event SingleSend(address recipient, uint256 balance, uint256 total);

  // Payable constructor can receive Ether
  constructor() payable {}

  receive() external payable {}


  function multisendEther(address[] calldata _contributors, uint256[] calldata _balances) external payable {
      uint256 total = msg.value;
      emit FooBar("call done");
      emit SingleSend(_contributors[0], _balances[0], total);
      require(total >= 0);
      emit FooBar("req1 done");
      uint256 i = 0;
      for (i; i < _contributors.length; i++) {
          require(total >= _balances[i]);
          assert(total - _balances[i] > 0);
          total = total - _balances[i];
          emit SingleSend(_contributors[i], _balances[i], total);
          
          (bool success, ) = _contributors[i].call{value:_balances[i]}("");
          require(success, "Transfer failed.");
      }
      emit Multisended(msg.value);
  }    
}