pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Utils/Refundable.sol";
import "./ExchangeCore.sol";

contract Exchange is
    Ownable,
    Refundable,
    ExchangeCore
{

    constructor (uint256 chainId) LibEIP712ExchangeDomain(chainId) {}
    
    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @return fulfilled boolean
    function fillOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketIdentifier
    )
        override
        public
        payable
        refundFinalBalanceNoReentry
        returns (bool fulfilled)
    {
        return _fillOrder(
            order,
            signature,
            msg.sender,
            marketIdentifier
        );
    }

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @param takerAddress address to fulfill the order for / gift.
    /// @return fulfilled boolean
    function fillOrderFor(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketIdentifier,
        address takerAddress
    )
        override
        public
        payable
        refundFinalBalanceNoReentry
        returns (bool fulfilled)
    {
        return _fillOrder(
            order,
            signature,
            takerAddress,
            marketIdentifier
        );
    }

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(LibOrder.Order memory order)
        override
        public
        payable
        refundFinalBalanceNoReentry
    {
        _cancelOrder(order);
    }

    /// @dev Cancels all orders created by makerAddress with a salt less than or equal to the targetOrderEpoch
    ///      and senderAddress equal to msg.sender (or null address if msg.sender == makerAddress).
    /// @param targetOrderEpoch Orders created with a salt less or equal to this value will be cancelled.
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        override
        external
        payable
        refundFinalBalanceNoReentry
    {
        address makerAddress = msg.sender;
        // orderEpoch is initialized to 0, so to cancelUpTo we need salt + 1
        uint256 newOrderEpoch = targetOrderEpoch + 1;
        uint256 oldOrderEpoch = orderEpoch[makerAddress];

        // Ensure orderEpoch is monotonically increasing
        if (newOrderEpoch <= oldOrderEpoch) {
            revert('EXCHANGE: order epoch error');
        }

        // Update orderEpoch
        orderEpoch[makerAddress] = newOrderEpoch;
        emit CancelUpTo(
            makerAddress,
            newOrderEpoch
        );
    }

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    ///         See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(LibOrder.Order memory order)
        override
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo)
    {
        return _getOrderInfo(order);
    }

    function returnAllETHToOwner() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function returnERC20ToOwner(address ERC20Token) public payable onlyOwner {
        IERC20 CustomToken = IERC20(ERC20Token);
        CustomToken.transferFrom(address(this), msg.sender, CustomToken.balanceOf(address(this)));
    }

    receive() external payable {}
}

pragma solidity ^0.8.4;

