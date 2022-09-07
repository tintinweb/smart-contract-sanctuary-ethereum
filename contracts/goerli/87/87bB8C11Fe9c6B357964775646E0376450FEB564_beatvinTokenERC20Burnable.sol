// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
 import "./IERC20.sol";
contract beatvinTokenERC20Burnable is IERC20{
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "beatvinTokenBurnable";
    string public symbol = "BTTTB";
    uint8 public decimals = 18;
    uint256 private deploTimeStamp = block.timestamp + 1 minutes;

    constructor(){
        totalSupply = 15 ether;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier canBeBurned {
        require(block.timestamp >=deploTimeStamp);
        _;        
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external canBeBurned {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}