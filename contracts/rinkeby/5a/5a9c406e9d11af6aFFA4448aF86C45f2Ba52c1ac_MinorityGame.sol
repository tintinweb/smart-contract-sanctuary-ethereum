/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;


contract MinorityGame {
    address payable public gameMaster;
    uint public ticketPrice;
    mapping(bytes32 => bool) public commitMap;
    address payable[] public players;
    address payable[] opt0;
    address payable[] opt1;
    uint public Qid;
    uint private ticketLimit;
    
    struct Vote {
        address _address;
        uint option;
        string salt;
    }

    constructor (uint _ticketPrice){
        gameMaster = payable(msg.sender);
        // Vote limits
        // ticketLimit = 5;
        ticketPrice = _ticketPrice;
        Qid = 1;
    }

    modifier onlyGameMaster() {
        require(msg.sender == gameMaster);
        _;
    }

    // Vote is called by participants to commit their votes (and pay)
    function vote(bytes32 commitHash) public payable{
        //ticket price equals to amount entered
        // require(msg.value == 50000000 * 1 gwei); // #TODO CHANGE BACK
        require(msg.value == ticketPrice * 1 gwei);
        
        // Push all player addresses to players[] for emergencyRepay
        players.push(payable(msg.sender));
        
        // Add commitHash to commitMap
        commitMap[commitHash] = true;
    }

    // Revert function that is called when game fails for any reason
    function emergencyRepay() public payable onlyGameMaster{
        for(uint i; i < players.length; i++){
            players[i].transfer(ticketPrice * 1 gwei);
            }
        // Resetting contract state
        players = new address payable[](0);
        Qid++;
        return;
    }

    // Ends the game
    // 1. Check length of players = length of votes
    // 2. Double check votes sent in from backend against the commitMap
    // 3. If there are no discrepencies, proceed to distribute Prize
    function reveal(Vote[] memory votes) payable external {
        // First check - length of players
        if(players.length != votes.length){
            emergencyRepay();
        }

        for(uint i; i < votes.length; i++){
            // Build opt0 and opt1 and emergencyRepay on unexpected vote data
            if(votes[i].option == 0){
                opt0.push(payable(votes[i]._address));
            }
            else if(votes[i].option == 1){
                opt1.push(payable(votes[i]._address));
            }
            else{
                emergencyRepay();
            }

            // Hash vote information
            bytes32 _hash = hasher(votes[i]._address, votes[i].option, votes[i].salt);

            // Second check - check against commitMap
            if (commitMap[_hash] != true){
                // Fault in commit-reveal scheme
                emergencyRepay();
                return;
            }
        }
        // Option 1 is the minority, payout to players that chose option 1
        if(opt0.length > opt1.length){
            distributePrize(opt1);
        }
        // Option 0 is the minority, payout to players that chose option 0
        else if(opt0.length < opt1.length){
            distributePrize(opt0);
        }
        else{
            emergencyRepay();
        }

        // No discrepencies, distribute prize
        // Resetting contract state
        players = new address payable[](0);
        Qid++;
        return;
    }


    // When distributePrize is called, winning amount is distributed to each minority winner that
    // is passed into the function.
    function distributePrize( address payable[] memory winners) internal onlyGameMaster {
        // GameMaster earnings
        uint commission = address(this).balance * 5/100;
        gameMaster.transfer(commission);

        if(winners.length == 0){
            emergencyRepay();
        }

        uint winningAmount =(address(this).balance - commission) / winners.length;
        for(uint i; i < winners.length; i++){
            winners[i].transfer(winningAmount);
        }
        return;
    }
    
    // Hashing function that hashes address, option and salt
    function hasher(address add, uint option, string memory salt) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(add, option, salt));
    }

    // Return the number of players participating
    function getPlayersNumber() view public returns(uint256){
        return players.length;
    }
}