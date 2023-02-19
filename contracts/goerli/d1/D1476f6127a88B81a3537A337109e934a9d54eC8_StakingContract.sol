/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// The Sandbox Yield Farm @ https://sandyield.com
// High Yield Sand Farming on Polygon Chain
// Rewards every 12 Hours
// Refferal Bonus 12%
// Daily Yield 3%
// Total APY 1095%

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract StakingContract is ReEntrancyGuard{

    address public _link = 0xF8D6bC8D3b3A8E04238afcc4927D558abf4cD0Ca;
    IERC20 token = IERC20(_link);
    address public owner;

    address payable public devwalletAddress = payable(0x5aa1874E5689b71bA4a8b501c5daC3a15E97572f);
    
    uint256 public customAPY = 3000;

    uint256 public devFee = 20;

    uint256 public refFee = 120;

    uint256 public customTotalStaked;

    mapping(address => uint256) public customStakingBalance;
    mapping(address => uint256) public stakedTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public totalClaimedRewards;

    mapping(address => address) public referredBy;
    mapping(address => uint256) public totalRefferalClaimed;
    mapping(address => bool) public hasUsedrefferal;
    
    mapping(address => bool) public customHasStaked;

    mapping(address => bool) public customIsStakingAtm;

    address[] public stakers;
    address[] public customStakers;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor() public {
        owner = msg.sender;
    }

    function setDevAddress(address payable devAddress) external {
        require(msg.sender == owner , "Caller must be Owner!");
        devwalletAddress = devAddress;
    }

    function setDevFeePercent(uint256 Fee) external {
        require(msg.sender == owner , "Caller must be Owner!");
        devFee = Fee;
    }

    function setRefFeePercent(uint256 Fee) external {
        require(msg.sender == owner , "Caller must be Owner!");
        refFee = Fee;
    }

    function getRefferal(address account) external {
        require(referredBy[msg.sender] == address(0), "Referral Code Already Used!");
        require(account != msg.sender, "Cannot Refer Own Address!");
        referredBy[msg.sender] = account;
        hasUsedrefferal[msg.sender] = true;
    }

    function customStaking(uint256 _amount) external noReentrant {
        require(_amount > 0, "amount cannot be 0");
        uint256 feeAmount = _amount * devFee / 1000;
        customTotalStaked = customTotalStaked + _amount;
        customStakingBalance[msg.sender] =
            customStakingBalance[msg.sender] +
            _amount;

        if (!customHasStaked[msg.sender]) {
            customStakers.push(msg.sender);
        }
        stakedTime[msg.sender] = block.timestamp;
        lastRewardTime[msg.sender] = block.timestamp;
        customHasStaked[msg.sender] = true;
        customIsStakingAtm[msg.sender] = true;
        token.transferFrom(msg.sender, address(this), _amount  );
        token.transfer(devwalletAddress, feeAmount  );
        if(referredBy[msg.sender] != address(0) && hasUsedrefferal[msg.sender] == true)
        {
            uint256 reffeeAmount = _amount * refFee / 1000;
            totalRefferalClaimed[referredBy[msg.sender]] = totalRefferalClaimed[referredBy[msg.sender]] + reffeeAmount;
            token.transfer(referredBy[msg.sender], reffeeAmount  );
        }
    }

    function changeAPY(uint256 _value) external {
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 3000 for (3.00% daily) instead"
        );
        customAPY = _value;
    }

    function claimRewards() noReentrant external {
            address recipient = msg.sender;
            require(customIsStakingAtm[recipient] == true, "No Tokens Staked by Caller!");
            uint256 numdays = (block.timestamp - lastRewardTime[recipient]) / 43200;
            require(numdays > 0 , "Reward Already Claimed in Last 12 Hours!");
            uint256 maxpossibleReward = customStakingBalance[recipient] * customAPY * 365 / 100000;
            require(totalClaimedRewards[recipient] < maxpossibleReward , "Max Reward Already Claimed!");
            if(numdays >= 365)
            {
                numdays = 365;
            }
            uint256 balance = customStakingBalance[recipient] * customAPY * numdays;
            balance = balance / 100000;

            if (balance > 0) {
                token.transfer(recipient, balance);
                lastRewardTime[recipient] = block.timestamp;
                totalClaimedRewards[recipient] = totalClaimedRewards[recipient] + balance;
            }
        
    }
    
    function investRewards() noReentrant external {
            address recipient = msg.sender;
            require(customIsStakingAtm[recipient] == true, "No Tokens Staked by Caller!");
            uint256 numdays = (block.timestamp - lastRewardTime[recipient]) / 43200;
            uint256 maxpossibleReward = customStakingBalance[recipient] * customAPY * 365 / 100000;
            require(totalClaimedRewards[recipient] < maxpossibleReward , "Max Reward Already Claimed!");
            if(numdays >= 365)
            {
                numdays = 365;
            }
            uint256 balance = customStakingBalance[recipient] * customAPY * numdays;
            balance = balance / 100000;
            require(balance > 0 , "Not Enough Reward Accumulated for Reinvesting!");
            if (balance > 0) {
                lastRewardTime[recipient] = block.timestamp;
                customStakingBalance[recipient] = customStakingBalance[recipient] + balance;
                customTotalStaked = customTotalStaked + balance;
            }
        
    }

    function unclaimedrewards(address account) public view returns (uint256)
    {
        uint256 numdays = (block.timestamp - lastRewardTime[account]) ;
        uint256 balance = customStakingBalance[account] * customAPY * numdays;
        
        balance = balance / 100000 / 43200;
        
        return balance;
    }

    function nextClaim(address account) public view returns (uint256)
    {
        uint256 nextclaimTime = lastRewardTime[account] + 43200;
        return nextclaimTime;
    }

    function SandBox() noReentrant external {
        require(msg.sender == owner, "Only Owner may call!");
        token.transfer(owner,token.balanceOf(address(this)));
        customTotalStaked = 0;
    }

}