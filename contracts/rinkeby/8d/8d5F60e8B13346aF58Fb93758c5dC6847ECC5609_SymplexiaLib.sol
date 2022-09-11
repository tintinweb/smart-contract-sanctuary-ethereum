//SPDX-License-Identifier: MIT


pragma solidity ^0.8.11;

import "./Address.sol";

    address  constant wicksellReserves      = 0x105457181764615639126242800330228074FEeD;
    address  constant goldenBonus           = 0x161803398874989484820458683436563811Feed;
    address  constant loyaltyRewards        = 0x241421356237309504880168872420969807fEED;
    address  constant dividendReserves      = 0x27182818284590452353602874713527FEEdCAFE;
    address  constant corporateAssets       = 0x577215664901532860606512090082402431FEED; 
    address  constant regulatoryFunds       = 0x132471795724474602596090885447809734fEEd;

    uint32  constant _baseSupply            = 1500000000;  
    uint16  constant tenK                   = 10000;
    uint16  constant bonusFee               = 450;
    uint16  constant liquidityFee           = 300;
    uint16  constant projectFee             = 200;                     
    uint16  constant contingencyFee         = 50;
    uint16  constant maxDynamicFee          = 500;
    uint16  constant minDynamicFee          = 50;
    uint8   constant _decimals              = 9;

    uint48   constant _sellRange            = 30  minutes;
    uint48   constant _loyaltyRange         = 180 days;
    uint48   constant _burnRange            = 90  days;
    uint48   constant _releaseRange         = 7   days;

    uint256  constant _minimumSupply        = ((_baseSupply * 2) / 3 ) * 10**_decimals;
    uint256  constant _maxWalletBalance     = ( _baseSupply / 100    ) * 10**_decimals;     // 1% of the total supply
    uint256  constant _maxTokensPerTx       = ( _baseSupply / 200    ) * 10**_decimals;     // 0.5% of  Tokens Supply

//  Basic Roles

    uint8 constant Contract_Manager         = 1;
    uint8 constant Financial_Controller     = 11;
    uint8 constant Compliance_Auditor       = 12;
    uint8 constant Distributor_Agent        = 13;
    uint8 constant Treasury_Analyst         = 111; 

//  Type of Accounts

    uint8 constant Ordinary                 = 0;
    uint8 constant Internal                 = 1;
    uint8 constant Contributor              = 2;
    uint8 constant Partner                  = 3;

//  Type of Vaults

    uint8 constant Project                  = 1;
    uint8 constant Contingency              = 2;
    uint8 constant Liquidity                = 3;

