// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import './dCommon.sol';


struct ArbitTable{
    //arbit users
    mapping(address => ArbitUserInfo ) arbitUserList;
    uint[] arbiterList;
    //arbitOrder
    mapping(string => ExOrderArbit ) orderArbitList;
    //aribit result
    mapping(string => ArbitInfo[]) orderArbitDetailList;
    mapping(string => uint)  orderArbitCount;
    uint totalOrderArbitCount;
    mapping(string => OrderArbitSettle) orderArbitSettle;
    //cardArbit table
    CardArbitTable cardArbitTable;
    //Extension
    ArbitExtension extend;

}
struct ArbitExtension{
   //tokens from arbit assets
   mapping(address => uint) arbitGivedToken;
   mapping(string => string) arbitIdList;
}
struct CardArbitTable{
    //card arbit
    mapping(address => CardArbit) carArbitList;
    //card arbit result
    mapping(address => ArbitInfo[]) cardArbitDetailList;
    uint  totalCardArbitCount;
    mapping(string => address) cardArbitIds;
    mapping(string => CardArbitSettle) cardArbitSettle;
}
//arbit record
enum ArbitState{
    None,
    Dealing,
    Completed,
    Cancelled
}
enum ArbitResult{
    None,
    Accuser,
    Appellee
}
enum ArbitPeriod{
    None,
    Proof,
    Arbit,
    Appeal,
    Over
}
struct ExOrderArbit{
    string adOrderId;
    string exOrderId;
    address applyUser;
    address appelle;
    ArbitState state;  
    ArbitResult arbitResult;
    uint lastApplyTime;
    ArbitBackInfo arbitBackInfo;
    string currentArbitId;
}
struct ArbitBackInfo{
    uint orderArbitTimes;
    ArbitPeriod period;
    uint lastCompleteTime;
    uint lockedDotcAmount;  
    address lockedUser; 
    bool isSettled;
    uint settleTime;
}
struct ArbitInfo{
    address arbiter;
    ArbitResult result;
    uint taskTime;  
    uint handleTime;
}
struct OrderArbitSettle{
   UserTokenInfo loserExCoin;
   UserTokenInfo loserDeposit;
   UserTokenInfo loserFee;
   TokenInfo minePool;
   TokenInfo riskPool;
   TokenInfo stakingPoolA;
   TokenInfo stakingPoolB;
   TokenInfo arbitorReward;
   UserTokenInfo invitorSponsor;
}
struct ArbitUserInfo{
    bool isActive;
    uint applayTime;
    address lockedToken;
    uint lockedAmount;
    uint nHandleCount;
}
struct CardArbit{
   uint applyUSDTAmount;
   ArbitState state;
   ArbitResult arbitResult;
   string arbitID;
   uint lastApplyTime;
   uint lastCompleteTime;
  
   uint cardArbitTimes;
   uint totalGivedUSDT;
   uint lockedDotcAmount;
}

struct CardArbitSettle{
   UserTokenInfo userGetCoin;
   TokenInfo arbitorReward;
   TokenInfo riskPool;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

struct OracleInfo{
    address robotAddr;
    uint currentPrice;
    bool isInited;
    uint lastUpdateTime;
}
struct Config{
    address dotcContract;
    address wethContract;
    address usdtContract;
    address mainContract;
    /***FEE */
    uint makerFee;
    uint takerFee;
    bool isPause;
    bool isPauseAsset; //spare value
}
//constant
struct ConstInstance{
    uint priceMode;
    uint maxDotcPrice;
    uint vipDOTC;
    uint arbiterDOTC;
    uint nMaxOrderMine;
    OrderLimit orderLimit;
    ArbitParam arbitParam;
    StakingParam stakingParam;
    PriceParam priceParam;
    PeriodParam periodParam;
}
struct PriceParam{
    uint nDOTCDecimals;
    uint nWethDecimals; //spareValue
    uint nUsdtDecimals;
    uint minOrderValue;
    uint minAdValue;
    uint minAdDepositeValue;
}
struct OrderLimit{
    uint orderNum;
    uint vipOrderNum;
    uint vipAdorder;
    uint exOrderOutTime;
    uint AdOutTime;
    uint cancelWaitTime;
}
struct PeriodParam{
    uint firstTradeLockTime;
    uint otherTradeLockTime;
    uint arbitPeriodTime;
    uint cardPeriodTime;
    uint depositRate;
}
struct ArbitParam{
    uint nArbitNum;
    uint nOrderArbitCost;
    uint nCardArbitCost;
    uint arbiterApplyCost;
    uint arbiterPunish;
    uint nCardMaxGive;
}
struct StakingParam{
    uint poolAMin;
    uint poolBMin;
    uint unLockWaitTime;
    uint bonusUnlockTime;
    uint firstBonusTime;
    uint bonusWaitTime;
    uint bonusPeriod;
}

struct TokenInfo{
    address token;
    uint amount;
}
struct UserTokenInfo{
    address userAddr;
    bool isAddOrSub;
    address token;
    uint amount;
}

struct Sign{
    uint8 v;
    bytes32 r;
    bytes32 s;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import '../utils/RandomHelper.sol';

import '../defines/dUser.sol';
import '../defines/dOrder.sol';
import '../defines/dRisk.sol';
import '../defines/dMiningPool.sol';
import '../defines/dStaking.sol';
import '../defines/dArbit.sol';
import '../defines/dCommon.sol';
import '../defines/dTotal.sol';

library DOTCLib{
    function Contains(uint[] memory data,uint num) internal pure returns(bool isFind,uint index){
        
        for(uint i=0;i<data.length;i++){
            if(data[i]==num){
                isFind=true;
                index=i;
                break;
            }
        }
    }
    function _findArrayIndexByValue(uint[] memory array,uint source) internal pure returns(uint){
       if(array.length<1) return 0;
       for(uint i=0;i<array.length;i++){
         if(array[i]==source){
            return i+1;
         }
       }
       return 0;
    }
    function _findArbiterIndexForExOrder(ArbitInfo[] memory arbitList,address arbiter) internal pure returns(uint){
      if(arbitList.length<1) return 0;
      for(uint i=0;i<arbitList.length;i++){
         if(arbitList[i].arbiter==arbiter){
            return i+1;
         }
      }
      return 0;
    }

    function _getRandomList(uint[] memory arbiterList,uint nLength,uint num) internal view returns(uint[] memory indexList){
      require(nLength>=num,'the length is less than target num');
      uint nonce=nLength/2;
      uint nTryTimes=0;
      indexList=new uint[](num);
      uint nCurrentIndex=0;
      {
         while(nCurrentIndex<num){
            nonce++;nTryTimes++;
            if(nTryTimes>100){
               //overflow
               break;
            }
            uint nIndex=RandomHelper.rand(nLength,nonce);
            if(arbiterList[nIndex]==0){
               continue;
            }
            (bool isFind,uint index)=Contains(indexList,nIndex);
            if(!isFind && index<=0){
               indexList[nCurrentIndex]=nIndex;
               nCurrentIndex++;
            }
         }
      }
     
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0;

// helper generate serveral random numbers.
library RandomHelper {

    function rand(uint _length,uint nonce) internal view  returns(uint) {
        require(_length!=0,"max num is zero");
        uint random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,msg.sender,nonce)));
        return  random%_length;
    }     
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

struct UserTable{
    //userInfo List
    mapping (address => UserInfo) userList;
    //relationship
    mapping(address => address) userInviteList;
    //assets
    mapping(address => mapping (address => AssetInfo)) userAssets;
    //ASSET LockedInfo
    mapping(address => mapping (address => AssetLockInfo[])) userLockedList;
    //sponsor data
    //user address => sponsorData
    mapping(address => SponsorData) userSponsorData;
    //spare value for future
    //mapping(address => uint) tokenWhiteList;
}
struct SponsorData {
    // user address => balance
    mapping(address => uint256) sponsorBalances;
    uint totalSupply;

    //exorder => balance
    mapping(string => uint256) sponsorLockList;
    uint totalLocked;
}
struct UserInfo{
    uint kycState;
    bool isVIP;
    uint arbitExOrderCount; 
}
struct AssetLockInfo{
    uint amount;
    uint lockTime;
    bool isUnLocked;
    uint unlockDeadline;
}
struct AssetInfo{
    uint available;
    uint locked;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

struct OrderTable{
    mapping(string => AdOrder) otcAdOrders;
    uint orderCount;

    mapping(string => mapping(string => ExOrder)) otcTradeOrders;
    mapping(string => string[]) otcAdOrderCounter; //记录当前正在交易的交易订单ID号
    mapping(string => string) otcExAdMap;
    mapping(address => mapping(address => uint)) otcTradeStatistics; //taker == mapping(maker ==> count)
    mapping(address => mapping(address => uint)) rewardStatistics;//交易挖矿统计
    mapping(address => UserOrder) userOrderDb;

}
struct UserOrder{
    uint totalAdOrder;
    uint noneAdOrder;//uncompleted adOrder
    string[] noneAdOrderList; //uncompleted adOrder list
    
    uint totalExOrder;
    uint noneExOrder; //uncompleted exorder
    string[] noneExOrderList; //uncompleted exorder list
}
enum ExchangeSide{
    BUY,
    SELL
}
enum OrderState{
    NONE,
    ONTRADE,
    CLOSED
}
enum TradeState{
    UnFilled,
    PartialFilled,
    Filled,
    MoneyPayed,
    MoneyReceived,
    Completed,
    ArbitClosed,
    Cancelled
}
enum CoinType{
    UNKNOWN,
    USDT,
    DOTC,
    WETH,
    OTHER
}
//OTCAdOrder Info
struct AdOrder{
    string orderId;
    address makerAddress;
    ExchangeSide side;
    address tokenA;
    address tokenB;
    OrderState state;
    AdOrderDetail detail;
    DepositInfo depositInfo;
}
struct AdOrderDetail{
    uint price;
    uint totalAmount;
    uint leftAmount;
    uint lockedAmount;
    uint minAmount;
    uint maxAmount;
    uint AdTime;
}
struct DepositInfo{
    uint orderValue;
    uint dotcAmount;
    uint deposit;
    CoinType feeType;
    uint feeValue;
}
//OTCExOrder Info
struct ExOrder{
    string _exOrderId;
    string _adOrderId;
    address makerAddress;
    address takerAddress;
    ExchangeSide side;
    ExOrderDetail detail;
    DepositInfo depositInfo;
    RebateInfo[] rebateList;
}
struct ExOrderDetail{
    address tokenA;
    address tokenB;
    uint tradeAmount;
    uint tradeTime;
    TradeState state;
    uint lastUpdateTime;
    ExRewardInfo exRewardInfo;
}
struct FeeInfo{
    uint feeValue;
    CoinType feeType;
}
struct ExRewardInfo{
    address token;
    uint amount;
}
struct RebateInfo{
    address user;
    uint rlevel;
    address token;
    uint amount;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

struct RiskPool{
   mapping(address => PoolInfo) poolTokens;
}

struct PoolInfo{
   uint initSupply;
   uint currentSupply;
   uint totalPayed;
   uint payTimes;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

struct MiningPool{
   mapping(address => MineInfo) poolTokens;
}

struct MineInfo{
   uint initSupply;
   uint initBackRate;
   uint currentSupply;
   uint totalMined;
   uint periodMined;
   uint periodCount;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

struct StakingDetail{
    uint balance;
    uint lastLockTime;
    //uint weightTime;
    uint lastBonusTime;
    uint totalBonused;
    PeriodStaking v1;
    PeriodStaking v2;
}
struct StakingPool {
    // user address => balance
    mapping(address => StakingDetail) accountStakings;
    uint totalSupply;
    uint totalAccount;

    PoolPeriodInfo v1Info;
    PoolPeriodInfo v2Info;

    uint totalUSDTBonus;
    uint totalBonused;
}
struct PoolPeriodInfo{
    uint startTime;
    uint periodNum;
    uint totalUSDTBonus;
    uint Bonused;
}
struct PeriodStaking{
    uint amount;
    uint weightTime;
    bool isBonused;
}

struct StakingTable{
   uint startTime;
   bool isEnableLock;
   bool isEnableUnLock;
   bool isEnableBonus;

