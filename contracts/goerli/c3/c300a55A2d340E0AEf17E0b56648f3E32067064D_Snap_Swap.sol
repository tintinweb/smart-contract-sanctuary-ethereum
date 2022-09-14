// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "AggregatorV3Interface.sol";
import "AccessControlEnumerable.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "Context.sol";
import "Referral.sol";

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

error NotAdmin();
error Address0();
error AllowanceIsLow();
error ExceedLimit();
error BalanceLow();

/**
    @title Snap Innovations
 */

contract Snap_Swap is
    Context,
    AccessControlEnumerable,
    Pausable,
    ReentrancyGuard
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev chainlink aggregator price feed
     */
    AggregatorV3Interface internal priceFeed_USDT;
    AggregatorV3Interface internal priceFeed_USDC;

    /**
     * @dev ReferralDB contract address
     */
    ReferralDB public REF_DB;

    /**
     * @dev keep the referral codes
     * Note: referral code 1 is reserved
     */
    mapping(bytes32 => uint256) public referrals_amount;

    /**
     * @dev maximum limit of each transaction
     */
    uint256 public max_limit_tx;

    /**
     * @dev maximum limit for each day
     */
    uint256 public max_limit_day;

    /**
     * @dev last update
     */
    uint256 public last_update;

    /**
     * @dev total swap today
     */
    uint256 public total_swap_day;

    /**
     * @dev Base fee => in bp (*10000)
     */
    uint256 public base_fee;

    /**
     * @dev USDT contract address
     */
    address public USDT;

    /**
     * @dev USDC contract address
     */
    address public USDC;

    /**
     * @dev Treasury wallet address
     * this wallet is the one which gets the withdrawed funds
     */
    address public treasury_wallet;

    /**
     * @dev Fee wallet address
     * this wallet is the one which gets all the fees when swapping happens
     */
    address public fee_wallet;

    /**
     * @dev is the stable token Interface
     */
    IERC20 public immutable token;

    /**
     * @dev EVENTS
     */
    // withdraw event fires when a withdraw happens
    event withdraw_event(address token);

    // mint_event fires when a minting happens through another token
    event swap_event(
        address swapped_token,
        uint256 amount,
        string referral,
        uint256 timestamp,
        uint256 percentage
    );

    // fires when updating a price feed aggregator address
    event AggregatorUpdated(address new_aggregator, bool isUSDT);

    // fires when maximum limit for a transaction has been updated
    event max_limit_tx_updated(uint256 _limit);

    // fires when maximum limit for a day has been updated
    event max_limit_day_updated(uint256 _limit);

    // fires when ReferralDB updated
    event refDB_updated(address newAdd);

    // fires when Base percentage updated
    event basePercentageUpdated(uint256 new_base);

    // fires when referral contract address has been updated
    event referralContractAddressUpdated(address new_address);

    /**
    * @dev should pass USDT and USDC chainlink price feed address also their contract addresses on the
    deployment chain
    * @param _priceFeed_USDT is the address of the USDT/USD price feed Aggregator to read the price from
    * @param _priceFeed_USDC is the address of the USDC/USD price feed Aggregator to read the price from
    * @param _USDT is the contract address of the USDT token on the deployment chain
    * @param _USDC is the contract address of the USDC token on the deployment chain
    * @param _token_address is the address of the stable token
     */
    constructor(
        address _priceFeed_USDT,
        address _priceFeed_USDC,
        address _USDT,
        address _USDC,
        address _token_address,
        address _referral_db,
        uint256 _max_limit_tx,
        uint256 _max_limit_day
    ) {
        if (
            _priceFeed_USDC == address(0) ||
            _priceFeed_USDT == address(0) ||
            _USDT == address(0) ||
            _USDC == address(0) ||
            _token_address == address(0)
        ) {
            revert Address0();
        }

        priceFeed_USDT = AggregatorV3Interface(_priceFeed_USDT);
        priceFeed_USDC = AggregatorV3Interface(_priceFeed_USDC);
        USDT = _USDT;
        USDC = _USDC;
        treasury_wallet = _msgSender();
        fee_wallet = _msgSender();
        token = IERC20(_token_address);
        REF_DB = ReferralDB(_referral_db);
        max_limit_day = _max_limit_day;
        max_limit_tx = _max_limit_tx;
        last_update = block.timestamp;
        total_swap_day = 0;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
    @dev checks if caller has DEFAULT_ADMIN_ROLE role
     */
    modifier AdminOnly() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAdmin();
        }
        _;
    }

    /**
    @dev checks whether the contract has paused
     */
    modifier NotPaused() {
        if (paused()) {
            revert ContractPaused();
        }
        _;
    }

    /**
    @dev withdraw all balances of the contract to the treasury wallet
    */
    function withdraw() public nonReentrant AdminOnly {
        IERC20(USDC).transfer(
            treasury_wallet,
            IERC20(USDC).balanceOf(address(this))
        );
        emit withdraw_event(USDC);

        IERC20(USDT).transfer(
            treasury_wallet,
            IERC20(USDT).balanceOf(address(this))
        );
        emit withdraw_event(USDT);

        if (address(this).balance > 0) {
            payable(treasury_wallet).transfer(address(this).balance);
            emit withdraw_event(address(0));
        }
    }

    // ==================================== minting logic - USDT ====================================
    /**
    @dev sending USDT and swapping to SUSD
    @param _amount of USDT to send. user has to approve this contract to spend _amount of USDT before calling this function.
    @param _referral code 
     */
    function swap_by_USDT(uint256 _amount, string calldata _referral)
        public
        nonReentrant
        NotPaused
    {
        address _USDT = USDT;
        if (
            IERC20(_USDT).allowance(_msgSender(), address(this)) <
            _amount * 10e17 ||
            IERC20(_USDT).balanceOf(_msgSender()) < _amount * 10e17
        ) {
            revert AllowanceIsLow();
        }

        // checking and updating the limits before continue
        require(updateOrReject(_amount));

        if (
            !IERC20(_USDT).transferFrom(
                _msgSender(),
                address(this),
                _amount * 10e17
            )
        ) {
            revert AllowanceIsLow();
        }
        uint256 _swap_amount = (USDT_USD_price() * _amount);

        if (_swap_amount > IERC20(token).balanceOf(address(this))) {
            revert BalanceLow();
        }

        uint256 _referral_percentage = getRefPercentage(_referral);
        uint256 percentage = ((base_fee + _referral_percentage) *
            _swap_amount) / 10000;

        IERC20(token).transfer(_msgSender(), _swap_amount - percentage);
        // send profit from the fees to the treasury contract right away
        IERC20(token).transfer(fee_wallet, percentage);

        referrals_amount[bytes32(bytes(_referral))] += _amount;
        emit swap_event(
            _USDT,
            _swap_amount,
            _referral,
            block.timestamp,
            _referral_percentage
        );
    }

    /**
    @dev checking to see how much we get in exchange of _amount_in of USDT
    @param _amount_in is the amount of USDT we want to send
    */
    function swap_USDT_view(uint256 _amount_in) public view returns (uint256) {
        // kovan
        // USDC/USD: 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60
        // USDT/USD: 0x2ca5A90D34cA333661083F89D831f757A9A50148
        return (USDT_USD_price() * _amount_in);
    }

    /**
    @dev USDT/USD price
    @return _USDT_price with 18 decimals
     */
    function USDT_USD_price() public view returns (uint256 _USDT_price) {
        (, int256 price, , , ) = priceFeed_USDT.latestRoundData();
        // it already has 8 decimals, we add another 10
        // to unify all calculations based on 18 decimal points of the SUSD
        return (uint256(price) * (10**10));
    }

    // ==================================== minting logic - USDC ====================================
    /**
    @dev sending USDC and swapping to SUSD
    @param _amount of USDC to send. user has to approve this contract to spend _amount of USDC before calling this function.
    @param _referral code 
     */
    function swap_by_USDC(uint256 _amount, string calldata _referral)
        public
        nonReentrant
        NotPaused
    {
        address _USDC = USDC;
        if (
            IERC20(_USDC).allowance(_msgSender(), address(this)) <
            _amount * 10e5 ||
            IERC20(_USDC).balanceOf(_msgSender()) < _amount * 10e5
        ) {
            revert AllowanceIsLow();
        }

        // checking and updating the limits before continue
        require(updateOrReject(_amount));

        if (
            !IERC20(_USDC).transferFrom(
                _msgSender(),
                address(this),
                _amount * 10e5
            )
        ) {
            revert AllowanceIsLow();
        }

        uint256 _swap_amount = (USDC_USD_price() * _amount);
        if (_swap_amount > IERC20(token).balanceOf(address(this))) {
            revert BalanceLow();
        }

        uint256 _referral_percentage = getRefPercentage(_referral);
        uint256 percentage = ((base_fee + _referral_percentage) *
            _swap_amount) / 10000;

        IERC20(token).transfer(_msgSender(), _swap_amount - percentage);
        // send profit from the fees to the treasury contract right away
        IERC20(token).transfer(fee_wallet, percentage);
        referrals_amount[bytes32(bytes(_referral))] += _amount;
        emit swap_event(
            _USDC,
            _swap_amount,
            _referral,
            block.timestamp,
            _referral_percentage
        );
    }

    /**
     * @dev updating and checking the limits
     * @param _amount of the swap
     */
    function updateOrReject(uint256 _amount) private NotPaused returns (bool) {
        if (
            (block.timestamp - last_update < 86400 &&
                total_swap_day > max_limit_day) ||
            _amount > max_limit_tx ||
            _amount + total_swap_day > max_limit_day
        ) {
            revert ExceedLimit();
        }

        if (block.timestamp - last_update >= 86400) {
            last_update = block.timestamp;
            total_swap_day = 0;
        }
        total_swap_day += _amount;
        return true;
    }

    /**
    @dev checking to see how much we get in exchange of _amount_in of USDC
    @param _amount_in is the amount of USDC we want to send
    */
    function swap_USDC_view(uint256 _amount_in) public view returns (uint256) {
        // kovan
        // USDC/USD: 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60
        // USDT/USD: 0x2ca5A90D34cA333661083F89D831f757A9A50148
        return (USDC_USD_price() * _amount_in);
    }

    /**
    @dev USDC/USD price
    @return _USDC_price with 18 decimals
     */
    function USDC_USD_price() public view returns (uint256 _USDC_price) {
        (, int256 price, , , ) = priceFeed_USDC.latestRoundData();
        // it already has 8 decimals, we add another 10
        // to unify all calculations based on 18 decimal points of the SUSD
        return (uint256(price) * (10**10));
    }

    // ==================================== Utils ====================================
    /**
    @dev Updating aggregators 
    * NOTE: false is USDC, true is USDT
    @param _newPriceFeed is the address of the new chainlink price feed aggregator
    @param _isUSDT determines whether we are updating USDT price feed or USDC. true means USDT, false means USDC
     */
    function updateAggr(address _newPriceFeed, bool _isUSDT)
        public
        AdminOnly
        NotPaused
    {
        if (_newPriceFeed == address(0)) {
            revert Address0();
        }
        if (_isUSDT) {
            priceFeed_USDT = AggregatorV3Interface(_newPriceFeed);
        } else {
            priceFeed_USDC = AggregatorV3Interface(_newPriceFeed);
        }

        emit AggregatorUpdated(_newPriceFeed, _isUSDT);
    }

    /**
     * @dev this is a rescue function in case of any ERC20 mistake deposit
     * @param _contract_address is the token contract address
     * Note: this function withdraw all holdings of the token to the treasury address
     */
    function rescue_erc20(address _contract_address)
        public
        AdminOnly
        nonReentrant
        NotPaused
    {
        IERC20(_contract_address).transfer(
            treasury_wallet,
            IERC20(_contract_address).balanceOf(address(this))
        );
        emit withdraw_event(_contract_address);
    }

    /**
     * @dev this is a rescue function in case of any ERC721 mistake deposit
     * @param _contract_address is the token contract address
     * @param _tokenID of the ERC721 item
     * Note: this function withdraw the ERC721 token to the treasury address
     */
    function rescue_erc721(address _contract_address, uint256 _tokenID)
        public
        AdminOnly
        nonReentrant
        NotPaused
    {
        IERC721(_contract_address).transferFrom(
            address(this),
            treasury_wallet,
            _tokenID
        );
        emit withdraw_event(_contract_address);
    }

    /**
     * @dev updating treasury wallet
     * @param _new_wallet address of the treasury
     * Note: only Admin can perform this function
     */
    function updateTreasuryWallet(address _new_wallet)
        public
        nonReentrant
        AdminOnly
        NotPaused
    {
        treasury_wallet = _new_wallet;
    }

    /**
     * @dev updating fee wallet
     * @param _new_wallet address of the fee wallet
     * Note: only Admin can perform this function
     */
    function updateFeeWallet(address _new_wallet)
        public
        nonReentrant
        AdminOnly
        NotPaused
    {
        fee_wallet = _new_wallet;
    }

    /**
     * @dev updating limits; daily and per transaction
     * @param _new_Limit in dollars
     * @param _isDaily if true mean its daily limit, if false means per transaction
     * Note: this is in USD no decimals
     */
    function updateLimit(uint256 _new_Limit, bool _isDaily)
        public
        AdminOnly
        NotPaused
    {
        if (_isDaily) {
            max_limit_day = _new_Limit;
            emit max_limit_day_updated(_new_Limit);
        } else {
            max_limit_tx = _new_Limit;
            emit max_limit_tx_updated(_new_Limit);
        }
    }

    /**
     * @dev get percentage of a referral code
     * @param _ref_code of the account to query
     * @return uint256 of the percentage in  bp
     * Note: view function which read percentage from ReferralDB contrat
     */
    function getRefPercentage(string calldata _ref_code)
        public
        view
        returns (uint256)
    {
        return REF_DB.referrals_mapping(bytes32(bytes(_ref_code)), 0);
    }

    /**
     * @dev set the referral contract address (ref storage)
     * @param _new_ref_add of the account to query
     * Note: Only admin can perform this action
     */
    function setRefContract(address _new_ref_add)
        public
        AdminOnly
        returns (uint256)
    {
        REF_DB = ReferralDB(_new_ref_add);
        emit referralContractAddressUpdated(_new_ref_add);
    }

    /**
     * @dev set the base percentage in bp
     * @param _new_base in bp - percentage * 10000
     * Note: Only admin can perform this action
     */
    function setBasePercentage(uint256 _new_base) public AdminOnly NotPaused {
        base_fee = _new_base;
        emit basePercentageUpdated(_new_base);
    }

    /**
     * @dev Pauses any transaction.
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        if (!hasRole(PAUSER_ROLE, _msgSender())) {
            revert Denied();
        }
        _pause();
    }

    /**
     * @dev Unpauses all transactions.
     * Requirements:
     *
     * - the caller   must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        if (!hasRole(PAUSER_ROLE, _msgSender())) {
            revert Denied();
        }
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControlEnumerable.sol";
import "AccessControl.sol";
import "EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "AccessControlEnumerable.sol";
import "Pausable.sol";
import "Context.sol";

error NotUpdater();
error WrongIndex();
error ContractPaused();
error Denied();

/**
 * @title Referal info contract
 */

