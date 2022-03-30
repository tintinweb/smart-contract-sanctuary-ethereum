// SPDX-License-Identifier: MIT

pragma solidity 0.5.1;

import "./Math.sol";

// TODO: Auction
// TODO: Oracle for dollar prices.

contract Mani {
    string public symbol;
    uint256 public tokens_remaining;
    int public version = 1;
    address[] public owners;
    uint256 ownerCount;
    uint public value;
    uint256 public total_manni = 100000;
    uint256 public _initial_block_number ;
    uint256 public inflation_constant;

    mapping(address => uint256) public balances;

    event TransactionLog(
        address indexed customer,
        uint256 remaining,
        uint256 purchased,
        string action,
        string comment
    );

    function compute_token_value() public view returns (uint256)  {
        return  100 szabo * ( 2 ** uint( (block.number - _initial_block_number)/ inflation_constant)  ) ;
    }

    constructor()  public 
    {
        symbol = "MANI";
        tokens_remaining = total_manni;
        inflation_constant = 1000;
        _initial_block_number = block.number;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    function mint() public payable {
        uint256 token_value = compute_token_value();
        uint256 num_tokens = Math.divide(msg.value, token_value);
        require (num_tokens > 0);

        uint256 cost = token_value * num_tokens;
        uint256 change = uint256((msg.value - cost));
        address(msg.sender).transfer(change);

        balances[tx.origin] += num_tokens;
        tokens_remaining -= num_tokens;
    
        emit TransactionLog(msg.sender, tokens_remaining, num_tokens, "buy", "Have a nice day!");
        ownerCount ++;
        owners.push(tx.origin);
    }

    function redeem(uint256 num_tokens) public payable{
        uint256 token_balance = balances[tx.origin];
        require(num_tokens <= token_balance);
        balances[tx.origin] -= num_tokens;
        address(tx.origin).transfer(num_tokens * compute_token_value());
        emit TransactionLog(msg.sender, tokens_remaining, num_tokens, "sell", "See ya later aligator!");
    }

    function send(address wallet, uint256 amount) public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[wallet] += amount;
        ownerCount ++;
        owners.push(wallet);
    }

}

contract MoneyForMani is Mani {

    address owner;
    uint256 openingTime  = 1647210381;
    address payable wallet;
    uint public version = 1;

    constructor(address payable _wallet) Mani() public{
        owner = msg.sender;
        wallet = _wallet;
    }

    function () external payable {}

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhileOpen(){
        require( block.timestamp >= openingTime);
        _;
    }


    uint256 public peopleCount =0;

    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
    }
    mapping(uint => Person) public people;

    function set_inflation_constant(uint256 blocks) public  onlyOwner{
        inflation_constant = blocks;
        _initial_block_number = block.number;
    }


    function chaChing() public payable onlyOwner {
        wallet.transfer( getBalance() );
    }

    function addPerson(string memory _firstName, string memory _lastName) public onlyOwner onlyWhileOpen {
        people[peopleCount] = Person(peopleCount, _firstName, _lastName);
        incrementCount();
    }


    function incrementCount() internal {
        peopleCount ++;
    }



}