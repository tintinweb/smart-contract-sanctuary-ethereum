//SPDX-License-Identifier: MIT

/*
/ This code was developed to support the distribution of shares of The Symplexia Labs, 
/ so it contains a set of monetary concepts that support the company's business development. 
/ In particular, some monetary reserves were created (Wicksell Reserves and Regulatory Funds) 
/ that are linked to the WicksellBurn and FisherAttenuation methods, among others. These   
/ methods were named in tribute to two brilliant economists related to monetary concepts.
/ If you want to know more about Knut Wicksell and his influence in the monetary concepts 
/ follow this link https://en.wikipedia.org/wiki/Knut_Wicksell. The same way, if you want 
/ to know more about Irving Fisher follow this link https://en.wikipedia.org/wiki/Irving_Fisher.
*/

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./BasicAccessControl.sol";

//    Interfaces   

import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

//**********************************//
//             BaseToken 
//**********************************//

abstract contract BaseToken  is ERC20, Ownable {

    address public            contingencyFundsVault;
    address public            projectFundsVault;
    address public            liquidityVault;
    address internal          _swapRouterAddress;
    address internal constant wicksellReserves       = 0x105457181764615639126242800330228074FEeD;
    address internal constant goldenBonus            = 0x161803398874989484820458683436563811Feed;
    address internal constant loyaltyRewards         = 0x241421356237309504880168872420969807fEED;
    address internal constant corporateAssets        = 0x577215664901532860606512090082402431FEED; 
    address internal constant regulatoryFunds        = 0x132471795724474602596090885447809734fEEd;


    uint32  internal constant _baseSupply            = 1500000000;  
    uint8   internal constant _decimals              = 9;
    uint16  internal constant tenK                   = 10000;
    uint16  internal constant bonusFee               = 450;
    uint16  internal constant liquidityFee           = 300;
    uint16  internal constant projectFee             = 200;                     
    uint16  internal constant contingencyFee         = 50;
    uint16  internal constant maxDynamicFee          = 500;
    uint16  internal constant minDynamicFee          = 50;
    uint16  internal          reducedLiquidityFee;                   // Initially 1%            (Depends on efficiencyFactor)
    uint16  internal          reducedBonusFee;                       // Initially 2%            (Depends on efficiencyFactor)
    uint16  internal          reducedProjectFee;                     // Initially 1%            (Depends on efficiencyFactor)
    uint16  public            efficiencyFactor;                      // Must be calibrated between 150 and 250 
    bool    public            isBurnable             = true;

    uint256 internal          _tokensSupply          = ( _baseSupply          ) * 10**_decimals;
    uint256 internal constant _minimumSupply         = ((_baseSupply * 2) / 3 ) * 10**_decimals;
    uint256 internal constant _maxWalletBalance      = ( _baseSupply / 100    ) * 10**_decimals; 	 // 1% of the total supply
    uint256 internal constant _maxTokensPerTx        = ( _baseSupply / 200    ) * 10**_decimals;     // 0.5% of  Tokens Supply
    uint256 internal          _liquidityThreshold;            	                                     // 0.05% of Tokens Suplly  (Depends on efficiencyFactor)

    struct AccountInfo {uint256 balance; uint48 lastTxn; uint48 nextMilestone; uint48 headSpecialAssets;
                        bool isInternal; bool isTaxFree; bool isNonBonus; bool isLocked; bool isUnrewardable; }

    struct AssetsInfo {uint256 balance; uint48 releaseTime;}
	        
    mapping (address => AccountInfo) internal Wallet;
    mapping (address => mapping (uint48 => AssetsInfo)) internal specialAssets;

//   ======================================
//             Constructor Function             
//   ======================================

    constructor (address _projectFundsVault,
                 address _contingencyFundsVault, 
                 address _liquidityVault, 
                 address swapRouterAddress)  {

        contingencyFundsVault = _contingencyFundsVault;
        projectFundsVault     = _projectFundsVault;
        liquidityVault        = _liquidityVault;
        _swapRouterAddress    = swapRouterAddress;
    }

    function _tokenTransfer (address, address, uint256, bool) internal virtual {}

//   ======================================
//          IERC20 Functions                
//   ======================================

    function decimals()    public pure override returns (uint8)   { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _tokensSupply; }
}
//**********************************//
//     M A N A G E A B L E 
//**********************************//

abstract contract Manageable is BasicAccessControl {
    
    uint8 constant Contract_Manager     = 1;
    uint8 constant Financial_Controller = 11;
    uint8 constant Compliance_Auditor   = 12;
    uint8 constant Distributor_Agent    = 13;
    uint8 constant Treasury_Analyst     = 111;

    constructor() {
       _setupRole(Contract_Manager,     _msgSender());
       _setupRole(Financial_Controller, _msgSender());
       _setupRole(Compliance_Auditor,   _msgSender());
       _setupRole(Treasury_Analyst,     _msgSender());
       _setupRole(Distributor_Agent,    _msgSender());

       _setRoleAdmin(Contract_Manager,     Contract_Manager);
       _setRoleAdmin(Financial_Controller, Contract_Manager);
       _setRoleAdmin(Distributor_Agent,    Contract_Manager);
       _setRoleAdmin(Compliance_Auditor,   Contract_Manager);
       _setRoleAdmin(Treasury_Analyst,     Financial_Controller);
    }
}
//**********************************//
//        A D J U S T A B L E   
//**********************************//

