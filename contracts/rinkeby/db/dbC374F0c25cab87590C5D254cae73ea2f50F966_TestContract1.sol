pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x659b8ff1AF26000b4be7a0b1fD84c256BA16BAd3";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}