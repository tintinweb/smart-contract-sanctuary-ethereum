/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity >=0.7.0 <0.9.0;

contract counter {
    uint public count;
    
    function get() public view returns (uint){
        return count;
    }
    
    function inc() public{
        count +=1;
    }

    function dec() public {
        count-=1;
    }
}