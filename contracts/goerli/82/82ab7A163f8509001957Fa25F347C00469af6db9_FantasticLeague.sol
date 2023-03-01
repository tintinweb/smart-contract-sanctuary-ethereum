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
        string potID,
        address winner,
        uint256 potAmount
    );

    event potCreatedSuccess(
        string potID
    );

    // Structure for holding information about each pot
    struct Pot {
        string potID; // ID of the pot
        address creator; // Address of the pot creator
        uint potAmount; // Total amount of Ether in the pot
        uint buyInAmount; // Amount of Ether required for each player to join the pot
        bool isPrivate; // Flag indicating whether the pot is private
        bytes32 code; // Code required to join a private pot
        address[] users; // Addresses of all users in the pot
        bool isPayedOut; // Flag indicating whether the pot has been paid out
    }

    uint public potIndex; // Index for the next pot to be created
    mapping(string => Pot) public pots; // Mapping of pot IDs to pot structures
    mapping(string => mapping(address => uint)) public userScore; // Mapping of pot IDs to mappings of player addresses to player balances

    function hashCode(string memory _code) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_code));
    }

    // Function for creating a new pot
    function createPot(string memory _potID, string memory _code, uint _buyInAmount, bool _isPrivate) public payable {
        require(msg.value >= _buyInAmount, "Insufficient funds"); // Make sure that the amount of Ether sent is at least equal to the buy-in amount
        Pot memory newPot = Pot({ // Create a new pot structure
            potID: _potID, // Set the pot ID
            creator: msg.sender, // Set the pot creator to the address of the message sender
            potAmount: msg.value, // Set the pot amount to the amount of Ether sent with the message
            buyInAmount: _buyInAmount, // Set the buy-in amount to the input value
            isPrivate: _isPrivate, // Set the is-private flag to the input value
            code: hashCode(_code), // Set the pot code to the input value
            users: new address[](0), // Initialize the users array to an empty array
            isPayedOut: false // Set the is-paid-out flag to false
        });
        pots[_potID] = newPot; // Add the new pot to the pots mapping
        joinPot(_potID, hashCode(_code)); // Call the joinPot function to add the creator to the users array and update the player balances mapping
        potIndex++; // Increment the pot index for the next pot
        emit potCreatedSuccess(_potID);
    }

    // Function for a player to join a pot
    function joinPot(string memory _potID, bytes32 _code) public payable {
        Pot storage pot = pots[_potID]; // Get a reference to the pot structure
        require(msg.value == pot.buyInAmount, "Incorrect buy-in amount"); // Make sure that the amount of Ether sent is equal to the buy-in amount
        if (pot.isPrivate) { // If the pot is private
            require(_code == pot.code, "Incorrect pot code"); // Make sure that the input code matches the pot code
        }
        pot.users.push(msg.sender); // Add the player to the users array
        userScore[_potID][msg.sender] += msg.value; // Update the player's balance in the player balances mapping
        pot.potAmount += msg.value; // Add the player's buy-in amount to the pot amount
    }


    function closePot(string calldata _potID) public onlyOwner {
        require(pots[_potID].isPayedOut == false, "Pot already payed out");

        pots[_potID].isPayedOut = true;

        address payable winner = payable(determineWinner(_potID));

        uint256 potAmount = pots[_potID].potAmount;
        if (winner != address(0)) {
            winner.transfer(potAmount);
        }

        emit PotClosed(_potID, winner, potAmount);
    }

    function determineWinner(string calldata _potID) public onlyOwner returns (address) {
        updateScores();
        Pot storage pot = pots[_potID];

        address payable winner = payable(address(0));
        uint256 highestScore = 0;

        for (uint256 i = 0; i < pot.users.length; i++) {
            address player = pot.users[i];
            uint256 score = userScore[_potID][player];

            if (score > highestScore) {
                highestScore = score;
                winner = payable(player);
            }
        }

        require(winner != address(0), "No winner found");
        return winner;
    }

    function updateScores() public onlyOwner {
        //fetch scores from oracle
        //send potID to oracle
        //receive list of users with teams
        //each team consits of players
        //each player has a rating

        // struct team {
        //     uint ratingPlayer1,
        //     uint ratingPlayer2,
        //     uint ratingPlayer3,
        //     uint ratingPlayer4,
        //     uint ratingPlayer5
        //}

        //determine the teamrating by adding up the playerratings
        //update the userScore mapping
    }
}