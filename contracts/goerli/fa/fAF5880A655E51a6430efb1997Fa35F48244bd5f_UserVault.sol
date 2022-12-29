pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../interfaces/IDSProxy.sol";
import "../openzeppelin/Ownable.sol";
import  "../libraries/SmartPoolManager.sol";
import "../libraries/EnumerableSet.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../libraries/SafeERC20.sol";
import "../base/Logs.sol";

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);

    function isCompletedCollect() external view returns (bool);
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

interface IDesynOwnable {
    function adminList(address adr) external view returns (bool);
    function getController() external view returns (address);
    function getOwners() external view returns (address[] memory);
    function getOwnerPercentage() external view returns (uint[] memory);
    function allOwnerPercentage() external view returns (uint);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract UserVault is Ownable, Logs {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    event ManagersClaim(address indexed caller,address indexed pool, address token, uint amount, uint time);
    event ManagerClaim(address indexed caller,address indexed pool, address indexed manager, address token, uint amount, uint time);
    event KolClaim(address indexed caller,address indexed kol, address token, uint amount, uint time);

    event TypeAmountIn(address indexed pool, uint types, address caller, address token, uint balance);

    ICRPFactory crpFactory;
    address vaultAddress;

    // pool of tokens
    struct PoolTokens {
        address[] tokenList;
        uint[] managerAmount;
        uint[] issueAmount;
        uint[] redeemAmount;
        uint[] perfermanceAmount;
    }

    struct PoolStatus {
        bool couldManagerClaim;
        bool isBlackList;
        bool isSetParams;
        SmartPoolManager.KolPoolParams kolPoolConfig;
    }

    // kol list
    struct KolUserInfo {
        address userAdr;
        uint[] userAmount;
    }

    struct UserKolInfo {
        address kol;
        uint index;
    }

    struct ClaimTokens {
        address[] tokens;
        uint[] amounts;
    }

    // pool => kol => KolUserInfo[]
    mapping(address => mapping(address => KolUserInfo[])) kolUserInfo;

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) poolsStatus;

    //pool => initTotalAmount[]
    mapping(address => uint) public poolInviteTotal;

    //pool => kol[]
    mapping(address => EnumerableSet.AddressSet) kolsList;

    //pool => kol => totalAmount[]
    mapping(address => mapping(address => uint[])) public kolTotalAmountList;

    // pool => user => kol
    mapping(address => mapping(address => UserKolInfo)) public userKolList;
    
    // pool=>kol=>tokens
    mapping(address => mapping(address => ClaimTokens)) kolHasClaimed;

    // pool=>manage=>tokens
    mapping (address => ClaimTokens) manageHasClaimed;

    receive() external payable {}

    uint constant RATIO_BASE = 100;

