/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @ethereansos/swissknife/contracts/lib/GeneralUtilities.sol


pragma solidity >=0.7.0;


library BehaviorUtilities {

    function randomKey(uint256 i) internal view returns (bytes32) {
        return keccak256(abi.encode(i, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function calculateProjectedArraySizeAndLoopUpperBound(uint256 arraySize, uint256 start, uint256 offset) internal pure returns(uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) {
        if(arraySize != 0 && start < arraySize && offset != 0) {
            uint256 length = start + offset;
            if(start < (length = length > arraySize ? arraySize : length)) {
                projectedArraySize = (projectedArrayLoopUpperBound = length) - start;
            }
        }
    }
}

library ReflectionUtilities {

    function read(address subject, bytes memory inputData) internal view returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.staticcall(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function submit(address subject, uint256 value, bytes memory inputData) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.call{value : value}(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function isContract(address subject) internal view returns (bool) {
        if(subject == address(0)) {
            return false;
        }
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(subject)
        }
        return codeLength > 0;
    }

    function clone(address originalContract) internal returns(address copyContract) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(originalContract, 0x1000000000000000000)
                )
            )
            copyContract := create(0, 0, 32)
            switch extcodesize(copyContract)
                case 0 {
                    invalid()
                }
        }
    }
}

library BytesUtilities {

    bytes private constant ALPHABET = "0123456789abcdef";
    string internal constant BASE64_ENCODER_DATA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function asAddress(bytes memory b) internal pure returns(address) {
        if(b.length == 0) {
            return address(0);
        }
        if(b.length == 20) {
            address addr;
            assembly {
                addr := mload(add(b, 20))
            }
            return addr;
        }
        return abi.decode(b, (address));
    }

    function asAddressArray(bytes memory b) internal pure returns(address[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (address[]));
        }
    }

    function asBool(bytes memory bs) internal pure returns(bool) {
        return asUint256(bs) != 0;
    }

    function asBoolArray(bytes memory b) internal pure returns(bool[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bool[]));
        }
    }

    function asBytesArray(bytes memory b) internal pure returns(bytes[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bytes[]));
        }
    }

    function asString(bytes memory b) internal pure returns(string memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string));
        }
    }

    function asStringArray(bytes memory b) internal pure returns(string[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string[]));
        }
    }

    function asUint256(bytes memory bs) internal pure returns(uint256 x) {
        if (bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }

    function asUint256Array(bytes memory b) internal pure returns(uint256[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (uint256[]));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2+i*2] = ALPHABET[uint256(uint8(data[i] >> 4))];
            str[3+i*2] = ALPHABET[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function asSingletonArray(bytes memory a) internal pure returns(bytes[] memory array) {
        array = new bytes[](1);
        array[0] = a;
    }

    function toBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        string memory table = BASE64_ENCODER_DATA;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

library StringUtilities {

    bytes1 private constant CHAR_0 = bytes1('0');
    bytes1 private constant CHAR_A = bytes1('A');
    bytes1 private constant CHAR_a = bytes1('a');
    bytes1 private constant CHAR_f = bytes1('f');

    bytes  internal constant BASE64_DECODER_DATA = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                                   hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                                   hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                                   hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function isEmpty(string memory test) internal pure returns (bool) {
        return equals(test, "");
    }

    function equals(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint256 i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function asBytes(string memory str) internal pure returns(bytes memory toDecode) {
        bytes memory data = abi.encodePacked(str);
        if(data.length == 0 || data[0] != "0" || (data[1] != "x" && data[1] != "X")) {
            return "";
        }
        uint256 start = 2;
        toDecode = new bytes((data.length - 2) / 2);

        for(uint256 i = 0; i < toDecode.length; i++) {
            toDecode[i] = bytes1(_fromHexChar(uint8(data[start++])) + _fromHexChar(uint8(data[start++])) * 16);
        }
    }

    function toBase64(string memory input) internal pure returns(string memory) {
        return BytesUtilities.toBase64(abi.encodePacked(input));
    }

    function fromBase64(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        bytes memory table = BASE64_DECODER_DATA;

        uint256 decodedLen = (data.length / 4) * 3;

        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            mstore(result, decodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        bytes1 charc = bytes1(c);
        return charc < CHAR_0 || charc > CHAR_f ? 0 : (charc < CHAR_A ? 0 : 10) + c - uint8(charc < CHAR_A ? CHAR_0 : charc < CHAR_a ? CHAR_A : CHAR_a);
    }
}

library Uint256Utilities {
    function asSingletonArray(uint256 n) internal pure returns(uint256[] memory array) {
        array = new uint256[](1);
        array[0] = n;
    }

    function toHex(uint256 _i) internal pure returns (string memory) {
        return BytesUtilities.toString(abi.encodePacked(_i));
    }

    function toString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function sum(uint256[] memory arr) internal pure returns (uint256 result) {
        for(uint256 i = 0; i < arr.length; i++) {
            result += arr[i];
        }
    }
}

library AddressUtilities {
    function asSingletonArray(address a) internal pure returns(address[] memory array) {
        array = new address[](1);
        array[0] = a;
    }

    function toString(address _addr) internal pure returns (string memory) {
        return _addr == address(0) ? "0x0000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(_addr));
    }
}

library Bytes32Utilities {

    function asSingletonArray(bytes32 a) internal pure returns(bytes32[] memory array) {
        array = new bytes32[](1);
        array[0] = a;
    }

    function toString(bytes32 bt) internal pure returns (string memory) {
        return bt == bytes32(0) ?  "0x0000000000000000000000000000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(bt));
    }
}

library TransferUtilities {
    using ReflectionUtilities for address;

    function balanceOf(address erc20TokenAddress, address account) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return account.balance;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).balanceOf.selector, account)), (uint256));
    }

    function allowance(address erc20TokenAddress, address account, address spender) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return 0;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).allowance.selector, account, spender)), (uint256));
    }

    function safeApprove(address erc20TokenAddress, address spender, uint256 value) internal {
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, spender, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function safeTransfer(address erc20TokenAddress, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol


pragma solidity >=0.7.0;


interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}
// File: @ethereansos/swissknife/contracts/generic/impl/LazyInitCapableElement.sol


pragma solidity >=0.7.0;



abstract contract LazyInitCapableElement is ILazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override initializer;
    address public override host;

    constructor(bytes memory lazyInitData) {
        if(lazyInitData.length > 0) {
            _privateLazyInit(lazyInitData);
        }
    }

    function lazyInit(bytes calldata lazyInitData) override external returns (bytes memory lazyInitResponse) {
        return _privateLazyInit(lazyInitData);
    }

    function supportsInterface(bytes4 interfaceId) override external view returns(bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ILazyInitCapableElement).interfaceId ||
            interfaceId == this.lazyInit.selector ||
            interfaceId == this.initializer.selector ||
            interfaceId == this.subjectIsAuthorizedFor.selector ||
            interfaceId == this.host.selector ||
            interfaceId == this.setHost.selector ||
            _supportsInterface(interfaceId);
    }

    function setHost(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = host;
        host = newValue;
        emit Host(oldValue, newValue);
    }

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) public override virtual view returns(bool) {
        (bool chidlElementValidationIsConsistent, bool chidlElementValidationResult) = _subjectIsAuthorizedFor(subject, location, selector, payload, value);
        if(chidlElementValidationIsConsistent) {
            return chidlElementValidationResult;
        }
        if(subject == host) {
            return true;
        }
        if(!host.isContract()) {
            return false;
        }
        (bool result, bytes memory resultData) = host.staticcall(abi.encodeWithSelector(ILazyInitCapableElement(host).subjectIsAuthorizedFor.selector, subject, location, selector, payload, value));
        return result && abi.decode(resultData, (bool));
    }

    function _privateLazyInit(bytes memory lazyInitData) private returns (bytes memory lazyInitResponse) {
        require(initializer == address(0), "init");
        initializer = msg.sender;
        (host, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        emit Host(address(0), host);
        lazyInitResponse = _lazyInit(lazyInitResponse);
    }

    function _lazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _supportsInterface(bytes4 selector) internal virtual view returns (bool);

    function _subjectIsAuthorizedFor(address, address, bytes4, bytes calldata, uint256) internal virtual view returns(bool, bool) {
    }

    modifier authorizedOnly {
        require(_authorizedOnly(), "unauthorized");
        _;
    }

    function _authorizedOnly() internal returns(bool) {
        return subjectIsAuthorizedFor(msg.sender, address(this), msg.sig, msg.data, msg.value);
    }
}
// File: @ethereansos/swissknife/contracts/dynamicMetadata/model/IDynamicMetadataCapableElement.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;


interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}
// File: contracts/core/model/IOrganization.sol


pragma solidity >=0.7.0;


interface IOrganization is IDynamicMetadataCapableElement {

    struct Component {
        bytes32 key;
        address location;
        bool active;
        bool log;
    }

    function keyOf(address componentAddress) external view returns(bytes32);
    function history(bytes32 key) external view returns(address[] memory componentsAddresses);
    function batchHistory(bytes32[] calldata keys) external view returns(address[][] memory componentsAddresses);

    function get(bytes32 key) external view returns(address componentAddress);
    function list(bytes32[] calldata keys) external view returns(address[] memory componentsAddresses);
    function isActive(address subject) external view returns(bool);
    function keyIsActive(bytes32 key) external view returns(bool);

    function set(Component calldata) external returns(address replacedComponentAddress);
    function batchSet(Component[] calldata) external returns (address[] memory replacedComponentAddresses);

    event ComponentSet(bytes32 indexed key, address indexed from, address indexed to, bool active);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
}
// File: contracts/base/model/IProposalsManager.sol


pragma solidity >=0.7.0;



interface IProposalsManager is IERC1155Receiver, ILazyInitCapableElement {

    struct ProposalCode {
        address location;
        bytes bytecode;
    }

    struct ProposalCodes {
        ProposalCode[] codes;
        bool alsoTerminate;
    }

