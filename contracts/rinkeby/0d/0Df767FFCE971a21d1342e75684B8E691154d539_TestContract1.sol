pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x651C485bd25f1123D5D0a30818A0e4ba7864752a";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}