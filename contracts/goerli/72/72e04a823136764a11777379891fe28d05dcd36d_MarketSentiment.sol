/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MarketSentiment {
    address public owner; //account owner address

    string[] public cryptoArray; //array containing cryptos set by owner

    constructor() {
        owner = msg.sender;
    }

    //any crypto added will have following properties
    struct crypto {
        bool exists; //if it exists
        uint32 up; //for upvotes
        uint32 down; //for downvotes
        mapping(address => bool) voters; //for containing list of voters who have voted
    }

    //event to notify moralis for any events happening with this smart contract
    event cryptoUpdated(uint256 up, uint256 down, address voter, string crypto);

    mapping(string => crypto) private Cryptos; //for mapping each crypto with it's properties

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can create/add cryptos");
        _;
    }

    modifier doesExists(string memory _crypto){
        require(Cryptos[_crypto].exists, "Can't vote on this coin");
        _;
    }

    modifier hasNotVoted(string memory _crypto){
        require(Cryptos[_crypto].voters[msg.sender], "You have already voted for this coin");
        _;
    }

    function addCrypto(string memory _crypto) public onlyOwner {
        crypto storage newCrypto = Cryptos[_crypto];
        newCrypto.exists = true;
        cryptoArray.push(_crypto);
    }

    function vote(string memory _crypto, bool _vote) public doesExists(_crypto) hasNotVoted(_crypto){ 
        crypto storage cry = Cryptos[_crypto];
        cry.voters[msg.sender] = true;
        
        if(_vote){
            cry.up++;
        }else{
            cry.down++;
        }

        emit cryptoUpdated(cry.up, cry.down, msg.sender, _crypto);  //emitting the event for moralis
    } 

    function getVotes(string memory _crypto) public view doesExists(_crypto) returns(uint32 up, uint32 down){
        crypto storage cry = Cryptos[_crypto];
        return(cry.up, cry.down);
    }
}