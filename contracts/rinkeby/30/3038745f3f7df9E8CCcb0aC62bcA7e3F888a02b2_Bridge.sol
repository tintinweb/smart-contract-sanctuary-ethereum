// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMyERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Bridge is AccessControl {

    // счётчик транзакций
    uint256 counter;
    // id блокчейна
    uint256 currentChainId;
    // адрес хозяина контракта
    address owner;
    // роли
    bytes32 public constant bridgeOwner = keccak256("owner");
    bytes32 public constant administrator = keccak256("administrator");
    // словарь с ролями
    mapping(bytes32 => RoleData) public _roles;

    // имя токена => адрес токена
    mapping(string => address) public tokens;
    // id цепочки => поддерживается/не поддерживается
    mapping(uint256 => bool) public chainIds;
    // счётчик была ли совершена транзакция из другого блокчейна по счётчику
    // id блокчейна, где вызвали swap => (счётчик транзакции => true/false)
    mapping(uint256 => mapping(uint256 => bool)) counters;

    event swapInitialized(
        uint256 currentChainId,
        string tokenName,
        address recipient,
        uint256 chainId,
        uint256 value,
        uint256 counter
    );

    modifier onlyOwner(){
        require(msg.sender == owner || hasRole(administrator, msg.sender),
                "Bridge: You don't have access rights");
        _;
    }

    constructor(uint256 _currentChainId){
        _setRoleAdmin(bridgeOwner, bridgeOwner);
        _grantRole(bridgeOwner, msg.sender);
        _setRoleAdmin(administrator, bridgeOwner);
        _grantRole(administrator, msg.sender);
        owner = msg.sender;
        counter = 0;
        currentChainId = _currentChainId;
    }

    // Функция swap(): списывает токены с пользователя и отправляет event ‘swapInitialized’
    function swap(string memory tokenName, address recipient, uint256 chainId, uint256 value) public {
        require(chainIds[chainId] == true, "Chain is not supported");
        require(tokens[tokenName] != address(0), "Token not added");
        IMyERC20(tokens[tokenName]).burn(msg.sender, value);
        emit swapInitialized(currentChainId, tokenName, recipient, chainId, value, ++counter);
    }

    // Функция redeem(): вызывает функцию ecrecover и восстанавливает по хэшированному сообщению и сигнатуре 
    // адрес валидатора, если адрес совпадает с адресом указанным на контракте моста
    // то пользователю отправляются токены
    function redeem
    (
        uint256 chainId,
        string memory tokenName,
        uint256 value,
        uint256 _counter,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        public
    {
        require(chainIds[chainId] == true, "Chain is not supported");
        require(tokens[tokenName] != address(0), "Token not added");
        require(counters[chainId][_counter] != true, "Translation is already done");
        require(checkSign(chainId, tokenName, msg.sender, value, _counter, v, r, s),
                "Signature not valid");
        address tokenAddress = tokens[tokenName];
        IMyERC20(tokenAddress).mint(msg.sender, value);
        counters[chainId][_counter] = true;
    }

    function checkSign
    (
        uint256 chainId,
        string memory tokenName,
        address recipient,
        uint256 value,
        uint256 _counter,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        public view returns (bool)
    {
        bytes32 message = keccak256(
            abi.encodePacked(chainId, tokenName, recipient, currentChainId, value, _counter)
        );
        address addr1 = ecrecover(hashMessage(message), v, r, s);
        return hasRole(administrator, addr1);
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    // Функция updateChainById(): добавить блокчейн или удалить по его chainID
    function updateChainById(uint256 chainId, bool update) public onlyOwner {
        chainIds[chainId] = update;
    }

    // Функция includeToken(): добавить токен для передачи его в другую сеть
    function includeToken(address tokenAddress) public onlyOwner {
        string memory name = IMyERC20(tokenAddress).name();
        require(tokens[name] == address(0), "Token already added");
        tokens[name] = tokenAddress;
    }

    // Функция excludeToken(): исключить токен для передачи
    function excludeToken(address tokenAddress) public onlyOwner {
        string memory name = IMyERC20(tokenAddress).name();
        require(tokens[name] != address(0), "Token not added");
        delete tokens[name];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMyERC20 {
    function mint(address, uint) external;
    function burn(address, uint) external;
    function name() external returns(string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Контрактный модуль, позволяющий наследникам реализовать механизмы управления доступом на основе ролей.
 * Это облегченная версия, которая не позволяет перечислять членов роли,
 * кроме как с помощью внецепочечных средств, обращаясь к журналам событий контракта. 
 * Некоторые приложения могут выиграть от перечислимости на цепочке, для таких случаев см.
 * {AccessControlEnumerable}.
 *
 * На роли ссылаются по их идентификатору `bytes32`. 
 * Они должны быть открыты во внешнем API и быть уникальными. 
 * Лучший способ достичь этого - использовать хэш-дайджесты `public constant`:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Роли можно использовать для представления набора разрешений. 
 * Чтобы ограничить доступ к вызову функции, используйте {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Роли могут быть предоставлены и отозваны динамически с помощью функций {grantRole} и {revokeRole}.
 * Each role has an associated admin role, and only
 * Каждая роль имеет связанную с ней роль администратора, и только учетные записи,
 * и только учетные записи, имеющие роль администратора роли, могут вызывать {grantRole} и {revokeRole}.
 *
 * По умолчанию роль администратора для всех ролей - `DEFAULT_ADMIN_ROLE`,
 * что означает, что только учетные записи с этой ролью смогут предоставлять или отзывать другие роли.
 * Более сложные ролевые отношения могут быть созданы с помощью
 * {_setRoleAdmin}.
 *
 * ВНИМАНИЕ: `DEFAULT_ADMIN_ROLE` также является собственным администратором:
 * он имеет право предоставлять и отзывать эту роль.
 * Следует принять дополнительные меры предосторожности для защиты учетных записей, которым он был предоставлен.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Модификатор, проверяющий, имеет ли учетная запись определенную роль.
     * Возвращает стандартное сообщение с указанием требуемой роли.
     *
     * Формат причины возврата задается следующим регулярным выражением:
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
     * @dev Возвращает `true`, если `account` была предоставлена `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Возврат со стандартным сообщением, если в `_msgSender()` отсутствует `role`.
     * Переопределение этой функции изменяет поведение модификатора {onlyRole}.
     *
     * Формат сообщения о возврате описан в {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Возврат со стандартным сообщением, если в `account` отсутствует `role`.
     *
     * Формат причины возврата задается следующим регулярным выражением:
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
     * @dev Возвращает роль администратора, которая управляет `role`. См. {grantRole} и
     * {revokeRole}.
     *
     * Чтобы изменить роль администратора, используйте {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Предоставляет `роль` для `аккаунта`.
     *
     * Если `account` еще не был наделен `role`, выдает событие {RoleGranted}.
     *
     * Требования:
     *
     * - вызывающий должен иметь роль администратора для ``role``.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Отзывает `role` у `account`.
     *
     * Если `account` был наделен `role`, выдает событие {RoleRevoked}.
     *
     * Требования:
     *
     * - вызывающий должен иметь роль администратора для ``role``.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Отзывает `role` у вызывающей учетной записи.
     *
     * Роли часто управляются через {grantRole} и {revokeRole}: 
     * цель этой функции - обеспечить механизм потери привилегий для учетных записей
     * если они скомпрометированы (например, когда доверенное устройство потеряно).
     *
     * Если у вызывающей учетной записи была отозвана `role`, выдает событие {RoleRevoked}.
     *
     * Требования:
     *
     * - вызывающая сторона должна быть `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Предоставляет `role` для `account`.
     *
     * Если `account` еще не был наделен `role`, выдает событие {RoleGranted} событие.
     * Обратите внимание, что в отличие от {grantRole},
     * эта функция не выполняет никаких проверок вызывающей учетной записи.
     *
     * [ВНИМАНИЕ]
     * ====
     * Эта функция должна вызываться только из конструктора при установке начальных ролей для системы.
     *
     * Использование этой функции любым другим способом является эффективным обходом системы администрирования,
     * наложенной {AccessControl}.
     * ====
     *
     * NOTE: Эта функция устарела в пользу {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Устанавливает `adminRole` в качестве роли администратора ``role``.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Предоставляет `role` для `account`.
     *
     * Внутренняя функция без ограничения доступа.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Отзывает `role` у `account`.
     *
     * Внутренняя функция без ограничения доступа.
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