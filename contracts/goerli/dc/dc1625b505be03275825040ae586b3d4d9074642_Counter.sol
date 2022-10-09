pragma solidity ^0.8.9;

contract Counter {
    uint public counter;
    address public owner;

    constructor(uint8 _initialCount){
        counter = _initialCount;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Not the owner");
        _;
    }
    function inc() public {
        require(msg.sender == owner, "sorry, you don't own shit");
        ++counter;
    }

    function superInc() public onlyOwner {
        counter += 10;
    }

    function dec() public {
        --counter;
    }

    function get() public view returns (uint) {
        return counter;
    }

    function getTimestamp() public view returns (uint){
        return block.timestamp;
    }

    function showValue(uint y) public pure returns (uint){
        return y;
    }

    receive() external payable {}

    // Function to withdraw all Ether from this contract.
    function withdraw() public onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success,bytes memory data) = owner.call{value : amount}("");
        require(success, "Failed to send Ether");
    }
}