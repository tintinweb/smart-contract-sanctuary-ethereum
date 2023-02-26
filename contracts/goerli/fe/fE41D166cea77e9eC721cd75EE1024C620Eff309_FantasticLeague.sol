pragma solidity ^0.8.17;

contract FantasticLeague {
    address public owner;

    constructor() {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this method");
        _;
    }

    event PotClosed(
        uint256 potId,
        address winner,
        uint256 potAmount
    );

    // Structure for holding information about each pot
    struct Pot {
        uint potID; // ID of the pot
        address creator; // Address of the pot creator
        uint potAmount; // Total amount of Ether in the pot
        uint buyInAmount; // Amount of Ether required for each player to join the pot
        bool isPrivate; // Flag indicating whether the pot is private
        bytes32 code; // Code required to join a private pot
        address[] players; // Addresses of all players in the pot
        bool isPayedOut; // Flag indicating whether the pot has been paid out
    }

    uint public potIndex; // Index for the next pot to be created
    mapping(uint => Pot) public pots; // Mapping of pot IDs to pot structures
    mapping(uint => mapping(address => uint)) public playerBalances; // Mapping of pot IDs to mappings of player addresses to player balances

    function hashCode(string memory _code) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_code));
    }

    // Function for creating a new pot
    function createPot(uint _buyInAmount, bool _isPrivate, string memory _code) public payable {
        require(msg.value >= _buyInAmount, "Insufficient funds"); // Make sure that the amount of Ether sent is at least equal to the buy-in amount
        Pot memory newPot = Pot({ // Create a new pot structure
            potID: potIndex, // Set the pot ID to the current value of the pot index
            creator: msg.sender, // Set the pot creator to the address of the message sender
            potAmount: msg.value, // Set the pot amount to the amount of Ether sent with the message
            buyInAmount: _buyInAmount, // Set the buy-in amount to the input value
            isPrivate: _isPrivate, // Set the is-private flag to the input value
            code: hashCode(_code), // Set the pot code to the input value
            players: new address[](0), // Initialize the players array to an empty array
            isPayedOut: false // Set the is-paid-out flag to false
        });
        pots[potIndex] = newPot; // Add the new pot to the pots mapping
        joinPot(potIndex, _code); // Call the joinPot function to add the creator to the players array and update the player balances mapping
        potIndex++; // Increment the pot index for the next pot
    }

    // Function for a player to join a pot
    function joinPot(uint _potID, string memory _code) public payable {
        Pot storage pot = pots[_potID]; // Get a reference to the pot structure
        require(msg.value == pot.buyInAmount, "Incorrect buy-in amount"); // Make sure that the amount of Ether sent is equal to the buy-in amount
        if (pot.isPrivate) { // If the pot is private
            require(hashCode(_code) == pot.code, "Incorrect pot code"); // Make sure that the input code matches the pot code
        }
        pot.players.push(msg.sender); // Add the player to the players array
        playerBalances[_potID][msg.sender] += msg.value; // Update the player's balance in the player balances mapping
        pot.potAmount += msg.value; // Add the player's buy-in amount to the pot amount
    }


    function closePot(uint256 _potId) public onlyOwner {
        require(pots[_potId].isPayedOut == false, "Pot already payed out");

        pots[_potId].isPayedOut = true;

        address payable winner = payable(determineWinner(_potId));

        uint256 potAmount = pots[_potId].potAmount;
        if (winner != address(0)) {
            winner.transfer(potAmount);
        }

        emit PotClosed(_potId, winner, potAmount);
    }

    function determineWinner(uint256 _potId) public onlyOwner returns (address) {
        Pot storage pot = pots[_potId];

        address payable winner = payable(address(0));
        uint256 highestBalance = 0;

        for (uint256 i = 0; i < pot.players.length; i++) {
            address player = pot.players[i];
            uint256 balance = playerBalances[_potId][player];

            if (balance > highestBalance) {
                highestBalance = balance;
                winner = payable(player);
            }
        }

        require(winner != address(0), "No winner found");
        return winner;
    }
}