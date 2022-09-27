/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// hevm: flattened sources of src/fee-market/SimpleFeeMarket.sol
// SPDX-License-Identifier: GPL-3.0 AND MIT
pragma solidity =0.7.6;
pragma abicoder v2;

////// src/interfaces/IFeeMarket.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/// @title A interface for user to enroll to be a relayer.
/// @author echo
/// @notice After enroll to be a relyer , you have the duty to relay
/// the meesage which is assigned to you, or you will be slashed
interface IFeeMarket {
    //  Relayer which delivery the messages
    struct DeliveredRelayer {
        // relayer account
        address relayer;
        // encoded message key begin
        uint256 begin;
        // encoded message key end
        uint256 end;
    }
    /// @dev return the real time market maker fee
    /// @notice Revert `!top` when there is not enroll relayer in the fee-market
    function market_fee() external view returns (uint256 fee);
    // Assign new message encoded key to top N relayers in fee-market
    function assign(uint256 nonce) external payable returns(bool);
    // Settle delivered messages and reward/slash relayers
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external returns(bool);
}

////// src/proxy/transparent/Address.sol

/* pragma solidity 0.7.6; */

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

////// src/proxy/Initializable.sol
//
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

/* pragma solidity 0.7.6; */

/* import "./transparent/Address.sol"; */

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
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

////// src/fee-market/SimpleFeeMarket.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../interfaces/IFeeMarket.sol"; */
/* import "../proxy/Initializable.sol"; */

