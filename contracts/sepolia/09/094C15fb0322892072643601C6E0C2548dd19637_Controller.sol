// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IController} from "./interfaces/IController.sol";
import {IControllerOwner} from "./interfaces/IControllerOwner.sol";
import {IAdapter} from "./interfaces/IAdapter.sol";
import {ICoordinator} from "./interfaces/ICoordinator.sol";
import {INodeStaking} from "Staking-v0.1/interfaces/INodeStaking.sol";
import {BLS} from "./libraries/BLS.sol";
import {GroupLib} from "./libraries/GroupLib.sol";
import {Coordinator} from "./Coordinator.sol";

contract Controller is Initializable, IController, IControllerOwner, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using GroupLib for GroupLib.GroupData;

    // *Constants*
    uint16 public constant BALANCE_BASE = 1;

    // *Controller Config*
    ControllerConfig private _config;
    IERC20 private _arpa;

    // *Node State Variables*
    mapping(address => Node) private _nodes; // maps node address to Node Struct
    mapping(address => uint256) private _withdrawableEths; // maps node address to withdrawable eth amount
    mapping(address => uint256) private _arpaRewards; // maps node address to arpa rewards

    // *DKG Variables*
    mapping(uint256 => address) private _coordinators; // maps group index to coordinator address

    // *Group Variables*
    GroupLib.GroupData internal _groupData;

    // *Task Variables*
    uint256 private _lastOutput;

    // *Structs*
    struct ControllerConfig {
        address stakingContractAddress;
        address adapterContractAddress;
        uint256 nodeStakingAmount;
        uint256 disqualifiedNodePenaltyAmount;
        uint256 defaultDkgPhaseDuration;
        uint256 pendingBlockAfterQuit;
        uint256 dkgPostProcessReward;
    }

    // *Events*
    event NodeRegistered(address indexed nodeAddress, bytes dkgPublicKey, uint256 groupIndex);
    event NodeActivated(address indexed nodeAddress, uint256 groupIndex);
    event NodeQuit(address indexed nodeAddress);
    event DkgPublicKeyChanged(address indexed nodeAddress, bytes dkgPublicKey);
    event NodeSlashed(address indexed nodeIdAddress, uint256 stakingRewardPenalty, uint256 pendingBlock);
    event NodeRewarded(address indexed nodeAddress, uint256 ethAmount, uint256 arpaAmount);
    event ControllerConfigSet(
        address stakingContractAddress,
        address adapterContractAddress,
        uint256 nodeStakingAmount,
        uint256 disqualifiedNodePenaltyAmount,
        uint256 defaultNumberOfCommitters,
        uint256 defaultDkgPhaseDuration,
        uint256 groupMaxCapacity,
        uint256 idealNumberOfGroups,
        uint256 pendingBlockAfterQuit,
        uint256 dkgPostProcessReward
    );
    event DkgTask(
        uint256 indexed globalEpoch,
        uint256 indexed groupIndex,
        uint256 indexed groupEpoch,
        uint256 size,
        uint256 threshold,
        address[] members,
        uint256 assignmentBlockHeight,
        address coordinatorAddress
    );

    // *Errors*
    error NodeNotRegistered();
    error NodeAlreadyRegistered();
    error NodeAlreadyActive();
    error NodeStillPending(uint256 pendingUntilBlock);
    error GroupNotExist(uint256 groupIndex);
    error CoordinatorNotFound(uint256 groupIndex);
    error DkgNotInProgress(uint256 groupIndex);
    error DkgStillInProgress(uint256 groupIndex, int8 phase);
    error EpochMismatch(uint256 groupIndex, uint256 inputGroupEpoch, uint256 currentGroupEpoch);
    error NodeNotInGroup(uint256 groupIndex, address nodeIdAddress);
    error PartialKeyAlreadyRegistered(uint256 groupIndex, address nodeIdAddress);
    error SenderNotAdapter();

    function initialize(address arpa, uint256 lastOutput) public initializer {
        _arpa = IERC20(arpa);
        _lastOutput = lastOutput;

        __Ownable_init();
    }

    // =============
    // IControllerOwner
    // =============
    function setControllerConfig(
        address stakingContractAddress,
        address adapterContractAddress,
        uint256 nodeStakingAmount,
        uint256 disqualifiedNodePenaltyAmount,
        uint256 defaultNumberOfCommitters,
        uint256 defaultDkgPhaseDuration,
        uint256 groupMaxCapacity,
        uint256 idealNumberOfGroups,
        uint256 pendingBlockAfterQuit,
        uint256 dkgPostProcessReward
    ) external override(IControllerOwner) onlyOwner {
        _config = ControllerConfig({
            stakingContractAddress: stakingContractAddress,
            adapterContractAddress: adapterContractAddress,
            nodeStakingAmount: nodeStakingAmount,
            disqualifiedNodePenaltyAmount: disqualifiedNodePenaltyAmount,
            defaultDkgPhaseDuration: defaultDkgPhaseDuration,
            pendingBlockAfterQuit: pendingBlockAfterQuit,
            dkgPostProcessReward: dkgPostProcessReward
        });

        _groupData.setConfig(idealNumberOfGroups, groupMaxCapacity, defaultNumberOfCommitters);

        emit ControllerConfigSet(
            stakingContractAddress,
            adapterContractAddress,
            nodeStakingAmount,
            disqualifiedNodePenaltyAmount,
            defaultNumberOfCommitters,
            defaultDkgPhaseDuration,
            groupMaxCapacity,
            idealNumberOfGroups,
            pendingBlockAfterQuit,
            dkgPostProcessReward
        );
    }

    // =============
    // IController
    // =============
    function nodeRegister(bytes calldata dkgPublicKey) external override(IController) {
        if (_nodes[msg.sender].idAddress != address(0)) {
            revert NodeAlreadyRegistered();
        }

        uint256[4] memory publicKey = BLS.fromBytesPublicKey(dkgPublicKey);
        if (!BLS.isValidPublicKey(publicKey)) {
            revert BLS.InvalidPublicKey();
        }
        // Lock staking amount in Staking contract
        INodeStaking(_config.stakingContractAddress).lock(msg.sender, _config.nodeStakingAmount);

        // Populate Node struct and insert into nodes
        Node storage n = _nodes[msg.sender];
        n.idAddress = msg.sender;
        n.dkgPublicKey = dkgPublicKey;
        n.state = true;

        // Initialize withdrawable eths and arpa rewards to save gas for adapter call
        _withdrawableEths[msg.sender] = BALANCE_BASE;
        _arpaRewards[msg.sender] = BALANCE_BASE;

        (uint256 groupIndex, uint256[] memory groupIndicesToEmitEvent) = _groupData.nodeJoin(msg.sender, _lastOutput);

        for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
            _emitGroupEvent(groupIndicesToEmitEvent[i]);
        }

        emit NodeRegistered(msg.sender, dkgPublicKey, groupIndex);
    }

    function nodeActivate() external override(IController) {
        Node storage node = _nodes[msg.sender];
        if (node.idAddress != msg.sender) {
            revert NodeNotRegistered();
        }

        if (node.state) {
            revert NodeAlreadyActive();
        }

        if (node.pendingUntilBlock > block.number) {
            revert NodeStillPending(node.pendingUntilBlock);
        }

        // lock up to staking amount in Staking contract
        uint256 lockedAmount = INodeStaking(_config.stakingContractAddress).getLockedAmount(msg.sender);
        if (lockedAmount < _config.nodeStakingAmount) {
            INodeStaking(_config.stakingContractAddress).lock(msg.sender, _config.nodeStakingAmount - lockedAmount);
        }

        node.state = true;

        (uint256 groupIndex, uint256[] memory groupIndicesToEmitEvent) = _groupData.nodeJoin(msg.sender, _lastOutput);

        for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
            _emitGroupEvent(groupIndicesToEmitEvent[i]);
        }

        emit NodeActivated(msg.sender, groupIndex);
    }

    function nodeQuit() external override(IController) {
        Node storage node = _nodes[msg.sender];

        if (node.idAddress != msg.sender) {
            revert NodeNotRegistered();
        }
        uint256[] memory groupIndicesToEmitEvent = _groupData.nodeLeave(msg.sender, _lastOutput);

        for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
            _emitGroupEvent(groupIndicesToEmitEvent[i]);
        }

        _freezeNode(msg.sender, _config.pendingBlockAfterQuit);

        // unlock staking amount in Staking contract
        INodeStaking(_config.stakingContractAddress).unlock(msg.sender, _config.nodeStakingAmount);

        emit NodeQuit(msg.sender);
    }

    function changeDkgPublicKey(bytes calldata dkgPublicKey) external override(IController) {
        Node storage node = _nodes[msg.sender];
        if (node.idAddress != msg.sender) {
            revert NodeNotRegistered();
        }

        if (node.state) {
            revert NodeAlreadyActive();
        }

        uint256[4] memory publicKey = BLS.fromBytesPublicKey(dkgPublicKey);
        if (!BLS.isValidPublicKey(publicKey)) {
            revert BLS.InvalidPublicKey();
        }

        node.dkgPublicKey = dkgPublicKey;

        emit DkgPublicKeyChanged(msg.sender, dkgPublicKey);
    }

    function commitDkg(CommitDkgParams memory params) external override(IController) {
        if (params.groupIndex >= _groupData.groupCount) revert GroupNotExist(params.groupIndex);

        // require coordinator exists
        if (_coordinators[params.groupIndex] == address(0)) {
            revert CoordinatorNotFound(params.groupIndex);
        }

        // Ensure DKG Proccess is in Phase
        ICoordinator coordinator = ICoordinator(_coordinators[params.groupIndex]);
        if (coordinator.inPhase() == -1) {
            revert DkgNotInProgress(params.groupIndex);
        }

        // Ensure epoch is correct, node is in group, and has not already submitted a partial key
        Group storage g = _groupData.groups[params.groupIndex];
        if (params.groupEpoch != g.epoch) {
            revert EpochMismatch(params.groupIndex, params.groupEpoch, g.epoch);
        }

        if (_groupData.getMemberIndexByAddress(params.groupIndex, msg.sender) == -1) {
            revert NodeNotInGroup(params.groupIndex, msg.sender);
        }

        // check to see if member has called commitdkg in the past.
        if (isPartialKeyRegistered(params.groupIndex, msg.sender)) {
            revert PartialKeyAlreadyRegistered(params.groupIndex, msg.sender);
        }

        // require publickey and partial public key are not empty  / are the right format
        uint256[4] memory partialPublicKey = BLS.fromBytesPublicKey(params.partialPublicKey);
        if (!BLS.isValidPublicKey(partialPublicKey)) {
            revert BLS.InvalidPartialPublicKey();
        }

        uint256[4] memory publicKey = BLS.fromBytesPublicKey(params.publicKey);
        if (!BLS.isValidPublicKey(publicKey)) {
            revert BLS.InvalidPublicKey();
        }

        // Populate CommitResult / CommitCache
        CommitResult memory commitResult = CommitResult({
            groupEpoch: params.groupEpoch,
            publicKey: publicKey,
            disqualifiedNodes: params.disqualifiedNodes
        });

        if (!_groupData.tryAddToExistingCommitCache(params.groupIndex, commitResult)) {
            CommitCache memory commitCache = CommitCache({commitResult: commitResult, nodeIdAddress: new address[](1)});

            commitCache.nodeIdAddress[0] = msg.sender;
            g.commitCacheList.push(commitCache);
        }

        // no matter consensus previously reached, update the partial public key of the given node's member entry in the group
        g.members[uint256(_groupData.getMemberIndexByAddress(params.groupIndex, msg.sender))].partialPublicKey =
            partialPublicKey;

        // if not.. call get StrictlyMajorityIdenticalCommitmentResult for the group and check if consensus has been reached.
        if (!g.isStrictlyMajorityConsensusReached) {
            (bool success, address[] memory disqualifiedNodes) =
                _groupData.tryEnableGroup(params.groupIndex, _lastOutput);

            if (success) {
                // Iterate over disqualified nodes and call slashNode on each.
                for (uint256 i = 0; i < disqualifiedNodes.length; i++) {
                    _slashNode(disqualifiedNodes[i], _config.disqualifiedNodePenaltyAmount, 0);
                }
            }
        }
    }

    function postProcessDkg(uint256 groupIndex, uint256 groupEpoch) external override(IController) {
        if (groupIndex >= _groupData.groupCount) revert GroupNotExist(groupIndex);

        // require calling node is in group
        if (_groupData.getMemberIndexByAddress(groupIndex, msg.sender) == -1) {
            revert NodeNotInGroup(groupIndex, msg.sender);
        }

        // require correct epoch
        Group storage g = _groupData.groups[groupIndex];
        if (groupEpoch != g.epoch) {
            revert EpochMismatch(groupIndex, groupEpoch, g.epoch);
        }

        // require coordinator exists
        if (_coordinators[groupIndex] == address(0)) {
            revert CoordinatorNotFound(groupIndex);
        }

        // Ensure DKG Proccess is out of phase
        ICoordinator coordinator = ICoordinator(_coordinators[groupIndex]);
        if (coordinator.inPhase() != -1) {
            revert DkgStillInProgress(groupIndex, coordinator.inPhase());
        }

        // delete coordinator
        coordinator.selfDestruct(); // coordinator self destructs
        _coordinators[groupIndex] = address(0); // remove coordinator from mapping

        if (!g.isStrictlyMajorityConsensusReached) {
            (address[] memory nodesToBeSlashed, uint256[] memory groupIndicesToEmitEvent) =
                _groupData.handleUnsuccessfulGroupDkg(groupIndex, _lastOutput);

            for (uint256 i = 0; i < nodesToBeSlashed.length; i++) {
                _slashNode(nodesToBeSlashed[i], _config.disqualifiedNodePenaltyAmount, 0);
            }
            for (uint256 i = 0; i < groupIndicesToEmitEvent.length; i++) {
                _emitGroupEvent(groupIndicesToEmitEvent[i]);
            }
        }

        // update rewards for calling node
        _arpaRewards[msg.sender] += _config.dkgPostProcessReward;

        emit NodeRewarded(msg.sender, 0, _config.dkgPostProcessReward);
    }

    function nodeWithdraw(address recipient) external override(IController) {
        uint256 ethAmount = _withdrawableEths[msg.sender];
        uint256 arpaAmount = _arpaRewards[msg.sender];
        if (ethAmount > BALANCE_BASE) {
            _withdrawableEths[msg.sender] = BALANCE_BASE;
            IAdapter(_config.adapterContractAddress).nodeWithdrawETH(recipient, ethAmount - BALANCE_BASE);
        }
        if (arpaAmount > BALANCE_BASE) {
            _arpaRewards[msg.sender] = BALANCE_BASE;
            _arpa.safeTransfer(recipient, arpaAmount - BALANCE_BASE);
        }
    }

    function addReward(address[] memory nodes, uint256 ethAmount, uint256 arpaAmount) public override(IController) {
        if (msg.sender != _config.adapterContractAddress) {
            revert SenderNotAdapter();
        }
        for (uint256 i = 0; i < nodes.length; i++) {
            _withdrawableEths[nodes[i]] += ethAmount;
            _arpaRewards[nodes[i]] += arpaAmount;
            emit NodeRewarded(nodes[i], ethAmount, arpaAmount);
        }
    }

    function setLastOutput(uint256 lastOutput) external override(IController) {
        if (msg.sender != _config.adapterContractAddress) {
            revert SenderNotAdapter();
        }
        _lastOutput = lastOutput;
    }

    function getValidGroupIndices() public view override(IController) returns (uint256[] memory) {
        return _groupData.getValidGroupIndices();
    }

    function getGroupCount() external view override(IController) returns (uint256) {
        return _groupData.groupCount;
    }

    function getGroup(uint256 groupIndex) public view override(IController) returns (Group memory) {
        return _groupData.groups[groupIndex];
    }

    function getGroupThreshold(uint256 groupIndex) public view override(IController) returns (uint256, uint256) {
        return (_groupData.groups[groupIndex].threshold, _groupData.groups[groupIndex].size);
    }

    function getNode(address nodeAddress) public view override(IController) returns (Node memory) {
        return _nodes[nodeAddress];
    }

    function getMember(uint256 groupIndex, uint256 memberIndex)
        public
        view
        override(IController)
        returns (Member memory)
    {
        return _groupData.groups[groupIndex].members[memberIndex];
    }

    function getBelongingGroup(address nodeAddress) external view override(IController) returns (int256, int256) {
        return _groupData.getBelongingGroupByMemberAddress(nodeAddress);
    }

    function getCoordinator(uint256 groupIndex) public view override(IController) returns (address) {
        return _coordinators[groupIndex];
    }

    function getNodeWithdrawableTokens(address nodeAddress)
        public
        view
        override(IController)
        returns (uint256, uint256)
    {
        return (
            _withdrawableEths[nodeAddress] == 0 ? 0 : (_withdrawableEths[nodeAddress] - BALANCE_BASE),
            _arpaRewards[nodeAddress] == 0 ? 0 : (_arpaRewards[nodeAddress] - BALANCE_BASE)
        );
    }

    function getLastOutput() external view returns (uint256) {
        return _lastOutput;
    }

    /// Check to see if a group has a partial public key registered for a given node.
    function isPartialKeyRegistered(uint256 groupIndex, address nodeIdAddress)
        public
        view
        override(IController)
        returns (bool)
    {
        Group memory g = _groupData.groups[groupIndex];
        for (uint256 i = 0; i < g.members.length; i++) {
            if (g.members[i].nodeIdAddress == nodeIdAddress) {
                return g.members[i].partialPublicKey[0] != 0;
            }
        }
        return false;
    }

    // =============
    // Internal
    // =============

    function _emitGroupEvent(uint256 groupIndex) internal {
        _groupData.prepareGroupEvent(groupIndex);

        Group memory g = _groupData.groups[groupIndex];

        // Deploy coordinator, add to coordinators mapping
        Coordinator coordinator;
        coordinator = new Coordinator(g.threshold, _config.defaultDkgPhaseDuration);
        _coordinators[groupIndex] = address(coordinator);

        // Initialize Coordinator
        address[] memory groupNodes = new address[](g.size);
        bytes[] memory groupKeys = new bytes[](g.size);

        for (uint256 i = 0; i < g.size; i++) {
            groupNodes[i] = g.members[i].nodeIdAddress;
            groupKeys[i] = _nodes[g.members[i].nodeIdAddress].dkgPublicKey;
        }

        coordinator.initialize(groupNodes, groupKeys);

        emit DkgTask(
            _groupData.epoch, g.index, g.epoch, g.size, g.threshold, groupNodes, block.number, address(coordinator)
        );
    }

    // Give node staking reward penalty and freezeNode
    function _slashNode(address nodeIdAddress, uint256 stakingRewardPenalty, uint256 pendingBlock) internal {
        // slash staking reward in Staking contract
        INodeStaking(_config.stakingContractAddress).slashDelegationReward(nodeIdAddress, stakingRewardPenalty);

        // remove node from group if handleGroup is true and deactivate it
        _freezeNode(nodeIdAddress, pendingBlock);

        emit NodeSlashed(nodeIdAddress, stakingRewardPenalty, pendingBlock);
    }

    function _freezeNode(address nodeIdAddress, uint256 pendingBlock) internal {
        // set node state to false for frozen node
        _nodes[nodeIdAddress].state = false;

        uint256 currentBlock = block.number;
        // if the node is already pending, add the pending block to the current pending block
        if (_nodes[nodeIdAddress].pendingUntilBlock > currentBlock) {
            _nodes[nodeIdAddress].pendingUntilBlock += pendingBlock;
            // else set the pending block to the current block + pending block
        } else {
            _nodes[nodeIdAddress].pendingUntilBlock = currentBlock + pendingBlock;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IController {
    struct Group {
        uint256 index;
        uint256 epoch;
        uint256 size;
        uint256 threshold;
        Member[] members;
        address[] committers;
        CommitCache[] commitCacheList;
        bool isStrictlyMajorityConsensusReached;
        uint256[4] publicKey;
    }

    struct Member {
        address nodeIdAddress;
        uint256[4] partialPublicKey;
    }

    struct CommitResult {
        uint256 groupEpoch;
        uint256[4] publicKey;
        address[] disqualifiedNodes;
    }

    struct CommitCache {
        address[] nodeIdAddress;
        CommitResult commitResult;
    }

    struct Node {
        address idAddress;
        bytes dkgPublicKey;
        bool state;
        uint256 pendingUntilBlock;
    }

    struct CommitDkgParams {
        uint256 groupIndex;
        uint256 groupEpoch;
        bytes publicKey;
        bytes partialPublicKey;
        address[] disqualifiedNodes;
    }

    // node transaction
    function nodeRegister(bytes calldata dkgPublicKey) external;

    function nodeActivate() external;

    function nodeQuit() external;

    function changeDkgPublicKey(bytes calldata dkgPublicKey) external;

    function commitDkg(CommitDkgParams memory params) external;

    function postProcessDkg(uint256 groupIndex, uint256 groupEpoch) external;

    function nodeWithdraw(address recipient) external;

    // adapter transaction
    function addReward(address[] memory nodes, uint256 ethAmount, uint256 arpaAmount) external;

    function setLastOutput(uint256 lastOutput) external;

    // view
    /// @notice Get list of all group indexes where group.isStrictlyMajorityConsensusReached == true
    /// @return uint256[] List of valid group indexes
    function getValidGroupIndices() external view returns (uint256[] memory);

    function getGroupCount() external view returns (uint256);

    function getGroup(uint256 index) external view returns (Group memory);

    function getGroupThreshold(uint256 groupIndex) external view returns (uint256, uint256);

    function getNode(address nodeAddress) external view returns (Node memory);

    function getMember(uint256 groupIndex, uint256 memberIndex) external view returns (Member memory);

    /// @notice Get the group index and member index of a given node.
    function getBelongingGroup(address nodeAddress) external view returns (int256, int256);

    function getCoordinator(uint256 groupIndex) external view returns (address);

    function getNodeWithdrawableTokens(address nodeAddress) external view returns (uint256, uint256);

    function getLastOutput() external view returns (uint256);

    /// @notice Check to see if a group has a partial public key registered for a given node.
    /// @return bool True if the node has a partial public key registered for the group.
    function isPartialKeyRegistered(uint256 groupIndex, address nodeIdAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IControllerOwner {
    /**
     * @notice Sets the configuration of the controller
     * @param stakingContract The address of the staking contract
     * @param adapterContract The address of the adapter contract
     * @param nodeStakingAmount The amount of ARPA must staked by a node
     * @param disqualifiedNodePenaltyAmount The amount of ARPA will be slashed from a node if it is disqualified
     * @param defaultNumberOfCommitters The default number of committers for a DKG
     * @param defaultDkgPhaseDuration The default duration(block number) of a DKG phase
     * @param groupMaxCapacity The maximum number of nodes in a group
     * @param idealNumberOfGroups The ideal number of groups
     * @param pendingBlockAfterQuit The number of blocks a node must wait before joining a group after quitting
     * @param dkgPostProcessReward The amount of ARPA will be rewarded to the node after dkgPostProcess is completed
     */
    function setControllerConfig(
        address stakingContract,
        address adapterContract,
        uint256 nodeStakingAmount,
        uint256 disqualifiedNodePenaltyAmount,
        uint256 defaultNumberOfCommitters,
        uint256 defaultDkgPhaseDuration,
        uint256 groupMaxCapacity,
        uint256 idealNumberOfGroups,
        uint256 pendingBlockAfterQuit,
        uint256 dkgPostProcessReward
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IRequestTypeBase} from "./IRequestTypeBase.sol";

interface IAdapter is IRequestTypeBase {
    struct PartialSignature {
        uint256 index;
        uint256 partialSignature;
    }

    struct RandomnessRequestParams {
        RequestType requestType;
        bytes params;
        uint64 subId;
        uint256 seed;
        uint16 requestConfirmations;
        uint256 callbackGasLimit;
        uint256 callbackMaxGasPrice;
    }

    struct RequestDetail {
        uint64 subId;
        uint256 groupIndex;
        RequestType requestType;
        bytes params;
        address callbackContract;
        uint256 seed;
        uint16 requestConfirmations;
        uint256 callbackGasLimit;
        uint256 callbackMaxGasPrice;
        uint256 blockNum;
    }

    // controller transaction
    function nodeWithdrawETH(address recipient, uint256 ethAmount) external;

    // consumer contract transaction
    function requestRandomness(RandomnessRequestParams calldata params) external returns (bytes32);

    function fulfillRandomness(
        uint256 groupIndex,
        bytes32 requestId,
        uint256 signature,
        RequestDetail calldata requestDetail,
        PartialSignature[] calldata partialSignatures
    ) external;

    // user transaction
    function createSubscription() external returns (uint64);

    function addConsumer(uint64 subId, address consumer) external;

    function fundSubscription(uint64 subId) external payable;

    function setReferral(uint64 subId, uint64 referralSubId) external;

    function cancelSubscription(uint64 subId, address to) external;

    function removeConsumer(uint64 subId, address consumer) external;

    // view
    function getLastSubscription(address consumer) external view returns (uint64);

    function getSubscription(uint64 subId)
        external
        view
        returns (uint256 balance, uint256 inflightCost, uint64 reqCount, address owner, address[] memory consumers);

    function getPendingRequestCommitment(bytes32 requestId) external view returns (bytes32);

    function getLastRandomness() external view returns (uint256);

    function getRandomnessCount() external view returns (uint256);

    /*
     * @notice Compute fee based on the request count
     * @param reqCount number of requests
     * @return feePPM fee in ARPA PPM
     */
    function getFeeTier(uint64 reqCount) external view returns (uint32);

    // Estimate the amount of gas used for fulfillment
    function estimatePaymentAmountInETH(
        uint256 callbackGasLimit,
        uint256 gasExceptCallback,
        uint32 fulfillmentFlatFeeEthPPM,
        uint256 weiPerUnitGas
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICoordinator {
    function inPhase() external view returns (int8);

    function initialize(address[] memory nodes, bytes[] memory publicKeys) external;

    function startBlock() external view returns (uint256);

    function selfDestruct() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface INodeStaking {
    /// @notice This event is emitted when a node locks stake in the pool.
    /// @param staker Staker address
    /// @param newLock New principal amount locked
    event Locked(address staker, uint256 newLock);

    /// @notice This event is emitted when a node unlocks stake in the pool.
    /// @param staker Staker address
    /// @param newUnlock New principal amount unlocked
    event Unlocked(address staker, uint256 newUnlock);

    /// @notice This event is emitted when a node gets delegation reward slashed.
    /// @param staker Staker address
    /// @param amount Amount slashed
    event DelegationRewardSlashed(address staker, uint256 amount);

    /// @notice This error is raised when attempting to unlock with more than the current locked staking amount
    /// @param currentLockedStakingAmount Current locked staking amount
    error InadequateOperatorLockedStakingAmount(uint256 currentLockedStakingAmount);

    /// @notice This function allows controller to lock staking amount for a node.
    /// @param staker Node address
    /// @param amount Amount to lock
    function lock(address staker, uint256 amount) external;

    /// @notice This function allows controller to unlock staking amount for a node.
    /// @param staker Node address
    /// @param amount Amount to unlock
    function unlock(address staker, uint256 amount) external;

    /// @notice This function allows controller to slash delegation reward of a node.
    /// @param staker Node address
    /// @param amount Amount to slash
    function slashDelegationReward(address staker, uint256 amount) external;

    /// @notice This function returns the locked amount of a node.
    /// @param staker Node address
    function getLockedAmount(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL 3.0
pragma solidity ^0.8.15;

import {BN256G2} from "./BN256G2.sol";

/**
 * @title BLS operations on bn254 curve
 * @author ARPA-Network adapted from https://github.com/ChihChengLiang/bls_solidity_python
 * @dev Homepage: https://github.com/ARPA-Network/BLS-TSS-Network
 *      Signature and Point hashed to G1 are represented by affine coordinate in big-endian order, deserialized from compressed format.
 *      Public key is represented and serialized by affine coordinate Q-x-re(x0), Q-x-im(x1), Q-y-re(y0), Q-y-im(y1) in big-endian order.
 */
library BLS {
    // Field order
    uint256 public constant N = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Negated genarator of G2
    uint256 public constant N_G2_X1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 public constant N_G2_X0 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 public constant N_G2_Y1 = 17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 public constant N_G2_Y0 = 13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 public constant FIELD_MASK = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    error MustNotBeInfinity();
    error InvalidPublicKeyEncoding();
    error InvalidSignatureFormat();
    error InvalidSignature();
    error InvalidPartialSignatureFormat();
    error InvalidPartialSignatures();
    error EmptyPartialSignatures();
    error InvalidPublicKey();
    error InvalidPartialPublicKey();

    function verifySingle(uint256[2] memory signature, uint256[4] memory pubkey, uint256[2] memory message)
        public
        view
        returns (bool)
    {
        uint256[12] memory input = [
            signature[0],
            signature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            pubkey[1],
            pubkey[0],
            pubkey[3],
            pubkey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
            case 0 { invalid() }
        }
        require(success, "");
        return out[0] != 0;
    }

    function verifyPartials(uint256[2][] memory partials, uint256[4][] memory pubkeys, uint256[2] memory message)
        public
        view
        returns (bool)
    {
        uint256[2] memory aggregatedSignature;
        uint256[4] memory aggregatedPublicKey;
        for (uint256 i = 0; i < partials.length; i++) {
            aggregatedSignature = addPoints(aggregatedSignature, partials[i]);
            aggregatedPublicKey = BN256G2.ecTwistAdd(aggregatedPublicKey, pubkeys[i]);
        }

        uint256[12] memory input = [
            aggregatedSignature[0],
            aggregatedSignature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            aggregatedPublicKey[1],
            aggregatedPublicKey[0],
            aggregatedPublicKey[3],
            aggregatedPublicKey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
            case 0 { invalid() }
        }
        require(success, "");
        return out[0] != 0;
    }

    // TODO a simple hash and increment implementation, can be improved later
    function hashToPoint(bytes memory data) public view returns (uint256[2] memory p) {
        bool found;
        bytes32 candidateHash = keccak256(data);
        while (true) {
            (p, found) = mapToPoint(candidateHash);
            if (found) {
                break;
            }
            candidateHash = keccak256(bytes.concat(candidateHash));
        }
    }

    //  we take the y-coordinate as the lexicographically largest of the two associated with the encoded x-coordinate
    function mapToPoint(bytes32 _x) internal view returns (uint256[2] memory p, bool found) {
        uint256 y;
        uint256 x = uint256(_x) % N;
        (y, found) = deriveYOnG1(x);
        if (found) {
            p[0] = x;
            p[1] = y > N / 2 ? N - y : y;
        }
    }

    function deriveYOnG1(uint256 x) internal view returns (uint256, bool) {
        uint256 y;
        y = mulmod(x, x, N);
        y = mulmod(y, x, N);
        y = addmod(y, 3, N);
        return sqrt(y);
    }

    function isValidPublicKey(uint256[4] memory publicKey) public pure returns (bool) {
        if ((publicKey[0] >= N) || (publicKey[1] >= N) || (publicKey[2] >= N || (publicKey[3] >= N))) {
            return false;
        } else {
            return isOnCurveG2(publicKey);
        }
    }

    function fromBytesPublicKey(bytes memory point) public pure returns (uint256[4] memory pubkey) {
        if (point.length != 128) {
            revert InvalidPublicKeyEncoding();
        }
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // look the first 32 bytes of a bytes struct is its length
            x0 := mload(add(point, 32))
            x1 := mload(add(point, 64))
            y0 := mload(add(point, 96))
            y1 := mload(add(point, 128))
        }
        pubkey = [x0, x1, y0, y1];
    }

    function decompress(uint256 compressedSignature) public view returns (uint256[2] memory uncompressed) {
        uint256 x = compressedSignature & FIELD_MASK;
        // The most significant bit, when set, indicates that the y-coordinate of the point
        // is the lexicographically largest of the two associated values.
        // The second-most significant bit indicates that the point is at infinity. If this bit is set,
        // the remaining bits of the group element's encoding should be set to zero.
        // We don't accept infinity as valid signature.
        uint256 decision = compressedSignature >> 254;
        if (decision & 1 == 1) {
            revert MustNotBeInfinity();
        }
        uint256 y;
        (y,) = deriveYOnG1(x);

        // If the following two conditions or their negative forms are not met at the same time, get the negative y.
        // 1. The most significant bit of compressed signature is set
        // 2. The y we recovered first is the lexicographically largest
        if (((decision >> 1) ^ (y > N / 2 ? 1 : 0)) == 1) {
            y = N - y;
        }
        return [x, y];
    }

    function isValid(uint256 compressedSignature) public view returns (bool) {
        uint256 x = compressedSignature & FIELD_MASK;
        if (x >= N) {
            return false;
        } else if (x == 0) {
            return false;
        }
        return isOnCurveG1(x);
    }

    function isOnCurveG1(uint256[2] memory point) internal pure returns (bool _isOnCurve) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            let t2 := mulmod(t0, t0, N)
            t2 := mulmod(t2, t0, N)
            t2 := addmod(t2, 3, N)
            t1 := mulmod(t1, t1, N)
            _isOnCurve := eq(t1, t2)
        }
    }

    function isOnCurveG1(uint256 x) internal view returns (bool _isOnCurve) {
        bool callSuccess;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let t0 := x
            let t1 := mulmod(t0, t0, N)
            t1 := mulmod(t1, t0, N)
            // x ^ 3 + b
            t1 := addmod(t1, 3, N)

            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), t1)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(add(freemem, 0x80), 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3)
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
            callSuccess := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            _isOnCurve := eq(1, mload(freemem))
        }
    }

    function isOnCurveG2(uint256[4] memory point) internal pure returns (bool _isOnCurve) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // x0, x1
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            // x0 ^ 2
            let t2 := mulmod(t0, t0, N)
            // x1 ^ 2
            let t3 := mulmod(t1, t1, N)
            // 3 * x0 ^ 2
            let t4 := add(add(t2, t2), t2)
            // 3 * x1 ^ 2
            let t5 := addmod(add(t3, t3), t3, N)
            // x0 * (x0 ^ 2 - 3 * x1 ^ 2)
            t2 := mulmod(add(t2, sub(N, t5)), t0, N)
            // x1 * (3 * x0 ^ 2 - x1 ^ 2)
            t3 := mulmod(add(t4, sub(N, t3)), t1, N)

            // x ^ 3 + b
            t0 := addmod(t2, 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5, N)
            t1 := addmod(t3, 0x009713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2, N)

            // y0, y1
            t2 := mload(add(point, 64))
            t3 := mload(add(point, 96))
            // y ^ 2
            t4 := mulmod(addmod(t2, t3, N), addmod(t2, sub(N, t3), N), N)
            t3 := mulmod(shl(1, t2), t3, N)

            // y ^ 2 == x ^ 3 + b
            _isOnCurve := and(eq(t0, t4), eq(t1, t3))
        }
    }

    function sqrt(uint256 xx) internal view returns (uint256 x, bool hasRoot) {
        bool callSuccess;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), xx)
            // this is enabled by N % 4 = 3 and Fermat's little theorem
            // (N + 1) / 4 = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
            mstore(add(freemem, 0x80), 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52)
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
            callSuccess := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            x := mload(freemem)
            hasRoot := eq(xx, mulmod(x, x, N))
        }
        require(callSuccess, "BLS: sqrt modexp call failed");
    }

    /// @notice Add two points in G1
    function addPoints(uint256[2] memory p1, uint256[2] memory p2) internal view returns (uint256[2] memory ret) {
        uint256[4] memory input;
        input[0] = p1[0];
        input[1] = p1[1];
        input[2] = p2[0];
        input[3] = p2[1];
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, ret, 0x60)
        }
        // solhint-disable-next-line reason-string
        require(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IController} from "../interfaces/IController.sol";