   mapping(address => StakingPool) poolA;
   mapping(address => StakingPool) poolB;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import '../defines/dUser.sol';
import '../defines/dOrder.sol';
import '../defines/dRisk.sol';
import '../defines/dMiningPool.sol';
import '../defines/dStaking.sol';
import '../defines/dArbit.sol';
import '../defines/dCommon.sol';

struct DAOData{
    /*****Risk Pool */
    RiskPool riskPool;
    /**** Mining Pool */
    MiningPool miningPool;
    /******Oracle Start ******/
    OracleInfo oracleInfo;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import "../libraries/LibStrings.sol";
import '../libraries/DOTCLib.sol';
import "../facetBase/DOTCFacetBase.sol";

import '../utils/SafeMath.sol';
import '../utils/SignHelper.sol';

//import "hardhat/console.sol";

contract DOTCUserFacet is DOTCFacetBase {
    using SafeMath for uint;

    event _VIPApplied(address indexed user,bool indexed result);
    event _SponsorUpdated(address indexed sponsor,address indexed userAddr,uint indexed amount);

    event _tokenDeposited(address indexed userAddr,address indexed token,uint indexed amount);
    event _tokenWithdrawed(address indexed userAddr,address indexed token,uint indexed amount);

    event _ReleaseUnlockAmount(address indexed userAddr,address indexed token,uint indexed amount);
    event _ArbitApplied(address indexed user,bool indexed result);
    event _ArbitCancelled(address indexed user,bool indexed result);


    function queryUserInvitor() external view returns(address invitor){
      invitor=db.userTable.userInviteList[msg.sender];
    }
    function updateSponsorAmount(address userAddr,uint amount,uint8 v, bytes32 r,bytes32 s) external returns (bool result) {
      //check balance
      {
        require(userAddr!=address(0),'user address invalid.');
        // require(amount >= consts.priceParam.nDOTCDecimals,'amount invalid.');
        require(db.userTable.userInviteList[userAddr]==address(0) || db.userTable.userInviteList[userAddr]==msg.sender,'user has been invited');
        require(db.userTable.userList[userAddr].arbitExOrderCount<=0,'user has an unclosed arbit');
      }
      {
        if(db.userTable.userInviteList[userAddr]==address(0)){
          string memory originData='InviterAddress:';
          originData=LibStrings.strConcat(originData,LibStrings.addressToString(msg.sender));
          Sign memory sig=Sign(v,r,s);
          require( SignHelper.verifyString(originData,sig)==userAddr,'signature invalid');
        }

      }
      uint nAddAmount=0;
      uint nSubAmount=0;
      {
        uint nCurrentAmount=db.userTable.userSponsorData[msg.sender].sponsorBalances[userAddr];
         if(nCurrentAmount>=amount){
           nSubAmount=nCurrentAmount.sub(amount);
         }else{
            nAddAmount=amount.sub(nCurrentAmount);
         }
      }
      {
        if(nAddAmount>0){
          _lockToken(msg.sender,db.config.dotcContract,nAddAmount);

          db.userTable.userSponsorData[msg.sender].sponsorBalances[userAddr]=db.userTable.userSponsorData[msg.sender].sponsorBalances[userAddr].add(nAddAmount);
          db.userTable.userSponsorData[msg.sender].totalSupply=db.userTable.userSponsorData[msg.sender].totalSupply.add(nAddAmount);
        }else if(nSubAmount>0){
           _unLockToken(msg.sender,db.config.dotcContract,nSubAmount);

          db.userTable.userSponsorData[msg.sender].sponsorBalances[userAddr]=db.userTable.userSponsorData[msg.sender].sponsorBalances[userAddr].sub(nSubAmount);
          db.userTable.userSponsorData[msg.sender].totalSupply=db.userTable.userSponsorData[msg.sender].totalSupply.sub(nSubAmount);
        }
      }
      if(db.userTable.userInviteList[userAddr]==address(0)){
          db.userTable.userInviteList[userAddr]=msg.sender;
      }

      result=true;
      emit _SponsorUpdated(msg.sender,userAddr,amount);
    }
    function checkInvitorSign(address userAddr,uint8 v, bytes32 r,bytes32 s) external view returns (bool result){
       //console.log("msg.sender:",msg.sender);
       string memory originData='InviterAddress:';
       originData=LibStrings.strConcat(originData,LibStrings.addressToString(msg.sender));
       //console.log(originData);
       Sign memory sig=Sign(v,r,s);
       address newSigner=SignHelper.verifyString(originData,sig);
       //console.log('newSigner:',newSigner);
       result=(newSigner==userAddr);
    }
    function querySponsorAmount(address userAddr) external view returns(address invitor,uint amount){
      invitor=db.userTable.userInviteList[userAddr];
      if(invitor!=address(0)){
        amount= db.userTable.userSponsorData[invitor].sponsorBalances[userAddr];
      }
    }

    function applyVIP() external returns (bool result) {
      UserInfo storage info=db.userTable.userList[msg.sender];
      require(info.isVIP == false,'user has been vip');
      require(db.stakingTable.poolA[db.config.dotcContract].accountStakings[msg.sender].balance.add(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance)>=consts.vipDOTC,"insufficient total staking DOTC balance");

//      if(!info.isVIP)
      {
          //update vip state
          db.userTable.userList[msg.sender].isVIP=true;
          result=true;
      }
      emit _VIPApplied(msg.sender,result);
    }

    function queryVIP(address userAddr) external view returns (bool) {
       return db.userTable.userList[userAddr].isVIP;
    }
    function tokenApproveQuery(address token) external view returns(uint256 amount){
      amount=LibERC20.approveQuery(token,address(this));
    }
    function tokenDeposit(address token,uint amount) external returns (bool result) {
      require(!db.config.isPauseAsset,'system paused');
      require(token!=address(0),'token invalid');
      require(amount>0,'amount must be greater than 0');
      db.userTable.userAssets[msg.sender][token].available=db.userTable.userAssets[msg.sender][token].available.add(amount);
      LibERC20.transferFrom(token, msg.sender, address(this), amount);

      emit _tokenDeposited(msg.sender,token,amount);

      return true;

    }
    function tokenWithdraw(address token,uint amount) external returns (bool) {
      require(!db.config.isPauseAsset,'system paused');
      require(token!=address(0),'token invalid');
      require(amount>0,'amount must be greater than 0');

      if (token == db.config.dotcContract) {
          (bool isLock,address lendToken) =  _checkLendLock(msg.sender);
          require(token != lendToken,'dotc token lending');
      }

      uint avail=db.userTable.userAssets[msg.sender][token].available;
      require(avail>=amount,"insufficient balance");
      db.userTable.userAssets[msg.sender][token].available=db.userTable.userAssets[msg.sender][token].available.sub(amount);
      LibERC20.transfer(token, msg.sender, amount);
      emit _tokenWithdrawed(msg.sender,token,amount);

      return true;

    }
    function tokenQuery(address token) external view returns (uint avail,uint locked,uint canUnlocked,uint nonUnlocked) {
      avail=db.userTable.userAssets[msg.sender][token].available;
      locked=db.userTable.userAssets[msg.sender][token].locked;
      (canUnlocked,nonUnlocked)=_queryUnlockedAmount(msg.sender,token);
    }
    function queryUnlockedAmount(address token) external view returns(uint canUnlocked,uint nonUnlocked){
       (canUnlocked,nonUnlocked)=_queryUnlockedAmount(msg.sender,token);
    }
    function releaseUnlockedAmount(address token) external returns(uint canUnlocked){
       canUnlocked=_releaseUnlockedAmount(msg.sender,token);
       emit _ReleaseUnlockAmount(msg.sender,token,canUnlocked);
    }
    /******arbit interfaces */
    function applyArbiter() external returns (bool result) {
       require(!db.arbitTable.arbitUserList[msg.sender].isActive,"user has been an arbiter");
       require(db.stakingTable.poolA[db.config.dotcContract].accountStakings[msg.sender].balance.add(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance)>=consts.arbiterDOTC,"insufficient total staking DOTC balance");
       require(db.userTable.userAssets[msg.sender][db.config.dotcContract].available>=consts.arbitParam.arbiterApplyCost,'insufficient available DOTC balance');

       if(!db.arbitTable.arbitUserList[msg.sender].isActive){
          //sub assets
          if(consts.arbitParam.arbiterApplyCost>0){
              db.userTable.userAssets[msg.sender][db.config.dotcContract].available=db.userTable.userAssets[msg.sender][db.config.dotcContract].available.sub(consts.arbitParam.arbiterApplyCost);
              db.arbitTable.arbitUserList[msg.sender].lockedToken=db.config.dotcContract;
              db.arbitTable.arbitUserList[msg.sender].lockedAmount=db.arbitTable.arbitUserList[msg.sender].lockedAmount.add(consts.arbitParam.arbiterApplyCost);
          }
          //update
          db.arbitTable.arbitUserList[msg.sender].isActive=true;
          db.arbitTable.arbitUserList[msg.sender].applayTime=block.timestamp;
          //add to arbiterlist
          (bool isFind,uint index)=DOTCLib.Contains(db.arbitTable.arbiterList,uint(uint160(msg.sender)));
          if(!isFind){
            db.arbitTable.arbiterList.push(uint(uint160(msg.sender)));
          }
          result=true;
          emit _ArbitApplied(msg.sender,result);
      }
    }
    function cancelArbiter() external returns (bool result) {
        require(db.arbitTable.arbitUserList[msg.sender].isActive,"user is not an arbiter");
        //update arbit state
        _removeArbiterFromDB(msg.sender);
        result=true;
        emit _ArbitCancelled(msg.sender,result);
    }
    function forceCancelArbiter(address userAddr) external returns (bool result) {
        LibDiamond.enforceIsContractOwner();
       require(db.arbitTable.arbitUserList[userAddr].isActive,"user is not an arbiter");
        //update arbit state
        _removeArbiterFromDB(userAddr);
        result=true;
        emit _ArbitCancelled(userAddr,result);
    }
    function queryArbiter(address userAddr) external view returns(bool result){
        result=db.arbitTable.arbitUserList[userAddr].isActive;
    }
    function queryArbiterHandleCount(address userAddr) external view returns(uint){
        require(db.arbitTable.arbitUserList[userAddr].isActive,'user is not an arbiter');
        return db.arbitTable.arbitUserList[userAddr].nHandleCount;
    }
    function queryArbiterListCount() external view returns(uint count){
        return _getArbiterLength();
    }
    function queryArbiterList() external view returns(uint[] memory){
        return db.arbitTable.arbiterList;
    }

    function queryArbiterLocked(address userAddr) external view returns(uint amount){
        require(db.arbitTable.arbitUserList[userAddr].isActive,"user is not an arbiter");
        amount=db.arbitTable.arbitUserList[userAddr].lockedAmount;
    }

    function queryUserOrderDB(address userAddr) external view returns(UserOrder memory){
      return db.orderTable.userOrderDb[userAddr];
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import '../defines/dUser.sol';
import '../defines/dOrder.sol';
import '../defines/dRisk.sol';
import '../defines/dMiningPool.sol';
import '../defines/dStaking.sol';
import '../defines/dArbit.sol';
import '../defines/dCommon.sol';
import '../defines/dTotal.sol';
import '../defines/dLend.sol';

library LibAppStorage {
     bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamondApp.standard.dotcyz.storage");
    //Diamond Storage data
    struct AppStorage {
        Config config;
        /****** AdOrder ****/
        OrderTable orderTable;
        /****** AdUser ****/
        UserTable userTable;
        /****** DOTCArbit ****/
        ArbitTable arbitTable;
        /****** DOTCStaking ****/
        StakingTable stakingTable;
        /*******DAO data */
        DAOData daoData;
        //spare value for future
        mapping(address => uint) tokenWhiteList;
        //lendTable
        LendTable  lendTable;
    }
    
    function appStorage() internal pure returns (AppStorage storage es) {
     bytes32 position = DIAMOND_STORAGE_POSITION;
     assembly {
       es.slot := position
    }
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import '../utils/SafeMath.sol';
import '../defines/dCutFacet.sol';
//import "hardhat/console.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.dotcyz.storage");
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct DiamondStorage {
        mapping(bytes4 => bytes32) facets;
        mapping(uint256 => bytes32) selectorSlots;
        uint16 selectorCount;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
        address contractManager;
    }
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner,_newOwner);
    }
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }
    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }
    function enforceIsContractManager() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(msg.sender!=address(0),'invalid sender');
        require(msg.sender == ds.contractOwner || msg.sender == ds.contractManager , "LibDiamond: Must be contract owner or manager");
    }
    modifier onlyOwner {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut,address _init,bytes memory _calldata) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        {
            for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
                FacetInfo memory facetInfo=FacetInfo(
                  selectorCount,
                    selectorSlot,
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].action,
                    _diamondCut[facetIndex].functionSelectors
                );
                (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(facetInfo);
            }
            if (selectorCount != originalSelectorCount) {
                ds.selectorCount = uint16(selectorCount);
            }
            // If last selector slot is not full
            if (selectorCount % 8 > 0) {
                ds.selectorSlots[selectorCount / 8] = selectorSlot;
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }
    function addReplaceRemoveFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32) {
        require(facetInfo._selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (facetInfo._action == IDiamondCut.FacetCutAction.Add) {
           (facetInfo._selectorCount, facetInfo._selectorSlot) = _AddFacetSelectors(facetInfo);
        } else if (facetInfo._action == IDiamondCut.FacetCutAction.Replace) {
           (facetInfo._selectorCount, facetInfo._selectorSlot) = _ReplaceFacetSelectors(facetInfo);
        } else if (facetInfo._action == IDiamondCut.FacetCutAction.Remove) {
           (facetInfo._selectorCount, facetInfo._selectorSlot) =_RemoveFacetSelectors(facetInfo);
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }
    function _AddFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32) {
        require(facetInfo._newFacetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(facetInfo._newFacetAddress, "LibDiamondCut: Add facet has no code");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < facetInfo._selectors.length; selectorIndex++) {
            bytes4 selector = facetInfo._selectors[selectorIndex];
            bytes32 oldFacet = ds.facets[selector];
            //check if exists
            require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
            // add facet for selector
            ds.facets[selector] = bytes20(facetInfo._newFacetAddress) | bytes32(facetInfo._selectorCount);
            uint256 selectorInSlotPosition = (facetInfo._selectorCount % 8) * 32;
            // clear selector position in slot and add selector
            facetInfo._selectorSlot = (facetInfo._selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
            // if slot is full then write it to storage
            if (selectorInSlotPosition == 224) {
                ds.selectorSlots[facetInfo._selectorCount / 8] = facetInfo._selectorSlot;
                facetInfo._selectorSlot = 0;
            }
            facetInfo._selectorCount++;
        }
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }
    function _ReplaceFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32) {
        require(facetInfo._newFacetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(facetInfo._newFacetAddress, "LibDiamondCut: Replace facet has no code");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < facetInfo._selectors.length; selectorIndex++) {
            bytes4 selector = facetInfo._selectors[selectorIndex];
            bytes32 oldFacet = ds.facets[selector];
            address oldFacetAddress = address(bytes20(oldFacet));
            // only useful if immutable functions exist
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != facetInfo._newFacetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(facetInfo._newFacetAddress);
            //update ds.selectorSlots
            uint256 selectorInSlotPosition = (facetInfo._selectorCount % 8) * 32;
            // clear selector position in slot and add selector
            facetInfo._selectorSlot = (facetInfo._selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
            // if slot is full then write it to storage
            if (selectorInSlotPosition == 224) {
                ds.selectorSlots[facetInfo._selectorCount / 8] = facetInfo._selectorSlot;
                facetInfo._selectorSlot = 0;
            }
            facetInfo._selectorCount++;
        }
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }
    function _RemoveFacetSelectors(FacetInfo memory facetInfo) internal returns (uint256, bytes32){
        require(facetInfo._newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        uint256 selectorSlotCount = facetInfo._selectorCount / 8;
        uint256 selectorInSlotIndex = (facetInfo._selectorCount % 8) - 1;
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < facetInfo._selectors.length; selectorIndex++) {
            if (facetInfo._selectorSlot == 0) {
                // get last selectorSlot
                selectorSlotCount--;
                facetInfo._selectorSlot = ds.selectorSlots[selectorSlotCount];
                selectorInSlotIndex = 7;
            }
            bytes4 lastSelector;
            uint256 oldSelectorsSlotCount;
            uint256 oldSelectorInSlotPosition;
            // adding a block here prevents stack too deep error
            {
                bytes4 selector = facetInfo._selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                // only useful if immutable functions exist
                require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                // replace selector with last selector in ds.facets
                // gets the last selector
                lastSelector = bytes4(facetInfo._selectorSlot << (selectorInSlotIndex * 32));
                if (lastSelector != selector) {
                    // update last selector slot position info
                    ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                }
                delete ds.facets[selector];
                uint256 oldSelectorCount = uint16(uint256(oldFacet));
                oldSelectorsSlotCount = oldSelectorCount / 8;
                oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
            }
            if (oldSelectorsSlotCount != selectorSlotCount) {
                bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                // clears the selector we are deleting and puts the last selector in its place.
                oldSelectorSlot =
                    (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                    (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                // update storage with the modified slot
                ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
            } else {
                // clears the selector we are deleting and puts the last selector in its place.
                facetInfo._selectorSlot =
                    (facetInfo._selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                    (bytes32(lastSelector) >> oldSelectorInSlotPosition);
            }
            if (selectorInSlotIndex == 0) {
                delete ds.selectorSlots[selectorSlotCount];
                facetInfo._selectorSlot = 0;
            }
            selectorInSlotIndex--;
        }
        facetInfo._selectorCount = selectorSlotCount * 8 + selectorInSlotIndex + 1;
        return (facetInfo._selectorCount, facetInfo._selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "../interfaces/IERC20.sol";

library LibERC20 {

   function approveQuery(address _token,address _spender) internal view returns(uint256 _amount){
       _amount=IERC20(_token).allowance(msg.sender,_spender);
   }

   function queryDecimals(address _token) internal view returns(uint256 decimals){
       decimals=IERC20(_token).decimals();
   }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
     ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: Address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: Address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: contract call returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: contract call reverted");
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function uintStr(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    function StrCmp(string memory s1, string memory s2) internal pure returns(bool){
        bytes memory _s1=bytes(s1);
        bytes memory _s2=bytes(s2);
        uint len=_s1.length;
        for(uint i=0;i<len;i++){
            if(_s1[i]!=_s2[i])
                return false;
        }
        return true;
    }

    
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function addressToString(address _address) internal pure returns(string memory) {
       bytes32 _bytes = bytes32(uint256(uint160(_address)));
       bytes memory HEX = "0123456789abcdef";
       bytes memory _string = new bytes(42);
       _string[0] = '0';
       _string[1] = 'x';
       for(uint i = 0; i < 20; i++) {
           _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
           _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
       }
       return string(_string);
    }
    /// string to bytes32
    function stringToBytes32(string memory source) internal pure returns(bytes32 result){
        assembly{
            result := mload(add(source,32))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import '../interfaces/IDOTCFacetBase.sol';

import '../libraries/AppStorage.sol';
import '../utils/SafeMath.sol';
import '../utils/RandomHelper.sol';
import '../libraries/DOTCLib.sol';
import '../libraries/LibERC20.sol';
import '../libraries/LibStrings.sol';

import '../defines/dUser.sol';
import '../defines/dOrder.sol';
import '../defines/dRisk.sol';
import '../defines/dMiningPool.sol';
import '../defines/dStaking.sol';
import '../defines/dArbit.sol';
import '../defines/dCommon.sol';
import '../defines/dTotal.sol';
import '../defines/dLend.sol';

import '../libraries/LibStrings.sol';
import '../oracle/IDOTCOracleRobot.sol';

//import "hardhat/console.sol";

/**
 * @dev DOTC facet base class
 */
contract DOTCFacetBase is IDOTCFacetBase {
    using SafeMath for uint;
    LibAppStorage.AppStorage internal db;
    ConstInstance internal consts;

   uint constant MIN_ARBITER_NUM=3;

   function _lockToken(address userAddr,address token,uint lockAmount) internal {
      require(db.userTable.userAssets[userAddr][token].available >= lockAmount,"insufficient available balance");
      db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.sub(lockAmount);
      db.userTable.userAssets[userAddr][token].locked=db.userTable.userAssets[userAddr][token].locked.add(lockAmount);
   }
   function _unLockToken(address userAddr,address token,uint unLockAmount) internal {
      if(unLockAmount>db.userTable.userAssets[userAddr][token].locked){
         unLockAmount=db.userTable.userAssets[userAddr][token].locked;
      }
      //require(db.userTable.userAssets[userAddr][token].locked >= unLockAmount,"insufficient locked balance");
      db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.add(unLockAmount);
      db.userTable.userAssets[userAddr][token].locked=db.userTable.userAssets[userAddr][token].locked.sub(unLockAmount);
   }
   function _getPubDOTCPrice() internal view returns(uint dotcPrice){
        if(consts.priceMode==0 && db.daoData.oracleInfo.robotAddr!=address(0)){
          //uniswap orcle price
          {
               try IDOTCOracleRobot(db.daoData.oracleInfo.robotAddr).getRealTimePrice(true) returns(uint price0,uint price1,uint priceDest,uint time)
               {
                  dotcPrice=priceDest;
               }catch{
                  dotcPrice=consts.maxDotcPrice;
               }
          }
        }
        else{
          //manual
          dotcPrice=db.daoData.oracleInfo.currentPrice;
        }
        //console.log('db price:',dotcPrice);
        if(dotcPrice>=consts.maxDotcPrice){
            dotcPrice=consts.maxDotcPrice;
        }
   }
   function _checkUpdateOracleTime() internal {
      if(consts.priceMode==0 && db.daoData.oracleInfo.robotAddr!=address(0)){
          //uniswap orcle price
          try IDOTCOracleRobot(db.daoData.oracleInfo.robotAddr).checkUpdateTimestamp(){

          }catch{

          }
      }
   }
   function _calculateOrderFee(address token,uint feeRate,uint orderValue,uint dotcAmount,bool isCheckMax) internal view returns(FeeInfo memory feeInfo){
      if(feeRate<=0 || orderValue<=0){
         feeInfo.feeValue=0;
         feeInfo.feeType=CoinType.UNKNOWN;
         return feeInfo;
      }
      if(token==db.config.usdtContract){
         //usdt order
         feeInfo.feeValue=orderValue.mul(feeRate).div(10000);
         if(feeInfo.feeValue<consts.priceParam.nUsdtDecimals/10) feeInfo.feeValue=consts.priceParam.nUsdtDecimals/10;
         if(isCheckMax){
           if(feeInfo.feeValue>100*consts.priceParam.nUsdtDecimals) feeInfo.feeValue=100*consts.priceParam.nUsdtDecimals;
         }
         feeInfo.feeType=CoinType.USDT;
      }else{
         //non-usdt order
         feeInfo.feeValue=dotcAmount.mul(feeRate).div(10000);
         //uint nMin=dotcAmount.mul(nUsdtDecimals/10).div(orderValue);
         //if(feeInfo.feeValue<nMin) feeInfo.feeValue=nMin;
         if(feeInfo.feeValue<consts.priceParam.nDOTCDecimals/10000) feeInfo.feeValue=consts.priceParam.nDOTCDecimals/10000;
         if(isCheckMax){
            if(feeInfo.feeValue>100*consts.priceParam.nDOTCDecimals) feeInfo.feeValue=100*consts.priceParam.nDOTCDecimals;
         }

         feeInfo.feeType=CoinType.DOTC;
      }
   }
   function _backSELLAdOrderLeftFee(string calldata adOrderId) internal{
      if(db.orderTable.otcAdOrders[adOrderId].detail.leftAmount<=0) return;
      if(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue<=0) return;
      if(db.orderTable.otcAdOrders[adOrderId].side==ExchangeSide.BUY) return;
      uint leftFeeValue=db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue.mul(db.orderTable.otcAdOrders[adOrderId].detail.leftAmount).div(db.orderTable.otcAdOrders[adOrderId].detail.totalAmount);
      //back left fee
      if(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeType==CoinType.USDT){
         _unLockToken(db.orderTable.otcAdOrders[adOrderId].makerAddress,db.config.usdtContract,leftFeeValue);
         db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue=db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue.sub(leftFeeValue);
      }else if(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeType==CoinType.DOTC){
        _unLockToken(db.orderTable.otcAdOrders[adOrderId].makerAddress,db.config.dotcContract,leftFeeValue);
        db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue=db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue.sub(leftFeeValue);
      }
   }
   function _getBackRate() internal view returns(uint backRate){
      if(db.daoData.miningPool.poolTokens[db.config.dotcContract].initSupply<=0 || db.daoData.miningPool.poolTokens[db.config.dotcContract].currentSupply<=0) backRate=0;
      uint nPeriodCount=db.daoData.miningPool.poolTokens[db.config.dotcContract].periodCount;
//    if(nPeriodCount>10**12) nPeriodCount=10**12;
      if(nPeriodCount>=10) nPeriodCount=10;
      backRate=db.daoData.miningPool.poolTokens[db.config.dotcContract].initBackRate.mul(700 ** nPeriodCount).div(1000 ** nPeriodCount);
      if(backRate>1000) backRate=1000;
   }
   function _getDOTCNumFromUSDT(uint usdtValue) internal view returns(uint dotcAmount){
      dotcAmount= usdtValue.mul(_getPubDOTCPrice()).div(consts.priceParam.nUsdtDecimals);
   }
   function _RemoveExOrderFromList(string memory adOrderId,string memory exOrderId) internal {
       _removeStrFromList(db.orderTable.otcAdOrderCounter[adOrderId], exOrderId);
   }
   function _removeStrFromList(string[] storage list,string memory str) internal{
      if(list.length<=0) return;
      uint index=0;
      bool isFind=false;
      for(uint i=0;i<list.length;i++){
         if(LibStrings.StrCmp(list[i],str)){
            isFind=true;
            index=i;
            break;
         }
      }
      if(isFind){
         if(list.length==1){
              list.pop();
          }else if(index==list.length-1){
              list.pop();
          }
          else{
            for (uint j = index; j < list.length-1; j++) {
              list[j] = list[j+1];
            }
            list.pop();
         }
      }
   }
   function _getAdOrderExCount(string memory orderId) internal view returns(uint length){
      if(db.orderTable.otcAdOrderCounter[orderId].length <= 0){
        length=0;
      }else{
        for(uint i=0;i<db.orderTable.otcAdOrderCounter[orderId].length;i++){
          if(bytes(db.orderTable.otcAdOrderCounter[orderId][i]).length>0){
              if (db.orderTable.otcTradeOrders[orderId][db.orderTable.otcAdOrderCounter[orderId][i]].detail.state < TradeState.Completed) {
                  length++;
              }
        }
       }
      }
    }

   function _queryUnlockedAmount(address userAddr,address token) internal view returns(uint canUnlocked,uint nonUnlocked){
     AssetLockInfo[] memory assetLockInfo=db.userTable.userLockedList[userAddr][token];
     if(assetLockInfo.length<=0){
        canUnlocked=0;
        nonUnlocked=0;
        return (canUnlocked,nonUnlocked);
     }
     for(uint i=0;i<assetLockInfo.length;i++){
        if(assetLockInfo[i].unlockDeadline>0 && !assetLockInfo[i].isUnLocked){
            uint unlockDeadline = assetLockInfo[i].unlockDeadline;
           if(block.timestamp>=unlockDeadline){
              canUnlocked=canUnlocked.add(assetLockInfo[i].amount);
           }else if(unlockDeadline - block.timestamp > 604800){
              canUnlocked=canUnlocked.add(assetLockInfo[i].amount);
           }else{
              nonUnlocked=nonUnlocked.add(assetLockInfo[i].amount);
           }
        }
     }
   }
   function _releaseUnlockedAmount(address userAddr,address token) internal returns(uint canUnlocked){
     AssetLockInfo[] memory assetLockInfo=db.userTable.userLockedList[userAddr][token];
     if(assetLockInfo.length<=0){
        canUnlocked=0;
        return canUnlocked;
     }
     for(uint i=0;i<assetLockInfo.length;i++){
         uint unlockDeadline = assetLockInfo[i].unlockDeadline;
        if((block.timestamp>=assetLockInfo[i].unlockDeadline || unlockDeadline - block.timestamp > 604800)
             && assetLockInfo[i].unlockDeadline>0 && !assetLockInfo[i].isUnLocked){
           //can unlock
           db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.add(assetLockInfo[i].amount);
           db.userTable.userLockedList[userAddr][token][i].isUnLocked=true;
           db.userTable.userLockedList[userAddr][token][i].unlockDeadline=0;
           canUnlocked=canUnlocked.add(assetLockInfo[i].amount);
           delete db.userTable.userLockedList[userAddr][token][i];
        }
     }

   }
   function _addUnlockedAmount(address _userAddr,address _token,uint _amount,uint _timePeriod) internal{
      if(_amount<=0) return;
      AssetLockInfo memory assetLockInfo=AssetLockInfo(_amount,block.timestamp,false,block.timestamp.add(_timePeriod));
      db.userTable.userLockedList[_userAddr][_token].push(assetLockInfo);
   }
   /*******arbit method */
   function _removeArbiterFromDB(address arbiter) internal{
      uint aValue=uint(uint160(arbiter));
      uint index=DOTCLib._findArrayIndexByValue(db.arbitTable.arbiterList,aValue);
      if(index>0){
         index--;
         if(db.arbitTable.arbiterList.length==1 || index==db.arbitTable.arbiterList.length-1){ //
             db.arbitTable.arbiterList.pop();
         } else{
            db.arbitTable.arbiterList[index]=db.arbitTable.arbiterList[db.arbitTable.arbiterList.length-1];
             db.arbitTable.arbiterList.pop();
         }
      }
      if(db.arbitTable.arbitUserList[arbiter].isActive){
         if(db.arbitTable.arbitUserList[arbiter].lockedAmount>0){
            //back assets
            db.userTable.userAssets[arbiter][db.config.dotcContract].available=db.userTable.userAssets[arbiter][db.config.dotcContract].available.add(db.arbitTable.arbitUserList[arbiter].lockedAmount);
         }

         delete db.arbitTable.arbitUserList[arbiter];
      }
   }
   function _getArbiterLength() internal view returns(uint count){
      for(uint i=0;i<db.arbitTable.arbiterList.length;i++){
         if(db.arbitTable.arbiterList[i]!=0){
            count++;
         }
      }
   }
   //staking
   function _calculatePeriod() internal view returns(uint v1Time,uint v1Num,uint v2Time,uint v2Num){
      uint poolStartTime=db.stakingTable.startTime;
      if(block.timestamp<poolStartTime){
        //pool closing
        return(0,0,0,0);
      }
      uint mod=(block.timestamp-poolStartTime) % consts.stakingParam.bonusPeriod;
      v2Time=block.timestamp.sub(mod);
      v1Num= v2Time.sub(poolStartTime) / consts.stakingParam.bonusPeriod;
      if(v1Num>0){
        v1Time=v2Time.sub(consts.stakingParam.bonusPeriod);
      }
      v2Num=v1Num+1;
    }
   function _updatePoolPeriod() internal{
       (uint v1Time,uint v1Num,uint v2Time,uint v2Num)=_calculatePeriod();
       if(v2Num != db.stakingTable.poolA[db.config.dotcContract].v2Info.periodNum){
         //update poolA
         db.stakingTable.poolA[db.config.dotcContract].v1Info.periodNum=v1Num;
         db.stakingTable.poolA[db.config.dotcContract].v1Info.startTime=v1Time;
         uint leftBonus=db.stakingTable.poolA[db.config.dotcContract].v1Info.totalUSDTBonus.sub(db.stakingTable.poolA[db.config.dotcContract].v1Info.Bonused);
         db.stakingTable.poolA[db.config.dotcContract].v1Info.totalUSDTBonus=leftBonus.add(db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus);
         db.stakingTable.poolA[db.config.dotcContract].v1Info.Bonused=0;

         db.stakingTable.poolA[db.config.dotcContract].v2Info.periodNum=v2Num;
         db.stakingTable.poolA[db.config.dotcContract].v2Info.startTime=v2Time;
         db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus=0;
         db.stakingTable.poolA[db.config.dotcContract].v2Info.Bonused=0;

       }
       if(v2Num!=db.stakingTable.poolB[db.config.dotcContract].v2Info.periodNum){
         //update poolB
         //update poolA
         db.stakingTable.poolB[db.config.dotcContract].v1Info.periodNum=v1Num;
         db.stakingTable.poolB[db.config.dotcContract].v1Info.startTime=v1Time;
         uint leftBonus=db.stakingTable.poolB[db.config.dotcContract].v1Info.totalUSDTBonus.sub(db.stakingTable.poolB[db.config.dotcContract].v1Info.Bonused);
         db.stakingTable.poolB[db.config.dotcContract].v1Info.totalUSDTBonus=leftBonus.add(db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus);
         db.stakingTable.poolB[db.config.dotcContract].v1Info.Bonused=0;

         db.stakingTable.poolB[db.config.dotcContract].v2Info.periodNum=v2Num;
         db.stakingTable.poolB[db.config.dotcContract].v2Info.startTime=v2Time;
         db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus=0;
         db.stakingTable.poolB[db.config.dotcContract].v2Info.Bonused=0;
       }

   }
   function _checkLendLock(address userAddr) internal view returns(bool isLock,address lendToken){
       LendResult storage userLend=db.lendTable.userLend[userAddr];
      if(userLend.state==2){
         //lending
         lendToken=userLend.lend.lendToken;
         isLock=db.lendTable.poolTokens[lendToken].config.isLock;
      }
   }

}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y>0,'ds-math-div-overflow');
        z = x / y;
        //require((z = x / y) * y == x, 'ds-math-div-overflow');
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
//import "hardhat/console.sol";
import "../libraries/LibStrings.sol";
import '../defines/dCommon.sol';

library SignHelper{
  
    function verifyString(string memory message, Sign memory sig) internal pure returns (address signer) {
        // The message header; we will fill in the length next

        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthLength= getMsgLength(message,header);
        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, sig.v, sig.r, sig.s);
        //return address(0);
    }

    function getMsgLength(string memory message,string memory header) internal pure returns(uint256 lengthLength){

       uint256 lengthOffset;
       uint256 length;
       assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }
        // Maximum length we support
        require(length <= 999999);
        // The length of the message's length in base-10
        {
            // The divisor to get the next left-most message length digit
            uint256 divisor = 100000;
            // Move one digit of the message length to the right at a time
            {
              while (divisor != 0) {
                // The place value at the divisor
                uint256 digit = length / divisor;
                if (digit == 0) {
                    // Skip leading zeros
                    if (lengthLength == 0) {
                        divisor /= 10;
                        continue;
                    }
                }
                // Found a non-zero digit or non-leading zero digit
                lengthLength++;
                // Remove this digit from the message length's current value
                length -= digit * divisor;
                // Shift our base-10 divisor over
                divisor /= 10;
                // Convert the digit to its ASCII representation (man ascii)
                digit += 0x30;
                // Move to the next character and write the digit
                lengthOffset++;
                assembly {
                    mstore8(lengthOffset, digit)
                }
              }
            }
            
            // The null string requires exactly 1 zero (unskip 1 leading 0)
            if (lengthLength == 0) {
                lengthLength = 1 + 0x19 + 1;
            } else {
                lengthLength += 1 + 0x19;
            }
        }
     

        return lengthLength;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

struct LendTable{
    bool isForbidden;
    //token =>poolInfo
    mapping(address=> LendPoolInfo) poolTokens;
    //user pledge
    mapping(address=> LendResult) userLend;
    //global param
    LendGlobal global;
    //pledge param
    PledgeParam pledgeParam;
    //lend param
    LendParam lendParam;

}
struct LendPoolInfo{
   //pledge
   uint totalPledge;
   uint pledgeAccount;
   //lend
   uint totalLend;
   uint lendAccount;
   //config
   LendConfig config;
}
struct LendConfig{
    bool isVip;
    uint pledgeRate;//decimal 10000
    uint lendRate;//decimal 10000
    bool isLock;
}
struct PledgeParam{
    //pledge
    uint minPledge;//20 USDT
    uint maxPledge;//20000 USDT
    uint bonusRate; //decimal 10000
    uint minBonusPeriod;
    bool enabled; // pledge switch
}
struct LendParam{
    //lend
    uint lendRate;//decimal:10000
    uint maxLendValue;//USDT,5000U
    uint minInterest;//0.1U
    uint clearRate;//decimal 100000
    bool enabled; // lend switch

}
struct LendGlobal{
      //global
    uint minDOTCPrice;//protect price,spared
    uint maxDOTCPrice;//protect price,

    uint riskPrice;//DOTC PRICE for risk
    uint priceTime;//DOTC PRICE START TIME
}
struct LendResult{
    //pledge
    UserPledge pledge;
    //lend
    UserLend lend;
    uint8 state; //0-clear,1-pledged,2-lending
}
struct UserPledge{
    address pledgeToken;
    uint pledgeAmount;
    uint pledgeTime;
    uint pledgePeriod;
    uint dotcPrice;
    uint bonusRate;//decimal 10000
}
struct UserLend{
    address lendToken;
    uint lendTime;
    uint lendAmount;
    uint lendRate;//decimal 10000
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "../interfaces/IDiamondCut.sol";

struct FacetInfo{
    uint256 _selectorCount;
    bytes32 _selectorSlot;
    address _newFacetAddress;
    IDiamondCut.FacetCutAction _action;
    bytes4[] _selectors;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;
interface IDOTCFacetBase{
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface IDOTCOracleRobot {

   function initOracleRobot(address _uniFactory, address _dotcAddr, address _wethAddr,address _usdtAddr,bool _isTwoPair) external;

   function getRealTimePrice(bool isReverse) external view returns(uint price0,uint price1,uint price,uint blockTimestamp);

   function checkUpdateTimestamp() external;
   
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";

import '../utils/SafeMath.sol';

contract DOTCRiskFacet is DOTCFacetBase  {
     using SafeMath for uint; 
     event _RiskTokenAdded(address indexed userAddr,address indexed token,uint indexed amount); 
     event _RiskTokenRemoved(address indexed userAddr,address indexed token,uint indexed amount); 
     
     function AddTokenToRiskPool(address token,uint amount) external returns(bool result){
       require(token!=address(0),'token invalid');
       require(amount>0,'amount must be greater than 0');
       uint balance= IERC20(token).balanceOf(msg.sender);
       require(balance>=amount,'insufficient token balance');
       LibDiamond.enforceIsContractManager();
       //开始转账
       db.daoData.riskPool.poolTokens[token].currentSupply=db.daoData.riskPool.poolTokens[token].currentSupply.add(amount);
       db.daoData.riskPool.poolTokens[token].initSupply=db.daoData.riskPool.poolTokens[token].initSupply.add(amount);   
       LibERC20.transferFrom(token, msg.sender, address(this), amount);
           
       emit _RiskTokenAdded(msg.sender,token,amount);
       result=true;
     }

     function RemoveTokenFromRiskPool(address token,uint amount) external returns(bool result){
        require(token!=address(0),'token invalid');
        require(amount>0,'amount must be greater than 0');
        require(db.daoData.riskPool.poolTokens[token].currentSupply>=amount,'insufficient pool balance');
        LibDiamond.enforceIsContractOwner();
        db.daoData.riskPool.poolTokens[token].currentSupply=db.daoData.riskPool.poolTokens[token].currentSupply.sub(amount);
        LibERC20.transfer(token, msg.sender, amount);
        
        emit _RiskTokenRemoved(msg.sender,token,amount);
        result=true;
     }

     function queryRiskPoolInfo(address tokenAddr) external view returns(PoolInfo memory poolInfo){
         poolInfo=db.daoData.riskPool.poolTokens[tokenAddr];
     }

}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity ^0.7.0;

import "../utils/SafeMath.sol";

contract DOTCToken {
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 constant public DECIMALS = 12;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approved(address indexed from,address spender, uint256 value);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(uint256 initialSupply,string memory tokenName,string memory tokenSymbol){
        totalSupply = initialSupply * 10 ** uint256(DECIMALS);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        require(balanceOf[_from].add(balanceOf[_to]) == previousBalances,'transfer error');
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approved(msg.sender,_spender,_value);
        return true;
    }
   
}

// SPDX-License-Identifier: MIT
// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

import '../utils/SafeMath.sol';

contract DOTCTimelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 7 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;
    bool public adminInitialized;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");
        require(admin_ != address(0),'Zero address');
        admin = admin_;
        delay = delay_;
        adminInitialized = false;
    }

    // XXX: function() external payable { }
    receive() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (adminInitialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            adminInitialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";

import "../facetBase/DOTCStakingBase.sol";

import '../utils/SafeMath.sol';
contract DOTCStakingFacet is DOTCStakingBase {
    using SafeMath for uint;

    function AddUSDTBonusToStaking(uint lockType,uint amount) external returns(bool result){
       require(amount>0,'amount must be greater than 0');
       uint balance= IERC20(db.config.usdtContract).balanceOf(msg.sender);
       require(balance>=amount,'insufficient token balance');
       LibDiamond.enforceIsContractManager();
       //update period
       _updatePoolPeriod();
       if(lockType==0){
         db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus.add(amount);
         db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus.add(amount);
       }else{
         db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus.add(amount);
         db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus.add(amount);
       }
        //开始转账
       LibERC20.transferFrom(db.config.usdtContract, msg.sender, address(this), amount);

       emit _stakingDeposited(msg.sender,db.config.usdtContract,amount);

       result=true;
    }
    function addStakingA(uint amount) external returns (bool result) {
       {
          require(!db.config.isPause,'system paused');
          require(db.stakingTable.startTime>0 && db.stakingTable.startTime<=block.timestamp,'staking is not open yet');
          require(db.stakingTable.isEnableLock,'staking lock is disabled');

           (bool isLock,address lendToken) =  _checkLendLock(msg.sender);
           require(db.config.dotcContract != lendToken,'dotc token lending');

          require(db.stakingTable.poolA[db.config.dotcContract].totalAccount<=POOL_MAX,"Pool accounts have been the maximum");
          require(amount>=consts.stakingParam.poolAMin,'amount less than poolAMin');
          require(db.userTable.userAssets[msg.sender][db.config.dotcContract].available>=amount,"insufficient available balance");
       }
       //update period
       _updatePoolPeriod();
       //update
       db.userTable.userAssets[msg.sender][db.config.dotcContract].available=db.userTable.userAssets[msg.sender][db.config.dotcContract].available.sub(amount);
       _updateUserStaking(db.stakingTable.poolA[db.config.dotcContract],0,msg.sender,amount);

       result=true;

       emit _stakingAAdded(msg.sender,db.config.dotcContract,amount);
    }
    function addStakingB(uint amount) external returns (bool result) {
       {
          require(!db.config.isPause,'system paused');
          require(db.stakingTable.startTime>0 && db.stakingTable.startTime<=block.timestamp,'staking is not open yet');
          require(db.stakingTable.isEnableLock,'staking lock is disabled');

           (bool isLock,address lendToken) =  _checkLendLock(msg.sender);
           require(db.config.dotcContract != lendToken,'dotc token lending');

          require(db.stakingTable.poolB[db.config.dotcContract].totalAccount<=POOL_MAX,"Pool accounts have been the maximum");
          require(amount>=consts.stakingParam.poolBMin,'amount less than min');
          require(db.userTable.userAssets[msg.sender][db.config.dotcContract].available>=amount,"insufficient available balance");
       }
       //update period
       _updatePoolPeriod();
       //update
       db.userTable.userAssets[msg.sender][db.config.dotcContract].available=db.userTable.userAssets[msg.sender][db.config.dotcContract].available.sub(amount);
       _updateUserStaking(db.stakingTable.poolB[db.config.dotcContract],1,msg.sender,amount);

       result=true;

      emit _stakingBAdded(msg.sender,db.config.dotcContract,amount);
    }
    function unlockStaking(uint amount) external returns (bool result) {

       uint balance=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance;
       {
          require(!db.config.isPause,'system paused');
          require(db.stakingTable.isEnableUnLock,'staking unlock is disabled');
          require(balance>=amount,'insufficient locked balance');
          uint lastLockTime=block.timestamp.sub(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].lastLockTime);
          require(lastLockTime>=consts.stakingParam.unLockWaitTime,'you can not unlockStaking inside unlockWaittime');
          uint lastBonusTime=block.timestamp.sub(db.stakingTable.poolA[db.config.dotcContract].accountStakings[msg.sender].lastBonusTime);
          require(lastBonusTime>=consts.stakingParam.bonusUnlockTime,'you can not unlockStaking inside bonusUnlockTime');
       }
        //update period
       _updatePoolPeriod();
       //update v1,v2
       _updateUserStaking(db.stakingTable.poolB[db.config.dotcContract],1,msg.sender,0);
       //sub from v1,v2
       if(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount>=amount){
         db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount.sub(amount);
       }else{
         uint v1Balance=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount;
         db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount=0;
         db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v2.amount=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v2.amount.sub(amount.sub(v1Balance));
       }
       if(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount==0){
          db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.weightTime=0;
       }
       if(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v2.amount==0){
          db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v2.weightTime=0;
       }
       //update staking
       db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance=balance.sub(amount);
       db.stakingTable.poolB[db.config.dotcContract].totalSupply=db.stakingTable.poolB[db.config.dotcContract].totalSupply.sub(amount);
       balance=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance;
       {
          if(balance == 0){
              //all unlocked
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].lastLockTime=0;
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].lastBonusTime=0;
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.amount=0;
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.weightTime=block.timestamp;
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v1.isBonused=false;
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v2.amount=0;
              //db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].v2.weightTime=block.timestamp;

              db.stakingTable.poolB[db.config.dotcContract].totalAccount= db.stakingTable.poolB[db.config.dotcContract].totalAccount.sub(1);
          }
          //check vip
          uint totalStaking=db.stakingTable.poolA[db.config.dotcContract].accountStakings[msg.sender].balance.add(db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance);
          if(totalStaking < consts.vipDOTC){
              db.userTable.userList[msg.sender].isVIP=false;
          }
          //check arbitor
          if(totalStaking < consts.arbiterDOTC){
              _removeArbiterFromDB(msg.sender);
          }
       }
       //unlock balance
       _addUnlockedAmount(msg.sender,db.config.dotcContract,amount,consts.stakingParam.unLockWaitTime);
       //db.userTable.userAssets[msg.sender][db.config.dotcContract].available=db.userTable.userAssets[msg.sender][db.config.dotcContract].available.add(amount);
       result=true;
       emit _stakingUnlocked(msg.sender,db.config.dotcContract,amount);

    }
    function queryAvailBonus(uint lockType) external view returns(uint availBonus,uint totalBonus,uint lastBonusTime){
       (availBonus,totalBonus,lastBonusTime)=_queryUserAvailBonus(msg.sender,lockType);
    }
    function queryUserAvailBonus(address userAddr,uint lockType) external view returns(uint availBonus,uint totalBonus,uint lastBonusTime){
       (availBonus,totalBonus,lastBonusTime)=_queryUserAvailBonus(userAddr,lockType);
    }
    function queryLockAAmount() external view returns(uint balance,uint lastLockTime,uint v1Amount, uint v1WeightTime,uint v2Amount,uint v2WeightTime){
      balance=db.stakingTable.poolA[db.config.dotcContract].accountStakings[msg.sender].balance;
      lastLockTime=db.stakingTable.poolA[db.config.dotcContract].accountStakings[msg.sender].lastLockTime;
      (StakingDetail memory detail,uint v1Time,uint v2Time) = _queryLastLockInfo(db.stakingTable.poolA[db.config.dotcContract],msg.sender,1);
      v1Amount=detail.v1.amount;
      v1WeightTime=detail.v1.weightTime;
      v2Amount=detail.v2.amount;
      v2WeightTime=detail.v2.weightTime;
    }
    function queryLockBAmount() external view returns(uint balance,uint lastLockTime,uint v1Amount, uint v1WeightTime,uint v2Amount,uint v2WeightTime){
      balance=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].balance;
      lastLockTime=db.stakingTable.poolB[db.config.dotcContract].accountStakings[msg.sender].lastLockTime;
      (StakingDetail memory detail,uint v1Time,uint v2Time) =_queryLastLockInfo(db.stakingTable.poolB[db.config.dotcContract],msg.sender,1);
      v1Amount=detail.v1.amount;
      v1WeightTime=detail.v1.weightTime;
      v2Amount=detail.v2.amount;
      v2WeightTime=detail.v2.weightTime;
    }
    function queryUserStaking(address userAddr,uint lockType) external view returns(uint stakingAmount,uint tatalBonus,uint lastBonusTime){
      if(lockType==0){
         //PoolA
         stakingAmount=db.stakingTable.poolA[db.config.dotcContract].accountStakings[userAddr].balance;
         tatalBonus=db.stakingTable.poolA[db.config.dotcContract].accountStakings[userAddr].totalBonused;
         lastBonusTime=db.stakingTable.poolA[db.config.dotcContract].accountStakings[userAddr].lastBonusTime;
       }else{
         //PoolB
         stakingAmount=db.stakingTable.poolB[db.config.dotcContract].accountStakings[userAddr].balance;
         tatalBonus=db.stakingTable.poolB[db.config.dotcContract].accountStakings[userAddr].totalBonused;
         lastBonusTime=db.stakingTable.poolB[db.config.dotcContract].accountStakings[userAddr].lastBonusTime;
       }
    }
    function queryPoolInfo(uint lockType) external view returns(uint totalSupply,uint totalAccount,uint totalUSDTBonus,uint totalBonused){
      if(lockType==0){
        //PoolA
        totalSupply=db.stakingTable.poolA[db.config.dotcContract].totalSupply;
        totalAccount=db.stakingTable.poolA[db.config.dotcContract].totalAccount;
        totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus;
        totalBonused=db.stakingTable.poolA[db.config.dotcContract].totalBonused;
      }else{
        //Pool B
        totalSupply=db.stakingTable.poolB[db.config.dotcContract].totalSupply;
        totalAccount=db.stakingTable.poolB[db.config.dotcContract].totalAccount;
        totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus;
        totalBonused=db.stakingTable.poolB[db.config.dotcContract].totalBonused;
      }
    }
    function getMyBonus(uint lockType) external returns (bool result) {
      require(!db.config.isPause,'system paused');
      require(db.stakingTable.isEnableBonus,'staking bonus is paused now');

      if(lockType==0){
        //PoolA
        result=_takeBonus(db.stakingTable.poolA[db.config.dotcContract],0);
       }else{
        //PoolB
        result=_takeBonus(db.stakingTable.poolB[db.config.dotcContract],1);
       }
    }
    function queryStakingPeriod() external view returns(uint startTime,uint v1Time,uint v1Num,uint v2Time,uint v2Num){
      startTime=db.stakingTable.startTime;
      (v1Time,v1Num,v2Time,v2Num)=_calculatePeriod();
    }
    function queryPeriodInfo(uint lockType) external view returns(PoolPeriodInfo memory v1Info,PoolPeriodInfo memory v2Info){
      if(lockType==0){
        v1Info=db.stakingTable.poolA[db.config.dotcContract].v1Info;
        v2Info=db.stakingTable.poolA[db.config.dotcContract].v2Info;
      }else{
        v1Info=db.stakingTable.poolB[db.config.dotcContract].v1Info;
        v2Info=db.stakingTable.poolB[db.config.dotcContract].v2Info;
      }
    }
    function updateStakingPeriod() external{
       //update period
       _updatePoolPeriod();
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
import '../libraries/LibStrings.sol';

contract DOTCStakingBase is DOTCFacetBase {
    using SafeMath for uint;
    uint public constant POOL_MAX = 1e8; //POOL_MAX

    uint public constant POOLA_MAX_DAYS= 1440 days;  // 720 days

    event _stakingAAdded(address indexed userAddr,address indexed token,uint indexed amount);
    event _stakingBAdded(address indexed userAddr,address indexed token,uint indexed amount);
    event _stakingUnlocked(address indexed userAddr,address indexed token,uint indexed amount);
    event _stakingBonused(address indexed userAddr,address indexed token,uint indexed amount);
    event _stakingDeposited(address indexed userAddr,address indexed token,uint indexed amount);
       //staking
    function _takeBonus(StakingPool storage pool,uint poolType) internal returns(bool result){
        //update period
       _updatePoolPeriod();
       _updateUserStaking(pool,poolType,msg.sender,0);
       //check
       {
          require(pool.accountStakings[msg.sender].v1.weightTime>0,'locktime not enough');
          //uint lastBonusTime=block.timestamp.sub(pool.accountStakings[msg.sender].lastBonusTime);
          uint lastBonusTime = pool.accountStakings[msg.sender].lastBonusTime;
          //require(lastBonusTime>=consts.stakingParam.bonusWaitTime,'you can not get bonus right now.');
          //require(lastBonusTime>=pool.v2Info.startTime,'you can not get bonus right now.');
          require(lastBonusTime < pool.v2Info.startTime,'you can not get bonus right now.');
       }
       uint availBonus=_calculateAvailBonus(pool,msg.sender,poolType);
       require(availBonus<= (pool.v1Info.totalUSDTBonus.sub(pool.v1Info.Bonused)),'bonus overflow');
       if(availBonus>0){
          //give bonus
          db.userTable.userAssets[msg.sender][db.config.usdtContract].available=db.userTable.userAssets[msg.sender][db.config.usdtContract].available.add(availBonus);
          //update bonus time
          pool.accountStakings[msg.sender].lastBonusTime=block.timestamp;
          pool.accountStakings[msg.sender].totalBonused=pool.accountStakings[msg.sender].totalBonused.add(availBonus);

          pool.v1Info.Bonused= pool.v1Info.Bonused.add(availBonus);

          pool.totalUSDTBonus= pool.totalUSDTBonus.sub(availBonus);
          pool.totalBonused=pool.totalBonused.add(availBonus);

          pool.accountStakings[msg.sender].v1.isBonused=true;

       }
       result=true;
       emit _stakingBonused(msg.sender,db.config.dotcContract,availBonus);
    }
    function _calculateAvailBonus(StakingPool storage pool,address userAddr,uint poolType) internal view returns(uint avail){

       if(pool.accountStakings[userAddr].balance<=0) return 0;
       if(pool.totalSupply==0){
         return 0;
       }
       //update v1,v2 ,updatePoolPeriod first
       (StakingDetail memory detail,uint v1Time,uint v2Time)=_queryLastLockInfo(pool,userAddr,poolType);
       //calculate bonus
       {
         if(detail.v1.isBonused){
           avail=0;
         }
         else if(detail.v1.weightTime>0 && detail.v1.weightTime<v2Time && detail.v1.amount>0){
           uint nLockTimes=v2Time.sub(detail.v1.weightTime);
           //if(nLockDays<1 days) nLockDays=1 days;
           if(nLockTimes>consts.stakingParam.bonusPeriod) nLockTimes=consts.stakingParam.bonusPeriod;
           avail=detail.v1.amount.mul(nLockTimes).mul(pool.v1Info.totalUSDTBonus*70/100).div(consts.stakingParam.bonusPeriod).div(pool.totalSupply);
         }
         else{
           avail=0;
         }
       }


    }
    function _queryLastLockInfo(StakingPool storage pool,address userAddr,uint poolType) internal view returns(StakingDetail memory detail,uint v1Time,uint v2Time){
       detail=pool.accountStakings[userAddr];
       uint v1Num;
       uint v2Num;
       (v1Time,v1Num,v2Time,v2Num)=_calculatePeriod();
       //check poolA
       if(poolType==0){
          if(detail.v1.amount>0 && block.timestamp.sub(detail.v1.weightTime)>=POOLA_MAX_DAYS){
            //clear poolA
            detail.balance=detail.balance.sub(detail.v1.amount);
            detail.v1.amount=0;
            detail.v1.isBonused=false;
          }
          if(detail.v2.amount>0 && block.timestamp.sub(detail.v2.weightTime)>=POOLA_MAX_DAYS){
            detail.balance=detail.balance.sub(detail.v2.amount);
            detail.v2.amount=0;
          }
       }
       //update v1,v2
       if(detail.v2.weightTime<v2Time){
        //combine
        detail.v1.amount=detail.v1.amount.add(detail.v2.amount);
        uint weightTime=_calV1V2WeigthTime(detail.v1.weightTime,detail.v1.amount,detail.v2.weightTime,detail.v2.amount,v1Time,v2Time);
        if(weightTime<v1Time && v1Time>0) weightTime=v1Time;
        if(weightTime>v2Time && v2Time>0) weightTime=v2Time;
        detail.v1.weightTime=weightTime;
        detail.v1.isBonused=false;

        detail.v2.amount=0;
        detail.v2.weightTime=block.timestamp;
       }
    }
    function _updateUserStaking(StakingPool storage pool,uint poolType,address userAddr,uint newAmount) internal {
      //update v1,v2 ,updatePoolPeriod first
      StakingDetail memory detail=pool.accountStakings[userAddr];
      //check poolA
      if(poolType==0){
        if(detail.v1.amount>0 && block.timestamp.sub(detail.v1.weightTime)>=POOLA_MAX_DAYS){
         //clear poolA
         pool.accountStakings[userAddr].balance=pool.accountStakings[userAddr].balance.sub(detail.v1.amount);
         pool.accountStakings[userAddr].v1.amount=0;
         pool.accountStakings[userAddr].v1.isBonused=false;
        }
        if(detail.v2.amount>0 && block.timestamp.sub(detail.v2.weightTime)>=POOLA_MAX_DAYS){
          pool.accountStakings[userAddr].balance=pool.accountStakings[userAddr].balance.sub(detail.v2.amount);
          pool.accountStakings[userAddr].v2.amount=0;
        }
        if(pool.accountStakings[userAddr].balance==0){
          if(pool.totalAccount>1){
              pool.totalAccount--;
          }
        }
      }

      //update v1,v2
      if(detail.v2.weightTime<pool.v2Info.startTime){
        //combine
        pool.accountStakings[userAddr].v1.amount=pool.accountStakings[userAddr].v1.amount.add(pool.accountStakings[userAddr].v2.amount);
        uint newWeightTime=_calV1V2WeigthTime(detail.v1.weightTime,detail.v1.amount,detail.v2.weightTime,detail.v2.amount,pool.v1Info.startTime,pool.v2Info.startTime);
        if(newWeightTime<pool.v1Info.startTime && pool.v1Info.startTime>0) newWeightTime=pool.v1Info.startTime;
        if(newWeightTime>pool.v2Info.startTime && pool.v2Info.startTime>0) newWeightTime=pool.v2Info.startTime;
        pool.accountStakings[userAddr].v1.weightTime=newWeightTime;
        pool.accountStakings[userAddr].v1.isBonused=false;

        pool.accountStakings[userAddr].v2.amount=0;
        pool.accountStakings[userAddr].v2.weightTime=block.timestamp;
      }
      if(detail.balance==0){
        if(newAmount>0){
          pool.totalAccount+=1;
        }
        pool.accountStakings[userAddr].lastBonusTime=0;
      }
      //add newAmount
      if(newAmount>0){
        pool.accountStakings[userAddr].v2.amount=pool.accountStakings[userAddr].v2.amount.add(newAmount);
        uint newWeightTime=_calV1V2WeigthTime(pool.accountStakings[userAddr].v2.weightTime,pool.accountStakings[userAddr].v2.amount,block.timestamp,newAmount,pool.v2Info.startTime,block.timestamp);
        if(newWeightTime<pool.v2Info.startTime) newWeightTime =pool.v2Info.startTime;
        pool.accountStakings[userAddr].v2.weightTime=newWeightTime;
        pool.totalSupply=pool.totalSupply.add(newAmount);
        pool.accountStakings[userAddr].balance=pool.accountStakings[userAddr].balance.add(newAmount);
        pool.accountStakings[userAddr].lastLockTime=block.timestamp;
      }


    }
    function _calV1V2WeigthTime(uint wt1,uint amount1,uint wt2,uint amount2,uint startTime,uint endTime) internal pure returns(uint newWT){
      if(wt1==0 || amount1==0){
       newWT=wt2;
      }
      else if(wt2==0 || amount2==0){
        newWT=wt1;
      }
      else {
        if(wt1<startTime) wt1=startTime;
        if(wt2<startTime) wt2=startTime;
        newWT=(amount1*(endTime-wt1)).add(amount2*(endTime-wt2));
        newWT=newWT.div(amount1.add(amount2));
        if(newWT>=endTime){
          newWT=endTime;
        }else{
          newWT=endTime.sub(newWT);
        }

      }
    }

    function _queryUserAvailBonus(address userAddr,uint lockType) internal view returns(uint availBonus,uint totalBonus,uint lastBonusTime){
       if(lockType==0){
         //PoolA
         availBonus=_calculateAvailBonus(db.stakingTable.poolA[db.config.dotcContract],userAddr,0);
         totalBonus=db.stakingTable.poolA[db.config.dotcContract].accountStakings[userAddr].totalBonused;
         lastBonusTime=db.stakingTable.poolA[db.config.dotcContract].accountStakings[userAddr].lastBonusTime;
       }else{
         //PoolB
         availBonus=_calculateAvailBonus(db.stakingTable.poolB[db.config.dotcContract],userAddr,1);
         totalBonus=db.stakingTable.poolB[db.config.dotcContract].accountStakings[userAddr].totalBonused;
         lastBonusTime=db.stakingTable.poolB[db.config.dotcContract].accountStakings[userAddr].lastBonusTime;
       }
    }

}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

//import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
import '../libraries/LibStrings.sol';
//import '../facetBase/DOTCExOrderBase.sol';
import '../facetBase/DOTCExOrderBaseSettle.sol';

contract DOTCExOrderSettleFacet is DOTCExOrderBaseSettle {
  using SafeMath for uint; 
  
  event _AdOrderReceived(string  orderId); 
  function confirmMoneyReceived(string calldata adOrderId,string calldata exOrderId) external returns (bool result) {
    require(!db.config.isPause,'system paused');
    require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
    require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress !=address(0),'Trade Order not exists');
    require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state==TradeState.Filled || db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state==TradeState.MoneyPayed,'Trade order state can only be Filled or MoneyPayed');
    if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY){
        require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress == msg.sender,'no access');
    }
    else{
        require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress == msg.sender,'no access');
    }
    require(db.arbitTable.orderArbitList[exOrderId].state!=ArbitState.Dealing,'the order has an dealing arbit');

    db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state=TradeState.MoneyReceived;
    db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.lastUpdateTime=block.timestamp;

    _OrderCompleted(adOrderId,exOrderId);

    result=true;
    emit _AdOrderReceived(exOrderId);
  }
  function queryExOrderReward(string calldata exOrderId) external view returns(RebateInfo[] memory rebates){
    string memory adOrderId=db.orderTable.otcExAdMap[exOrderId];
    require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
    require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress !=address(0),'Trade Order not exists');
    rebates=db.orderTable.otcTradeOrders[adOrderId][exOrderId].rebateList;
  }
  function queryUserReward(address userAddr,address token) external view returns(uint amount){
    amount=db.orderTable.rewardStatistics[userAddr][token];
  } 
  

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
import '../libraries/LibStrings.sol';

contract DOTCExOrderBaseSettle is DOTCFacetBase {
    using SafeMath for uint;
    event _ExOrderReward(string  exOrderId,address indexed userAddr,address indexed token,uint amount);

    function _OrderCompleted(string calldata adOrderId,string calldata exOrderId)  internal{
      db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state=TradeState.Completed;
      db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.lastUpdateTime=block.timestamp;
      address takerAddr=db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress;
      if(db.orderTable.userOrderDb[takerAddr].noneExOrder>0){
       db.orderTable.userOrderDb[takerAddr].noneExOrder=db.orderTable.userOrderDb[takerAddr].noneExOrder.sub(1);
      }
      _removeStrFromList(db.orderTable.userOrderDb[takerAddr].noneExOrderList,exOrderId);
      //clear deposit
      _ClearOrderDeposit(adOrderId,exOrderId);

      _checkCloseAdOrder(adOrderId);

      _RemoveExOrderFromList(adOrderId,exOrderId);

    }
    function _ClearOrderDeposit(string calldata adOrderId,string calldata exOrderId) internal {
      address buyerAddr;
      address sellerAddr;
      FeeInfo memory buyFee;
      FeeInfo memory sellFee;
      if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY){
        buyerAddr = db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress;
        sellerAddr = db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress;
        buyFee=_GetOrderFeeValue(adOrderId,exOrderId,1);
        sellFee=_GetAdSellMakerFeeValue(adOrderId,exOrderId); //广告订单为卖单
      }else{
        buyerAddr = db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress;
        sellerAddr = db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress;
        buyFee=_GetOrderFeeValue(adOrderId,exOrderId,0);
        sellFee=_GetExSellTakerFeeValue(adOrderId,exOrderId); //交易订单为卖单
      }

      _clearExOrderAssets(adOrderId,exOrderId,buyerAddr,sellerAddr,buyFee,sellFee);

      db.orderTable.otcTradeStatistics[db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress][db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress]++;
    }
    function _GetOrderFeeValue(string memory adOrderId,string memory exOrderId,uint tradeType) internal view returns(FeeInfo memory feeInfo){
       uint feeRate=0;
       if(tradeType==0){
         feeRate=db.config.makerFee;
       }else{
         feeRate=db.config.takerFee;
       }
       if(feeRate>0){
          feeInfo=_calculateOrderFee(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenA,
          feeRate,
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.orderValue,
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.dotcAmount,
          true
         );
        }
    }
    function _GetAdSellMakerFeeValue(string memory adOrderId,string memory exOrderId) internal view returns(FeeInfo memory feeInfo){
      if(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue<=0) return feeInfo;
      feeInfo.feeValue=db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount.mul(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue)
           .div(db.orderTable.otcAdOrders[adOrderId].detail.totalAmount);
      feeInfo.feeType=db.orderTable.otcAdOrders[adOrderId].depositInfo.feeType;
    }
    function _GetExSellTakerFeeValue(string memory adOrderId,string memory exOrderId) internal view returns(FeeInfo memory feeInfo){
       feeInfo.feeValue=db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue;
       feeInfo.feeType=db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType;
    }
    function _clearExOrderAssets(string memory adOrderId,string memory exOrderId,address buyerAddr,address sellerAddr,FeeInfo memory buyFee,FeeInfo memory sellFee) internal{
      uint deposit=db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit;
      uint tradeAmount=db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount;
      address tokenA=db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenA;
      uint nHistoryTradeTimes=db.orderTable.otcTradeStatistics[db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress][db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress];
      if(tokenA == db.config.usdtContract){

        _unLockToken(buyerAddr,db.config.dotcContract,deposit);
        _unLockToken(sellerAddr,db.config.dotcContract,deposit);

        db.userTable.userAssets[sellerAddr][tokenA].locked=db.userTable.userAssets[sellerAddr][tokenA].locked.sub(tradeAmount);
        db.userTable.userAssets[sellerAddr][db.config.usdtContract].locked=db.userTable.userAssets[sellerAddr][db.config.usdtContract].locked.sub(sellFee.feeValue);

        _addUnlockedAmount(buyerAddr,tokenA,tradeAmount.sub(buyFee.feeValue),nHistoryTradeTimes>0?consts.periodParam.otherTradeLockTime:consts.periodParam.firstTradeLockTime);
        //db.userTable.userAssets[buyerAddr][tokenA].available=db.userTable.userAssets[buyerAddr][tokenA].available.add(tradeAmount.sub(buyFee.feeValue));
        db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount=db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount.sub(tradeAmount);

        _RewardTradeMining(adOrderId,exOrderId,buyerAddr,buyFee);
        _RewardTradeMining(adOrderId,exOrderId,sellerAddr,sellFee);
         //usdt fee to risk pool
        _transferFeeToStakingPool(buyFee);
        _transferFeeToStakingPool(sellFee);
      }else{

        _backOrderToken(buyerAddr,db.config.dotcContract,deposit,buyFee);
        _backOrderToken(sellerAddr,db.config.dotcContract,deposit.add(sellFee.feeValue),sellFee);

        db.userTable.userAssets[sellerAddr][tokenA].locked=db.userTable.userAssets[sellerAddr][tokenA].locked.sub(tradeAmount);
        _addUnlockedAmount(buyerAddr,tokenA,tradeAmount,nHistoryTradeTimes>0?consts.periodParam.otherTradeLockTime:consts.periodParam.firstTradeLockTime);
        db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount=db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount.sub(tradeAmount);
      }
    }
    function _transferFeeToStakingPool(FeeInfo memory feeInfo) internal{
      //staking pool
      if(feeInfo.feeValue<=0 || feeInfo.feeType!=CoinType.USDT) return;
      _updatePoolPeriod();
      uint poolFee=feeInfo.feeValue.div(2);
      db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus.add(poolFee);
      db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus.add(poolFee);

      db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus.add(poolFee);
      db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus.add(poolFee);
    }
    function _backOrderToken(address userAddr,address token,uint unLockAmount,FeeInfo memory feeInfo) internal {
      require(db.userTable.userAssets[userAddr][token].locked >= unLockAmount,"insufficient locked balance");
      db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.add(unLockAmount.sub(feeInfo.feeValue));
      db.userTable.userAssets[userAddr][token].locked=db.userTable.userAssets[userAddr][token].locked.sub(unLockAmount);
      if(feeInfo.feeType==CoinType.DOTC){
         //db.daoData.miningPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.miningPool.poolTokens[db.config.dotcContract].currentSupply.add(feeInfo.feeValue);
         db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(feeInfo.feeValue);
      }
    }
    function _RewardTradeMining(string memory adOrderId,string memory exOrderId,address userAddr,FeeInfo memory feeInfo) internal {
      if(feeInfo.feeType!=CoinType.USDT) return;
      uint dotcAmount=_getDOTCNumFromUSDT(feeInfo.feeValue);
      uint backRate=_getBackRate();
      dotcAmount=dotcAmount.mul(backRate).div(1000);
      if(dotcAmount<=0) return;
      if(dotcAmount>consts.nMaxOrderMine){
        dotcAmount=consts.nMaxOrderMine;
      }

      uint nTotalMined=dotcAmount.mul(110).div(100);
      if(db.daoData.miningPool.poolTokens[db.config.dotcContract].currentSupply<nTotalMined){

        return;
      }
      //reward
      {
        nTotalMined=dotcAmount;
        db.userTable.userAssets[userAddr][db.config.dotcContract].available=db.userTable.userAssets[userAddr][db.config.dotcContract].available.add(dotcAmount);
        db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.exRewardInfo.token=db.config.dotcContract;
        db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.exRewardInfo.amount=dotcAmount;
        emit _ExOrderReward(exOrderId,userAddr,db.config.dotcContract,dotcAmount);
        address invitor=db.userTable.userInviteList[userAddr];
        if(invitor!=address(0)){
          _rewardToUser(adOrderId,exOrderId,invitor,1,db.config.dotcContract,dotcAmount.mul(10).div(100));
          nTotalMined=nTotalMined.add(dotcAmount.mul(10).div(100));
        }
        address invitorLast=db.userTable.userInviteList[invitor];
        if(invitorLast!=address(0)){
          _rewardToUser(adOrderId,exOrderId,invitorLast,2,db.config.dotcContract,dotcAmount.mul(10).div(100));
          nTotalMined=nTotalMined.add(dotcAmount.mul(10).div(100));
        }
      }

      //update pool
      _updateMingPool(nTotalMined);
    }
    function _rewardToUser(string memory adOrderId,string memory exOrderId,address userAddr,uint rlevel,address token,uint amount) internal {
       db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.add(amount);
       RebateInfo memory info=RebateInfo(userAddr,rlevel,token,amount);
       db.orderTable.otcTradeOrders[adOrderId][exOrderId].rebateList.push(info);
       db.orderTable.rewardStatistics[userAddr][token]=db.orderTable.rewardStatistics[userAddr][token].add(amount);
       emit _ExOrderReward(exOrderId,userAddr,token,amount);
    }
    function _updateMingPool(uint newAmount) internal {
      db.daoData.miningPool.poolTokens[db.config.dotcContract].periodMined=db.daoData.miningPool.poolTokens[db.config.dotcContract].periodMined.add(newAmount);
      db.daoData.miningPool.poolTokens[db.config.dotcContract].totalMined=db.daoData.miningPool.poolTokens[db.config.dotcContract].totalMined.add(newAmount);
      db.daoData.miningPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.miningPool.poolTokens[db.config.dotcContract].currentSupply.sub(newAmount);
      if(db.daoData.miningPool.poolTokens[db.config.dotcContract].periodMined>=(1365000 * consts.priceParam.nDOTCDecimals)){
        db.daoData.miningPool.poolTokens[db.config.dotcContract].periodCount++; //1360000
        db.daoData.miningPool.poolTokens[db.config.dotcContract].periodMined=0;
      }
    }
    function _checkCloseAdOrder(string memory adOrderId) internal{
      if(db.orderTable.otcAdOrders[adOrderId].detail.leftAmount<=0 &&db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount<=0){

         db.orderTable.otcAdOrders[adOrderId].state=OrderState.CLOSED;

         if(db.orderTable.orderCount>0){
           db.orderTable.orderCount--;
         }
         address makerAddr= db.orderTable.otcAdOrders[adOrderId].makerAddress;
         if(db.orderTable.userOrderDb[makerAddr].noneAdOrder>0){
           db.orderTable.userOrderDb[makerAddr].noneAdOrder=db.orderTable.userOrderDb[makerAddr].noneAdOrder.sub(1);
         }
         _removeStrFromList(db.orderTable.userOrderDb[makerAddr].noneAdOrderList,adOrderId);
      }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import './libs/OracleLibrary.sol';
import './libs/PoolAddress.sol';
import './libs/SafeUint128.sol';

import '../../interfaces/IERC20.sol';
import "../IDOTCOracleRobot.sol";
import '../../utils/SafeMath.sol';

/// @title UniswapV3 oracle with ability to query across an intermediate liquidity pool
contract UniswapV3Oracle is IDOTCOracleRobot {
    using SafeMath for uint; 

    address public uniswapV3Factory;
    address public weth;
    uint24 public  defaultFee;
    uint public wethDeci;
    uint24 public dotcFee;
    //robot param
    address public dotcAddr;
    address public usdtAddr;

    uint public dotcDeci;
    uint public usdtDeci;

    bool public isTwoPair=false;
    uint32 public constant PERIOD = 120;
    uint public immutable nRatio=100;
    bool public isInited;
    //result
    uint public lastPrice0;
    uint public lastPrice1;
    uint public lastUniPrice=0;
    uint lastTimeStamp;


    function initOracleRobot(address _uniFactory, address _dotcAddr, address _wethAddr,address _usdtAddr,bool _isTwoPair) override external{
        uniswapV3Factory=_uniFactory;
        dotcAddr=_dotcAddr;
        weth=_wethAddr;
        usdtAddr=_usdtAddr;
        isTwoPair=_isTwoPair;
        defaultFee=3000;
        dotcFee=3000;
        //init amount
        dotcDeci = 10 ** IERC20(dotcAddr).decimals();
        wethDeci = 10 ** IERC20(weth).decimals();
        if(isTwoPair){
            usdtDeci = 10 ** IERC20(usdtAddr).decimals();
        }
        
        isInited=true;
        //update
        _updatePrice();
        
    }
    function getRealTimePrice(bool isReverse) override external view  returns(uint price0,uint price1,uint price,uint blockTimestamp){
        (price0,price1,price)=(lastPrice0,lastPrice1,lastUniPrice);
        if(isReverse && price>0){
            if(!isTwoPair){
                price= wethDeci.mul(dotcDeci).div(price); 
            }else{
                price= usdtDeci.mul(dotcDeci).div(price); 
            }
        }
        //protect
        if(price<=0){
            if(isReverse){
                price=dotcDeci;
            }else{
                price=usdtDeci;
            }
        
        }
        blockTimestamp=block.timestamp;
    }
    function checkUpdateTimestamp() override external  {
        uint256 timeElapsed=block.timestamp-lastTimeStamp;
        if(timeElapsed>=PERIOD){
            _updatePrice();
        }
    }
    function _updatePrice() internal{
        require(isInited,'oracle not init');
        {
            lastPrice0=_fetchTwap(dotcAddr,weth,dotcFee, PERIOD,dotcDeci/nRatio);
            if(isTwoPair){
                lastPrice1=_fetchTwap(weth,usdtAddr,defaultFee,PERIOD,wethDeci/nRatio);
            }
            if(!isTwoPair){
                lastUniPrice= lastPrice0;
            }else{
                lastUniPrice = lastPrice0.mul(lastPrice1).div(wethDeci);
            }
            lastPrice0=lastPrice0.mul(nRatio);
            lastPrice1=lastPrice1.mul(nRatio);
            lastUniPrice=lastUniPrice.mul(nRatio);
        }
        lastTimeStamp=block.timestamp; 
        
    }

    function _fetchTwap(
        address _tokenIn,
        address _tokenOut,
        uint24 _poolFee,
        uint32 _twapPeriod,
        uint256 _amountIn
    ) internal view returns (uint256 amountOut) {
        address pool =
            PoolAddress.computeAddress(uniswapV3Factory, PoolAddress.getPoolKey(_tokenIn, _tokenOut, _poolFee));
        // Leave twapTick as a int256 to avoid solidity casting
        int256 twapTick = OracleLibrary.consult(pool, _twapPeriod);
        
        return
            OracleLibrary.getQuoteAtTick(
                int24(twapTick), // can assume safe being result from consult()
                SafeUint128.toUint128(_amountIn),
                _tokenIn,
                _tokenOut
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0 <0.8.0;

import './FullMath.sol';
import './TickMath.sol';
import './IUniswapV3Pool.sol';
import './LowGasSafeMath.sol';
import './PoolAddress.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Fetches time-weighted average tick using Uniswap V3 oracle
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @param period Number of seconds in the past to start calculating time-weighted average
    /// @return timeWeightedAverageTick The time-weighted average tick from (block.timestamp - period) to block.timestamp
    function consult(address pool, uint32 period) internal view returns (int24 timeWeightedAverageTick) {
        require(period != 0, 'BP');

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = period;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / period);

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % period != 0)) timeWeightedAverageTick--;
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Safe uint128 casting methods
/// @notice Contains methods for safely casting between types
library SafeUint128 {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import '../libraries/FixedPoint.sol';
import './UniswapV2OracleLibrary.sol';
import './UniswapV2Library.sol';

import '../../interfaces/IERC20.sol';

import "../IDOTCOracleRobot.sol";
import '../../utils/SafeMath.sol';

//import "hardhat/console.sol";

contract UniOracleRobot is IDOTCOracleRobot {
    using SafeMath for uint; 
    using FixedPoint for *;
    uint public constant PERIOD = 8 hours;

    struct UniPair{
        IUniswapV2Pair pair;
        address tokenA;
        address tokenB;
        uint token0Decimal;
        uint token1Decimal;
        uint  price0CumulativeLast;
        uint  price1CumulativeLast;
        uint blockTimestampLast;
    }

    //IUniswapV2Pair immutable pair;
    UniPair public pairBotDOTC_ETH;
    UniPair public pairBotETH_USDT;
    
    address public uniFactoryAddr;

    bool public isUniReady;
    uint public  dotcDeci;
    uint public ethDeci;
    uint public usdtDeci;
    //当前价格
    uint public currentUniPrice=0;

    bool public isTwoPair=false;

    event _OracleInited(address _uniFactory, address _dotcAddr, address _wethAddr,address _usdtAddr,bool _isTwoPair);

    //admin set
    function initOracleRobot(address _uniFactory, address _dotcAddr, address _wethAddr,address _usdtAddr,bool _isTwoPair) override external {
         require(!isUniReady,'uniswap has been ready.');
         //LibDiamond.enforceIsContractOwner();
         pairBotDOTC_ETH.pair=IUniswapV2Pair(UniswapV2Library.pairFor(_uniFactory, _dotcAddr, _wethAddr));
         pairBotDOTC_ETH.tokenA=_dotcAddr;
         pairBotDOTC_ETH.tokenB=_wethAddr;
         dotcDeci=IERC20(_dotcAddr).decimals();
         ethDeci=IERC20(_wethAddr).decimals();
         pairBotDOTC_ETH.token0Decimal=(pairBotDOTC_ETH.pair.token0()==_dotcAddr?dotcDeci:ethDeci);
         pairBotDOTC_ETH.token1Decimal=(pairBotDOTC_ETH.pair.token0()==_dotcAddr?ethDeci:dotcDeci);
         pairBotDOTC_ETH.price0CumulativeLast = pairBotDOTC_ETH.pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
         pairBotDOTC_ETH.price1CumulativeLast = pairBotDOTC_ETH.pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
         pairBotDOTC_ETH.blockTimestampLast=_checkPairReserves(pairBotDOTC_ETH.pair);
         isTwoPair=_isTwoPair;
         if(isTwoPair){
             usdtDeci=IERC20(_usdtAddr).decimals();
             pairBotETH_USDT.pair=IUniswapV2Pair(UniswapV2Library.pairFor(_uniFactory,_wethAddr,_usdtAddr));
             pairBotETH_USDT.tokenA=_wethAddr;
             pairBotETH_USDT.tokenB=_usdtAddr;
             pairBotETH_USDT.token0Decimal=(pairBotETH_USDT.pair.token0()==_wethAddr?ethDeci:usdtDeci); 
             pairBotETH_USDT.token1Decimal=(pairBotETH_USDT.pair.token0()==_wethAddr?usdtDeci:ethDeci); 
             pairBotETH_USDT.price0CumulativeLast = pairBotETH_USDT.pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
             pairBotETH_USDT.price1CumulativeLast = pairBotETH_USDT.pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
             pairBotETH_USDT.blockTimestampLast=_checkPairReserves(pairBotETH_USDT.pair);
         }
         uniFactoryAddr=_uniFactory;
         isUniReady=true;
         
         emit _OracleInited(_uniFactory,_dotcAddr,_wethAddr,_usdtAddr,_isTwoPair);
    }
    //get price
    function getRealTimePrice(bool isReverse) override external view  returns(uint price0,uint price1,uint price,uint blockTimestamp)  {
      (price0,price1,price,blockTimestamp)=_getRealTimePrice(isReverse);
    }
    function checkUpdateTimestamp() override external  {
        _update(pairBotDOTC_ETH);
        if(isTwoPair){
            _update(pairBotETH_USDT);
        }
    }
    
    /*************internal methods ****/
    function _update(UniPair storage uniPair) internal returns(bool isUpdated){
        require(isUniReady,'Uniswap is not ready');
        (uint price0,uint price1,uint price,uint time)=_getRealTimePrice(true);
        if(price>0){
          currentUniPrice=price;
        }
        (uint price0Cumulative, uint price1Cumulative, uint blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniPair.pair);
        uint timeElapsed = blockTimestamp - uniPair.blockTimestampLast; // overflow is desired
        if(timeElapsed>=PERIOD){
           uniPair.price0CumulativeLast=price0Cumulative;
           uniPair.price1CumulativeLast=price1Cumulative;
           uniPair.blockTimestampLast=blockTimestamp;
           isUpdated=true;
        }
    }
    function _checkPairReserves(IUniswapV2Pair pair) internal view returns (uint) {
        (uint112 reserve0,uint112 reserve1,uint timestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'DOTCOracleRobot: NO_RESERVES'); // ensure that there's liquidity in the pair
        return timestampLast;
    }
    function _getRealTimePrice(bool isReverse) internal view  returns(uint price0,uint price1,uint price,uint blockTimestamp){
        require(isUniReady,'Uniswap is not ready');
        price0=_getSinglePrice(pairBotDOTC_ETH,pairBotDOTC_ETH.tokenA);
        if(isTwoPair){
           price1=_getSinglePrice(pairBotETH_USDT,pairBotETH_USDT.tokenA);
           price=price0.mul(price1).div(10**ethDeci);
        }else{
           price=price0;
        }
        if(isReverse && price>0){
          if(isTwoPair){
            price=(10**usdtDeci).mul(10**dotcDeci).div(price); 
          }else{
            price=(10**ethDeci).mul(10**dotcDeci).div(price);
          }
        } 
        if(price<=0){
          price=currentUniPrice;
        }
        blockTimestamp=block.timestamp;
    }
    function _getSinglePrice(UniPair storage uniPair,address destToken) internal view  returns(uint price){
       (uint price0Cumulative, uint price1Cumulative, uint blockTimestamp)=UniswapV2OracleLibrary.currentCumulativePrices(uniPair.pair);
       uint timeElapsed = blockTimestamp - uniPair.blockTimestampLast; // overflow is desired
       if(timeElapsed>0){
         FixedPoint.uq112x112 memory price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - uniPair.price0CumulativeLast) / timeElapsed));
         FixedPoint.uq112x112 memory price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - uniPair.price1CumulativeLast) / timeElapsed));
         price=UniswapV2OracleLibrary.getDestPrice(uniPair.pair.token0(),uniPair.pair.token1(),price0Average.mul(10**uniPair.token0Decimal).decode144(),price1Average.mul(10**uniPair.token1Decimal).decode144(),destToken);
       }
    }
    
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

interface IUniswapV2Pair {
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

import './IUniswapV2Pair.sol';
import '../libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        IUniswapV2Pair pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();
        {
           // if time has elapsed since the last update on the pair, mock the accumulated price values
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
            if (blockTimestampLast != blockTimestamp) {
                // subtraction overflow is desired
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                // addition overflow is desired
                // counterfactual
                price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
                // counterfactual
                price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
            }   
        }
       
    }

    function getDestPrice(address token0,address token1,uint price0Cumulative, uint price1Cumulative,address destToken) internal pure returns(uint price){
         if(token0==destToken){
           price=price0Cumulative;
        }else if(token1==destToken){
           price=price1Cumulative;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

import './IUniswapV2Pair.sol';

import "../../utils/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

import './IMdexPair.sol';
import '../libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library MdexOracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        IMdexPair pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();
        {
           // if time has elapsed since the last update on the pair, mock the accumulated price values
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
            if (blockTimestampLast != blockTimestamp) {
                // subtraction overflow is desired
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                // addition overflow is desired
                // counterfactual
                price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
                // counterfactual
                price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
            }   
        }
       
    }

    function getDestPrice(address token0,address token1,uint price0Cumulative, uint price1Cumulative,address destToken) internal pure returns(uint price){
         if(token0==destToken){
           price=price0Cumulative;
        }else if(token1==destToken){
           price=price1Cumulative;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

interface IMdexPair {
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

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function price(address token, uint256 baseDecimal) external view returns (uint256);

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import './IMdexFactory.sol';
import './IMdexPair.sol';
import '../libraries/FixedPoint.sol';
import './MdexOracleLibrary.sol';

import '../../interfaces/IERC20.sol';
import "../IDOTCOracleRobot.sol";
import '../../utils/SafeMath.sol';

contract MdexOracleRobot is IDOTCOracleRobot {
    using SafeMath for uint; 
    using FixedPoint for *;
    uint public constant PERIOD = 4 hours;

    struct MdexPair{
        IMdexPair pair;
        address tokenA;
        address tokenB;
        uint token0Decimal;
        uint token1Decimal;
        uint  price0CumulativeLast;
        uint  price1CumulativeLast;
        uint blockTimestampLast;
    }

    //IUniswapV2Pair immutable pair;
    MdexPair public pairBotDOTC_BASE;
    MdexPair public pairBotBASE_MC;
    
    address public factoryAddr;

    bool public isReady;
    uint public  dotcDeci;
    uint public baseDeci;
    uint public mcDeci;
    //当前价格
    uint public currentUniPrice=0;

    bool public isTwoPair=false;

    event _OracleInited(address _factory, address _dotcAddr, address _baseAddr,address _mcAddr,bool _isTwoPair);

    //admin set
    function initOracleRobot(address _factory, address _dotcAddr, address _baseAddr,address _mcAddr,bool _isTwoPair) override external {
         require(!isReady,'mdex has been ready.');
         //LibDiamond.enforceIsContractOwner();
         pairBotDOTC_BASE.pair=IMdexPair(IMdexFactory(_factory).pairFor(_dotcAddr, _baseAddr));
         pairBotDOTC_BASE.tokenA=_dotcAddr;
         pairBotDOTC_BASE.tokenB=_baseAddr;
         dotcDeci=IERC20(_dotcAddr).decimals();
         baseDeci=IERC20(_baseAddr).decimals();
         pairBotDOTC_BASE.token0Decimal=(pairBotDOTC_BASE.pair.token0()==_dotcAddr?dotcDeci:baseDeci);
         pairBotDOTC_BASE.token1Decimal=(pairBotDOTC_BASE.pair.token0()==_dotcAddr?baseDeci:dotcDeci);
         pairBotDOTC_BASE.price0CumulativeLast = pairBotDOTC_BASE.pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
         pairBotDOTC_BASE.price1CumulativeLast = pairBotDOTC_BASE.pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
         pairBotDOTC_BASE.blockTimestampLast=_checkPairReserves(pairBotDOTC_BASE.pair);
         isTwoPair=_isTwoPair;
         if(isTwoPair){
             mcDeci=IERC20(_mcAddr).decimals();
             pairBotBASE_MC.pair=IMdexPair(IMdexFactory(_factory).pairFor(_baseAddr,_mcAddr)); 
             pairBotBASE_MC.tokenA=_baseAddr;
             pairBotBASE_MC.tokenB=_mcAddr;
             pairBotBASE_MC.token0Decimal=(pairBotBASE_MC.pair.token0()==_baseAddr?baseDeci:mcDeci); 
             pairBotBASE_MC.token1Decimal=(pairBotBASE_MC.pair.token0()==_baseAddr?mcDeci:baseDeci); 
             pairBotBASE_MC.price0CumulativeLast = pairBotBASE_MC.pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
             pairBotBASE_MC.price1CumulativeLast = pairBotBASE_MC.pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
             pairBotBASE_MC.blockTimestampLast=_checkPairReserves(pairBotBASE_MC.pair);
         }
         factoryAddr=_factory;
         isReady=true;
         
         emit _OracleInited(_factory,_dotcAddr,_baseAddr,_mcAddr,_isTwoPair);
    }
    //get price
    function getRealTimePrice(bool isReverse) override external view  returns(uint price0,uint price1,uint price,uint blockTimestamp)  {
      (price0,price1,price,blockTimestamp)=_getRealTimePrice(isReverse);
    }
    function checkUpdateTimestamp() override external  {
        _update(pairBotDOTC_BASE);
        if(isTwoPair){
            _update(pairBotBASE_MC);
        }
    }
    
    /*************internal methods ****/
    function _update(MdexPair storage mdPair) internal returns(bool isUpdated){
        require(isReady,'mdex is not ready');
        (uint price0,uint price1,uint price,uint time)=_getRealTimePrice(true);
        if(price>0){
          currentUniPrice=price;
        }
        (uint price0Cumulative, uint price1Cumulative, uint blockTimestamp) =
            MdexOracleLibrary.currentCumulativePrices(mdPair.pair);
        uint timeElapsed = blockTimestamp - mdPair.blockTimestampLast; // overflow is desired
        if(timeElapsed>=PERIOD){
           mdPair.price0CumulativeLast=price0Cumulative;
           mdPair.price1CumulativeLast=price1Cumulative;
           mdPair.blockTimestampLast=blockTimestamp;
           isUpdated=true;
        }
    }
    function _checkPairReserves(IMdexPair pair) internal view returns (uint) {
        (uint112 reserve0,uint112 reserve1,uint timestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'MdexOracleRobot: NO_RESERVES'); // ensure that there's liquidity in the pair
        return timestampLast;
    }
    function _getRealTimePrice(bool isReverse) internal view  returns(uint price0,uint price1,uint price,uint blockTimestamp){
        require(isReady,'mdex is not ready');
        price0=_getSinglePrice(pairBotDOTC_BASE,pairBotDOTC_BASE.tokenA);
        if(isTwoPair){
           price1=_getSinglePrice(pairBotBASE_MC,pairBotBASE_MC.tokenA);
           price=price0.mul(price1).div(10**baseDeci);
        }else{
           price=price0;
        }
        if(isReverse && price>0){
          if(isTwoPair){
            price=(10**mcDeci).mul(10**dotcDeci).div(price); 
          }else{
            price=(10**baseDeci).mul(10**dotcDeci).div(price);
          }
        } 
        if(price<=0){
          price=currentUniPrice;
        }
        blockTimestamp=block.timestamp;
    }
    function _getSinglePrice(MdexPair storage mdPair,address destToken) internal view  returns(uint price){
       (uint price0Cumulative, uint price1Cumulative, uint blockTimestamp)=MdexOracleLibrary.currentCumulativePrices(mdPair.pair);
       uint timeElapsed = blockTimestamp - mdPair.blockTimestampLast; // overflow is desired
       if(timeElapsed>0){
         FixedPoint.uq112x112 memory price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - mdPair.price0CumulativeLast) / timeElapsed));
         FixedPoint.uq112x112 memory price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - mdPair.price1CumulativeLast) / timeElapsed));
         price=MdexOracleLibrary.getDestPrice(mdPair.pair.token0(),mdPair.pair.token1(),price0Average.mul(10**mdPair.token0Decimal).decode144(),price1Average.mul(10**mdPair.token1Decimal).decode144(),destToken);
       }
    }
    
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;

interface IMdexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function feeToRate() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setFeeToRate(uint256) external;

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../oracle/mdex/MdexOracleRobot.sol";
import "../oracle/uniswap/UniOracleRobot.sol";
import "../oracle/uniswapv3/UniswapV3Oracle.sol";

import "../oracle/IDOTCOracleRobot.sol";

import "../facetBase/DOTCFacetBase.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";


import '../utils/SafeMath.sol';

//import "hardhat/console.sol";

contract DOTCOracleFacet is DOTCFacetBase {
    using SafeMath for uint;

    event _DOTCPriceUpdated(uint price,uint updateTime);
    event _RobotAddressUpdated(uint indexed _robotType,address indexed _factory, address _dotcAddr, address _baseAddr,address  _base2Addr,bool _isTwoPair);
    //admin set
    function updateRobotAddress(uint _robotType,address _factory, address _dotcAddr, address _baseAddr,address _base2Addr,bool _isTwoPair) external {
         //robotType,0-UNI,1-Mdex
         LibDiamond.enforceIsContractOwner();
         require(_dotcAddr==db.config.dotcContract,'token must be DOTC');

         address robotAddr=_createOracleRobot(_robotType,_factory,_dotcAddr,_baseAddr,_base2Addr,_isTwoPair);
         db.daoData.oracleInfo.robotAddr=robotAddr;

         emit _RobotAddressUpdated(_robotType,_factory,_dotcAddr,_baseAddr,_base2Addr,_isTwoPair);
    }
    function getOracleInfo() external view returns(OracleInfo memory info){
        return db.daoData.oracleInfo;
    }
    function getPriceMode() external view returns(uint priceMode){
       return consts.priceMode;
    }
    //get price
    function getRobotRTPrice() external view returns(uint price0,uint price1,uint price,uint blockTimestamp) {
        (price0,price1,price,blockTimestamp)=IDOTCOracleRobot(db.daoData.oracleInfo.robotAddr).getRealTimePrice(true);
    }
    //admin set
    function updateDOTCPrice() external returns(uint price,uint blockTimestamp) {
        if(consts.priceMode==1){
            return (0,0);
        }
        IDOTCOracleRobot(db.daoData.oracleInfo.robotAddr).checkUpdateTimestamp();
        (uint price0,uint price1,uint priceDest,uint time)=IDOTCOracleRobot(db.daoData.oracleInfo.robotAddr).getRealTimePrice(true);
        price=priceDest;
        blockTimestamp=time;
        db.daoData.oracleInfo.currentPrice=priceDest;
        db.daoData.oracleInfo.isInited=true;

        uint lastUpdateTime=block.timestamp;
        db.daoData.oracleInfo.lastUpdateTime= lastUpdateTime;

        emit _DOTCPriceUpdated(_getPubDOTCPrice(), lastUpdateTime);
    }
    function getDotcPrice() external view returns (uint){
        return _getPubDOTCPrice();
    }
    /*************internal methods ****/
    function _createOracleRobot(uint _robotType,address _factory, address _dotcAddr, address _baseAddr,address _base2Addr,bool _isTwoPair) internal returns (address robot) {
        bytes memory bytecode;
        if(_robotType==1){
            //MDEX
            bytecode= type(MdexOracleRobot).creationCode;
        }
        else if(_robotType==2){
            bytecode= type(UniswapV3Oracle).creationCode;
        }
        else{
            //UNISWAP
            bytecode= type(UniOracleRobot).creationCode;
        }

        bytes32 salt = keccak256(abi.encodePacked(_factory,_dotcAddr, _baseAddr,_base2Addr,_isTwoPair,block.timestamp));
        assembly {
            robot := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IDOTCOracleRobot(robot).initOracleRobot(_factory,_dotcAddr, _baseAddr,_base2Addr,_isTwoPair);
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;
import "../facetBase/DOTCFacetBase.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";

import '../utils/SafeMath.sol';

contract DOTCMiningFacet is DOTCFacetBase {
     using SafeMath for uint; 
     event _MineTokenAdded(address indexed userAddr,address indexed token,uint indexed amount); 
     event _MineTokenRemoved(address indexed userAddr,address indexed token,uint indexed amount); 
     event _MineParamReseted(address indexed userAddr,uint indexed nBackRate); 
     
     function AddTokenToPool(address token,uint amount) external returns(bool result){
       require(token!=address(0),'token invalid');
       require(amount>0,'amount must be greater than 0');
       require(token==db.config.dotcContract,'only dotc is supported');
       uint balance= IERC20(token).balanceOf(msg.sender);
       require(balance>=amount,'insufficient token balance');
       LibDiamond.enforceIsContractManager();
       //开始转账
       if(db.daoData.miningPool.poolTokens[token].initSupply<=0){
          _resetPoolParams(800);
       }
       db.daoData.miningPool.poolTokens[token].currentSupply=db.daoData.miningPool.poolTokens[token].currentSupply.add(amount);
       db.daoData.miningPool.poolTokens[token].initSupply=db.daoData.miningPool.poolTokens[token].initSupply.add(amount);

       LibERC20.transferFrom(token, msg.sender, address(this), amount);
     
       emit _MineTokenAdded(msg.sender,token,amount);

       result=true;
     }

     function RemoveTokenFromPool(address token,uint amount) external returns(bool result){
        require(token!=address(0),'token invalid');
        require(amount>0,'amount must be greater than 0');
        require(db.daoData.miningPool.poolTokens[token].currentSupply>=amount,'insufficient pool balance');
        LibDiamond.enforceIsContractOwner();
        db.daoData.miningPool.poolTokens[token].currentSupply=db.daoData.miningPool.poolTokens[token].currentSupply.sub(amount);
        LibERC20.transfer(token, msg.sender, amount);
        
        emit _MineTokenRemoved(msg.sender,token,amount);
        result=true;
     }

     function ResetPoolParams(uint nBackRate) external returns(bool result){
        LibDiamond.enforceIsContractManager();
        _resetPoolParams(nBackRate);
        result=true;
        emit _MineParamReseted(msg.sender,nBackRate);
     }

     function _resetPoolParams(uint nBackRate) internal {
        require(nBackRate<=1000 && nBackRate>=0,'invalid back rate');
        db.daoData.miningPool.poolTokens[db.config.dotcContract].initBackRate=nBackRate;
        db.daoData.miningPool.poolTokens[db.config.dotcContract].periodMined=0;
        db.daoData.miningPool.poolTokens[db.config.dotcContract].periodCount=0;
     }

     function queryMingPoolInfo(address tokenAddr) external view returns(MineInfo memory mineInfo){
         mineInfo=db.daoData.miningPool.poolTokens[tokenAddr];
     }


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IDOTCManageFacet.sol";

import '../utils/SafeMath.sol';
//import "hardhat/console.sol";

contract DOTCManageFacet is DOTCFacetBase,IDOTCManageFacet {
   using SafeMath for uint;

   function setContractManager(address _newManager) external returns(bool result) {
      LibDiamond.enforceIsContractOwner();
      LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
      address previousManager = ds.contractManager;
      ds.contractManager = _newManager;
      result=true;
      emit ManagerTransferred(previousManager, _newManager);
   }
   function getContractManager() external view returns (address contractManager_) {
      contractManager_ = LibDiamond.diamondStorage().contractManager;
   }
   function setEmergentPause(bool isPause,bool isPauseAsset) external{
      LibDiamond.enforceIsContractOwner();
      db.config.isPause=isPause;
      db.config.isPauseAsset=isPauseAsset;
      emit _EmergentPauseUpdated(msg.sender,isPause,isPauseAsset);
   }
   function getEmergentPause() external view returns(bool isPause,bool isPauseAsset){
      isPause=db.config.isPause;
      isPauseAsset=db.config.isPauseAsset;
   }
   function updateUnitAddress(address _dotcContract,address _wethContract) external {
      LibDiamond.enforceIsContractOwner();
      require(_dotcContract != address(0), "DOTCManageFacet: dotcContract can't be address(0)");
      require(_wethContract != address(0), "DOTCManageFacet: wethContract can't be address(0)");
      db.config.dotcContract = _dotcContract;
      db.config.wethContract = _wethContract;
      emit _UnitUpdated(_dotcContract,_wethContract);
   }
   function queryUserBalance(address userAddr,address token) external view returns (uint avail,uint locked,uint canUnlocked,uint nonUnlocked) {
      LibDiamond.enforceIsContractManager();
      avail=db.userTable.userAssets[userAddr][token].available;
      locked=db.userTable.userAssets[userAddr][token].locked;
      (canUnlocked,nonUnlocked)=_queryUnlockedAmount(userAddr,token);
   }
   function setPriceMode(uint mode) external{
      LibDiamond.enforceIsContractManager();
      require(mode>=0 && mode<2,'invalid mode');
      consts.priceMode=mode;
      emit _PriceModeChanged(msg.sender,mode);
   }
   function setManualDOTCPrice(uint price) external{
      LibDiamond.enforceIsContractManager();
//      require(consts.priceMode==1,'DOTC Price mode is auto');
      db.daoData.oracleInfo.currentPrice=price;
      db.daoData.oracleInfo.isInited=false;
      db.daoData.oracleInfo.lastUpdateTime=block.timestamp;
      emit _PriceManualChanged(msg.sender,price);
   }

   //1 USDT= XXX DOTC?
   function getMaxDotcPrice() external view returns(uint){
      return consts.maxDotcPrice;
   }

   function setMaxDotcPrice(uint nMaxPrice) external{
      LibDiamond.enforceIsContractManager();
      consts.maxDotcPrice=nMaxPrice;
      emit _MaxDotcPriceUpdated(msg.sender,nMaxPrice);
   }
   function queryVIPConditionAmount() external view returns (uint) {
      return consts.vipDOTC;
   }
   function setVIPConditionAmount(uint amount) external {
      LibDiamond.enforceIsContractManager();
      require(amount>=consts.priceParam.nDOTCDecimals,"amount is too little");
      consts.vipDOTC=amount;
      emit _VIPConditionUpdated(msg.sender,amount);
   }
   function queryArbitConditionAmount() external view returns (uint stakingDOTC,uint applyCost,uint punishCost) {
      stakingDOTC=consts.arbiterDOTC;
      applyCost=consts.arbitParam.arbiterApplyCost;
      punishCost=consts.arbitParam.arbiterPunish;
   }
   function setArbitConditionAmount(uint stakingDOTC,uint applyCost,uint punishCost) external {
      LibDiamond.enforceIsContractManager();
      require(stakingDOTC>=consts.priceParam.nDOTCDecimals,"amount is too little");
      consts.arbiterDOTC=stakingDOTC;
      consts.arbitParam.arbiterApplyCost=applyCost;
      consts.arbitParam.arbiterPunish=punishCost;
      emit _ArbitConditionUpdated(msg.sender,stakingDOTC,applyCost,punishCost);
   }
   //staking management
   function setStakingStartTime(uint startTime) external returns(bool result){
      LibDiamond.enforceIsContractManager();
      require(startTime==0 || startTime>=block.timestamp,'invalid staking time');
      if(startTime==0){
         startTime=block.timestamp;
      }
      db.stakingTable.startTime=startTime;
      result=true;
      emit _StakingTimeUpdated(msg.sender,db.stakingTable.startTime);
   }
   function getStakingStartTime() external view returns(uint){
      return db.stakingTable.startTime;
   }
   function setStakingParam(bool enableLock,bool enableUnLock,bool enableBonus) external returns(bool result){
      LibDiamond.enforceIsContractManager();
      db.stakingTable.isEnableLock=enableLock;
      db.stakingTable.isEnableUnLock=enableUnLock;
      db.stakingTable.isEnableBonus=enableBonus;
      result=true;
      emit _StakingParamUpdated(msg.sender,enableLock,enableUnLock,enableBonus);
   }
   function getStakingParam() external view returns(bool enableLock,bool enableUnLock,bool enableBonus){
      enableLock= db.stakingTable.isEnableLock;
      enableUnLock=db.stakingTable.isEnableUnLock;
      enableBonus=db.stakingTable.isEnableBonus;
   }
   function getStakingMin() external view returns(uint poolAMin,uint poolBMin){
      poolAMin= consts.stakingParam.poolAMin;
      poolBMin=consts.stakingParam.poolBMin;
   }
   function setStakingMin(uint poolAMin,uint poolBMin) external returns(bool result){
      LibDiamond.enforceIsContractManager();
      consts.stakingParam.poolAMin=poolAMin;
      consts.stakingParam.poolBMin=poolBMin;
      result=true;
   }
   function getArbitParam() external view returns(uint arbitNum,uint nOrderArbitCost,uint nCardArbitCost,uint nCardMaxGive){
      arbitNum=consts.arbitParam.nArbitNum;
      nOrderArbitCost=consts.arbitParam.nOrderArbitCost;
      nCardArbitCost=consts.arbitParam.nCardArbitCost;
      nCardMaxGive=consts.arbitParam.nCardMaxGive;
   }
   function setArbitParam(uint arbitNum,uint nOrderArbitCost,uint nCardArbitCost,uint nCardMaxGive) external returns(bool result){
      LibDiamond.enforceIsContractManager();
      consts.arbitParam.nArbitNum=arbitNum;
      consts.arbitParam.nOrderArbitCost=nOrderArbitCost;
      consts.arbitParam.nCardArbitCost=nCardArbitCost;
      consts.arbitParam.nCardMaxGive=nCardMaxGive;
      result=true;
      emit _ArbitParamUpdated(msg.sender,nOrderArbitCost,nCardArbitCost);
   }
   function getUnlockParam() external view returns(uint unLockWaitTime,uint bonusUnlockTime){
      unLockWaitTime= consts.stakingParam.unLockWaitTime;
      bonusUnlockTime=consts.stakingParam.bonusUnlockTime;
   }
   function setUnlockParam(uint unLockWaitTime,uint bonusUnlockTime) external returns(bool result){
      LibDiamond.enforceIsContractManager();
      consts.stakingParam.unLockWaitTime=unLockWaitTime;
      consts.stakingParam.bonusUnlockTime=bonusUnlockTime;
      result=true;
      emit _UnlockParamUpdated(msg.sender,unLockWaitTime,bonusUnlockTime);
   }
   function getBonusParam() external view returns(uint firstBonusTime,uint bonusWaitTime){
      firstBonusTime= consts.stakingParam.firstBonusTime;
      bonusWaitTime= consts.stakingParam.bonusWaitTime;
   }
   function setBonusParam(uint firstBonusTime,uint bonusWaitTime) external returns(bool result){
      LibDiamond.enforceIsContractManager();
      consts.stakingParam.firstBonusTime=firstBonusTime;
      consts.stakingParam.bonusWaitTime=bonusWaitTime;
      result=true;
      emit _BonusParamUpdated(msg.sender,firstBonusTime,bonusWaitTime);
   }
   function getOrderParam()external view returns(uint maxMine){
      maxMine=consts.nMaxOrderMine;
   }
   function setOrderParam(uint maxMine)external{
      LibDiamond.enforceIsContractManager();
      consts.nMaxOrderMine=maxMine;
   }
   function depostArbitAsset(address destAddress,address token,uint amount) external{
      LibDiamond.enforceIsContractOwner();
      require(db.arbitTable.extend.arbitGivedToken[token]>=amount,'insufficient balance');
      db.arbitTable.extend.arbitGivedToken[token]=db.arbitTable.extend.arbitGivedToken[token].sub(amount);
      LibERC20.transfer(token, destAddress, amount);

      emit _DepostArbitAsset(destAddress,token,amount);
   }
   function InitParam() external{
      LibDiamond.enforceIsContractOwner();

       //priceParam;
      _initPriceParam();
      //contract param
      _initParams();

   }
   function _initParams() internal{
        {
          consts.priceMode= 0 ;//0-auto,1-manual
          consts.vipDOTC= 100 * consts.priceParam.nDOTCDecimals;
          consts.arbiterDOTC=500 * consts.priceParam.nDOTCDecimals;//5000000000000000;
          consts.nMaxOrderMine= 100 * consts.priceParam.nDOTCDecimals;//Maximum backed DOTC quantity of a single order
          consts.maxDotcPrice= 1e8 * 16666; //consts.priceParam.nDOTCDecimals;
          db.config.makerFee=20;
          db.config.takerFee=20;
        }
        {
           consts.orderLimit.orderNum=5;
           consts.orderLimit.vipOrderNum=20;
           consts.orderLimit.vipAdorder=20;
           consts.orderLimit.exOrderOutTime=30 minutes; //spare value
           consts.orderLimit.AdOutTime= 30 minutes; //spare value
           consts.orderLimit.cancelWaitTime = 30 minutes;
        }
        {
           consts.arbitParam.nArbitNum=11; // prod 11, test 3
           consts.arbitParam.nOrderArbitCost= 20 * consts.priceParam.nUsdtDecimals; //USDT
           consts.arbitParam.nCardArbitCost= 20 * consts.priceParam.nUsdtDecimals; //USDT
           consts.arbitParam.arbiterApplyCost= 100 * consts.priceParam.nDOTCDecimals; //DOTC
           consts.arbitParam.arbiterPunish= 20 * consts.priceParam.nUsdtDecimals; //USDT
           consts.arbitParam.nCardMaxGive=10000 * consts.priceParam.nDOTCDecimals;//DOTC,maximum dotc quantity of card arbit
        }
        {
            consts.stakingParam.poolAMin=100 * consts.priceParam.nDOTCDecimals;
            consts.stakingParam.poolBMin=10 * consts.priceParam.nDOTCDecimals;
            consts.stakingParam.unLockWaitTime= 7 days; // 5 minutes;  7 days
            consts.stakingParam.bonusUnlockTime=7 days; // 5 minutes;  7 days
            consts.stakingParam.bonusWaitTime = 7 days; // 5 minutes;  7 days
            consts.stakingParam.firstBonusTime= 7 days; // 5 minutes;  7 days
            consts.stakingParam.bonusPeriod  = 30 days; // 1 hours;    30 days
        }
        {
           //period param
           //FIRST_TRADE_LOCKTIME
           consts.periodParam.firstTradeLockTime= 10 seconds;
           //OTHER_TRADE_LOCKTIME
           consts.periodParam.otherTradeLockTime= 10 seconds;
           //ARBIT_PERIOD_TIME
           consts.periodParam.arbitPeriodTime=3 days; // test 10 minutes prod 3 days;
           //CARD_PERIOD_TIME
           consts.periodParam.cardPeriodTime= 30 days; // test 5 minutes prod 30 days;
           //DEPOSIT_RATE
           consts.periodParam.depositRate= 10;
        }

    }
   function _initPriceParam() internal {
        consts.priceParam.nDOTCDecimals=10 ** (IERC20(db.config.dotcContract).decimals());
        consts.priceParam.nWethDecimals=10 ** (IERC20(db.config.wethContract).decimals());
        consts.priceParam.nUsdtDecimals=10 ** (IERC20(db.config.usdtContract).decimals());
        //MIN_ORDER_VALUE
        consts.priceParam.minOrderValue=200 * consts.priceParam.nUsdtDecimals;
        //MIN_AD_VALUE
        consts.priceParam.minAdValue=1000 * consts.priceParam.nUsdtDecimals;
        //MIN_AD_DEPOSIT_VALUE
        consts.priceParam.minAdDepositeValue=100 * consts.priceParam.nUsdtDecimals;
   }
   function InitLendParam() external{
      LibDiamond.enforceIsContractOwner();

      uint usdtDecimals=consts.priceParam.nUsdtDecimals;
      {
           db.lendTable.pledgeParam.minPledge = 100*usdtDecimals;
           db.lendTable.pledgeParam.maxPledge = 100000*usdtDecimals;
           db.lendTable.pledgeParam.bonusRate = 5;
           db.lendTable.pledgeParam.minBonusPeriod = 30 days; // prod 30 days test 30 minutes
      }
      {
            db.lendTable.lendParam.lendRate = 10;
            db.lendTable.lendParam.maxLendValue = 50000*usdtDecimals;
            db.lendTable.lendParam.minInterest = usdtDecimals/10;
            db.lendTable.lendParam.clearRate = 9000;
      }
   }
   /*
   function forceCloseAdOrder(string calldata AdOrderId) external{
      LibDiamond.enforceIsContractManager();
      {
         require(db.orderTable.otcAdOrders[AdOrderId].makerAddress !=address(0),'AdOrder not exists');
         require(db.orderTable.otcAdOrders[AdOrderId].state == OrderState.ONTRADE,'AdOrder has been closed');
         require(_getAdOrderExCount(AdOrderId)== 0,'there is non-closed trade order');
      }
   }*/
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface IDOTCManageFacet {
    event _UnitUpdated(address indexed dotcAddr,address indexed wethAddr);
    event ManagerTransferred(address indexed previousManager, address indexed newManager);
    event _EmergentPauseUpdated(address indexed userAddr,bool indexed isPause,bool indexed isPauseAsset);
    event _PriceModeChanged(address indexed userAddr,uint indexed mode);
    event _PriceManualChanged(address indexed userAddr,uint indexed price);
    event _VIPConditionUpdated(address indexed userAddr,uint indexed amount);
    event _ArbitConditionUpdated(address indexed userAddr,uint indexed stakingDOTC,uint applyCost,uint punishCost);
    event _StakingTimeUpdated(address indexed userAddr,uint indexed time);
    event _StakingParamUpdated(address indexed userAddr,bool enableLock,bool enableUnLock,bool enableBonus);
    event _StakingMinUpdated(address indexed userAddr,uint indexed poolAMin,uint indexed poolBMin);
    event _ArbitParamUpdated(address indexed userAddr,uint indexed nOrderArbitCost,uint indexed nCardArbitCost);
    event _UnlockParamUpdated(address indexed userAddr,uint indexed unLockWaitTime,uint indexed bonusUnlockTime);
    event _BonusParamUpdated(address indexed userAddr,uint indexed firstBonusTime,uint indexed bonusWaitTime);

    event _MaxDotcPriceUpdated(address indexed userAddr,uint newMax);

    event _DepostArbitAsset(address indexed destAddress,address indexed token,uint amount);

    //event _ForceCloseAdOrder(address indexed userAddr,string AdOrderId);

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import "../facetBase/DOTCLendBase.sol";

import '../utils/SafeMath.sol';

contract DOTCLendFacet is DOTCLendBase{
    using SafeMath for uint;


    function userPledgeToken(uint tokenType,uint pledgeAmount,uint period) external returns(address token,uint dotcPrice,uint bonusRate){
        {
            require(!db.lendTable.isForbidden,'lend banned');
            require(db.lendTable.pledgeParam.enabled,'pledge not enabled');
            require(tokenType==0 || tokenType==1,'tokenType error');
            require(pledgeAmount>0,'invalid amount');
            // pledge USDT limit amount < 100k
            if(tokenType==1){
                require(pledgeAmount <= db.lendTable.pledgeParam.maxPledge,'exceed maximum pledge');
            }
        }
        (token,dotcPrice,bonusRate)=_pledgeToken(msg.sender,tokenType,pledgeAmount,period);

        emit _userPledged(msg.sender,token,pledgeAmount,dotcPrice,bonusRate);
    }
    function userLendToken(uint tokenType,uint lendAmount) external returns(address lendToken,uint actualLend,uint dotcPrice,uint   lendRate){
        {
            require(!db.lendTable.isForbidden,'lend banned');
            require(db.lendTable.lendParam.enabled,'lend not enabled');
            require(tokenType==0 || tokenType==1,'tokenType error');
            require(lendAmount>0,'invalid amount');
        }
        (lendToken,actualLend,dotcPrice,lendRate) = _lendToken(msg.sender,tokenType,lendAmount);

        emit _userLendCreated(msg.sender,lendToken,actualLend,lendRate);
    }
    function backLendAssets() external returns(uint interest,address lendToken,uint actualBack){
        {
            require(!db.lendTable.isForbidden,'lend banned');
        }
        uint lendAmount=db.lendTable.userLend[msg.sender].lend.lendAmount;
        (interest,lendToken,actualBack) = _backToken(msg.sender);

        emit _userLendBacked(msg.sender,lendToken,lendAmount,interest,actualBack);
    }
    function unLockPledge() external returns(address unlockToken,uint unlockAmount,uint bonusDOTC){
        {
            require(!db.lendTable.isForbidden,'lend banned');
        }
        (unlockToken,unlockAmount,bonusDOTC) = _unlockPledgeAmount(msg.sender);

        emit _userPledgeUnlocked(msg.sender,unlockToken,unlockAmount,bonusDOTC);
    }
    function updatePledgePeriod(uint newPeriod) external{
        {
            require(!db.lendTable.isForbidden,'lend banned');
            require(_checkPeriodValid(newPeriod),'invalid period');
        }
        LendResult storage userLend=db.lendTable.userLend[msg.sender];
        {
            require(userLend.state>0,'state cleared');
            require(userLend.pledge.pledgeAmount>0,'pledgeAmount zero');
            require(newPeriod>userLend.pledge.pledgePeriod,'period less');
        }
        uint oldPeriod = userLend.pledge.pledgePeriod;
        userLend.pledge.pledgePeriod=newPeriod;

        emit _userPledgePerioded(msg.sender,newPeriod,oldPeriod);
    }
    function getPledgeBonus(address userAddr) external view returns(uint bonusDotc) {
        LendResult storage userLend=db.lendTable.userLend[userAddr];
        bonusDotc = _getPledgeBonus(userLend);
    }

    function getInterest(address userAddr)  external view returns(uint interest) {
        LendResult storage userLend=db.lendTable.userLend[userAddr];
        {
            require(userLend.state==2,'state not lending');
            require(userLend.lend.lendAmount>0,'lendAmount zero');
            // require(block.timestamp<userLend.pledge.pledgeTime.add(userLend.pledge.pledgePeriod),'period exceed');
        }
        interest=_getInterest(userLend.lend.lendToken,userLend.lend.lendAmount,userLend.lend.lendTime,userLend.lend.lendRate);
    }

    function queryLendAvail(uint tokenType,uint pledgeAmount,uint pledgePeriod) external view returns(uint lendAvail,address lendToken){
        address pledgeToken;
        if(tokenType==0){
            pledgeToken=db.config.dotcContract;
            lendToken=db.config.usdtContract;
        }else{
            pledgeToken=db.config.usdtContract;
            lendToken=db.config.dotcContract;
        }
        lendAvail=_queryLendValue(pledgeToken,pledgeAmount,pledgePeriod,lendToken,_getProtectPrice());
    }
    function queryLendPrice() external view returns(uint dotcPrice){
        dotcPrice = _getProtectPrice();
    }
    function queryLendPoolInfo(uint tokenType) external view returns(LendPoolInfo memory pool){
       if(tokenType==0){
           //dotc
           pool = db.lendTable.poolTokens[db.config.dotcContract];
       }else{
           //usdt
           pool = db.lendTable.poolTokens[db.config.usdtContract];
       }
    }
    function queryLendParam() external view returns(LendGlobal memory global,PledgeParam memory pledge,LendParam memory lend){
        global = db.lendTable.global;
        pledge = db.lendTable.pledgeParam;
        lend = db.lendTable.lendParam;
    }
    function queryUserLend(address userAddr) external view returns(UserPledge memory pledge,UserLend memory lend,uint8 state){
       pledge = db.lendTable.userLend[userAddr].pledge;
       lend = db.lendTable.userLend[userAddr].lend;
       state = db.lendTable.userLend[userAddr].state;
    }
   /* function queryUserLendRate(address userAddr) external view returns(uint interest,address intToken,uint pledgeRate,uint bonusDOTC){
        //check unlock period
        LendResult storage userLend=db.lendTable.userLend[userAddr];
        if(userLend.state==2){
            //lending
            intToken=userLend.lend.lendToken;
            interest = _getInterest(intToken,userLend.lend.lendAmount,userLend.lend.lendTime,userLend.lend.lendRate);
        } if(userLend.state>=1){
            //pledged
            pledgeRate=10000;
            //bonus
            bonusDOTC = _getPledgeBonus(userLend);
        }
    }*/
    function queryUserCanClear(address userAddr) external view returns(uint pledgeRate,uint interest,uint dotcPrice,bool canClear){
        LendResult memory userLend=db.lendTable.userLend[userAddr];
        (pledgeRate,interest,dotcPrice,canClear)=_checkPledgeClear(userLend);
    }
    function queryLendForbidden() external view returns(bool isForbidden){
        isForbidden=db.lendTable.isForbidden;
    }
    /***Pool Manage */
    function clearUserLendAsset(address userAddr) external returns(uint pledgeRate,uint clearRate,uint interest,uint dotcPrice, uint pledgeAmount,uint clearAmount,uint clearInterest){
        LibDiamond.enforceIsContractManager();
        bool canClear;
        LendResult storage userLend=db.lendTable.userLend[userAddr];
        (pledgeRate,interest,dotcPrice,canClear)=_checkPledgeClear(userLend);
        require(canClear,'can not clear');
        clearRate=db.lendTable.lendParam.clearRate;
        {
            //pledge into risk
            pledgeAmount=userLend.pledge.pledgeAmount;
            //to risk
           _transferTokenToPool(userLend.pledge.pledgeToken,pledgeAmount);
        }
        {
            //interest
            clearInterest=2*interest;
            address lendToken=userLend.lend.lendToken;

            uint balance=db.userTable.userAssets[userAddr][lendToken].available;
            clearAmount=userLend.lend.lendAmount.min(balance);

            clearInterest=clearInterest.min(balance.sub(clearAmount));
            if(clearInterest>0){
                clearAmount=clearAmount.add(clearInterest);
            }
            // clearAmount
            clearAmount = clearAmount.min(balance);
            db.userTable.userAssets[userAddr][lendToken].available=balance.sub(clearAmount);
            //to risk
            _transferTokenToPool(lendToken,clearAmount);
        }
        {
            //update state
            userLend.state=0;
        }

        emit _userLendAssetCleared(msg.sender,userAddr,dotcPrice,pledgeAmount,clearAmount,clearInterest);
    }
    //param set
    function setPledgeParam(uint bonusRate,uint minBonusPeriod,uint minPledge,uint maxPledge, bool enabled) external{
        LibDiamond.enforceIsContractManager();
        {
            require(bonusRate>=0 && bonusRate<=10000,'bonusRate exceed');
            require(minBonusPeriod>= 1 days,'bonusPeriod zero');
            require(maxPledge>minPledge,'maxPledge error');
            require(minPledge>0,'minPledge zero');
        }

        db.lendTable.pledgeParam.bonusRate=bonusRate;
        db.lendTable.pledgeParam.minBonusPeriod=minBonusPeriod;
        db.lendTable.pledgeParam.minPledge=minPledge;
        db.lendTable.pledgeParam.maxPledge=maxPledge;
        db.lendTable.pledgeParam.enabled=enabled;

        emit _pledgeParamUpdated(msg.sender,bonusRate,minBonusPeriod,minPledge,maxPledge);
    }
    function setLendParam(uint lendRate,uint maxLendValue,uint minInterest,uint clearRate, bool enabled) external{
        LibDiamond.enforceIsContractManager();
        {
            require(lendRate>=0 && lendRate<=10000,'lendRate exceed');
            require(maxLendValue>0,'maxLendValue zero');
            require(clearRate>=500 && clearRate<=10000,'clearRate exceed');
        }

        db.lendTable.lendParam.lendRate=lendRate;
        db.lendTable.lendParam.maxLendValue=maxLendValue;
        db.lendTable.lendParam.minInterest=minInterest;
        db.lendTable.lendParam.clearRate=clearRate;
        db.lendTable.lendParam.enabled=enabled;

        emit _lendParamUpdated(msg.sender,lendRate,maxLendValue,minInterest,clearRate);
    }

    function setPledgeEnabled(bool enabled) external{
        LibDiamond.enforceIsContractManager();
        db.lendTable.pledgeParam.enabled=enabled;
        emit _setPledgeEnabled(msg.sender,enabled);
    }
    function setLendEnabled(bool enabled) external{
        LibDiamond.enforceIsContractManager();
        db.lendTable.lendParam.enabled=enabled;
        emit _setLendEnabled(msg.sender,enabled);
    }


    function setLendRiskPrice(uint riskPrice) external{
       LibDiamond.enforceIsContractManager();

       db.lendTable.global.riskPrice = riskPrice;
       db.lendTable.global.priceTime = block.timestamp;

       emit _lendRiskPriceUpdated(msg.sender,riskPrice,db.lendTable.global.priceTime);
    }
    function setLendProtectPrice(uint minPrice,uint maxPrice) external{
        LibDiamond.enforceIsContractManager();
        require(minPrice>0,'minPrice zero');
        require(maxPrice>minPrice,'maxPrice error');

        db.lendTable.global.minDOTCPrice=minPrice;
        db.lendTable.global.maxDOTCPrice=maxPrice;

        emit _lendProtectPriceUpdated(msg.sender,minPrice,maxPrice);
    }
    function setLendForbidden(bool isForbidden) external{
        LibDiamond.enforceIsContractManager();

        db.lendTable.isForbidden = isForbidden;

        emit _lendForbiddenUpdated(msg.sender,isForbidden);
    }


    function setLendConfig(uint tokenType,bool isVip,uint pledgeRate,uint lendRate,bool isLock) external {
        LibDiamond.enforceIsContractManager();
        address token=db.config.dotcContract;
        if(tokenType==0){
            //lend dotc
            token = db.config.dotcContract;

        }else{
            //lend usdt
            token = db.config.usdtContract;
        }
        //update
        LendPoolInfo storage pool=db.lendTable.poolTokens[token];
        pool.config.isVip = isVip;
        pool.config.pledgeRate = pledgeRate;
        pool.config.lendRate = lendRate;
        pool.config.isLock = isLock;

        emit _lendConfigUpdated(msg.sender,isVip,pledgeRate,lendRate,isLock);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';

contract DOTCLendBase is DOTCFacetBase{
    using SafeMath for uint;

    //period max
    uint constant PERIOD_MAX=500;//USDT
    //risk period
//    uint constant PERIOD_RISK = 7 minutes;
    uint constant PERIOD_RISK = 7 days;

    event _userPledged(address indexed userAddr,address indexed token,uint amount,uint dotcPrice,uint bonusRate);
    event _userLendCreated(address indexed userAddr,address indexed lendToken,uint lendAmount,uint lendRate);
    event _userLendBacked(address indexed userAddr,address indexed lendToken,uint lendAmount,uint interest,uint actualBack);
    event _userPledgeUnlocked(address indexed userAddr,address indexed unlockToken,uint unlockAmount,uint bonusDOTC);
    event _userPledgePerioded(address indexed userAddr,uint newPeriod,uint oldPeriod);
    //manage
    event _userLendAssetCleared(address indexed manager,address indexed user,uint dotcPrice, uint pledgeAmount,uint clearAmount,uint clearInterest);
    event _pledgeParamUpdated(address indexed manager,uint bonusRate,uint minBonusPeriod,uint minPledge,uint maxPledge );
    event _lendParamUpdated(address indexed manager,uint lendRate,uint maxLendValue,uint minInterest,uint clearRate);
    event _setPledgeEnabled(address indexed manager, bool enabled);
    event _setLendEnabled(address indexed manager, bool enabled);
    event _lendRiskPriceUpdated(address indexed manager,uint price,uint priceTime);
    event _lendProtectPriceUpdated(address indexed manager,uint minPrice,uint maxPrice );
    event _lendForbiddenUpdated(address indexed manager,bool isForbidden );
    event _lendConfigUpdated(address indexed manager,bool isVip,uint pledgeRate,uint lendRate,bool isLock );

    function _pledgeToken(address userAddr,uint tokenType,uint amount,uint period) internal returns(address token,uint dotcPrice,uint bonusRate){
        {
            require(db.lendTable.userLend[userAddr].state==0,'state locked');
            require(_checkPeriodValid(period),'invalid period');
        }

        token=(tokenType==0?db.config.dotcContract:db.config.usdtContract);

        // pledge USDT limit poolTotal <5000k
        if(tokenType==1){
            require(db.lendTable.poolTokens[token].totalPledge.add(amount) <= 5000000 * consts.priceParam.nUsdtDecimals,'USDT pledge pool  fulled');
        }

        {
            dotcPrice=_getProtectPrice();
            bonusRate = db.lendTable.pledgeParam.bonusRate;

            db.lendTable.userLend[userAddr].pledge.pledgeToken=token;
            db.lendTable.userLend[userAddr].pledge.pledgeAmount=amount;
            db.lendTable.userLend[userAddr].pledge.pledgeTime=block.timestamp;
            db.lendTable.userLend[userAddr].pledge.pledgePeriod= period;
            db.lendTable.userLend[userAddr].pledge.dotcPrice=dotcPrice;
            db.lendTable.userLend[userAddr].pledge.bonusRate=bonusRate;
            //update state
            db.lendTable.userLend[userAddr].state=1;
            {
                //clear lend
                db.lendTable.userLend[userAddr].lend.lendToken=address(0);
                db.lendTable.userLend[userAddr].lend.lendAmount=0;
                db.lendTable.userLend[userAddr].lend.lendRate=0;
                db.lendTable.userLend[userAddr].lend.lendTime=0;
            }
            //total
            db.lendTable.poolTokens[token].totalPledge=db.lendTable.poolTokens[token].totalPledge.add(amount);
            db.lendTable.poolTokens[token].pledgeAccount=db.lendTable.poolTokens[token].pledgeAccount.add(1);

            //update asset
            db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.sub(amount);
        }
    }
    function _getProtectPrice() internal view returns(uint dotcUPrice){
        uint dotcPrice=_getPubDOTCPrice();

        uint usdtDecimals=consts.priceParam.nUsdtDecimals;
        uint dotcDecimals=consts.priceParam.nDOTCDecimals;
        dotcUPrice = usdtDecimals.mul(dotcDecimals).div(dotcPrice);

        if(db.lendTable.global.maxDOTCPrice>0){
            dotcUPrice=dotcUPrice.min(db.lendTable.global.maxDOTCPrice);
        }
        if(db.lendTable.global.minDOTCPrice>0){
            dotcUPrice=dotcUPrice.max(db.lendTable.global.minDOTCPrice);
        }
    }
    function _lendToken(address userAddr,uint tokenType,uint amount) internal returns(address lendToken,uint lendAmount,uint dotcPrice,uint lendRate){
        LendResult storage userLend=db.lendTable.userLend[userAddr];
        {
            require(userLend.state==1,'state error');// no pledge or lending
        }
        address pledgeToken=userLend.pledge.pledgeToken;
        if(tokenType==0){
            //lend dotc
            require(pledgeToken==db.config.usdtContract,'pledge not USDT');

        }else{
            //lend usdt
            require(pledgeToken==db.config.dotcContract,'pledge not DOTC');
        }
        uint lendAvail=0;
        (lendToken,dotcPrice,lendAvail)=_queryLendAvail(userLend);
        {
             //check vip
            if(db.lendTable.poolTokens[lendToken].config.isVip){
                require(db.userTable.userList[msg.sender].isVIP,"only vip lend this token");
            }

            require(lendToken!=address(0) && lendAvail>=amount,'lendAmount not enough');
            LendPoolInfo memory pool=db.lendTable.poolTokens[lendToken];
            require(pool.totalPledge>amount.add(pool.totalLend),'pool not enough');
            uint lendLeft=pool.totalPledge.sub(amount.add(pool.totalLend));
            require(lendLeft>=pool.totalPledge.mul(30).div(100),'pool left limit');
        }
        {
            //start lend
            userLend.lend.lendToken=lendToken;
            userLend.lend.lendTime=block.timestamp;
            userLend.lend.lendAmount=amount;
            lendAmount=amount;
            lendRate=db.lendTable.lendParam.lendRate;
            userLend.lend.lendRate= lendRate;
            //update state
            userLend.state=2;
            //update assets
            db.userTable.userAssets[userAddr][lendToken].available=db.userTable.userAssets[userAddr][lendToken].available.add(amount);
            //update total
            db.lendTable.poolTokens[lendToken].totalLend=db.lendTable.poolTokens[lendToken].totalLend.add(amount);
            db.lendTable.poolTokens[lendToken].lendAccount++;
        }
    }
    function _backToken(address userAddr) internal returns(uint interest,address lendToken,uint backAmount){
        LendResult storage userLend=db.lendTable.userLend[userAddr];

        {
            require(userLend.state==2,'state not lending');
            require(userLend.lend.lendAmount>0,'lendAmount zero');
           // require(block.timestamp<userLend.pledge.pledgeTime.add(userLend.pledge.pledgePeriod),'period exceed');
        }
        lendToken=userLend.lend.lendToken;
        interest=_getInterest(userLend.lend.lendToken,userLend.lend.lendAmount,userLend.lend.lendTime,userLend.lend.lendRate);
        interest=interest.min(userLend.lend.lendAmount);
        backAmount=interest.add(userLend.lend.lendAmount);

        AssetInfo storage userAssets = db.userTable.userAssets[userAddr][lendToken];
        require(userAssets.available >= backAmount, 'Insufficient available');
        {
            //start backToken
            //update state
            userLend.state=1;
            //update assets
            userAssets.available=userAssets.available.sub(backAmount);
            //update total
            db.lendTable.poolTokens[lendToken].totalLend=db.lendTable.poolTokens[lendToken].totalLend.sub(userLend.lend.lendAmount);
            if(db.lendTable.poolTokens[lendToken].lendAccount>0)
            {
                db.lendTable.poolTokens[lendToken].lendAccount--;
            }
            //transfer interest
            _transferTokenToPool(lendToken, interest);
            //clear lend
            userLend.lend.lendToken=address(0);
            userLend.lend.lendTime = 0;
            userLend.lend.lendAmount=0;
            userLend.lend.lendRate= 0;
        }

    }
    function _unlockPledgeAmount(address userAddr) internal returns(address pledgeToken,uint pledgeAmount,uint bonusAmount){
        //check unlock period
        LendResult storage userLend=db.lendTable.userLend[userAddr];
        {
            require(userLend.state==1,'state error');
            require(userLend.pledge.pledgeAmount>0,'lendAmount zero');
            //check period
            require(block.timestamp>=userLend.pledge.pledgeTime.add(userLend.pledge.pledgePeriod),'period limit');
        }
        {
            //start unlock
            pledgeToken=userLend.pledge.pledgeToken;
            pledgeAmount=userLend.pledge.pledgeAmount;
            uint poolBalance =db.lendTable.poolTokens[pledgeToken].totalPledge.sub(db.lendTable.poolTokens[pledgeToken].totalLend);
            require(poolBalance >= pledgeAmount,'Insufficient available balance in the loan pool');

          /*  if(poolBalance >=pledgeAmount){*/
              //normal
            db.userTable.userAssets[userAddr][pledgeToken].available=db.userTable.userAssets[userAddr][pledgeToken].available.add(pledgeAmount);
            db.lendTable.poolTokens[pledgeToken].totalPledge= db.lendTable.poolTokens[pledgeToken].totalPledge.sub(pledgeAmount);
           /* }else{
                //not enough
                //back from risk pool
                uint riskBalance=db.daoData.riskPool.poolTokens[pledgeToken].currentSupply;
                uint backAmount=pledgeAmount.min(riskBalance);
                db.userTable.userAssets[userAddr][pledgeToken].available=db.userTable.userAssets[userAddr][pledgeToken].available.add(backAmount);
                db.lendTable.poolTokens[pledgeToken].totalPledge= poolBalance.sub(pledgeAmount);
                if(pledgeAmount>backAmount){
                    if(pledgeToken==db.config.usdtContract){
                      //USDT,back dotc
                      uint riskPrice=db.lendTable.global.riskPrice;
                      require(riskPrice>0,'riskPrice zero');
                      require(block.timestamp<db.lendTable.global.priceTime.add(PERIOD_RISK),'Risk price overTime');
                      uint riskDotcBalance=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply;
                      uint dotcAmount= pledgeAmount.mul(riskPrice).div(consts.priceParam.nUsdtDecimals);
                      uint backDotcAmount=dotcAmount.min(riskDotcBalance);
                      db.userTable.userAssets[userAddr][db.config.dotcContract].available=db.userTable.userAssets[userAddr][db.config.dotcContract].available.add(backDotcAmount);
                    }else if(pledgeToken==db.config.dotcContract){
                        //DOTC
                    }
                }
            }*/
        }
        if(pledgeToken == db.config.dotcContract){
            //check bonus
            bonusAmount=_getPledgeBonus(userLend);
            if(bonusAmount>0){
                _bonusDOTCToUser(userAddr,bonusAmount);
            }
        }
        {
            //reset state
            userLend.state=0;
            if(db.lendTable.poolTokens[pledgeToken].pledgeAccount>0){
                db.lendTable.poolTokens[pledgeToken].pledgeAccount--;
            }
        }

    }
    function _queryLendAvail(LendResult memory userLend) internal view returns(address lendToken,uint dotcPrice,uint lendAvail){
        if(userLend.state==1 && userLend.pledge.pledgeToken!=address(0)){
            //avail
            dotcPrice=_getProtectPrice();
            lendToken=(userLend.pledge.pledgeToken==db.config.dotcContract?db.config.usdtContract:db.config.dotcContract);
            uint pledgeAmount=userLend.pledge.pledgeAmount;
            lendAvail=_queryLendValue(userLend.pledge.pledgeToken,pledgeAmount,userLend.pledge.pledgePeriod, lendToken,dotcPrice);
        }
    }
    function _queryLendValue(address pledgeToken,uint pledgeAmount,uint pledgePeriod,address lendToken,uint dotcPrice) internal view returns(uint lendAvail){
        uint periodMax=_getPeriodLendMax(pledgePeriod);
        if(pledgeToken==db.config.dotcContract){
            //pledge dotc,lend usdt
            uint pleValue=pledgeAmount.mul(db.lendTable.poolTokens[pledgeToken].config.pledgeRate).div(10000);
            lendAvail=pleValue.mul(dotcPrice).div(consts.priceParam.nDOTCDecimals);
            // consts.priceParam.nUsdtDecimals
            //check max
            lendAvail=lendAvail.min(db.lendTable.lendParam.maxLendValue);
            lendAvail=lendAvail.min(periodMax);
            lendToken=db.config.usdtContract;
        }else{
            //pledge usdt,lend dotc
            uint pleValue=pledgeAmount.mul(db.lendTable.poolTokens[pledgeToken].config.pledgeRate).div(10000); //usdt
            pleValue=pleValue.min(db.lendTable.lendParam.maxLendValue);
            pleValue=pleValue.min(periodMax);

            lendAvail=pleValue.mul(consts.priceParam.nDOTCDecimals).div(dotcPrice);
            lendToken=db.config.dotcContract;
        }
    }
    function _getInterest(address lendToken,uint lendAmount,uint lendTime,uint rate) internal view returns(uint interest){
        uint lendDays=block.timestamp.sub(lendTime).div(1 days);
        // uint lendDays=block.timestamp.sub(lendTime).div(1 minutes);
        if(lendDays<1) lendDays=1;
        interest=lendAmount.mul(lendDays).mul(rate)/10000;

        interest=interest.min(lendAmount);
        if(lendToken== db.config.dotcContract){
            uint minDotc=_getDOTCNumFromUSDT(db.lendTable.lendParam.minInterest);
            interest = interest.max(minDotc);
        }else{
          interest=interest.max(db.lendTable.lendParam.minInterest);
        }

    }
    function _getRealPledgeRate(LendResult memory userLend,uint price,uint interest) internal view returns(uint pledgeRate){
        address lendToken = userLend.lend.lendToken;
        uint pledgeValue = userLend.pledge.pledgeAmount;
        if(pledgeValue>0){
            uint lendTotal = userLend.lend.lendAmount.add(interest);
            uint lendValue = 0;
            if(lendToken== db.config.dotcContract){
                lendValue= lendTotal.mul(price).div(consts.priceParam.nDOTCDecimals);
                pledgeRate = lendValue.mul(10000).div(pledgeValue);
            } else {
                lendValue= lendTotal;
                pledgeRate = lendValue.mul(10000).div(pledgeValue.mul(price).div(consts.priceParam.nDOTCDecimals));
            }
        }
    }
    function _checkPledgeClear(LendResult memory userLend) internal view returns(uint pledgeRate,uint interest,uint dotcPrice,bool canClear){
        if(userLend.state>1){
            //lending state
            interest=_getInterest(userLend.lend.lendToken,userLend.lend.lendAmount,userLend.lend.lendTime,userLend.lend.lendRate);
            dotcPrice=_getProtectPrice();
            pledgeRate=_getRealPledgeRate(userLend, dotcPrice,interest);
            canClear=(pledgeRate>=db.lendTable.lendParam.clearRate || block.timestamp>=userLend.pledge.pledgeTime.add(userLend.pledge.pledgePeriod));
        }
    }
    function _transferTokenToPool(address token,uint amount) internal{
        if(amount>0){
           //token to risk pool
           db.daoData.riskPool.poolTokens[token].currentSupply=db.daoData.riskPool.poolTokens[token].currentSupply.add(amount);
        }

        /* if(token==db.config.dotcContract){
            //dotc to risk pool
            db.daoData.riskPool.poolTokens[token].currentSupply=db.daoData.riskPool.poolTokens[token].currentSupply.add(amount);
        }
        else{
            //usdt to staking pool
            _transferUSDTToStakingPool(amount);
        } */
    }
    function _transferUSDTToStakingPool(uint usdtAmount) internal{
      //staking pool
      if(usdtAmount<=0) return;
      _updatePoolPeriod();
      uint poolValue=usdtAmount.div(2);
      address token=db.config.dotcContract; //save gas
      db.stakingTable.poolA[token].v2Info.totalUSDTBonus=db.stakingTable.poolA[token].v2Info.totalUSDTBonus.add(poolValue);
      db.stakingTable.poolA[token].totalUSDTBonus=db.stakingTable.poolA[token].totalUSDTBonus.add(poolValue);

      db.stakingTable.poolB[token].v2Info.totalUSDTBonus=db.stakingTable.poolB[token].v2Info.totalUSDTBonus.add(poolValue);
      db.stakingTable.poolB[token].totalUSDTBonus=db.stakingTable.poolB[token].totalUSDTBonus.add(poolValue);
    }
    function _checkPeriodValid(uint period) internal pure returns(bool isValid){
      isValid=(period== 1 days || period== 7 days || period== 30 days || period==90 days || period==180 days);
//    isValid=(period== 1 minutes || period== 7 minutes || period== 30 minutes || period==90 minutes || period==180 minutes);
    }
    function _getPeriodLendMax(uint period) internal view returns(uint maxUSDT){
      maxUSDT=PERIOD_MAX.mul(consts.priceParam.nUsdtDecimals).mul(period.div(1 days));
//    maxUSDT=PERIOD_MAX.mul(consts.priceParam.nUsdtDecimals).mul(period.div(1 minutes));
    }
    function _getPledgeBonus(LendResult memory userLend) internal view returns(uint bonusDotc){
        if(userLend.pledge.pledgePeriod>=db.lendTable.pledgeParam.minBonusPeriod){
            //exist bonus
            uint dotcValue=0;
            if(userLend.pledge.pledgeToken==db.config.dotcContract){
                dotcValue=userLend.pledge.pledgeAmount;
            }
            //else{
                //usdt no bonus 20220210
                // dotcValue=userLend.pledge.pledgeAmount.mul(consts.priceParam.nDOTCDecimals).div(userLend.pledge.dotcPrice);
            //}
            uint pledgePeriod=userLend.pledge.pledgePeriod.div(1 days);
            // uint pledgePeriod=userLend.pledge.pledgePeriod.div(1 minutes);
            if (dotcValue > 0) {
                bonusDotc=dotcValue.mul(userLend.pledge.bonusRate).div(10000).mul(pledgePeriod);
            }
        }
    }
    function _bonusDOTCToUser(address userAddr,uint dotcAmount) internal{
        address token=db.config.dotcContract;
        uint currentSupply=db.daoData.miningPool.poolTokens[token].currentSupply;
        dotcAmount=dotcAmount.min(currentSupply);
        if(dotcAmount>0){
            db.daoData.miningPool.poolTokens[token].currentSupply=currentSupply.sub(dotcAmount);
            db.userTable.userAssets[userAddr][token].available=db.userTable.userAssets[userAddr][token].available.add(dotcAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IFeeFacet.sol";

import '../utils/SafeMath.sol';


contract DOTCFeeFacet is DOTCFacetBase,IFeeFacet {
    using SafeMath for uint; 

    function getMakerFee() external view  override returns (uint) {
       return db.config.makerFee;
    }

    function setMakerFee(uint _fee) external override returns(bool result){
       LibDiamond.enforceIsContractManager();
       require(_fee<10000,'fee must be less than 10000');
       db.config.makerFee=_fee;
       result=true;
       emit feeChanged(0,_fee);
    }

    function getTakerFee() external view override returns(uint){
        return db.config.takerFee;
    }

    function setTakerFee(uint _fee) external override returns(bool result){
       LibDiamond.enforceIsContractManager();
       require(_fee<10000,'fee must be less than 10000');
       db.config.takerFee=_fee;
       result=true;
       emit feeChanged(1,_fee);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IFeeFacet {
    /******** DOTCFee START***/
    event feeChanged(uint indexed feetype,uint indexed fee);

    function getMakerFee() external view returns (uint);

    function setMakerFee(uint _fee) external returns(bool result);

    function getTakerFee() external view returns(uint);

    function setTakerFee(uint _fee) external returns(bool result);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

//import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
import '../libraries/LibStrings.sol';
import '../facetBase/DOTCExOrderBase.sol';

contract DOTCExOrderFacet is DOTCExOrderBase {
    using SafeMath for uint;
    event _ExOrderCreated(string  adOrderId,string  exOrderId,uint  indexedamount);
    event _ExOrderCancelled(string  adOrderId,string  exOrderId);
    event _AdOrderPayed(string  orderId);


   function createExOrder(string calldata adOrderId,string calldata exOrderId,uint amount) external returns (bool result) {
      require(!db.config.isPause,'system paused');
      require(bytes(adOrderId).length > 0,'adOrderId not null');
      require(bytes(exOrderId).length > 0,'exOrderId not null');
      _checkExOrder(adOrderId,exOrderId,amount);
      {
        db.orderTable.otcAdOrders[adOrderId].detail.leftAmount=db.orderTable.otcAdOrders[adOrderId].detail.leftAmount.sub(amount);
        db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount=db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount.add(amount);
      }
      (uint256 nOrderValue,uint256 dotcAmount,uint256 deposit)=_queryAdDeposit(adOrderId,amount);
      require(nOrderValue >= consts.priceParam.minOrderValue,'ExOrder value too little');
      _checkAdOrderLeftDeposit(adOrderId,deposit);

      _checkUpdateOracleTime();

      ExchangeSide myside=(db.orderTable.otcAdOrders[adOrderId].side==ExchangeSide.BUY?ExchangeSide.SELL:ExchangeSide.BUY);
      _updateExAsset(dotcAmount,deposit,amount,db.orderTable.otcAdOrders[adOrderId].tokenA,myside);
      //lock fee
      _lockExOrderFee(adOrderId,exOrderId,dotcAmount,deposit,db.orderTable.otcAdOrders[adOrderId].tokenA,myside,nOrderValue);
      //add trade order
      _addExOrder(adOrderId,exOrderId,amount,myside,nOrderValue,dotcAmount,deposit);
      result=true;
      emit _ExOrderCreated(adOrderId,exOrderId,amount);
   }
   function queryExOrderDeposit(string calldata adOrderId,uint amount) external view returns(uint nOrderValue,uint dotcAmount,uint deposit){
      (nOrderValue,dotcAmount,deposit)=_queryAdDeposit(adOrderId,amount);
   }
   function cancelExOrder(string memory adOrderId,string memory exOrderId) external returns(bool result){
      require(!db.config.isPause,'system paused');
     _checkCancelExOrder(adOrderId,exOrderId);
     _RemoveExOrderFromList(adOrderId,exOrderId);
     {
        uint amount=db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount;
        db.orderTable.otcAdOrders[adOrderId].detail.leftAmount=db.orderTable.otcAdOrders[adOrderId].detail.leftAmount.add(amount);
        db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount=db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount.sub(amount);
     }

     _unLockCancelAssets(adOrderId,exOrderId);

     db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state=TradeState.Cancelled;
     db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.lastUpdateTime=block.timestamp;

     delete db.orderTable.otcExAdMap[exOrderId];
     if(db.orderTable.userOrderDb[msg.sender].noneExOrder>0){
       db.orderTable.userOrderDb[msg.sender].noneExOrder=db.orderTable.userOrderDb[msg.sender].noneExOrder.sub(1);
     }
     if(db.orderTable.userOrderDb[msg.sender].totalExOrder>0){
       db.orderTable.userOrderDb[msg.sender].totalExOrder=db.orderTable.userOrderDb[msg.sender].totalExOrder.sub(1);
     }
     _removeStrFromList(db.orderTable.userOrderDb[msg.sender].noneExOrderList,exOrderId);

     result=true;
     emit _ExOrderCancelled(adOrderId,exOrderId);
   }
   function queryMultiExOrderStatus(string[] calldata exOrderIds) external view returns(uint[] memory states){
      require(exOrderIds.length>0,'orderIds must be greater than 0');
      require(exOrderIds.length<=100,'orderIds must be less than 101');
      states=new uint[](exOrderIds.length);
      for(uint i=0;i<exOrderIds.length;i++){
        string memory adOrderId=db.orderTable.otcExAdMap[exOrderIds[i]];
        states[i]=uint(db.orderTable.otcTradeOrders[adOrderId][exOrderIds[i]].detail.state);
      }

   }
   function queryExOrderStatus(string calldata adOrderId,string calldata exOrderId) external view returns(uint state){
      state=uint(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state);
   }
   function queryExOrderInfo(string calldata exOrderId) external view returns(ExOrder memory exOrder){
    string memory adOrderId=db.orderTable.otcExAdMap[exOrderId];
    exOrder=db.orderTable.otcTradeOrders[adOrderId][exOrderId];
   }
   function confirmMoneyPayed(string calldata adOrderId,string calldata exOrderId) external returns (bool result) {
    require(!db.config.isPause,'system paused');
    require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
    require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress !=address(0),'Trade Order not exists');
    //check exorder state
    require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state==TradeState.Filled,'Trade order state can only be filled');

    //check user is valid
    if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY){
        require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress == msg.sender,'no access');
    }else{
        require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress == msg.sender,'no access');
    }

    db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state=TradeState.MoneyPayed;
    db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.lastUpdateTime=block.timestamp;
    result=true;
    emit _AdOrderPayed(exOrderId);
   }
   function getTradeParam() external view returns(uint takerFee,uint makerFee,uint backRate,uint price){
    takerFee=db.config.takerFee;
    makerFee=db.config.makerFee;
    backRate=_getBackRate(); //1:0.7
    price=_getPubDOTCPrice();
   }
   function queryNoneExList() external view returns(string[] memory){
    return db.orderTable.userOrderDb[msg.sender].noneExOrderList;
   }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
import '../libraries/stringUtils.sol';

contract DOTCExOrderBase is DOTCFacetBase {
    using SafeMath for uint;
    function _checkExOrder(string memory adOrderId,string memory exOrderId,uint amount) internal view {
      require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
      require(db.orderTable.otcAdOrders[adOrderId].state == OrderState.ONTRADE,'AdOrder has been closed');
      require(db.orderTable.otcAdOrders[adOrderId].makerAddress != msg.sender,'you can not trade with yourself');

      require(StringUtils.indexOf(exOrderId,adOrderId) == 0, 'Invalid exOrderId prefix');

      if(db.userTable.userList[msg.sender].isVIP){
         require(db.orderTable.userOrderDb[msg.sender].noneExOrder<consts.orderLimit.vipOrderNum,'ExOrder VIP Limit');
      }else{
        require(db.orderTable.userOrderDb[msg.sender].noneExOrder<consts.orderLimit.orderNum,'ExOrder Limit');
      }

      if (uint(db.orderTable.otcAdOrders[adOrderId].side) == 0 && db.orderTable.otcAdOrders[adOrderId].tokenA == db.config.dotcContract) {
        (bool isLock,address lendToken) = _checkLendLock(msg.sender);
        require(lendToken != db.config.dotcContract, "Lending DOTC can not be sold");
      }

      require(db.orderTable.otcAdOrders[adOrderId].detail.leftAmount>=amount,'insufficient left amount');
      require(amount <= db.orderTable.otcAdOrders[adOrderId].detail.maxAmount,"amount must be less than maxAmount");
      require(amount >= db.orderTable.otcAdOrders[adOrderId].detail.minAmount,"amount must be greater than minAmount");
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress==address(0),'trade has been exists');

    }
    function _queryAdDeposit(string memory adOrderId,uint amount) internal view returns(uint nOrderValue,uint dotcAmount,uint deposit){
      nOrderValue=db.orderTable.otcAdOrders[adOrderId].depositInfo.orderValue.mul(amount).div(db.orderTable.otcAdOrders[adOrderId].detail.totalAmount);
      dotcAmount=db.orderTable.otcAdOrders[adOrderId].depositInfo.dotcAmount.mul(amount).div(db.orderTable.otcAdOrders[adOrderId].detail.totalAmount);
      deposit=db.orderTable.otcAdOrders[adOrderId].depositInfo.deposit.mul(amount).div(db.orderTable.otcAdOrders[adOrderId].detail.totalAmount);

      //uint nMinDeposit=_getDOTCNumFromUSDT(consts.arbitParam.nOrderArbitCost);
      //deposit=deposit.max(nMinDeposit);
    }
    function _updateExAsset(uint dotcAmount,uint deposit,uint amount,address tokenA,ExchangeSide myside) internal {
      _lockToken(msg.sender,db.config.dotcContract,deposit);
      if(myside==ExchangeSide.BUY){
      }else{
        _lockToken(msg.sender,tokenA,amount);
      }
    }
    function _checkAdOrderLeftDeposit(string memory adOrderId,uint newDeposit) internal view{
      uint nTotalUsed=0;
      for(uint i=0;i<db.orderTable.otcAdOrderCounter[adOrderId].length;i++){
        string memory exOrderId=db.orderTable.otcAdOrderCounter[adOrderId][i];
        nTotalUsed=nTotalUsed.add(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit);
      }
      nTotalUsed=nTotalUsed.add(newDeposit);
      require(nTotalUsed<=db.orderTable.otcAdOrders[adOrderId].depositInfo.deposit,'adOrder left deposit not enough');
    }
    function _lockExOrderFee(string memory adOrderId,string memory exOrderId,uint dotcAmount,uint deposit,address tokenA,ExchangeSide myside,uint nExOrderValue) internal {
      if(db.config.takerFee>0 && myside==ExchangeSide.SELL){

          FeeInfo memory feeInfo=_calculateOrderFee(tokenA,db.config.takerFee,nExOrderValue,dotcAmount,true);
          if(feeInfo.feeValue>0){
            if(feeInfo.feeType==CoinType.USDT){
              //usdt trade--lock fee
              _lockToken(msg.sender,db.config.usdtContract,feeInfo.feeValue);
              db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue=feeInfo.feeValue;
              db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType=CoinType.USDT;
            }else if(feeInfo.feeType==CoinType.DOTC){
              //non-usdt trade
              //lock dotc fee
              _lockToken(msg.sender,db.config.dotcContract,feeInfo.feeValue);
              db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue=feeInfo.feeValue;
              db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType=CoinType.DOTC;
            }
          }

      }
    }
    function _addExOrder(string memory adOrderId,string memory exOrderId,uint amount,ExchangeSide myside,uint nOrderValue,uint dotcAmount,uint deposit) internal{
        {
          db.orderTable.otcTradeOrders[adOrderId][exOrderId]._exOrderId=exOrderId;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId]._adOrderId=adOrderId;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress=db.orderTable.otcAdOrders[adOrderId].makerAddress;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress=msg.sender;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].side=myside;
        }
        {
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenA=db.orderTable.otcAdOrders[adOrderId].tokenA;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenB=db.orderTable.otcAdOrders[adOrderId].tokenB;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount=amount;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeTime=block.timestamp;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state=TradeState.Filled;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.lastUpdateTime=block.timestamp;

          db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.orderValue=nOrderValue;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.dotcAmount=dotcAmount;
          db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit=deposit;
          //add to map
          db.orderTable.otcExAdMap[exOrderId]=adOrderId;
          db.orderTable.otcAdOrderCounter[adOrderId].push(exOrderId);
        }
        db.orderTable.userOrderDb[msg.sender].totalExOrder++;
        db.orderTable.userOrderDb[msg.sender].noneExOrder++;
        db.orderTable.userOrderDb[msg.sender].noneExOrderList.push(exOrderId);
    }
    function _checkCancelExOrder(string memory adOrderId,string memory exOrderId) internal view {
      require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress!=address(0),'ExOrder not exists');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress==msg.sender,'You do not have permission to cancel');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state==TradeState.Filled,'ExOrder can not be cancelled now');
      require(db.arbitTable.orderArbitList[exOrderId].state!=ArbitState.Dealing,'the order has an dealing arbit');
      require(block.timestamp.sub(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeTime)>=consts.orderLimit.cancelWaitTime,'cancel time limit');
    }
    function _unLockCancelAssets(string memory adOrderId,string memory exOrderId) internal{

      {
        uint deposit=db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit;
         _unLockToken(msg.sender,db.config.dotcContract,deposit);
        if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY){

        }else{

          _unLockToken(msg.sender,db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenA,db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount);
          _backSELLExOrderFee(adOrderId,exOrderId);
        }
      }
    }
    function _backSELLExOrderFee(string memory adOrderId,string memory exOrderId) internal {
       if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue<=0) return;
       if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY) return;
       if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType==CoinType.USDT){
         _unLockToken(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress,db.config.usdtContract,db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue);
       }else if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType==CoinType.DOTC){
         _unLockToken(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress,db.config.dotcContract,db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue);
       }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.0;
library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

//import "../facetBase/DOTCFacetBase.sol";
import "../facetBase/DOTCArbitBase.sol";

import '../libraries/DOTCLib.sol';
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
contract DOTCCardAribtFacet is DOTCArbitBase {
    using SafeMath for uint; 
    event _CardArbitCreated(address indexed userAddr,uint indexed usdtAmount,uint indexed applyTime); 
    event _CardArbitCancelled(address indexed userAddr); 
    event _CardArbitResultGived(address indexed aribtAddr,address indexed userAddr,uint indexed result); 
    event _CardArbitResultUpdated(address indexed senderAddr,address indexed userAddr,uint AccuserCount,uint AppelleeCount);
    /************************* Card Arbit ******************/
    function createCardArbit(string calldata arbitId,uint usdtAmount) external returns(bool result){
     {
        require(!db.config.isPause,'system paused');
        require(usdtAmount>0,'amount must be greater than 0');
        require(usdtAmount<=10000* consts.priceParam.nUsdtDecimals,'you can apply up to 10000usdt');
        require(db.userTable.userList[msg.sender].isVIP,'only vip user can apply card arbit');
        require(_getArbiterLength()>=consts.arbitParam.nArbitNum,'arbiter count is less than minimum');
        require(db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply>0,'risk pool is empty');
        uint dotcAmount=_getDOTCNumFromUSDT(usdtAmount);
        require(db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply>=dotcAmount,'insufficient risk pool supply');
        CardArbit memory cardArbit=db.arbitTable.cardArbitTable.carArbitList[msg.sender];
        require(cardArbit.state!=ArbitState.Dealing,'you have an arbit in process');
        require(cardArbit.lastApplyTime==0 || (block.timestamp-cardArbit.lastApplyTime)>=consts.periodParam.cardPeriodTime,'you have an arbit within 180 days');
        require(db.arbitTable.cardArbitTable.cardArbitIds[arbitId]==address(0),'arbitId exsits');
     }
     {
       if(consts.arbitParam.nCardArbitCost>0){
          uint dotcCost=_getDOTCNumFromUSDT(consts.arbitParam.nCardArbitCost);
         _lockToken(msg.sender,db.config.dotcContract,dotcCost);
          db.arbitTable.cardArbitTable.carArbitList[msg.sender].lockedDotcAmount=dotcCost;
       }
       else{
           db.arbitTable.cardArbitTable.carArbitList[msg.sender].lockedDotcAmount=0;
       }
      
     }
     {
        //create card arbit
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].arbitID=arbitId;
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].applyUSDTAmount=usdtAmount;
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].state=ArbitState.Dealing;
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].lastApplyTime=block.timestamp;
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].arbitResult=ArbitResult.None;
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].lastCompleteTime=0;
        db.arbitTable.cardArbitTable.carArbitList[msg.sender].cardArbitTimes++;
        db.arbitTable.cardArbitTable.cardArbitIds[arbitId]=msg.sender;
     }
     {
        //clear history
        if(db.arbitTable.cardArbitTable.cardArbitDetailList[msg.sender].length>0){
           delete db.arbitTable.cardArbitTable.cardArbitDetailList[msg.sender];
        }
        //give arbiters
        if(consts.arbitParam.nArbitNum<MIN_ARBITER_NUM) consts.arbitParam.nArbitNum=MIN_ARBITER_NUM;
        uint[] memory arbiterList=_getRandomArbiter(consts.arbitParam.nArbitNum);
        for(uint i=0;i<arbiterList.length;i++){
           db.arbitTable.cardArbitTable.cardArbitDetailList[msg.sender].push(ArbitInfo(address(uint160(arbiterList[i])),ArbitResult.None,block.timestamp,0));
        }
        db.arbitTable.cardArbitTable.totalCardArbitCount++;
     }
     result=true;
     emit _CardArbitCreated(msg.sender,usdtAmount,db.arbitTable.cardArbitTable.carArbitList[msg.sender].lastApplyTime);
    }
    function queryCardArbitInfo(address userAddr) external view returns(string memory arbitId,uint usdtAmount,uint applyTime,uint state,uint result,uint applyTimes){
      arbitId=db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitID;
      usdtAmount=db.arbitTable.cardArbitTable.carArbitList[userAddr].applyUSDTAmount;
      applyTime=db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime;
      state=uint(db.arbitTable.cardArbitTable.carArbitList[userAddr].state);
      result=uint(db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult);
      applyTimes=db.arbitTable.cardArbitTable.carArbitList[userAddr].cardArbitTimes;
    }
    function queryCardArbitDetail(address userAddr) external view returns(CardArbit memory detail){
      detail=db.arbitTable.cardArbitTable.carArbitList[userAddr];
    }
    function giveCardArbitResult(string calldata arbitId,address userAddr,uint giveResult ) external {
       require(!db.config.isPause,'system paused');
      _checkCardGivedResult(userAddr,giveResult);
     
      uint nArbiterIndex=DOTCLib._findArbiterIndexForExOrder(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr],msg.sender);
      {
         require(nArbiterIndex>0,'you can not arbit this order');
         //check arbitInfo
         nArbiterIndex--;
         require(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr][nArbiterIndex].taskTime != 0,'Arbiting time has not arrived yet');
         require(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr][nArbiterIndex].result == ArbitResult.None,'arbit has been handled');
      }

