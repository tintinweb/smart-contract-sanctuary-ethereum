// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./PaymentContractInterface.sol";

contract StoreContract {
    PaymentContractInterface private _paymentContract;

    constructor(){

    }

    function placeOrder(uint price) public {
        _paymentContract.MakePayment(price);
    }

    function setPaymentContract(address _paymentContractAddress) public{
        require(_paymentContractAddress != address(0), "You can not enter zero address");
        _paymentContract = PaymentContractInterface(_paymentContractAddress);
    } 
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract KudosInterfaceId {
    bytes4 internal constant PAYMENT_INTERFACE_ID = type(PaymentContractInterface).interfaceId;
}

interface PaymentContractInterface {
    function MakePayment(uint valueToPay) external;
}