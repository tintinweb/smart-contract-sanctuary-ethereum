// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./PaymentContractInterface.sol";


contract PaymentContract{
    event PaymentMade(uint valueToPay);
    constructor(){

    }

    function DontMakePayment(uint valueToPay) public {
        //Do some logic
        emit PaymentMade(valueToPay);
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