      db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr][nArbiterIndex].result=(giveResult==1? ArbitResult.Accuser:ArbitResult.Appellee);
      db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr][nArbiterIndex].handleTime=block.timestamp;
      db.arbitTable.arbitUserList[msg.sender].nHandleCount++;

      _updateCardArbitResult(arbitId,userAddr);

       emit _CardArbitResultGived(msg.sender,userAddr,giveResult);
    }
    function getCardArbitPeriod(address userAddr) external view returns(uint blockTime,uint applyTime,uint period,uint timeUsed){
       blockTime=block.timestamp;
       applyTime=db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime;
       period=consts.periodParam.cardPeriodTime;
       timeUsed=blockTime.sub(applyTime);
    }
    function _checkCardGivedResult(address userAddr,uint giveResult) internal view {
     require(giveResult>0 && giveResult<3,'result error');
     require(userAddr!=address(0),'address invalid');
     require(db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime>0,'applytime error');
     uint period=block.timestamp.sub(db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime);
     require(period>=consts.periodParam.cardPeriodTime && period<=consts.periodParam.cardPeriodTime*2,'period not allowed');
     require(db.arbitTable.cardArbitTable.carArbitList[userAddr].state==ArbitState.Dealing,'arbit state error');
    }
    function queryCardArbitResult(address userAddr) external view returns(uint result,uint AccuserCount,uint AppelleeCount){
     if(db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime>0 && db.arbitTable.cardArbitTable.carArbitList[userAddr].state!=ArbitState.None){
         (AccuserCount,AppelleeCount)=_queryResultCount(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr]);
         result=uint(db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult);
     }
    }
    function updateCardArbitResult(address userAddr,string calldata  arbitId) external returns(uint result,uint AccuserCount,uint AppelleeCount){
     if(db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime>0 && db.arbitTable.cardArbitTable.carArbitList[userAddr].state!=ArbitState.None){
         if(db.arbitTable.cardArbitTable.carArbitList[userAddr].state!=ArbitState.Completed){
            (AccuserCount,AppelleeCount)=_updateCardArbitResult(arbitId,userAddr);
         }else{
            (AccuserCount,AppelleeCount)=_queryResultCount(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr]);
         }
         result=uint(db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult);
     }
    }
    function queryCardArbitState(address userAddr) external view returns(uint state,string memory arbitId){
       state=uint(db.arbitTable.cardArbitTable.carArbitList[userAddr].state);
       arbitId=db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitID;
    }
    function queryCardArbitList(address userAddr) external view returns(ArbitInfo[] memory){
       return db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr];
    }
    function queryCardArbitLocked(address userAddr) external view returns(uint lockedAmount){
       lockedAmount=db.arbitTable.cardArbitTable.carArbitList[userAddr].lockedDotcAmount;
    }
    function queryCardArbitSettle(string calldata arbitId) external view returns(CardArbitSettle memory){
      return db.arbitTable.cardArbitTable.cardArbitSettle[arbitId];
    }
    function _updateCardArbitResult(string calldata arbitId,address userAddr) internal returns(uint AccuserCount,uint AppelleeCount) {
      if(db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime<=0) {
         return (0,0);
      }
      (AccuserCount,AppelleeCount)=_queryResultCount(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr]);
      if(AccuserCount>=_getOrderArbitWinNum()){
         db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult=ArbitResult.Accuser;
      }else if(AppelleeCount>=_getOrderArbitWinNum()){
         db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult=ArbitResult.Appellee;
      }
      uint nTotal=AccuserCount.add(AppelleeCount);
      if((block.timestamp.sub(db.arbitTable.cardArbitTable.carArbitList[userAddr].lastApplyTime)>=consts.periodParam.cardPeriodTime*2 || nTotal>=consts.arbitParam.nArbitNum) && db.arbitTable.cardArbitTable.carArbitList[userAddr].state==ArbitState.Dealing){
         
          if(db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult!=ArbitResult.Accuser){
             db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult=ArbitResult.Appellee;
          }
          db.arbitTable.cardArbitTable.carArbitList[userAddr].lastCompleteTime=block.timestamp;
          db.arbitTable.cardArbitTable.carArbitList[userAddr].state=ArbitState.Completed;
         
          if(db.arbitTable.cardArbitTable.totalCardArbitCount>0){
             db.arbitTable.cardArbitTable.totalCardArbitCount--;
          }
         
          _settleCardArbitAssets(arbitId,userAddr,db.arbitTable.cardArbitTable.carArbitList[userAddr].arbitResult,AccuserCount,AppelleeCount);
      }
      emit _CardArbitResultUpdated(msg.sender,userAddr,AccuserCount,AppelleeCount);
    }
    function _settleCardArbitAssets(string calldata arbitId,address userAddr,ArbitResult arbitResult,uint AccuserCount,uint AppelleeCount) internal{
     uint winnerCount=0;
     if(arbitResult == ArbitResult.Accuser){
        winnerCount=AccuserCount;
        uint dotcAmount=_getDOTCNumFromUSDT( db.arbitTable.cardArbitTable.carArbitList[userAddr].applyUSDTAmount);
        if(dotcAmount>=consts.arbitParam.nCardMaxGive){
           dotcAmount=consts.arbitParam.nCardMaxGive;
        }
        require(dotcAmount>0,'dotcAmount zero');
        require(db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply>=dotcAmount,'insufficient risk pool supply');
        db.userTable.userAssets[userAddr][db.config.dotcContract].available=db.userTable.userAssets[userAddr][db.config.dotcContract].available.add(dotcAmount);
        db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].userGetCoin.userAddr=userAddr;
        db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].userGetCoin.token=db.config.dotcContract;
        db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].userGetCoin.isAddOrSub=true;
        db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].userGetCoin.amount=dotcAmount;
        //update riskpool
        db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.sub(dotcAmount);
        db.daoData.riskPool.poolTokens[db.config.dotcContract].totalPayed=db.daoData.riskPool.poolTokens[db.config.dotcContract].totalPayed.add(dotcAmount);
        db.daoData.riskPool.poolTokens[db.config.dotcContract].payTimes++;
     }
     else if(arbitResult == ArbitResult.Appellee){
        winnerCount=AppelleeCount;
     }
     else{
          
     }
     //reward arbiter
      uint nRewardAmount=db.arbitTable.cardArbitTable.carArbitList[userAddr].lockedDotcAmount;
      db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].arbitorReward.token=db.config.dotcContract;
      db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].arbitorReward.amount=nRewardAmount;
      _rewardDOTCToArbiter(db.arbitTable.cardArbitTable.cardArbitDetailList[userAddr],nRewardAmount,winnerCount,arbitResult);
      if(nRewardAmount>0){
         if(arbitResult==ArbitResult.None || winnerCount<=0){
          //无人仲裁，将保证金划转到风控池
           db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(nRewardAmount);
           db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].riskPool.token=db.config.dotcContract;
           db.arbitTable.cardArbitTable.cardArbitSettle[arbitId].riskPool.amount=nRewardAmount;
         }
         //发起仲裁人资产
         db.userTable.userAssets[userAddr][db.config.dotcContract].locked=db.userTable.userAssets[userAddr][db.config.dotcContract].locked.sub(nRewardAmount);
      }
    }
    function cancelCardArbit() external returns(bool result){
       _checkCancelCardArbit();
      
       db.arbitTable.cardArbitTable.carArbitList[msg.sender].state=ArbitState.Cancelled;
       db.arbitTable.cardArbitTable.carArbitList[msg.sender].lastCompleteTime=block.timestamp;
       db.arbitTable.cardArbitTable.carArbitList[msg.sender].lastApplyTime=0;
       if(db.arbitTable.cardArbitTable.carArbitList[msg.sender].lockedDotcAmount>0){
         
           _unLockToken(msg.sender,db.config.dotcContract,db.arbitTable.cardArbitTable.carArbitList[msg.sender].lockedDotcAmount);
           db.arbitTable.cardArbitTable.carArbitList[msg.sender].lockedDotcAmount=0;
       }
     
       delete db.arbitTable.cardArbitTable.cardArbitDetailList[msg.sender];
       if(db.arbitTable.cardArbitTable.totalCardArbitCount>0){
          db.arbitTable.cardArbitTable.totalCardArbitCount--;
       }
       result=true;
       emit _CardArbitCancelled(msg.sender);
    }
    function _checkCancelCardArbit() internal view{
       require(db.arbitTable.cardArbitTable.carArbitList[msg.sender].state==ArbitState.Dealing,'arbit state can only be dealing');
       (uint AccuserCount,uint AppelleeCount)=_queryResultCount(db.arbitTable.cardArbitTable.cardArbitDetailList[msg.sender]);
       require(AccuserCount<=0 && AppelleeCount<=0,'some arbiters have gived result.');
    }
  
}

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';
import '../libraries/LibStrings.sol';

