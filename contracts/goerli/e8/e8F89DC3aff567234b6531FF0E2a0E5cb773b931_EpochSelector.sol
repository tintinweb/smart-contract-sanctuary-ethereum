// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IEpochSelector.sol";
import "./ClusterSelector_wih_abi_encode.sol";

/// @title Contract to select the top 5 clusters in an epoch
contract EpochSelector is AccessControl, ClusterSelector, IEpochSelector {
    using SafeERC20 for IERC20;

    /// @notice Event emitted when Cluster is selected
    /// @param epoch Number of Epoch
    /// @param cluster Address of cluster
    event ClusterSelected(uint256 indexed epoch, address indexed cluster);

    /// @notice Event emited when the number of clusters to select is updated
    /// @param newNumberOfClusters New number of clusters selected
    event UpdateNumberOfClustersToSelect(uint256 newNumberOfClusters);

    /// @notice Event emited when the reward is updated
    /// @param newReward New Reward For selecting the tokens
    event UpdateRewardForSelectingTheNodes(uint256 newReward);

    /// @notice Event emited when the reward token is emitted
    /// @param _newRewardToken Address of the new reward token
    event UpdateRewardToken(address _newRewardToken);

    /// @notice length of epoch
    uint256 public constant EPOCH_LENGTH = 4 hours;

    /// @notice timestamp when the selector starts
    uint256 public immutable START_TIME;

    /// @notice Number of clusters selected in every epoch
    uint256 public numberOfClustersToSelect;

    /// @notice clusters selected during each epoch
    mapping(uint256 => address[]) private clustersSelected;

    /// @notice ID for update role
    bytes32 public constant UPDATER_ROLE = keccak256(abi.encode("updater"));

    /// @notice ID for admin role
    bytes32 public constant ADMIN_ROLE = keccak256(abi.encode("admin"));

    /// @notice ID for reward control
    bytes32 public constant REWARD_CONTROLLER_ROLE = keccak256(abi.encode("reward-control"));

    /// @notice Reward that the msg.sender recevies when cluster are selected for the epoch;
    uint256 public rewardForSelectingClusters;

    /// @notice Reward Token
    address public rewardToken;

    constructor(
        address _admin,
        uint256 _numberOfClustersToSelect,
        uint256 _startTime,
        address _rewardToken,
        uint256 _rewardForSelectingClusters
    ) ClusterSelector() {
        START_TIME = _startTime;
        numberOfClustersToSelect = _numberOfClustersToSelect;

        AccessControl._setRoleAdmin(UPDATER_ROLE, ADMIN_ROLE);
        AccessControl._setRoleAdmin(REWARD_CONTROLLER_ROLE, ADMIN_ROLE);

        AccessControl._grantRole(ADMIN_ROLE, _admin);
        AccessControl._grantRole(REWARD_CONTROLLER_ROLE, _admin);

        rewardToken = _rewardToken;
        rewardForSelectingClusters = _rewardForSelectingClusters;
    }

    /// @notice Current Epoch
    function getCurrentEpoch() public view override returns (uint256) {
        return (block.timestamp - START_TIME) / EPOCH_LENGTH;
    }

    /// @notice Returns the list of selected clusters for the next
    /// @return List of the clusters selected
    function selectClusters() public override returns (address[] memory) {
        uint256 nextEpoch = getCurrentEpoch() + 1;
        address[] memory nodes = clustersSelected[nextEpoch];

        if (nodes.length == 0) {
            // select and save from the tree
            uint32 blockHash = uint32(uint256(blockhash(block.number - 1)));
            // console2.log("blockhash of", block.number - 1, blockHash);
            clustersSelected[nextEpoch] = selectTopNClusters(blockHash, numberOfClustersToSelect);
            nodes = clustersSelected[nextEpoch];
            for (uint256 index = 0; index < nodes.length; index++) {
                emit ClusterSelected(nextEpoch, nodes[index]);
            }

            _dispenseReward(msg.sender);
        }

        return nodes;
    }

    /// @notice Updates the missing cluster in case epoch was not selected by anyone
    /// @notice The group of selected clusters will be selected again
    /// @param anyPreviousEpochNumber Epoch Number to fix the missing clusters
    function updateMissingClusters(uint256 anyPreviousEpochNumber) public returns (address[] memory previousSelectedClusters) {
        uint256 currentEpoch = getCurrentEpoch();
        require(anyPreviousEpochNumber < currentEpoch, "Can't update current or more epochs");
        return _updateMissingClusters(anyPreviousEpochNumber);
    }

    /// @notice Internal function to Update the missing cluster in case epoch
    /// @param anyPreviousEpochNumber Epoch Number to fix the missing clusters
    function _updateMissingClusters(uint256 anyPreviousEpochNumber) internal returns (address[] memory previousSelectedClusters) {
        if (anyPreviousEpochNumber == 0) {
            return previousSelectedClusters;
        }

        address[] memory clusters = clustersSelected[anyPreviousEpochNumber];
        if (clusters.length == 0) {
            clusters = _updateMissingClusters(anyPreviousEpochNumber - 1);
            clustersSelected[anyPreviousEpochNumber] = clusters;
        } else {
            return clusters;
        }
    }

    /// @inheritdoc IClusterSelector
    function insert(address newNode, uint32 balance) public override(IClusterSelector, SingleSelector) onlyRole(UPDATER_ROLE) {
        require(newNode != address(0), ClusterLib.CANNOT_BE_ADDRESS_ZERO);
        uint32 nodeIndex = addressToIndexMap[newNode];
        Node memory node = nodes[nodeIndex];

        if (node.node == 0) {
            uint32 newIndex = getNewId();
            root = _insert(root, newIndex, balance);
            totalElements++;
            indexToAddressMap[newIndex] = newNode;
            addressToIndexMap[newNode] = newIndex;
        } else {
            // int256 differenceInKeyBalance = int256(clusterBalance) - int256(node.balance);
            _update(root, nodeIndex, int32(balance) - int32(node.balance));
        }
    }

    /// @inheritdoc IClusterSelector
    function insertMultiple(address[] calldata newNodes, uint32[] calldata balances)
        public
        override(IClusterSelector, SingleSelector)
        onlyRole(UPDATER_ROLE)
    {
        require(newNodes.length == balances.length, "arity mismatch");
        for (uint256 index = 0; index < newNodes.length; index++) {
            insert(newNodes[index], balances[index]);
        }
    }

    /// @inheritdoc IClusterSelector
    function deleteNode(address key) public override(IClusterSelector, SingleSelector) onlyRole(UPDATER_ROLE) {
        require(deleteNodeIfPresent(key), ClusterLib.NODE_NOT_PRESENT_IN_THE_TREE);
    }

    /// @inheritdoc IEpochSelector
    function deleteNodeIfPresent(address key) public override onlyRole(UPDATER_ROLE) returns (bool) {
        require(key != address(0), ClusterLib.CANNOT_BE_ADDRESS_ZERO);
        uint32 indexKey = addressToIndexMap[key];

        Node memory node = nodes[indexKey];
        if (node.node == indexKey) {
            // delete node
            root = _deleteNode(root, indexKey, node.balance);
            totalElements--;
            delete indexToAddressMap[indexKey];
            delete addressToIndexMap[key];
            emptyIds.push(indexKey);
            return true;
        }
        return false;
    }

    /// @inheritdoc IClusterSelector
    function update(address existingNode, uint32 newBalance) public override(IClusterSelector, SingleSelector) onlyRole(UPDATER_ROLE) {
        uint32 indexKey = addressToIndexMap[existingNode];

        require(indexKey != 0, ClusterLib.CANNOT_BE_ADDRESS_ZERO);
        if (nodes[indexKey].node == 0) {
            assert(false);
        } else {
            int32 differenceInKeyBalance = int32(newBalance) - int32(nodes[indexKey].balance);
            _update(root, indexKey, differenceInKeyBalance);
        }
    }

    /// @inheritdoc IEpochSelector
    function updateNumberOfClustersToSelect(uint256 _numberOfClusters) external override onlyRole(ADMIN_ROLE) {
        require(_numberOfClusters != 0 && numberOfClustersToSelect != _numberOfClusters, "Should be a valid number");
        numberOfClustersToSelect = _numberOfClusters;
        emit UpdateNumberOfClustersToSelect(_numberOfClusters);
    }

    /// @notice Updates the reward token
    /// @param _rewardToken Address of the reward token
    function updateRewardToken(address _rewardToken) external onlyRole(REWARD_CONTROLLER_ROLE) {
        require(_rewardToken == rewardToken, "Update reward token");
        rewardToken = _rewardToken;
        emit UpdateRewardToken(_rewardToken);
    }

    function _dispenseReward(address _to) internal {
        if (rewardForSelectingClusters != 0) {
            IERC20 _rewardToken = IERC20(rewardToken);
            if (_rewardToken.balanceOf(address(this)) >= rewardForSelectingClusters) {
                _rewardToken.safeTransfer(_to, rewardForSelectingClusters);
            }
        }
    }

    function flushTokens(address token, address to) external onlyRole(REWARD_CONTROLLER_ROLE) {
        IERC20 _token = IERC20(token);

        uint256 remaining = _token.balanceOf(address(this));
        if (remaining > 0) {
            _token.safeTransfer(to, remaining);
        }
    }

    function getClusters(uint256 epochNumber) public view returns (address[] memory) {
        if (epochNumber == 0) {
            return new address[](0);
        }
        address[] memory clusters = clustersSelected[epochNumber];

        if (clusters.length == 0) {
            return getClusters(epochNumber - 1);
        } else {
            return clusters;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "./IClusterSelector.sol";

interface IEpochSelector is IClusterSelector {
    function getCurrentEpoch() external view returns (uint256);

    function selectClusters() external returns (address[] memory nodes);

    /// @notice Delete a node from tree if it is stored
    /// @param key Address of the node
    function deleteNodeIfPresent(address key) external returns (bool);

    /// @notice Update the number of clusters to select
    /// @param numberOfClusters New number of clusters to select
    function updateNumberOfClustersToSelect(uint256 numberOfClusters) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClusterSelectorHelper/SimpleSelector.sol";

contract ClusterSelector is SingleSelector {
    using ClusterLib for uint32[];
    using ClusterLib for address[];
    using ClusterLib for bytes;

    constructor() SingleSelector() {}

    /// @notice Select top N clusters
    /// @return List of addresses selected
    function selectTopNClusters(uint32 randomizer, uint256 N) public view returns (address[] memory) {
        require(N <= totalElements, ClusterLib.INSUFFICIENT_ELEMENTS_IN_TREE);

        uint32[] memory selectedNodes = new uint32[](N);
        uint32[] memory balancesOfSelectedNodes = new uint32[](N);
        uint32[17][] memory pathToSelectedNodes = new uint32[17][](N);
        uint256[] memory pidxs = new uint256[](N);

        Node memory _root = nodes[root];
        uint32 totalWeightInTree = _getTotalBalancesIncludingWeight(_root);
        uint32 _sumOfBalancesOfSelectedNodes;

        for (uint256 index = 0; index < N; index++) {
            randomizer = uint32(uint256(keccak256(abi.encode(randomizer, index))));
            uint32 searchNumber = randomizer % (totalWeightInTree - _sumOfBalancesOfSelectedNodes);

            (uint32 _node, uint32 _selectedNodeBalance) = _selectTopCluster(
                root,
                searchNumber,
                selectedNodes,
                balancesOfSelectedNodes,
                pathToSelectedNodes,
                pidxs,
                index
            );

            selectedNodes[index] = _node;
            balancesOfSelectedNodes[index] = _selectedNodeBalance;
            _sumOfBalancesOfSelectedNodes += _selectedNodeBalance;
        }

        address[] memory sn = new address[](N);
        for (uint256 index = 0; index < N; index++) {
            sn[index] = indexToAddressMap[selectedNodes[index]];
        }
        return sn;
    }

    /// @notice Select top N Clusters
    /// @param _root Address of the current node (which is referred as root here)
    /// @param searchNumber a random number used to navigate the tree
    /// @param selectedNodes List of already selected nodes. This node have to ignored while traversing the tree
    /// @param pathsToSelectedNodes Paths to the selected nodes.
    /// @return Address of the selected node
    /// @return Balance of selected node
    function _selectTopCluster(
        uint32 _root,
        uint32 searchNumber,
        uint32[] memory selectedNodes,
        uint32[] memory balancesOfSelectedNodes,
        uint32[17][] memory pathsToSelectedNodes,
        uint256[] memory pidxs,
        uint256 index
    ) internal view returns (uint32, uint32) {
        Node memory node = nodes[_root];
        // stored in existing variable to conserve memory
        (node.sumOfLeftBalances, node.sumOfRightBalances) = _getModifiedWeights(
            node,
            balancesOfSelectedNodes,
            pathsToSelectedNodes,
            pidxs,
            index
        );
        // if the node is already selected, movie either to left or right
        if (selectedNodes.ifArrayHasElement(_root)) {
            (uint32 index1, , uint32 index2) = ClusterLib._getIndexesWithWeights(node.sumOfLeftBalances, 0, node.sumOfRightBalances);

            pathsToSelectedNodes[index][pidxs[index]] = _root;
            pidxs[index]++;

            if (searchNumber <= index1) {
                return
                    _selectTopCluster(node.left, searchNumber, selectedNodes, balancesOfSelectedNodes, pathsToSelectedNodes, pidxs, index);
            } else if (searchNumber > index1 && searchNumber <= index2) {
                return
                    _selectTopCluster(
                        node.right,
                        searchNumber - index1,
                        selectedNodes,
                        balancesOfSelectedNodes,
                        pathsToSelectedNodes,
                        pidxs,
                        index
                    );
            } else {
                revert(ClusterLib.ERROR_OCCURED_DURING_TRAVERSING_SELECTED_NODE);
            }
        }
        // if not selected then, check if it lies between the indexes
        else {
            // console2.log("_root is not selected", _root);
            // console2.log("searchNumber", searchNumber);
            // _printArray("selected nodes this _root", selectedNodes);
            (uint32 index1, uint32 index2, uint32 index3) = ClusterLib._getIndexesWithWeights(
                node.sumOfLeftBalances,
                node.balance,
                node.sumOfRightBalances
            );

            pathsToSelectedNodes[index][pidxs[index]] = _root;
            pidxs[index]++;

            if (searchNumber <= index1) {
                return
                    _selectTopCluster(node.left, searchNumber, selectedNodes, balancesOfSelectedNodes, pathsToSelectedNodes, pidxs, index);
            } else if (searchNumber > index1 && searchNumber <= index2) {
                return (_root, node.balance);
            } else if (searchNumber > index2 && searchNumber <= index3) {
                return
                    _selectTopCluster(
                        node.right,
                        searchNumber - index2,
                        selectedNodes,
                        balancesOfSelectedNodes,
                        pathsToSelectedNodes,
                        pidxs,
                        index
                    );
            } else {
                revert(ClusterLib.ERROR_OCCURED_DURING_TRAVERSING_NON_SELECTED_NODE);
            }
        }
    }

    /// @notice When a node is selected, the left and right weights have to be reduced in memory
    /// @param node Node to reduce the weights
    /// @param balancesOfSelectedNodes balance of selected nodes
    /// @param pathsToSelectedNodes Paths to the selected nodes
    /// @return leftWeight reduced left weight of the node
    /// @return rightWeight reduced right weight of the node
    function _getModifiedWeights(
        Node memory node,
        uint32[] memory balancesOfSelectedNodes,
        uint32[17][] memory pathsToSelectedNodes,
        uint256[] memory pidxs,
        uint256 _index
    ) internal pure returns (uint32 leftWeight, uint32 rightWeight) {
        leftWeight = node.sumOfLeftBalances;
        rightWeight = node.sumOfRightBalances;

        for (uint256 index = 0; index < _index; index++) {
            uint32[17] memory _pathsToSelectedNodes = pathsToSelectedNodes[index];

            for (uint256 _idx = 0; _idx < pidxs[index]; _idx++) {
                if (_pathsToSelectedNodes[_idx] == node.left) {
                    leftWeight -= balancesOfSelectedNodes[index];
                    break;
                } else if (_pathsToSelectedNodes[_idx] == node.right) {
                    rightWeight -= balancesOfSelectedNodes[index];
                    break;
                }
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

interface IClusterSelector {
    /// @notice Address of the node
    /// @param node Address of the node
    /// @param balance Balance of the node
    /// @param left Address of the node left of node
    /// @param right Address of the node right of the node
    /// @param sumOfLeftBalances Sum of the balance of nodes on left of the node
    /// @param sumOfRightBalances Sum of the balance of the nodes of right of the node
    /// @param height Height of the current node
    struct Node {
        uint32 node; // sorting condition
        uint32 balance;
        uint32 left;
        uint32 sumOfLeftBalances;
        uint32 height;
        uint32 right;
        uint32 sumOfRightBalances;
    }

    /// @notice Add an element to tree. If the element already exists, it will be updated
    /// @param newNode Address of the node to add
    /// @param balance Balance of the node
    function insert(address newNode, uint32 balance) external;

    /// @notice function add multiple addresses in one call
    /// @param newNodes newNodes of the node nodes
    /// @param balances Balances of the new nodes.
    function insertMultiple(address[] calldata newNodes, uint32[] calldata balances) external;

    /// @notice Update the balance of the node
    /// @param cluster Address of the existing node
    /// @param clusterBalance new balance of the node
    function update(address cluster, uint32 clusterBalance) external;

    /// @notice Delete a node from the tree
    /// @param key Address of the node to delete
    function deleteNode(address key) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./SelectorHelper.sol";

contract SingleSelector is SelectorHelper {
    constructor() {}

    /// @inheritdoc IClusterSelector
    function insert(address newNode, uint32 balance) public virtual override {
        require(newNode != address(0), ClusterLib.CANNOT_BE_ADDRESS_ZERO);
        uint32 nodeIndex = addressToIndexMap[newNode];
        Node memory node = nodes[nodeIndex];

        if (node.node == 0) {
            uint32 newIndex = getNewId();
            root = _insert(root, newIndex, balance);
            totalElements++;
            indexToAddressMap[newIndex] = newNode;
            addressToIndexMap[newNode] = newIndex;
        } else {
            // int256 differenceInKeyBalance = int256(clusterBalance) - int256(node.balance);
            _update(root, nodeIndex, int32(balance) - int32(node.balance));
        }
    }

    /// @inheritdoc IClusterSelector
    function insertMultiple(address[] calldata newNodes, uint32[] calldata balances) public virtual override {
        require(newNodes.length == balances.length, "arity mismatch");
        for (uint256 index = 0; index < newNodes.length; index++) {
            insert(newNodes[index], balances[index]);
        }
    }

    /// @inheritdoc IClusterSelector
    function deleteNode(address key) public virtual override {
        require(key != address(0), ClusterLib.CANNOT_BE_ADDRESS_ZERO);

        uint32 indexKey = addressToIndexMap[key];

        require(indexKey != 0, ClusterLib.CANNOT_BE_ADDRESS_ZERO);

        Node memory node = nodes[indexKey];
        require(node.node == indexKey, ClusterLib.NODE_NOT_PRESENT_IN_THE_TREE);
        root = _deleteNode(root, indexKey, node.balance);
        totalElements--;
        delete indexToAddressMap[indexKey];
        delete addressToIndexMap[key];
        emptyIds.push(indexKey);
    }

    /// @inheritdoc IClusterSelector
    function update(address existingNode, uint32 newBalance) public virtual override {
        uint32 indexKey = addressToIndexMap[existingNode];

        require(indexKey != 0, ClusterLib.CANNOT_BE_ADDRESS_ZERO);
        if (nodes[indexKey].node == 0) {
            assert(false);
        } else {
            int32 differenceInKeyBalance = int32(newBalance) - int32(nodes[indexKey].balance);
            _update(root, indexKey, differenceInKeyBalance);
        }
    }

    /// @notice Search a single node from the tree. Probability of getting selected is proportional to node's balance
    /// @param randomizer random number used for traversing the tree
    /// @return Address of the selected node
    function weightedSearch(uint256 randomizer) public view returns (address) {
        Node memory _root = nodes[root];
        uint256 totalWeightInTree = _getTotalBalancesIncludingWeight(_root);
        uint256 searchNumber = randomizer % totalWeightInTree;
        // console2.log("totalWeightInTree", totalWeightInTree);
        // console2.log("searchNumber", searchNumber);
        uint32 index = _weightedSearch(root, searchNumber);
        return indexToAddressMap[index];
    }

    /// @notice internal function to recursively search the node
    /// @param _node address of the node
    /// @param searchNumber random number used for traversing the tree
    /// @return Address of the selected node
    function _weightedSearch(uint32 _node, uint256 searchNumber) public view returns (uint32) {
        // |-----------sumOfLeftWeight -------|----balance-----|------sumOfRightWeights------|
        Node memory node = nodes[_node];
        (uint256 index1, uint256 index2, uint256 index3) = ClusterLib._getIndexesWithWeights(
            node.sumOfLeftBalances,
            node.balance,
            node.sumOfRightBalances
        );

        if (searchNumber <= index1) {
            return _weightedSearch(node.left, searchNumber);
        } else if (searchNumber > index1 && searchNumber <= index2) {
            return _node;
        } else if (searchNumber > index2 && searchNumber <= index3) {
            return _weightedSearch(node.right, searchNumber - index2);
        } else {
            // _printNode(_node);
            // console2.log("indexes", index1, index2, index3);
            // console2.log("search number", searchNumber);
            revert(ClusterLib.ERROR_OCCURED_DURING_WEIGHTED_SEARCH);
        }
    }

    /// @notice Update the balance of the node
    /// @param root Address of the current node
    /// @param key Address of the key
    /// @param diff Difference in the balance of the key
    function _update(
        uint32 root,
        uint32 key,
        int32 diff
    ) internal {
        Node storage currentNode = nodes[root];
        if (root == key) {
            diff > 0 ? currentNode.balance += uint32(diff) : currentNode.balance -= uint32(-diff);
        } else if (key < root) {
            diff > 0 ? currentNode.sumOfLeftBalances += uint32(diff) : currentNode.sumOfLeftBalances -= uint32(-diff);
            _update(currentNode.left, key, diff);
        } else {
            diff > 0 ? currentNode.sumOfRightBalances += uint32(diff) : currentNode.sumOfRightBalances -= uint32(-diff);
            _update(currentNode.right, key, diff);
        }
    }

    /// @notice Insert the node to the by searching the position where to add
    /// @param node Address of the current node
    /// @param key Address to add
    /// @param keyBalance Balance of the key
    function _insert(
        uint32 node,
        uint32 key,
        uint32 keyBalance
    ) internal returns (uint32) {
        // console2.log("inserting node", node);
        // console2.log("key", key);
        // console2.log("keyBalance", keyBalance);
        if (node == 0) {
            nodes[key] = _newNode(key, keyBalance);
            return nodes[key].node;
        }

        Node storage currentNode = nodes[node];
        if (key < node) {
            currentNode.left = _insert(currentNode.left, key, keyBalance);
            currentNode.sumOfLeftBalances += keyBalance;
        } else {
            currentNode.right = _insert(currentNode.right, key, keyBalance);
            currentNode.sumOfRightBalances += keyBalance;
        }

        // 2. update the height
        currentNode.height = uint8(calculateUpdatedHeight(currentNode));

        // 3. Get the height difference
        int256 heightDifference = getHeightDifference(node);

        // Left Left Case
        if (heightDifference > 1 && key < currentNode.left) {
            // console2.log("_insert LL Case", keyBalance);
            return _rightRotate(node);
        }

        // Right Right Case
        if (heightDifference < -1 && key > currentNode.right) {
            // console2.log("_insert RR Case", keyBalance);
            return _leftRotate(node);
        }

        // Left Right Case
        if (heightDifference > 1 && key > currentNode.left) {
            // console2.log("_insert LR Case", keyBalance);
            currentNode.left = _leftRotate(currentNode.left);
            return _rightRotate(node);
        }

        // Right Left Case
        if (heightDifference < -1 && key < currentNode.right) {
            // console2.log("_insert RL Case", keyBalance);
            currentNode.right = _rightRotate(currentNode.right);
            return _leftRotate(node);
        }

        return node;
    }

    /// @notice Returns true if the node is present in the tree with non zero balance.
    /// @param _node Address of the node to search
    /// @return True if node is present
    function search(address _node) public view returns (bool) {
        uint32 nodeKey = addressToIndexMap[_node];
        if (nodeKey == 0) {
            return false;
        }
        Node memory node = nodes[nodeKey];
        return node.node == nodeKey && node.balance != 0;
    }

    /// @notice Internal function to delete the node from the key
    /// @param _root Current root
    /// @param key Address of the node to be removed
    /// @param existingBalanceOfKey Balance of the key to be deleted
    function _deleteNode(
        uint32 _root,
        uint32 key,
        uint32 existingBalanceOfKey
    ) internal returns (uint32) {
        // console2.log("At node", _root);
        // console2.log("Element to delete", key);
        // console2.log("Balance of key to delete", existingBalanceOfKey);
        if (_root == 0) {
            return (_root);
        }

        Node storage node = nodes[_root];
        if (key < _root) {
            // console2.log("Moving to left");
            node.sumOfLeftBalances -= existingBalanceOfKey;
            (node.left) = _deleteNode(node.left, key, existingBalanceOfKey);
            // console2.log("After Moving to left");
        } else if (key > _root) {
            // console2.log("Moving to right");
            // console2.log("node.sumOfRightBalances", node.sumOfRightBalances);
            node.sumOfRightBalances -= existingBalanceOfKey;
            (node.right) = _deleteNode(node.right, key, existingBalanceOfKey);
            // console2.log("After Moving to right");
        } else {
            // console2.log("Wow! found node to delete");
            // if node.left and node.right are full, select the next smallest element to node.right, replace it with element to be removed
            // if node.right is full and node.left is null, select the next smallest element to node.right, replace it with element to be removed
            // if node.left is full and node.right is null, select node.left, replace it with node.left
            // if node.left and node.right are null, simply delete the element

            if (node.left != 0 && node.right != 0) {
                // console2.log("case 1");
                return _replaceWithLeastMinimumNode(_root);
            } else if (node.left == 0 && node.right != 0) {
                // console2.log("case 2");
                return _deleteNodeAndReturnRight(_root);
            } else if (node.left != 0 && node.right == 0) {
                // console2.log("case 3");
                return _deleteNodeAndReturnLeft(_root);
            }
            // last case == (node.left == address(0) && node.right == address(0))
            else {
                delete nodes[_root];
                return 0;
            }
        }

        node.height = uint8(calculateUpdatedHeight(node));

        int256 heightDifference = getHeightDifference(_root);

        if (heightDifference > 1 && getHeightDifference(node.left) >= 0) {
            return (_rightRotate(_root));
        }

        if (heightDifference > 1 && getHeightDifference(node.right) < 0) {
            node.left = _leftRotate(node.left);
            return (_rightRotate(_root));
        }

        if (heightDifference < -1 && getHeightDifference(node.right) <= 0) {
            return (_leftRotate(_root));
        }

        if (heightDifference < -1 && getHeightDifference(node.right) > 0) {
            node.right = _rightRotate(node.right);
            return (_leftRotate(_root));
        }

        return (_root);
    }

    /// @notice Internal function to delete when there exists a left node but no right node
    /// @param _node Address of Node to delete
    /// @return Address of node to replace the deleted node
    function _deleteNodeAndReturnLeft(uint32 _node) internal returns (uint32) {
        Node memory C_ND = nodes[_node];
        delete nodes[_node];

        Node memory SND = nodes[C_ND.left];
        return SND.node;
    }

    ///@notice Internal function to delete when there exist a right node but no left node
    /// @param _node Address of Node to delete
    /// @return Address of node to replace the deleted node
    function _deleteNodeAndReturnRight(uint32 _node) internal returns (uint32) {
        Node memory C_ND = nodes[_node];
        delete nodes[_node];

        Node memory SND = nodes[C_ND.right];
        return SND.node;
    }

    /// @notice Internal function to delete when both left and right node are defined.
    /// @param _node Address of Node to delete
    /// @return Address of node to replace the deleted node
    function _replaceWithLeastMinimumNode(uint32 _node) internal returns (uint32) {
        // update deletion here

        Node memory C_ND = nodes[_node];
        Node memory nodeRight = nodes[C_ND.right];

        if (nodeRight.left == 0) {
            Node storage nodeRightStorage = nodes[C_ND.right];

            nodeRightStorage.left = C_ND.left;
            nodeRightStorage.sumOfLeftBalances = C_ND.sumOfLeftBalances;
            nodeRightStorage.height = uint8(1 + Math.max(height(nodeRightStorage.left), height(nodeRightStorage.right)));

            delete nodes[_node];

            return C_ND.right;
        } else {
            // nodes[_node].balance = 0;
            // return _node

            Node memory leastMinNode = _findLeastMinNode(C_ND.right);

            C_ND.right = _deleteNode(C_ND.right, leastMinNode.node, leastMinNode.balance);
            delete nodes[_node];

            Node storage lmnStore = nodes[leastMinNode.node];

            // lmn is removed in storage, so create a new one
            lmnStore.node = leastMinNode.node;
            lmnStore.balance = leastMinNode.balance;
            lmnStore.left = C_ND.left;
            lmnStore.right = C_ND.right;
            lmnStore.sumOfLeftBalances = C_ND.sumOfLeftBalances;

            Node memory C_ND_right = nodes[C_ND.right];
            lmnStore.sumOfRightBalances = _getTotalBalancesIncludingWeight(C_ND_right);
            lmnStore.height = uint8(calculateUpdatedHeight(lmnStore));

            return leastMinNode.node;
        }
    }

    /// @notice Find the least minimum node for given node
    /// @param _node Address of node from which least min node has to be found
    /// @return Copy of Node that will be replaced
    function _findLeastMinNode(uint32 _node) internal view returns (Node memory) {
        Node memory node = nodes[_node];

        if (node.left != 0) {
            return _findLeastMinNode(node.left);
        }

        return (node);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ClusterLib.sol";
import "../interfaces/IClusterSelector.sol";

// import "forge-std/console2.sol";

abstract contract SelectorHelper is IClusterSelector {
    uint32 public idCounters;
    uint32[] public emptyIds;

    mapping(address => uint32) public addressToIndexMap;
    mapping(uint32 => address) public indexToAddressMap;

    /// @notice List of all nodes
    mapping(uint32 => Node) nodes;

    /// @notice Total number of all nodes in the tree
    uint256 public totalElements;

    /// @notice Address of the current root
    uint32 public root;

    /// @notice Height of the tree at a given moment
    /// @return Height of the tree
    function heightOfTheTree() public view returns (uint256) {
        return height(root);
    }

    /// @notice Height of any node at a given moment
    /// @param node Address of the node whose height needs to be searched
    /// @return Height of the node
    function height(uint32 node) public view returns (uint32) {
        if (node == 0) return 0;
        return nodes[node].height;
    }

    /// @notice Function to create a empty node
    /// @param node Address of the new node
    /// @param balance Balance of the new node
    /// @return newNode Empty node with address and balance
    function _newNode(uint32 node, uint32 balance) internal pure returns (Node memory newNode) {
        newNode = Node(node, balance, 0, 0, 1, 0, 0);
    }

    /// @notice Right rotate a given node
    /// @param addressOfZ address of the node to right rotate
    /// @return Returns the new root after the rotation
    /// @notice ----------------------------- z -----------------------------
    /// @notice --------------------------- /   \ ---------------------------
    /// @notice -------------------------- y     T4 -------------------------
    /// @notice ------------------------- / \        ------------------------
    /// @notice ------------------------ x   T3       -----------------------
    /// @notice ----------------------- / \            ----------------------
    /// @notice ---------------------- T1  T2            --------------------
    /// @notice is rotated to
    /// @notice ----------------------------- y -----------------------------
    /// @notice --------------------------- /   \ ---------------------------
    /// @notice -------------------------- x     z --------------------------
    /// @notice ------------------------- / \   / \ -------------------------
    /// @notice ------------------------ T1 T2 T3 T4 ------------------------
    function _rightRotate(uint32 addressOfZ) internal returns (uint32) {
        if (addressOfZ == 0) {
            revert(ClusterLib.CANNOT_RR_ADDRESS_ZERO);
        }
        Node storage z = nodes[addressOfZ];

        Node storage y = nodes[z.left];

        // do not rotate if left is 0
        if (y.node == 0) {
            // console2.log("RR: not because y is 0 ");
            return z.node;
        }
        Node memory T3 = nodes[y.right];

        // cut z.left
        z.sumOfLeftBalances = _getTotalBalancesIncludingWeight(T3);
        z.left = T3.node;
        // cut y.right
        y.sumOfRightBalances = _getTotalBalancesIncludingWeight(z);
        y.right = z.node;

        z.height = uint8(calculateUpdatedHeight(z));
        y.height = uint8(calculateUpdatedHeight(y));
        return y.node;
    }

    /// @notice Lef rotate a given node
    /// @param addressOfZ address of the node to left rotate
    /// @return Returns the new root after the rotation
    /// @notice ----------------------------- z -----------------------------
    /// @notice --------------------------- /   \ ---------------------------
    /// @notice -------------------------- T1    y --------------------------
    /// @notice -------------------------       / \ -------------------------
    /// @notice ------------------------      T2   x ------------------------
    /// @notice -----------------------           / \ -----------------------
    /// @notice ----------------------           T3  T4 ---------------------
    /// @notice is rotated to
    /// @notice ----------------------------- y -----------------------------
    /// @notice --------------------------- /   \ ---------------------------
    /// @notice -------------------------- z     x --------------------------
    /// @notice ------------------------- / \   / \ -------------------------
    /// @notice ------------------------ T1 T2 T3 T4 ------------------------
    function _leftRotate(uint32 addressOfZ) internal returns (uint32) {
        if (addressOfZ == 0) {
            revert(ClusterLib.CANNOT_LR_ADDRESS_ZERO);
        }
        Node storage z = nodes[addressOfZ];

        Node storage y = nodes[z.right];

        // do not rotate if right is 0
        if (y.node == 0) {
            // console2.log("LR: not because y is 0 ");
            return z.node;
        }
        Node memory T2 = nodes[y.left];

        // cut z.right
        z.sumOfRightBalances = _getTotalBalancesIncludingWeight(T2);
        z.right = T2.node;
        // cut y.left
        y.sumOfLeftBalances = _getTotalBalancesIncludingWeight(z);
        y.left = z.node;

        z.height = uint8(calculateUpdatedHeight(z));
        y.height = uint8(calculateUpdatedHeight(y));
        return y.node;
    }

    /// @notice Returns the (node balance) i.e difference in heights of left and right nodes
    /// @param node Address of the node to get height difference of
    /// @return Height Difference of the node
    function getHeightDifference(uint32 node) public view returns (int32) {
        if (node == 0) return 0;

        Node memory existingNode = nodes[node];

        return int32(height(existingNode.left)) - int32(height(existingNode.right));
    }

    /// @notice Returns the data of the node
    /// @param _node Address of the node
    /// @return node Data of the node
    function nodeData(uint32 _node) public view returns (Node memory node) {
        node = nodes[_node];
    }

    /// @notice Get total weight of the node
    /// @param node Node to calculate total weight for
    /// @return Total weight of the node
    function _getTotalBalancesIncludingWeight(Node memory node) internal pure returns (uint32) {
        return node.balance + node.sumOfLeftBalances + node.sumOfRightBalances;
    }

    function calculateUpdatedHeight(Node memory node) internal view returns (uint256) {
        return Math.max(height(node.right), height(node.left)) + 1;
    }

    // optimise this whole function
    function getNewId() internal returns (uint32) {
        if (emptyIds.length > 0) {
            uint32 id = emptyIds[emptyIds.length - 1];
            emptyIds.pop();
            return id;
        } else {
            uint32 id = ++idCounters;
            return id;
        }
    }

    // function _printNode(address _node) internal view {
    //     Node memory node = nodes[_node];
    //     console2.log("************************************");
    //     console2.log("cluster", node.node);
    //     console2.log("balance", node.balance);
    //     console2.log("left", node.left);
    //     console2.log("right", node.right);
    //     console2.log("sumOfLeftBalances", node.sumOfLeftBalances);
    //     console2.log("sumOfRightBalances", node.sumOfRightBalances);
    //     console2.log(" height", node.height);
    //     console2.log("************************************");
    // }

    // function _printArray(string memory data, bytes memory arrayBytes) internal view {
    //     console2.log(data);
    //     address[] memory array = abi.decode(arrayBytes, (address[]));
    //     console2.log("[");
    //     for (uint256 index = 0; index < array.length; index++) {
    //         console2.log(index, array[index]);
    //     }
    //     console2.log("]");
    // }

    // function _printArray(string memory data, address[] memory array) internal view {
    //     console2.log(data);
    //     console2.log("[");
    //     for (uint256 index = 0; index < array.length; index++) {
    //         console2.log(index, array[index]);
    //     }
    //     console2.log("]");
    // }

    // function _printPaths(string memory data, bytes[] memory bytesdata) internal view {
    //     console2.log(data);

    //     console2.log("[");
    //     for (uint256 index = 0; index < bytesdata.length; index++) {
    //         address[] memory _paths = abi.decode(bytesdata[index], (address[]));
    //         _printArray("subarray ", _paths);
    //     }
    //     console2.log("]");
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "forge-std/console2.sol";

library ClusterLib {
    string constant CANNOT_RR_ADDRESS_ZERO = "1";
    string constant CANNOT_LR_ADDRESS_ZERO = "2";
    string constant CANNOT_BE_ADDRESS_ZERO = "3";
    string constant NODE_NOT_PRESENT_IN_THE_TREE = "4";
    string constant ERROR_OCCURED_DURING_WEIGHTED_SEARCH = "5";
    string constant ERROR_OCCURED_DURING_UPDATE = "6";
    string constant CANNOT_INSERT_DUPLICATE_ELEMENT_INTO_TREE = "7";
    string constant ERROR_OCCURED_DURING_DELETE = "8";
    string constant INSUFFICIENT_ELEMENTS_IN_TREE = "9";
    string constant ERROR_OCCURED_DURING_TRAVERSING_SELECTED_NODE = "10";
    string constant ERROR_OCCURED_DURING_TRAVERSING_NON_SELECTED_NODE = "11";

    /// @notice Checks if the array has an element in it
    /// @param array Array to check
    /// @param element Element to check in the array
    function ifArrayHasElement(address[] memory array, address element) internal pure returns (bool) {
        if (element == address(0)) {
            return false;
        }
        for (uint256 index = 0; index < array.length; index++) {
            if (element == array[index]) {
                return true;
            }
        }
        return false;
    }

    /// @notice Checks if the array has an element in it
    /// @param array Array to check
    /// @param element Element to check in the array
    function ifArrayHasElement(uint32[] memory array, uint32 element) internal pure returns (bool) {
        if (element == 0) {
            return false;
        }
        for (uint256 index = 0; index < array.length; index++) {
            if (element == array[index]) {
                return true;
            }
        }
        return false;
    }

    /// @notice Returns indexes when only balances and left and right weights are provided
    /// @param sumOfLeftBalances Sum of balances of nodes on the left
    /// @param balance Balance of the node
    /// @param sumOfRightBalances Sum of balances of nodes on the right
    /// @return First index of the search
    /// @return Second index of the search
    /// @return Third index of the search
    function _getIndexesWithWeights(
        uint32 sumOfLeftBalances,
        uint32 balance,
        uint32 sumOfRightBalances
    )
        internal
        pure
        returns (
            uint32,
            uint32,
            uint32
        )
    {
        return (sumOfLeftBalances, sumOfLeftBalances + balance, sumOfLeftBalances + balance + sumOfRightBalances);
    }

    /// @notice Add element to array
    /// @param array Array to which the element must be added
    /// @param toAdd Element to add
    /// @return A new array with element added to it
    function _addAddressToEncodedArray(bytes memory array, address toAdd) internal pure returns (bytes memory) {
        address[] memory _currentNodePath = abi.decode(array, (address[]));
        uint256 lengthOfNewPath = _currentNodePath.length + 1;

        assembly {
            mstore(_currentNodePath, lengthOfNewPath)
        }

        _currentNodePath[lengthOfNewPath - 1] = toAdd;
        return abi.encode(_currentNodePath);
    }

    function _getAddressesFromEncodedArray(bytes memory array) internal pure returns (address[] memory) {
        return abi.decode(array, (address[]));
    }

    // function _addAddressToEncodedArray(address[] memory array, address toAdd) internal pure returns (address[] memory) {
    //     let _array = new address[](array.length
    //     array.push(toAdd);
    //     return _array;
    // }

    // function _addAddressToEncodedArray(bytes memory array, address toAdd) internal pure returns (bytes memory) {
    //     return abi.encodePacked(array, toAdd);
    // }

    // function ifArrayHasElement(bytes memory array, address element) internal pure returns (bool) {
    //     uint256 index = 0;
    //     while (index < array.length) {
    //         address temp = bytesToAddress(slice(array, index, 20));
    //         if (temp == element) {
    //             return true;
    //         }
    //         index += 20;
    //     }

    //     return false;
    // }

    // function bytesToAddress(bytes memory bys) private pure returns (address addr) {
    //     assembly {
    //         addr := mload(add(bys, 20))
    //     }
    // }

    // function slice(
    //     bytes memory _bytes,
    //     uint256 _start,
    //     uint256 _length
    // ) internal pure returns (bytes memory) {
    //     require(_length + 31 >= _length, "slice_overflow");
    //     require(_bytes.length >= _start + _length, "slice_outOfBounds");

    //     bytes memory tempBytes;

    //     assembly {
    //         switch iszero(_length)
    //         case 0 {
    //             // Get a location of some free memory and store it in tempBytes as
    //             // Solidity does for memory variables.
    //             tempBytes := mload(0x40)

    //             // The first word of the slice result is potentially a partial
    //             // word read from the original array. To read it, we calculate
    //             // the length of that partial word and start copying that many
    //             // bytes into the array. The first word we copy will start with
    //             // data we don't care about, but the last `lengthmod` bytes will
    //             // land at the beginning of the contents of the new array. When
    //             // we're done copying, we overwrite the full first word with
    //             // the actual length of the slice.
    //             let lengthmod := and(_length, 31)

    //             // The multiplication in the next line is necessary
    //             // because when slicing multiples of 32 bytes (lengthmod == 0)
    //             // the following copy loop was copying the origin's length
    //             // and then ending prematurely not copying everything it should.
    //             let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
    //             let end := add(mc, _length)

    //             for {
    //                 // The multiplication in the next line has the same exact purpose
    //                 // as the one above.
    //                 let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
    //             } lt(mc, end) {
    //                 mc := add(mc, 0x20)
    //                 cc := add(cc, 0x20)
    //             } {
    //                 mstore(mc, mload(cc))
    //             }

    //             mstore(tempBytes, _length)

    //             //update free-memory pointer
    //             //allocating the array padded to 32 bytes like the compiler does now
    //             mstore(0x40, and(add(mc, 31), not(31)))
    //         }
    //         //if we want a zero-length slice let's just return a zero-length array
    //         default {
    //             tempBytes := mload(0x40)
    //             //zero out the 32 bytes slice we are about to return
    //             //we need to do it because Solidity does not garbage collect
    //             mstore(tempBytes, 0)

    //             mstore(0x40, add(tempBytes, 0x20))
    //         }
    //     }

    //     return tempBytes;
    // }
}