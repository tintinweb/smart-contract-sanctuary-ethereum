// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;
import "./Initializable.sol";

contract countV2 is Initializable{

    uint32 private num;

    function initialize() public initializer { //0x8129fc1c
        num = 0;
    }

    function inc () public{
        num++;
    }
    function dec () public{
        num--;
    }
    function inc10 () public{
        num = num+10;
    }
    
    function getNum () public view returns (uint32){
        return num;
    }

}