abstract contract Adjustable  is Pausable, Manageable, BaseToken {

    bool      public   allowSecurityPause = true;
    address[] internal _noBonus;

    event NumTokensToLiquidityUpdated(address authorizer, uint256 _liquidityThreshold);
    event MaxTokensPerTxUpdated(address authorizer, uint256 _maxTokensPerTx);
    event VaultUpdated(address authorizer, uint8 id, address liquidityVault);
    event EfficiencyFactorUpdated (address authorizer, uint16 _newValue);

    function _addInternalStatus (address account, bool isLocked) internal {
        Wallet[account].isInternal     = true;
        Wallet[account].isTaxFree      = true;
        Wallet[account].isLocked       = isLocked;
        Wallet[account].isNonBonus     = true;
        Wallet[account].isUnrewardable = true;
        _noBonus.push(account);
    }

    function _removeInternalStatus (address account) internal {
        Wallet[account].isInternal = false;
        Wallet[account].isTaxFree  = false;
        Wallet[account].isLocked   = false;
    }

    function _setEfficiencyFactor (uint16 _newFactor) internal {
        efficiencyFactor       = _newFactor;
        reducedLiquidityFee    = efficiencyFactor/2;      
        reducedBonusFee        = efficiencyFactor;
        reducedProjectFee      = efficiencyFactor/2;              
        _liquidityThreshold    = _tokensSupply / (efficiencyFactor*10); 	 
    }
//   ======================================
//           Parameters Functions                    
//   ======================================

    function setEfficiencyFactor (uint16 _newValue) external onlyRole(Financial_Controller) {
        require (_newValue >= 150 && _newValue <= 250, "Out of thresholds");
        _setEfficiencyFactor (_newValue);
        emit EfficiencyFactorUpdated (_msgSender(), _newValue);
    }

    function setVault (address _newVault, uint8 _id) external onlyRole(Financial_Controller) {
        require (_id == 1 || _id == 2 || _id == 3, "Invalid Vault id");
        require (Wallet[_newVault].balance == 0, "New account is not empty");

        _addInternalStatus (_newVault, false);

        if        (_id == 1) {
            _removeInternalStatus (projectFundsVault);              // NOTE: The previous account remains without receiving bonus 
            projectFundsVault = _newVault;
        } else if (_id == 2) {
            _removeInternalStatus (contingencyFundsVault);          // NOTE: The previous account remains without receiving bonus 
            contingencyFundsVault = _newVault;
        } else               {
            _removeInternalStatus (liquidityVault);                 // NOTE: The previous account remains without receiving bonus 
            liquidityVault = _newVault;
        }

        emit VaultUpdated(_msgSender(), _id, _newVault);
    }
//   ======================================
//           Contingency Functions                    
//   ======================================

  // Called by the Compliance Auditor on emergency, allow begin or end an emergency stop
    function setSecurityPause (bool isPause) external onlyRole(Compliance_Auditor) {
        if (isPause)  {
            require(  allowSecurityPause, "Contingency pauses not allowed." );
            _pause();
        } else {
            require( paused(), "Contingency pause is not active.");
            _unpause();  
        }
    }
    
  // Called by the Financial Controller to disable ability to begin or end an emergency stop
    function disableContingencyFeature() external onlyRole(Financial_Controller)  {
        allowSecurityPause = false;
    }
}
//**********************************//
//    F L O W - F L E X I B L E
//**********************************//
abstract contract  FlowFlexible is Manageable, BaseToken {

    uint48 internal constant _sellRange    = 30  minutes;
    uint48 internal constant _loyaltyRange = 180 days;
    uint48 internal constant _burnRange    = 90  days;
    uint48 internal constant _releaseRange = 7   days;

    event WarningListUpdated     (address authorizer, address _user, bool _status);
    event UnfitEarningsFrozen    (address authorizer, address unfitTrader, uint256 _balance);
    event WicksellReservesBurned (address authorizer, uint256 burnAmount);
   
    function _getDynamicFee (address account, uint256 sellAmount) internal returns (uint256) {
        
        uint256 reduceFee;
        uint256 sellQuocient; 
        uint256 reduceFactor;

        uint256 dynamicFee = Wallet[account].balance * maxDynamicFee * efficiencyFactor / _tokensSupply;
       
        if (dynamicFee > maxDynamicFee) {dynamicFee = maxDynamicFee;}
        if (dynamicFee < minDynamicFee) {dynamicFee = minDynamicFee;}
        
        if (Wallet[account].lastTxn + _sellRange < block.timestamp) {
            sellQuocient = (sellAmount * tenK) / Wallet[account].balance;
            reduceFactor = (sellQuocient > 1000) ? 0 : (1000 - sellQuocient);
            reduceFee    = (reduceFactor * 30) / 100;
            dynamicFee  -= reduceFee;
        }

        Wallet[account].lastTxn = uint48(block.timestamp);
        return dynamicFee;
    }

    function setNextMilestone (address account, uint256 txAmount) internal {
        uint256 elapsedTime  = _loyaltyRange + block.timestamp - Wallet[account].nextMilestone;
        uint256 adjustedTime = ( elapsedTime * Wallet[account].balance) / ( Wallet[account].balance + txAmount ); 
        Wallet[account].nextMilestone = uint48(block.timestamp + _loyaltyRange - adjustedTime);
        Wallet[account].lastTxn = uint48(block.timestamp);
    }
//   ======================================
//            Manageable Functions                    
//   ======================================
    function setWarningList (address _markedAccount, bool _status) external onlyRole(Treasury_Analyst) {
        require (!Wallet[_markedAccount].isInternal, "Internal Account is immutable"); 
        Wallet[_markedAccount].isLocked = _status;
        if ( _status = true ) Wallet[_markedAccount].lastTxn = uint48(block.timestamp);
        emit WarningListUpdated(_msgSender(), _markedAccount, _status);
    }
   
    function WicksellBurn () external onlyRole(Treasury_Analyst) {
        require (Wallet[wicksellReserves].balance > 0, "There is no balance to burn");
        require (Wallet[wicksellReserves].lastTxn + 30 days < block.timestamp, "Time elapsed too short");
        uint256 elapsedTime  = _burnRange + block.timestamp - Wallet[wicksellReserves].nextMilestone;
        uint256 burnAmount;
       
        if (isBurnable) {
            if (elapsedTime > _burnRange) { 
                 burnAmount = Wallet[wicksellReserves].balance;                                // Balance without the part reffering to bonus
                 Wallet[wicksellReserves].nextMilestone = uint48(block.timestamp + _burnRange);
            } else {
                 burnAmount = (Wallet[wicksellReserves].balance * elapsedTime) / _burnRange;
            }

            Wallet[wicksellReserves].balance -= burnAmount;                                    // Burn only the raw balance, without the bonus
            _tokensSupply                    -= burnAmount;
        } else{
            uint256 _residueBurn = (Wallet[wicksellReserves].balance + _minimumSupply) - _tokensSupply;
            Wallet[goldenBonus].balance += _residueBurn;
            delete Wallet[wicksellReserves];
            _tokensSupply = _minimumSupply;
        }

        emit WicksellReservesBurned (_msgSender(), burnAmount);
    }
//   ======================================
//            Investor Functions                    
//   ======================================

    function unlockMyAccount () external {
        require (!Wallet[_msgSender()].isInternal && Wallet[_msgSender()].isLocked, "Unlock is not allowed");
        require (Wallet[_msgSender()].lastTxn + _releaseRange < block.timestamp,    "Unlock is not allowed yet"); 
        Wallet[_msgSender()].isLocked = false;
        emit WarningListUpdated(_msgSender(), _msgSender(), false);
    }
}
//**********************************//
//   A U T O L I Q U I D I T Y
//**********************************//
abstract contract AutoLiquidity is BaseToken, Adjustable {

    IUniswapV2Router02 internal _swapRouter;
    address public liquidityPair;
 
    bool    public   autoLiquidity = true;
    bool    internal inLiquidityProcess; 

    modifier nonReentrant {
        inLiquidityProcess = true;
        _;
        inLiquidityProcess = false;
    }
    
    event LiquidityIncreased(uint256 tokensSwapped, uint256 coinsReceived, uint256 tokensIntoLiquidity);    
    event CoinsTransferred(address recipient, uint256 amountCoins);
    event AutoLiquiditySet (address authorizer, bool _status);

//   ======================================
//             Constructor Function             
//   ======================================  
    constructor () {

        IUniswapV2Router02 swapRouter = IUniswapV2Router02(_swapRouterAddress);    	//DEX Swap's Address
        
        // Create a Uniswap/Pancakeswap pair for this new Token
        liquidityPair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this),swapRouter.WETH());
 
        // set the rest of the contract variables
        _swapRouter = swapRouter;
    }
