/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

pragma solidity >= 0.7.0 <0.9.0;

contract rdxContract{
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

	event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address indexed owner,address indexed spender,uint value);

    uint public maxTotalSupply ;
    string public name = "RDX";
    string public symbol = "RDX";
    uint public decimal = 3;

    constructor(uint256 value) {
        balances[msg.sender] = value;
        maxTotalSupply = value;
    }

    function approve(address spender, uint value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function transfer(address to, uint value) public {
        require(balances[msg.sender] >= value, "not enought token");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) public {
        require(balanceOf(from) >= value, "not enought token");
        require(
            allowance[from][msg.sender] >= value,
            "not enought token allower"
        );
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

}