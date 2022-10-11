// SPDX-License-Identifier: MIT

import "./IPowerStationV2_1.sol";
pragma solidity ^0.8.4;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DuoPowerStation is Initializable, UUPSUpgradeable, OwnableUpgradeable,IDUOPowerStation{
    using SafeMathUpgradeable for uint256;

    IERC20 public usdt;
    IERC20 public rgp;
    IERC20 public renFil;

    // Dev address.
    address public filAddr;
    address public usdAddr;

    // Staking user for a pool
    struct Staker {
        uint256 redeemedRewards; // The reward tokens quantity the user already redeemed
        uint256 shares; 
        bool exists;
    }

    // Staking pool
    struct Pool {
        string poolInfo;      //name and description of the pool
        uint256 totalRewards; // Total amout of tokens
        bool isOpen;        //the opening status of the pool
        uint256 remainBalance;   //the remaining balance after distributing rewards
        uint256 allocatedShares;  //The shares that have already been sold
        address[] stakerAddr;      //All user address in the pool
        uint256 [] dailyRewardPershare; //
        uint256 totalDailyRewardPershare;
        bool exists;
        address poolMiner;
        
        // buyEndTime, startTime, endingTime
        uint256 [3] timing;
        //DataFee, GasFee, IDCfee, RGPtoShare, pricePerShare, pledgePerShare, maxShares
        uint256[7]  poolInfoVars;
    }

    // Info of each pool.
  Pool[] public pools; // Staking pools
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => Staker)) public poolStaker;

    function initialize(
            address _usdt,
            address _renFil,
            address _rgp,
            address _filAddr,
            address _usdAddr
        ) public initializer {
            usdt = IERC20(_usdt);
            renFil = IERC20(_renFil);
            rgp = IERC20(_rgp);
            filAddr = _filAddr;
            usdAddr =_usdAddr;

            ///@dev as there is no constructor, we need to inititalze the OwnableUpgradeable explicitly
            __Ownable_init();
        }
    
    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Add staker address to the pool stakers if it's not there already
     * This is for init the pool members. No individual can be add.
     */
    function stakerJoinPool(uint256 _pid, uint256 shares, string memory payby) public override {
        _poolExist(_pid);
        require(shares > 0, "can't be zero");
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        ///TODO: removed for testing, should add back when depoloy
        _poolIsOpen(_pid);

        //0 DataFee,1 GasFee,2 IDCfee,3 rgptoShare,4 pricePerShare,5 pledgePerShare,6 maxShares

        // a single deal may exceed the total shares of a pool
        require(poolUSDT.allocatedShares+ poolRGP.allocatedShares + shares <= poolUSDT.poolInfoVars[6], "over sell");
        
        ///@dev pay for the pledge
   
        require(renFil.transferFrom(msg.sender,filAddr, poolUSDT.poolInfoVars[5] * shares),"transfer failed");
        emit PayPledge(msg.sender, poolUSDT.poolInfoVars[5] * shares);

        ///@dev pay for expenses

        //Data+Gas
        require(renFil.transferFrom(msg.sender, filAddr, 
                    ( ( poolUSDT.poolInfoVars[0]+poolUSDT.poolInfoVars[1]) * shares)),"transfer failed");          // 15/10 is ultility/T/month

        emit PayDataGas(msg.sender, (poolUSDT.poolInfoVars[0]+poolUSDT.poolInfoVars[1]) * shares);

        ///@dev pay for the contract by usdt or RGP
        if (keccak256(abi.encodePacked(payby)) == keccak256(abi.encodePacked("USDT"))){
           
            require(usdt.transferFrom(msg.sender,usdAddr, (poolUSDT.poolInfoVars[4] + (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * 
                                                           poolUSDT.poolInfoVars[2]) * shares),"transfer failed");
            emit PayPower(msg.sender, poolUSDT.poolInfoVars[4] * shares);
            emit PayIDC(msg.sender, (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * poolUSDT.poolInfoVars[2] * shares);
            poolUSDT.allocatedShares += shares;
            
            if (stakerExistsInPool(_pid, msg.sender)== false){
                poolUSDT.stakerAddr.push(msg.sender);
            }
            Staker storage stakerUSDT = poolStaker[_pid*2][msg.sender];
            
            stakerUSDT.exists = true;
            stakerUSDT.shares += shares;
            }

        else if (keccak256(abi.encodePacked(payby)) == keccak256(abi.encodePacked("RGP"))){

            //RGP
            require(rgp.transferFrom(msg.sender,usdAddr, poolRGP.poolInfoVars[3] * shares),"transfer failed");
            emit PayPower(msg.sender, poolRGP.poolInfoVars[3] * shares);

            //IDC
            require(usdt.transferFrom(msg.sender, usdAddr, (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * 
                                                            poolRGP.poolInfoVars[2]*shares),"transfer failed");
            emit PayIDC(msg.sender, (poolUSDT.timing[2]-poolUSDT.timing[1])/30 days * poolRGP.poolInfoVars[2] * shares);
            poolRGP.allocatedShares += shares;
            if (stakerExistsInPool(_pid, msg.sender)== false){
                poolUSDT.stakerAddr.push(msg.sender);
            }
            Staker storage stakerUSDT = poolStaker[_pid*2][msg.sender];
            Staker storage stakerRGP = poolStaker[_pid*2 + 1][msg.sender];
            stakerUSDT.exists = true;
            stakerRGP.shares += shares;     
        }

        else {
            revert("not legit");
        }

        //if reach max shares, close the pool
        if(poolUSDT.allocatedShares +poolRGP.allocatedShares == poolRGP.poolInfoVars[6]){
            
            poolRGP.isOpen = false;
            poolUSDT.isOpen = false;
            emit PoolIsFull(_pid);
        }
    }
    
    function AdminJoinPool(uint256 _pid, address stakerAddr, uint256 shares, string memory payby) public override onlyOwner {
        _poolExist(_pid);
        require(shares > 0, "can't be zero");
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        ///TODO: removed for testing, should add back when depoloy
        _poolIsOpen(_pid);

        //0 DataFee,1 GasFee,2 IDCfee,3 rgptoShare,4 pricePerShare,5 pledgePerShare,6 maxShares

        // a single deal may exceed the total shares of a pool
        require(poolUSDT.allocatedShares+ poolRGP.allocatedShares + shares <= poolUSDT.poolInfoVars[6], "over sell");
        
       
        ///@dev pay for the contract by usdt or RGP
        if (keccak256(abi.encodePacked(payby)) == keccak256(abi.encodePacked("USDT"))){
           
            poolUSDT.allocatedShares += shares;
            
            if (stakerExistsInPool(_pid, stakerAddr)== false){
                poolUSDT.stakerAddr.push(stakerAddr);
            }
            Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
            
            stakerUSDT.exists = true;
            stakerUSDT.shares += shares;
            }

        else if (keccak256(abi.encodePacked(payby)) == keccak256(abi.encodePacked("RGP"))){

            poolRGP.allocatedShares += shares;

            if (stakerExistsInPool(_pid, stakerAddr)== false){
                poolUSDT.stakerAddr.push(stakerAddr);
            }
            Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
            Staker storage stakerRGP = poolStaker[_pid*2 + 1][stakerAddr];
            stakerUSDT.exists = true;
            stakerRGP.shares += shares;     
        }

        else {
            revert("not legit");
        }

        //if reach max shares, close the pool
        if(poolUSDT.allocatedShares +poolRGP.allocatedShares == poolRGP.poolInfoVars[6]){
            
            poolRGP.isOpen = false;
            poolUSDT.isOpen = false;
            emit PoolIsFull(_pid);
        }
    }

    function _poolIsOpen(uint256 _pid) internal{
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        if (block.timestamp > poolUSDT.timing[0]){      // buy end time
            poolUSDT.isOpen = false;
            poolRGP.isOpen = false;
        }
        require(poolUSDT.isOpen, "pool closed");
    }
    function _poolExist(uint256 _pid)internal view virtual{
        require(poolExists(_pid),"pool is not exist");
        
    }
    
    function _stakerExist(uint256 _pid, address stakerAddr)internal view virtual{
        require(stakerExistsInPool(_pid, stakerAddr),"not in the pool");
    
    }

    function withdraw(uint256 _pid) public override{
        _stakerExist(_pid, msg.sender);
        Staker storage stakerUSDT = poolStaker[_pid*2][msg.sender];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][msg.sender];
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        uint256 remainingRewardsPerShareUSDT;
        uint256 remainingRewardsPerShareRGP;

        if(stakerUSDT.shares ==0){
            remainingRewardsPerShareUSDT = 0;
                }
        else{
            remainingRewardsPerShareUSDT = poolUSDT.totalDailyRewardPershare -stakerUSDT.redeemedRewards / stakerUSDT.shares;
                }
        if(stakerRGP.shares ==0){
            remainingRewardsPerShareRGP = 0;
                }
        else{
            remainingRewardsPerShareRGP = poolRGP.totalDailyRewardPershare -stakerRGP.redeemedRewards / stakerRGP.shares;
                }

        require(remainingRewardsPerShareRGP + remainingRewardsPerShareUSDT > 0, "insufficient rewards");
        
        renFil.approve(address(this), remainingRewardsPerShareUSDT* stakerUSDT.shares + 
                                        remainingRewardsPerShareRGP* stakerRGP.shares);
        require(renFil.transfer(msg.sender, remainingRewardsPerShareUSDT* stakerUSDT.shares + 
                                        remainingRewardsPerShareRGP* stakerRGP.shares),"transfer failed");
        stakerUSDT.redeemedRewards += remainingRewardsPerShareUSDT* stakerUSDT.shares;
        stakerRGP.redeemedRewards += remainingRewardsPerShareRGP* stakerRGP.shares;
    }


    function poolLength() public override view returns (uint256) {

        return pools.length;
    }

    function numberOfstakers(uint256 _pid) public override view returns (uint256) {
        _poolExist(_pid);
        Pool storage pool = pools[_pid];
        return pool.stakerAddr.length;
    }
    /**
     * @dev Create a new staking pool
     */

    function addPool(uint256 periods,  uint256 pricePerShare, uint256 pledgePerShare, address poolMiner, 
                    string memory poolInfo,uint256 maxShares, uint256 startTime, 
                    uint256 dataFee, uint256 gasFee, uint256 rgptoShare, uint256 idcFee, uint256 buyEndTime)
        public override onlyOwner{
        Pool memory pool;
        uint256[7] memory poolInfoVars;
        poolInfoVars = [dataFee,gasFee, idcFee, rgptoShare, pricePerShare, pledgePerShare, maxShares];
        pool.poolInfoVars = poolInfoVars;

        pool.poolMiner = poolMiner;
        pool.poolInfo = poolInfo;
        ///TODO this is for testing convience
        // startTime =block.timestamp;

        uint256 endingTime = startTime + periods*30 days;

        uint256[3] memory timing = [buyEndTime,startTime, endingTime];
        pool.timing =timing;
        pool.exists = true;
        pool.isOpen = true;
      
        pools.push(pool);
        pools.push(pool);
        uint256 poolId = pools.length/2 - 1;
        emit PoolCreated(poolId);
    }
            
    ///@dev admin top up the daily rewards into the pool

    function topUpPool(uint256 _pid, uint256 _allocPoint) public override{
        
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        require(msg.sender == poolUSDT.poolMiner,"not allowed");

        uint256 rewardPerShareRGP = _allocPoint*  1/poolRGP.poolInfoVars[6] * 85/100;    // allocPoint* 1/maxShares *0.85
        uint256 rewardPerShareUSDT = _allocPoint*  1/poolRGP.poolInfoVars[6] * 80/100;    // allocPoint* 1/maxShares *0.8
        uint256 allocatedRewardsRGP = rewardPerShareRGP * poolRGP.allocatedShares;
        uint256 allocatedRewardsUSDT = rewardPerShareUSDT * poolUSDT.allocatedShares;

        require(renFil.transferFrom(msg.sender, filAddr, _allocPoint - allocatedRewardsRGP - allocatedRewardsUSDT),"dev not received");
        require(renFil.transferFrom(msg.sender, address(this), allocatedRewardsRGP + allocatedRewardsUSDT),"pool not received");
        emit TopUp(_pid, _allocPoint);

        ///update the total rewards that has been sent in this pool
        poolUSDT.totalRewards += _allocPoint;
        poolUSDT.dailyRewardPershare.push(rewardPerShareUSDT);
        poolRGP.dailyRewardPershare.push(rewardPerShareRGP);
        poolUSDT.totalDailyRewardPershare += rewardPerShareUSDT;
        poolRGP.totalDailyRewardPershare += rewardPerShareRGP;
        poolUSDT.remainBalance +=  _allocPoint - allocatedRewardsRGP - allocatedRewardsUSDT;
   
        emit TopUp(_pid, _allocPoint);
    }
    
    function poolAvailable(uint256 _pid) public override view returns(bool){
        _poolExist(_pid);
    
        Pool storage pool = pools[_pid*2];
        return(pool.timing[1] < block.timestamp && block.timestamp < pool.timing[2]);
    }

    function poolRemainingTime(uint256 _pid) public override view returns(uint256){
        _poolExist(_pid);

        Pool storage pool = pools[_pid*2];
        return(pool.timing[2] - block.timestamp);
    }

    function pendingRewards(address stakerAddr, uint256 _pid) public override view returns (uint256){
        _stakerExist(_pid, stakerAddr);
        Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][stakerAddr];
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        uint256 remainingRewardsPerShareUSDT;
        uint256 remainingRewardsPerShareRGP;

        if(stakerUSDT.shares == 0){
            remainingRewardsPerShareUSDT = 0;
                }
        else{
            remainingRewardsPerShareUSDT = poolUSDT.totalDailyRewardPershare -stakerUSDT.redeemedRewards / stakerUSDT.shares;
                }
        if(stakerRGP.shares == 0){
            remainingRewardsPerShareRGP = 0;
                }
        else{
            remainingRewardsPerShareRGP = poolRGP.totalDailyRewardPershare -stakerRGP.redeemedRewards / stakerRGP.shares;
                }
        return(remainingRewardsPerShareUSDT * stakerUSDT.shares + remainingRewardsPerShareRGP * stakerRGP.shares);
        }
    
    function pendingRewardsWithInfo(address stakerAddr, uint256 _pid) 
        public view returns (uint256, uint256, uint256 [7] memory,uint256[7] memory){
        _stakerExist(_pid, stakerAddr);
        Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][stakerAddr];
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];

        uint256[7] memory poolVars = getPoolVars(_pid);
        // (string memory poolName, address miner, bool isOpen, uint256 [7] memory poolInfo)= getPoolInfo(_pid);
        uint256 [7] memory poolInfo= getPoolInfo(_pid);

        uint256 remainingRewardsPerShareUSDT;
        uint256 remainingRewardsPerShareRGP;

        if(stakerUSDT.shares ==0){
            remainingRewardsPerShareUSDT = 0;
                }
        else{
            remainingRewardsPerShareUSDT = poolUSDT.totalDailyRewardPershare -stakerUSDT.redeemedRewards / stakerUSDT.shares;
                }
        if(stakerRGP.shares ==0){
            remainingRewardsPerShareRGP = 0;
                }
        else{
            remainingRewardsPerShareRGP = poolRGP.totalDailyRewardPershare -stakerRGP.redeemedRewards / stakerRGP.shares;
                }
       
        // return(remainingRewardsPerShareUSDT * stakerUSDT.shares + remainingRewardsPerShareRGP * stakerRGP.shares, 
        //     stakerUSDT.shares + stakerRGP.shares, poolName, miner, isOpen, poolInfo, poolVars);
        return(remainingRewardsPerShareUSDT * stakerUSDT.shares + remainingRewardsPerShareRGP * stakerRGP.shares, 
            stakerUSDT.shares + stakerRGP.shares, poolInfo, poolVars);
    }

    function minerWithdraw(uint256 _pid)public override{
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        require(msg.sender == pool.poolMiner,"not allowed");

        renFil.transfer(msg.sender, pool.remainBalance);
        pool.remainBalance = 0;
    }

    function emergencyWithdraw()public override onlyOwner{
        renFil.transfer(filAddr, renFil.balanceOf(address(this)));
        
        for(uint256 i =0; i < pools.length; i + 2){
            Pool storage pool = pools[i];
            pool.remainBalance = 0;
        } 
    }

    // check the total computation powers that have been sold 
    function checkSoldShares(uint256 _pid)public override view returns(uint256){
        _poolExist(_pid);
        Pool storage poolUSDT = pools[_pid*2];
        Pool storage poolRGP = pools[_pid*2 + 1];
        return(poolUSDT.allocatedShares+poolRGP.allocatedShares);
    }

    function poolExists(uint256 _pid) public view override returns(bool){
        Pool storage pool = pools[_pid*2];
        return(pool.exists);
    }

    function stakerExistsInPool(uint256 _pid, address stakerAddr) public override view returns(bool){
        Staker storage staker = poolStaker[_pid*2][stakerAddr];
        return(staker.exists);
    }

    function stakerAddrInPool(uint256 _pid) public view override returns( address [] memory){
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        return(pool.stakerAddr);
    }

    function getPoolVars(uint256 _pid) public view override returns( uint256[7] memory){
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        return(pool.poolInfoVars);
    }

    function getPoolDailyPricePerShare(uint256 _pid) public override view returns(uint256[] memory){
        _poolExist(_pid);

        Pool storage pool = pools[_pid*2];
        return(pool.dailyRewardPershare);
    }
    
    function getStakerInfoNTime(uint256 _pid, address stakerAddr) public override view returns(uint256[6] memory){
        _stakerExist(_pid,stakerAddr);
        Staker storage stakerUSDT = poolStaker[_pid*2][stakerAddr];
        Staker storage stakerRGP =  poolStaker[_pid*2 + 1][stakerAddr];
        uint256[7] memory poolVars = getPoolVars(_pid);
        uint256[3] memory poolTime = getTiming(_pid);
        uint256 rgpTosShare = poolVars[3];
        uint256 pricePerShare = poolVars[4];
        uint256 startTime  = poolTime[1];
        uint256 endTime = poolTime[2];
        uint256[6] memory data = [stakerUSDT.shares, stakerRGP.shares, pricePerShare,
                                rgpTosShare, startTime, endTime];
        return(data);
    }

    function getTiming(uint256 _pid) public override view returns(uint256[3] memory){
        _poolExist(_pid);

        Pool storage pool = pools[_pid*2];
        return(pool.timing);
    }
     function getPoolInfo(uint256 _pid) private view returns(uint256 [7] memory){
        _poolExist(_pid);
        Pool storage pool = pools[_pid*2];
        // return(pool.poolInfo, pool.poolMiner, pool.isOpen, [pool.totalRewards, pool.timing[0],
        // pool.timing[1], pool.timing[2], pool.remainBalance, pool.allocatedShares, pool.totalDailyRewardPershare]);
        
        return([pool.totalRewards, pool.timing[0],
        pool.timing[1], pool.timing[2], pool.remainBalance, pool.allocatedShares, pool.totalDailyRewardPershare]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
pragma solidity ^0.8.0;

/**
 * @dev Interface of the PowerStation
 */
interface IDUOPowerStation {
    
    event EnterPool(address indexed staker, uint64 shares);
    
    event PayDataGas(address indexed staker, uint256 amount);

    event PayPledge(address indexed staker, uint256 amount);

    event PayPower(address indexed staker, uint256 amount);

    // event PayIDC(address indexed staker, uint8 months);
    event PayIDC(address indexed staker, uint256 amount);

    event TopUp(uint256 indexed _pid, uint256 _allocPoint);

    event Withdraw(address indexed staker, uint256 indexed _pid, uint256 amount);

    event PoolCreated(uint256 _pid); 

    event PoolIsFull(uint256 _pid);


    function stakerJoinPool(uint256 _pid,uint256 shares, string memory Fil) external;
    
    // function payUtils(uint256 _pid, uint8 months) external;

    function withdraw(uint256 _pid) external;

    function poolLength()  external view returns (uint256) ;
    
    function addPool(uint256 periods,  uint256 pricePerShare, uint256 pledgePerShare, address poolMiner, 
                    string memory poolInfo,uint256 maxShares, uint256 startTime, 
                    uint256 dataFee, uint256 gasFee, uint256 rgptoShare, uint256 idcFee, uint256 buyEndTime) external;

    function topUpPool(uint256 _pid, uint256 _allocPoint) external;

    // function utilsAvailable(address user, uint256 _pid)  external returns(bool);

    function poolAvailable(uint256 _pid) external view returns(bool);

    function poolRemainingTime(uint256 _pid) external view returns(uint256);

    // function utilsRemaining(address user, uint256 _pid)  external returns(uint256);

    function pendingRewards(address user, uint256 _pid)  external  view returns (uint256);

    function checkSoldShares(uint256 _pid) external view returns(uint256);

    function poolExists(uint256 _pid)  external view returns(bool);

    function stakerExistsInPool(uint256 _pid, address stakerAddr) view external returns(bool);

    function numberOfstakers(uint256 _pid)  external view returns (uint256);

    function stakerAddrInPool(uint256 _pid)  external returns (address [] memory);

    function minerWithdraw(uint256 _pid)external;

    function emergencyWithdraw() external;

    function getPoolVars(uint256 _pid) external view returns(uint256[7] memory);

    function getPoolDailyPricePerShare(uint256 _pid) external view returns(uint256[] memory);
    
    function getTiming(uint256 _pid)  external view returns(uint256[3] memory);

    function getStakerInfoNTime(uint256 _pid, address stakerAddr) external view returns(uint256[6] memory);

    function AdminJoinPool(uint256 _pid, address stakerAddr, uint256 shares, string memory payby) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}