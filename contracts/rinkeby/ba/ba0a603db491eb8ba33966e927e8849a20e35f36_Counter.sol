pragma solidity ^0.8.4;

contract Counter {
    uint public count;
    
    function increment() external {
        count++;
    }
    
    function getAddress() public view returns(address) {
        
        return address(this);
        
    }
}