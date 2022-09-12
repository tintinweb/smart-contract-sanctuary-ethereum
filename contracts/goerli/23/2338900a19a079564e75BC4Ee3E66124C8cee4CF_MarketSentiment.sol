// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MarketSentiment {

    // Stores the address of the owner of the contract and he can add addtional crypto currencies that can be voted
    address public immutable owner;

    // All the crypto currencies who we have set to be voted by the users
    string[] public tokensArray;
    
    constructor() {
        owner = msg.sender;       
    }

    // Structure of the crypto currency that we have set up to be voted for
    struct Token{
        bool exists; // Indicates if it exists or not
        uint256 up; // The amount of upvotes it got
        uint256 down; // The amount of downVotes it got
        mapping(address=>bool) Voters; // A dictionary storing the addresses of the people who have voted for us  
    }                                  // and there addresses will keys and there values will set to true so tht they don't
                                      // vote again.

    // An event which is going to emitted upon recieving of each vote and logs the current amount of upVotes, downVotes
    // of the token they voted for and the token name they voted for and the address of the voter                                
    event tokenUpdated (
        uint256 up,
        uint256 down,
        address voter,
        string token
    );
   
    // A mapping strcture that sets the values of the crypto tokens as keys and sets a ticket object as value to the name 
    // So that we can know how many upvoted and downvoted and voted.
    mapping (string => Token) private tokenNameToTokenInfo;

    //errors 

    error OnlyOwnerCanCreateTokens();
    error tokenDoesNotExists();
    error YouHaveAlreadyVoted();

    modifier OnlyOwner {
        if(msg.sender == owner){
            revert OnlyOwnerCanCreateTokens();
        }
        _;
    }

    function addToken(string memory _tokenName) public OnlyOwner {
        // Storing the ticker in our mapping structure and updting the exists property in its value to true
        tokenNameToTokenInfo[_tokenName].exists = true;
        tokensArray.push(_tokenName);
    }

   // Creating a function that lets people vote by giving us the tickers name they want to vote for and give us a 
   // boolean representing true as upvote and false as downvote.

    function vote(string memory _token,bool _vote)public {

// Checking to see if the ticker they tryna vote for actually exists
        if(!tokenNameToTokenInfo[_token].exists){
            revert tokenDoesNotExists();
        }
        if(tokenNameToTokenInfo[_token].Voters[msg.sender]){
            revert YouHaveAlreadyVoted();
        }

        // Adding the person who is voting to our mapping structure and setting its value to true so that they cannot 
        // vote again
        tokenNameToTokenInfo[_token].Voters[msg.sender] = true;
        
        if(_vote){
            tokenNameToTokenInfo[_token].up += 1;
        } else {
            tokenNameToTokenInfo[_token].down += 1;
        }
        emit tokenUpdated(tokenNameToTokenInfo[_token].up,tokenNameToTokenInfo[_token].down,msg.sender,_token);
    }

    function getVotes(string memory _token) public view returns (uint256 up , uint256 down) {
        up = tokenNameToTokenInfo[_token].up;
        down= tokenNameToTokenInfo[_token].down;
    }
}