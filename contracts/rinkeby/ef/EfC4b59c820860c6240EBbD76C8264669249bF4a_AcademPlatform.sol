//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IACDM_token.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error Uregistered();
error SelfReffering();
error AlreadyRegistered();
error AlreadyStarted(string round);
error NotFinished(string round);
error AlreadyFinished(string round);
error AmountExeeded(uint256 amount0, uint256 amount1);

contract AcademPlatform is AccessControl {
    event SaleStarted(uint256 currentRound, uint256 timeStamp);
    event TradeStarted(uint256 currentRound, uint256 timeStamp);
    event OrderAdded(uint256 orderId, address orderOwner, uint256 amount, uint256 price);
    event OrderRemoved(uint256 orderId);
    event OrderRedeemed(uint256 orderId, address redeemer, uint256 amount, uint256 price);
    event BonusesChanged(uint16 saleLvl1, uint16 saleLvl2, uint16 tradeLvl1, uint16 tradeLvl2);

    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant CHAIR_MAN = keccak256("CHAIR_MAN");

    IACDM_token public acdmToken;

    uint16[] public bonuses;
    uint256 public roundTime;
    uint256 public currentRound = 0;
    uint256 public invDecimals;
    uint256 private orderId = 0;
    address public dao;

    mapping(address => User) public users;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => Order) public orders;
    
    struct Order {
        address user;
        uint256 amount;
        uint256 price;
        bool isActive;
    }

    struct Round {
        RoundState round;
        uint256 startTime;
        uint256 tokenMintCount;
        uint256 tokenPrice;
        uint256 tradedEthCount;
    }

    struct User {
        bool isUser;
        address payable referrer1;
        address payable referrer2;
    }

    enum RoundState { sale, trade }

    /*
     * Constructor
     * @param {address} daoAddress - Address of the DAO
     * @param {address} acdmAddress - Address of the ACDM token
     * @param {uint256} _roundTime - Period of the round
     */
    constructor(address daoAddress, address acdmAddress, uint256 _roundTime) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CHAIR_MAN, msg.sender);

        dao = daoAddress;
        acdmToken = IACDM_token(acdmAddress);
        roundTime = _roundTime * 1 days;
        invDecimals = (10**18/(10**acdmToken.decimals()));

        rounds[0].round = RoundState.trade;
        rounds[1].tokenPrice = 10 * invDecimals;
        rounds[0].tradedEthCount = 1 * 10**18;

        bonuses = new uint16[](4);
        bonuses[0] = 500;
        bonuses[1] = 300;
        bonuses[2] = 250;
        bonuses[3] = 250;
    }

    /*
     * Registers new user with referrer
     * @param {address payable} referrer - Referrer address
     */
    function register(address payable referrer) external {
        if(users[msg.sender].isUser) revert AlreadyRegistered();
        if(referrer == msg.sender) revert SelfReffering();
        if(!users[referrer].isUser) revert Uregistered();

        users[msg.sender] = User(true, referrer, users[referrer].referrer1);
    }
    
    /**
     * Registers new user
     */
    function register() external {
        if(users[msg.sender].isUser) revert AlreadyRegistered();
        users[msg.sender].isUser = true;
    }

    /**
     * Starts sale round, only chairman can call this function
     */
    function startSaleRound() external onlyRole(CHAIR_MAN){
        currentRound++;
        Round memory prevRound = rounds[currentRound-1];

        if(prevRound.round == RoundState.sale) revert AlreadyStarted("sale");
        if(prevRound.startTime + roundTime >= block.timestamp) revert NotFinished("trade");        
        
        rounds[currentRound] = Round(
            RoundState.sale,
            block.timestamp,
            prevRound.tradedEthCount / rounds[currentRound].tokenPrice, 
            rounds[currentRound].tokenPrice, 
            0
        );

        acdmToken.mint(address(this), rounds[currentRound].tokenMintCount);

        uint256 lastPrice = rounds[currentRound].tokenPrice / invDecimals;
        rounds[currentRound + 1].tokenPrice = ((((lastPrice * 103 + 400) * invDecimals) / 10**2) / invDecimals) * invDecimals;
        
        emit SaleStarted(currentRound, rounds[currentRound].startTime);
    }

    /**
     * Starts trade round, only chairman can call this function
     */
    function startTradeRound() external onlyRole(CHAIR_MAN){     
        if(rounds[currentRound].round == RoundState.trade) revert AlreadyStarted("trade");   
        if(rounds[currentRound].startTime + roundTime >= block.timestamp) revert NotFinished("sale");

        rounds[currentRound].startTime = block.timestamp;
        rounds[currentRound].round = RoundState.trade;

        emit TradeStarted(currentRound, rounds[currentRound].startTime);
    }
    
    /*
     * Buy ACDM tokens during sale round
     * @param {uint256} amount - Amount of tokens to buy
     */
    function buyACDM(uint256 amount) external payable {
        User memory user = users[msg.sender];

        if(!user.isUser) revert Uregistered();
        if(rounds[currentRound].round != RoundState.sale) revert NotFinished("trade");
        if(rounds[currentRound].startTime + roundTime < block.timestamp) revert AlreadyFinished("sale");
        if(rounds[currentRound].tokenMintCount < amount) revert AmountExeeded(rounds[currentRound].tokenMintCount, amount);

        uint256 price = rounds[currentRound].tokenPrice;
        if(msg.value < amount*price) revert AmountExeeded(msg.value, amount*price);

        if(user.referrer1 != address(0)){
            uint256 bonus = (amount*price*bonuses[0])/10000;
            user.referrer1.transfer(bonus);
        }
        if(user.referrer2 != address(0)){
            uint256 bonus = (amount*price*bonuses[1])/10000;
            user.referrer2.transfer(bonus);
        }

        rounds[currentRound].tokenMintCount -= amount;

        if(rounds[currentRound].tokenMintCount == 0){
            rounds[currentRound].startTime = 0;
        }

        acdmToken.transfer(msg.sender, amount);
    }

    /*
     * Add order for trade round
     * @param {uint256} amount - Amount of tokens to buy
     * @param {uint256} price - Price of the token
     */
    function addOrder(uint256 amount, uint256 price) external{
        if(!users[msg.sender].isUser) revert Uregistered();
        if(rounds[currentRound].round != RoundState.trade) revert NotFinished("sale");
        if(rounds[currentRound].startTime + roundTime < block.timestamp) revert AlreadyFinished("trade");
        if(acdmToken.balanceOf(msg.sender) < amount) revert AmountExeeded(acdmToken.balanceOf(msg.sender), amount);

        orders[orderId] = Order(msg.sender, amount, price, true);

        acdmToken.transferFrom(msg.sender, address(this), amount);

        emit OrderAdded(orderId, msg.sender, amount, price);
        orderId++;
    }

    /*
     * Cancel order
     * @param {uint256} orderId - Order id
     */
    function removeOrder(uint256 _orderId) external{
        require(orders[_orderId].user == msg.sender, "Not an owner");
        require(orders[_orderId].isActive, "No such order");
        if(rounds[currentRound].round != RoundState.trade) revert NotFinished("sale");
        if(rounds[currentRound].startTime + roundTime < block.timestamp) revert AlreadyFinished("trade");
        
        orders[_orderId].isActive = false;
        acdmToken.transfer(msg.sender, orders[_orderId].amount);

        emit OrderRemoved(_orderId);
    }

    /*
     * Redeem order by id
     * @param {uint256} orderId - Order id
     * @param {uint256} amount - Amount of tokens to redeem
     */
    function redeemOrder(uint256 _orderId, uint256 amount) external payable {
        User memory user = users[msg.sender];
        if(!user.isUser) revert Uregistered();
        require(orders[_orderId].isActive, "No such order");
        if(rounds[currentRound].round != RoundState.trade) revert NotFinished("sale");
        if(rounds[currentRound].startTime + roundTime < block.timestamp) revert AlreadyFinished("trade");

        uint256 price = orders[_orderId].price;
        uint256 currentAmount = orders[_orderId].amount;
        uint256 total = amount * price;
        uint256 bonus;

        if(currentAmount < amount) revert AmountExeeded(currentAmount, amount);
        if(msg.value < total) revert AmountExeeded(msg.value, total);

        if(amount == currentAmount){
            orders[_orderId].isActive = false;
        }
        else{
            orders[_orderId].amount -= amount;
        }

        rounds[currentRound].tradedEthCount += total;

        bonus = (total*bonuses[2])/10000;
        if(user.referrer1 != address(0)){         
            user.referrer1.transfer(bonus);
        } else{
            payable(dao).transfer(bonus);
        }

        bonus = (total*bonuses[3])/10000;
        if(user.referrer2 != address(0)){
            user.referrer2.transfer(bonus);
        } else {
            payable(dao).transfer(bonus);
        }
        
        acdmToken.transfer(msg.sender, amount);
        payable(orders[_orderId].user).transfer(total);

        emit OrderRedeemed(_orderId, msg.sender, amount, price);
    }

    /**
     * Sets bonuses for lvl refferal, only dao can call this function
     */
    function setBonuses(uint16 b1, uint16 b2, uint16 b3, uint16 b4) external onlyRole(DAO_ROLE) {
        bonuses[0] = b1;
        bonuses[1] = b2;
        bonuses[2] = b3;
        bonuses[3] = b4;

        emit BonusesChanged(bonuses[0], bonuses[1], bonuses[2], bonuses[3]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IACDM_token {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function decimals() external view returns (uint8);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

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