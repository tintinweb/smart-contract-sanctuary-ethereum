// SPDX-License-Identifier: AGPL-3.0-only

/*      -.:````:::..        Arbor allows DAOs and other on-chain        .A
      /`:``-..-`   ..:.     entities to borrow stablecoins using       .AAA:
   ./`.:       \:``   :.    their tokens as collateral with fixed    .AAAAAA:
 ./`::`          \.--`` :.       rates and no liquidations.       .:AA.:AAAA:
./_.::            \.    .:                                       :AA..AAAAAA:
||  ::             |--``::.                                     :AA..AAAAAAA:
||_ ::             |.___.::                        ...         :AA..AAAAAAA`
|| `::             ||`|`:::                   .:AAAAAAAAA:.    .A..AAAAAAA`
||_\::             || | |::                  .AAAAAAAAAAAAAAA:  A..AAAA`
|| `::             ||\|/|::                .AAAAA.  AAAAAAAAAA:.:.``
||_\::             || | |::               .AAAAAAA```..........`:`..AA.
|| `:: An Arbor to ||/|\|::                    ``AAAAAAAAAAAAA` .AA..AAA.
||_\::  help DAOs  || | |::                          ``````     AAAA..ABG.
|| `::    Grow     ||\|/|::                                    .AAAAA..AAA.
||_\::             || | |::      For more information about    .AAAAAAA.AA.
|| `::             ||/|\|::         Arbor Finance, visit        .AAAAAAA.AA.
||_\::             ||_  |::         https://arbor.garden         .AAAAAA:AA.
`` `::                `` ::                                        .AAAAAAAA.
    ::                   ::                                            .AAAAA.
    ::                      Authors: Bookland Luckyrobot Namaskar          `*/

pragma solidity 0.8.9;

import {IBondFactory} from "./interfaces/IBondFactory.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {FixedPointMathLib} from "./utils/FixedPointMathLib.sol";

import "./Bond.sol";

