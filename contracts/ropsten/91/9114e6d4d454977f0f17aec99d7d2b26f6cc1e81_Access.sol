/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;




contract Access {

   // address public externalContractAddress;

    Sum sum;



    function setExternalAddress(address otherAddress) public {

       // externalContractAddress = otherAddress;

        sum = Sum(otherAddress);

    }



    function setNum1(int _num1) external {

        sum.setNum1(_num1);

    }



    function setNum2(int _num2) external {

        sum.setNum2(_num2);

    }

   

    function callSum() external view returns (int) {

        return sum.sum();

    }

}



abstract contract Sum {

    function sum() virtual public view returns (int);

    function setNum1(int _num1) public virtual;

    function setNum2(int _num2) public virtual;

}