//   ======================================
//     To receive Coins              
//   ======================================

    receive() external payable {}                      			

//   ======================================
//      BEGIN Function swapAndLiquify  
//   ======================================

    function _increaseLiquidity (uint256 numTokensToLiquidity) internal nonReentrant {

        // **** Split the 'numTokensToLiquidity' into halves  ***
        uint256 swapAmount      = numTokensToLiquidity / 2;
        uint256 liquidityAmount;

        // NOTE: Capture the contract's current Coins balance,  
        // thus we can know exactly how much Coins the swap 
        // creates, and not make recent events include any Coin  
        // that has been manually sent to the contract. 
        uint256 initialCoinBalance = address(this).balance;

        // Swap tokens for Coins (01)
        _swapProcess(swapAmount);

        // Calculate how much Coins was swapped
        uint256  swappedCoins  = address(this).balance - initialCoinBalance;

        // Adjust the amount of Tokens to add to Liquidity Pool
        uint256 _tokensDesired = (getTokenPrice() * swappedCoins) / (10 ** 18);
        uint256 _deficitTokens = ( _tokensDesired > Wallet[address(this)].balance) ? (_tokensDesired - Wallet[address(this)].balance) : 0;

        if (_deficitTokens == 0) {
            liquidityAmount = _tokensDesired; }
        else {
            if (Wallet[regulatoryFunds].balance >= _deficitTokens) {
                Wallet[regulatoryFunds].balance -= _deficitTokens;
                Wallet[address(this)].balance   += _deficitTokens;
            }
            liquidityAmount = Wallet[address(this)].balance;
        }

        // Add liquidity to DEX  (02)
        _liquidityProcess(liquidityAmount, swappedCoins);

        emit LiquidityIncreased(swapAmount, swappedCoins, liquidityAmount);

        /** NOTE:  ***  Take Remaining Balance  (03)   ***
        *   There is a possibility that a small amount of Coins remains in the contract. 
        *   So the method "TransferCoins" allow to transfer these coins to "LiquidityVault",  
        *   otherwise those coins would be locked in the contract forever.
        */
  
    }
