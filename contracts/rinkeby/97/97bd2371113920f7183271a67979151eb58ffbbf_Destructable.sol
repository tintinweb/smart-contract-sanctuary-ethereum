/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

pragma solidity 0.5.11;

contract Destructable {
    address private owner;
    constructor() public payable {
        owner = msg.sender;    
    }    
    
    function destroy(address payable x) public {
        require(msg.sender == owner);
        selfdestruct(x);
    }
}