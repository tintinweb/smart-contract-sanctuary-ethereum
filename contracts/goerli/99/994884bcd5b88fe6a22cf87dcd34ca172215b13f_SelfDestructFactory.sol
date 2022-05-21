/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity 0.8.13;

contract SelfDestructFactory {

    function forceSend(address _target) external payable {
        SelfDectInConst newCont = (new SelfDectInConst){value: msg.value}(_target);
    }

}


contract SelfDectInConst {
    constructor(address _payee) payable {
        selfdestruct(payable(_payee));
    }
}