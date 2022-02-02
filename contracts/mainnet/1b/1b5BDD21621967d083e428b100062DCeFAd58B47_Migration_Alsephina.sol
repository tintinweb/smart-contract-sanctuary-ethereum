/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: migrations/Migration_Alsephina.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/migrations/Migration_Alsephina.sol
* Docs: https://docs.synthetix.io/contracts/migrations/Migration_Alsephina
*
* Contract Dependencies: 
*	- BaseMigration
*	- ExchangeRates
*	- IAddressResolver
*	- IExchangeRates
*	- IExchangeState
*	- ISystemSettings
*	- ISystemStatus
*	- MixinResolver
*	- MixinSystemSettings
*	- Owned
*	- State
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*	- SystemSettingsLib
*
* MIT License
* ===========
*
* Copyright (c) 2022 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


contract BaseMigration is Owned {
    address public deployer;

    constructor(address _owner) internal Owned(_owner) {
        deployer = msg.sender;
    }

    // safety value to return ownership (anyone can invoke)
    function returnOwnership(address forContract) public {
        bytes memory payload = abi.encodeWithSignature("nominateNewOwner(address)", owner);

        // solhint-disable avoid-low-level-calls
        (bool success, ) = forContract.call(payload);

        if (!success) {
            // then try legacy way
            bytes memory legacyPayload = abi.encodeWithSignature("nominateOwner(address)", owner);

            // solhint-disable avoid-low-level-calls
            (bool legacySuccess, ) = forContract.call(legacyPayload);

            require(legacySuccess, "Legacy nomination failed");
        }
    }

    function _requireDeployer() private view {
        require(msg.sender == deployer, "Only the deployer can invoke this");
    }

    modifier onlyDeployer() {
        _requireDeployer();
        _;
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableSynthetixAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Synthetix
    function issueSynths(address from, uint amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint balance
    ) external;

    function liquidateDelinquentAccount(
        address account,
        uint susdAmount,
        address liquidator
    ) external returns (uint totalRedeemed, uint amountToLiquidate);
}


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// Inheritance


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/state
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}


// https://docs.synthetix.io/contracts/source/interfaces/iexchangestate
interface IExchangeState {
    // Views
    struct ExchangeEntry {
        bytes32 src;
        uint amount;
        bytes32 dest;
        uint amountReceived;
        uint exchangeFeeRate;
        uint timestamp;
        uint roundIdForSrc;
        uint roundIdForDest;
    }

    function getLengthOfEntries(address account, bytes32 currencyKey) external view returns (uint);

    function getEntryAt(
        address account,
        bytes32 currencyKey,
        uint index
    )
        external
        view
        returns (
            bytes32 src,
            uint amount,
            bytes32 dest,
            uint amountReceived,
            uint exchangeFeeRate,
            uint timestamp,
            uint roundIdForSrc,
            uint roundIdForDest
        );

    function getMaxTimestamp(address account, bytes32 currencyKey) external view returns (uint);

    // Mutative functions
    function appendExchangeEntry(
        address account,
        bytes32 src,
        uint amount,
        bytes32 dest,
        uint amountReceived,
        uint exchangeFeeRate,
        uint timestamp,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external;

    function removeEntries(address account, bytes32 currencyKey) external;
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/exchangestate
contract ExchangeState is Owned, State, IExchangeState {
    mapping(address => mapping(bytes32 => IExchangeState.ExchangeEntry[])) public exchanges;

    uint public maxEntriesInQueue = 12;

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    /* ========== SETTERS ========== */

    function setMaxEntriesInQueue(uint _maxEntriesInQueue) external onlyOwner {
        maxEntriesInQueue = _maxEntriesInQueue;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function appendExchangeEntry(
        address account,
        bytes32 src,
        uint amount,
        bytes32 dest,
        uint amountReceived,
        uint exchangeFeeRate,
        uint timestamp,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external onlyAssociatedContract {
        require(exchanges[account][dest].length < maxEntriesInQueue, "Max queue length reached");

        exchanges[account][dest].push(
            ExchangeEntry({
                src: src,
                amount: amount,
                dest: dest,
                amountReceived: amountReceived,
                exchangeFeeRate: exchangeFeeRate,
                timestamp: timestamp,
                roundIdForSrc: roundIdForSrc,
                roundIdForDest: roundIdForDest
            })
        );
    }

    function removeEntries(address account, bytes32 currencyKey) external onlyAssociatedContract {
        delete exchanges[account][currencyKey];
    }

    /* ========== VIEWS ========== */

    function getLengthOfEntries(address account, bytes32 currencyKey) external view returns (uint) {
        return exchanges[account][currencyKey].length;
    }

    function getEntryAt(
        address account,
        bytes32 currencyKey,
        uint index
    )
        external
        view
        returns (
            bytes32 src,
            uint amount,
            bytes32 dest,
            uint amountReceived,
            uint exchangeFeeRate,
            uint timestamp,
            uint roundIdForSrc,
            uint roundIdForDest
        )
    {
        ExchangeEntry storage entry = exchanges[account][currencyKey][index];
        return (
            entry.src,
            entry.amount,
            entry.dest,
            entry.amountReceived,
            entry.exchangeFeeRate,
            entry.timestamp,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );
    }

    function getMaxTimestamp(address account, bytes32 currencyKey) external view returns (uint) {
        ExchangeEntry[] storage userEntries = exchanges[account][currencyKey];
        uint timestamp = 0;
        for (uint i = 0; i < userEntries.length; i++) {
            if (userEntries[i].timestamp > timestamp) {
                timestamp = userEntries[i].timestamp;
            }
        }
        return timestamp;
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/systemstatus
contract SystemStatus is Owned, ISystemStatus {
    mapping(bytes32 => mapping(address => Status)) public accessControl;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_ISSUANCE = "Issuance";
    bytes32 public constant SECTION_EXCHANGE = "Exchange";
    bytes32 public constant SECTION_SYNTH_EXCHANGE = "SynthExchange";
    bytes32 public constant SECTION_SYNTH = "Synth";

    Suspension public systemSuspension;

    Suspension public issuanceSuspension;

    Suspension public exchangeSuspension;

    mapping(bytes32 => Suspension) public synthExchangeSuspension;

    mapping(bytes32 => Suspension) public synthSuspension;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== VIEWS ========== */
    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function requireIssuanceActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();

        // and issuance itself of course
        _internalRequireIssuanceActive();
    }

    function requireExchangeActive() external view {
        // Exchanging requires the system be active
        _internalRequireSystemActive();

        // and exchanging itself of course
        _internalRequireExchangeActive();
    }

    function requireSynthExchangeActive(bytes32 currencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireSynthExchangeActive(currencyKey);
    }

    function requireSynthActive(bytes32 currencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireSynthActive(currencyKey);
    }

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequireSynthActive(sourceCurrencyKey);
        _internalRequireSynthActive(destinationCurrencyKey);
    }

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Synth exchange and transfer requires the system be active
        _internalRequireSystemActive();

        // and exchanging must be active
        _internalRequireExchangeActive();

        // and the synth exchanging between the synths must be active
        _internalRequireSynthExchangeActive(sourceCurrencyKey);
        _internalRequireSynthExchangeActive(destinationCurrencyKey);

        // and finally, the synths cannot be suspended
        _internalRequireSynthActive(sourceCurrencyKey);
        _internalRequireSynthActive(destinationCurrencyKey);
    }

    function isSystemUpgrading() external view returns (bool) {
        return systemSuspension.suspended && systemSuspension.reason == SUSPENSION_REASON_UPGRADE;
    }

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons)
    {
        exchangeSuspensions = new bool[](synths.length);
        reasons = new uint256[](synths.length);

        for (uint i = 0; i < synths.length; i++) {
            exchangeSuspensions[i] = synthExchangeSuspension[synths[i]].suspended;
            reasons[i] = synthExchangeSuspension[synths[i]].reason;
        }
    }

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](synths.length);
        reasons = new uint256[](synths.length);

        for (uint i = 0; i < synths.length; i++) {
            suspensions[i] = synthSuspension[synths[i]].suspended;
            reasons[i] = synthSuspension[synths[i]].reason;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateAccessControl(section, account, canSuspend, canResume);
    }

    function updateAccessControls(
        bytes32[] calldata sections,
        address[] calldata accounts,
        bool[] calldata canSuspends,
        bool[] calldata canResumes
    ) external onlyOwner {
        require(
            sections.length == accounts.length &&
                accounts.length == canSuspends.length &&
                canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
        for (uint i = 0; i < sections.length; i++) {
            _internalUpdateAccessControl(sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    function suspendSystem(uint256 reason) external {
        _requireAccessToSuspend(SECTION_SYSTEM);
        systemSuspension.suspended = true;
        systemSuspension.reason = uint248(reason);
        emit SystemSuspended(systemSuspension.reason);
    }

    function resumeSystem() external {
        _requireAccessToResume(SECTION_SYSTEM);
        systemSuspension.suspended = false;
        emit SystemResumed(uint256(systemSuspension.reason));
        systemSuspension.reason = 0;
    }

    function suspendIssuance(uint256 reason) external {
        _requireAccessToSuspend(SECTION_ISSUANCE);
        issuanceSuspension.suspended = true;
        issuanceSuspension.reason = uint248(reason);
        emit IssuanceSuspended(reason);
    }

    function resumeIssuance() external {
        _requireAccessToResume(SECTION_ISSUANCE);
        issuanceSuspension.suspended = false;
        emit IssuanceResumed(uint256(issuanceSuspension.reason));
        issuanceSuspension.reason = 0;
    }

    function suspendExchange(uint256 reason) external {
        _requireAccessToSuspend(SECTION_EXCHANGE);
        exchangeSuspension.suspended = true;
        exchangeSuspension.reason = uint248(reason);
        emit ExchangeSuspended(reason);
    }

    function resumeExchange() external {
        _requireAccessToResume(SECTION_EXCHANGE);
        exchangeSuspension.suspended = false;
        emit ExchangeResumed(uint256(exchangeSuspension.reason));
        exchangeSuspension.reason = 0;
    }

    function suspendSynthExchange(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendSynthExchange(currencyKeys, reason);
    }

    function suspendSynthsExchange(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendSynthExchange(currencyKeys, reason);
    }

    function resumeSynthExchange(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumeSynthsExchange(currencyKeys);
    }

    function resumeSynthsExchange(bytes32[] calldata currencyKeys) external {
        _internalResumeSynthsExchange(currencyKeys);
    }

    function suspendSynth(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendSynths(currencyKeys, reason);
    }

    function suspendSynths(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendSynths(currencyKeys, reason);
    }

    function resumeSynth(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumeSynths(currencyKeys);
    }

    function resumeSynths(bytes32[] calldata currencyKeys) external {
        _internalResumeSynths(currencyKeys);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireAccessToSuspend(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireAccessToResume(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canResume, "Restricted to access control list");
    }

    function _internalRequireSystemActive() internal view {
        require(
            !systemSuspension.suspended,
            systemSuspension.reason == SUSPENSION_REASON_UPGRADE
                ? "Synthetix is suspended, upgrade in progress... please stand by"
                : "Synthetix is suspended. Operation prohibited"
        );
    }

    function _internalRequireIssuanceActive() internal view {
        require(!issuanceSuspension.suspended, "Issuance is suspended. Operation prohibited");
    }

    function _internalRequireExchangeActive() internal view {
        require(!exchangeSuspension.suspended, "Exchange is suspended. Operation prohibited");
    }

    function _internalRequireSynthExchangeActive(bytes32 currencyKey) internal view {
        require(!synthExchangeSuspension[currencyKey].suspended, "Synth exchange suspended. Operation prohibited");
    }

    function _internalRequireSynthActive(bytes32 currencyKey) internal view {
        require(!synthSuspension[currencyKey].suspended, "Synth is suspended. Operation prohibited");
    }

    function _internalSuspendSynths(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_SYNTH);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            synthSuspension[currencyKey].suspended = true;
            synthSuspension[currencyKey].reason = uint248(reason);
            emit SynthSuspended(currencyKey, reason);
        }
    }

    function _internalResumeSynths(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_SYNTH);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit SynthResumed(currencyKey, uint256(synthSuspension[currencyKey].reason));
            delete synthSuspension[currencyKey];
        }
    }

    function _internalSuspendSynthExchange(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_SYNTH_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            synthExchangeSuspension[currencyKey].suspended = true;
            synthExchangeSuspension[currencyKey].reason = uint248(reason);
            emit SynthExchangeSuspended(currencyKey, reason);
        }
    }

    function _internalResumeSynthsExchange(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_SYNTH_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit SynthExchangeResumed(currencyKey, uint256(synthExchangeSuspension[currencyKey].reason));
            delete synthExchangeSuspension[currencyKey];
        }
    }

