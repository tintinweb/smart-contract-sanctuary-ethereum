// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract HydraS1Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [8609986746108439658545470593166889256314951959466775818870246174320018498804,
             6848251127850009101372611262053374737897586140140607384018397707035108265914],
            [21367916863936594568281095443965096905143705300114190558130516981138584550504,
             13327705762185115653848159709412003423932761899188342359583872691135383932883]
        );
        vk.IC = new Pairing.G1Point[](11);
        
        vk.IC[0] = Pairing.G1Point( 
            19965766170734310004645394427613286415565755728797065894668054116047682895204,
            6952067612339183672227137101423582097916038093373585908267153974352032944482
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            3754737654948662562435613969155994959132173506784418442817218316697091994043,
            16520141448541154153981919757383608282199583682574061862571018786569723115048
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            14734466460881491794568175288621656907425457509621292263456156896685122952305,
            18495564446073110430251898491840031389094613665866187171071741938161262650771
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            13987716160490730015463796942940452666334097189904948795214986996497499925899,
            5336810094802209074340875836312868429276540870324469349093948627126061524544
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            14931593253473978964215343699995811275378324235306358485461293343370969283966,
            564306919152089917957316877787764763278299990971316475606280877961553231205
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            11591267743733991434114686002448165336885445656808796470854638278338319268343,
            11495219763417990955889652410266075210402006084183208750635660647824890013350
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            8183184532870222270700473518157259944911700429689031755853536692005688965081,
            9121077094104828462137861111631978599019724423614716723152060153405564278301
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            4314095526093128699362232919686741372014146055311239687202926853002748112330,
            11665330391505820654128458332883010598817535082070674418723503440883598640597
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            19602244162575575785636531633124796303002902053486919698240132790672698216585,
            181057165072599074288983745076121344893296348827576905983079816835912241514
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            18925967077785550270509493111690046951994174908254476036944536825999614778001,
            4990629719417206796668074534812314525340851981015724652256935997545282642849
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            7320700433668244102684846027945878190869912696586803178638351868907615350377,
            2941840530209756385349015075958743796933501451265755778001586753024906675441
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[10] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IHydraS1AccountboundAttester} from './interfaces/IHydraS1AccountboundAttester.sol';

// Core protocol Protocol imports
import {Request, Attestation, Claim} from '../../core/libs/Structs.sol';

// Imports related to Hydra-S1
import {HydraS1SimpleAttester, IAttester, HydraS1Lib, HydraS1ProofData, HydraS1Claim} from './HydraS1SimpleAttester.sol';

/**
 * @title  Hydra-S1 Accountbound Attester
 * @author Sismo
 * @notice This attester is part of the family of the Hydra-S1 Attesters.
 * Hydra-S1 attesters enable users to prove they have an account in a group in a privacy preserving way.
 * The Hydra-S1 Simple Attester contract is inherited and holds the complex Hydra S1 verification logic.
 * Request verification alongside proof verification is already implemented in the inherited HydraS1SimpleAttester, along with the buildAttestations logic.
 * However, we override the buildAttestations function to encode the nullifier and its burn count in the user attestation.
 * The _beforeRecordAttestations is also overriden to fit the Accountbound logic.
 * We invite readers to refer to:
 *    - https://hydra-s1.docs.sismo.io for a full guide through the Hydra-S1 ZK Attestations
 *    - https://hydra-s1-circuits.docs.sismo.io for circuits, prover and verifiers of Hydra-S1

 * This specific attester has the following characteristics:

 * - Zero Knowledge
 *   One cannot deduct from an attestation what source account was used to generate the underlying proof

 * - Non Strict (scores)
 *   If a user can generate an attestation of max value 100, they can also generate any attestation with value < 100.
 *   This attester generate attestations of scores

 * - Nullified
 *   Each source account gets one nullifier per claim (i.e only one attestation per source account per claim)
 *   While semaphore/ tornado cash are using the following notations: nullifierHash = hash(IdNullifier, externalNullifier)
 *   We prefered to use the naming 'nullifier' instead of 'nullifierHash' in our contracts and documentation.
 *   We also renamed 'IdNullifier' in 'sourceSecret' (the secret tied to a source account) and we kept the 'externalNullifier' notation.
 *   Finally, here is our notations at Sismo: nullifier = hash(sourceSecret, externalNullifier)

 * - Accountbound (opt-in, with cooldown period)
 *   The owner of this attester can set a cooldown duration for a specific group, activating the accountbound feature for this group.
 *   Users can update their attestation's destination by providing a new Hydra-S1 ZK proof 
 *   It means the attestation is bound to the source account, stored on an updatable destination account.
 *   When deleting/ sending to a new destination, the nullifier will enter a cooldown period, so it remains occasional.
 *   A group that has its cooldown duration set to 0 means it has been configured to not feature accountbound attestations, attestations can not be transferred
 *   One can however know that the former and the new destinations were created using the same nullifier, thus creating a link between those two destinations.
 
 * - Renewable
 *   A nullifier can actually be reused as long as the destination of the attestation remains the same
 *   It enables users to renew or update their attestations
 **/

