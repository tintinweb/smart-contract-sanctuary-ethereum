/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.8.0;


contract Donation  {
    address payable owner;
    function Setowner( address payable _owner) public  {
 owner = _owner;

}

function Donate() public payable {

owner.transfer(msg.value);
}
}