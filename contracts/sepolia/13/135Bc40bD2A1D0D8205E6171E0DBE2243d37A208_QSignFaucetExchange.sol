// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./QSignConnect.sol";
import "./libraries/StringToAddress.sol";
contract QSignFaucetExchange is QSignConnect {
    using StringToAddress for string;

    uint256 internal defaultGasPrice = 5000000000;
    uint256 internal gasLimit = 23000;

    bytes32 internal constant mumbaiChainId =
        0xa24f2e4ffab961d4f74844398efaab23f70f2830a83e1ea4f58097ea0408d254;

    bytes32 internal constant fujiChainId =
        0x5f3f93115d7efd19d933ee81a3fe76ec1e0f35d41927d6fe0875a4f4c29345da;

    uint256 internal nonce = 0;

    uint256 internal keyIndex;
    address payable internal executor;

    mapping(uint256 => Transaction) internal transactions;
    struct Transaction {
        bytes32 dstChainId;
        address to;
        uint256 value;
        uint256 gasPrice;
        uint256 fee;
    }

    receive() external payable {}

    function configExecutor() external {
        string memory addr = getEVMWallet(keyIndex);
        executor = payable(addr.stringToAddress());
    }

    function submitTransactionToFuji(uint256 _gasPrice) external payable {
        submitTransaction(fujiChainId, msg.sender, _gasPrice);
    }

    function submitTransactionToFuji(address _to, uint256 _gasPrice)
        external
        payable
    {
        submitTransaction(fujiChainId, _to, _gasPrice);
    }

    function submitTransactionToMumbai(uint256 _gasPrice) external payable {
        submitTransaction(mumbaiChainId, msg.sender, _gasPrice);
    }

    function submitTransactionToMumbai(address _to, uint256 _gasPrice)
        external
        payable
    {
        submitTransaction(mumbaiChainId, _to, _gasPrice);
    }

    function submitTransaction(
        bytes32 _dstChain,
        address _to,
        uint256 _gasPrice
    ) public payable {
        bytes memory data = rlpEncodeData(abi.encodePacked(block.chainid));

        if (_gasPrice == 0) {
            _gasPrice = defaultGasPrice;
        }

        uint256 transactionFee = msg.value - (_gasPrice * gasLimit);
        require(
            msg.value > transactionFee,
            "insufficient funds for intrinsic transaction cost"
        );
        uint256 value = msg.value - transactionFee;

        Transaction storage t = transactions[nonce];
        t.dstChainId = _dstChain;
        t.to = _to;
        t.value = value;
        t.gasPrice = _gasPrice;
        t.fee = transactionFee;

        bytes memory rlpTransactionData = rlpEncodeTransaction(
            nonce,
            t.gasPrice,
            gasLimit,
            t.to,
            t.value,
            data
        );
        executor.transfer(t.value);
        requestSignatureForTransaction(
            EVMWalletType,
            keyIndex,
            _dstChain,
            rlpTransactionData,
            true
        );

        nonce++;
    }

    function speedUpTransasction(
        uint256 _gasPrice,
        uint256 _nonce
    ) external payable {
        bytes memory data = rlpEncodeData(abi.encodePacked(block.chainid));
        Transaction storage t = transactions[_nonce];

        uint256 oldFee = t.fee;
        uint256 newFee = _gasPrice * gasLimit;
        uint256 feeDifference = newFee - oldFee;

        t.value = (t.value + msg.value) - feeDifference;
        t.fee = newFee;

        bytes memory rlpTransactionData = rlpEncodeTransaction(
            _nonce,
            t.gasPrice,
            gasLimit,
            t.to,
            t.value,
            data
        );

        requestSignatureForTransaction(
            EVMWalletType,
            keyIndex,
            t.dstChainId,
            rlpTransactionData,
            true
        );
    }

    function getTransaction(uint256 _nonce)
        external
        view
        returns (Transaction memory)
    {
        return transactions[_nonce];
    }

    function getNonce() external view returns (uint256) {
        return nonce;
    }

    function getExecutor() external view returns (address payable) {
        return executor;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Interface for the Sign contract
interface IQSign {
    // Request a public key for a given wallet type ID
    // This function should be payable to allow sending Ether along with the request
    function requestPublicKey(bytes32 walletTypeId) external payable;

    // Request a signature for a hash
    // The hash is associated with a specific wallet type and public key index
    // The function is payable to allow sending Ether along with the request
    function requestSignatureForHash(
        bytes32 walletTypeId,
        uint256 publicKeyIndex,
        bytes32 dstChainId,
        bytes32 payloadHash
    ) external payable;

    // Request a signature for data
    // The data is associated with a specific wallet type and public key index
    // The function is payable to allow sending Ether along with the request
    function requestSignatureForData(
        bytes32 walletTypeId,
        uint256 publicKeyIndex,
        bytes32 dstChainId,
        bytes memory payload
    ) external payable;

    // Request a signature for a transaction
    // The transaction data is associated with a specific wallet type and public key index
    // If the broadcast flag is true, the transaction will be broadcasted after being signed
    // The function is payable to allow sending Ether along with the request
    function requestSignatureForTransaction(
        bytes32 walletTypeId,
        uint256 publicKeyIndex,
        bytes32 dstChainId,
        bytes memory payload,
        bool broadcast
    ) external payable;

    // Return the version of the contract
    function version() external view returns (uint256);

    // Check if a wallet type is supported by the contract
    function isWalletTypeSupported(bytes32 walletTypeId)
        external
        view
        returns (bool);

    // Check if a chain ID is supported for a given wallet type
    function isChainIdSupported(bytes32 walletTypeId, bytes32 chainId)
        external
        view
        returns (bool);

    // Return the fee for operations in the contract
    function getFee() external returns (uint256);

    // Return all wallets of a particular type that belong to a certain owner
    function getWallets(bytes32 walletTypeId, address owner)
        external
        view
        returns (string[] memory);

    // Return the wallet of a specific type and index that belongs to a certain owner
    function getWalletByIndex(
        bytes32 walletTypeId,
        address owner,
        uint256 index
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Lib_RLPWriter {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in)
        internal
        pure
        returns (bytes memory)
    {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) internal pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list)
        private
        pure
        returns (bytes memory)
    {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library StringToAddress {
    function stringToAddress(
        string memory _address
    ) public pure returns (address) {
        string memory cleanAddress = remove0xPrefix(_address);
        bytes20 _addressBytes = parseHexStringToBytes20(cleanAddress);
        return address(_addressBytes);
    }

    function remove0xPrefix(
        string memory _hexString
    ) internal pure returns (string memory) {
        if (
            bytes(_hexString).length >= 2 &&
            bytes(_hexString)[0] == "0" &&
            (bytes(_hexString)[1] == "x" || bytes(_hexString)[1] == "X")
        ) {
            return substring(_hexString, 2, bytes(_hexString).length);
        }
        return _hexString;
    }

    function substring(
        string memory _str,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory _strBytes = bytes(_str);
        bytes memory _result = new bytes(_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _result[i - _start] = _strBytes[i];
        }
        return string(_result);
    }

    function parseHexStringToBytes20(
        string memory _hexString
    ) internal pure returns (bytes20) {
        bytes memory _bytesString = bytes(_hexString);
        uint160 _parsedBytes = 0;
        for (uint256 i = 0; i < _bytesString.length; i += 2) {
            _parsedBytes *= 256;
            uint8 _byteValue = parseByteToUint8(_bytesString[i]);
            _byteValue *= 16;
            _byteValue += parseByteToUint8(_bytesString[i + 1]);
            _parsedBytes += _byteValue;
        }
        return bytes20(_parsedBytes);
    }

    function parseByteToUint8(bytes1 _byte) internal pure returns (uint8) {
        if (uint8(_byte) >= 48 && uint8(_byte) <= 57) {
            return uint8(_byte) - 48;
        } else if (uint8(_byte) >= 65 && uint8(_byte) <= 70) {
            return uint8(_byte) - 55;
        } else if (uint8(_byte) >= 97 && uint8(_byte) <= 102) {
            return uint8(_byte) - 87;
        } else {
            revert(string(abi.encodePacked("Invalid byte value: ", _byte)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./libraries/Lib_RLPWriter.sol";
import "./interfaces/IQSign.sol";

// Abstract contract for QSign connections
abstract contract QSignConnect {
    // Use the RLPWriter library for various types
    using Lib_RLPWriter for address;
    using Lib_RLPWriter for uint256;
    using Lib_RLPWriter for bytes;
    using Lib_RLPWriter for bytes[];

    // Address of the QSign contract
    address internal constant qSign =
        payable(address(0xF6B22AcbA6D4b2887B36387ebDD81D17887aD652));

    // The wallet type for EVM-based wallets
    bytes32 internal constant EVMWalletType =
        0xe146c2986893c43af5ff396310220be92058fb9f4ce76b929b80ef0d5307100a;

    // Fee for QSign operations
    uint256 internal _qSignFee = 100;

    // Request a new EVM wallet
    // This function uses the QSign contract to request a new public key for the EVM wallet type
    function requestNewEVMWallet() public virtual {
        uint256 _fee = getQSignFee();
        IQSign(qSign).requestPublicKey{value: _fee}(EVMWalletType);
    }

    // Request a signature for a transaction
    // This function uses the QSign contract to request a signature for a transaction
    // Parameters:
    // - walletTypeId: The ID of the wallet type associated with the transaction
    // - fromAccountIndex: The index of the account from which the transaction will be sent
    // - chainId: The ID of the chain on which the transaction will be executed
    // - rlpTransactionData: The RLP-encoded transaction data
    // - broadcast: A flag indicating whether the transaction should be broadcasted immediately

    function requestSignatureForTransaction(
        bytes32 walletTypeId,
        uint256 fromAccountIndex,
        bytes32 chainId,
        bytes memory rlpTransactionData,
        bool broadcast
    ) internal virtual {
        uint256 _fee = getQSignFee();
        IQSign(qSign).requestSignatureForTransaction{value: _fee}(
            walletTypeId,
            fromAccountIndex,
            chainId,
            rlpTransactionData,
            broadcast
        );
    }

    // Get all EVM wallets associated with this contract
    // This function uses the QSign contract to get all wallets of the EVM type that belong to this contract
    function getEVMWallets() public view virtual returns (string[] memory) {
        return IQSign(qSign).getWallets(EVMWalletType, address(this));
    }

    function getEVMWallet(uint256 index) public view returns (string memory) {
        return
            IQSign(qSign).getWalletByIndex(EVMWalletType, address(this), index);
    }

    // Set the fee for QSign operations
    // This function sets the fee for QSign operations, which is stored in an internal variable
    function setQSignFee(uint256 fee) internal virtual {
        _qSignFee = fee;
    }

    // Adjust the QSign fee based on the current fee
    // This function gets the current fee from the QSign contract and sets the internal QSign fee to that value
    function adjustQSignFee() public virtual {
        uint256 newFee = IQSign(qSign).getFee();
        setQSignFee(newFee);
    }

    // Get the current QSign fee
    // This function returns the current fee for QSign operations
    function getQSignFee() public view virtual returns (uint256) {
        return _qSignFee;
    }

    // Encode data using RLP
    // This function uses the RLPWriter library to encode data into RLP format
    function rlpEncodeData(bytes memory data)
        internal
        virtual
        returns (bytes memory)
    {
        return data.writeBytes();
    }

    // Encode a transaction using RLP
    // This function uses the RLPWriter library to encode a transaction into RLP format
    function rlpEncodeTransaction(
        uint256 nonce,
        uint256 gasPrice,
        uint256 gasLimit,
        address to,
        uint256 value,
        bytes memory data
    ) internal virtual returns (bytes memory) {
        bytes memory nb = nonce.writeUint();
        bytes memory gp = gasPrice.writeUint();
        bytes memory gl = gasLimit.writeUint();
        bytes memory t = to.writeAddress();
        bytes memory v = value.writeUint();
        return _encodeTransaction(nb, gp, gl, t, v, data);
    }

    // Helper function to encode a transaction
    // This function is used by the rlpEncodeTransaction function to encode a transaction into RLP format
    function _encodeTransaction(
        bytes memory nonce,
        bytes memory gasPrice,
        bytes memory gasLimit,
        bytes memory to,
        bytes memory value,
        bytes memory data
    ) internal pure returns (bytes memory) {
        bytes memory zb = uint256(0).writeUint();
        bytes[] memory payload = new bytes[](9);
        payload[0] = nonce;
        payload[1] = gasPrice;
        payload[2] = gasLimit;
        payload[3] = to;
        payload[4] = value;
        payload[5] = data;
        payload[6] = zb;
        payload[7] = zb;
        payload[8] = zb;
        return payload.writeList();
    }
}