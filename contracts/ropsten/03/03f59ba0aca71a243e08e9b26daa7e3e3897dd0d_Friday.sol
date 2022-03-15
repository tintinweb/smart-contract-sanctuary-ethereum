/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6; // version of compiler

/* FRIDAY token */


/* ERS-20 Token Standard */

// Abstract Contract - not executed, at least one function without any implementation. 
// Such a contract is used as a base contract. Generally an abstract contract contains both implemented as well as abstract functions.

abstract contract ERC20Token {
    function name() virtual public view returns (string memory); // tells the name of the token
    function symbol() virtual public view returns (string memory); // tels the symbol of the token
    function decimals() virtual public view returns (uint8); // tells how many decimal points the token is denominated to
    function totalSupply() virtual public view returns (uint256); // how many total token are there in circulation
    function balanceOf(address _owner) virtual public view returns (uint256 balance); // takes address given by owner and tells how many tokens owner has
    function transfer(address _to, uint256 _value) virtual public returns (bool success); // allos to transfer specific value of token to the adress given by _to
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success); // transfer from third party to somebody given value
    function approve(address _spender, uint256 _value) virtual public returns (bool success); // approve spending from somebody's account
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining); // governs how much money you can take from the owners account and give it to the spender

// Events - mark something that should be recorded on the blockchain
    event Transfer(address indexed _from, address indexed _to, uint256 _value); // Transfer money
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); // Owner allowed spend tokens from spender
}

// executed 
// What is means for token to be owned?

contract Owned {
    address public owner; // keep track of the initial Owner 
    address public newOwner; // and potential new owner

// OwnershipTransferred event - mark a change in ownership
// _indexed - for logged events will allow to search for these events using the indexed parameters as filters. 
    event OwnershipTransferred(address indexed _from, address indexed _to);

    // constructor - to create an instance of this contract, instance that is called whenever we create a contract Owned
    constructor() {
        owner = msg.sender; // owner of the contract is whoever is calling it
    }
// transferOwnership(address _to) Function to be able to transfer ownership
    function transferOwnership(address _to) public {
        require(msg.sender == owner); // condition: make sure whoever is transferring is the owner
        newOwner = _to;
    }
// acceptOwnership() Function to accept ownership, whoever ownership is transferred to has to agree to accept it

    function acceptOwnership() public {
        // person calling the contract has to be the new ownership
        require(msg.sender == newOwner); // only the new oner can accept
        emit OwnershipTransferred(owner, newOwner); // once the function is called, emit the ownership transfer event from owner to new owner. 

// Emit keyword is used to emit an event in solidity, which can be read by the client in Dapp. 
// Event in solidity is to used to log the transactions happening in the blockchain.

        owner = newOwner; // formally change the even of the ownership to new owner
        newOwner = address(0); // no newOwner anymore, assign garbage address (0) to newOwner
    }
}

// Friday (Token) contract is also a type contract of ERS20Token and Owned
// In addition to what is defined in this contract, get the functionality of everything defined above
// Inheritance
// Because Friday Token is ERS20 Token, which is abstract, we have to define how all of the ERS20 functions work in Friday token

contract Friday is ERC20Token, Owned {
    // key parameters of token
    string public _symbol; // symbol of token
    string public _name;
    uint8 public _decimal; // denominating in 
    uint public _totalSupply;
    // Minter - central authority that will be allowed to mint new coins & distribute them & move from circulation if want
    address public _minter; // designate address that is allowed to mint new currecny 

    // balances - mapping from addresses to integers
    // mapping - table where each address gets mapped to how much currency it owns
    // keep track of al transactions going on 
    // mappings values - represented by the hash of their keys

    mapping(address => uint) balances;
    // address: ...
    // balance: ...

    // contructor for tokens 
    // constructor in Solidity is a special function that is used to initialize state variables in a contract. 
    // called when an contract is first created and can be used to set initial values (for us, initialize values of Friday token).

    constructor () {
        _symbol = "FRD";
        _name = "Friday";
        _decimal = 0;
        _totalSupply = 100;
        _minter = 0xFfc019F997ca6a86CCf6F15F0E96e4982Be2f22c; // address to which all initial currency will be send 

    // giving all initial supply to winter, who can distribute it 
        balances[_minter] = _totalSupply;
    // Since there was a transfer of currency, make a record of in the blockchain through a transfer event
    // address zero - void to the minter, transfered amount - total amount
        emit Transfer(address(0), _minter, _totalSupply);
    }

    // Implement functions from ERS20 Token section that we declared, but never implemented 
    // modifiers:
    // public - scope
    // view - tells us state of the situate, no modify of vars
    // returns  
    // override definition of functions

    function name() public override view returns (string memory) {
        return _name; // now name has a proper definition -> return name of the currency
    }
    // do the same for other functions
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimal;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    // looks inside the balances mapping and asks how much the address owner has associated w/ it
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner]; 
    }

    // more complicated functions
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value); // require that _from has enough money to send
        balances[_from] -= _value; // if true her balance goes down by vaue sent
        balances[_to] += _value; // increase balance of who is receiving
        emit Transfer(_from, _to, _value); // Since transfer of currency, emit it to blockchain
        return true; //return True if the transfer was successful for Token standard
    }

    // transfer - specific instance of transferFrom, just transfered from whoever is calling the contract
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        return transferFrom(msg.sender, _to, _value);
    }
    // approve somebody else to spend value from my account -> don't want
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    } 
    // allow 3rd parties being spend money from other people's wallets -> don't want
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    } 

    // Mint() Function 
    // Mint - publishing a unique instance of ERC-20 token on the blockchain
    // enject new currency
    function mint(uint amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }

    // remove new currency by force
    function confiscate(address target, uint amount) public returns (bool) {
        require(msg.sender == _minter);

        if (balances[target] >= amount) {
            balances[target] -= amount;
            _totalSupply -= amount;
        } else {
            // no negative balances, so if not enough money, just get everything that person has
            _totalSupply -= balances[target];
            balances[target] = 0;
        }
        return true;
    }



}