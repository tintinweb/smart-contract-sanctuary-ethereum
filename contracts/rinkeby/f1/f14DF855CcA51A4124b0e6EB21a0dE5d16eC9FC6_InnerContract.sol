pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x9C6576bf2cee450aDB3DB6d9ffb471DbfAE16a8F";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}