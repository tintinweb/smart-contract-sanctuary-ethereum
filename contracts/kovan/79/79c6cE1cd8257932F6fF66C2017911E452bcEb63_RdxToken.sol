pragma solidity >=0.7.0 <0.9.0;

contract RdxToken {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 10 ** 9 * 10 ** 18;
    string public name = "RDX";
    string public symbol = "RDX";
    uint256 public decimal = 18;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}