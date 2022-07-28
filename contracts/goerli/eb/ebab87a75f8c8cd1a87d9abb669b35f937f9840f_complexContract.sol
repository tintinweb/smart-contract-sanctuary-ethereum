/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

pragma solidity >=0.7.0 <0.9.0;

contract simpleContract{
    constructor(){}
}

contract simpleContract2{
    string private msg;
    function getMsg() external view returns(string memory msg_){
        msg_ = msg;
    }

}

contract complexContract{
    address[] public contracts;
    bytes4[] public selectors;
    constructor(){
        simpleContract  cs1 = new simpleContract();
        simpleContract2  cs2 = new simpleContract2();
        contracts.push(address(cs1));
        contracts.push(address(cs2));
        selectors.push(simpleContract2.getMsg.selector);
    }
}