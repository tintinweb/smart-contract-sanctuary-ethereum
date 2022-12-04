// SPDX-License-Identifier: NOLICENCE

pragma solidity 0.8.17;

contract FortuneWheel{
    uint256 private capacity = 3;
    uint256 private betPrice = 1e16;
    address[] private members;
    address immutable owner;

    constructor(){
        owner = msg.sender;
        }

    function setCapacity(uint256 _capacity) public onlyOwner{
        if(members.length!=0){
            require(_capacity >= capacity, "New capacity must be grater that current capacity");
        }else
        {
            require(_capacity != 0, "New capacity must be greater than 0"); 
        }
        capacity = _capacity;
    }

    function setBetPrice(uint _betPrice) public onlyOwner{
        betPrice = _betPrice;
    }

    function getCapacity() public onlyOwner view returns(uint256){
        return capacity;
    }

    function getBetPrice() public view returns(uint256){
        return betPrice;
    }

    function placeBet() external payable{
        require(msg.sender != owner && msg.value == betPrice, "You cannot place a bet or ETH value is wrong");
        members.push(msg.sender);
        
        if(members.length == capacity){
            withdraw();
        }
    }

    function withdraw() private{
        members = new address[](0);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }
}