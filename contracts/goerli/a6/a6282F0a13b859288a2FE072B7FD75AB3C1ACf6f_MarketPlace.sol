/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// contracts/NFTMarketplace.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
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

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC2981 is IERC721 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

abstract contract BasePlace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Address for address payable;
    using ECDSA for bytes32;
    
    Counters.Counter private itemCounter; //start from 1
    Counters.Counter private itemSoldCounter;
    Counters.Counter private swapCounter;

    mapping(address => uint256) private collectedFees;

    address private marketOperator;

    uint256 public marketplaceFee = 150;
    uint256 public immutable denominator = 1000;

    enum State {
        Created,
        Release,
        Inactive
    }

    struct MarketItem {
        uint256 id;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 expiry;
        address creatorAddress;
        uint256 creatorRoyalty;
        State state;
    }

    struct SwapItem {
        uint256 id;
        address[] sellerNFTContracts;
        uint256[] sellerTokenIds;
        address[] buyerNFTContracts;
        uint256[] buyerTokenIds;
        uint256 expiry;
        address seller;
        address buyer;
        State state;
    }

    mapping(uint256 => MarketItem) public marketItems;
    mapping(uint256 => SwapItem) public swapItems;

    event MarketItemCreated(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        uint256 expiry,
        State state
    );

    event MarketItemSold(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        address token,
        uint256 price,
        State state
    );

    event SwapItemCreated(
        uint256 indexed id,
        address[] sellerNFTContracts,
        uint256[] sellerTokenIds,
        address[] buyerNFTContracts,
        uint256[] buyerTokenIds,
        address seller,
        address buyer,
        uint256 expiry,
        State state
    );

    event SwapSuccessful(
        uint256 indexed id,
        address[] sellerNFTContracts,
        uint256[] sellerTokenIds,
        address[] buyerNFTContracts,
        uint256[] buyerTokenIds,
        address seller,
        address buyer,
        State state
    );

    constructor(address operator) {
        marketOperator = operator;
    }

    /// @dev View functions

    function fetchAllActiveItems() external view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 total = itemCounter.current();
        for (uint256 i = 1; i <= total; i++) {
            if (marketItems[i].buyer == address(0) &&
                marketItems[i].state == State.Created &&
                marketItems[i].expiry >= block.timestamp &&
                checkAllowance(marketItems[i].seller, marketItems[i].nftContract, marketItems[i].tokenId)) {
                    itemCount ++;
                }
        }

        uint256 index;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= total; i++) {
            if (marketItems[i].buyer == address(0) &&
                marketItems[i].state == State.Created &&
                marketItems[i].expiry >= block.timestamp &&
                checkAllowance(marketItems[i].seller, marketItems[i].nftContract, marketItems[i].tokenId)) {
                    items[index] = marketItems[i];
                    index ++;
                }
        }
        return items;
    }

    function fetchAllNFTItems(address _nftContract) external view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 total = itemCounter.current();
        for (uint256 i = 1; i <= total; i++) {
            if (marketItems[i].nftContract == _nftContract) {
                itemCount ++;
            }
        }
        uint256 index;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= total; i++) {
            if (marketItems[i].nftContract == _nftContract) {
                items[index] = marketItems[i];
                index ++;
            }
        }
        return items;
    }

    function fetchAllUserSwaps(address user) external view returns (SwapItem[] memory) {
        uint256 itemCount;
        uint256 total = swapCounter.current();
        for (uint256 i = 1; i <= total; i++) {
            if (swapItems[i].state == State.Created &&
                swapItems[i].expiry >= block.timestamp &&
                (swapItems[i].buyer == user || swapItems[i].seller == user)) {
                    itemCount ++;
                }
        }
        uint256 index;
        SwapItem[] memory items = new SwapItem[](itemCount);
        for (uint256 i = 1; i <= total; i++) {
            if (swapItems[i].state == State.Created &&
                swapItems[i].expiry >= block.timestamp &&
                (swapItems[i].buyer == user || swapItems[i].seller == user)) {
                    items[index] = swapItems[i];
                    index ++;
            }
        }
        return items;
    }

    function fetchUserActiveItems(address user)
        external
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.ActiveItems, user);
    }

    function fetchMyPurchasedItems(address user)
        external
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.MyPurchasedItems, user);
    }

    function fetchMyCreatedItems(address user)
        external
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.MyCreatedItems, user);
    }

    /// @dev Public write functions

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 expiry,
        address creatorAddress,
        uint256 creatorRoyalty,
        bytes memory data
    ) external {
        require(verifyPost(nftContract, tokenId, _msgSender(), price, expiry, creatorAddress, creatorRoyalty, data), "Not authorised");
        require(expiry <= (block.timestamp + 30*24*60*60), "Invalid Expiry");
        require(price > 0, "Price must be at least 1 wei");
        require(checkAllowance(_msgSender(), nftContract, tokenId), "NFT must be approved to market");

        itemCounter.increment();
        uint256 id = itemCounter.current();

        marketItems[id] = MarketItem(
            id,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            expiry,
            creatorAddress,
            creatorRoyalty,
            State.Created
        );

        emit MarketItemCreated(
            id,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            expiry,
            State.Created
        );
    }

    function createMarketSale(uint256 id) external payable nonReentrant {
        MarketItem storage item = marketItems[id];
        uint256 price = item.price;
        uint256 tokenId = item.tokenId;

        require(msg.value == price, "Please submit the asking price");
        require(checkAllowance(item.seller, item.nftContract, tokenId), "NFT must be approved to market");
        require(IERC721(item.nftContract).ownerOf(tokenId) == item.seller, "Seller is not the owner");
        require(item.expiry > block.timestamp, "Item has expired");
        require(item.state == State.Created, "Invalid State");

        item.buyer = payable(_msgSender());
        item.state = State.Release;
        itemSoldCounter.increment();

        uint256 toSeller = msg.value;

        if (marketplaceFee > 0) {
            uint256 platformFee = (msg.value * marketplaceFee) / denominator;
            collectedFees[address(0)] += platformFee;
            toSeller -= platformFee;
        }

        if (item.creatorRoyalty > 0) {
            uint256 creatorRoyalty = (msg.value * item.creatorRoyalty) / denominator;
            toSeller -= creatorRoyalty;
            payable(item.creatorAddress).sendValue(creatorRoyalty);
        }

        item.seller.sendValue(toSeller);

        IERC721(item.nftContract).transferFrom(item.seller, _msgSender(), tokenId);

        emit MarketItemSold(
            id,
            item.nftContract,
            tokenId,
            item.seller,
            _msgSender(),
            address(0),
            price,
            State.Release
        );
    }

    function deleteMarketItem(uint256 itemId) external {
        require(itemId <= itemCounter.current(), "id must be less than item count");
        MarketItem storage item = marketItems[itemId];
        require(item.state == State.Created, "item must be on market");
        require(item.expiry >= block.timestamp, "Item has expired");
        require(IERC721(item.nftContract).ownerOf(item.tokenId) == _msgSender(), "Caller is not the owner of NFT");
        require(item.seller == _msgSender(), "Caller is not the owner");
        require(checkAllowance(_msgSender(), item.nftContract, item.tokenId), "NFT must be approved to market");

        item.state = State.Inactive;

        emit MarketItemSold(
            itemId,
            item.nftContract,
            item.tokenId,
            item.seller,
            address(0),
            address(0),
            0,
            State.Inactive
        );
    }

    function completeMarketSaleBid(uint256 id, address nftContract, uint256 tokenId,  address buyer, address token, uint256 price, address creatorAddress, uint256 creatorRoyalty, bytes memory data) external nonReentrant {
        require(verifyBid(id, nftContract, tokenId, _msgSender(), buyer, token, price, creatorAddress, creatorRoyalty, data), "Invalid signature");
        require(IERC20(token).allowance(buyer, address(this)) >= price, "Not enough approved");

        IERC20(token).transferFrom(buyer, address(this), price);
        uint256 toSeller = price;

        if (marketplaceFee > 0) {
            uint256 platformFee = (price * marketplaceFee) / denominator;
            collectedFees[token] += platformFee;
            toSeller -= platformFee;
        }

        if (creatorRoyalty > 0) {
            uint256 creatorFee = (price * creatorRoyalty) / denominator;
            toSeller -= creatorFee;
            IERC20(token).transfer(creatorAddress, creatorFee);
        }

        IERC721(nftContract).safeTransferFrom(_msgSender(), buyer, tokenId);
        IERC20(token).transfer(_msgSender(), toSeller);

        emit MarketItemSold(
            id, 
            nftContract, 
            tokenId, 
            _msgSender(), 
            buyer, 
            token,
            price, 
            State.Release);
        
    }

    function createSwapItem(
        address seller,
        address[] calldata _sellerNFTContracts,
        uint256[] calldata _sellerTokenIds,
        address[] calldata _buyerNFTContracts,
        uint256[] calldata _buyerTokenIds,
        uint256 _expiry
    ) external {
        require(_expiry > block.timestamp, "Invalid expiry");
        require(_sellerNFTContracts.length == _sellerTokenIds.length, "Seller lengths mismatch");
        require(_buyerNFTContracts.length == _buyerTokenIds.length, "Buyer lengths mismatch");

        for (uint256 i; i < _sellerNFTContracts.length; i++) {
            require(IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) == seller, "Token not owned by seller");
        }

        for (uint256 i; i < _buyerNFTContracts.length; i++) {
            require(IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) == _msgSender(), "Token not owned by seller");
            require(checkAllowance(_msgSender(), _buyerNFTContracts[i], _buyerTokenIds[i]), "Buyer NFT is not approved to the market");
        }

        swapCounter.increment();
        uint256 id = swapCounter.current();

        swapItems[id] = SwapItem(
            id,
            _sellerNFTContracts,
            _sellerTokenIds,
            _buyerNFTContracts,
            _buyerTokenIds,
            _expiry,
            seller,
            _msgSender(),
            State.Created
        );
    }

    function completeSwap(uint256 itemId) external {
        SwapItem storage item = swapItems[itemId];
        require(item.expiry >= block.timestamp, "Item has expired");
        require(_msgSender() == item.seller, "Not authorised");
        require(item.state == State.Created, "Invalid State");

        for (uint256 i; i < item.sellerNFTContracts.length; i++) {
            require(IERC721(item.sellerNFTContracts[i]).ownerOf(item.sellerTokenIds[i]) == item.seller, "Token not owned by seller");
            require(checkAllowance(item.seller, item.sellerNFTContracts[i], item.sellerTokenIds[i]), "Seller NFT must be approved to market");
        }

        for (uint256 i; i < item.buyerNFTContracts.length; i++) {
            require(IERC721(item.buyerNFTContracts[i]).ownerOf(item.buyerTokenIds[i]) == item.buyer, "Token not owned by seller");
            require(checkAllowance(item.buyer, item.buyerNFTContracts[i], item.buyerTokenIds[i]), "Buyer NFT must be approved to market");
        }

        item.state = State.Release;

        for (uint256 i; i < item.sellerNFTContracts.length; i++) {
            IERC721(item.sellerNFTContracts[i]).safeTransferFrom(item.seller, item.buyer, item.sellerTokenIds[i]);
        }

        for (uint256 i; i < item.buyerNFTContracts.length; i++) {
            IERC721(item.buyerNFTContracts[i]).safeTransferFrom(item.buyer, item.seller, item.buyerTokenIds[i]);
        }

        itemSoldCounter.increment();

        emit SwapSuccessful(
            itemId, 
            item.sellerNFTContracts, 
            item.sellerTokenIds, 
            item.buyerNFTContracts, 
            item.buyerTokenIds, 
            item.seller, 
            item.buyer, 
            item.state
        );

    }

    function deleteSwapItem(uint256 itemId) external {
        require(itemId <= swapCounter.current(), "id must be less than item count");
        SwapItem storage item = swapItems[itemId];
        require(item.state == State.Created, "Item must be on market");
        require(item.expiry >= block.timestamp, "Item has expired");
        require(item.buyer == _msgSender(), "Caller is not authorised");
        item.state = State.Inactive;
        emit SwapSuccessful(
            itemId, 
            item.sellerNFTContracts, 
            item.sellerTokenIds, 
            item.buyerNFTContracts, 
            item.buyerTokenIds, 
            item.seller, 
            item.buyer, 
            item.state
            );
    }

    /// @dev Internal Functions

    enum FetchOperator {
        ActiveItems,
        MyPurchasedItems,
        MyCreatedItems
    }

    function fetchHepler(FetchOperator _op, address user)
        internal
        view
        returns (MarketItem[] memory)
    {
        uint256 total = itemCounter.current();

        uint256 itemCount = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op, user)) {
                itemCount++;
            }
        }

        uint256 index = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op, user)) {
                items[index] = marketItems[i];
                index++;
            }
        }
        return items;
    }

    function isCondition(
        MarketItem memory item,
        FetchOperator _op,
        address user
    ) internal view returns (bool) {
        if (_op == FetchOperator.MyCreatedItems) {
            return
                (item.seller == user && item.state != State.Inactive && item.expiry >= block.timestamp)
                    ? true
                    : false;
        } else if (_op == FetchOperator.MyPurchasedItems) {
            return (item.buyer == user) ? true : false;
        } else if (_op == FetchOperator.ActiveItems) {
            return
                (item.buyer == address(0) &&
                item.state == State.Created &&
                item.seller == user &&
                checkAllowance(_msgSender(), item.nftContract, item.tokenId) &&
                item.expiry >= block.timestamp
                )
                    ? true
                    : false;
        } else {
            return false;
        }
    }

    function checkAllowance(address user, address nftContract, uint256 tokenId) internal view returns (bool) {
        return (IERC721(nftContract).getApproved(tokenId) == address(this) || 
                IERC721(nftContract).isApprovedForAll(user, address(this))) ? true : false;
    }

    /// @dev onlyOwner

    function getCollectedFees(address token) external view returns (uint256) {
        return collectedFees[token];
    }

    function withdrawFees(address token) external onlyOwner {
        uint256 toSend = collectedFees[token];
        collectedFees[token] = 0;
        if (token == address(0)) {
            payable(owner()).sendValue(toSend);
        } else {
            IERC20(token).transfer(owner(), toSend);
        }
    }

    function changeMarketOperator(address _nmo) external onlyOwner {
        marketOperator = _nmo;
    }

    function changeMarketplaceFee(uint256 newFee) external onlyOwner {
        marketplaceFee = newFee;
    }

    /// @dev Bytes verification

    function verifyPost(address nftContract, uint256 tokenId, address seller, uint256 price, uint256 expiry, address creatorAddress, uint256 creatorRoyalty, bytes memory data) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(nftContract, tokenId, seller, price, expiry, creatorAddress, creatorRoyalty));
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(messageHash);
        (address rec, ) = ECDSA.tryRecover(ethHash, data);
        return rec == marketOperator;
    }

    function verifyBid(uint256 id, address nftContract, uint256 tokenId, address seller, address buyer, address token, uint256 price, address creatorAddress, uint256 creatorRoyalty, bytes memory data) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(id, nftContract, tokenId, seller, buyer, token, price, creatorAddress, creatorRoyalty));
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(messageHash);
        (address rec, ) = ECDSA.tryRecover(ethHash, data);
        return rec == marketOperator;
    }



}

// abstract contract CrossChain is ReentrancyGuard, Ownable {

// }

contract MarketPlace is BasePlace {

    constructor(address sys) BasePlace(sys) {}

    /// @dev For testing purposes only 

    function getMessageHashPost(address nftContract, uint256 tokenId, address seller, uint256 price, uint256 expiry, address creatorAddress, uint256 creatorRoyalty) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId, seller, price, expiry, creatorAddress, creatorRoyalty));
    }

    function getMessageHashBid(uint256 id, address nftContract, uint256 tokenId, address seller, address buyer, address token, uint256 price, address creatorAddress, uint256 creatorRoyalty) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, nftContract, tokenId, seller, buyer, token, price, creatorAddress, creatorRoyalty));
    }


}