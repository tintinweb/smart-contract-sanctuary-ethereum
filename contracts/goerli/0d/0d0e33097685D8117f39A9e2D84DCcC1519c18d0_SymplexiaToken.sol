//SPDX-License-Identifier: MIT

/*
/ This code was developed to support the distribution of shares of The Symplexia Labs, 
/ so it contains a set of monetary concepts that support the company's business development. 
/ In particular, some monetary reserves were created (Wicksell Reserves and Regulatory Funds) 
/ that are linked to the WicksellBurn and FisherAttenuation methods, among others. These   
/ methods were named in tribute to two brilliant economists related to monetary concepts.
/ If you want to know more about Knut Wicksell and his influence in the monetary concepts 
/ follow this link https://en.wikipedia.org/wiki/Knut_Wicksell. The same way, if you want to
/ know more about Irving Fisher follow this link https://en.wikipedia.org/wiki/Irving_Fisher.
*/

pragma solidity ^0.8.11;

import "./BaseToken.sol";
import "./PausableUpgradable.sol";
import "./BasicAccessControl.sol";

//    Interfaces   

import "./ILiquidityVault.sol";
import "./ISalesVault.sol";

//**********************************//
//        A D J U S T A B L E   
//**********************************//

abstract contract Adjustable is BasicAccessControl, Pausable, BaseToken {
    using SymplexiaLib for SymplexiaLib.InventoryStorage;

    bool      public   allowSecurityPause;
    bool      internal isAdjustable;

    event NumTokensToLiquidityUpdated(address authorizer, uint256 _liquidityThreshold);
    event MaxTokensPerTxUpdated(address authorizer, uint256 _maxTokensPerTx);
    event VaultUpdated(address authorizer, uint8 id, address liquidityVault);
    event EfficiencyFactorUpdated (address authorizer, uint16 _newValue);

//   ======================================
//             Initialize Function             
//   ======================================

    function _Adjustable_init () internal initializer { 

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

       isAdjustable          = true;
       allowSecurityPause    = true;
       _Pausable_init (); 
    }

//   ======================================
//             Internal Functions             
//   ======================================
    function _setEfficiencyFactor (uint16 _newFactor) internal {
        efficiencyFactor       = _newFactor;
        reducedLiquidityFee    = efficiencyFactor / 2;      
        reducedBonusFee        = efficiencyFactor;
        reducedProjectFee      = efficiencyFactor / 2;              
        _liquidityThreshold    = Inventory.tokensSupply / (efficiencyFactor * 10); 	 
    }

    function _setVault (address _oldVault,address _newVault) internal {
        require (Inventory.Basis[_newVault].balance == 0,   "New vault not empty");

        Inventory.setInternalStatus (_newVault, false);
        Inventory.Basis[_newVault].balance  = Inventory.Basis[_oldVault].balance;
        Inventory.Basis[_oldVault].balance  = 0;
        Inventory.Basis[_oldVault].accType  = Ordinary;
        _oldVault                           = _newVault; 
    }


//   ======================================
//           Parameters Functions                    
//   ======================================

    function setEfficiencyFactor (uint16 _newValue) external onlyRole(Financial_Controller) {
        require (_newValue >= 150 && _newValue <= 250, "Thresholds Invalid");
        _setEfficiencyFactor (_newValue);
        emit EfficiencyFactorUpdated (_msgSender(), _newValue);
    }

    function setSpecialAccount (address _account, uint8 _newType) external onlyRole(Contract_Manager) {
        require ( Inventory.Basis[_account].accType  == Ordinary && 
                 (_newType == Contributor || _newType == Partner), "Invalid Type");
        Inventory.Basis[_account].accType =  _newType;
        if (_newType == Partner) { Inventory.partnersList.push(_account); }
    }

    function setProjectVault (address _newVault) external onlyRole(Contract_Manager) {
        _setVault(projectFundsVault, _newVault);
        emit VaultUpdated(_msgSender(), Project, _newVault);
    } 

    function setContingencyVault (address _newVault) external onlyRole(Contract_Manager) {
        _setVault(contingencyFundsVault, _newVault);
        emit VaultUpdated(_msgSender(), Contingency, _newVault);
    } 

    function setLiquidityVault (address _newVault) external onlyRole(Contract_Manager) {
        // Require "Liquidity Vault" to be Initialized
        require (ILiquidityVault(_newVault).baseToken() == address(this), "Vault not Linked");
        require (ILiquidityVault(_newVault).isInitialized(), "Vault not Initialized");
        _setVault(liquidityVault, _newVault);
        
        _updateLiquidityPair();
        emit VaultUpdated(_msgSender(), Liquidity, _newVault);
    } 
      
    function authorizeDealer (address _newVault, uint256 _salesAmount) external onlyRole(Contract_Manager) {
        // Require "Sales Vault" to be linked to this contract
        require (ISalesVault(_newVault).baseToken() == address(this),"Vault not Linked");
        _setVault(authorizedDealer, _newVault);
        
        _salesAmount *= (10**_decimals);
        _salesAmount  = ( _salesAmount <= balanceOf(_msgSender()) ? _salesAmount :  balanceOf(_msgSender()) );
       
        Inventory.Basis[authorizedDealer].balance += _salesAmount;
        _setupRole(Distributor_Agent, authorizedDealer);

        emit VaultUpdated(_msgSender(), 4, authorizedDealer);
    }
 
//   ======================================
//           Contingency Functions                    
//   ======================================

  // Called by the Compliance Auditor on emergency, allow begin or end an emergency stop
    function setSecurityPause (bool isPause) external onlyRole(Compliance_Auditor) {
        if (isPause)  {
            require (allowSecurityPause, "Pause not allowed.");
            _pause();
        } else {
            _unpause();  
        }
    }
 
  // Called by the Financial Controller to disable ability to begin or end an emergency stop
    function disableContingencyFeature() external onlyRole(Financial_Controller)  {
        allowSecurityPause = false;
    }

//   ======================================
//           Information Functions                    
//   ====================================== 

    function liquidityThreshold () external view returns (uint256) {
        return _liquidityThreshold;
    }

    function getTokenPrice () public view returns (uint256) { 
        return ILiquidityVault(liquidityVault).getTokenPrice();
    }
    
    function maxWalletBalance () external pure returns (uint256) { 
        return _maxWalletBalance;
    }
}
//**********************************//
//    F L O W - F L E X I B L E
//**********************************//
abstract contract  FlowFlexible is Adjustable {
    using SymplexiaLib for SymplexiaLib.InventoryStorage;

    event WarningListUpdated     (address authorizer, address _user, bool _status);
 
    function _getDynamicFee (address account, uint256 sellAmount) internal returns (uint256 dynamicFee) {
         
        uint256 reduceFee;
        uint256 sellQuocient; 
        uint256 reduceFactor;

        dynamicFee = Inventory.Basis[account].balance * maxDynamicFee * efficiencyFactor / Inventory.tokensSupply;
       
        if (dynamicFee > maxDynamicFee) {dynamicFee = maxDynamicFee;}
        if (dynamicFee < minDynamicFee) {dynamicFee = minDynamicFee;}
        
        if (Inventory.Basis[account].lastTxn + _sellRange < block.timestamp) {
            sellQuocient = (sellAmount * tenK) / Inventory.Basis[account].balance;
            reduceFactor = (sellQuocient > 1000) ? 0 : (1000 - sellQuocient);
            reduceFee    = (reduceFactor * 30) / 100;
            dynamicFee  -= reduceFee;
        }

        Inventory.Basis[account].lastTxn = uint48(block.timestamp);
    }

    function setNextMilestone (address account, uint256 txAmount) internal {
        uint256 elapsedTime  = _loyaltyRange + block.timestamp - Inventory.Basis[account].nextMilestone;
        uint256 adjustedTime = ( elapsedTime * Inventory.Basis[account].balance) / ( Inventory.Basis[account].balance + txAmount ); 
        Inventory.Basis[account].nextMilestone = uint48(block.timestamp + _loyaltyRange - adjustedTime);
        Inventory.Basis[account].lastTxn = uint48(block.timestamp);
    }
//   ======================================
//            Manageable Functions                    
//   ======================================
    function setWarningList (address _markedAccount, bool _status) external onlyRole(Treasury_Analyst) {
        require (Inventory.Basis[_markedAccount].accType != Internal, "Account immutable"); 
        Inventory.Basis[_markedAccount].isLocked = _status;
        if ( _status = true ) Inventory.Basis[_markedAccount].lastTxn = uint48(block.timestamp);
        emit WarningListUpdated(_msgSender(), _markedAccount, _status);
    }

    function WicksellBurn () external onlyRole(Treasury_Analyst) {
        Inventory.wicksellBurn (_msgSender()); 
    } 
//   ======================================
//            Investor Functions                    
//   ======================================

    function unlockMyAccount () external {
        require (Inventory.Basis[_msgSender()].accType != Internal && Inventory.Basis[_msgSender()].isLocked, "Not allowed");
        require (Inventory.Basis[_msgSender()].lastTxn + _releaseRange < block.timestamp,    "Not allowed yet"); 
        Inventory.Basis[_msgSender()].isLocked = false;
        emit WarningListUpdated(_msgSender(), _msgSender(), false);
    } 
}
//**********************************//
//   A U T O L I Q U I D I T Y
//**********************************//
abstract contract AutoLiquidity is Adjustable {

    address             internal   _slotReserved_2;
    address             public      liquidityPair;
    bool                public      autoLiquidity;
    bool                internal   _slotReserved_3;
    
    event AutoLiquidityIssued(uint256 tradedTokens, uint256 tradedCoins);    
    event CoinsTransferred(address recipient, uint256 amountCoins);
    event AutoLiquiditySet (address authorizer, bool _status);

//   ======================================
//     To receive Coins              
//   ======================================

    receive() external payable {}                      			

//   ======================================
//          Internal Functions                    
//   ====================================== 

    function _autoLiquidity(uint256 _amount) internal {
        Inventory.Basis[address(this)].balance      -= _amount;
        Inventory.Basis[liquidityVault].balance     += _amount;    
        (uint256 tradedTokens, uint256 tradedCoins)  = ILiquidityVault(liquidityVault).autoLiquidity(_amount);

        emit AutoLiquidityIssued(tradedTokens, tradedCoins);
    }
//   ======================================
//          External Functions                    
//   ======================================   

    function transferCoins () external onlyRole(Treasury_Analyst) {
        require(address(this).balance > 0, "Zero Balance");
        uint256 amountToTransfer = address(this).balance;
        payable(liquidityVault).transfer(amountToTransfer);
        emit CoinsTransferred(liquidityVault, amountToTransfer);
    }

    function enableAutoLiquidity () external onlyRole(Treasury_Analyst) {
        // Require "Liquidity Vault" to be Initialized
        require (!autoLiquidity, "AutoLiquidity Already Enabled");
        require (liquidityVault != address(0), "Liquidity Vault not Informed");
        require (ILiquidityVault(liquidityVault).isInitialized(), "Vault not Initialized");
        if (Inventory.Basis[address(this)].balance >= _liquidityThreshold) { 
            _autoLiquidity(_liquidityThreshold);
        }
        autoLiquidity = true;
        emit AutoLiquiditySet (_msgSender(), autoLiquidity);
    }

    function disableAutoLiquidity () external onlyRole(Treasury_Analyst) {
        require (autoLiquidity, "Auto Liquidity Already Disabled");
        if (Inventory.Basis[address(this)].balance >= _liquidityThreshold) { 
            _autoLiquidity(_liquidityThreshold);
        }
        autoLiquidity = false;
        emit AutoLiquiditySet (_msgSender(), autoLiquidity);
    }

    function manualLiquidity () external onlyRole(Treasury_Analyst) {
        require (Inventory.Basis[address(this)].balance >= _liquidityThreshold, "Below liquidity threshold"); 
            _autoLiquidity(_liquidityThreshold);
    }
}
//**********************************//
//   T   A   X   A   B   L   E 
//**********************************//
abstract contract Taxable is  FlowFlexible, AutoLiquidity {
    using Address      for address;
    using SymplexiaLib for SymplexiaLib.InventoryStorage;

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

    event FeesTransfered (uint256 Liquidity, uint256 Contingency, uint256 Project, uint256 Bonus, uint256 LoyaltyRewards, uint256 WicksellReserves, uint256 Burn );
    event SetTaxableStatus (address authorizer, address account, bool status);
//   ======================================
//             Initialize Function             
//   ======================================

    function _Taxable_init () internal initializer { 

        Inventory.Basis[corporateAssets].balance = _maxWalletBalance * 10;
        Inventory.Basis[regulatoryFunds].balance = _maxWalletBalance * 5;
        Inventory.Basis[_msgSender()].balance    = Inventory.tokensSupply - Inventory.Basis[corporateAssets].balance - Inventory.Basis[regulatoryFunds].balance;

        Inventory.setInternalStatus (owner(),               false);
        Inventory.setInternalStatus (address(this),         false);
        Inventory.setInternalStatus (projectFundsVault,     false);
        Inventory.setInternalStatus (contingencyFundsVault, false);
        Inventory.setInternalStatus (address(0),            true);
        Inventory.setInternalStatus (wicksellReserves,      true);
        Inventory.setInternalStatus (goldenBonus,           true);
        Inventory.setInternalStatus (loyaltyRewards,        true);
        Inventory.setInternalStatus (dividendReserves,      true);
        Inventory.setInternalStatus (corporateAssets,       true);
        Inventory.setInternalStatus (regulatoryFunds,       true); 

        Inventory.includeInBonus(_msgSender(),wicksellReserves);   // Additional Bonus generation strategy in the burning process
    
        // This factor calibrates the contract performance and the values of reduced fees 

        _setEfficiencyFactor (200);
        
        emit Transfer(address(0), _msgSender(), Inventory.tokensSupply);
    } 

//  =======================================
//        IERC20 Functions (OVERRIDE)              
//   ======================================

    function balanceOf (address account) public view override returns (uint256) {
        return Inventory.balanceOf (account);
    }
//   ======================================
//          BEGIN Function _transfer   
//   ======================================

    function _transfer ( address sender, address recipient, uint256 amount ) internal override whenNotPaused {
        require(!Inventory.Basis[sender].isLocked && 
               (!Inventory.Basis[recipient].isLocked || recipient == dividendReserves), "Address locked");
          
        require(amount > 0 && balanceOf(sender) >= amount, "Insufficient balance"); 
    
        if (Inventory.Basis[sender].accType != Internal  || sender == liquidityPair || recipient == liquidityPair) {
            require(amount <= _maxTokensPerTx, "Amount exceeds limit"); 
        }

        if (Inventory.Basis[recipient].accType != Internal )  {
            require( balanceOf(recipient) + amount <= _maxWalletBalance, "Exceeds limit");
        }      

        //  Indicates that all fees should be deducted from transfer
        bool applyFee = (Inventory.Basis[sender].isTaxFree || Inventory.Basis[recipient].isTaxFree) ? false:true;

        if (autoLiquidity && !ILiquidityVault(liquidityVault).isAddingLiquidity()) {_beforeTokenTransfer(sender, recipient, amount);}

        _tokenTransfer(sender, recipient, amount, applyFee); 
  
    }
//   ==========================================
//     BEGIN Function  __beforeTokenTransfer     
//   ==========================================

    function _beforeTokenTransfer (address sender, address recipient, uint256 amount) internal { 
        uint256 _newTokenPrice = getTokenPrice();

        if (_newTokenPrice == 0) {return;}

        if (isAdjustable) {
            uint256 _attenuationPoint =  Inventory.updateStack(liquidityPair, _newTokenPrice);

            Inventory.tradingTrack.lastTokenPrice = _newTokenPrice;
            Inventory.tradingTrack.lastTxnValue   = amount;

            if (Inventory.tradingTrack.needAttenuation && sender != liquidityPair)  {_attenuateImpulse(_attenuationPoint);}
            else if (sender    == liquidityPair)                {Inventory.tradingTrack.lastTxnType = 1;}
            else if (recipient == liquidityPair)                {Inventory.tradingTrack.lastTxnType = 2;}
            else                                                {Inventory.tradingTrack.lastTxnType = 0;}

            return;
        }

        if (sender != liquidityPair && Inventory.Basis[address(this)].balance >= _liquidityThreshold) { 
            _autoLiquidity(_liquidityThreshold);
        }
    }
//   ======================================
//      BEGIN Function _tokenTransfer                   
//   ======================================

//   This Function is responsible for taking all fees, if 'applyFee' is true
    function _tokenTransfer (address sender, address recipient, uint256 tAmount, bool applyFee) internal override {

        BonusInfo  memory bonus;
        AmountInfo memory amount;

        uint256 transferAmount;
        uint256 totalFees;
        uint256 deflatFee;
        uint256 WicksellReservesFee;
        uint256 loyaltyRewardsFee;
        uint256 dynamicFee;

        // Calculate the Outflow values distribution (Raw Balance and Bonus)

        bonus.Balance  = Inventory.getBonus(sender);
        bonus.Outflow  = bonus.Balance > 0 ? (bonus.Balance * tAmount) / balanceOf(sender) : 0;
        amount.Outflow = tAmount - bonus.Outflow;

        // Collect all Fees and Bonus 

        if (applyFee) {
            if (sender == liquidityPair) {
               totalFees = _calcFees (tAmount, 0, 0, 0, 0, 0, bonusFee, projectFee); 
            } else if (recipient == liquidityPair) {
                    uint16  salesBonusFee = (Inventory.Basis[goldenBonus].balance == bonus.Balance)? 0 : reducedBonusFee;
                    dynamicFee = _getDynamicFee(sender, tAmount);

                    if (Inventory.isBurnable) {
                        loyaltyRewardsFee     = dynamicFee < (2 * minDynamicFee) ? dynamicFee : (2 * minDynamicFee);
                        dynamicFee           -= loyaltyRewardsFee;
                        deflatFee             = dynamicFee / 3;
                        WicksellReservesFee   = dynamicFee - deflatFee;
                    } else {loyaltyRewardsFee = dynamicFee;}

                    totalFees = _calcFees (tAmount, liquidityFee, deflatFee, WicksellReservesFee, loyaltyRewardsFee,
                                           contingencyFee, salesBonusFee, reducedProjectFee); 
            } else {
                    totalFees = _calcFees (tAmount, reducedLiquidityFee, 0, 0, minDynamicFee,
                                           contingencyFee, reducedBonusFee, reducedProjectFee); 
            }
         }

        transferAmount = tAmount - totalFees;

        // Calculate the Inflow values distribution (Raw Balance and Bonus)
        (bonus.Inflow, amount.Inflow) = (Inventory.Basis[recipient].isNonBonus) ? (0, transferAmount) : Inventory.shareAmount(transferAmount);

       // Update of sender and recipient balances 
        if (!Inventory.Basis[recipient].isLocked) {setNextMilestone(recipient, amount.Inflow);}

        Inventory.Basis[sender].balance    -= amount.Outflow;
        Inventory.Basis[recipient].balance += amount.Inflow;

         // Update the Bonus Shares 
        Inventory.Basis[goldenBonus].balance =  Inventory.Basis[goldenBonus].balance + bonus.Inflow - bonus.Outflow; 

        emit Transfer(sender, recipient, tAmount);
    }
//   ======================================
//     BEGIN Function  _calcFees     
//   ======================================
    function _calcFees (uint256 _tAmount, uint256 _liquidityFee, 
                        uint256 _deflatFee, uint256 _wicksellFee, 
                        uint256 _loyaltyRewardsFee, uint256 _contingencyFee, 
                        uint256 _bonusFee, uint256 _projectFee) private returns (uint256 totalFees) {
       
        FeesInfo memory fees;

        fees.Liquidity            = (_tAmount * _liquidityFee) / tenK;
        fees.Burn                 = (_tAmount * _deflatFee) / tenK;
        fees.WicksellReserves     = (_tAmount * _wicksellFee) / tenK;
        fees.LoyaltyRewards       = (_tAmount * _loyaltyRewardsFee) / tenK;
        fees.Contingency          = (_tAmount * _contingencyFee) / tenK;
        fees.Bonus                = (_tAmount * _bonusFee) / tenK;
        fees.Project              = (_tAmount * _projectFee) / tenK;

        Inventory.Basis[address(this)].balance          +=  fees.Liquidity; 
        Inventory.Basis[contingencyFundsVault].balance  +=  fees.Contingency;
        Inventory.Basis[projectFundsVault].balance      +=  fees.Project;
        Inventory.Basis[goldenBonus].balance            +=  fees.Bonus;
        Inventory.Basis[loyaltyRewards].balance         +=  fees.LoyaltyRewards;
        if (Inventory.isBurnable) {
            Inventory.Basis[wicksellReserves].balance   +=  fees.WicksellReserves; 
            Inventory.tokensSupply                      -=  fees.Burn;
            if (Inventory.tokensSupply - Inventory.Basis[wicksellReserves].balance <= _minimumSupply ) {
               Inventory.isBurnable = false;
            }
        }  
        emit FeesTransfered(fees.Liquidity, fees.Contingency, fees.Project, fees.Bonus, fees.LoyaltyRewards, fees.WicksellReserves, fees.Burn );
    
        totalFees = fees.Liquidity + fees.Burn + fees.WicksellReserves + fees.LoyaltyRewards + 
                    fees.Contingency + fees.Bonus + fees.Project;
    }
//   ======================================
//               RFI Functions                  
//   ======================================

    function isTaxFree (address account) external view returns(bool) {
        return Inventory.Basis[account].isTaxFree;
    }

    function isExcludedFromBonus (address account) external view returns (bool) {
        return Inventory.Basis[account].isNonBonus;
    }
        
    function DeviationAnalysis() external view returns (bool NeededAttenuation, bool WicksellReady, bool AllowBurn, bool AutoLiquidityOn) {
        NeededAttenuation =  Inventory.tradingTrack.needAttenuation;
        AllowBurn         =  Inventory.isBurnable;
        AutoLiquidityOn   =  autoLiquidity;
        WicksellReady     = (Inventory.Basis[wicksellReserves].balance > 0 && 
                             Inventory.Basis[wicksellReserves].lastTxn + 30 days < block.timestamp);
    }
//   ======================================
//             Support  Functions                  
//   ======================================
    function _attenuateImpulse (uint256 numTokensToLiquidity) private {

        Inventory.tradingTrack.buyingStack -= numTokensToLiquidity;
        numTokensToLiquidity               *= 2;

        if (Inventory.Basis[regulatoryFunds].balance >= numTokensToLiquidity) {
            Inventory.Basis[regulatoryFunds].balance -= numTokensToLiquidity;      
            Inventory.Basis[address(this)].balance   += numTokensToLiquidity;
            _autoLiquidity(numTokensToLiquidity);
            Inventory.tradingTrack.lastTxnType        = 5;
            Inventory.tradingTrack.needAttenuation    = false;
        }
        else {
            Inventory.Basis[address(this)].balance += Inventory.Basis[regulatoryFunds].balance;
            delete Inventory.Basis[regulatoryFunds];
            delete Inventory.tradingTrack;
            isAdjustable  = false;
        }
    }

    function _updateLiquidityPair () internal override {
        liquidityPair = ILiquidityVault(liquidityVault).liquidityPair();
        Inventory.setInternalStatus (liquidityPair,false);
        Inventory.Basis[liquidityPair].isTaxFree = false;
    }
//   ======================================
//            Manageable Functions                    
//   ======================================

    function updateLiquidityPair () external onlyRole(Contract_Manager) {
        require (ILiquidityVault(liquidityVault).baseToken() == address(this), "Vault not Linked");
        _updateLiquidityPair ();
    }

    function shareCorporateAssets (address _beneficiary, uint256 _amountToShare) external  onlyRole(Contract_Manager) {
        require(Inventory.Basis[_beneficiary].accType == Contributor || 
                Inventory.Basis[_beneficiary].accType == Partner, "Invalid Account");
        
        uint64 _freezeDuration;       
        if      (Inventory.Basis[_beneficiary].accType == Contributor) { _freezeDuration =  550; }
        else if (Inventory.Basis[_beneficiary].accType == Partner)     { _freezeDuration = 1095; } 

        Inventory.sendAndFreeze(corporateAssets, _beneficiary, _amountToShare, _freezeDuration); 
    }

    function shareDividends () external onlyRole(Financial_Controller) { 
        require(Inventory.Basis[dividendReserves].balance > 0,"Zero balance") ;
        Inventory.shareDividends ();
    }

    function setUnfitAccount (address _unfitTrader) external onlyRole(Financial_Controller) {  
        Inventory.setUnfitAccount (_msgSender(),_unfitTrader);
    }

    function FisherAttenuation () external onlyRole(Treasury_Analyst) {
        uint256 _newTokenPrice = getTokenPrice();
        uint256 _attenuationPoint = Inventory.updateStack(liquidityPair, _newTokenPrice);
        require (Inventory.tradingTrack.needAttenuation, "Not allowed now");
        _attenuateImpulse(_attenuationPoint);
    }

    function excludeFromBonus (address account) external onlyRole(Treasury_Analyst) {
        Inventory.excludeFromBonus(_msgSender(), account);
    }
    
    function includeInBonus (address account) external onlyRole(Compliance_Auditor) {
        require(Inventory.Basis[account].accType != Internal, "Cannot receive bonus");
        Inventory.includeInBonus(_msgSender(), account);
    }

    function setTaxable (address account, bool status) external onlyRole(Compliance_Auditor) {
        require (Inventory.Basis[account].accType != Internal,"Cannot be modified");
        Inventory.Basis[account].isTaxFree = status;
        emit SetTaxableStatus (_msgSender(), account, status);
    }
    
    function salesClearance () external onlyRole(Distributor_Agent) {

        uint256 clearanceAmount = Inventory.Basis[authorizedDealer].balance;
        uint256 rewardsAmount   = Inventory.Basis[loyaltyRewards].balance / 10;
        rewardsAmount           = (rewardsAmount > clearanceAmount ? clearanceAmount : rewardsAmount);
        uint256 wicksellAmount  = clearanceAmount - rewardsAmount;

        Inventory.Basis[authorizedDealer].balance = 0;
        Inventory.Basis[loyaltyRewards].balance   += rewardsAmount;
        Inventory.Basis[wicksellReserves].balance += wicksellAmount;
        
        if (Inventory.tokensSupply - Inventory.Basis[wicksellReserves].balance <= _minimumSupply ) {
            Inventory.isBurnable = false;
        }
    }
 
//   ======================================
//      Ownable Functions  (OVERRIDE)             
//   ======================================

    function transferOwnership (address newOwner) public virtual override onlyOwner {
        require(!Inventory.Basis[newOwner].isLocked && Inventory.Basis[newOwner].balance == 0, "Not allowed");
        
        address oldOwner = owner();
        _transferOwnership(newOwner);
        Inventory.Basis[oldOwner].accType = Ordinary;
        Inventory.setInternalStatus (newOwner, false);
    } 
//   ======================================
//          INVESTOR Functions                   
//   ======================================
    function InvestorBurn (uint256 burnAmount) external { 
        Inventory.investorBurn (_msgSender(), burnAmount);
     } 

    function ClaimLoyaltyRewards () external { 
        Inventory.claimLoyaltyRewards (_msgSender());
    }

    function LoyaltyRewardsAvailable (address account) external view returns (uint256 availableRewards) { 
     
        if (Inventory.Basis[account].isNonBonus || Inventory.Basis[account].isLocked || 
            Inventory.Basis[account].isUnrewardable || Inventory.Basis[account].nextMilestone > block.timestamp) {return 0;} 

        availableRewards = (Inventory.getBonus(account) * Inventory.Basis[loyaltyRewards].balance) / Inventory.Basis[goldenBonus].balance;
     }

    function SendAndFreeze (address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) external {
        require(_freezeDuration >= 180 && _freezeDuration <= 1095, "Freeze duration invalid");
        require(Inventory.Basis[_recipient].accType != Partner, "Recipient not allowed");
        Inventory.sendAndFreeze (_msgSender(), _recipient, _amountToFreeze, _freezeDuration);                                                                                               
    }

    function ReleaseFutureAssets () external {
        Inventory.releaseFutureAssets (_msgSender());
    }

    function FutureAssetsBalance (address _recipient) external view returns (uint256 _unfrozenAmount, uint256 _frozenAmount, uint256 _futureBonus) {
        return Inventory.futureAssetsBalance (_recipient);
    } 

    function FutureAssetsNextRelease (address _recipient) external view returns (uint48 _daysToRelease, uint256 _valueToRelease) {
        uint48 _nextRelease = Inventory.Basis[_recipient].headFutureAssets * 86400;
        require (_nextRelease > 0, "Zero frozen assets" ); 
        require (block.timestamp < _nextRelease, "Already have assets released"); 
        
        _daysToRelease  = uint48((_nextRelease - block.timestamp) / 86400);
        _valueToRelease = (Inventory.futureAssets[_recipient][Inventory.Basis[_recipient].headFutureAssets].balance) / (10 ** _decimals);
    }

}
//**********************************//
//     S Y M P L E X I A  CONTRACT
//**********************************//

contract SymplexiaToken is Taxable {

   function initialize (string  memory _tokenName, 
			            string  memory _tokenSymbol,
			            address _projectFundsVault, 
			            address _contingencyFundsVault ) public initializer {

        _BaseToken_init (_tokenName, _tokenSymbol, _projectFundsVault, _contingencyFundsVault);
        _Adjustable_init ();
        _Taxable_init (); 
    }   

}