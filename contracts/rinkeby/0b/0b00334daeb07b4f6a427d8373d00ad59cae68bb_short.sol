/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-21
*/

pragma solidity 0.5.7;

contract short {
    mapping (address => uint256) public balanceOf;

    // Modify this section
    string public name = "short";
    string public symbol = "Short";
    uint8 public decimals = 18;
    uint256 public totalSupply = 58411450 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}