/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimal() external view returns (string memory);    //Max 18 decimals 
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external view returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

contract ERC20 {

    constructor(){
        balances[msg.sender] = tSupply; //Deployer has all the supply initially
    }
    string nameToken = "PoojaToken";
    string symbolToken = "Pooja";
    uint8 decimalToken = 2; // t = tSupply*10^(decimal token)
    uint256 tSupply = 1000*(10**decimalToken);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //Digital assets Tokens are created on top of one currency like etherum 
    // 1 rupee = 10 banana
    //Fungible = Interchangable: Easyliy exhangeble - ERC20 token
    //Non-Fungible = Not Interchangable: Not exhangeble - NFT

    function name() public view returns (string memory){
        return nameToken;
    }
    function symbol() public view returns (string memory){
        return symbolToken;
    }
    function decimals() public view returns (uint8){
        return decimalToken;
    }    //Max 18 decimals 
    function totalSupply() public view returns (uint256){
        return tSupply;
    } 
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    } 

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>=_value, "ERC20: Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    } 

    //First deploy from a account: Owner : check balance 1000
    //Now transfer to other acc 

    //ThirdParty
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>=_value, "ERC20: Insufficient balance");
        require(allowed[_from][msg.sender]>= _value, "ERC20: Not enough Allowance");   //Owner should not send 1 million token if he dont have that
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //Owner 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}