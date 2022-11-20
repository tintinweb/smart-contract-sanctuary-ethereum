/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8; // TODO: reconsider compiler version before production release
pragma experimental ABIEncoderV2; // required for passing structs in calldata (fairly secure at this point)

import "erc3k/contracts/IERC3000.sol";

import "@aragon/govern-contract-utils/contracts/protocol/IArbitrable.sol";
import "../protocol/IExecutable.sol";
import "@aragon/govern-contract-utils/contracts/deposits/DepositLib.sol";
import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";
import "@aragon/govern-contract-utils/contracts/adaptative-erc165/AdaptativeERC165.sol";
import "@aragon/govern-contract-utils/contracts/erc20/SafeERC20.sol";

library GovernQueueStateLib {
    enum State {
        None,
        Scheduled,
        Challenged,
        Approved,
        Rejected,
        Cancelled,
        Executed
    }

    struct Item {
        State state;
    }

    function checkState(Item storage _item, State _requiredState) internal view {
        require(_item.state == _requiredState, "queue: bad state");
    }

    function setState(Item storage _item, State _state) internal {
        _item.state = _state;
    }

    function checkAndSetState(Item storage _item, State _fromState, State _toState) internal {
        checkState(_item, _fromState);
        setState(_item, _toState);
    }
}