    struct Proposal {
        address proposer;
        address[] codeSequence;
        uint256 creationBlock;
        uint256 accept;
        uint256 refuse;
        address triggeringRules;
        address[] canTerminateAddresses;
        address[] validatorsAddresses;
        bool validationPassed;
        uint256 terminationBlock;
        bytes votingTokens;
    }

    struct ProposalConfiguration {
        address[] collections;
        uint256[] objectIds;
        uint256[] weights;
        address creationRules;
        address triggeringRules;
        address[] canTerminateAddresses;
        address[] validatorsAddresses;
    }

    function batchCreate(ProposalCodes[] calldata codeSequences) external returns(bytes32[] memory createdProposalIds);

    function list(bytes32[] calldata proposalIds) external view returns(Proposal[] memory);

    function votes(bytes32[] calldata proposalIds, address[] calldata voters, bytes32[][] calldata items) external view returns(uint256[][] memory accepts, uint256[][] memory refuses, uint256[][] memory toWithdraw);
    function weight(bytes32 code) external view returns(uint256);

    function vote(address erc20TokenAddress, bytes memory permitSignature, bytes32 proposalId, uint256 accept, uint256 refuse, address voter, bool alsoTerminate) external payable;
    function batchVote(bytes[] calldata data) external payable;

    function withdrawAll(bytes32[] memory proposalIds, address voterOrReceiver, bool afterTermination) external;

    function terminate(bytes32[] calldata proposalIds) external;

    function configuration() external view returns(ProposalConfiguration memory);
    function setConfiguration(ProposalConfiguration calldata newValue) external returns(ProposalConfiguration memory oldValue);

    function lastProposalId() external view returns(bytes32);

    function lastVoteBlock(address voter) external view returns (uint256);

    event ProposalCreated(address indexed proposer, address indexed code, bytes32 indexed proposalId);
    event ProposalWeight(bytes32 indexed proposalId, address indexed collection, uint256 indexed id, bytes32 key, uint256 weight);
    event ProposalTerminated(bytes32 indexed proposalId, bool result, bytes errorData);

    event Accept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event MoveToAccept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event RetireAccept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);

    event Refuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event MoveToRefuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event RetireRefuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
}

interface IProposalChecker {
    function check(address proposalsManagerAddress, bytes32 id, bytes calldata data, address from, address voter) external view returns(bool);
}

interface IExternalProposalsManagerCommands {
    function createProposalCodeSequence(bytes32 proposalId, IProposalsManager.ProposalCode[] memory codeSequenceInput, address sender) external returns (address[] memory codeSequence, IProposalsManager.ProposalConfiguration memory localConfiguration);
    function proposalCanBeFinalized(bytes32 proposalId, IProposalsManager.Proposal memory proposal, bool validationPassed, bool result) external view returns (bool);
    function isVotable(bytes32 proposalId, IProposalsManager.Proposal memory proposal, address from, address voter, bool voteOrWithtraw) external view returns (bytes memory response);
}
// File: contracts/base/impl/ProposalsManager.sol


