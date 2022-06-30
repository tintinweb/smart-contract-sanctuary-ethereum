/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.14;
pragma abicoder v2;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


interface IVRFProvider {
    /// @dev The function for consumers who want random data.
    /// Consumers can simply make requests to get random data back later.
    /// @param seed Any string that used to initialize the randomizer.
    function requestRandomData(string calldata seed) external payable;
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
library VRFDecoder {
    using Obi for Obi.Data;

    struct Params {
        string seed;
        uint64 time;
        address taskWorker;
    }

    struct Result {
        bytes result;
        bytes proof;
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
        params.seed = decoder.decodeString();
        params.time = decoder.decodeU64();
        params.taskWorker = bytesToAddress(decoder.decodeBytes());

        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");
    }

    /// @notice Decodes the encoded data request response result
    /// @param encodedResult Encoded result data
    function decodeResult(bytes memory encodedResult)
        internal
        pure
        returns (Result memory result)
    {
        Obi.Data memory decoder = Obi.from(encodedResult);
        result.result = decoder.decodeBytes();
        result.proof = decoder.decodeBytes();
        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");
    }
}

/// @title VRFUtils library
/// @notice This library helps separate the codes that are not directly relevant to the core logic of the VRF.
library VRFUtils {

    /// @notice This function helps change the representation of the input from a bytes32 to a lowercase string
    /// without a 0x prefix.
    /// @param _data Any bytes32 data
    function toStringLowerCase(bytes32 _data) internal pure returns (string memory) {
        bytes32 firstPart = bytes16(_data);
        firstPart = bytes32(firstPart) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32(firstPart) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        firstPart = firstPart & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (firstPart & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        firstPart = firstPart & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (firstPart & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        firstPart = firstPart & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (firstPart & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        firstPart = (firstPart & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (firstPart & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        firstPart = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256(firstPart) +
            (uint256(firstPart) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);

        bytes32 secondPart = bytes16(_data << 128);
        secondPart = bytes32(secondPart) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32(secondPart) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        secondPart = secondPart & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (secondPart & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        secondPart = secondPart & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (secondPart & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        secondPart = secondPart & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (secondPart & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        secondPart = (secondPart & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (secondPart & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        secondPart = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (secondPart) +
            (uint256 (secondPart) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);

        return string(abi.encodePacked(firstPart, secondPart));
    }
}


/// @title VRFProvider contract
/// @notice Contract for working with BandChain's verifiable random function feature
abstract contract VRFProviderBase is IVRFProvider, Ownable, ReentrancyGuard {
    using VRFDecoder for bytes;
    using Address for address;
    using VRFUtils for bytes32;

    IBridge public bridge;
    uint64 public oracleScriptID;
    uint8 public minCount;
    uint8 public askCount;
    uint64 public taskNonce;
    uint256 public minimumFee;

    mapping(address => mapping(string => bool)) public hasClientSeed;
    mapping(string => Task) public tasks;

    event RandomDataRequested(
        uint64 time,
        uint64 nonce,
        address indexed caller,
        bytes32 blockHash,
        uint256 chainID,
        uint256 taskFee,
        string clientSeed,
        string seed
    );
    event RandomDataRelayed(
        uint64 time,
        uint64 bandRequestID,
        address indexed to,
        bytes32 resultHash,
        string clientSeed,
        string seed
    );
    event SetBridge(address indexed newBridge);
    event SetOracleScriptID(uint64 newOID);
    event SetMinCount(uint8 newMinCount);
    event SetAskCount(uint8 newAskCount);
    event SetMinimumFee(uint256 newMinimumFee);

    struct Task {
        bool isResolved;
        uint64 time;
        address caller;
        uint256 taskFee;
        string clientSeed;
        bytes result;
        bytes proof;
    }

    constructor(
        IBridge _bridge,
        uint64 _oracleScriptID,
        uint8 _minCount,
        uint8 _askCount,
        uint256 _minimumFee
    ) {
        bridge = _bridge;
        oracleScriptID = _oracleScriptID;
        minCount = _minCount;
        askCount = _askCount;
        minimumFee = _minimumFee;

        emit SetBridge(address(_bridge));
        emit SetOracleScriptID(_oracleScriptID);
        emit SetMinCount(_minCount);
        emit SetAskCount(_askCount);
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
        string memory _clientSeed,
        uint64 _time,
        bytes32 _blockHash,
        uint256 _chainID,
        uint256 _nonce,
        address _caller
    ) public pure returns (string memory) {
        return keccak256(
            abi.encode(_clientSeed, _time, _blockHash, _chainID, _nonce, _caller)
        ).toStringLowerCase();
    }

    function setBridge(IBridge _bridge) external onlyOwner {
        bridge = _bridge;
        emit SetBridge(address(_bridge));
    }

    function setOracleScriptID(uint64 _oracleScriptID) external onlyOwner {
        oracleScriptID = _oracleScriptID;
        emit SetOracleScriptID(_oracleScriptID);
    }

    function setMinCount(uint8 _minCount) external onlyOwner {
        minCount = _minCount;
        emit SetMinCount(_minCount);
    }

    function setAskCount(uint8 _askCount) external onlyOwner {
        askCount = _askCount;
        emit SetAskCount(_askCount);
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
        bytes32 blockHash = getBlockLatestHash();
        uint256 chainID = getChainID();
        uint64 _taskNonce = taskNonce;
        string memory seed = getSeed(
            _clientSeed,
            time,
            blockHash,
            chainID,
            _taskNonce,
            msg.sender
        );

        require(msg.value >= minimumFee, "VRFProviderBase: Task fee is lower than the minimum fee");

        Task storage task = tasks[seed];
        task.caller = msg.sender;
        task.taskFee = msg.value;
        task.time = time;
        task.clientSeed = _clientSeed;

        emit RandomDataRequested(
            time,
            _taskNonce,
            msg.sender,
            blockHash,
            chainID,
            msg.value,
            _clientSeed,
            seed
        );

        hasClientSeed[msg.sender][_clientSeed] = true;
        taskNonce = _taskNonce + 1;
    }

    function relayProof(bytes calldata _proof) external nonReentrant {
        IBridge.Result memory res = bridge.relayAndVerify(_proof);

        // check oracle script id, min count, ask count
        require(
            res.oracleScriptID == oracleScriptID,
            "VRFProviderBase: Oracle Script ID not match"
        );
        require(res.minCount == uint8(minCount), "VRFProviderBase: Min Count not match");
        require(res.askCount == uint8(askCount), "VRFProviderBase: Ask Count not match");
        require(
            res.resolveStatus == IBridge.ResolveStatus.RESOLVE_STATUS_SUCCESS,
            "VRFProviderBase: Request not successfully resolved"
        );

        // Check if sender is a worker
        VRFDecoder.Params memory params = res.params.decodeParams();
        require(msg.sender == params.taskWorker, "VRFProviderBase: The sender must be the task worker");

        // Check that the request on Band was successfully resolved
        // create a local var to save cost
        Task memory _task = tasks[params.seed];

        require(_task.caller != address(0), "VRFProviderBase: Task not found");
        require(!_task.isResolved, "VRFProviderBase: Task already resolved");

        // Mark this task as resolved
        _task.isResolved = true;

        // Extract the task's result
        VRFDecoder.Result memory result = res.result.decodeResult();
        bytes32 resultHash = keccak256(result.result);

        // Save result and its proof
        _task.result = result.result;
        _task.proof = result.proof;

        emit RandomDataRelayed(
            _task.time,
            res.requestID,
            _task.caller,
            resultHash,
            _task.clientSeed,
            params.seed
        );

        // Save _task to the storage
        tasks[params.seed] = _task;

        // End function by call consume function on VRF consumer with data from BandChain
        if (_task.caller.isContract()) {
            IVRFConsumer(_task.caller).consume(
                _task.clientSeed,
                _task.time,
                resultHash
            );
        }

        // Pay fee to the worker
        msg.sender.call{value: _task.taskFee}("");
    }
}

contract VRFProvider is VRFProviderBase {
    constructor(
        IBridge _bridge,
        uint64 _oracleScriptID,
        uint8 _minCount,
        uint8 _askCount,
        uint256 _minimumFee
    ) VRFProviderBase(_bridge, _oracleScriptID, _minCount, _askCount, _minimumFee) {}
}