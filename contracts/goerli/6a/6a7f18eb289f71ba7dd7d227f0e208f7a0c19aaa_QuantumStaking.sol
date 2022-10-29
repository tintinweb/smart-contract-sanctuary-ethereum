/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: CC-BY-SA 4.0 (@LogETH)

pragma solidity >=0.8.0 <0.9.0;

contract QuantumStaking {

    constructor () {

        rewardToken = ERC20(0xDA75FB2D30976d59Cf6D846a2Cd168EDcE0CeD84);
        LPtoken = ERC20(0x345aA09d037e7aE50254730F819b7D100D1E6a30);

        deployer = msg.sender;
    }

    ERC20 public LPtoken;
    ERC20 public rewardToken;
    address deployer;

    uint public lastTime;
    uint public yieldPerBlock;
    uint public endTime;
    bool public started;
    bool public ended;
    address[] list;
    mapping(address => bool) listed;
    mapping(address => uint) pendingReward;

    mapping(address => uint) stakedBalance;
    uint public totalStaked;


    modifier onlyDeployer{

        require(deployer == msg.sender, "Not deployer");
        _;
    }

    function StartContract(uint HowManyDays, uint HowManyTokens) onlyDeployer public {

        require(!started, "You have already started the staking system");

        endTime = HowManyDays * 86400 + block.timestamp;

        uint togive = HowManyTokens;

        rewardToken.transferFrom(msg.sender, address(this), HowManyTokens);

        yieldPerBlock = togive/(endTime - block.timestamp);

        lastTime = block.timestamp;
        started = true;
    }

    function sweep() public{

        require(msg.sender == deployer, "Not deployer");

        (bool sent,) = msg.sender.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    function claimReward() public {

        require(started, "The airdrop has not started yet");

        updateYield();

        rewardToken.transfer(msg.sender, pendingReward[msg.sender]);
        pendingReward[msg.sender] = 0;
    }

    function deposit(uint HowManyTokens) public {

        updateYield();

        rewardToken.transferFrom(msg.sender, address(this), HowManyTokens);

        if(!listed[msg.sender]){

            listed[msg.sender] = true;
            list.push(msg.sender);
        }
        stakedBalance[msg.sender] += HowManyTokens;
        totalStaked += HowManyTokens;
    }

    function withdraw(uint HowManyTokens) public {

        updateYield();

        require(HowManyTokens <= stakedBalance[msg.sender] || HowManyTokens == type(uint256).max, "You cannot withdraw more than your staked balance");

        if(HowManyTokens == 0 || HowManyTokens == type(uint256).max){

            HowManyTokens = stakedBalance[msg.sender];
        }

        LPtoken.transfer(msg.sender, HowManyTokens);

        stakedBalance[msg.sender] -= HowManyTokens;
        totalStaked -= HowManyTokens;

        
    }

    uint LTotal;
    uint period;

    function updateYield() public {

        if(!started || ended){return;}

        if(block.timestamp >= endTime){
            
            lastTime = endTime;
            ended = true;
        }

        LTotal = totalStaked;
        period = block.timestamp - lastTime;

        for(uint i; i < list.length; i++){

            pendingReward[list[i]] += ProcessReward(list[i]);
        }

        delete LTotal;
        delete period;
        lastTime = block.timestamp;
    }

    function ProcessReward(address who) internal view returns (uint reward) {

        uint percent = stakedBalance[who]*1e23/LTotal;

        reward = yieldPerBlock*period*percent/100000;
    }

    function ProcessRewardALT(address who) internal view returns (uint reward) {

        uint percent = stakedBalance[who]*1e23/totalStaked;

        reward = yieldPerBlock*(block.timestamp - lastTime)*percent/100000;
    }

    function GetReward(address who) public view returns(uint reward){

        if(lastTime == 0){return 0;}

        reward = ProcessRewardALT(who) + pendingReward[who];
    }

}


interface ERC20{
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns(uint8);
    function approve(address, uint) external returns(bool);
    function totalSupply() external view returns (uint256);
}