/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity ^0.8.17;

interface IBridge {
    enum ResolveStatus {
        RESOLVE_STATUS_OPEN_UNSPECIFIED,
        RESOLVE_STATUS_SUCCESS,
        RESOLVE_STATUS_FAILURE,
        RESOLVE_STATUS_EXPIRED
    }
    /// Result struct is similar packet on Bandchain using to re-calculate result hash.
    struct Result {
        string clientID;
        uint64 oracleScriptID;
        bytes params;
        uint64 askCount;
        uint64 minCount;
        uint64 requestID;
        uint64 ansCount;
        uint64 requestTime;
        uint64 resolveTime;
        ResolveStatus resolveStatus;
        bytes result;
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata data)
        external
        returns (Result memory);

    /// Performs oracle state relay and many times of oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and an array of data verification.
    function relayAndMultiVerify(bytes calldata data)
        external
        returns (Result[] memory);

    // Performs oracle state relay and requests count verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready tobe validated and used.
    /// @param data The encoded data for oracle state relay and requests count verification.
    function relayAndVerifyCount(bytes calldata data)
        external
        returns (uint64, uint64); // block time, requests count
}

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/// @title IVRFProvider interface
/// @notice Interface for the BandVRF provider
interface IVRFProvider {
    /// @dev The function for consumers who want random data.
    /// Consumers can simply make requests to get random data back later.
    /// @param seed Any string that used to initialize the randomizer.
    function requestRandomData(string calldata seed) external payable;
}

/// @title IVRFConsumer interface
/// @notice Interface for the VRF consumer base
interface IVRFConsumer {
    /// @dev The function is called by the VRF provider in order to deliver results to the consumer.
    /// @param seed Any string that used to initialize the randomizer.
    /// @param time Timestamp where the random data was created.
    /// @param result A random bytes for given seed anfd time.
    function consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) external;
}

library Obi {

    struct Data {
        uint256 offset;
        bytes raw;
    }

    function from(bytes memory data) internal pure returns (Data memory) {
        return Data({offset: 0, raw: data});
    }

    modifier shift(Data memory data, uint256 size) {
        require(data.raw.length >= data.offset + size, "Obi: Out of range");
        _;
        data.offset += size;
    }

    function finished(Data memory data) internal pure returns (bool) {
        return data.offset == data.raw.length;
    }

    function decodeU8(Data memory data)
        internal
        pure
        shift(data, 1)
        returns (uint8 value)
    {
        value = uint8(data.raw[data.offset]);
    }

    function decodeI8(Data memory data)
        internal
        pure
        shift(data, 1)
        returns (int8 value)
    {
        value = int8(uint8(data.raw[data.offset]));
    }

    function decodeU16(Data memory data) internal pure returns (uint16 value) {
        value = uint16(decodeU8(data)) << 8;
        value |= uint16(decodeU8(data));
    }

    function decodeI16(Data memory data) internal pure returns (int16 value) {
        value = int16(decodeI8(data)) << 8;
        value |= int16(decodeI8(data));
    }

    function decodeU32(Data memory data) internal pure returns (uint32 value) {
        value = uint32(decodeU16(data)) << 16;
        value |= uint32(decodeU16(data));
    }

    function decodeI32(Data memory data) internal pure returns (int32 value) {
        value = int32(decodeI16(data)) << 16;
        value |= int32(decodeI16(data));
    }

    function decodeU64(Data memory data) internal pure returns (uint64 value) {
        value = uint64(decodeU32(data)) << 32;
        value |= uint64(decodeU32(data));
    }

    function decodeI64(Data memory data) internal pure returns (int64 value) {
        value = int64(decodeI32(data)) << 32;
        value |= int64(decodeI32(data));
    }

    function decodeU128(Data memory data)
        internal
        pure
        returns (uint128 value)
    {
        value = uint128(decodeU64(data)) << 64;
        value |= uint128(decodeU64(data));
    }

    function decodeI128(Data memory data) internal pure returns (int128 value) {
        value = int128(decodeI64(data)) << 64;
        value |= int128(decodeI64(data));
    }

    function decodeU256(Data memory data)
        internal
        pure
        returns (uint256 value)
    {
        value = uint256(decodeU128(data)) << 128;
        value |= uint256(decodeU128(data));
    }

    function decodeI256(Data memory data) internal pure returns (int256 value) {
        value = int256(decodeI128(data)) << 128;
        value |= int256(decodeI128(data));
    }

    function decodeBool(Data memory data) internal pure returns (bool value) {
        value = (decodeU8(data) != 0);
    }

    function decodeBytes(Data memory data)
        internal
        pure
        returns (bytes memory value)
    {
        value = new bytes(decodeU32(data));
        for (uint256 i = 0; i < value.length; i++) {
            value[i] = bytes1(decodeU8(data));
        }
    }

    function decodeString(Data memory data)
        internal
        pure
        returns (string memory value)
    {
        return string(decodeBytes(data));
    }

    function decodeBytes32(Data memory data)
        internal
        pure
        shift(data, 32)
        returns (bytes1[32] memory value)
    {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(value, mload(add(add(raw, 32), offset)))
        }
    }

    function decodeBytes64(Data memory data)
        internal
        pure
        shift(data, 64)
        returns (bytes1[64] memory value)
    {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(value, mload(add(add(raw, 32), offset)))
            mstore(add(value, 32), mload(add(add(raw, 64), offset)))
        }
    }

    function decodeBytes65(Data memory data)
        internal
        pure
        shift(data, 65)
        returns (bytes1[65] memory value)
    {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(value, mload(add(add(raw, 32), offset)))
            mstore(add(value, 32), mload(add(add(raw, 64), offset)))
        }
        value[64] = data.raw[data.offset + 64];
    }
}

