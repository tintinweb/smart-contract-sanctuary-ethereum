/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

contract ECCArithmetic {
    // constant term in affine curve equation: y²=x³+b
    uint256 constant B = 3;

    // Base field for G1 is 𝔽ₚ
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
    uint256 constant P =
        // solium-disable-next-line indentation
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // #E(𝔽ₚ), number of points on  G1/G2Add
    // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
    uint256 constant Q =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    struct G1Point {
        uint256[2] p;
    }

    struct G2Point {
        uint256[4] p;
    }

    function checkPointOnCurve(G1Point memory p) internal pure {
        require(p.p[0] < P, "x not in F_P");
        require(p.p[1] < P, "y not in F_P");
        uint256 rhs = addmod(
            mulmod(mulmod(p.p[0], p.p[0], P), p.p[0], P),
            B,
            P
        );
        require(mulmod(p.p[1], p.p[1], P) == rhs, "point not on curve");
    }

    function _addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory sum)
    {
        checkPointOnCurve(p1);
        checkPointOnCurve(p2);

        uint256[4] memory summands;
        summands[0] = p1.p[0];
        summands[1] = p1.p[1];
        summands[2] = p2.p[0];
        summands[3] = p2.p[1];
        uint256[2] memory result;
        uint256 callresult;
        assembly {
            // solhint-disable-line no-inline-assembly
            callresult := staticcall(
                // gas cost. https://eips.ethereum.org/EIPS/eip-1108 ,
                // https://github.com/ethereum/go-ethereum/blob/9d10856/params/protocol_params.go#L124
                150,
                // g1add https://github.com/ethereum/go-ethereum/blob/9d10856/core/vm/contracts.go#L89
                0x6,
                summands, // input
                0x80, // input length: 4 words
                result, // output
                0x40 // output length: 2 words
            )
        }
        require(callresult != 0, "addg1 call failed");
        sum.p[0] = result[0];
        sum.p[1] = result[1];
        return sum;
    }

    function addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory)
    {
        G1Point memory sum = _addG1(p1, p2);
        // This failure is mathematically possible from a legitimate return
        // value, but vanishingly unlikely, and almost certainly instead
        // reflects a failure in the precompile.
        require(sum.p[0] != 0 && sum.p[1] != 0, "addg1 failed: zero ordinate");
        return sum;
    }

    // Coordinates for generator of G2.
    uint256 constant g2GenXA =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 constant g2GenXB =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 constant g2GenYA =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 constant g2GenYB =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 constant pairingGasCost = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
    uint256 constant pairingPrecompileAddress = 0x8;
    uint256 constant pairingInputLength = 12 * 0x20;
    uint256 constant pairingOutputLength = 0x20;

    // discreteLogsMatch returns true iff signature = sk*base, where sk is the
    // secret key associated with pubkey, i.e. pubkey = sk*<G2 generator>
    //
    // This is used for signature/VRF verification. In actual use, g1Base is the
    // hash-to-curve to be signed/exponentiated, and pubkey is the public key
    // the signature pertains to.
    function discreteLogsMatch(
        G1Point memory g1Base,
        G1Point memory signature,
        G2Point memory pubkey
    ) internal view returns (bool) {
        // It is not necessary to check that the points are in their respective
        // groups; the pairing check fails if that's not the case.

        // Let g1, g2 be the canonical generators of G1, G2, respectively..
        // Let l be the (unknown) discrete log of g1Base w.r.t. the G1 generator.
        //
        // In the happy path, the result of the first pairing in the following
        // will be -l*log_{g2}(pubkey) * e(g1,g2) = -l * sk * e(g1,g2), of the
        // second will be sk * l * e(g1,g2) = l * sk * e(g1,g2). Thus the two
        // terms will cancel, and the pairing function will return one. See
        // EIP-197.
        G1Point[] memory g1s = new G1Point[](2);
        G2Point[] memory g2s = new G2Point[](2);
        g1s[0] = G1Point([g1Base.p[0], P - g1Base.p[1]]);
        g1s[1] = signature;
        g2s[0] = pubkey;
        g2s[1] = G2Point([g2GenXA, g2GenXB, g2GenYA, g2GenYB]);
        return pairing(g1s, g2s);
    }

    function negateG1(G1Point memory p)
        internal
        pure
        returns (G1Point memory neg)
    {
        neg.p[0] = p.p[0];
        neg.p[1] = P - p.p[1];
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    //
    // Cribbed from https://gist.github.com/BjornvdLaan/ca6dd4e3993e1ef392f363ec27fe74c4
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].p[0];
            input[i * 6 + 1] = p1[i].p[1];
            input[i * 6 + 2] = p2[i].p[0];
            input[i * 6 + 3] = p2[i].p[1];
            input[i * 6 + 4] = p2[i].p[2];
            input[i * 6 + 5] = p2[i].p[3];
        }

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(
                pairingGasCost,
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        require(success);
        return out[0] != 0;
    }
}

