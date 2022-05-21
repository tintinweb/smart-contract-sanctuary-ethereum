/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity 0.8.13;

contract Forward {
    address alice = 0x5f635323aBdd0deFB216d1b1867d865271e3EF88;
    address bob = 0xA842e822AE53984FcAcc570C80c243Cd2F6Ae4F6;


    receive() external payable {
        payable(alice).transfer(msg.value/2);
        payable(bob).transfer(msg.value/2);
    }
}

contract checkBalance {
    function getBalance(address _addCheck) external view returns (uint) {
        return _addCheck.balance;
    }
}


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