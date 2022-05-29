/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {

        function totalSupply() external view returns (uint256);
        
        function decimals() external view returns (uint8);
        
        function symbol() external view returns (string memory);
        
        function name() external view returns (string memory);
        
        function balanceOf(address account) external view returns (uint256);
        
        function transfer(address recipient, uint256 amount) external returns (bool);
        
        function allowance(address _owner, address spender) external view returns (uint256);
        
        function approve(address spender, uint256 amount) external returns (bool);
        
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
}

interface IPoolFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);


        // address[] public allPools = [];

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

     function getInfo(address _poolCreater) external view returns (address n);

    struct User {
        address token1;
        address token2;
        address poolCreater;
        uint24 fee;
    }
    
        function getPoolInfo(address _poolCreater) external view returns (address, address, address , uint24);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;


        // mapping(address => User) public poolInformation;


}



contract StakeInPool {


    IPoolFactory public factory;



    constructor(IPoolFactory _factory) {
        factory = _factory;
    }






/////// FUNCTIONS FOR POOL INCENTIVE PROGRAM CREATORS ////////


    function getPoolInfo(address info) external view  returns (address, address, address , uint24) {
        return (factory.getPoolInfo(info));

    }

    struct Incentive {
        uint256 totalRewardUnclaimed;
        uint256 totalSecondsClaimedX128;
        uint256 numberOfStakes;
    }


    mapping(bytes32 => Incentive) public incentives;


    struct IncentiveKey {
        IBEP20 rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
        uint256 reward;
    }




    mapping(uint256 => IncentiveKey) public _incentiveKey;

    event IncentiveCreated( IBEP20 indexed rewardToken, address indexed pool, uint256 startTime,  uint256 endTime, address refundee,  uint256 reward);

    event IncentiveEnded(bytes32 indexed incentiveId, uint256 refund);

    function compute(IncentiveKey memory key) internal pure returns (bytes32 incentiveId) {
        return keccak256(abi.encode(key));
    }

    uint256 totalIncentiveCount = 0;


    function incentiveToBytes32(uint256 _key) public view returns(bytes32 incentiveId) {
        IncentiveKey storage key = _incentiveKey[_key];
        return keccak256(abi.encode(key));

    }

    function createIncentive(address _pool, uint256 _startTime, uint256 _endTime,address _refundee , uint256 _reward) external {
    

        (address token1, address token2 , address poolCreater, uint24 fee) = factory.getPoolInfo(_pool);

        IBEP20 tokenTwo;
        tokenTwo = IBEP20(token2);

        require(token1 != address(0), "StakeInPool::createIncentive: pool doesn't exist in factory contract");



        IncentiveKey storage key = _incentiveKey[totalIncentiveCount];
        
        
        key.rewardToken = tokenTwo;
        key.pool = _pool;
        key.startTime = _startTime;
        key.endTime = _endTime;
        key.refundee = _refundee;
        key.reward = _reward;


        require(_reward > 0, "StakeInPool::createIncentive: reward must be greater then 0");
        require(key.startTime >= block.timestamp, "StakeInPool::createIncentive: start time must be in future");
        require(key.startTime < key.endTime, "StakeInPool::createIncentive: start time must be before end time");

        bytes32 incentiveId = compute(key);

        incentives[incentiveId].totalRewardUnclaimed += _reward;

        key.rewardToken.transferFrom(/*address(key.rewardToken),*/ msg.sender, address(this), _reward);

        totalIncentiveCount++;



        emit IncentiveCreated(key.rewardToken, key.pool, key.startTime, key.endTime, key.refundee, _reward);

    }

    function endIncentive(uint256 _key) external returns(uint256 refund) {

        IncentiveKey storage key = _incentiveKey[_key];


        require(block.timestamp >= key.endTime, "StakeInPool::endIncentive: cannot end incentive before end time");
        
        bytes32 incentiveId = compute(key);
        Incentive storage incentive = incentives[incentiveId];

        refund = incentive.totalRewardUnclaimed;

        require(refund > 0, "StakeInPool::endIncentive: no refund available");
        require(incentive.numberOfStakes == 0, "StakeInPool::endIncentive: cannot end incentive while deposits are staked");

        // issue the refund
        incentive.totalRewardUnclaimed = 0;
        key.rewardToken.transfer(key.refundee, refund);

        emit IncentiveEnded(incentiveId, refund);

    }




////// FOR NORMAL USERS //////

    mapping(address => mapping(uint256 => uint256)) public _userLiquidities;

    uint256 public liquidityId = 0;

    event DepositTransferred(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);


    function creatLiquidityId(uint256 amount) public returns(uint256 id) {
        liquidityId++;
        uint256 a = liquidityId - 1;
        _userLiquidities[msg.sender][a] = amount;

        deposits[a] = Deposit({owner: msg.sender, numberOfStakes: 0});
        emit DepositTransferred(liquidityId, address(0), msg.sender);


        return liquidityId;
    }

    function transferDeposit(uint256 _liquidityId, address to) external {
        uint256 a = liquidityId - 1;
        require(_liquidityId <=  _userLiquidities[msg.sender][a], "StakInPool::transferDeposit: you are not owner of this liquidityId");
        require(to != address(0), "StakInPool::transferDeposit: invalid transfer recipient");
        address owner = deposits[liquidityId].owner;
        require(owner == msg.sender, "StakeInPool::transferDeposit: can only be called by deposit owner");
        deposits[_liquidityId].owner = to;
        emit DepositTransferred(liquidityId,owner,to);
    }


    struct Deposit {
        address owner;
        uint256 numberOfStakes;
    }

    struct Stake {
        uint256 secondsPerLiquidityInsideX128;
        uint256 liquidity;
        uint256 reward;
        bool unstaked;
    }

    // deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    // stakes[tokenId][incentiveHash] => Stake
    // mapping(uint256 => mapping(bytes32 => Stake)) private _stakes;
    mapping(address => mapping(uint256 => mapping(bytes32 => Stake))) internal _stakes;




    event TokenStaked(uint256 indexed tokenId, bytes32 indexed incentiveId, uint256 liquidity);


    function stakes(uint256 _liquidityId, uint256 _key) public view returns (uint256 secondsPerLiquidityInsideX128, uint256 liquidity, uint256 reward , bool unstaked) {
        IncentiveKey storage key = _incentiveKey[_key];
        bytes32 incentiveId = compute(key);

        Stake storage stake = _stakes[msg.sender][_liquidityId][incentiveId];
        secondsPerLiquidityInsideX128 = stake.secondsPerLiquidityInsideX128;
        liquidity = stake.liquidity;
        reward = stake.reward;
        unstaked = stake.unstaked;

    }

    function stakeToken(uint256 _key, uint256 _liquidityId) external {
        require(deposits[_liquidityId].owner == msg.sender, "StakeInPool::stakeToken: only owner can stake token");

        _stakeToken(_key, _liquidityId);
    }

    function _stakeToken(uint256 _key, uint256 _liquidityId) private {

        require(_key < totalIncentiveCount, "StakeInPool::stakeToken: incentive program doesn't exist");


        IncentiveKey storage key = _incentiveKey[_key];
        bytes32 incentiveId = compute(key);

        Stake storage stake = _stakes[msg.sender][_liquidityId][incentiveId];
        require(stake.unstaked == false, "StakeInPool::stakeToken: liquidity already unstaked");


        require(block.timestamp >= key.startTime, "StakeInPool::stakeToken: incentive not started");
        require(block.timestamp < key.endTime, ": incentive ended");

        require(incentives[incentiveId].totalRewardUnclaimed > 0, "StakeInPool::stakeToken: non-existent incentive");
        require(_stakes[msg.sender][_liquidityId][incentiveId].liquidity == 0, "StakeInPool::stakeToken: token already staked or liquidityId doesn't exists.");

        // require(liquidity > 0, 'UniswapV3Staker::stakeToken: cannot stake token with 0 liquidity');


        (address token1, address token2 , address poolCreater, uint24 fee) = factory.getPoolInfo(key.pool);


        IBEP20 tokenOne;
        tokenOne = IBEP20(token1);

        require(tokenOne.balanceOf(msg.sender) > 0 , "StakeInPool::stakeToken: not enough balance");
        uint256 amount = _userLiquidities[msg.sender][_liquidityId];

        require(amount > 0, "StakeInPool::stakeToken: not enough liquidity");

        uint256 feeForPoolCreater = amount * (fee) / 10000;
        uint256 feeForFactory = amount * (30) / 10000;

        uint256 toThis = amount - (feeForPoolCreater + feeForFactory);

        address facOwner = factory.owner();


        tokenOne.transferFrom(msg.sender,poolCreater, feeForPoolCreater);
        tokenOne.transferFrom(msg.sender,facOwner, feeForFactory);
        tokenOne.transferFrom(msg.sender,address(this), toThis);

        deposits[_liquidityId].numberOfStakes++;
        incentives[incentiveId].numberOfStakes++;

        stake.secondsPerLiquidityInsideX128 = block.timestamp;
        stake.liquidity = toThis;

        emit TokenStaked(_liquidityId, incentiveId, toThis);


    }



    event TokenUnstaked(uint256 indexed tokenId, bytes32 indexed incentiveId);

    // //rewards[rewardToken][owner] => uint256
    // mapping(IBEP20 => mapping(address => uint256)) public rewards;

    function unstakeToken(uint256 _key, uint256 _liquidityId) external {
        IncentiveKey storage key = _incentiveKey[_key];
        bytes32 incentiveId = compute(key);

        // reward = stake.liquidityId;

  

        Incentive storage incentive = incentives[incentiveId];

        Deposit memory deposit = deposits[_liquidityId];

        Stake storage stake = _stakes[msg.sender][_liquidityId][incentiveId];


        if (block.timestamp < key.endTime) {
            require(deposit.owner == msg.sender, "StakeInPool::unstakeToken: stake does not exist");
        }

        (address token1, address token2 , address poolCreater, uint24 fee) = factory.getPoolInfo(key.pool);




        IBEP20 tokenOne;
        tokenOne = IBEP20(token1);
        IBEP20 tokenTwo;
        tokenTwo = IBEP20(token2);

        uint256 reqa = 0;
        uint256 earned = 0;

        reqa = (key.reward * ( block.timestamp - stake.secondsPerLiquidityInsideX128)) / 527040 minutes;
        earned = reqa / 100;

        tokenOne.transfer(msg.sender, stake.liquidity);

        tokenTwo.transfer(msg.sender, earned);


        deposits[_liquidityId].numberOfStakes--;
        incentive.numberOfStakes--;




        incentive.totalRewardUnclaimed -= earned;
        stake.reward = earned;
        stake.unstaked == true;
        



        incentive.totalRewardUnclaimed = incentive.totalRewardUnclaimed - earned;

        // delete stake.secondsPerLiquidityInsideX128;
        // delete stake.liquidity;
        emit TokenUnstaked(_liquidityId, incentiveId);
    }




}