contract Refundable
{

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier refundFinalBalanceNoReentry {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        _refundNonZeroBalance();

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function _refundNonZeroBalance()
        internal
    {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }
}

pragma solidity ^0.8.4;


library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            revert('SAFE MATH: mul overflow');
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            revert('SAFE MATH: division by zero');
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            revert('SAFE MATH: sub underflow');
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            revert('SAFE MATH: add overflow');
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

pragma solidity ^0.8.4;


library LibEIP712 {

    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return result EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    )
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct)
        internal
        pure
        returns (bytes32 result)
    {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

pragma solidity ^0.8.4;


contract LibEIP1271 {

    /// @dev Magic bytes returned by EIP1271 wallets on success.
    /// @return 0 Magic bytes.
    bytes4 constant public EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

pragma solidity ^0.8.4;


library LibBytes {

    using LibBytes for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            revert('LIB BYTES: from less than or equals to required');
        }
        if (to > b.length) {
            revert('LIB BYTES: to less than or equals length required');
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            revert('LIB BYTES: from less than or equals to required');
        }
        if (to > b.length) {
            revert('LIB BYTES: to less than or equals length required');
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            revert('LIB BYTES: length freater than zero required');
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            revert('LIB BYTES: length freated than or equals twenty required');
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            revert('LIB BYTES: length greater than or equals twenty required');
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            revert('LIB BYTES: length greater than or equals thirty two required');
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            revert('LIB BYTES: length greater than or equals thirty two required');
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            revert('LIB BYTES: length greater than or equals four required');
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

pragma solidity ^0.8.4;

import "./LibBytes.sol";
import "../Proxies/interfaces/IAssetData.sol";


library LibAssetData {

    using LibBytes for bytes;

    /// @dev Decode AssetProxy identifier
    /// @param assetData AssetProxy-compliant asset data describing an ERC-20, ERC-721, ERC1155, or MultiAsset asset.
    /// @return assetProxyId The AssetProxy identifier
    function decodeAssetProxyId(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC20Token.selector ||
            assetProxyId == IAssetData(address(0)).ERC721Token.selector ||
            assetProxyId == IAssetData(address(0)).ERC1155Assets.selector ||
            assetProxyId == IAssetData(address(0)).MultiAsset.selector ||
            assetProxyId == IAssetData(address(0)).StaticCall.selector,
            "WRONG_PROXY_ID"
        );
        return assetProxyId;
    }

    /// @dev Encode ERC-20 asset data into the format described in the AssetProxy contract specification.
    /// @param tokenAddress The address of the ERC-20 contract hosting the asset to be traded.
    /// @return assetData AssetProxy-compliant data describing the asset.
    function encodeERC20AssetData(address tokenAddress)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(IAssetData(address(0)).ERC20Token.selector, tokenAddress);
        return assetData;
    }

    /// @dev Decode ERC-20 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-20 asset.
    /// @return assetProxyId The AssetProxy identifier, and the address of the ERC-20
    /// tokenAddress contract hosting this asset.
    function decodeERC20AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC20Token.selector,
            "WRONG_PROXY_ID"
        );

        tokenAddress = assetData.readAddress(16);
        return (assetProxyId, tokenAddress);
    }

    /// @dev Encode ERC-721 asset data into the format described in the AssetProxy specification.
    /// @param tokenAddress The address of the ERC-721 contract hosting the asset to be traded.
    /// @param tokenId The identifier of the specific asset to be traded.
    /// @return assetData AssetProxy-compliant asset data describing the asset.
    function encodeERC721AssetData(address tokenAddress, uint256 tokenId)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC721Token.selector,
            tokenAddress,
            tokenId
        );
        return assetData;
    }

    /// @dev Decode ERC-721 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-721 asset.
    /// @return assetProxyId The ERC-721 AssetProxy identifier, the address of the ERC-721
    /// tokenAddress contract hosting this asset, and the identifier of the specific
    /// tokenId asset to be traded.
    function decodeERC721AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256 tokenId
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC721Token.selector,
            "WRONG_PROXY_ID"
        );

        tokenAddress = assetData.readAddress(16);
        tokenId = assetData.readUint256(36);
        return (assetProxyId, tokenAddress, tokenId);
    }

    /// @dev Encode ERC-1155 asset data into the format described in the AssetProxy contract specification.
    /// @param tokenAddress The address of the ERC-1155 contract hosting the asset(s) to be traded.
    /// @param tokenIds The identifiers of the specific assets to be traded.
    /// @param tokenValues The amounts of each asset to be traded.
    /// @param callbackData Data to be passed to receiving contracts when a transfer is performed.
    /// @return assetData AssetProxy-compliant asset data describing the set of assets.
    function encodeERC1155AssetData(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenValues,
        bytes memory callbackData
    )
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC1155Assets.selector,
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
        return assetData;
    }

    /// @dev Decode ERC-1155 asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing an ERC-1155 set of assets.
    /// @return assetProxyId The ERC-1155 AssetProxy identifier, the address of the ERC-1155
    /// contract hosting the assets, an array of the identifiers of the
    /// assets to be traded, an array of asset amounts to be traded, and
    /// callback data.  Each element of the arrays corresponds to the
    /// same-indexed element of the other array.  Return values specified as
    /// `memory` are returned as pointers to locations within the memory of
    /// the input parameter `assetData`.
    function decodeERC1155AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256[] memory tokenIds,
            uint256[] memory tokenValues,
            bytes memory callbackData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC1155Assets.selector,
            "WRONG_PROXY_ID"
        );

        assembly {
            // Skip selector and length to get to the first parameter:
            assetData := add(assetData, 36)
            // Read the value of the first parameter:
            tokenAddress := mload(assetData)
            // Point to the next parameter's data:
            tokenIds := add(assetData, mload(add(assetData, 32)))
            // Point to the next parameter's data:
            tokenValues := add(assetData, mload(add(assetData, 64)))
            // Point to the next parameter's data:
            callbackData := add(assetData, mload(add(assetData, 96)))
        }

        return (
            assetProxyId,
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
    }

    /// @dev Encode data for multiple assets, per the AssetProxy contract specification.
    /// @param amounts The amounts of each asset to be traded.
    /// @param nestedAssetData AssetProxy-compliant data describing each asset to be traded.
    /// @return assetData AssetProxy-compliant data describing the set of assets.
    function encodeMultiAssetData(uint256[] memory amounts, bytes[] memory nestedAssetData)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).MultiAsset.selector,
            amounts,
            nestedAssetData
        );
        return assetData;
    }

    /// @dev Decode multi-asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant data describing a multi-asset basket.
    /// @return assetProxyId The Multi-Asset AssetProxy identifier, an array of the amounts
    /// of the assets to be traded, and an array of the
    /// AssetProxy-compliant data describing each asset to be traded.  Each
    /// element of the arrays corresponds to the same-indexed element of the other array.
    function decodeMultiAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            uint256[] memory amounts,
            bytes[] memory nestedAssetData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).MultiAsset.selector,
            "WRONG_PROXY_ID"
        );

        // solhint-disable indent
        (amounts, nestedAssetData) = abi.decode(
            assetData.slice(4, assetData.length),
            (uint256[], bytes[])
        );
        // solhint-enable indent
    }

    /// @dev Encode StaticCall asset data into the format described in the AssetProxy contract specification.
    /// @param staticCallTargetAddress Target address of StaticCall.
    /// @param staticCallData Data that will be passed to staticCallTargetAddress in the StaticCall.
    /// @param expectedReturnDataHash Expected Keccak-256 hash of the StaticCall return data.
    /// @return assetData AssetProxy-compliant asset data describing the set of assets.
    function encodeStaticCallAssetData(
        address staticCallTargetAddress,
        bytes memory staticCallData,
        bytes32 expectedReturnDataHash
    )
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).StaticCall.selector,
            staticCallTargetAddress,
            staticCallData,
            expectedReturnDataHash
        );
        return assetData;
    }

    /// @dev Decode StaticCall asset data from the format described in the AssetProxy contract specification.
    /// @param assetData AssetProxy-compliant asset data describing a StaticCall asset
    /// @return assetProxyId The StaticCall AssetProxy identifier, the target address of the StaticCAll, the data to be
    /// passed to the target address, and the expected Keccak-256 hash of the static call return data.
    function decodeStaticCallAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address staticCallTargetAddress,
            bytes memory staticCallData,
            bytes32 expectedReturnDataHash
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).StaticCall.selector,
            "WRONG_PROXY_ID"
        );

        (staticCallTargetAddress, staticCallData, expectedReturnDataHash) = abi.decode(
            assetData.slice(4, assetData.length),
            (address, bytes, bytes32)
        );
    }

    /// @dev Reverts if assetData is not of a valid format for its given proxy id.
    /// @param assetData AssetProxy compliant asset data.
    function revertIfInvalidAssetData(bytes memory assetData)
        public
        pure
    {
        bytes4 assetProxyId = assetData.readBytes4(0);

        if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {
            decodeERC20AssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).ERC721Token.selector) {
            decodeERC721AssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).ERC1155Assets.selector) {
            decodeERC1155AssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).MultiAsset.selector) {
            decodeMultiAssetData(assetData);
        } else if (assetProxyId == IAssetData(address(0)).StaticCall.selector) {
            decodeStaticCallAssetData(assetData);
        } else {
            revert("WRONG_PROXY_ID");
        }
    }
}

pragma solidity ^0.8.4;


interface IAssetProxy {

    /// @dev Transfers assets. Either succeeds or throws.
    /// @param assetData Byte array encoded for the respective asset proxy.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external;
    
    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4);
}

pragma solidity ^0.8.4;


// @dev Interface of the asset proxy's assetData.
// The asset proxies take an ABI encoded `bytes assetData` as argument.
// This argument is ABI encoded as one of the methods of this interface.
interface IAssetData {

    /// @dev Function signature for encoding ERC20 assetData.
    /// @param tokenAddress Address of ERC20Token contract.
    function ERC20Token(address tokenAddress)
        external;

    /// @dev Function signature for encoding ERC721 assetData.
    /// @param tokenAddress Address of ERC721 token contract.
    /// @param tokenId Id of ERC721 token to be transferred.
    function ERC721Token(
        address tokenAddress,
        uint256 tokenId
    )
        external;

    /// @dev Function signature for encoding ERC1155 assetData.
    /// @param tokenAddress Address of ERC1155 token contract.
    /// @param tokenIds Array of ids of tokens to be transferred.
    /// @param values Array of values that correspond to each token id to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param callbackData Extra data to be passed to receiver's `onERC1155Received` callback function.
    function ERC1155Assets(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata callbackData
    )
        external;

    /// @dev Function signature for encoding MultiAsset assetData.
    /// @param values Array of amounts that correspond to each asset to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param nestedAssetData Array of assetData fields that will be be dispatched to their correspnding AssetProxy contract.
    function MultiAsset(
        uint256[] calldata values,
        bytes[] calldata nestedAssetData
    )
        external;

