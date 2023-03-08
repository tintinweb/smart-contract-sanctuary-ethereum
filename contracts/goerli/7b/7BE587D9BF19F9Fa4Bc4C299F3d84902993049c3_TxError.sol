/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

pragma solidity 0.8.0;

contract TxError {
    uint public value;

    function setValue(uint _value) public {
        value = _value;
    }

    function sendValue(address payable recipient) public {
        require(value <= address(this).balance, "Insufficient balance.");
        recipient.transfer(value);
        // The following line will never be executed if the transaction to transfer fails
        value = 0;
    }
}