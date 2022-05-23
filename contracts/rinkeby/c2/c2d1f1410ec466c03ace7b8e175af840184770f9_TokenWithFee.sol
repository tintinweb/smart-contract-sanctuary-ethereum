/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: Pumpkin.sol


//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

//// What is this contract? 

//// This contract is an ERC20 token that has a fee module attached to it that only triggers on sells
//// The admin can change the fee or set it to zero and assign the "immume" role to addresses that makes them immune to the fee.
//// The admin is the person that deploys the contract, it cannot be changed once deployed.

//// Unlike traditional fee contracts, this contract broadcasts the fee and the sent amount in the transaction data.
//// The broadcast is supported by ethereum explorers like etherscan and makes accounting much easier.

//// Commissioned by spagetti#7777 on 3/19/2022

contract TokenWithFee {

//// Before you deploy the contract, make sure to change these parameters to what you want

    constructor () {

        balances[msg.sender] = 2000000*10**18;
        totalSupply = 2000000*10**18;
        name = "LOG token";
        decimals = 18;
        symbol = "LOG";
        FeePercent = 5;

        // SpookySwap = ???????????????????????????;

        admin = msg.sender;
        ImmuneFromFee[address(this)] = true;
        ImmuneFromFee[msg.sender] = true;
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;
    uint public FeePercent;
    mapping(address => bool) ImmuneFromFee;
    address public admin;
    address public SpookySwap;

    function EditDEX(address DEX) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button!");

        SpookySwap = DEX; 
    }

    function EditFee(uint Fee) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button!");
        require(Fee <= 100, "You cannot make the fee higher than 100%");
        FeePercent = Fee;
    }

    function ExcludeFromFee(address Who) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button!");

        ImmuneFromFee[Who] = true;
    }

    function IncludeFromFee(address Who) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button!");

        ImmuneFromFee[Who] = false;
    }

    function ProcessFee(uint _value, address _payee) internal returns (uint){

        uint fee = FeePercent*(_value/100);
        _value -= fee;

        balances[_payee] -= fee;
        balances[admin] += fee;
        emit Transfer(_payee, admin, fee);
        return _value;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balances[msg.sender] >= _value, "You can't send more tokens than you have");

        if(_to == SpookySwap && ImmuneFromFee[msg.sender] != true){_value = ProcessFee(_value, msg.sender);}

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        if(_to == SpookySwap && ImmuneFromFee[msg.sender] != true){_value = ProcessFee(_value, _from);}

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