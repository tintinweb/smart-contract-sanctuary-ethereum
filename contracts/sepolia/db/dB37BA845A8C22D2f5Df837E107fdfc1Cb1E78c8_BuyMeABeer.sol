// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BuyMeABeer {

    uint256 totalBeers;
    address payable public owner; 


    constructor() payable {
        owner = payable(msg.sender);
    }

    event NewBeer (
        address indexed from ,
        uint256 timeStamp, 
        string name, 
        string message
    );

    struct Beer {
        address sender; 
        string message; 
        string name;
        uint256 timeStamp;        
    }

    Beer[] beer;

    function getAllBeers() public view returns (Beer[] memory)
    {
        return beer; 
    }

    function getTotalBeers() public view returns (uint256 )
    {
        return totalBeers; 
    }

    function buyBeer(string memory _name, string memory _message, uint256 _numberofBeers) payable public 
    {
        require(msg.value == _numberofBeers * 0.01 ether, "Please pay the require amount");

        totalBeers += 1; 
        beer.push(Beer(msg.sender, _message, _name, block.timestamp));

        (bool success,) = owner.call{value: msg.value}("");
        require (success, "Failed to send the ethers to the owner.");

        emit NewBeer(msg.sender, block.timestamp, _name,_message );
    }

}