// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Initializer {
    bool public initialized = false;

    modifier isUninitialized() {
        require(!initialized, "Initializer: initialized");
        _;
        initialized = true;
    }

    modifier isInitialized() {
        require(initialized, "Initializer: uninitialized");
        _;
    }
}

abstract contract DelegateGuard {
    // a global variable used to determine whether it is a delegatecall
    address private immutable self = address(this);

    modifier isDelegateCall() {
        require(self != address(this), "DelegateGuard: delegate call");
        _;
    }
}

contract Protected {
    mapping(address => uint) cooldown_block;
    mapping(address => bool) cooldown_free;
    mapping(address => bool) is_auth;

    address owner;
    bool locked;
    uint cooldown = 5 seconds;

    modifier onlyOwner() {
      require(msg.sender==owner, "Not owner.");
      _;
    }

    modifier onlyAuth() {
      require( is_auth[msg.sender] || msg.sender==owner, "Not authorized.");
      _;
    }

    modifier safe() {
      require(!locked, "Reentrant.");
      locked = true;
      _;
      locked = false;
    }

    modifier cooled() {
        if(!cooldown_free[msg.sender]) { 
            require(cooldown_block[msg.sender] < block.timestamp, "Slowdown.");
            _;
            cooldown_block[msg.sender] = block.timestamp + cooldown;
        }
    }

    function authorized(address addy) public view returns(bool) {
      return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
      is_auth[addy] = booly;
    }

    receive() external payable {}
    fallback() external payable {}
}

contract DarkMarket is Protected, DelegateGuard, Initializer {
    // STATUSES
    // 0 ACTIVE
    // 1 FINISHED
    // 2 CANCELLED


    struct Bet {
        uint id;
        uint status;
        string statement;
        uint timestamp;
    }

    mapping (uint => Bet) public bets;

    struct Odd {
        uint id;
        uint betId;
        address owner;      // address who make the odd
        address challenger; // address who contest the bet
        address winner;     // address who can claim prize
        bool option;
        uint oddWiner;
        bool claimed;
        uint timestamp;     // timestamp
    }

    mapping (uint => Odd) public odds;

    uint betCounter;
    uint oddCounter;


    event LogPublishBet(uint indexed _id, string indexed statment);

    function constructor1(address _manager) public isDelegateCall isUninitialized {
        owner = _manager;
        is_auth[_manager] = true;
    }

    // Function to add bet only admin
    // Publish a new bet
    function publishBet(string calldata statment) public onlyAuth {
        // A new bet
        betCounter++;

        // Store this bet into the contract
        bets[betCounter] = Bet(
        betCounter,
        0,
        statment,
        block.timestamp
        );
    
        emit LogPublishBet(betCounter, statment);
    }

    // Function to create option (odd + winner)
    function publishOdd(uint betId, bool option, uint oddWinner) payable public {
        require(bets[betId].status == 0, "Bet has to be active");

        // A new bet
        oddCounter++;

        // Store this bet into the contract
        odds[oddCounter] = Odd(
            oddCounter,
            betId,
            msg.sender,
            address(0x0),
            address(0x0),
            option,
            oddWinner,
            false,
            block.timestamp
        );
    }

    // Function to contest bet (id)
    function contestOdd(uint oddId) payable public {
        require(bets[odds[oddId].betId].status == 0, "Bet has to be active");
        require(odds[oddId].owner != msg.sender, "Can't contest yourself");

        odds[oddId].challenger = msg.sender;
    }

    // Function to resolve bet only admin
    function resolvetBet(uint betId, bool winnerOption) payable public onlyAuth {
        require(bets[betId].status == 0, "Bet has to be active");
        bets[betId].status = 1;

        // here we must to do a for on odds, and marking the winner, so he can claim the price
        // for each pool bet
        for (uint256 index = 0; index < oddCounter; index++) {
            // If bet is for win pool
            if (odds[index].option == winnerOption) {
                odds[index].winner = odds[index].owner;
            } else {
                odds[index].challenger = odds[index].owner;
            }
      
        }
    }

    // Function to cancel bet only admin
    function cancelBet(uint betId) payable public onlyAuth {
        require(bets[betId].status == 0, "Bet has to be active");
        bets[betId].status = 2;
    }

    // Claim
    function claimOdd(uint oddId) payable public {
        require(bets[odds[oddId].betId].status == 1, "Bet has to be active");
        require(odds[oddId].winner == msg.sender, "You are not the winner");

        // Function to pay
        odds[oddId].claimed = true;
    }

    // function to get active bets (ids)
    function getBetsByStatus(uint status) public view returns (uint[] memory) {
        uint[] memory betIds = new uint[](betCounter);
        uint numberOfAvailableBets = 0;

        // Iterate over all bets
        for(uint i = 1; i <= betCounter; i++) {
            // Keep the ID if the bet is still available
            if(bets[i].status == status) {
                betIds[numberOfAvailableBets] = bets[i].id;
                numberOfAvailableBets++;
            }
        }

        uint[] memory availableBets = new uint[](numberOfAvailableBets);

        // Copy the betIds array into a smaller availableBets array to get rid of empty indexes
        for(uint j = 0; j < numberOfAvailableBets; j++) {
             availableBets[j] = betIds[j];
        }

        return availableBets;
    }

    // function to get odds, by id
    function getOddsByBetId(uint betId) public view returns (uint[] memory) {
        uint[] memory oddIds = new uint[](oddCounter);
        uint numberOfAvailableBets = 0;

        // Iterate over all bets
        for(uint i = 1; i <= oddCounter; i++) {
            // Keep the ID if the bet is still available
      
            if(odds[i].betId == betId) {
                oddIds[numberOfAvailableBets] = bets[i].id;
                numberOfAvailableBets++;
            }
        }

        uint[] memory availableBets = new uint[](numberOfAvailableBets);

        // Copy the oddIds array into a smaller availableBets array to get rid of empty indexes
        for(uint j = 0; j < numberOfAvailableBets; j++) {
            availableBets[j] = oddIds[j];
        }

        return availableBets;
    }
}