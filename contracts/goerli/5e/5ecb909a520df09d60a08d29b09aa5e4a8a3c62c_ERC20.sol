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
// 4. Everything is in wei internally!  1 szabo = 10^12 wei.  1000 Gwei = 1 szabo.  1 szabo = 1 micro eth. 

// import xxxxx
// erc20 address = xxxxxx

contract ERC20 {
    
    // Basic Functionality:
    //   mint -> create new token from nothing
    //   buyToken, sellToken  -> interact with contract token balance
    //   send  ->  Transfer from one user to another. 
    //   ownerPayout -> Claim any ETH in contract
    //   track owner list
    //   

    // State Variables 
    address payable owner;
    address[] public owners;

    address[] public hodlers;
    uint256 public hodlerCount;
    uint256 public total_tokens;
    uint256 public tokens_remaining;

    mapping(address => uint256) public balances;

   constructor()
    {
        tokens_remaining = 1000000;
        total_tokens = tokens_remaining;
        owner = payable(msg.sender);
        owners.push(owner);
    }

    event MessageLog(
        string comment
    );


    // Modifiers
    modifier onlyOriginalOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwner(){
        bool req = false;

        for (uint256 i = 0; i <= owners.length; i++){
            if (msg.sender == owners[i]) req = true;
        }
        require(msg.sender == owner);
        _;
    }

    // Functions 

    function addOwner(address add_owner) onlyOwner public payable{
        // Takes one address as an argument and adds to the list of owners.  Any owner can use this function.
        owners.push(add_owner);
    }

    function deleteOwner(address del_owner) onlyOriginalOwner public payable{
        // Remove an owner from the list of owners.  Only the original owner (i.e., the one who launched the contract) may call this function.
        uint256 i;
        for (i = 0; i <= owners.length; i++){
            if (del_owner == owners[i]) break;
        }

        for (uint256 j = i; j <= owners.length - 1; j++){
            owners[j] = owners[j+1];
        }

        owners.pop();
    }

    function mint(uint256 amount) public onlyOwner {
        total_tokens += amount;
        tokens_remaining += amount;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function ownerPayout() public payable onlyOwner {

        owner.transfer( getBalance() );
    }

    function compute_token_value() public pure virtual returns(uint256)
    {
        return 1000000000000;
    }

    function buyToken() public payable {
        uint256 token_value = compute_token_value();
        uint256 num_tokens = Math.divide(msg.value, token_value);

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
}

contract UChicagoFinMath is ERC20 {

    // Inherited from ERC20

    string public symbol;
    uint256 public version;

    constructor(address payable wallet) 
    {
        tokens_remaining = 10000000;
        total_tokens = tokens_remaining;
        owner = wallet;
        symbol = "dmileeva";
    }

}

contract UChicagoFinMathInherited is ERC20 {

    // Here we illustrate three methods for interacting between two contracts. 
    // I. Via inheritance
    // II. Via delegatecall
    // III. Via tx.origin. 

    string public symbol;
    uint256 public version;
    address payable token;

    constructor(address payable wallet, address payable token_) 
    {
        tokens_remaining = 10000000;
        total_tokens = tokens_remaining;
        owner = wallet;
        symbol = "dmileeva";
        token = token_;
    }

    function buyFromContract() public payable {

        ERC20 tokenClass = ERC20(token);
        uint256 val = msg.value;
        uint256 token_value = tokenClass.compute_token_value();
        require(val > token_value);

        (bool success, bytes memory data)  = token.delegatecall(
            abi.encodeWithSignature("buyToken()", 0)
        );
    }

}