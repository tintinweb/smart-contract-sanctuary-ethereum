/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;
pragma solidity ^0.8.7;


// TODO: Auction
// TODO: Oracle for dollar prices.

// Gotchas:
// 1. money locked in contract unless you provide a payout mechanism.  
// 2. tx.origin vs msg.sender:  tx.origin gives address of initiator, msg.sender is whatever contract is interacting with this one.
// 3. Base class vs child class - who has the money?
// 4. Everything is in wei internally!  1 szabo = 10^12 wei.  1000 Gwei = 1 szabo.  1 szabo = 1 micro eth. 

// import xxxxx
// erc20 address = xxxxxx

contract Manyowners {
    
    // Basic Functionality:
    //   mint -> create new token from nothing
    //   buyToken, sellToken  -> interact with contract token balance
    //   send  ->  Transfer from one user to another. 
    //   ownerPayout -> Claim any ETH in contract
    //   track owner list
    //   

    // State Variables 
    address payable[] owner;
    address payable originowner;
    address[] public hodlers;
    uint256 public hodlerCount;
    uint256 public total_tokens;
    uint256 public tokens_remaining;

    mapping(address => uint256) public balances;
    string public symbol;

   constructor()
    {
        symbol = "yunhongwang";
        tokens_remaining = 1000000;
        total_tokens = tokens_remaining;
        owner.push(payable(msg.sender));
        originowner = payable(msg.sender);
    }

    event MessageLog(
        string comment
    );


    // Modifiers
    modifier OnlyOwner(){
        require(originowner == msg.sender);
        _;
    }

    modifier InOwner(){
        require(msg.sender == originowner);
        bool isowner = false;
        for (uint i = 0; i < owner.length; i++){
            if (owner[i] == msg.sender){
                isowner == true;
                break;
            }
        }
        require (isowner);
        _;
    }

    // Functions 
    function mint(uint256 amount) public InOwner {
        total_tokens += amount;
        tokens_remaining += amount;
    }
    
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b > 0);
        uint256 c = a/b;
        return c;
        //
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function ownerPayout(address payable people) public payable InOwner {

        people.transfer( getBalance() );
    }

    function compute_token_value() public pure virtual returns(uint256)
    {
        return 1000000000000;
    }

    function buyToken() public payable {
        uint256 token_value = compute_token_value();
        uint256 num_tokens = divide(msg.value, token_value);

        require(num_tokens > 0);

        if (num_tokens >= tokens_remaining){
            num_tokens = tokens_remaining;
             emit MessageLog("You bought everything!");
        }

        uint256 cost = token_value * num_tokens;
        uint256 change = uint256((msg.value - cost));

        // This contract doesn't have the funds to transfer! 
        payable(msg.sender).transfer(change);

        balances[msg.sender] += num_tokens;
        tokens_remaining -= num_tokens;

        hodlerCount ++;
        hodlers.push(msg.sender);
    }


    function sellToken(uint256 num_tokens) public payable{
        uint256 token_balance = balances[msg.sender];
        require(num_tokens <= token_balance);
        require(num_tokens > 0);
        balances[msg.sender] -= num_tokens;
        tokens_remaining += num_tokens;

        payable(msg.sender).transfer(num_tokens * compute_token_value());
    }

    function send(address wallet, uint256 amount) public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[wallet] += amount;
        hodlerCount ++;
        hodlers.push(wallet);
    }

    function addOwner(address payable people) public{
        bool isowner = false;
        for (uint i = 0; i < owner.length; i++){
            if (owner[i] == msg.sender){
                isowner == true;
                break;
            }
        }
        if (isowner == false){
            owner.push(people);
        }
    }

    function deleteOwner(address payable people) public OnlyOwner{
        for (uint i = 0; i < owner.length; i++){
            if (owner[i] == people){
                owner[i] == owner[owner.length-1];
                owner.pop();
            }
        }
    }
}