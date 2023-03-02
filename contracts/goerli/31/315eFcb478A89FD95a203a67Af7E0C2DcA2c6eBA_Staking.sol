/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.7.5;

interface ERC {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Math {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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

 
contract Staking is Math {
    ERC public smartContract;
    address public admin;

    modifier isAdmin(){
        require(msg.sender == admin,"Access Error");
        _;
    }

    constructor(){
        admin = msg.sender;
    }
    
    struct User {
        uint256 currentStake;
        uint256 rewardsClaimed;
        uint256 time;
        bool active;
    }

    mapping(address => mapping(address => User)) public users;
    mapping(address => uint256) public rFactor;
    mapping(address => uint256) public lockTime;
    
    function stake(uint256 _stakeAmount,address _contractAddress) public returns(bool){
        smartContract = ERC(_contractAddress);
        require(smartContract.allowance(msg.sender,address(this))>=_stakeAmount,"Allowance Exceeded");
        User storage u = users[msg.sender][_contractAddress];
        require(u.currentStake == 0,"Already Staked");
        u.currentStake = _stakeAmount;
        u.time = block.timestamp;
        u.active = true;
        smartContract.transferFrom(msg.sender,address(this),_stakeAmount);
        return true;
    }
    
    function claim(address _contractAddress) public returns(bool){
        smartContract = ERC(_contractAddress);
        User storage u = users[msg.sender][_contractAddress];
        require(u.active == true,"Invalid User");
        require(Math.add(u.time,lockTime[_contractAddress]) < block.timestamp,"Not Matured Yet");
        uint256 a = Math.sub(block.timestamp,u.time);
        uint256 b = Math.mul(u.currentStake,a);
        uint256 c = Math.mul(b,rFactor[_contractAddress]);
        uint256 d = Math.div(c,10**20);
        uint256 transferAmount = Math.add(u.currentStake,d);
        u.rewardsClaimed = Math.add(u.rewardsClaimed,d);
        u.currentStake = 0;
        smartContract.transfer(msg.sender,transferAmount);
        return true;
    }
    
    function fetchUnclaimed(address _contractAddress) public view returns(uint256 claimableAmount){
        User storage u = users[msg.sender][_contractAddress];
        require(u.active == true,"Invalid User");
        require(u.currentStake > 0,"No Stake");
        uint256 a = Math.sub(block.timestamp,u.time);
        uint256 b = Math.mul(u.currentStake,a);
        uint256 c = Math.mul(b,rFactor[_contractAddress]);
        uint256 d = Math.div(c,10**20);
        return(d);
    }
    
    function updateReward(address _contractAddress,uint256 _rFactor) public isAdmin returns(bool){
        rFactor[_contractAddress] = _rFactor;
        return true;
    }
    
    function updateLockTime(address _contractAddress,uint256 _newTime) public isAdmin returns(bool){
        lockTime[_contractAddress] = _newTime;
        return true;
    }

    // For Testing  Purpose only
    function emergencyDrain(address _contractAddress) public isAdmin returns(bool){
        smartContract = ERC(_contractAddress);
        uint256 b = smartContract.balanceOf(address(this));
        smartContract.transfer(admin,b);
        return true;
    }
}