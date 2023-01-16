// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./base/MetawinNFTMinter.sol";
import "./base/modules/MintingReward.sol";

/**
 * @dev Contract defining "MetaWinners DAC" minting process.
 * Full feature list in the base contract {MetawinNFTMinter}
 * Aditional features:
 *  -Paid mints also grant free entries to special competitions
 */
contract MetaWinnersDACMinter is MetawinNFTMinter, MintingReward {

    /**
     * @dev Buyers get free competition entries after each minting
     * (if {MintingReward-competitionContract} is set).
     */
    function _afterPaidMinting(address to, uint256 amount) internal virtual override {
        _reward_grant(to, amount);
        super._afterPaidMinting(to, amount);
    }

    /**
     * @dev Implementation of {MintingReward-_totalSupply}.
     */
    function _totalSupply() view internal override returns(uint256){
        return IMetawinNFT(NFTcontract).totalSupply();
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/** 
 * @dev Contract providing an address whitelisting feature (using merkleProof).
 * It is meant to be deployed as an instance (by using the "new" command): this approach allows to have
 * multiple lists in the same contract.
 * To optimize the gas usage, it is recommended to deploy only the first instance with the "new" command
 * and use minimalProxies (aka clones - EIP-1167) for the others.
 * The contract can be used in two ways:
 * (1) The list contains only addresses: address allowance is determined by the "allowance" variable
 * (2) The list contains both addresses and allowances: use the alternative functions with the additional
 * "_listAllowance" input. These functions ignore the allowance variable and rely on the _allowance parameter.
 * Note: each function is flagged with (1), (2) or (1)(2), depending on which methodology they are meant to be
 * used with.
 */
contract Whitelist {
    uint8 private allowance; // Allowance for each member of the list - defaults to 1
    bytes32 private merkleRoot; // MerkleRoot for whitelist membership verification
    address private deployer; // Store the deployer address to restrict some functions
    mapping(address => uint8) private used; // User address => Counter

    error ExceedingAllowance(uint256 requested, uint256 used, uint256 remaining);

    constructor() {
        initialize();
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Access restricted to deployer");
        _;
    }

    /**
     * @dev (1)(2) This function acts like a constructor but it's compatible
     * with proxy contracts (clones, upgradable, etc.). Must be called by deployer
     * as soon as the instance is created. If the contract has been deployed normally,
     * there is no need to call this as it is also wrapped in the actual constructor.
     */
    function initialize() public {
        require(deployer == address(0), "Already initialized");
        deployer = msg.sender;
        allowance = 1; // Set default
    }

    /**
     * @dev (1) Checks if the address is in the whitelist.
     * @param _address Address to be checked
     * @param _merkleProof Merkle proof
     */
    function isInWhitelist(address _address, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encode(_address));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev (2) Overload of the previous function with an additional parameters for the allowance
     * To be used when the allowance is reported in the list
     * Each item in the list must be formatted as follows: "[address]:[allowance]"
     * @param _address Address to be checked
     * @param _listAllowance Allowance as reported in the whitelist
     * @param _merkleProof Merkle proof
     */
    function isInWhitelist(
        address _address,
        uint8 _listAllowance,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encode(_address, ":", _listAllowance));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev (1) Returns the total allowance of the queried address, zero if not in whitelist
     * @param _address Address to be checked
     * @param _merkleProof Merkle proof
     */
    function getAllowance(address _address, bytes32[] calldata _merkleProof)
        public
        view
        returns (uint8)
    {
        if (isInWhitelist(_address, _merkleProof)) return allowance;
        else return 0;
    }

    /**
     * @dev (1)(2) Returns the allowance used by the queried address
     * @param _address Address to be checked
     */
    function getUsedAllowance(address _address) public view returns (uint8) {
        return used[_address];
    }

    /**
     * @dev (1) Returns the allowance available to the queried address
     * @param _address Address to be checked
     * @param _merkleProof Whitelist merkle proof
     */
    function getUnusedAllowance(
        address _address,
        bytes32[] calldata _merkleProof
    ) public view returns (uint8) {
        uint8 addressAllowance = getAllowance(_address, _merkleProof);
        return
            used[_address] < addressAllowance
                ? addressAllowance - used[_address]
                : 0;
    }

    /**
     * @dev (2) Alternative method to be used when the allowance is reported in the original list
     * Important: in the input allowance specified is wrong, the return value will be zero as
     * each [address]:[allowance] pair is a unique list element
     * @param _address Address to be checked
     * @param _listAllowance Allowance as reported in the whitelist
     * @param _merkleProof Whitelist merkle proof
     */
    function getUnusedAllowance(
        address _address,
        uint8 _listAllowance,
        bytes32[] calldata _merkleProof
    ) public view returns (uint8) {
        if (!isInWhitelist(_address, _listAllowance, _merkleProof)) {
            return 0;
        } else {
            return
                used[_address] < _listAllowance
                    ? _listAllowance - used[_address]
                    : 0;
        }
    }

    /**
     * @dev (1)(2) Stores the whitelist merkle root
     * @param _merkleRoot Merkle root to be stored
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyDeployer {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev (1) Changes the whitelist allowance
     * @param _allowance New allowance per address
     */
    function setAllowance(uint8 _allowance) external onlyDeployer {
        allowance = _allowance;
    }

    /**
     * @dev (1) Use the whitelist allowance
     * @param _address Address claiming
     * @param _merkleProof Whitelist merkle proof
     */
    function claim(address _address, bytes32[] calldata _merkleProof)
        external
        onlyDeployer
    {
        if (getUnusedAllowance(_address, _merkleProof) == 0)
            revert ExceedingAllowance(
                1,
                getUsedAllowance(_address),
                getUnusedAllowance(_address, _merkleProof)
            );
        used[_address]++;
    }

    /**
     * @dev (2) Use the whitelist allowance, alternative with allowance input
     * @param _address Address claiming
     * @param _listAllowance Address allowance (as reported on the whitelist)
     * @param _merkleProof Whitelist merkle proof
     */
    function claim(
        address _address,
        uint8 _listAllowance,
        bytes32[] calldata _merkleProof
    ) external onlyDeployer {
        if (getUnusedAllowance(_address, _listAllowance, _merkleProof) == 0)
            revert ExceedingAllowance(
                1,
                getUsedAllowance(_address),
                getUnusedAllowance(_address, _listAllowance, _merkleProof)
            );
        used[_address]++;
    }

    /**
     * @dev (1) Use the whitelist allowance (more than one entry)
     * @param _address Address claiming
     * @param _merkleProof Whitelist merkle proof
     * @param _amount Amount to claim
     */
    function claim(
        address _address,
        bytes32[] calldata _merkleProof,
        uint8 _amount
    ) external onlyDeployer {
        if (_amount > getUnusedAllowance(_address, _merkleProof))
            revert ExceedingAllowance(
                _amount,
                getUsedAllowance(_address),
                getUnusedAllowance(_address, _merkleProof)
            );
        unchecked{used[_address] += _amount;}
    }

    /**
     * @dev (2) Alternative specifying the allowance from the list
     * @param _address Address claiming
     * @param _listAllowance Address allowance (as reported on the whitelist)
     * @param _merkleProof Whitelist merkle proof
     * @param _amount Amount to claim
     */
    function claim(
        address _address,
        uint8 _listAllowance,
        bytes32[] calldata _merkleProof,
        uint8 _amount
    ) external onlyDeployer {
        if (
            _amount > getUnusedAllowance(_address, _listAllowance, _merkleProof)
        )
            revert ExceedingAllowance(
                _amount,
                getUsedAllowance(_address),
                getUnusedAllowance(_address, _listAllowance, _merkleProof)
            );
        unchecked{used[_address] += _amount;}
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "../env/Roles.sol";
import "../interfaces/ICompetition.sol";

/**
 * @dev This module allows to set up reward competitions granted upon minting.
 * Specifically, admin can set up supply bracket rules to ensure that each
 * token ID range grants entries for a different competition.
 * Exampe: token ID 1 to 5000 grant entries for competition A, 5001 to 10000 grant
 * entries for competition B.
 * Note: In order to use this module, the child contract must implement
 * {_totalSupply} so that the returned value is the minted tokens supply.
 */
abstract contract MintingReward is Roles {
    // Type to define a reward rule
    struct RewardRule {
        uint16 threshold; // Minted supply bracket (upper bound)
        uint256 competitionId;
    }

    // Default Competition Id, can be amended by admin
    uint256 private _defaultCompetitionId;

    // Array of the pricing rules
    RewardRule[] private _rewardRules;

    // Address of the competition contract.
    address public competitionContract;


    // EVENTS AND ERRORS //

    // Emitted when a reward is granted
    event RewardGranted(uint256 indexed competitionId, uint256 indexed entries, address indexed account);

    // Emitted when no reward is granted
    event NoRewardGranted();

    // Raised when attempting to reward a user with tickets of invalid Competition Ids.
    error InvalidCompetitionId(uint256 competitionId);

    // Raised when a competition requested to be part of a rule is not in accepted state
    error NotInAcceptedState(uint256 id);


    // PUBLIC/EXTERNAL FUNCTIONS - VIEW //

    /**
     * @notice Return the current reward rule (selected depending on the minted supply).
     * @return isDefault True if the _rewardRules array is empty (therefore the returned rule has the default Competition Id)
     */
    function reward_currentRule()
        external
        view
        returns (RewardRule memory, bool isDefault)
    {
        return (_reward_currentRule(_totalSupply()));
    }

    /**
     * @notice Get the current competition Id.
     */
    function reward_currentCompetitionId() external view returns (uint256) {
        (RewardRule memory currentRule, ) = _reward_currentRule(_totalSupply());
        return currentRule.competitionId;
    }

    /**
     * @notice Returns the default competition id.
     */
    function reward_defaultCompetitionId() external view returns (uint256) {
        return _defaultCompetitionId;
    }

    /**
     * @notice Return all reward rules.
     * @return thresholds List of thresholds
     * @return competitionIds List of competition IDs
     */
    function reward_getAllRules()
        external
        view
        returns (uint16[] memory thresholds, uint256[] memory competitionIds)
    {
        uint256 arrayLen = _rewardRules.length;
        uint16[] memory _thresholds = new uint16[](arrayLen);
        uint256[] memory _competitionIds = new uint256[](arrayLen);
        for (uint256 i; i < arrayLen;) {
            _thresholds[i] = _rewardRules[i].threshold;
            _competitionIds[i] = _rewardRules[i].competitionId;
            unchecked{++i;}
        }
        thresholds = _thresholds;
        competitionIds = _competitionIds;
    }


    // PUBLIC/EXTERNAL FUNCTIONS - TX //

    /**
     * @notice Store the competition contract address.
     * @param competitionAddress Address of the competition contract
     */
    function reward_setCompetitionContractAddress(address competitionAddress)
        external
        onlyRole(METAWIN_ROLE)
    {
        require(competitionAddress != address(0), "Input is zero address");
        competitionContract = competitionAddress;
    }

    /**
     * @notice Resets {competitionContract} to address(0).
     * By doing so, no rewards are granted.
     */
    function reward_clearCompetitionContractAddress()
        external
        onlyRole(METAWIN_ROLE)
    {
        delete competitionContract;
    }

    /**
     * @notice Set the default competition id.
     * @param competitionId New competition Id
     */
    function reward_setDefaultCompetition(uint256 competitionId)
        external
        onlyRole(METAWIN_ROLE)
    {
        if (_cmp().raffleNotInAcceptedState(competitionId))
            revert NotInAcceptedState(competitionId);
        _defaultCompetitionId = competitionId;
    }

    /**
     * @notice Add a new reward rule. If the input threshold is already used by an
     * existing rule, that rule is replaced.
     * @param threshold Upper range bracket: when the total supply reaches it, the following rule kicks in
     * @param competitionId Id of the competition being rewarded by the rule
     */
    function reward_setRule(uint16 threshold, uint256 competitionId)
        external
        onlyRole(METAWIN_ROLE)
    {
        if (_cmp().raffleNotInAcceptedState(competitionId))
            revert NotInAcceptedState(competitionId);
        uint256 arrayLen = _rewardRules.length;
        (uint256 target, bool replace) = _findTargetIndex(threshold, arrayLen);
        if (target == _rewardRules.length) {
            _rewardRules.push(RewardRule(threshold, competitionId));
        } else {
            if (replace)
                _rewardRules[target] = RewardRule(threshold, competitionId);
            else {
                _insertRule(threshold, competitionId, arrayLen, target);
            }
        }
    }

    /**
     * @notice Set/replace all the existing rules.
     * @param thresholds List of new thresholds (check {RewardRule} type for info)
     * @param competitionIds List of new ids
     */
    function reward_setAllRules(
        uint16[] calldata thresholds,
        uint256[] calldata competitionIds
    ) external onlyRole(METAWIN_ROLE) {
        require(
            competitionIds.length == thresholds.length,
            "Input arrays length differ"
        );
        delete _rewardRules;
        uint256 count = competitionIds.length;
        for (uint256 index; index < count;) {
            if (_cmp().raffleNotInAcceptedState(competitionIds[index]))
                revert NotInAcceptedState(competitionIds[index]);
            _rewardRules.push(
                RewardRule(thresholds[index], competitionIds[index])
            );
            unchecked{++index;}
        }
    }

    /**
     * @notice Delete an existing reward rule.
     * @param index Index of the rule to be deleted
     */
    function reward_deleteRule(uint256 index) external onlyRole(METAWIN_ROLE) {
        RewardRule[] memory tempArray = _rewardRules;
        delete _rewardRules;
        uint256 count = tempArray.length;
        for (uint256 i; i < count;) {
            if (i != index) {
                _rewardRules.push(tempArray[i]);
            }
            unchecked{++i;}
        }
    }

    /**
     * @notice Delete all the existing rules
     * (Default competition ID will be used for all mintings).
     */
    function reward_deleteAllRules() external onlyRole(METAWIN_ROLE) {
        delete _rewardRules;
    }


    // PRIVATE/INTERNAL FUNCTIONS //

    /**
     * @dev Return the token supply - to be implemented (by override) in the child contract.
     */
    function _totalSupply() internal view virtual returns (uint256) {}

    /**
     * @dev Give to `account` `amountOfEntries` tickets of the current reward competition;
     * if the competition contract is not set, no reward ticket is given.
     */
    function _reward_grant(address account, uint256 amountOfEntries) internal {
        if(competitionContract != address(0) ){
            (RewardRule memory currentRule, ) = _reward_currentRule(_totalSupply());
            uint256 currentId = currentRule.competitionId;
            if (currentId!=0){
                _cmp().createFreeEntriesFromExternalContract({
                    _competitionId: currentId,
                    _amountOfEntries: amountOfEntries,
                    _player: account
                });
                emit RewardGranted(currentId, amountOfEntries, account);
            }
            else revert InvalidCompetitionId(0);
        }
        else emit NoRewardGranted();
    }

    /**
     * @dev Private function to return the current reward rule (selected depending on the minted supply).
     * @return isDefault True if the _rewardRules array is empty (therefore the returned rule has the default Competition Id)
     */
    function _reward_currentRule(uint256 totalSupply)
        private
        view
        returns (RewardRule memory, bool isDefault)
    {
        uint256 count = _rewardRules.length;
        for (uint256 index; index < count;) {
            if (totalSupply < _rewardRules[index].threshold) {
                return (_rewardRules[index], false);
            }
            unchecked{++index;}
        }
        return (RewardRule(0, _defaultCompetitionId), true);
    }

    /**
     * @dev Private function to find the correct position in the rules array to insert/replace a new entry.
     * @param _threshold Threshold of the rule to be added
     * @param _arrayLen Length of the array to search within
     * @return uint256 Detected target index
     * @return replace True if the existing item at found index should be replaced instead of shifted.
     */
    function _findTargetIndex(uint16 _threshold, uint256 _arrayLen)
        private
        view
        returns (uint256, bool replace)
    {
        if (_arrayLen == 0) return (0, false);
        else if (_rewardRules[_arrayLen - 1].threshold == _threshold)
            return (_arrayLen - 1, true);
        else if (_rewardRules[_arrayLen - 1].threshold < _threshold)
            return (_arrayLen, false);
        else {
            --_arrayLen;
            return _findTargetIndex(_threshold, _arrayLen);
        }
    }

    /**
     * @dev Private function to insert a new rule in the {_rewardRules} array.
     * @param _threshold Threshold of the rule to be added
     * @param _utilityId Utility ID to be stored in the rule
     * @param _arrayLen Length of the array before the addition
     * @param _index Target index
     */
    function _insertRule(
        uint16 _threshold,
        uint256 _utilityId,
        uint256 _arrayLen,
        uint256 _index
    ) private {
        uint256 target = _arrayLen;
        _rewardRules.push(_rewardRules[target - 1]);
        --target;
        while (target > _index) {
            _rewardRules[target] = _rewardRules[target - 1];
            --target;
        }
        _rewardRules[_index] = RewardRule(_threshold, _utilityId);
    }

    /**
     * @dev Private function acting as an alias of the instance of the competition interface
     * at the current competition contract address (check {competitionContract} variable).
     */
    function _cmp() private view returns (ICompetition) {
        return ICompetition(competitionContract);
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "../env/Roles.sol";

/** @dev Base contract providing the logics for a multi-phase minting.
*/
abstract contract MintingPhases is Roles {

    // Phases enumerator
    enum MintingPhase {setup, earlyMinting, minting, end}

    // Start time of each phase (Unix timestamp)
    mapping (MintingPhase => uint256) public phaseStartTime;

    /**
     * @dev Error to be raised when a function is called in the wrong phase.
     */
    error PhaseError(MintingPhase current, MintingPhase required);

    /**
     * @dev Modifier to restrict functions to a specific phase.
     */
    modifier onlyInPhase(MintingPhase _phase){
        if(_phase_current()!=_phase) revert PhaseError(_phase_current(), _phase);
        _;
    }

    /**
     * @notice Return the enum index of the current phase.
     */
    function phase_indexOfCurrent() external view returns (uint256){
        return uint256(_phase_current());
    }

    /**
     * @notice Return the name of the current phase.
     */
    function phase_nameOfCurrent() external view returns (string memory){
        string[4] memory phaseNames = ["Setup", "Early-Minting", "Minting", "End"];
        return phaseNames[uint256(_phase_current())];
    }

    /**
     * @notice Time left before the current phase ends.
     */
    function phase_timeToNext() external view returns(uint256){
        MintingPhase cur = _phase_current();
        if(cur == MintingPhase.end || phaseStartTime[_next(cur)]==0) return 0;
        else return phaseStartTime[_next(cur)]-block.timestamp;
    }

    /**
     * @notice Set the phases times.
     * @param _earlyminting_startTime Start time: early-minting (in Unix timestamp)
     * @param _minting_delay Early-minting duration(in seconds)
     * @param _end_delay Minting phase duration (in seconds)
     */
    function phase_setTimes (
        uint256 _earlyminting_startTime, 
        uint256 _minting_delay,
        uint256 _end_delay)
        external
        virtual
        onlyRole(METAWIN_ROLE)
        onlyInPhase(MintingPhase.setup) {
            phaseStartTime[MintingPhase.earlyMinting] = _earlyminting_startTime;
            phaseStartTime[MintingPhase.minting] = _earlyminting_startTime + _minting_delay;
            phaseStartTime[MintingPhase.end] = _earlyminting_startTime + _minting_delay + _end_delay;
    }

    /**
     * @notice End the current phase (and start the next) immediately; this action
     * also anticipates the following phases to preserve their duration.
     */    
    function phase_endCurrent() external virtual onlyRole(METAWIN_ROLE) {
        MintingPhase next = _next(_phase_current());
        require(phaseStartTime[next]!=0, "Phase times not set");
        if(next!=MintingPhase.end){
            uint256 timeShift = phaseStartTime[next]-block.timestamp;
            for (uint8 i=uint8(next); i<=uint8(MintingPhase.end);){
                phaseStartTime[MintingPhase(i)] -= timeShift;
                unchecked{++i;}
            }
        }
        else phaseStartTime[next] = block.timestamp;
    }

    /**
     * @notice Extend the duration of the current phase; this also
     * adds the same delay to the following phases to preserve their duration.
     * @param _time Time to extend (in seconds).
     */
    function phase_extendCurrent(uint256 _time) external virtual onlyRole(METAWIN_ROLE) {
        uint8 next = uint8(_phase_current())+1;
        require(phaseStartTime[MintingPhase(next)]>0);
        for (uint8 i=next; i<=uint8(MintingPhase.end);){
            phaseStartTime[MintingPhase(i)] += _time;
            unchecked{++i;}
        }
    }

    /**
     * @notice Get the full list of phase start times.
     */
    function phase_startTimes() external view returns(uint256[] memory){
        uint8 numPhases = uint8(MintingPhase.end)+1;
        uint256[] memory phaseTimes = new uint256[](numPhases);
        for(uint8 i; i<numPhases;) {
            phaseTimes[i] = phaseStartTime[MintingPhase(i)];
            unchecked{++i;}
        }
        return phaseTimes;
    }

    /**
     * @notice Return to setup phase by resetting all phase times.
     */
    function phase_reset() external virtual onlyRole(METAWIN_ROLE) onlyInPhase(MintingPhase.end) {
        for(uint256 i; i<=uint256(MintingPhase.end);){
            delete phaseStartTime[MintingPhase(i)];
            unchecked{++i;}
        }
    }

    /**
     * @dev Internal function to get the current phase.
     */
    function _phase_current() internal view returns(MintingPhase){
        if (phaseStartTime[MintingPhase(1)] == 0) return MintingPhase(0);
        uint256 curTime = block.timestamp;
        for (uint8 phase=uint8(MintingPhase.end); phase!=0; --phase){
            if(curTime > phaseStartTime[MintingPhase(phase)]) return MintingPhase(phase);
        }
        return MintingPhase(0);
    }

    /**
     * @dev Private function: given an input phase, returns the following one.
     */
    function _next(MintingPhase _phase) private pure returns(MintingPhase){
        return(MintingPhase(uint8(_phase)+1));
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "../libraries/Math.sol";
import "../env/Roles.sol";

/**
 * @dev Base contract providing logics to setup dutch auctions
 * and query their current price.
 */
abstract contract DutchAuction is Roles {
    using Math for uint256;

    /**
     * @dev Dutch auction data type.
     */
    struct DutchAuctionInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 minPrice;
        uint256 timeStep;
    }

    // DutchAuctionInfo
    DutchAuctionInfo private _dutchAuction;

    /**
     * @notice Returns the current Dutch auction settings.
     */
    function dutchAuction_getSettings()
        external
        view
        returns (DutchAuctionInfo memory)
    {
        return _dutchAuction;
    }

    /**
     * @dev Save/override dutch auction data on storage.
     * @param startPrice Initial price
     * @param endPrice Final price
     * @param startTime When the initial price shall start decreasing
     * @param endTime When the price reaches the end-price
     * @param timeStep Price update frequency
     */
    function dutchAuction_set(
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 timeStep
    ) external onlyRole(METAWIN_ROLE) {
        _dutchAuction = DutchAuctionInfo(
            startTime,
            endTime,
            startPrice,
            endPrice,
            timeStep
        );
    }

    /**
     * @dev Return the current Dutch auction price.
     */
    function _currentDutchAuctionPrice() internal view returns (uint256) {
        DutchAuctionInfo memory data = _dutchAuction;
        uint256 timeStepped = _stepFloor(block.timestamp, data.timeStep)
            .clampToRange(data.startTime, data.endTime);
        return
            (data.endTime - timeStepped).fitRange(
                0,
                data.endTime - data.startTime,
                data.minPrice,
                data.startPrice
            );
    }

    /**
     * @dev Private function to round down `value` to nearest multiple of `step`.
     */
    function _stepFloor(uint256 value, uint256 step)
        private
        pure
        returns (uint256)
    {
        return value - (value % step);
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

library Math {
    function fitRange(
        uint256 _value,
        uint256 _source_min,
        uint256 _source_max,
        uint256 _destination_min,
        uint256 _destination_max
    ) internal pure returns (uint256) {
        uint256 precision = 10**3; //increase precision by working with larger numbers
        _value = clampToRange(_value, _source_min, _source_max); //clamp to source range
        uint256 result = ((((_value - _source_min) *
            (_destination_max - _destination_min) *
            precision) / (_source_max - _source_min)) +
            _destination_min *
            precision) / precision;
        return result;
    }

    function clampToRange(
        uint256 _value,
        uint256 _min,
        uint256 _max
    ) internal pure returns (uint256) {
        return _value < _min ? _min : (_value > _max ? _max : _value);
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

/**
 * @dev Interface allowing to interact with Metawin NFT contracts
 */
interface IMetawinNFT{
    /**
     * @dev Token mint. As no second argument is allowed, will mint the next available tokenId.
     * @param to receiver address
     */
    function mint(address to) external;
    /**
     * @dev Get the current supply (total minted tokens).
     */
    function totalSupply() view external returns(uint256);
    /**
     * @dev Get the maximum supply.
     */
    function MAX_SUPPLY() view external returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

/**
 * @dev Interface allowing to interact with the competition contract.
 */
interface ICompetition {
    /**
     * @dev Gets entries for a promo competition. Only callable by the minter contract.
     * Minter contract must have the "MINTERCONTRACT" role assigned in the competition contract.
     * @param _competitionId Id of the competition.
     * @param _amountOfEntries Amount of entries.
     * @param _player Address of the user.
     */
    function createFreeEntriesFromExternalContract(
        uint256 _competitionId,
        uint256 _amountOfEntries,
        address _player
    ) external;

    /**
     * @dev Check whether `_player` is blacklisted.
     * @param _player The address of the player
     */
    function playerIsBlacklisted(address _player) external view returns (bool);

    /**
     * @dev Check whether the competition `_raffleId` is NOT in "accepted" state.
     * @param _raffleId Id of the competition
     */
    function raffleNotInAcceptedState(uint256 _raffleId)
        external
        view
        returns (bool);

    /**
     * @dev Check whether `_player` is account which provided the competition prize.
     * @param _player Player address
     * @param _raffleId Id of the competition
     */
    function playerIsSeller(address _player, uint256 _raffleId)
        external
        view
        returns (bool);

    /**
     * @dev Check whether `_player` would reach the maximum amount of allowed competition entries.
     * @param _player Player address
     * @param _raffleId Id of the competition
     * @param _amountOfEntries Amount of entries being requested
     */
    function playerReachedMaxEntries(
        address _player,
        uint256 _raffleId,
        uint256 _amountOfEntries
    ) external view returns (bool);

    /**
     * @dev Only needed for competitions restricted to players owning specific NFT collections.
     * Check if `_player` owns the token `_tokenIdUsed` of the collection `_collection`, required
     * to enter the competition `_raffleId`, and makes sure that such a token has not been
     * already used to enter the same competiotion.
     * @param _player The address of the player
     * @param _raffleId id of the raffle
     * @param _collection Address of the required collection, if any
     * @param _tokenIdUsed Id of the token of the required collection the player says he has and want to use in the raffle
     * @return canBuy True if the player can buy
     * @return cause Cause of the rejection if "canBuy" is False
     */
    function playerHasRequiredNFTs(
        address _player,
        uint256 _raffleId,
        address _collection,
        uint256 _tokenIdUsed
    ) external view returns (bool canBuy, string memory cause);
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Roles is AccessControlEnumerable {

    // Role for Metawin backend
    bytes32 public constant METAWIN_ROLE = keccak256("METAWIN_ROLE");

    /**
     * @dev Grants all roles to deployer by default.
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(METAWIN_ROLE, _msgSender());
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./Roles.sol";

abstract contract Payout is Roles{

    // Target address for payments
    address public payoutAddress = 0x1544D2de126e3A4b194Cfad2a5C6966b3460ebE3; // Default: metawin.eth

    /**
    * @dev Raised when a transfer is not successful.
    */
    error PaymentError();

    /**
    * @dev [Tx][External][Owner] Set the address that will receive the payments.
    * @param _address Payments will be routed to this
    */
    function setPayoutAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payoutAddress = payable(_address);
    }

    /**
     * @dev [Tx][Internal] Send funds to the payout address.
     * @param amount Amount to be sent
     */
    function _pay(uint256 amount) internal{
        (bool success, ) = payoutAddress.call{value: amount}("");
        if(!success) revert PaymentError();
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./env/Roles.sol";
import "./env/Payout.sol";
import "./modules/Whitelist.sol";
import "./modules/MintingPhases.sol";
import "./modules/DutchAuction.sol";
import "./interfaces/IMetawinNFT.sol";

/**
 * @dev Contract defining Metawin NFT minting environments
 * Rules:
 *     Two phases (early-minting, minting)
 *     Each phase has a timer - admin can manually end the current phase.
 *     Free minting if in early-mint list
 *     Max 10 paid mints per address
 *     Price: dutch auction
 */
contract MetawinNFTMinter is
    Roles,
    DutchAuction,
    MintingPhases,
    Payout,
    Pausable,
    ReentrancyGuard
{
    // CONTRACT VARIABLES //

    uint256 public limitPerAddress = 10; // Maximum mints per address
    uint256 public mintingCap; // Maximum mintings cap (can be set lower than max supply)
    mapping(address => uint256) minted; // Track number of tokens minted by each address

    IMetawinNFT public NFTcontract; // NFT contract
    Whitelist public immutable earlymintList; // Contract that handles the early-mint list

    // CONSTRUCTOR //

    constructor() {
        earlymintList = new Whitelist(); // Deploy the earlymintList contract
    }

    // EVENTS AND ERRORS //

    // Emitted when accounts in the early-minting list claim their tokens
    event EarlyMintClaimed(address indexed user, uint256 indexed amount);
    // Emitted when minting purchases occur
    event MintPurchased(address indexed user, uint256 indexed amount);
    // Emitted when tokens are reserved (minted) to Metawin
    event ReservedToTeam(uint256 amount);

    // Raised when accounts not in early-minting list attempt to claim free tokens
    error NotInList(address account, uint256 allowance);
    // Raised when attempting to mint more tokens than available
    error ExceedingAvailability(uint256 requested, uint256 available);
    // Raised when attempting to mint beyond the minting cap per address
    error ExceedingLimitPerAddress(
        uint256 requested,
        uint256 minted,
        uint256 limit
    );
    // Raised when underpaying a purchase
    error PricePaidIncorrect(uint256 paid, uint256 price);

    // SETUP //

    /**
     * @notice Link this contract to the NFT contract.
     * @param _NFTcontract Address of the NFT contract
     */
    function setNFTaddress(address _NFTcontract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        NFTcontract = IMetawinNFT(_NFTcontract);
        mintingCap = NFTcontract.MAX_SUPPLY(); // Also initialize max mints
    }

    /**
     * @notice Change the global minting cap; accepts any value in the range `totalSupply`-`MAX_SUPPLY`.
     * @param amount New amount
     */
    function setMintingCap(uint256 amount) external onlyRole(METAWIN_ROLE) {
        if (amount > NFTcontract.MAX_SUPPLY()) revert("Input above MAX_SUPPLY");
        if (amount < NFTcontract.totalSupply())
            revert("Input below totalSupply");
        mintingCap = amount;
    }

    /**
     * @notice Change the minting cap per address.
     */
    function setLimitPerAddress(uint256 _newLimit)
        external
        onlyRole(METAWIN_ROLE)
    {
        limitPerAddress = _newLimit;
    }

    /**
     * @notice Put some tokens aside for the team; restricted to setup phase.
     * @param amount Number of tokens to mint
     * @param teamAddress Address receiving team-reserved tokens
     */
    function mintTeamReserve(uint256 amount, address teamAddress)
        external
        onlyRole(METAWIN_ROLE)
        nonReentrant
        onlyInPhase(MintingPhase.setup)
    {
        _mint(teamAddress, amount);
        emit ReservedToTeam(amount);
    }

    // EARLY-MINTING //

    /**
     * @notice Store the merkle root of the early-mint list.
     * @param _merkleRoot Merkle root hash
     */
    function earlymint_setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(METAWIN_ROLE)
    {
        earlymintList.setMerkleRoot(_merkleRoot);
    }

    /**
     * @notice Check if the queried address is in the early-mint list.
     * @param _address Address to check
     * @param _merkleProof Merkle proof
     */
    function earlymint_isInList(
        address _address,
        uint8 _tickets,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        return earlymintList.isInWhitelist(_address, _tickets, _merkleProof);
    }

    /**
     * @notice Get amount of early-mint tokens claimed by the given address.
     * @param _address Address to check
     */
    function earlymint_amountClaimed(address _address)
        external
        view
        returns (uint256)
    {
        return earlymintList.getUsedAllowance(_address);
    }

    /**
     * @notice Early minting (free) - only whitelisted addresses.
     * @param amountToClaim Amount of tokens to be minted
     * @param totalTickets Total amount of free mints granted to the user
     * @param merkleProof Merkle proof
     */
    function mintFree(
        uint8 amountToClaim,
        uint8 totalTickets,
        bytes32[] calldata merkleProof
    ) external nonReentrant whenNotPaused {
        // Phase check
        MintingPhase currentPhase = _phase_current();
        if (currentPhase == MintingPhase.setup)
            revert PhaseError(currentPhase, MintingPhase.earlyMinting);
        if (currentPhase == MintingPhase.end)
            revert PhaseError(currentPhase, MintingPhase.minting);
        // Whitelist check
        if (
            !earlymintList.isInWhitelist(
                _msgSender(),
                totalTickets,
                merkleProof
            )
        ) revert NotInList(_msgSender(), totalTickets);
        // Availability check
        if (amountToClaim > _mintableSupply())
            revert ExceedingAvailability(amountToClaim, _mintableSupply());
        // Update whitelist records
        earlymintList.claim(
            _msgSender(),
            totalTickets,
            merkleProof,
            amountToClaim
        );
        // Actual minting
        _mint(_msgSender(), amountToClaim);
        // Post-minting ops
        _afterFreeMinting(_msgSender(), amountToClaim);
        emit EarlyMintClaimed(_msgSender(), amountToClaim);
    }

    // PURCHASE //

    /**
     * @notice Get current price.
     */
    function price_current() external view virtual returns (uint256) {
        return _currentDutchAuctionPrice();
    }

    /**
     * @notice Get how many tokens are mintable.
     */
    function mintableSupply() external view returns (uint256) {
        return _mintableSupply();
    }

    /**
     * @notice Paid minting.
     * @param amount Number of tokens to mint
     */
    function mintBuy(uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyInPhase(MintingPhase.minting)
    {
        //Checks
        if (amount > _mintableSupply())
            revert ExceedingAvailability(amount, _mintableSupply());
        if (limitPerAddress < (amount + minted[_msgSender()]))
            revert ExceedingLimitPerAddress(
                amount,
                minted[_msgSender()],
                limitPerAddress
            );
        if (msg.value < _getPrice(amount))
            revert PricePaidIncorrect(msg.value, _getPrice(amount));
        //Pay & Mint
        minted[_msgSender()] += amount;
        _mint(_msgSender(), amount);
        _afterPaidMinting(_msgSender(), amount);
        _pay(msg.value);
        emit MintPurchased(_msgSender(), amount);
    }

    // PRE/POST MINTING HOOKS //

    /**
     * @dev Hook that is called after FREE minting.
     * @param amount Number of tokens minted
     */
    function _afterFreeMinting(address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after PAID minting.
     * @param amount Number of tokens minted
     */
    function _afterPaidMinting(address to, uint256 amount) internal virtual {}

    // PAUSE //

    /**
     * @notice Pause the contract
     */
    function pauseContract() external onlyRole(METAWIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpauseContract() external onlyRole(METAWIN_ROLE) {
        _unpause();
    }

    // PRIVATE FUNCTIONS //

    /**
     * @dev Private function to return how many tokens are mintable.
     */
    function _mintableSupply() private view returns (uint256) {
        return mintingCap - NFTcontract.totalSupply();
    }

    /**
     * @dev Private function to calculate the purchase price.
     */
    function _getPrice(uint256 amount) view private returns (uint256) {
        return _currentDutchAuctionPrice()*amount;
    }

    /**
     * @dev Private function to mint `amount` of tokens to `account`.
     */
    function _mint(address account, uint256 amount) private {
        for (uint256 i; i < amount;) {
            NFTcontract.mint(account);
            unchecked{++i;}
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
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
        mapping(bytes32 => uint256) _indexes;
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
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
    function _length(Set storage set) private view returns (uint256) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
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

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}