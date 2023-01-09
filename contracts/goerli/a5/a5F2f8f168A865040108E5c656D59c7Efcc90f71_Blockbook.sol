pragma solidity ^0.8.17;

contract Blockbook{
    address payable public address1;
    address payable public address2;
    address payable public address3;

    constructor(address payable _address1, address payable _address2, address payable _address3) public {
        address1 = _address1;
        address2 = _address2;
        address3 = _address3;
    }

    function splitPayment(uint amount) public payable {
        address1.transfer(amount * 80/100);
        address2.transfer(amount/10);
        address3.transfer(amount/10);
    }

    receive() external payable {
        splitPayment(msg.value);
    }

    function updateAddresses(address payable _address1, address payable _address2, address payable _address3) public {
        address1 = _address1;
        address2 = _address2;
        address3 = _address3;
}
}