contract HydraS1AccountboundAttester is
  IHydraS1AccountboundAttester,
  HydraS1SimpleAttester,
  Ownable
{
  using HydraS1Lib for HydraS1ProofData;
  using HydraS1Lib for bytes;
  using HydraS1Lib for Request;

  uint8 public constant IMPLEMENTATION_VERSION = 4;

  /*******************************************************
    Storage layout:
    20 slots between HydraS1SimpleAttester and HydraS1AccountboundAttester
      1 currently used by Ownable
      19 place holders
    2O for config
      1 currently used
      19 place holders
    20 for logic
      2 currently used
      18 place holders
  *******************************************************/

  // keeping some space for future config logics
  uint256[19] private _placeHolderBeforeHydraS1Accountbound;

  // cooldown durations for each groupIndex
  mapping(uint256 => uint32) internal _cooldownDurations;

  // keeping some space for future config logics
  uint256[19] private _placeHoldersHydraS1AccountboundConfig;

  mapping(uint256 => uint32) internal _nullifiersCooldownStart;
  mapping(uint256 => uint16) internal _nullifiersBurnCount;

  // keeping some space for future config logics
  uint256[18] private _placeHoldersHydraS1AccountboundLogic;

  /*******************************************************
    INITIALIZATION FUNCTIONS                           
  *******************************************************/
  /**
   * @dev Constructor. Initializes the contract
   * @param attestationsRegistryAddress Attestations Registry contract on which the attester will write attestations
   * @param hydraS1VerifierAddress ZK Snark Hydra-S1 Verifier contract
   * @param availableRootsRegistryAddress Registry storing the available groups for this attester (e.g roots of registry merkle trees)
   * @param commitmentMapperAddress commitment mapper's public key registry
   * @param collectionIdFirst Id of the first attestation collection in which the attester is supposed to record
   * @param collectionIdLast Id of the last attestation collection in which the attester is supposed to record
   * @param owner Address of attester's owner
   */
  constructor(
    address attestationsRegistryAddress,
    address hydraS1VerifierAddress,
    address availableRootsRegistryAddress,
    address commitmentMapperAddress,
    uint256 collectionIdFirst,
    uint256 collectionIdLast,
    address owner
  )
    HydraS1SimpleAttester(
      attestationsRegistryAddress,
      hydraS1VerifierAddress,
      availableRootsRegistryAddress,
      commitmentMapperAddress,
      collectionIdFirst,
      collectionIdLast
    )
  {
    initialize(owner);
  }

  /**
   * @dev Initialize function, to be called by the proxy delegating calls to this implementation
   * @param ownerAddress Owner of the contract, has the right to authorize/unauthorize attestations issuers
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(address ownerAddress) public reinitializer(IMPLEMENTATION_VERSION) {
    // if proxy did not setup owner yet or if called by constructor (for implem setup)
    if (owner() == address(0) || address(this).code.length == 0) {
      _transferOwnership(ownerAddress);
    }
  }

  /*******************************************************
    MANDATORY FUNCTIONS TO OVERRIDE FROM ATTESTER.SOL
  *******************************************************/

  /**
   * @dev Returns the actual attestations constructed from the user request
   * @param request users request. Claim of having an account part of a group of accounts
   * @param proofData snark public input as well as snark proof
   */
  function buildAttestations(
    Request calldata request,
    bytes calldata proofData
  ) public view virtual override(IAttester, HydraS1SimpleAttester) returns (Attestation[] memory) {
    Attestation[] memory attestations = super.buildAttestations(request, proofData);

    uint256 nullifier = proofData._getNullifier();
    attestations[0].extraData = abi.encodePacked(
      attestations[0].extraData, // nullifier, from HydraS1 Simple
      _getNextBurnCount(nullifier, attestations[0].owner) // BurnCount
    );

    return (attestations);
  }

  /*******************************************************
    OPTIONAL HOOK VIRTUAL FUNCTIONS FROM ATTESTER.SOL
  *******************************************************/
  /**
   * @dev Hook run before recording the attestation.
   * Throws if nullifier already used, not a renewal, and nullifier on cooldown.
   * @param request users request. Claim of having an account part of a group of accounts
   * @param proofData provided to back the request. snark input and snark proof
   */
  function _beforeRecordAttestations(
    Request calldata request,
    bytes calldata proofData
  ) internal virtual override {
    uint256 nullifier = proofData._getNullifier();
    address previousNullifierDestination = _getDestinationOfNullifier(nullifier);

    HydraS1Claim memory claim = request._claim();

    // check if the nullifier has already been used previously, if so it may be on cooldown
    if (
      previousNullifierDestination != address(0) &&
      previousNullifierDestination != claim.destination
    ) {
      uint32 cooldownDuration = _getCooldownDurationForGroupIndex(claim.groupProperties.groupIndex);
      if (cooldownDuration == 0) {
        revert CooldownDurationNotSetForGroupIndex(claim.groupProperties.groupIndex);
      }
      if (_isOnCooldown(nullifier, cooldownDuration)) {
        uint16 burnCount = _getNullifierBurnCount(nullifier);
        revert NullifierOnCooldown(
          nullifier,
          previousNullifierDestination,
          burnCount,
          cooldownDuration
        );
      }

      // Delete the old Attestation linked to the nullifier before recording the new one (accountbound feature)
      _deletePreviousAttestation(claim, previousNullifierDestination);

      _setNullifierOnCooldownAndIncrementBurnCount(nullifier);
    }
    _setDestinationForNullifier(nullifier, request.destination);
  }

  /*******************************************************
    LOGIC FUNCTIONS RELATED TO ACCOUNTBOUND FEATURE
  *******************************************************/

  /**
   * @dev Getter, returns the burnCount of a nullifier
   * @param nullifier nullifier used
   **/
  function getNullifierBurnCount(uint256 nullifier) external view returns (uint16) {
    return _getNullifierBurnCount(nullifier);
  }

  /**
   * @dev Getter, returns the cooldown start of a nullifier
   * @param nullifier nullifier used
   **/
  function getNullifierCooldownStart(uint256 nullifier) external view returns (uint32) {
    return _getNullifierCooldownStart(nullifier);
  }

  /**
   * @dev returns the nullifier for a given extraData
   * @param extraData bytes where the nullifier is encoded
   */
  function getNullifierFromExtraData(
    bytes memory extraData
  ) external pure override(HydraS1SimpleAttester, IHydraS1AccountboundAttester) returns (uint256) {
    (uint256 nullifier, ) = abi.decode(extraData, (uint256, uint16));

    return nullifier;
  }

  /**
   * @dev Returns the burn count for a given extraData
   * @param extraData bytes where the burnCount is encoded
   */
  function getBurnCountFromExtraData(bytes memory extraData) external pure returns (uint16) {
    (, uint16 burnCount) = abi.decode(extraData, (uint256, uint16));

    return burnCount;
  }

  /**
   * @dev Checks if a nullifier is on cooldown
   * @param nullifier user nullifier
   * @param cooldownDuration waiting time before the user can change its badge destination
   */
  function _isOnCooldown(uint256 nullifier, uint32 cooldownDuration) internal view returns (bool) {
    return _getNullifierCooldownStart(nullifier) + cooldownDuration > block.timestamp;
  }

  /**
   * @dev Delete the previous attestation created with this nullifier
   * @param claim user claim
   * @param previousNullifierDestination previous destination chosen for this user nullifier
   */
  function _deletePreviousAttestation(
    HydraS1Claim memory claim,
    address previousNullifierDestination
  ) internal {
    address[] memory attestationOwners = new address[](1);
    uint256[] memory attestationCollectionIds = new uint256[](1);

    attestationOwners[0] = previousNullifierDestination;
    attestationCollectionIds[0] = AUTHORIZED_COLLECTION_ID_FIRST + claim.groupProperties.groupIndex;

    ATTESTATIONS_REGISTRY.deleteAttestations(attestationOwners, attestationCollectionIds);
  }

  function _setNullifierOnCooldownAndIncrementBurnCount(uint256 nullifier) internal {
    _nullifiersCooldownStart[nullifier] = uint32(block.timestamp);
    _nullifiersBurnCount[nullifier] += 1;
    emit NullifierSetOnCooldown(nullifier, _nullifiersBurnCount[nullifier]);
  }

  function _getNullifierCooldownStart(uint256 nullifier) internal view returns (uint32) {
    return _nullifiersCooldownStart[nullifier];
  }

  function _getNullifierBurnCount(uint256 nullifier) internal view returns (uint16) {
    return _nullifiersBurnCount[nullifier];
  }

  /**
   * @dev returns burn count or burn count + 1 if new burn will happen
   * @param nullifier user nullifier
   * @param claimDestination destination referenced in the user claim
   */
  function _getNextBurnCount(
    uint256 nullifier,
    address claimDestination
  ) public view virtual returns (uint16) {
    address previousNullifierDestination = _getDestinationOfNullifier(nullifier);
    uint16 burnCount = _getNullifierBurnCount(nullifier);
    // If the attestation is minted on a new destination address
    // the burnCount that will be encoded in the extraData of the Attestation should be incremented
    if (
      previousNullifierDestination != address(0) && previousNullifierDestination != claimDestination
    ) {
      burnCount += 1;
    }
    return burnCount;
  }

  /*******************************************************
    GROUP CONFIGURATION LOGIC
  *******************************************************/

  /**
   * @dev Setter, sets the cooldown duration of a groupIndex
   * @notice set to 0 to deactivate the accountbound feature for this group
   * @param groupIndex internal collection id
   * @param cooldownDuration cooldown duration we want to set for the groupIndex
   **/
  function setCooldownDurationForGroupIndex(
    uint256 groupIndex,
    uint32 cooldownDuration
  ) external onlyOwner {
    _cooldownDurations[groupIndex] = cooldownDuration;
    emit CooldownDurationSetForGroupIndex(groupIndex, cooldownDuration);
  }

  /**
   * @dev Getter, get the cooldown duration of a groupIndex
   * @notice returns 0 when the accountbound feature is deactivated for this group
   * @param groupIndex internal collection id
   **/
  function getCooldownDurationForGroupIndex(uint256 groupIndex) external view returns (uint32) {
    return _getCooldownDurationForGroupIndex(groupIndex);
  }

  // = 0 means that the accountbound feature is deactivated for this group
  function _getCooldownDurationForGroupIndex(uint256 groupIndex) internal view returns (uint32) {
    return _cooldownDurations[groupIndex];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {IHydraS1SimpleAttester} from './interfaces/IHydraS1SimpleAttester.sol';
import {IHydraS1Base} from './base/IHydraS1Base.sol';

// Core protocol Protocol imports
import {Request, Attestation, Claim} from './../../core/libs/Structs.sol';
import {Attester, IAttester, IAttestationsRegistry} from './../../core/Attester.sol';

// Imports related to HydraS1 Proving Scheme
import {HydraS1Base, HydraS1Lib, HydraS1ProofData, HydraS1ProofInput, HydraS1Claim} from './base/HydraS1Base.sol';

/**
 * @title  Hydra-S1 Simple Attester
 * @author Sismo
 * @notice This attester is part of the family of the Hydra-S1 Attesters.
 * Hydra-S1 attesters enable users to prove they have an account in a group in a privacy preserving way.
 * The Hydra-S1 Base abstract contract is inherited and holds the complex Hydra S1 verification logic.
 * We invite readers to refer to:
 *    - https://hydra-s1.docs.sismo.io for a full guide through the Hydra-S1 ZK Attestations
 *    - https://hydra-s1-circuits.docs.sismo.io for circuits, prover and verifiers of Hydra-S1

 * This specific attester has the following characteristics:

 * - Zero Knowledge
 *   One cannot deduct from an attestation what source account was used to generate the underlying proof

 * - Non Strict (scores)
 *   If a user can generate an attestation of max value 100, they can also generate any attestation with value < 100.
 *   This attester generate attestations of scores

 * - Nullified
 *   Each source account gets one nullifier per claim (i.e only one attestation per source account per claim)
 *   For people used to semaphore/ tornado cash people:
 *   nullifier = hash(sourceSecret, externalNullifier) <=> nullifierHash = hash(IdNullifier, externalNullifier)
 
 * - Renewable
 *   A nullifier can actually be reused as long as the destination of the attestation remains the same
 *   It enables users to renew their attestations
 **/

contract HydraS1SimpleAttester is IHydraS1SimpleAttester, HydraS1Base {
  using HydraS1Lib for HydraS1ProofData;
  using HydraS1Lib for bytes;
  using HydraS1Lib for Request;

  // The deployed contract will need to be authorized to write into the Attestation registry
  // It should get write access on attestation collections from AUTHORIZED_COLLECTION_ID_FIRST to AUTHORIZED_COLLECTION_ID_LAST.
  uint256 public immutable AUTHORIZED_COLLECTION_ID_FIRST;
  uint256 public immutable AUTHORIZED_COLLECTION_ID_LAST;

  /*******************************************************
    Storage layout:
      20 slots for HydraS1
        1 slot used
        19 place holders
  *******************************************************/

  mapping(uint256 => address) internal _nullifiersDestinations;

  // keeping some space for future
  uint256[19] private _placeHoldersHydraS1Simple;

  /*******************************************************
    INITIALIZATION FUNCTIONS                           
  *******************************************************/
  /**
   * @dev Constructor. Initializes the contract
   * @param attestationsRegistryAddress Attestations Registry contract on which the attester will write attestations
   * @param hydraS1VerifierAddress ZK Snark Hydra-S1 Verifier contract
   * @param availableRootsRegistryAddress Registry storing the available groups for this attester (e.g roots of registry merkle trees)
   * @param commitmentMapperAddress commitment mapper's public key registry
   * @param collectionIdFirst Id of the first collection in which the attester is supposed to record
   * @param collectionIdLast Id of the last collection in which the attester is supposed to record
   */
  constructor(
    address attestationsRegistryAddress,
    address hydraS1VerifierAddress,
    address availableRootsRegistryAddress,
    address commitmentMapperAddress,
    uint256 collectionIdFirst,
    uint256 collectionIdLast
  )
    Attester(attestationsRegistryAddress)
    HydraS1Base(hydraS1VerifierAddress, availableRootsRegistryAddress, commitmentMapperAddress)
  {
    AUTHORIZED_COLLECTION_ID_FIRST = collectionIdFirst;
    AUTHORIZED_COLLECTION_ID_LAST = collectionIdLast;
  }

  /*******************************************************
    MANDATORY FUNCTIONS TO OVERRIDE FROM ATTESTER.SOL
  *******************************************************/

  /**
   * @dev Throws if user request is invalid when verified against
   * Look into HydraS1Base for more details
   * @param request users request. Claim of having an account part of a group of accounts
   * @param proofData provided to back the request. snark input and snark proof
   */
  function _verifyRequest(
    Request calldata request,
    bytes calldata proofData
  ) internal virtual override {
    HydraS1ProofData memory snarkProof = abi.decode(proofData, (HydraS1ProofData));
    HydraS1ProofInput memory snarkInput = snarkProof._input();
    HydraS1Claim memory claim = request._claim();

    // verifies that the proof corresponds to the claim
    _validateInput(claim, snarkInput);
    // verifies the proof validity
    _verifyProof(snarkProof);
  }

  /**
   * @dev Returns attestations that will be recorded, constructed from the user request
   * @param request users request. Claim of having an account part of a group of accounts
   */
  function buildAttestations(
    Request calldata request,
    bytes calldata proofData
  ) public view virtual override(IAttester, Attester) returns (Attestation[] memory) {
    HydraS1Claim memory claim = request._claim();

    Attestation[] memory attestations = new Attestation[](1);

    uint256 attestationCollectionId = AUTHORIZED_COLLECTION_ID_FIRST +
      claim.groupProperties.groupIndex;

    if (attestationCollectionId > AUTHORIZED_COLLECTION_ID_LAST)
      revert CollectionIdOutOfBound(attestationCollectionId);

    address issuer = address(this);

    uint256 nullifier = proofData._getNullifier();

    attestations[0] = Attestation(
      attestationCollectionId,
      claim.destination,
      issuer,
      claim.claimedValue,
      claim.groupProperties.generationTimestamp,
      abi.encode(nullifier)
    );
    return (attestations);
  }

  /*******************************************************
    OPTIONAL HOOK VIRTUAL FUNCTIONS FROM ATTESTER.SOL
  *******************************************************/

  /**
   * @dev Hook run before recording the attestation.
   * Throws if nullifier already used and not a renewal (e.g destination different that last)
   * @param request users request. Claim of having an account part of a group of accounts
   * @param proofData provided to back the request. snark input and snark proof
   */
  function _beforeRecordAttestations(
    Request calldata request,
    bytes calldata proofData
  ) internal virtual override {
    // we get the nullifier used from the snark input in the data provided
    uint256 nullifier = proofData._getNullifier();
    address currentDestination = _getDestinationOfNullifier(nullifier);

    if (currentDestination != address(0) && currentDestination != request.destination) {
      revert NullifierUsed(nullifier);
    }

    _setDestinationForNullifier(nullifier, request.destination);
  }

  /*******************************************************
    Hydra-S1 MANDATORY FUNCTIONS FROM Hydra-S1 Base Attester
  *******************************************************/

  /**
   * @dev Returns the external nullifier from a user claim
   * @param claim user Hydra-S1 claim = have an account with a specific value in a specific group
   * nullifier = hash(sourceSecretHash, externalNullifier), which is verified inside the snark
   * users bring sourceSecretHash as private input in snark which guarantees privacy
   
   * Here we chose externalNullifier = hash(attesterAddress, claim.GroupId)
   * Creates one nullifier per group, per user and makes sure no collision with other attester's nullifiers
  **/
  function _getExternalNullifierOfClaim(
    HydraS1Claim memory claim
  ) internal view override returns (uint256) {
    uint256 externalNullifier = _encodeInSnarkField(
      address(this),
      claim.groupProperties.groupIndex
    );
    return externalNullifier;
  }

  /**
   * @dev returns the nullifier for a given extraData
   * @param extraData bytes where the nullifier is encoded
   */
  function getNullifierFromExtraData(
    bytes memory extraData
  ) external pure virtual override(IHydraS1Base, HydraS1Base) returns (uint256) {
    return abi.decode(extraData, (uint256));
  }

  /*******************************************************
    Hydra-S1 Attester Specific Functions
  *******************************************************/

  /**
   * @dev Getter, returns the last attestation destination of a nullifier
   * @param nullifier nullifier used
   **/
  function getDestinationOfNullifier(uint256 nullifier) external view override returns (address) {
    return _getDestinationOfNullifier(nullifier);
  }

  function _setDestinationForNullifier(uint256 nullifier, address destination) internal virtual {
    _nullifiersDestinations[nullifier] = destination;
    emit NullifierDestinationUpdated(nullifier, destination);
  }

  function _getDestinationOfNullifier(uint256 nullifier) internal view returns (address) {
    return _nullifiersDestinations[nullifier];
  }

  function _encodeInSnarkField(address addr, uint256 nb) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(addr, nb))) % HydraS1Lib.SNARK_FIELD;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {IHydraS1Base} from './IHydraS1Base.sol';
import {Attester} from '../../../core/Attester.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

// Protocol imports
import {Request, Attestation, Claim} from '../../../core/libs/Structs.sol';

// Imports related to Hydra S1 ZK Proving Scheme
import {HydraS1Verifier, HydraS1Lib, HydraS1Claim, HydraS1ProofData, HydraS1ProofInput, HydraS1GroupProperties} from '../libs/HydraS1Lib.sol';
import {ICommitmentMapperRegistry} from '../../../periphery/utils/CommitmentMapperRegistry.sol';
import {IAvailableRootsRegistry} from '../../../periphery/utils/AvailableRootsRegistry.sol';

/**
 * @title Hydra-S1 Base Attester
 * @author Sismo
 * @notice Abstract contract that facilitates the use of the Hydra-S1 ZK Proving Scheme.
 * Hydra-S1 is single source, single group: it allows users to verify they are part of one and only one group at a time
 * It is inherited by the family of Hydra-S1 attesters.
 * It contains the user input checking and the ZK-SNARK proof verification.
 * We invite readers to refer to the following:
 *    - https://hydra-s1.docs.sismo.io for a full guide through the Hydra-S1 ZK Attestations
 *    - https://hydra-s1-circuits.docs.sismo.io for circuits, prover and verifiers of Hydra-S1
 *
 */
abstract contract HydraS1Base is IHydraS1Base, Attester, Initializable {
  using HydraS1Lib for HydraS1ProofData;

  // ZK-SNARK Verifier
  HydraS1Verifier immutable VERIFIER;
  // Registry storing the Commitment Mapper EdDSA Public key
  ICommitmentMapperRegistry immutable COMMITMENT_MAPPER_REGISTRY;
  // Registry storing the Registry Tree Roots of the Attester's available ClaimData
  IAvailableRootsRegistry immutable AVAILABLE_ROOTS_REGISTRY;

  /*******************************************************
    INITIALIZATION FUNCTIONS
  *******************************************************/

  /**
   * @dev Constructor. Initializes the contract
   * @param hydraS1VerifierAddress ZK Snark Verifier contract
   * @param availableRootsRegistryAddress Registry where is the Available Data (Registry Merkle Roots)
   * @param commitmentMapperAddress Commitment mapper's public key registry
   */
  constructor(
    address hydraS1VerifierAddress,
    address availableRootsRegistryAddress,
    address commitmentMapperAddress
  ) {
    VERIFIER = HydraS1Verifier(hydraS1VerifierAddress);
    AVAILABLE_ROOTS_REGISTRY = IAvailableRootsRegistry(availableRootsRegistryAddress);
    COMMITMENT_MAPPER_REGISTRY = ICommitmentMapperRegistry(commitmentMapperAddress);
  }

  /**
   * @dev Getter of Hydra-S1 Verifier contract
   */
  function getVerifier() external view returns (HydraS1Verifier) {
    return VERIFIER;
  }

  /**
   * @dev Getter of Commitment Mapper Registry contract
   */
  function getCommitmentMapperRegistry() external view returns (ICommitmentMapperRegistry) {
    return COMMITMENT_MAPPER_REGISTRY;
  }

  /**
   * @dev Getter of Roots Registry Contract
   */
  function getAvailableRootsRegistry() external view returns (IAvailableRootsRegistry) {
    return AVAILABLE_ROOTS_REGISTRY;
  }

  /*******************************************************
    Hydra-S1 SPECIFIC FUNCTIONS
  *******************************************************/

  /**
   * @dev MANDATORY: must be implemented to return the nullifier from an attestation extraData
   * @dev Getter of a nullifier encoded in extraData
   * @notice Must be implemented by the inheriting contracts
   * @param extraData extraData where nullifier can be encoded
   */
  function getNullifierFromExtraData(
    bytes memory extraData
  ) external view virtual returns (uint256);

  /**
   * @dev MANDATORY: must be implemented to return the external nullifier from a user request
   * so it can be checked against snark input
   * nullifier = hash(sourceSecretHash, externalNullifier), which is verified inside the snark
   * users bring sourceSecretHash as private input which guarantees privacy
   *
   * This function MUST be implemented by Hydra-S1 attesters.
   * This is the core function that implements the logic of external nullifiers
   *
   * Do they get one external nullifier per claim?
   * Do they get 2 external nullifiers per claim?
   * Do they get 1 external nullifier per claim, every month?
   * Take a look at Hydra-S1 Simple Attester for an example
   * @param claim user claim: part of a group of accounts, with a claimedValue for their account
   */
  function _getExternalNullifierOfClaim(
    HydraS1Claim memory claim
  ) internal view virtual returns (uint256);

  /**
   * @dev Checks whether the user claim and the snark public input are a match
   * @param claim user claim
   * @param input snark public input
   */
  function _validateInput(
    HydraS1Claim memory claim,
    HydraS1ProofInput memory input
  ) internal view virtual {
    if (input.accountsTreeValue != claim.groupId) {
      revert AccountsTreeValueMismatch(claim.groupId, input.accountsTreeValue);
    }

    if (input.isStrict == claim.groupProperties.isScore) {
      revert IsStrictMismatch(claim.groupProperties.isScore, input.isStrict);
    }

    if (input.destination != claim.destination) {
      revert DestinationMismatch(claim.destination, input.destination);
    }

    if (input.chainId != block.chainid) revert ChainIdMismatch(block.chainid, input.chainId);

    if (input.value != claim.claimedValue) revert ValueMismatch(claim.claimedValue, input.value);

    if (!AVAILABLE_ROOTS_REGISTRY.isRootAvailableForMe(input.registryRoot)) {
      revert RegistryRootMismatch(input.registryRoot);
    }

    uint256[2] memory commitmentMapperPubKey = COMMITMENT_MAPPER_REGISTRY.getEdDSAPubKey();
    if (
      input.commitmentMapperPubKey[0] != commitmentMapperPubKey[0] ||
      input.commitmentMapperPubKey[1] != commitmentMapperPubKey[1]
    ) {
      revert CommitmentMapperPubKeyMismatch(
        commitmentMapperPubKey[0],
        commitmentMapperPubKey[1],
        input.commitmentMapperPubKey[0],
        input.commitmentMapperPubKey[1]
      );
    }

    uint256 externalNullifier = _getExternalNullifierOfClaim(claim);

    if (input.externalNullifier != externalNullifier) {
      revert ExternalNullifierMismatch(externalNullifier, input.externalNullifier);
    }
  }

  /**
   * @dev verify the groth16 mathematical proof
   * @param proofData snark public input
   */
  function _verifyProof(HydraS1ProofData memory proofData) internal view virtual {
    try
      VERIFIER.verifyProof(proofData.proof.a, proofData.proof.b, proofData.proof.c, proofData.input)
    returns (bool success) {
      if (!success) revert InvalidGroth16Proof('');
    } catch Error(string memory reason) {
      revert InvalidGroth16Proof(reason);
    } catch Panic(uint256 /*errorCode*/) {
      revert InvalidGroth16Proof('');
    } catch (bytes memory /*lowLevelData*/) {
      revert InvalidGroth16Proof('');
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {IAttester} from '../../../core/interfaces/IAttester.sol';
import {HydraS1Verifier, HydraS1Lib, HydraS1ProofData} from '../libs/HydraS1Lib.sol';
import {ICommitmentMapperRegistry} from '../../../periphery/utils/CommitmentMapperRegistry.sol';
import {IAvailableRootsRegistry} from '../../../periphery/utils/AvailableRootsRegistry.sol';

/**
 * @title Hydra-S1 Base Interface
 * @author Sismo
 * @notice Interface that facilitates the use of the Hydra-S1 ZK Proving Scheme.
 * Hydra-S1 is single source, single group: it allows users to verify they are part of one and only one group at a time
 * It is inherited by the family of Hydra-S1 attesters.
 * It contains the errors and method specific of the Hydra-S1 attesters family and the Hydra-S1 ZK Proving Scheme
 * We invite readers to refer to the following:
 *    - https://hydra-s1.docs.sismo.io for a full guide through the Hydra-S1 ZK Attestations
 *    - https://hydra-s1-circuits.docs.sismo.io for circuits, prover and verifiers of Hydra-S1
 **/
interface IHydraS1Base is IAttester {
  error ClaimsLengthDifferentThanOne(uint256 claimLength);
  error RegistryRootMismatch(uint256 inputRoot);
  error DestinationMismatch(address expectedDestination, address inputDestination);
  error CommitmentMapperPubKeyMismatch(
    uint256 expectedX,
    uint256 expectedY,
    uint256 inputX,
    uint256 inputY
  );
  error ExternalNullifierMismatch(uint256 expectedExternalNullifier, uint256 externalNullifier);
  error IsStrictMismatch(bool expectedStrictness, bool strictNess);
  error ChainIdMismatch(uint256 expectedChainId, uint256 chainId);
  error ValueMismatch(uint256 expectedValue, uint256 inputValue);
  error AccountsTreeValueMismatch(
    uint256 expectedAccountsTreeValue,
    uint256 inputAccountsTreeValue
  );
  error InvalidGroth16Proof(string reason);

  function getNullifierFromExtraData(bytes memory extraData) external view returns (uint256);

  /**
   * @dev Getter of Hydra-S1 Verifier contract
   */
  function getVerifier() external view returns (HydraS1Verifier);

  /**
   * @dev Getter of Commitment Mapper Registry contract
   */
  function getCommitmentMapperRegistry() external view returns (ICommitmentMapperRegistry);

  /**
   * @dev Getter of Roots Registry Contract
   */
  function getAvailableRootsRegistry() external view returns (IAvailableRootsRegistry);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {IHydraS1SimpleAttester} from '././IHydraS1SimpleAttester.sol';

/**
 * @title Hydra-S1 Accountbound Interface
 * @author Sismo
 * @notice Interface of the HydraS1AccountboundAttester contract which inherits from the errors, events and methods specific to the HydraS1SimpleAttester interface.
 **/
interface IHydraS1AccountboundAttester is IHydraS1SimpleAttester {
  /**
   * @dev Event emitted when the duration of the cooldown duration for a group index (internal collection id) has been set
   * @param groupIndex internal collection id
   * @param cooldownDuration the duration of the cooldown period
   **/
  event CooldownDurationSetForGroupIndex(uint256 indexed groupIndex, uint32 cooldownDuration);

  /**
   * @dev Event emitted when the nullifier has been set on cooldown. This happens when the
   * attestation destination of a nullifier has been changed
   * @param nullifier user nullifier
   * @param burnCount the number of times the attestation destination of a nullifier has been changed
   **/
  event NullifierSetOnCooldown(uint256 indexed nullifier, uint16 burnCount);

  /**
   * @dev Error when the nullifier is on cooldown. The user have to wait the cooldownDuration
   * before being able to change again the destination address.
   **/
  error NullifierOnCooldown(
    uint256 nullifier,
    address destination,
    uint16 burnCount,
    uint32 cooldownStart
  );

  /**
   * @dev Error when the cooldown duration for a given groupIndex is equal to zero.
   * The HydraS1AccountboundAttester behaves like the HydraS1SimpleAttester.
   **/
  error CooldownDurationNotSetForGroupIndex(uint256 groupIndex);

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   */
  function initialize(address owner) external;

  /**
   * @dev returns the nullifier for a given extraData
   * @param extraData bytes where the nullifier is encoded
   */
  function getNullifierFromExtraData(bytes memory extraData) external pure returns (uint256);

  /**
   * @dev Returns the burn count for a given extraData
   * @param extraData bytes where the burnCount is encoded
   */
  function getBurnCountFromExtraData(bytes memory extraData) external pure returns (uint16);

  /**
   * @dev Getter, returns the cooldown start of a nullifier
   * @param nullifier nullifier used
   **/
  function getNullifierCooldownStart(uint256 nullifier) external view returns (uint32);

  /**
   * @dev Getter, returns the burnCount of a nullifier
   * @param nullifier nullifier used
   **/
  function getNullifierBurnCount(uint256 nullifier) external view returns (uint16);

  /**
   * @dev Setter, sets the cooldown duration of a groupIndex
   * @param groupIndex internal collection id
   * @param cooldownDuration cooldown duration we want to set for the groupIndex
   **/
  function setCooldownDurationForGroupIndex(uint256 groupIndex, uint32 cooldownDuration) external;

  /*/**
   * @dev Getter, get the cooldown duration of a groupIndex
   * @notice returns 0 when the accountbound feature is deactivated for this group
   * @param groupIndex internal collection id
   **/
  function getCooldownDurationForGroupIndex(uint256 groupIndex) external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import {Attestation} from '../../../core/libs/Structs.sol';
import {CommitmentMapperRegistry} from '../../../periphery/utils/CommitmentMapperRegistry.sol';
import {AvailableRootsRegistry} from '../../../periphery/utils/AvailableRootsRegistry.sol';
import {HydraS1Lib, HydraS1ProofData, HydraS1ProofInput} from './../libs/HydraS1Lib.sol';
import {IHydraS1Base} from './../base/IHydraS1Base.sol';

/**
 * @title Hydra-S1 Accountbound Interface
 * @author Sismo
 * @notice Interface with errors, events and methods specific to the HydraS1SimpleAttester.
 **/
interface IHydraS1SimpleAttester is IHydraS1Base {
  /**
   * @dev Error when the nullifier is already used for a destination address
   **/
  error NullifierUsed(uint256 nullifier);

  /**
   * @dev Error when the collectionId of an attestation overflow the AUTHORIZED_COLLECTION_ID_LAST
   **/
  error CollectionIdOutOfBound(uint256 collectionId);

  /**
   * @dev Event emitted when the nullifier is associated to a destination address.
   **/
  event NullifierDestinationUpdated(uint256 nullifier, address newOwner);

  /**
   * @dev Getter, returns the last attestation destination of a nullifier
   * @param nullifier nullifier used
   **/
  function getDestinationOfNullifier(uint256 nullifier) external view returns (address);

  /**
   * @dev Getter
   * returns of the first collection in which the attester is supposed to record
   **/
  function AUTHORIZED_COLLECTION_ID_FIRST() external view returns (uint256);

  /**
   * @dev Getter
   * returns of the last collection in which the attester is supposed to record
   **/
  function AUTHORIZED_COLLECTION_ID_LAST() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Claim, Request} from '../../../core/libs/Structs.sol';
import {HydraS1Verifier} from '@sismo-core/hydra-s1/contracts/HydraS1Verifier.sol';

// user Hydra-S1 claim retrieved form his request
struct HydraS1Claim {
  uint256 groupId; // user claims to have an account in this group
  uint256 claimedValue; // user claims this value for its account in the group
  address destination; // user claims to own this destination[]
  HydraS1GroupProperties groupProperties; // user claims the group has the following properties
}

struct HydraS1GroupProperties {
  uint128 groupIndex;
  uint32 generationTimestamp;
  bool isScore;
}

struct HydraS1CircomSnarkProof {
  uint256[2] a;
  uint256[2][2] b;
  uint256[2] c;
}

struct HydraS1ProofData {
  HydraS1CircomSnarkProof proof;
  uint256[10] input;
  // destination
  // chainId
  // commitmentMapperPubKey.x
  // commitmentMapperPubKey.y
  // registryTreeRoot
  // externalNullifier
  // nullifier
  // claimedValue
  // accountsTreeValue
  // isStrict
}

struct HydraS1ProofInput {
  address destination;
  uint256 chainId;
  uint256 registryRoot;
  uint256 externalNullifier;
  uint256 nullifier;
  uint256 value;
  uint256 accountsTreeValue;
  bool isStrict;
  uint256[2] commitmentMapperPubKey;
}

library HydraS1Lib {
  uint256 constant SNARK_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  error GroupIdAndPropertiesMismatch(uint256 expectedGroupId, uint256 groupId);

  function _input(HydraS1ProofData memory self) internal pure returns (HydraS1ProofInput memory) {
    return
      HydraS1ProofInput(
        _getDestination(self),
        _getChainId(self),
        _getRegistryRoot(self),
        _getExpectedExternalNullifier(self),
        _getNullifier(self),
        _getValue(self),
        _getAccountsTreeValue(self),
        _getIsStrict(self),
        _getCommitmentMapperPubKey(self)
      );
  }

  function _claim(Request memory self) internal pure returns (HydraS1Claim memory) {
    Claim memory claim = self.claims[0];
    _validateClaim(claim);

    HydraS1GroupProperties memory groupProperties = abi.decode(
      claim.extraData,
      (HydraS1GroupProperties)
    );

    return (HydraS1Claim(claim.groupId, claim.claimedValue, self.destination, groupProperties));
  }

  function _toCircomFormat(
    HydraS1ProofData memory self
  )
    internal
    pure
    returns (uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[10] memory)
  {
    return (self.proof.a, self.proof.b, self.proof.c, self.input);
  }

  function _getDestination(HydraS1ProofData memory self) internal pure returns (address) {
    return address(uint160(self.input[0]));
  }

  function _getChainId(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[1];
  }

  function _getCommitmentMapperPubKey(
    HydraS1ProofData memory self
  ) internal pure returns (uint256[2] memory) {
    return [self.input[2], self.input[3]];
  }

  function _getRegistryRoot(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[4];
  }

  function _getExpectedExternalNullifier(
    HydraS1ProofData memory self
  ) internal pure returns (uint256) {
    return self.input[5];
  }

  function _getNullifier(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[6];
  }

  function _getValue(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[7];
  }

  function _getAccountsTreeValue(HydraS1ProofData memory self) internal pure returns (uint256) {
    return self.input[8];
  }

  function _getIsStrict(HydraS1ProofData memory self) internal pure returns (bool) {
    return self.input[9] == 1;
  }

  function _getNullifier(bytes calldata self) internal pure returns (uint256) {
    HydraS1ProofData memory snarkProofData = abi.decode(self, (HydraS1ProofData));
    uint256 nullifier = uint256(_getNullifier(snarkProofData));
    return nullifier;
  }

  function _generateGroupIdFromProperties(
    uint128 groupIndex,
    uint32 generationTimestamp,
    bool isScore
  ) internal pure returns (uint256) {
    return
      _generateGroupIdFromEncodedProperties(
        _encodeGroupProperties(groupIndex, generationTimestamp, isScore)
      );
  }

  function _generateGroupIdFromEncodedProperties(
    bytes memory encodedProperties
  ) internal pure returns (uint256) {
    return uint256(keccak256(encodedProperties)) % HydraS1Lib.SNARK_FIELD;
  }

  function _encodeGroupProperties(
    uint128 groupIndex,
    uint32 generationTimestamp,
    bool isScore
  ) internal pure returns (bytes memory) {
    return abi.encode(groupIndex, generationTimestamp, isScore);
  }

  function _validateClaim(Claim memory claim) internal pure {
    uint256 expectedGroupId = _generateGroupIdFromEncodedProperties(claim.extraData);
    if (claim.groupId != expectedGroupId)
      revert GroupIdAndPropertiesMismatch(expectedGroupId, claim.groupId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import {IAttester} from './interfaces/IAttester.sol';
import {IAttestationsRegistry} from './interfaces/IAttestationsRegistry.sol';
import {Request, Attestation, AttestationData} from './libs/Structs.sol';

/**
 * @title Attester Abstract Contract
 * @author Sismo
 * @notice Contract to be inherited by Attesters
 * All attesters that expect to be authorized in Sismo Protocol (i.e write access on the registry)
 * are recommended to implemented this abstract contract

 * Take a look at the HydraS1SimpleAttester.sol for example on how to implement this abstract contract
 *
 * This contracts is built around two main external standard functions.
 * They must NOT be override them, unless your really know what you are doing
 
 * - generateAttestations(request, proof) => will write attestations in the registry
 * 1. (MANDATORY) Implement the buildAttestations() view function which generate attestations from user request
 * 2. (MANDATORY) Implement teh _verifyRequest() internal function where to write checks
 * 3. (OPTIONAL)  Override _beforeRecordAttestations and _afterRecordAttestations hooks

 * - deleteAttestations(collectionId, owner, proof) => will delete attestations in the registry
 * 1. (DEFAULT)  By default this function throws (see _verifyAttestationsDeletionRequest)
 * 2. (OPTIONAL) Override the _verifyAttestationsDeletionRequest so it no longer throws
 * 3. (OPTIONAL) Override _beforeDeleteAttestations and _afterDeleteAttestations hooks

 * For more information: https://attesters.docs.sismo.io
 **/
abstract contract Attester is IAttester {
  // Registry where all attestations are stored
  IAttestationsRegistry internal immutable ATTESTATIONS_REGISTRY;

  /**
   * @dev Constructor
   * @param attestationsRegistryAddress The address of the AttestationsRegistry contract storing attestations
   */
  constructor(address attestationsRegistryAddress) {
    ATTESTATIONS_REGISTRY = IAttestationsRegistry(attestationsRegistryAddress);
  }

  /**
   * @dev Main external function. Allows to generate attestations by making a request and submitting proof
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that has been recorded
   */
  function generateAttestations(
    Request calldata request,
    bytes calldata proofData
  ) external override returns (Attestation[] memory) {
    // Verify if request is valid by verifying against proof
    _verifyRequest(request, proofData);

    // Generate the actual attestations from user request
    Attestation[] memory attestations = buildAttestations(request, proofData);

    _beforeRecordAttestations(request, proofData);

    ATTESTATIONS_REGISTRY.recordAttestations(attestations);

    _afterRecordAttestations(attestations);

    for (uint256 i = 0; i < attestations.length; i++) {
      emit AttestationGenerated(attestations[i]);
    }

    return attestations;
  }

  /**
   * @dev External facing function. Allows to delete attestations by submitting proof
   * @param collectionIds Collection identifier of attestations to delete
   * @param attestationsOwner Owner of attestations to delete
   * @param proofData Data sent along the deletion request to prove its validity
   * @return attestations Attestations that were deleted
   */
  function deleteAttestations(
    uint256[] calldata collectionIds,
    address attestationsOwner,
    bytes calldata proofData
  ) external override returns (Attestation[] memory) {
    address[] memory attestationOwners = new address[](collectionIds.length);

    uint256[] memory attestationCollectionIds = new uint256[](collectionIds.length);

    Attestation[] memory attestations = new Attestation[](collectionIds.length);

    for (uint256 i = 0; i < collectionIds.length; i++) {
      // fetch attestations from the registry
      (
        address issuer,
        uint256 attestationValue,
        uint32 timestamp,
        bytes memory extraData
      ) = ATTESTATIONS_REGISTRY.getAttestationDataTuple(collectionIds[i], attestationsOwner);

      attestationOwners[i] = attestationsOwner;
      attestationCollectionIds[i] = collectionIds[i];

      attestations[i] = (
        Attestation(
          collectionIds[i],
          attestationsOwner,
          issuer,
          attestationValue,
          timestamp,
          extraData
        )
      );
    }

    _verifyAttestationsDeletionRequest(attestations, proofData);

    _beforeDeleteAttestations(attestations, proofData);

    ATTESTATIONS_REGISTRY.deleteAttestations(attestationOwners, attestationCollectionIds);

    _afterDeleteAttestations(attestations, proofData);

    for (uint256 i = 0; i < collectionIds.length; i++) {
      emit AttestationDeleted(attestations[i]);
    }
    return attestations;
  }

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should build attestations from the user request and the proof
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function buildAttestations(
    Request calldata request,
    bytes calldata proofData
  ) public view virtual returns (Attestation[] memory);

  /**
   * @dev Attestation registry getter
   * @return attestationRegistry
   */
  function getAttestationRegistry() external view override returns (IAttestationsRegistry) {
    return ATTESTATIONS_REGISTRY;
  }

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should verify the user request is valid
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   */
  function _verifyRequest(Request calldata request, bytes calldata proofData) internal virtual;

  /**
   * @dev Optional: must be overridden by attesters that want to feature attestations deletion
   * Default behavior: throws
   * It should verify attestations deletion request is valid
   * @param attestations Attestations that will be deleted
   * @param proofData Data sent along the request to prove its validity
   */
  function _verifyAttestationsDeletionRequest(
    Attestation[] memory attestations,
    bytes calldata proofData
  ) internal virtual {
    revert AttestationDeletionNotImplemented();
  }

  /**
   * @dev Optional: Hook, can be overridden in attesters
   * Will be called before recording attestations in the registry
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   */
  function _beforeRecordAttestations(
    Request calldata request,
    bytes calldata proofData
  ) internal virtual {}

  /**
   * @dev (Optional) Can be overridden in attesters inheriting this contract
   * Will be called after recording an attestation
   * @param attestations Recorded attestations
   */
  function _afterRecordAttestations(Attestation[] memory attestations) internal virtual {}

  /**
   * @dev Optional: Hook, can be overridden in attesters
   * Will be called before deleting attestations from the registry
   * @param attestations Attestations to delete
   * @param proofData Data sent along the deletion request to prove its validity
   */
  function _beforeDeleteAttestations(
    Attestation[] memory attestations,
    bytes calldata proofData
  ) internal virtual {}

  /**
   * @dev Optional: Hook, can be overridden in attesters
   * Will be called after deleting attestations from the registry
   * @param attestations Attestations to delete
   * @param proofData Data sent along the deletion request to prove its validity
   */
  function _afterDeleteAttestations(
    Attestation[] memory attestations,
    bytes calldata proofData
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Attestation, AttestationData} from '../libs/Structs.sol';
import {IAttestationsRegistryConfigLogic} from './IAttestationsRegistryConfigLogic.sol';

/**
 * @title IAttestationsRegistry
 * @author Sismo
 * @notice This is the interface of the AttestationRegistry
 */
interface IAttestationsRegistry is IAttestationsRegistryConfigLogic {
  error IssuerNotAuthorized(address issuer, uint256 collectionId);
  error OwnersAndCollectionIdsLengthMismatch(address[] owners, uint256[] collectionIds);
  event AttestationRecorded(Attestation attestation);
  event AttestationDeleted(Attestation attestation);

  /**
   * @dev Main function to be called by authorized issuers
   * @param attestations Attestations to be recorded (creates a new one or overrides an existing one)
   */
  function recordAttestations(Attestation[] calldata attestations) external;

  /**
   * @dev Delete function to be called by authorized issuers
   * @param owners The owners of the attestations to be deleted
   * @param collectionIds The collection ids of the attestations to be deleted
   */
  function deleteAttestations(address[] calldata owners, uint256[] calldata collectionIds) external;

  /**
   * @dev Returns whether a user has an attestation from a collection
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function hasAttestation(uint256 collectionId, address owner) external returns (bool);

  /**
   * @dev Getter of the data of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationData(
    uint256 collectionId,
    address owner
  ) external view returns (AttestationData memory);

  /**
   * @dev Getter of the value of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationValue(uint256 collectionId, address owner) external view returns (uint256);

  /**
   * @dev Getter of the data of a specific attestation as tuple
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationDataTuple(
    uint256 collectionId,
    address owner
  ) external view returns (address, uint256, uint32, bytes memory);

  /**
   * @dev Getter of the extraData of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationExtraData(
    uint256 collectionId,
    address owner
  ) external view returns (bytes memory);

  /**
   * @dev Getter of the issuer of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationIssuer(
    uint256 collectionId,
    address owner
  ) external view returns (address);

  /**
   * @dev Getter of the timestamp of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationTimestamp(
    uint256 collectionId,
    address owner
  ) external view returns (uint32);

  /**
   * @dev Getter of the data of specific attestations
   * @param collectionIds Collection identifiers of the targeted attestations
   * @param owners Owners of the targeted attestations
   */
  function getAttestationDataBatch(
    uint256[] memory collectionIds,
    address[] memory owners
  ) external view returns (AttestationData[] memory);

  /**
   * @dev Getter of the values of specific attestations
   * @param collectionIds Collection identifiers of the targeted attestations
   * @param owners Owners of the targeted attestations
   */
  function getAttestationValueBatch(
    uint256[] memory collectionIds,
    address[] memory owners
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.14;

import {Range, RangeUtils} from '../libs/utils/RangeLib.sol';

interface IAttestationsRegistryConfigLogic {
  error AttesterNotFound(address issuer);
  error RangeIndexOutOfBounds(address issuer, uint256 expectedArrayLength, uint256 rangeIndex);
  error IdsMismatch(
    address issuer,
    uint256 rangeIndex,
    uint256 expectedFirstId,
    uint256 expectedLastId,
    uint256 FirstId,
    uint256 lastCollectionId
  );
  error AttributeDoesNotExist(uint8 attributeIndex);
  error AttributeAlreadyExists(uint8 attributeIndex);
  error ArgsLengthDoesNotMatch();

  event NewAttributeCreated(uint8 attributeIndex, bytes32 attributeName);
  event AttributeNameUpdated(
    uint8 attributeIndex,
    bytes32 newAttributeName,
    bytes32 previousAttributeName
  );
  event AttributeDeleted(uint8 attributeIndex, bytes32 deletedAttributeName);

  event AttestationsCollectionAttributeSet(
    uint256 collectionId,
    uint8 attributeIndex,
    uint8 attributeValue
  );

  event IssuerAuthorized(address issuer, uint256 firstCollectionId, uint256 lastCollectionId);
  event IssuerUnauthorized(address issuer, uint256 firstCollectionId, uint256 lastCollectionId);

  /**
   * @dev Returns whether an attestationsCollection has a specific attribute referenced by its index
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute. Can go from 0 to 63.
   */
  function attestationsCollectionHasAttribute(
    uint256 collectionId,
    uint8 index
  ) external view returns (bool);

  function attestationsCollectionHasAttributes(
    uint256 collectionId,
    uint8[] memory indices
  ) external view returns (bool);

  /**
   * @dev Returns the attribute's value (from 1 to 15) of an attestationsCollection
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param attributeIndex Index of the attribute. Can go from 0 to 63.
   */
  function getAttributeValueForAttestationsCollection(
    uint256 collectionId,
    uint8 attributeIndex
  ) external view returns (uint8);

  function getAttributesValuesForAttestationsCollection(
    uint256 collectionId,
    uint8[] memory indices
  ) external view returns (uint8[] memory);

  /**
   * @dev Set a value for an attribute of an attestationsCollection. The attribute should already be created.
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute (must be between 0 and 63)
   * @param value Value of the attribute we want to set for this attestationsCollection. Can take the value 0 to 15
   */
  function setAttributeValueForAttestationsCollection(
    uint256 collectionId,
    uint8 index,
    uint8 value
  ) external;

  function setAttributesValuesForAttestationsCollections(
    uint256[] memory collectionIds,
    uint8[] memory indices,
    uint8[] memory values
  ) external;

  /**
   * @dev Returns all the enabled attributes names and their values for a specific attestationsCollection
   * @param collectionId Collection Id of the targeted attestationsCollection
   */
  function getAttributesNamesAndValuesForAttestationsCollection(
    uint256 collectionId
  ) external view returns (bytes32[] memory, uint8[] memory);

  /**
   * @dev Authorize an issuer for a specific range
   * @param issuer Issuer that will be authorized
   * @param firstCollectionId First collection Id of the range for which the issuer will be authorized
   * @param lastCollectionId Last collection Id of the range for which the issuer will be authorized
   */
  function authorizeRange(
    address issuer,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) external;

  /**
   * @dev Unauthorize an issuer for a specific range
   * @param issuer Issuer that will be unauthorized
   * @param rangeIndex Index of the range to be unauthorized
   * @param firstCollectionId First collection Id of the range for which the issuer will be unauthorized
   * @param lastCollectionId Last collection Id of the range for which the issuer will be unauthorized
   */
  function unauthorizeRange(
    address issuer,
    uint256 rangeIndex,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) external;

  /**
   * @dev Authorize an issuer for specific ranges
   * @param issuer Issuer that will be authorized
   * @param ranges Ranges for which the issuer will be authorized
   */
  function authorizeRanges(address issuer, Range[] memory ranges) external;

  /**
   * @dev Unauthorize an issuer for specific ranges
   * @param issuer Issuer that will be unauthorized
   * @param ranges Ranges for which the issuer will be unauthorized
   */
  function unauthorizeRanges(
    address issuer,
    Range[] memory ranges,
    uint256[] memory rangeIndexes
  ) external;

  /**
   * @dev Returns whether a specific issuer is authorized or not to record in a specific attestations collection
   * @param issuer Issuer to be checked
   * @param collectionId Collection Id for which the issuer will be checked
   */
  function isAuthorized(address issuer, uint256 collectionId) external view returns (bool);

  /**
   * @dev Pauses the registry. Issuers can no longer record or delete attestations
   */
  function pause() external;

  /**
   * @dev Unpauses the registry
   */
  function unpause() external;

  /**
   * @dev Create a new attribute.
   * @param index Index of the attribute. Can go from 0 to 63.
   * @param name Name in bytes32 of the attribute
   */
  function createNewAttribute(uint8 index, bytes32 name) external;

  function createNewAttributes(uint8[] memory indices, bytes32[] memory names) external;

  /**
   * @dev Update the name of an existing attribute
   * @param index Index of the attribute. Can go from 0 to 63. The attribute must exist
   * @param newName new name in bytes32 of the attribute
   */
  function updateAttributeName(uint8 index, bytes32 newName) external;

  function updateAttributesName(uint8[] memory indices, bytes32[] memory names) external;

  /**
   * @dev Delete an existing attribute
   * @param index Index of the attribute. Can go from 0 to 63. The attribute must exist
   */
  function deleteAttribute(uint8 index) external;

  function deleteAttributes(uint8[] memory indices) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Request, Attestation} from '../libs/Structs.sol';
import {IAttestationsRegistry} from '../interfaces/IAttestationsRegistry.sol';

/**
 * @title IAttester
 * @author Sismo
 * @notice This is the interface for the attesters in Sismo Protocol
 */
interface IAttester {
  event AttestationGenerated(Attestation attestation);

  event AttestationDeleted(Attestation attestation);

  error AttestationDeletionNotImplemented();

  /**
   * @dev Main external function. Allows to generate attestations by making a request and submitting proof
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that has been recorded
   */
  function generateAttestations(
    Request calldata request,
    bytes calldata proofData
  ) external returns (Attestation[] memory);

  /**
   * @dev External facing function. Allows to delete an attestation by submitting proof
   * @param collectionIds Collection identifier of attestations to delete
   * @param attestationsOwner Owner of attestations to delete
   * @param proofData Data sent along the deletion request to prove its validity
   * @return attestations Attestations that was deleted
   */
  function deleteAttestations(
    uint256[] calldata collectionIds,
    address attestationsOwner,
    bytes calldata proofData
  ) external returns (Attestation[] memory);

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should build attestations from the user request and the proof
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function buildAttestations(
    Request calldata request,
    bytes calldata proofData
  ) external view returns (Attestation[] memory);

  /**
   * @dev Attestation registry address getter
   * @return attestationRegistry Address of the registry
   */
  function getAttestationRegistry() external view returns (IAttestationsRegistry);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * @title  Attestations Registry State
 * @author Sismo
 * @notice This contract holds all of the storage variables and data
 *         structures used by the AttestationsRegistry and parent
 *         contracts.
 */

// User Attestation Request, can be made by any user
// The context of an Attestation Request is a specific attester contract
// Each attester has groups of accounts in its available data
// eg: for a specific attester:
//     group 1 <=> accounts that sent txs on mainnet
//     group 2 <=> accounts that sent txs on polygon
// eg: for another attester:
//     group 1 <=> accounts that sent eth txs in 2022
//     group 2 <=> accounts sent eth txs in 2021
struct Request {
  // implicit address attester;
  // implicit uint256 chainId;
  Claim[] claims;
  address destination; // destination that will receive the end attestation
}

struct Claim {
  uint256 groupId; // user claims to have an account in this group
  uint256 claimedValue; // user claims this value for its account in the group
  bytes extraData; // arbitrary data, may be required by the attester to verify claims or generate a specific attestation
}

/**
 * @dev Attestation Struct. This is the struct receive as argument by the Attestation Registry.
 * @param collectionId Attestation collection
 * @param owner Attestation collection
 * @param issuer Attestation collection
 * @param value Attestation collection
 * @param timestamp Attestation collection
 * @param extraData Attestation collection
 */
struct Attestation {
  // implicit uint256 chainId;
  uint256 collectionId; // Id of the attestation collection (in the registry)
  address owner; // Owner of the attestation
  address issuer; // Contract that created or last updated the record.
  uint256 value; // Value of the attestation
  uint32 timestamp; // Timestamp chosen by the attester, should correspond to the effective date of the attestation
  // it is different from the recording timestamp (date when the attestation was recorded)
  // e.g a proof of NFT ownership may have be recorded today which is 2 month old data.
  bytes extraData; // arbitrary data that can be added by the attester
}

// Attestation Data, stored in the registry
// The context is a specific owner of a specific collection
struct AttestationData {
  // implicit uint256 chainId
  // implicit uint256 collectionId - from context
  // implicit owner
  address issuer; // Address of the contract that recorded the attestation
  uint256 value; // Value of the attestation
  uint32 timestamp; // Effective date of issuance of the attestation. (can be different from the recording timestamp)
  bytes extraData; // arbitrary data that can be added by the attester
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

struct Range {
  uint256 min;
  uint256 max;
}

// Range [0;3] includees 0 and 3
library RangeUtils {
  function _includes(Range[] storage ranges, uint256 collectionId) internal view returns (bool) {
    for (uint256 i = 0; i < ranges.length; i++) {
      if (collectionId >= ranges[i].min && collectionId <= ranges[i].max) {
        return true;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IAvailableRootsRegistry} from './interfaces/IAvailableRootsRegistry.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

/**
 * @title Attesters Groups Registry
 * @author Sismo
 * @notice This contract stores that data required by attesters to be available so they can verify user claims
 * This contract is deployed behind a proxy and this implementation is focused on storing merkle roots
 * For more information: https://available-roots-registry.docs.sismo.io
 *
 **/
contract AvailableRootsRegistry is IAvailableRootsRegistry, Initializable, Ownable {
  uint8 public constant IMPLEMENTATION_VERSION = 2;

  mapping(address => mapping(uint256 => bool)) public _roots;

  /**
   * @dev Constructor
   * @param owner Owner of the contract, can register/ unregister roots
   */
  constructor(address owner) {
    initialize(owner);
  }

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param ownerAddress Owner of the contract, can update public key and address
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(address ownerAddress) public reinitializer(IMPLEMENTATION_VERSION) {
    // if proxy did not setup owner yet or if called by constructor (for implem setup)
    if (owner() == address(0) || address(this).code.length == 0) {
      _transferOwnership(ownerAddress);
    }
  }

  /**
   * @dev Register a root available for an attester
   * @param attester Attester which will have the root available
   * @param root Root to register
   */
  function registerRootForAttester(address attester, uint256 root) external onlyOwner {
    if (attester == address(0)) revert CannotRegisterForZeroAddress();
    _registerRootForAttester(attester, root);
  }

  /**
   * @dev Unregister a root for an attester
   * @param attester Attester which will no longer have the root available
   * @param root Root to unregister
   */
  function unregisterRootForAttester(address attester, uint256 root) external onlyOwner {
    if (attester == address(0)) revert CannotUnregisterForZeroAddress();
    _unregisterRootForAttester(attester, root);
  }

  /**
   * @dev Registers a root, available for all contracts
   * @param root Root to register
   */
  function registerRootForAll(uint256 root) external onlyOwner {
    _registerRootForAttester(address(0), root);
  }

  /**
   * @dev Unregister a root, available for all contracts
   * @param root Root to unregister
   */
  function unregisterRootForAll(uint256 root) external onlyOwner {
    _unregisterRootForAttester(address(0), root);
  }

  /**
   * @dev returns whether a root is available for a caller (msg.sender)
   * @param root root to check whether it is registered for me or not
   */
  function isRootAvailableForMe(uint256 root) external view returns (bool) {
    return _roots[_msgSender()][root] || _roots[address(0)][root];
  }

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param attester Owner of the contract, can update public key and address
   * @param root Owner of the contract, can update public key and address
   */
  function isRootAvailableForAttester(address attester, uint256 root) external view returns (bool) {
    return _roots[attester][root] || _roots[address(0)][root];
  }

  function _registerRootForAttester(address attester, uint256 root) internal {
    _roots[attester][root] = true;
    if (attester == address(0)) {
      emit RegisteredRootForAll(root);
    } else {
      emit RegisteredRootForAttester(attester, root);
    }
  }

  function _unregisterRootForAttester(address attester, uint256 root) internal {
    _roots[attester][root] = false;
    if (attester == address(0)) {
      emit UnregisteredRootForAll(root);
    } else {
      emit UnregisteredRootForAttester(attester, root);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {ICommitmentMapperRegistry} from './interfaces/ICommitmentMapperRegistry.sol';

/**
 * @title Commitment Mapper Registry Contract
 * @author Sismo
 * @notice This contract stores information about the commitment mapper.
 * Its ethereum address and its EdDSA public key
 * For more information: https://commitment-mapper.docs.sismo.io
 *
 **/
contract CommitmentMapperRegistry is ICommitmentMapperRegistry, Initializable, Ownable {
  uint8 public constant IMPLEMENTATION_VERSION = 2;

  uint256[2] internal _commitmentMapperPubKey;
  address _commitmentMapperAddress;

  /**
   * @dev Constructor
   * @param owner Owner of the contract, can update public key and address
   * @param commitmentMapperEdDSAPubKey EdDSA public key of the commitment mapper
   * @param commitmentMapperAddress Address of the commitment mapper
   */
  constructor(
    address owner,
    uint256[2] memory commitmentMapperEdDSAPubKey,
    address commitmentMapperAddress
  ) {
    initialize(owner, commitmentMapperEdDSAPubKey, commitmentMapperAddress);
  }

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param ownerAddress Owner of the contract, can update public key and address
   * @param commitmentMapperEdDSAPubKey EdDSA public key of the commitment mapper
   * @param commitmentMapperAddress Address of the commitment mapper
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(
    address ownerAddress,
    uint256[2] memory commitmentMapperEdDSAPubKey,
    address commitmentMapperAddress
  ) public reinitializer(IMPLEMENTATION_VERSION) {
    // if proxy did not setup owner yet or if called by constructor (for implem setup)
    if (owner() == address(0) || address(this).code.length == 0) {
      _transferOwnership(ownerAddress);
      _updateCommitmentMapperEdDSAPubKey(commitmentMapperEdDSAPubKey);
      _updateCommitmentMapperAddress(commitmentMapperAddress);
    }
  }

  /**
   * @dev Updates the EdDSA public key
   * @param newEdDSAPubKey new EdDSA pubic key
   */
  function updateCommitmentMapperEdDSAPubKey(uint256[2] memory newEdDSAPubKey) external onlyOwner {
    _updateCommitmentMapperEdDSAPubKey(newEdDSAPubKey);
  }

  /**
   * @dev Updates the address
   * @param newAddress new address
   */
  function updateCommitmentMapperAddress(address newAddress) external onlyOwner {
    _updateCommitmentMapperAddress(newAddress);
  }

  /**
   * @dev Getter of the EdDSA public key of the commitment mapper
   */
  function getEdDSAPubKey() external view override returns (uint256[2] memory) {
    return _commitmentMapperPubKey;
  }

  /**
   * @dev Getter of the address of the commitment mapper
   */
  function getAddress() external view override returns (address) {
    return _commitmentMapperAddress;
  }

  function _updateCommitmentMapperAddress(address newAddress) internal {
    _commitmentMapperAddress = newAddress;
    emit UpdatedCommitmentMapperAddress(newAddress);
  }

  function _updateCommitmentMapperEdDSAPubKey(uint256[2] memory pubKey) internal {
    _commitmentMapperPubKey = pubKey;
    emit UpdatedCommitmentMapperEdDSAPubKey(pubKey);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * @title IAvailableRootsRegistry
 * @author Sismo
 * @notice Interface for (Merkle) Roots Registry
 */
interface IAvailableRootsRegistry {
  event RegisteredRootForAttester(address attester, uint256 root);
  event RegisteredRootForAll(uint256 root);
  event UnregisteredRootForAttester(address attester, uint256 root);
  event UnregisteredRootForAll(uint256 root);

  error CannotRegisterForZeroAddress();
  error CannotUnregisterForZeroAddress();

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(address owner) external;

  /**
   * @dev Register a root available for an attester
   * @param attester Attester which will have the root available
   * @param root Root to register
   */
  function registerRootForAttester(address attester, uint256 root) external;

  /**
   * @dev Unregister a root for an attester
   * @param attester Attester which will no longer have the root available
   * @param root Root to unregister
   */
  function unregisterRootForAttester(address attester, uint256 root) external;

  /**
   * @dev Registers a root, available for all contracts
   * @param root Root to register
   */
  function registerRootForAll(uint256 root) external;

  /**
   * @dev Unregister a root, available for all contracts
   * @param root Root to unregister
   */
  function unregisterRootForAll(uint256 root) external;

  /**
   * @dev returns whether a root is available for a caller (msg.sender)
   * @param root root to check whether it is registered for me or not
   */
  function isRootAvailableForMe(uint256 root) external view returns (bool);

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param attester Owner of the contract, can update public key and address
   * @param root Owner of the contract, can update public key and address
   */
  function isRootAvailableForAttester(address attester, uint256 root) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICommitmentMapperRegistry {
  event UpdatedCommitmentMapperEdDSAPubKey(uint256[2] newEdDSAPubKey);
  event UpdatedCommitmentMapperAddress(address newAddress);
  error PubKeyNotValid(uint256[2] pubKey);

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param owner Owner of the contract, can update public key and address
   * @param commitmentMapperEdDSAPubKey EdDSA public key of the commitment mapper
   * @param commitmentMapperAddress Address of the commitment mapper
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(
    address owner,
    uint256[2] memory commitmentMapperEdDSAPubKey,
    address commitmentMapperAddress
  ) external;

  /**
   * @dev Updates the EdDSA public key
   * @param newEdDSAPubKey new EdDSA pubic key
   */
  function updateCommitmentMapperEdDSAPubKey(uint256[2] memory newEdDSAPubKey) external;

  /**
   * @dev Updates the address
   * @param newAddress new address
   */
  function updateCommitmentMapperAddress(address newAddress) external;

  /**
   * @dev Getter of the address of the commitment mapper
   */
  function getEdDSAPubKey() external view returns (uint256[2] memory);

  /**
   * @dev Getter of the address of the commitment mapper
   */
  function getAddress() external view returns (address);
}