    /// @dev Function signature for encoding StaticCall assetData.
    /// @param staticCallTargetAddress Address that will execute the staticcall.
    /// @param staticCallData Data that will be executed via staticcall on the staticCallTargetAddress.
    /// @param expectedReturnDataHash Keccak-256 hash of the expected staticcall return data.
    function StaticCall(
        address staticCallTargetAddress,
        bytes calldata staticCallData,
        bytes32 expectedReturnDataHash
    )
        external;
}

pragma solidity ^0.8.4;

import "../Libs/LibOrder.sol";


interface IWallet {

    /// @dev Validates a hash with the `Wallet` signature type.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return magicValue `bytes4(0xb0671381)` if the signature check succeeds.
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        returns (bytes4 magicValue);
}

pragma solidity ^0.8.4;

import "../Libs/LibOrder.sol";


interface ISignatureValidator {

   // Allowed signature types.
    enum SignatureType {
        Illegal,                     // 0x00, default value
        Invalid,                     // 0x01
        EIP712,                      // 0x02
        EthSign,                     // 0x03
        Wallet,                      // 0x04
        EIP1271Wallet,               // 0x05
        NSignatureTypes              // 0x06, number of signature types. Always leave at end.
    }

    /// @dev Verifies that a hash has been signed by the given signer.
    /// @param hash Any 32-byte hash.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid `true` if the signature is valid for the given hash and signer.
    function isValidHashSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        external
        view
        returns (bool isValid);

    /// @dev Verifies that a signature for an order is valid.
    /// @param order The order.
    /// @param signature Proof that the order has been signed by signer.
    /// @return isValid true if the signature is valid for the given order and signer.
    function isValidOrderSignature(
        LibOrder.Order memory order,
        bytes memory signature
    )
        external
        view
        returns (bool isValid);
}

pragma solidity ^0.8.4;


interface IProtocolFees {

    // Logs updates to the protocol fee multiplier.
    event ProtocolFeeMultiplier(uint256 oldProtocolFeeMultiplier, uint256 updatedProtocolFeeMultiplier);

    // Logs updates to the protocol fixed fee.
    event ProtocolFixedFee(uint256 oldProtocolFixedFee, uint256 updatedProtocolFixedFee);

    // Logs updates to the protocolFeeCollector address.
    event ProtocolFeeCollectorAddress(address oldProtocolFeeCollector, address updatedProtocolFeeCollector);

    /// @dev Allows the owner to update the protocol fee multiplier.
    /// @param updatedProtocolFeeMultiplier The updated protocol fee multiplier.
    function setProtocolFeeMultiplier(uint256 updatedProtocolFeeMultiplier) external;

    /// @dev Allows the owner to update the protocol fixed fee.
    /// @param fixedProtocolFee The updated protocol fixed fee.
    function setProtocolFixedFee(uint256 fixedProtocolFee) external;

    /// @dev Allows the owner to update the protocolFeeCollector address.
    /// @param updatedProtocolFeeCollector The updated protocolFeeCollector contract address.
    function setProtocolFeeCollectorAddress(address updatedProtocolFeeCollector) external;
}

pragma solidity ^0.8.4;

import "../Libs/LibOrder.sol";


abstract contract IExchangeCore {

    // Fill event is emitted whenever an order is filled.
    event Fill(
        address indexed makerAddress,         // Address that created the order.
        address indexed royaltiesAddress,     // Address that received fees.
        bytes makerAssetData,                 // Encoded data specific to makerAsset.
        bytes takerAssetData,                 // Encoded data specific to takerAsset.
        bytes32 indexed orderHash,            // EIP712 hash of order (see LibOrder.getTypedDataHash).
        address takerAddress,                 // Address that filled the order.
        address senderAddress,                // Address that called the Exchange contract (msg.sender).
        uint256 makerAssetAmount,             // Amount of makerAsset sold by maker and bought by taker.
        uint256 takerAssetAmount,             // Amount of takerAsset sold by taker and bought by maker.
        uint256 royaltiesAmount,              // Amount of royalties paid to royaltiesAddress.
        uint256 protocolFeePaid,              // Amount paid to the protocol.
        bytes32 marketplaceIdentifier,        // marketplace identifier.
        uint256 marketplaceFeePaid            // Amount paid to the marketplace brought the taker.
    );

    // Cancel event is emitted whenever an individual order is cancelled.
    event Cancel(
        address indexed makerAddress,         // Address that created the order.
        bytes makerAssetData,                 // Encoded data specific to makerAsset.
        bytes takerAssetData,                 // Encoded data specific to takerAsset.
        address senderAddress,                // Address that called the Exchange contract (msg.sender).
        bytes32 indexed orderHash             // EIP712 hash of order (see LibOrder.getTypedDataHash).
    );

    // CancelUpTo event is emitted whenever `cancelOrdersUpTo` is executed succesfully.
    event CancelUpTo(
        address indexed makerAddress,         // Orders cancelled must have been created by this address.
        uint256 orderEpoch                    // Orders with a salt less than this value are considered cancelled.
    );

    /// @dev Cancels all orders created by makerAddress with a salt less than or equal to the targetOrderEpoch
    /// @param targetOrderEpoch Orders created with a salt less or equal to this value will be cancelled.
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        virtual
        external
        payable;

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @return fulfilled boolean
    function fillOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketIdentifier
    )
        virtual
        public
        payable
        returns (bool fulfilled);

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @param takerAddress address to fulfill the order for / gift.
    /// @return fulfilled boolean
    function fillOrderFor(
        LibOrder.Order memory order,
        bytes memory signature,
        bytes32 marketIdentifier,
        address takerAddress
    )
        virtual
        public
        payable
        returns (bool fulfilled);

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(LibOrder.Order memory order)
        virtual
        public
        payable;

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    ///                   See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(LibOrder.Order memory order)
        virtual
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo);
}

pragma solidity ^0.8.4;

import "../../Utils/LibEIP1271.sol";


abstract contract IEIP1271Wallet is
    LibEIP1271
{
    /// @dev Verifies that a signature is valid.
    /// @param data Arbitrary signed data.
    /// @param signature Proof that data has been signed.
    /// @return magicValue bytes4(0x20c13b0b) if the signature check succeeds.
    function isValidSignature(
        bytes calldata data,
        bytes calldata signature
    )
        virtual
        external
        view
        returns (bytes4 magicValue);
}

pragma solidity ^0.8.4;

import "../Libs/LibOrder.sol";

// solhint-disable
abstract contract IEIP1271Data {

    /// @dev This function's selector is used when ABI encoding the order
    ///      and hash into a byte array before calling `isValidSignature`.
    ///      This function serves no other purpose.
    function OrderWithHash(
        LibOrder.Order calldata order,
        bytes32 orderHash
    )
        virtual
        external
        pure;
}