contract ReferralDB is Context, AccessControlEnumerable, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    /**
     * @dev mapping of each referral code to its list of available info
     * Note: referral code => array of info
     */
    mapping(bytes32 => uint256[1000]) public referrals_mapping;

    /**
     * @dev keeps the description of each index of the referral info array
     * Note: index => decsription
     */
    mapping(uint256 => bytes32) public index_desc;

    // fires when an index of a user gets updated
    event updated(uint256 index, uint256 info, bytes32 code);

    // fires each time description gets updated
    event desc_updated(uint256 index, bytes32 desc);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(UPDATER_ROLE, _msgSender());
    }

    /**
     * @dev adding a new referral code
     * @param _index to be updated -- uint256
     * @param _info in uint256 to save in the index of the referrals array
     * @param _referral_code of the user -- bytes32
     * Note: only updater can perform this action
     */
    function update(
        uint256 _index,
        uint256 _info,
        bytes32 _referral_code
    ) public {
        if (paused()) {
            revert ContractPaused();
        }
        if (!hasRole(UPDATER_ROLE, _msgSender())) {
            revert NotUpdater();
        }

        if (_index > 999 || _index < 0) {
            revert WrongIndex();
        }

        referrals_mapping[_referral_code][_index] = _info;

        emit updated(_index, _info, _referral_code);
    }

    /**
     * @dev Pauses any transaction.
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        if (!hasRole(PAUSER_ROLE, _msgSender())) {
            revert Denied();
        }
        _pause();
    }

    /**
     * @dev Unpauses all transactions.
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        if (!hasRole(PAUSER_ROLE, _msgSender())) {
            revert Denied();
        }
        _unpause();
    }
}