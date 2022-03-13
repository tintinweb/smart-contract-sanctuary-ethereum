// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface ISwapHelper {
    function isTokenSwapSupport(address fromToken, address toToken) external view returns (bool);
    function getAmountsOut(address fromToken, address toToken, uint fromAmount) external view returns (uint[] memory);
    function swapExactTokensForTokens(address fromToken, address toToken, uint fromAmount, uint amountOutMin) external;
}

interface IPreGenesis {
    function getAssetBalance(address account) external view returns(uint256);
    function transferVCoin(address _user, uint256 _vCoinAmount) external;
}

interface IPriceHelper {
    function getBTCUSDC365() external view returns(uint256);
    function getBTCUSDC24() external view returns(uint256);
    function getBTCUSDC() external view returns(uint256);
    function getBTCHBTC24() external view returns(uint256);
    function getBTCHBTC() external view returns(uint256);
    function update() external;
}

contract Genesis {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    event VTokenDeposit(address indexed user, address toToken, uint256 targetAmount);
    event TokenDeposit(address indexed user, address fromToken, address toToken, uint256 targetAmount);
    
    struct TokenInfo {
        bool isActive;
        bool fromNative;
        address token;
    }
    
    struct GenesisInfo {
        bool isActive;
        uint genesisAmount;
        uint bondRate;
    }
    
    modifier genesisOwner() {
        require(msg.sender == admin, "NoOwner");
        _;
    }
    
    modifier genesisReward() {
        require(msg.sender == genesisRewardHandler, "NoRewardHandler");
        _;
    }
    
    modifier tokenSupported(address token) {
        require(tokenMap[token].isActive, "NotSupported");
        _;
    }
    
    modifier genesisOngoing() {
        require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp, "GenesisNotOngoing");
        _;
    }
    
    modifier genesisEnd() {
        require(block.timestamp > endTimestamp, "GenesisNotEnd");
        _;
    }
    
    modifier genesisUnsettled() {
        require(genesisSettleState == 0, "GenesisNotUnsettled");
        _;
    }
    
    modifier genesisSettled1() {
        require(genesisSettleState == 1, "GenesisNotSettled1");
        _;
    }
    
    modifier genesisSettled12() {
        require(genesisSettleState >= 1, "GenesisNotSettled12");
        _;
    }
    
    modifier genesisSettled2() {
        require(genesisSettleState == 2, "GenesisNotSettled2");
        _;
    }
    
    uint public constant RATE_MAX = 50;
    uint public constant RATE_LEVEL = 100;
    uint public constant BOND_DISCOUNT_MIN = 0;
    uint public constant BOND_DISCOUNT_MAX = 1000;
    uint public constant BOND_DISCOUNT_LEVEL = 10000;
    
    address public admin;
    address public nativeToken;
    address public targetToken;
    
    address public swapHelper;
    address public priceHelper;
    address public genesisRewardHandler;
    
    address[] public preGenesisArray;
    mapping(address => uint) public preGenesises;
    
    mapping(address => TokenInfo) public tokenMap;
    
    mapping(address => GenesisInfo) public userGenesisMap;
    
    uint public startTimestamp = 1646827200; //2022-03-09GMT12:00:00
    uint public endTimestamp = 1648036800; //2022-03-23GMT12:00:00
    
    uint public genesisSettleState = 0;
    uint public totalGenesisAmount;
    uint public totalBondAmount;
    uint public genesisPrice;
    uint public bondPrice;
    
    receive() external payable {
    }
    
    constructor(address pAdmin, address pNativeToken, address pTargetToken) {
        admin = pAdmin;
        nativeToken = pNativeToken;
        targetToken = pTargetToken;
        
        //USDC
        tokenMap[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = TokenInfo({
            isActive: true,
            fromNative: false,
            token: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        });
        
        //USDT
        tokenMap[0xdAC17F958D2ee523a2206206994597C13D831ec7] = TokenInfo({
            isActive: true,
            fromNative: false,
            token: 0xdAC17F958D2ee523a2206206994597C13D831ec7
        });
        
        //WBTC
        tokenMap[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = TokenInfo({
            isActive: true,
            fromNative: false,
            token: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        });
        
        //WETH
        tokenMap[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = TokenInfo({
            isActive: true,
            fromNative: true,
            token: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        });
        
        preGenesisArray.push(0xfCA3a1a001bb11A8E2b9b7eF81E62408aCEC8D19);
        preGenesises[0xfCA3a1a001bb11A8E2b9b7eF81E62408aCEC8D19] = 1;
    }
    
    function changeOwner(address pOwner) 
        public 
        genesisOwner 
    {
        admin = pOwner;
    }
    
    function setParametersAddr(uint paramType, address paramAddr) 
        public 
        genesisOwner 
    {
        require(paramType >= 1 && paramType <= 3, "OutOfRange");
        
        if(paramType == 1) 
        {
            swapHelper = paramAddr;
        }
        else if(paramType == 2) 
        {
            priceHelper = paramAddr;
        }
        else if(paramType == 3) 
        {
            genesisRewardHandler = paramAddr;
        }
    }
    
    function setParameters(uint paramType, uint paramValue) 
        public 
        genesisOwner 
    {
        require(paramType >= 1 && paramType <= 2, "OutOfRange");
        
        if(paramType == 1) 
        {
            startTimestamp = paramValue;
        }
        else if(paramType == 2) 
        {
            endTimestamp = paramValue;
        }
    }
    
    function setPreGenesis(address pPreGenesis, uint enabled) 
        public 
        genesisOwner 
    {
        if(enabled == 1) {
            preGenesisArray.push(pPreGenesis);
        }
        
        preGenesises[pPreGenesis] = enabled;
    }
     
    function enableTokenInfo(address token, bool fromNative)
        public
        genesisOwner
    {
        tokenMap[token] = TokenInfo({
            isActive: true,
            fromNative: fromNative,
            token: token
        });
    }
    
    function disableTokenInfo(address token)
        public
        genesisOwner
    {
        TokenInfo storage tokenInfo = tokenMap[token];
        require(tokenInfo.isActive, "TokenAlreadyDisabled");
        
        tokenMap[token].isActive = false;
    }
    
    function adjustGenesisAmounts(address user, uint targetAmount)
        internal
    {
        if(userGenesisMap[user].isActive) {
            GenesisInfo storage genesisInfo = userGenesisMap[user];
            
            uint bondAmount = genesisInfo.genesisAmount * genesisInfo.bondRate / RATE_LEVEL;
            totalBondAmount -= bondAmount;
            
            genesisInfo.genesisAmount += targetAmount;
            totalGenesisAmount += targetAmount;
            
            bondAmount = genesisInfo.genesisAmount * genesisInfo.bondRate / RATE_LEVEL;
            totalBondAmount += bondAmount;
        }
        else {
            userGenesisMap[user] = GenesisInfo({
                isActive: true,
                genesisAmount: targetAmount,
                bondRate: 0
            });
            
            totalGenesisAmount += targetAmount;
        }
    }
    
    function convertPreGenesis(address preGenesis)
        public
        genesisOngoing
    {
        require(preGenesises[preGenesis] == 1, "NotPreGenesis");
        
        uint targetAmount = IPreGenesis(preGenesis).getAssetBalance(msg.sender);
        require(targetAmount > 0, "NoAmount");
        
        IPreGenesis(preGenesis).transferVCoin(msg.sender, targetAmount);
        emit VTokenDeposit(msg.sender, targetToken, targetAmount);
        adjustGenesisAmounts(msg.sender, targetAmount);
    }
    
    function depositToken(address fromToken, uint fromAmount, uint targetAmountMin)
        public
        genesisOngoing
        tokenSupported(fromToken)
    {
        uint targetAmount;
        require(fromAmount > 0, "NoAmount");
        
        if(fromToken == targetToken) {
            IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount);
            targetAmount = fromAmount;
        }
        else {
            IERC20(fromToken).safeTransferFrom(msg.sender, swapHelper, fromAmount);
            uint oldTokenBalance = IERC20(targetToken).balanceOf(address(this));
            ISwapHelper(swapHelper).swapExactTokensForTokens(fromToken, targetToken, fromAmount, targetAmountMin);
            uint newTokenBalance = IERC20(targetToken).balanceOf(address(this));
            targetAmount = newTokenBalance - oldTokenBalance;
        }
        
        emit TokenDeposit(msg.sender, fromToken, targetToken, targetAmount);
        adjustGenesisAmounts(msg.sender, targetAmount);
    }
    
    function depositNative(uint targetAmountMin)
        public
        payable
        genesisOngoing
        tokenSupported(nativeToken)
    {
        uint fromAmount = msg.value;
        require(fromAmount > 0, "NoAmount");
        
        payable(swapHelper).transfer(fromAmount);
        uint oldTokenBalance = IERC20(targetToken).balanceOf(address(this));
        ISwapHelper(swapHelper).swapExactTokensForTokens(nativeToken, targetToken, fromAmount, targetAmountMin);
        uint newTokenBalance = IERC20(targetToken).balanceOf(address(this));
        uint targetAmount = newTokenBalance - oldTokenBalance;
        
        emit TokenDeposit(msg.sender, nativeToken, targetToken, targetAmount);
        adjustGenesisAmounts(msg.sender, targetAmount);
    }
    
    function setPreBondRate(uint bondRate)
        public
        genesisOngoing
    {
        require(userGenesisMap[msg.sender].isActive, "NoUser");
        require(bondRate <= RATE_MAX, "MaxExceeded");
        
        GenesisInfo storage genesisInfo = userGenesisMap[msg.sender];
        require(bondRate >= genesisInfo.bondRate, "NoDecrease");
        
        uint bondAmount = genesisInfo.genesisAmount * genesisInfo.bondRate / RATE_LEVEL;
        totalBondAmount -= bondAmount;
        
        genesisInfo.bondRate = bondRate;
        bondAmount = genesisInfo.genesisAmount * genesisInfo.bondRate / RATE_LEVEL;
        totalBondAmount += bondAmount;
    }
    
    function handlePreGenesisBatch(address preGenesis, address[] calldata users)
        public
        genesisOwner
        genesisEnd
        genesisUnsettled
    {
        require(preGenesises[preGenesis] == 1, "NotPreGenesis");
        
        for(uint k=0; k<users.length; k++) {
            uint targetAmount = IPreGenesis(preGenesis).getAssetBalance(users[k]);
            require(targetAmount > 0, "NoAmount");
            
            IPreGenesis(preGenesis).transferVCoin(users[k], targetAmount);
            emit VTokenDeposit(users[k], targetToken, targetAmount);
            adjustGenesisAmounts(users[k], targetAmount);
        }
    }
    
    function settleGenesis()
        public
        genesisOwner
        genesisEnd
        genesisUnsettled
    {
        uint btcusdc365 = IPriceHelper(priceHelper).getBTCUSDC365();
        require(btcusdc365 > 0, "NoPrice");
        
        //DISCOUNT: 10000 LEVEL
        //BOND_DISCOUNT_MIN = 0: when rate is RATE_MAX
        //BOND_DISCOUNT_MAX = 1000: when rate is 0.
        uint bondDiscount = (RATE_MAX-totalBondAmount*RATE_LEVEL/totalGenesisAmount)*BOND_DISCOUNT_MAX/RATE_MAX + 
                            totalBondAmount*RATE_LEVEL/totalGenesisAmount*BOND_DISCOUNT_MIN/RATE_MAX;
        genesisPrice = btcusdc365/10000;
        bondPrice = genesisPrice*(BOND_DISCOUNT_LEVEL-bondDiscount)/BOND_DISCOUNT_LEVEL;
        
        genesisSettleState = 1;
    }
    
    function getGenesisInfo()
        public
        view
        genesisSettled12
        returns(uint256 genesisAmount, uint256 bondAmount, uint256 priceGenesis, uint256 priceBond)
    {
        genesisAmount = totalGenesisAmount;
        bondAmount = totalBondAmount;
        priceGenesis = genesisPrice;
        priceBond = bondPrice;
    }
    
    function getUserGenesisInfo(address user)
        public
        view
        returns(uint256 genesisAmount, uint256 bondRate, uint256 bondRateLevel)
    {
        if(userGenesisMap[user].isActive) {
            genesisAmount = userGenesisMap[user].genesisAmount;
            bondRate = userGenesisMap[user].bondRate;
            bondRateLevel = RATE_LEVEL;
        }
    }
    
    function withdrawGenesis()
        public
        genesisSettled1
        genesisReward
    {
        uint amount = IERC20(targetToken).balanceOf(address(this));
        IERC20(targetToken).safeTransfer(msg.sender, amount);
        
        genesisSettleState = 2;
    }
    
    function withdrawTokenProtocol(address token, address payable receiver)
        public
        genesisSettled2
        genesisOwner
    {
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(receiver, amount);
    }
    
    function withdrawNativeProtocol(address payable receiver)
        public
        genesisSettled2
        genesisOwner
    {
        uint amount = address(this).balance;
        receiver.transfer(amount);
    }

}