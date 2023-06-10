// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {ICamelotPair} from "./interfaces/uniswapV2/ICamelotPair.sol";
import {AggregatorV3Interface} from "./interfaces/chainlink/AggregatorV3Interface.sol";
import {IUniswapV3Pool} from "./interfaces/uniswapV3/IUniswapV3Pool.sol";
import {ICamelotRouter} from "./interfaces/uniswapV2/ICamelotRouter.sol";
import {ILBQuoter} from "./interfaces/traderjoeV2/ILBQuoter.sol";
import {IMasterPenpieReader} from "./interfaces/penpieReader/IMasterPenpieReader.sol";
import {IPendleStakingReader} from "./interfaces/penpieReader/IPendleStakingReader.sol";
import {IPenpieReceiptTokenReader} from "./interfaces/penpieReader/IPenpieReceiptTokenReader.sol";
import {IPendleMarketReader} from "./interfaces/penpieReader/IPendleMarketReader.sol";
import {IVLPenpieReader} from "./interfaces/penpieReader/IVLPenpieReader.sol";

/// @title MagpieReader for Arbitrum
/// @author Magpie Team

contract PenpieReader is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct TokenPrice {
        address token;
        string  symbol;
        uint256 price;
    }

    struct TokenRouter {
        address token;
        string symbol;
        uint256 decimals;
        address[] paths;
        address[] pools;
        address chainlink;
        uint256 routerType;
    }

    struct PenpieInfo {
        address masterPenpie;
        address pendleStaking;
        address vlPenpie;
        address penpieOFT;
        address mPendleOFT;
        address PENDLE;
        address WETH;
        address mPendleConvertor;
        uint256 autoBribeFee;
        PenpiePool[] pools;
    }

    struct PenpiePool {
        uint256 poolId;
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        uint256 allocPoint; // How many allocation points assigned to this pool. Penpies to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that Penpies distribution occurs.
        uint256 accPenpiePerShare; // Accumulated Penpies per share, times 1e12. See below.
        uint256 totalStaked;
        uint256 emission;
        uint256 allocpoint;
        uint256 sizeOfPool;
        uint256 totalPoint;
        address rewarder;
        bool    isActive;  
        bool isPendleMarket;
        string poolType;
        ERC20TokenInfo stakedTokenInfo;
        PendleMarket pendleMarket;
        PendleStakingPoolInfo pendleStakingPoolInfo;
        PenpieAccountInfo  accountInfo;
        PenpieRewardInfo rewardInfo;
        VlPenpieLockInfo vlPenpieLockInfo;
    }

    struct VlPenpieLockInfo {
        uint256 userTotalLocked;
        uint256 userAmountInCoolDown;
        VlPenpieUserUnlocking[] userUnlockingSchedule;
        uint256 totalPenalty;
        uint256 nextAvailableUnlockSlot;
        bool isFull;
    }

    struct VlPenpieUserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amountInCoolDown; // total amount comitted to the unlock slot, never changes except when reseting slot
        uint256 expectedPenaltyAmount;
        uint256 amountToUser;
    }  

    struct PenpieRewardInfo {
        uint256 pendingPenpie;
        address[]  bonusTokenAddresses;
        string[]  bonusTokenSymbols;
        uint256[]  pendingBonusRewards;
    }

    struct PendleMarket {
       address marketAddress;
       ERC20TokenInfo SY;
       ERC20TokenInfo PT;
       ERC20TokenInfo YT;
    }

    struct PenpieAccountInfo {
        
        uint256 balance;
        uint256 stakedAmount;
        uint256 stakingAllowance;
        uint256 availableAmount;
        uint256 mPendleConvertAllowance;
        uint256 lockPenpieAllowance;
        uint256 pendleBalance;
        uint256 penpieBalance;
    }

    struct PendleStakingPoolInfo {
        address market;
        address rewarder;
        address helper;
        address receiptToken;
        uint256 lastHarvestTime;
        bool isActive;
        uint256 activeBalance;
        uint256 lpBalance;
    }

    struct ERC20TokenInfo {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    /* ============ State Variables ============ */

    mapping(address => TokenRouter) public tokenRouterMap;
    address[] public tokenList;

    uint256 constant CamelotRouterType = 1;
    uint256 constant WombatRouterType = 2;
    uint256 constant ChainlinkType = 3;
    uint256 constant UniswapV3RouterType = 4;
    uint256 constant TraderJoeV2Type = 5;
    
    address constant public TraderJoeV2LBQuoter = 0x7f281f22eDB332807A039073a7F34A4A215bE89e;
    ICamelotRouter constant public CamelotRouter = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IMasterPenpieReader public masterPenpie;
    IPendleStakingReader public pendleStaking;
    address public penpieOFT;
    address public vlPenpie;
    address public mPendleOFT;
    address public PENDLE;
    address public WETHToken;
    address public mPendleConvertor;
    address public Penpie;
    uint256 public autoBribeFee;

    /* ============ Events ============ */

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    function __PenpieReader_init() public initializer {
        __Ownable_init();
    }

    /* ============ External Getters ============ */

    // function getUSDTPrice() public view returns (uint256) {
    //     return getTokenPrice(USDT, address(0));
    // }

    // function getUSDCPrice() public view returns (uint256) {
    //     return getTokenPrice(USDC, address(0));
    // }    

    function getWETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    // just to make frontend happy
    function getETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    function getTokenPrice(address token, address unitToken) public view returns (uint256) {
        TokenRouter memory tokenRouter = tokenRouterMap[token];
        uint256 amountOut = 0;
        if (tokenRouter.token != address(0)) {
           if (tokenRouter.routerType == CamelotRouterType) {
            uint256[] memory prices = CamelotRouter.getAmountsOut(10 ** tokenRouter.decimals , tokenRouter.paths);
            amountOut = prices[tokenRouter.paths.length - 1];
           }
           else if (tokenRouter.routerType == ChainlinkType) {
            AggregatorV3Interface aggregatorV3Interface = AggregatorV3Interface(tokenRouter.chainlink);
              (
                /* uint80 roundID */,
                int256 price,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = aggregatorV3Interface.latestRoundData();
            amountOut = uint256(price * 1e18 / 1e8);
           } else if (tokenRouter.routerType == UniswapV3RouterType) {
            IUniswapV3Pool pool = IUniswapV3Pool(tokenRouter.pools[0]);
            (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
            amountOut = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);
           } else if (tokenRouter.routerType == TraderJoeV2Type) {
            uint256[] memory quotes = (ILBQuoter(TraderJoeV2LBQuoter).findBestPathFromAmountIn(tokenRouter.paths, 10 ** tokenRouter.decimals)).amounts;
            amountOut = quotes[tokenRouter.paths.length - 1];
           }
       
        }
        if (unitToken == address(0)) {
            return amountOut;
        } 

        TokenRouter memory router = tokenRouterMap[unitToken];
        uint256 unitPrice;
        if (router.routerType != ChainlinkType) {
            address target = router.paths[router.paths.length - 1];
            unitPrice = getTokenPrice(unitToken, target);
        } else {
            unitPrice = getTokenPrice(unitToken, address(0));
        }
        
        uint256 uintDecimals =  ERC20(unitToken).decimals();
        return amountOut * unitPrice / (10 ** uintDecimals);
    }

    function getAllTokenPrice() public view returns (TokenPrice[] memory) {
        TokenPrice[] memory items = new TokenPrice[](tokenList.length);
        for(uint256 i = 0; i < tokenList.length; i++) {
            TokenPrice memory tokenPrice;
            TokenRouter memory router = tokenRouterMap[tokenList[i]];
            address target;

            if (router.routerType != ChainlinkType) {
                target = router.paths[router.paths.length - 1];

            }

            tokenPrice.price = getTokenPrice(tokenList[i], target);
            
            tokenPrice.symbol = router.symbol;
            tokenPrice.token = tokenList[i];
            items[i] = tokenPrice;
        }
        return items;
    }

    function getERC20TokenInfo(address token) public view returns (ERC20TokenInfo memory) {
        ERC20TokenInfo memory tokenInfo;
        tokenInfo.tokenAddress = token;
        ERC20 tokenContract = ERC20(token);
        tokenInfo.symbol = tokenContract.symbol();
        tokenInfo.decimals = tokenContract.decimals();
        return tokenInfo;
    }

    function getPenpieInfo(address account)  external view returns (PenpieInfo memory) {
        PenpieInfo memory info;
        uint256 poolCount = masterPenpie.poolLength();
        PenpiePool[] memory pools = new PenpiePool[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
           pools[i] = getPenpiePoolInfo(i, account);
        }
        info.pools = pools;
        info.masterPenpie = address(masterPenpie);
        info.pendleStaking = address(pendleStaking);
        info.penpieOFT = penpieOFT;
        info.vlPenpie = vlPenpie;
        info.mPendleOFT = mPendleOFT;
        info.PENDLE = PENDLE;
        info.WETH = WETHToken;
        info.mPendleConvertor = mPendleConvertor;
        info.autoBribeFee = autoBribeFee;
        return info;
    }

    function getPenpiePoolInfo(uint256 poolId, address account) public view returns (PenpiePool memory) {
        PenpiePool memory penpiePool;
        penpiePool.poolId = poolId;
        address registeredToken = masterPenpie.registeredToken(poolId);
        IMasterPenpieReader.PenpiePoolInfo memory penpiePoolInfo = masterPenpie.tokenToPoolInfo(registeredToken);
        penpiePool.stakingToken = penpiePoolInfo.stakingToken;
        penpiePool.allocPoint = penpiePoolInfo.allocPoint;
        penpiePool.lastRewardTimestamp = penpiePoolInfo.lastRewardTimestamp;
        penpiePool.accPenpiePerShare = penpiePoolInfo.accPenpiePerShare;
        penpiePool.totalStaked = penpiePoolInfo.totalStaked;
        penpiePool.rewarder = penpiePoolInfo.rewarder;
        penpiePool.isActive = penpiePoolInfo.isActive;
        penpiePool.receiptToken = penpiePoolInfo.receiptToken;
        (penpiePool.emission, penpiePool.allocpoint, penpiePool.sizeOfPool, penpiePool.totalPoint) = masterPenpie.getPoolInfo(penpiePool.stakingToken);
        if (penpiePool.stakingToken == vlPenpie) {
            penpiePool.poolType = "VLPENPIE_POOL";
            penpiePool.stakedTokenInfo = getERC20TokenInfo(penpiePool.stakingToken);
            penpiePool.vlPenpieLockInfo = getVlPenpieLockInfo(account);
        }
        else if (penpiePool.stakingToken == penpieOFT) {
            penpiePool.poolType = "PENPIEOFT_POOL";
            penpiePool.stakedTokenInfo = getERC20TokenInfo(penpiePool.stakingToken);
        }
        else if (penpiePool.stakingToken == mPendleOFT) {
            penpiePool.poolType = "MPENDLE_POOL";
            penpiePool.stakedTokenInfo = getERC20TokenInfo(penpiePool.stakingToken);
        }
        else if (penpiePool.stakingToken != penpiePool.receiptToken) {
            penpiePool.isPendleMarket = true;
        }
        if (penpiePool.isPendleMarket == true) {
            penpiePool.poolType = "PENDLE_MARKET";
            PendleMarket memory pendleMarket;
           // IPenpieReceiptTokenReader penpieReceiptTokenReader = IPenpieReceiptTokenReader(penpiePoolInfo.stakingToken);
            pendleMarket.marketAddress = penpiePoolInfo.stakingToken;
            IPendleMarketReader pendleMarketReader = IPendleMarketReader(pendleMarket.marketAddress);
            (address SY, address PT, address YT) = pendleMarketReader.readTokens();
            pendleMarket.SY = getERC20TokenInfo(SY);
            pendleMarket.PT = getERC20TokenInfo(PT);
            pendleMarket.YT = getERC20TokenInfo(YT);
            IPendleStakingReader.PendleStakingPoolInfo memory poolInfo = pendleStaking.pools(pendleMarket.marketAddress);
            PendleStakingPoolInfo memory pendleStakingPoolInfo;
            pendleStakingPoolInfo.helper = poolInfo.helper;
            pendleStakingPoolInfo.isActive = poolInfo.isActive;
            pendleStakingPoolInfo.market = poolInfo.market;
            pendleStakingPoolInfo.receiptToken = poolInfo.receiptToken;
            pendleStakingPoolInfo.rewarder = poolInfo.rewarder;
            pendleStakingPoolInfo.lastHarvestTime = poolInfo.lastHarvestTime;
            pendleStakingPoolInfo.activeBalance = pendleMarketReader.activeBalance(address(pendleStaking));
            pendleStakingPoolInfo.lpBalance = ERC20(pendleMarket.marketAddress).balanceOf(address(pendleStaking));
            penpiePool.pendleStakingPoolInfo = pendleStakingPoolInfo;
            penpiePool.pendleMarket = pendleMarket;
            penpiePool.stakedTokenInfo = getERC20TokenInfo(pendleMarket.marketAddress);
        }
    

        if (account != address(0)) {
            penpiePool.accountInfo = getPenpieAccountInfo(penpiePool, account);
            penpiePool.rewardInfo = getPenpieRewardInfo(penpiePool.stakingToken, account);
        }
        return penpiePool;
    }

    function getVlPenpieLockInfo(address account) public view returns (VlPenpieLockInfo memory) {
        VlPenpieLockInfo memory vlPenpieLockInfo;
        IVLPenpieReader vlPenpieReader = IVLPenpieReader(vlPenpie);
        vlPenpieLockInfo.totalPenalty = vlPenpieReader.totalPenalty();
        if (account != address(0)) {
            try vlPenpieReader.getNextAvailableUnlockSlot(account) returns (uint256 nextAvailableUnlockSlot) {
                vlPenpieLockInfo.isFull = false;
            }
            catch {
                vlPenpieLockInfo.isFull = true;
            }
            vlPenpieLockInfo.userAmountInCoolDown = vlPenpieReader.getUserAmountInCoolDown(account);
            vlPenpieLockInfo.userTotalLocked = vlPenpieReader.getUserTotalLocked(account);
            IVLPenpieReader.UserUnlocking[] memory userUnlockingList = vlPenpieReader.getUserUnlockingSchedule(account);
            VlPenpieUserUnlocking[] memory vlPenpieUserUnlockingList = new VlPenpieUserUnlocking[](userUnlockingList.length);
            for(uint256 i = 0; i < userUnlockingList.length; i++) {
                VlPenpieUserUnlocking memory vlPenpieUserUnlocking;
                IVLPenpieReader.UserUnlocking memory userUnlocking = userUnlockingList[i];
                vlPenpieUserUnlocking.startTime = userUnlocking.startTime;
                vlPenpieUserUnlocking.endTime = userUnlocking.endTime;
                vlPenpieUserUnlocking.amountInCoolDown = userUnlocking.amountInCoolDown;
                (uint256 penaltyAmount, uint256 amountToUser) = vlPenpieReader.expectedPenaltyAmount(i);
                vlPenpieUserUnlocking.expectedPenaltyAmount = penaltyAmount;
                vlPenpieUserUnlocking.amountToUser = amountToUser;
            }
            vlPenpieLockInfo.userUnlockingSchedule = vlPenpieUserUnlockingList;
        }
        return vlPenpieLockInfo;
    }


    function getPenpieAccountInfo(PenpiePool memory pool, address account) public view returns (PenpieAccountInfo memory) {
        PenpieAccountInfo memory accountInfo;
        if (pool.isPendleMarket) {
            accountInfo.balance = ERC20(pool.pendleMarket.marketAddress).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(pool.pendleMarket.marketAddress).allowance(account, address(pendleStaking));
            accountInfo.stakedAmount = ERC20(pool.pendleStakingPoolInfo.receiptToken).balanceOf(account);
        }
        else {
            accountInfo.balance = ERC20(pool.stakingToken).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(pool.stakingToken).allowance(account, address(masterPenpie));
            (accountInfo.stakedAmount, accountInfo.availableAmount) = masterPenpie.stakingInfo(pool.stakingToken, account);
        }
        if (pool.stakingToken == mPendleOFT) {
            accountInfo.mPendleConvertAllowance = ERC20(PENDLE).allowance(account, mPendleConvertor);
            accountInfo.pendleBalance = ERC20(PENDLE).balanceOf(account);
        }
        if  (pool.stakingToken == vlPenpie) {
            accountInfo.lockPenpieAllowance = ERC20(penpieOFT).allowance(account, vlPenpie);
            accountInfo.penpieBalance = ERC20(penpieOFT).balanceOf(account);
        }
        
        return accountInfo;
    }

    function getPenpieRewardInfo(address stakingToken, address account) public view returns (PenpieRewardInfo memory) {
        PenpieRewardInfo memory rewardInfo;
        (rewardInfo.pendingPenpie, rewardInfo.bonusTokenAddresses, rewardInfo.bonusTokenSymbols, rewardInfo.pendingBonusRewards) = masterPenpie.allPendingTokens(stakingToken, account);
        return rewardInfo;
    }

  

    /* ============ Internal Functions ============ */

    function _addTokenRouteInteral(address tokenAddress, address [] memory paths, address[] memory pools) internal returns (TokenRouter memory tokenRouter) {
        if (tokenRouterMap[tokenAddress].token == address(0)) {
            tokenList.push(tokenAddress);
        }
        tokenRouter.token = tokenAddress;
        tokenRouter.symbol = ERC20(tokenAddress).symbol();
        tokenRouter.decimals = ERC20(tokenAddress).decimals();
        tokenRouter.paths = paths;
        tokenRouter.pools = pools;
    }

    

    /* ============ Admin Functions ============ */

    function addTokenCamelotRouter(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = CamelotRouterType;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    function addUniswapV3Router(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = UniswapV3RouterType;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    function addTradeJoeV2Router(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = TraderJoeV2Type;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }        

    function addTokenChainlink(address tokenAddress, address [] memory paths, address[] memory pools, address priceAddress) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = ChainlinkType;
        tokenRouter.chainlink = priceAddress;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    function setMasterPenpie(IMasterPenpieReader _masterPenpie)  external onlyOwner  {
        masterPenpie = _masterPenpie;
        vlPenpie = masterPenpie.vlPenpie();
        penpieOFT = masterPenpie.penpieOFT();
    }

    function setPendleStaking(IPendleStakingReader _pendleStaking)  external onlyOwner  {
        pendleStaking = _pendleStaking;
        mPendleOFT = pendleStaking.mPendleOFT();
        PENDLE = pendleStaking.PENDLE();
        WETHToken = pendleStaking.WETH();
        mPendleConvertor = pendleStaking.mPendleConvertor();
        autoBribeFee = pendleStaking.autoBribeFee();
    }
}


//  const lockAllowance = await tokenContract.allowance(this.account, pool.locker);
      
//       const userTotalLocked: ethers.BigNumber = await lockerContract.getUserTotalLocked(this.account);
//       const startUnlock = userTotalLocked.sub(userTotalVotedInVlmgp);
//       const formatUserTotalLocked = formatEther(userTotalLocked);
      
//       const userAmountInCoolDown: ethers.BigNumber = await lockerContract.getUserAmountInCoolDown(this.account);
//       const formatUserAmountInCoolDown = formatEther(userAmountInCoolDown);
//       const yourLocking = userAmountInCoolDown.add(userTotalLocked);

//     //  const length = await lockerContract.getUserUnlockSlotLength(this.account);
//       const datas: LockItemInfo [] = [];
//       const blockNumber = await this.provider.getBlockNumber();
//       const block = await this.provider.getBlock(blockNumber);
//       const userUnlockingSchedule = await lockerContract.getUserUnlockingSchedule(this.account);
//       const totalPenalty = await lockerContract.totalPenalty();
//       const formatTotalPenalty = formatEther(totalPenalty);
//       const fixedFormatTotalPenalty = toSignificant(formatTotalPenalty);
//       let lastIndex = 0;
//       for (let i = 0; i < userUnlockingSchedule.length; i++) {
//         const item = userUnlockingSchedule[i]
      
//         let expectedPenaltyAmount = ethers.constants.Zero;
//         if (pool.type === "MAGPIE_VLMGP_POOL") {
//           const result = await lockerContract.expectedPenaltyAmount(i);
//           expectedPenaltyAmount = result.penaltyAmount;
//         }
//         const userGetAmount =  item.amountInCoolDown.sub(expectedPenaltyAmount);
//         if (!item.amountInCoolDown.isZero()) {
//           lastIndex = i;
//         }
//         datas.push({
//           unlockStartTime: item.startTime.toNumber(),
//           formatUnlockStartTime:  dayjs(item.startTime.toNumber() * 1000).format(
//             "YYYY/MM/DD"
//           ),
//           unlockEndTime: item.endTime.toNumber(),
//           formatUnlockEndTime:  dayjs(item.endTime.toNumber() * 1000).format(
//             "YYYY/MM/DD"
//           ),
//           coolDownAmount: item.amountInCoolDown,
//           formatCoolDownAmount: formatEther(item.amountInCoolDown),
//           fixedFormatCoolDownAmount: toSignificant(formatEther(item.amountInCoolDown)),
//           currentBlockTime: block.timestamp,
//           expectedPenaltyAmount,
//           formatExpectedPenaltyAmount: formatEther(expectedPenaltyAmount),
//           fixedFormatExpectedPenaltyAmount: toSignificant(formatEther(expectedPenaltyAmount)),
//           userGetAmount,
//           formatUserGetAmount: formatEther(userGetAmount),
//           fixedFormatUserGetAmount: toSignificant(formatEther(userGetAmount)),
//         });
//       }
//       let isFull = false;
//       try {
//         await lockerContract.getNextAvailableUnlockSlot(this.account)
//       }
//       catch(error) {
//         isFull = true;
//       }
//       return {
//         isFull,
//         lastSlotIndex: lastIndex,
//         userUnlockSlotLength: userUnlockingSchedule.length,
//         lockAllowance,
//         userTotalLocked,
//         formatUserTotalLocked,
//         fixedFormatUserTotalLocked: toSignificant(formatUserTotalLocked),
//         userAmountInCoolDown,
//         formatUserAmountInCoolDown,
//         fixedFormatUserAmountInCoolDown: toSignificant(formatUserAmountInCoolDown),
//         userLockList: datas,
//         totalPenalty,
//         formatTotalPenalty,
//         fixedFormatTotalPenalty,
//         startUnlock,
//         formatStartUnlock: formatEther(startUnlock),
//         fixedFormatStartUnlock: toSignificant(formatEther(startUnlock)),
//         yourLocking,
//         formatYourLocking: formatEther(yourLocking),
//         fixedFormatYourLocking: toSignificant(formatEther(yourLocking)),
//         userTotalVotedInVlmgp,
//         formatUserTotalVotedInVlmgp:  formatEther(userTotalVotedInVlmgp),
//         fixedFormatUserTotalVotedInVlmgp: toSignificant(formatEther(userTotalVotedInVlmgp))
//       };

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
library SafeMath {
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
pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IMasterPenpieReader {
    function poolLength() external view returns (uint256);
    function penpieOFT() external view returns (address);
    function vlPenpie() external view returns (address);
    function registeredToken(uint256) external view returns (address);
    struct PenpiePoolInfo {
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        uint256 allocPoint; // How many allocation points assigned to this pool. Penpies to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that Penpies distribution occurs.
        uint256 accPenpiePerShare; // Accumulated Penpies per share, times 1e12. See below.
        uint256 totalStaked;
        address rewarder;
        bool    isActive;  
    }
    function tokenToPoolInfo(address) external view returns (PenpiePoolInfo memory);
    function getPoolInfo(address) external view returns (uint256, uint256, uint256, uint256);
    function allPendingTokens(address _stakingToken, address _user)
        external view returns (
            uint256 pendingPenpie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards);
    function stakingInfo(address _stakingToken, address _user)
        external
        view
        returns (uint256 stakedAmount, uint256 availableAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPendleMarketReader  {
    function activeBalance(address) external view returns (uint256);
    function readTokens() external view returns (
        address _SY,
        address _PT,
        address _YT
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IPendleStakingReader {
  
    struct PendleStakingPoolInfo {
        address market;
        address rewarder;
        address helper;
        address receiptToken;
        uint256 lastHarvestTime;
        bool isActive;
    }
    function pools(address) external view returns (PendleStakingPoolInfo memory);
    function mPendleOFT() external view returns (address);
    function PENDLE() external view returns (address);
    function WETH() external view returns (address);
    function mPendleConvertor() external view returns (address);
    function autoBribeFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IPenpieReceiptTokenReader {

    function underlying() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IVLPenpieReader {
     struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amountInCoolDown; // total amount comitted to the unlock slot, never changes except when reseting slot
     }    
    function getUserUnlockingSchedule(address _user) external view returns (UserUnlocking[] memory slots);
    function getUserAmountInCoolDown(address _user) external view returns (uint256);
    function totalLocked() external view returns (uint256);
    function getFullyUnlock(address _user) external view returns(uint256 unlockedAmount);
    function getRewardablePercentWAD(address _user) external view returns(uint256 percent);
    function totalAmountInCoolDown() external view returns (uint256);
    function getUserNthUnlockSlot(address _user, uint256 n) external view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 amountInCoolDown
    );

    function getUserUnlockSlotLength(address _user) external view returns (uint256);
    function getNextAvailableUnlockSlot(address _user) external view returns (uint256);
    function getUserTotalLocked(address _user) external view returns (uint256);
    function expectedPenaltyAmount(uint256 _slotIndex) external view returns(uint256 penaltyAmount, uint256 amountToUser) ;
    function totalPenalty() external view returns (uint256);

}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILBRouter } from "./ILBRouter.sol";

interface ILBQuoter {

   struct Quote {
        address[] route;
        address[] pairs;
        uint256[] binSteps;
        uint256[] amounts;
        uint256[] virtualAmountsWithoutSlippage;
        uint256[] fees;
    }

    function findBestPathFromAmountIn(address[] calldata route, uint256 amountIn)
        external
        view
    returns (Quote memory quote);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Liquidity Book Router Interface
 * @author Trader Joe
 * @notice Required interface of LBRouter contract
 */
interface ILBRouter {

    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function kLast() external view returns (uint);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;

interface ICamelotRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );    
}