/// @title ParamsDecoder library
/// @notice Library for decoding the OBI-encoded input parameters of a VRF data request
library VRFDecoderV2 {
    using Obi for Obi.Data;

    struct Params {
        uint64 time;
        address taskWorker;
        bytes32 seed;
    }

    function bytesToAddress(bytes memory addressBytes) internal pure returns(address addr) {
        require(addressBytes.length == 20, "DATA_DECODE_INVALID_SIZE_FOR_ADDRESS");
        assembly {
            addr := mload(add(addressBytes, 20))
        }
    }

    function bytesToBytes32(bytes memory _bytes) internal pure returns(bytes32 result) {
        require(_bytes.length == 32, "DATA_DECODE_INVALID_SIZE_FOR_BYTES32");
        assembly {
            result := mload(add(_bytes, 32))
        }
    }

    /// @notice Decodes the encoded request input parameters
    /// @param encodedParams Encoded paramter data
    function decodeParams(bytes memory encodedParams)
        internal
        pure
        returns (Params memory params)
    {
        Obi.Data memory decoder = Obi.from(encodedParams);
        params.seed = bytesToBytes32(decoder.decodeBytes());
        params.time = decoder.decodeU64();
        params.taskWorker = bytesToAddress(decoder.decodeBytes());

        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");
    }

    /// @notice Decodes the encoded data request response result
    /// @param encodedResult Encoded result data
    function decodeResult(bytes memory encodedResult)
        internal
        pure
        returns (bytes32 result)
    {
        Obi.Data memory decoder = Obi.from(encodedResult);
        result = bytes32(decoder.decodeBytes());
        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");
    }
}

