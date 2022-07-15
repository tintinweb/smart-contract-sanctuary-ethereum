/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
interface  IERC20{
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}
contract Super_Staking{
    //адрес хозяина контракта
    address public owner;

    //адрес LP токена
    address public LPTokenAdress;

    //адрес токена, в котором будет выдаваться награда
    address public rewardTokenAddress;

    //интерфейс к LP токену
    IERC20 public LPToken;

    //интерфейс к токену, в котором будет выдаваться награда
    IERC20 public rewardToken;

    /*время заморозки в секундах. Пользователь не может вывести LPToken пока не пройдёт  freezingTime секунд с момента внесения им стейка. 
    Кроме того, пока стейк находится на контракте каждые  freezingTime  секунд пользователь может выводить награду на свой адрес в токенах rewardToken. 
    Размер награды зависит от размера стейка и percents*/
    uint256 public freezingTime;

    //процент вознаграждения. Пользователь, внёсший стейк получает награду в rewardToken, равную проценту percents от количества внесённых им LPToken каждые freezingTime
    uint256 public percents;

    //Структура стейкинга - каждый стейк сохраняется в такой структуре
    struct StakeStruct{
        uint256 tokenValue; // количество застейканых токенов
        uint256 timeStamp; // время создания стейка
        uint256 rewardPaid; // сумма уже выплаченной награды
    }

    //словарь стейков - у каждого пользователя по его адресу хранится свой стейк
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
        LPToken = IERC20(_LPTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function stake(uint256 value) external{
        require(stakes[msg.sender].tokenValue == 0, 
        "You already have a stake");
        LPToken.transferFrom(msg.sender, address(this), value);
        stakes[msg.sender].tokenValue = value;
        stakes[msg.sender].timeStamp = block.timestamp;
        stakes[msg.sender].rewardPaid = 0;
        emit Stake(msg.sender, stakes[msg.sender].timeStamp, value);
    }

    function claim() external{
        require(stakes[msg.sender].tokenValue > 0, 
        "Stake: You don't have a stake");
        require(block.timestamp - freezingTime >= stakes[msg.sender].timeStamp, 
        "Stake: freezing time has not yet passed");
        stakes[msg.sender].timeStamp = block.timestamp;
        uint256 reward = stakes[msg.sender].tokenValue * percents / 100;
        require(reward > 0, 
        "Stake: you have no reward available for withdrawal");
        rewardToken.mint(msg.sender, reward);
        stakes[msg.sender].rewardPaid += reward;
        emit Claim(msg.sender, reward);
    }

    function unstake() external{
        require(stakes[msg.sender].tokenValue > 0, 
        "Stake: You don't have a stake");
        require(block.timestamp - freezingTime >= stakes[msg.sender].timeStamp, 
        "Stake: freezing time has not yet passed");
        LPToken.transfer(msg.sender, stakes[msg.sender].tokenValue);
        uint256 value = stakes[msg.sender].tokenValue;
        stakes[msg.sender].tokenValue = 0;
        emit Unstake(msg.sender, value);
    }
}