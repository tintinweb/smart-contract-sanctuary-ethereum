/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.4.24;

contract mysmartcontract {
    enum State { waiting, ready, active }
    State public state;
    
    constructor() public { //僅運行一次的函數
        state = State.waiting; //預設Waiting(0)的狀態
    } 

    function activate999() public {
        state = State.active; //激活按紐 isactive
    }

    function isactive() public view returns(bool) {
        return state == State.active ; //State.waitng == State.active 不相等 故boolean回傳false
    }
}