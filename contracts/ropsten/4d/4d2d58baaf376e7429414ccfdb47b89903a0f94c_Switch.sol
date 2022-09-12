/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity ^0.5.0;


contract Switch{

    bool switch_white = false;

    mapping(address=>int32) lists;


    function switchstatus() public  view returns(bool){
        return switch_white;
    }

    function setswitch(bool _switch) public {
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        switch_white = _switch;
    }

    function setlists(address userid, int32 num) public {
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        lists[userid] = num;
    }

    function getlists(address userid) public view returns(int32) {
        return lists[userid];
    }


    function sub1(address userid) public returns(int32) {
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        lists[userid] = lists[userid] - 1;
        return lists[userid];
    }

}