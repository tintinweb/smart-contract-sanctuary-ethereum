/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.5.1;

contract fuck {
    enum State { Sleeping, Ready, Active }
    State public state;

    constructor() public {
        state = State.Sleeping;
    }
    
    function activate() public { //激活
        state = State.Active;
    }

    function isactive() public view returns(bool){
        return state == State.Active;
    }
}