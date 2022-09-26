// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "./base/MetawinNFTMinter.sol";

/**
 * @dev Interface allowing to interact with the raffle contract.
 */
interface RaffleI {
    /**
     * @dev Gets entries for a promo raffle. Only callable by the minter contract.
     * Minter contract must have the "MINTERCONTRACT" role assigned in the raffle contract.
     * @param _raffleId Id of the raffle.
     * @param _amountOfEntries Amount of entries.
     * @param _player Address of the user.
     */
    function createFreeEntriesFromExternalContract(
        uint256 _raffleId,
        uint256 _amountOfEntries,
        address _player
    ) external;
}

/** @dev Contract defining "MetaWinners DAC" minting process.
 *  Full feature list in the base contract {MetawinNFTMinter}
 *  Aditional features:
 *      -Paid mints also grant free entries to special raffles
 */
contract MetaWinnersDACMinter is MetawinNFTMinter {

    // Address of the raffle contract.
    address public raffleContract;

    // Default raffle ID when a pricing rule is not found.
    uint256 private _defaultRaffleId;

    constructor() MetawinNFTMinter(500) {} // Setting freemints pool size to 500

    /**
     * @notice [View][External] Frontend helper function to return the current raffleId.
     * Check {_currentRaffleId} method for more info.
     */
    function raffle_getCurrentId() view external returns(uint256){
        return _currentRaffleId();
    }

    /**
     * @notice [View][External] Get the default raffle ID (used when no pricing rule is found).
     * (if a pricing rule exists, its "utilityId" is used as raffle ID instead).
     */
    function raffle_getDefaultId() external view returns (uint256){
        return _defaultRaffleId;
    }

    /**
     * @dev [View][Internal] Returns the current raffleId.
     * If a pricing rule exists, its "utilityId" is used as raffle ID.
     * Otherwise, {_defaultRaffleId} is returned.
     */
    function _currentRaffleId() view internal returns(uint256){
        (PriceInfo memory currentRule, bool isDefault) =
        _price_currentRule(MetawinNFTI(NFTcontract).totalSupply());

        return isDefault ? _defaultRaffleId : currentRule.utilityId;
    }

    /**
     * @notice [Tx][External][Owner] Set the default raffle ID to be used when no pricing rule is found.
     * (if a pricing rule exists, its "utilityId" is used as raffle ID).
     */
    function raffle_setDefaultId(uint256 _raffleId) external onlyOwner {
        _defaultRaffleId = _raffleId;
    }

    /**
     * @dev [Tx][External][Owner] Store the raffle contract address.
     * @param _raffleContract Address of the raffle contract.
     */
    function raffle_setContractAddress(address _raffleContract) external onlyOwner {
        raffleContract = _raffleContract;
    }

    /**
     * @dev [Tx][External][Owner] Resets {raffleContract} to address(0).
     * By doing so, paid mintings won't grant raffle entries any longer.
     */
    function raffle_clearContractAddress() external onlyOwner {
        delete raffleContract;
    }

    /**
     * @dev [Tx][Internal] Buyers get free raffle entries after each minting
     * (if {raffleContract} is set).
     */
    function _afterPaidMinting(address to, uint256 amount) internal virtual override {
        if(raffleContract != address(0) ){
            RaffleI(raffleContract).createFreeEntriesFromExternalContract(
                _currentRaffleId(),
                amount,
                to);
        }
        super._afterPaidMinting(to, amount);
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/** @dev Contract providing an address whitelisting feature (using merkleProof).
 *  It is meant to be deployed as an instance (by using the "new" command): this approach allows to have
 *  multiple lists in the same contract.
 *  To optimize the gas usage, it is recommended to deploy only the first instance with the "new" command
 *  and use minimalProxies (aka clones - EIP-1167) for the others.
 *  The contract can be used in two ways:
 *  (1) With a list containing only addresses: the contract variable "allowance" will be used - and can also be set
 *  (2) With a list containing both addresses and allowances: call the alternative functions with the additional
 *  "_listAllowance" input. These functions ignore the allowance variable and rely on the _allowance parameter.
 *  Note: each function is flagged with (1), (2) or (1)(2), depending on which methodology they are meant to be
 *  used with.
*/
contract Whitelist {

    uint8 private allowance;                    // Allowance for each member of the list - defaults to 1
    bytes32 private merkleRoot;                 // MerkleRoot for whitelist membership verification
    address private deployer;                   // Store the deployer address to restrict some functions
    mapping(address => uint8) private used;     // User address => Counter

    constructor(){
        initialize();
    }

    modifier onlyDeployer{
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
    function isInWhitelist(address _address, bytes32[] calldata _merkleProof) view public returns(bool){
        bytes32 leaf = keccak256(abi.encode(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev (2) Overload of the previous function with an additional parameters for the allowance
     * To be used when the allowance is reported in the list
     * Each item in the list must be formatted as follows: "[address]:[allowance]"
     * @param _address Address to be checked
     * @param _listAllowance Allowance as reported in the whitelist
     * @param _merkleProof Merkle proof
     */
    function isInWhitelist(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof) view public returns(bool){
        bytes32 leaf = keccak256(abi.encode(_address, ":", _listAllowance));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev (1) Returns the total allowance of the queried address, zero if not in whitelist
     * @param _address Address to be checked
     * @param _merkleProof Merkle proof
     */
    function getAllowance(address _address, bytes32[] calldata _merkleProof) view public returns(uint8){
        if (isInWhitelist(_address, _merkleProof)) return allowance;
        else return 0;
    }
    
    /**
     * @dev (1)(2) Returns the allowance used by the queried address
     * @param _address Address to be checked
     */
    function getUsedAllowance(address _address) view public returns(uint8){
        return used[_address];
    }
    
    /**
     * @dev (1) Returns the allowance available to the queried address
     * @param _address Address to be checked
     * @param _merkleProof Whitelist merkle proof
     */
    function getUnusedAllowance(address _address, bytes32[] calldata _merkleProof) view public returns(uint8){
        uint8 addressAllowance = getAllowance(_address, _merkleProof);
        return used[_address] < addressAllowance ? addressAllowance-used[_address] : 0;
    }

    /**
     * @dev (2) Alternative method to be used when the allowance is reported in the original list
     * Important: in the input allowance specified is wrong, the return value will be zero as
     * each [address]:[allowance] pair is a unique list element
     * @param _address Address to be checked
     * @param _listAllowance Allowance as reported in the whitelist
     * @param _merkleProof Whitelist merkle proof
     */
    function getUnusedAllowance(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof) view public returns(uint8){
        if (!isInWhitelist(_address, _listAllowance, _merkleProof)){
            return 0;
        }
        else{
            return used[_address] < _listAllowance ? _listAllowance-used[_address] : 0;
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
        allowance=_allowance;
    }

    /**
     * @dev (1) Use the whitelist allowance
     * @param _address Address claiming
     * @param _merkleProof Whitelist merkle proof
     */
    function claim(address _address, bytes32[] calldata _merkleProof) external onlyDeployer{
        require(getUnusedAllowance(_address, _merkleProof)>0, "Exceeding allowance");
        used[_address] += 1;
    }

    /**
     * @dev (2) Use the whitelist allowance, alternative with allowance input
     * @param _address Address claiming
     * @param _listAllowance Address allowance (as reported on the whitelist)
     * @param _merkleProof Whitelist merkle proof
     */
    function claim(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof) external onlyDeployer{
        require(getUnusedAllowance(_address, _listAllowance, _merkleProof)>0, "Exceeding allowance");
        used[_address] += 1;
    }

    /**
     * @dev (1) Use the whitelist allowance (more than one entry)
     * @param _address Address claiming
     * @param _merkleProof Whitelist merkle proof
     * @param _amount Amount to claim
     */
    function claim(address _address, bytes32[] calldata _merkleProof, uint8 _amount) external onlyDeployer{
        require(_amount<=getUnusedAllowance(_address, _merkleProof), "Exceeding allowance");
        used[_address] += _amount;
    }

    /**
     * @dev (2) Alternative specifying the allowance from the list
     * @param _address Address claiming
     * @param _listAllowance Address allowance (as reported on the whitelist)
     * @param _merkleProof Whitelist merkle proof
     * @param _amount Amount to claim
     */
    function claim(address _address, uint8 _listAllowance, bytes32[] calldata _merkleProof, uint8 _amount) external onlyDeployer{
        require(_amount<=getUnusedAllowance(_address, _listAllowance, _merkleProof), "Exceeding allowance");
        used[_address] += _amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/** @dev Base contract providing the logics for a multi-phase minting.
*/
abstract contract MintingPhases is Ownable {

    enum MintingPhase {setup, freemints, whitelist, openToAll, end}
    mapping (MintingPhase => uint256) public phaseStartTime;

    /**
    * @dev Modifier to restrict functions to a specific phase.
    */
    modifier onlyInPhase(MintingPhase _phase){
        require(phase_current()==_phase, "Not allowed during current phase");
        _;
    }

    /**
    * @dev [Pure][Private] Given an input phase, returns the following.
    */
    function _next(MintingPhase _phase) private pure returns(MintingPhase){
        return(MintingPhase(uint8(_phase)+1));
    }

    /**
    * @dev [View][Internal] Get the current phase, based on block.timestamp.
    */
    function phase_current() internal view returns(MintingPhase){
        if (phaseStartTime[MintingPhase.freemints] == 0) return MintingPhase(0);
        uint256 curTime = block.timestamp;
        for (uint8 phase=uint8(MintingPhase.end); phase>0; phase--){
            if(curTime > phaseStartTime[MintingPhase(phase)]) return MintingPhase(phase);
        }
        return MintingPhase(0);
    }

    /**
    * @dev [View][Public] Return the name of the current phase.
    */
    function phase_nameOfCurrent() public view returns (string memory){
        string[5] memory phaseNames = ["Setup", "Freemints", "Whitelisted", "Open", "End"];
        return phaseNames[uint256(phase_current())];
    }

    /**
    * @notice [View][Public] Time left before the current phase ends.
    */
    function phase_timeToNext() public view returns(uint256){
        MintingPhase cur = phase_current();
        if(cur == MintingPhase.end || phaseStartTime[_next(cur)]==0) return 0;
        else return phaseStartTime[_next(cur)]-block.timestamp;
    }

    /**
    * @notice [Tx][External][Admin] Set the phases times.
    * @param _freemint_startTime Start time: freemints (in Unix timestamp).
    * @param _whitelist_delay Freemint phase duration (in seconds).
    * @param _open_delay Whitelist-only phase duration (in seconds).
    * @param _end_delay Open-mint phase duration (in seconds).
    */
    function phase_setTimes (
        uint256 _freemint_startTime, 
        uint256 _whitelist_delay, 
        uint256 _open_delay,
        uint256 _end_delay)
        external virtual onlyOwner {
            require(uint8(phase_current()) == 0, "Restricted to Setup phase");
            phaseStartTime[MintingPhase.freemints] = _freemint_startTime;
            phaseStartTime[MintingPhase.whitelist] = _freemint_startTime + _whitelist_delay;
            phaseStartTime[MintingPhase.openToAll] = phaseStartTime[MintingPhase.whitelist] + _open_delay;
            phaseStartTime[MintingPhase.end] = phaseStartTime[MintingPhase.openToAll] + _end_delay;
    }

    /**
    * @notice [Tx][External][Admin] End the current phase (and start the next) immediately.
    * @notice Also anticipates the following phases to preserve their duration.
    */    
    function phase_endCurrent() external virtual onlyOwner {
        MintingPhase next = _next(phase_current());
        require(phaseStartTime[next]>0, "Set phase times first");
        if(next!=MintingPhase.end){
            uint256 timeShift = phaseStartTime[next]-block.timestamp;
            for (uint8 i=uint8(next); i<=uint8(MintingPhase.end); ++i){
                phaseStartTime[MintingPhase(i)] -= timeShift;
            }
        }
        else phaseStartTime[next] = block.timestamp;
    }

    /**
    * @notice [Tx][External][Admin] Extend the duration of the current phase.
    * @notice Also adds the same delay to the following phases to preserve their duration.
    * @param _time Time to extend (in seconds).
    */
    function phase_extendCurrent(uint256 _time) external virtual onlyOwner {
        uint8 next = uint8(phase_current())+1;
        require(phaseStartTime[MintingPhase(next)]>0);
        for (uint8 i=next; i<=uint8(MintingPhase.end); ++i){
            phaseStartTime[MintingPhase(i)] += _time;
        }
    }

    /**
    * @dev [View][Public] Get the full list of phase start times.
    */
    function phase_startTimes() public view returns(uint256[] memory){
        uint8 numPhases = uint8(MintingPhase.end)+1;
        uint256[] memory phaseTimes = new uint256[](numPhases);
        for(uint8 i; i<numPhases; ++i) phaseTimes[i] = phaseStartTime[MintingPhase(i)];
        return phaseTimes;
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/** @dev Base contract providing the logics for the mint pricing.
 * Admin is able to either set a fixed price for all mintings ("default price")
 * or define a set rules consisting of thresholds, related prices and IDs.
 * UtilityIds are optional data that can be either used as a reference ID or to store
 * a utility uint value. For example, they can be used to store the ID of a raffle
 * that users are be eligible for upon minting.
 * When the total supply exceeds a threshold, the next rule is used.
 * If no rule is found for the current total supply, the default price is used.
 */
abstract contract MintPricing is Ownable {

    // Defines a pricing rule
    struct PriceInfo{
        uint16 threshold;
        uint256 price;
        uint256 utilityId;
    }

    // Default price, can be set by admin
    uint256 private _defaultPrice = 1 ether;

    // Array of the pricing rules
    PriceInfo[] private _priceInfo;
    
    /**@dev Returns the current price. Internal, can be wrapped in child contract's
     * price function.
     * @param totalSupply Total minted supply
    */
    function _price_current(uint256 totalSupply) view internal returns(uint256){
        (PriceInfo memory currentRule, ) = _price_currentRule(totalSupply);
        return currentRule.price;
    }

    /**@dev Returns the current pricing rule.
     * @param totalSupply Total minted supply
     * @return isDefault True if the rules array is empty, therefore returning a default value.
    */
    function _price_currentRule(uint256 totalSupply) view internal returns(PriceInfo memory, bool isDefault){
        for(uint256 index = 0; index<_priceInfo.length; ++index){
            if(totalSupply<_priceInfo[index].threshold) {
                return (_priceInfo[index], false);
            }
        }
        return (PriceInfo(0, _defaultPrice, 0), true);
    }

    /**@notice Returns the default price.
     */
    function price_getDefaultPrice() external view returns (uint256) {
        return _defaultPrice;
    }

    /**@dev Returns all the current pricing rules.
     * @return thresholds List of thresholds.
     * @return prices List of prices.
     * @return utilityIds List of utility IDs.
     */
    function price_getAllRules() external view returns (
        uint16[] memory thresholds,
        uint256[] memory prices,
        uint256[] memory utilityIds)
        {
        uint256 arrayLen = _priceInfo.length;
        uint16[] memory _thresholds = new uint16[](arrayLen);
        uint256[] memory _prices = new uint256[](arrayLen);
        uint256[] memory _utilityIds = new uint256[](arrayLen);
        for(uint256 i; i<arrayLen; ++i){
            _thresholds[i] = _priceInfo[i].threshold;
            _prices[i] = _priceInfo[i].price;
            _utilityIds[i] = _priceInfo[i].utilityId;
        }
        thresholds = _thresholds;
        prices = _prices;
        utilityIds = _utilityIds;
    }

    /**@notice Set the default price.
     * @param _price New price.
     */
    function price_setDefaultPrice(uint256 _price) external onlyOwner {
        _defaultPrice = _price;
    }

    /**@notice Add a new pricing rule. If the specified threshold is already used by an
     * existing rule, that rule is replaced.
     * @param _threshold Supply threshold
     * @param _price Minting price to be used until threshold is exceeded
     * @param _utilityId Utility ID to be stored.
    */
    function price_addRule(uint16 _threshold, uint256 _price, uint256 _utilityId) external onlyOwner {
        uint256 arrayLen = _priceInfo.length;
        (uint256 target, bool replace) = _findTargetIndex(_threshold, arrayLen);
        if(target == _priceInfo.length) {_priceInfo.push(PriceInfo(_threshold, _price, _utilityId));}
        else{
            if(replace) _priceInfo[target] = PriceInfo(_threshold, _price, _utilityId);
            else{
                _insertRule(_threshold, _price, _utilityId, arrayLen, target);
            }
        }
    }

    /**@notice Delete an existing pricing rule.
     * @param _index Index of the rule to be deleted.
    */
    function price_deleteRule(uint256 _index) external onlyOwner {
        PriceInfo[] memory tempArray = _priceInfo;
        delete _priceInfo;
        for(uint256 i; i<tempArray.length; ++i){
            if(i!=_index) {
                _priceInfo.push(tempArray[i]);
            }
        }
    }

    /**@notice Set/replace all the existing rules.
     * @param _thresholds List of new thresholds.
     * @param _prices List of new prices.
     * @param _utilityIds List of new ids.
    */
    function price_setAllRules(
        uint16[] calldata _thresholds,
        uint256[] calldata _prices,
        uint256[] calldata _utilityIds)
        external onlyOwner {
        require(_prices.length == _thresholds.length, "Number of input prices and thresholds not equal");
        delete _priceInfo;
        for(uint256 index; index<_prices.length; ++index){
            _priceInfo.push(PriceInfo(_thresholds[index], _prices[index], _utilityIds[index]));
        }
    }

    /**@notice Delete all of the existing rules.
     * (Default price will be used for all mintings)
     */
    function price_clearRules() external onlyOwner {
        delete _priceInfo;
    }

    /**@dev Find the correct position in the pricing rules array to insert/replace a new entry.
     * @param _threshold Threshold of the rule to be added.
     * @param _arrayLen Length of the array to search within.
     * @return uint256 Index found.
     * @return replace True if the existing item at found index should be replaced instead of shifted.
     */
    function _findTargetIndex(uint16 _threshold, uint256 _arrayLen) private view returns (uint256, bool replace){
        if(_arrayLen == 0) return (0, false);
        else if (_priceInfo[_arrayLen-1].threshold == _threshold) return (_arrayLen-1, true);
        else if (_priceInfo[_arrayLen-1].threshold < _threshold) return (_arrayLen, false);
        else{
            --_arrayLen;
            return _findTargetIndex(_threshold, _arrayLen);
        }
    }

    /**@dev Insert a new rule in the {_priceInfo} array.
     * @param _threshold Threshold of the rule to be added.
     * @param _price Price of the rule to be added.
     * @param _utilityId Utility ID to be stored in the rule.
     * @param _arrayLen Length of the array before the addition.
     * @param _index Target index.
     */
    function _insertRule(uint16 _threshold, uint256 _price, uint256 _utilityId, uint256 _arrayLen, uint256 _index) private {
        uint256 target = _arrayLen;
        _priceInfo.push(_priceInfo[target-1]);
        --target;
        while(target>_index){
            _priceInfo[target] = _priceInfo[target-1];
            --target;
        }
        _priceInfo[_index] = PriceInfo(_threshold, _price, _utilityId);
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./utils/Whitelist.sol";
import "./utils/MintingPhases.sol";
import "./utils/MintPricing.sol";

/**
* @dev Interface allowing to interact with the NFT contract
*/
interface MetawinNFTI{
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

/** @dev Contract defining Metawin NFT minting environments
  * Rules:
  *     Multiple phases (freemints only, freemints + whitelisted, open to everyone)
  *     Each phase has a timer - admin can manually end the current phase.
  *     Free minting if in freemint list
  *     Max 5 paid mints per address during whitelist phase
  *     Additional 5 paid mints per address during open phase
  *     Price: dynamic (based on rules defined by admin)
*/
contract MetawinNFTMinter is Ownable, MintPricing, MintingPhases, Pausable, ReentrancyGuard {

    using Clones for address;

    // CONTRACT VARIABLES //

    uint256 public limitPerAddress = 5;           // Maximum mints per address
    uint256 public maxMints;                      // Maximum mints during current even (can be lower than max supply)
    mapping (address => uint256) minted;          // Track number of tokens minted by each address
    address public NFTcontract;
    address public payoutAddress = 0x1544D2de126e3A4b194Cfad2a5C6966b3460ebE3; // metawin.eth

    Whitelist immutable public whitelistContract; // Contract that handles the whitelist
    Whitelist immutable public freemintContract;  // Contract that handles the freemint list
    uint256 public freemints_reserved;            // Max tokens reserved to freemint wallets


    // CONSTRUCTOR //

    constructor(uint256 _freemintsPool_size){
        whitelistContract = new Whitelist();      // Deploy the whitelist contract
        freemintContract = Whitelist(address(whitelistContract).clone()); // Deploy the freemintList contract as a clone - save gas
        freemintContract.initialize();            // Also initialize it - cloning doesn't call the constructor
        freemints_reserved = _freemintsPool_size; // Set size of freemints pool
    }


    // EVENTS //

    event FreemintClaimed(address indexed user, uint256 indexed amount);
    event MintPurchased(address indexed user, uint256 indexed amount);
    event ReservedToTeam(uint256 amount);


    // SETUP //

    /**
    * @dev [Tx][External][Owner] Link this contract to the NFT contract
    * @param _NFTcontract Address of the NFT contract
    */
    function setNFTaddress(address _NFTcontract) external onlyOwner {
        NFTcontract = _NFTcontract;
        maxMints = MetawinNFTI(NFTcontract).MAX_SUPPLY(); // Also initialize max mints
    }

    /**
    * @dev [Tx][External][Owner] Change the mints cap (maximum mintable pool)
    * @param amount New amount
    */
    function setMaxMints(uint256 amount) external onlyOwner {
        require(
            amount <= MetawinNFTI(NFTcontract).MAX_SUPPLY() &&
            amount >= MetawinNFTI(NFTcontract).totalSupply(),
            "Out of range"
            );
        maxMints = amount;
    }

    /**
    * @dev [Tx][External][Owner] Set the address that will receive the payments
    * @param _address Payments will be routed to this
    */
    function setPayoutAddress(address _address) external onlyOwner {
        payoutAddress = payable(_address);
    }

    /**
    * @dev [Tx][External][Owner] Set freemints reserve
    * @param _newValue New reserve value
    */
    function setFreemintReserve(uint256 _newValue) external onlyOwner {
        freemints_reserved = _newValue;
    }

    /**
    * @dev [Tx][External][Owner] Change the maximum mints per address
    */
    function setLimitPerAddress(uint256 _newLimit) external onlyOwner{
        limitPerAddress = _newLimit;
    }

    /**
    * @dev [Tx][External][Owner] Put some tokens aside for the team
    * @notice Restricted to setup phase
    * @param amount Number of tokens to mint
    * @param teamAddress Address receiving team-reserved tokens
    */
    function reserveToTeam(uint256 amount, address teamAddress) external onlyOwner onlyInPhase(MintingPhase.setup){
        for (uint256 n; n<amount; ++n){
            MetawinNFTI(NFTcontract).mint(teamAddress);
        }
        emit ReservedToTeam(amount);
    }


    // PRE/POST MINTING HOOKS //

    /**
    * @dev [Tx][Internal] Hook that is called after FREE minting.
    * @param amount Number of tokens minted.
    */
    function _afterFreeMinting(address to, uint256 amount) internal virtual {}
    
    /**
    * @dev [Tx][Internal] Hook that is called after PAID minting.
    * @param amount Number of tokens minted.
    */
    function _afterPaidMinting(address to, uint256 amount) internal virtual {}


    // FREEMINT //

    /**
    * @dev [Tx][External][Owner] Store the merkle root of the freemint list
    * @param _merkleRoot Merkle root hash
    */
    function freemint_setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freemintContract.setMerkleRoot(_merkleRoot);
    }

    /**
    * @dev [View][Public] Check if the queried address is in the freemint list
    * @param _address Address to check
    * @param _tickets Number of tickets, must match the number on the list.
    * @param _merkleProof Merkle proof
    */
    function freemint_isInList(address _address, uint8 _tickets, bytes32[] calldata _merkleProof) external view returns(bool) {
        return freemintContract.isInWhitelist(_address, _tickets, _merkleProof);
    }

    /**
    * @dev [View][Public] Get amount of freemint tokens claimed by the given address
    * @param _address Address to check
    */
    function freemint_amountClaimed(address _address) external view returns(uint256) {
        return freemintContract.getUsedAllowance(_address);
    }

    /**
    * @dev [Tx][External] Free minting
    * @param _merkleProof Merkle proof
    */
    function mintFree(uint8 _amountToClaim, uint8 _totalTickets, bytes32[] calldata _merkleProof) external whenNotPaused {
        require(phase_current() > MintingPhase(0) && phase_current() < MintingPhase.end, "Not allowed in current phase");
        require(freemintContract.isInWhitelist(msg.sender, _totalTickets, _merkleProof), "Address not in freemint list");
        require(MetawinNFTI(NFTcontract).totalSupply()+_amountToClaim <= maxMints, "Not enough tokens available to mint");
        freemintContract.claim(msg.sender, _totalTickets, _merkleProof, _amountToClaim);
        freemints_reserved -= _amountToClaim;
        for (uint256 n; n<_amountToClaim; ++n){
            MetawinNFTI(NFTcontract).mint(msg.sender);
        }
        _afterFreeMinting(msg.sender, _amountToClaim);
        emit FreemintClaimed(msg.sender, _amountToClaim);
    }


    // WHITELIST //
    
    /**
    * @dev [Tx][External][Owner] Store the merkle root of the whitelist
    * @param _merkleRoot Merkle root hash
    */
    function whitelist_setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistContract.setMerkleRoot(_merkleRoot);
    }

    /**
    * @dev [View][Public] Check if the queried address in the whitelist
    * @param _address Address to check
    * @param _merkleProof Merkle proof
    */
    function whitelist_isInList(address _address, bytes32[] calldata _merkleProof) public view returns(bool) {
        return whitelistContract.isInWhitelist(_address, _merkleProof);
    }


    // PURCHASE //

    /**
    * @dev [View][Public] Get current price
    */
    function price_current() public view virtual returns(uint256) {
        return _price_current(MetawinNFTI(NFTcontract).totalSupply());
    }

    /**
    * @dev [View][Public] Return how many tokens are mintable (and not reserved)
    */
    function mintableSupply() public view returns(uint256){
        return maxMints - 
            MetawinNFTI(NFTcontract).totalSupply() -
            (phase_current() < MintingPhase.openToAll ? freemints_reserved : 0);  // Freemints no longer reserved in Open phase
    }

    /**
    * @dev [Tx][External][PAYABLE] Paid minting with merkfleProof
    * @notice Whitelist phase only
    * @param amount Number of tokens to mint
    */
    function mintBuy(uint256 amount, bytes32[] calldata _whitelist_merkleProof) external payable
        nonReentrant
        whenNotPaused
        onlyInPhase(MintingPhase.whitelist)
    {
        //Checks
        require(amount <= mintableSupply(), "Not enough tokens available to mint");
        require((amount + minted[msg.sender]) <= limitPerAddress, "Exceeding allocation");
        require(price_current()*amount == msg.value, "Price paid incorrect");
        require(whitelist_isInList(msg.sender, _whitelist_merkleProof), "Not in whitelist");
        //Purchase
        (bool paid, ) = payoutAddress.call{value: address(this).balance}("");
        require(paid);
        //Mint
        minted[msg.sender] += amount;
        for(uint256 i; i<amount; i++){
            MetawinNFTI(NFTcontract).mint(msg.sender);
        }
        _afterPaidMinting(msg.sender, amount);
        emit MintPurchased(msg.sender, amount);
    }

    /**
    * @dev [Tx][External][PAYABLE] Paid minting (overloaded function with no merkleproof input, only for Open phase)
    * @notice Open phase only
    * @param amount Number of tokens to mint
    */
    function mintBuy(uint256 amount) external payable nonReentrant whenNotPaused onlyInPhase(MintingPhase.openToAll) {
        //Checks
        require(amount <= mintableSupply(), "Not enough tokens available to mint");
        require((amount + minted[msg.sender]) <= (limitPerAddress*2), "Exceeding allocation"); // x2 limit in Open phase
        require(price_current()*amount == msg.value, "Price paid incorrect");
        //Purchase
        (bool paid, ) = payoutAddress.call{value: address(this).balance}("");
        require(paid);
        //Mint
        minted[msg.sender] += amount;
        for(uint256 i; i<amount; i++){
            MetawinNFTI(NFTcontract).mint(msg.sender);
        }
        _afterPaidMinting(msg.sender, amount);
        emit MintPurchased(msg.sender, amount);
    }


    // PAUSE //

    /**
    * @dev [Tx][Public][Owner] Pause the contract
    */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
    * @dev [Tx][Public][Owner] Unpause the contract
    */
    function unpauseContract() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}