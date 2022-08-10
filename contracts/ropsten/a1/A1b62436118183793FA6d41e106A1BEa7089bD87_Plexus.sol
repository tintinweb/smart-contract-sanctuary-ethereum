// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

contract Plexus {
    using SafeMath for uint256;

    // ======== ERC20 =========
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed holder, address indexed spender, uint256 amount);

    string public constant name = "Plexus";
    string public constant symbol = "PLX";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ======== Construction & Init ========
    address public owner;

    bool public entered;

    constructor() public {
        owner = msg.sender;

        uint256 initSupply = 500000000 * 1e18;
        totalSupply = totalSupply.add(initSupply);
        balanceOf[msg.sender] = initSupply;

        emit Transfer(address(0), msg.sender, initSupply);
    }

    modifier nonReentrant() {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    // ======== ERC20 =========
    function transfer(address _to, uint256 _value) public returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function burn(uint256 amount) public {
        address user = msg.sender;
        require(balanceOf[user] >= amount);

        balanceOf[user] = balanceOf[user].sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(user, address(0), amount);
    }

    function _mint(uint256 amount, address to) internal {
        require(to != address(0));

        totalSupply = totalSupply.add(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        emit Transfer(address(0), to, amount);
    }

    function mint(uint256 amount, address to) public {
        require(msg.sender == owner);

        _mint(amount, to);
    }
}