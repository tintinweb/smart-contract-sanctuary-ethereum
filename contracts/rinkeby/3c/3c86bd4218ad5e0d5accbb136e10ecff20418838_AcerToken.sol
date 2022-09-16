/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity ^0.4.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    // function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint amount) external returns (bool);

    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint amount
    // ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
}

contract AcerToken is IERC20 {
    address owner;

    uint256 totalSupply_;
    // mapping(address => mapping(address => uint)) public allowance;
    string public name = "NEXUS CRIPTO";
    string public symbol = "NEXUS";
    uint8 public decimals = 18;

    mapping(address => uint256) public balances;

    constructor() public {
        totalSupply_ = 1500;
        balances[msg.sender] = 1500;
    }

    using SafeMath for uint256;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function mint(uint256 amount) external {
        balances[msg.sender] += amount;
        totalSupply_ += amount;
        emit Mint(msg.sender, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        totalSupply_ -= amount;
        emit Burn(msg.sender, address(0), amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}