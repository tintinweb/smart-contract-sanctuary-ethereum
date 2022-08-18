/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract DaiToken {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 0;
    string public name = "DAI";
    string public symbol = "DAI";
    uint256 public decimal = 18;

    function mint(address to, uint256 value) public {
        balances[to] += value;
        totalSupply += value;
    }

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value, "not enought token");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
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

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}