/** 
    @title Bond Factory
    @author Arbor Finance
    @notice This factory contract issues new bond contracts.
    @dev This uses a cloneFactory to save on gas costs during deployment.
        See OpenZeppelin's "Clones" proxy.
*/
contract BondFactory is IBondFactory, AccessControl {
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    /// @notice Max length of the Bond.
    uint256 internal constant MAX_TIME_TO_MATURITY = 3650 days;

    /**
        @notice The max number of decimals for the paymentToken and
            collateralToken.
    */
    uint8 internal constant MAX_DECIMALS = 18;

    /// @notice The role required to issue bonds.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    /// @notice The role given to allowed tokens.
    bytes32 public constant ALLOWED_TOKEN = keccak256("ALLOWED_TOKEN");

    /// @inheritdoc IBondFactory
    address public immutable tokenImplementation;

    /// @inheritdoc IBondFactory
    mapping(address => bool) public isBond;

    /// @inheritdoc IBondFactory
    bool public isIssuerAllowListEnabled = true;

    /// @inheritdoc IBondFactory
    bool public isTokenAllowListEnabled = true;

    /**
        @dev If allow list is enabled, only allow-listed issuers are
            able to call functions.
    */
    modifier onlyIssuer() {
        if (isIssuerAllowListEnabled) {
            _checkRole(ISSUER_ROLE, _msgSender());
        }
        _;
    }

    /*
        When deployed, the deployer will be granted the DEFAULT_ADMIN_ROLE. This
        gives the ability to call `grantRole` to grant access to the ISSUER_ROLE
        as well as the ability to toggle if the allow list is enabled or not at
        any time.
    */
    constructor() {
        tokenImplementation = address(new Bond());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @inheritdoc IBondFactory
    function setIsIssuerAllowListEnabled(bool _isIssuerAllowListEnabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isIssuerAllowListEnabled = _isIssuerAllowListEnabled;
        emit IssuerAllowListEnabled(_isIssuerAllowListEnabled);
    }

    function setIsTokenAllowListEnabled(bool _isTokenAllowListEnabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isTokenAllowListEnabled = _isTokenAllowListEnabled;
        emit TokenAllowListEnabled(_isTokenAllowListEnabled);
    }

    /// @inheritdoc IBondFactory
    function createBond(
        string memory name,
        string memory symbol,
        uint256 maturity,
        address paymentToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 convertibleTokenAmount,
        uint256 bonds
    ) external onlyIssuer returns (address clone) {
        if (bonds == 0) {
            revert ZeroBondsToMint();
        }
        if (paymentToken == collateralToken) {
            revert TokensMustBeDifferent();
        }
        if (collateralTokenAmount < convertibleTokenAmount) {
            revert CollateralTokenAmountLessThanConvertibleTokenAmount();
        }
        if (
            maturity <= block.timestamp ||
            maturity > block.timestamp + MAX_TIME_TO_MATURITY
        ) {
            revert InvalidMaturity();
        }
        if (
            IERC20Metadata(paymentToken).decimals() > MAX_DECIMALS ||
            IERC20Metadata(collateralToken).decimals() > MAX_DECIMALS
        ) {
            revert TooManyDecimals();
        }
        if (isTokenAllowListEnabled) {
            _checkRole(ALLOWED_TOKEN, paymentToken);
            _checkRole(ALLOWED_TOKEN, collateralToken);
        }

        clone = Clones.clone(tokenImplementation);

        isBond[clone] = true;
        uint256 collateralRatio = collateralTokenAmount.divWadDown(bonds);
        uint256 convertibleRatio = convertibleTokenAmount.divWadDown(bonds);
        _deposit(_msgSender(), clone, collateralToken, collateralTokenAmount);

        Bond(clone).initialize(
            name,
            symbol,
            _msgSender(),
            maturity,
            paymentToken,
            collateralToken,
            collateralRatio,
            convertibleRatio,
            bonds
        );

        emit BondCreated(
            clone,
            name,
            symbol,
            _msgSender(),
            maturity,
            paymentToken,
            collateralToken,
            collateralTokenAmount,
            convertibleTokenAmount,
            bonds
        );
    }

    function _deposit(
        address owner,
        address clone,
        address collateralToken,
        uint256 collateralToDeposit
    ) internal {
        IERC20Metadata(collateralToken).safeTransferFrom(
            owner,
            clone,
            collateralToDeposit
        );
        uint256 collateralInContract = IERC20Metadata(collateralToken)
            .balanceOf(clone);

        /*
            For a valid deposit, the balance of collateralToken in the clone
            at initialization must be at least the collateralToDeposit. This
            ensures that the bonds minted are all at least backed by the 
            appropriate collateral ratio. There is a chance the bond already has
            been given some amount of the tokens due to deterministic contract
            creation. This check therefore allows an excess of tokens, but in
            the case of a token taking a fee, will disallow creation if there
            is an insufficient amount.
        */
        if (collateralToDeposit > collateralInContract) {
            revert InvalidDeposit();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*      -.:````:::..        Arbor allows DAOs and other on-chain        .A
      /`:``-..-`   ..:.     entities to borrow stablecoins using       .AAA:
   ./`.:       \:``   :.    their tokens as collateral with fixed    .AAAAAA:
 ./`::`          \.--`` :.       rates and no liquidations.       .:AA.:AAAA:
./_.::            \.    .:                                       :AA..AAAAAA:
||  ::             |--``::.                                     :AA..AAAAAAA:
||_ ::             |.___.::                        ...         :AA..AAAAAAA`
|| `::             ||`|`:::                   .:AAAAAAAAA:.    .A..AAAAAAA`
||_\::             || | |::                  .AAAAAAAAAAAAAAA:  A..AAAA`
|| `::             ||\|/|::                .AAAAA.  AAAAAAAAAA:.:.``
||_\::             || | |::               .AAAAAAA```..........`:`..AA.
|| `:: An Arbor to ||/|\|::                    ``AAAAAAAAAAAAA` .AA..AAA.
||_\::  help DAOs  || | |::                          ``````     AAAA..ABG.
|| `::    Grow     ||\|/|::                                    .AAAAA..AAA.
||_\::             || | |::      For more information about    .AAAAAAA.AA.
|| `::             ||/|\|::         Arbor Finance, visit        .AAAAAAA.AA.
||_\::             ||_  |::         https://arbor.garden         .AAAAAA:AA.
`` `::                `` ::                                        .AAAAAAAA.
    ::                   ::                                            .AAAAA.
    ::                      Authors: Bookland Luckyrobot Namaskar          `*/

pragma solidity 0.8.9;

interface IBondFactory {
    /**
        @notice Emitted when the restriction of bond creation to allow-listed
            accounts is toggled on or off.
        @param isIssuerAllowListEnabled The new state of the allow list.
    */
    event IssuerAllowListEnabled(bool isIssuerAllowListEnabled);

    /**
        @notice Emitted when the restriction of collateralToken and paymentToken
            to allow-listed tokens is toggled on or off.
        @param isTokenAllowListEnabled The new state of the allow list.
    */
    event TokenAllowListEnabled(bool isTokenAllowListEnabled);

    /**
        @notice Emitted when a new bond is created.
        @param newBond The address of the newly deployed bond.
        @param name Passed into the ERC20 token to define the name.
        @param symbol Passed into the ERC20 token to define the symbol.
        @param owner Ownership of the created Bond is transferred to this
            address by way of _transferOwnership and tokens are minted to this
            address. See `initialize` in `Bond`.
        @param maturity The timestamp at which the Bond will mature.
        @param paymentToken The ERC20 token address the Bond is redeemable for.
        @param collateralToken The ERC20 token address the Bond is backed by.
        @param collateralTokenAmount The amount of collateral tokens per bond.
        @param convertibleTokenAmount The amount of convertible tokens per bond.
        @param bonds The amount of bond shares to give to the owner during the
            one-time mint during the `Bond`'s `initialize`.
    */
    event BondCreated(
        address newBond,
        string name,
        string symbol,
        address indexed owner,
        uint256 maturity,
        address indexed paymentToken,
        address indexed collateralToken,
        uint256 collateralTokenAmount,
        uint256 convertibleTokenAmount,
        uint256 bonds
    );

    /// @notice Fails if the collateralToken takes a fee.
    error InvalidDeposit();

    /// @notice Decimals with more than 18 digits are not supported.
    error TooManyDecimals();

    /// @notice Maturity date is not valid.
    error InvalidMaturity();

    /// @notice There must be more collateralTokens than convertibleTokens.
    error CollateralTokenAmountLessThanConvertibleTokenAmount();

    /// @notice Bonds must be minted during initialization.
    error ZeroBondsToMint();

    /// @notice The paymentToken and collateralToken must be different.
    error TokensMustBeDifferent();

    /**
        @notice Creates a new Bond. The calculated ratios are rounded down.
        @param name Passed into the ERC20 token to define the name.
        @param symbol Passed into the ERC20 token to define the symbol.
        @param maturity The timestamp at which the Bond will mature.
        @param paymentToken The ERC20 token address the Bond is redeemable for.
        @param collateralToken The ERC20 token address the Bond is backed by.
        @param collateralTokenAmount The amount of collateral tokens per bond.
        @param convertibleTokenAmount The amount of convertible tokens per bond.
        @param bonds The amount of Bonds given to the owner during the one-time
            mint during the `Bond`'s `initialize`.
        @dev This uses a clone to save on deployment costs which adds a slight
            overhead when users interact with the bonds, but also saves on gas
            during every deployment. Emits `BondCreated` event.
        @return clone The address of the newly created Bond.
    */
    function createBond(
        string memory name,
        string memory symbol,
        uint256 maturity,
        address paymentToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 convertibleTokenAmount,
        uint256 bonds
    ) external returns (address clone);

    /**  
        @notice If enabled, issuance is restricted to those with ISSUER_ROLE.
        @dev Emits `IssuerAllowListEnabled` event.
        @return isEnabled Whether or not the `ISSUER_ROLE` will be checked when
            creating new bonds.
    */
    function isIssuerAllowListEnabled() external view returns (bool isEnabled);

    /**  
        @notice If enabled, tokens used as paymentToken and collateralToken are
            restricted to those with the ALLOWED_TOKEN role.
        @dev Emits `TokenAllowListEnabled` event.
        @return isEnabled Whether or not the collateralToken and paymentToken
            are checked for the `ALLOWED_TOKEN` role when creating new bonds.
    */
    function isTokenAllowListEnabled() external view returns (bool isEnabled);

    /**
        @notice Returns whether or not the given address key is a bond created
            by this Bond factory.
        @dev This mapping is used to check if a bond was issued by this contract
            on-chain. For example, if we want to make a new contract that
            accepts any issued Bonds and exchanges them for new Bonds, the
            exchange contract would need a way to know that the Bonds are owned
            by this contract.
    */
    function isBond(address) external view returns (bool);

    /**
        @notice Sets the state of bond restriction to allow-listed accounts.
        @param _isIssuerAllowListEnabled If the issuer allow list should be
            enabled or not.
        @dev Must be called by the current owner.
    */
    function setIsIssuerAllowListEnabled(bool _isIssuerAllowListEnabled)
        external;

    /**
        @notice Sets the state of token restriction to the list of allowed
            tokens.
        @param _isTokenAllowListEnabled If the token allow list should be
            enabled or not.
        @dev Must be called by the current owner.
    */
    function setIsTokenAllowListEnabled(bool _isTokenAllowListEnabled) external;

    /**
        @notice Address where the bond implementation contract is stored.
        @dev This is needed since we are using a clone proxy.
        @return The implementation address.
    */
    function tokenImplementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*      -.:````:::..        Arbor allows DAOs and other on-chain        .A
      /`:``-..-`   ..:.     entities to borrow stablecoins using       .AAA:
   ./`.:       \:``   :.    their tokens as collateral with fixed    .AAAAAA:
 ./`::`          \.--`` :.       rates and no liquidations.       .:AA.:AAAA:
./_.::            \.    .:                                       :AA..AAAAAA:
||  ::             |--``::.                                     :AA..AAAAAAA:
||_ ::             |.___.::                        ...         :AA..AAAAAAA`
|| `::             ||`|`:::                   .:AAAAAAAAA:.    .A..AAAAAAA`
||_\::             || | |::                  .AAAAAAAAAAAAAAA:  A..AAAA`
|| `::             ||\|/|::                .AAAAA.  AAAAAAAAAA:.:.``
||_\::             || | |::               .AAAAAAA```..........`:`..AA.
|| `:: An Arbor to ||/|\|::                    ``AAAAAAAAAAAAA` .AA..AAA.
||_\::  help DAOs  || | |::                          ``````     AAAA..ABG.
|| `::    Grow     ||\|/|::                                    .AAAAA..AAA.
||_\::             || | |::      For more information about    .AAAAAAA.AA.
|| `::             ||/|\|::         Arbor Finance, visit        .AAAAAAA.AA.
||_\::             ||_  |::         https://arbor.garden         .AAAAAA:AA.
`` `::                `` ::                                        .AAAAAAAA.
    ::                   ::                                            .AAAAA.
    ::                      Authors: Bookland Luckyrobot Namaskar          `*/

pragma solidity 0.8.9;

import {IBond} from "./interfaces/IBond.sol";

import {ERC20BurnableUpgradeable, IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {FixedPointMathLib} from "./utils/FixedPointMathLib.sol";

/**
    @title Bond
    @author Arbor Finance
    @notice A custom ERC20 token that can be used to issue bonds.
    @notice The contract handles issuance, payment, conversion, and redemption.
    @dev External calls to tokens used for collateral and payment are used
        throughout to transfer and check balances. There is risk that these
        are non-standard and should be carefully inspected before being trusted.
        The contract does not inherit from ERC20Upgradeable or Initializable
        since ERC20BurnableUpgradeable inherits from them. Additionally,
        throughout the contract some state variables are redefined to save
        an extra SLOAD.
*/
contract Bond is
    IBond,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    /**
        @notice A period of time after maturity in which bond redemption is
            disallowed for non fully paid bonds. This restriction is lifted 
            once the grace period has ended. The issuer has the ability to
            pay during this time to fully pay the bond. 
    */
    uint256 internal constant GRACE_PERIOD = 7 days;

    /// @inheritdoc IBond
    uint256 public maturity;

    /// @inheritdoc IBond
    address public paymentToken;

    /// @inheritdoc IBond
    address public collateralToken;

    /// @inheritdoc IBond
    uint256 public collateralRatio;

    /// @inheritdoc IBond
    uint256 public convertibleRatio;

    /**
        @dev Confirms the Bond has not yet matured. This is used on the
            `convert` function because bond shares are convertible only before
            maturity has been reached.
    */
    modifier beforeMaturity() {
        if (isMature()) {
            revert BondPastMaturity();
        }
        _;
    }

    /**
        @dev Confirms that the Bond is after the grace period or has been paid.
            This is used in the `redeem` function because bond shares can be
            redeemed when the Bond is fully paid or past the grace period.
    */
    modifier afterGracePeriodOrPaid() {
        if (isAfterGracePeriod() || amountUnpaid() == 0) {
            _;
        } else {
            revert BondBeforeGracePeriodAndNotPaid();
        }
    }

    constructor() {
        /*
            Since the constructor is executed only when creating the
            implementation contract, prevent its re-initialization.
        */
        _disableInitializers();
    }

    /// @inheritdoc IBond
    function initialize(
        string memory bondName,
        string memory bondSymbol,
        address bondOwner,
        uint256 _maturity,
        address _paymentToken,
        address _collateralToken,
        uint256 _collateralRatio,
        uint256 _convertibleRatio,
        uint256 maxSupply
    ) external initializer {
        // Safety checks: Ensure multiplication can not overflow uint256.
        maxSupply * maxSupply;
        maxSupply * _collateralRatio;
        maxSupply * _convertibleRatio;

        __ERC20_init(bondName, bondSymbol);

        // Transfer ownership to the address initializing this contract.
        _transferOwnership(bondOwner);

        maturity = _maturity;
        paymentToken = _paymentToken;
        collateralToken = _collateralToken;
        collateralRatio = _collateralRatio;
        convertibleRatio = _convertibleRatio;

        // Transfer all bond shares to the address initializing this contract.
        _mint(bondOwner, maxSupply);
    }

    /// @inheritdoc IBond
    function convert(uint256 bonds) external nonReentrant beforeMaturity {
        if (bonds == 0) {
            revert ZeroAmount();
        }

        // Calculate how many convertible tokens the bond shares convert into.
        uint256 convertibleTokensToSend = previewConvertBeforeMaturity(bonds);
        if (convertibleTokensToSend == 0) {
            revert ZeroAmount();
        }

        /*
            Burn the callers bond shares which reduces the required
            paymentAmount for the borrower.
        */
        _burn(_msgSender(), bonds);

        address _collateralToken = collateralToken;

        // Transfer the correct amount of collateralTokens to the caller.
        IERC20Metadata(_collateralToken).safeTransfer(
            _msgSender(),
            convertibleTokensToSend
        );

        emit Convert(
            _msgSender(),
            _collateralToken,
            bonds,
            convertibleTokensToSend
        );
    }

    /// @inheritdoc IBond
    function pay(uint256 amount) external {
        if (amountUnpaid() == 0) {
            revert PaymentAlreadyMet();
        }
        if (amount == 0) {
            revert ZeroAmount();
        }

        // Calculate balance before transfer for fee-on-transfer tokens.
        uint256 balanceBefore = IERC20Metadata(paymentToken).balanceOf(
            address(this)
        );

        // Transfer tokens from caller to the Bond contract.
        IERC20Metadata(paymentToken).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
        uint256 balanceAfter = IERC20Metadata(paymentToken).balanceOf(
            address(this)
        );

        /* 
            Compare balanceAfter and balanceBefore to ensure the actual amount
            transferred is emitted for fee-on-transfer tokens. 
        */
        emit Payment(_msgSender(), balanceAfter - balanceBefore);
    }

    /// @inheritdoc IBond
    function gracePeriodEnd()
        public
        view
        returns (uint256 gracePeriodEndTimestamp)
    {
        gracePeriodEndTimestamp = maturity + GRACE_PERIOD;
    }

    /// @inheritdoc IBond
    function redeem(uint256 bonds)
        external
        nonReentrant
        afterGracePeriodOrPaid
    {
        if (bonds == 0) {
            revert ZeroAmount();
        }

        /* 
            Calculate the amount of paymentTokens and collateralTokens that
            should be transferred on redeem. The tokens returned will change
            based on the state of the bond. 
        */
        (
            uint256 paymentTokensToSend,
            uint256 collateralTokensToSend
        ) = previewRedeemAtMaturity(bonds);

        if (paymentTokensToSend == 0 && collateralTokensToSend == 0) {
            revert ZeroAmount();
        }

        /*
            Burn the callers bond shares. They will be sent paymentTokens
            and/or collateralTokens in exchange for their bond shares. 
        */
        _burn(_msgSender(), bonds);

        address _paymentToken = paymentToken;
        address _collateralToken = collateralToken;

        /*
            Transfer the caller paymentTokens. These will only be sent
            in Paid, PaidEarly, or Defaulted & Partially Paid Bond states.
        */
        if (paymentTokensToSend != 0) {
            IERC20Metadata(_paymentToken).safeTransfer(
                _msgSender(),
                paymentTokensToSend
            );
        }

        /*
            Transfer the caller collateralTokens. These will only be sent if the
            Bond is in a Defaulted state.
        */
        if (collateralTokensToSend != 0) {
            IERC20Metadata(_collateralToken).safeTransfer(
                _msgSender(),
                collateralTokensToSend
            );
        }

        emit Redeem(
            _msgSender(),
            _paymentToken,
            _collateralToken,
            bonds,
            paymentTokensToSend,
            collateralTokensToSend
        );
    }

    /// @inheritdoc IBond
    function withdrawExcessCollateral(uint256 amount, address receiver)
        external
        nonReentrant
        onlyOwner
    {
        /*
            Ensure the amount being withdrawn is not greater than the excess
            collateral in the contract.
        */
        if (amount > previewWithdrawExcessCollateral()) {
            revert NotEnoughCollateral();
        }

        address _collateralToken = collateralToken;

        // Transfer excess collateral to the receiver.
        IERC20Metadata(_collateralToken).safeTransfer(receiver, amount);

        emit CollateralWithdraw(
            _msgSender(),
            receiver,
            _collateralToken,
            amount
        );
    }

    /// @inheritdoc IBond
    function withdrawExcessPayment(address receiver)
        external
        nonReentrant
        onlyOwner
    {
        uint256 overpayment = previewWithdrawExcessPayment();

        /*
            Ensure the amount being withdrawn is not greater
            than the excess paymentToken in the contract.
        */
        if (overpayment <= 0) {
            revert NoPaymentToWithdraw();
        }

        address _paymentToken = paymentToken;

        // Transfers excess paymentToken to the receiver.
        IERC20Metadata(_paymentToken).safeTransfer(receiver, overpayment);

        emit ExcessPaymentWithdraw(
            _msgSender(),
            receiver,
            _paymentToken,
            overpayment
        );
    }

    /// @inheritdoc IBond
    function sweep(IERC20Metadata sweepingToken, address receiver)
        external
        onlyOwner
    {
        /*
            To protect against tokens that may proxy transfers through different
            addresses, compare the balances before and after.
        */
        uint256 paymentTokenBalanceBefore = IERC20Metadata(paymentToken)
            .balanceOf(address(this));
        uint256 collateralTokenBalanceBefore = IERC20Metadata(collateralToken)
            .balanceOf(address(this));

        uint256 sweepingTokenBalance = sweepingToken.balanceOf(address(this));

        if (sweepingTokenBalance == 0) {
            revert ZeroAmount();
        }

        sweepingToken.safeTransfer(receiver, sweepingTokenBalance);

        uint256 paymentTokenBalanceAfter = IERC20Metadata(paymentToken)
            .balanceOf(address(this));
        uint256 collateralTokenBalanceAfter = IERC20Metadata(collateralToken)
            .balanceOf(address(this));

        // Revert if trying to sweep collateralToken or paymentToken.
        if (
            paymentTokenBalanceBefore != paymentTokenBalanceAfter ||
            collateralTokenBalanceBefore != collateralTokenBalanceAfter
        ) {
            revert SweepDisallowedForToken();
        }

        emit TokenSweep(
            _msgSender(),
            receiver,
            sweepingToken,
            sweepingTokenBalance
        );
    }

    /// @inheritdoc IBond
    function previewConvertBeforeMaturity(uint256 bonds)
        public
        view
        returns (uint256 collateralTokens)
    {
        collateralTokens = bonds.mulWadDown(convertibleRatio);
    }

    /// @inheritdoc IBond
    function previewRedeemAtMaturity(uint256 bonds)
        public
        view
        returns (uint256 paymentTokensToSend, uint256 collateralTokensToSend)
    {
        uint256 bondSupply = totalSupply();
        if (bondSupply == 0) {
            return (0, 0);
        }

        /* 
            PaidAmount can never be greater than the total number of bond
            shares. For each share, 1 payment token is due at maturity.
            If the Bond is fully paid, paidAmount will be equal to the number of
            outstanding bond shares. If the Bond has not been fully paid, the
            paidAmount will be equal to the paymentTokens in the contract.
        */
        uint256 paidAmount = amountUnpaid() == 0
            ? bondSupply
            : paymentBalance();

        /*
            Paid/PaidEarly: 100% paymentTokens    
            Defaulted: 0 paymentTokens
            Defaulted & Partially Paid: pro-rata amount of paymentTokens
         */
        paymentTokensToSend = bonds.mulDivDown(paidAmount, bondSupply);

        uint256 nonPaidAmount = bondSupply - paidAmount;

        /*
            Paid/PaidEarly: 0 collateralTokens    
            Defaulted: 100% collateralTokens
            Defaulted & PartiallyPaid: pro-rata amount of collateralTokens
         */
        collateralTokensToSend = collateralRatio.mulWadDown(
            bonds.mulDivDown(nonPaidAmount, bondSupply)
        );
    }

    /// @inheritdoc IBond
    function previewWithdrawExcessCollateral()
        public
        view
        returns (uint256 collateralTokens)
    {
        collateralTokens = previewWithdrawExcessCollateralAfterPayment(0);
    }

    /// @inheritdoc IBond
    function previewWithdrawExcessCollateralAfterPayment(uint256 payment)
        public
        view
        returns (uint256 collateralTokens)
    {
        uint256 tokensCoveredByPayment = paymentBalance() + payment;
        uint256 bondSupply = totalSupply();

        uint256 collateralTokensRequired;

        /*
            Calculate number of collateralTokens that are required to stay 
            in the contract using the collateralRatio.
        */
        if (tokensCoveredByPayment < bondSupply) {
            collateralTokensRequired = (bondSupply - tokensCoveredByPayment)
                .mulWadUp(collateralRatio);
        }

        /*
            Calculate number of collateralTokens that are required to stay 
            in the contract using the convertibleRatio.
        */
        uint256 convertibleTokensRequired = bondSupply.mulWadUp(
            convertibleRatio
        );

        uint256 totalRequiredCollateral;

        /*
            Calculate how many collateralTokens must stay in the contract 
            for the current state of the bond. 
        */
        if (amountUnpaid() == 0) {
            /*
                The Bond has been paid. If the Bond is also mature, the Bond is
                in a Paid sate and 0 collateral is required. If the Bond is not
                mature, the Bond is in a PaidEarly state and enough collateral
                is required to cover the convertible tokens of the outstanding
                bond shares.
            */
            totalRequiredCollateral = isMature()
                ? 0
                : convertibleTokensRequired;
        } else {
            /*
                The Bond has not yet been paid. If the bond is mature, the Bond
                is in a Defaulted state and must have enough collateral to cover
                the collateral tokens of the outstanding bond shares. If the
                Bond is not yet mature, the Bond is in an Active state and needs
                to have enough collateral to cover either the amount of 
                convertible tokens or collateral tokens of the outstanding bond
                shares. Whichever is greater. 
            */
            totalRequiredCollateral = isMature()
                ? collateralTokensRequired
                : _max(convertibleTokensRequired, collateralTokensRequired);
        }
        uint256 _collateralBalance = collateralBalance();
        if (totalRequiredCollateral >= _collateralBalance) {
            return 0;
        }
        // Return the amount of collateral that is able to be withdrawn.
        collateralTokens = _collateralBalance - totalRequiredCollateral;
    }

    /// @inheritdoc IBond
    function previewWithdrawExcessPayment()
        public
        view
        returns (uint256 paymentTokens)
    {
        uint256 bondSupply = totalSupply();
        uint256 _paymentBalance = paymentBalance();

        if (bondSupply >= _paymentBalance) {
            return 0;
        }
        // Return the amount of paymentTokens above the required amount.
        paymentTokens = _paymentBalance - bondSupply;
    }

    /// @inheritdoc IBond
    function collateralBalance()
        public
        view
        returns (uint256 collateralTokens)
    {
        collateralTokens = IERC20Metadata(collateralToken).balanceOf(
            address(this)
        );
    }

    /// @inheritdoc IBond
    function paymentBalance() public view returns (uint256 paymentTokens) {
        paymentTokens = IERC20Metadata(paymentToken).balanceOf(address(this));
    }

    /// @inheritdoc IBond
    function amountUnpaid() public view returns (uint256 paymentTokens) {
        uint256 bondSupply = totalSupply();
        uint256 _paymentBalance = paymentBalance();

        if (bondSupply <= _paymentBalance) {
            return 0;
        }

        paymentTokens = bondSupply - _paymentBalance;
    }

    /// @inheritdoc IBond
    function isMature() public view returns (bool isBondMature) {
        isBondMature = block.timestamp >= maturity;
    }

    /// @inheritdoc IERC20MetadataUpgradeable
    function decimals() public view override returns (uint8) {
        return IERC20Metadata(paymentToken).decimals();
    }

    /**
        @notice Checks if the grace period timestamp has passed.
        @return isGracePeriodOver Whether or not the Bond is past the
            grace period.
    */
    function isAfterGracePeriod()
        internal
        view
        returns (bool isGracePeriodOver)
    {
        isGracePeriodOver = block.timestamp >= gracePeriodEnd();
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only

/*      -.:````:::..        Arbor allows DAOs and other on-chain        .A
      /`:``-..-`   ..:.     entities to borrow stablecoins using       .AAA:
   ./`.:       \:``   :.    their tokens as collateral with fixed    .AAAAAA:
 ./`::`          \.--`` :.       rates and no liquidations.       .:AA.:AAAA:
./_.::            \.    .:                                       :AA..AAAAAA:
||  ::             |--``::.                                     :AA..AAAAAAA:
||_ ::             |.___.::                        ...         :AA..AAAAAAA`
|| `::             ||`|`:::                   .:AAAAAAAAA:.    .A..AAAAAAA`
||_\::             || | |::                  .AAAAAAAAAAAAAAA:  A..AAAA`
|| `::             ||\|/|::                .AAAAA.  AAAAAAAAAA:.:.``
||_\::             || | |::               .AAAAAAA```..........`:`..AA.
|| `:: An Arbor to ||/|\|::                    ``AAAAAAAAAAAAA` .AA..AAA.
||_\::  help DAOs  || | |::                          ``````     AAAA..ABG.
|| `::    Grow     ||\|/|::                                    .AAAAA..AAA.
||_\::             || | |::      For more information about    .AAAAAAA.AA.
|| `::             ||/|\|::         Arbor Finance, visit        .AAAAAAA.AA.
||_\::             ||_  |::         https://arbor.garden         .AAAAAA:AA.
`` `::                `` ::                                        .AAAAAAAA.
    ::                   ::                                            .AAAAA.
    ::                      Authors: Bookland Luckyrobot Namaskar          `*/

pragma solidity 0.8.9;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBond {
    /// @notice Operation restricted because the Bond has matured.
    error BondPastMaturity();

    /**
        @notice Bond redemption is impossible because the grace period has not
            yet passed and the bond has not been fully paid.
    */
    error BondBeforeGracePeriodAndNotPaid();

    /// @notice Attempted to pay after payment was met.
    error PaymentAlreadyMet();

    /// @notice Attempted to sweep a token used in the contract.
    error SweepDisallowedForToken();

    /// @notice Attempted to perform an action that would do nothing.
    error ZeroAmount();

    /// @notice Attempted to withdraw with no excess payment in the contract.
    error NoPaymentToWithdraw();

    /// @notice Attempted to withdraw more collateral than available.
    error NotEnoughCollateral();

    /**
        @notice Emitted when bond shares are converted by a Bond holder.
        @param from The address converting their tokens.
        @param collateralToken The address of the collateralToken.
        @param amountOfBondsConverted The number of burnt bond shares.
        @param amountOfCollateralTokens The number of collateralTokens received.
    */
    event Convert(
        address indexed from,
        address indexed collateralToken,
        uint256 amountOfBondsConverted,
        uint256 amountOfCollateralTokens
    );

    /**
        @notice Emitted when collateral is withdrawn.
        @param from The address withdrawing the collateralTokens.
        @param receiver The address receiving the collateralTokens.
        @param token The address of the collateralToken.
        @param amount The number of collateralTokens withdrawn.
    */
    event CollateralWithdraw(
        address indexed from,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
        @notice Emitted when a portion of the Bond's principal is paid.
        @param from The address depositing payment.
        @param amount Amount paid.
        @dev The amount could be incorrect if the token takes a fee on transfer. 
    */
    event Payment(address indexed from, uint256 amount);

    /**
        @notice Emitted when a bond share is redeemed.
        @param from The Bond holder whose bond shares are burnt.
        @param paymentToken The address of the paymentToken.
        @param collateralToken The address of the collateralToken.
        @param amountOfBondsRedeemed The number of bond shares burned for
            redemption.
        @param amountOfPaymentTokensReceived The number of paymentTokens.
        @param amountOfCollateralTokens The number of collateralTokens.
    */
    event Redeem(
        address indexed from,
        address indexed paymentToken,
        address indexed collateralToken,
        uint256 amountOfBondsRedeemed,
        uint256 amountOfPaymentTokensReceived,
        uint256 amountOfCollateralTokens
    );

    /**
        @notice Emitted when payment over the required amount is withdrawn.
        @param from The caller withdrawing the excess payment amount.
        @param receiver The address receiving the paymentTokens.
        @param token The address of the paymentToken being withdrawn.
        @param amount The amount of paymentToken withdrawn.
    */
    event ExcessPaymentWithdraw(
        address indexed from,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
        @notice Emitted when a token is swept by the contract owner.
        @param from The owner's address.
        @param receiver The address receiving the swept tokens.
        @param token The address of the token that was swept.
        @param amount The number of tokens swept.
    */
    event TokenSweep(
        address from,
        address indexed receiver,
        IERC20Metadata token,
        uint256 amount
    );

    /**
        @notice The amount of paymentTokens required to fully pay the contract.
        @return paymentTokens The number of paymentTokens unpaid.
    */
    function amountUnpaid() external view returns (uint256 paymentTokens);

    /**
        @notice The external balance of the ERC20 collateral token.
        @return collateralTokens The number of collateralTokens in the contract.
    */
    function collateralBalance()
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice The number of collateralTokens per Bond.
        @dev This ratio is calculated as a deviation from 1-to-1 multiplied by
            the decimals of the collateralToken. See BondFactory's `CreateBond`.
        @return The number of collateralTokens per Bond.
    */
    function collateralRatio() external view returns (uint256);

    /**
        @notice The ERC20 token used as collateral backing the bond.
        @return The collateralToken's address.
    */
    function collateralToken() external view returns (address);

    /**
        @notice For convertible Bonds (ones with a convertibilityRatio > 0),
            the Bond holder may convert their bond to underlying collateral at
            the convertibleRatio. The bond must also have not past maturity
            for this to be possible.
        @dev Emits `Convert` event.
        @param bonds The number of bonds which will be burnt and converted
            into the collateral at the convertibleRatio.
    */
    function convert(uint256 bonds) external;

    /**
        @notice The number of convertibleTokens the bonds will convert into.
        @dev This ratio is calculated as a deviation from 1-to-1 multiplied by
            the decimals of the collateralToken. See BondFactory's `CreateBond`.
            The "convertibleTokens" are a subset of the collateralTokens, based
            on this ratio. If this ratio is 0, the bond is not convertible.
        @return The number of convertibleTokens per Bond.
    */
    function convertibleRatio() external view returns (uint256);

    /**
        @notice This one-time setup initiated by the BondFactory initializes the
            Bond with the given configuration.
        @dev New Bond contract deployed via clone. See `BondFactory`.
        @dev During initialization, __Ownable_init is not called because the
            owner would be set to the BondFactory's Address. Additionally,
            __ERC20Burnable_init is not called because it generates an empty
            function.
        @param bondName Passed into the ERC20 token to define the name.
        @param bondSymbol Passed into the ERC20 token to define the symbol.
        @param bondOwner Ownership of the created Bond is transferred to this
            address by way of _transferOwnership and also the address that
            tokens are minted to. See `initialize` in `Bond`.
        @param _maturity The timestamp at which the Bond will mature.
        @param _paymentToken The ERC20 token address the Bond is redeemable for.
        @param _collateralToken The ERC20 token address the Bond is backed by.
        @param _collateralRatio The amount of collateral tokens per bond.
        @param _convertibleRatio The amount of convertible tokens per bond.
        @param maxSupply The amount of Bonds given to the owner during the one-
            time mint during this initialization.
    */
    function initialize(
        string memory bondName,
        string memory bondSymbol,
        address bondOwner,
        uint256 _maturity,
        address _paymentToken,
        address _collateralToken,
        uint256 _collateralRatio,
        uint256 _convertibleRatio,
        uint256 maxSupply
    ) external;

    /**
        @notice Checks if the maturity timestamp has passed.
        @return isBondMature Whether or not the Bond has reached maturity.
    */
    function isMature() external view returns (bool isBondMature);

    /**
        @notice A date set at Bond creation when the Bond will mature.
        @return The maturity date as a timestamp.
    */
    function maturity() external view returns (uint256);

    /**
        @notice One week after the maturity date. Bond collateral can be 
            redeemed after this date.
        @return gracePeriodEndTimestamp The grace period end date as 
            a timestamp. This is always one week after the maturity date
    */
    function gracePeriodEnd()
        external
        view
        returns (uint256 gracePeriodEndTimestamp);

    /**
        @notice Allows the owner to pay the bond by depositing paymentTokens.
        @dev Emits `Payment` event.
        @param amount The number of paymentTokens to deposit.
    */
    function pay(uint256 amount) external;

    /**
        @notice Gets the external balance of the ERC20 paymentToken.
        @return paymentTokens The number of paymentTokens in the contract.
    */
    function paymentBalance() external view returns (uint256 paymentTokens);

    /**
        @notice This is the token the borrower deposits into the contract and
            what the Bond holders will receive when redeemed.
        @return The address of the token.
    */
    function paymentToken() external view returns (address);

    /**
        @notice Before maturity, if the given bonds are converted, this would be
            the number of collateralTokens received. This function rounds down
            the number of returned collateral.
        @param bonds The number of bond shares burnt and converted into
            collateralTokens.
        @return collateralTokens The number of collateralTokens the Bonds would
            be converted into.
    */
    function previewConvertBeforeMaturity(uint256 bonds)
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice At maturity, if the given bond shares are redeemed, this would
            be the number of collateralTokens and paymentTokens received by the
            bond holder. The number of paymentTokens to receive is rounded down.
        @param bonds The number of Bonds to burn and redeem for tokens.
        @return paymentTokensToSend The number of paymentTokens that the bond
            shares would be redeemed for.
        @return collateralTokensToSend The number of collateralTokens that would
            be redeemed for.
    */
    function previewRedeemAtMaturity(uint256 bonds)
        external
        view
        returns (uint256 paymentTokensToSend, uint256 collateralTokensToSend);

    /** 
        @notice The number of collateralTokens that the owner would be able to 
            withdraw from the contract. This function rounds up the number 
            of collateralTokens required in the contract and therefore may round
            down the amount received.
        @dev This function calculates the amount of collateralTokens that are
            able to be withdrawn by the owner. The amount of tokens can
            increase when Bonds are burnt and converted as well when payment is
            made. Each Bond is covered by a certain amount of collateral to
            the collateralRatio. In addition to covering the collateralRatio,
            convertible Bonds (ones with a convertibleRatio greater than 0) must
            have enough convertibleTokens in the contract to the totalSupply of
            Bonds as well. That means even if all of the Bonds were covered by
            payment, there must still be enough collateral in the contract to
            cover the portion of collateral that would be required to convert
            the totalSupply of outstanding Bonds. At the maturity date, however,
            all collateral will be able to be withdrawn as the Bond would no
            longer be convertible.

            There are the following scenarios:
            bond IS paid AND mature (Paid)
                to cover collateralRatio: 0
                to cover convertibleRatio: 0

            bond IS paid AND NOT mature (PaidEarly)
                to cover collateralRatio: 0
                to cover convertibleRatio: totalSupply * convertibleRatio

            * totalUncoveredSupply: Bonds not covered by paymentTokens *

            bond is NOT paid AND NOT mature (Active)
                to cover collateralRatio: totalUncoveredSupply * collateralRatio
                to cover convertibleRatio: totalSupply * convertibleRatio

            bond is NOT paid AND mature (Defaulted)
                to cover collateralRatio: totalUncoveredSupply * collateralRatio
                to cover convertibleRatio: 0
        @param payment The number of paymentTokens to add when previewing a
            withdraw.
        @return collateralTokens The number of collateralTokens that would be
            withdrawn.
     */
    function previewWithdrawExcessCollateralAfterPayment(uint256 payment)
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice The number of collateralTokens that the owner would be able to 
            withdraw from the contract. This does not take into account an
            amount of payment like `previewWithdrawExcessCollateralAfterPayment`
            does. See that function for more information.
        @dev Calls `previewWithdrawExcessCollateralAfterPayment` with a payment
            amount of 0.
        @return collateralTokens The number of collateralTokens that would be
            withdrawn.
    */
    function previewWithdrawExcessCollateral()
        external
        view
        returns (uint256 collateralTokens);

    /**
        @notice The number of excess paymentTokens that the owner would be able
            to withdraw from the contract.
        @return paymentTokens The number of paymentTokens that would be
            withdrawn.
    */
    function previewWithdrawExcessPayment()
        external
        view
        returns (uint256 paymentTokens);

    /**
        @notice The Bond holder can burn bond shares in return for their portion
            of paymentTokens and collateralTokens backing the Bonds. These
            portions of tokens depends on the number of paymentTokens deposited.
            When the Bond is fully paid, redemption will result in all 
            paymentTokens. If the Bond has reached maturity without being fully
            paid, a portion of the collateralTokens will be available.
        @dev Emits Redeem event.
        @param bonds The number of bond shares to redeem and burn.
    */
    function redeem(uint256 bonds) external;

    /**
        @notice Sends ERC20 tokens to the owner that are in this contract.
        @dev The collateralToken and paymentToken cannot be swept. Emits 
            `TokenSweep` event.
        @param sweepingToken The ERC20 token to sweep and send to the receiver.
        @param receiver The address that is transferred the swept token.
    */
    function sweep(IERC20Metadata sweepingToken, address receiver) external;

    /**
        @notice The Owner may withdraw excess collateral from the Bond contract.
            The number of collateralTokens remaining in the contract must be
            enough to cover the total supply of Bonds in accordance to both the collateralRatio and convertibleRatio.
        @dev Emits `CollateralWithdraw` event.
        @param amount The number of collateralTokens to withdraw. Reverts if
            the amount is greater than available in the contract. 
        @param receiver The address transferred the excess collateralTokens.
    */
    function withdrawExcessCollateral(uint256 amount, address receiver)
        external;

    /**
        @notice The owner can withdraw any excess paymentToken in the contract.
        @param receiver The address that is transferred the excess paymentToken.
    */
    function withdrawExcessPayment(address receiver) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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