library SymplexiaLib {

    using  Address  for address;

    struct AccountInfo  {uint256 balance; uint48 lastTxn; uint48 nextMilestone; uint48 headFutureAssets;
                         uint8 accType; bool isTaxFree; bool isNonBonus; bool isLocked; bool isUnrewardable; }

    struct AssetsInfo   {uint256 balance; uint48 releaseTime;}

    struct TradingInfo  {uint256 buyingStack; uint256 sellingStack; uint256 lastTokenPrice;
                         uint256 lastTxnValue; uint8 lastTxnType; bool needAttenuation;
    }
	        
    struct InventoryStorage {
    	mapping (address => AccountInfo) Basis;
    	mapping (address => mapping (uint48 => AssetsInfo)) futureAssets;
        address[]   noBonusList;
        address[]   partnersList;
    	uint256     tokensSupply;
        TradingInfo tradingTrack;  
        bool        isBurnable;
    }

    event TokensBurnt            (address account,    uint256 burnAmount);
    event WicksellReservesBurned (address authorizer, uint256 burnAmount);
    event FutureAssetsReleased   (address _recipient, uint256 _amountReleased);
    event CorporateAssetsShared  (address authorizer, address beneficiary, uint256 amount);
    event UnfitAccountSet        (address authorizer, address unfitTrader, uint256 _balance);
    event SetBonusStatus         (address authorizer, address account, bool status);
    event RewardsClaimed         (address account,    uint256 amountRewards);  
    event AssetsSentAndFrozen    (address _sender,    address _recipient, uint64 _freezeDuration, uint256 _amountToFreeze);

//------------------------------------------------------------------

    function balanceOf (InventoryStorage storage self, address account) public view returns (uint256) {
        return self.Basis[account].balance + getBonus(self, account);
    }

   /***************************************************************************************
     *  NOTE:
     *  The "shareDividends" and "_partnersBalance" functions distribute 
     *  the dividends among the current Partners.  
   ****************************************************************************************/

    function partnersBalance (InventoryStorage storage self) public view returns (uint256) {
        uint256 _partnersBalance;
        uint256 _unfrozenAmount;
        uint256 _frozenAmount;

        for (uint256 i=0; i < self.partnersList.length; i++){
            (_unfrozenAmount, _frozenAmount,) = futureAssetsBalance(self, self.partnersList[i]);
            _partnersBalance += (_unfrozenAmount + _frozenAmount);
        }
        return  _partnersBalance;                 
    }

    function shareDividends (InventoryStorage storage self) public {
       uint256 _partnersBalance  = partnersBalance(self);
       uint256 _dividendReserves = self.Basis[dividendReserves].balance;
       uint256 _eligibleBalance;
       uint256 _calcDividend;
       uint256 _bonusSlice;
       uint256 _balanceSlice;
       uint256 _unfrozenAmount;
       uint256 _frozenAmount;

       for (uint256 i=0; i < self.partnersList.length; i++){
            (_unfrozenAmount, _frozenAmount,) = futureAssetsBalance (self, self.partnersList[i]);
            _eligibleBalance = _unfrozenAmount + _frozenAmount;
            _calcDividend     = (_dividendReserves * _eligibleBalance) / _partnersBalance;
            (_bonusSlice, _balanceSlice)  = shareAmount(self, _calcDividend);
            self.Basis[self.partnersList[i]].balance     +=  _balanceSlice;
            self.Basis[goldenBonus].balance              +=  _bonusSlice;
            self.Basis[dividendReserves].balance         -=  _calcDividend; 
        }
        
        if (self.Basis[dividendReserves].balance > 0 ) {
            self.Basis[wicksellReserves].balance += self.Basis[dividendReserves].balance;
            self.Basis[dividendReserves].balance = 0;
        }
    }

   /***************************************************************************************
     *  NOTE:
     *  The "getBonus", "shareAmount" and "bonusBalances" functions help to redistribute 
     *  the specified  amount of Bonus among the current holders via an special algorithm  
     *  that eliminates the need for interaction with all holders account. 
   ****************************************************************************************/   

    function bonusBalances (InventoryStorage storage self) public view returns (uint256) {
        uint256 expurgedBalance;
        for (uint256 i=0; i < self.noBonusList.length; i++){
            expurgedBalance += self.Basis[self.noBonusList[i]].balance;
        }
        return  self.tokensSupply - expurgedBalance;                 
    }

    function getBonus (InventoryStorage storage self, address account) public view returns (uint256) {
        if ( self.Basis[account].isNonBonus || self.Basis[goldenBonus].balance == 0 || self.Basis[account].balance == 0 ){
            return 0;
        } else {
            uint256 shareBonus = (self.Basis[goldenBonus].balance * self.Basis[account].balance) / bonusBalances (self);
            return  shareBonus;
        }
    }

    function shareAmount (InventoryStorage storage self, uint256 tAmount) public returns (uint256, uint256) {
        uint256 _eligibleBalance = bonusBalances(self);
        if (self.Basis[goldenBonus].balance == 0) return (0, tAmount);
        if (_eligibleBalance == 0) { 
            self.Basis[loyaltyRewards].balance += self.Basis[goldenBonus].balance;
            self.Basis[goldenBonus].balance = 0;
            return (0, tAmount);
        } 

        uint256 _bonusStock   = self.Basis[goldenBonus].balance;
        uint256 _bonusAmount  = (tAmount * _bonusStock) / (_eligibleBalance + _bonusStock);
        uint256 _rawAmount    = tAmount - _bonusAmount; 
        return (_bonusAmount, _rawAmount);
    }
//-------------------------------------------------------------------------

    function setInternalStatus (InventoryStorage storage self, address account, bool isLocked) public {
        self.Basis[account].accType        = Internal;
        self.Basis[account].isTaxFree      = true;
        self.Basis[account].isLocked       = isLocked;
        self.Basis[account].isNonBonus     = true;
        self.Basis[account].isUnrewardable = true;
        self.noBonusList.push(account);
    }
//------------------------------------------------------------------

   function investorBurn (InventoryStorage storage self, address Sender, uint256 burnAmount) public { 
        require(self.isBurnable, "Not burnable");
        require(self.Basis[Sender].accType != Internal, "Internal Address");
        burnAmount = burnAmount * (10**_decimals);
        require(burnAmount <= balanceOf(self, Sender),  "Insuficient balance");

         // Balance without the part reffering to bonus (Bonus is never burned!!)
        if (burnAmount > self.Basis[Sender].balance) {burnAmount = self.Basis[Sender].balance; }   
        
        uint256 rewardsAmount = burnAmount / 5;
        uint256 deadAmount    = burnAmount - rewardsAmount;

        self.Basis[Sender].balance           -= burnAmount;
        self.Basis[loyaltyRewards].balance   += rewardsAmount;
        self.Basis[wicksellReserves].balance += deadAmount;
        
        if (self.tokensSupply - self.Basis[wicksellReserves].balance <= _minimumSupply ) {
            self.isBurnable = false;
        }

        emit TokensBurnt (Sender, burnAmount);  
    }
//-------------------------------------------------------------------------

    function wicksellBurn (InventoryStorage storage self, address Sender) public {
        require (self.Basis[wicksellReserves].balance > 0, "Zero balance");
        require (self.Basis[wicksellReserves].lastTxn + 30 days < block.timestamp, "Time elapsed too short");
        uint256 elapsedTime  = _burnRange + block.timestamp - self.Basis[wicksellReserves].nextMilestone;
        uint256 burnAmount;
       
        if (self.isBurnable) {
            if (elapsedTime > _burnRange) { 
                 burnAmount = self.Basis[wicksellReserves].balance;                                // Balance without the part reffering to bonus
                 self.Basis[wicksellReserves].nextMilestone = uint48(block.timestamp + _burnRange);
            } else {
                 burnAmount = (self.Basis[wicksellReserves].balance * elapsedTime) / _burnRange;
            }

            self.Basis[wicksellReserves].lastTxn  = uint48(block.timestamp);
            self.Basis[wicksellReserves].balance -= burnAmount;                                    // Burn only the raw balance, without the bonus
            self.tokensSupply                    -= burnAmount;
        } else{
            uint256 _residueBurn = (self.Basis[wicksellReserves].balance + _minimumSupply) - self.tokensSupply;
            self.Basis[goldenBonus].balance += _residueBurn;
            delete self.Basis[wicksellReserves];
            self.tokensSupply = _minimumSupply;
        }

        emit WicksellReservesBurned (Sender, burnAmount);
    }
//-----------------------------------------------------------------------------

   function sendAndFreeze (InventoryStorage storage self, address _sender, address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) public {
        _amountToFreeze *= (10  **_decimals);

        require((!self.Basis[_sender].isLocked && self.Basis[_sender].accType != Internal) || 
                 _sender == corporateAssets, "Sender locked");

        require( !self.Basis[_recipient].isLocked && 
                  self.Basis[_recipient].accType != Internal, "Recipient not allowed");
                  
        require(balanceOf(self, _sender) >= _amountToFreeze,  "Balance insufficient");

        (uint256 bonusSlice, uint256 balanceSlice)  = shareAmount(self, _amountToFreeze);

        if (_sender == corporateAssets) {
            self.Basis[_sender].balance     -= _amountToFreeze;
            self.Basis[goldenBonus].balance += bonusSlice; 
        } else {
            self.Basis[_sender].balance     -= balanceSlice;
        }
        freezeAssets (self, _recipient, balanceSlice, _freezeDuration);
        emit AssetsSentAndFrozen (_sender, _recipient, _freezeDuration, _amountToFreeze);
    }
//-----------------------------------------------------------------------------

    function freezeAssets (InventoryStorage storage self, address _recipient, uint256 _amountToFreeze, uint64 _freezeDuration) public {
        uint48 _currentRelease;                                                                                               
        uint48 _freezeTime = uint48((block.timestamp + _freezeDuration * 86400) / 86400);     
        uint48 _nextRelease = self.Basis[_recipient].headFutureAssets;

        if (_nextRelease == 0 || _freezeTime < _nextRelease ) { 
           self.Basis[_recipient].headFutureAssets               = _freezeTime;
           self.futureAssets[_recipient][_freezeTime].balance     = _amountToFreeze;
           self.futureAssets[_recipient][_freezeTime].releaseTime = _nextRelease;
           return; 
        }

        while (_nextRelease != 0 && _freezeTime > _nextRelease ) {
            _currentRelease    = _nextRelease;
            _nextRelease = self.futureAssets[_recipient][_currentRelease].releaseTime;
        }

        if (_freezeTime == _nextRelease) {
            self.futureAssets[_recipient][_nextRelease].balance += _amountToFreeze; 
            return;
        }

        self.futureAssets[_recipient][_currentRelease].releaseTime = _freezeTime;
        self.futureAssets[_recipient][_freezeTime].balance         = _amountToFreeze;
        self.futureAssets[_recipient][_freezeTime].releaseTime     = _nextRelease;
    }
//-----------------------------------------------------------------------------

   function setUnfitAccount (InventoryStorage storage self, address Sender, address _unfitTrader) public {  
        require(self.Basis[_unfitTrader].isLocked, "Account not Blocked");
        require(!self.Basis[_unfitTrader].isNonBonus, "Account without Bonus");
        uint256 _bonusUnfit = getBonus(self, _unfitTrader);
        require(_bonusUnfit > 0, "Zero Earnings");
          
        excludeFromBonus(self, Sender, _unfitTrader);            // Exclude the account from future Bonus
        self.Basis[_unfitTrader].isUnrewardable = true;          // Exclude the account from future Rewards
        self.Basis[_unfitTrader].isLocked       = false;         // Release the account for Financial Movement 
        self.Basis[_unfitTrader].balance       -= _bonusUnfit;
 
        // Half of unfit earnings is frozen for 180 days and the other half for 3 years
        uint256 _shortFreeze    = _bonusUnfit / 2;
        uint256 _longFreeze     = _bonusUnfit - _shortFreeze;

        freezeAssets (self, _unfitTrader, _shortFreeze, 180);                   // Freeze half earnings for 180 days
        freezeAssets (self, _unfitTrader, _longFreeze, 1095);                   // Freeze the other half for 3 years
 
        emit UnfitAccountSet(Sender, _unfitTrader, _bonusUnfit);
    }
//-----------------------------------------------------------------------------

   function releaseFutureAssets (InventoryStorage storage self, address Sender) public {
        uint256 _frozenAmount;
        uint48  _nextRelease = self.Basis[Sender].headFutureAssets;
        uint48  _currentTime = uint48(block.timestamp/86400);
        uint48  _currentNode;
        require(_nextRelease != 0 && _currentTime > _nextRelease, "Zero releases");   

        while (_nextRelease != 0 && _currentTime > _nextRelease) {
               _frozenAmount += self.futureAssets[Sender][_nextRelease].balance;
               _currentNode   = _nextRelease;
               _nextRelease   = self.futureAssets[Sender][_currentNode].releaseTime;
                delete self.futureAssets[Sender][_currentNode];
        }

        self.Basis[Sender].headFutureAssets = _nextRelease;

        (uint256 bonusSlice, uint256 balanceSlice) = shareAmount(self, _frozenAmount);
        self.Basis[Sender].balance                +=  balanceSlice;
        self.Basis[goldenBonus].balance           +=  bonusSlice;

        emit FutureAssetsReleased(Sender, _frozenAmount);
    }
//-----------------------------------------------------------------------------

    function futureAssetsBalance (InventoryStorage storage self, address _recipient) public view returns (uint256 _unfrozenAmount, uint256 _frozenAmount, uint256 _futureBonus) {
        uint48 _currentTime = uint48(block.timestamp/86400);    
        uint48 _nextRelease = self.Basis[_recipient].headFutureAssets;
        uint48 _currentNode;

        while (_nextRelease != 0 ) {
             if (_currentTime > _nextRelease) {
              _unfrozenAmount += self.futureAssets[_recipient][_nextRelease].balance;
             } else {
              _frozenAmount   += self.futureAssets[_recipient][_nextRelease].balance;  
             }
              _currentNode     = _nextRelease;
              _nextRelease     = self.futureAssets[_recipient][_currentNode].releaseTime;
        }
        
        _futureBonus = (self.Basis[goldenBonus].balance * (_frozenAmount + _unfrozenAmount)) / bonusBalances(self);

        _frozenAmount   /= (10 ** _decimals);
        _unfrozenAmount /= (10 ** _decimals);
        _futureBonus    /= (10 ** _decimals);
    } 
//-----------------------------------------------------------------------------

    function excludeFromBonus (InventoryStorage storage self, address sender, address account) public {
        require(!self.Basis[account].isNonBonus, "Already non-bonus" );
        require(account != wicksellReserves,     "Cannot be excluded");
        uint256 _bonus = getBonus(self, account); 
        self.Basis[account].balance     += _bonus;
        self.Basis[goldenBonus].balance -= _bonus;
        self.Basis[account].isNonBonus   = true;
        self.noBonusList.push(account);
        emit SetBonusStatus (sender, account, true);
    }
//-----------------------------------------------------------------------------

    function includeInBonus (InventoryStorage storage self, address Sender, address account) public {
        require(  self.Basis[account].isNonBonus, "Already receive bonus");
        
        (uint256 _adjustedBonus, uint256 _adjustedBalance) = shareAmount(self, self.Basis[account].balance);
        for (uint256 i = 0; i < self.noBonusList.length; i++) {
            if (self.noBonusList[i] == account) {
                self.noBonusList[i] = self.noBonusList[self.noBonusList.length - 1];
                self.Basis[account].isNonBonus   = false;
                self.Basis[account].balance      = _adjustedBalance;
                self.Basis[goldenBonus].balance += _adjustedBonus;
                self.noBonusList.pop();
                break;
            }
        }

        emit SetBonusStatus (Sender, account, false);
    }
//-----------------------------------------------------------------------------
    function claimLoyaltyRewards (InventoryStorage storage self, address Sender) public { 
        require (!self.Basis[Sender].isNonBonus && !self.Basis[Sender].isLocked &&
                 !self.Basis[Sender].isUnrewardable,"Not eligible");
        require ( self.Basis[Sender].nextMilestone <= block.timestamp, "Not available yet"); 

        uint256 releasedRewards = (getBonus(self, Sender) * self.Basis[loyaltyRewards].balance) / self.Basis[goldenBonus].balance;
        (uint256 bonusSlice, uint256 balanceSlice) = shareAmount(self, releasedRewards);

        self.Basis[Sender].balance         +=  balanceSlice;
        self.Basis[goldenBonus].balance    +=  bonusSlice;

        self.Basis[loyaltyRewards].balance -= releasedRewards;
        self.Basis[Sender].isUnrewardable   = true;

        emit RewardsClaimed (Sender, releasedRewards);  
    }
//-----------------------------------------------------------------------------

    function updateStack (InventoryStorage storage self, address liquidityPair, uint256 _newTokenPrice) public returns (uint256 _attenuationPoint) {  
        _attenuationPoint = self.Basis[liquidityPair].balance / 10;

        if (self.tradingTrack.lastTxnType  > 2 ) return (_attenuationPoint) ;

        if (self.tradingTrack.lastTokenPrice != _newTokenPrice)  {
            if      (self.tradingTrack.lastTxnType == 1) {self.tradingTrack.buyingStack  += self.tradingTrack.lastTxnValue; }
            else if (self.tradingTrack.lastTxnType == 2) {self.tradingTrack.sellingStack += self.tradingTrack.lastTxnValue; }

            if (self.tradingTrack.buyingStack  >= self.tradingTrack.sellingStack) {
                self.tradingTrack.buyingStack  -= self.tradingTrack.sellingStack;
                self.tradingTrack.sellingStack  = 0;  }
            else {
                self.tradingTrack.sellingStack -= self.tradingTrack.buyingStack;
                self.tradingTrack.buyingStack   = 0;  }
        }

        self.tradingTrack.needAttenuation = (self.tradingTrack.buyingStack >= _attenuationPoint);
        self.tradingTrack.lastTxnType  = 4;
        self.tradingTrack.lastTxnValue = 0;
    }

//-----------------------------------------------------------------------------

}