// If these types are changed, the types in beaconObservation.proto and
// AbstractCostedCallbackRequest etc. probably need to change, too.
contract VRFBeaconTypes {
    type RequestID is uint48;
    RequestID constant MAX_REQUEST_ID = RequestID.wrap(type(uint48).max);
    uint8 public constant NUM_CONF_DELAYS = 8;
    uint256 internal constant MAX_NUM_ORACLES = 31;

    /// @dev With a beacon period of 15, using a uint32 here allows for roughly
    /// @dev 60B blocks, which would take roughly 2000 years on a chain with a 1s
    /// @dev block time.
    type SlotNumber is uint32;
    SlotNumber internal constant MAX_SLOT_NUMBER =
        SlotNumber.wrap(type(uint32).max);

    type ConfirmationDelay is uint24;
    ConfirmationDelay internal constant MAX_CONFIRMATION_DELAY =
        ConfirmationDelay.wrap(type(uint24).max);
    uint8 internal constant CONFIRMATION_DELAY_BYTE_WIDTH = 3;

    /// @dev Request metadata. Designed to fit in a single 32-byte word, to save
    /// @dev on storage/retrieval gas costs.
    struct BeaconRequest {
        SlotNumber slotNumber;
        ConfirmationDelay confirmationDelay;
        uint16 numWords;
        address requester; // Address which will eventually retrieve randomness
    }

    struct Callback {
        RequestID requestID;
        uint16 numWords;
        address requester;
        bytes arguments;
        uint64 subID;
        uint96 gasAllowance; // gas offered to callback method when called
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
    }

    // TODO(coventry): There is scope for optimization of the calldata gas cost,
    // here. The solidity lists can be replaced by something lower-level, where
    // the lengths are represented by something shorter, and there could be a
    // specialized part of the report which deals with fulfillments for blocks
    // which have already had their seeds reported.
    struct VRFOutput {
        uint64 blockHeight; // Beacon height this output corresponds to
        ConfirmationDelay confirmationDelay; // #blocks til offchain system response
        // VRF output for blockhash at blockHeight. If this is (0,0), indicates that
        // this is a request for callbacks for a pre-existing height, and the seed
        // should be sought from contract storage
        ECCArithmetic.G1Point vrfOutput;
        CostedCallback[] callbacks; // Contracts to callback with random outputs
    }

    struct OutputServed {
        uint64 height;
        ConfirmationDelay confirmationDelay;
    }
}

interface SubscriptionInterface {
    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get current subscription ID.
     * @return subId - ID of the current subscription
     */
    function getCurrentSubId() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;
}