    function _internalUpdateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal {
        require(
            section == SECTION_SYSTEM ||
                section == SECTION_ISSUANCE ||
                section == SECTION_EXCHANGE ||
                section == SECTION_SYNTH_EXCHANGE ||
                section == SECTION_SYNTH,
            "Invalid section supplied"
        );
        accessControl[section][account].canSuspend = canSuspend;
        accessControl[section][account].canResume = canResume;
        emit AccessControlUpdated(section, account, canSuspend, canResume);
    }

    /* ========== EVENTS ========== */

    event SystemSuspended(uint256 reason);
    event SystemResumed(uint256 reason);

    event IssuanceSuspended(uint256 reason);
    event IssuanceResumed(uint256 reason);

    event ExchangeSuspended(uint256 reason);
    event ExchangeResumed(uint256 reason);

    event SynthExchangeSuspended(bytes32 currencyKey, uint256 reason);
    event SynthExchangeResumed(bytes32 currencyKey, uint256 reason);

    event SynthSuspended(bytes32 currencyKey, uint256 reason);
    event SynthResumed(bytes32 currencyKey, uint256 reason);

    event AccessControlUpdated(bytes32 indexed section, address indexed account, bool canSuspend, bool canResume);
}


// https://docs.synthetix.io/contracts/source/interfaces/iflexiblestorage
interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int[] calldata values
    ) external;

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external;

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external;

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external;

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external;

    function setBytes32Value(
        bytes32 contractName,
        bytes32 record,
        bytes32 value
    ) external;

    function setBytes32Values(
        bytes32 contractName,
        bytes32[] calldata records,
        bytes32[] calldata values
    ) external;
}


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/mixinsystemsettings
contract MixinSystemSettings is MixinResolver {
    // must match the one defined SystemSettingsLib, defined in both places due to sol v0.5 limitations
    bytes32 internal constant SETTING_CONTRACT_NAME = "SystemSettings";

    bytes32 internal constant SETTING_WAITING_PERIOD_SECS = "waitingPeriodSecs";
    bytes32 internal constant SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR = "priceDeviationThresholdFactor";
    bytes32 internal constant SETTING_ISSUANCE_RATIO = "issuanceRatio";
    bytes32 internal constant SETTING_FEE_PERIOD_DURATION = "feePeriodDuration";
    bytes32 internal constant SETTING_TARGET_THRESHOLD = "targetThreshold";
    bytes32 internal constant SETTING_LIQUIDATION_DELAY = "liquidationDelay";
    bytes32 internal constant SETTING_LIQUIDATION_RATIO = "liquidationRatio";
    bytes32 internal constant SETTING_LIQUIDATION_PENALTY = "liquidationPenalty";
    bytes32 internal constant SETTING_RATE_STALE_PERIOD = "rateStalePeriod";
    /* ========== Exchange Fees Related ========== */
    bytes32 internal constant SETTING_EXCHANGE_FEE_RATE = "exchangeFeeRate";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD = "exchangeDynamicFeeThreshold";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY = "exchangeDynamicFeeWeightDecay";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS = "exchangeDynamicFeeRounds";
    bytes32 internal constant SETTING_EXCHANGE_MAX_DYNAMIC_FEE = "exchangeMaxDynamicFee";
    /* ========== End Exchange Fees Related ========== */
    bytes32 internal constant SETTING_MINIMUM_STAKE_TIME = "minimumStakeTime";
    bytes32 internal constant SETTING_AGGREGATOR_WARNING_FLAGS = "aggregatorWarningFlags";
    bytes32 internal constant SETTING_TRADING_REWARDS_ENABLED = "tradingRewardsEnabled";
    bytes32 internal constant SETTING_DEBT_SNAPSHOT_STALE_TIME = "debtSnapshotStaleTime";
    bytes32 internal constant SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT = "crossDomainDepositGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT = "crossDomainEscrowGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT = "crossDomainRewardGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT = "crossDomainWithdrawalGasLimit";
    bytes32 internal constant SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT = "crossDomainRelayGasLimit";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MAX_ETH = "etherWrapperMaxETH";
    bytes32 internal constant SETTING_ETHER_WRAPPER_MINT_FEE_RATE = "etherWrapperMintFeeRate";
    bytes32 internal constant SETTING_ETHER_WRAPPER_BURN_FEE_RATE = "etherWrapperBurnFeeRate";
    bytes32 internal constant SETTING_WRAPPER_MAX_TOKEN_AMOUNT = "wrapperMaxTokens";
    bytes32 internal constant SETTING_WRAPPER_MINT_FEE_RATE = "wrapperMintFeeRate";
    bytes32 internal constant SETTING_WRAPPER_BURN_FEE_RATE = "wrapperBurnFeeRate";
    bytes32 internal constant SETTING_INTERACTION_DELAY = "interactionDelay";
    bytes32 internal constant SETTING_COLLAPSE_FEE_RATE = "collapseFeeRate";
    bytes32 internal constant SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK = "atomicMaxVolumePerBlock";
    bytes32 internal constant SETTING_ATOMIC_TWAP_WINDOW = "atomicTwapWindow";
    bytes32 internal constant SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING = "atomicEquivalentForDexPricing";
    bytes32 internal constant SETTING_ATOMIC_EXCHANGE_FEE_RATE = "atomicExchangeFeeRate";
    bytes32 internal constant SETTING_ATOMIC_PRICE_BUFFER = "atomicPriceBuffer";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = "atomicVolConsiderationWindow";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD = "atomicVolUpdateThreshold";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    enum CrossDomainMessageGasLimits {Deposit, Escrow, Reward, Withdrawal, Relay}

    struct DynamicFeeConfig {
        uint threshold;
        uint weightDecay;
        uint rounds;
        uint maxFee;
    }

    constructor(address _resolver) internal MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function _getGasLimitSetting(CrossDomainMessageGasLimits gasLimitType) internal pure returns (bytes32) {
        if (gasLimitType == CrossDomainMessageGasLimits.Deposit) {
            return SETTING_CROSS_DOMAIN_DEPOSIT_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Escrow) {
            return SETTING_CROSS_DOMAIN_ESCROW_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Reward) {
            return SETTING_CROSS_DOMAIN_REWARD_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Withdrawal) {
            return SETTING_CROSS_DOMAIN_WITHDRAWAL_GAS_LIMIT;
        } else if (gasLimitType == CrossDomainMessageGasLimits.Relay) {
            return SETTING_CROSS_DOMAIN_RELAY_GAS_LIMIT;
        } else {
            revert("Unknown gas limit type");
        }
    }

    function getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, _getGasLimitSetting(gasLimitType));
    }

    function getTradingRewardsEnabled() internal view returns (bool) {
        return flexibleStorage().getBoolValue(SETTING_CONTRACT_NAME, SETTING_TRADING_REWARDS_ENABLED);
    }

    function getWaitingPeriodSecs() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS);
    }

    function getPriceDeviationThresholdFactor() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR);
    }

    function getIssuanceRatio() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ISSUANCE_RATIO);
    }

    function getFeePeriodDuration() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_FEE_PERIOD_DURATION);
    }

    function getTargetThreshold() internal view returns (uint) {
        // lookup on flexible storage directly for gas savings (rather than via SystemSettings)
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_TARGET_THRESHOLD);
    }

    function getLiquidationDelay() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_DELAY);
    }

    function getLiquidationRatio() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_RATIO);
    }

    function getLiquidationPenalty() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_PENALTY);
    }

    function getRateStalePeriod() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    /* ========== Exchange Related Fees ========== */
    function getExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    /// @notice Get exchange dynamic fee related keys
    /// @return threshold, weight decay, rounds, and max fee
    function getExchangeDynamicFeeConfig() internal view returns (DynamicFeeConfig memory) {
        bytes32[] memory keys = new bytes32[](4);
        keys[0] = SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD;
        keys[1] = SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY;
        keys[2] = SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS;
        keys[3] = SETTING_EXCHANGE_MAX_DYNAMIC_FEE;
        uint[] memory values = flexibleStorage().getUIntValues(SETTING_CONTRACT_NAME, keys);
        return DynamicFeeConfig({threshold: values[0], weightDecay: values[1], rounds: values[2], maxFee: values[3]});
    }

    /* ========== End Exchange Related Fees ========== */

    function getMinimumStakeTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MINIMUM_STAKE_TIME);
    }

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }

    function getDebtSnapshotStaleTime() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_DEBT_SNAPSHOT_STALE_TIME);
    }

    function getEtherWrapperMaxETH() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MAX_ETH);
    }

    function getEtherWrapperMintFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_MINT_FEE_RATE);
    }

    function getEtherWrapperBurnFeeRate() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ETHER_WRAPPER_BURN_FEE_RATE);
    }

    function getWrapperMaxTokenAmount(address wrapper) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_MAX_TOKEN_AMOUNT, wrapper))
            );
    }

    function getWrapperMintFeeRate(address wrapper) internal view returns (int) {
        return
            flexibleStorage().getIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_MINT_FEE_RATE, wrapper))
            );
    }

    function getWrapperBurnFeeRate(address wrapper) internal view returns (int) {
        return
            flexibleStorage().getIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_WRAPPER_BURN_FEE_RATE, wrapper))
            );
    }

    function getInteractionDelay(address collateral) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_INTERACTION_DELAY, collateral))
            );
    }

    function getCollapseFeeRate(address collateral) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_COLLAPSE_FEE_RATE, collateral))
            );
    }

    function getAtomicMaxVolumePerBlock() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK);
    }

    function getAtomicTwapWindow() internal view returns (uint) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_TWAP_WINDOW);
    }

    function getAtomicEquivalentForDexPricing(bytes32 currencyKey) internal view returns (address) {
        return
            flexibleStorage().getAddressValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING, currencyKey))
            );
    }

    function getAtomicExchangeFeeRate(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    function getAtomicPriceBuffer(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_PRICE_BUFFER, currencyKey))
            );
    }

    function getAtomicVolatilityConsiderationWindow(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW, currencyKey))
            );
    }

    function getAtomicVolatilityUpdateThreshold(bytes32 currencyKey) internal view returns (uint) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD, currencyKey))
            );
    }
}


// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);
}


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Libraries


// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
}


interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
  //
  // V2 Interface:
  //
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  //
  // V3 Interface:
  //
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


interface FlagsInterface {
  function getFlag(address) external view returns (bool);
  function getFlags(address[] calldata) external view returns (bool[] memory);
  function raiseFlag(address) external;
  function raiseFlags(address[] calldata) external;
  function lowerFlags(address[] calldata) external;
  function setRaisingAccessController(address) external;
}


interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint amount;
        bytes32 dest;
        uint reclaim;
        uint rebate;
        uint srcRoundIdAtPeriodEnd;
        uint destRoundIdAtPeriodEnd;
        uint timestamp;
    }

    struct ExchangeEntry {
        uint sourceRate;
        uint destinationRate;
        uint destinationAmount;
        uint exchangeFeeRate;
        uint exchangeDynamicFeeRate;
        uint roundIdForSrc;
        uint roundIdForDest;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) external view returns (uint amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate, bool tooVolatile);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    // Mutative functions
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualSynth,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function resetLastExchangeRate(bytes32[] calldata currencyKeys) external;

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;
}


// Inheritance


// Libraries


// Internal references
// AggregatorInterface from Chainlink represents a decentralized pricing network for a single currency key

// FlagsInterface from Chainlink addresses SIP-76


// https://docs.synthetix.io/contracts/source/contracts/exchangerates
contract ExchangeRates is Owned, MixinSystemSettings, IExchangeRates {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "ExchangeRates";
    //slither-disable-next-line naming-convention
    bytes32 internal constant sUSD = "sUSD";

    // Decentralized oracle networks that feed into pricing aggregators
    mapping(bytes32 => AggregatorV2V3Interface) public aggregators;

    mapping(bytes32 => uint8) public currencyKeyDecimals;

    // List of aggregator keys for convenient iteration
    bytes32[] public aggregatorKeys;

    // ========== CONSTRUCTOR ==========

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external onlyOwner {
        AggregatorV2V3Interface aggregator = AggregatorV2V3Interface(aggregatorAddress);
        // This check tries to make sure that a valid aggregator is being added.
        // It checks if the aggregator is an existing smart contract that has implemented `latestTimestamp` function.

        require(aggregator.latestRound() >= 0, "Given Aggregator is invalid");
        uint8 decimals = aggregator.decimals();
        require(decimals <= 18, "Aggregator decimals should be lower or equal to 18");
        if (address(aggregators[currencyKey]) == address(0)) {
            aggregatorKeys.push(currencyKey);
        }
        aggregators[currencyKey] = aggregator;
        currencyKeyDecimals[currencyKey] = decimals;
        emit AggregatorAdded(currencyKey, address(aggregator));
    }

    function removeAggregator(bytes32 currencyKey) external onlyOwner {
        address aggregator = address(aggregators[currencyKey]);
        require(aggregator != address(0), "No aggregator exists for key");
        delete aggregators[currencyKey];
        delete currencyKeyDecimals[currencyKey];

        bool wasRemoved = removeFromArray(currencyKey, aggregatorKeys);

        if (wasRemoved) {
            emit AggregatorRemoved(currencyKey, aggregator);
        }
    }

    /* ========== VIEWS ========== */

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory currencies) {
        uint count = 0;
        currencies = new bytes32[](aggregatorKeys.length);
        for (uint i = 0; i < aggregatorKeys.length; i++) {
            bytes32 currencyKey = aggregatorKeys[i];
            if (address(aggregators[currencyKey]) == aggregator) {
                currencies[count++] = currencyKey;
            }
        }
    }

    function rateStalePeriod() external view returns (uint) {
        return getRateStalePeriod();
    }

    function aggregatorWarningFlags() external view returns (address) {
        return getAggregatorWarningFlags();
    }

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time) {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(currencyKey);
        return (rateAndTime.rate, rateAndTime.time);
    }

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint) {
        uint roundId = startingRoundId;
        uint nextTimestamp = 0;
        while (true) {
            (, nextTimestamp) = _getRateAndTimestampAtRound(currencyKey, roundId + 1);
            // if there's no new round, then the previous roundId was the latest
            if (nextTimestamp == 0 || nextTimestamp > startingTimestamp + timediff) {
                return roundId;
            }
            roundId++;
        }
        return roundId;
    }

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint) {
        return _getCurrentRoundId(currencyKey);
    }

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        (sourceRate, ) = _getRateAndTimestampAtRound(sourceCurrencyKey, roundIdForSrc);
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) {
            destinationRate = sourceRate;
            value = sourceAmount;
        } else {
            (destinationRate, ) = _getRateAndTimestampAtRound(destinationCurrencyKey, roundIdForDest);
            // prevent divide-by 0 error (this happens if the dest is not a valid rate)
            if (destinationRate > 0) {
                // Calculate the effective value by going from source -> USD -> destination
                value = sourceAmount.multiplyDecimalRound(sourceRate).divideDecimalRound(destinationRate);
            }
        }
    }

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time) {
        return _getRateAndTimestampAtRound(currencyKey, roundId);
    }

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256) {
        return _getUpdatedTime(currencyKey);
    }

    function lastRateUpdateTimesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory) {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = _getUpdatedTime(currencyKeys[i]);
        }

        return lastUpdateTimes;
    }

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value) {
        (value, , ) = _effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        return _effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    // SIP-120 Atomic exchanges
    function effectiveAtomicValueAndRates(
        bytes32,
        uint,
        bytes32
    )
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        _notImplemented();
    }

    function rateForCurrency(bytes32 currencyKey) external view returns (uint) {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    /// @notice getting N rounds of rates for a currency at a specific round
    /// @param currencyKey the currency key
    /// @param numRounds the number of rounds to get
    /// @param roundId the round id
    /// @return a list of rates and a list of times
    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times) {
        rates = new uint[](numRounds);
        times = new uint[](numRounds);

        roundId = roundId > 0 ? roundId : _getCurrentRoundId(currencyKey);
        for (uint i = 0; i < numRounds; i++) {
            // fetch the rate and treat is as current, so inverse limits if frozen will always be applied
            // regardless of current rate
            (rates[i], times[i]) = _getRateAndTimestampAtRound(currencyKey, roundId);

            if (roundId == 0) {
                // if we hit the last round, then return what we have
                return (rates, times);
            } else {
                roundId--;
            }
        }
    }

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory) {
        uint[] memory _localRates = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            _localRates[i] = _getRate(currencyKeys[i]);
        }

        return _localRates;
    }

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid) {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(currencyKey);

        if (currencyKey == sUSD) {
            return (rateAndTime.rate, false);
        }
        return (
            rateAndTime.rate,
            _rateIsStaleWithTime(getRateStalePeriod(), rateAndTime.time) ||
                _rateIsFlagged(currencyKey, FlagsInterface(getAggregatorWarningFlags()))
        );
    }

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid)
    {
        rates = new uint[](currencyKeys.length);

        uint256 _rateStalePeriod = getRateStalePeriod();

        // fetch all flags at once
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint i = 0; i < currencyKeys.length; i++) {
            // do one lookup of the rate & time to minimize gas
            RateAndUpdatedTime memory rateEntry = _getRateAndUpdatedTime(currencyKeys[i]);
            rates[i] = rateEntry.rate;
            if (!anyRateInvalid && currencyKeys[i] != sUSD) {
                anyRateInvalid = flagList[i] || _rateIsStaleWithTime(_rateStalePeriod, rateEntry.time);
            }
        }
    }

    function rateIsStale(bytes32 currencyKey) external view returns (bool) {
        return _rateIsStale(currencyKey, getRateStalePeriod());
    }

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool) {
        return
            _rateIsStale(currencyKey, getRateStalePeriod()) ||
            _rateIsFlagged(currencyKey, FlagsInterface(getAggregatorWarningFlags()));
    }

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool) {
        return _rateIsFlagged(currencyKey, FlagsInterface(getAggregatorWarningFlags()));
    }

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool) {
        // Loop through each key and check whether the data point is stale.

        uint256 _rateStalePeriod = getRateStalePeriod();
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint i = 0; i < currencyKeys.length; i++) {
            if (flagList[i] || _rateIsStale(currencyKeys[i], _rateStalePeriod)) {
                return true;
            }
        }

        return false;
    }

    /// this method checks whether any rate is:
    /// 1. flagged
    /// 2. stale with respect to current time (now)
    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds)
        external
        view
        returns (bool)
    {
        // Loop through each key and check whether the data point is stale.

        require(roundIds.length == currencyKeys.length, "roundIds must be the same length as currencyKeys");

        uint256 _rateStalePeriod = getRateStalePeriod();
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint i = 0; i < currencyKeys.length; i++) {
            if (flagList[i] || _rateIsStaleAtRound(currencyKeys[i], roundIds[i], _rateStalePeriod)) {
                return true;
            }
        }

        return false;
    }

    function synthTooVolatileForAtomicExchange(bytes32) external view returns (bool) {
        _notImplemented();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function getFlagsForRates(bytes32[] memory currencyKeys) internal view returns (bool[] memory flagList) {
        FlagsInterface _flags = FlagsInterface(getAggregatorWarningFlags());

        // fetch all flags at once
        if (_flags != FlagsInterface(0)) {
            address[] memory _aggregators = new address[](currencyKeys.length);

            for (uint i = 0; i < currencyKeys.length; i++) {
                _aggregators[i] = address(aggregators[currencyKeys[i]]);
            }

            flagList = _flags.getFlags(_aggregators);
        } else {
            flagList = new bool[](currencyKeys.length);
        }
    }

    function removeFromArray(bytes32 entry, bytes32[] storage array) internal returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == entry) {
                delete array[i];

                // Copy the last key into the place of the one we just deleted
                // If there's only one key, this is array[0] = array[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                array[i] = array[array.length - 1];

                // Decrease the size of the array by one.
                array.length--;

                return true;
            }
        }
        return false;
    }

    function _formatAggregatorAnswer(bytes32 currencyKey, int256 rate) internal view returns (uint) {
        require(rate >= 0, "Negative rate not supported");
        if (currencyKeyDecimals[currencyKey] > 0) {
            uint multiplier = 10**uint(SafeMath.sub(18, currencyKeyDecimals[currencyKey]));
            return uint(uint(rate).mul(multiplier));
        }
        return uint(rate);
    }

    function _getRateAndUpdatedTime(bytes32 currencyKey) internal view returns (RateAndUpdatedTime memory) {
        // sUSD rate is 1.0
        if (currencyKey == sUSD) {
            return RateAndUpdatedTime({rate: uint216(SafeDecimalMath.unit()), time: 0});
        } else {
            AggregatorV2V3Interface aggregator = aggregators[currencyKey];
            if (aggregator != AggregatorV2V3Interface(0)) {
                // this view from the aggregator is the most gas efficient but it can throw when there's no data,
                // so let's call it low-level to suppress any reverts
                bytes memory payload = abi.encodeWithSignature("latestRoundData()");
                // solhint-disable avoid-low-level-calls
                // slither-disable-next-line low-level-calls
                (bool success, bytes memory returnData) = address(aggregator).staticcall(payload);

                if (success) {
                    (, int256 answer, , uint256 updatedAt, ) =
                        abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));
                    return
                        RateAndUpdatedTime({
                            rate: uint216(_formatAggregatorAnswer(currencyKey, answer)),
                            time: uint40(updatedAt)
                        });
                } // else return defaults, to avoid reverting in views
            } // else return defaults, to avoid reverting in views
        }
    }

    function _getCurrentRoundId(bytes32 currencyKey) internal view returns (uint) {
        if (currencyKey == sUSD) {
            return 0;
        }
        AggregatorV2V3Interface aggregator = aggregators[currencyKey];
        if (aggregator != AggregatorV2V3Interface(0)) {
            return aggregator.latestRound();
        } // else return defaults, to avoid reverting in views
    }

    function _getRateAndTimestampAtRound(bytes32 currencyKey, uint roundId) internal view returns (uint rate, uint time) {
        // short circuit sUSD
        if (currencyKey == sUSD) {
            // sUSD has no rounds, and 0 time is preferrable for "volatility" heuristics
            // which are used in atomic swaps and fee reclamation
            return (SafeDecimalMath.unit(), 0);
        } else {
            AggregatorV2V3Interface aggregator = aggregators[currencyKey];
            if (aggregator != AggregatorV2V3Interface(0)) {
                // this view from the aggregator is the most gas efficient but it can throw when there's no data,
                // so let's call it low-level to suppress any reverts
                bytes memory payload = abi.encodeWithSignature("getRoundData(uint80)", roundId);
                // solhint-disable avoid-low-level-calls
                (bool success, bytes memory returnData) = address(aggregator).staticcall(payload);

                if (success) {
                    (, int256 answer, , uint256 updatedAt, ) =
                        abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));
                    return (_formatAggregatorAnswer(currencyKey, answer), updatedAt);
                } // else return defaults, to avoid reverting in views
            } // else return defaults, to avoid reverting in views
        }
    }

    function _getRate(bytes32 currencyKey) internal view returns (uint256) {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    function _getUpdatedTime(bytes32 currencyKey) internal view returns (uint256) {
        return _getRateAndUpdatedTime(currencyKey).time;
    }

    function _effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        internal
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        sourceRate = _getRate(sourceCurrencyKey);
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) {
            destinationRate = sourceRate;
            value = sourceAmount;
        } else {
            // Calculate the effective value by going from source -> USD -> destination
            destinationRate = _getRate(destinationCurrencyKey);
            // prevent divide-by 0 error (this happens if the dest is not a valid rate)
            if (destinationRate > 0) {
                value = sourceAmount.multiplyDecimalRound(sourceRate).divideDecimalRound(destinationRate);
            }
        }
    }

    function _rateIsStale(bytes32 currencyKey, uint _rateStalePeriod) internal view returns (bool) {
        // sUSD is a special case and is never stale (check before an SLOAD of getRateAndUpdatedTime)
        if (currencyKey == sUSD) {
            return false;
        }
        return _rateIsStaleWithTime(_rateStalePeriod, _getUpdatedTime(currencyKey));
    }

    function _rateIsStaleAtRound(
        bytes32 currencyKey,
        uint roundId,
        uint _rateStalePeriod
    ) internal view returns (bool) {
        // sUSD is a special case and is never stale (check before an SLOAD of getRateAndUpdatedTime)
        if (currencyKey == sUSD) {
            return false;
        }
        (, uint time) = _getRateAndTimestampAtRound(currencyKey, roundId);
        return _rateIsStaleWithTime(_rateStalePeriod, time);
    }

    function _rateIsStaleWithTime(uint _rateStalePeriod, uint _time) internal view returns (bool) {
        return _time.add(_rateStalePeriod) < now;
    }

    function _rateIsFlagged(bytes32 currencyKey, FlagsInterface flags) internal view returns (bool) {
        // sUSD is a special case and is never invalid
        if (currencyKey == sUSD) {
            return false;
        }
        address aggregator = address(aggregators[currencyKey]);
        // when no aggregator or when the flags haven't been setup
        if (aggregator == address(0) || flags == FlagsInterface(0)) {
            return false;
        }
        return flags.getFlag(aggregator);
    }

    function _notImplemented() internal pure {
        // slither-disable-next-line dead-code
        revert("Cannot be run on this layer");
    }

    /* ========== EVENTS ========== */

    event AggregatorAdded(bytes32 currencyKey, address aggregator);
    event AggregatorRemoved(bytes32 currencyKey, address aggregator);
}


