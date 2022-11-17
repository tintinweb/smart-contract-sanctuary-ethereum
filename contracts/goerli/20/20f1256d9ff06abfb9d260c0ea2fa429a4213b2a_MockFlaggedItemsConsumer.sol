/**
 *Submitted for verification at Etherscan.io on 2022-11-17
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

/// @title IFlaggedItemConsumer interface
/// @notice Interface for the flagged items consumer
interface IFlaggedItemConsumer {
    /// @dev The function is called by the VRF provider in order to deliver results to the consumer.
    /// @param timestamp The unix timestamp when the request is resolved on Bandchain.
    /// @param collection The address of the collection.
    /// @param itemIds The token ids from the collection.
    /// @param flaggedStatus The list of flagged status according to the given itemIds.
    function submitFlaggedItems(
        uint256 timestamp,
        address collection,
        uint256[] calldata itemIds,
        bool[] calldata flaggedStatus
    ) external;
}

/// @title Decoder library
/// @notice Library for decoding the OBI-encoded input parameters of a FlaggedItems data request
library FlaggedItemsDecoder {
    using Obi for Obi.Data;

    struct Params {
        address collection;
        uint256[] itemIds;
    }

    struct Result {
        bool[] flaggedStatus;
    }

    function bytesToAddress(bytes memory addressBytes) internal pure returns(address addr) {
        require(addressBytes.length == 20, "DATA_DECODE_INVALID_SIZE_FOR_ADDRESS");
        assembly {
            addr := mload(add(addressBytes, 20))
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
        params.collection = bytesToAddress(decoder.decodeBytes());
        bytes memory encodedItemIds = decoder.decodeBytes();
        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");

        uint256 size = encodedItemIds.length >> 5;
        require(size << 5 == encodedItemIds.length, "INVALID_LENGTH_FOR_ENCODE_ITEM_IDS");

        params.itemIds = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 itemId;
            uint256 j = i<<5;
            assembly {
                itemId := mload(add(add(encodedItemIds, 32), j))
            }
            params.itemIds[i] = itemId;
        }
    }

    /// @notice Decodes the encoded data request response result
    /// @param encodedResult Encoded result data
    function decodeResult(bytes memory encodedResult)
        internal
        pure
        returns (bool[] memory flaggedStatus)
    {
        Obi.Data memory decoder = Obi.from(encodedResult);
        bytes memory encodedFlaggedItems = decoder.decodeBytes();
        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");

        flaggedStatus = new bool[](encodedFlaggedItems.length);
        for (uint256 i = 0; i < encodedFlaggedItems.length; i++) {
            if (encodedFlaggedItems[i] == 0x00) {
                flaggedStatus[i] = false;
            } else if (encodedFlaggedItems[i] == 0x01) {
                flaggedStatus[i] = true;
            } else {
                revert("INVALID_BYTES_FOR_ENCODED_FLAGGED_ITEMS");
            }
        }
    }
}

/// @title FlaggedItemsProxy contract
/// @notice Contract for working with BandChain's flagged items oracle-script
contract FlaggedItemsProxy is Ownable, ReentrancyGuard {
    using FlaggedItemsDecoder for bytes;
    using Address for address;

    uint8 public minCount;
    uint8 public askCount;
    uint64 public oracleScriptID;

    IBridge public bridge;
    IFlaggedItemConsumer public consumer;

    event SetBridge(address indexed newBridge);
    event SetFlaggedItemConsumer(address indexed newConsumer);
    event SetOracleScriptID(uint64 newOID);
    event SetMinCount(uint8 newMinCount);
    event SetMinAsk(uint8 newMinAsk);

    constructor(
        uint8 _minCount,
        uint8 _askCount,
        uint64 _oracleScriptID,
        IBridge _bridge,
        IFlaggedItemConsumer _consumer
    ) {
        minCount = _minCount;
        askCount = _askCount;
        oracleScriptID = _oracleScriptID;
        bridge = _bridge;
        consumer = _consumer;

        emit SetMinCount(_minCount);
        emit SetMinAsk(_askCount);
        emit SetOracleScriptID(_oracleScriptID);
        emit SetBridge(address(_bridge));
        emit SetFlaggedItemConsumer(address(_consumer));
    }

    function setMinCount(uint8 _minCount) external onlyOwner {
        minCount = _minCount;
        emit SetMinCount(_minCount);
    }

    function setMinAsk(uint8 _askCount) external onlyOwner {
        askCount = _askCount;
        emit SetMinAsk(_askCount);
    }

    function setOracleScriptID(uint64 _oracleScriptID) external onlyOwner {
        oracleScriptID = _oracleScriptID;
        emit SetOracleScriptID(_oracleScriptID);
    }

    function setBridge(IBridge _bridge) external onlyOwner {
        bridge = _bridge;
        emit SetBridge(address(_bridge));
    }

    function setFlaggedItemConsumer(IFlaggedItemConsumer _consumer) external onlyOwner {
        consumer = _consumer;
        emit SetFlaggedItemConsumer(address(_consumer));
    }

    function relayProof(bytes calldata _proof) external nonReentrant {
        // Verify proof using Bridge and extract the result
        IBridge.Result memory res = bridge.relayAndVerify(_proof);

        // check oracle script id, min count, ask count
        require(res.oracleScriptID == oracleScriptID, "Oracle Script ID not match");
        require(res.minCount == uint8(minCount), "Min Count not match");
        require(res.askCount == uint8(askCount), "Ask Count not match");

        // Check that the request on Band was successfully resolved
        require(res.resolveStatus == IBridge.ResolveStatus.RESOLVE_STATUS_SUCCESS, "Request not successfully resolved");

        // Check if sender is a worker
        FlaggedItemsDecoder.Params memory params = res.params.decodeParams();
        // Extract the task's result
        bool[] memory flaggedStatus = res.result.decodeResult();

        require(params.itemIds.length == flaggedStatus.length, "Size of flags and itemIds not match");

        consumer.submitFlaggedItems(
            uint256(res.resolveTime),
            params.collection,
            params.itemIds,
            flaggedStatus
        );
    }
}

contract MockFlaggedItemsConsumer is IFlaggedItemConsumer {

    struct SavedResult {
        uint256 timestamp;
        address collection;
        uint256[] itemIds;
        bool[] flaggedStatus;
    }

    SavedResult public latestSavedResult;

    function submitFlaggedItems(
        uint256 timestamp,
        address collection,
        uint256[] calldata itemIds,
        bool[] calldata flaggedStatus
    ) external {
        latestSavedResult.timestamp = timestamp;
        latestSavedResult.collection = collection;
        latestSavedResult.itemIds = itemIds;
        latestSavedResult.flaggedStatus = flaggedStatus;
    }

}