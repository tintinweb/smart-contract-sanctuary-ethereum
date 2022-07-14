/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

//SPDX-License-Identifier: MIT
//Day3

pragma solidity ^0.8.6;

contract Token{
    string public name;
    string public symbol;
    uint256 public Decimal;
    mapping (address => uint256) public Balance;
    mapping (address => mapping(address => uint256)) public SpendingAllowance; //My address => (spenderAddr => SpendingAmount)

    event TransferEvent(address indexed from, address indexed to, uint256 value);
    event AllowanceEvent(address indexed owner, address indexed spender, uint value);

    constructor(string memory _name, string memory _symbol, uint _Decimal){
        name = _name;
        symbol = _symbol;
        Decimal = _Decimal;
        uint256 TotalSupply = 1000000000000000000000000;
        Balance[msg.sender] = TotalSupply;  //giving myself all the supply hahahahaha!

    }

    //dummy transac function to check all the requirements and then call the main transaction function
    function dummytransfer(address _to, uint _value) external returns (bool){

        require(Balance[msg.sender] >= _value, "Insufficient funds to send ://"); //check my funds
        require(_to != address(0), "Invalid address"); //check receiver address
        Realtransfer(msg.sender,_to,_value); //call real transaction function
        return true; //return true
    }

    function Realtransfer(address owner, address receiver, uint amount) internal{
        Balance[owner] = Balance[owner] - amount; //deduct the amount from my(owner) balance
        Balance[receiver] = Balance[receiver] + amount; //add the amount to the receiver balance
        emit TransferEvent(owner,receiver,amount); //emit the Transfer Event
    }

    //Approve some tokens to the dapp's address [ex=> Uniswap]
    function Approve(address _spender, uint _value) external returns(bool){
        require(_spender != address(0), "Invalid Address");
        SpendingAllowance[msg.sender][_spender] = _value;
        emit AllowanceEvent(msg.sender,_spender,_value);
        return true;
    }

    //Allow the actual transfer for dapps
    //_from is basically dapp's address
    function AllowanceTransfer(address _from, address _to, uint amount) external returns(bool){
        require(Balance[_from] >= amount); //check if dapp got enough juice
        require(SpendingAllowance[_from][msg.sender] >= amount); //check if that much token spending is allowed
        SpendingAllowance[_from][msg.sender] = SpendingAllowance[_from][msg.sender] - amount; //deduct the dapp's balance
        Realtransfer(_from,_to,amount); //call the real transaction ;)
        return true;
    }



  
}