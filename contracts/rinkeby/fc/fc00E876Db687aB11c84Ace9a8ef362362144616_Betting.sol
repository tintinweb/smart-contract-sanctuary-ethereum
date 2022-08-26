// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "IERC20.sol";
import "AccessControl.sol";

contract Betting is AccessControl{

    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER");
    enum match_status{
        open,
        start,
        cancel,
        completed
    }

    struct Match {
        uint256 matchId;
        string team1;
        string team2;
        address currency_address;
        uint256 starting_time;
        uint256 team1_win;
        uint256 team2_win;
        string winner_team;
        match_status Status;
    }
    mapping(uint256 => Match) public creatematchs;
    uint256 matchno;

    struct Bet{
        address better_address;
        uint256 amount;
        string team;
        uint256 winning_amount;
    }
    mapping(uint256 => Bet) public bet;
    uint256 betno;

    mapping(uint256 => uint256[]) public total_bet; 

    event CreateMatch(uint256 indexed matchId,string team1,string team2,uint256 match_day,address currency,uint256 team1_winning_prize,uint256 team2_winning_prize);
    event CancelMatch(uint256 indexed matchId,string team1,string team2,uint256 match_day,address currency);
    event Betting(uint256 indexed matchId,address better_address,uint256  amount,string  team);
    event CompleteMatch(uint256 indexed matchId,string team1,string team2,uint256 match_day,string winner);
   
    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MEMBER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    modifier onlyAdmin(){
        require(isAdmin(msg.sender), "Restricted to admin");
        _;
    }
    modifier onlyMember(){
        require(isMember(msg.sender), "Restricted to users");
        _;
    }
    function addMember(address account)public virtual onlyAdmin{
        grantRole(MEMBER_ROLE, account);
    }
    function removeMember(address account)public virtual onlyAdmin{
        revokeRole(MEMBER_ROLE, account);
    }

    function isMember(address account)public virtual view returns (bool){
        return hasRole(MEMBER_ROLE,account);
    }

    function isAdmin(address account)public virtual view returns (bool){
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // function addAdmin(address account)public virtual onlyAdmin{
    //     grantRole(DEFAULT_ADMIN_ROLE, account);
    // }

    // function renounceAdmin()public virtual onlyAdmin{
    //     renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // }

    function create_match(uint256 _matchid,string memory _team1,
                          string memory _team2,address _currency,
                          uint256 _startingtime,uint256 _team1win,uint256 _team2win) external onlyAdmin {
        // require(msg.sender == contract_owner,'only owner call this function');
        require(_startingtime > block.timestamp,'please enter valid time');
        Match storage matchs=creatematchs[matchno];
        matchs.matchId=_matchid;
        matchs.team1=_team1;
        matchs.team2=_team2;
        matchs.currency_address=_currency;
        matchs.starting_time=_startingtime;
        matchs.team1_win=_team1win;
        matchs.team2_win=_team2win;
        matchs.Status=match_status.open;
        matchno++;
        emit CreateMatch(_matchid,_team1,_team2,_startingtime,_currency,_team1win,_team2win);        
    }


    function betting_on_match(uint256 _matchno,uint256 _amount,string memory _team) external {
        Match storage matchs=creatematchs[_matchno];
        IERC20 currency=IERC20(matchs.currency_address);
        require(matchs.starting_time > block.timestamp,'match start');
        require(matchs.Status == match_status.open,'match start');
        require(currency.allowance(msg.sender,address(this)) >= _amount,'you have a not allowance');
        require(currency.balanceOf(msg.sender) >= _amount,'not enough balance');
        currency.transferFrom(msg.sender,address(this),_amount);
        Bet storage bets=bet[betno];
        total_bet[_matchno].push(betno);
        bets.better_address=msg.sender;
        bets.amount=_amount;
        bets.team=_team;
        betno++;

        emit Betting(matchs.matchId,msg.sender,_amount,_team);        
    }

    function cancel_match(uint256 _matchno) external onlyAdmin {
        // require(msg.sender == contract_owner,'only owner cancel betting event');
        Match storage matchs=creatematchs[_matchno];
        IERC20 currency=IERC20(matchs.currency_address);
        for (uint256 i=0; i< total_bet[_matchno].length; i++){
            Bet storage bets=bet[total_bet[_matchno][i]];
            currency.transfer(bets.better_address,bets.amount);
        }
        matchs.Status=match_status.cancel; 
        emit CancelMatch(matchs.matchId,matchs.team1,matchs.team2, matchs.starting_time, matchs.currency_address);  
    }

    function start_match(uint256 _matchno) external onlyAdmin {
        Match storage matchs=creatematchs[_matchno];
        // require(msg.sender == contract_owner,'only owner call this function');
        require(matchs.starting_time <= block.timestamp,'match not start');
        require(matchs.Status == match_status.open,'betting status not open');
        matchs.Status=match_status.start;
    }

    function complate_match(uint256 _matchno,string memory _winner) external onlyAdmin{
        Match storage matchs=creatematchs[_matchno];
        IERC20 currency=IERC20(matchs.currency_address);
        // require(msg.sender == contract_owner,'only owner call this function');
        require(matchs.Status==match_status.start,'match not finish');

        for (uint256 i=0; i < total_bet[_matchno].length; i++){
            Bet storage bets=bet[total_bet[_matchno][i]];
            uint256 winner_amount;
            if(keccak256(abi.encodePacked(bets.team)) == keccak256(abi.encodePacked(_winner))){
                if(keccak256(abi.encodePacked(matchs.team1)) == keccak256(abi.encodePacked(_winner))){
                    winner_amount=(bets.amount) + (bets.amount * matchs.team1_win /100);
                    currency.transfer(bets.better_address,winner_amount);
                }
                winner_amount=(bets.amount) + (bets.amount * matchs.team2_win /100);
                currency.transfer(bets.better_address,winner_amount);
                bets.winning_amount=winner_amount;
            }
        }
        matchs.winner_team=_winner;
        matchs.Status=match_status.completed;

        emit CompleteMatch(matchs.matchId,matchs.team1,matchs.team2,matchs.starting_time,_winner);
    }

    function withdraw(address _erc20,uint256 _amount,address _receiver) external onlyAdmin{
        IERC20 currency=IERC20(_erc20);
        // require(msg.sender == contract_owner,'only owner withdraw token');
        require(address(this).balance >= _amount,'please enter the valid amount');
        currency.transfer(_receiver,_amount);
    }
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

pragma solidity ^0.8.0;

import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "IERC165.sol";

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