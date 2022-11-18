/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface ERC20
{
    function totalSupply () external view returns(uint);
    function balanceOf(address $add) external view returns(uint);
    function allowance(address $owner , address $spender) external view returns(uint);

    function transfer(address $receiver , uint $amount) external returns(bool);
    function approve(address $spender , uint $amount) external returns(bool);
    function transferFrom(address $from , address $to , uint $amount) external returns(bool);

    event Transfer(address indexed $from , address indexed $to , uint indexed $amount);
    event Approval(address indexed $from , address indexed $to , uint indexed $amount);
}

contract urs is ERC20
{
    address $admin;
    string $name;
    string $symbol;
    uint8 $decimal;
    uint $_totalSupply;
    bool $Lock;

    modifier AllowCallFunction()
    {
        require(!$Lock , "you cant call this function");
        $Lock = true;
        _;
        $Lock = false;
    }

    mapping (address => uint) Balances;
    mapping (address => mapping(address => uint)) Allowed;

    constructor()
    {
        $admin = msg.sender;
        $name = "urs";
        $symbol = "URS";
        $decimal = 10;
        $_totalSupply = 1000000000000;
        Balances[$admin] = $_totalSupply;
    }

    function totalSupply() external override view returns(uint)
    {
        return $_totalSupply;
    }

    function balanceOf(address $add) external override view returns(uint)
    {
        return Balances[$add];
    }

    function approve(address $delegate , uint $amount) external override returns(bool)
    {
        Allowed[msg.sender][$delegate] = $amount;
        emit Approval(msg.sender , $delegate , $amount);
        return true;
    }

    function allowance(address $owner , address $delegate) external override view returns(uint)
    {
        uint $value;
        $value = Allowed[$owner][$delegate];
        return $value;
    }

    function transferFrom(address $from , address $to , uint $amount) external override AllowCallFunction returns(bool $success)
    {
        if(Balances[$from] >= $amount){
            if(Allowed[$from][msg.sender] >= $amount){
                Balances[$from] -= $amount;
                Balances[$to] += $amount;
                Allowed[$from][msg.sender] -= $amount;
                emit Transfer($from , $to , $amount);
                $success = true;
                return $success;
            }
        }else{
            revert("your balance is low");
        }
    }

    function transfer(address $to , uint $amount) external override AllowCallFunction returns(bool)
    {
        
        if(Balances[msg.sender] >= $amount){
            Balances[msg.sender] -= $amount;
            Balances[$to] += $amount;
            emit Transfer(msg.sender ,$to , $amount);
            return true;
        }else{
            revert("your balance is low");
        }
    }
}