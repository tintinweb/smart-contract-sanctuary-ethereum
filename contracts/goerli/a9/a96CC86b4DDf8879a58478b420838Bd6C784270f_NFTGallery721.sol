// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./commons/EIP712MetaTransaction.sol";
import "./interfaces/INFTGallery.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/NFTGalleryHelper.sol";
import "./libraries/OrderData.sol";
import "./libraries/OfferData.sol";

contract NFTGallery721 is EIP712MetaTransaction("NFTGallery721", "1"), ReentrancyGuard, Ownable, INFTGallery {
    using EnumerableSet for EnumerableSet.AddressSet;
    using OrderData for OrderData.OrderDataMap;
    using OfferData for OfferData.OfferDataMap;

    OrderData.OrderDataMap private ordersMap;
    mapping(bytes32 => OfferData.OfferDataMap) private _offersMap;

    uint256 private _feePercentage; // 100% = 10000;
    address private _feeTo;

    /**
     * address(0) means native token such as QTUM/ETH ...
     */
    EnumerableSet.AddressSet private _allowedQuoteTokens;
    EnumerableSet.AddressSet private _allowedCollections;

    bytes4 public constant ERC721InterfaceID = bytes4(0x80ac58cd);

    constructor(address multiSigWallet) {
        require(multiSigWallet != address(0), "ZERO Address value");
        _allowedQuoteTokens.add(address(0));
        transferOwnership(multiSigWallet);
    }

    function getOrder(address _nftAddress, uint256 _nftId)
        external
        view
        returns (
            address seller,
            address quoteToken,
            uint128 price,
            uint64 expirationTime
        )
    {
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        (seller, quoteToken, price, , expirationTime) = ordersMap.get(orderHash);
    }

    function allowedQuoteTokens() external view returns (address[] memory) {
        return _allowedQuoteTokens.values();
    }

    function isAllowedQuoteToken(address _token) external view returns (bool) {
        return _allowedQuoteTokens.contains(_token);
    }

    function feeTo() external view returns (address) {
        return _feeTo;
    }

    /**
     * @dev This value should be devided by 10000. It meeans 100% = 10000
     */
    function feePercentage() external view returns (uint256) {
        return _feePercentage;
    }

    struct OfferDataMemory {
        address _user;
        address _quoteToken;
        uint128 _price;
        uint128 _expirationTime;
    }

    struct OrderDataMemory {
        address seller;
        address quoteToken;
        uint128 price;
        uint64 expirationTime;
    }

    function getOffersByNFT(address _nftAddress, uint256 _nftId) external view returns (OfferDataMemory[] memory) {
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        uint256 len = _offersMap[orderHash].length();
        OfferDataMemory[] memory vars = new OfferDataMemory[](len);

        for (uint256 ii = 0; ii < len; ii++) {
            (address _user, address _quoteToken, uint256 _price, uint256 _expirationTime) = _offersMap[orderHash].at(ii);
            vars[ii] = OfferDataMemory({
                _user: _user,
                _quoteToken: _quoteToken,
                _price: uint128(_price),
                _expirationTime: uint128(_expirationTime)
            });
        }

        return vars;
    }

    function addQuoteToken(address _asset) external onlyOwner {
        require(!_allowedQuoteTokens.contains(_asset), "Asset was already added in white list");
        _allowedQuoteTokens.add(_asset);
        emit AddQuoteToken(_asset, msgSender());
    }

    function removeQuoteToken(address _asset) external onlyOwner {
        require(_allowedQuoteTokens.contains(_asset), "Asset is not in white list");
        _allowedQuoteTokens.remove(_asset);
        emit RemoveQuoteToken(_asset, msgSender());
    }

    function addCollection(address _collection) external onlyOwner {
        _requireERC721(_collection);
        require(!_allowedCollections.contains(_collection), "Collection was already added");
        _allowedCollections.add(_collection);
        emit AddCollection(_collection, msgSender());
    }

    function removeCollection(address _collection) external onlyOwner {
        require(_allowedCollections.contains(_collection), "Collection was already removed");
        _allowedCollections.remove(_collection);
        emit RemoveCollection(_collection, msgSender());
    }

    function updateFeeSettings(address __feeTo, uint256 __feePercentage) external onlyOwner {
        require(_feeTo != __feeTo || _feePercentage != __feePercentage, "Already set values");
        emit UpdateFeeSettings(__feeTo, __feePercentage, _feeTo, _feePercentage);        
    }

    /* ========== MARKET FUNCTIONS ========== */
    function createOrder(
        address _nftAddress,
        address _quoteToken,
        uint256 _nftId,
        uint128 _price,
        uint64 expirationTime
    ) external nonReentrant {
        _requireERC721(_nftAddress);
        require(_allowedQuoteTokens.contains(_quoteToken), "Quote token should be allowed.");
        require(_allowedCollections.contains(_nftAddress), "Collection should be allowed");
        require(expirationTime > block.timestamp, "Invalid expiration time");
        IERC721 nftTokenContract = IERC721(_nftAddress);

        address _sender = msgSender();

        require(nftTokenContract.ownerOf(_nftId) == _sender, "Only the owner of NFT can create orders");
        require(
            nftTokenContract.isApprovedForAll(_sender, address(this)) || nftTokenContract.getApproved(_nftId) == address(this),
            "The contract is not authorized to manage the asset"
        );

        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);

        require(!ordersMap.contains(orderHash), "This item is already in sale.");
        ordersMap.set(orderHash, _sender, _quoteToken, _price, 1, expirationTime);

        emit OrderCreated(_sender, _nftAddress, _quoteToken, _nftId, _price, 1, expirationTime);
    }

    function cancelOrder(address _nftAddress, uint256 _nftId) external nonReentrant {
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        (address seller, , , ,) = ordersMap.get(orderHash);
        // This condition is checking if order exists, too.
        require(seller == msgSender(), "Only seller can cancel order");

        ordersMap.remove(orderHash);

        emit OrderCancelled(_nftAddress, _nftId);
    }

    function updateOrder(
        address _nftAddress,
        uint256 _nftId,
        uint128 _newPrice,
        uint64 _newExpirationTime
    ) external nonReentrant {
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        (address seller, address quoteToken, , ,) = ordersMap.get(orderHash);
        // This condition is checking if order exists, too.
        require(seller == msgSender(), "Only seller can update order");
        require(_newExpirationTime > block.timestamp, "Invalid expiration time");

        ordersMap.set(orderHash, seller, quoteToken, _newPrice, 1, _newExpirationTime);

        emit OrderUpdated(_nftAddress, _nftId, _newPrice, _newExpirationTime, 1);
    }

    function executeOrder(address _nftAddress, uint256 _nftId) external payable nonReentrant {
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        OrderDataMemory memory orderVar;

        (orderVar.seller, orderVar.quoteToken, orderVar.price, ,orderVar.expirationTime) = ordersMap.get(orderHash);
        require(orderVar.seller != address(0), "This sale is no longer active");
        require(orderVar.expirationTime >= block.timestamp, "Expirred order");

        IERC721 nftTokenContract = IERC721(_nftAddress);

        address _sender = msgSender();

        ordersMap.remove(orderHash);

        if (orderVar.quoteToken == address(0)) {
            require(msg.value == orderVar.price, "Insufficient fund");
            transferETH(orderVar.seller, orderVar.price);
        } else {
            require(msg.value == 0, "QRC20 token sale");
            TransferHelper.safeTransferFrom(orderVar.quoteToken, _sender, orderVar.seller, orderVar.price);
            transferToken(orderVar.quoteToken, _sender, orderVar.seller, orderVar.price);
        }

        nftTokenContract.transferFrom(orderVar.seller, _sender, _nftId);

        emit OrderExecuted(_sender, _nftAddress, _nftId, 1);
    }

    /**
     * @param _expirationTime is the expiration time of offer. 0 means it has no expiration time.
     */
    function approveOffer(
        address _nftAddress,
        address _quoteToken,
        uint256 _nftId,
        uint128 _offerPrice,
        uint64 _expirationTime
    ) external nonReentrant {
        require(_allowedCollections.contains(_nftAddress), "Collection is not allowed.");
        require(_expirationTime == 0 || _expirationTime > block.timestamp, "Invalid expiration time");
        require(_quoteToken != address(0), "Only QRC20 tokens are allowed for offer");
        require(_allowedQuoteTokens.contains(_quoteToken), "Quote token is not allowed.");
        require(_offerPrice > 0, "Offer price should be greater than 0.");

        address _sender = msgSender();

        require(
            IERC20(_quoteToken).allowance(_sender, address(this)) >= _offerPrice,
            "The contract is not authorized to manage the asset"
        );

        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        require(ordersMap.contains(orderHash), "This sale is not active");

        (address seller, , , ,) = ordersMap.get(orderHash);
        require(seller != _sender, "Seller can not offer to his item");

        require(!_offersMap[orderHash].contains(_sender), "You have already offer for this item.");

        _offersMap[orderHash].set(_sender, _quoteToken, _offerPrice, 1, _expirationTime);

        emit OfferApproved(_sender, _nftAddress, _quoteToken, _nftId, _offerPrice, _expirationTime, 1);
    }

    function updateOffer(
        address _tokenAddress,
        uint256 _tokenId,
        uint128 _offerPrice,
        uint64 _expirationTime
    ) external nonReentrant {
        require(_allowedCollections.contains(_tokenAddress), "Collection is not allowed.");
        require(_expirationTime == 0 || _expirationTime > block.timestamp, "Invalid expiration time");
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_tokenAddress, _tokenId);

        address _sender = msgSender();
        (address quoteToken, , , ) = _offersMap[orderHash].get(_sender);
        require(quoteToken != address(0), "Offer was not created yet");

        require(
            _offerPrice != 0 && IERC20(quoteToken).balanceOf(_sender) >= _offerPrice,
            "ZERO price or you have no sufficient balance"
        );

        _offersMap[orderHash].set(_sender, quoteToken, _offerPrice, 1, _expirationTime);

        emit OfferApproved(_sender, _tokenAddress, quoteToken, _tokenId, _offerPrice, _expirationTime, 1);
    }

    function cancelOffer(address _nftAddress, uint256 _nftId) external {
        require(_allowedCollections.contains(_nftAddress), "Collection is not allowed.");
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);

        address _sender = msgSender();
        require(_offersMap[orderHash].contains(_sender), "Offer was not created or removed yet");

        _offersMap[orderHash].remove(_sender);

        emit OfferCanceled(_sender, _nftAddress, _nftId);
    }

    function executeOffer(
        address _nftAddress,
        uint256 _nftId,
        address _offerer
    ) external nonReentrant {
        require(_allowedCollections.contains(_nftAddress), "Collection is not allowed.");
        bytes32 orderHash = NFTGalleryHelper.hashOrder(_nftAddress, _nftId);
        (address seller, , , ,) = ordersMap.get(orderHash);
        require(msgSender() == seller, "Only seller can execute offer");

        (address quoteToken, uint256 price, , uint256 expirationTime) = _offersMap[orderHash].get(_offerer);

        require(expirationTime == 0 || expirationTime > block.timestamp, "Offer was expired");
        require(quoteToken != address(0) && price != 0, "Offer was not approved from that user");

        ordersMap.remove(orderHash);
        _offersMap[orderHash].remove(_offerer);

        transferToken(quoteToken, _offerer, seller, price);

        IERC721(_nftAddress).transferFrom(seller, _offerer, _nftId);

        emit OfferExecuted(_offerer, _nftAddress, quoteToken, _nftId, price, 1);
    }

    function transferETH(address seller, uint256 price) private {
        if (_feeTo == address(0) || _feePercentage == 0) {
            TransferHelper.safeTransferETH(seller, price);
        } else {
            uint256 fee = price * _feePercentage / 10000;
            if (fee > 0) {
                TransferHelper.safeTransferETH(_feeTo, fee);
                price -= fee;
            }

            TransferHelper.safeTransferETH(seller, price);    
        }
    }

    function transferToken(address token, address sender, address seller, uint256 price) private {
        if (_feeTo == address(0) || _feePercentage == 0) {
            TransferHelper.safeTransferFrom(token, sender, seller, price);
        }

        uint256 fee = price * _feePercentage / 10000;
        if (fee > 0) {
            TransferHelper.safeTransferFrom(token, sender, _feeTo, fee);
            price -= fee;
        }
        TransferHelper.safeTransferFrom(token, sender, seller, price);
    }

    function _requireERC721(address nftAddress) private view {
        require(
            IERC721(nftAddress).supportsInterface(ERC721InterfaceID),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns (bytes32) {
        return domainSeparator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./EIP712Base.sol";

contract EIP712MetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress] + 1;
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature)));
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface INFTGallery {
    event OrderCreated(
        address indexed seller,
        address indexed nftAddress,
        address quoteToken,
        uint256 nftId,
        uint256 price,
        uint256 quantity,
        uint64 expirationTime
    );
    event OrderCancelled(address indexed nftAddress, uint256 nftId);
    event OrderUpdated(address indexed nftAddress, uint256 nftId, uint256 newPrice, uint256 nexExpirationTime, uint256 newQuantity);
    event OrderExecuted(address indexed buyer, address indexed nftAddress, uint256 nftId, uint256 quantity);
    event OfferApproved(
        address indexed user,
        address indexed nftAddress,
        address quoteToken,
        uint256 nftId,
        uint256 offerPrice,
        uint256 expirationTime,
        uint256 quantity
    );
    event OfferExecuted(
        address indexed to,
        address indexed nftAddress,
        address quoteToken,
        uint256 nftId,
        uint256 offerPrice,
        uint256 quantity
    );
    event OfferCanceled(address indexed user, address indexed nftAddress, uint256 nftId);
    event AddQuoteToken(address indexed asset, address user);
    event RemoveQuoteToken(address indexed asset, address user);
    event AddCollection(address indexed collection, address user);
    event RemoveCollection(address indexed collection, address user);
    event UpdateFeeSettings(address indexed newFeeTo, uint256 newFeePercentage, address oldFeeTo, uint256 oldFeePercentage);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library NFTGalleryHelper {
    function hashOrder(address _tokenAddr, uint256 _tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenAddr, _tokenId));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// user address => offer data
library OfferData {
    struct MapEntry {
        address _key;
        address _quoteToken;
        uint128 _price;
        uint64 _quantity;
        uint64 _expirationTime;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(address => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        address key,
        address _quoteToken,
        uint128 _price,
        uint64 _quantity,
        uint64 _expirationTime
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(
                MapEntry({
                    _key: key,
                    _quoteToken: _quoteToken,
                    _price: _price,
                    _quantity: _quantity,
                    _expirationTime: _expirationTime
                })
            );
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            if (map._entries[keyIndex - 1]._quoteToken != _quoteToken) {
                map._entries[keyIndex - 1]._quoteToken = _quoteToken;
            }
            if (map._entries[keyIndex - 1]._price != _price) {
                map._entries[keyIndex - 1]._price = _price;
            }
            if (map._entries[keyIndex - 1]._expirationTime != _expirationTime) {
                map._entries[keyIndex - 1]._expirationTime = _expirationTime;
            }


            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, address key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, address key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index)
        private
        view
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._quoteToken, entry._price, entry._expirationTime);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, address key)
        private
        view
        returns (
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        address key,
        string memory errorMessage
    )
        private
        view
        returns (
            address,
            uint128,
            uint64,
            uint64
        )
    {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return (
            map._entries[keyIndex - 1]._quoteToken,
            map._entries[keyIndex - 1]._price,
            map._entries[keyIndex - 1]._quantity,
            map._entries[keyIndex - 1]._expirationTime
        ); // All indexes are 1-based
    }

    // UintToUintMap

    struct OfferDataMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        OfferDataMap storage map,
        address key,
        address quoteToken,
        uint128 price,
        uint64 qunatity,
        uint64 expirationTime
    ) internal returns (bool) {
        return _set(map._inner, key, quoteToken, price, qunatity, expirationTime);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(OfferDataMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(OfferDataMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(OfferDataMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(OfferDataMap storage map, uint256 index)
        internal
        view
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(OfferDataMap storage map, address key)
        internal
        view
        returns (
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        OfferDataMap storage map,
        address key,
        string memory errorMessage
    )
        internal
        view
        returns (
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _get(map._inner, key, errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library OrderData {
    struct MapEntry {
        bytes32 _key;
        address seller;
        address quoteToken;
        uint128 price;
        uint64 quantity;
        uint64 expirationTime;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        address _seller,
        address _quoteToken,
        uint128 _price,
        uint64 _quantity,
        uint64 _expirationTime
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(
                MapEntry({_key: key, seller: _seller, quoteToken: _quoteToken, price: _price, quantity: _quantity, expirationTime: _expirationTime})
            );
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            if (map._entries[keyIndex - 1].price != _price) {
                map._entries[keyIndex - 1].price = _price;
            }

            if (map._entries[keyIndex - 1].quantity != _quantity) {
                map._entries[keyIndex - 1].quantity = _quantity;
            }

            if (map._entries[keyIndex - 1].expirationTime != _expirationTime) {
                map._entries[keyIndex - 1].expirationTime = _expirationTime;
            }

            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index)
        private
        view
        returns (
            bytes32,
            address,
            address,
            uint128,
            uint64,
            uint64
        )
    {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry.seller, entry.quoteToken, entry.price, entry.quantity, entry.expirationTime);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key)
        private
        view
        returns (
            address,
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    )
        private
        view
        returns (
            address,
            address,
            uint128,
            uint64,
            uint64
        )
    {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        uint256 index = keyIndex - 1;
        return (
            map._entries[index].seller,
            map._entries[index].quoteToken,
            map._entries[index].price,
            map._entries[index].quantity,
            map._entries[index].expirationTime
        ); // All indexes are 1-based
    }

    // UintToUintMap

    struct OrderDataMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        OrderDataMap storage map,
        bytes32 key,
        address seller,
        address quoteToken,
        uint128 price,
        uint64 quantity,
        uint64 expirationTime
    ) internal returns (bool) {
        return _set(map._inner, key, seller, quoteToken, price, quantity, expirationTime);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(OrderDataMap storage map, bytes32 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(OrderDataMap storage map, bytes32 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(OrderDataMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(OrderDataMap storage map, uint256 index)
        internal
        view
        returns (
            bytes32,
            address,
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(OrderDataMap storage map, bytes32 key)
        internal
        view
        returns (
            address,
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        OrderDataMap storage map,
        bytes32 key,
        string memory errorMessage
    )
        internal
        view
        returns (
            address,
            address,
            uint128,
            uint64,
            uint64
        )
    {
        return _get(map._inner, key, errorMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

// from uniswap SDK
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}