contract SimpleFeeMarket is Initializable, IFeeMarket {
    // Governance role to decide which outbounds message to relay
    address public setter;
    // All outbounds that message will be relayed by relayers
    mapping(address => uint256) public outbounds;
    // Balance of the relayer including deposit and eared fee
    mapping(address => uint256) public balanceOf;
    // Locked balance of relayer for relay messages
    mapping(address => uint256) public lockedOf;
    // All relayers in fee-market, they are linked one by one and sorted by the relayer fee asc
    mapping(address => address) public relayers;
    // Relayer count
    uint256 public relayerCount;
    // Maker fee of the relayer
    mapping(address => uint256) public feeOf;
    // Message encoded key => Order
    mapping(uint256 => Order) public orderOf;

    // The collateral relayer need to lock for each order
    uint256 public immutable COLLATERAL_PER_ORDER;
    // SlashAmount = COLLATERAL_PER_ORDER * LateTime / SLASH_TIME
    uint256 public immutable SLASH_TIME;
    // Time assigned relayer to relay messages
    uint256 public immutable RELAY_TIME;
    // RATIO_NUMERATOR of two chain's native token price, denominator of ratio is 1_000_000
    uint256 public immutable PRICE_RATIO_NUMERATOR;
    // Duty reward ratio
    uint256 public immutable DUTY_REWARD_RATIO;

    address private constant SENTINEL_HEAD = address(0x1);
    address private constant SENTINEL_TAIL = address(0x2);

    event Assigned(uint256 indexed key, uint256 timestamp, address relayer, uint256 collateral, uint256 fee);
    event Delist(address indexed prev, address indexed cur);
    event Deposit(address indexed dst, uint wad);
    event Enrol(address indexed prev, address indexed cur, uint fee);
    event Locked(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event Settled(uint256 indexed key, uint timestamp, address delivery, address confirm);
    event Slash(address indexed src, uint wad);
    event SetOutbound(address indexed out, uint256 flag);
    event UnLocked(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);

    struct Order {
        // Assigned time
        uint32 time;
        // Assigned relayer
        address relayer;
        // Assigned collateral
        uint256 collateral;
        // Assigned relayer maker fee
        uint256 makerFee;
    }

    modifier onlySetter {
        require(msg.sender == setter, "!auth");
        _;
    }

    modifier onlyOutBound() {
        require(outbounds[msg.sender] == 1, "!outbound");
        _;
    }

    modifier enoughBalance() {
        require(_enough_balance(msg.sender), "!balance");
        _;
    }

    function _enough_balance(address src) private view returns (bool)  {
        return balanceOf[src] >= COLLATERAL_PER_ORDER;
    }

    constructor(
        uint256 _collateral_perorder,
        uint256 _slash_time,
        uint256 _relay_time,
        uint256 _price_ratio_numerator,
        uint256 _duty_reward_ratio
    ) {
        require(_slash_time > 0 && _relay_time > 0, "!0");
        require(_price_ratio_numerator < 1_000_000, "!price_ratio");
        require(_duty_reward_ratio < 100);
        COLLATERAL_PER_ORDER = _collateral_perorder;
        SLASH_TIME = _slash_time;
        RELAY_TIME = _relay_time;
        PRICE_RATIO_NUMERATOR = _price_ratio_numerator;
        DUTY_REWARD_RATIO = _duty_reward_ratio;
    }

    function initialize() public initializer {
        __FM_init__(msg.sender);
    }

    function __FM_init__(address setter_) internal onlyInitializing {
        setter = setter_;
        relayers[SENTINEL_HEAD] = SENTINEL_TAIL;
        feeOf[SENTINEL_TAIL] = type(uint256).max;
    }

    receive() external payable {
        deposit();
    }

    function setSetter(address setter_) external onlySetter {
        setter = setter_;
    }

    function setOutbound(address out, uint256 flag) external onlySetter {
        outbounds[out] = flag;
        emit SetOutbound(out, flag);
    }

    function totalSupply() external view returns (uint) {
        return address(this).balance;
    }

    // Fetch the real time maket maker fee
    // Revert `!top` when there is not enroll relayer in the fee-market
    function market_fee() external view override returns (uint fee) {
        address top_relayer = getTopRelayer();
        return feeOf[top_relayer];
    }

    // Fetch the `count` of order book in fee-market
    // If flag set true, will ignore their balance
    // If flag set false, will ensure they have enough balance
    function getOrderBook(uint count, bool flag) external view returns (
        uint256,
        address[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        require(count <= relayerCount, "!count");
        address[] memory array1 = new address[](count);
        uint256[] memory array2 = new uint256[](count);
        uint256[] memory array3 = new uint256[](count);
        uint256[] memory array4 = new uint256[](count);
        uint index = 0;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < count) {
            if (flag || _enough_balance(cur)) {
                array1[index] = cur;
                array2[index] = feeOf[cur];
                array3[index] = balanceOf[cur];
                array4[index] = lockedOf[cur];
                index++;
            }
            cur = relayers[cur];
        }
        return (index, array1, array2, array3, array4);
    }

    // Find top lowest maker fee relayer
    function getTopRelayer() public view returns (address top) {
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL) {
            if (_enough_balance(cur)) {
                top = cur;
                break;
            }
            cur = relayers[cur];
        }
        require(top != address(0), "!top");
    }

    function isRelayer(address addr) public view returns (bool) {
        return addr != SENTINEL_HEAD && addr != SENTINEL_TAIL && relayers[addr] != address(0);
    }

    // Deposit native token as collateral to enrol relayer
    // Once the relayer is assigned to relay a new message
    // the deposited token of assigned relayer  will be locked
    // as collateral to relay the message, After the assigned message is settled
    // the locked token will be free
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw your free(including eared) balance anytime.
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    // Deposit native token and enrol to be a relayer
    function enroll(address prev, uint fee) external payable {
        deposit();
        enrol(prev, fee);
    }

    // Withdraw all balance and delist relayer role
    function leave(address prev) external {
        withdraw(balanceOf[msg.sender]);
        delist(prev);
    }

    // Enrol to be a relayer
    // `prev` is the previous relayer
    // `fee` is the maker fee to set, PrevFee <= CurFee <= NextFee
    function enrol(address prev, uint fee) public enoughBalance {
        address cur = msg.sender;
        address next = relayers[prev];
        require(
            cur != address(0) &&
            cur != SENTINEL_HEAD &&
            cur != SENTINEL_TAIL,
            "!valid"
        );
        // No duplicate relayer allowed.
        require(relayers[cur] == address(0), "!new");
        // Next relayer must in the list.
        require(next != address(0), "!next");
        // PrevFee <= CurFee <= NextFee
        require(feeOf[prev] <= fee && fee <= feeOf[next], "!fee");
        relayers[cur] = next;
        relayers[prev] = cur;
        feeOf[cur] = fee;
        relayerCount++;
        emit Enrol(prev, cur, fee);
    }

    // Delist the relayer from the fee-market
    function delist(address prev) public {
        _delist(prev, msg.sender);
    }

    function _delist(address prev, address cur) private {
        require(
            cur != address(0) &&
            cur != SENTINEL_HEAD &&
            cur != SENTINEL_TAIL,
            "!valid"
        );
        require(relayers[prev] == cur, "!cur");
        relayers[prev] = relayers[cur];
        relayers[cur] = address(0);
        feeOf[cur] = 0;
        relayerCount--;
        emit Delist(prev, cur);
    }

    // Prune relayers which have not enough collateral
    function prune(address prev, address cur) public {
        if (lockedOf[cur] == 0 && balanceOf[cur] < COLLATERAL_PER_ORDER) {
            _delist(prev, cur);
        }
    }

    // Move your position in the fee-market orderbook
    function move(address old_prev, address new_prev, uint new_fee) external {
        delist(old_prev);
        enrol(new_prev, new_fee);
    }

    // Assign new message with encoded key to top relayer in fee-market
    function assign(uint256 key) external override payable onlyOutBound returns (bool) {
        // Fetch top relayer
        address top_relayer = _get_and_prune_top_relayer();
        require(isRelayer(top_relayer), "!relayer");
        uint256 fee = feeOf[top_relayer];
        require(msg.value == fee, "!fee");
        uint256 _collateral = COLLATERAL_PER_ORDER;
        _lock(top_relayer, _collateral);
        // record the assigned time
        uint32 assign_time = uint32(block.timestamp);
        orderOf[key] = Order(assign_time, top_relayer, _collateral, fee);
        emit Assigned(key, assign_time, top_relayer, _collateral, fee);
        return true;
    }

    // Settle delivered messages and reward/slash relayers
    function settle(
        DeliveredRelayer[] calldata delivery_relayers,
        address confirm_relayer
    ) external override onlyOutBound returns (bool) {
        _pay_relayers_rewards(delivery_relayers, confirm_relayer);
        return true;
    }

    function _get_and_prune_top_relayer() private returns (address top) {
        address prev = SENTINEL_HEAD;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL) {
            if (_enough_balance(cur)) {
                top = cur;
                break;
            } else {
                prune(prev, cur);
                prev = cur;
                cur = relayers[cur];
            }
        }
    }

    function _lock(address to, uint wad) private {
        require(balanceOf[to] >= wad, "!lock");
        balanceOf[to] -= wad;
        lockedOf[to] += wad;
        emit Locked(to, wad);
    }

    function _unlock(address to, uint wad) private {
        require(lockedOf[to] >= wad, "!unlock");
        lockedOf[to] -= wad;
        balanceOf[to] += wad;
        emit UnLocked(to, wad);
    }

    function _slash_and_unlock(address src, uint c, uint s) private {
        require(lockedOf[src] >= c, "!unlock");
        require(c >= s, "!slash");
        lockedOf[src] -= c;
        balanceOf[src] += (c - s);
        emit UnLocked(src, c);
        emit Slash(src, s);
    }

    function _reward(address dst, uint wad) private {
        balanceOf[dst] += wad;
        emit Reward(dst, wad);
    }

    // Pay rewards to given relayers, optionally rewarding confirmation relayer.
    function _pay_relayers_rewards(DeliveredRelayer[] memory delivery_relayers, address confirm_relayer) private {
        uint256 total_confirm_reward = 0;
        for (uint256 i = 0; i < delivery_relayers.length; i++) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; key++) {
                uint256 assigned_time = orderOf[key].time;
                require(assigned_time > 0, "!exist");
                require(block.timestamp >= assigned_time, "!time");
                // diff_time = settle_time - assign_time
                uint256 diff_time = block.timestamp - assigned_time;
                // on time
                // [0, slot * 1)
                if (diff_time < RELAY_TIME) {
                    // Reward and unlock each assign_relayer
                    (uint256 delivery_reward, uint256 confirm_reward) = _reward_and_unlock_ontime(key,  entry.relayer, confirm_relayer);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                // too late
                // [slot * 1, +∞)
                } else {
                    // Slash and unlock each assign_relayer
                    uint256 late_time = diff_time - RELAY_TIME;
                    (uint256 delivery_reward, uint256 confirm_reward) = _slash_and_unlock_late(key, late_time);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                }
                delete orderOf[key];
                emit Settled(key, block.timestamp, entry.relayer, confirm_relayer);
            }
            // Reward every delivery relayer
            _reward(entry.relayer, every_delivery_reward);
        }
        // Reward confirm relayer
        _reward(confirm_relayer, total_confirm_reward);
    }

    function _reward_and_unlock_ontime(
        uint256 key,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        Order memory order = orderOf[key];
        address assign_relayer = order.relayer;
        // The message delivery in the `slot` assign_relayer
        (delivery_reward, confirm_reward) = _distribute_ontime(order.makerFee, assign_relayer, delivery_relayer, confirm_relayer);
        _unlock(assign_relayer, order.collateral);
    }

    function _slash_and_unlock_late(uint256 key, uint256 late_time) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        Order memory order = orderOf[key];
        uint256 message_fee = order.makerFee;
        uint256 collateral = order.collateral;
        // Slash fee is linear incremental, and the slop is `late_time / SLASH_TIME`
        uint256 slash_fee = late_time >= SLASH_TIME ? collateral : (collateral * late_time / SLASH_TIME);
        address assign_relayer = order.relayer;
        _slash_and_unlock(assign_relayer, collateral, slash_fee);
        // Reward_fee = message_fee + slash_fee
        (delivery_reward, confirm_reward) = _distribute_fee(message_fee + slash_fee);
    }

    function _distribute_ontime(
        uint256 message_fee,
        address assign_relayer,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        if (message_fee > 0) {
            // 60% * base fee => assigned_relayers_rewards
            uint256 assign_reward = message_fee * DUTY_REWARD_RATIO / 100;
            // 40% * base fee => other relayer
            uint256 other_reward = message_fee - assign_reward;
            (delivery_reward, confirm_reward) = _distribute_fee(other_reward);
            // If assign_relayer == delivery_relayer, we give the reward to delivery_relayer
            if (assign_relayer == delivery_relayer) {
                delivery_reward += assign_reward;
            // If assign_relayer == confirm_relayer, we give the reward to confirm_relayer
            } else if (assign_relayer == confirm_relayer) {
                confirm_reward += assign_reward;
            // Both not, we reward the assign_relayer directlly
            } else {
                _reward(assign_relayer, assign_reward);
            }
        }
    }

    function _distribute_fee(uint256 fee) private view returns (uint256 delivery_reward, uint256 confirm_reward) {
        // fee * PRICE_RATIO_NUMERATOR / 1_000_000 => delivery relayer
        delivery_reward = fee * PRICE_RATIO_NUMERATOR / 1_000_000;
        // remaining fee => confirm relayer
        confirm_reward = fee - delivery_reward;
    }
}