pragma solidity ^0.8.4;


abstract contract IAssetProxyDispatcher {

    // Logs registration of new asset proxy
    event AssetProxyRegistered(
        bytes4 id,              // Id of new registered AssetProxy.
        address assetProxy      // Address of new registered AssetProxy.
    );

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        virtual external;

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        virtual
        external
        view
        returns (address);
}

pragma solidity ^0.8.4;

import "../Utils/LibBytes.sol";
import "../Utils/LibEIP1271.sol";
import "./Libs/LibOrder.sol";
import "./Libs/LibEIP712ExchangeDomain.sol";
import "./interfaces/IWallet.sol";
import "./interfaces/IEIP1271Wallet.sol";
import "./interfaces/ISignatureValidator.sol";
import "./interfaces/IEIP1271Data.sol";


abstract contract SignatureValidator is
    LibEIP712ExchangeDomain,
    LibEIP1271,
    ISignatureValidator
{
    using LibBytes for bytes;
    using LibOrder for LibOrder.Order;

    // Magic bytes to be returned by `Wallet` signature type validators.
    // bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)"))
    bytes4 private constant LEGACY_WALLET_MAGIC_VALUE = 0xb0671381;

    /// @dev Verifies that a hash has been signed by the given signer.
    /// @param hash Any 32-byte hash.
    /// @param signerAddress Address that should have signed the given hash.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid `true` if the signature is valid for the given hash and signer.
    function isValidHashSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        override
        public
        view
        returns (bool isValid)
    {
        SignatureType signatureType = _readValidSignatureType(
            hash,
            signerAddress,
            signature
        );
        // Only hash-compatible signature types can be handled by this
        // function.
        if (
            signatureType == SignatureType.EIP1271Wallet
        ) {
            revert('SIGNATURE: inappropriate type');
        }
        isValid = _validateHashSignatureTypes(
            signatureType,
            hash,
            signerAddress,
            signature
        );
        return isValid;
    }

    /// @dev Verifies that a signature for an order is valid.
    /// @param order The order.
    /// @param signature Proof that the order has been signed by signer.
    /// @return isValid `true` if the signature is valid for the given order and signer.
    function isValidOrderSignature(
        LibOrder.Order memory order,
        bytes memory signature
    )
        override
        public
        view
        returns (bool isValid)
    {
        bytes32 orderHash = order.getTypedDataHash(EIP712_EXCHANGE_DOMAIN_HASH);
        isValid = _isValidOrderWithHashSignature(
            order,
            orderHash,
            signature
        );
        return isValid;
    }

    /// @dev Verifies that an order, with provided order hash, has been signed
    ///      by the given signer.
    /// @param order The order.
    /// @param orderHash The hash of the order.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if the signature is valid for the given order and signer.
    function _isValidOrderWithHashSignature(
        LibOrder.Order memory order,
        bytes32 orderHash,
        bytes memory signature
    )
        internal
        view
        returns (bool isValid)
    {
        address signerAddress = order.makerAddress;
        SignatureType signatureType = _readValidSignatureType(
            orderHash,
            signerAddress,
            signature
        );
        if (signatureType == SignatureType.EIP1271Wallet) {
            // The entire order is verified by a wallet contract.
            isValid = _validateBytesWithWallet(
                _encodeEIP1271OrderWithHash(order, orderHash),
                signerAddress,
                signature
            );
        } else {
            // Otherwise, it's one of the hash-only signature types.
            isValid = _validateHashSignatureTypes(
                signatureType,
                orderHash,
                signerAddress,
                signature
            );
        }
        return isValid;
    }

    /// Validates a hash-only signature type
    /// (anything but `EIP1271Wallet`).
    function _validateHashSignatureTypes(
        SignatureType signatureType,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        view
        returns (bool isValid)
    {
        // Always invalid signature.
        // Like Illegal, this is always implicitly available and therefore
        // offered explicitly. It can be implicitly created by providing
        // a correctly formatted but incorrect signature.
        if (signatureType == SignatureType.Invalid) {
            if (signature.length != 1) {
                revert('SIGNATURE: invalid length');
            }
            isValid = false;

        // Signature using EIP712
        } else if (signatureType == SignatureType.EIP712) {
            if (signature.length != 66) {
                revert('SIGNATURE: invalid length');
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            address recovered = ecrecover(
                hash,
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;

        // Signed using web3.eth_sign
        } else if (signatureType == SignatureType.EthSign) {
            if (signature.length != 66) {
                revert('SIGNATURE: invalid length');
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            address recovered = ecrecover(
                keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hash
                )),
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;

        // Signature verified by wallet contract.
        } else if (signatureType == SignatureType.Wallet) {
            isValid = _validateHashWithWallet(
                hash,
                signerAddress,
                signature
            );
        }

        return isValid;
    }

    /// @dev Reads the `SignatureType` from a signature with minimal validation.
    function _readSignatureType(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType)
    {
        if (signature.length == 0) {
            revert('SIGNATURE: invalid length');
        }
        return SignatureType(uint8(signature[signature.length - 1]));
    }

    /// @dev Reads the `SignatureType` from the end of a signature and validates it.
    function _readValidSignatureType(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType signatureType)
    {
        // Read the signatureType from the signature
        signatureType = _readSignatureType(
            hash,
            signerAddress,
            signature
        );

        // Disallow address zero because ecrecover() returns zero on failure.
        if (signerAddress == address(0)) {
            revert('SIGNATURE: signerAddress cannot be null');
        }

        // Ensure signature is supported
        if (uint8(signatureType) >= uint8(SignatureType.NSignatureTypes)) {
            revert('SIGNATURE: signature not supported');
        }

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            revert('SIGNATURE: illegal signature');
        }

        return signatureType;
    }

    /// @dev ABI encodes an order and hash with a selector to be passed into
    ///      an EIP1271 compliant `isValidSignature` function.
    function _encodeEIP1271OrderWithHash(
        LibOrder.Order memory order,
        bytes32 orderHash
    )
        private
        pure
        returns (bytes memory encoded)
    {
        return abi.encodeWithSelector(
            IEIP1271Data(address(0)).OrderWithHash.selector,
            order,
            orderHash
        );
    }

    /// @dev Verifies a hash and signature using logic defined by Wallet contract.
    /// @param hash Any 32 byte hash.
    /// @param walletAddress Address that should have signed the given hash
    ///                      and defines its own signature verification method.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return True if the signature is validated by the Wallet.
    function _validateHashWithWallet(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    )
        private
        view
        returns (bool)
    {
        // Backup length of signature
        uint256 signatureLength = signature.length;
        // Temporarily remove signatureType byte from end of signature
        signature.writeLength(signatureLength - 1);
        // Encode the call data.
        bytes memory callData = abi.encodeWithSelector(
            IWallet(address(0)).isValidSignature.selector,
            hash,
            signature
        );
        // Restore the original signature length
        signature.writeLength(signatureLength);
        // Static call the verification function.
        (bool didSucceed, bytes memory returnData) = walletAddress.staticcall(callData);
        // Return the validity of the signature if the call was successful
        if (didSucceed && returnData.length == 32) {
            return returnData.readBytes4(0) == LEGACY_WALLET_MAGIC_VALUE;
        }
        // Revert if the call was unsuccessful
        revert('SIGNATURE: waller error');
    }

    /// @dev Verifies arbitrary data and a signature via an EIP1271 Wallet
    ///      contract, where the wallet address is also the signer address.
    /// @param data Arbitrary signed data.
    /// @param walletAddress Contract that will verify the data and signature.
    /// @param signature Proof that the data has been signed by signer.
    /// @return isValid True if the signature is validated by the Wallet.
    function _validateBytesWithWallet(
        bytes memory data,
        address walletAddress,
        bytes memory signature
    )
        private
        view
        returns (bool isValid)
    {
        isValid = _staticCallEIP1271WalletWithReducedSignatureLength(
            walletAddress,
            data,
            signature,
            1  // The last byte of the signature (signatureType) is removed before making the staticcall
        );
        return isValid;
    }

    /// @dev Performs a staticcall to an EIP1271 compiant `isValidSignature` function and validates the output.
    /// @param verifyingContractAddress Address of EIP1271Wallet.
    /// @param data Arbitrary signed data.
    /// @param signature Proof that the hash has been signed by signer. Bytes will be temporarily be popped
    ///                  off of the signature before calling `isValidSignature`.
    /// @param ignoredSignatureBytesLen The amount of bytes that will be temporarily popped off the the signature.
    /// @return The validity of the signature.
    function _staticCallEIP1271WalletWithReducedSignatureLength(
        address verifyingContractAddress,
        bytes memory data,
        bytes memory signature,
        uint256 ignoredSignatureBytesLen
    )
        private
        view
        returns (bool)
    {
        // Backup length of the signature
        uint256 signatureLength = signature.length;
        // Temporarily remove bytes from signature end
        signature.writeLength(signatureLength - ignoredSignatureBytesLen);
        bytes memory callData = abi.encodeWithSelector(
            IEIP1271Wallet(address(0)).isValidSignature.selector,
            data,
            signature
        );
        // Restore original signature length
        signature.writeLength(signatureLength);
        // Static call the verification function
        (bool didSucceed, bytes memory returnData) = verifyingContractAddress.staticcall(callData);
        // Return the validity of the signature if the call was successful
        if (didSucceed && returnData.length == 32) {
            return returnData.readBytes4(0) == EIP1271_MAGIC_VALUE;
        }
        // Revert if the call was unsuccessful
        revert('SIGNATURE: call was unsuccessful');
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IProtocolFees.sol";


contract ProtocolFees is
    IProtocolFees,
    Ownable
{
    /// @dev The protocol fee multiplier -- the owner can update this field.
    /// @return 0 Gas multplier.
    uint256 public protocolFeeMultiplier;

    /// @dev The protocol fixed fee multiplier -- the owner can update this field.
    /// @return 0 fixed fee.
    uint256 public protocolFixedFee;

    /// @dev The address of the registered protocolFeeCollector contract -- the owner can update this field.
    /// @return 0 Contract to forward protocol fees to.
    address public protocolFeeCollector;

    /// @dev Allows the owner to update the protocol fee multiplier.
    /// @param updatedProtocolFeeMultiplier The updated protocol fee multiplier.
    function setProtocolFeeMultiplier(uint256 updatedProtocolFeeMultiplier)
        override
        external
        onlyOwner
    {
        emit ProtocolFeeMultiplier(protocolFeeMultiplier, updatedProtocolFeeMultiplier);
        protocolFeeMultiplier = updatedProtocolFeeMultiplier;
    }

    /// @dev Allows the owner to update the protocol fixed fee.
    /// @param updatedProtocolFixedFee The updated protocol fixed fee.
    function setProtocolFixedFee(uint256 updatedProtocolFixedFee)
        override
        external
        onlyOwner
    {
        emit ProtocolFixedFee(protocolFixedFee, updatedProtocolFixedFee);
        protocolFixedFee = updatedProtocolFixedFee;
    }

    /// @dev Allows the owner to update the protocolFeeCollector address.
    /// @param updatedProtocolFeeCollector The updated protocolFeeCollector contract address.
    function setProtocolFeeCollectorAddress(address updatedProtocolFeeCollector)
        override
        external
        onlyOwner
    {
        _setProtocolFeeCollectorAddress(updatedProtocolFeeCollector);
    }

    /// @dev Sets the protocolFeeCollector contract address to 0.
    ///      Only callable by owner.
    function detachProtocolFeeCollector()
        external
        onlyOwner
    {
        _setProtocolFeeCollectorAddress(address(0));
    }

    /// @dev Sets the protocolFeeCollector address and emits an event.
    /// @param updatedProtocolFeeCollector The updated protocolFeeCollector contract address.
    function _setProtocolFeeCollectorAddress(address updatedProtocolFeeCollector)
        internal
    {
        emit ProtocolFeeCollectorAddress(protocolFeeCollector, updatedProtocolFeeCollector);
        protocolFeeCollector = updatedProtocolFeeCollector;
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketRegistry is Ownable {
    struct Market {
        uint256 feeMultiplier;
        address feeCollector;
        bool isActive;
    }

    event MarketAdd(bytes32 identifier, uint256 feeMultiplier, address feeCollector);
    event MarketUpdateStatus(bytes32 identifier, bool status);
    event MarketSetFees(bytes32 identifier, uint256 feeMultiplier, address feeCollector);

    bool public distributeMarketFees = true;

    mapping(bytes32 => Market) markets;

    function marketDistribution(bool _distributeMarketFees)
        external
        onlyOwner
    {
        distributeMarketFees = _distributeMarketFees;
    }

    function addMarket(bytes32 identifier, uint256 feeMultiplier, address feeCollector) external onlyOwner {
        require(feeMultiplier >= 0 && feeMultiplier <= 100, "fee multiplier must be betwen 0 to 100");
        markets[identifier] = Market(feeMultiplier, feeCollector, true);
        emit MarketAdd(identifier, feeMultiplier, feeCollector);
    }

    function setMarketStatus(bytes32 identifier, bool isActive)
        external
        onlyOwner
    {
        markets[identifier].isActive = isActive;
        emit MarketUpdateStatus(identifier, isActive);
    }

    function setMarketFees(
        bytes32 identifier,
        uint256 feeMultiplier,
        address feeCollector
    ) external onlyOwner {
        require(feeMultiplier >= 0 && feeMultiplier <= 100, "fee multiplier must be betwen 0 to 100");
        markets[identifier].feeMultiplier = feeMultiplier;
        markets[identifier].feeCollector = feeCollector;
        emit MarketSetFees(identifier, feeMultiplier, feeCollector);
    }
}

pragma solidity ^0.8.4;

import "../../Utils/LibEIP712.sol";


library LibOrder {

    using LibOrder for Order;

    // Hash for the EIP712 Order Schema:
    // keccak256(abi.encodePacked(
    //     "Order(",
    //     "address makerAddress,",
    //     "address takerAddress,",
    //     "address royaltiesAddress,",
    //     "address senderAddress,",
    //     "uint256 makerAssetAmount,",
    //     "uint256 takerAssetAmount,",
    //     "uint256 royaltiesAmount,",
    //     "uint256 expirationTimeSeconds,",
    //     "uint256 salt,",
    //     "bytes makerAssetData,",
    //     "bytes takerAssetData",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_ORDER_SCHEMA_HASH =
        0x85eeee70c9e228559a0ea5492e9915b70dab1efedd40807802f996020d88dc2e;

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's status is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        INVALID_ROYALTIES,           // Order does not have a valid royalties
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FILLED,                      // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

    enum OrderType {
        INVALID,                     // Default value
        LIST,
        OFFER,
        SWAP
    }

    // solhint-disable max-line-length
    /// @dev Canonical order structure.
    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address royaltiesAddress;       // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 royaltiesAmount;        // Fee paid to royaltiesAddress when order is filled.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
    }
    // solhint-enable max-line-length

    /// @dev Order information returned by `getOrderInfo()`.
    struct OrderInfo {
        OrderStatus orderStatus;              // Status that describes order's validity and fillability.
        OrderType orderType;                  // type that describes order's side.
        bytes32 orderHash;                    // EIP712 typed data hash of the order (see LibOrder.getTypedDataHash).
        bool filled;                          // order has already been filled.
    }

    /// @dev Calculates the EIP712 typed data hash of an order with a given domain separator.
    /// @param order The order structure.
    /// @return orderHash EIP712 typed data hash of the order.
    function getTypedDataHash(Order memory order, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = LibEIP712.hashEIP712Message(
            eip712ExchangeDomainHash,
            order.getStructHash()
        );
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order struct.
    /// @param order The order structure.
    /// @return result EIP712 hash of the order struct.
    function getStructHash(Order memory order)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_ORDER_SCHEMA_HASH;
        bytes memory makerAssetData = order.makerAssetData;
        bytes memory takerAssetData = order.takerAssetData;

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ORDER_SCHEMA_HASH,
        //     uint256(order.makerAddress),
        //     uint256(order.takerAddress),
        //     uint256(order.royaltiesAddress),
        //     uint256(order.senderAddress),
        //     order.makerAssetAmount,
        //     order.takerAssetAmount,
        //     order.royaltiesAmount,
        //     order.expirationTimeSeconds,
        //     order.salt,
        //     keccak256(order.makerAssetData),
        //     keccak256(order.takerAssetData)
        // ));

        assembly {
            // Assert order offset (this is an internal error that should never be triggered)
            if lt(order, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(order, 32)
            let pos2 := add(order, 288)
            let pos3 := add(order, 320)

            // Backup
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)

            // Hash in place
            mstore(pos1, schemaHash)
            mstore(pos2, keccak256(add(makerAssetData, 32), mload(makerAssetData)))        // store hash of makerAssetData
            mstore(pos3, keccak256(add(takerAssetData, 32), mload(takerAssetData)))        // store hash of takerAssetData
            result := keccak256(pos1, 384)

            // Restore
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
        }
        return result;
    }
}

pragma solidity ^0.8.4;

import "../../Utils/LibEIP712.sol";


contract LibEIP712ExchangeDomain {

    // EIP712 Exchange Domain Name value
    string constant internal _EIP712_EXCHANGE_DOMAIN_NAME = "Nifty Exchange";

    // EIP712 Exchange Domain Version value
    string constant internal _EIP712_EXCHANGE_DOMAIN_VERSION = "2.0";

    // solhint-disable var-name-mixedcase
    /// @dev Hash of the EIP712 Domain Separator data
    /// @return 0 Domain hash.
    bytes32 public EIP712_EXCHANGE_DOMAIN_HASH;
    // solhint-enable var-name-mixedcase

    /// @param chainId Chain ID of the network this contract is deployed on.
    constructor (
        uint256 chainId
    )
    {
        EIP712_EXCHANGE_DOMAIN_HASH = LibEIP712.hashEIP712Domain(
            _EIP712_EXCHANGE_DOMAIN_NAME,
            _EIP712_EXCHANGE_DOMAIN_VERSION,
            chainId,
            address(this)
        );
    }
}

pragma solidity ^0.8.4;

import "../Utils/LibBytes.sol";
import "../Utils/LibSafeMath.sol";
import "../Utils/LibAssetData.sol";
import "./Libs/LibOrder.sol";
import "./Libs/LibEIP712ExchangeDomain.sol";
import "./interfaces/IExchangeCore.sol";
import "../Proxies/interfaces/IAssetData.sol";
import "./AssetProxyDispatcher.sol";
import "./ProtocolFees.sol";
import "./SignatureValidator.sol";
import "./MarketRegistry.sol";

abstract contract ExchangeCore is
    IExchangeCore,
    AssetProxyDispatcher,
    ProtocolFees,
    SignatureValidator,
    MarketRegistry
{
    using LibOrder for LibOrder.Order;
    using LibSafeMath for uint256;
    using LibBytes for bytes;

    /// @dev orderHash => filled
    /// @return boolean the order has been filled
    mapping (bytes32 => bool) public filled;

    /// @dev orderHash => cancelled
    /// @return boolean the order has been cancelled
    mapping (bytes32 => bool) public cancelled;

    /// @dev makerAddress => lowest salt an order can have in order to be fillable
    /// @return epoc Orders with a salt less than their epoch are considered cancelled
    mapping (address => uint256) public orderEpoch;

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @param takerAddress orider fill for the taker.
    /// @return fulfilled boolean
    function _fillOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        address takerAddress,
        bytes32 marketIdentifier
    )
        internal
        returns (bool fulfilled)
    {
        // Fetch order info
        LibOrder.OrderInfo memory orderInfo = _getOrderInfo(order);

        // Assert that the order is fillable by taker
        _assertFillable(
            order,
            orderInfo,
            takerAddress,
            signature
        );

        bytes32 orderHash = orderInfo.orderHash;

        // Update state
        filled[orderHash] = true;

        Market memory market = markets[marketIdentifier];

        // Settle order
        (uint256 protocolFee, uint256 marketFee) = _settle(
            orderInfo,
            order,
            takerAddress,
            market
        );

        _notifyFill(order, orderHash, takerAddress, protocolFee, marketIdentifier, marketFee);

        return filled[orderHash];
    }

    function _notifyFill(
        LibOrder.Order memory order,
        bytes32 orderHash,
        address takerAddress,
        uint256 protocolFee,
        bytes32 marketIdentifier,
        uint256 marketFee
    ) internal {
        emit Fill(
            order.makerAddress,
            order.royaltiesAddress,
            order.makerAssetData,
            order.takerAssetData,
            orderHash,
            takerAddress,
            msg.sender,
            order.makerAssetAmount,
            order.takerAssetAmount,
            order.royaltiesAmount,
            protocolFee,
            marketIdentifier,
            marketFee
        );
    }

    /// @dev After calling, the order can not be filled anymore.
    ///      Throws if order is invalid or sender does not have permission to cancel.
    /// @param order Order to cancel. Order must be OrderStatus.FILLABLE.
    function _cancelOrder(LibOrder.Order memory order)
        internal
    {
        // Fetch current order status
        LibOrder.OrderInfo memory orderInfo = _getOrderInfo(order);

        // Validate context
        _assertValidCancel(order);

        // Noop if order is already unfillable
        if (orderInfo.orderStatus != LibOrder.OrderStatus.FILLABLE) {
            return;
        }

        // Perform cancel
        _updateCancelledState(order, orderInfo.orderHash);
    }

    /// @dev Updates state with results of cancelling an order.
    ///      State is only updated if the order is currently fillable.
    ///      Otherwise, updating state would have no effect.
    /// @param order that was cancelled.
    /// @param orderHash Hash of order that was cancelled.
    function _updateCancelledState(
        LibOrder.Order memory order,
        bytes32 orderHash
    )
        internal
    {
        // Perform cancel
        cancelled[orderHash] = true;

        // Log cancel
        emit Cancel(
            order.makerAddress,
            order.makerAssetData,
            order.takerAssetData,
            msg.sender,
            orderHash
        );
    }

    /// @dev Validates context for fillOrder. Succeeds or throws.
    /// @param order to be filled.
    /// @param orderInfo OrderStatus, orderHash, and amount already filled of order.
    /// @param takerAddress Address of order taker.
    /// @param signature Proof that the orders was created by its maker.
    function _assertFillable(
        LibOrder.Order memory order,
        LibOrder.OrderInfo memory orderInfo,
        address takerAddress,
        bytes memory signature
    )
        internal
    {
        if (orderInfo.orderType == LibOrder.OrderType.INVALID) {
            revert('EXCHANGE: type illegal');
        }

        if (orderInfo.orderType == LibOrder.OrderType.LIST) {
            address erc20TokenAddress = order.takerAssetData.readAddress(4);
            if (erc20TokenAddress == address(0) && msg.value < order.takerAssetAmount) {
                revert('EXCHANGE: wrong value sent');
            }
        }

        if (orderInfo.orderType != LibOrder.OrderType.LIST && takerAddress != msg.sender) {
            revert('EXCHANGE: fill order for is only valid for buy now');
        }

        if (orderInfo.orderType == LibOrder.OrderType.SWAP) {
            if (msg.value < protocolFixedFee) {
                revert('EXCHANGE: wrong value sent');
            }
        }

        // An order can only be filled if its status is FILLABLE.
        if (orderInfo.orderStatus != LibOrder.OrderStatus.FILLABLE) {
            revert('EXCHANGE: status not fillable');
        }

        // Validate sender is allowed to fill this order
        if (order.senderAddress != address(0)) {
            if (order.senderAddress != msg.sender) {
                revert('EXCHANGE: invalid sender');
            }
        }

        // Validate taker is allowed to fill this order
        if (order.takerAddress != address(0)) {
            if (order.takerAddress != takerAddress) {
                revert('EXCHANGE: invalid taker');
            }
        }

        // Validate signature
        if (!_isValidOrderWithHashSignature(
                order,
                orderInfo.orderHash,
                signature
            )
        ) {
            revert('EXCHANGE: invalid signature');
        }
    }

    /// @dev Validates context for cancelOrder. Succeeds or throws.
    /// @param order to be cancelled.
    function _assertValidCancel(
        LibOrder.Order memory order
    )
        internal
        view
    {
        // Validate sender is allowed to cancel this order
        if (order.senderAddress != address(0)) {
            if (order.senderAddress != msg.sender) {
                revert('EXCHANGE: invalid sender');
            }
        }

        // Validate transaction signed by maker
        address makerAddress = msg.sender;
        if (order.makerAddress != makerAddress) {
            revert('EXCHANGE: invalid maker');
        }
    }

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    ///         See LibOrder.OrderInfo for a complete description.
    function _getOrderInfo(LibOrder.Order memory order)
        internal
        view
        returns (LibOrder.OrderInfo memory orderInfo)
    {
        // Compute the order hash
        orderInfo.orderHash = order.getTypedDataHash(EIP712_EXCHANGE_DOMAIN_HASH);

        bool isTakerAssetDataERC20 = _isERC20Proxy(order.takerAssetData);
        bool isMakerAssetDataERC20 = _isERC20Proxy(order.makerAssetData);

        if (isTakerAssetDataERC20 && !isMakerAssetDataERC20) {
            orderInfo.orderType = LibOrder.OrderType.LIST;
        } else if (!isTakerAssetDataERC20 && isMakerAssetDataERC20) {
            orderInfo.orderType = LibOrder.OrderType.OFFER;
        } else if (!isTakerAssetDataERC20 && !isMakerAssetDataERC20) {
            orderInfo.orderType = LibOrder.OrderType.SWAP;
        } else {
            orderInfo.orderType = LibOrder.OrderType.INVALID;
        }

        // If order.makerAssetAmount is zero the order is invalid
        if (order.makerAssetAmount == 0) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_MAKER_ASSET_AMOUNT;
            return orderInfo;
        }

        // If order.takerAssetAmount is zero the order is invalid
        if (order.takerAssetAmount == 0) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_TAKER_ASSET_AMOUNT;
            return orderInfo;
        }

        if (orderInfo.orderType == LibOrder.OrderType.LIST && order.royaltiesAmount > order.takerAssetAmount) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_ROYALTIES;
            return orderInfo;
        }

        if (orderInfo.orderType == LibOrder.OrderType.OFFER && order.royaltiesAmount > order.makerAssetAmount) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_ROYALTIES;
            return orderInfo;
        }

        // Validate order expiration
        if (block.timestamp >= order.expirationTimeSeconds) {
            orderInfo.orderStatus = LibOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        // Check if order has been cancelled
        if (cancelled[orderInfo.orderHash]) {
            orderInfo.orderStatus = LibOrder.OrderStatus.CANCELLED;
            return orderInfo;
        }

        // Check if order has been filled
        if (filled[orderInfo.orderHash]) {
            orderInfo.orderStatus = LibOrder.OrderStatus.FILLED;
            return orderInfo;
        }

        if (orderEpoch[order.makerAddress] > order.salt) {
            orderInfo.orderStatus = LibOrder.OrderStatus.CANCELLED;
            return orderInfo;
        }

        // All other statuses are ruled out: order is Fillable
        orderInfo.orderStatus = LibOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }


    /// @dev Settles an order by transferring assets between counterparties.
    /// @param orderInfo The order info struct.
    /// @param order Order struct containing order specifications.
    /// @param takerAddress Address selling takerAsset and buying makerAsset.
    function _settle(
        LibOrder.OrderInfo memory orderInfo,
        LibOrder.Order memory order,
        address takerAddress,
        Market memory market
    )
        internal
        returns (uint256 protocolFee, uint256 marketFee)
    {
        bytes memory payerAssetData;
        bytes memory sellerAssetData;
        address payerAddress;
        address sellerAddress;
        uint256 buyerPayment;
        uint256 sellerAmount;

        if (orderInfo.orderType == LibOrder.OrderType.LIST) {
            payerAssetData = order.takerAssetData;
            sellerAssetData = order.makerAssetData;
            payerAddress = msg.sender;
            sellerAddress = order.makerAddress;
            buyerPayment = order.takerAssetAmount;
            sellerAmount = order.makerAssetAmount;
        }

        if (orderInfo.orderType == LibOrder.OrderType.OFFER || orderInfo.orderType == LibOrder.OrderType.SWAP) {
            payerAssetData = order.makerAssetData;
            sellerAssetData = order.takerAssetData;
            payerAddress = order.makerAddress;
            sellerAddress = msg.sender;
            takerAddress = payerAddress;
            buyerPayment = order.makerAssetAmount;
            sellerAmount = order.takerAssetAmount;
        }


        // pay protocol fees
        if (protocolFeeCollector != address(0)) {
            bytes memory protocolAssetData = payerAssetData;
            if (orderInfo.orderType == LibOrder.OrderType.SWAP && protocolFixedFee > 0) {
                protocolFee = protocolFixedFee;
                protocolAssetData = LibAssetData.encodeERC20AssetData(address(0));
            } else if (protocolFeeMultiplier > 0) {
                protocolFee = buyerPayment.safeMul(protocolFeeMultiplier).safeDiv(100);
                buyerPayment = buyerPayment.safeSub(protocolFee);
            }

            if (market.isActive && market.feeCollector != address(0) && market.feeMultiplier > 0 && distributeMarketFees) {
                marketFee = protocolFee.safeMul(market.feeMultiplier).safeDiv(100);
                protocolFee = protocolFee.safeSub(marketFee);
                _dispatchTransfer(
                    protocolAssetData,
                    payerAddress,
                    market.feeCollector,
                    marketFee
                );
            }

            _dispatchTransfer(
                protocolAssetData,
                payerAddress,
                protocolFeeCollector,
                protocolFee
            );
        }

        // pay royalties
        if (order.royaltiesAddress != address(0) && order.royaltiesAmount > 0 ) {
            buyerPayment = buyerPayment.safeSub(order.royaltiesAmount);
            _dispatchTransfer(
                payerAssetData,
                payerAddress,
                order.royaltiesAddress,
                order.royaltiesAmount
            );
        }

        // pay seller // erc20
        _dispatchTransfer(
            payerAssetData,
            payerAddress,
            sellerAddress,
            buyerPayment
        );

        // Transfer seller -> buyer (nft / bundle)
        _dispatchTransfer(
            sellerAssetData,
            sellerAddress,
            takerAddress,
            sellerAmount
        );

        return (protocolFee, marketFee);
      
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Utils/LibBytes.sol";
import "../Proxies/interfaces/IAssetData.sol";
import "../Proxies/interfaces/IAssetProxy.sol";
import "./interfaces/IAssetProxyDispatcher.sol";


contract AssetProxyDispatcher is
    Ownable,
    IAssetProxyDispatcher
{
    using LibBytes for bytes;

    // Mapping from Asset Proxy Id's to their respective Asset Proxy
    mapping (bytes4 => address) internal _assetProxies;

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        override
        external
        onlyOwner
    {
        // Ensure that no asset proxy exists with current id.
        bytes4 assetProxyId = IAssetProxy(assetProxy).getProxyId();
        // Add asset proxy and log registration.
        _assetProxies[assetProxyId] = assetProxy;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return assetProxy The asset proxy address registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        override
        external
        view
        returns (address assetProxy)
    {
        return _assetProxies[assetProxyId];
    }

    function _isERC20Proxy(bytes memory assetData)
        internal
        pure
        returns (bool)
    {
        bytes4 assetProxyId = assetData.readBytes4(0);
        bytes4 erc20ProxyId = IAssetData(address(0)).ERC20Token.selector;

        return assetProxyId == erc20ProxyId;
    }

    /// @dev Forwards arguments to assetProxy and calls `transferFrom`. Either succeeds or throws.
    /// @param assetData Byte array encoded for the asset.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param amount Amount of token to transfer.
    function _dispatchTransfer(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        // Do nothing if no amount should be transferred.
        if (amount > 0) {

            // Ensure assetData is padded to 32 bytes (excluding the id) and is at least 4 bytes long
            if (assetData.length % 32 != 4) {
                revert('ASSET PROXY: invalid length');
            }

            // Lookup assetProxy.
            bytes4 assetProxyId = assetData.readBytes4(0);
            address assetProxy = _assetProxies[assetProxyId];

            // Ensure that assetProxy exists
            if (assetProxy == address(0)) {
                revert('ASSET PROXY: unknown');
            }

            bool ethPayment = false;

            if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {
                address erc20TokenAddress = assetData.readAddress(4);
                ethPayment = erc20TokenAddress == address(0);
            }

            if (ethPayment) {
                if (address(this).balance < amount) {
                    revert("ASSET PROXY: insufficient balance");
                }
                payable(to).transfer(amount);
            } else {
                // Construct the calldata for the transferFrom call.
                bytes memory proxyCalldata = abi.encodeWithSelector(
                    IAssetProxy(address(0)).transferFrom.selector,
                    assetData,
                    from,
                    to,
                    amount
                );

                // Call the asset proxy's transferFrom function with the constructed calldata.
                (bool didSucceed, ) = assetProxy.call(proxyCalldata);

                // If the transaction did not succeed, revert with the returned data.
                if (!didSucceed) {
                    revert("ASSET PROXY: transfer failed");
                }
            }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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