// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract PrimeContract {
    uint public val;
    constructor(uint a) payable {
        val = a;
    }
}

contract SmallContract {
    PrimeContract d = new PrimeContract(4); // will be executed as part of C's constructor

    function createD(uint arg) public {
        PrimeContract newD = new PrimeContract(arg);
        newD.val();
    }

    function createAndEndowD(uint arg, uint amount) public payable {
        // Send ether along with the creation
        PrimeContract newD = new PrimeContract{value: amount}(arg);
        newD.val();
    }
}