    // one type call and receiver token
    function depositToken(
        address pool,
        uint types,
        address[] calldata tokensIn,
        uint[] calldata amountsIn
    ) external onlyVault {
        require(tokensIn.length == amountsIn.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        _updatePool(pool, types, tokensIn, amountsIn);
        poolsStatus[pool].couldManagerClaim = true;
    }

    // total tokens in pool
    function getPoolReward(address pool) external view returns (address[] memory tokenList, uint[] memory balances) {
        PoolTokens memory tokens = poolsTokens[pool];
        uint len = tokens.tokenList.length;

        balances = new uint[](len);    
        tokenList = tokens.tokenList;

        for(uint i; i<len ;i++){
            balances[i] = tokens.managerAmount[i]
                            .add(tokens.issueAmount[i])
                            .add(tokens.redeemAmount[i])
                            .add(tokens.perfermanceAmount[i]);
        }
    }

    struct RewardVars {
        address pool;
        uint t0Ratio;
        uint t1Ratio;
        uint t2Ratio;
        uint t3Ratio;
        uint[] managementAmounts;
        uint[] issueAmounts;
        uint[] redemptionAmounts;
        uint[] performanceAmounts;
    }

    // one kol total reward 
    function getKolReward(
        address pool,
        address kol
    ) external view returns (address[] memory tokenList, uint[] memory balances) {
        uint contributionByCurKol = kolTotalAmountList[pool][kol].length > 0 ? kolTotalAmountList[pool][kol][0] : 0;
        uint allContributionByKol = poolInviteTotal[pool];

        SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;

        PoolTokens memory tokens = poolsTokens[pool];
        balances = new uint[](tokens.tokenList.length);
        tokenList = tokens.tokenList;

        RewardVars memory vars = RewardVars(
            pool,
            _levelJudge(contributionByCurKol, params.managerFee),
            _levelJudge(contributionByCurKol, params.issueFee),
            _levelJudge(contributionByCurKol, params.redeemFee),
            _levelJudge(contributionByCurKol, params.perfermanceFee),
            tokens.managerAmount,
            tokens.issueAmount,
            tokens.redeemAmount,
            tokens.perfermanceAmount
        );

        for(uint i; i < tokenList.length; i++){
             balances[i] = vars.managementAmounts[i].mul(vars.t0Ratio).div(RATIO_BASE)
                                .add(vars.issueAmounts[i].mul(vars.t1Ratio).div(RATIO_BASE))
                                .add(vars.redemptionAmounts[i].mul(vars.t2Ratio).div(RATIO_BASE))
                                .add(vars.performanceAmounts[i].mul(vars.t3Ratio).div(RATIO_BASE))
                                .mul(contributionByCurKol)
                                .div(allContributionByKol);
        }
    }

    function kolClaim(address pool) external {
        if (_isClosePool(pool)) {
            require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
            require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
            (address[] memory tokens, uint[] memory amounts) = this.getKolReward(pool, msg.sender);

            ClaimTokens storage kolClaimedInfo = kolHasClaimed[pool][msg.sender];

            // update length
            kolClaimedInfo.tokens = tokens;
            uint amountsLen = kolClaimedInfo.amounts.length;
            uint tokensLen = tokens.length;

            if(amountsLen != tokensLen){
                uint delta = tokensLen - amountsLen;
                for(uint i; i < delta; i++){
                    kolClaimedInfo.amounts.push(0);
                }
            }
            
            address receiver = address(msg.sender).isContract()? IDSProxy(msg.sender).owner(): msg.sender;
            for(uint i; i< tokens.length; i++) {
                uint b = amounts[i] - kolClaimedInfo.amounts[i];
                if(b != 0){
                    IERC20(tokens[i]).safeTransfer(receiver, b);
                    kolClaimedInfo.amounts[i] = kolClaimedInfo.amounts[i].add(b);
                    emit KolClaim(msg.sender,receiver,tokens[i],b,block.timestamp);
                }
            }
        }
    }

    // manager claim
    function managerClaim(address pool) external {
        // try  {} catch {}
        if (_isClosePool(pool)) {
            bool isManager = IDesynOwnable(pool).adminList(msg.sender) || IDesynOwnable(pool).getController() == msg.sender;
            bool isCollectSuccee = ICRPPool(pool).isCompletedCollect();
            require(isCollectSuccee, "ERR_NOT_COMPLETED_COLLECT");
            require(isManager, "ERR_NOT_MANAGER");
            (address[] memory tokens, uint[] memory amounts) = this.getUnManagerReward(pool);
            poolsStatus[pool].couldManagerClaim = false;

            ClaimTokens storage manageHasClimed = manageHasClaimed[pool];

            // update length
            manageHasClimed.tokens = tokens;
            uint amountsLen = manageHasClimed.amounts.length;
            uint tokensLen = tokens.length;

            if(amountsLen != tokensLen){
                uint delta = tokensLen - amountsLen;
                for(uint i; i < delta; i++){
                    manageHasClimed.amounts.push(0);
                }
            }
            // update tokens
            for(uint i; i< tokens.length; i++){
                address t = tokens[i];
                if(amounts[i]!=0){
                    _transferHandle(pool, t, amounts[i]);
                    manageHasClimed.amounts[i] = manageHasClimed.amounts[i].add(amounts[i]);
                }
            }
        }
    }

    function getManagerReward(address pool) external view returns (address[] memory, uint[] memory) {
        (address[] memory totalTokens, uint[] memory totalFee) = this.getPoolReward(pool);
        (, uint[] memory kolFee) = this.getKolsReward(pool);

        uint len = totalTokens.length;
        uint[] memory balances = new uint[](len);

        for(uint i; i<len; i++){
            balances[i] = totalFee[i] - kolFee[i];
        }

        return (totalTokens, balances);
    }
    // for all manager
    function getUnManagerReward(address pool) external returns (address[] memory, uint[] memory) {
        (address[] memory totalTokens, uint[] memory totalAmounts) = this.getManagerReward(pool);
        ClaimTokens storage manageHasClimed = manageHasClaimed[pool];

        // update length
        manageHasClimed.tokens = totalTokens;
        uint amountsLen = manageHasClimed.amounts.length;
        uint tokensLen = totalTokens.length;
        if(amountsLen != tokensLen){
            uint delta = tokensLen - amountsLen;
            for(uint i; i < delta; i++){
                manageHasClimed.amounts.push(0);
            }
        }

        uint len = totalTokens.length;
        uint[] memory balances = new uint[](len);
        for(uint i; i < totalTokens.length; i++){
            balances[i] = totalAmounts[i] - manageHasClimed.amounts[i];
        }        

        return (totalTokens,balances);
    }

    function getPoolFeeTypes(address pool) external view returns(PoolTokens memory result){      
        return poolsTokens[pool];
    }
    
    function getManagerFeeTypes(address pool) external view returns(PoolTokens memory result){     
        result = this.getPoolFeeTypes(pool);
        PoolTokens memory allKolFee = _getKolsFeeTypes(pool); 

        uint len = result.tokenList.length;
        for(uint i; i< len; i++){
            result.managerAmount[i] = result.managerAmount[i].sub(allKolFee.managerAmount[i]);
            result.issueAmount[i] = result.issueAmount[i].sub(allKolFee.issueAmount[i]);
            result.redeemAmount[i] = result.redeemAmount[i].sub(allKolFee.redeemAmount[i]);
            result.perfermanceAmount[i] = result.perfermanceAmount[i].sub(allKolFee.perfermanceAmount[i]);
        }
    }
  
    function _getKolsFeeTypes(address pool) internal view returns(PoolTokens memory result) {
        PoolTokens memory poolInfo = poolsTokens[pool];
        uint len = poolInfo.tokenList.length;
        result.tokenList = poolInfo.tokenList;
        
        EnumerableSet.AddressSet storage list = kolsList[pool];
        uint kolLen = list.length();
        // init result
        result.managerAmount = new uint[](len);
        result.issueAmount = new uint[](len);
        result.redeemAmount = new uint[](len);
        result.perfermanceAmount = new uint[](len);

        for(uint types; types<4; types++){
            for(uint i; i<len; i++){ 
                for (uint j; j < kolLen; j++) {
                    if(types == 0) result.managerAmount[i] = result.managerAmount[i].add(_computeKolTotalReward(pool, list.at(j), 0, i));
                    else if(types == 1) result.issueAmount[i] = result.issueAmount[i].add(_computeKolTotalReward(pool, list.at(j), 1, i));
                    else if(types == 2) result.redeemAmount[i] = result.redeemAmount[i].add(_computeKolTotalReward(pool, list.at(j), 2, i));
                    else if(types == 3) result.perfermanceAmount[i] = result.perfermanceAmount[i].add(_computeKolTotalReward(pool, list.at(j), 3, i));
                }    
            }      
        }
    }

    function getKolFeeType(address pool, address kol) external view returns(PoolTokens memory result) {
        PoolTokens memory poolInfo = poolsTokens[pool];
        result.tokenList = poolInfo.tokenList;
        
        uint len = poolInfo.tokenList.length;
        // init result
        result.managerAmount = new uint[](len);
        result.issueAmount = new uint[](len);
        result.redeemAmount = new uint[](len);
        result.perfermanceAmount = new uint[](len);
        // more for to save gas
        for(uint i; i<len; i++){ 
            result.managerAmount[i] = result.managerAmount[i].add(_computeKolTotalReward(pool, kol, 0, i));
            result.issueAmount[i] = result.issueAmount[i].add(_computeKolTotalReward(pool, kol, 1, i));
            result.redeemAmount[i] = result.redeemAmount[i].add(_computeKolTotalReward(pool, kol, 2, i));
            result.perfermanceAmount[i] = result.perfermanceAmount[i].add(_computeKolTotalReward(pool, kol, 3, i));
        }      
    }

    function getKolsReward(address pool) external view returns (address[] memory, uint[] memory) {
        EnumerableSet.AddressSet storage list = kolsList[pool];
        uint len = list.length();
        address[] memory tokens = poolsTokens[pool].tokenList;
        uint[] memory balances = new uint[](tokens.length);
        for (uint i = 0; i < len; i++) {
            (, uint[] memory singleReward) = this.getKolReward(pool, list.at(i));
            for(uint k; k < singleReward.length; k++){
                balances[k] = balances[k] + singleReward[k];
            }
        }

        return (tokens,balances);
    }

    function getUnKolReward(address pool, address kol) external returns (address[] memory,uint[] memory) {
        (address[] memory totalTokens, uint[] memory totalReward) = this.getKolReward(pool, kol);

        ClaimTokens storage singleKolHasReward = kolHasClaimed[pool][kol];
        // update length
        singleKolHasReward.tokens = totalTokens;
        uint amountsLen = singleKolHasReward.amounts.length;
        uint tokensLen = totalTokens.length;
        if(amountsLen != tokensLen){
            uint delta = tokensLen - amountsLen;
            for(uint i; i < delta; i++){
                singleKolHasReward.amounts.push(0);
            }
        }

        uint len = totalTokens.length;
        uint[] memory balances = new uint[](len);
        for(uint i; i<len; i++){
            balances[i] = totalReward[i] - singleKolHasReward.amounts[i];
        }

        return (totalTokens, balances);
    }

    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external {
        address pool = msg.sender;
        uint len = poolTokens.length;
        require(len == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        UserKolInfo storage userKolBind = userKolList[pool][user];
        
        if (userKolBind.kol == address(0)) {
            userKolBind.kol = kol;
            if (!kolsList[pool].contains(kol)) kolsList[pool].addValue(kol);
        }
        address newKol = userKolBind.kol;
        require(newKol != address(0), "ERR_INVALID_KOL_ADDRESS");
        //total amount record
        poolInviteTotal[pool] = poolInviteTotal[pool].add(tokensAmount[0]);
        uint[] memory totalAmounts = new uint[](len);
        for (uint i; i < len; i++) {
            bool kolHasInvitations = kolTotalAmountList[pool][newKol].length == 0;
            kolHasInvitations
                ? totalAmounts[i] = tokensAmount[i]
                : totalAmounts[i] = tokensAmount[i].add(kolTotalAmountList[pool][newKol][i]);
        }
        kolTotalAmountList[pool][newKol] = totalAmounts;
        //kol user info record
        KolUserInfo[] storage userInfoArray = kolUserInfo[pool][newKol];
        uint index = userKolBind.index;
        if (index == 0) {
            KolUserInfo memory userInfo;
            userInfo.userAdr = user;
            userInfo.userAmount = tokensAmount;
            userInfoArray.push(userInfo);
            userKolBind.index = userInfoArray.length;
        } else {
            KolUserInfo storage userInfo = kolUserInfo[pool][newKol][index - 1];
            for (uint a; a < userInfo.userAmount.length; a++) {
                userInfo.userAmount[a] = userInfo.userAmount[a].add(tokensAmount[a]);
            }
        }
    }

    function setPoolParams(address pool, SmartPoolManager.KolPoolParams memory _poolParams) external onlyCrpFactory {
        PoolStatus storage status = poolsStatus[pool];
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(!status.isSetParams, "ERR_HAS_SETED");

        status.isSetParams = true;
        status.kolPoolConfig = _poolParams;
    }

    // function _getRatioTotal(address pool, uint types) internal view returns(uint){
    //     SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;
    //     if(types == 0) return params.managerFee.firstLevel.ratio.add(params.managerFee.secondLevel.ratio).add(params.managerFee.thirdLevel.ratio).add(params.managerFee.fourLevel.ratio);
    //     else if(types == 1) return params.issueFee.firstLevel.ratio.add(params.issueFee.secondLevel.ratio).add(params.issueFee.thirdLevel.ratio).add(params.issueFee.fourLevel.ratio);
    //     else if(types == 2) return params.redeemFee.firstLevel.ratio.add(params.redeemFee.secondLevel.ratio).add(params.redeemFee.thirdLevel.ratio).add(params.redeemFee.fourLevel.ratio);
    //     else if(types == 3) return params.perfermanceFee.firstLevel.ratio.add(params.perfermanceFee.secondLevel.ratio).add(params.perfermanceFee.thirdLevel.ratio).add(params.perfermanceFee.fourLevel.ratio);
    // }

    function getKolsAdr(address pool) external view returns (address[] memory) {
        return kolsList[pool].values();
    }

    function getPoolConfig(address pool) external view returns (SmartPoolManager.KolPoolParams memory) {
        return poolsStatus[pool].kolPoolConfig;
    }

    function setBlackList(address pool, bool bools) external onlyOwner _logs_ {
        poolsStatus[pool].isBlackList = bools;
    }

    function setCrpFactory(address adr) external onlyOwner _logs_ {
        crpFactory = ICRPFactory(adr);
    }

    function claimToken(
        address token,
        address user,
        uint amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(user, amount);
    }

    function claimEther() external payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setVaultAdr(address adr) external onlyOwner _logs_ {
        vaultAddress = adr;
    }

    function getKolHasClaimed(address pool,address kol) external view returns(ClaimTokens memory) {
        return kolHasClaimed[pool][kol];
    }
        
    function getManageHasClaimed(address pool) external view returns(ClaimTokens memory) {
        return manageHasClaimed[pool];
    }

    function getKolUserInfo(address pool, address kol) external view  returns (KolUserInfo[] memory) {
        return kolUserInfo[pool][kol];
    }

    function getUserKolInfo(address pool, address user) external view  returns (UserKolInfo memory) {
        return userKolList[pool][user];
    }

    function _updatePool(
        address pool,
        uint types,
        address[] memory tokenIn,
        uint[] memory amountIn
    ) internal {
        PoolTokens storage tokens = poolsTokens[pool];

        for(uint i; i < tokenIn.length; i++){
            address t = tokenIn[i];
            uint b = amountIn[i];

            (bool isExit,uint index) = _arrIncludeAddr(tokens.tokenList, t);

            // update token and init value
            if(!isExit){
                tokens.tokenList.push(t);
                tokens.managerAmount.push(0);
                tokens.issueAmount.push(0);
                tokens.redeemAmount.push(0);
                tokens.perfermanceAmount.push(0);
                index = tokens.tokenList.length -1;
            }

            // update valut
            if(b != 0){
                if(types == 0) tokens.managerAmount[index] = tokens.managerAmount[index].add(b);
                else if(types == 1) tokens.issueAmount[index] = tokens.issueAmount[index].add(b);
                else if(types == 2) tokens.redeemAmount[index] = tokens.redeemAmount[index].add(b);
                else if(types == 3) tokens.perfermanceAmount[index] = tokens.perfermanceAmount[index].add(b);
                emit TypeAmountIn(pool, types, msg.sender, t, b);
            }
        }
    }

    function _arrIncludeAddr(address[] memory tokens, address target) internal pure returns(bool isInclude, uint index){
        for(uint i; i<tokens.length; i++){
            if(tokens[i] == target){ 
                isInclude = true;
                index = i;
                break;
            }
        }
    }

    function _transferHandle(
        address pool,
        address t,
        uint balance
    ) internal {
        require(balance != 0, "ERR_ILLEGAL_BALANCE");
        address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
        uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
        uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

        for (uint k = 0; k < managerAddressList.length; k++) {
            address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
            uint b = balance.mul(ownerPercentage[k]).div(allOwnerPercentage);
            IERC20(t).safeTransfer(reciver, b);
            emit ManagerClaim(msg.sender, pool, reciver,t,b,block.timestamp);
        }
        emit ManagersClaim(msg.sender,pool,t,balance,block.timestamp);
    }

    function _levelJudge(uint amount, SmartPoolManager.feeParams memory _feeParams) internal pure returns (uint) {
        if (_feeParams.firstLevel.level <= amount && amount < _feeParams.secondLevel.level) return _feeParams.firstLevel.ratio;
        else if (_feeParams.secondLevel.level <= amount && amount < _feeParams.thirdLevel.level) return _feeParams.secondLevel.ratio;
        else if (_feeParams.thirdLevel.level <= amount && amount < _feeParams.fourLevel.level) return _feeParams.thirdLevel.ratio;
        else if (_feeParams.fourLevel.level <= amount) return _feeParams.fourLevel.ratio;
        return 0;
    }

    function _isClosePool(address pool) internal view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function _computeKolTotalReward(
        address pool,
        address kol,
        uint types,
        uint tokenIndex
    ) internal view returns (uint totalFee) {
        uint kolTotalAmount = kolTotalAmountList[pool][kol].length > 0 ? kolTotalAmountList[pool][kol][0] : 0;
        SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;

        PoolTokens memory tokens = poolsTokens[pool];

        if(kolTotalAmount == 0 || tokens.tokenList.length == 0) return 0;

        uint allKolTotalAmount = poolInviteTotal[pool];
        if (types == 0) totalFee = tokens.managerAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.managerFee)).div(RATIO_BASE);
        else if (types == 1) totalFee = tokens.issueAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.issueFee)).div(RATIO_BASE);
        else if (types == 2) totalFee = tokens.redeemAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.redeemFee)).div(RATIO_BASE);
        else if (types == 3) totalFee = tokens.perfermanceAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.perfermanceFee)).div(RATIO_BASE);
        
        return totalFee.mul(kolTotalAmount).div(allKolTotalAmount);
    }

    modifier onlyCrpFactory() {
        require(address(crpFactory) == msg.sender, "ERR_NOT_CRP_FACTORY");
        _;
    }

    modifier onlyVault() {
        require(vaultAddress == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IDSProxy {
    function owner() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the decimals of tokens
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";

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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        uint value
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
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

contract Logs {
    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }
}

pragma solidity 0.6.12;

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint toDeleteIndex = valueIndex - 1;
            uint lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function addValue(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint index) internal view returns (address) {
        return address(uint160(uint(_at(set._inner, index))));
    }
    
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IERC20.sol";
import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IBFactory.sol"; // unused
import "./DesynSafeMath.sol";
import "./SafeMath.sol";
import "./SafeApprove.sol";

/**
 * @author Desyn Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    using SafeApprove for IERC20;
    using DesynSafeMath for uint;
    using SafeMath for uint;

    //kol pool params
    struct levelParams {
        uint level;
        uint ratio;
    }

    struct feeParams {
        levelParams firstLevel;
        levelParams secondLevel;
        levelParams thirdLevel;
        levelParams fourLevel;
    }
    
    struct KolPoolParams {
        feeParams managerFee;
        feeParams issueFee;
        feeParams redeemFee;
        feeParams perfermanceFee;
    }

    // Type declarations
    enum Etypes {
        OPENED,
        CLOSED
    }

    enum Period {
        HALF,
        ONE,
        TWO
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */
    struct Status {
        uint collectPeriod;
        uint collectEndTime;
        uint closurePeriod;
        uint closureEndTime;
        uint upperCap;
        uint floorCap;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        uint startClaimFeeTime;
    }

    struct PoolParams {
        // Desyn Pool Token (representing shares of the pool)
        string poolTokenSymbol;
        string poolTokenName;
        // Tokens inside the Pool
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        Etypes etype;
    }

    struct PoolTokenRange {
        uint bspFloor;
        uint bspCap;
    }

    struct Fund {
        uint etfAmount;
        uint fundAmount;
    }

    function initRequire(
        uint swapFee,
        uint managerFee,
        uint issueFee,
        uint redeemFee,
        uint perfermanceFee,
        uint tokenBalancesLength,
        uint tokenWeightsLength,
        uint constituentTokensLength,
        bool initBool
    ) external pure {
        // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
        // (and be unrecoverable if they don't have permission set to change it)
        // Most likely to fail, so check first
        require(!initBool, "Init fail");
        require(swapFee >= DesynConstants.MIN_FEE, "ERR_INVALID_SWAP_FEE");
        require(swapFee <= DesynConstants.MAX_FEE, "ERR_INVALID_SWAP_FEE");
        require(managerFee >= DesynConstants.MANAGER_MIN_FEE, "ERR_INVALID_MANAGER_FEE");
        require(managerFee <= DesynConstants.MANAGER_MAX_FEE, "ERR_INVALID_MANAGER_FEE");
        require(issueFee >= DesynConstants.ISSUE_MIN_FEE, "ERR_INVALID_ISSUE_MIN_FEE");
        require(issueFee <= DesynConstants.ISSUE_MAX_FEE, "ERR_INVALID_ISSUE_MAX_FEE");
        require(redeemFee >= DesynConstants.REDEEM_MIN_FEE, "ERR_INVALID_REDEEM_MIN_FEE");
        require(redeemFee <= DesynConstants.REDEEM_MAX_FEE, "ERR_INVALID_REDEEM_MAX_FEE");
        require(perfermanceFee >= DesynConstants.PERFERMANCE_MIN_FEE, "ERR_INVALID_PERFERMANCE_MIN_FEE");
        require(perfermanceFee <= DesynConstants.PERFERMANCE_MAX_FEE, "ERR_INVALID_PERFERMANCE_MAX_FEE");

        // Arrays must be parallel
        require(tokenBalancesLength == constituentTokensLength, "ERR_START_BALANCES_MISMATCH");
        require(tokenWeightsLength == constituentTokensLength, "ERR_START_WEIGHTS_MISMATCH");
        // Cannot have too many or too few - technically redundant, since BPool.bind() would fail later
        // But if we don't check now, we could have a useless contract with no way to create a pool

        require(constituentTokensLength >= DesynConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(constituentTokensLength <= DesynConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        // There are further possible checks (e.g., if they use the same token twice), but
        // we can let bind() catch things like that (i.e., not things that might reasonably work)
    }

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenA - token to sell
     * @param tokenB - token to buy
     */
    function rebalance(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external {
        uint currentWeightA = bPool.getDenormalizedWeight(tokenA);
        uint currentBalanceA = bPool.getBalance(tokenA);
        // uint currentWeightB = bPool.getDenormalizedWeight(tokenB);

        require(deltaWeight <= currentWeightA, "ERR_DELTA_WEIGHT_TOO_BIG");

        // deltaBalance = currentBalance * (deltaWeight / currentWeight)
        uint deltaBalanceA = DesynSafeMath.bmul(currentBalanceA, DesynSafeMath.bdiv(deltaWeight, currentWeightA));

        // uint currentBalanceB = bPool.getBalance(tokenB);

        // uint deltaWeight = DesynSafeMath.bsub(newWeight, currentWeightA);

        // uint newWeightB = DesynSafeMath.bsub(currentWeightB, deltaWeight);
        // require(newWeightB >= 0, "ERR_INCORRECT_WEIGHT_B");
        bool soldout;
        if (deltaWeight == currentWeightA) {
            // reduct token A
            bPool.unbindPure(tokenA);
            soldout = true;
        }

        // Now with the tokens this contract can bind them to the pool it controls
        bPool.rebindSmart(tokenA, tokenB, deltaWeight, deltaBalanceA, soldout, minAmountOut);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
        }
    }

    function createPoolInternalHandle(IBPool bPool, uint initialSupply) external view {
        require(initialSupply >= DesynConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= DesynConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");
        require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        require(DesynConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");
    }

    function createPoolHandle(
        uint collectPeriod,
        uint upperCap,
        uint initialSupply
    ) external pure {
        require(collectPeriod <= DesynConstants.MAX_COLLECT_PERIOD, "ERR_EXCEEDS_FUND_RAISING_PERIOD");
        require(upperCap >= initialSupply, "ERR_CAP_BIGGER_THAN_INITSUPPLY");
    }

    function exitPoolHandle(
        uint _endEtfAmount,
        uint _endFundAmount,
        uint _beginEtfAmount,
        uint _beginFundAmount,
        uint poolAmountIn,
        uint totalEnd
    )
        external
        pure
        returns (
            uint endEtfAmount,
            uint endFundAmount,
            uint profitRate
        )
    {
        endEtfAmount = DesynSafeMath.badd(_endEtfAmount, poolAmountIn);
        endFundAmount = DesynSafeMath.badd(_endFundAmount, totalEnd);
        uint amount1 = DesynSafeMath.bdiv(endFundAmount, endEtfAmount);
        uint amount2 = DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount);
        if (amount1 > amount2) {
            profitRate = DesynSafeMath.bdiv(
                DesynSafeMath.bmul(DesynSafeMath.bsub(DesynSafeMath.bdiv(endFundAmount, endEtfAmount), DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount)), poolAmountIn),
                totalEnd
            );
        }
    }

    function exitPoolHandleA(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint _tokenAmountOut,
        uint redeemFee,
        uint profitRate,
        uint perfermanceFee
    )
        external
        returns (
            uint redeemAndPerformanceFeeReceived,
            uint finalAmountOut,
            uint redeemFeeReceived
        )
    {
        // redeem fee
        redeemFeeReceived = DesynSafeMath.bmul(_tokenAmountOut, redeemFee);

        // performance fee
        uint performanceFeeReceived = DesynSafeMath.bmul(DesynSafeMath.bmul(_tokenAmountOut, profitRate), perfermanceFee);
        
        // redeem fee and performance fee
        redeemAndPerformanceFeeReceived = DesynSafeMath.badd(performanceFeeReceived, redeemFeeReceived);

        // final amount the user got
        finalAmountOut = DesynSafeMath.bsub(_tokenAmountOut, redeemAndPerformanceFeeReceived);

        _pushUnderlying(bPool, poolToken, msg.sender, finalAmountOut);

        if (redeemFee != 0 || (profitRate > 0 && perfermanceFee != 0)) {
            _pushUnderlying(bPool, poolToken, address(this), redeemAndPerformanceFeeReceived);
            IERC20(poolToken).safeApprove(self.vaultAddress(), redeemAndPerformanceFeeReceived);
        }
    }

    function exitPoolHandleB(
        IConfigurableRightsPool self,
        bool bools,
        bool isCompletedCollect,
        uint closureEndTime,
        uint collectEndTime,
        uint _etfAmount,
        uint _fundAmount,
        uint poolAmountIn
    ) external view returns (uint etfAmount, uint fundAmount, uint actualPoolAmountIn) {
        actualPoolAmountIn = poolAmountIn;
        if (bools) {
            bool isCloseEtfCollectEndWithFailure = isCompletedCollect == false && block.timestamp >= collectEndTime;
            bool isCloseEtfClosureEnd = block.timestamp >= closureEndTime;
            require(isCloseEtfCollectEndWithFailure || isCloseEtfClosureEnd, "ERR_CLOSURE_TIME_NOT_ARRIVED!");

            actualPoolAmountIn = self.balanceOf(msg.sender);
        }
        fundAmount = _fundAmount;
        etfAmount = _etfAmount;
    }

    function joinPoolHandle(
        bool canWhitelistLPs,
        bool isList,
        bool bools,
        uint collectEndTime
    ) external view {
        require(!canWhitelistLPs || isList, "ERR_NOT_ON_WHITELIST");

        if (bools) {
            require(block.timestamp <= collectEndTime, "ERR_COLLECT_PERIOD_FINISHED!");
        }
    }

    function rebalanceHandle(
        IBPool bPool,
        bool isCompletedCollect,
        bool bools,
        uint collectEndTime,
        uint closureEndTime,
        bool canChangeWeights,
        address tokenA,
        address tokenB
    ) external {
        require(bPool.isBound(tokenA), "ERR_TOKEN_NOT_BOUND");
        if (bools) {
            require(isCompletedCollect, "ERROR_COLLECTION_FAILED");
            require(block.timestamp > collectEndTime && block.timestamp < closureEndTime, "ERR_NOT_REBALANCE_PERIOD");
        }

        if (!bPool.isBound(tokenB)) {
            bool returnValue = IERC20(tokenB).safeApprove(address(bPool), DesynConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");
        }

        require(canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
        require(tokenA != tokenB, "ERR_TOKENS_SAME");
    }

    /**
     * @notice Join a pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        uint issueFee
    ) external view returns (uint[] memory actualAmountsIn) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = DesynSafeMath.bdiv(poolAmountOut, DesynSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        uint issueFeeRate = issueFee.bmul(1000);
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint base = bal.badd(1).bmul(poolAmountOut * uint(1000));
            uint tokenAmountIn = base.bdiv(poolTotal.bsub(1) * (uint(1000).bsub(issueFeeRate)));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    ) external view returns (uint[] memory actualAmountsOut) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        uint ratio = DesynSafeMath.bdiv(poolAmountIn, DesynSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = DesynSafeMath.bmul(ratio, DesynSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    // Internal functions
    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }

    function handleTransferInTokens(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint actualAmountIn,
        uint _actualIssueFee
    ) external returns (uint issueFeeReceived) {
        issueFeeReceived = DesynSafeMath.bmul(actualAmountIn, _actualIssueFee);
        uint amount = DesynSafeMath.bsub(actualAmountIn, issueFeeReceived);

        _pullUnderlying(bPool, poolToken, msg.sender, amount);

        if (_actualIssueFee != 0) {
            bool xfer = IERC20(poolToken).transferFrom(msg.sender, address(this), issueFeeReceived);
            require(xfer, "ERR_ERC20_FALSE");

            IERC20(poolToken).safeApprove(self.vaultAddress(), issueFeeReceived);
        }
    }

    function handleClaim(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint managerFee,
        uint timeElapsed,
        uint claimPeriod
    ) external returns (uint[] memory) {
        uint[] memory tokensAmount = new uint[](poolTokens.length);
        
        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenBalance = bPool.getBalance(t);
            uint tokenAmountOut = tokenBalance.bmul(managerFee).mul(timeElapsed).div(claimPeriod).div(12);    
            _pushUnderlying(bPool, t, address(this), tokenAmountOut);
            IERC20(t).safeApprove(self.vaultAddress(), tokenAmountOut);
            tokensAmount[i] = tokenAmountOut;
        }
        
        return tokensAmount;
    }

    function handleCollectionCompleted(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint issueFee
    ) external {
        if (issueFee != 0) {
            uint[] memory tokensAmount = new uint[](poolTokens.length);

            for (uint i = 0; i < poolTokens.length; i++) {
                address t = poolTokens[i];
                uint currentAmount = bPool.getBalance(t);
                uint currentAmountFee = DesynSafeMath.bmul(currentAmount, issueFee);

                _pushUnderlying(bPool, t, address(this), currentAmountFee);
                tokensAmount[i] = currentAmountFee;
                IERC20(t).safeApprove(self.vaultAddress(), currentAmountFee);
            }

            IVault(self.vaultAddress()).depositIssueRedeemPToken(poolTokens, tokensAmount, tokensAmount, false);
        }
    }

    function WhitelistHandle(
        bool bool1,
        bool bool2,
        address adr
    ) external pure {
        require(bool1, "ERR_CANNOT_WHITELIST_LPS");
        require(bool2, "ERR_LP_NOT_WHITELISTED");
        require(adr != address(0), "ERR_INVALID_ADDRESS");
    }

    function _pullUnderlying(
        IBPool bPool,
        address erc20,
        address from,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, DesynSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    function _pushUnderlying(
        IBPool bPool,
        address erc20,
        address to,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, DesynSafeMath.bsub(tokenBalance, amount), tokenWeight);
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

// Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
// Removing circularity allows flattener tools to work, which enables Etherscan verification
interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint amount) external;

    function pushPoolShareFromLib(address to, uint amount) external;

    function pullPoolShareFromLib(address from, uint amount) external;

    function burnPoolShareFromLib(uint amount) external;

    function balanceOf(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

    function getController() external view returns (address);

    function vaultAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../libraries/SmartPoolManager.sol";

interface IBPool {
    function rebind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function rebindSmart(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint deltaBalance,
        bool isSoldout,
        uint minAmountOut
    ) external;

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external returns (bytes memory _returnValue);

    function bind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function unbind(address token) external;

    function unbindPure(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint);

    function totalSupply() external view returns (uint);

    function getSwapFee() external view returns (uint);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function EXIT_FEE() external view returns (uint);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function setController(address owner) external;
}

interface IBFactory {
    function newLiquidityPool() external returns (IBPool);

    function setBLabs(address b) external;

    function collect(IBPool pool) external;

    function isBPool(address b) external view returns (bool);

    function getBLabs() external view returns (address);

    function getSwapRouter() external view returns (address);

    function getVault() external view returns (address);

    function getUserVault() external view returns (address);

    function getVaultAddress() external view returns (address);

    function getOracleAddress() external view returns (address);

    function getManagerOwner() external view returns (address);

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool);

    function isTokenWhitelistedForVerify(address token) external view returns (bool);

    function getModuleStatus(address etf, address module) external view returns (bool);

    function isPaused() external view returns (bool);
}

interface IVault {
    function depositManagerToken(address[] calldata poolTokens, uint[] calldata tokensAmount) external;

    function depositIssueRedeemPToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountP,
        bool isPerfermance
    ) external;

    function managerClaim(address pool) external;

    function getManagerClaimBool(address pool) external view returns (bool);
}

interface IUserVault {
    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface Oracles {
    function getPrice(address tokenAddress) external returns (uint price);

    function getAllPrice(address[] calldata poolTokens, uint[] calldata tokensAmount) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "../interfaces/IERC20.sol";

// Libraries

/**
 * @author PieDAO (ported to Desyn Labs)
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice handle approvals of tokens that require approving from a base of 0
     * @param token - the token we're approving
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint amount
    ) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "./DesynConstants.sol";

/**
 * @author Desyn Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library DesynSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint c1 = c0 + (DesynConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / DesynConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0) {
            return 0;
        }

        uint c0 = dividend * DesynConstants.BONE;
        require(c0 / dividend == DesynConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @author Desyn Labs
 * @title Put all the constants in one place
 */

library DesynConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = 0;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    //Fee Set
    uint public constant MANAGER_MIN_FEE = 0;
    uint public constant MANAGER_MAX_FEE = BONE / 10;
    uint public constant ISSUE_MIN_FEE = BONE / 1000;
    uint public constant ISSUE_MAX_FEE = BONE / 10;
    uint public constant REDEEM_MIN_FEE = 0;
    uint public constant REDEEM_MAX_FEE = BONE / 10;
    uint public constant PERFERMANCE_MIN_FEE = 0;
    uint public constant PERFERMANCE_MAX_FEE = BONE / 2;
    // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint public constant MIN_ASSET_LIMIT = 1;
    uint public constant MAX_ASSET_LIMIT = 16;
    uint public constant MAX_UINT = uint(-1);
    uint public constant MAX_COLLECT_PERIOD = 60 days;
}