contract DOTCArbitBase is DOTCFacetBase {
   using SafeMath for uint; 
   function _getRandomArbiter(uint num) internal view returns(uint[] memory arbiterList){
      require(num>=MIN_ARBITER_NUM,'arbiter count is less than minimum');
      require(db.arbitTable.arbiterList.length>=num,'arbiter count is less than num');   
      uint[] memory randIndexs=DOTCLib._getRandomList(db.arbitTable.arbiterList,db.arbitTable.arbiterList.length,num);
      require(randIndexs.length==num,'get random list error');  
      arbiterList=new uint[](num);
      for(uint i=0;i<randIndexs.length;i++){
         arbiterList[i]=db.arbitTable.arbiterList[randIndexs[i]];
      }
   }
   function _rewardDOTCToArbiter(ArbitInfo[] memory arbitInfoList,uint totalReward,uint ArbiterNum,ArbitResult arbitResult ) internal{
      if(arbitInfoList.length>0 && totalReward>0){
         uint nSingleReward=0;
         if(ArbiterNum>0){
            nSingleReward=totalReward.div(ArbiterNum);
         }
         for(uint i=0;i<arbitInfoList.length;i++){
            if(arbitInfoList[i].arbiter!=address(0) && arbitInfoList[i].result==arbitResult && nSingleReward>0 && arbitResult!=ArbitResult.None){
               //give token
               db.userTable.userAssets[arbitInfoList[i].arbiter][db.config.dotcContract].available=db.userTable.userAssets[arbitInfoList[i].arbiter][db.config.dotcContract].available.add(nSingleReward);
            }
            if(arbitInfoList[i].arbiter!=address(0) && arbitInfoList[i].result==ArbitResult.None){
               address arbiter=arbitInfoList[i].arbiter;
               //未处理任何仲裁，扣除违约保证金 
               uint punishNum=_getDOTCNumFromUSDT(consts.arbitParam.arbiterPunish);
               if(db.arbitTable.arbitUserList[arbiter].lockedAmount>=punishNum){
                  db.arbitTable.arbitUserList[arbiter].lockedAmount=db.arbitTable.arbitUserList[arbiter].lockedAmount.sub(punishNum);
                  db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(punishNum);
               }
               else if(db.arbitTable.arbitUserList[arbiter].lockedAmount>0) {
                  db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(db.arbitTable.arbitUserList[arbiter].lockedAmount);
                  db.arbitTable.arbitUserList[arbiter].lockedAmount=0;
               }
               if(db.arbitTable.arbitUserList[arbiter].lockedAmount<=0){
                  //取消仲裁员身份
                  _removeArbiterFromDB(arbiter);
               }
            }
         }
      }
   }
   function _queryResultCount(ArbitInfo[] memory arbitInfoList) internal pure returns(uint AccuserCount,uint AppelleeCount ){
      if(arbitInfoList.length>0){
         for(uint i=0;i<arbitInfoList.length;i++){
            if(arbitInfoList[i].result==ArbitResult.Accuser){
               AccuserCount++;
            }else if(arbitInfoList[i].result==ArbitResult.Appellee){
               AppelleeCount++;
            }
         }
      }
   }
   function _getOrderArbitWinNum() internal view returns(uint winNum){
       return consts.arbitParam.nArbitNum/2+1;
   }
   function _calculateArbitPeriod(string memory exOrderId) internal view returns(ArbitPeriod period){
       if(db.arbitTable.orderArbitList[exOrderId].state==ArbitState.Dealing){
         //console.log("lastApplyTime:");
         //console.log(db.arbitTable.orderArbitList[exOrderId].lastApplyTime);

         if(db.arbitTable.orderArbitList[exOrderId].lastApplyTime!=0){
           uint useTimes=block.timestamp.sub(db.arbitTable.orderArbitList[exOrderId].lastApplyTime);
           //console.log('useTimes:');
           //console.log(useTimes);
           uint ARBIT_PERIOD_TIME=consts.periodParam.arbitPeriodTime;
           if(useTimes>=0 && useTimes<ARBIT_PERIOD_TIME){
              period=ArbitPeriod.Proof;
           }else if(useTimes>=ARBIT_PERIOD_TIME && useTimes<2 * ARBIT_PERIOD_TIME){
              period=ArbitPeriod.Arbit;
           }else if(useTimes>=2 * ARBIT_PERIOD_TIME && useTimes<3 * ARBIT_PERIOD_TIME){
              if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes>1){
                period=ArbitPeriod.Over;
              }else{
                period=ArbitPeriod.Appeal;
              }
           }else {
              period=ArbitPeriod.Over;
           }
         }
         
       }else if (db.arbitTable.orderArbitList[exOrderId].state!=ArbitState.None){
         period=ArbitPeriod.Over;
       }
       else{
          period=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.period;
       }
   }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