pragma solidity >=0.7.0;







library ProposalsManagerLibrary {
    using ReflectionUtilities for address;

    function createCodeSequence(IProposalsManager.ProposalCode[] memory codeSequenceInput) external returns (address[] memory codeSequence) {
        require(codeSequenceInput.length > 0, "code");
        codeSequence = new address[](codeSequenceInput.length);
        for(uint256 i = 0; i < codeSequenceInput.length; i++) {
            address code = codeSequenceInput[i].location;
            bytes memory bytecode = codeSequenceInput[i].bytecode;
            if(bytecode.length > 0) {
                assembly {
                    code := create(0, add(bytecode, 0x20), mload(bytecode))
                }
            }
            codeSequence[i] = code;
            bool isContract;
            assembly {
                isContract := not(iszero(extcodesize(code)))
            }
            require(isContract, "code");
        }
    }

    function giveBack(address[] memory collections, uint256[] memory objectIds, uint256[] memory accepts, uint256[] memory refuses, address receiver) external returns (bool almostOne) {
        for(uint256 i = 0; i < collections.length; i++) {
            uint256 amount = accepts[i] + refuses[i];
            if(amount == 0) {
                continue;
            }
            if(collections[i] != address(0)) {
                collections[i].submit(0, abi.encodeWithSelector(IERC1155(address(0)).safeTransferFrom.selector, address(this), receiver, objectIds[i], amount, ""));
            } else {
                _safeTransferOrTransferFrom(address(uint160(objectIds[i])), address(0), receiver, amount);
            }
            almostOne = true;
        }
    }

    function safeTransferOrTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) external {
        _safeTransferOrTransferFrom(erc20TokenAddress, from, to, value);
    }

    function _safeTransferOrTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) private {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            if(from != address(0)) {
                return;
            }
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, from == address(0) ? abi.encodeWithSelector(IERC20(address(0)).transfer.selector, to, value) : abi.encodeWithSelector(IERC20(address(0)).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)));
    }

    function setConfiguration(IProposalsManager.ProposalConfiguration storage _configuration, IProposalsManager.ProposalConfiguration memory newValue) external returns(IProposalsManager.ProposalConfiguration memory oldValue) {
        oldValue = _configuration;
        require(newValue.collections.length == newValue.objectIds.length && newValue.collections.length == newValue.weights.length, "lengths");
        _configuration.collections = newValue.collections;
        _configuration.objectIds = newValue.objectIds;
        _configuration.weights = newValue.weights;
        _configuration.creationRules = newValue.creationRules;
        _configuration.triggeringRules = newValue.triggeringRules;
        _configuration.canTerminateAddresses = newValue.canTerminateAddresses;
        _configuration.validatorsAddresses = newValue.validatorsAddresses;
    }

    function performAuthorizedCall(address host, bytes32 key, address subject, bytes memory inputData) external {
        IOrganization organization = IOrganization(host);
        organization.set(IOrganization.Component(key, subject, true, false));
        (bool result, bytes memory returnData) = subject.call(inputData);
        if(!result) {
            returnData = abi.encode(subject, returnData);
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
        if(organization.isActive(subject)) {
            organization.set(IOrganization.Component(key, address(0), false, false));
        }
    }
}

