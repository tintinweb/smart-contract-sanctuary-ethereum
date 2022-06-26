/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Test{
    uint256 public totalSupply = 0;
    address owner;
    string public name;
    string public symbol;
    uint8  public  decimals;
    address public staking;

    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed from, address indexed spender, uint256 value); 
    
    constructor() {
        owner = msg.sender;
        name = "TokenA";
        symbol = "A";
        decimals = 21;
    }

    function setStacking(address _staking) public {
        require(msg.sender == owner, "ERC20: You are not owner");
        staking = _staking;
    }

    function approve(address from, address spender, uint256 value) public returns(bool) {
        allowed[from][spender] = value;
        emit Approval(from, msg.sender, value);
        return true;
    }
    
    function allownce(address from, address spender) public view returns(uint256) {
        return allowed[from][spender];
    }

    function mint(address to, uint256 value) public {
        require((msg.sender == owner) || (msg.sender == staking), "ERC20: You are not owner");
        
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function transfer(address to, uint256 value) public returns(bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public {
        require(balances[from] >= value, "ERC20: not enough tokens");
        require(allownce(from, msg.sender) >= value, "ERC20: no permission to spend");
        balances[from] -= value;
        balances[to] += value;
        allowed[msg.sender][from] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[msg.sender][from]);
    }
    
    function balanceOf(address to) public view returns(uint256){
        return balances[to];
    }
}

interface IERC20 {
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external;
}

contract Staking {
    address public owner;
    address public LPTokenAdress;
    address public rewardTokenAddress;
    IERC20 public LPToken;
    IERC20 public rewardToken;
    uint256 public freezingTime;
    uint256 public percents;

    struct StakeStruct{

        uint256 tokenValue; // количество застейканых токенов
        
        uint256 timeStamp; // время создания стейка

        uint256 rewardPaid; // сумма уже выплаченной награды

    }

    mapping(address => StakeStruct) public stakes;

    event Stake(address from, uint256 timeStamp, uint256 value);
    event Claim(address to, uint256 value);
    event Unstake(address to, uint256 value);

    constructor(address _LPTokenAddress, address _rewardTokenAddress, uint256 _freezingTime, uint256 _percents){
        owner = msg.sender;
        LPTokenAdress = _LPTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        freezingTime = _freezingTime;
        percents = _percents;
    }

    function stake(uint256 value) public{
        require(stakes[msg.sender].timeStamp == 0, "You already have a stake");
        uint currentTime = block.timestamp;
        stakes[msg.sender].tokenValue += value;
        stakes[msg.sender].timeStamp = currentTime;
        LPToken.transferFrom(msg.sender, address(this), value);
        emit Stake(msg.sender, currentTime, value);
    }

    function claim() public{
        address sender = msg.sender;
        require(stakes[sender].timeStamp != 0, "Stake: You don't have a stake");
        require(block.timestamp > (stakes[sender].timeStamp + freezingTime), "Stake: freezing time has not yet passed");

        uint256 reward = (stakes[sender].tokenValue - (stakes[sender].rewardPaid * 100 / percents)) / 100 * percents;
        rewardToken.mint(sender, reward);
        stakes[sender].rewardPaid += reward;

        emit Claim(sender, reward);
    }

    function unstake() public{
        address sender = msg.sender;
        require(stakes[sender].timeStamp != 0, "Stake: You don't have a stake");
        require(block.timestamp > (stakes[sender].timeStamp + freezingTime), "Stake: freezing time has not yet passed");
        LPToken.transfer(sender, stakes[sender].tokenValue);
        stakes[sender].tokenValue = 0;
        stakes[sender].timeStamp = 0;
        stakes[sender].rewardPaid = 0;
        emit Unstake(sender, stakes[sender].tokenValue);
    }
}