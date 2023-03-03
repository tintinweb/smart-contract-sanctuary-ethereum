// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- Davos CDP database

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/VatLike.sol";

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Vat is VatLike, Initializable {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Vat/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "Vat/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }

    mapping(address => mapping (address => uint)) public can;
    function behalf(address bit, address usr) external auth { can[bit][usr] = 1; }
    function regard(address bit, address usr) external auth { can[bit][usr] = 0; }
    function hope(address usr) external { can[msg.sender][usr] = 1; }
    function nope(address usr) external { can[msg.sender][usr] = 0; }
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]
    mapping (address => uint256)                   public davos;  // [rad]
    mapping (address => uint256)                   public sin;  // [rad]

    uint256 public debt;  // Total Davos Issued    [rad]
    uint256 public vice;  // Total Unbacked Davos  [rad]
    uint256 public Line;  // Total Debt Ceiling  [rad]
    uint256 public live;  // Active Flag

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);

    // --- Init ---
    function initialize() public initializer {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function _add(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x + uint(y);
            require(y >= 0 || z <= x);
            require(y <= 0 || z >= x);
        }
    }
    function _sub(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x - uint(y);
            require(y <= 0 || z <= x);
            require(y >= 0 || z >= x);
        }
    }
    function _mul(uint x, int y) internal pure returns (int z) {
        unchecked {
            z = int(x) * y;
            require(int(x) >= 0);
            require(y == 0 || z / y == int(x));
        }
    }
    function _add(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }
    function _mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }

    // --- Administration ---
    function init(bytes32 ilk) external auth {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10 ** 27;
    }
    function file(bytes32 what, uint data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 ilk, bytes32 what, uint data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
        emit File(ilk, what, data);
    }
    function cage() external auth {
        live = 0;
    }

    function uncage() external auth {
        live = 1;
    }

    // --- Fungibility ---
    function slip(bytes32 ilk, address usr, int256 wad) external auth {
        gem[ilk][usr] = _add(gem[ilk][usr], wad);
    }
    function flux(bytes32 ilk, address src, address dst, uint256 wad) external auth {
        require(wish(src, msg.sender), "Vat/not-allowed");
        gem[ilk][src] = _sub(gem[ilk][src], wad);
        gem[ilk][dst] = _add(gem[ilk][dst], wad);
    }
    function move(address src, address dst, uint256 rad) external auth {
        require(wish(src, msg.sender), "Vat/not-allowed");
        davos[src] = _sub(davos[src], rad);
        davos[dst] = _add(davos[dst], rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- CDP Manipulation ---
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external auth {
        // system is live
        require(live == 1, "Vat/not-live");

        Urn memory urn = urns[i][u];
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int dtab = _mul(ilk.rate, dart);
        uint tab = _mul(ilk.rate, urn.art);
        debt     = _add(debt, dtab);

        // either debt has decreased, or debt ceilings are not exceeded
        require(either(dart <= 0, both(_mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)), "Vat/ceiling-exceeded");
        // urn is either less risky than before, or it is safe
        require(either(both(dart <= 0, dink >= 0), tab <= _mul(urn.ink, ilk.spot)), "Vat/not-safe");

        // urn is either more safe, or the owner consents
        require(either(both(dart <= 0, dink >= 0), wish(u, msg.sender)), "Vat/not-allowed-u");
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");

        gem[i][v] = _sub(gem[i][v], dink);
        davos[w]    = _add(davos[w],    dtab);

        urns[i][u] = urn;
        ilks[i]    = ilk;
    }

    // --- CDP Fungibility ---
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) external auth {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = _sub(u.ink, dink);
        u.art = _sub(u.art, dart);
        v.ink = _add(v.ink, dink);
        v.art = _add(v.art, dart);

        uint utab = _mul(u.art, i.rate);
        uint vtab = _mul(v.art, i.rate);

        // both sides consent
        require(both(wish(src, msg.sender), wish(dst, msg.sender)), "Vat/not-allowed");

        // both sides safe
        require(utab <= _mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= _mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
    }

    // --- CDP Confiscation ---
    function grab(bytes32 i, address u, address v, address w, int dink, int dart) external auth {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int dtab = _mul(ilk.rate, dart);

        gem[i][v] = _sub(gem[i][v], dink);
        sin[w]    = _sub(sin[w],    dtab);
        vice      = _sub(vice,      dtab);
    }

    // --- Settlement ---
    function heal(uint rad) external {
        address u = msg.sender;
        sin[u] = _sub(sin[u], rad);
        davos[u] = _sub(davos[u], rad);
        vice   = _sub(vice,   rad);
        debt   = _sub(debt,   rad);
    }
    function suck(address u, address v, uint rad) external auth {
        sin[u] = _add(sin[u], rad);
        davos[v] = _add(davos[v], rad);
        vice   = _add(vice,   rad);
        debt   = _add(debt,   rad);
    }

    // --- Rates ---
    function fold(bytes32 i, address u, int rate) external auth {
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];
        ilk.rate = _add(ilk.rate, rate);
        int rad  = _mul(ilk.Art, rate);
        davos[u]   = _add(davos[u], rad);
        debt     = _add(debt,   rad);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface VatLike {
    function init(bytes32 ilk) external;

    function hope(address usr) external;

    function nope(address usr) external;

    function rely(address usr) external;

    function deny(address usr) external;

    function move(address src, address dst, uint256 rad) external;

    function behalf(address bit, address usr) external;

    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;

    function flux(bytes32 ilk, address src, address dst, uint256 wad) external;

    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);

    function fold(bytes32 i, address u, int rate) external;

    function gem(bytes32, address) external view returns (uint256);

    function davos(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function file(bytes32, bytes32, uint) external;

    function sin(address) external view returns (uint256);

    function heal(uint rad) external;

    function suck(address u, address v, uint rad) external;

    function grab(bytes32,address,address,address,int256,int256) external;

    function slip(bytes32,address,int) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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