//import "../facetBase/DOTCFacetBase.sol";
import '../libraries/DOTCLib.sol';
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';

import "../facetBase/DOTCArbitBase.sol";

contract DOTCArbitFacet is DOTCArbitBase {
    using SafeMath for uint;
    event _OrderArbitCreated(string  adOrderId,string  exOrderId,address indexed userAddr,uint  applytime);
    event _OrderArbitCancelled(string  adOrderId,string  exOrderId,address indexed userAddr);


    function createOrderArbit(string calldata adOrderId,string calldata exOrderId,string calldata arbitId) external returns (bool result,uint period) {
      require(!db.config.isPause,'system paused');
      _checkExArbitApply(adOrderId,exOrderId,msg.sender);
      uint ncheckResult=_checkExArbitAccess(exOrderId,msg.sender);
      require(ncheckResult!=0,'you can not apply arbit now.');
      if(ncheckResult==1){
        //settle first cost
        if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes>0){
          if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount>0){

            address payUser=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedUser;
            uint amount=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount;
            db.userTable.userAssets[payUser][db.config.dotcContract].locked=db.userTable.userAssets[payUser][db.config.dotcContract].locked.sub(amount);
            db.arbitTable.extend.arbitGivedToken[db.config.dotcContract]=db.arbitTable.extend.arbitGivedToken[db.config.dotcContract].add(amount);
            db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount=0;
          }
        }
        if(consts.arbitParam.nOrderArbitCost>0){
          uint dotcCost=_getDOTCNumFromUSDT(consts.arbitParam.nOrderArbitCost);
          _lockToken(msg.sender,db.config.dotcContract,dotcCost);
          db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount=dotcCost;
          db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedUser=msg.sender;
        }
      }
      //create arbit
      {
         db.arbitTable.orderArbitList[exOrderId].adOrderId=adOrderId;
         db.arbitTable.orderArbitList[exOrderId].exOrderId=exOrderId;

         if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes==0){
            //first time apply
            db.arbitTable.orderArbitList[exOrderId].applyUser=msg.sender;
            if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress==msg.sender){
             db.arbitTable.orderArbitList[exOrderId].appelle=db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress;
            }else{
              db.arbitTable.orderArbitList[exOrderId].appelle=db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress;
            }

             // first create arbit count
             db.arbitTable.totalOrderArbitCount++;
             db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].applyUser].arbitExOrderCount++;
             db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].appelle].arbitExOrderCount++;
         }

         db.arbitTable.orderArbitList[exOrderId].state=ArbitState.Dealing;
         db.arbitTable.orderArbitList[exOrderId].lastApplyTime=block.timestamp;
         db.arbitTable.orderArbitList[exOrderId].arbitResult=ArbitResult.None;
         db.arbitTable.orderArbitList[exOrderId].currentArbitId = arbitId;
         db.arbitTable.extend.arbitIdList[arbitId]=exOrderId;
         db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lastCompleteTime=0;
         db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.isSettled=false;
         db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes++;
         // db.arbitTable.totalOrderArbitCount++;
         // db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].applyUser].arbitExOrderCount++;
         // db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].appelle].arbitExOrderCount++;
         //update arbit period
         db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.period=_calculateArbitPeriod(exOrderId);
         period=uint(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.period);
      }
      {
         //give arbiters
         if(consts.arbitParam.nArbitNum<MIN_ARBITER_NUM) consts.arbitParam.nArbitNum=MIN_ARBITER_NUM;

         if(db.arbitTable.orderArbitDetailList[exOrderId].length>0){
            delete db.arbitTable.orderArbitDetailList[exOrderId];
         }
         uint[] memory arbiterList=_getRandomArbiter(consts.arbitParam.nArbitNum);
         for(uint i=0;i<arbiterList.length;i++){
            db.arbitTable.orderArbitDetailList[exOrderId].push(ArbitInfo(address(uint160(arbiterList[i])),ArbitResult.None,block.timestamp,0));
         }
      }
      emit _OrderArbitCreated(adOrderId,exOrderId,msg.sender,db.arbitTable.orderArbitList[exOrderId].lastApplyTime);

      result=true;

    }
     //0-no access，1-need pay，2-free
    function checkExArbitAccess(string calldata adOrderId,string calldata exOrderId,address userAddr) external view returns(uint ncheckResult){
      _checkExArbitApply(adOrderId,exOrderId,userAddr);
      ncheckResult=_checkExArbitAccess(exOrderId,userAddr);
    }
    function queryArbitInfo(string calldata exOrderId) external view returns(address userAddr,uint applyTime,uint state,uint result,uint applyTimes,uint period){
       userAddr=db.arbitTable.orderArbitList[exOrderId].applyUser;
       applyTime=db.arbitTable.orderArbitList[exOrderId].lastApplyTime;
       state=uint(db.arbitTable.orderArbitList[exOrderId].state);
       result=uint(db.arbitTable.orderArbitList[exOrderId].arbitResult);
       applyTimes=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes;
       period=uint(_calculateArbitPeriod(exOrderId));
    }
    function queryArbitState(string calldata exOrderId) external view returns(uint state,uint period){
      state=uint(db.arbitTable.orderArbitList[exOrderId].state);
      period=uint(_calculateArbitPeriod(exOrderId));
    }
    function queryArbitStateById(string calldata arbitId) external view returns(uint state,uint period){
      string memory exOrderId=db.arbitTable.extend.arbitIdList[arbitId];
      state=uint(db.arbitTable.orderArbitList[exOrderId].state);
      period=uint(_calculateArbitPeriod(exOrderId));
    }
    function cancelOrderArbit(string calldata adOrderId,string calldata exOrderId) external returns(bool result){
       _checkCancelOrderArbit(exOrderId);
       //cancel
       db.arbitTable.orderArbitList[exOrderId].state=ArbitState.Cancelled;
       db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lastCompleteTime=block.timestamp;
       if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount>0){

          address payUser=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedUser;
           _unLockToken(payUser,db.config.dotcContract,db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount);
           db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount=0;
       }
       //delete
       {
          delete db.arbitTable.orderArbitDetailList[exOrderId];
          if(db.arbitTable.totalOrderArbitCount>0){
            db.arbitTable.totalOrderArbitCount--;
          }
          if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes>0){
            db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes--;
          }
          if(db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].applyUser].arbitExOrderCount>0){
            db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].applyUser].arbitExOrderCount--;
          }
          if(db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].appelle].arbitExOrderCount>0){
            db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].appelle].arbitExOrderCount--;
          }
       }
       result=true;
       emit _OrderArbitCancelled(adOrderId,exOrderId,msg.sender);
    }
    function queryOrderArbitReward(string calldata exOrderId ) external view returns(uint nRewardAmount){
       nRewardAmount=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount;
       string memory adOrderId=db.orderTable.otcExAdMap[exOrderId];
       nRewardAmount=nRewardAmount.add(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.dotcAmount.mul(10).div(100));
    }
    function queryArbitResultCount(string calldata exOrderId) external view returns(uint result,uint AccuserCount,uint AppelleeCount){
       if(db.arbitTable.orderArbitList[exOrderId].applyUser!=address(0)){
         (AccuserCount,AppelleeCount)=_queryResultCount(db.arbitTable.orderArbitDetailList[exOrderId]);
         result=uint(db.arbitTable.orderArbitList[exOrderId].arbitResult);
       }
    }
    function queryOrderArbitList(string calldata exOrderId) external  view returns(ArbitInfo[] memory){
       return db.arbitTable.orderArbitDetailList[exOrderId];
    }
    function getOrderArbitPeriod(string calldata exOrderId) external view returns(uint blockTime,uint applyTime,uint period,uint timeUsed){
      blockTime=block.timestamp;
      applyTime=db.arbitTable.orderArbitList[exOrderId].lastApplyTime;
      timeUsed=block.timestamp-applyTime;
      period= consts.periodParam.arbitPeriodTime;
    }
    function queryArbitLocked(string calldata exOrderId) external view returns(address payUser,uint lockedAmount,uint arbitTimes){
       payUser=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedUser;
       lockedAmount=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount;
       arbitTimes=db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes;
    }
    function queryOrderArbitSettle(string calldata exOrderId) external view returns(OrderArbitSettle memory){
       return db.arbitTable.orderArbitSettle[exOrderId];
    }
    function queryOrderArbitRewardInfo(string calldata exOrderId) external view returns(TokenInfo memory){
       return db.arbitTable.orderArbitSettle[exOrderId].arbitorReward;
    }
    function queryArbitGivedAmount(address tokenAddr) external view returns(uint amount){
         amount=db.arbitTable.extend.arbitGivedToken[tokenAddr];
    }
    function _checkExArbitApply(string calldata adOrderId,string calldata exOrderId,address userAddr) internal view{
      require(_getArbiterLength()>=consts.arbitParam.nArbitNum,'arbiter count is less than minimum');
      require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress !=address(0),'Trade Order not exists');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress==userAddr || db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress==userAddr ,'no access');
      //require(db.arbitTable.orderArbitList[exOrderId].state!=ArbitState.Dealing,'you have an uncompleted arbit now.');
      require(db.orderTable.otcAdOrders[adOrderId].state==OrderState.ONTRADE,'the ad order has been closed.');
      require(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes<2,'The maximum number of applications has been reached');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state==TradeState.Filled || db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state==TradeState.MoneyPayed,'Trade order state can only be Filled or MoneyPayed');
    }
    function _checkCancelOrderArbit(string calldata exOrderId) internal view {
       require(db.arbitTable.orderArbitList[exOrderId].applyUser!=address(0),'arbit not exist');
       require(db.arbitTable.orderArbitList[exOrderId].applyUser==msg.sender,'no access');
       require(db.arbitTable.orderArbitList[exOrderId].state==ArbitState.Dealing,'arbit state can only be dealing');
       require(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes<2,'second arbit order can not be cancelled');
       uint lastApplyTime=db.arbitTable.orderArbitList[exOrderId].lastApplyTime;
       require(lastApplyTime>0,'lastApplyTime error');
       uint timeUsed=block.timestamp-lastApplyTime;
       require(timeUsed < consts.periodParam.arbitPeriodTime,'Arbit Period can only be cancelled in proof time');
       (uint AccuserCount,uint AppelleeCount)=_queryResultCount(db.arbitTable.orderArbitDetailList[exOrderId]);
       require(AccuserCount<=0 && AppelleeCount<=0,'some arbiters have given result.');

    }
     //0-no access，1-need pay，2-free
    function _checkExArbitAccess(string calldata exOrderId,address userAddr) internal view returns(uint){
       if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes==0){
          //first time
          return 1;
       }
       else if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes>1){
          //over two times
          return 0;
       }else{
          //second time
          ArbitPeriod period=_calculateArbitPeriod(exOrderId);
          if(period==ArbitPeriod.Appeal){

            (uint AccuserCount,uint AppelleeCount)=_queryResultCount(db.arbitTable.orderArbitDetailList[exOrderId]);
            uint winNum=_getOrderArbitWinNum();
            if(AccuserCount<winNum && AppelleeCount<winNum){

              return 2;
            }
            if(AccuserCount<winNum && AppelleeCount>=winNum){

              if(db.arbitTable.orderArbitList[exOrderId].applyUser==userAddr){
                return 1;
              }
            }
            else if(AccuserCount>=winNum && AppelleeCount<winNum){

              if(db.arbitTable.orderArbitList[exOrderId].appelle==userAddr){
                return 1;
              }
            }

          }
       }
       return 0;
    }


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import '../libraries/DOTCLib.sol';
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';

