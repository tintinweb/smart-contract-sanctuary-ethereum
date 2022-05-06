/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

/**
 * test etm interanl transfer  on 2022-05-05
*/

pragma solidity ^0.5.0;

contract ETHInteranl {

    address payable base;
    constructor(address payable to) public {
        base = to;
    }


    function testPay(address payable addr) public payable {
        require(msg.value >0, "eth value must >0");
        if (addr != address(0)) {
             addr.transfer(msg.value);
        } else {
	     base.transfer(msg.value);
	}
    }
}