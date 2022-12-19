// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint);

    function exchangeRateStored() external returns (uint);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOf(address owner) external view returns (uint);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

// SPDX-License-Identifier: MIT
//Author: Mohak Malhotra
pragma solidity ^0.8.9;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CEth} from "./interfaces/ICEth.sol";
import {IERC20} from "./interfaces/IERC20.sol";
 
/**
 * @title Staking Vault for Compound
 * @notice A custom vault which allows users to stake eth which is then used as collateral on compound.
 * @notice Users can stake multiple times but they can only redeem rewards after unstaking. Reward rate is in DevUSDC @ a constant 10%p.a.
 * @author Mohak Malhotra
 */
contract Vault {

    // VARIABLES & CONSTANTS
    IERC20 public immutable devUSDC;
    address public immutable cEthAddr;
    uint32 public immutable secYear = 31449600;
    uint8 public immutable rewardrate = 10;
    AggregatorV3Interface internal priceFeed;
    address public owner;
    uint public vaultReserves;
    uint public totalSupply;

    
    struct StakeObj {
        uint stakedAmount;
        uint lastUpdatedTimeStamp;
        uint pendingRewards;
        uint cEthBalance;
    }
    mapping (address => StakeObj) public userStakes; 

    //EVENTS
    event Received(address, uint);
    event MyLog(string, uint256);


     /**
     * @notice Sender supplies assets into the market and receives oTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _rewardToken The amount of the underlying asset to supply
     * @param _cEthContract the contract address of cEth Ctoken
     */
    constructor( address _rewardToken, address  _cEthContract) {
        owner = msg.sender;
        devUSDC = IERC20(_rewardToken);
        cEthAddr = _cEthContract;
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }


    /**
     * @notice Only owner modifier ensuring access control
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    /**
     * @notice Modifier that updates the reward and timestamp based on staking/unstaking
     * @dev 18 decimal points have been used for standardisation. ERC reward token is also 18 decimals
     * @param _account The amount of stake/unstake amount 
     */
    modifier updateReward(address _account) {
        StakeObj memory userStake = userStakes[_account];
        uint previousStake = userStake.stakedAmount;
        if(previousStake != 0){ 
        uint timeDiff = block.timestamp - userStake.lastUpdatedTimeStamp;
        uint timeRatio = (timeDiff*1e18) / (secYear);
        uint currEthPrice = uint(getPrice());
        uint reward = ((timeRatio / rewardrate) *  currEthPrice * (previousStake/1e18))/1e18;
        userStakes[_account].pendingRewards += reward;
            } 
        userStakes[_account].lastUpdatedTimeStamp = block.timestamp;
        _;
    }

        /**
     * @notice Sender supplies assets into the market and receives oTokens in exchange
     * @dev Chainlink V3 Aggregator interface is being used. The result is in 
     * @return price which is the current price of ehtereum in USD * 10^8
     */
    function getPrice() public view returns (int){
        ( , int price, , ,) = priceFeed.latestRoundData();
        require(price > 0, "Incorrect price");
        return price;
    }

        /**
     * @notice Retrieves staking balance of an account
     * @param _account The account for which the balance needs to be checked
     */
    function balanceOf(address _account) public view returns(uint){
        return userStakes[_account].stakedAmount;
    }

        /**
     * @notice Sender supplies ether to be staked in this contract which then gets supplied to compound as collateral
     * @dev Modifier updateReward allows multiple stakes at different points in time. Minimum 5 eth needs to be staked at a time
     */
    function stake() external payable updateReward(msg.sender) {
        require(msg.value >= 0.1*1e18, "Please stake 5 or more eth");
        totalSupply += msg.value;
        userStakes[msg.sender].stakedAmount += msg.value;
        supplyEthToCompound(msg.value, msg.sender);
        
    }

    /**
     * @notice The user executes this function to unstake their funds at any point, there is no lock up time.
     * @dev Collateral on Compound in CETH is also redeemed back to ether and sent to the user. THe yield from compound stays in the contract
     */
    function unstake() external updateReward(msg.sender) {
        uint stakedAmount = userStakes[msg.sender].stakedAmount;
        require(stakedAmount > 0, "You haven't staked any ether");
        uint returnedAmount = redeemCEth(userStakes[msg.sender].cEthBalance);
        vaultReserves += returnedAmount - stakedAmount;
        totalSupply -= stakedAmount;
        address payable receiver = payable(msg.sender);
        receiver.transfer(stakedAmount);
        userStakes[msg.sender].stakedAmount = 0;
        userStakes[msg.sender].cEthBalance = 0;
    }



    /**
     * @notice Once the user has unstaked their funds, they can then withdraw their DevUSDC rewards
     */
    function redeemRewards() external{
        require(userStakes[msg.sender].pendingRewards > 0, "You don't have any rewards to redeem");
        require(userStakes[msg.sender].cEthBalance == 0, "You can't redeem rewards before unstaking all your stake");
        devUSDC.transfer(msg.sender, userStakes[msg.sender].pendingRewards);
        userStakes[msg.sender].pendingRewards = 0;
    }

    /**
     * @notice Check redeemable rewards for user
     * @param _account address of the target account
     * @return redeemable rewards
     */
    function redeemableRewards(address _account )  external view returns(uint){
        return userStakes[_account].pendingRewards;
    }


    /**
     * @notice Sender supplies assets into the market and receives oTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _amount Amount of eth to be put as collateral
     * @param _account address of the user account
     */
    function supplyEthToCompound(uint _amount, address _account) internal returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(cEthAddr);
        uint initialBalance = cToken.balanceOf(address(this));
        cToken.mint{ value: _amount, gas: 250000 }();
        uint newBalance = cToken.balanceOf(address(this));
        userStakes[_account].cEthBalance += newBalance - initialBalance;
        return true;
    }

    /**
     * @notice When unstaking first the CEth needs to be redeemed for eth
     * @dev Exchange rate is calculated and then Ceth is compared with the eth staked. The difference is the yield
     * @param _amount The amount of cEth to be redeemed for ether(wei)
     * @return returnedAmount The amount received back from Compound
     */
     function redeemCEth(
        uint256 _amount
    ) public returns ( uint) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(cEthAddr);

        uint256 exchangeRateMantissa = (cToken.exchangeRateCurrent())/1e18;
        
        uint returnedAmount = exchangeRateMantissa * _amount;

        // Retrieve your asset based on a cToken amount
         uint256 redeemResult;
        redeemResult = cToken.redeem(_amount);
        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return returnedAmount;
    }

    /**
     * @notice Receive ether
     */
        receive() external payable {
        emit Received(msg.sender, msg.value);
       
    }
}