pragma solidity 0.8.13;
//SPDX-License-Identifier: UNLICENSED

import "./Ownable.sol";
import "./TimeoftheGames.sol";

// The HungerGames contract is a multisig contract with escrow properties. The balance of the contract is the winning prize
// and it can only be withdrawed to the winner when the mayority of the contestants aproves it.
// It is recomended to use with your friends and with small amounts of money, just for the lulz.

// This project is in dedication to my friend Marcelo who had the original idea this summer to lose weight
// by placing a bet against yourself while competing with friends...

contract HungerGames is Ownable, Timeable {
    //state variables

    uint256 public peopleCount = 0;

    mapping(uint => Person) public people;

    struct Person {
        uint _id;
        string _name;
        uint _weight; // This value is in plain kilograms without commas. If you weigth 105,5 kilogramos,
        // round down to 105 kg. If you weight 105,51kg, round up to 106kg.
        uint _bet;
        address payable _receiver;
    }

    function retrieve() public view returns (uint256) {
        return peopleCount;
    }

    function addPerson(
        uint _id,
        string memory _name,
        uint _weight,
        uint _bet,
        address payable _receiver
    ) public onlyOwner onlyWhileOpen {
        incrementCount();
        people[peopleCount] = Person(_id, _name, _weight, _bet, _receiver);
    }

    function incrementCount() internal {
        peopleCount += 1;
    }

    function getPerson(
        uint _index
    ) public view returns (uint, string memory, uint, uint, address payable) {
        Person memory personToReturn = people[_index];
        return (
            personToReturn._id,
            personToReturn._name,
            personToReturn._weight,
            personToReturn._bet,
            personToReturn._receiver
        );
    }

    mapping(address => uint) public deposits;

    function depositBet(address winner) public payable {
        uint amount = msg.value;
        deposits[winner] = deposits[winner] + amount;
    }

    function collectPrize(address payable winner) public {
        uint Prize = deposits[winner];
        deposits[winner] = 0;
        winner.transfer(Prize);
    }
}

pragma solidity 0.8.13;
//SPDX-License-Identifier: UNLICENSED


contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;    //run the function
    }

    constructor (){
        owner = msg.sender;
    }
}

pragma solidity 0.8.13;
//SPDX-License-Identifier: UNLICENSED


contract Timeable {

    uint openingTime = 1648436401;

    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime);
        _;      
    }

    constructor (){
        
    }
}