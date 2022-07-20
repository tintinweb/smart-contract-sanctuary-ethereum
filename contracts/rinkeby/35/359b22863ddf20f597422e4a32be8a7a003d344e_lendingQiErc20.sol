// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
import "../superQiToken/superQiErc20.sol";
import "../lendingSuperToken.sol";
// lendingQiErc20 is a combination of super benqi ERC20 token and lending pool.
//
// This contract will benefit from mining income and loan interest income.
contract lendingQiErc20 is superQiErc20,lendingSuperToken {
    using SafeMath for uint256;
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,
    address payable _swapHelper,address payable _feePool,address leverageFactory)
        superQiErc20(multiSignature,origin0,origin1,_stakeToken,_swapHelper,_feePool) 
        lendingSuperToken(leverageFactory) {
        setTokenInfo("Lending ","L");
    }
    function getTotalAssets() internal virtual override view returns (uint256){
        return getAvailableBalance().add(totalAssetAmount());
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
interface ISwapHelper {
    function WAVAX() external view returns (address);
    function swapExactTokens(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external payable returns (uint256 amountOut);
    function swapExactTokens_oracle(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 slipRate,
        address to
    ) external payable returns (uint256 amountOut);
    function swapToken_exactOut(address token0,address token1,uint256 amountMaxIn,uint256 amountOut,address to) external returns (uint256);
    function swapToken_exactOut_oracle(address token0,address token1,uint256 amountOut,uint256 slipRate,address to) external returns (uint256);
    function getAmountIn(address token0,address token1,uint256 amountOut)external view returns (uint256);
    function getAmountOut(address token0,address token1,uint256 amountIn)external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;
import "../modules/SafeMath.sol";
import "../modules/IERC20.sol";
import "../interfaces/IWAVAX.sol";
import "../swapHelper/ISwapHelper.sol";
import "../modules/safeErc20.sol";
import "../modules/ERC20.sol";
// superTokenInterface is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superTokenInterface.
abstract contract superTokenInterface is ERC20{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    uint256 constant calDecimals = 1e18;
    IERC20 public asset;
    ISwapHelper public swapHelper;
    IWAVAX public WAVAX;
    uint256 public slipRate = 98e16;

    address payable public feePool;
        struct rewardInfo {
        uint8 rewardType;
        bool bClosed;
        address rewardToken;
        uint256 sellLimit;
    }
    uint64[3] public feeRate;
    uint256 internal constant compoundFeeID = 0;
    uint256 internal constant enterFeeID = 1;
    uint256 internal constant flashFeeID = 2;
    /**
     * @dev `sender` has exchanged `assets` for `shares`, and transferred those `shares` to `receiver`.
     */
    event Deposit(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

    /**
     * @dev `sender` has exchanged `shares` for `assets`, and transferred those `assets` to `receiver`.
     */
    event Withdraw(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);
    event LendTo(address indexed sender,address indexed account,uint256 amount);
    event RepayFrom(address indexed sender,address indexed account,uint256 amount);
    event SetReward(address indexed sender, uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit);
    function onDeposit(address account,uint256 _amount,uint64 _fee)internal virtual returns(uint256);
    function onWithdraw(address account,uint256 _amount)internal virtual returns(uint256);
    function getAvailableBalance() internal virtual view returns (uint256);
    function onCompound() internal virtual;
    function getTotalAssets() internal virtual view returns (uint256);
    function getMidText()internal virtual returns(string memory,string memory);
    receive() external payable {
        // React to receiving ether
    }
    function setTokenInfo(string memory _prefixName,string memory _prefixSympol)internal{
        (string memory midName,string memory midSymbol) = getMidText();
        string memory tokenName_ = string(abi.encodePacked(_prefixName,midName,asset.name()));
        string memory symble_ = string(abi.encodePacked(_prefixSympol,midSymbol,asset.symbol()));
        setErc20Info(tokenName_,symble_,asset.decimals());
    }
    function availableBalance() external view returns (uint256){
        return getAvailableBalance();
    }
    function swapOnDex(address token,uint256 sellLimit)internal{
        uint256 balance = (token != address(0)) ? IERC20(token).balanceOf(address(this)) : address(this).balance;
        if (balance < sellLimit){
            return;
        }
        swapTokensOnDex(token,address(asset),balance);
    }
    function swapTokensOnDex(address token0,address token1,uint256 balance)internal{
        if(token0 == token1){
            return;
        }
        if (token0 == address(0)){
            WAVAX.deposit{value: balance}();
            token0 = address(WAVAX);
            if(token1 == address(WAVAX)){
                 return;
            }
        }else if(token0 == address(WAVAX) && token1 == address(0)){
            WAVAX.withdraw(balance);
            return;
        }
        approveRewardToken(token0);
        swapHelper.swapExactTokens_oracle(token0,token1,balance,slipRate,address(this));
    }
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
    modifier notZeroAddress(address inputAddress) {
        require(inputAddress != address(0), "superToken : Zero Address");
        _;
    }
    function approveRewardToken(address token)internal {
        if(token != address(0) && IERC20(token).allowance(address(this), address(swapHelper)) == 0){
            SafeERC20.safeApprove(IERC20(token), address(swapHelper), uint(-1));
        }
    }
    function _setReward(rewardInfo[] storage rewardInfos,uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit) internal virtual{
        if(index <rewardInfos.length){
            rewardInfo storage info = rewardInfos[index];
            info.rewardType = _reward;
            info.bClosed = _bClosed;
            info.rewardToken = _rewardToken;
            info.sellLimit = _sellLimit;
        }else{
            rewardInfos.push(rewardInfo(_reward,_bClosed,_rewardToken,_sellLimit));
        }
        emit SetReward(msg.sender,index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;
import "../../interfaces/ICToken.sol";
import "../../interfaces/IBenqiCompound.sol";
import "../../modules/safeErc20.sol";
import "../superTokenInterface.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
abstract contract superQiTokenImpl is superTokenInterface{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IBenqiCompound public compounder;
    rewardInfo[] public benqiRewardInfos;
    IERC20 public qiToken;
    constructor(address _lendingToken){
        qiToken = IERC20(_lendingToken);
        compounder = IBenqiCompound(ICErc20(address(qiToken)).comptroller());
        setBenqiRewardToken(0,0,false,0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5,1e17);//qi
        setBenqiRewardToken(1,1,false,address(0),1e15);//avax
    }
    function getAvailableBalance() internal virtual override view returns (uint256){
        return _getTotalAssets();
    }
    function getTotalAssets() internal virtual override view returns (uint256){
        return _getTotalAssets();
    }
    function _getTotalAssets() internal view returns (uint256){
        uint256 exchangeRate = ICErc20(address(qiToken)).exchangeRateStored();
        return exchangeRate.mul(qiToken.balanceOf(address(this)))/calDecimals;
    }
    function setBenqiRewardToken(uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit)internal { 
        require(_rewardToken != address(qiToken), "reward token error!");
        _setReward(benqiRewardInfos,index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
    function claimRewards() internal {
        uint nLen = benqiRewardInfos.length;
        for (uint i=0;i<nLen;i++){
            rewardInfo memory info = benqiRewardInfos[i];
            if(info.bClosed){
                return;
            }
            address[] memory qiTokens = new address[](1); 
            qiTokens[0] = address(qiToken);
            compounder.claimReward(info.rewardType,address(this),qiTokens);
            swapOnDex(info.rewardToken,info.sellLimit);
        }
    }
    function getMidText()internal virtual override returns(string memory,string memory){
        return ("Benqi ","qi");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superQiTokenImpl.sol";

//
// This contract handles swapping to and from superQiErc20
abstract contract superQiErc20Impl is superQiTokenImpl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // Define the qiToken token contract
    constructor(address _lendingToken) superQiTokenImpl(_lendingToken){
        asset = IERC20(ICErc20(address(qiToken)).underlying());
        SafeERC20.safeApprove(asset, address(qiToken), uint(-1));
    }
    function onDeposit(address account,uint256 _amount,uint64 _fee)internal virtual override returns(uint256){
        asset.safeTransferFrom(account, address(this), _amount);
        return qiSupply(_fee);
    }
    function onWithdraw(address account,uint256 _amount)internal virtual override returns(uint256){
        uint256 success = ICErc20(address(qiToken)).redeemUnderlying(_amount);
        require(success == 0, "benqi redeem error");
        asset.safeTransfer(account, _amount);
        return _amount;
    }
    function qiWithdraw()internal{
        uint256 success = ICErc20(address(qiToken)).redeem(qiToken.balanceOf(address(this)));
        require(success == 0, "benqi redeem error");
    }
    function qiSupply(uint256 _fee) internal returns (uint256){
        uint256 balance = asset.balanceOf(address(this));
        if (balance>0){
            uint256 fee = balance.mul(_fee)/calDecimals;
            if (fee > 0){
                asset.safeTransfer(feePool,fee);
            }
            balance = balance.sub(fee);
            ICErc20(address(qiToken)).mint(balance);
            return balance;
        }
        return 0;
    }
    function onCompound() internal virtual override{
        claimRewards();
        qiSupply(feeRate[compoundFeeID]);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
import "../superQiTokenImpl/superQiErc20Impl.sol";
import "../baseSuperToken.sol";
// lendingAaveErc20 is a combination of super aave ERC20 token and lending pool.
//
// This contract will benefit from mining income and loan interest income.
contract superQiErc20 is baseSuperToken,superQiErc20Impl {
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,
    address payable _swapHelper,address payable _feePool)
        baseSuperToken(multiSignature,origin0,origin1,_swapHelper,_feePool) superQiErc20Impl(_stakeToken) {
        setTokenInfo("Super ","S");
    }
    function setReward(uint256 index,uint8 _reward,bool _bClosed,address _rewardToken,uint256 _sellLimit)  external onlyOrigin {
        setBenqiRewardToken(index,_reward,_bClosed,_rewardToken,_sellLimit);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./baseSuperToken.sol";
import "../modules/IERC20.sol";
import "../modules/SafeMath.sol";
import "../modules/safeErc20.sol";
import "../interestEngine/interestLinearEngineHash.sol";
import "./superTokenInterface.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
abstract contract lendingSuperToken is superTokenInterface,interestLinearEngineHash{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 public interestFee = 5e14;
    address public immutable ownerLeverageFactory;
        // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    event Borrow(address indexed sender,bytes32 indexed account,address indexed token,uint256 reply);
    event Repay(address indexed sender,bytes32 indexed account,address indexed token,uint256 amount);
    event SetInterestFee(address indexed sender,uint256 interestFee);
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    constructor(address leverageFactory){
//        authorizedAccounts[leverageFactory] = 1;
        ownerLeverageFactory = leverageFactory;
        assetCeiling = uint(-1);
        _setInterestInfo(3e19,1,1e30,1e27);
    } 
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isFactory notZeroAddress(account) {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isFactory notZeroAddress(account) {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "leverageSuperToken : account is not authorized");
        _;
    }
    modifier isFactory {
        require(msg.sender == ownerLeverageFactory,"sender is not owner factory");
        _;
    }
    function setInterestFee(uint256 _interestFee) external isFactory {
        require(_interestFee<=5e17,"input interest rate is too large");
        interestFee = _interestFee;
        emit SetInterestFee(msg.sender,_interestFee);
    }
    function setInterestRate(int256 _interestRate,uint256 rateInterval)external isFactory{
        _setInterestInfo(_interestRate,rateInterval,1e30,1e27);
    }
    function totalLoan()external view returns(uint256){
        return totalAssetAmount();
    }
    function loan(bytes32 account) external view returns(uint256){
        return getAssetBalance(account);
    }
    function borrowLimit()external view returns (uint256){
        return getAvailableBalance();
    }
    function borrow(bytes32 account,uint256 amount) external isAuthorized returns(uint256) {
        addAsset(account,amount);
        onWithdraw(msg.sender,amount);
        emit Borrow(msg.sender,account, address(asset),amount);
        return amount;
    }
    function repay(bytes32 account,uint256 amount) external payable isAuthorized {
        if (amount == uint(-1)){
            amount = getAssetBalance(account);
        }
        uint256 _repayDebt = subAsset(account,amount);
        if(amount>_repayDebt){
            uint256 fee = amount.sub(_repayDebt).mul(interestFee)/calDecimals;
            if (fee>0){
                asset.safeTransferFrom(msg.sender, feePool, fee);
            }
            amount = amount.sub(fee);
        }
        onDeposit(msg.sender,amount,0);
        emit Repay(msg.sender,account,address(asset),amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superTokenInterface.sol";
import "../modules/IERC20.sol";
import "../modules/safeErc20.sol";
import "../modules/proxyOwner.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/timeLockSetting.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
abstract contract baseSuperToken is timeLockSetting,superTokenInterface,proxyOwner,ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public latestCompoundTime;

    event Compound(address indexed sender);
    event FlashLoan(address indexed sender,address indexed receiver,address indexed token,uint256 amount);
    event SetFeePoolAddress(address indexed sender,address _feePool);
    event SetSlipRate(address indexed sender,uint256 _slipRate);
    event SetFeeRate(address indexed sender,uint256 index,uint256 _feeRate);
    // Define the baseSuperToken token contract
    constructor(address multiSignature,address origin0,address origin1,
        address payable _swapHelper,address payable _feePool)
        proxyOwner(multiSignature,origin0,origin1) {
        feePool = _feePool;
        swapHelper = ISwapHelper(_swapHelper);
        WAVAX = IWAVAX(swapHelper.WAVAX());
        feeRate[compoundFeeID] = 2e17;
        feeRate[enterFeeID] = 0;
        feeRate[flashFeeID] = 1e14;
    }
    function getRate()external view returns(uint256){
        // Gets the amount of superToken in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of stakeToken the superToken is worth
        if (totalShares>0){
            return getTotalAssets().mul(calDecimals)/totalShares;
        }
        return calDecimals;
    }
    // Enter the bar. Pay some stakeTokens. Earn some shares.
    // Locks stakeToken and mints superToken
    function deposit(uint256 _amount, address receiver) external returns (uint256){
        uint256 amount = _deposit(msg.sender,_amount,receiver);
        emit Deposit(msg.sender,receiver,_amount,amount);
        return amount;
    }
    // Burns _share from owner and sends exactly _value of asset tokens to receiver.
    function withdraw(uint256 _value,address receiver,address owner) external returns (uint256) {
        uint256 _share = convertToShares(_value);
        _withdraw(_value,_share,receiver,owner);
        emit Withdraw(msg.sender,receiver,_value,_share);
        return _share;
    }

    // Burns exactly shares from owner and sends assets of asset tokens to receiver.
    function redeem(uint256 shares,address receiver,address owner) external returns (uint256) {
        uint256 _value = convertToAssets(shares);
        _withdraw(_value,shares,receiver,owner);
        emit Withdraw(msg.sender,receiver,_value,shares);
        return _value;
    }
    //The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.
    function convertToShares(uint256 _assetNum) public view returns(uint256){
        return _assetNum.mul(totalSupply())/getTotalAssets();
    }
    //The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
    function convertToAssets(uint256 _shareNum) public view returns(uint256){
        return _shareNum.mul(getTotalAssets())/totalSupply();
    }
    function _withdraw(uint256 _assetNum,uint256 _shareNum,address receiver,address owner) internal {
        require(msg.sender == owner,"owner must be msg.sender!");
        require(_shareNum>0,"super token burn 0!");
        _burn(msg.sender, _shareNum);
        _assetNum = onWithdraw(receiver, _assetNum);
    }
    function _deposit(address from,uint256 _amount, address receiver) internal returns (uint256){
        // Gets the amount of stakeToken locked in the contract
        uint256 totaStake = getTotalAssets();
        // Gets the amount of superToken in existence
        uint256 totalShares = totalSupply();
        _amount = onDeposit(from,_amount,feeRate[enterFeeID]);
        // If no superToken exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totaStake == 0) {
            _mint(receiver, _amount);
            return _amount;
        }
        // Calculate and mint the amount of superToken the stakeToken is worth. The ratio will change overtime, as superToken is burned/minted and stakeToken deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares)/totaStake;
            require(what>0,"super token mint 0!");
            _mint(receiver, what);
            return what;
        }
    }
    function depositETH(address receiver)external payable AVAXUnderlying nonReentrant returns(uint256){
        WAVAX.deposit{value: msg.value}();
        uint256 amount = _deposit(address(this),msg.value,receiver);
        emit Deposit(msg.sender,receiver,msg.value,amount);
        return amount;
    }
    function withdrawETH(uint256 _value,address receiver,address owner) external AVAXUnderlying nonReentrant returns (uint256) {
        uint256 _share = convertToShares(_value);
        _withdraw(_value,_share,address(this),owner);
        WAVAX.withdraw(_value);
        _safeTransferETH(receiver, _value);
        emit Withdraw(msg.sender,receiver,_value,_share);
        return _share;
    }
    function redeemETH(uint256 shares,address receiver,address owner) external AVAXUnderlying nonReentrant returns (uint256) {
        uint256 _value = convertToAssets(shares);
        _withdraw(_value,shares,address(this),owner);
        WAVAX.withdraw(_value);
        _safeTransferETH(receiver, _value);
        emit Withdraw(msg.sender,receiver,_value,shares);
        return _value;
    }
    function totalAssets()external view returns(uint256){
        return getTotalAssets();
    }
    function compound() external {
        latestCompoundTime = block.timestamp;
        onCompound();
        emit Compound(msg.sender);
    }
    function setFeePoolAddress(address payable feeAddress)external onlyOrigin notZeroAddress(feeAddress){
        feePool = feeAddress;
        emit SetFeePoolAddress(msg.sender,feeAddress);
    }
    function setSlipRate(uint256 _slipRate) external onlyOrigin{
        require(_slipRate < 1e18,"slipRate out of range!");
        slipRate = _slipRate;
        emit SetSlipRate(msg.sender,_slipRate);
    }
    function setFeeRate(uint256 index,uint64 _feeRate) external onlyOrigin{
        require(_feeRate < 5e17,"feeRate out of range!");
        feeRate[index] = _feeRate;
        emit SetFeeRate(msg.sender,index,_feeRate);
    }
    
    function setSwapHelper(address _swapHelper) external onlyOrigin notZeroAddress(_swapHelper) {
        require(_swapHelper != address(swapHelper),"SwapHelper set error!");
        _set(1,uint256(_swapHelper));
    }
    function acceptSwapHelper() external onlyOrigin {
        swapHelper = ISwapHelper(address(_accept(1)));
    }

    function maxFlashLoan(address token) external view returns (uint256){
        require(token == address(asset),"flash borrow token Error!");
        return getAvailableBalance();
    }
    function flashFee(address token, uint256 amount) public view virtual returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        require(token == address(asset),"flash borrow token Error!");
        return amount.mul(feeRate[flashFeeID])/calDecimals;
    }
    modifier AVAXUnderlying() {
        require(address(asset) == address(WAVAX), "Not WAVAX super token");
        _;
    }
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (bool) {
        require(token == address(asset),"flash borrow token Error!");
        uint256 fee = flashFee(token, amount);
        onWithdraw(address(receiver),amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "invalid return value"
        );
        onDeposit(address(receiver),amount + fee,0);
        emit FlashLoan(msg.sender,address(receiver),token,amount);
        return true;
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
abstract contract timeLockSetting{
    struct settingInfo {
        uint256 info;
        uint256 acceptTime;
    }
    mapping(uint256=>settingInfo) public settingMap;
    uint256 public constant timeSpan = 2 days;

    event SetValue(address indexed from,uint256 indexed key, uint256 value,uint256 acceptTime);
    event AcceptValue(address indexed from,uint256 indexed key, uint256 value);
    function _set(uint256 key, uint256 _value)internal{
        settingMap[key] = settingInfo(_value,block.timestamp+timeSpan);
        emit SetValue(msg.sender,key,_value,block.timestamp+timeSpan);
    }
    function _remove(uint256 key)internal{
        settingMap[key] = settingInfo(0,0);
        emit SetValue(msg.sender,key,0,0);
    }
    function _accept(uint256 key)internal returns(uint256){
        require(settingMap[key].acceptTime>0 && settingMap[key].acceptTime < block.timestamp , "timeLock error!");
        emit AcceptValue(msg.sender,key,settingMap[key].info);
        return settingMap[key].info;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

import "./IERC20.sol";
import "../modules/SafeMath.sol";
import "../modules/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (address(this) == to){
            return;
        }
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        if (from == to){
            return;
        }
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

/**
 * @title  proxyOwner Contract

 */
import "./multiSignatureClient.sol";
contract proxyOwner is multiSignatureClient{
    bytes32 private constant proxyOwnerPosition  = keccak256("org.defrost.Owner.storage");
    bytes32 private constant proxyOriginPosition0  = keccak256("org.defrost.Origin.storage.0");
    bytes32 private constant proxyOriginPosition1  = keccak256("org.defrost.Origin.storage.1");
    uint256 private constant oncePosition  = uint256(keccak256("org.defrost.Once.storage"));
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature,address origin0,address origin1) multiSignatureClient(multiSignature) {
        require(multiSignature != address(0) &&
        origin0 != address(0)&&
        origin1 != address(0),"proxyOwner : input zero address");
        _setProxyOwner(msg.sender);
        _setProxyOrigin(address(0),origin0);
        _setProxyOrigin(address(0),origin1);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) external onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _oldOrigin,address _newOrigin) external onlyOrigin
    {
        _setProxyOrigin(_oldOrigin,_newOrigin);
    }
    function _setProxyOrigin(address _oldOrigin,address _newOrigin) internal 
    {
        emit OriginTransferred(_oldOrigin,_newOrigin);
        (address _origin0,address _origin1) = txOrigin();
        if (_origin0 == _oldOrigin){
            bytes32 position = proxyOriginPosition0;
            assembly {
                sstore(position, _newOrigin)
            }
        }else if(_origin1 == _oldOrigin){
            bytes32 position = proxyOriginPosition1;
            assembly {
                sstore(position, _newOrigin)
            }            
        }else{
            require(false,"OriginTransferred : old origin is illegal address!");
        }
    }
    function txOrigin() public view returns (address _origin0,address _origin1) {
        bytes32 position0 = proxyOriginPosition0;
        bytes32 position1 = proxyOriginPosition1;
        assembly {
            _origin0 := sload(position0)
            _origin1 := sload(position1)
        }
    }
    modifier originOnce() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOrigin() public view returns (bool){
        (address _origin0,address _origin1) = txOrigin();
        return  msg.sender == _origin0 || msg.sender == _origin1;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(isOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * defrost
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;

interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
//Multisignature  wallet client.
//The contract that inherits this contract needs to cooperate with the multiSignature contract for multi-signature
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.defrost.multiSignature.storage"));
    /**
     * @param multiSignature multiSignature contract address
    */
    constructor(address multiSignature) {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity >=0.7.0 <0.8.0;
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    uint256 constant internal calDecimal = 1e18; 
    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }
    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
abstract contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * defrost
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

      /**
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed sender, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity >=0.7.0 <0.8.0;


contract ERC20{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed sender, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
    }
    function setErc20Info(string memory name_, string memory symbol_,uint8 decimals_) internal{
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
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
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
import "../modules/IERC20.sol";
interface IWAVAX is IERC20 {
    /**
     * @dev returns the address of the aToken's underlying asset
     */
    // solhint-disable-next-line func-name-mixedcase
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ICErc20{
    function exchangeRateStored() external view returns (uint);
    function underlying() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function comptroller() external view returns (address);
    function redeem(uint redeemAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}
interface ICEther{
    function exchangeRateStored() external view returns (uint);
    function mint() external payable;
    function comptroller() external view returns (address);
    function redeem(uint redeemAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface IBenqiCompound {
    function claimReward(uint8 rewardType, address payable holder, address[] memory qiTokens) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./baseInterestEngineHash.sol";
import "../modules/SignedSafeMath.sol";
/**
 * @title linear interest engine.
 * @dev calculate interest on assets,linear interest rate.
 *
 */
contract interestLinearEngineHash is baseInterestEngineHash{
    using SignedSafeMath for int256;
    using SafeMath for uint256;
    function calAccumulatedRate(uint256 baseRate,uint256 timeSpan,
        int256 _interestRate,uint256 _interestInterval)internal override pure returns (uint256){
        int256 newRate = _interestRate.mul(int256(timeSpan/_interestInterval));
        if (newRate>=0){
            return baseRate.add(uint256(newRate));
        }else{
            return baseRate.sub(uint256(-newRate));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../modules/SafeMath.sol";
/**
 * @title interest engine.
 * @dev Calculate interest on asset.
 *
 */
abstract contract baseInterestEngineHash{
    using SafeMath for uint256;

    //Special decimals for calculation
    uint256 constant internal rayDecimals = 1e27;
    uint256 constant internal InterestDecimals = 1e36;
    uint256 internal totalAsset;
    // Maximum amount of debt that can be generated with this collateral type
    uint256 public assetCeiling;       // [rad]
    // Minimum amount of debt that must be generated by a SAFE using this collateral
    uint256 public assetFloor;         // [rad]
    //interest rate
    int256 internal interestRate;
    uint256 internal interestInterval = 3600;
    struct assetInfo{
        uint256 originAsset;
        uint256 baseAsset;
    }
    // asset balance
    mapping(bytes32=>assetInfo) public assetInfoMap;

    // latest time to settlement
    uint256 internal latestSettleTime;
    // Accumulate interest rate.
    uint256 internal accumulatedRate;

    event SetInterestInfo(address indexed sender,int256 _interestRate,uint256 _interestInterval);
    event AddAsset(bytes32 indexed recieptor,uint256 amount);
    event SubAsset(bytes32 indexed account,uint256 amount,uint256 subOrigin);
    /**
     * @dev retrieve Interest informations.
     * @return distributed Interest rate and distributed time interval.
     */
    function getInterestInfo()external view returns(int256,uint256){
        return (interestRate,interestInterval);
    }

    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param _interestRate mineCoin distributed amount
     * @param _interestInterval mineCoin distributied time interval
     */
    function _setInterestInfo(int256 _interestRate,uint256 _interestInterval,uint256 maxRate,uint256 minRate)internal {
        if (accumulatedRate == 0){
            accumulatedRate = rayDecimals;
        }
        require(_interestRate<=1e27 && _interestRate>=-1e27,"input interest rate is too large");
        require(_interestInterval>0,"input mine Interval must larger than zero");
        uint256 newLimit = calAccumulatedRate(rayDecimals,31536000,_interestRate,_interestInterval);
        require(newLimit<=maxRate && newLimit>=minRate,"input interest rate is out of range");
        _interestSettlement();
        interestRate = _interestRate;
        interestInterval = _interestInterval;
        emit SetInterestInfo(msg.sender,_interestRate,_interestInterval);
    }
    function totalAssetAmount()internal virtual view returns(uint256){
        return calInterestAmount(totalAsset,newAccumulatedRate());
    }
    function getAssetBalance(bytes32 account)internal virtual view returns(uint256){
        return calInterestAmount(assetInfoMap[account].baseAsset,newAccumulatedRate());
    }
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function addAsset(bytes32 account,uint256 amount) internal {
        assetInfoMap[account].originAsset = assetInfoMap[account].originAsset.add(amount);
        uint256 _currentRate = newAccumulatedRate();
        mintAsset(account,calBaseAmount(amount,_currentRate));
        require(calInterestAmount(assetInfoMap[account].baseAsset,_currentRate)+1 >= assetFloor, "Debt is below the limit");
        require(calInterestAmount(totalAsset,_currentRate) <= assetCeiling, "vault debt is overflow");
        emit AddAsset(account,amount);
    }
    /**
     * @dev repay user's debt and taxes.
     * @param amount repay amount.
     */
    function subAsset(bytes32 account,uint256 amount)internal returns(uint256) {
        uint256 originBalance = assetInfoMap[account].originAsset;
        uint256 _currentRate = newAccumulatedRate();
        uint256 assetAndInterest = calInterestAmount(assetInfoMap[account].baseAsset,_currentRate);
        
        uint256 _subAsset;
        if(assetAndInterest == amount){
            _subAsset = originBalance;
            assetInfoMap[account].originAsset = 0;
            burnAsset(account,assetInfoMap[account].baseAsset);
        }else if(assetAndInterest > amount){
            _subAsset = originBalance.mul(amount)/assetAndInterest;
            burnAsset(account,calBaseAmount(amount,_currentRate));
            require(calInterestAmount(assetInfoMap[account].baseAsset,_currentRate)+1 >= assetFloor, "Debt is below the limit");
            assetInfoMap[account].originAsset = originBalance.sub(_subAsset);
        }else{
            require(false,"overflow asset balance");
        }
        emit SubAsset(account,amount,_subAsset);
        return _subAsset;
    }
    //Accumulate interest rate when the insterest Rate is changed.
    function _interestSettlement()internal{
        uint256 _interestInterval = interestInterval;
        if (_interestInterval>0){
            accumulatedRate = newAccumulatedRate();
            latestSettleTime = currentTime()/_interestInterval*_interestInterval;
        }else{
            latestSettleTime = currentTime();
        }
    }
    //Calculate current accumulated interest
    function newAccumulatedRate()internal view returns (uint256){
        return calAccumulatedRate(accumulatedRate,currentTime().sub(latestSettleTime),interestRate,interestInterval);
    }
    //Calculate accumulated interest function
    function calAccumulatedRate(uint256 baseRate,uint256 timeSpan,
        int256 _interestRate,uint256 _interestInterval)internal virtual pure returns (uint256);
    function currentTime() internal virtual view returns (uint256){
        return block.timestamp;
    }
    function calBaseAmount(uint256 amount, uint256 _interestRate) internal pure returns(uint256){
        return amount.mul(InterestDecimals)/_interestRate;
    }
    function calInterestAmount(uint256 amount, uint256 _interestRate) internal pure returns(uint256){
        return amount.mul(_interestRate)/InterestDecimals;
    }
    function mintAsset(bytes32 account,uint256 amount)internal{
        assetInfoMap[account].baseAsset = assetInfoMap[account].baseAsset.add(amount);
        totalAsset = totalAsset.add(amount);
    }
    function burnAsset(bytes32 account,uint256 amount) internal{
        assetInfoMap[account].baseAsset = assetInfoMap[account].baseAsset.sub(amount);
        totalAsset = totalAsset.sub(amount);
    }
}