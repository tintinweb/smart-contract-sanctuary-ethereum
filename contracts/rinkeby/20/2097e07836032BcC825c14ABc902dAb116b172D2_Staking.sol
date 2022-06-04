//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IERC20{
    function mint(address, uint256) external;
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

import "./IDAO.sol";

contract Staking {

    IDAO dao;

    address public owner;
    address public stakeTokenAddress;
    address public rewardTokenAddress;
    uint256 public freezingTime;
    uint256 public percents;

    struct StakeStruct{
        uint256 tokenAmount;
        uint256 timeStamp;
        uint256 rewardPaid;
    }

    mapping(address => StakeStruct) public stakes;

    event Stake(address indexed, uint, uint);
    event Claim(address indexed, uint);
    event Unstake(address indexed, uint);

    modifier checker() {
        require(stakes[msg.sender].tokenAmount > 0, "You don't have a stake");
        require(stakes[msg.sender].timeStamp + freezingTime < block.timestamp, "freezing time has not yet passed");
        _;
    }

    constructor(
        address _stakeTokenAddress,
        address _rewardTokenAddress,
        address _daoAdderss,
        uint256 _freezingTime,
        uint256 _percents
    ) 
    {
        owner = msg.sender;
        dao = IDAO(_daoAdderss);
        stakeTokenAddress = _stakeTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        freezingTime = _freezingTime;
        percents = _percents;
    }

    function stake(uint256 _amount) external {
        IERC20(stakeTokenAddress).transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender] = StakeStruct(_amount, block.timestamp, 0);
        emit Stake(msg.sender, block.timestamp, _amount);
    }

    function claim() external checker {
        // рассчитываем размер награды 
        uint256 rewardCount = (block.timestamp - stakes[msg.sender].timeStamp) / freezingTime;
        uint256 reward = (stakes[msg.sender].tokenAmount / 100 * percents) * rewardCount - stakes[msg.sender].rewardPaid;
        require(reward != 0, "You have no reward available for withdrawal");
        // отправляем награду на адрес
        IERC20(rewardTokenAddress).mint(msg.sender, reward);
        stakes[msg.sender].rewardPaid += reward;
        emit Claim(msg.sender, reward);
    }

    function unstake() external checker {
        deposit memory _deposit = dao.getDeposit(msg.sender);
        require(block.timestamp > _deposit.unFrozentime, "Tokens are still frozen in the DAO contract");
        IERC20(stakeTokenAddress).transfer(msg.sender, stakes[msg.sender].tokenAmount);
        emit Unstake(msg.sender, stakes[msg.sender].tokenAmount);
        stakes[msg.sender].tokenAmount = 0;
    }

    function setFreezingTime(uint256 _freezingTime) public {
        require(msg.sender == address(dao), "You are not DAO");
        freezingTime = _freezingTime;
    }

    function getStakes(address _adr) public view returns(StakeStruct memory){
        return stakes[_adr];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

struct deposit{
    uint256 frozenToken;
    uint256 unFrozentime;
}

interface IDAO{

    function getDeposit(address) external view returns(deposit memory);
}