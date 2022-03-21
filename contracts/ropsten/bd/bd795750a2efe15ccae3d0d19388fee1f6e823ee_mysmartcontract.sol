/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.4.24;

contract mysmartcontract {
    enum State { waiting, ready, active }
    State public state;
    
    constructor() public {
        state = State.waiting; 
    } 

    function activate() public {
        state = State.active;
    }

    function isactive() public view returns(bool) {
        return state == State.active ;
    }
}