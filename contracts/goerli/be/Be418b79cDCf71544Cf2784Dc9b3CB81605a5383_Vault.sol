// SPDX-License-Identifier: MIT
//Author: Mohak Malhotra
pragma solidity ^0.8.9;


//import "./chainlink/EthPrice.sol";

contract Vault {
    IERC20 public immutable DevUSDC;

    address payable public immutable cEthAddr;

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
    event MyLog(string, uint256);

    constructor( address _rewardToken, address payable _cEthContract) {
        owner = msg.sender;
        DevUSDC = IERC20(_rewardToken);
        cEthAddr = _cEthContract;
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
            userStakes[_account].pendingRewards += reward;
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
        supplyEthToCompound(msg.value);
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
        require(userStakes[msg.sender].stakedAmount == 0, "You can't redeem rewards before unstaking all your stake");
        DevUSDC.transfer(msg.sender, userStakes[msg.sender].pendingRewards);
        userStakes[msg.sender].pendingRewards = 0;
    }

    function redeemableRewards(address _account)  external view returns(uint){
        return userStakes[_account].pendingRewards;
    }

        function supplyEthToCompound(uint _amount)
        internal
        returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(cEthAddr);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        cToken.mint{ value: _amount, gas: 250000 }();
        return true;
    }

     function redeemCEth(
        uint256 amount,
        bool redeemType
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(cEthAddr);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
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

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}