contract ProposalsManager is IProposalsManager, LazyInitCapableElement {
    using ReflectionUtilities for address;

    mapping(bytes32 => Proposal) private _proposal;
    mapping(bytes32 => uint256) public override weight;

    // Mapping for proposalId => address => item => weighted accept votes
    mapping(bytes32 => mapping(address => mapping(bytes32 => uint256))) private _accept;

    // Mapping for proposalId => address => item => weighted refuse votes
    mapping(bytes32 => mapping(address => mapping(bytes32 => uint256))) private _refuse;

    // If the address has withdrawed or not the given objectId
    mapping(bytes32 => mapping(address => mapping(bytes32 => uint256))) private _toWithdraw;

    ProposalConfiguration private _configuration;

    uint256 private _keyIndex;

    bool private _hostIsProposalCommand;

    bytes32 public override lastProposalId;

    mapping(address => uint256) public override lastVoteBlock;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns(bytes memory) {
        (_hostIsProposalCommand, lazyInitData) = abi.decode(lazyInitData, (bool, bytes));
        if(lazyInitData.length > 0) {
            ProposalsManagerLibrary.setConfiguration(_configuration, abi.decode(lazyInitData, (ProposalConfiguration)));
        }
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IProposalsManager).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    bytes32[] private _toTerminate;

    function batchCreate(ProposalCodes[] calldata proposalCodesArray) external override returns(bytes32[] memory createdProposalIds) {
        createdProposalIds = new bytes32[](proposalCodesArray.length);
        ProposalConfiguration memory standardConfiguration = _configuration;
        for(uint256 i = 0; i < proposalCodesArray.length; i++) {
            ProposalCodes memory proposalCodes = proposalCodesArray[i];
            bytes32 proposalId = createdProposalIds[i] = lastProposalId = _randomKey();
            if(proposalCodes.alsoTerminate) {
                _toTerminate.push(proposalId);
            }
            (address[] memory codeSequence, ProposalConfiguration memory localConfiguration) =
            _hostIsProposalCommand ? IExternalProposalsManagerCommands(host).createProposalCodeSequence(proposalId, proposalCodes.codes, msg.sender) :
            (ProposalsManagerLibrary.createCodeSequence(proposalCodes.codes), standardConfiguration);
            (address[] memory collections, uint256[] memory objectIds, uint256[] memory weights) = (
                localConfiguration.collections.length > 0 ? localConfiguration.collections : standardConfiguration.collections,
                localConfiguration.objectIds.length > 0 ? localConfiguration.objectIds : standardConfiguration.objectIds,
                localConfiguration.weights.length > 0 ? localConfiguration.weights : standardConfiguration.weights
            );
            for(uint256 z = 0; z < collections.length; z++) {
                bytes32 key = keccak256(abi.encodePacked(proposalId, collections[z], objectIds[z]));
                emit ProposalWeight(proposalId, collections[z], objectIds[z], key, weight[key] = weights[z]);
            }
            (bool result, bytes memory response) = _validateRules(localConfiguration.creationRules != address(0) ? localConfiguration.creationRules : standardConfiguration.creationRules, proposalId, abi.encode(_proposal[proposalId] = Proposal(
                msg.sender,
                codeSequence,
                block.number,
                0,
                0,
                localConfiguration.triggeringRules != address(0) ? localConfiguration.triggeringRules : standardConfiguration.triggeringRules,
                localConfiguration.canTerminateAddresses.length > 0 ? localConfiguration.canTerminateAddresses : standardConfiguration.canTerminateAddresses,
                localConfiguration.validatorsAddresses.length > 0 ? localConfiguration.validatorsAddresses : standardConfiguration.validatorsAddresses,
                false,
                0,
                abi.encode(collections, objectIds, weights)
            )), msg.sender);
            if(!result) {
                if(response.length > 0) {
                    assembly {
                        revert(add(response, 0x20), mload(response))
                    }
                } else {
                    revert("creation");
                }
            }
            for(uint256 z = 0; z < codeSequence.length; z++) {
                emit ProposalCreated(msg.sender, codeSequence[z], proposalId);
            }
        }
        bytes32[] memory toTerminate = _toTerminate;
        delete _toTerminate;
        if(toTerminate.length > 0) {
            terminate(toTerminate);
        }
    }

    function list(bytes32[] calldata proposalIds) external override view returns(Proposal[] memory proposals) {
        proposals = new Proposal[](proposalIds.length);
        for(uint256 i = 0; i < proposalIds.length; i++) {
            proposals[i] = _proposal[proposalIds[i]];
        }
    }

    function votes(bytes32[] calldata proposalIds, address[] calldata voters, bytes32[][] calldata items) external override view returns(uint256[][] memory accepts, uint256[][] memory refuses, uint256[][] memory toWithdraw) {
        accepts = new uint256[][](proposalIds.length);
        refuses = new uint256[][](proposalIds.length);
        toWithdraw = new uint256[][](proposalIds.length);
        for(uint256 i = 0; i < proposalIds.length; i++) {
            accepts[i] = new uint256[](items[i].length);
            refuses[i] = new uint256[](items[i].length);
            toWithdraw[i] = new uint256[](items[i].length);
            for(uint256 z = 0; z < items[i].length; z++) {
                accepts[i][z] = _accept[proposalIds[i]][voters[i]][items[i][z]];
                refuses[i][z] = _refuse[proposalIds[i]][voters[i]][items[i][z]];
                toWithdraw[i][z] = _toWithdraw[proposalIds[i]][voters[i]][items[i][z]];
            }
        }
    }

    function onERC1155Received(address operator, address from, uint256 objectId, uint256 amount, bytes calldata data) external override returns(bytes4) {
        if(operator != address(this) || data.length > 0) {
            _onItemReceived(from, objectId, amount, data);
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata objectIds, uint256[] calldata amounts, bytes calldata data) external override returns (bytes4) {
        if(operator != address(this) || data.length > 0) {
            bytes[] memory dataArray = abi.decode(data, (bytes[]));
            for(uint256 i = 0; i < objectIds.length; i++) {
                _onItemReceived(from, objectIds[i], amounts[i], dataArray[i]);
            }
        }
        return this.onERC1155BatchReceived.selector;
    }

    function vote(address erc20TokenAddress, bytes memory permitSignature, bytes32 proposalId, uint256 accept, uint256 refuse, address voter, bool alsoTerminate) public override payable {
        if(permitSignature.length > 0) {
            (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(permitSignature, (uint8, bytes32, bytes32, uint256));
            IERC20Permit(erc20TokenAddress).permit(msg.sender, address(this), (accept + refuse), deadline, v, r, s);
        }
        uint256 transferedValue = _safeTransferFrom(erc20TokenAddress, (accept + refuse));
        require(erc20TokenAddress != address(0) || transferedValue == msg.value, "ETH");
        _vote(msg.sender, address(0), uint160(erc20TokenAddress), transferedValue, proposalId, accept, refuse, voter, alsoTerminate);
    }

    function batchVote(bytes[] calldata data) external override payable {
        for(uint256 i = 0; i < data.length; i++) {
            (address erc20TokenAddress, bytes memory permitSignature, bytes32 proposalId, uint256 accept, uint256 refuse, address voter, bool alsoTerminate) = abi.decode(data[i], (address, bytes, bytes32, uint256, uint256, address, bool));
            vote(erc20TokenAddress, permitSignature, proposalId, accept, refuse, voter, alsoTerminate);
        }
    }

    function withdrawAll(bytes32[] memory proposalIds, address voterOrReceiver, bool afterTermination) external override {
        bool almostOne = false;
        address voter = msg.sender;
        address receiver = voterOrReceiver != address(0) ? voterOrReceiver : msg.sender;
        if(afterTermination) {
            require(voterOrReceiver != address(0), "Mandatory");
            voter = voterOrReceiver;
            receiver = voterOrReceiver;
        }
        for(uint256 z = 0; z < proposalIds.length; z++) {
            bytes32 proposalId = proposalIds[z];
            (bool canVote, address[] memory collections, uint256[] memory objectIds, uint256[] memory accepts, uint256[] memory refuses) = _withdrawAll(proposalId, afterTermination ? voter : msg.sender, voter);
            require(canVote ? !afterTermination : afterTermination, "termination switch");
            bool result = ProposalsManagerLibrary.giveBack(collections, objectIds, accepts, refuses, receiver);
            almostOne = almostOne || result;
        }
        require(almostOne, "No transfers");
    }

    function terminate(bytes32[] memory proposalIds) public override {
        for(uint256 i = 0; i < proposalIds.length; i++) {
            Proposal storage proposal = _proposal[proposalIds[i]];
            require(proposal.terminationBlock == 0, "terminated");
            require(proposal.validationPassed || _mustStopAtFirst(true, proposal.canTerminateAddresses, proposalIds[i], msg.sender, msg.sender), "Cannot Terminate");
            if(!proposal.validationPassed) {
                if(_mustStopAtFirst(false, proposal.validatorsAddresses, proposalIds[i], msg.sender, msg.sender)) {
                    _finalizeTermination(proposalIds[i], proposal, false, false);
                    emit ProposalTerminated(proposalIds[i], false, "");
                    continue;
                }
            }
            (bool result, bytes memory errorData) = address(this).call(abi.encodeWithSelector(this.tryExecute.selector, proposal.codeSequence, abi.encodeWithSelector(0xe751f271, proposalIds[i]), new bytes[](0)));//execute(bytes32)
            if(result && errorData.length == 0) {
                (result, ) = _validateRules(proposal.triggeringRules, proposalIds[i], abi.encode(proposal), msg.sender);
                errorData = result ? errorData : bytes("triggering");
            }
            _finalizeTermination(proposalIds[i], proposal, true, result && errorData.length == 0);
            emit ProposalTerminated(proposalIds[i], result, errorData);
        }
    }

    function tryExecute(address[] memory codeSequence, bytes memory inputData, bytes[] memory bytecodes) external {
        require(msg.sender == address(this));
        for(uint256 i = 0; i < codeSequence.length; i++) {
            address codeLocation = codeSequence[i];
            if(i < bytecodes.length && bytecodes[i].length > 0) {
                require(codeSequence[i] == address(0), "codeLocation");
                bytes memory bytecode = bytecodes[i];
                uint256 codeSize;
                assembly {
                    codeLocation := create(0, add(bytecode, 0x20), mload(bytecode))
                    codeSize := extcodesize(codeLocation)
                }
                require(codeLocation != address(0), "codeLocation");
                require(codeSize > 0, "codeSize");
            }
            ProposalsManagerLibrary.performAuthorizedCall(host, _randomKey(), codeLocation, inputData);
        }
    }

    function configuration() external override view returns(ProposalConfiguration memory) {
        return _configuration;
    }

    function setConfiguration(ProposalConfiguration calldata newValue) external override authorizedOnly returns(ProposalConfiguration memory oldValue) {
        return ProposalsManagerLibrary.setConfiguration(_configuration, newValue);
    }

    function _onItemReceived(address from, uint256 objectId, uint256 amount, bytes memory data) private {
        (bytes32 proposalId, uint256 accept, uint256 refuse, address voter, bool alsoTterminate) = abi.decode(data, (bytes32, uint256, uint256, address, bool));
        _vote(from, msg.sender, objectId, amount, proposalId, accept, refuse, voter, alsoTterminate);
    }

    function _vote(address from, address collection, uint256 objectId, uint256 amount, bytes32 proposalId, uint256 accept, uint256 refuse, address voterInput, bool alsoTterminate) private {
        if(amount == 0) {
            return;
        }
        require(amount == (accept + refuse), "amount");
        address voter = voterInput == address(0) ? from : voterInput;
        _ensure(proposalId, from, voter, true);
        bytes32 item = keccak256(abi.encodePacked(proposalId, collection, objectId));
        uint256 proposalWeight = weight[item];
        require(proposalWeight > 0, "item");
        _toWithdraw[proposalId][voter][item] += (accept + refuse);
        if(accept > 0) {
            _accept[proposalId][voter][item] += accept;
            _proposal[proposalId].accept += (accept * proposalWeight);
            emit Accept(proposalId, voter, item, accept);
        }
        if(refuse > 0) {
            _refuse[proposalId][voter][item] += refuse;
            _proposal[proposalId].refuse += (refuse * proposalWeight);
            emit Refuse(proposalId, voter, item, refuse);
        }
        if(accept > 0 || refuse > 0) {
            lastVoteBlock[voter] = block.number;
        }
        if(alsoTterminate) {
            bytes32[] memory proposalIds = new bytes32[](1);
            proposalIds[0] = proposalId;
            terminate(proposalIds);
        }
    }

    function _ensure(bytes32 proposalId, address from, address voter, bool voteOrWithtraw) private view returns (bool canVote) {
        Proposal memory proposal = _proposal[proposalId];
        require(proposal.creationBlock > 0, "proposal");
        if(_hostIsProposalCommand) {
            bytes memory response = IExternalProposalsManagerCommands(host).isVotable(proposalId, proposal, from, voter, voteOrWithtraw);
            if(response.length > 0) {
                return abi.decode(response, (bool));
            }
        }
        bool isTerminated;
        canVote = !(isTerminated = proposal.terminationBlock != 0) && !proposal.validationPassed && !_mustStopAtFirst(true, proposal.canTerminateAddresses, proposalId, from, voter);
        if(voteOrWithtraw) {
            require(canVote, "vote");
        } else {
            require(block.number > lastVoteBlock[voter], "wait 1 block");
            require(!isTerminated || _proposal[proposalId].terminationBlock < block.number, "early");
        }
    }

    function _mustStopAtFirst(bool value, address[] memory checkers, bytes32 proposalId, address from, address voter) private view returns(bool) {
        if(checkers.length == 0 || (checkers.length == 1 && checkers[0] == address(0))) {
            return value;
        }
        Proposal memory proposal = _proposal[proposalId];
        bytes memory inputData = abi.encodeWithSelector(IProposalChecker(address(0)).check.selector, address(this), proposalId, abi.encode(proposal), from, voter);
        for(uint256 i = 0; i < checkers.length; i++) {
            (bool result, bytes memory response) = checkers[i].staticcall(inputData);
            if((!result || abi.decode(response, (bool))) == value) {
                return true;
            }
        }
        return false;
    }

    function _validateRules(address rulesToValidate, bytes32 key, bytes memory payload, address sender) private returns(bool result, bytes memory response) {
        if(rulesToValidate == address(0)) {
            return (true, "");
        }
        (result, response) = rulesToValidate.call(abi.encodeWithSelector(IProposalChecker(address(0)).check.selector, address(this), key, payload, sender, sender));
        if(result) {
            result = abi.decode(response, (bool));
            response = "";
        }
    }

    function _finalizeTermination(bytes32 proposalId, Proposal storage proposal, bool validationPassed, bool result) internal virtual {
        proposal.validationPassed = validationPassed;
        if(_hostIsProposalCommand) {
            proposal.terminationBlock = IExternalProposalsManagerCommands(host).proposalCanBeFinalized(proposalId, proposal, validationPassed, result) ? block.number : proposal.terminationBlock;
            return;
        }
        proposal.terminationBlock = !validationPassed || result ? block.number : proposal.terminationBlock;
    }

    function _safeTransferFrom(address erc20TokenAddress, uint256 value) private returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return value;
        }
        uint256 previousBalance = IERC20(erc20TokenAddress).balanceOf(address(this));
        ProposalsManagerLibrary.safeTransferOrTransferFrom(erc20TokenAddress, msg.sender, address(this), value);
        uint256 actualBalance = IERC20(erc20TokenAddress).balanceOf(address(this));
        require(actualBalance > previousBalance);
        require(actualBalance - previousBalance == value, "unsupported");
        return actualBalance - previousBalance;
    }

    function _randomKey() private returns (bytes32) {
        return keccak256(abi.encode(_keyIndex++, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function _withdrawAll(bytes32 proposalId, address sender, address voter) private returns(bool canVote, address[] memory collections, uint256[] memory objectIds, uint256[] memory accepts, uint256[] memory refuses) {
        canVote = _ensure(proposalId, sender, voter, false);
        Proposal storage proposal = _proposal[proposalId];
        require(!canVote || block.number > proposal.creationBlock, "Cannot withdraw during creation");
        (collections, objectIds,) = abi.decode(proposal.votingTokens, (address[], uint256[], uint256[]));
        accepts = new uint256[](collections.length);
        refuses = new uint256[](collections.length);
        for(uint256 i = 0; i < collections.length; i++) {
            (accepts[i], refuses[i]) = _singleWithdraw(proposal, proposalId, collections[i], objectIds[i], voter, canVote);
        }
    }

    function _singleWithdraw(Proposal storage proposal, bytes32 proposalId, address collection, uint256 objectId, address voter, bool canVote) private returns(uint256 accept, uint256 refuse) {
        bytes32 item = keccak256(abi.encodePacked(proposalId, collection, objectId));
        uint256 proposalWeight = weight[item];
        require(proposalWeight > 0, "item");
        accept = _accept[proposalId][voter][item];
        refuse = _refuse[proposalId][voter][item];
        require(_toWithdraw[proposalId][voter][item] >= (accept + refuse), "amount");
        if(accept > 0) {
            _toWithdraw[proposalId][voter][item] -= accept;
            if(canVote) {
                _accept[proposalId][voter][item] -= accept;
                proposal.accept -= (accept * proposalWeight);
                emit RetireAccept(proposalId, voter, item, accept);
            }
        }
        if(refuse > 0) {
            _toWithdraw[proposalId][voter][item] -= refuse;
            if(canVote) {
                _refuse[proposalId][voter][item] -= refuse;
                proposal.refuse -= (refuse * proposalWeight);
                emit RetireRefuse(proposalId, voter, item, refuse);
            }
        }
    }
}