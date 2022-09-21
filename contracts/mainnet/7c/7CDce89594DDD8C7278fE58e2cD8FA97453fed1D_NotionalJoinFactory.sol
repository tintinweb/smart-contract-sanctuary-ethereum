// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import '@yield-protocol/vault-v2/contracts/other/notional/NotionalJoin.sol';
import '@yield-protocol/utils-v2/contracts/access/AccessControl.sol';
import {IEmergencyBrake} from '@yield-protocol/utils-v2/contracts/utils/EmergencyBrake.sol';
import {ILadleGov} from '@yield-protocol/vault-v2/contracts/interfaces/ILadleGov.sol';
import {INotionalJoin} from '@yield-protocol/vault-v2/contracts/other/notional/INotionalJoin.sol';
import {ILadle} from '@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol';

/// @dev NotionalJoinFactory creates new join contracts supporting Notional Finance's fCash tokens.
/// @author @calnix
contract NotionalJoinFactory is AccessControl {

    ILadleGov public ladle;

    event JoinCreated(address indexed asset, address indexed join);
    event Point(bytes32 indexed param, address indexed oldValue, address indexed newValue);
    event Log(string message);

    error UnrecognisedParam(bytes32 param);

    constructor(ILadleGov ladle_) {
        ladle = ladle_;
    }

    /// @dev Deploys a new notional join using create2
    /// @param oldAssetId Id of prior matured fCash token. (e.g. fDAIJUN22)
    /// @param newAssetId Id of incoming fCash token. (e.g. fDAISEP22)
    /// @param salt Random number of choice
    /// @return join Deployed notional join address
    function deploy(
        bytes6 oldAssetId,
        bytes6 newAssetId,
        address newAssetAddress,
        uint256 salt
    ) external auth returns (NotionalJoin) {
        require(address(ladle.joins(oldAssetId)) != address(0), "oldAssetId invalid");
        require(address(ladle.joins(newAssetId)) == address(0), "newAssetId join exists"); 

        // get join of oldAssetId
        INotionalJoin oldJoin = INotionalJoin(address(ladle.joins(oldAssetId)));

        // njoin check
        // check could be bypassed if Join has a fallback function 
        try oldJoin.fCashId() returns (uint256) {
            emit Log("valid njoin");
        } catch {
            emit Log("oldAssetId join invalid");
        }
        
        // get underlying, underlyingJoin addresses
        address underlying = oldJoin.underlying(); 
        address underlyingJoin = oldJoin.underlyingJoin();
        
        // get new maturity
        uint16 currencyId = oldJoin.currencyId();
        uint40 oldMaturity = oldJoin.maturity();
        uint40 maturity = oldMaturity + 90 days;
  
        NotionalJoin join = new NotionalJoin{salt: bytes32(salt)}(
            newAssetAddress,
            underlying,
            underlyingJoin,
            maturity,
            currencyId
        );

        address joinAddress = address(join);

        // grant ROOT to msg.sender
        AccessControl(joinAddress).grantRole(ROOT, msg.sender);  
        // revoke ROOT from NotionalJoinFactory
        AccessControl(joinAddress).renounceRole(ROOT, address(this));

        emit JoinCreated(newAssetAddress, address(join));
        return join;
    }

    /// @dev Get address of contract to be deployed
    /// @param bytecode Bytecode of the contract to be deployed (include constructor params)
    /// @param salt Random number of choice
    function getAddress(bytes memory bytecode, uint256 salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        // cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @dev Get bytecode of contract to be deployed
    /// @param asset Address of the ERC1155 token. (e.g. fDai2203)
    /// @param underlying Address of the underlying token. (e.g. Dai)
    /// @param underlyingJoin Address of the underlying join contract. (e.g. Dai join contract)
    /// @param maturity Maturity of fCash token. (90-day intervals)
    /// @param currencyId Maturity of fCash token. (90-day intervals)
    /// @return bytes Bytecode of notional join to be passed into getAddress()
    function getByteCode(
        address asset,
        address underlying,
        address underlyingJoin,
        uint40 maturity,
        uint16 currencyId
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(NotionalJoin).creationCode;

        //append constructor arguments
        return abi.encodePacked(bytecode, abi.encode(asset, underlying, underlyingJoin, maturity, currencyId));
    }

    /// @dev Point to a different ladle
    /// @param param Name of parameter to set (must be "ladle")
    /// @param value Address of new contract
    function point(bytes32 param, address value) external auth {
        if (param != "ladle") {
            revert UnrecognisedParam(param);
        }
        address oldLadle = address(ladle);
        ladle = ILadleGov(value);
        emit Point(param, oldLadle, value);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
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
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/AccessControl.sol";


interface IEmergencyBrake {
    struct Permission {
        address contact;
        bytes4[] signatures;
    }

    function plan(address target, Permission[] calldata permissions) external returns (bytes32 txHash);
    function cancel(bytes32 txHash) external;
    function execute(bytes32 txHash) external;
    function restore(bytes32 txHash) external;
    function terminate(bytes32 txHash) external;
}

/// @dev EmergencyBrake allows to plan for and execute transactions that remove access permissions for a target
/// contract. In an permissioned environment this can be used for pausing components.
/// All contracts in scope of emergency plans must grant ROOT permissions to EmergencyBrake. To mitigate the risk
/// of governance capture, EmergencyBrake has very limited functionality, being able only to revoke existing roles
/// and to restore previously revoked roles. Thus EmergencyBrake cannot grant permissions that weren't there in the 
/// first place. As an additional safeguard, EmergencyBrake cannot revoke or grant ROOT roles.
/// In addition, there is a separation of concerns between the planner and the executor accounts, so that both of them
/// must be compromised simultaneously to execute non-approved emergency plans, and then only creating a denial of service.
contract EmergencyBrake is AccessControl, IEmergencyBrake {
    enum State {UNPLANNED, PLANNED, EXECUTED}

    struct Plan {
        State state;
        address target;
        bytes permissions;
    }

    event Planned(bytes32 indexed txHash, address indexed target);
    event Cancelled(bytes32 indexed txHash);
    event Executed(bytes32 indexed txHash, address indexed target);
    event Restored(bytes32 indexed txHash, address indexed target);
    event Terminated(bytes32 indexed txHash);

    mapping (bytes32 => Plan) public plans;

    constructor(address planner, address executor) AccessControl() {
        _grantRole(IEmergencyBrake.plan.selector, planner);
        _grantRole(IEmergencyBrake.cancel.selector, planner);
        _grantRole(IEmergencyBrake.execute.selector, executor);
        _grantRole(IEmergencyBrake.restore.selector, planner);
        _grantRole(IEmergencyBrake.terminate.selector, planner);

        // Granting roles (plan, cancel, execute, restore, terminate) is reserved to ROOT
    }

    /// @dev Compute the hash of a plan
    function hash(address target, Permission[] calldata permissions)
        external pure
        returns (bytes32 txHash)
    {
        txHash = keccak256(abi.encode(target, permissions));
    }

    /// @dev Register an access removal transaction
    function plan(address target, Permission[] calldata permissions)
        external override auth
        returns (bytes32 txHash)
    {
        txHash = keccak256(abi.encode(target, permissions));
        require(plans[txHash].state == State.UNPLANNED, "Emergency already planned for.");

        // Removing or granting ROOT permissions is out of bounds for EmergencyBrake
        for (uint256 i = 0; i < permissions.length; i++){
            for (uint256 j = 0; j < permissions[i].signatures.length; j++){
                require(
                    permissions[i].signatures[j] != ROOT,
                    "Can't remove ROOT"
                );
            }
        }

        plans[txHash] = Plan({
            state: State.PLANNED,
            target: target,
            permissions: abi.encode(permissions)
        });
        emit Planned(txHash, target);
    }

    /// @dev Erase a planned access removal transaction
    function cancel(bytes32 txHash)
        external override auth
    {
        require(plans[txHash].state == State.PLANNED, "Emergency not planned for.");
        delete plans[txHash];
        emit Cancelled(txHash);
    }

    /// @dev Execute an access removal transaction
    function execute(bytes32 txHash)
        external override auth
    {
        Plan memory plan_ = plans[txHash];
        require(plan_.state == State.PLANNED, "Emergency not planned for.");
        plans[txHash].state = State.EXECUTED;

        Permission[] memory permissions_ = abi.decode(plan_.permissions, (Permission[]));

        for (uint256 i = 0; i < permissions_.length; i++){
            // AccessControl.sol doesn't revert if revoking permissions that haven't been granted
            // If we don't check, planner and executor can collude to gain access to contacts
            Permission memory permission_ = permissions_[i]; 
            for (uint256 j = 0; j < permission_.signatures.length; j++){
                AccessControl contact = AccessControl(permission_.contact);
                bytes4 signature_ = permission_.signatures[j];
                require(
                    contact.hasRole(signature_, plan_.target),
                    "Permission not found"
                );
                contact.revokeRole(signature_, plan_.target);
            }
        }
        emit Executed(txHash, plan_.target);
    }

    /// @dev Restore the orchestration from an isolated target
    function restore(bytes32 txHash)
        external override auth
    {
        Plan memory plan_ = plans[txHash];
        require(plan_.state == State.EXECUTED, "Emergency plan not executed.");
        plans[txHash].state = State.PLANNED;

        Permission[] memory permissions_ = abi.decode(plan_.permissions, (Permission[]));

        for (uint256 i = 0; i < permissions_.length; i++){
            Permission memory permission_ = permissions_[i]; 
            for (uint256 j = 0; j < permission_.signatures.length; j++){
                AccessControl contact = AccessControl(permission_.contact);
                bytes4 signature_ = permission_.signatures[j];
                contact.grantRole(signature_, plan_.target);
            }
        }
        emit Restored(txHash, plan_.target);
    }

    /// @dev Remove the restoring option from an isolated target
    function terminate(bytes32 txHash)
        external override auth
    {
        require(plans[txHash].state == State.EXECUTED, "Emergency plan not executed.");
        delete plans[txHash];
        emit Terminated(txHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IJoin.sol";

interface ILadleGov {
    function joins(bytes6) external view returns (IJoin);

    function addJoin(bytes6, address) external;

    function addPool(bytes6, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IJoin.sol";
import "./ICauldron.sol";

interface ILadle {
    function joins(bytes6) external view returns (IJoin);

    function pools(bytes6) external view returns (address);

    function cauldron() external view returns (ICauldron);

    function build(
        bytes6 seriesId,
        bytes6 ilkId,
        uint8 salt
    ) external returns (bytes12 vaultId, DataTypes.Vault memory vault);

    function destroy(bytes12 vaultId) external;

    function pour(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external payable;

    function serve(
        bytes12 vaultId,
        address to,
        uint128 ink,
        uint128 base,
        uint128 max
    ) external payable returns (uint128 art);

    function close(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "../../interfaces/IJoin.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/MinimalTransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/math/WMul.sol";
import "@yield-protocol/utils-v2/contracts/math/WDiv.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import "./IBatchAction.sol";
import "./ERC1155.sol";

contract NotionalJoin is IJoin, ERC1155TokenReceiver, AccessControl {
    using WMul for uint256;
    using WDiv for uint256;
    using CastU256U128 for uint256;

    event FlashFeeFactorSet(uint256 indexed fee);
    event Redeemed(uint256 fCash, uint256 underlying, uint256 accrual);

    bytes32 internal constant FLASH_LOAN_RETURN =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public constant FLASH_LOANS_DISABLED = type(uint256).max;

    address public immutable override asset;
    address public immutable underlying;
    address public immutable underlyingJoin;
    uint40 public immutable maturity; // Maturity date for fCash
    uint16 public immutable currencyId; // Notional currency id for the underlying
    uint256 public immutable fCashId; // This ERC1155 Join only accepts one fCashId from the ERC1155 token
    uint256 public storedBalance; // After maturity, this is reused as the balance for underlying
    uint256 public accrual; // fCash to underlying factor, with 18 decimals
    uint256 public flashFeeFactor = FLASH_LOANS_DISABLED; // Fee on flash loans, as a percentage in fixed point with 18 decimals. Flash loans disabled by default.

    constructor(
        address asset_,
        address underlying_,
        address underlyingJoin_,
        uint40 maturity_,
        uint16 currencyId_
    ) {
        asset = asset_;
        underlying = underlying_;
        maturity = maturity_;
        currencyId = currencyId_;
        underlyingJoin = underlyingJoin_;

        // TransferAssets.encodeAssetId
        fCashId = uint256(
            (bytes32(uint256(currencyId_)) << 48) |
                (bytes32(uint256(maturity_)) << 8) |
                bytes32(uint256(1))
        );
    }

    modifier afterMaturity() {
        require(block.timestamp >= maturity, "Only after maturity");
        _;
    }

    modifier beforeMaturity() {
        require(block.timestamp < maturity, "Only before maturity");
        _;
    }

    /// @dev Advertising through ERC165 the available functions
    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns (bool)
    {
        // ERC-165 support = `bytes4(keccak256('supportsInterface(bytes4)'))`.
        // ERC-1155 `ERC1155TokenReceiver` support = `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
        return
            interfaceID == NotionalJoin.supportsInterface.selector ||
            interfaceID ==
            ERC1155TokenReceiver.onERC1155Received.selector ^
                ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    /// @dev Called by the sender after a transfer to verify it was received. Ensures only `fCashId` tokens are received.
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        require(id == fCashId, "Token fCashId not accepted");
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @dev Called by the sender after a batch transfer to verify it was received. Ensures only `fCashId` tokens are received.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4) {
        uint256 length = ids.length;
        for (uint256 i; i < length; ++i)
            require(ids[i] == fCashId, "Token fCashId not accepted");
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    /// @dev Take `amount` `asset` from `user` using `transferFrom`, minus any unaccounted `asset` in this contract.
    /// @param user Address of receiver of tokens
    /// @param amount Amount of tokens
    function join(address user, uint128 amount)
        external
        override
        auth
        returns (uint128)
    {
        return _join(user, amount);
    }

    /// @dev Take `amount` `asset` from `user` using `transferFrom`, minus any unaccounted `asset` in this contract.
    /// @param user Address of receiver of tokens
    /// @param amount Amount of tokens
    function _join(address user, uint128 amount)
        internal
        beforeMaturity
        returns (uint128)
    {
        ERC1155 token = ERC1155(asset);
        uint256 _storedBalance = storedBalance;
        uint256 available = token.balanceOf(address(this), fCashId) - _storedBalance; // Fine to panic if this underflows

        unchecked {
            storedBalance = _storedBalance + amount; // Unlikely that a uint128 added to the stored balance will make it overflow
            if (available < amount)
                token.safeTransferFrom(
                    user,
                    address(this),
                    fCashId,
                    amount - available,
                    ""
                );
        }
        return amount;
    }

    /// @dev Before maturity, transfer `amount` `asset` to `user`.
    /// @param user Address of receiver of tokens
    /// @param amount Amount of tokens
    /// After maturity, withdraw if necessary, then transfer `amount.wmul(accrual)` `underlying` to `user`.
    function exit(address user, uint128 amount)
        external
        override
        auth
        returns (uint128)
    {
        if (block.timestamp < maturity) {
            return _exit(user, amount);
        } else {
            if (accrual == 0) redeem(); // Redeem all fCash, switch to underlying join, set accrual.
            return _exitUnderlying(user, uint256(amount).wmul(accrual).u128());
        }
    }

    /// @dev Transfer `amount` `asset` to `user`
    /// @param user Address of receiver of fCash tokens
    /// @param amount Amount of ERC1155 tokens
    function _exit(address user, uint128 amount) internal returns (uint128) {
        storedBalance -= amount;
        ERC1155(asset).safeTransferFrom(address(this), user, fCashId, amount, "");
        return amount;
    }

    /// @dev Transfer `amount` `underlying` to `user`
    /// @param user Recipient of token transfer
    /// @param amount Amount of underlying tokens to transfer
    function _exitUnderlying(address user, uint128 amount)
        internal
        returns (uint128)
    {
        IJoin(underlyingJoin).exit(user, amount);
        return amount;
    }

    /// @dev Converts all fCash holdings to underlying and send it to the main underlying join
    function redeem() public afterMaturity {
        require(accrual == 0, "Already redeemed");

        // Build an action to withdraw all mature fCash into underlying, then withdraw.
        IBatchAction.BalanceAction[]
            memory withdrawActions = new IBatchAction.BalanceAction[](1);
        withdrawActions[0] = IBatchAction.BalanceAction({
            actionType: IBatchAction.DepositActionType.None,
            currencyId: currencyId,
            depositActionAmount: 0,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true
        });

        IBatchAction(asset).batchBalanceAction(address(this), withdrawActions);

        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        uint256 storedBalance_ = storedBalance;
        accrual = underlyingBalance.wdiv(storedBalance_); // There is a rounding loss here. Some wei will be forever locked in the join.

        // transfer underlying to main join
        MinimalTransferHelper.safeTransfer(
            IERC20(underlying),
            address(underlyingJoin),
            underlyingBalance
        );
        IJoin(underlyingJoin).join(address(this), underlyingBalance.u128());

        // no more fCash left in holding
        storedBalance = 0;

        emit Redeemed(storedBalance_, underlyingBalance, accrual);
    }

    /// @dev Retrieve any ERC20 tokens. Useful for airdropped tokens.
    /// @param token ERC20 contract object
    /// @param to Address of receiver
    function retrieve(IERC20 token, address to) external auth {
        require(
            address(token) != address(underlying),
            "Use exit for underlying"
        );
        MinimalTransferHelper.safeTransfer(
            token,
            to,
            token.balanceOf(address(this))
        );
    }

    /// @dev Retrieve any ERC1155 tokens other than the `asset`. Useful for airdropped tokens.
    /// @param token ERC1155 token passed as contract object
    /// @param id ID of ERC1155 token
    /// @param to Address of receiver
    function retrieveERC1155(
        ERC1155 token,
        uint256 id,
        address to
    ) external auth {
        require(
            address(token) != address(asset) || id != fCashId,
            "Use exit for asset"
        );
        token.safeTransferFrom(
            address(this),
            to,
            id,
            token.balanceOf(address(this), id),
            ""
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../interfaces/IJoin.sol";

interface INotionalJoin is IJoin {
    function underlying() external view returns(address);
    function underlyingJoin() external view returns(address);
    function maturity() external view returns(uint40); // Maturity date for fCash
    function currencyId() external view returns(uint16); // Notional currency id for the underlying
    function fCashId() external view returns(uint256); // This ERC1155 Join only accepts one fCashId from the ERC1155 token
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";

interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC5095.sol";
import "./IJoin.sol";

interface IFYToken is IERC5095 {
    /// @dev Source of redemption funds.
    function join() external view returns (IJoin);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";

library DataTypes {
    // ======== Cauldron data types ========
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }

    // ======== Witch data types ========
    struct Auction {
        address owner;
        uint32 start;
        bytes6 baseId; // We cache the baseId here
        uint128 ink;
        uint128 art;
        address auctioneer;
        bytes6 ilkId; // We cache the ilkId here
        bytes6 seriesId; // We cache the seriesId here
    }

    struct Line {
        uint32 duration; // Time that auctions take to go to minimal price and stay there
        uint64 vaultProportion; // Proportion of the vault that is available each auction (1e18 = 100%)
        uint64 collateralProportion; // Proportion of collateral that is sold at auction start (1e18 = 100%)
    }

    struct Limits {
        uint128 max; // Maximum concurrent auctioned collateral
        uint128 sum; // Current concurrent auctioned collateral
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IERC5095 is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address underlyingAddress);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256 timestamp);

    /// @dev Converts a specified amount of principal to underlying
    function convertToUnderlying(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Converts a specified amount of underlying to principal
    function convertToPrincipal(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Gives the maximum amount an address holder can redeem in terms of the principal
    function maxRedeem(address holder) external view returns (uint256 maxPrincipalAmount);

    /// @dev Gives the amount in terms of underlying that the princiapl amount can be redeemed for plus accrual
    function previewRedeem(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Burn fyToken after maturity for an amount of principal.
    function redeem(uint256 principalAmount, address to, address from) external returns (uint256 underlyingAmount);

    /// @dev Gives the maximum amount an address holder can withdraw in terms of the underlying
    function maxWithdraw(address holder) external returns (uint256 maxUnderlyingAmount);

    /// @dev Gives the amount in terms of principal that the underlying amount can be withdrawn for plus accrual
    function previewWithdraw(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function withdraw(uint256 underlyingAmount, address to, address from) external returns (uint256 principalAmount);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for transferring ERC20 tokens that do not consistently return true/false
library MinimalTransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library WMul {
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Multiply an amount by a fixed point factor with 18 decimals, rounds down.
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked { z /= 1e18; }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library WDiv { // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide an amount by a fixed point factor with 18 decimals
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e18) / y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

interface IBatchAction {
    /// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
    enum DepositActionType {
        // No deposit action
        None,
        // Deposit asset cash, depositActionAmount is specified in asset cash external precision
        DepositAsset,
        // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
        // external precision
        DepositUnderlying,
        // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
        // nTokens into the account
        DepositAssetAndMintNToken,
        // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
        DepositUnderlyingAndMintNToken,
        // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
        // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
        RedeemNToken,
        // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
        // Notional internal 8 decimal precision.
        ConvertCashToNToken
    }
    /// @notice Defines a balance action for batchAction
    struct BalanceAction {
        // Deposit action to take (if any)
        DepositActionType actionType;
        uint16 currencyId;
        // Deposit action amount must correspond to the depositActionType, see documentation above.
        uint256 depositActionAmount;
        // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
        uint256 withdrawAmountInternalPrecision;
        // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
        // residual left from trading.
        bool withdrawEntireCashBalance;
        // If set to true, will redeem asset cash to the underlying token on withdraw.
        bool redeemToUnderlying;
    }

    /// @notice Executes a batch of balance transfers including minting and redeeming nTokens.
    /// @param account the account for the action
    /// @param actions array of balance actions to take, must be sorted by currency id
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}