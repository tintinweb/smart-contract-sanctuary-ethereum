// SPDX-License-Identifier: MIT
//Author: Mohak Malhotra
pragma solidity ^0.8.9;


//import "./chainlink/EthPrice.sol";

contract Vault {
    IERC20 public immutable DevUSDC;
    //EthPrice public ethPrice;
    address public owner;


    //Seconds in a year
    uint32 public immutable secYear = 31449600;

    uint public immutable ethPrice = 1234*1e18;

    struct StakeObj {
        uint stakedAmount;
        uint lastUpdatedTimeStamp;
        uint pendingRewards;
    }

    mapping (address => StakeObj) public userStakes; 

    // Total staked
    uint public totalSupply;

    event Received(address, uint);

    constructor( address _rewardToken) {
        owner = msg.sender;
        DevUSDC = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account, uint _amount, bool unstaked) {
        StakeObj memory userStake = userStakes[_account];
        uint previousStake = userStake.stakedAmount;
        uint timeDiff = block.timestamp - userStake.lastUpdatedTimeStamp;
        uint timeRatio = (timeDiff*1e18) / (secYear);
        if(unstaked == false){
            if(previousStake != 0){
                
                uint reward = ((timeRatio / 10) *  ethPrice * (previousStake/1e18))/1e18;
                //later
                userStakes[_account].pendingRewards += reward;
            } 
            userStakes[_account].stakedAmount += _amount;
        } else{
            uint reward = ((timeRatio / 10) *  ethPrice * (previousStake/1e18))/1e18;
            userStakes[_account].stakedAmount -= _amount;
        }
         userStakes[_account].lastUpdatedTimeStamp = block.timestamp;
        _;
    }

    function balanceOf(address _account) public view returns(uint){
        return userStakes[_account].stakedAmount;
    }

    function stake() external payable updateReward(msg.sender, msg.value, false) {
        require(msg.value > 0, "amount = 0");
        totalSupply += msg.value;
    }

    function unstake(uint _amount) external updateReward(msg.sender, _amount ,true) {
        require(_amount > 0, "amount = 0");
        totalSupply -= _amount;
        address payable receiver = payable(msg.sender);
        receiver.transfer(_amount);
    }
        receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function redeemRewards() external{
        require(userStakes[msg.sender].pendingRewards > 0, "You don't have any rewards to redeem");
        DevUSDC.transfer(msg.sender, userStakes[msg.sender].pendingRewards);
    }

    function redeemableRewards(address _account)  external view returns(uint){
        return userStakes[_account].pendingRewards;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}