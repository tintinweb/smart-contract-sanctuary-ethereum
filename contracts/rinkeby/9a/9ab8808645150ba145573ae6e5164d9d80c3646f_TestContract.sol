/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

pragma solidity 0.5.0;

contract TestContract {

    address public owner;

    address public lastwithdraw;

    constructor() public {
        owner = msg.sender;
    }

    function withdraw() public {
       
       lastwithdraw = msg.sender;
       
    }

}