/// @title VRFProvider contract
/// @notice Contract for working with BandChain's verifiable random function feature
abstract contract VRFProviderBaseV2 is IVRFProvider, Ownable, ReentrancyGuard {
    using VRFDecoderV2 for bytes;
    using Address for address;

    IBridge public bridge;
    uint64 public oracleScriptID;
    uint64 public taskNonce;
    uint256 public minimumFee;

    // Mapping that enforces the client to provide a unique seed for each request
    mapping(address => mapping(string => bool)) public hasClientSeed;
    // Mapping from nonce => task
    mapping(uint64 => Task) public tasks;

    event RandomDataRequested(
        uint64 time,
        uint64 nonce,
        address indexed caller,
        bytes32 blockHash,
        bytes32 seed,
        uint256 chainID,
        uint256 taskFee,
        string clientSeed
    );
    event RandomDataRelayed(
        uint64 time,
        uint64 bandRequestID,
        address indexed to,
        bytes32 resultHash,
        bytes32 seed,
        string clientSeed
    );
    event SetBridge(address indexed newBridge);
    event SetOracleScriptID(uint64 newOID);
    event SetMinimumFee(uint256 newMinimumFee);

    struct Task {
        bool isResolved;
        uint64 time;
        address caller;
        uint256 taskFee;
        bytes32 seed;
        bytes32 result;
        string clientSeed;
    }

    constructor(uint64 _oracleScriptID, IBridge _bridge, uint256 _minimumFee) {
        bridge = _bridge;
        oracleScriptID = _oracleScriptID;
        minimumFee = _minimumFee;

        emit SetBridge(address(_bridge));
        emit SetOracleScriptID(_oracleScriptID);
        emit SetMinimumFee(_minimumFee);
    }

    function getBlockTime() public view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    function getBlockLatestHash() public view virtual returns (bytes32) {
        return blockhash(block.number - 1);
    }

    function getChainID() public view virtual returns(uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getSeed(
        uint64 _time,
        address _caller,
        bytes32 _blockHash,
        uint256 _chainID,
        uint256 _nonce,
        string memory _clientSeed
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_time, _caller, _blockHash, _chainID, _nonce, _clientSeed));
    }

    function setBridge(IBridge _bridge) external onlyOwner {
        bridge = _bridge;
        emit SetBridge(address(_bridge));
    }

    function setOracleScriptID(uint64 _oracleScriptID) external onlyOwner {
        oracleScriptID = _oracleScriptID;
        emit SetOracleScriptID(_oracleScriptID);
    }

    function setMinimumFee(uint256 _minimumFee) external onlyOwner {
        minimumFee = _minimumFee;
        emit SetMinimumFee(_minimumFee);
    }

    function requestRandomData(string calldata _clientSeed)
        external
        payable
        override
        nonReentrant
    {
        require(
            !hasClientSeed[msg.sender][_clientSeed],
            "VRFProviderBase: Seed already existed for this sender"
        );

        uint64 time = getBlockTime();
        uint64 currentTaskNonce = taskNonce;
        bytes32 blockHash = getBlockLatestHash();
        uint256 chainID = getChainID();
        bytes32 seed = getSeed(time, msg.sender, blockHash, chainID, currentTaskNonce, _clientSeed);

        require(msg.value >= minimumFee, "VRFProviderBase: Task fee is lower than the minimum fee");

        // Initiate a new task
        tasks[currentTaskNonce].time = time;
        tasks[currentTaskNonce].caller = msg.sender;
        tasks[currentTaskNonce].seed = seed;
        tasks[currentTaskNonce].taskFee = msg.value;
        tasks[currentTaskNonce].clientSeed = _clientSeed;

        emit RandomDataRequested(
            time,
            currentTaskNonce,
            msg.sender,
            blockHash,
            seed,
            chainID,
            msg.value,
            _clientSeed
        );

        hasClientSeed[msg.sender][_clientSeed] = true;
        taskNonce = currentTaskNonce + 1;
    }

    function relayProof(bytes calldata _proof, uint64 _taskNonce) external nonReentrant {
        // create a local var to save cost
        Task memory _task = tasks[_taskNonce];

        // Check the validity of the task
        require(_task.caller != address(0), "VRFProviderBase: Task not found");
        require(!_task.isResolved, "VRFProviderBase: Task already resolved");

        // Verify proof using Bridge and extract the result
        IBridge.Result memory res = bridge.relayAndVerify(_proof);

        // check oracle script id, min count, ask count
        require(
            res.oracleScriptID == oracleScriptID,
            "VRFProviderBase: Oracle Script ID not match"
        );

        // Check that the request on Band was successfully resolved
        require(
            res.resolveStatus == IBridge.ResolveStatus.RESOLVE_STATUS_SUCCESS,
            "VRFProviderBase: Request not successfully resolved"
        );

        // Check if sender is a worker
        VRFDecoderV2.Params memory params = res.params.decodeParams();
        require(msg.sender == params.taskWorker, "VRFProviderBase: The sender must be the task worker");
        require(_task.seed == params.seed, "VRFProviderBase: Seed is mismatched");
        require(_task.time == params.time, "VRFProviderBase: Time is mismatched");

        // Extract the task's result
        bytes32 result = res.result.decodeResult();

        // Save update the storage task
        tasks[_taskNonce].isResolved = true;
        tasks[_taskNonce].result = result;

        emit RandomDataRelayed(
            _task.time,
            res.requestID,
            _task.caller,
            result,
            params.seed,
            _task.clientSeed
        );

        // End function by call consume function on VRF consumer with data from BandChain
        if (_task.caller.isContract()) {
            IVRFConsumer(_task.caller).consume(
                _task.clientSeed,
                _task.time,
                result
            );
        }

        // Pay fee to the worker
        msg.sender.call{value: _task.taskFee}("");
    }
}

contract VRFProviderV2 is VRFProviderBaseV2 {
    constructor(
        uint64 _oracleScriptID,
        IBridge _bridge,
        uint256 _minimumFee
    ) VRFProviderBaseV2(_oracleScriptID, _bridge, _minimumFee) {}
}