import "./DOTCArbitBase.sol";

contract DOTCArbitSettleBase is DOTCArbitBase {
    using SafeMath for uint;


    function _backWinnerDeposit(string memory adOrderId,string memory exOrderId,bool isMakerWin,bool isTwoBack) internal {
      if(isMakerWin || isTwoBack){
        uint amount=db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount;
        db.orderTable.otcAdOrders[adOrderId].detail.leftAmount=db.orderTable.otcAdOrders[adOrderId].detail.leftAmount.add(amount);
        db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount=db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount.sub(amount);
      }

      if(!isMakerWin || isTwoBack){
         address takerAddr=db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress;
         uint depositAmount= db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit;
         _unLockToken(takerAddr,db.config.dotcContract,depositAmount);
         if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY){

         }else{
            _unLockToken(takerAddr,db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenA,db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount);
         }

         if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue>0){
            if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType==CoinType.USDT){
              _unLockToken(takerAddr,db.config.usdtContract,db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue);
            }else if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType==CoinType.DOTC) {
               _unLockToken(takerAddr,db.config.dotcContract,db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue);
            }
            db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue=0;
         }
      }
    }
    function _clearLoserDeposit(string memory adOrderId,string memory exOrderId,address loser,ExchangeSide loserSide,bool isMaker) internal {
       uint tradeAmount=db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tradeAmount;
       if(isMaker){

          db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount=db.orderTable.otcAdOrders[adOrderId].detail.lockedAmount.sub(tradeAmount);

          if(db.orderTable.otcAdOrders[adOrderId].side==ExchangeSide.SELL && db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue>0){
             uint subFee=db.orderTable.otcAdOrders[adOrderId].depositInfo.feeValue.mul(tradeAmount).div(db.orderTable.otcAdOrders[adOrderId].detail.totalAmount);
             address token;
             if(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeType==CoinType.USDT){
               token=db.config.usdtContract;
             }else if(db.orderTable.otcAdOrders[adOrderId].depositInfo.feeType==CoinType.DOTC) {
               token=db.config.dotcContract;
             }
             if(token!=address(0)){
               db.userTable.userAssets[loser][token].locked=db.userTable.userAssets[loser][token].locked.sub(subFee);
               db.arbitTable.orderArbitSettle[exOrderId].loserFee.token=token;
               db.arbitTable.orderArbitSettle[exOrderId].loserFee.amount=subFee;
               db.arbitTable.orderArbitSettle[exOrderId].loserFee.userAddr=loser;
               db.arbitTable.orderArbitSettle[exOrderId].loserFee.isAddOrSub=false;
               //handle fee
               _handleLoserFee(token,subFee);
             }
          }
       }else{

         if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue>0){
            uint feeValue=db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue;
            address token;
            if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType==CoinType.USDT){
               token=db.config.usdtContract;
            }else if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeType==CoinType.DOTC) {
               token=db.config.dotcContract;
            }
            if(token!=address(0)){
                db.userTable.userAssets[loser][token].locked=db.userTable.userAssets[loser][token].locked.sub(feeValue);
                db.arbitTable.orderArbitSettle[exOrderId].loserFee.token=token;
                db.arbitTable.orderArbitSettle[exOrderId].loserFee.amount=feeValue;
                db.arbitTable.orderArbitSettle[exOrderId].loserFee.userAddr=loser;
                db.arbitTable.orderArbitSettle[exOrderId].loserFee.isAddOrSub=false;
                db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.feeValue=0;
                //handle fee
               _handleLoserFee(token,feeValue);
            }
         }
       }

       uint depositAmount=db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit;
       address tokenA= db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.tokenA;

       db.userTable.userAssets[loser][db.config.dotcContract].locked=db.userTable.userAssets[loser][db.config.dotcContract].locked.sub(depositAmount);
       db.arbitTable.orderArbitSettle[exOrderId].loserDeposit.token=db.config.dotcContract;
       db.arbitTable.orderArbitSettle[exOrderId].loserDeposit.amount=depositAmount;
       if(loserSide==ExchangeSide.BUY){

       }else{

         db.arbitTable.orderArbitSettle[exOrderId].loserDeposit.userAddr=loser;
         db.arbitTable.orderArbitSettle[exOrderId].loserDeposit.isAddOrSub=false;

         db.userTable.userAssets[loser][tokenA].locked=db.userTable.userAssets[loser][tokenA].locked.sub(tradeAmount);
         db.arbitTable.orderArbitSettle[exOrderId].loserExCoin.token=tokenA;
         db.arbitTable.orderArbitSettle[exOrderId].loserExCoin.userAddr=loser;
         db.arbitTable.orderArbitSettle[exOrderId].loserExCoin.isAddOrSub=false;
         db.arbitTable.orderArbitSettle[exOrderId].loserExCoin.amount=tradeAmount;


         if(tokenA==db.config.dotcContract){

            db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(tradeAmount);
            db.arbitTable.orderArbitSettle[exOrderId].riskPool.token=db.config.dotcContract;
            db.arbitTable.orderArbitSettle[exOrderId].riskPool.amount=tradeAmount;

         }else if(tokenA==db.config.usdtContract){
            _updatePoolPeriod();
            db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus.add(tradeAmount/2);
            db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus.add(tradeAmount/2);
            db.arbitTable.orderArbitSettle[exOrderId].stakingPoolA.token=db.config.usdtContract;
            db.arbitTable.orderArbitSettle[exOrderId].stakingPoolA.amount=tradeAmount/2;

            db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus.add(tradeAmount/2);
            db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus.add(tradeAmount/2);
            db.arbitTable.orderArbitSettle[exOrderId].stakingPoolB.token=db.config.usdtContract;
            db.arbitTable.orderArbitSettle[exOrderId].stakingPoolB.amount=tradeAmount/2;
         }else{

            db.arbitTable.extend.arbitGivedToken[tokenA]=db.arbitTable.extend.arbitGivedToken[tokenA].add(tradeAmount);
         }
       }

       _clearInvitorSponsor(exOrderId,loser,depositAmount);
    }
    function _clearInvitorSponsor(string memory exOrderId,address userAddr,uint dotcAmount) internal {
      address invitor=db.userTable.userInviteList[msg.sender];
      if(invitor==address(0)) return;
      uint sponsorAmount=db.userTable.userSponsorData[invitor].sponsorBalances[userAddr];
      uint nClearAmount=sponsorAmount.min(dotcAmount.mul(10).div(100));
      nClearAmount=nClearAmount.min(db.userTable.userAssets[invitor][db.config.dotcContract].locked);
      if(nClearAmount<=0) return;

      db.userTable.userSponsorData[invitor].sponsorBalances[userAddr]= db.userTable.userSponsorData[invitor].sponsorBalances[userAddr].sub(nClearAmount);
      db.userTable.userSponsorData[invitor].totalSupply=db.userTable.userSponsorData[invitor].totalSupply.sub(nClearAmount);
//      if(db.userTable.userAssets[invitor][db.config.dotcContract].locked >= nClearAmount){
      {
        db.userTable.userAssets[invitor][db.config.dotcContract].locked=db.userTable.userAssets[invitor][db.config.dotcContract].locked.sub(nClearAmount);
        db.arbitTable.orderArbitSettle[exOrderId].invitorSponsor.token=db.config.dotcContract;
        db.arbitTable.orderArbitSettle[exOrderId].invitorSponsor.userAddr=invitor;
        db.arbitTable.orderArbitSettle[exOrderId].invitorSponsor.isAddOrSub=false;
        db.arbitTable.orderArbitSettle[exOrderId].invitorSponsor.amount=nClearAmount;

        db.arbitTable.extend.arbitGivedToken[db.config.dotcContract]=db.arbitTable.extend.arbitGivedToken[db.config.dotcContract].add(nClearAmount);
      }
    }

    function _rewardArbiter(string memory adOrderId, string memory exOrderId, uint winnerCount) internal {

        uint nRewardAmount = db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount;
        if (winnerCount > 0) {
            nRewardAmount = nRewardAmount.add(db.orderTable.otcTradeOrders[adOrderId][exOrderId].depositInfo.deposit);
        }
        db.arbitTable.orderArbitSettle[exOrderId].arbitorReward.token = db.config.dotcContract;
        db.arbitTable.orderArbitSettle[exOrderId].arbitorReward.amount = nRewardAmount;
        _rewardDOTCToArbiter(db.arbitTable.orderArbitDetailList[exOrderId], nRewardAmount, winnerCount, db.arbitTable.orderArbitList[exOrderId].arbitResult);
        if (nRewardAmount > 0) {
            if (db.arbitTable.orderArbitList[exOrderId].arbitResult == ArbitResult.None || winnerCount <= 0) {

                db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply = db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(nRewardAmount);
                db.arbitTable.orderArbitSettle[exOrderId].riskPool.token = db.config.dotcContract;
                db.arbitTable.orderArbitSettle[exOrderId].riskPool.amount = nRewardAmount;
            }

            address payUser = db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedUser;
            if (db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount > 0 && db.userTable.userAssets[payUser][db.config.dotcContract].locked >= db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount)
            {
                db.userTable.userAssets[payUser][db.config.dotcContract].locked = db.userTable.userAssets[payUser][db.config.dotcContract].locked.sub(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lockedDotcAmount);
            }

        }
    }

    function _handleLoserFee(address token,uint feeValue) internal{
       if(feeValue==0) return;
       if(token==db.config.usdtContract){
          //staking pool
          _updatePoolPeriod();
          uint poolFee=feeValue.div(2);
          db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].v2Info.totalUSDTBonus.add(poolFee);
          db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolA[db.config.dotcContract].totalUSDTBonus.add(poolFee);

          db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].v2Info.totalUSDTBonus.add(poolFee);
          db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus=db.stakingTable.poolB[db.config.dotcContract].totalUSDTBonus.add(poolFee);
       }
       else if(token==db.config.dotcContract){
          //risk pool
         db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply=db.daoData.riskPool.poolTokens[db.config.dotcContract].currentSupply.add(feeValue);
       }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

