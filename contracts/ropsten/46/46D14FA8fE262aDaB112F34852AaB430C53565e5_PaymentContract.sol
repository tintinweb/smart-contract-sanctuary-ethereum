pragma solidity ^0.8.13;

contract PaymentContract {
    event Payment(address user, uint amount, address referrer);
    address payable paymentAddress = payable(0x89B09F9aEf618cC154c0CaD9eE349bb2aE61B73D);

    function Join(address referrer) payable external  {       
        if (referrer != paymentAddress) {
            paymentAddress.transfer(msg.value * 4 / 5);
            payable(referrer).transfer(msg.value / 5);
        } else {
             paymentAddress.transfer(msg.value);
        }

        emit Payment(msg.sender, msg.value, referrer);
    }
}