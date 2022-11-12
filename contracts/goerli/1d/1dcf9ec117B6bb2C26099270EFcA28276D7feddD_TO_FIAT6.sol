//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/access/AccessControl.sol";

contract TO_FIAT6 is AccessControl {

    // =============================================================
    //                            STORAGE
    // =============================================================

    uint8 public commissions; // commission in tenths of a percent
    uint256 public comissionSumNative; // sum of commissions in native token
    mapping(address => uint256) public comissionSumToken; // sum of commissions in tokens
    uint256 public minTimeForTakerAndMaker; // minimal time for approve between deal sides
    uint256 public maxTimeForTakerAndMaker; // maximum time for approve between deal sides
    uint256 public multiplicityOfTime; // module from time
    
    // multisig role
    bytes32 public constant TCmultisig = keccak256("TC_MULTISIG");

    // Room structure
    struct RoomNumber {

        // maker address
        address maker;

        // time for approve between deal sides
        uint32 timeForTakerAndMaker;

        // mapping with all the takers
        mapping (uint256 => Taker) taker;

        // counter of takers
        uint16 counter;

        // volume of room
        uint256 volume;

        // the rate at which the token will be exchanged for fiat
        uint32 rate;

        // address of token
        address addressOfToken;

        // upper limit of room
        uint256 maxLimit;

        // lower limit of room
        uint256 lowLimit;

        // room status state
        roomStatusENUM roomStatus; // 0 - None, 1 - Continue, 2 - Paused, 3 - Closed

    }

    enum roomStatusENUM {
        None,
        Continue,
        Paused,
        Closed
    }

    // Tekar structure
    struct Taker {
        // address of taker
        address addressOfTaker;

        // volume of this taker
        uint256 volume;

        // timestamp for timeForTakerAndMaker
        uint256 timer;

        // taker scam state
        bool isScam;

        // here is decision about the scam in this taker
        moderDecisionENUM moderDecision; // 0 - None, 1 - scamReal, 2 - scamFake, 3 - scamHalf

        // taker status state
        dealStatusENUM dealStatus; // 0 - None, 1 - Continue, 2 - ApprovedByTaker, 3 - ApprovedByMaker, 4 - Closed

    }

    enum dealStatusENUM {
        None,
        Continue,
        ApprovedByTaker,
        ApprovedByMaker,
        Closed
    }

    enum moderDecisionENUM {
        None,
        scamReal,
        scamFake,
        scamHalf
    }

    // main mapping with all roomNumber structs
    mapping(uint256 => RoomNumber) roomNumberMap;

    // =============================================================
    //                            Modifiers
    // =============================================================

    // modifier for room status check
    modifier roomStatusCheck(bool decision, uint256 _roomNumber, roomStatusENUM status) {
        require(decision ? roomNumberMap[_roomNumber].roomStatus == status : roomNumberMap[_roomNumber].roomStatus != status, "RSC");
        _;
    }

    // modifier for taker status check
    modifier takerStatusCheck(bool decision, uint256 _roomNumber, uint256 _takerNumber, dealStatusENUM status) {
        require(decision ? roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus == status : roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus != status, "DSC");
        _;
    }

    modifier isRoomMaker(uint256 _roomNumber, address maker) {
        require(roomNumberMap[_roomNumber].maker == maker, "RM");
        _;
    }

    // =============================================================
    //                            Events
    // =============================================================

    event CreateRoom(
        uint256 roomNumber,
        address maker,
        address addressOfToken,
        uint256 volume
    );

    event JoinRoom(
        uint256 roomNumber,
        uint16 takerNumber,
        address addressOfTaker,
        uint256 takerVolume
    );
    
    event TakerApprove(
        uint256 roomNumber,
        uint256 takerNumber
    );

    event MakerApprove(
        uint256 roomNumber,
        uint256 takerNumber
    );

    event TakerWithdraw(
        uint256 roomNumber,
        uint256 takerNumber,
        address addressOfToken,
        uint256 volume
    );

    event CloseRoom(
        uint256 roomNumber
    );

    event ScamFromTaker(
        uint256 roomNumber,
        uint256 takerNumber
    );


    // =============================================================
    //                         Main functions
    // =============================================================

    // here we makes room
    function createRoom(
        uint256 _roomNumber, // room number
        uint32 _timeForTakerAndMaker, // time for approve between deal sides in this room
        uint256 _maxLimit, // upper limit of room
        uint256 _lowLimit, // lower limit of room
        address _addressOfToken, // address of token (address(0) if native token)
        uint256 _msgValue, // the number of tokens that will be executed in this room
        uint32 _rate // the rate at which the token will be exchanged for fiat
    ) public payable roomStatusCheck(true, _roomNumber, roomStatusENUM.None) {
        require(_timeForTakerAndMaker <= maxTimeForTakerAndMaker &&
                _timeForTakerAndMaker >= minTimeForTakerAndMaker &&
                _timeForTakerAndMaker % multiplicityOfTime == 0,
                "IT");

        if (_addressOfToken == address(0)) {
            require(_maxLimit > _lowLimit && 
                _maxLimit <= (msg.value - (msg.value / 1000 * commissions)),
                "IL");

            comissionSumNative += msg.value / 1000 * commissions;
    
            roomNumberMap[_roomNumber].timeForTakerAndMaker = _timeForTakerAndMaker;
            roomNumberMap[_roomNumber].volume = (msg.value - (msg.value / 1000 * commissions));
            roomNumberMap[_roomNumber].addressOfToken = address(0);
        } else {
            require(_maxLimit > _lowLimit && 
                _maxLimit <= _msgValue - (_msgValue / 1000 * commissions),
                "IL");
        
            bool success = IERC20(_addressOfToken).transferFrom(msg.sender, address(this), _msgValue);
            require(success);

            comissionSumToken[_addressOfToken] += _msgValue / 1000 * commissions;
    
            roomNumberMap[_roomNumber].timeForTakerAndMaker = _timeForTakerAndMaker;
            roomNumberMap[_roomNumber].volume = (_msgValue - (_msgValue / 1000 * commissions));
            roomNumberMap[_roomNumber].addressOfToken = _addressOfToken;
        }

        roomNumberMap[_roomNumber].maxLimit = _maxLimit;
        roomNumberMap[_roomNumber].lowLimit = _lowLimit;
        roomNumberMap[_roomNumber].maker = msg.sender;
        roomNumberMap[_roomNumber].rate = _rate;
        roomNumberMap[_roomNumber].roomStatus = roomStatusENUM.Continue;

        emit CreateRoom(
            _roomNumber,
            roomNumberMap[_roomNumber].maker,
            roomNumberMap[_roomNumber].addressOfToken,
            roomNumberMap[_roomNumber].volume);
    }

    // here taker joins the room
    function joinRoom (
        uint256 _roomNumber, // room number
        uint256 _txVolume // volume of taker
    ) public roomStatusCheck(true, _roomNumber, roomStatusENUM.Continue) {
        require(roomNumberMap[_roomNumber].maxLimit >= _txVolume && roomNumberMap[_roomNumber].lowLimit <= _txVolume, "OL");

        // here we init the taker
        roomNumberMap[_roomNumber].taker[roomNumberMap[_roomNumber].counter] = Taker({
            addressOfTaker: msg.sender,
            volume: _txVolume,
            timer: block.timestamp,
            isScam: false,
            moderDecision: moderDecisionENUM.None,
            dealStatus: dealStatusENUM.Continue
        });

        roomNumberMap[_roomNumber].volume -= _txVolume;

        emit JoinRoom(_roomNumber, roomNumberMap[_roomNumber].counter, msg.sender, _txVolume);

        roomNumberMap[_roomNumber].counter++;

    }

    // here taker approves his fiat transfer
    function takerApprove(uint256 _roomNumber, uint256 _takerNumber) takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.Continue) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker == msg.sender, "NT");
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.ApprovedByTaker;
        roomNumberMap[_roomNumber].taker[_takerNumber].timer = block.timestamp + roomNumberMap[_roomNumber].timeForTakerAndMaker;
        emit TakerApprove(_roomNumber, _takerNumber);
    }

    // here maker approves, that taker have done everything right
    function makerApprove(uint256 _roomNumber, uint256 _takerNumber) external isRoomMaker(_roomNumber, msg.sender) takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.ApprovedByTaker) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].isScam == false, "ST");

        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.ApprovedByMaker;
        emit MakerApprove(_roomNumber, _takerNumber);
    }

    // here taker withdraw tokens
    function takerWithdraw(uint256 _roomNumber, uint256 _takerNumber) public takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.ApprovedByMaker) {
        withdraw(_roomNumber, _takerNumber);
        emit TakerWithdraw(_roomNumber, _takerNumber, roomNumberMap[_roomNumber].addressOfToken, roomNumberMap[_roomNumber].taker[_takerNumber].volume);
    }

    // internal withdraw function
    function withdraw(uint256 _roomNumber, uint256 _takerNumber) internal takerStatusCheck(false, _roomNumber, _takerNumber, dealStatusENUM.Closed) {
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.Closed;

        if (roomNumberMap[_roomNumber].addressOfToken == address(0)) {
            payable(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker).transfer(roomNumberMap[_roomNumber].taker[_takerNumber].volume);
        } else {
            bool success = IERC20(roomNumberMap[_roomNumber].addressOfToken).transfer(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker, roomNumberMap[_roomNumber].taker[_takerNumber].volume);
            require(success);
        }

    }

    // here maker can withdraw all his tokens and close the room, if here is no takers
    function closeRoom(uint256 _roomNumber) external roomStatusCheck(false, _roomNumber, roomStatusENUM.Closed) isRoomMaker(_roomNumber, msg.sender) {

        if (roomNumberMap[_roomNumber].counter > 0) {
            for (uint256 i = 0; i < roomNumberMap[_roomNumber].counter; i++) {
                require(roomNumberMap[_roomNumber].taker[i].dealStatus == dealStatusENUM.Closed, "DO");
            }
        }

        if (roomNumberMap[_roomNumber].volume > 0) {
            if (roomNumberMap[_roomNumber].addressOfToken == address(0)) {
                payable(msg.sender).transfer(roomNumberMap[_roomNumber].volume);
            } else {
                bool success = IERC20(roomNumberMap[_roomNumber].addressOfToken).transfer(msg.sender, roomNumberMap[_roomNumber].volume);
                require(success);
            }
        }

        roomNumberMap[_roomNumber].roomStatus = roomStatusENUM.Closed;
        emit CloseRoom(_roomNumber);
    }

    // here maker can stop room
    function pauseRoom(uint256 _roomNumber) external isRoomMaker(_roomNumber, msg.sender) {
        roomNumberMap[_roomNumber].roomStatus = roomStatusENUM.Paused;
    }

    // here maker can continue room
    function continueRoom(uint256 _roomNumber) external isRoomMaker(_roomNumber, msg.sender) {
        roomNumberMap[_roomNumber].roomStatus = roomStatusENUM.Continue;
    }

    // here maker can return the volume from taker to the room, if the taker overstays the function "takerApprove" call
    function delayFromTaker(uint256 _roomNumber, uint256 _takerNumber) external takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.Continue) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].timer <= block.timestamp + roomNumberMap[_roomNumber].timeForTakerAndMaker, "TT");
        
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.Closed;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].taker[_takerNumber].volume;
    }

    // here taker can wothdraw the his volume from room, if maker overstays the function "makerApprove" call
    function delayFromMaker(uint256 _roomNumber, uint256 _takerNumber) external takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.ApprovedByTaker) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].timer <= block.timestamp + roomNumberMap[_roomNumber].timeForTakerAndMaker, "MS");

        withdraw(_roomNumber, _takerNumber);
    }

    // here maker can complain about scam
    function scamFromTaker(uint256 _roomNumber, uint256 _takerNumber) external isRoomMaker(_roomNumber, msg.sender) takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.ApprovedByTaker) {
        roomNumberMap[_roomNumber].taker[_takerNumber].isScam = true;
        emit ScamFromTaker(_roomNumber, _takerNumber);
    }

    // here admins passes their decision about scam in the room
    function moderDecision(uint256 _roomNumber, moderDecisionENUM _decision, uint256 _takerNumber) external onlyRole(TCmultisig) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].isScam == true);
        roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision = _decision;
    }

    // in this admin decision, volume of deal get rafunded to the room
    function scamReal(uint256 _roomNumber, uint256 _takerNumber) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision == moderDecisionENUM.scamReal);

        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.Closed;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].taker[_takerNumber].volume;
    }

    // in this admin decision, volume of deal get withdrawn to taker
    function scamFake(uint256 _roomNumber, uint256 _takerNumber) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision == moderDecisionENUM.scamFake);

        withdraw(_roomNumber, _takerNumber);
    }

    // in this admin decision, volume of deal separates between maker and taker
    function scamHalf(uint256 _roomNumber, uint256 _takerNumber) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision == moderDecisionENUM.scamHalf);
        uint256 half = roomNumberMap[_roomNumber].taker[_takerNumber].volume/2;
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.Closed;

        roomNumberMap[_roomNumber].volume += half;

        if (roomNumberMap[_roomNumber].addressOfToken == address(0)) {
            payable(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker).transfer(half);
        } else {
            bool success = IERC20(roomNumberMap[_roomNumber].addressOfToken).transfer(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker, half);
            require(success);
        }
    }

    // if the taker makes a mistake in the input parameters when entering the trade, he can return everything and quickly exit the trade
    function mistakeFromTaker(uint256 _roomNumber, uint256 _takerNumber) external takerStatusCheck(true, _roomNumber, _takerNumber, dealStatusENUM.Continue) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker == msg.sender, "NT");
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = dealStatusENUM.Closed;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].taker[_takerNumber].volume;
    }

    // =============================================================
    //                            View functions
    // =============================================================

    function getTaker(uint256 _roomNumber, uint256 _takerNumber) public view returns(Taker memory) {
        return(roomNumberMap[_roomNumber].taker[_takerNumber]);
    }

    function getRoomStatic(uint256 _roomNumber) public view returns(
        address,
        uint32,
        uint256,
        uint256,
        address,
        uint32
        ) {
        return(
            roomNumberMap[_roomNumber].maker,
            roomNumberMap[_roomNumber].timeForTakerAndMaker,
            roomNumberMap[_roomNumber].maxLimit,
            roomNumberMap[_roomNumber].lowLimit,
            roomNumberMap[_roomNumber].addressOfToken,
            roomNumberMap[_roomNumber].rate
        );
    }

    function getRoomDynamic(uint256 _roomNumber) public view returns(
        uint16,
        uint256,
        roomStatusENUM
    ) {
        return(
            roomNumberMap[_roomNumber].counter,
            roomNumberMap[_roomNumber].volume,
            roomNumberMap[_roomNumber].roomStatus
        );
    }

    // =============================================================
    //                            Admin functions
    // =============================================================

    // withdraw all commissions in native token
    function withdrawCommissionsNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(comissionSumNative);
        comissionSumNative = 0;
    }

    // withdraw all commissions in token
    function withdrawCommissionsToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool success = IERC20(token).transfer(msg.sender, comissionSumToken[token]);
        require(success);
        comissionSumToken[token] = 0;
    }

    // here admin can set comissions
    function setCommissions(uint8 _commissions) external onlyRole(DEFAULT_ADMIN_ROLE) {
        commissions = _commissions;
    }

    function setMaxTimeForTakerAndMaker(uint256 _maxTimeForTakerAndMaker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTimeForTakerAndMaker = _maxTimeForTakerAndMaker;
    }

    function setMinTimeForTakerAndMaker(uint256 _minTimeForTakerAndMaker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minTimeForTakerAndMaker = _minTimeForTakerAndMaker;
    }

    function setMultiplicityOfTime(uint256 _multiplicityOfTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        multiplicityOfTime = _multiplicityOfTime;
    }

    // =============================================================
    //                            Constructor
    // =============================================================

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

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