// https://sips.synthetix.io/sips/sip-120/
// Uniswap V3 based DecPriceAggregator (unaudited) e.g. https://etherscan.io/address/0xf120f029ac143633d1942e48ae2dfa2036c5786c#code
// https://github.com/sohkai/uniswap-v3-spot-twap-oracle
//  inteface: https://github.com/sohkai/uniswap-v3-spot-twap-oracle/blob/8f9777a6160a089c99f39f2ee297119ee293bc4b/contracts/interfaces/IDexPriceAggregator.sol
//  implementation: https://github.com/sohkai/uniswap-v3-spot-twap-oracle/blob/8f9777a6160a089c99f39f2ee297119ee293bc4b/contracts/DexPriceAggregatorUniswapV3.sol
interface IDexPriceAggregator {
    function assetToAsset(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint twapPeriod
    ) external view returns (uint amountOut);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/exchangerateswithdexpricing
contract ExchangeRatesWithDexPricing is ExchangeRates {
    bytes32 public constant CONTRACT_NAME = "ExchangeRatesWithDexPricing";

    bytes32 internal constant SETTING_DEX_PRICE_AGGREGATOR = "dexPriceAggregator";

    constructor(address _owner, address _resolver) public ExchangeRates(_owner, _resolver) {}

    /* ========== SETTERS ========== */

    function setDexPriceAggregator(IDexPriceAggregator _dexPriceAggregator) external onlyOwner {
        flexibleStorage().setAddressValue(
            ExchangeRates.CONTRACT_NAME,
            SETTING_DEX_PRICE_AGGREGATOR,
            address(_dexPriceAggregator)
        );
        emit DexPriceAggregatorUpdated(address(_dexPriceAggregator));
    }

    /* ========== VIEWS ========== */

    function dexPriceAggregator() public view returns (IDexPriceAggregator) {
        return
            IDexPriceAggregator(
                flexibleStorage().getAddressValue(ExchangeRates.CONTRACT_NAME, SETTING_DEX_PRICE_AGGREGATOR)
            );
    }

    function atomicTwapWindow() external view returns (uint) {
        return getAtomicTwapWindow();
    }

    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address) {
        return getAtomicEquivalentForDexPricing(currencyKey);
    }

    function atomicPriceBuffer(bytes32 currencyKey) external view returns (uint) {
        return getAtomicPriceBuffer(currencyKey);
    }

    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityConsiderationWindow(currencyKey);
    }

    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityUpdateThreshold(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // Note that the returned systemValue, systemSourceRate, and systemDestinationRate are based on
    // the current system rate, which may not be the atomic rate derived from value / sourceAmount
    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        )
    {
        IERC20 sourceEquivalent = IERC20(getAtomicEquivalentForDexPricing(sourceCurrencyKey));
        require(address(sourceEquivalent) != address(0), "No atomic equivalent for src");

        IERC20 destEquivalent = IERC20(getAtomicEquivalentForDexPricing(destinationCurrencyKey));
        require(address(destEquivalent) != address(0), "No atomic equivalent for dest");

        (systemValue, systemSourceRate, systemDestinationRate) = _effectiveValueAndRates(
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey
        );
        // Derive P_CLBUF from highest configured buffer between source and destination synth
        uint sourceBuffer = getAtomicPriceBuffer(sourceCurrencyKey);
        uint destBuffer = getAtomicPriceBuffer(destinationCurrencyKey);
        uint priceBuffer = sourceBuffer > destBuffer ? sourceBuffer : destBuffer; // max
        uint pClbufValue = systemValue.multiplyDecimal(SafeDecimalMath.unit().sub(priceBuffer));

        // refactired due to stack too deep
        uint pDexValue = _dexPriceDestinationValue(sourceEquivalent, destEquivalent, sourceAmount);

        // Final value is minimum output between P_CLBUF and P_TWAP
        value = pClbufValue < pDexValue ? pClbufValue : pDexValue; // min
    }

    function _dexPriceDestinationValue(
        IERC20 sourceEquivalent,
        IERC20 destEquivalent,
        uint sourceAmount
    ) internal view returns (uint) {
        // Normalize decimals in case equivalent asset uses different decimals from internal unit
        uint sourceAmountInEquivalent =
            (sourceAmount.mul(10**uint(sourceEquivalent.decimals()))).div(SafeDecimalMath.unit());

        uint twapWindow = getAtomicTwapWindow();
        require(twapWindow != 0, "Uninitialized atomic twap window");

        uint twapValueInEquivalent =
            dexPriceAggregator().assetToAsset(
                address(sourceEquivalent),
                sourceAmountInEquivalent,
                address(destEquivalent),
                twapWindow
            );
        require(twapValueInEquivalent > 0, "dex price returned 0");

        // Similar to source amount, normalize decimals back to internal unit for output amount
        return (twapValueInEquivalent.mul(SafeDecimalMath.unit())).div(10**uint(destEquivalent.decimals()));
    }

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool) {
        // sUSD is a special case and is never volatile
        if (currencyKey == "sUSD") return false;

        uint considerationWindow = getAtomicVolatilityConsiderationWindow(currencyKey);
        uint updateThreshold = getAtomicVolatilityUpdateThreshold(currencyKey);

        if (considerationWindow == 0 || updateThreshold == 0) {
            // If either volatility setting is not set, never judge an asset to be volatile
            return false;
        }

        // Go back through the historical oracle update rounds to see if there have been more
        // updates in the consideration window than the allowed threshold.
        // If there have, consider the asset volatile--by assumption that many close-by oracle
        // updates is a good proxy for price volatility.
        uint considerationWindowStart = block.timestamp.sub(considerationWindow);
        uint roundId = _getCurrentRoundId(currencyKey);
        for (updateThreshold; updateThreshold > 0; updateThreshold--) {
            (uint rate, uint time) = _getRateAndTimestampAtRound(currencyKey, roundId);
            if (time != 0 && time < considerationWindowStart) {
                // Round was outside consideration window so we can stop querying further rounds
                return false;
            } else if (rate == 0 || time == 0) {
                // Either entire round or a rate inside consideration window was not available
                // Consider the asset volatile
                break;
            }

            if (roundId == 0) {
                // Not enough historical data to continue further
                // Consider the asset volatile
                break;
            }
            roundId--;
        }

        return true;
    }

    /* ========== EVENTS ========== */

    event DexPriceAggregatorUpdated(address newDexPriceAggregator);
}


// https://docs.synthetix.io/contracts/source/interfaces/isystemsettings
interface ISystemSettings {
    // Views
    function waitingPeriodSecs() external view returns (uint);

    function priceDeviationThresholdFactor() external view returns (uint);

    function issuanceRatio() external view returns (uint);

    function feePeriodDuration() external view returns (uint);

    function targetThreshold() external view returns (uint);

    function liquidationDelay() external view returns (uint);

    function liquidationRatio() external view returns (uint);

    function liquidationPenalty() external view returns (uint);

