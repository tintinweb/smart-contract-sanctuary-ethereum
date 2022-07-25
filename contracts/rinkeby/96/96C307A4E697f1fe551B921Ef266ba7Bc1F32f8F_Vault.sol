// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IClaim.sol";
import "./interfaces/IDownline.sol";
import "./interfaces/IToken.sol";


/**
 * @title Vault
 * @author Steve Harmeyer
 * @notice This is the Furio vault contract.
 * @dev All percentages are * 100 (e.g. .5% = 50, .25% = 25)
 */

/// @custom:security-contact [email protected]
contract Vault is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _properties.period = 86400; // PRODUCTION period is 24 hours.
        _properties.lookbackPeriods = 28; // 28 periods.
        _properties.penaltyLookbackPeriods = 7; // 7 periods.
        _properties.maxPayout = 100000 * (10 ** 18);
        _properties.maxReturn = 36000;
        _properties.neutralClaims = 13;
        _properties.negativeClaims = 15;
        _properties.penaltyClaims = 7;
        _properties.depositTax = 1000;
        _properties.depositReferralBonus = 1000;
        _properties.compoundTax = 500;
        _properties.compoundReferralBonus = 500;
        _properties.airdropTax = 1000;
        _properties.claimTax = 1000;
        _properties.maxReferralDepth = 15;
        _properties.teamWalletRequirement = 5;
        _properties.teamWalletChildBonus = 2500;
        _properties.devWalletReceivesBonuses = true;
        // Rewards percentages based on 28 day claims.
        _rates[0] = 250;
        _rates[1] = 225;
        _rates[2] = 225;
        _rates[3] = 225;
        _rates[4] = 225;
        _rates[5] = 225;
        _rates[6] = 225;
        _rates[7] = 225;
        _rates[8] = 225;
        _rates[9] = 200;
        _rates[10] = 200;
        _rates[11] = 200;
        _rates[12] = 200;
        _rates[13] = 200;
        _rates[14] = 200;
        _rates[15] = 100;
        _rates[16] = 100;
        _rates[17] = 100;
        _rates[18] = 100;
        _rates[19] = 100;
        _rates[20] = 100;
        _rates[21] = 50;
        _rates[22] = 50;
        _rates[23] = 50;
        _rates[24] = 50;
        _rates[25] = 50;
        _rates[26] = 50;
        _rates[27] = 50;
        _rates[28] = 50;
    }

    /**
     * Participant struct.
     */
    struct Participant {
        uint256 startTime;
        uint256 balance;
        address referrer;
        uint256 deposited;
        uint256 compounded;
        uint256 claimed;
        uint256 taxed;
        uint256 awarded;
        bool negative;
        bool penalized;
        bool maxed;
        bool banned;
        bool teamWallet;
        bool complete;
        uint256 maxedRate;
        uint256 availableRewards;
        uint256 lastRewardUpdate;
        uint256 directReferrals;
        uint256 airdropSent;
        uint256 airdropReceived;
    }
    mapping(address => Participant) private _participants;
    mapping(address => address[]) private _referrals;
    mapping(address => uint256[]) private _claims;

    /**
     * Stats.
     */
    struct Stats {
        uint256 totalParticipants;
        uint256 totalDeposits;
        uint256 totalDeposited;
        uint256 totalCompounds;
        uint256 totalCompounded;
        uint256 totalClaims;
        uint256 totalClaimed;
        uint256 totalTaxed;
        uint256 totalTaxes;
        uint256 totalAirdropped;
        uint256 totalAirdrops;
        uint256 totalBonused;
        uint256 totalBonuses;
    }
    Stats private _stats;

    /**
     * Properties.
     */
    struct Properties {
        uint256 period;
        uint256 lookbackPeriods;
        uint256 penaltyLookbackPeriods;
        uint256 maxPayout;
        uint256 maxReturn;
        uint256 neutralClaims;
        uint256 negativeClaims;
        uint256 penaltyClaims;
        uint256 depositTax;
        uint256 depositReferralBonus;
        uint256 compoundTax;
        uint256 compoundReferralBonus;
        uint256 airdropTax;
        uint256 claimTax;
        uint256 maxReferralDepth;
        uint256 teamWalletRequirement;
        uint256 teamWalletChildBonus;
        bool devWalletReceivesBonuses;
    }
    Properties private _properties;
    mapping(uint256 => uint256) private _rates; // Mapping of claims to rates.
    mapping(address => address) private _lastRewarded; // Mapping of last addresses rewarded in an upline.

    /**
     * Events.
     */
    event Deposit(address participant_, uint256 amount_);
    event Compound(address participant_, uint256 amount_);
    event Claim(address participant_, uint256 amount_);
    event Tax(address participant_, uint256 amount_);
    event Bonus(address particpant_, uint256 amount_);
    event Maxed(address participant_);
    event Complete(address participant_);
    event TokensSent(address recipient_, uint256 amount_);
    event AirdropSent(address from_, address to_, uint256 amount_);

    /**
     * -------------------------------------------------------------------------
     * PARTICIPANTS.
     * -------------------------------------------------------------------------
     */

    /**
     * Get participant.
     * @param participant_ Address of participant.
     * @return Participant The participant struct.
     */
    function getParticipant(address participant_) public view returns (Participant memory)
    {
        return _participants[participant_];
    }

    /**
     * -------------------------------------------------------------------------
     * STATS.
     * -------------------------------------------------------------------------
     */

    /**
     * Get stats.
     * @return Stats The contract stats.
     */
    function getStats() external view returns (Stats memory)
    {
        return _stats;
    }

    /**
     * -------------------------------------------------------------------------
     * PROPERTIES.
     * -------------------------------------------------------------------------
     */

    /**
     * Get properties.
     * @return Properties The contract properties.
     */
    function getProperties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * -------------------------------------------------------------------------
     * DEPOSITS.
     * -------------------------------------------------------------------------
     */

    /**
     * Deposit.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function deposit(uint256 quantity_) external returns (bool)
    {
        return depositFor(msg.sender, quantity_);
    }

    /**
     * Deposit with referrer.
     * @param quantity_ Token quantity.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function deposit(uint256 quantity_, address referrer_) external returns (bool)
    {
        return depositFor(msg.sender, quantity_, referrer_);
    }

    /**
     * Deposit for.
     * @param participant_ Participant address.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function depositFor(address participant_, uint256 quantity_) public returns (bool)
    {
        _addReferrer(participant_, address(0));
        if(msg.sender != addressBook.get("claim") && msg.sender != addressBook.get("swap")) {
            // The claim contract can deposit on behalf of a user straight from a presale NFT.
            require(_token().transferFrom(participant_, address(this), quantity_), "Unable to transfer tokens");
        }
        return _deposit(participant_, quantity_, _properties.depositTax);
    }

    /**
     * Deposit for with referrer.
     * @param participant_ Participant address.
     * @param quantity_ Token quantity.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function depositFor(address participant_, uint256 quantity_, address referrer_) public returns (bool)
    {
        _addReferrer(participant_, referrer_);
        if(msg.sender != addressBook.get("claim") && msg.sender != addressBook.get("swap")) {
            // The claim contract can deposit on behalf of a user straight from a presale NFT.
            require(_token().transferFrom(participant_, address(this), quantity_), "Unable to transfer tokens");
        }
        return _deposit(participant_, quantity_, _properties.depositTax);
    }

    /**
     * Internal deposit.
     * @param participant_ Participant address.
     * @param amount_ Deposit amount.
     * @param taxRate_ Tax rate.
     * @return bool True if successful.
     */
    function _deposit(address participant_, uint256 amount_, uint256 taxRate_) internal returns (bool)
    {
        require(_participants[participant_].deposited + _participants[participant_].airdropReceived + amount_ <= 5000e18, "Maximum deposit reached");
        // Get some data that will be used a bunch.
        uint256 _maxThreshold_ = _maxThreshold();
        // Checks.
        require(amount_ > 0, "Invalid deposit amount");
        require(!_participants[participant_].banned, "Participant is banned");
        require(_participants[participant_].balance < _maxThreshold_ , "Participant has reached the max payout threshold");
        // Check if participant is new.
        _addParticipant(participant_);
        // Calculate tax amount.
        uint256 _taxAmount_ = amount_ * taxRate_ / 10000;
        if(_taxAmount_ > 0) {
            amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[participant_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Calculate refund amount if this deposit pushes them over the max threshold.
        uint256 _refundAmount_ = 0;
        if(_participants[participant_].balance + amount_ > _maxThreshold_) {
            _refundAmount_ = _participants[participant_].balance + amount_ - _maxThreshold_;
            amount_ -= _refundAmount_;
        }
        // Update contract deposit stats.
        _stats.totalDeposits ++;
        _stats.totalDeposited += amount_;
        // Update participant deposit stats.
        _participants[participant_].deposited += amount_;
        // Emit Deposit event.
        emit Deposit(participant_, amount_);
        // Credit the particpant.
        _participants[participant_].balance += amount_;
        // Check if participant is maxed.
        if(_participants[participant_].balance >= _maxThreshold_) {
            _participants[participant_].maxedRate = _rewardPercent(participant_);
            _participants[participant_].maxed = true;
            // Emit Maxed event
            emit Maxed(participant_);
        }
        // Calculate the referral bonus.
        uint256 _referralBonus_ = amount_ * _properties.depositReferralBonus / 10000;
        _payUpline(participant_, _referralBonus_);
        _sendTokens(participant_, _refundAmount_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * COMPOUNDS.
     * -------------------------------------------------------------------------
     */

    /**
     * Compound.
     * @return bool True if successful.
     */
    function compound() external returns (bool)
    {
        return _compound(msg.sender, _properties.compoundTax);
    }

    /**
     * Auto compound.
     * @param participant_ Address of participant to compound.
     * @return bool True if successful.
     */
    function autoCompound(address participant_) external returns (bool)
    {
        require(msg.sender == addressBook.get("autocompound"));
        return _compound(participant_, _properties.compoundTax);
    }

    /**
     * Compound.
     * @param participant_ Address of participant.
     * @param taxRate_ Tax rate.
     * @return bool True if successful.
     */
    function _compound(address participant_, uint256 taxRate_) internal returns (bool)
    {
        _addReferrer(participant_, address(0));
        // Get some data that will be used a bunch.
        uint256 _timestamp_ = block.timestamp;
        uint256 _maxThreshold_ = _maxThreshold();
        uint256 _amount_ = _availableRewards(participant_);
        // Checks.
        require(_amount_ > 0, "Invalid compound amount");
        require(!_participants[participant_].banned, "Participant is banned");
        require(_participants[participant_].balance < _maxThreshold_ , "Participant has reached the max payout threshold");
        // Check if participant is new.
        _addParticipant(participant_);
        // Update participant available rewards
        _participants[participant_].availableRewards = 0;
        _participants[participant_].lastRewardUpdate = _timestamp_;
        // Calculate tax amount.
        uint256 _taxAmount_ = _amount_ * taxRate_ / 10000;
        if(_taxAmount_ > 0) {
            _amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[participant_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Calculate if this compound pushes them over the max threshold.
        if(_participants[participant_].balance + _amount_ > _maxThreshold_) {
            uint256 _over_ = _participants[participant_].balance + _amount_ - _maxThreshold_;
            _amount_ -= _over_;
            _participants[participant_].availableRewards = _over_;
            _participants[participant_].lastRewardUpdate = _timestamp_;
        }
        // Update contract compound stats.
        _stats.totalCompounds ++;
        _stats.totalCompounded += _amount_;
        // Update participant compound stats.
        _participants[participant_].compounded += _amount_;
        // Emit Compound event.
        emit Compound(participant_, _amount_);
        // Credit the particpant.
        _participants[participant_].balance += _amount_;
        // Check if participant is maxed.
        if(_participants[participant_].balance >= _maxThreshold_) {
            _participants[participant_].maxedRate = _rewardPercent(participant_);
            _participants[participant_].maxed = true;
            // Emit Maxed event
            emit Maxed(participant_);
        }
        // Calculate the referral bonus.
        uint256 _referralBonus_ = _amount_ * _properties.compoundReferralBonus / 10000;
        _payUpline(participant_, _referralBonus_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * CLAIMS.
     * -------------------------------------------------------------------------
     */

    /**
     * Claim.
     * @return bool True if successful.
     */
    function claim() external returns (bool)
    {
        return _claim(msg.sender, _properties.claimTax);
    }

    /**
     * Claim.
     * @param participant_ Address of participant.
     * @param taxRate_ Tax rate.
     * @return bool True if successful.
     */
    function _claim(address participant_, uint256 taxRate_) internal returns (bool)
    {
        // Get some data that will be used a bunch.
        uint256 _timestamp_ = block.timestamp;
        uint256 _amount_ = _availableRewards(participant_);
        uint256 _maxPayout_ = _maxPayout(participant_);
        _addReferrer(participant_, address(0));
        // Checks.
        require(_amount_ > 0, "Invalid claim amount");
        require(!_participants[participant_].banned, "Participant is banned");
        require(!_participants[participant_].complete, "Participant is complete");
        require(_participants[participant_].claimed < _maxPayout_, "Maximum payout has been reached");
        // Keep total under max payout.
        if(_participants[participant_].claimed + _amount_ > _maxPayout_) {
            _amount_ = _maxPayout_ - _participants[participant_].claimed;
        }
        // Check penalty claims
        if(_penaltyClaims(participant_) + 1 >= _properties.penaltyClaims) {
            // User is penalized
            _participants[participant_].penalized = true;
        }
        // Check effective claims
        if(_effectiveClaims(participant_, 1) >= _properties.negativeClaims) {
            // User is negative
            _participants[participant_].negative = true;
        }
        // Update the claims mapping.
        _claims[participant_].push(_timestamp_);
        // Update participant available rewards.
        _participants[participant_].availableRewards = 0;
        _participants[participant_].lastRewardUpdate = _timestamp_;
        // Update contract claim stats.
        _stats.totalClaims ++;
        _stats.totalClaimed += _amount_;
        // Update participant claim stats.
        _participants[participant_].claimed += _amount_;
        // Emit Claim event.
        emit Claim(participant_, _amount_);
        // Check if participant is finished.
        if(_participants[participant_].claimed >= _properties.maxPayout) {
            _participants[participant_].complete = true;
            emit Complete(participant_);
        }
        // Calculate tax amount.
        uint256 _taxAmount_ = _amount_ * taxRate_ / 10000;
        if(_taxAmount_ > 0) {
            _amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[participant_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Calculate whale tax.
        uint256 _whaleTax_ = _amount_ * _whaleTax(participant_) / 10000;
        if(_whaleTax_ > 0) {
            _amount_ -= _whaleTax_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _whaleTax_;
            // Update participant tax stats
            _participants[participant_].taxed += _whaleTax_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Pay the participant
        _sendTokens(participant_, _amount_);
        return true;
    }

    /**
     * Effective claims.
     * @param participant_ Participant address.
     * @param additional_ Additional claims to add.
     * @return uint256 Effective claims.
     */
    function _effectiveClaims(address participant_, uint256 additional_) internal view returns (uint256)
    {
        if(_participants[participant_].penalized) {
            return _properties.lookbackPeriods; // Max amount of claims.
        }
        uint256 _penaltyClaims_ = _penaltyClaims(participant_) + additional_;
        if(_penaltyClaims_ >= _properties.penaltyClaims) {
            return _properties.lookbackPeriods; // Max amount of claims.
        }
        uint256 _claims_ = _periodClaims(participant_) + additional_;
        if(_participants[participant_].negative && _claims_ < _properties.negativeClaims) {
            _claims_ = _properties.negativeClaims; // Once you go negative, you never go back!
        }
        if(_claims_ > _properties.lookbackPeriods) {
            _claims_ = _properties.lookbackPeriods; // Limit claims to make rate calculation easier.
        }
        if(_participants[participant_].startTime >= block.timestamp - (_properties.period * _properties.lookbackPeriods) && _claims_ < _properties.neutralClaims) {
            _claims_ = _properties.neutralClaims; // Before the lookback periods are up, a user can only go up to neutral.
        }
        if(_participants[participant_].startTime == 0) {
            _claims_ = _properties.neutralClaims; // User hasn't started yet.
        }
        return _claims_;
    }

    /**
     * Claims.
     * @param participant_ Participant address.
     * @return uint256 Effective claims.
     */
    function _periodClaims(address participant_) internal view returns (uint256)
    {
        return _claimsSinceTimestamp(participant_, block.timestamp - (_properties.period * _properties.lookbackPeriods));
    }

    /**
     * Penalty claims.
     * @param participant_ Participant address.
     * @return uint256 Effective claims.
     */
    function _penaltyClaims(address participant_) internal view returns (uint256)
    {
        return _claimsSinceTimestamp(participant_, block.timestamp - (_properties.period * _properties.penaltyLookbackPeriods));
    }

    /**
     * Claims since timestamp.
     * @param participant_ Participant address.
     * @param timestamp_ Unix timestamp for start of period.
     * @return uint256 Number of claims during period.
     */
    function _claimsSinceTimestamp(address participant_, uint256 timestamp_) internal view returns (uint256)
    {
        uint256 _claims_ = 0;
        for(uint i = 0; i < _claims[participant_].length; i++) {
            if(_claims[participant_][i] >= timestamp_) {
                _claims_ ++;
            }
        }
        return _claims_;
    }

    /**
     * -------------------------------------------------------------------------
     * AIRDROPS.
     * -------------------------------------------------------------------------
     */

    /**
     * Send an airdrop.
     * @param to_ Airdrop recipient.
     * @param amount_ Amount to send.
     * @return bool True if successful.
     */
    function airdrop(address to_, uint256 amount_) external returns (bool)
    {
        require(!_participants[msg.sender].banned, "Sender is banned");
        IToken _token_ = _token();
        require(_token_.transferFrom(msg.sender, address(this), amount_), "Token transfer failed");
        return _airdrop(msg.sender, to_, amount_);
    }

    /**
     * Send an airdrop to your team.
     * @param amount_ Amount to send.
     * @param minBalance_ Minimum balance to qualify.
     * @param maxBalance_ Maximum balance to qualify.
     * @return bool True if successful.
     */
    function airdropTeam(uint256 amount_, uint256 minBalance_, uint256 maxBalance_) external returns (bool)
    {
        require(!_participants[msg.sender].banned, "Sender is banned");
        IToken _token_ = _token();
        require(_token_.transferFrom(msg.sender, address(this), amount_), "Token transfer failed");
        address[] memory _team_ = _referrals[msg.sender];
        uint256 _count_;
        // Loop through first to get number of qualified accounts.
        for(uint256 i = 0; i < _team_.length; i ++) {
            if(_team_[i] == msg.sender) {
                continue;
            }
            if( _participants[_team_[i]].balance >= minBalance_ &&
                _participants[_team_[i]].balance <= maxBalance_ &&
                !_participants[_team_[i]].maxed &&
                _participants[_team_[i]].deposited + _participants[_team_[i]].airdropReceived + amount_ <= 5000e18
            ) {
                _count_ ++;
            }
        }
        require(_count_ > 0, "No qualified accounts exist");
        uint256 _airdropAmount_ = amount_ / _count_;
        // Send an airdrop to each qualified account.
        for(uint256 i = 0; i < _team_.length; i ++) {
            if(_team_[i] == msg.sender) {
                continue;
            }
            if( _participants[_team_[i]].balance >= minBalance_ &&
                _participants[_team_[i]].balance <= maxBalance_ &&
                !_participants[_team_[i]].maxed &&
                _participants[_team_[i]].deposited + _participants[_team_[i]].airdropReceived + amount_ <= 5000e18
            ) {
                _airdrop(msg.sender, _team_[i], _airdropAmount_);
            }
        }
        return true;
    }

    /**
     * Send an airdrop.
     * @param from_ Airdrop sender.
     * @param to_ Airdrop recipient.
     * @param amount_ Amount to send.
     * @return bool True if successful.
     */
    function _airdrop(address from_, address to_, uint256 amount_) internal returns (bool)
    {
        require(!_participants[to_].banned, "Receiver is banned");
        // Check if participant is new.
        _addParticipant(to_);
        _addReferrer(to_, address(0));
        // Check that airdrop can happen.
        require(from_ != to_, "Cannot airdrop to self");
        require(!_participants[to_].maxed, "Recipient is maxed");
        // Update sender airdrop stats.
        _participants[from_].airdropSent += amount_;
        // Update contract airdrop stats.
        _stats.totalAirdropped += amount_;
        _stats.totalAirdrops ++;
        // Remove tax
        uint256 _taxAmount_ = amount_ * _properties.airdropTax / 10000;
        if(_taxAmount_ > 0) {
            amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[to_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(to_, _taxAmount_);
        }
        // Add amount to receiver.
        require(_participants[to_].balance + amount_ <= _maxThreshold(), "Recipient is maxed");
        require(_participants[to_].deposited + _participants[to_].airdropReceived + amount_ <= 5000e18, "Maximum deposits received");
        _participants[to_].airdropReceived += amount_;
        _participants[to_].balance += amount_;
        // Emit airdrop event.
        emit AirdropSent(from_, to_, amount_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * REFERRALS.
     * -------------------------------------------------------------------------
     */

    /**
     * Add referrer.
     * @param referred_ Address of the referred participant.
     * @param referrer_ Address of the referrer.
     */
    function _addReferrer(address referred_, address referrer_) internal
    {
        if(_participants[referred_].referrer != address(0) && _participants[referred_].referrer != addressBook.get("safe")) {
            // Only update referrer if none is set yet
            return;
        }
        if(referrer_ == address(0)) {
            // Use the safe address if referrer is zero.
            referrer_ = addressBook.get("safe");
        }
        if(referred_ == referrer_) {
            // Use the safe address if referrer is self.
            referrer_ = addressBook.get("safe");
        }
        _participants[referred_].referrer = referrer_;
        _referrals[referrer_].push(referred_);
        _participants[referrer_].directReferrals ++;
        // Check if the referrer is a team wallet.
        if(_referrals[referrer_].length >= _properties.teamWalletRequirement) {
            _participants[referrer_].teamWallet = true;
        }
        // Check if referrer is new.
        if(_participants[referrer_].referrer != address(0)) {
            return;
        }
        // Referrer is new so add them to the safe's referrals.
        _addReferrer(referrer_, addressBook.get("safe"));
    }

    /**
     * Pay upline.
     * @param participant_ Address of participant.
     * @param bonus_ Bonus amount.
     */
    function _payUpline(address participant_, uint256 bonus_) internal
    {
        if(bonus_ == 0) {
            return;
        }
        // Get some data that will be used later.
        address _safe_ = addressBook.get("safe");
        uint256 _maxThreshold_ = _maxThreshold();
        address _lastRewarded_ = _lastRewarded[participant_];
        IDownline _downline_ = _downline();
        // If nobody has been rewarded yet start with the participant.
        if(_lastRewarded_ == address(0)) {
            _lastRewarded_ = participant_;
        }
        // Set previous rewarded so we can pay out team bonuses if applicable.
        address _previousRewarded_ = address(0);
        // Set depth to 1.
        for(uint _depth_ = 1; _depth_ <= _properties.maxReferralDepth; _depth_ ++) {
            if(_lastRewarded_ == _safe_) {
                // We're at the top so let's start over.
                _lastRewarded_ = participant_;
            }
            // Move up the chain.
            _previousRewarded_ = _lastRewarded_;
            _lastRewarded_ = _participants[_lastRewarded_].referrer;
            // Check for downline NFTs
            if(_downline_.balanceOf(_lastRewarded_) < _depth_) {
                // Downline NFT balance is not high enough so skip to the next referrer.
                continue;
            }
            if(_participants[_lastRewarded_].balance + bonus_ > _maxThreshold_) {
                // Bonus is too high, so skip to the next referrer.
                continue;
            }
            if(_participants[_lastRewarded_].balance < _participants[_lastRewarded_].claimed) {
                // Participant has claimed more than deposited/compounded.
                continue;
            }
            if(_lastRewarded_ == participant_) {
                // Can't receive your own bonuses.
                continue;
            }
            // We found our winner!
            _lastRewarded[participant_] = _lastRewarded_;
            if(_participants[_lastRewarded_].teamWallet) {
                uint256 _childBonus_ = bonus_ * _properties.teamWalletChildBonus / 10000;
                bonus_ -= _childBonus_;
                if(_participants[_previousRewarded_].balance + _childBonus_ > _maxThreshold_) {
                    _childBonus_ = _maxThreshold_ - _participants[_previousRewarded_].balance;
                }
                _participants[_previousRewarded_].balance += _childBonus_;
                _participants[_previousRewarded_].awarded += _childBonus_;
            }
            if(_lastRewarded_ == _safe_) {
                _sendTokens(_lastRewarded_, bonus_);
            }
            else {
                _participants[_lastRewarded_].balance += bonus_;
                _participants[_lastRewarded_].awarded += bonus_;
            }
            // Update contract bonus stats.
            _stats.totalBonused += bonus_;
            _stats.totalBonuses ++;
            // Fire bonus event.
            emit Bonus(_lastRewarded_, bonus_);
            break;
        }
    }

    /**
     * Get referrals.
     * @param participant_ Participant address.
     * @return address[] Participant's referrals.
     */
    function getReferrals(address participant_) external view returns (address[] memory)
    {
        return _referrals[participant_];
    }

    /**
     * Admin update referrer.
     * @param participant_ Participant address.
     * @param referrer_ Referrer address.
     * @dev Owner can update someone's referrer.
     */
    function adminUpdateReferrer(address participant_, address referrer_) external onlyOwner
    {
        for(uint i = 0; i < _referrals[_participants[participant_].referrer].length; i ++) {
            if(_referrals[_participants[participant_].referrer][i] == participant_) {
                delete _referrals[_participants[participant_].referrer][i];
                _participants[_participants[participant_].referrer].directReferrals --;
                break;
            }
        }
        _participants[participant_].referrer = referrer_;
        _participants[referrer_].directReferrals ++;
        _referrals[referrer_].push(participant_);
    }

    /**
     * -------------------------------------------------------------------------
     * REWARDS.
     * -------------------------------------------------------------------------
     */

    /**
     * Available rewards.
     * @param participant_ Participant address.
     * @return uint256 Amount of rewards available.
     */
    function _availableRewards(address participant_) internal view returns (uint256)
    {
        uint256 _period_ = ((block.timestamp - _participants[participant_].lastRewardUpdate) * 10000) / _properties.period;
        if(_period_ > 10000) {
            // Only let rewards accumulate for 1 period.
            _period_ = 10000;
        }
        uint256 _available_ = ((_period_ * _rewardPercent(participant_) * _participants[participant_].balance) / 100000000);
        // Make sure participant doesn't go above max payout.
        uint256 _maxPayout_ = _maxPayout(participant_);
        if(_available_ + _participants[participant_].claimed > _maxPayout_) {
            _available_ = _maxPayout_ - _participants[participant_].claimed;
        }
        return _available_;
    }

    /**
     * Reward percent.
     * @param participant_ Participant address.
     * @return uint256 Reward percent.
     */
    function _rewardPercent(address participant_) internal view returns (uint256)
    {
        if(_participants[participant_].startTime == 0) {
            return _rates[_properties.neutralClaims];
        }
        if(_participants[participant_].maxed) {
            return _participants[participant_].maxedRate;
        }
        if(_participants[participant_].penalized) {
            return _rates[_properties.lookbackPeriods];
        }
        return _rates[_effectiveClaims(participant_, 0)];
    }

    /**
     * -------------------------------------------------------------------------
     * GETTERS.
     * -------------------------------------------------------------------------
     */

    /**
     * Available rewards.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's available rewards.
     */
    function availableRewards(address participant_) external view returns (uint256)
    {
        return _availableRewards(participant_);
    }

    /**
     * Max payout.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's max payout.
     */
    function maxPayout(address participant_) external view returns (uint256)
    {
        return _maxPayout(participant_);
    }

    /**
     * Remaining payout.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's remaining payout.
     */
    function remainingPayout(address participant_) external view returns (uint256)
    {
        return _maxPayout(participant_) - _participants[participant_].claimed;
    }

    /**
     * Participant status.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's status (1 = negative, 2 = neutral, 3 = positive).
     */
    function participantStatus(address participant_) external view returns (uint256)
    {
        uint256 _status_ = 3;
        uint256 _effectiveClaims_ = _effectiveClaims(participant_, 0);
        if(_effectiveClaims_ >= _properties.neutralClaims) _status_ = 2;
        if(_effectiveClaims_ >= _properties.negativeClaims) _status_ = 1;
        if(_participants[participant_].startTime == 0) {
            _status_ = 2;
        }
        return _status_;
    }

    /**
     * Participant balance.
     * @param participant_ Address of participant.
     * @return uint256 Participant's balance.
     */
    function participantBalance(address participant_) external view returns (uint256)
    {
        return _participants[participant_].balance;
    }

    /**
     * Participant maxed.
     * @param participant_ Address of participant.
     * @return bool Whether the participant is maxed or not.
     */
    function participantMaxed(address participant_) external view returns (bool)
    {
        return _participants[participant_].maxed;
    }


    /**
     * Claim precheck.
     * @param participant_ Address of participant.
     * @return uint256 Reward rate after another claim.
     */
    function claimPrecheck(address participant_) external view returns (uint256)
    {
        if(_participants[participant_].maxed) {
            return _participants[participant_].maxedRate;
        }
        return _rates[_effectiveClaims(participant_, 1)];
    }

    /**
     * Reward rate.
     * @param participant_ Address of participant.
     * @return uint256 Current reward rate.
     */
    function rewardRate(address participant_) external view returns (uint256)
    {
        return _rates[_effectiveClaims(participant_, 0)];
    }

    /**
     * Max threshold.
     * @return uint256 Maximum balance threshold.
     */
    function maxThreshold() external view returns (uint256)
    {
        return _maxThreshold();
    }

    /**
     * -------------------------------------------------------------------------
     * HELPER FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Get token contract.
     * @return IToken Token contract.
     */
    function _token() internal view returns (IToken)
    {
        return IToken(addressBook.get("token"));
    }

    /**
     * Get downline contract.
     * @return IDownline Downline contract.
     */
    function _downline() internal view returns (IDownline)
    {
        return IDownline(addressBook.get("downline"));
    }

    /**
     * Max threshold.
     * @return uint256 Number of tokens needed to be considered at max.
     */
    function _maxThreshold() internal view returns (uint256)
    {
        return _properties.maxPayout * 10000 / _properties.maxReturn;
    }

    /**
     * Max payout.
     * @param participant_ Address of participant.
     * @return uint256 Maximum payout based on balance of participant and max payout.
     */
    function _maxPayout(address participant_) internal view returns (uint256)
    {
        uint256 _maxPayout_ = _participants[participant_].balance * _properties.maxReturn / 1000;
        if(_maxPayout_ > _properties.maxPayout) {
            _maxPayout_ = _properties.maxPayout;
        }
        return _maxPayout_;
    }

    /**
     * Add participant.
     * @param participant_ Address of participant.
     */
    function _addParticipant(address participant_) internal
    {
        // Check if participant is new.
        if(_participants[participant_].startTime == 0) {
            _participants[participant_].startTime = block.timestamp;
            _participants[participant_].lastRewardUpdate = block.timestamp;
            _stats.totalParticipants ++;
        }
    }

    /**
     * Send tokens.
     * @param recipient_ Token recipient.
     * @param amount_ Tokens to send.
     */
    function _sendTokens(address recipient_, uint256 amount_) internal
    {
        if(amount_ == 0) {
            return;
        }
        IToken _token_ = _token();
        uint256 _balance_ = _token_.balanceOf(address(this));
        if(_balance_ < amount_) {
            _token_.mint(address(this), amount_ - _balance_);
        }
        emit TokensSent(recipient_, amount_);
        _token_.transfer(recipient_, amount_);
    }

    /**
     * Whale tax.
     * @param participant_ Participant address.
     * @return uint256 Whale tax amount.
     */
    function _whaleTax(address participant_) internal view returns (uint256)
    {
        uint256 _claimed_ = _participants[participant_].claimed + _participants[participant_].compounded;
        uint256 _tax_ = 0;
        if(_claimed_ > 10000 * (10 ** 18)) _tax_ = 500;
        if(_claimed_ > 20000 * (10 ** 18)) _tax_ = 1000;
        if(_claimed_ > 30000 * (10 ** 18)) _tax_ = 1500;
        if(_claimed_ > 40000 * (10 ** 18)) _tax_ = 2000;
        if(_claimed_ > 50000 * (10 ** 18)) _tax_ = 2500;
        if(_claimed_ > 60000 * (10 ** 18)) _tax_ = 3000;
        if(_claimed_ > 70000 * (10 ** 18)) _tax_ = 3500;
        if(_claimed_ > 80000 * (10 ** 18)) _tax_ = 4000;
        if(_claimed_ > 90000 * (10 ** 18)) _tax_ = 4500;
        if(_claimed_ > 100000 * (10 ** 18)) _tax_ = 5000;
        return _tax_;
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Ban participant.
     * @param participant_ Address of participant.
     */
    function banParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].banned = true;
    }

    /**
     * Unban participant.
     * @param participant_ Address of participant.
     */
    function unbanParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].banned = false;
    }

    /**
     * Add to compounded.
     * @param participant_ Address of participant.
     * @param amount_ Amount to add.
     */
    function addToCompounded(address participant_, uint256 amount_) external onlyOwner
    {
        _participants[participant_].compounded += amount_;
    }

    /**
     * Add to claimed.
     * @param participant_ Address of participant.
     * @param amount_ Amount to add.
     */
    function addToClaimed(address participant_, uint256 amount_) external onlyOwner
    {
        _participants[participant_].claimed += amount_;
    }

    /**
     * Add to taxed.
     * @param participant_ Address of participant.
     * @param amount_ Amount to add.
     */
    function addToTaxed(address participant_, uint256 amount_) external onlyOwner
    {
        _participants[participant_].taxed += amount_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IAddressBook.sol";
import "../interfaces/IAutoCompound.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title BaseContract
 * @author Steve Harmeyer
 * @notice This is an abstract base contract to handle UUPS upgrades and pausing.
 */

/// @custom:security-contact [email protected]
abstract contract BaseContract is Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function __BaseContract_init() internal onlyInitializing {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * Address book.
     */
    IAddressBook public addressBook;

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Pause contract.
     * @dev This stops all operations with the contract.
     */
    function pause() external onlyOwner
    {
        _pause();
    }

    /**
     * Unpause contract.
     * @dev This resumes all operations with the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Set address book.
     * @param address_ Address book address.
     * @dev Sets the address book address.
     */
    function setAddressBook(address address_) public onlyOwner
    {
        addressBook = IAddressBook(address_);
    }

    /**
     * -------------------------------------------------------------------------
     * HOOKS.
     * -------------------------------------------------------------------------
     */

    /**
     * @dev This prevents upgrades from anyone but owner.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IClaim {
    function addressBook (  ) external view returns ( address );
    function claimNft ( uint256 quantity_, address address_, bool vault_ ) external returns ( bool );
    function getOwnerValue ( address owner_ ) external view returns ( uint256 );
    function getTokenValue ( uint256 tokenId_ ) external view returns ( uint256 );
    function initialize (  ) external;
    function owned ( address owner_ ) external view returns ( uint256[] memory );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDownline {
    function approve (address to, uint256 tokenId) external;
    function available (address buyer_, uint256 max_, uint256 price_, uint256 value_, uint256 total_) external view returns (uint256);
    function balanceOf (address owner) external view returns (uint256);
    function buy (bytes memory signature_, uint256 quantity_, uint256 max_, uint256 price_, uint256 value_, uint256 total_, uint256 expiration_) external returns (bool);
    function claim () external;
    function claimed (uint256) external view returns (bool);
    function furToken () external view returns (address);
    function getApproved (uint256 tokenId) external view returns (address);
    function isApprovedForAll (address owner, address operator) external view returns (bool);
    function name () external view returns (string memory);
    function owner () external view returns (address);
    function ownerOf (uint256 tokenId) external view returns (address);
    function paymentToken () external view returns (address);
    function renounceOwnership () external;
    function safeTransferFrom (address from, address to, uint256 tokenId) external;
    function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory _data) external;
    function setApprovalForAll (address operator, bool approved) external;
    function setFurToken (address furToken_) external;
    function setPaymentToken (address paymentToken_) external;
    function setTokenUri (string memory uri_) external;
    function setTreasury (address treasury_) external;
    function setVerifier (address verifier_) external;
    function sold (uint256 max_, uint256 price_, uint256 value_, uint256 total_) external view returns (uint256);
    function supportsInterface (bytes4 interfaceId) external view returns (bool);
    function symbol () external view returns (string memory);
    function tokenByIndex (uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex (address owner, uint256 index) external view returns (uint256);
    function tokenURI (uint256 tokenId_) external view returns (string memory);
    function tokenValue (uint256) external view returns (uint256);
    function totalSupply () external view returns (uint256);
    function transferFrom (address from, address to, uint256 tokenId) external;
    function transferOwnership (address newOwner) external;
    function treasury () external view returns (address);
    function value (address owner_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken {
    function addressBook (  ) external view returns ( address );
    function allowance ( address owner, address spender ) external view returns ( uint256 );
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function balanceOf ( address account ) external view returns ( uint256 );
    function decimals (  ) external view returns ( uint8 );
    function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
    function getLastSell ( address address_ ) external view returns ( uint256 );
    function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
    function initialize (  ) external;
    function mint ( address to_, uint256 quantity_ ) external;
    function name (  ) external view returns ( string memory );
    function onCooldown ( address address_ ) external view returns ( bool );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setPumpAndDumpRate ( uint256 pumpAndDumpRate_ ) external;
    function setPumpAndDumpTax ( uint256 pumpAndDumpTax_ ) external;
    function setSellCooldown ( uint256 sellCooldown_ ) external;
    function setTax ( uint256 tax_ ) external;
    function setVaultTax ( uint256 vaultTax_ ) external;
    function symbol (  ) external view returns ( string memory );
    function totalSupply (  ) external view returns ( uint256 );
    function transfer ( address to, uint256 amount ) external returns ( bool );
    function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function updateAddresses (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAddressBook
{
    function get (string memory name_) external view returns (address);
    function initialize () external;
    function owner () external view returns (address);
    function pause () external;
    function paused () external view returns (bool);
    function proxiableUUID () external view returns (bytes32);
    function renounceOwnership () external;
    function set (string memory name_, address address_) external;
    function transferOwnership (address newOwner) external;
    function unpause () external;
    function unset (string memory name_) external;
    function upgradeTo (address newImplementation) external;
    function upgradeToAndCall (address newImplementation, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAutoCompound {
    struct Properties {
        uint256 maxPeriods; // Maximum number of periods a participant can auto compound.
        uint256 period; // Seconds between compounds.
        uint256 fee; // BNB fee per period of auto compounding.
        uint256 maxParticipants; // Maximum autocompound participants.
    }
    struct Stats {
        uint256 compounding; // Number of participants auto compounding.
        uint256 compounds; // Number of auto compounds performed.
    }
    function addPeriods ( address participant_, uint256 periods_ ) external;
    function addressBook (  ) external view returns ( address );
    function compound ( uint256 quantity_ ) external;
    function compound (  ) external;
    function compounding ( address participant_ ) external view returns ( bool );
    function compounds ( address participant_ ) external view returns ( uint256[] memory );
    function compoundsLeft ( address participant_ ) external view returns ( uint256 );
    function due (  ) external view returns ( uint256 );
    function end (  ) external;
    function initialize (  ) external;
    function lastCompound ( address participant_ ) external view returns ( uint256 );
    function next (  ) external view returns ( address );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function properties (  ) external view returns ( Properties memory );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setMaxParticipants ( uint256 max_ ) external;
    function start ( uint256 periods_ ) external;
    function stats (  ) external view returns ( Stats memory );
    function totalCompounds ( address participant_ ) external view returns ( uint256 );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
    function withdraw (  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}