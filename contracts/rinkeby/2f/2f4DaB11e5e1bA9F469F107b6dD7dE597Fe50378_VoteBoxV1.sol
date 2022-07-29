// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * VoteBox - Sharkz genesis voting system
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-27
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../lib/sharkz/vote/IVoteBox.sol";
import "../lib/sharkz/vote/IVoteScore.sol";
import "../lib-upgradeable/sharkz/AdminableUpgradeable.sol";
import "../lib-upgradeable/712/EIP712VoteAllowlistUpgradeable.sol";

interface IBalanceOf {
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract VoteBoxV1 is IVoteBox, Initializable, UUPSUpgradeable, AdminableUpgradeable, EIP712VoteAllowlistUpgradeable {
    // Implementation version number
    function version() external pure virtual returns (uint256) { return 1; }

    // poll option
    struct PollOption {
        // votion option name
        string name;
        // total vote count
        uint256 vote;
    }

    struct AddressVote {
        // vote option
        uint128 voteOption;
        // vote score is calculated and fixed after voter casted a vote
        uint128 voteScore;
    }

    // poll object
    struct Poll {
        string topic;
        string content;
        uint16 optionCount;
        uint32 startTime;
        uint32 endTime;
        uint8 disableChange;
        uint8 onlyAllowlist;
        uint8 onlyNftHolder;
        uint8 disableVoteScore;
        address tokenContract;
        // keep track of each vote option data
        mapping(uint256 => PollOption) options;
        // keep track of each voter address
        mapping(uint256 => address) addresses;
        // keep track of each voter address voting option and score
        mapping(address => AddressVote) addressVote;
    }

    // poll count, also represent next poll id
    uint256 public pollCount;

    // all polls
    mapping(uint256 => Poll) public polls;

    // init this upgradeable contract
    function initialize() public initializer onlyProxy {
        __Adminable_init();
        __EIP712VoteAllowlist_init();
    }

    // only admins can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    // check if a poll id exist
    modifier existsPoll(uint256 _pid) {
        require(_existsPoll(_pid), "NonExistPoll()");
        _;
    }

    ////////// For admins
    // create new poll by contract owner
    function createPoll(
        string calldata _topic,
        string calldata _content,
        uint16 _optionCount,
        uint32 _startTime,
        uint32 _endTime,
        uint8 _disableChange,
        uint8 _onlyAllowlist,
        uint8 _onlyNftHolder,
        address _tokenContract,
        uint8 _disableVoteScore
    ) 
        external 
        onlyAdmin 
        onlyProxy 
    {
        require(bytes(_topic).length > 0, "CreatePollWithEmptyTopic()");
        require(_optionCount > 0, "CreatePollWithInvalidOptionCount()");
        require(_disableChange == 0 || _disableChange == 1, "CreatePollWithInvalidDisableChange()");
        require(_onlyAllowlist == 0 || _onlyAllowlist == 1, "CreatePollWithInvalidAllowlistSwitch()");
        require(_onlyNftHolder == 0 || _onlyNftHolder == 1, "CreatePollWithInvalidNftHolderSwitch()");
        
        uint256 _pindex = pollCount;
        polls[_pindex].topic = _topic;
        polls[_pindex].content = _content;
        polls[_pindex].startTime = _startTime;
        polls[_pindex].endTime = _endTime;
        polls[_pindex].optionCount = _optionCount;
        polls[_pindex].disableChange = _disableChange;
        polls[_pindex].onlyAllowlist = _onlyAllowlist;
        polls[_pindex].onlyNftHolder = _onlyNftHolder;
        polls[_pindex].tokenContract = _tokenContract;
        polls[_pindex].disableVoteScore = _disableVoteScore;
        pollCount ++;

        emit PollCreated(_pindex, _topic);
    }

    // update poll content
    function setPollContent(uint256 _pid, string calldata _content) external onlyAdmin existsPoll(_pid) {
        polls[_pid].content = _content;
    }

    // update poll option name
    function setPollOptionName(uint256 _pid, uint256 _option, string calldata _name) external onlyAdmin existsPoll(_pid) {
        require(_existsPollOption(_pid, _option), "NonExistPollOption()");
        polls[_pid].options[_option].name = _name;
    }

    // schedule poll with start time
    function setPollStartTime(uint256 _pid, uint32 _time) external onlyAdmin existsPoll(_pid) {
        polls[_pid].startTime = _time;

        emit PollChangedStartTime(_pid, _time);
    }

    // schedule poll ending time
    function setPollEndTime(uint256 _pid, uint32 _time) external onlyAdmin existsPoll(_pid) {
        polls[_pid].endTime = _time;

        emit PollChangedEndTime(_pid, _time);
    }

    ////////// For voters
    // do not allow contract to call
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // submit vote or change existing vote
    function vote(uint256 _pid, uint256 _value, bytes calldata _signature) 
        external 
        callerIsUser 
        existsPoll(_pid) 
        onlyProxy 
    {
        address voterAddr = msg.sender;
        // poll option starts from 1 ~ n (poll optionCount)
        require(_existsPollOption(_pid, _value), "NonExistPollOption()");
        require(_isPollStarted(_pid), "VoteForNonStartedPoll()");
        require(isVoterAllowed(_pid, _signature), "VoterDisallowed()");
        require(isVoterTokenOwner(_pid, voterAddr), "VoterIsNotTokenOwner()");

        // voter index starts at 0, next voter index will be the current vote count
        uint256 voterIndex = _getPollVoteCount(_pid);

        unchecked {
            if (!_existsVote(_pid, voterAddr)) {
                // first-time record new voter address and vote value
                polls[_pid].addresses[voterIndex] = voterAddr;
                polls[_pid].options[_value].vote ++;
            } else {
                // changing vote
                require(polls[_pid].disableChange == 0, "VoteChangeDisabled()");
                uint256 previousVote = _getAddressVote(_pid, voterAddr);
                if (_value != previousVote) {
                    // changing previous vote
                    polls[_pid].options[previousVote].vote --;
                    polls[_pid].options[_value].vote ++;
                }
            }
        }

        // Update vote option and score
        AddressVote memory addrVote;
        addrVote.voteOption = uint128(_value);
        addrVote.voteScore = uint128(_getVoterScore(polls[_pid].tokenContract, voterAddr));
        polls[_pid].addressVote[voterAddr] = addrVote;

        emit Voted(voterAddr, _pid, _value);
    }
    
    ////////// External functions
    // Get poll content url
    function totalPoll() external view override returns (uint256) {
        return pollCount;
    }

    // Get poll available option count
    function getPollOptionCount(uint256 _pid) external view override existsPoll(_pid) returns (uint256) {
        return polls[_pid].optionCount;
    }

    // Get poll topic
    function getPollTopic(uint256 _pid) external view override existsPoll(_pid) returns (string memory) {
        return polls[_pid].topic;
    }

    // Get poll content url
    function getPollContent(uint256 _pid) external view override existsPoll(_pid) returns (string memory) {
        return polls[_pid].content;
    }

    // Get poll option name
    function getPollOptionName(uint256 _pid, uint256 _option) external view override existsPoll(_pid) returns (string memory) {
        require(_existsPollOption(_pid, _option), "NonExistPollOption()");
        return polls[_pid].options[_option].name;
    }

    // Get poll total vote counts
    function getPollTotalVoteCount(uint256 _pid) external view override existsPoll(_pid) returns (uint256) {
        return _getPollVoteCount(_pid);
    }

    // Get poll total vote counts
    function getPollTotalVoteScore(uint256 _pid) external view override existsPoll(_pid) returns (uint256) {
        uint256 totalVote = _getPollVoteCount(_pid);
        uint8 disableVoteScore = polls[_pid].disableVoteScore;
        uint256 score;
        address voterAddr;
        uint256 i;
        // Avoid max uint checking since it is unlikely to hit 2**256-1
        unchecked {
            while (i < totalVote) {
                voterAddr = polls[_pid].addresses[i];
                if (disableVoteScore == 0) {
                    score += _getAddressVoteScore(_pid, voterAddr);
                } else {
                    // just count one score per vote
                    score += 1;
                }
                i += 1;
            }
        }
        return score;
    }

    // Get poll total vote count for an option
    function getPollOptionVoteCount(uint256 _pid, uint256 _option) external view override existsPoll(_pid) returns (uint256) {
        require(_existsPollOption(_pid, _option), "NonExistPollOption()");
        return _getPollOptionVoteCount(_pid, _option);
    }

    // Get poll total vote score for an option
    function getPollOptionVoteScore(uint256 _pid, uint256 _option) external view override existsPoll(_pid) returns (uint256) {
        uint256 totalVote = _getPollVoteCount(_pid);
        uint8 disableVoteScore = polls[_pid].disableVoteScore;
        uint256 score;
        address voterAddr;
        uint256 i;
        // Avoid max uint checking since it is unlikely to hit 2**256-1
        unchecked {
            while (i < totalVote) {
                voterAddr = polls[_pid].addresses[i];
                if (_getAddressVote(_pid, voterAddr) == _option) {
                    if (disableVoteScore == 0) {
                        score += _getAddressVoteScore(_pid, voterAddr);
                    } else {
                        // just count one score per vote
                        score += 1;
                    }
                }
                i += 1;
            }
        }
        return score;
    }

    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view override existsPoll(_pid) returns (uint256) {        
        uint256 value = _getAddressVote(_pid, _addr);
        require(value != 0, "Vote not found");

        return value;
    }

    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view override existsPoll(_pid) returns (address) {
        address voterAddr = polls[_pid].addresses[_voterIndex];
        require(voterAddr != address(0), "Voter not found");

        return voterAddr;
    }

    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view override existsPoll(_pid) returns (bool) {
        return _isPollStarted(_pid);
    }

    // Check voter is on poll allowlist
    function isVoterAllowed(uint256 _pid, bytes calldata _signature) public view override returns (bool) {
        // by default, this will return true when unset or 0 value
        if (polls[_pid].onlyAllowlist == 0) {
            return true;
        }
        return verifySignature(_signature, _pid);
    }

    // Check if voter is currently owner of required NFT
    function isVoterTokenOwner(uint256 _pid, address _addr) public view override existsPoll(_pid) returns (bool) {
        // when poll onlyNftHolder is disabled, skipping nft holder checking
        if (polls[_pid].onlyNftHolder == 0) return true;

        address tokenContract = polls[_pid].tokenContract;
        require(tokenContract != address(0), "NonExistTokenContract()");

        return _isExternalTokenOwner(tokenContract, _addr);
    }

    ////////// Internal functions
    /**
     * @dev Returns whether poll started
     */
    function _isPollStarted(uint256 _pid) internal view returns (bool) {
        uint256 startTime = polls[_pid].startTime;
        uint256 endTime = polls[_pid].endTime;
        uint256 blockTime = block.timestamp;

        return startTime > 0 && blockTime >= startTime 
                && blockTime < endTime;
    }

    /**
     * @dev Returns whether poll id exists.
     */
    function _existsPoll(uint256 _pid) internal view returns (bool) {
        return _pid < pollCount;
    }

    /**
     * @dev Returns whether poll option exists.
     */
    function _existsPollOption(uint256 _pid, uint256 _option) internal view returns (bool) {
        return _option > 0 && _option <= polls[_pid].optionCount;
    }

    /**
     * @dev Returns whether address has existing vote
     */
    function _existsVote(uint256 _pid, address _addr) internal view returns (bool) {
        return uint256(polls[_pid].addressVote[_addr].voteOption) != 0;
    }

    /**
     * @dev Returns the vote value for a voter address
     */
    function _getAddressVote(uint256 _pid, address _addr) internal view returns (uint256) {
        return uint256(polls[_pid].addressVote[_addr].voteOption);
    }

    /**
     * @dev Retuns the vote score for a voter address
     */
    function _getAddressVoteScore(uint256 _pid, address _addr) internal view returns (uint256) {
        return uint256(polls[_pid].addressVote[_addr].voteScore);
    }

    /**
     * @dev Returns the total vote count for a poll
     */
    function _getPollVoteCount(uint256 _pid) internal view returns (uint256) {
        // optionCount must be larger than 0
        uint256 optionCount = polls[_pid].optionCount;

        uint256 index = 1;
        uint256 count = 0;
        do {
            count += polls[_pid].options[index].vote;
            index ++;
        }
        while (index <= optionCount);

        return count;
    }

    /**
     * @dev Returns the total vote count for a poll option
     */
    function _getPollOptionVoteCount(uint256 _pid, uint256 _option) internal view returns (uint256) {
        return polls[_pid].options[_option].vote;
    }

    /**
     * @dev Returns whether an address is NFT owner
     */
    function _isExternalTokenOwner(address _tokenContract, address _ownerAddress) internal view returns (bool) {
        try IBalanceOf(_tokenContract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
            // when reverted, just returns...
            return false;
        }
    }

    /**
     * @dev Returns the vote score from external token contract for an owner address
     */
    function _getVoterScore(address _tokenContract, address _ownerAddress) internal view returns (uint256) {
        try IVoteScore(_tokenContract).voteScoreByAddress(_ownerAddress) returns (uint256 score) {
            return score;
        } catch (bytes memory) {
            // when reverted, just returns...
            return 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
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

/**
 *******************************************************************************
 * IVoteBox interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-02
 *
 */

pragma solidity ^0.8.7;

interface IVoteBox {
    event PollCreated(uint256 indexed pollId, string topic);
    event PollChangedStartTime(uint256 indexed pollId, uint256 indexed time);
    event PollChangedEndTime(uint256 indexed pollId, uint256 indexed time);
    event Voted(address indexed sender, uint256 indexed pollId, uint256 value);

    // Get total poll count
    function totalPoll() external view returns (uint256);
    // Get poll content
    function getPollTopic(uint256 _pid) external view returns (string memory);
    // Get poll content
    function getPollContent(uint256 _pid) external view returns (string memory);
    // Get poll total options available
    function getPollOptionCount(uint256 _pid) external view returns (uint256);
    // Get poll option name
    function getPollOptionName(uint256 _pid, uint256 _option) external view returns (string memory);
    // Get poll total vote counts
    function getPollTotalVoteCount(uint256 _pid) external view returns (uint256);
    // Get poll total vote score
    function getPollTotalVoteScore(uint256 _pid) external view returns (uint256);
    // Get poll total vote count for an option
    function getPollOptionVoteCount(uint256 _pid, uint256 _option) external view returns (uint256);
    // Get poll total vote score for an option
    function getPollOptionVoteScore(uint256 _pid, uint256 _option) external view returns (uint256);
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view returns (address);
    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view returns (bool);
    // Check voter is on poll allowlist
    function isVoterAllowed(uint256 _pid, bytes calldata _signature) external view returns (bool);
    // Check voter is poll targeted nft holder
    function isVoterTokenOwner(uint256 _pid, address _addr) external returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IVoteScore interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-21
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of voting score, it allows external contract to use the score
 * to calculate voting power.
 */
interface IVoteScore {
    /**
     * @dev Get vote score for each one token (each token get same unit score)
     */
    function voteScore() external pure returns (uint256);

    /**
     * @dev Get vote score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function voteScoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get vote score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function voteScoreByAddress(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-27
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides basic multiple admins access control 
 * mechanism, admins are granted exclusive access to specific functions with the 
 * provided modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access for  
 * admins only.
 * 
 */
contract AdminableUpgradeable is Initializable, ContextUpgradeable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);
    event AdminTransfer(address indexed from, address indexed to);

    // Array of admin addresses
    address[] private _admins;

    // Initializes the contract setting the deployer as the initial admin.
    function __Adminable_init() internal onlyInitializing {
        __Adminable_init_unchained();
    }

    function __Adminable_init_unchained() internal onlyInitializing {
        _createAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        require(_msgSender() != address(0), "Adminable: caller is the zero address");

        bool found = false;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_msgSender() == _admins[i]) {
                found = true;
            }
        }
        require(found, "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual onlyAdmin returns (bool) {
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    function countAdmin() external view virtual returns (uint256) {
        return _admins.length;
    }

    function getAdmin(uint256 _index) external view virtual onlyAdmin returns (address) {
        return _admins[_index];
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        bool existingAdmin = isAdmin(to);

        // approve = true, adding
        // approve = false, removing
        if (approved) {
            require(!existingAdmin, "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(existingAdmin, "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i] && addr != address(0)) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Transfers message sender admin account to a new address
     */
    function transferAdmin(address to) public virtual onlyAdmin {
        require(to != address(0), "Adminable: address is the zero address");
        
        _admins[_adminIndex(_msgSender())] = to;
        emit AdminTransfer(_msgSender(), to);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");

        delete _admins;
        emit AdminRemoved(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * EIP 721 whitelist with voting poll id
 *******************************************************************************
 * Author: Jason Hoi
 * Date: 2022-07-23
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../sharkz/AdminableUpgradeable.sol";

contract EIP712VoteAllowlistUpgradeable is Initializable, ContextUpgradeable, AdminableUpgradeable {
    event SetSigner(address indexed sender, address indexed signer);

    using ECDSAUpgradeable for bytes32;

    // Verify signature with this signer address
    address public eip712Signer;

    // Domain separator is EIP-712 defined struct to make sure 
    // signature is coming from the this contract in same ETH newtork.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    // @MATCHING cliend-side code
    bytes32 public DOMAIN_SEPARATOR;

    // HASH_STRUCT should not contain unnecessary whitespace between each parameters
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodetype
    // @MATCHING cliend-side code
    bytes32 public constant HASH_STRUCT = keccak256("Minter(address wallet,uint256 pollId)");    

    function __EIP712VoteAllowlist_init() internal onlyInitializing {
        __EIP712VoteAllowlist_init_unchained();
    }

    function __EIP712VoteAllowlist_init_unchained() internal onlyInitializing {
        // @MATCHING cliend-side code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // @MATCHING cliend-side code
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // initial signer is contract creator
        setSigner(_msgSender());
    }

    function setSigner(address _addr) public onlyAdmin {
        eip712Signer = _addr;

        emit SetSigner(_msgSender(), _addr);
    }

    modifier checkWhitelist(bytes calldata _signature, uint256 _pid) {
        require(eip712Signer == _recoverSigner(_signature, _pid), "EIP712: Invalid Signature");
        _;
    }

    // Verify signature (relating to _msgSender()) comes by correct signer
    function verifySignature(bytes calldata _signature, uint256 _pid) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature, _pid);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature, uint256 _pid) internal view returns (address) {
        require(eip712Signer != address(0), "EIP712: Whitelist not enabled");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(HASH_STRUCT, _msgSender(), _pid))
            )
        );
        return digest.recover(_signature);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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