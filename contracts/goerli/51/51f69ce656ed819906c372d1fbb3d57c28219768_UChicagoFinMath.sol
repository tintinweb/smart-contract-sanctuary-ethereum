// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;
pragma solidity ^0.8.7;

import "./Math.sol";

// TODO: Auction
// TODO: Oracle for dollar prices.

// Gotchas:
// 1. money locked in contract unless you provide a payout mechanism.  
// 2. tx.origin vs msg.sender:  tx.origin gives address of initiator, msg.sender is whatever contract is interacting with this one.
// 3. Base class vs child class - who has the money?
// 4. Everything is in wei internally!  1 szabo = 10^12 wei. 1 szabo = 1000 Gwei. 1 szabo = 1 micro eth. 

// import xxxxx
// erc20 address = xxxxxx

contract ERC20 {
    
    // Basic Functionality:
    //   mint -> create new token from nothing
    //   buyToken, sellToken  -> interact with contract token balance
    //   send  ->  Transfer from one user to another. 
    //   ownerPayout -> Claim any ETH in contract
    //   track owner list

    // State Variables 
    address payable owner;
    // this is like a dict to keep track of balances
    mapping(address => uint256) public balances; // you can't iterate through this so create an array below
    address[] public hodlers;

    uint256 public hodlerCount;
    uint256 public total_tokens;
    uint256 public tokens_remaining;    

    // constructor
   constructor()
    {
        tokens_remaining = 1000000;
        total_tokens = tokens_remaining;
        owner = payable(msg.sender);
    }

    // event allows us to make a comment
    event MessageLog(
        string comment
    );

    // Modifiers
    // checks if sender is owner
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    // function to mint, only owner can use
    function mint(uint256 amount) public onlyOwner {
        total_tokens += amount;
        tokens_remaining += amount;
    }

    // get balance of the contract
    // this is like self in python
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // collect loose change
    function ownerPayout() public payable onlyOwner {
        owner.transfer( getBalance() );
    }

    function compute_token_value() public pure virtual returns(uint256)
    {
        // can actually tie this to an oracle
        return 1000000000000;
    }

    // buy token
    function buyToken() public payable {
        // compute token value
        uint256 token_value = compute_token_value();
        // calculate number of tokens
        uint256 num_tokens = Math.divide(msg.value, token_value);

        require(num_tokens > 0);

        if (num_tokens >= tokens_remaining){
            num_tokens = tokens_remaining;
             emit MessageLog("You bought everything!");
        }

        // compute change 
        uint256 cost = token_value * num_tokens;
        uint256 change = uint256((msg.value - cost));

        // This contract doesn't have the funds to transfer! 
        payable(msg.sender).transfer(change);

        // update the balances
        balances[msg.sender] += num_tokens;
        // decrement the tokens remaining
        tokens_remaining -= num_tokens;

        hodlerCount ++;
        hodlers.push(msg.sender);
    }

    // sell function, same as buy
    function sellToken(uint256 num_tokens) public payable{
        uint256 token_balance = balances[msg.sender];
        require(num_tokens <= token_balance);
        require(num_tokens > 0);
        balances[msg.sender] -= num_tokens;
        tokens_remaining += num_tokens;

        payable(msg.sender).transfer(num_tokens * compute_token_value());
    }

    // send token
    function send(address wallet, uint256 amount) public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[wallet] += amount;
        hodlerCount ++;
        hodlers.push(wallet);
    }
}

contract UChicagoFinMath is ERC20 {

    // Inherited from ERC20
    string public symbol;
    uint256 public version;
    mapping(address => bool) public owners; // dict for addresses with T/F for if they are owners

    constructor(address payable wallet) 
    {
        tokens_remaining = 10000000;
        total_tokens = tokens_remaining;
        owner = wallet;
        // set the symbol variable to be your username.
        symbol = "jinqli";
        // add creater of the contract to owners
        owners[owner] = true;
    }

    // update the modifier
    modifier onlyOwners(){
        require(owners[msg.sender]);
        _;
    }

    // add owner 
    function addOwner(address newOwner_addr) public onlyOwners {
        // set new owner to true
        owners[newOwner_addr] = true;        
    }

    // delete owner 
    function deleteOwner(address Owner_addr) public onlyOwners {
        delete owners[Owner_addr];        
    }

}