//   ======================================
//          Special Functions                    
//   ======================================  

    function _swapProcess (uint256 swapAmount) private {
        address[] memory path = new address[](2);                       // Generate the DEX pair path of token -> weth
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        _approve(address(this), address(_swapRouter), swapAmount);

        // Make the Swap
         _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0, 				// Accept any amount of Coins
            path,
            address(this),  // Recipient of the ETH/BNB 
            block.timestamp
        );
    }

    function _liquidityProcess (uint256 liquidityAmount, uint256 swappedCoins) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_swapRouter), liquidityAmount);   

        // Add the liquidity
        _swapRouter.addLiquidityETH{value: swappedCoins}(
            address(this),
            liquidityAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityVault,     // Recipient of the liquidity tokens.
            block.timestamp  );
    }

    function transferCoins () external onlyRole(Treasury_Analyst) {
        require(address(this).balance > 0, "The Balance must be greater than 0");
        uint256 amountToTransfer = address(this).balance;
        payable(liquidityVault).transfer(amountToTransfer);
        emit CoinsTransferred(liquidityVault, amountToTransfer);
    }

    function setAutoLiquidity (bool _status) external onlyRole(Treasury_Analyst) {
        if (Wallet[address(this)].balance >= _liquidityThreshold) { 
            _increaseLiquidity(_liquidityThreshold);
        }
        autoLiquidity = _status;
        emit AutoLiquiditySet (_msgSender(), _status);
    }

    function getTokenPrice () public view returns(uint256) {
        ERC20 T0 = ERC20(IUniswapV2Pair(liquidityPair).token0());
        ERC20 T1 = ERC20(IUniswapV2Pair(liquidityPair).token1());

        (uint256 _reservesT0, uint256 _reservesT1,) = IUniswapV2Pair(liquidityPair).getReserves();

        // Return amount of Token1 needed to buy Token0 (ETH/BNB)
        if (_reservesT0 == 0 || _reservesT1 == 0) return 0;
        if (address(T0) == address(this)) {
            return( (_reservesT0 * (10 ** uint256(T1.decimals() ))) / (_reservesT1) ); }
        else { 
            return( (_reservesT1 * (10 ** uint256(T0.decimals() ))) / (_reservesT0) ); }   
    }

}
//**********************************//
//   T   A   X   A   B   L   E 
//**********************************//
abstract contract Taxable is FlowFlexible, AutoLiquidity {
    using Address  for address;
    
    struct AmountInfo {
           uint256 Inflow;
           uint256 Outflow;
    }

    struct BonusInfo  {
           uint256 Balance;
           uint256 Inflow;
           uint256 Outflow;
    }
     
    struct FeesInfo   {
           uint256 Liquidity;
           uint256 Funds;
           uint256 Bonus;
           uint256 Burn;
           uint256 WicksellReserves;
           uint256 LoyaltyRewards;
           uint256 Project;
           uint256 Contingency;
    }

    struct TradeInfo   {
            uint256 buyingStack;
            uint256 sellingStack;
            uint256 lastTokenPrice;
            uint256 lastTxnValue;
            uint8   lastTxnType;
            bool    needAttenuation;
    }

    TradeInfo public  _tradingTrack;                 // Must be always a "private" variable
    bool      private isAdjustable = true;

    event FeesTransfered (uint256 Liquidity, uint256 Contingency, uint256 Project, uint256 Bonus, uint256 LoyaltyRewards, uint256 WicksellReserves, uint256 Burn );
    event SetExcludedFromBonus (address authorizer, address account, bool status);
    event SetTaxableStatus (address authorizer, address account, bool status);
    event TokensBurnt (address account, uint256 burnAmount);
    event RewardsClaimed (address account, uint256 amountRewards);  
    event AssetsSentAndFrozen (address _recipient, uint64 _freezeDuration, uint256 _amountToFreeze);
    event SpecialAssetsReleased (address _recipient, uint256 _amountReleased);
    event CorporateAssetsShared (address authorizer, address beneficiary, uint256 amount);

//   ======================================
//             Constructor Function             
//   ====================================== 
    constructor () {

        Wallet[corporateAssets].balance = _maxWalletBalance * 5;
        Wallet[regulatoryFunds].balance = _maxWalletBalance * 5;
        Wallet[_msgSender()].balance    = _tokensSupply - Wallet[corporateAssets].balance - Wallet[regulatoryFunds].balance;

        _addInternalStatus (owner(),               false);
        _addInternalStatus (address(this),         false);
        _addInternalStatus (projectFundsVault,     false);
        _addInternalStatus (contingencyFundsVault, false);
        _addInternalStatus (liquidityVault,        false);
        _addInternalStatus (address(0),            true);
        _addInternalStatus (wicksellReserves,      true);
        _addInternalStatus (goldenBonus,           true);
        _addInternalStatus (loyaltyRewards,        true);
        _addInternalStatus (corporateAssets,       true);
        _addInternalStatus (regulatoryFunds,       true);

        _includeInBonus(wicksellReserves);
 
        // Exclude liquidityPair from Bonus

        Wallet[liquidityPair].isNonBonus = true;
        _noBonus.push(liquidityPair);

        // This factor calibrates the contract performance and the values of reduced fees 

        _setEfficiencyFactor (200);
        
        emit Transfer(address(0), _msgSender(), _tokensSupply);
    }
//  =======================================
//        IERC20 Functions (OVERRIDE)              
//   ======================================

    function balanceOf (address account) public view override returns (uint256) {
        return Wallet[account].balance + _getBonus(account);
    }
//   ======================================
//          BEGIN Function _transfer   
//   ======================================

    function _transfer ( address sender, address recipient, uint256 amount ) internal override whenNotPaused {
        require(!Wallet[sender].isLocked && !Wallet[recipient].isLocked, "This address is locked");  
        require(amount > 0 && balanceOf(sender) >= amount, "Insufficient balance to transfer"); 
    
        if (!Wallet[sender].isInternal  && !Wallet[recipient].isInternal) {  
            require(amount <= _maxTokensPerTx, "Transfer exceeds the maximum limit."); 
        }

        if (!Wallet[sender].isInternal && 
            !Wallet[recipient].isInternal &&
            recipient != liquidityPair )  {

            require( balanceOf(recipient) + amount <= _maxWalletBalance, "Wallet balance exceed the limit");
        }      

        //  Indicates that all fees should be deducted from transfer
        bool applyFee = (Wallet[sender].isTaxFree || Wallet[recipient].isTaxFree) ? false:true;

        if (autoLiquidity && !inLiquidityProcess) {_beforeTokenTransfer(sender, recipient, amount);}

        _tokenTransfer(sender, recipient, amount, applyFee); 
  
    }
//   ==========================================
//     BEGIN Function  __beforeTokenTransfer     
//   ==========================================

    function _beforeTokenTransfer (address sender, address recipient, uint256 amount) internal override { 
        uint256 _newTokenPrice = getTokenPrice();

        if (_newTokenPrice == 0) {return;}

        if (isAdjustable) {
            uint256 _attenuationPoint =  _updateStack(_newTokenPrice);

            _tradingTrack.lastTokenPrice = _newTokenPrice;
            _tradingTrack.lastTxnValue   = amount;

            if (_tradingTrack.needAttenuation && sender != liquidityPair)  {_attenuateImpulse(_attenuationPoint);}
            else if (sender    == liquidityPair)                {_tradingTrack.lastTxnType = 1;}
            else if (recipient == liquidityPair)                {_tradingTrack.lastTxnType = 2;}
            else                                                {_tradingTrack.lastTxnType = 0;}

            return;
        }

        if (sender != liquidityPair && Wallet[address(this)].balance >= _liquidityThreshold) { 
            _increaseLiquidity(_liquidityThreshold);
        }
    }
//   ======================================
//      BEGIN Function _tokenTransfer                   
//   ======================================

//   This Function is responsible for taking all fee, if 'applyFee' is true
    function _tokenTransfer (address sender, address recipient, uint256 tAmount, bool applyFee) internal override {

        BonusInfo  memory bonus;
        FeesInfo   memory fees;
        AmountInfo memory amount;

        uint256 transferAmount;
        uint256 totalFees;
        uint256 deflatFee;
        uint256 WicksellReservesFee;
        uint256 loyaltyRewardsFee;
        uint256 dynamicFee;

        // Calculate the Outflow values distribution (Raw Balance and Bonus)

        bonus.Balance  = _getBonus(sender);
        bonus.Outflow  = bonus.Balance > 0 ? (bonus.Balance * tAmount) / balanceOf(sender) : 0;
        amount.Outflow = tAmount - bonus.Outflow;

        // Calculate all Fees

        if (applyFee) {
            if (sender == liquidityPair) {
               (fees, totalFees) = _calcFees (tAmount, 0, 0, 0, 0, 0, bonusFee, projectFee); 

            } else if (recipient == liquidityPair) {
                    uint16  salesBonusFee = (Wallet[goldenBonus].balance == bonus.Balance)? 0 : reducedBonusFee;
                    dynamicFee = _getDynamicFee(sender, tAmount);

                    if (isBurnable) {
                        loyaltyRewardsFee     = dynamicFee < (2 * minDynamicFee) ? dynamicFee : (2 * minDynamicFee);
                        dynamicFee           -= loyaltyRewardsFee;
                        deflatFee             = dynamicFee / 3;
                        WicksellReservesFee   = dynamicFee - deflatFee;
                    } else {loyaltyRewardsFee = dynamicFee;}

                    (fees, totalFees) = _calcFees (tAmount, liquidityFee, deflatFee, WicksellReservesFee, loyaltyRewardsFee,
                                                   contingencyFee, salesBonusFee, reducedProjectFee); 
            } else {
                    (fees, totalFees) = _calcFees (tAmount, reducedLiquidityFee, 0, 0, minDynamicFee,
                                                   contingencyFee, reducedBonusFee, reducedProjectFee); 
            }
         }

        transferAmount = tAmount - totalFees;

        // Calculate the Inflow values distribution (Raw Balance and Bonus)
        (bonus.Inflow, amount.Inflow) = (Wallet[recipient].isNonBonus) ? (0, transferAmount) : _shareAmount(transferAmount);

       // Update of sender and recipient balances 
        if (!Wallet[recipient].isLocked) {setNextMilestone(recipient, amount.Inflow);}

        Wallet[sender].balance    -= amount.Outflow;
        Wallet[recipient].balance += amount.Inflow;

         // Update the Bonus Shares 
        Wallet[goldenBonus].balance =  Wallet[goldenBonus].balance + bonus.Inflow - bonus.Outflow; 

        emit Transfer(sender, recipient, tAmount);

        // Collect all Fees and Bonus    
        if ( applyFee ) {
            Wallet[address(this)].balance          +=  fees.Liquidity; 
            Wallet[contingencyFundsVault].balance  +=  fees.Contingency;
            Wallet[projectFundsVault].balance      +=  fees.Project;
            Wallet[goldenBonus].balance            +=  fees.Bonus;
            Wallet[loyaltyRewards].balance         +=  fees.LoyaltyRewards;
            if (isBurnable) {
                Wallet[wicksellReserves].balance   +=  fees.WicksellReserves; 
                _tokensSupply                      -=  fees.Burn;
                if (_tokensSupply - Wallet[wicksellReserves].balance <= _minimumSupply ) {
                   isBurnable = false;
                }
            }  
            emit FeesTransfered(fees.Liquidity, fees.Contingency, fees.Project, fees.Bonus, fees.LoyaltyRewards, fees.WicksellReserves, fees.Burn );
        }
    }
//   ======================================
//     BEGIN Function  _updateStack     
//   ======================================
    function _updateStack (uint256 _newTokenPrice) internal returns (uint256 _attenuationPoint) {  
        _attenuationPoint = (Wallet[liquidityPair].balance  / 10);

        if (_tradingTrack.lastTxnType  > 2 ) return (_attenuationPoint) ;

        if (_tradingTrack.lastTokenPrice != _newTokenPrice)  {
            if      (_tradingTrack.lastTxnType == 1) {_tradingTrack.buyingStack  += _tradingTrack.lastTxnValue; }
            else if (_tradingTrack.lastTxnType == 2) {_tradingTrack.sellingStack += _tradingTrack.lastTxnValue; }

            if (_tradingTrack.buyingStack  >= _tradingTrack.sellingStack) {
                _tradingTrack.buyingStack  -= _tradingTrack.sellingStack;
                _tradingTrack.sellingStack  = 0;  }
            else {
                _tradingTrack.sellingStack -= _tradingTrack.buyingStack;
                _tradingTrack.buyingStack   = 0;  }
        }

        _tradingTrack.needAttenuation = (_tradingTrack.buyingStack >= _attenuationPoint);
        _tradingTrack.lastTxnType  = 4;
        _tradingTrack.lastTxnValue = 0;
    }
//   ======================================
//     BEGIN Function  _calcFees     
//   ======================================
    function _calcFees (uint256 _tAmount, uint256 _liquidityFee, 
                        uint256 _deflatFee, uint256 _wicksellFee, 
                        uint256 _loyaltyRewardsFee, uint256 _contingencyFee, 
                        uint256 _bonusFee, uint256 _projectFee) private pure returns (FeesInfo memory, uint256) {
               
        FeesInfo memory fees;
        uint256 totalFees;

        fees.Liquidity            = (_tAmount * _liquidityFee) / tenK;
        fees.Burn                 = (_tAmount * _deflatFee) / tenK;
        fees.WicksellReserves     = (_tAmount * _wicksellFee) / tenK;
        fees.LoyaltyRewards       = (_tAmount * _loyaltyRewardsFee) / tenK;
        fees.Contingency          = (_tAmount * _contingencyFee) / tenK;
        fees.Bonus                = (_tAmount * _bonusFee) / tenK;
        fees.Project              = (_tAmount * _projectFee) / tenK;
        totalFees                 = fees.Liquidity + fees.Burn + fees.WicksellReserves + fees.LoyaltyRewards + 
                                    fees.Contingency + fees.Bonus + fees.Project;
        return (fees, totalFees);
    }
//   ======================================
//               RFI Functions                  
//   ======================================

    /** NOTE:
     *  The "_getBonus", "_shareAmount" and "_bonusBalances" functions help to redistribute 
     *  the specified  amount of Bonus among the current holders via an special algorithm  
     *  that eliminates the need for interaction with all holders account. 
     */
    function _shareAmount (uint256 tAmount) private returns (uint256, uint256) {
        uint256 _eligibleBalance = _bonusBalances();
        if (Wallet[goldenBonus].balance == 0) return (0, tAmount);
        if (_eligibleBalance == 0) { 
            Wallet[loyaltyRewards].balance += Wallet[goldenBonus].balance;
            Wallet[goldenBonus].balance = 0;
            return (0, tAmount);
        } 

        uint256 _bonusStock   = Wallet[goldenBonus].balance;
        uint256 _bonusAmount  = (tAmount * _bonusStock) / (_eligibleBalance + _bonusStock);
        uint256 _rawAmount    = tAmount - _bonusAmount; 
        return (_bonusAmount, _rawAmount);
    }

    function _getBonus (address account) internal view returns (uint256) {
        if ( Wallet[account].isNonBonus || Wallet[goldenBonus].balance == 0 || Wallet[account].balance == 0 ){
            return 0;
        } else {
            uint256 shareBonus = (Wallet[goldenBonus].balance * Wallet[account].balance) / _bonusBalances();
            return  shareBonus;
        }
    }

    function _bonusBalances () private view returns (uint256) {
        uint256 expurgedBalance;
        for (uint256 i=0; i < _noBonus.length; i++){
            expurgedBalance += Wallet[_noBonus[i]].balance;
        }
        return  _tokensSupply - expurgedBalance;                 
    }

    function isTaxFree (address account) external view returns(bool) {
        return Wallet[account].isTaxFree;
    }

    function isExcludedFromBonus (address account) external view returns (bool) {
        return Wallet[account].isNonBonus;
    }

    function _excludeFromBonus (address account) internal {
        uint256 _bonus = _getBonus(account); 
        Wallet[account].balance     += _bonus;
        Wallet[goldenBonus].balance -= _bonus;
        Wallet[account].isNonBonus   = true;
        _noBonus.push(account);
    }

    function _includeInBonus (address account) internal {
        (uint256 _adjustedBonus, uint256 _adjustedBalance) = _shareAmount(Wallet[account].balance);
        for (uint256 i = 0; i < _noBonus.length; i++) {
            if (_noBonus[i] == account) {
                _noBonus[i] = _noBonus[_noBonus.length - 1];
                Wallet[account].isNonBonus   = false;
                Wallet[account].balance      = _adjustedBalance;
                Wallet[goldenBonus].balance += _adjustedBonus;
                _noBonus.pop();
                break;
            }
        }
    }
//   ======================================
//             Support  Functions                  
//   ======================================
    function _sendAndFreeze (address _sender, address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) internal {
        _amountToFreeze *= (10  **_decimals);

        require(!Wallet[_sender].isLocked || _sender == corporateAssets,        "Sender wallet is locked");
        require(!Wallet[_recipient].isLocked && !Wallet[_recipient].isInternal, "Recipient is blocked");
        require(balanceOf(_sender) >= _amountToFreeze,                          "Balance insufficient");
        require(_freezeDuration >= 180 && _freezeDuration <= 1095,              "Freeze duration invalid");

        if (autoLiquidity) {_beforeTokenTransfer(_sender, _recipient, _amountToFreeze);}

        (uint256 bonusSlice, uint256 balanceSlice)  = _shareAmount(_amountToFreeze);

        if (_sender == corporateAssets) {
            Wallet[_sender].balance     -= _amountToFreeze;
            Wallet[goldenBonus].balance += bonusSlice; 
        } else {
            Wallet[_sender].balance     -= balanceSlice;
        }
        _freezeAssets (_recipient, balanceSlice, _freezeDuration);
    }

    function _freezeAssets (address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) internal {
        uint48 _currentRelease;                                                                                               
        uint48 _freezeTime = uint48((block.timestamp + _freezeDuration * 86400) / 86400);     
        uint48 _nextRelease = Wallet [_recipient].headSpecialAssets;

        if (_nextRelease == 0 || _freezeTime < _nextRelease ) { 
           Wallet [_recipient].headSpecialAssets               = _freezeTime;
           specialAssets [_recipient][_freezeTime].balance     = _amountToFreeze;
           specialAssets [_recipient][_freezeTime].releaseTime = _nextRelease;
           return; 
        }

        while (_nextRelease != 0 && _freezeTime > _nextRelease ) {
            _currentRelease    = _nextRelease;
            _nextRelease = specialAssets [_recipient][_currentRelease].releaseTime;
        }

        if (_freezeTime == _nextRelease) {
            specialAssets [_recipient][_nextRelease].balance += _amountToFreeze; 
            return;
        }

        specialAssets [_recipient][_currentRelease].releaseTime = _freezeTime;
        specialAssets [_recipient][_freezeTime].balance         = _amountToFreeze;
        specialAssets [_recipient][_freezeTime].releaseTime     = _nextRelease;
    }

    function _attenuateImpulse (uint256 numTokensToLiquidity) internal {

        _tradingTrack.buyingStack -= numTokensToLiquidity;
        numTokensToLiquidity      *= 2;

        if (Wallet[regulatoryFunds].balance >= numTokensToLiquidity) {
            Wallet[regulatoryFunds].balance -= numTokensToLiquidity;      
            Wallet[address(this)].balance   += numTokensToLiquidity;
            _increaseLiquidity(numTokensToLiquidity);
            _tradingTrack.lastTxnType        = 5;
            _tradingTrack.needAttenuation    = false;
        }
        else {
            Wallet[address(this)].balance += Wallet[regulatoryFunds].balance;
            delete Wallet[regulatoryFunds];
            delete _tradingTrack;
            isAdjustable  = false;
        }
    }
//   ======================================
//            Manageable Functions                    
//   ======================================

    function shareCorporateAssets (address _beneficiary, uint256 _amountToShare) external  onlyRole(Contract_Manager) {
        _sendAndFreeze(corporateAssets, _beneficiary, _amountToShare, 720);   
        emit CorporateAssetsShared (_msgSender(), _beneficiary, _amountToShare);
    }

    function freezeUnfitEarnings (address _unfitTrader) external onlyRole(Financial_Controller) {  
        require(Wallet[_unfitTrader].isLocked, "Account is not Blocked");
        require(!Wallet[_unfitTrader].isNonBonus, "Account without Bonus");
        uint256 _bonusUnfit = _getBonus(_unfitTrader);
        require(_bonusUnfit > 0, "There are no Earnings");
          
        _excludeFromBonus(_unfitTrader);                     // Exclude the account from future Bonus
        Wallet[_unfitTrader].isUnrewardable = true;          // Exclude the account from future Rewards
        Wallet[_unfitTrader].isLocked       = false;         // Release the account for Financial Movement 
        Wallet[_unfitTrader].balance       -= _bonusUnfit;
 
        // Half of unfit earnings is frozen for 180 days and the other half for 3 years
        uint256 _shortFreeze    = _bonusUnfit / 2;
        uint256 _longFreeze     = _bonusUnfit - _shortFreeze;

        _freezeAssets (_unfitTrader, _shortFreeze, 180);                   // Freeze half earning for 180 days
        _freezeAssets (_unfitTrader, _longFreeze, 1095);                   // Freeze the other half for 3 years
 
        emit UnfitEarningsFrozen(_msgSender(), _unfitTrader, _bonusUnfit);
    }

    function FisherAttenuation () external onlyRole(Treasury_Analyst) {
        uint256 _newTokenPrice = getTokenPrice();
        uint256 _attenuationPoint = _updateStack(_newTokenPrice);
        require (_tradingTrack.needAttenuation, "Adjust not allowed at the moment");
        _attenuateImpulse(_attenuationPoint);
    }

    function excludeFromBonus (address account) external onlyRole(Treasury_Analyst) {
        require(!Wallet[account].isNonBonus, "Account already non-bonus");
        require(account != wicksellReserves, "The Account can not be excluded");
        _excludeFromBonus(account);
        emit SetExcludedFromBonus (_msgSender(), account, true);
    }
    
    function includeInBonus (address account) external onlyRole(Compliance_Auditor) {
        require(Wallet[account].isNonBonus, "Account already receive bonus");
        require( (!Wallet[account].isInternal && account != liquidityPair), "Account can not receive bonus");
        _includeInBonus(account);
        emit SetExcludedFromBonus (_msgSender(), account, false);
    }

    function setTaxable (address account, bool status) external onlyRole(Compliance_Auditor) {
        require (!Wallet[account].isInternal,"Account cannot be modified");
        Wallet[account].isTaxFree = status;
        emit SetTaxableStatus (_msgSender(), account, status);
    }

//   ======================================
//      Ownable Functions  (OVERRIDE)             
//   ======================================

    function transferOwnership (address newOwner) public virtual override onlyOwner {
        require(!Wallet[newOwner].isLocked, "Account informed is locked");

        address oldOwner = owner();
        _transferOwnership(newOwner);

        Wallet[oldOwner].isInternal = false;
        Wallet[oldOwner].isTaxFree  = false;
        _includeInBonus(oldOwner);

        Wallet[newOwner].isInternal = true;
        Wallet[newOwner].isTaxFree  = true;
        _excludeFromBonus(newOwner);
    }
//   ======================================
//          INVESTOR Functions                   
//   ======================================

    function InvestorBurn (uint256 burnAmount) external { 
        require(isBurnable, "Contract is not burnable");
        require(!Wallet[_msgSender()].isInternal, "Internal Address can not burn");
        burnAmount = burnAmount * (10**_decimals);
        require(burnAmount <= balanceOf(_msgSender()), "Burn amount exceeds balance");
        
        // Balance without the part reffering to bonus (Bonus is never burned!!)
        if (burnAmount > Wallet[_msgSender()].balance) {burnAmount = Wallet[_msgSender()].balance; }   
        
        uint256 rewardsAmount = burnAmount / 5;
        uint256 deadAmount    = burnAmount - rewardsAmount;

        Wallet[_msgSender()].balance     -= burnAmount;
        Wallet[loyaltyRewards].balance   += rewardsAmount;
        Wallet[wicksellReserves].balance += deadAmount;
        
        if (_tokensSupply - Wallet[wicksellReserves].balance <= _minimumSupply ) {
            isBurnable = false;
        }

        emit TokensBurnt (_msgSender(), burnAmount);  
    }
    
    function ClaimLoyaltyRewards () external { 
        require (!Wallet[_msgSender()].isNonBonus && !Wallet[_msgSender()].isLocked &&
                 !Wallet[_msgSender()].isUnrewardable,"Not eligible for rewards");
        require ( Wallet[_msgSender()].nextMilestone <= block.timestamp, "Rewards are not available yet"); 

        uint256 releasedRewards = (_getBonus(_msgSender()) * Wallet[loyaltyRewards].balance) / Wallet[goldenBonus].balance;
        (uint256 bonusSlice, uint256 balanceSlice) = _shareAmount(releasedRewards);

        Wallet[_msgSender()].balance       +=  balanceSlice;
        Wallet[goldenBonus].balance        +=  bonusSlice;

        Wallet[loyaltyRewards].balance     -= releasedRewards;
        Wallet[_msgSender()].isUnrewardable = true;

        emit RewardsClaimed (_msgSender(), releasedRewards);  
    }

    function LoyaltyRewardsAvailable (address account) external view returns (uint256) { 
     
        if (Wallet[account].isNonBonus || Wallet[account].isLocked || 
            Wallet[account].isUnrewardable || Wallet[account].nextMilestone > block.timestamp) {return 0;} 

        uint256 availableRewards = (_getBonus(account) * Wallet[loyaltyRewards].balance) / Wallet[goldenBonus].balance;
        return availableRewards;
    }

    function SendAndFreeze (address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) external {
        _sendAndFreeze(_msgSender(), _recipient, _amountToFreeze, _freezeDuration);                                                                                               
        emit  AssetsSentAndFrozen(_recipient, _freezeDuration, _amountToFreeze);
    }

    function ReleaseSpecialAssets () external {
        uint256 _frozenAmount;
        uint48  _nextRelease = Wallet [_msgSender()].headSpecialAssets;
        uint48  _currentTime = uint48(block.timestamp/86400);
        uint48  _currentNode;
        require(_nextRelease != 0 && _currentTime > _nextRelease, "No assets to release");   

        while (_nextRelease != 0 && _currentTime > _nextRelease) {
               _frozenAmount += specialAssets [_msgSender()][_nextRelease].balance;
               _currentNode   = _nextRelease;
               _nextRelease   = specialAssets [_msgSender()][_currentNode].releaseTime;
                delete specialAssets [_msgSender()][_currentNode];
        }

        Wallet [_msgSender()].headSpecialAssets = _nextRelease;

        (uint256 bonusSlice, uint256 balanceSlice) = _shareAmount(_frozenAmount);
        Wallet[_msgSender()].balance               +=  balanceSlice;
        Wallet[goldenBonus].balance                +=  bonusSlice;

        emit SpecialAssetsReleased(_msgSender(),_frozenAmount);
    }

    function SpecialAssetsBalance (address _recipient) external view returns (uint256 _unfrozenAmount, uint256 _frozenAmount, uint256 _futureBonus) {
        uint48 _currentTime = uint48(block.timestamp/86400);    
        uint48 _nextRelease = Wallet [_recipient].headSpecialAssets;
        uint48 _currentNode;

        while (_nextRelease != 0 ) {
             if (_currentTime > _nextRelease) {
              _unfrozenAmount += specialAssets [_recipient][_nextRelease].balance;
             } else {
              _frozenAmount   += specialAssets [_recipient][_nextRelease].balance;  
             }
              _currentNode     = _nextRelease;
              _nextRelease     = specialAssets  [_recipient][_currentNode].releaseTime;
        }
        
        _futureBonus = (Wallet[goldenBonus].balance * (_frozenAmount + _unfrozenAmount)) / _bonusBalances();

        _frozenAmount   /= (10 ** _decimals);
        _unfrozenAmount /= (10 ** _decimals);
        _futureBonus    /= (10 ** _decimals);

    }

    function SpecialAssetsNextRelease (address _recipient) external view returns (uint48 _daysToRelease, uint256 _valueToRelease) {
        uint48 _nextRelease = Wallet [_recipient].headSpecialAssets * 86400;
        require (_nextRelease > 0, "There are no frozen assets" ); 
        require (block.timestamp < _nextRelease, "Already have assets released"); 
        
        _daysToRelease  = uint48((_nextRelease - block.timestamp) / 86400);
        _valueToRelease = specialAssets [_recipient][_nextRelease].balance;
    }
}
//**********************************//
//     S Y M P L E X I A  CONTRACT
//**********************************//
contract SymplexiaToken is  Taxable {

   // _projectFundsVault
   // _contingencyVault
   // _liquidityVault
   // swapRouterAddress

    constructor ()  ERC20("Symplexia Labs", "SWH82") BaseToken ( 
                    0xE0674e01Fef1Da05b10BC09cEF93e5d9C38eCfef,    
                    0xa39d7Ca2e433164bf54Aad3Ed8d76E794746F3DA,    
                    0xe3d3fb37b12A1C7C984f7e213Bd199019683ea9A,    
                    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)    
                    { 	}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Context.sol";

abstract contract BasicAccessControl is Context {
    struct RoleData {
        mapping(address => bool) members;
        uint8 adminRole;
    }

    mapping(uint8 => RoleData) private _roles;

    event RoleAdminChanged (uint8 indexed role, uint8 indexed previousAdminRole, uint8 indexed newAdminRole);
    event RoleGranted (uint8 indexed role, address indexed account, address indexed sender);
    event RoleRevoked (uint8 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(uint8 role) {
        require(hasRole(role, _msgSender()), "Caller has not the needed Role");
        _;
    }

    function hasRole(uint8 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function getRoleAdmin(uint8 role) public view returns (uint8) {
        return _roles[role].adminRole;
    }

    function grantRole(uint8 role, address account) public virtual onlyRole (getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(uint8 role, address account) public virtual onlyRole (getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(uint8 role, address account) public virtual {
         require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _setupRole(uint8 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(uint8 role, uint8 adminRole) internal virtual {
        uint8 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(uint8 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(uint8 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.10;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.10;

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

pragma solidity ^0.8.10;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.10;

import "./Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.10;

import "./IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}