interface ERC677ReceiverInterface {
    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

abstract contract VRFBeaconBilling is
    OwnableUpgradeable,
    SubscriptionInterface,
    ERC677ReceiverInterface
{
    LinkTokenInterface public _link; // Address of LINK token contract
    // We need to maintain a list of consuming addresses.
    // This bound ensures we are able to loop over them as needed.
    // Should a user require more consumers, they can use multiple subscriptions.
    uint16 public constant MAX_CONSUMERS = 100;
    uint64 private s_currentSubId; // Highest subscription ID. Rises monotonically
    // s_totalBalance tracks the total link sent to
    // this contract through onTokenTransfer
    // A discrepancy with this contract's link balance indicates someone
    // sent tokens using transfer and so we may need to use recoverFunds.
    uint96 private s_totalBalance;
    // Note a nonce of 0 indicates an the consumer is not assigned to that subscription.
    mapping(address => mapping(uint64 => uint64)) /* consumer */ /* subId */ /* nonce */
        private s_consumers;

    /// @dev configuration parameters for billing
    struct BillingConfig {
        // Reentrancy protection.
        bool reentrancyLock;
        // stalenessSeconds is how long before we consider the feed price to be
        // stale and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Gas to cover oracle payment after we calculate the payment.
        // We make it configurable in case those operations are repriced.
        uint32 gasAfterPaymentCalculation;
    }
    BillingConfig private s_config;

    struct SubscriptionConfig {
        address owner; // Owner can fund/withdraw/cancel the sub.
        address requestedOwner; // For safely transferring sub ownership.
        // Maintains the list of keys in s_consumers.
        // We do this for 2 reasons:
        // 1. To be able to clean up all keys from s_consumers when canceling a
        //    subscription.
        // 2. To be able to return the list of all consumers in getSubscription.
        // Note that we need the s_consumers map to be able to directly check if a
        // consumer is valid without reading all the consumers from storage.
        address[] consumers;
    }
    mapping(uint64 => SubscriptionConfig) /* subId */ /* subscriptionConfig */
        private s_subscriptionConfigs;

    struct Subscription {
        // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
        uint96 balance; // Common link balance used for all consumer requests.
        uint64 reqCount; // For fee tiers
    }
    mapping(uint64 => Subscription) /* subId */ /* subscription */
        private s_subscriptions;

    event SubscriptionCreated(uint64 indexed subId, address owner);
    event SubscriptionOwnerTransferRequested(
        uint64 indexed subId,
        address from,
        address to
    );
    event SubscriptionOwnerTransferred(
        uint64 indexed subId,
        address from,
        address to
    );
    event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
    event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
    event SubscriptionCanceled(
        uint64 indexed subId,
        address to,
        uint256 amount
    );
    event SubscriptionFunded(
        uint64 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );

    /// @dev Emitted when a subscription for a given ID cannot be found
    error InvalidSubscription();
    /// @dev Emitted when sender is not authorized to make the requested change to
    /// @dev the subscription
    error MustBeSubOwner(address owner);
    /// @dev Emitted when consumer is not registered for the subscription
    error InvalidConsumer(uint64 subId, address consumer);
    /// @dev Emitted when number of consumer will exceed MAX_CONSUMERS
    error TooManyConsumers();
    /// @dev Emmited when balance is insufficient
    error InsufficientBalance();
    /// @dev Emmited when msg.sender is not the requested owner
    error MustBeRequestedOwner(address proposedOwner);
    /// @dev Emmited when subscription can't be cancelled because of pending requests
    error PendingRequestExists();
    /// @dev Emitted when caller transfers tokens other than LINK
    error OnlyCallableFromLink();
    /// @dev Emitted when calldata is invalid
    error InvalidCalldata();
    /// @dev Emitted when a client contract attempts to re-enter a state-changing
    /// @dev coordinator method.
    error Reentrant();

    function __VRFBeaconBilling_init(address link) internal onlyInitializing {
        _link = LinkTokenInterface(link); 
        __Ownable_init();
    }

    function getTotalBalance() external view returns (uint256) {
        return s_totalBalance;
    }

    function billSubscriberForCallback(
        VRFBeaconTypes.CostedCallback memory, /* c */
        uint192 /* juelsPerFeeCoin */
    ) internal returns (bool success) {
        return true;
    }

    function billSubscriberForRequest(
        VRFBeaconTypes.BeaconRequest memory, /* BeaconRequest */
        address, /* requester */
        uint64 /* subID */
    ) internal pure {
        /* XXX: "pure" for now just to silence compiler */
        // throws on failure
        /* XXX: Fill this in */
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function getCurrentSubId() external view returns (uint64) {
        return s_currentSubId;
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function createSubscription()
        external
        override
        nonReentrant
        returns (uint64)
    {
        s_currentSubId++;
        uint64 currentSubId = s_currentSubId;
        address[] memory consumers = new address[](0);
        s_subscriptions[currentSubId] = Subscription({balance: 0, reqCount: 0});
        s_subscriptionConfigs[currentSubId] = SubscriptionConfig({
            owner: msg.sender,
            requestedOwner: address(0),
            consumers: consumers
        });

        emit SubscriptionCreated(currentSubId, msg.sender);
        return currentSubId;
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function getSubscription(uint64 subId)
        external
        view
        override
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        )
    {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        return (
            s_subscriptions[subId].balance,
            s_subscriptions[subId].reqCount,
            s_subscriptionConfigs[subId].owner,
            s_subscriptionConfigs[subId].consumers
        );
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        // Proposing to address(0) would never be claimable so don't need to check.
        if (s_subscriptionConfigs[subId].requestedOwner != newOwner) {
            s_subscriptionConfigs[subId].requestedOwner = newOwner;
            emit SubscriptionOwnerTransferRequested(
                subId,
                msg.sender,
                newOwner
            );
        }
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId)
        external
        override
        nonReentrant
    {
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        if (s_subscriptionConfigs[subId].requestedOwner != msg.sender) {
            revert MustBeRequestedOwner(
                s_subscriptionConfigs[subId].requestedOwner
            );
        }
        address oldOwner = s_subscriptionConfigs[subId].owner;
        s_subscriptionConfigs[subId].owner = msg.sender;
        s_subscriptionConfigs[subId].requestedOwner = address(0);
        emit SubscriptionOwnerTransferred(subId, oldOwner, msg.sender);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function addConsumer(uint64 subId, address consumer)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        // Already maxed, cannot add any more consumers.
        if (s_subscriptionConfigs[subId].consumers.length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }
        if (s_consumers[consumer][subId] != 0) {
            // Idempotence - do nothing if already added.
            // Ensures uniqueness in s_subscriptions[subId].consumers.
            return;
        }
        // Initialize the nonce to 1, indicating the consumer is allocated.
        s_consumers[consumer][subId] = 1;
        s_subscriptionConfigs[subId].consumers.push(consumer);

        emit SubscriptionConsumerAdded(subId, consumer);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function removeConsumer(uint64 subId, address consumer)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        if (s_consumers[consumer][subId] == 0) {
            revert InvalidConsumer(subId, consumer);
        }
        // Note bounded by MAX_CONSUMERS
        address[] memory consumers = s_subscriptionConfigs[subId].consumers;
        uint256 lastConsumerIndex = consumers.length - 1;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == consumer) {
                address last = consumers[lastConsumerIndex];
                // Storage write to preserve last element
                s_subscriptionConfigs[subId].consumers[i] = last;
                // Storage remove last element
                s_subscriptionConfigs[subId].consumers.pop();
                break;
            }
        }
        delete s_consumers[consumer][subId];
        emit SubscriptionConsumerRemoved(subId, consumer);
    }

    /**
     * @inheritdoc SubscriptionInterface
     */
    function cancelSubscription(uint64 subId, address to)
        external
        override
        onlySubOwner(subId)
        nonReentrant
    {
        if (pendingRequestExists(subId)) {
            revert PendingRequestExists();
        }
        cancelSubscriptionHelper(subId, to);
    }

    function cancelSubscriptionHelper(uint64 subId, address to)
        private
        nonReentrant
    {
        SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
        Subscription memory sub = s_subscriptions[subId];
        uint96 balance = sub.balance;
        // Note bounded by MAX_CONSUMERS;
        // If no consumers, does nothing.
        for (uint256 i = 0; i < subConfig.consumers.length; i++) {
            delete s_consumers[subConfig.consumers[i]][subId];
        }
        delete s_subscriptionConfigs[subId];
        delete s_subscriptions[subId];
        s_totalBalance -= balance;
        if (!_link.transfer(to, uint256(balance))) {
            revert InsufficientBalance();
        }
        emit SubscriptionCanceled(subId, to, balance);
    }

    /// @dev TODO: Discuss if this functionality is needed. It seems to be only needed
    /// @dev if we support a free/cheap tier for low-volume users. If we do need it,
    /// @dev then s_consumerSubscription will require updates to functions in
    /// @dev SubscriptionInterface.sol
    /// @dev Each consumer is associated with a single subscription, for the life
    /// @dev of this coordinator, unless the coordinator owner moves it. This
    /// @dev prevents users from moving a consuming contract to different
    /// @dev subscription in order to obtain a cheaper fee tier. The zero value
    /// @dev means that a consumer has not yet been assigned to a subscription.
    mapping(address => uint64) /* consumer */ /* subscription */
        internal s_consumerSubscription;

    /// @notice Forget the subscription ID a consumer address is associated with.
    ///
    /// @dev Useful if a user needs to move to a new subscription for some reason.
    /// @dev Can only be called by coordinator owner.
    function forgetConsumerSubscriptionID(address[] calldata consumers)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < consumers.length; i++) {
            s_consumerSubscription[consumers[i]] = 0;
        }
    }

    function onTokenTransfer(
        address, /* sender */
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant {
        if (msg.sender != address(_link)) {
            revert OnlyCallableFromLink();
        }
        if (data.length != 32) {
            revert InvalidCalldata();
        }
        uint64 subId = abi.decode(data, (uint64));
        if (s_subscriptionConfigs[subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        // We do not check that the msg.sender is the subscription owner,
        // anyone can fund a subscription.
        uint256 oldBalance = s_subscriptions[subId].balance;
        s_subscriptions[subId].balance += uint96(amount);
        s_totalBalance += uint96(amount);
        emit SubscriptionFunded(subId, oldBalance, oldBalance + amount);
    }

    /// @dev reverts when a client contract attempts to re-enter a state-changing
    /// @dev method
    modifier nonReentrant() {
        if (s_config.reentrancyLock) {
            revert Reentrant();
        }
        _;
    }

    /// @dev reverts when the sender is not the owner of the subscription
    modifier onlySubOwner(uint64 subId) {
        address owner = s_subscriptionConfigs[subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    /**
     * @dev Hook for child classes to define whether pending request exists for a subscription
     * @param subId - subscription ID
     * @return bool - true if pending request exists, otherwise false
     */
    function pendingRequestExists(uint64 subId)
        public
        view
        virtual
        returns (bool)
    {}
}

abstract contract IVRFCoordinatorExternalAPI is VRFBeaconTypes {
    //////////////////////////////////////////////////////////////////////////////
    /// @notice Register a future request for randomness,and return the requestID.
    ///
    /// @notice The requestID resulting from given requestRandomness call MAY
    /// @notice CHANGE if a set of transactions calling requestRandomness are
    /// @notice re-ordered during a block re-organization. Thus, it is necessary
    /// @notice for the calling context to store the requestID onchain, unless
    /// @notice there is a an offchain system which keeps track of changes to the
    /// @notice requestID.
    ///
    /// @param numWords number of uint256's of randomness to provide in response
    /// @return ID of created request
    function requestRandomness(
        uint16 numWords,
        uint64 subID,
        ConfirmationDelay confirmationDelayArg
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice fulfillRandomness(RequestID,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param arguments data which should be passed to the callback method
    ///
    /// @return ID of created request
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    function requestRandomnessFulfillment(
        uint64 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(RequestID requestID)
        public
        virtual
        returns (uint256[] memory randomness);
}

abstract contract IVRFCoordinatorConsumer is VRFBeaconTypes {
    IVRFCoordinatorExternalAPI immutable coordinator;

    constructor(address _coordinator) {
        coordinator = IVRFCoordinatorExternalAPI(_coordinator);
    }

    function fulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual;

    function rawFulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory randomWords,
        bytes memory arguments
    ) external {
        require(
            address(coordinator) == msg.sender,
            "only coordinator can fulfill"
        );
        fulfillRandomWords(requestID, randomWords, arguments);
    }
}

// Interface used by VRF output producers such as VRFBeacon
// Exposes methods for processing VRF outputs and paying appropriate EOA
// The methods are only callable by producers
abstract contract IVRFCoordinatorProducerAPI is VRFBeaconTypes {
    /// @dev processes VRF outputs for given blockHeight and blockHash
    /// @dev also fulfills callbacks
    function processVRFOutputs(
        VRFOutput[] calldata vrfOutputs,
        uint192 juelsPerFeeCoin,
        uint64 blockHeight,
        bytes32 blockHash
    ) external virtual returns (OutputServed[] memory);

    /// @dev transfers LINK to recipient
    /// @dev reverts when there are not enough funds
    function transferLink(address recipient, uint256 juelsAmount)
        external
        virtual;

    /// @dev transfer LINK to multiple recipients
    /// @dev reverts when there are not enough funds or number of recipients and
    /// @dev paymentsInJuels are not as expected
    function batchTransferLink(
        address[] calldata recipients,
        uint256[] calldata paymentsInJuels
    ) external virtual;

    /// @dev returns total Link balance in the contract in juels
    function getTotalLinkBalance()
        external
        view
        virtual
        returns (uint256 balance);

    /// @dev sets allowed confirmation delays
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external virtual;
}

////////////////////////////////////////////////////////////////////////////////
/// @title Tracks VRF Beacon randomness requests
///
/// @notice Call `requestRandomness` to register retrieval of randomness from
/// @notice the next beacon output, then call `redeemRandomness` with the RequestID
/// @notice returned by `requestRandomness`
///
/// @dev This is intended as a superclass for the VRF Beacon contract,
/// @dev containing the logic for processing and responding to randomness
/// @dev requests
contract VRFCoordinator is
    IVRFCoordinatorExternalAPI,
    IVRFCoordinatorProducerAPI,
    VRFBeaconBilling
{
    /// @notice Max length of array returned from redeemRandomness
    uint256 public constant maxNumWords = 1000;

    /// @dev producer is responsible for writing VRF outputs to the coordinator
    /// @dev producer is the only allowed caller for IVRFCoordinatorExternalAPI
    address public producer;

    /// @inheritdoc IVRFCoordinatorExternalAPI
    function requestRandomness(
        uint16 numWords,
        uint64 subID,
        ConfirmationDelay confirmationDelayArg
    ) external override returns (RequestID) {
        (
            RequestID nonce,
            BeaconRequest memory r,
            uint64 nextBeaconOutputHeight
        ) = beaconRequest(numWords, confirmationDelayArg);
        billSubscriberForRequest(r, msg.sender, subID); // throws on failure
        s_pendingRequests[nonce] = r;
        emit RandomnessRequested(nextBeaconOutputHeight, confirmationDelayArg);
        return nonce;
    }

    /// @inheritdoc IVRFCoordinatorExternalAPI
    function requestRandomnessFulfillment(
        uint64 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) external override returns (RequestID) {
        (
            RequestID requestID, // BeaconRequest. We do not store this, because we trust the committee
            ,
            // to only sign off on reports containing valid fulfillment requests
            uint64 nextBeaconOutputHeight
        ) = beaconRequest(numWords, confirmationDelayArg);
        Callback memory callback = Callback({
            requestID: requestID,
            numWords: numWords,
            requester: msg.sender,
            arguments: arguments,
            subID: subID,
            gasAllowance: callbackGasLimit
        });
        // Record the callback so that it can only be played once. This is checked
        // in VRFBeaconReport.processCallback, and the entry is then deleted
        s_callbackMemo[requestID] = keccak256(
            abi.encode(
                nextBeaconOutputHeight,
                confirmationDelayArg,
                subID,
                callback
            )
        );
        emit RandomnessFulfillmentRequested(
            nextBeaconOutputHeight,
            confirmationDelayArg,
            subID,
            callback
        );
        return requestID;
    }

    // Used to track pending callbacks by their keccak256 hash
    mapping(RequestID => bytes32) internal s_callbackMemo;

    /// @inheritdoc IVRFCoordinatorExternalAPI
    function redeemRandomness(RequestID requestID)
        public
        override
        returns (uint256[] memory randomness)
    {
        // No billing logic required here. Callback-free requests are paid up-front
        // and only registered if fully paid.
        BeaconRequest memory r = s_pendingRequests[requestID];
        delete s_pendingRequests[requestID]; // save gas, prevent re-entrancy
        if (r.requester != msg.sender) {
            revert ResponseMustBeRetrievedByRequester(r.requester, msg.sender);
        }
        uint256 blockHeight = SlotNumber.unwrap(r.slotNumber) *
            i_beaconPeriodBlocks;
        uint256 confThreshold = block.number -
            ConfirmationDelay.unwrap(r.confirmationDelay);
        if (blockHeight >= confThreshold) {
            revert BlockTooRecent(blockHeight, block.number);
        }
        if (blockHeight > type(uint64).max) {
            revert UniverseHasEndedBangBangBang(blockHeight);
        }
        return
            finalOutput(
                requestID,
                r,
                s_seedByBlockHeight[blockHeight][r.confirmationDelay],
                uint64(blockHeight)
            );
    }

    struct Config {
        uint16 minimumRequestConfirmations;
        uint32 maxGasLimit;
        // Reentrancy protection.
        bool reentrancyLock;
        // stalenessSeconds is how long before we consider the feed price to be stale
        // and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Gas to cover oracle payment after we calculate the payment.
        // We make it configurable in case those operations are repriced.
        uint32 gasAfterPaymentCalculation;
    }
    Config private s_config;

    /// @notice emitted when the requestIDs have been fulfilled
    ///
    /// @dev There is one entry in truncatedErrorData for each false entry in
    /// @dev successfulFulfillment
    ///
    /// @param requestIDs the IDs of the requests which have been fulfilled
    /// @param successfulFulfillment ith entry true if ith fulfillment succeeded
    /// @param truncatedErrorData ith entry is error message for ith failure
    event RandomWordsFulfilled(
        RequestID[] requestIDs,
        bytes successfulFulfillment,
        bytes[] truncatedErrorData
    );

    /// @notice Emitted when the recentBlockHash is older than some of the VRF
    /// @notice outputs it's being used to sign.
    ///
    /// @param reportHeight height of the VRF output which is younger than the recentBlockHash
    /// @param separatorHeight recentBlockHeight in the report
    error HistoryDomainSeparatorTooOld(
        uint64 reportHeight,
        uint64 separatorHeight
    );

    /// @dev Stores the VRF outputs received so far, indexed by the block heights
    /// @dev they're associated with
    mapping(uint256 => mapping(ConfirmationDelay => bytes32)) s_seedByBlockHeight; /* block height */ /* seed */

    function setProducer(address addr) external onlyOwner {
        producer = addr;
    }

    function getProducer() external view onlyOwner returns (address addr) {
        return producer;
    }

    modifier onlyProducer() {
        require(msg.sender == producer, "call setProducer");
        _;
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function processVRFOutputs(
        VRFOutput[] calldata vrfOutputs,
        uint192 juelsPerFeeCoin,
        uint64 blockHeight,
        bytes32 /* blockHash */
    ) external override onlyProducer returns (OutputServed[] memory outputs) {
        uint16 numOutputs;
        OutputServed[] memory outputsServedFull = new OutputServed[](
            vrfOutputs.length
        );
        for (uint256 i = 0; i < vrfOutputs.length; i++) {
            VRFOutput memory r = vrfOutputs[i];
            processVRFOutput(r, blockHeight, juelsPerFeeCoin);
            if (r.vrfOutput.p[0] != 0 || r.vrfOutput.p[1] != 0) {
                outputsServedFull[i] = OutputServed({
                    height: r.blockHeight,
                    confirmationDelay: r.confirmationDelay
                });
                numOutputs++;
            }
        }
        OutputServed[] memory outputsServed = new OutputServed[](numOutputs);
        for (uint256 i = 0; i < numOutputs; i++) {
            // truncate heights
            outputsServed[i] = outputsServedFull[i];
        }
        return outputsServed;
    }

    function processVRFOutput(
        // extracted to deal with stack-depth issue
        VRFOutput memory output,
        uint64 blockHeight,
        uint192 juelsPerFeeCoin
    ) internal {
        if (output.blockHeight > blockHeight) {
            revert HistoryDomainSeparatorTooOld(
                blockHeight,
                output.blockHeight
            );
        }
        bytes32 seed;
        if (output.vrfOutput.p[0] == 0 && output.vrfOutput.p[1] == 0) {
            // We trust the committee to only sign off on reports with blank VRF
            // outputs for heights where the output already exists onchain.
            // TODO: does this happen when there are callbacks for existing height onchain
            seed = s_seedByBlockHeight[output.blockHeight][
                output.confirmationDelay
            ];
        } else {
            // We trust the committee to only sign off on reports with valid VRF
            // proofs
            seed = keccak256(abi.encode(output.vrfOutput));
            s_seedByBlockHeight[output.blockHeight][
                output.confirmationDelay
            ] = seed;
        }
        uint256 numCallbacks = output.callbacks.length;
        RequestID[] memory fulfilledRequests = new RequestID[](numCallbacks);
        bytes memory successfulFulfillment = new bytes(numCallbacks);
        bytes[] memory errorData = new bytes[](numCallbacks);
        uint16 errorCount = 0;
        for (uint256 j = 0; j < numCallbacks; j++) {
            // We trust the committee to only sign off on reports with valid,
            // requested callbacks.
            CostedCallback memory callback = output.callbacks[j];
            if (!billSubscriberForCallback(callback, juelsPerFeeCoin)) {
                errorData[errorCount] = "underfunded"; // Cannot complete until funded
                errorCount++;
                continue; // Do not process this callback, for now
            }
            (bool isErr, bytes memory errmsg) = processCallback(
                output.blockHeight,
                output.confirmationDelay,
                seed,
                callback
            );
            if (isErr) {
                errorData[errorCount] = errmsg;
                errorCount++;
            } else {
                successfulFulfillment[j] = bytes1(uint8(1)); // succeeded
            }
            fulfilledRequests[j] = callback.callback.requestID;
        }

        if (output.callbacks.length > 0) {
            bytes[] memory truncatedErrorData = new bytes[](errorCount);
            for (uint256 j = 0; j < errorCount; j++) {
                truncatedErrorData[j] = errorData[j];
            }
            emit RandomWordsFulfilled(
                fulfilledRequests,
                successfulFulfillment,
                truncatedErrorData
            );
        }
    }

    function processCallback(
        // extracted to deal with stack-depth issue
        uint64 blockHeight,
        ConfirmationDelay confDelay,
        bytes32 seed,
        CostedCallback memory c
    ) internal returns (bool isErr, bytes memory errmsg) {
        // We trust the committee to only sign off on reports with valid beacon
        // heights which are small enough to fit in a SlotNumber.
        SlotNumber slotNum = SlotNumber.wrap(
            uint32(blockHeight / i_beaconPeriodBlocks)
        );
        Callback memory cb = c.callback;
        bytes32 cbCommitment = keccak256(
            abi.encode(blockHeight, confDelay, cb.subID, cb)
        );
        if (cbCommitment != s_callbackMemo[cb.requestID]) {
            return (true, "unknown callback");
        }
        BeaconRequest memory request = BeaconRequest({
            slotNumber: slotNum,
            confirmationDelay: confDelay,
            numWords: cb.numWords,
            requester: cb.requester
        });
        uint256[] memory fOutput = finalOutput(
            cb.requestID,
            request,
            seed,
            blockHeight
        );
        IVRFCoordinatorConsumer consumer = IVRFCoordinatorConsumer(
            request.requester
        );
        bytes memory resp = abi.encodeWithSelector(
            consumer.rawFulfillRandomWords.selector,
            cb.requestID,
            fOutput,
            cb.arguments
        );
        s_config.reentrancyLock = true;
        bool success = callWithExactGas(
            c.callback.gasAllowance,
            cb.requester,
            resp
        );
        s_config.reentrancyLock = false;

        if (success) {
            delete s_callbackMemo[cb.requestID]; // prevent replays
            return (false, ""); // successfully executed callback
        } else {
            return (true, "execution failed");
        }
    }

    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

    function callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) private returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
            // We want to ensure that we revert if gasAmount >  63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
            // to revert if gasAmount >  63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                revert(0, 0)
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gasAmount, revert
            // (we subtract g//64 because of EIP-150)
            if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
                revert(0, 0)
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }
            // call and return whether we succeeded. ignore return data
            // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
            success := call(
                gasAmount,
                target,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
        return success;
    }

    //////////////////////////////////////////////////////////////////////////////
    // Errors emitted by the above functions

    /// @notice Emitted when too many random words requested in requestRandomness
    /// @param requested number of words requested, which was too large
    /// @param max, largest number of words which can be requested
    error TooManyWords(uint256 requested, uint256 max);

    /// @notice Emitted when zero random words requested in requestRandomness
    error NoWordsRequested();

    /// @notice Emitted when slot number cannot be represented in given int size,
    /// @notice indicating that the contract must be replaced with new
    /// @notice slot-processing logic. (Should not be an issue before the year
    /// @notice 4,000 A.D.)
    error TooManySlotsReplaceContract();

    /// @notice Emitted when number of requests cannot be represented in given int
    /// @notice size, indicating that the contract must be replaced with new
    /// @notice request-nonce logic.
    error TooManyRequestsReplaceContract();

    /// @notice Emitted when redeemRandomness is called by an address which does not
    /// @notice match the original requester's
    /// @param expected the  address which is allowed to retrieve the randomness
    /// @param actual the addres which tried to retrieve the randomness
    error ResponseMustBeRetrievedByRequester(address expected, address actual);

    /// @notice Emitted when redeemRandomness is called for a block which is too
    /// @notice recent to regard as committed.
    /// @param requestHeight the height of the block with the attempted retrieval
    /// @param earliestAllowed the lowest height at which retrieval is allowed
    error BlockTooRecent(uint256 requestHeight, uint256 earliestAllowed);

    /// @notice Emitted when redeemRandomness is called for a block where the seed
    /// @notice has not yet been provided.
    /// @param requestID the request for which retrieval was attempted
    /// @param requestHeight the block height at which retrieval was attempted
    error RandomnessNotAvailable(RequestID requestID, uint256 requestHeight);

    /// @notice Shortest possible confirmation delay.
    /// @dev Note that this is NOT an adequate value for most chains!!!
    uint16 public constant minDelay = 3;

    /// @param beaconPeriodBlocksArg number of blocks between beacon outputs
    ///
    /// @dev Confirmation delays must be at least minDelay, increasing, until the
    /// @dev first zero
    function initialize(
        uint256 beaconPeriodBlocksArg, 
        address linkToken
    ) public initializer {
        __VRFBeaconBilling_init(linkToken);
        if (beaconPeriodBlocksArg == 0) {
            revert BeaconPeriodMustBePositive();
        }
        i_beaconPeriodBlocks = beaconPeriodBlocksArg;

        // i_StartSlot = next block with height divisible by period ("slot")
        uint256 blocksSinceLastSlot = block.number % i_beaconPeriodBlocks;
        uint256 blocksToNextSlot = i_beaconPeriodBlocks - blocksSinceLastSlot;
        i_StartSlot = block.number + blocksToNextSlot;
    }

    /// @notice Emitted when beaconPeriodBlocksArg is zero
    error BeaconPeriodMustBePositive();

    /// @notice Emitted when the blockHeight doesn't fit in uint64
    error UniverseHasEndedBangBangBang(uint256 blockHeight);

    /// @notice Emitted when the first confirmation delay is below the minimum
    error ConfirmationDelayBlocksTooShort(uint16 firstDelay, uint16 minDelay);

    /// @notice Emitted when nonzero confirmation delays are not increasing
    error ConfirmationDelaysNotIncreasing(
        uint16[10] confirmationDelays,
        uint8 violatingIndex
    );

    /// @notice Emitted when nonzero conf delay follows zero conf delay
    error NonZeroDelayAfterZeroDelay(uint16[10] confDelays);

    /// @dev A VRF output is provided whenever
    /// @dev blockHeight % i_beaconPeriodBlocks == 0
    uint256 public i_beaconPeriodBlocks;

    /// @dev First slot for which randomness should be provided. Offchain system
    /// @dev uses this, plus NewHead and SeedProvided, events to determine which
    /// @dev blocks currently require an answer. (NewHead is used to invalidate
    /// @dev slots which follow the current head, in the case of a re-org.)
    uint256 public i_StartSlot;

    /* XXX: Check that this really fits into a word. Does the compiler do the
     right thing with a custom type like ConfirmationDelay? */
    struct RequestParams {
        /// @dev Incremented on each new request; used to disambiguate requests. We
        /// @dev can use a single nonce for all requests with no compromise to
        /// @dev security, because an adversary gains no predictable control over a
        /// @dev target by incrementing this value with interleaving requests.
        RequestID requestID;
        ConfirmationDelay[NUM_CONF_DELAYS] confirmationDelays;

        // Use extra 16 bits to specify a premium? /* XXX:  */
    }

    RequestParams s_requestParams;

    mapping(RequestID => BeaconRequest) s_pendingRequests;

    /// @dev Emitted when randomness is requested without a callback, for the
    /// @dev given beacon height. This signals to the offchain system that it
    /// @dev should provide the VRF output for that height
    ///
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    event RandomnessRequested(
        uint64 indexed nextBeaconOutputHeight,
        ConfirmationDelay confDelay
    );

    /// @dev Emitted when randomness is requested with a callback, for the given
    /// @dev height, to the given address, which should contain a contract with a
    /// @dev fulfillRandomness(RequestID,uint256,bytes) method. This will be
    /// @dev called with the given RequestID, the uint256 output, and the given
    /// @dev bytes arguments.
    ///
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param callback callback details
    /// @param subID subscription ID to bill
    event RandomnessFulfillmentRequested(
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint64 subID,
        Callback callback
    );

    /// returns the information common to both types of requests: The requestID,
    /// the BeaconRequest data, and the height of the VRF output
    function beaconRequest(
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg
    )
        internal
        returns (
            RequestID,
            BeaconRequest memory,
            uint64
        )
    {
        if (numWords > maxNumWords) {
            revert TooManyWords(numWords, maxNumWords);
        }
        if (numWords == 0) {
            revert NoWordsRequested();
        }
        uint256 periodOffset = block.number % i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = block.number +
            i_beaconPeriodBlocks -
            periodOffset;

        uint256 slotNumberBig = nextBeaconOutputHeight / i_beaconPeriodBlocks;
        if (slotNumberBig >= SlotNumber.unwrap(MAX_SLOT_NUMBER)) {
            revert TooManySlotsReplaceContract();
        }
        SlotNumber slotNumber = SlotNumber.wrap(uint32(slotNumberBig));
        RequestParams memory rp = s_requestParams;
        RequestID nonce = rp.requestID;
        if (RequestID.unwrap(nonce) >= RequestID.unwrap(MAX_REQUEST_ID)) {
            revert TooManyRequestsReplaceContract();
        }
        // Ensure next request has unique nonce
        s_requestParams.requestID = RequestID.wrap(RequestID.unwrap(nonce) + 1);

        uint256 i;
        for (i = 0; i < rp.confirmationDelays.length; i++) {
            if (
                ConfirmationDelay.unwrap(rp.confirmationDelays[i]) ==
                ConfirmationDelay.unwrap(confirmationDelayArg)
            ) {
                break;
            }
        }
        if (i >= rp.confirmationDelays.length) {
            revert UnknownConfirmationDelay(
                confirmationDelayArg,
                rp.confirmationDelays
            );
        }

        BeaconRequest memory r = BeaconRequest({
            slotNumber: slotNumber,
            confirmationDelay: confirmationDelayArg,
            numWords: numWords,
            requester: msg.sender
        });
        return (nonce, r, uint64(nextBeaconOutputHeight));
    }

    error UnknownConfirmationDelay(
        ConfirmationDelay givenDelay,
        ConfirmationDelay[NUM_CONF_DELAYS] knownDelays
    );

    // Returns the requested words for the given BeaconRequest and VRF output seed
    function finalOutput(
        RequestID requestID,
        BeaconRequest memory r,
        bytes32 seed,
        uint64 blockHeight
    ) internal pure returns (uint256[] memory) {
        if (seed == bytes32(0)) {
            revert RandomnessNotAvailable(requestID, blockHeight);
        }
        bytes32 finalSeed = keccak256(abi.encode(requestID, r, seed));
        if (r.numWords > maxNumWords) {
            // Could happen if corrupted quorum submits
            revert TooManyWords(r.numWords, maxNumWords); // fake callback
        }
        uint256[] memory randomness = new uint256[](r.numWords);
        for (uint16 i = 0; i < r.numWords; i++) {
            randomness[i] = uint256(keccak256(abi.encodePacked(finalSeed, i)));
        }
        return randomness;
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function transferLink(address recipient, uint256 juelsAmount)
        external
        override
        onlyProducer
    {
        // Poses no re-entrancy issues, because _link.transfer does not yield
        // control flow.
        require(_link.transfer(recipient, juelsAmount), "insufficient funds");
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function batchTransferLink(
        address[] calldata recipients,
        uint256[] calldata paymentsInJuels
    ) external override onlyProducer {
        uint256 numRecipients = recipients.length;
        require(
            numRecipients > 0,
            "number of recipients must be greater than 0"
        );
        require(numRecipients <= MAX_NUM_ORACLES, "too many recipients");
        require(
            numRecipients == paymentsInJuels.length,
            "length of recipients and paymentsInJuels did not match"
        );
        for (
            uint256 recipientidx = 0;
            recipientidx < numRecipients;
            recipientidx++
        ) {
            // Poses no re-entrancy issues, because LINK.transfer does not yield
            // control flow.
            require(
                _link.transfer(
                    recipients[recipientidx],
                    paymentsInJuels[recipientidx]
                ),
                "insufficient funds"
            );
        }
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    function getTotalLinkBalance()
        external
        view
        override
        onlyProducer
        returns (uint256 balance)
    {
        return _link.balanceOf(address(this));
    }

    /// @inheritdoc IVRFCoordinatorProducerAPI
    /// @dev can only be called by producer (call setProducer)
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external override onlyProducer {
        s_requestParams.confirmationDelays = confDelays;
    }

    /// @notice returns allowed confirmationDelays
    function getConfirmationDelays()
        external
        view
        returns (ConfirmationDelay[NUM_CONF_DELAYS] memory)
    {
        return s_requestParams.confirmationDelays;
    }
}