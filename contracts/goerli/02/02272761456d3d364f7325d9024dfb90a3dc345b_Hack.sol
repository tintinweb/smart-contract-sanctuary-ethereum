/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

pragma solidity ^0.8.0;


contract Hack {

    address public  _to;

    constructor(address to) {

        _to = to;
    }





    receive() external  payable {

    }

    fallback () external payable {
        payable(_to).transfer(address(this).balance);

    }
 


}