// solhint-disable-next-line no-global-import
import "../utils/Utils.sol" as Utils;

library GroupLib {
    // *Constants*
    uint256 public constant DEFAULT_MINIMUM_THRESHOLD = 3;

    struct GroupData {
        uint256 epoch;
        uint256 groupCount;
        mapping(uint256 => IController.Group) groups; // group_index => Group struct
        uint256 idealNumberOfGroups;
        uint256 groupMaxCapacity;
        uint256 defaultNumberOfCommitters;
    }

    event GroupRebalanced(uint256 indexed groupIndex1, uint256 indexed groupIndex2);

    // =============
    // Transaction
    // =============

    function setConfig(
        GroupData storage groupData,
        uint256 idealNumberOfGroups,
        uint256 groupMaxCapacity,
        uint256 defaultNumberOfCommitters
    ) public {
        groupData.idealNumberOfGroups = idealNumberOfGroups;
        groupData.groupMaxCapacity = groupMaxCapacity;
        groupData.defaultNumberOfCommitters = defaultNumberOfCommitters;
    }

    function nodeJoin(GroupData storage groupData, address idAddress, uint256 lastOutput)
        public
        returns (uint256 groupIndex, uint256[] memory groupIndicesToEmitEvent)
    {
        groupIndicesToEmitEvent = new uint256[](0);

        bool needRebalance;
        (groupIndex, needRebalance) = findOrCreateTargetGroup(groupData);

        bool needEmitGroupEvent = addToGroup(groupData, idAddress, groupIndex);
        if (needEmitGroupEvent) {
            groupIndicesToEmitEvent = new uint256[](1);
            groupIndicesToEmitEvent[0] = groupIndex;
            return (groupIndex, groupIndicesToEmitEvent);
        }

        if (needRebalance) {
            (bool rebalanceSuccess, uint256 groupIndexToRebalance) =
                tryRebalanceGroup(groupData, groupIndex, lastOutput);
            if (rebalanceSuccess) {
                groupIndicesToEmitEvent = new uint256[](2);
                groupIndicesToEmitEvent[0] = groupIndex;
                groupIndicesToEmitEvent[1] = groupIndexToRebalance;
            }
        }
    }

    function nodeLeave(GroupData storage groupData, address idAddress, uint256 lastOutput)
        public
        returns (uint256[] memory groupIndicesToEmitEvent)
    {
        groupIndicesToEmitEvent = new uint256[](0);

        (int256 groupIndex, int256 memberIndex) = getBelongingGroupByMemberAddress(groupData, idAddress);

        if (groupIndex != -1) {
            (bool needRebalance, bool needEmitGroupEvent) =
                removeFromGroup(groupData, uint256(memberIndex), uint256(groupIndex));
            if (needEmitGroupEvent) {
                groupIndicesToEmitEvent = new uint256[](1);
                groupIndicesToEmitEvent[0] = uint256(groupIndex);
                return groupIndicesToEmitEvent;
            }
            if (needRebalance) {
                return arrangeMembersInGroup(groupData, uint256(groupIndex), lastOutput);
            }
        }
    }

    function tryEnableGroup(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        public
        returns (bool success, address[] memory disqualifiedNodes)
    {
        IController.Group storage g = groupData.groups[groupIndex];
        IController.CommitCache memory identicalCommits =
            getStrictlyMajorityIdenticalCommitmentResult(groupData, groupIndex);

        if (identicalCommits.nodeIdAddress.length != 0) {
            disqualifiedNodes = identicalCommits.commitResult.disqualifiedNodes;

            // Get list of majority members with disqualified nodes excluded
            address[] memory majorityMembers =
                Utils.getNonDisqualifiedMajorityMembers(identicalCommits.nodeIdAddress, disqualifiedNodes);

            if (majorityMembers.length >= g.threshold) {
                // Remove all members from group where member.nodeIdAddress is in the disqualified nodes.
                for (uint256 i = 0; i < disqualifiedNodes.length; i++) {
                    for (uint256 j = 0; j < g.members.length; j++) {
                        if (g.members[j].nodeIdAddress == disqualifiedNodes[i]) {
                            g.members[j] = g.members[g.members.length - 1];
                            g.members.pop();
                            break;
                        }
                    }
                }

                // Update group with new values
                g.isStrictlyMajorityConsensusReached = true;
                g.size -= identicalCommits.commitResult.disqualifiedNodes.length;
                g.publicKey = identicalCommits.commitResult.publicKey;

                // Create indexMemberMap: Iterate through group.members and create mapping: memberIndex -> nodeIdAddress
                // Create qualifiedIndices: Iterate through group, add all member indexes found in majorityMembers.
                uint256[] memory qualifiedIndices = new uint256[](
                        majorityMembers.length
                    );

                for (uint256 j = 0; j < majorityMembers.length; j++) {
                    for (uint256 i = 0; i < g.members.length; i++) {
                        if (g.members[i].nodeIdAddress == majorityMembers[j]) {
                            qualifiedIndices[j] = i;
                            break;
                        }
                    }
                }

                // Compute commiter_indices by calling pickRandomIndex with qualifiedIndices as input.
                uint256[] memory committerIndices =
                    Utils.pickRandomIndex(lastOutput, qualifiedIndices, groupData.defaultNumberOfCommitters);

                // For selected commiter_indices: add corresponding members into g.committers
                g.committers = new address[](committerIndices.length);
                for (uint256 i = 0; i < committerIndices.length; i++) {
                    g.committers[i] = g.members[committerIndices[i]].nodeIdAddress;
                }

                return (true, disqualifiedNodes);
            }
        }
    }

    function handleUnsuccessfulGroupDkg(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        public
        returns (address[] memory nodesToBeSlashed, uint256[] memory groupIndicesToEmitEvent)
    {
        IController.Group storage g = groupData.groups[groupIndex];

        // get strictly majority identical commitment result
        IController.CommitCache memory majorityMembers =
            getStrictlyMajorityIdenticalCommitmentResult(groupData, groupIndex);

        if (majorityMembers.nodeIdAddress.length == 0) {
            // if empty cache: zero out group
            g.size = 0;
            g.threshold = 0;

            nodesToBeSlashed = new address[](g.members.length);
            for (uint256 i = 0; i < g.members.length; i++) {
                nodesToBeSlashed[i] = g.members[i].nodeIdAddress;
            }

            // zero out group members
            delete g.members;

            return (nodesToBeSlashed, new uint256[](0));
        } else {
            address[] memory disqualifiedNodes = majorityMembers.commitResult.disqualifiedNodes;
            g.size -= disqualifiedNodes.length;
            uint256 minimum = Utils.minimumThreshold(g.size);

            // set g.threshold to max (default min threshold / minimum threshold)
            g.threshold = GroupLib.DEFAULT_MINIMUM_THRESHOLD > minimum ? GroupLib.DEFAULT_MINIMUM_THRESHOLD : minimum;

            // Delete disqualified members from group
            for (uint256 j = 0; j < disqualifiedNodes.length; j++) {
                for (uint256 i = 0; i < g.members.length; i++) {
                    if (g.members[i].nodeIdAddress == disqualifiedNodes[j]) {
                        g.members[i] = g.members[g.members.length - 1];
                        g.members.pop();
                        break;
                    }
                }
            }

            return (disqualifiedNodes, arrangeMembersInGroup(groupData, groupIndex, lastOutput));
        }
    }

    function tryAddToExistingCommitCache(
        GroupData storage groupData,
        uint256 groupIndex,
        IController.CommitResult memory commitResult
    ) public returns (bool isExist) {
        IController.Group storage g = groupData.groups[groupIndex];
        for (uint256 i = 0; i < g.commitCacheList.length; i++) {
            if (keccak256(abi.encode(g.commitCacheList[i].commitResult)) == keccak256(abi.encode(commitResult))) {
                g.commitCacheList[i].nodeIdAddress.push(msg.sender);
                return true;
            }
        }
    }

    function prepareGroupEvent(GroupData storage groupData, uint256 groupIndex) internal {
        groupData.epoch++;
        IController.Group storage g = groupData.groups[groupIndex];
        g.epoch++;
        g.isStrictlyMajorityConsensusReached = false;

        delete g.committers;
        delete g.commitCacheList;

        for (uint256 i = 0; i < g.members.length; i++) {
            delete g.members[i].partialPublicKey;
        }
    }

    // =============
    // View
    // =============
    // Find group with member address equals to nodeIdAddress, return -1 if not found.
    function getBelongingGroupByMemberAddress(GroupData storage groupData, address nodeIdAddress)
        public
        view
        returns (int256, int256)
    {
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            int256 memberIndex = getMemberIndexByAddress(groupData, i, nodeIdAddress);
            if (memberIndex != -1) {
                return (int256(i), memberIndex);
            }
        }
        return (-1, -1);
    }

    function getMemberIndexByAddress(GroupData storage groupData, uint256 groupIndex, address nodeIdAddress)
        public
        view
        returns (int256)
    {
        IController.Group memory g = groupData.groups[groupIndex];
        for (uint256 i = 0; i < g.members.length; i++) {
            if (g.members[i].nodeIdAddress == nodeIdAddress) {
                return int256(i);
            }
        }
        return -1;
    }

    function getValidGroupIndices(GroupData storage groupData) public view returns (uint256[] memory) {
        uint256[] memory groupIndices = new uint256[](groupData.groupCount); //max length is group count
        uint256 index = 0;
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            IController.Group memory g = groupData.groups[i];
            if (g.isStrictlyMajorityConsensusReached) {
                groupIndices[index] = i;
                index++;
            }
        }

        return Utils.trimTrailingElements(groupIndices, index);
    }

    // =============
    // Internal
    // =============
    // Tries to rebalance the groups, and if it fails, it collects the IDs of the members in the group and tries to add them to other groups.
    // If a member is added to another group, the group is checked to see if its size meets a threshold; if it does, a group event is emitted.
    function arrangeMembersInGroup(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        internal
        returns (uint256[] memory groupIndicesToEmitEvent)
    {
        groupIndicesToEmitEvent = new uint256[](0);
        IController.Group storage g = groupData.groups[groupIndex];
        if (g.size == 0) {
            return groupIndicesToEmitEvent;
        }

        (bool rebalanceSuccess, uint256 groupIndexToRebalance) = tryRebalanceGroup(groupData, groupIndex, lastOutput);
        if (rebalanceSuccess) {
            groupIndicesToEmitEvent = new uint256[](2);
            groupIndicesToEmitEvent[0] = groupIndex;
            groupIndicesToEmitEvent[1] = groupIndexToRebalance;
            return groupIndicesToEmitEvent;
        }

        // Get group and set isStrictlyMajorityConsensusReached to false
        g.isStrictlyMajorityConsensusReached = false;

        // collect idAddress of members in group
        address[] memory membersLeftInGroup = new address[](g.members.length);
        for (uint256 i = 0; i < g.members.length; i++) {
            membersLeftInGroup[i] = g.members[i].nodeIdAddress;
        }
        uint256[] memory involvedGroups = new uint256[](groupData.groupCount); // max number of groups involved is groupCount
        uint256 currentIndex;

        // for each membersLeftInGroup, call findOrCreateTargetGroup and then add that member to the new group.
        for (uint256 i = 0; i < membersLeftInGroup.length; i++) {
            // find a suitable group for the member
            (uint256 targetGroupIndex,) = findOrCreateTargetGroup(groupData);

            // if the current group index is selected, break
            if (groupIndex == targetGroupIndex) {
                break;
            }

            // add member to target group
            addToGroup(groupData, membersLeftInGroup[i], targetGroupIndex);

            if (groupData.groups[i].size >= DEFAULT_MINIMUM_THRESHOLD) {
                involvedGroups[currentIndex] = targetGroupIndex;
                currentIndex++;
            }
        }

        return Utils.trimTrailingElements(involvedGroups, currentIndex);
    }

    function tryRebalanceGroup(GroupData storage groupData, uint256 groupIndex, uint256 lastOutput)
        internal
        returns (bool rebalanceSuccess, uint256 groupIndexToRebalance)
    {
        // get all group indices excluding the current groupIndex
        uint256[] memory groupIndices = new uint256[](groupData.groupCount -1);
        uint256 index = 0;
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            if (i != groupIndex) {
                groupIndices[index] = i;
                index++;
            }
        }

        // try to reblance each group, if succesful, return true
        for (uint256 i = 0; i < groupIndices.length; i++) {
            if (rebalanceGroup(groupData, groupIndices[i], groupIndex, lastOutput)) {
                return (true, groupIndices[i]);
            }
        }
    }

    function rebalanceGroup(GroupData storage groupData, uint256 groupAIndex, uint256 groupBIndex, uint256 lastOutput)
        internal
        returns (bool)
    {
        IController.Group memory groupA = groupData.groups[groupAIndex];
        IController.Group memory groupB = groupData.groups[groupBIndex];

        if (groupB.size > groupA.size) {
            (groupA, groupB) = (groupB, groupA);
            (groupAIndex, groupBIndex) = (groupBIndex, groupAIndex);
        }

        uint256 expectedSizeToMove = groupA.size - (groupA.size + groupB.size) / 2;
        if (expectedSizeToMove == 0 || groupA.size - expectedSizeToMove < DEFAULT_MINIMUM_THRESHOLD) {
            return false;
        }

        // Move members from group A to group B
        for (uint256 i = 0; i < expectedSizeToMove; i++) {
            uint256 memberIndex = Utils.pickRandomIndex(lastOutput, groupA.members.length - i);
            address memberAddress = getMemberAddressByIndex(groupData, groupAIndex, memberIndex);
            removeFromGroup(groupData, memberIndex, groupAIndex);
            addToGroup(groupData, memberAddress, groupBIndex);
        }

        emit GroupRebalanced(groupAIndex, groupBIndex);

        return true;
    }

    function findOrCreateTargetGroup(GroupData storage groupData)
        internal
        returns (uint256 groupIndex, bool needsRebalance)
    {
        // if group is empty, addgroup.
        if (groupData.groupCount == 0) {
            return (addGroup(groupData), false);
        }

        // get the group index of the group with the minimum size, as well as the min size
        uint256 indexOfMinSize;
        uint256 minSize = groupData.groupMaxCapacity;
        for (uint256 i = 0; i < groupData.groupCount; i++) {
            IController.Group memory g = groupData.groups[i];
            if (g.size < minSize) {
                minSize = g.size;
                indexOfMinSize = i;
            }
        }

        // compute the valid group count
        uint256 validGroupCount = getValidGroupIndices(groupData).length;

        // check if valid group count < ideal_number_of_groups || minSize == group_max_capacity
        // If either condition is met and the number of valid groups == group count, call add group and return (index of new group, true)
        if (
            (validGroupCount < groupData.idealNumberOfGroups && validGroupCount == groupData.groupCount)
                || (minSize == groupData.groupMaxCapacity)
        ) return (addGroup(groupData), true);

        // if none of the above conditions are met:
        return (indexOfMinSize, false);
    }

    function addGroup(GroupData storage groupData) internal returns (uint256) {
        uint256 groupIndex = groupData.groupCount; // groupIndex starts at 0. groupCount is index of next group to be added
        groupData.groupCount++;

        IController.Group storage g = groupData.groups[groupIndex];
        g.index = groupIndex;
        g.size = 0;
        g.threshold = DEFAULT_MINIMUM_THRESHOLD;

        return groupIndex;
    }

    function addToGroup(GroupData storage groupData, address idAddress, uint256 groupIndex)
        internal
        returns (bool needEmitGroupEvent)
    {
        // Get group from group index
        IController.Group storage g = groupData.groups[groupIndex];

        // Add Member Struct to group at group index
        IController.Member memory m;
        m.nodeIdAddress = idAddress;

        // insert (node id address - > member) into group.members
        g.members.push(m);
        g.size++;

        // assign group threshold
        uint256 minimum = Utils.minimumThreshold(g.size); // 51% of group size
        // max of 51% of group size and DEFAULT_MINIMUM_THRESHOLD
        g.threshold = minimum > DEFAULT_MINIMUM_THRESHOLD ? minimum : DEFAULT_MINIMUM_THRESHOLD;

        if (g.size >= 3) {
            return true;
        }
    }

    function removeFromGroup(GroupData storage groupData, uint256 memberIndex, uint256 groupIndex)
        public
        returns (bool needRebalance, bool needEmitGroupEvent)
    {
        IController.Group storage g = groupData.groups[groupIndex];
        g.size--;

        if (g.size == 0) {
            delete g.members;
            g.threshold = 0;
            return (false, false);
        }

        // Remove node from members
        g.members[memberIndex] = g.members[g.members.length - 1];
        g.members.pop();

        uint256 minimum = Utils.minimumThreshold(g.size);
        g.threshold = minimum > DEFAULT_MINIMUM_THRESHOLD ? minimum : DEFAULT_MINIMUM_THRESHOLD;

        if (g.size < 3) {
            return (true, false);
        }

        return (false, true);
    }

    // Get array of majority members with identical commit result. Return commit cache. if no majority, return empty commit cache.
    function getStrictlyMajorityIdenticalCommitmentResult(GroupData storage groupData, uint256 groupIndex)
        internal
        view
        returns (IController.CommitCache memory)
    {
        IController.CommitCache memory emptyCache;

        // If there are no commit caches, return empty commit cache.
        IController.Group memory g = groupData.groups[groupIndex];
        if (g.commitCacheList.length == 0) {
            return (emptyCache);
        }

        // If there is only one commit cache, return it.
        if (g.commitCacheList.length == 1) {
            return (g.commitCacheList[0]);
        }

        // If there are multiple commit caches, check if there is a majority.
        bool isStrictlyMajorityExist = true;
        IController.CommitCache memory majorityCommitCache = g.commitCacheList[0];
        for (uint256 i = 1; i < g.commitCacheList.length; i++) {
            IController.CommitCache memory commitCache = g.commitCacheList[i];
            if (commitCache.nodeIdAddress.length > majorityCommitCache.nodeIdAddress.length) {
                isStrictlyMajorityExist = true;
                majorityCommitCache = commitCache;
            } else if (commitCache.nodeIdAddress.length == majorityCommitCache.nodeIdAddress.length) {
                isStrictlyMajorityExist = false;
            }
        }

        // If no majority, return empty commit cache.
        if (!isStrictlyMajorityExist) {
            return (emptyCache);
        }
        // If majority, return majority commit cache
        return (majorityCommitCache);
    }

    function getMemberAddressByIndex(GroupData storage groupData, uint256 groupIndex, uint256 memberIndex)
        internal
        view
        returns (address nodeIdAddress)
    {
        IController.Group memory g = groupData.groups[groupIndex];
        return g.members[memberIndex].nodeIdAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Coordinator is Ownable {
    /// Mapping of Ethereum Address => DKG public keys
    mapping(address => bytes) public keys;

    /// Mapping of Ethereum Address => DKG Phase 1 Shares
    mapping(address => bytes) public shares;

    /// Mapping of Ethereum Address => DKG Phase 2 Responses
    mapping(address => bytes) public responses;

    /// Mapping of Ethereum Address => DKG Phase 3 Justifications
    mapping(address => bytes) public justifications;

    // List of registered Ethereum keys (used for conveniently fetching data)
    address[] public participants;

    /// The duration of each phase
    uint256 public immutable phaseDuration;

    /// The dkgThreshold of the DKG
    uint256 public immutable dkgThreshold;

    /// If it's 0 then the DKG is still pending start. If >0, it is the DKG's start block
    uint256 public startBlock = 0;

    /// A group member is one whose pubkey's length > 0
    modifier onlyGroupMember() {
        require(keys[msg.sender].length > 0, "you are not a group member!");
        _;
    }

    /// The DKG starts when startBlock > 0
    modifier onlyWhenNotStarted() {
        require(startBlock == 0, "DKG has already started");
        _;
    }

    constructor(uint256 threshold, uint256 duration) {
        dkgThreshold = threshold;
        phaseDuration = duration;
    }

    function initialize(address[] calldata nodes, bytes[] calldata publicKeys) external onlyWhenNotStarted onlyOwner {
        for (uint256 i = 0; i < nodes.length; i++) {
            participants.push(nodes[i]);
            keys[nodes[i]] = publicKeys[i];
        }

        startBlock = block.number;
    }

    /// Participant publishes their data and depending on the phase the data gets inserted
    /// in the shares, responses or justifications mapping. Reverts if the participant
    /// has already published their data for a phase or if the DKG has ended.
    function publish(bytes calldata value) external onlyGroupMember {
        uint256 blocksSinceStart = block.number - startBlock;

        if (blocksSinceStart <= phaseDuration) {
            require(shares[msg.sender].length == 0, "share existed");
            shares[msg.sender] = value;
        } else if (blocksSinceStart <= 2 * phaseDuration) {
            require(responses[msg.sender].length == 0, "response existed");
            responses[msg.sender] = value;
        } else if (blocksSinceStart <= 3 * phaseDuration) {
            require(justifications[msg.sender].length == 0, "justification existed");
            justifications[msg.sender] = value;
        } else {
            revert("DKG Publish has ended");
        }
    }

    // Helpers to fetch data in the mappings. If a participant has registered but not
    // published their data for a phase, the array element at their index is expected to be 0

    /// Gets the participants' shares
    function getShares() external view returns (bytes[] memory) {
        bytes[] memory _shares = new bytes[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            _shares[i] = shares[participants[i]];
        }

        return _shares;
    }

    /// Gets the participants' responses
    function getResponses() external view returns (bytes[] memory) {
        bytes[] memory _responses = new bytes[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            _responses[i] = responses[participants[i]];
        }

        return _responses;
    }

    /// Gets the participants' justifications
    function getJustifications() external view returns (bytes[] memory) {
        bytes[] memory _justifications = new bytes[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            _justifications[i] = justifications[participants[i]];
        }

        return _justifications;
    }

    /// Gets the participants' ethereum addresses
    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    /// Gets the participants' DKG keys along with the thershold of the DKG
    function getDkgKeys() external view returns (uint256, bytes[] memory) {
        bytes[] memory _keys = new bytes[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            _keys[i] = keys[participants[i]];
        }

        return (dkgThreshold, _keys);
    }

    /// Returns the current phase of the DKG.
    function inPhase() public view returns (int8) {
        // Phase 0 for after deployment before initialization.
        if (startBlock == 0) {
            return 0;
        }

        uint256 blocksSinceStart = block.number - startBlock;

        if (blocksSinceStart <= phaseDuration) {
            return 1; // share
        }

        if (blocksSinceStart <= 2 * phaseDuration) {
            return 2; // response
        }

        if (blocksSinceStart <= 3 * phaseDuration) {
            return 3; // justification
        }
        if (blocksSinceStart <= 4 * phaseDuration) {
            return 4; // Commit DKG: Handled in controller
        }

        // DKG Ended, commit_dkg should be called before this
        return -1;
    }

    function selfDestruct() external onlyOwner {
        selfdestruct(payable(owner()));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IRequestTypeBase {
    enum RequestType {
        Randomness,
        RandomWords,
        Shuffling
    }
}

// SPDX-License-Identifier: LGPL 3.0
pragma solidity ^0.8.15;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author ARPA-Network adapted from https://github.com/musalbas/solidity-BN256G2
 * @dev Homepage: https://github.com/ARPA-Network/BLS-TSS-Network
 */

library BN256G2 {
    uint256 public constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 public constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 public constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint256 public constant PTXX = 0;
    uint256 public constant PTXY = 1;
    uint256 public constant PTYX = 2;
    uint256 public constant PTYY = 3;
    uint256 public constant PTZX = 4;
    uint256 public constant PTZY = 5;

    function ecTwistAdd(uint256[4] memory pt1, uint256[4] memory pt2) internal view returns (uint256[4] memory pt) {
        (uint256 xx, uint256 xy, uint256 yx, uint256 yy) =
            ecTwistAdd(pt1[0], pt1[1], pt1[2], pt1[3], pt2[0], pt2[1], pt2[2], pt2[3]);
        pt = [xx, xy, yx, yy];
    }

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    ) internal view returns (uint256, uint256, uint256, uint256) {
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            if (!(pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0)) {
                assert(isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));
            }
            return (pt2xx, pt2xy, pt2yx, pt2yy);
        } else if (pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0) {
            assert(isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
            return (pt1xx, pt1xy, pt1yx, pt1yy);
        }

        assert(isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
        assert(isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));

        uint256[6] memory pt1 = [pt1xx, pt1xy, pt1yx, pt1yy, 1, 0];
        uint256[6] memory pt2 = [pt2xx, pt2xy, pt2yx, pt2yy, 1, 0];
        uint256[6] memory pt3 = ecTwistAddJacobian(pt1, pt2);

        return fromJacobian(pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]);
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function fq2Mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function fq2Muc(uint256 xx, uint256 xy, uint256 c) internal pure returns (uint256, uint256) {
        return (mulmod(xx, c, FIELD_MODULUS), mulmod(xy, c, FIELD_MODULUS));
    }

    function fq2Add(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (addmod(xx, yx, FIELD_MODULUS), addmod(xy, yy, FIELD_MODULUS));
    }

    function fq2Sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256 rx, uint256 ry) {
        return (submod(xx, yx, FIELD_MODULUS), submod(xy, yy, FIELD_MODULUS));
    }

    function fq2Div(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal view returns (uint256, uint256) {
        (yx, yy) = fq2Inv(yx, yy);
        return fq2Mul(xx, xy, yx, yy);
    }

    function fq2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv =
            modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (mulmod(x, inv, FIELD_MODULUS), FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS));
    }

    function isOnCurve(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = fq2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = fq2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = fq2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = fq2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = fq2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), a)
            mstore(add(freemem, 0x80), sub(n, 2))
            mstore(add(freemem, 0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        // solhint-disable-next-line reason-string
        require(success);
    }

    function fromJacobian(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy)
        internal
        view
        returns (uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy)
    {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = fq2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = fq2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = fq2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function ecTwistAddJacobian(uint256[6] memory pt1, uint256[6] memory pt2)
        public
        pure
        returns (uint256[6] memory pt3)
    {
        if (pt1[4] == 0 && pt1[5] == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                (pt2[0], pt2[1], pt2[2], pt2[3], pt2[4], pt2[5]);
            return pt3;
        } else if (pt2[4] == 0 && pt2[5] == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                (pt1[0], pt1[1], pt1[2], pt1[3], pt1[4], pt1[5]);
            return pt3;
        }

        (pt2[2], pt2[3]) = fq2Mul(pt2[2], pt2[3], pt1[4], pt1[5]); // U1 = y2 * z1
        (pt3[PTYX], pt3[PTYY]) = fq2Mul(pt1[2], pt1[3], pt2[4], pt2[5]); // U2 = y1 * z2
        (pt2[0], pt2[1]) = fq2Mul(pt2[0], pt2[1], pt1[4], pt1[5]); // V1 = x2 * z1
        (pt3[PTZX], pt3[PTZY]) = fq2Mul(pt1[0], pt1[1], pt2[4], pt2[5]); // V2 = x1 * z2

        if (pt2[0] == pt3[PTZX] && pt2[1] == pt3[PTZY]) {
            if (pt2[2] == pt3[PTYX] && pt2[3] == pt3[PTYY]) {
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) =
                    ecTwistDoubleJacobian(pt1[0], pt1[1], pt1[2], pt1[3], pt1[4], pt1[5]);
                return pt3;
            }
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (1, 0, 1, 0, 0, 0);
            return pt3;
        }

        (pt2[4], pt2[5]) = fq2Mul(pt1[4], pt1[5], pt2[4], pt2[5]); // W = z1 * z2
        (pt1[0], pt1[1]) = fq2Sub(pt2[2], pt2[3], pt3[PTYX], pt3[PTYY]); // U = U1 - U2
        (pt1[2], pt1[3]) = fq2Sub(pt2[0], pt2[1], pt3[PTZX], pt3[PTZY]); // V = V1 - V2
        (pt1[4], pt1[5]) = fq2Mul(pt1[2], pt1[3], pt1[2], pt1[3]); // V_squared = V * V
        (pt2[2], pt2[3]) = fq2Mul(pt1[4], pt1[5], pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
        (pt1[4], pt1[5]) = fq2Mul(pt1[4], pt1[5], pt1[2], pt1[3]); // V_cubed = V * V_squared
        (pt3[PTZX], pt3[PTZY]) = fq2Mul(pt1[4], pt1[5], pt2[4], pt2[5]); // newz = V_cubed * W
        (pt2[0], pt2[1]) = fq2Mul(pt1[0], pt1[1], pt1[0], pt1[1]); // U * U
        (pt2[0], pt2[1]) = fq2Mul(pt2[0], pt2[1], pt2[4], pt2[5]); // U * U * W
        (pt2[0], pt2[1]) = fq2Sub(pt2[0], pt2[1], pt1[4], pt1[5]); // U * U * W - V_cubed
        (pt2[4], pt2[5]) = fq2Muc(pt2[2], pt2[3], 2); // 2 * V_squared_times_V2
        (pt2[0], pt2[1]) = fq2Sub(pt2[0], pt2[1], pt2[4], pt2[5]); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
        (pt3[PTXX], pt3[PTXY]) = fq2Mul(pt1[2], pt1[3], pt2[0], pt2[1]); // newx = V * A
        (pt1[2], pt1[3]) = fq2Sub(pt2[2], pt2[3], pt2[0], pt2[1]); // V_squared_times_V2 - A
        (pt1[2], pt1[3]) = fq2Mul(pt1[0], pt1[1], pt1[2], pt1[3]); // U * (V_squared_times_V2 - A)
        (pt1[0], pt1[1]) = fq2Mul(pt1[4], pt1[5], pt3[PTYX], pt3[PTYY]); // V_cubed * U2
        (pt3[PTYX], pt3[PTYY]) = fq2Sub(pt1[2], pt1[3], pt1[0], pt1[1]); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function ecTwistDoubleJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) public pure returns (uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        (pt2xx, pt2xy) = fq2Muc(pt1xx, pt1xy, 3); // 3 * x
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = fq2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = fq2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = fq2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = fq2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = fq2Muc(pt2yx, pt2yy, 8); // 8 * B
        (pt1xx, pt1xy) = fq2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = fq2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = fq2Muc(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = fq2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = fq2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = fq2Muc(pt1yx, pt1yy, 8); // 8 * y
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = fq2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = fq2Muc(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = fq2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = fq2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = fq2Muc(pt2zx, pt2zy, 8); // newz = 8 * S * S_squared
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
// and some arithmetic operations.
uint256 constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

function containElement(uint256[] memory arr, uint256 element) pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == element) {
            return true;
        }
    }
    return false;
}

function containElement(address[] memory arr, address element) pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == element) {
            return true;
        }
    }
    return false;
}

