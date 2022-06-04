//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IMyERC20.sol";


contract ACDMPlatform is AccessControl{

    // владелец контракта
    address owner;
    // адрес платформы
    address platformAddress;
    // адрес управляющего контракта dao
    address daoAddress;
    // интерфейс к токену
    IMyERC20 ACDMToken;

    // номер раунда
    // нечётный - sale
    // чётный - trade
    uint256 public roundNumber;
    // продолжительность раунда
    uint256 public roundTime;
    // сумма на котороую совершены продажи в раунде trade
    uint256 public saleAmount;
    // цена токенов на последнем раунде sale
    uint256 public tokenPrice;
    // количество токенов заминченных на последнем раунде sale
    uint256 public tokenMint;
    // время окончания текущего раунда
    uint256 public endRoundTime;
    // количество токенов, выставленных на торги
    uint256 public tradeTokens;
    // количество реферального эфира на контракте
    uint256 public referalReward;
    // количество эфира от торгволи ACDMToken на котракте
    uint256 public tradeEth;
    // количество нулей у ACDMToken;
    uint24 public decimals;

    // параметры ревардов
    // указываются в промилле, регулируются через DAO
    uint8 public saleReward1;
    uint8 public saleReward2;
    uint8 public tradeReward;


    // Ордеры
    struct Order {
        address seller;
        uint256 tokenAmount;
        uint256 cost;
    }
    Order[] orders;

    // реферальная программа
    // refer1 - мой рефер
    // refer2 - рефер моего рефера
    struct Refer {
        address refer1;
        address refer2;
    }
    // словарь с сохранёнными рефералми пользователей
    mapping(address => Refer) referals;
    // словарь с количеством реферального эфира
    mapping(address => uint256) referalRewards;
    // словарь с количеством эфира от продажи токенов
    mapping(address => uint256) tradeEths;

    // роли
    //bytes32 public constant tokenOwner = keccak256("owner");
    //bytes32 public constant administrator = keccak256("administrator");
    // словарь с ролями
    //mapping(bytes32 => RoleData) public _roles;

    modifier onlyDao(){
        require(msg.sender == daoAddress, "You are not DAO");
        _;
    }

    constructor(address _ACDMToken, address _daoAddress, uint256 _roundTime){
        owner = msg.sender;
        daoAddress = _daoAddress;
        platformAddress = address(this);
        ACDMToken = IMyERC20(_ACDMToken);
        decimals = 1_000_000;
        roundTime = _roundTime;
        // что за странные числа? А вот:
        // это число нужно, что бы правильно посчитать цену в первом раунде Sale
        // 5 825 242 718 447 * 103 / 100 + 4 000 000 000 000 = 10 000 000 000 000
        tokenPrice = 5_825_242_718_447;
        // это число нужно, что бы правильно посчитать сколько минтить токенов в первом раунде Sale
        // 1 000 000 000 000 000 000 * 1 000 000 / 10 000 000 000 000 = 100 000 000 000
        saleAmount = 1_000_000_000_000_000_000;
        roundNumber = 0;
        // параметры ревардов регулируются через дао
        saleReward1 = 50;
        saleReward2 = 30;
        tradeReward = 25;
    }

    function register(address refer) public {
        // В словарь Referals по адресу msg.sender добавляется новая структура Refer в которой
        // refer1 = refer - реферал для msg.sender
        // refer2 = referals[refer].refer1 - реферал моего реферала 
        referals[msg.sender] = Refer(refer, referals[refer].refer1);
        // здесь регистрируемся в реферальной системе
        // refer - адрес нашего рефера
        // ему падают вознаграждения за наши действия
        // если кто-то отправит наш адрес - нам будут падать вознаграждения за его действия
        // двухуровневая система!
    }

    function startSaleRound() public {
        // Условие окончания работы:
        // прошло три дня. Не проданные токены по окончании раунда сжигаются
        // Проданы все заминченные токены. Тогда можно сразу начать trade раунд не дожидаясь трёх дней
        require(roundNumber % 2 == 0, "The sale round has already begun");
        require(block.timestamp > endRoundTime, "The time of the trade round is not over");
        // сохраняем текущее количество токенов на платформе - это токены, находящиеся в ордерах
        // Формула для расчёта стоимости
        // Price ETH = lastPrice * 1,03 + 0,000004
        // Пример расчета: 10 000 000 000 000 wei/ACDMtoken * 103 / 100 + 400 000 0000 000 = 14 300 000 000 000 wei/ACDMtoken
        tokenPrice = tokenPrice * 103 / 100 + 4_000_000_000_000;
        // минтим токены
        // Расчёт количества новых токенов в ACDM-копейках
        tokenMint = saleAmount * decimals / tokenPrice;
        ACDMToken.mint(platformAddress, tokenMint);

        // устанавливаем время окончания раунда
        endRoundTime = block.timestamp + roundTime;
        // увеличиваем счётчик раундов
        roundNumber++;
    }

    // функция покупки токенов
    function buyACDMToken() public payable {
        require(roundNumber % 2 == 1, "The sales round has not yet begun");
        require(endRoundTime > block.timestamp, "The time for the sale round is over");
        require(msg.value > 0, "Congratulations! You bought 0 tokens");

        // записываем награду на счёт рефералов, если они есть
        address refer1 = referals[msg.sender].refer1;
        if(refer1 != address(0)){
            uint256 reward = msg.value * saleReward1 / 1000;
            referalRewards[refer1] += reward;
            referalReward += reward;
            address refer2 = referals[msg.sender].refer2;
            if(refer2 != address(0)){
                reward =  msg.value * saleReward2 / 1000;
                referalRewards[refer2] += reward;
                referalReward += reward;
            }
        }
        // отправляем токены на счёт покупателя
        ACDMToken.transfer(msg.sender, msg.value * decimals / tokenPrice);
    }

    // Trade Round
    function startTradeRound() public {
        // Условие окончания работы:
        // прошло три дня. Не проданные токены по окончании раунда сжигаются
        // Проданы все заминченные токены. Тогда можно сразу начать trade раунд не дожидаясь трёх дней
        require(roundNumber % 2 == 1, "The trade round has already begun");
        require(block.timestamp > endRoundTime || ACDMToken.balanceOf(platformAddress) == 0,
            "Sales round time is not over yet or not all tokens are sold out");
        // сжигаем токены
        ACDMToken.burn(platformAddress, ACDMToken.balanceOf(platformAddress) - tradeTokens);
        // устанавливаем время окончания раунда
        endRoundTime = block.timestamp + roundTime;
        // увеличиваем счётчик раундов
        roundNumber++;
        // скидываем сумму на которую были накуплены в прошлом раунде торговли токены в ноль
        saleAmount = 0;
    }

    // Добавляем ордер на продажу токенов
    // cost - цена в wei за 1 ACDMToken
    function addOreder(uint256 tokenAmount, uint256 cost) public {
        require(roundNumber % 2 == 0, "The trade round has not yet begun");
        require(endRoundTime > block.timestamp, "The time for the trade round is over");
        //require(ACDMToken.allowance(msg.sender, platformAddress) >= tokenAmount, "No permission to transfer that many tokens");
        // делаем трансфер, если там не апрувнул, то там и сломается
        ACDMToken.transferFrom(msg.sender, platformAddress, tokenAmount);
        // добавляем ордер
        orders.push(Order(msg.sender, tokenAmount, cost));
        // добавляем токены в tradeTokens
        tradeTokens += tokenAmount;
    }

    function redeemToken(uint256 orderId) public payable {
        require(roundNumber % 2 == 0, "The trade round has not yet begun");
        require(endRoundTime > block.timestamp, "The time for the trade round is over");
        require(orderId < orders.length, "No order with this ID");
        require(msg.value > 0, "Congratulations! You bought 0 tokens");
        // рассчитываем сколько токенов можно купить в этом ордере за присланные деньги
        uint256 tokenAmount = msg.value  * decimals / orders[orderId].cost;
        // проверяем, что в этом ордере есть столько токенов
        require(orders[orderId].tokenAmount >= tokenAmount, "There are not enough tokens in this order for that amount");

        // записываем награду на счёт рефералов, если они есть
        uint256 reward = msg.value * tradeReward / 1000;
        address refer1 = referals[orders[orderId].seller].refer1;
        if(refer1 != address(0)){
            referalRewards[refer1] += reward;
            referalReward += reward;
            address refer2 = referals[orders[orderId].seller].refer2;
            if(refer2 != address(0)){
                referalRewards[refer2] += reward;
                referalReward += reward;
            }
        }
        // уменьшаем количество токенов в ордере
        orders[orderId].tokenAmount -= tokenAmount;
        // уменьшаем количество токенов, выставленных на продажу
        tradeTokens -= tokenAmount;
        // сохраняем количество эфира, заработанного продавцом ACDMToken
        tradeEths[orders[orderId].seller] += msg.value - reward * 2;
        // увеличиваем количество эфира от продажи токенов
        tradeEth += msg.value - reward * 2;
        // увеличиваем количество эфира, заработанного с продаж в этом раунде
        saleAmount += msg.value;
        // отправляем токены на адрес покупателя
        ACDMToken.transfer(msg.sender, tokenAmount);
    }

    // закрываем ордер, выводим из него токены
    function removeToken(uint256 orderId) public {
        require(orderId < orders.length, "No order with this ID");
        require(msg.sender == orders[orderId].seller, "You are not a seller in this order");
        require(orders[orderId].tokenAmount > 0 , "Order now closed");

        // для избежания атаки, сначала уменьшаем количество токенов
        uint256 tokenAmount = orders[orderId].tokenAmount;
        orders[orderId].tokenAmount = 0;
        tradeTokens -= tokenAmount;
        // отправляем токены на счёт владельца ордере
        ACDMToken.transfer(msg.sender, tokenAmount);
    }

    function getOrders() public view returns(Order[] memory){
        return orders;
    }

    function getMyReferalReward() public view returns(uint256){
        return referalRewards[msg.sender];
    }

    function getMyTradeEth() public view returns(uint256){
        return tradeEths[msg.sender];
    }

    function getMyRefers() public view returns(Refer memory){
        return referals[msg.sender];
    }

    // вывод награды за рефералов
    function withdrawalReferalReward() public {
        require(referalRewards[msg.sender] > 0, "You have no referral rewards");
        uint256 reward = referalRewards[msg.sender];
        referalReward -= referalRewards[msg.sender];
        referalRewards[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
    }

    // вывод прибыли от торговли
    function withdrawalTradeEth() public {
        require(tradeEths[msg.sender] > 0, "You have no trade ethers");
        uint256 trade = tradeEths[msg.sender];
        tradeEth -= tradeEths[msg.sender];
        tradeEths[msg.sender] = 0;
        payable(msg.sender).transfer(trade);
    }

    function setSaleReward1(uint8 _saleReward1) public onlyDao{
        saleReward1 = _saleReward1;
    }
    
    function setSaleReward2(uint8 _saleReward2) public onlyDao{
        saleReward2 = _saleReward2;
    }

    function setTradeReward(uint8 _tradeReward) public onlyDao{
        tradeReward = _tradeReward;
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

pragma solidity ^0.8.0;

interface IMyERC20 {
    function name() external view returns(string memory);
    function totalSupply() external view returns(uint256);
    function decimals() external view returns(uint8);
    function balanceOf(address) external view returns(uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
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