contract GovernQueue is IERC3000, AdaptativeERC165, IArbitrable, ACL {
    // Syntax sugar to enable method-calling syntax on types
    using ERC3000Data for *;
    using DepositLib for ERC3000Data.Collateral;
    using GovernQueueStateLib for GovernQueueStateLib.Item;
    using SafeERC20 for ERC20;

    // Permanent state
    bytes32 public configHash; // keccak256 hash of the current ERC3000Data.Config
    uint256 public nonce; // number of scheduled payloads so far
    mapping (bytes32 => GovernQueueStateLib.Item) public queue; // container hash -> execution state

    // Temporary state
    mapping (bytes32 => address) public challengerCache; // container hash -> challenger addr (used after challenging and before resolution implementation)
    mapping (IArbitrator => mapping (uint256 => bytes32)) public disputeItemCache; // arbitrator addr -> dispute id -> container hash (used between dispute creation and ruling)

    /**
     * @param _aclRoot account that will be given root permissions on ACL (commonly given to factory)
     * @param _initialConfig initial configuration parameters
     */
    constructor(address _aclRoot, ERC3000Data.Config memory _initialConfig)
        public
        ACL(_aclRoot) // note that this contract directly derives from ACL (ACL is local to contract and not global to system in Govern)
    {
        initialize(_aclRoot, _initialConfig);
    }

    function initialize(address _aclRoot, ERC3000Data.Config memory _initialConfig) public initACL(_aclRoot) onlyInit("queue") {
        _setConfig(_initialConfig);
        _registerStandard(ARBITRABLE_INTERFACE_ID);
        _registerStandard(ERC3000_INTERFACE_ID);
    }

     /**
     * @notice Schedules an action for execution, allowing for challenges and vetos on a defined time window. Pulls collateral from submitter into contract.
     * @param _container A ERC3000Data.Container struct holding both the paylaod being scheduled for execution and
       the current configuration of the system
     */
    function schedule(ERC3000Data.Container memory _container) // TO FIX: Container is in memory and function has to be public to avoid an unestrutable solidity crash
        public
        override
        auth(this.schedule.selector) // note that all functions in this contract are ACL protected (commonly some of them will be open for any addr to perform)
        returns (bytes32 containerHash)
    {   
        // prevent griefing by front-running (the same container is sent by two different people and one must be challenged)
        require(_container.payload.nonce == ++nonce, "queue: bad nonce");
        // hash using ERC3000Data.hash(ERC3000Data.Config)
        bytes32 _configHash = _container.config.hash();
        // ensure that the hash of the config passed in the container matches the current config (implicit agreement approval by scheduler)
        require(_configHash == configHash, "queue: bad config");
        // ensure that the time delta to the execution timestamp provided in the payload is at least after the config's execution delay
        require(_container.payload.executionTime >= block.timestamp + _container.config.executionDelay, "queue: bad delay");
        // ensure that the submitter of the payload is also the sender of this call
        require(_container.payload.submitter == msg.sender, "queue: bad submitter");

        for (
            uint256 index = 0;
            index < _container.payload.actions.length;
            index++
        ) {
            IExecutable executable = IExecutable(
                _container.payload.actions[index].to
            ); // Contract that can execute the action
            require(
                executable.canExecute(msg.sender),
                "Action cant be executed"
            );
        }

        containerHash = ERC3000Data.containerHash(_container.payload.hash(), _configHash);
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.None, // ensure that the state for this container is None
            GovernQueueStateLib.State.Scheduled // and if so perform a state transition to Scheduled
        );
        // we don't need to save any more state about the container in storage
        // we just authenticate the hash and assign it a state, since all future
        // actions regarding the container will need to provide it as a witness
        // all witnesses are logged from this contract at least once, so the 
        // trust assumption should be the same as storing all on-chain (move complexity to clients)

        ERC3000Data.Collateral memory collateral = _container.config.scheduleDeposit;
        collateral.collectFrom(_container.payload.submitter); // pull collateral from submitter (requires previous approval)

        // TODO: pay court tx fee

        // emit an event to ensure data availability of all state that cannot be otherwise fetched (see how config isn't emitted since an observer should already have it)
        emit Scheduled(containerHash, _container.payload);
    }

    /**
     * @notice Executes an action after its execution delayed has passed and its state hasn't been altered by a challenge or veto
     * @param _container A ERC3000Data.Container struct holding both the paylaod being scheduled for execution and
       the current configuration of the system
     */
    function execute(ERC3000Data.Container memory _container)
        public
        override
        auth(this.execute.selector) // in most instances this will be open for any addr, but leaving configurable for flexibility
        returns (bytes32 failureMap, bytes[] memory execResults)
    {
        // ensure enough time has passed
        require(uint64(block.timestamp) >= _container.payload.executionTime, "queue: wait more");

        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled, // note that we will revert here if the container wasn't previously scheduled
            GovernQueueStateLib.State.Executed
        );

        _container.config.scheduleDeposit.releaseTo(_container.payload.submitter); // release collateral to executor

        return _execute(_container.payload, containerHash);
    }

    /**
     * @notice Challenge a container in case its scheduling is illegal as per Config.rules. Pulls collateral and dispute fees from sender into contract
     * @param _container A ERC3000Data.Container struct holding both the paylaod being scheduled for execution and
       the current configuration of the system
     * @param _reason Hint for case reviewers as to why the scheduled container is illegal
     */
    function challenge(ERC3000Data.Container memory _container, bytes memory _reason) auth(this.challenge.selector) override public returns (uint256 disputeId) {
        bytes32 containerHash = _container.hash();
        challengerCache[containerHash] = msg.sender; // cache challenger address while it is needed
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled,
            GovernQueueStateLib.State.Challenged
        );

        ERC3000Data.Collateral memory collateral = _container.config.challengeDeposit;
        collateral.collectFrom(msg.sender); // pull challenge collateral from sender

        // create dispute on arbitrator
        IArbitrator arbitrator = IArbitrator(_container.config.resolver);
        (address recipient, ERC20 feeToken, uint256 feeAmount) = arbitrator.getDisputeFees();
        require(feeToken.safeTransferFrom(msg.sender, address(this), feeAmount), "queue: bad fee pull");
        require(feeToken.safeApprove(recipient, feeAmount), "queue: bad approve");
        disputeId = arbitrator.createDispute(2, abi.encode(_container)); // create dispute sending full container ABI encoded (could prob just send payload to save gas)
        require(feeToken.safeApprove(recipient, 0), "queue: bad reset"); // for security with non-compliant tokens (that fail on non-zero to non-zero approvals)

        // submit both arguments as evidence and close evidence period. no more evidence can be submitted and a settlement can't happen (could happen off-protocol)
        emit EvidenceSubmitted(arbitrator, disputeId, _container.payload.submitter, _container.payload.proof, true);
        emit EvidenceSubmitted(arbitrator, disputeId, msg.sender, _reason, true);
        arbitrator.closeEvidencePeriod(disputeId);

        disputeItemCache[arbitrator][disputeId] = containerHash; // cache a relation between disputeId and containerHash while needed

        emit Challenged(containerHash, msg.sender, _reason, disputeId, collateral);
    }

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param _container A ERC3000Data.Container struct holding both the paylaod being scheduled for execution and
       the current configuration of the system
     * @param _disputeId disputeId in the arbitrator in which the dispute over the container was created
     */
    function resolve(ERC3000Data.Container memory _container, uint256 _disputeId) override public returns (bytes32 failureMap, bytes[] memory execResults) {
        bytes32 containerHash = _container.hash();
        if (queue[containerHash].state == GovernQueueStateLib.State.Challenged) {
            // will re-enter in `rule`, `rule` will perform state transition depending on ruling
            IArbitrator(_container.config.resolver).executeRuling(_disputeId);
        } // else continue, as we must 

        GovernQueueStateLib.State state = queue[containerHash].state;

        emit Resolved(containerHash, msg.sender, state == GovernQueueStateLib.State.Approved);

        if (state == GovernQueueStateLib.State.Approved) {
            return executeApproved(_container);
        }

        require(state == GovernQueueStateLib.State.Rejected, "queue: unresolved");
        settleRejection(_container);
        return (bytes32(0), new bytes[](0));
    }

    function veto(bytes32 _containerHash, bytes memory _reason) auth(this.veto.selector) override public {
        queue[_containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled,
            GovernQueueStateLib.State.Cancelled
        );

        emit Vetoed(_containerHash, msg.sender, _reason);
    }

    /**
     * @notice Apply a new configuration for all *new* containers to be scheduled
     * @param _config A ERC3000Data.Config struct holding all the new params that will control the queue
     */
    function configure(ERC3000Data.Config memory _config)
        public
        override
        auth(this.configure.selector)
        returns (bytes32)
    {
        return _setConfig(_config);
    }

    // Finalization functions
    // In the happy path, they are not externally called (triggered from resolve -> rule -> executeApproved | settleRejection), but left public for security

    function executeApproved(ERC3000Data.Container memory _container) public returns (bytes32 failureMap, bytes[] memory execResults) {
        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Approved,
            GovernQueueStateLib.State.Executed
        );

        // release all collateral to submitter
        _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
        _container.config.challengeDeposit.releaseTo(_container.payload.submitter);

        challengerCache[containerHash] = address(0); // release state, refund gas, no longer needed in state

        return _execute(_container.payload, containerHash);
    }

    function settleRejection(ERC3000Data.Container memory _container) public {
        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Rejected,
            GovernQueueStateLib.State.Cancelled
        );

        address challenger = challengerCache[containerHash];

        // release all collateral to challenger
        _container.config.scheduleDeposit.releaseTo(challenger);
        _container.config.challengeDeposit.releaseTo(challenger);
        challengerCache[containerHash] = address(0); // release state, refund gas, no longer needed in state
    }

    // Arbitrable

    function rule(uint256 _disputeId, uint256 _ruling) override external {
        // implicit check that msg.sender was actually arbitrating a dispute over this container
        IArbitrator arbitrator = IArbitrator(msg.sender);
        bytes32 containerHash = disputeItemCache[arbitrator][_disputeId];
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Challenged,
            _ruling == ALLOW_RULING ? GovernQueueStateLib.State.Approved : GovernQueueStateLib.State.Rejected
        );
        disputeItemCache[arbitrator][_disputeId] = bytes32(0); // refund gas, no longer needed in state

        emit Ruled(arbitrator, _disputeId, _ruling);
    }

    function submitEvidence(
        uint256,
        bytes calldata,
        bool
    ) external override {
        revert("queue: evidence");
    }

    // Internal

    function _execute(ERC3000Data.Payload memory _payload, bytes32 _containerHash) internal returns (bytes32, bytes[] memory) {
        emit Executed(_containerHash, msg.sender);
        return _payload.executor.exec(_payload.actions, _payload.allowFailuresMap, _containerHash);
    }

    function _setConfig(ERC3000Data.Config memory _config)
        internal
        returns (bytes32)
    {
        configHash = _config.hash();

        emit Configured(configHash, msg.sender, _config);

        return configHash;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/aragonOS/blob/next/contracts/common/SafeERC20.sol

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.6.8;

import "../address-utils/AddressUtils.sol";

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 {
    function totalSupply() virtual public view returns (uint256);

    function balanceOf(address _who) virtual public view returns (uint256);

    function allowance(address _owner, address _spender)
        virtual public view returns (uint256);

    function transfer(address _to, uint256 _value) virtual public returns (bool);

    function approve(address _spender, uint256 _value)
        virtual public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        virtual public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using AddressUtils for address;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool ret)
    {
        if (!_addr.isContract()) {
            return false;
        }

        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas(),                // forward all 
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize()

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            _token.transfer.selector,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

import "../erc165/ERC165.sol";

contract AdaptativeERC165 is ERC165 {
    // erc165 interface ID -> whether it is supported
    mapping (bytes4 => bool) internal standardSupported;
    // callback function signature -> magic number to return
    mapping (bytes4 => bytes32) internal callbackMagicNumbers;

    bytes32 internal constant UNREGISTERED_CALLBACK = bytes32(0);

    event RegisteredStandard(bytes4 interfaceId);
    event RegisteredCallback(bytes4 sig, bytes4 magicNumber);
    event ReceivedCallback(bytes4 indexed sig, bytes data);

    function supportsInterface(bytes4 _interfaceId) override virtual public view returns (bool) {
        return standardSupported[_interfaceId] || super.supportsInterface(_interfaceId);
    }

    function _handleCallback(bytes4 _sig, bytes memory _data) internal {
        bytes32 magicNumber = callbackMagicNumbers[_sig];
        require(magicNumber != UNREGISTERED_CALLBACK, "adap-erc165: unknown callback");

        emit ReceivedCallback(_sig, _data);

        // low-level return magic number
        assembly {
            mstore(0x00, magicNumber)
            return(0x00, 0x20)
        }
    }

    function _registerStandardAndCallback(bytes4 _interfaceId, bytes4 _callbackSig, bytes4 _magicNumber) internal {
        _registerStandard(_interfaceId);
        _registerCallback(_callbackSig, _magicNumber);
    }

    function _registerStandard(bytes4 _interfaceId) internal {
        // use a random magic number for standards without number
        standardSupported[_interfaceId] = true;

        emit RegisteredStandard(_interfaceId);
    }

    function _registerCallback(bytes4 _callbackSig, bytes4 _magicNumber) internal {
        callbackMagicNumbers[_callbackSig] = _magicNumber;

        emit RegisteredCallback(_callbackSig, _magicNumber);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "../initializable/Initializable.sol";

import "./IACLOracle.sol";

library ACLData {
    enum BulkOp { Grant, Revoke, Freeze }

    struct BulkItem {
        BulkOp op;
        bytes4 role;
        address who;
    }
}

contract ACL is Initializable {
    bytes4 public constant ROOT_ROLE =
        this.grant.selector
        ^ this.revoke.selector
        ^ this.freeze.selector
        ^ this.bulk.selector
    ;

    address internal constant FREEZE_FLAG = address(1);
    address internal constant ANY_ADDR = address(-1);

    address internal constant UNSET_ROLE = address(0);
    address internal constant ALLOW_FLAG = address(2);
    
    mapping (bytes4 => mapping (address => address)) public roles;

    event Granted(bytes4 indexed role, address indexed actor, address indexed who, IACLOracle oracle);
    event Revoked(bytes4 indexed role, address indexed actor, address indexed who);
    event Frozen(bytes4 indexed role, address indexed actor);

    modifier auth(bytes4 _role) {
        require(willPerform(_role, msg.sender, msg.data), "acl: auth");
        _;
    }

    modifier initACL(address _initialRoot) {
        // ACL might have been already initialized by constructors
        if (initBlocks["acl"] == 0) {
            _initializeACL(_initialRoot);
        }
        _;
    }

    constructor(address _initialRoot) public initACL(_initialRoot) { }

    function _initializeACL(address _initialRoot) internal onlyInit("acl") {
        _grant(ROOT_ROLE, _initialRoot);
    }

    function grant(bytes4 _role, address _who) external auth(ROOT_ROLE) {
        _grant(_role, _who);
    }

    function grantWithOracle(bytes4 _role, address _who, IACLOracle _oracle) external auth(ROOT_ROLE) {
        _grantWithOracle(_role, _who, _oracle);
    }

    function revoke(bytes4 _role, address _who) external auth(ROOT_ROLE) {
        _revoke(_role, _who);
    }

    function freeze(bytes4 _role) external auth(ROOT_ROLE) {
        _freeze(_role);
    }

    function bulk(ACLData.BulkItem[] memory items) public auth(ROOT_ROLE) {
        for (uint256 i = 0; i < items.length; i++) {
            ACLData.BulkItem memory item = items[i];

            if (item.op == ACLData.BulkOp.Grant) _grant(item.role, item.who);
            else if (item.op == ACLData.BulkOp.Revoke) _revoke(item.role, item.who);
            else if (item.op == ACLData.BulkOp.Freeze) _freeze(item.role);
        }
    }

    function willPerform(bytes4 _role, address _sender, bytes memory _data) public returns (bool) {
        address senderRole = roles[_role][msg.sender];
        if (senderRole != UNSET_ROLE) {
            if (senderRole == ALLOW_FLAG) return true;
            if (IACLOracle(senderRole).willPerform(_role, _sender, _data)) return true;
        }

        address anyRole = roles[_role][ANY_ADDR];
        if (anyRole != UNSET_ROLE) {
            if (anyRole == ALLOW_FLAG) return true;
            if (IACLOracle(anyRole).willPerform(_role, _sender, _data)) return true;
        }

        return false;
    }

    function _grant(bytes4 _role, address _who) internal {
        _grantWithOracle(_role, _who, IACLOracle(ALLOW_FLAG));
    }

    function _grantWithOracle(bytes4 _role, address _who, IACLOracle _oracle) internal {
        require(!isFrozen(_role), "acl: frozen");
        require(_who != FREEZE_FLAG, "acl: bad freeze");
        
        roles[_role][_who] = address(_oracle);
        emit Granted(_role, msg.sender, _who, _oracle);
    }

    function _revoke(bytes4 _role, address _who) internal {
        require(!isFrozen(_role), "acl: frozen");

        roles[_role][_who] = UNSET_ROLE;
        emit Revoked(_role, msg.sender, _who);
    }

    function _freeze(bytes4 _role) internal {
        require(!isFrozen(_role), "acl: frozen");

        roles[_role][FREEZE_FLAG] = FREEZE_FLAG;

        emit Frozen(_role, msg.sender);
    }

    function isFrozen(bytes4 _role) public view returns (bool) {
        return roles[_role][FREEZE_FLAG] == FREEZE_FLAG;
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;

import "erc3k/contracts/ERC3000Data.sol";

import "../erc20/SafeERC20.sol";

library DepositLib {
    using SafeERC20 for ERC20;

    event Lock(address indexed token, address indexed from, uint256 amount);
    event Unlock(address indexed token, address indexed to, uint256 amount);

    function collectFrom(ERC3000Data.Collateral memory _collateral, address _from) internal {
        if (_collateral.amount > 0) {
            ERC20 token = ERC20(_collateral.token);
            require(token.safeTransferFrom(_from, address(this), _collateral.amount), "queue: bad get token");

            emit Lock(_collateral.token, _from, _collateral.amount);
        }
    }

    function releaseTo(ERC3000Data.Collateral memory _collateral, address _to) internal {
        if (_collateral.amount > 0) {
            ERC20 token = ERC20(_collateral.token);
            require(token.safeTransfer(_to, _collateral.amount), "queue: bad send token");

            emit Unlock(_collateral.token, _to, _collateral.amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IExecutable {
    function canExecute(address executer) external returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/aragon-court/blob/master/contracts/arbitration/IArbitrable.sol

pragma solidity ^0.6.8;

import "./IArbitrator.sol";

abstract contract IArbitrable {
    bytes4 internal constant ARBITRABLE_INTERFACE_ID = bytes4(0x88f3ee69);
    uint256 internal constant ALLOW_RULING = 4;

    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identification number of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);

    /**
    * @dev Emitted when new evidence is submitted for the IArbitrable instance's dispute
    * @param arbitrator IArbitrator submitting the evidence for
    * @param disputeId Identification number of the dispute receiving new evidence
    * @param submitter Address of the account submitting the evidence
    * @param evidence Data submitted for the evidence of the dispute
    * @param finished Whether or not the submitter has finished submitting evidence
    */
    event EvidenceSubmitted(IArbitrator indexed arbitrator, uint256 indexed disputeId, address indexed submitter, bytes evidence, bool finished);

    /**
    * @dev Submit evidence for a dispute
    * @param _disputeId Id of the dispute in the Court
    * @param _evidence Data submitted for the evidence related to the dispute
    * @param _finished Whether or not the submitter has finished submitting evidence
    */
    function submitEvidence(uint256 _disputeId, bytes calldata _evidence, bool _finished) virtual external;

    /**
    * @dev Give a ruling for a certain dispute, the account calling it must have rights to rule on the contract
    * @param _disputeId Identification number of the dispute to be ruled
    * @param _ruling Ruling given by the arbitrator, where 0 is reserved for "refused to make a decision"
    */
    function rule(uint256 _disputeId, uint256 _ruling) virtual external;
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC3000Data.sol";

contract ERC3000Interface {
    bytes4 internal constant ERC3000_INTERFACE_ID =
        IERC3000(0).schedule.selector
        ^ IERC3000(0).execute.selector
        ^ IERC3000(0).challenge.selector
        ^ IERC3000(0).resolve.selector
        ^ IERC3000(0).veto.selector
        ^ IERC3000(0).configure.selector
    ;
}

abstract contract IERC3000 is ERC3000Interface {
    /**
     * @notice Schedules an action for execution, allowing for challenges and vetos on a defined time window
     * @param container A Container struct holding both the payload being scheduled for execution and
       the current configuration of the system
     * @return containerHash
     */
    function schedule(ERC3000Data.Container memory container) virtual public returns (bytes32 containerHash);
    event Scheduled(bytes32 indexed containerHash, ERC3000Data.Payload payload);

    /**
     * @notice Executes an action after its execution delay has passed and its state hasn't been altered by a challenge or veto
     * @param container A ERC3000Data.Container struct holding both the paylaod being scheduled for execution and
       the current configuration of the system
     * MUST be an ERC3000Executor call: payload.executor.exec(payload.actions)
     * @return failureMap
     * @return execResults
     */
    function execute(ERC3000Data.Container memory container) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Executed(bytes32 indexed containerHash, address indexed actor);

    /**
     * @notice Challenge a container in case its scheduling is illegal as per Config.rules. Pulls collateral and dispute fees from sender into contract
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
       the current configuration of the system
     * @param reason Hint for case reviewers as to why the scheduled container is illegal
     * @return resolverId
     */
    function challenge(ERC3000Data.Container memory container, bytes memory reason) virtual public returns (uint256 resolverId);
    event Challenged(bytes32 indexed containerHash, address indexed actor, bytes reason, uint256 resolverId, ERC3000Data.Collateral collateral);

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
       the current configuration of the system
     * @param resolverId disputeId in the arbitrator in which the dispute over the container was created
     * @return failureMap
     * @return execResults
     */
    function resolve(ERC3000Data.Container memory container, uint256 resolverId) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Resolved(bytes32 indexed containerHash, address indexed actor, bool approved);

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param containerHash Hash of the container being vetoed
     * @param reason Justification for the veto
     */
    function veto(bytes32 containerHash, bytes memory reason) virtual public;
    event Vetoed(bytes32 indexed containerHash, address indexed actor, bytes reason);

    /**
     * @notice Apply a new configuration for all *new* containers to be scheduled
     * @param config A ERC3000Data.Config struct holding all the new params that will control the system
     * @return configHash
     */
    function configure(ERC3000Data.Config memory config) virtual public returns (bytes32 configHash);
    event Configured(bytes32 indexed containerHash, address indexed actor, ERC3000Data.Config config);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./IERC3000Executor.sol";

library ERC3000Data {
    // TODO: come up with a non-shitty name
    struct Container {
        Payload payload;
        Config config;
    }

    // WARN: Always remember to change the 'hash' function if modifying the struct
    struct Payload {
        uint256 nonce;
        uint256 executionTime;
        address submitter;
        IERC3000Executor executor;
        Action[] actions;
        bytes32 allowFailuresMap;
        bytes proof;
    }

    struct Action {
        address to;
        uint256 value;
        bytes data;
    }

    struct Config {
        uint256 executionDelay;
        Collateral scheduleDeposit;
        Collateral challengeDeposit;
        address resolver;
        bytes rules;
    }

    struct Collateral {
        address token;
        uint256 amount;
    }

    function containerHash(bytes32 payloadHash, bytes32 configHash) internal view returns (bytes32) {
        uint chainId;
        assembly {
            chainId := chainid()
        }

        return keccak256(abi.encodePacked("erc3k-v1", address(this), chainId, payloadHash, configHash));
    }

    function hash(Container memory container) internal view returns (bytes32) {
        return containerHash(hash(container.payload), hash(container.config));
    }

    function hash(Payload memory payload) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                payload.nonce,
                payload.executionTime,
                payload.submitter,
                payload.executor,
                keccak256(abi.encode(payload.actions)),
                payload.allowFailuresMap,
                keccak256(payload.proof)
            )
        );
    }

    function hash(Config memory config) internal pure returns (bytes32) {
        return keccak256(abi.encode(config));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/aragon-court/blob/master/contracts/arbitration/IArbitrator.sol

pragma solidity ^0.6.8;

import "../erc20/SafeERC20.sol";

interface IArbitrator {
    /**
    * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
    * @param _possibleRulings Number of possible rulings allowed for the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Close the evidence period of a dispute
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(uint256 _disputeId) external;

    /**
    * @dev Execute the Arbitrable associated to a dispute based on its final ruling
    * @param _disputeId Identification number of the dispute to be executed
    */
    function executeRuling(uint256 _disputeId) external;

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell the subscription fees information for a subscriber to be up-to-date
    * @param _subscriber Address of the account paying the subscription fees for
    * @return recipient Address where the corresponding subscriptions fees must be transferred to
    * @return feeToken ERC20 token used for the subscription fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getSubscriptionFees(address _subscriber) external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

library AddressUtils {
    function toPayable(address addr) internal pure returns (address payable) {
        return address(bytes20(addr));
    }

    function toAddress(address addr) internal pure returns (address payable) {
        return address(bytes20(addr));
    }

    function isContract(address addr) internal view returns (bool result) {
        assembly {
            result := not(iszero(extcodesize(addr)))
        }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

abstract contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) virtual public view returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID
          || block.timestamp == 1; // silence visibility warning needed for overrides
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

interface IACLOracle {
    function willPerform(bytes4 role, address who, bytes calldata data) external returns (bool allowed);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

contract Initializable {
    mapping (string => uint256) public initBlocks;

    event Initialized(string indexed key);

    modifier onlyInit(string memory key) {
        require(initBlocks[key] == 0, "initializable: already initialized");
        initBlocks[key] = block.number;
        _;
        emit Initialized(key);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC3000Data.sol";

abstract contract IERC3000Executor {
    bytes4 internal constant ERC3000_EXEC_INTERFACE_ID = this.exec.selector;

    /**
     * @notice Executes all given actions
     * @param actions A array of ERC3000Data.Action for later executing those
     * @param allowFailuresMap A map with the allowed failures
     * @param memo The hash of the ERC3000Data.Container
     * @return failureMap
     * @return execResults
     */
    function exec(ERC3000Data.Action[] memory actions, bytes32 allowFailuresMap, bytes32 memo) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Executed(address indexed actor, ERC3000Data.Action[] actions, bytes32 memo, bytes32 failureMap, bytes[] execResults);
}