/**
 * @dev returns the minimum threshold for a group of size groupSize
 */
function minimumThreshold(uint256 groupSize) pure returns (uint256) {
    return groupSize / 2 + 1;
}

/**
 * @dev choose one random index from an array.
 */
function pickRandomIndex(uint256 seed, uint256 length) pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed))) % length;
}

/**
 * @dev choose "count" random indices from "indices" array.
 */
function pickRandomIndex(uint256 seed, uint256[] memory indices, uint256 count) pure returns (uint256[] memory) {
    uint256[] memory chosenIndices = new uint256[](count);

    // Create copy of indices to avoid modifying original array.
    uint256[] memory remainingIndices = new uint256[](indices.length);
    for (uint256 i = 0; i < indices.length; i++) {
        remainingIndices[i] = indices[i];
    }

    uint256 remainingCount = remainingIndices.length;
    for (uint256 i = 0; i < count; i++) {
        uint256 index = uint256(keccak256(abi.encodePacked(seed, i))) % remainingCount;
        chosenIndices[i] = remainingIndices[index];
        remainingIndices[index] = remainingIndices[remainingCount - 1];
        remainingCount--;
    }
    return chosenIndices;
}

/**
 * @dev iterates through list of members and remove disqualified nodes.
 */
function getNonDisqualifiedMajorityMembers(address[] memory nodeAddresses, address[] memory disqualifiedNodes)
    pure
    returns (address[] memory)
{
    address[] memory majorityMembers = new address[](nodeAddresses.length);
    uint256 majorityMembersLength = 0;
    for (uint256 i = 0; i < nodeAddresses.length; i++) {
        if (!containElement(disqualifiedNodes, nodeAddresses[i])) {
            majorityMembers[majorityMembersLength] = nodeAddresses[i];
            majorityMembersLength++;
        }
    }

    // remove trailing zero addresses
    return trimTrailingElements(majorityMembers, majorityMembersLength);
}