    function rateStalePeriod() external view returns (uint);

    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint);

    function minimumStakeTime() external view returns (uint);

    function debtSnapshotStaleTime() external view returns (uint);

    function aggregatorWarningFlags() external view returns (address);

    function tradingRewardsEnabled() external view returns (bool);

    function wrapperMaxTokenAmount(address wrapper) external view returns (uint);

    function wrapperMintFeeRate(address wrapper) external view returns (int);

    function wrapperBurnFeeRate(address wrapper) external view returns (int);

    function etherWrapperMaxETH() external view returns (uint);

    function etherWrapperMintFeeRate() external view returns (uint);

    function etherWrapperBurnFeeRate() external view returns (uint);

    function interactionDelay(address collateral) external view returns (uint);

    function atomicMaxVolumePerBlock() external view returns (uint);

    function atomicTwapWindow() external view returns (uint);

    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address);

    function atomicExchangeFeeRate(bytes32 currencyKey) external view returns (uint);

    function atomicPriceBuffer(bytes32 currencyKey) external view returns (uint);

    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint);

    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint);
}


// Internal references


// Libraries


/// This library is to reduce SystemSettings contract size only and is not really
/// a proper library - so it shares knowledge of implementation details
/// Some of the setters were refactored into this library, and some setters remain in the
/// contract itself (SystemSettings)
library SystemSettingsLib {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant SETTINGS_CONTRACT_NAME = "SystemSettings";

    // No more synths may be issued than the value of SNX backing them.
    uint public constant MAX_ISSUANCE_RATIO = 1e18;

    // The fee period must be between 1 day and 60 days.
    uint public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint public constant MAX_FEE_PERIOD_DURATION = 60 days;

    uint public constant MAX_TARGET_THRESHOLD = 50;

    uint public constant MAX_LIQUIDATION_RATIO = 1e18; // 100% issuance ratio
    uint public constant RATIO_FROM_TARGET_BUFFER = 2e18; // 200% - mininimum buffer between issuance ratio and liquidation ratio

    uint public constant MAX_LIQUIDATION_PENALTY = 1e18 / 4; // Max 25% liquidation penalty / bonus

    uint public constant MAX_LIQUIDATION_DELAY = 30 days;
    uint public constant MIN_LIQUIDATION_DELAY = 1 days;

    // Exchange fee may not exceed 10%.
    uint public constant MAX_EXCHANGE_FEE_RATE = 1e18 / 10;

    // Minimum Stake time may not exceed 1 weeks.
    uint public constant MAX_MINIMUM_STAKE_TIME = 1 weeks;

    uint public constant MAX_CROSS_DOMAIN_GAS_LIMIT = 8e6;
    uint public constant MIN_CROSS_DOMAIN_GAS_LIMIT = 3e6;

    int public constant MAX_WRAPPER_MINT_FEE_RATE = 1e18;

    int public constant MAX_WRAPPER_BURN_FEE_RATE = 1e18;

    // Atomic block volume limit is encoded as uint192.
    uint public constant MAX_ATOMIC_VOLUME_PER_BLOCK = uint192(-1);

    // TWAP window must be between 1 min and 1 day.
    uint public constant MIN_ATOMIC_TWAP_WINDOW = 60;
    uint public constant MAX_ATOMIC_TWAP_WINDOW = 86400;

    // Volatility consideration window must be between 1 min and 1 day.
    uint public constant MIN_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = 60;
    uint public constant MAX_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = 86400;

    // workaround for library not supporting public constants in sol v0.5
    function contractName() external view returns (bytes32) {
        return SETTINGS_CONTRACT_NAME;
    }

    function setCrossDomainMessageGasLimit(
        IFlexibleStorage flexibleStorage,
        bytes32 gasLimitSettings,
        uint crossDomainMessageGasLimit
    ) external {
        require(
            crossDomainMessageGasLimit >= MIN_CROSS_DOMAIN_GAS_LIMIT &&
                crossDomainMessageGasLimit <= MAX_CROSS_DOMAIN_GAS_LIMIT,
            "Out of range xDomain gasLimit"
        );
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, gasLimitSettings, crossDomainMessageGasLimit);
    }

    function setIssuanceRatio(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint ratio
    ) external {
        require(ratio <= MAX_ISSUANCE_RATIO, "New issuance ratio cannot exceed MAX_ISSUANCE_RATIO");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, ratio);
    }

    function setTradingRewardsEnabled(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bool _tradingRewardsEnabled
    ) external {
        flexibleStorage.setBoolValue(SETTINGS_CONTRACT_NAME, settingName, _tradingRewardsEnabled);
    }

    function setWaitingPeriodSecs(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _waitingPeriodSecs
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _waitingPeriodSecs);
    }

    function setPriceDeviationThresholdFactor(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _priceDeviationThresholdFactor
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _priceDeviationThresholdFactor);
    }

    function setFeePeriodDuration(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _feePeriodDuration
    ) external {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "value < MIN_FEE_PERIOD_DURATION");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "value > MAX_FEE_PERIOD_DURATION");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _feePeriodDuration);
    }

    function setTargetThreshold(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint percent
    ) external returns (uint threshold) {
        require(percent <= MAX_TARGET_THRESHOLD, "Threshold too high");
        threshold = percent.mul(SafeDecimalMath.unit()).div(100);

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, threshold);
    }

    function setLiquidationDelay(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint time
    ) external {
        require(time <= MAX_LIQUIDATION_DELAY, "Must be less than 30 days");
        require(time >= MIN_LIQUIDATION_DELAY, "Must be greater than 1 day");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, time);
    }

    function setLiquidationRatio(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _liquidationRatio,
        uint getLiquidationPenalty,
        uint getIssuanceRatio
    ) external {
        require(
            _liquidationRatio <= MAX_LIQUIDATION_RATIO.divideDecimal(SafeDecimalMath.unit().add(getLiquidationPenalty)),
            "liquidationRatio > MAX_LIQUIDATION_RATIO / (1 + penalty)"
        );

        // MIN_LIQUIDATION_RATIO is a product of target issuance ratio * RATIO_FROM_TARGET_BUFFER
        // Ensures that liquidation ratio is set so that there is a buffer between the issuance ratio and liquidation ratio.
        uint MIN_LIQUIDATION_RATIO = getIssuanceRatio.multiplyDecimal(RATIO_FROM_TARGET_BUFFER);
        require(_liquidationRatio >= MIN_LIQUIDATION_RATIO, "liquidationRatio < MIN_LIQUIDATION_RATIO");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _liquidationRatio);
    }

    function setLiquidationPenalty(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint penalty
    ) external {
        require(penalty <= MAX_LIQUIDATION_PENALTY, "penalty > MAX_LIQUIDATION_PENALTY");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, penalty);
    }

    function setRateStalePeriod(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint period
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, period);
    }

    function setExchangeFeeRateForSynths(
        IFlexibleStorage flexibleStorage,
        bytes32 settingExchangeFeeRate,
        bytes32[] calldata synthKeys,
        uint256[] calldata exchangeFeeRates
    ) external {
        require(synthKeys.length == exchangeFeeRates.length, "Array lengths dont match");
        for (uint i = 0; i < synthKeys.length; i++) {
            require(exchangeFeeRates[i] <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
            flexibleStorage.setUIntValue(
                SETTINGS_CONTRACT_NAME,
                keccak256(abi.encodePacked(settingExchangeFeeRate, synthKeys[i])),
                exchangeFeeRates[i]
            );
        }
    }

    function setMinimumStakeTime(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _seconds
    ) external {
        require(_seconds <= MAX_MINIMUM_STAKE_TIME, "stake time exceed maximum 1 week");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _seconds);
    }

    function setDebtSnapshotStaleTime(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _seconds
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _seconds);
    }

    function setAggregatorWarningFlags(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _flags
    ) external {
        require(_flags != address(0), "Valid address must be given");
        flexibleStorage.setAddressValue(SETTINGS_CONTRACT_NAME, settingName, _flags);
    }

    function setEtherWrapperMaxETH(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _maxETH
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _maxETH);
    }

    function setEtherWrapperMintFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _rate
    ) external {
        require(_rate <= uint(MAX_WRAPPER_MINT_FEE_RATE), "rate > MAX_WRAPPER_MINT_FEE_RATE");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _rate);
    }

    function setEtherWrapperBurnFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _rate
    ) external {
        require(_rate <= uint(MAX_WRAPPER_BURN_FEE_RATE), "rate > MAX_WRAPPER_BURN_FEE_RATE");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _rate);
    }

    function setWrapperMaxTokenAmount(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _wrapper,
        uint _maxTokenAmount
    ) external {
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _wrapper)),
            _maxTokenAmount
        );
    }

    function setWrapperMintFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _wrapper,
        int _rate,
        int getWrapperBurnFeeRate
    ) external {
        require(_rate <= MAX_WRAPPER_MINT_FEE_RATE, "rate > MAX_WRAPPER_MINT_FEE_RATE");
        require(_rate >= -MAX_WRAPPER_MINT_FEE_RATE, "rate < -MAX_WRAPPER_MINT_FEE_RATE");

        // if mint rate is negative, burn fee rate should be positive and at least equal in magnitude
        // otherwise risk of flash loan attack
        if (_rate < 0) {
            require(-_rate <= getWrapperBurnFeeRate, "-rate > wrapperBurnFeeRate");
        }

        flexibleStorage.setIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _wrapper)), _rate);
    }

    function setWrapperBurnFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _wrapper,
        int _rate,
        int getWrapperMintFeeRate
    ) external {
        require(_rate <= MAX_WRAPPER_BURN_FEE_RATE, "rate > MAX_WRAPPER_BURN_FEE_RATE");
        require(_rate >= -MAX_WRAPPER_BURN_FEE_RATE, "rate < -MAX_WRAPPER_BURN_FEE_RATE");

        // if burn rate is negative, burn fee rate should be negative and at least equal in magnitude
        // otherwise risk of flash loan attack
        if (_rate < 0) {
            require(-_rate <= getWrapperMintFeeRate, "-rate > wrapperMintFeeRate");
        }

        flexibleStorage.setIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _wrapper)), _rate);
    }

    function setInteractionDelay(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _collateral,
        uint _interactionDelay
    ) external {
        require(_interactionDelay <= SafeDecimalMath.unit() * 3600, "Max 1 hour");
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _collateral)),
            _interactionDelay
        );
    }

    function setCollapseFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _collateral,
        uint _collapseFeeRate
    ) external {
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _collateral)),
            _collapseFeeRate
        );
    }

    function setAtomicMaxVolumePerBlock(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _maxVolume
    ) external {
        require(_maxVolume <= MAX_ATOMIC_VOLUME_PER_BLOCK, "Atomic max volume exceed maximum uint192");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _maxVolume);
    }

    function setAtomicTwapWindow(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint _window
    ) external {
        require(_window >= MIN_ATOMIC_TWAP_WINDOW, "Atomic twap window under minimum 1 min");
        require(_window <= MAX_ATOMIC_TWAP_WINDOW, "Atomic twap window exceed maximum 1 day");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _window);
    }

    function setAtomicEquivalentForDexPricing(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        address _equivalent
    ) external {
        require(_equivalent != address(0), "Atomic equivalent is 0 address");
        flexibleStorage.setAddressValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _equivalent
        );
    }

    function setAtomicExchangeFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint _exchangeFeeRate
    ) external {
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _exchangeFeeRate
        );
    }

    function setAtomicPriceBuffer(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint _buffer
    ) external {
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _buffer
        );
    }

    function setAtomicVolatilityConsiderationWindow(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint _window
    ) external {
        if (_window != 0) {
            require(
                _window >= MIN_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
                "Atomic volatility consideration window under minimum 1 min"
            );
            require(
                _window <= MAX_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
                "Atomic volatility consideration window exceed maximum 1 day"
            );
        }
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _window
        );
    }

    function setAtomicVolatilityUpdateThreshold(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint _threshold
    ) external {
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _threshold
        );
    }

    function setExchangeMaxDynamicFee(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint maxFee
    ) external {
        require(maxFee != 0, "Max dynamic fee cannot be 0");
        require(maxFee <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, maxFee);
    }
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/systemsettings
contract SystemSettings is Owned, MixinSystemSettings, ISystemSettings {
    // SystemSettingsLib is a way to split out the setters to reduce contract size
    using SystemSettingsLib for IFlexibleStorage;

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {
        // SETTING_CONTRACT_NAME is defined for the getters in MixinSystemSettings and
        // SystemSettingsLib.contractName() is a view into SystemSettingsLib of the contract name
        // that's used by the setters. They have to be equal.
        require(SETTING_CONTRACT_NAME == SystemSettingsLib.contractName(), "read and write keys not equal");
    }

    // ========== VIEWS ==========

    // backwards compatibility to having CONTRACT_NAME public constant
    // solhint-disable-next-line func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32) {
        return SystemSettingsLib.contractName();
    }

    // SIP-37 Fee Reclamation
    // The number of seconds after an exchange is executed that must be waited
    // before settlement.
    function waitingPeriodSecs() external view returns (uint) {
        return getWaitingPeriodSecs();
    }

    // SIP-65 Decentralized Circuit Breaker
    // The factor amount expressed in decimal format
    // E.g. 3e18 = factor 3, meaning movement up to 3x and above or down to 1/3x and below
    function priceDeviationThresholdFactor() external view returns (uint) {
        return getPriceDeviationThresholdFactor();
    }

    // The raio of collateral
    // Expressed in 18 decimals. So 800% cratio is 100/800 = 0.125 (0.125e18)
    function issuanceRatio() external view returns (uint) {
        return getIssuanceRatio();
    }

    // How long a fee period lasts at a minimum. It is required for
    // anyone to roll over the periods, so they are not guaranteed
    // to roll over at exactly this duration, but the contract enforces
    // that they cannot roll over any quicker than this duration.
    function feePeriodDuration() external view returns (uint) {
        return getFeePeriodDuration();
    }

    // Users are unable to claim fees if their collateralisation ratio drifts out of target threshold
    function targetThreshold() external view returns (uint) {
        return getTargetThreshold();
    }

    // SIP-15 Liquidations
    // liquidation time delay after address flagged (seconds)
    function liquidationDelay() external view returns (uint) {
        return getLiquidationDelay();
    }

    // SIP-15 Liquidations
    // issuance ratio when account can be flagged for liquidation (with 18 decimals), e.g 0.5 issuance ratio
    // when flag means 1/0.5 = 200% cratio
    function liquidationRatio() external view returns (uint) {
        return getLiquidationRatio();
    }

    // SIP-15 Liquidations
    // penalty taken away from target of liquidation (with 18 decimals). E.g. 10% is 0.1e18
    function liquidationPenalty() external view returns (uint) {
        return getLiquidationPenalty();
    }

    // How long will the ExchangeRates contract assume the rate of any asset is correct
    function rateStalePeriod() external view returns (uint) {
        return getRateStalePeriod();
    }

    /* ========== Exchange Related Fees ========== */
    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint) {
        return getExchangeFeeRate(currencyKey);
    }

    // SIP-184 Dynamic Fee
    /// @notice Get the dynamic fee threshold
    /// @return The dynamic fee threshold
    function exchangeDynamicFeeThreshold() external view returns (uint) {
        return getExchangeDynamicFeeConfig().threshold;
    }

    /// @notice Get the dynamic fee weight decay per round
    /// @return The dynamic fee weight decay per round
    function exchangeDynamicFeeWeightDecay() external view returns (uint) {
        return getExchangeDynamicFeeConfig().weightDecay;
    }

    /// @notice Get the dynamic fee total rounds for calculation
    /// @return The dynamic fee total rounds for calculation
    function exchangeDynamicFeeRounds() external view returns (uint) {
        return getExchangeDynamicFeeConfig().rounds;
    }

    /// @notice Get the max dynamic fee
    /// @return The max dynamic fee
    function exchangeMaxDynamicFee() external view returns (uint) {
        return getExchangeDynamicFeeConfig().maxFee;
    }

    /* ========== End Exchange Related Fees ========== */

    function minimumStakeTime() external view returns (uint) {
        return getMinimumStakeTime();
    }

    function debtSnapshotStaleTime() external view returns (uint) {
        return getDebtSnapshotStaleTime();
    }

    function aggregatorWarningFlags() external view returns (address) {
        return getAggregatorWarningFlags();
    }

    // SIP-63 Trading incentives
    // determines if Exchanger records fee entries in TradingRewards
    function tradingRewardsEnabled() external view returns (bool) {
        return getTradingRewardsEnabled();
    }

    function crossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) external view returns (uint) {
        return getCrossDomainMessageGasLimit(gasLimitType);
    }

    // SIP 112: ETH Wrappr
    // The maximum amount of ETH held by the EtherWrapper.
    function etherWrapperMaxETH() external view returns (uint) {
        return getEtherWrapperMaxETH();
    }

    // SIP 112: ETH Wrappr
    // The fee for depositing ETH into the EtherWrapper.
    function etherWrapperMintFeeRate() external view returns (uint) {
        return getEtherWrapperMintFeeRate();
    }

    // SIP 112: ETH Wrappr
    // The fee for burning sETH and releasing ETH from the EtherWrapper.
    function etherWrapperBurnFeeRate() external view returns (uint) {
        return getEtherWrapperBurnFeeRate();
    }

    // SIP 182: Wrapper Factory
    // The maximum amount of token held by the Wrapper.
    function wrapperMaxTokenAmount(address wrapper) external view returns (uint) {
        return getWrapperMaxTokenAmount(wrapper);
    }

    // SIP 182: Wrapper Factory
    // The fee for depositing token into the Wrapper.
    function wrapperMintFeeRate(address wrapper) external view returns (int) {
        return getWrapperMintFeeRate(wrapper);
    }

    // SIP 182: Wrapper Factory
    // The fee for burning synth and releasing token from the Wrapper.
    function wrapperBurnFeeRate(address wrapper) external view returns (int) {
        return getWrapperBurnFeeRate(wrapper);
    }

    function interactionDelay(address collateral) external view returns (uint) {
        return getInteractionDelay(collateral);
    }

    function collapseFeeRate(address collateral) external view returns (uint) {
        return getCollapseFeeRate(collateral);
    }

    // SIP-120 Atomic exchanges
    // max allowed volume per block for atomic exchanges
    function atomicMaxVolumePerBlock() external view returns (uint) {
        return getAtomicMaxVolumePerBlock();
    }

    // SIP-120 Atomic exchanges
    // time window (in seconds) for TWAP prices when considered for atomic exchanges
    function atomicTwapWindow() external view returns (uint) {
        return getAtomicTwapWindow();
    }

    // SIP-120 Atomic exchanges
    // equivalent asset to use for a synth when considering external prices for atomic exchanges
    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address) {
        return getAtomicEquivalentForDexPricing(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // fee rate override for atomic exchanges into a synth
    function atomicExchangeFeeRate(bytes32 currencyKey) external view returns (uint) {
        return getAtomicExchangeFeeRate(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // price dampener for chainlink prices when considered for atomic exchanges
    function atomicPriceBuffer(bytes32 currencyKey) external view returns (uint) {
        return getAtomicPriceBuffer(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // consideration window for determining synth volatility
    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityConsiderationWindow(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // update threshold for determining synth volatility
    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityUpdateThreshold(currencyKey);
    }

    // ========== RESTRICTED ==========

    function setCrossDomainMessageGasLimit(CrossDomainMessageGasLimits _gasLimitType, uint _crossDomainMessageGasLimit)
        external
        onlyOwner
    {
        flexibleStorage().setCrossDomainMessageGasLimit(_getGasLimitSetting(_gasLimitType), _crossDomainMessageGasLimit);
        emit CrossDomainMessageGasLimitChanged(_gasLimitType, _crossDomainMessageGasLimit);
    }

    function setIssuanceRatio(uint ratio) external onlyOwner {
        flexibleStorage().setIssuanceRatio(SETTING_ISSUANCE_RATIO, ratio);
        emit IssuanceRatioUpdated(ratio);
    }

    function setTradingRewardsEnabled(bool _tradingRewardsEnabled) external onlyOwner {
        flexibleStorage().setTradingRewardsEnabled(SETTING_TRADING_REWARDS_ENABLED, _tradingRewardsEnabled);
        emit TradingRewardsEnabled(_tradingRewardsEnabled);
    }

    function setWaitingPeriodSecs(uint _waitingPeriodSecs) external onlyOwner {
        flexibleStorage().setWaitingPeriodSecs(SETTING_WAITING_PERIOD_SECS, _waitingPeriodSecs);
        emit WaitingPeriodSecsUpdated(_waitingPeriodSecs);
    }

    function setPriceDeviationThresholdFactor(uint _priceDeviationThresholdFactor) external onlyOwner {
        flexibleStorage().setPriceDeviationThresholdFactor(
            SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR,
            _priceDeviationThresholdFactor
        );
        emit PriceDeviationThresholdUpdated(_priceDeviationThresholdFactor);
    }

    function setFeePeriodDuration(uint _feePeriodDuration) external onlyOwner {
        flexibleStorage().setFeePeriodDuration(SETTING_FEE_PERIOD_DURATION, _feePeriodDuration);
        emit FeePeriodDurationUpdated(_feePeriodDuration);
    }

    function setTargetThreshold(uint percent) external onlyOwner {
        uint threshold = flexibleStorage().setTargetThreshold(SETTING_TARGET_THRESHOLD, percent);
        emit TargetThresholdUpdated(threshold);
    }

    function setLiquidationDelay(uint time) external onlyOwner {
        flexibleStorage().setLiquidationDelay(SETTING_LIQUIDATION_DELAY, time);
        emit LiquidationDelayUpdated(time);
    }

    // The collateral / issuance ratio ( debt / collateral ) is higher when there is less collateral backing their debt
    // Upper bound liquidationRatio is 1 + penalty (100% + 10% = 110%) to allow collateral value to cover debt and liquidation penalty
    function setLiquidationRatio(uint _liquidationRatio) external onlyOwner {
        flexibleStorage().setLiquidationRatio(
            SETTING_LIQUIDATION_RATIO,
            _liquidationRatio,
            getLiquidationPenalty(),
            getIssuanceRatio()
        );
        emit LiquidationRatioUpdated(_liquidationRatio);
    }

    function setLiquidationPenalty(uint penalty) external onlyOwner {
        flexibleStorage().setLiquidationPenalty(SETTING_LIQUIDATION_PENALTY, penalty);
        emit LiquidationPenaltyUpdated(penalty);
    }

    function setRateStalePeriod(uint period) external onlyOwner {
        flexibleStorage().setRateStalePeriod(SETTING_RATE_STALE_PERIOD, period);
        emit RateStalePeriodUpdated(period);
    }

    /* ========== Exchange Fees Related ========== */
    function setExchangeFeeRateForSynths(bytes32[] calldata synthKeys, uint256[] calldata exchangeFeeRates)
        external
        onlyOwner
    {
        flexibleStorage().setExchangeFeeRateForSynths(SETTING_EXCHANGE_FEE_RATE, synthKeys, exchangeFeeRates);
        for (uint i = 0; i < synthKeys.length; i++) {
            emit ExchangeFeeUpdated(synthKeys[i], exchangeFeeRates[i]);
        }
    }

    /// @notice Set exchange dynamic fee threshold constant in decimal ratio
    /// @param threshold The exchange dynamic fee threshold
    /// @return uint threshold constant
    function setExchangeDynamicFeeThreshold(uint threshold) external onlyOwner {
        require(threshold != 0, "Threshold cannot be 0");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD, threshold);

        emit ExchangeDynamicFeeThresholdUpdated(threshold);
    }

    /// @notice Set exchange dynamic fee weight decay constant
    /// @param weightDecay The exchange dynamic fee weight decay
    /// @return uint weight decay constant
    function setExchangeDynamicFeeWeightDecay(uint weightDecay) external onlyOwner {
        require(weightDecay != 0, "Weight decay cannot be 0");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY, weightDecay);

        emit ExchangeDynamicFeeWeightDecayUpdated(weightDecay);
    }

    /// @notice Set exchange dynamic fee last N rounds with minimum 2 rounds
    /// @param rounds The exchange dynamic fee last N rounds
    /// @return uint dynamic fee last N rounds
    function setExchangeDynamicFeeRounds(uint rounds) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS, rounds);

        emit ExchangeDynamicFeeRoundsUpdated(rounds);
    }

    /// @notice Set max exchange dynamic fee
    /// @param maxFee The max exchange dynamic fee
    /// @return uint dynamic fee last N rounds
    function setExchangeMaxDynamicFee(uint maxFee) external onlyOwner {
        flexibleStorage().setExchangeMaxDynamicFee(SETTING_EXCHANGE_MAX_DYNAMIC_FEE, maxFee);
        emit ExchangeMaxDynamicFeeUpdated(maxFee);
    }

    function setMinimumStakeTime(uint _seconds) external onlyOwner {
        flexibleStorage().setMinimumStakeTime(SETTING_MINIMUM_STAKE_TIME, _seconds);
        emit MinimumStakeTimeUpdated(_seconds);
    }

    function setDebtSnapshotStaleTime(uint _seconds) external onlyOwner {
        flexibleStorage().setDebtSnapshotStaleTime(SETTING_DEBT_SNAPSHOT_STALE_TIME, _seconds);
        emit DebtSnapshotStaleTimeUpdated(_seconds);
    }

    function setAggregatorWarningFlags(address _flags) external onlyOwner {
        flexibleStorage().setAggregatorWarningFlags(SETTING_AGGREGATOR_WARNING_FLAGS, _flags);
        emit AggregatorWarningFlagsUpdated(_flags);
    }

    function setEtherWrapperMaxETH(uint _maxETH) external onlyOwner {
        flexibleStorage().setEtherWrapperMaxETH(SETTING_ETHER_WRAPPER_MAX_ETH, _maxETH);
        emit EtherWrapperMaxETHUpdated(_maxETH);
    }

    function setEtherWrapperMintFeeRate(uint _rate) external onlyOwner {
        flexibleStorage().setEtherWrapperMintFeeRate(SETTING_ETHER_WRAPPER_MINT_FEE_RATE, _rate);
        emit EtherWrapperMintFeeRateUpdated(_rate);
    }

    function setEtherWrapperBurnFeeRate(uint _rate) external onlyOwner {
        flexibleStorage().setEtherWrapperBurnFeeRate(SETTING_ETHER_WRAPPER_BURN_FEE_RATE, _rate);
        emit EtherWrapperBurnFeeRateUpdated(_rate);
    }

    function setWrapperMaxTokenAmount(address _wrapper, uint _maxTokenAmount) external onlyOwner {
        flexibleStorage().setWrapperMaxTokenAmount(SETTING_WRAPPER_MAX_TOKEN_AMOUNT, _wrapper, _maxTokenAmount);
        emit WrapperMaxTokenAmountUpdated(_wrapper, _maxTokenAmount);
    }

    function setWrapperMintFeeRate(address _wrapper, int _rate) external onlyOwner {
        flexibleStorage().setWrapperMintFeeRate(
            SETTING_WRAPPER_MINT_FEE_RATE,
            _wrapper,
            _rate,
            getWrapperBurnFeeRate(_wrapper)
        );
        emit WrapperMintFeeRateUpdated(_wrapper, _rate);
    }

    function setWrapperBurnFeeRate(address _wrapper, int _rate) external onlyOwner {
        flexibleStorage().setWrapperBurnFeeRate(
            SETTING_WRAPPER_BURN_FEE_RATE,
            _wrapper,
            _rate,
            getWrapperMintFeeRate(_wrapper)
        );
        emit WrapperBurnFeeRateUpdated(_wrapper, _rate);
    }

    function setInteractionDelay(address _collateral, uint _interactionDelay) external onlyOwner {
        flexibleStorage().setInteractionDelay(SETTING_INTERACTION_DELAY, _collateral, _interactionDelay);
        emit InteractionDelayUpdated(_interactionDelay);
    }

    function setCollapseFeeRate(address _collateral, uint _collapseFeeRate) external onlyOwner {
        flexibleStorage().setCollapseFeeRate(SETTING_COLLAPSE_FEE_RATE, _collateral, _collapseFeeRate);
        emit CollapseFeeRateUpdated(_collapseFeeRate);
    }

    function setAtomicMaxVolumePerBlock(uint _maxVolume) external onlyOwner {
        flexibleStorage().setAtomicMaxVolumePerBlock(SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK, _maxVolume);
        emit AtomicMaxVolumePerBlockUpdated(_maxVolume);
    }

    function setAtomicTwapWindow(uint _window) external onlyOwner {
        flexibleStorage().setAtomicTwapWindow(SETTING_ATOMIC_TWAP_WINDOW, _window);
        emit AtomicTwapWindowUpdated(_window);
    }

    function setAtomicEquivalentForDexPricing(bytes32 _currencyKey, address _equivalent) external onlyOwner {
        flexibleStorage().setAtomicEquivalentForDexPricing(
            SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING,
            _currencyKey,
            _equivalent
        );
        emit AtomicEquivalentForDexPricingUpdated(_currencyKey, _equivalent);
    }

    function setAtomicExchangeFeeRate(bytes32 _currencyKey, uint256 _exchangeFeeRate) external onlyOwner {
        flexibleStorage().setAtomicExchangeFeeRate(SETTING_ATOMIC_EXCHANGE_FEE_RATE, _currencyKey, _exchangeFeeRate);
        emit AtomicExchangeFeeUpdated(_currencyKey, _exchangeFeeRate);
    }

    function setAtomicPriceBuffer(bytes32 _currencyKey, uint _buffer) external onlyOwner {
        flexibleStorage().setAtomicPriceBuffer(SETTING_ATOMIC_PRICE_BUFFER, _currencyKey, _buffer);
        emit AtomicPriceBufferUpdated(_currencyKey, _buffer);
    }

    function setAtomicVolatilityConsiderationWindow(bytes32 _currencyKey, uint _window) external onlyOwner {
        flexibleStorage().setAtomicVolatilityConsiderationWindow(
            SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
            _currencyKey,
            _window
        );
        emit AtomicVolatilityConsiderationWindowUpdated(_currencyKey, _window);
    }

    function setAtomicVolatilityUpdateThreshold(bytes32 _currencyKey, uint _threshold) external onlyOwner {
        flexibleStorage().setAtomicVolatilityUpdateThreshold(
            SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD,
            _currencyKey,
            _threshold
        );
        emit AtomicVolatilityUpdateThresholdUpdated(_currencyKey, _threshold);
    }

    // ========== EVENTS ==========
    event CrossDomainMessageGasLimitChanged(CrossDomainMessageGasLimits gasLimitType, uint newLimit);
    event IssuanceRatioUpdated(uint newRatio);
    event TradingRewardsEnabled(bool enabled);
    event WaitingPeriodSecsUpdated(uint waitingPeriodSecs);
    event PriceDeviationThresholdUpdated(uint threshold);
    event FeePeriodDurationUpdated(uint newFeePeriodDuration);
    event TargetThresholdUpdated(uint newTargetThreshold);
    event LiquidationDelayUpdated(uint newDelay);
    event LiquidationRatioUpdated(uint newRatio);
    event LiquidationPenaltyUpdated(uint newPenalty);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    /* ========== Exchange Fees Related ========== */
    event ExchangeFeeUpdated(bytes32 synthKey, uint newExchangeFeeRate);
    event ExchangeDynamicFeeThresholdUpdated(uint dynamicFeeThreshold);
    event ExchangeDynamicFeeWeightDecayUpdated(uint dynamicFeeWeightDecay);
    event ExchangeDynamicFeeRoundsUpdated(uint dynamicFeeRounds);
    event ExchangeMaxDynamicFeeUpdated(uint maxDynamicFee);
    /* ========== End Exchange Fees Related ========== */
    event MinimumStakeTimeUpdated(uint minimumStakeTime);
    event DebtSnapshotStaleTimeUpdated(uint debtSnapshotStaleTime);
    event AggregatorWarningFlagsUpdated(address flags);
    event EtherWrapperMaxETHUpdated(uint maxETH);
    event EtherWrapperMintFeeRateUpdated(uint rate);
    event EtherWrapperBurnFeeRateUpdated(uint rate);
    event WrapperMaxTokenAmountUpdated(address wrapper, uint maxTokenAmount);
    event WrapperMintFeeRateUpdated(address wrapper, int rate);
    event WrapperBurnFeeRateUpdated(address wrapper, int rate);
    event InteractionDelayUpdated(uint interactionDelay);
    event CollapseFeeRateUpdated(uint collapseFeeRate);
    event AtomicMaxVolumePerBlockUpdated(uint newMaxVolume);
    event AtomicTwapWindowUpdated(uint newWindow);
    event AtomicEquivalentForDexPricingUpdated(bytes32 synthKey, address equivalent);
    event AtomicExchangeFeeUpdated(bytes32 synthKey, uint newExchangeFeeRate);
    event AtomicPriceBufferUpdated(bytes32 synthKey, uint newBuffer);
    event AtomicVolatilityConsiderationWindowUpdated(bytes32 synthKey, uint newVolatilityConsiderationWindow);
    event AtomicVolatilityUpdateThresholdUpdated(bytes32 synthKey, uint newVolatilityUpdateThreshold);
}


interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_Alsephina is BaseMigration {
    // https://etherscan.io/address/0xEb3107117FEAd7de89Cd14D463D340A2E6917769;
    address public constant OWNER = 0xEb3107117FEAd7de89Cd14D463D340A2E6917769;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://etherscan.io/address/0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83
    AddressResolver public constant addressresolver_i = AddressResolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    // https://etherscan.io/address/0x545973f28950f50fc6c7F52AAb4Ad214A27C0564
    ExchangeState public constant exchangestate_i = ExchangeState(0x545973f28950f50fc6c7F52AAb4Ad214A27C0564);
    // https://etherscan.io/address/0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E
    SystemStatus public constant systemstatus_i = SystemStatus(0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E);
    // https://etherscan.io/address/0xF68ECd50de7733015318361295547D8E939F93E6
    ExchangeRatesWithDexPricing public constant exchangerates_i =
        ExchangeRatesWithDexPricing(0xF68ECd50de7733015318361295547D8E939F93E6);
    // https://etherscan.io/address/0x80d65Bb7b9436A86c1928F93D6E7cc186987Ac54
    SystemSettings public constant systemsettings_i = SystemSettings(0x80d65Bb7b9436A86c1928F93D6E7cc186987Ac54);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://etherscan.io/address/0xa62F71D599Ec6179B4f6569adD69ffC7E1A7a1c5
    address public constant new_SystemSettingsLib_contract = 0xa62F71D599Ec6179B4f6569adD69ffC7E1A7a1c5;
    // https://etherscan.io/address/0x80d65Bb7b9436A86c1928F93D6E7cc186987Ac54
    address public constant new_SystemSettings_contract = 0x80d65Bb7b9436A86c1928F93D6E7cc186987Ac54;
    // https://etherscan.io/address/0xF68ECd50de7733015318361295547D8E939F93E6
    address public constant new_ExchangeRates_contract = 0xF68ECd50de7733015318361295547D8E939F93E6;
    // https://etherscan.io/address/0x3e343E89F4fF8057806F54F2208940B1Cd5C40ca
    address public constant new_Exchanger_contract = 0x3e343E89F4fF8057806F54F2208940B1Cd5C40ca;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](5);
        contracts[0] = address(addressresolver_i);
        contracts[1] = address(exchangestate_i);
        contracts[2] = address(systemstatus_i);
        contracts[3] = address(exchangerates_i);
        contracts[4] = address(systemsettings_i);
    }

    function migrate(address currentOwner) external onlyOwner {
        require(owner == currentOwner, "Only the assigned owner can be re-assigned when complete");

        require(
            ISynthetixNamedContract(new_SystemSettings_contract).CONTRACT_NAME() == "SystemSettings",
            "Invalid contract supplied for SystemSettings"
        );
        require(
            ISynthetixNamedContract(new_ExchangeRates_contract).CONTRACT_NAME() == "ExchangeRatesWithDexPricing",
            "Invalid contract supplied for ExchangeRates"
        );
        require(
            ISynthetixNamedContract(new_Exchanger_contract).CONTRACT_NAME() == "ExchangerWithFeeRecAlternatives",
            "Invalid contract supplied for Exchanger"
        );

        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 1;
        addressresolver_rebuildCaches_1();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 2;
        addressresolver_rebuildCaches_2();
        // Ensure the Exchanger contract can write to its State;
        exchangestate_i.setAssociatedContract(new_Exchanger_contract);
        // Ensure the Exchanger contract can suspend synths - see SIP-65;
        systemstatus_i.updateAccessControl("Synth", new_Exchanger_contract, true, false);
        // Ensure the ExchangeRates contract has the standalone feed for SNX;
        exchangerates_i.addAggregator("SNX", 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699);
        // Ensure the ExchangeRates contract has the standalone feed for ETH;
        exchangerates_i.addAggregator("ETH", 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        // Ensure the ExchangeRates contract has the feed for sEUR;
        exchangerates_i.addAggregator("sEUR", 0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        // Ensure the ExchangeRates contract has the feed for sJPY;
        exchangerates_i.addAggregator("sJPY", 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3);
        // Ensure the ExchangeRates contract has the feed for sAUD;
        exchangerates_i.addAggregator("sAUD", 0x77F9710E7d0A19669A13c055F62cd80d313dF022);
        // Ensure the ExchangeRates contract has the feed for sGBP;
        exchangerates_i.addAggregator("sGBP", 0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5);
        // Ensure the ExchangeRates contract has the feed for sCHF;
        exchangerates_i.addAggregator("sCHF", 0x449d117117838fFA61263B61dA6301AA2a88B13A);
        // Ensure the ExchangeRates contract has the feed for sKRW;
        exchangerates_i.addAggregator("sKRW", 0x01435677FB11763550905594A16B645847C1d0F3);
        // Ensure the ExchangeRates contract has the feed for sBTC;
        exchangerates_i.addAggregator("sBTC", 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        // Ensure the ExchangeRates contract has the feed for sETH;
        exchangerates_i.addAggregator("sETH", 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        // Ensure the ExchangeRates contract has the feed for sLINK;
        exchangerates_i.addAggregator("sLINK", 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
        // Ensure the ExchangeRates contract has the feed for sADA;
        exchangerates_i.addAggregator("sADA", 0xAE48c91dF1fE419994FFDa27da09D5aC69c30f55);
        // Ensure the ExchangeRates contract has the feed for sAAVE;
        exchangerates_i.addAggregator("sAAVE", 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);
        // Ensure the ExchangeRates contract has the feed for sDOT;
        exchangerates_i.addAggregator("sDOT", 0x1C07AFb8E2B827c5A4739C6d59Ae3A5035f28734);
        // Ensure the ExchangeRates contract has the feed for sETHBTC;
        exchangerates_i.addAggregator("sETHBTC", 0xAc559F25B1619171CbC396a50854A3240b6A4e99);
        // Ensure the ExchangeRates contract has the feed for sDEFI;
        exchangerates_i.addAggregator("sDEFI", 0xa8E875F94138B0C5b51d1e1d5dE35bbDdd28EA87);
        // Set exchange dynamic fee threshold (SIP-184);
        systemsettings_i.setExchangeDynamicFeeThreshold(4000000000000000);
        // Set exchange dynamic fee weight decay (SIP-184);
        systemsettings_i.setExchangeDynamicFeeWeightDecay(900000000000000000);
        // Set exchange dynamic fee rounds (SIP-184);
        systemsettings_i.setExchangeDynamicFeeRounds(0);
        // Set exchange max dynamic fee (SIP-184);
        systemsettings_i.setExchangeMaxDynamicFee(50000000000000000);
        // SIP-120 Set the DEX price aggregator (uniswap TWAP oracle reader);
        exchangerates_i.setDexPriceAggregator(IDexPriceAggregator(0xf120F029Ac143633d1942e48aE2Dfa2036C5786c));

        // NOMINATE OWNERSHIP back to owner for aforementioned contracts
        nominateAll();
    }

    function acceptAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            Owned(contracts[i]).acceptOwnership();
        }
    }

    function nominateAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            returnOwnership(contracts[i]);
        }
    }

    function addressresolver_importAddresses_0() internal {
        bytes32[] memory addressresolver_importAddresses_names_0_0 = new bytes32[](3);
        addressresolver_importAddresses_names_0_0[0] = bytes32("SystemSettings");
        addressresolver_importAddresses_names_0_0[1] = bytes32("ExchangeRates");
        addressresolver_importAddresses_names_0_0[2] = bytes32("Exchanger");
        address[] memory addressresolver_importAddresses_destinations_0_1 = new address[](3);
        addressresolver_importAddresses_destinations_0_1[0] = address(new_SystemSettings_contract);
        addressresolver_importAddresses_destinations_0_1[1] = address(new_ExchangeRates_contract);
        addressresolver_importAddresses_destinations_0_1[2] = address(new_Exchanger_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_0_0,
            addressresolver_importAddresses_destinations_0_1
        );
    }

    function addressresolver_rebuildCaches_1() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_1_0 = new MixinResolver[](20);
        addressresolver_rebuildCaches_destinations_1_0[0] = MixinResolver(new_SystemSettings_contract);
        addressresolver_rebuildCaches_destinations_1_0[1] = MixinResolver(0xAD95C918af576c82Df740878C3E983CBD175daB6);
        addressresolver_rebuildCaches_destinations_1_0[2] = MixinResolver(0x9D5551Cd3425Dd4585c3E7Eb7E4B98902222521E);
        addressresolver_rebuildCaches_destinations_1_0[3] = MixinResolver(new_Exchanger_contract);
        addressresolver_rebuildCaches_destinations_1_0[4] = MixinResolver(0xC2F1F551bfAd1E9A3b4816513bFd41d77f40F915);
        addressresolver_rebuildCaches_destinations_1_0[5] = MixinResolver(0xC1AAE9d18bBe386B102435a8632C8063d31e747C);
        addressresolver_rebuildCaches_destinations_1_0[6] = MixinResolver(0x067e398605E84F2D0aEEC1806e62768C5110DCc6);
        addressresolver_rebuildCaches_destinations_1_0[7] = MixinResolver(0x5c8344bcdC38F1aB5EB5C1d4a35DdEeA522B5DfA);
        addressresolver_rebuildCaches_destinations_1_0[8] = MixinResolver(0xaa03aB31b55DceEeF845C8d17890CC61cD98eD04);
        addressresolver_rebuildCaches_destinations_1_0[9] = MixinResolver(0x1F2c3a1046c32729862fcB038369696e3273a516);
        addressresolver_rebuildCaches_destinations_1_0[10] = MixinResolver(0x7C22547779c8aa41bAE79E03E8383a0BefBCecf0);
        addressresolver_rebuildCaches_destinations_1_0[11] = MixinResolver(new_ExchangeRates_contract);
        addressresolver_rebuildCaches_destinations_1_0[12] = MixinResolver(0xF66d34426C10CE91cDBcd86F8e9594AfB83049bd);
        addressresolver_rebuildCaches_destinations_1_0[13] = MixinResolver(0xDC01020857afbaE65224CfCeDb265d1216064c59);
        addressresolver_rebuildCaches_destinations_1_0[14] = MixinResolver(0x62922670313bf6b41C580143d1f6C173C5C20019);
        addressresolver_rebuildCaches_destinations_1_0[15] = MixinResolver(0xAFDd6B5A8aB32156dBFb4060ff87F6d9E31191bA);
        addressresolver_rebuildCaches_destinations_1_0[16] = MixinResolver(0xe301da3d2D3e96e57D05b8E557656629cDdbe7A0);
        addressresolver_rebuildCaches_destinations_1_0[17] = MixinResolver(0x4ed5c5D5793f86c8a85E1a96E37b6d374DE0E85A);
        addressresolver_rebuildCaches_destinations_1_0[18] = MixinResolver(0x005d19CA7ff9D79a5Bdf0805Fc01D9D7c53B6827);
        addressresolver_rebuildCaches_destinations_1_0[19] = MixinResolver(0xde3892383965FBa6eC434bE6350F85f140098708);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_1_0);
    }

    function addressresolver_rebuildCaches_2() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_2_0 = new MixinResolver[](10);
        addressresolver_rebuildCaches_destinations_2_0[0] = MixinResolver(0x39DDbbb113AF3434048b9d8018a3e99d67C6eE0D);
        addressresolver_rebuildCaches_destinations_2_0[1] = MixinResolver(0xe2f532c389deb5E42DCe53e78A9762949A885455);
        addressresolver_rebuildCaches_destinations_2_0[2] = MixinResolver(0x2B3eb5eF0EF06f2E02ef60B3F36Be4793d321353);
        addressresolver_rebuildCaches_destinations_2_0[3] = MixinResolver(0xc70B42930BD8D30A79B55415deC3be60827559f7);
        addressresolver_rebuildCaches_destinations_2_0[4] = MixinResolver(0x3FFE35c3d412150C3B91d3E22eBA60E16030C608);
        addressresolver_rebuildCaches_destinations_2_0[5] = MixinResolver(0x8f9fa817200F5B95f9572c8Acf2b31410C00335a);
        addressresolver_rebuildCaches_destinations_2_0[6] = MixinResolver(0x0705F0716b12a703d4F8832Ec7b97C61771f0361);
        addressresolver_rebuildCaches_destinations_2_0[7] = MixinResolver(0xfA60918C4417b64E722ca15d79C751c1f24Ab995);
        addressresolver_rebuildCaches_destinations_2_0[8] = MixinResolver(0xcc3aab773e2171b2E257Ee17001400eE378aa52B);
        addressresolver_rebuildCaches_destinations_2_0[9] = MixinResolver(0xe59dFC746D566EB40F92ed0B162004e24E3AC932);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_2_0);
    }
}