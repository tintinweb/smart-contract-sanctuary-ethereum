/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract brDAI {

////                           Variables that this contract uses

//   Having public in your variable is the same thing as a read function that displays that variable btw.
    
    address public brBOI; // address of the other contract - the one with the public BRRRRR function
    address charity; // address to be used to send money to a charity wallet
    address brDAIAddy; // address of the ERC20 contract
    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;
    address public Owner;
    ERC20 DAI;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Withdrawal(address indexed token, uint256 indexed amount, address indexed to);
    event IForgotWhyThisExists(ERC20 indexed token, uint256 indexed amount, address indexed to);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


////                   The big contructor, change these to what you want

    constructor() { 

        brBOI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // "random" address, simply defining it rn
        charity = address(this); //We will change this address to an actual charities address
        brDAIAddy = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // "random" address
        Owner = msg.sender;
        //Use the DAI ERC20 Address
        //Currently using: Rinkeby DAI
        DAI = ERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
        
        //Our token information 
        name = "brrrDAI";
        decimals = 18;
        symbol = "brDAI";
    }

////                      Visible functions that this contract uses

    //Bro no cap, dont let this address be accessable by anyone but the inherited contract
    //Also this can mint indefinite brDAI tokens with no cap, no cap.
   //Write function to forcefeed people into sending DAI to mint brrrrDai
   //Don't need a require statement because this contract will only ever transfer DAI
    function brrrDAI(uint256 amount) public {
        //transfer a token, to the charity address, with the called amount
        //write some code to make this token have to be DAI - Nah fuck that bro
         
        //safeTransferFrom....sender....receiver...amount
        //DAI is old, dont use safeTranserFrom
         DAI.transferFrom(msg.sender, charity, amount);
          
          //mint some nice juicy BRRRRRRRRR BRRRRRRRRTTTTTAATATAT BRRRRRRR for the msg.sender
          //Use the interface to run the brDAI function on the specified address. 
          //msg.sender is the receiver of the _brDAI function. amount they receive is the amount they put in
          mint(msg.sender, amount);
          
         //I dont remember why emits are important but all IERC20 Safetransfer examples include it.
         //Nevermind: this is an event emiting what token was BRRRRRATATATA'ed, how much of it and who BRRRRRSRRARARARARA
         //RRARATATATATATAT
        emit IForgotWhyThisExists (DAI, amount, msg.sender);
    }

//// THe openzepplin thingy but its inside this contract, don't mess with these functions pls
////Putting all of the OpenZepplin ERC20 functions inside the contract so we don't need to inherit from OpenZepplin imports


    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balances[msg.sender] >= _value, "You can't send more tokens than you have");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) internal returns (bool success) {
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {

        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {

        return allowed[_owner][_spender];
    }
    
}

// Contracts that this contract uses, contractception!
//Interface with the ERC20 safeTransferFrom Function; only ERC20 interface I need for this contract
interface ERC20{
    function transferFrom(address, address, uint256) external;
}