function trimTrailingElements(uint256[] memory arr, uint256 newLength) pure returns (uint256[] memory) {
    uint256[] memory output = new uint256[](newLength);
    for (uint256 i = 0; i < newLength; i++) {
        output[i] = arr[i];
    }
    return output;
}

function trimTrailingElements(address[] memory arr, uint256 newLength) pure returns (address[] memory) {
    address[] memory output = new address[](newLength);
    for (uint256 i = 0; i < newLength; i++) {
        output[i] = arr[i];
    }
    return output;
}

/**
 * @dev calls target address with exactly gasAmount gas and data as calldata
 * or reverts if at least gasAmount gas is not available.
 */
function callWithExactGas(uint256 gasAmount, address target, bytes memory data) returns (bool success) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        let g := gas()
        // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
        // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
        // We want to ensure that we revert if gasAmount >  63//64*gas available
        // as we do not want to provide them with less, however that check itself costs
        // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
        // to revert if gasAmount >  63//64*gas available.
        if lt(g, GAS_FOR_CALL_EXACT_CHECK) { revert(0, 0) }
        g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
        // if g - g//64 <= gasAmount, revert
        // (we subtract g//64 because of EIP-150)
        if iszero(gt(sub(g, div(g, 64)), gasAmount)) { revert(0, 0) }
        // solidity calls check that a contract actually exists at the destination, so we do the same
        if iszero(extcodesize(target)) { revert(0, 0) }
        // call and return whether we succeeded. ignore return data
        // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
        success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
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