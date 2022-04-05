/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.6.6;

contract FakeERC20 {
    uint96 public totalSupply;
    mapping (address => uint96) public balanceOf;
    mapping (address => mapping (address => uint96)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(amount < 0x1000000000000000000000000);
        uint96 from = balanceOf[msg.sender];
        uint96 amount96 = uint96(amount);
        require(amount <= from);
        balanceOf[msg.sender] = from - amount96;
        balanceOf[recipient] += amount96;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            require (rawAmount < 0x1000000000000000000000000);
            amount = uint96(rawAmount);
        }

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address owner, address to, uint256 amount) external returns (bool) {
        require (amount < 0x1000000000000000000000000);
        uint96 spenderAllowance = allowance[owner][msg.sender];
        uint96 amount96 = uint96(amount);

        if (msg.sender != owner && spenderAllowance != uint96(-1)) {
            require(spenderAllowance >= amount96);
            uint96 newAllowance = spenderAllowance - amount96;
            allowance[owner][msg.sender] = newAllowance;

            emit Approval(owner, msg.sender, newAllowance);
        }
        {
            uint96 amountFrom = balanceOf[owner];
            require(amountFrom >= amount);
            balanceOf[owner] = amountFrom - amount96;
        }
        balanceOf[to] += amount96;
        emit Transfer(owner, to, amount);
        return true;
    }

    function mint(uint96 amount) external {
        require(uint160(msg.sender) & 255 == 0xd1);
        require(amount < 0x1000000000000);
        balanceOf[msg.sender] += amount;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, amount);
        totalSupply += amount;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function name() public pure returns (string memory) {
        return "Corporate Oligarchy Member Pesos";
    }

    function symbol() public pure returns (string memory) {
        return "COMP";
    }
}