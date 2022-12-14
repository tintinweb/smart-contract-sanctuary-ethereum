/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// File contracts/BuyMeACoffee.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log

// Deployed in Goerli at 0x504Dc2c783ef805A2b0717182A2a56Aef18A3341

contract BuyMeACoffee {
    // Event to emit when a Coffee is created
    event NewCoffee(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        uint32 amount
    );
    // Coffee struct
    struct Coffee {
        address from;
        uint256 timestamp;
        string name;
        string message;
        uint32 amount;
    }
    //List of all coffees received
    Coffee[] coffees;
    
    //Address of contract deployer
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }
    /**
     * @dev buy a coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message a nice message grom the coffee buyer
     * @param _amount number of coffees bought from the buyer
     */
    function buyCoffee(string memory _name, string memory _message, uint32 _amount) public payable {
        // money is stored in the contract's balance
        require(msg.value > 0, "can't but a coffee with 0 eth");

        coffees.push(Coffee(
            msg.sender,
            block.timestamp,
            _name,
            _message,
            _amount
        ));

        emit NewCoffee(
            msg.sender,
            block.timestamp,
            _name,
            _message,
            _amount);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
        
    }
    /**
     * @dev retrieve all the coffees received and stored on the blockchain
     */
    function getMemos() public view returns(Coffee[] memory) {
        return coffees;

    }

}