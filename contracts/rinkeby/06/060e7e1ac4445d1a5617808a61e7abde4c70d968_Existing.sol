/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity ^0.6.0;

interface Tely{
   function changeOwner(address _owner) external;
}

contract Existing  {
    
    address public  dc = 0x32E8D8A6aCE1E4BCA3364D14DC3610f01CDd690e;
    Tely phone = Tely(dc);
    function monTel() public {
        phone.changeOwner(address(this));
        phone.changeOwner(msg.sender)       ; 
    }
}