//import "../facetBase/DOTCFacetBase.sol";
import '../libraries/DOTCLib.sol';
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';

import "../facetBase/DOTCArbitSettleBase.sol";

contract DOTCArbitSettleFacet is DOTCArbitSettleBase {
    using SafeMath for uint;

    event _ArbitResultGived(string  adOrderId,string  exOrderId,address indexed user,uint  result);
    event _OrderArbitResultUpdated(address indexed userAddr,string  exOrderId,uint  AccuserCount,uint  AppelleeCount,uint result);
    function giveOrderArbitResult(string calldata exOrderId,string calldata adOrderId,uint giveResult) external {
       require(!db.config.isPause,'system paused');
      _checkGivedResult(exOrderId,adOrderId,giveResult);

      uint nArbiterIndex=DOTCLib._findArbiterIndexForExOrder(db.arbitTable.orderArbitDetailList[exOrderId],msg.sender);
      {
         require(nArbiterIndex>0,'you can not arbit this order');
         //check arbitInfo
         nArbiterIndex--;
         require(db.arbitTable.orderArbitDetailList[exOrderId][nArbiterIndex].taskTime != 0,'Arbiting time has not arrived yet');
         require(db.arbitTable.orderArbitDetailList[exOrderId][nArbiterIndex].result == ArbitResult.None,'arbit has been handled');
      }

      db.arbitTable.orderArbitDetailList[exOrderId][nArbiterIndex].result=(giveResult==1? ArbitResult.Accuser:ArbitResult.Appellee);
      db.arbitTable.orderArbitDetailList[exOrderId][nArbiterIndex].handleTime=block.timestamp;
      db.arbitTable.arbitUserList[msg.sender].nHandleCount++;
      //update result
      _updateArbitResult(exOrderId);

      emit _ArbitResultGived(adOrderId,exOrderId,msg.sender,giveResult);

    }
    function updateArbitResult(string calldata exOrderId) external returns(uint result,uint AccuserCount,uint AppelleeCount){
       if(db.arbitTable.orderArbitList[exOrderId].applyUser!=address(0)){
         if(db.arbitTable.orderArbitList[exOrderId].state!=ArbitState.Completed){
            (AccuserCount,AppelleeCount)=_updateArbitResult(exOrderId);

         }else{
               (AccuserCount,AppelleeCount)=_queryResultCount(db.arbitTable.orderArbitDetailList[exOrderId]);
         }
         result=uint(db.arbitTable.orderArbitList[exOrderId].arbitResult);
       }
       emit _OrderArbitResultUpdated(msg.sender,exOrderId,AccuserCount,AppelleeCount,result);
    }

    function _checkGivedResult(string memory exOrderId,string memory adOrderId,uint giveResult) internal view {
      require(giveResult>0 && giveResult<3,'result error');
      //check order
      require(db.orderTable.otcAdOrders[adOrderId].makerAddress !=address(0),'AdOrder not exists');
      require(db.orderTable.otcTradeOrders[adOrderId][exOrderId].makerAddress !=address(0),'Trade Order not exists');
      require(db.arbitTable.orderArbitList[exOrderId].state==ArbitState.Dealing,'Arbit is not processing');
      uint lastApplyTime=db.arbitTable.orderArbitList[exOrderId].lastApplyTime;
      require(lastApplyTime>0,'lastApplyTime error');
      uint timeUsed=block.timestamp.sub(lastApplyTime);
      require(timeUsed >= consts.periodParam.arbitPeriodTime && timeUsed <= consts.periodParam.arbitPeriodTime*2,'Arbit Period can only be between 7th days and 14th days');
    }
    function _updateArbitResult(string memory exOrderId) internal returns(uint AccuserCount,uint AppelleeCount) {
      if(db.arbitTable.orderArbitList[exOrderId].lastApplyTime<=0) {
         return (0,0);
      }
      (AccuserCount,AppelleeCount)=_queryResultCount(db.arbitTable.orderArbitDetailList[exOrderId]);
      uint winnerCount=0;
      {
         if(AccuserCount>=_getOrderArbitWinNum()){
            db.arbitTable.orderArbitList[exOrderId].arbitResult=ArbitResult.Accuser;
            winnerCount=AccuserCount;
         }else if(AppelleeCount>=_getOrderArbitWinNum()){
            db.arbitTable.orderArbitList[exOrderId].arbitResult=ArbitResult.Appellee;
            winnerCount=AppelleeCount;
         }
      }
      uint nTotal=AccuserCount.add(AppelleeCount);
      ArbitPeriod period=_calculateArbitPeriod(exOrderId);
      db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.period=period;
      bool isClose=(nTotal>=consts.arbitParam.nArbitNum && db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.orderArbitTimes>1);

      if((period==ArbitPeriod.Over || isClose) && db.arbitTable.orderArbitList[exOrderId].state==ArbitState.Dealing){
          db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.lastCompleteTime=block.timestamp;
          db.arbitTable.orderArbitList[exOrderId].state=ArbitState.Completed;
          db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.period=ArbitPeriod.Over;
          if(db.arbitTable.totalOrderArbitCount>0){
               db.arbitTable.totalOrderArbitCount--;
          }
          string memory adOrderId=db.orderTable.otcExAdMap[exOrderId];

          _settleArbitAssets(adOrderId,exOrderId);

          _rewardArbiter(adOrderId,exOrderId,winnerCount);
          {
            //log state
            db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.isSettled=true;
            db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.settleTime=block.timestamp;

            db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.state=TradeState.ArbitClosed;
            db.orderTable.otcTradeOrders[adOrderId][exOrderId].detail.lastUpdateTime=block.timestamp;
            address takerAddr=db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress;
            if(db.orderTable.userOrderDb[takerAddr].noneExOrder>0){
             db.orderTable.userOrderDb[takerAddr].noneExOrder=db.orderTable.userOrderDb[takerAddr].noneExOrder.sub(1);
            }
            _removeStrFromList(db.orderTable.userOrderDb[takerAddr].noneExOrderList,exOrderId);

            _RemoveExOrderFromList(adOrderId,exOrderId);
          }
          {

             if(db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].applyUser].arbitExOrderCount>0){
               db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].applyUser].arbitExOrderCount--;
             }
             if(db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].appelle].arbitExOrderCount>0){
               db.userTable.userList[db.arbitTable.orderArbitList[exOrderId].appelle].arbitExOrderCount--;
             }
          }
      }

    }

    function _settleArbitAssets(string memory adOrderId,string memory exOrderId) internal{
      if(db.arbitTable.orderArbitList[exOrderId].arbitBackInfo.isSettled) return;
      if(db.arbitTable.orderArbitList[exOrderId].arbitResult == ArbitResult.None){
         _backWinnerDeposit(adOrderId,exOrderId,true,true);
         return;
      }
      address accUser; //winner
      address appelle; //loser
      ExchangeSide accUserSide;
      bool isMaker=false;
      {
         if(db.arbitTable.orderArbitList[exOrderId].arbitResult==ArbitResult.Accuser){

          accUser=db.arbitTable.orderArbitList[exOrderId].applyUser;
          appelle=db.arbitTable.orderArbitList[exOrderId].appelle;
         }else if (db.arbitTable.orderArbitList[exOrderId].arbitResult==ArbitResult.Appellee){

          accUser=db.arbitTable.orderArbitList[exOrderId].appelle;
          appelle=db.arbitTable.orderArbitList[exOrderId].applyUser;
         }
         if(db.orderTable.otcTradeOrders[adOrderId][exOrderId].takerAddress==accUser){
            accUserSide=db.orderTable.otcTradeOrders[adOrderId][exOrderId].side;
            isMaker=false;

         }else{
            accUserSide=(db.orderTable.otcTradeOrders[adOrderId][exOrderId].side==ExchangeSide.BUY?ExchangeSide.SELL:ExchangeSide.BUY);
            isMaker=true;
         }
      }
     //settle
     _backWinnerDeposit(adOrderId,exOrderId,isMaker,false);
     _clearLoserDeposit(adOrderId,exOrderId,appelle,accUserSide==ExchangeSide.BUY?ExchangeSide.SELL:ExchangeSide.BUY,!isMaker);

    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../facetBase/DOTCFacetBase.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IERC20.sol";
import '../utils/SafeMath.sol';

contract DOTCAdOrderFacet is DOTCFacetBase {
    using SafeMath for uint;
    event _AdOrderCreated(string  orderId,address indexed makerAddr);
    event _AdOrderClosed(string  orderId);

    struct AdInput{
      string orderId;
      uint side;
      address tokenA;
      address tokenB;
      uint price;
      uint totalAmount;
      uint minAmount;
      uint maxAmount;
    }
     //Create a otcOrder
    function createAdOrder(AdInput memory  adInput) external returns (bool result) {
      require(!db.config.isPause,'system paused');
      //check data
      _checkAdOrder(adInput);

      (uint nOrderValue,uint dotcAmount,uint deposit)=_queryAdDeposit(adInput);
      require(dotcAmount > 0,'invalid order deposit');
      require(nOrderValue >= consts.priceParam.minAdValue,'AdOrder value too little');
      _checkUpdateOracleTime();
      //update assets
      _updateAdAssets(adInput,nOrderValue,dotcAmount,deposit);
       //lock fee
      _lockAdOrderFee(adInput,nOrderValue,dotcAmount,deposit);
      //create adOrder
      _addAdOrder(adInput,nOrderValue,dotcAmount,deposit);

      result=true;
      emit _AdOrderCreated(adInput.orderId,msg.sender);
    }
    function queryAdOrderDeposit(AdInput memory  adInput) external view returns(uint orderValue,uint dotcAmount,uint deposit){
       (orderValue,dotcAmount,deposit)=_queryAdDeposit(adInput);
    }
    function _checkAdOrder(AdInput memory  adInput) internal view {
      require(bytes(adInput.orderId).length == 16,'adOrderId length invalid');
      require(msg.sender!=address(0),"sender invalid");
      require(db.userTable.userList[msg.sender].isVIP,"only vip user can create adorder.");
      require(db.orderTable.userOrderDb[msg.sender].noneAdOrder<consts.orderLimit.vipAdorder,'AdOrder Limit');
      require(adInput.tokenA!=address(0),"tokenA address invalid");
      require(adInput.tokenB!=address(0),"tokenB address invalid");
      require(adInput.tokenB==db.config.usdtContract,"tokenB can only be USDT");

      if (adInput.side == 1 && adInput.tokenA == db.config.dotcContract) {
        (bool isLock,address lendToken) =  _checkLendLock(msg.sender);
          if (lendToken == db.config.dotcContract) {
              require(!isLock,"Lending DOTC can not be sold");
          }
       // require(lendToken != db.config.dotcContract,"Lending DOTC can not be sold");
      }

      require(adInput.price> 0,'price must be greater than 0');
      require(adInput.totalAmount>0,"amount invalid");
      require(adInput.minAmount>0,"minAmount invalid");
      require(adInput.maxAmount>0,"maxAmount invalid");
      require(adInput.totalAmount>=adInput.maxAmount,"maxAmount greater than totalAmount");
      require(adInput.minAmount<=adInput.maxAmount,"maxAmount less than minAmount");
      require(db.orderTable.otcAdOrders[adInput.orderId].makerAddress ==address(0),'AdOrder exists');

    }
    function _queryAdDeposit(AdInput memory  adInput) internal view returns(uint nOrderValue,uint dotcAmount,uint deposit){
        uint tokenADecimals= 10 ** LibERC20.queryDecimals(adInput.tokenA);
        if(adInput.tokenA==db.config.usdtContract){
          nOrderValue=adInput.totalAmount;
        }else{
          //require(consts.usdtDecimals>0,'consts.usdtDecimals must be greater than 0');
          //require(usdtDecimals>0,'usdtDecimals must be greater than 0');
          require(tokenADecimals>0,'tokenADecimals must be greater than 0');
          nOrderValue=adInput.totalAmount.mul( consts.priceParam.nUsdtDecimals).div(tokenADecimals);
          nOrderValue=nOrderValue.mul(adInput.price).div(10000);
        }
        require(nOrderValue>0,'OrderValue must be greater than 0');

        if(adInput.tokenA==db.config.dotcContract){
          dotcAmount=adInput.totalAmount;
        }else{
          //uint nDotcDecimals=10 ** consts.dotcDecimals;
          dotcAmount= nOrderValue.mul(_getPubDOTCPrice()).div(consts.priceParam.nUsdtDecimals);
        }
        //calculate deposit
       deposit=dotcAmount.mul(consts.periodParam.depositRate).div(100);
       uint nMinDeposit=_getDOTCNumFromUSDT(consts.priceParam.minAdDepositeValue);//(consts.arbitParam.nOrderArbitCost);
       deposit=deposit.max(nMinDeposit);
    }
    function _updateAdAssets(AdInput memory  adInput,uint orderValue,uint dotcAmount,uint deposit) internal {
      _lockToken(msg.sender,db.config.dotcContract,deposit);
      if(adInput.side==0){

      }else{
        //check user available balance
        _lockToken(msg.sender,adInput.tokenA,adInput.totalAmount);
      }
    }
    function _lockAdOrderFee(AdInput memory  adInput,uint orderValue,uint dotcAmount,uint deposit) internal {
      if(db.config.makerFee>0 && adInput.side==1){

          FeeInfo memory feeInfo=_calculateOrderFee(adInput.tokenA,db.config.makerFee,orderValue,dotcAmount,false);
          if(feeInfo.feeValue>0){

             if(feeInfo.feeType==CoinType.USDT){
              //usdt trade--lock fee
              _lockToken(msg.sender,db.config.usdtContract,feeInfo.feeValue);
              db.orderTable.otcAdOrders[adInput.orderId].depositInfo.feeValue=feeInfo.feeValue;
              db.orderTable.otcAdOrders[adInput.orderId].depositInfo.feeType=CoinType.USDT;
            }else if(feeInfo.feeType==CoinType.DOTC){
              //non-usdt trade
              //lock dotc fee
              _lockToken(msg.sender,db.config.dotcContract,feeInfo.feeValue);
              db.orderTable.otcAdOrders[adInput.orderId].depositInfo.feeValue=feeInfo.feeValue;
              db.orderTable.otcAdOrders[adInput.orderId].depositInfo.feeType=CoinType.DOTC;
            }
          }

      }
    }
    function _addAdOrder(AdInput memory  adInput,uint nOrderValue,uint dotcAmount,uint deposit) internal {
      {
        db.orderTable.otcAdOrders[adInput.orderId].orderId=adInput.orderId;
        db.orderTable.otcAdOrders[adInput.orderId].makerAddress=msg.sender;
        db.orderTable.otcAdOrders[adInput.orderId].side=adInput.side==0?ExchangeSide.BUY:ExchangeSide.SELL;
        db.orderTable.otcAdOrders[adInput.orderId].tokenA=adInput.tokenA;
        db.orderTable.otcAdOrders[adInput.orderId].tokenB=adInput.tokenB;

        db.orderTable.otcAdOrders[adInput.orderId].detail.price=adInput.price;
        db.orderTable.otcAdOrders[adInput.orderId].detail.totalAmount=adInput.totalAmount;
        db.orderTable.otcAdOrders[adInput.orderId].detail.leftAmount=adInput.totalAmount;
        db.orderTable.otcAdOrders[adInput.orderId].detail.lockedAmount=0;
        db.orderTable.otcAdOrders[adInput.orderId].detail.minAmount=adInput.minAmount;
        db.orderTable.otcAdOrders[adInput.orderId].detail.maxAmount=adInput.maxAmount;
        db.orderTable.otcAdOrders[adInput.orderId].detail.AdTime=block.timestamp;

        db.orderTable.otcAdOrders[adInput.orderId].state=OrderState.ONTRADE;
        db.orderTable.otcAdOrders[adInput.orderId].depositInfo.orderValue=nOrderValue;
        db.orderTable.otcAdOrders[adInput.orderId].depositInfo.dotcAmount=dotcAmount;
        db.orderTable.otcAdOrders[adInput.orderId].depositInfo.deposit=deposit;
      }
      db.orderTable.orderCount=db.orderTable.orderCount.add(1);
      db.orderTable.userOrderDb[msg.sender].totalAdOrder++;
      db.orderTable.userOrderDb[msg.sender].noneAdOrder++;
      db.orderTable.userOrderDb[msg.sender].noneAdOrderList.push(adInput.orderId);
    }
    function removeAdOrder(string calldata orderId) external returns (bool result)  {
      require(!db.config.isPause,'system paused');
      require(db.orderTable.otcAdOrders[orderId].makerAddress == msg.sender,'no access');
      _checkAdRemovable(orderId);
      if(db.orderTable.otcAdOrders[orderId].detail.leftAmount>0){
        //unlock token balance;
        uint deposit=db.orderTable.otcAdOrders[orderId].depositInfo.deposit.mul(db.orderTable.otcAdOrders[orderId].detail.leftAmount).div(db.orderTable.otcAdOrders[orderId].detail.totalAmount);
        _unLockToken(msg.sender,db.config.dotcContract,deposit);
        if(db.orderTable.otcAdOrders[orderId].side==ExchangeSide.BUY){

        }else{
          //unlock balance
          _unLockToken(msg.sender,db.orderTable.otcAdOrders[orderId].tokenA,db.orderTable.otcAdOrders[orderId].detail.leftAmount);
          //unlock sell fee
          _backSELLAdOrderLeftFee(orderId);
        }
        db.orderTable.otcAdOrders[orderId].detail.leftAmount=0;
      }
      //update
      db.orderTable.otcAdOrders[orderId].state=OrderState.CLOSED;
      if(db.orderTable.orderCount>0){
        db.orderTable.orderCount=db.orderTable.orderCount.sub(1);
      }
      if(db.orderTable.userOrderDb[msg.sender].noneAdOrder>0){
        db.orderTable.userOrderDb[msg.sender].noneAdOrder=db.orderTable.userOrderDb[msg.sender].noneAdOrder.sub(1);
      }
       _removeStrFromList(db.orderTable.userOrderDb[msg.sender].noneAdOrderList,orderId);
      if(db.orderTable.userOrderDb[msg.sender].totalAdOrder>0){
        db.orderTable.userOrderDb[msg.sender].totalAdOrder=db.orderTable.userOrderDb[msg.sender].totalAdOrder.sub(1);
      }
      result=true;
      emit _AdOrderClosed(orderId);
    }
    function checkAdOrderRemovable(string calldata orderId) external view returns (bool result){
       result=_checkAdRemovable(orderId);
    }
    function _checkAdRemovable(string calldata orderId) internal view returns (bool result){
       require(db.orderTable.otcAdOrders[orderId].makerAddress !=address(0),'AdOrder not exists');
       require(db.orderTable.otcAdOrders[orderId].state == OrderState.ONTRADE,'AdOrder has been closed');
       require(_getAdOrderExCount(orderId)== 0,'there is non-closed trade order');
       result=true;
    }
    function queryAdOrderExOrderId(string calldata orderId ) external view returns(string[] memory exOrderIds){
      exOrderIds=db.orderTable.otcAdOrderCounter[orderId];
    }
    function queryAdOrderAvaiAmount(string calldata orderId) external view returns(uint amount){
      if(db.orderTable.otcAdOrders[orderId].state==OrderState.ONTRADE){
        amount=db.orderTable.otcAdOrders[orderId].detail.leftAmount;
      }
    }
    function existAdOrder(string calldata orderId) external view returns (bool result) {
      result=db.orderTable.otcAdOrders[orderId].state==OrderState.ONTRADE;
    }
    function getAdOrderCount() external view returns (uint) {
      return db.orderTable.orderCount;
    }
    function queryMultiAdOrdersStatus(string[] calldata orderIds) external view returns(uint[] memory states){
      require(orderIds.length>0,'orderId count must be greater than 0');
      require(orderIds.length<=100,'orderId count must be less than 101');
      states=new uint[](orderIds.length);
      for(uint i=0;i<orderIds.length;i++){
        states[i]=uint(db.orderTable.otcAdOrders[orderIds[i]].state);
      }

    }
    function queryAdOrderStatus(string calldata  orderId) external view returns(uint state){
      state=uint(db.orderTable.otcAdOrders[orderId].state);
    }
    function queryAdOrderInfo(string calldata  orderId) external view returns(AdOrder memory adOrder){
      adOrder=db.orderTable.otcAdOrders[orderId];
    }
    function queryAdOrderDepositInfo(string calldata  orderId) external view returns(DepositInfo memory deposit){
      deposit=db.orderTable.otcAdOrders[orderId].depositInfo;
    }
    function queryNoneAdList() external view returns(string[] memory){
      return db.orderTable.userOrderDb[msg.sender].noneAdOrderList;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: DAVID
* PROJECT NAME:DOTC
* 12 NOVEMBER 2020
*
/******************************************************************************/

import "./libraries/LibDiamond.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IERC173.sol";
import "./interfaces/IERC165.sol";
import "./libraries/LibERC20.sol";
import "./interfaces/IDOTCFactoryDiamond.sol";

import './defines/dCommon.sol';

import "./libraries/AppStorage.sol";


contract DOTCFactoryDiamond is IDOTCFactoryDiamond{

    LibAppStorage.AppStorage internal db;
    ConstInstance internal consts;
    bool internal isInited;

    constructor() {

    }
    function InitContract(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _owner,
        address _dotcContract,
        address _wethContract,
        address _usdtContract) external{
        if(!isInited){
          _checkParam(_diamondCut,_owner,_dotcContract,_wethContract,_usdtContract);
          _initInterface();
          isInited=true;
        }
    }

    function _checkParam(IDiamondCut.FacetCut[] memory _diamondCut,
        address _owner,
        address _dotcContract,
        address _wethContract,
        address _usdtContract) internal {
        require(_owner != address(0), "DOTCFactoryDiamond: owner can't be address(0)");
        require(_dotcContract != address(0), "DOTCFactoryDiamond: dotcContract can't be address(0)");
        require(_wethContract != address(0), "DOTCFactoryDiamond: wethContract can't be address(0)");
        require(_usdtContract != address(0), "DOTCFactoryDiamond: usdtContract can't be address(0)");

        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibDiamond.setContractOwner(_owner);
        db.config.dotcContract = _dotcContract;
        db.config.wethContract = _wethContract;
        db.config.usdtContract=_usdtContract;
        //record main contract
        db.config.mainContract=address(this);
    }
    function _initInterface() internal {
       // adding interfaces
       {
         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
         ds.supportedInterfaces[type(IERC165).interfaceId] = true;
         ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
         ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
         ds.supportedInterfaces[type(IERC173).interfaceId] = true;
       }

   }
    function getMainContractAddr() external view returns(address addr){
        return db.config.mainContract;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "DOTCFactory: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {
        revert("DOTCFactory: Does not accept ether");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

interface IDOTCFactoryDiamond {

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../libraries/LibDiamond.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](ds.selectorCount);
        uint8[] memory numFacetSelectors = new uint8[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex * 32));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex * 32));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    _facetFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex * 32));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ =LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    // Standard diamondCut external function
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) { 
                // selectorCount,
                // selectorSlot,
                // _diamondCut[facetIndex].facetAddress,
                // _diamondCut[facetIndex].action,
                // _diamondCut[facetIndex].functionSelectors
            FacetInfo memory facetInfo=FacetInfo(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
            (selectorCount, selectorSlot) = LibDiamond.addReplaceRemoveFacetSelectors(facetInfo);
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount % 8 > 0) {
            ds.selectorSlots[selectorCount / 8] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        LibDiamond.initializeDiamondCut(_init, _calldata);
    }
}