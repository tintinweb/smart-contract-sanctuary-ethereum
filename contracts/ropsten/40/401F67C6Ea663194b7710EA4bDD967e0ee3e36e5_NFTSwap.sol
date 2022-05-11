/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// File: contracts/lib/PaymentLib.sol


pragma solidity >=0.8.0;

library PaymentLib {
    event CreatePayment(uint256 indexed paymentId);

    struct Payment {
        address Payor;
        address Token;
        uint256 Amount;
    }

    function addItem(
        mapping(uint256 => Payment) storage map,
        uint256 key,
        Payment memory value
    ) internal {
        map[key] = value;

        emit CreatePayment(key);
    }


}

// File: contracts/component/PaymentComp.sol


pragma solidity >=0.8.0;


contract PaymentComp {

    using PaymentLib for mapping(uint256 => PaymentLib.Payment);

    mapping(uint256 => PaymentLib.Payment) internal _PaymentInfo;

    uint256 private _currentId;

    function _addPaymentInfo(
        address _Payor,
        address _token,
        uint256 _amount
    ) internal virtual returns (uint256 id_) {
        _PaymentInfo.addItem(
            _currentId,
            PaymentLib.Payment(
                _Payor,
                _token,
                _amount
            )
        );

        id_ = _currentId;
        _currentId ++;
    }

}
// File: contracts/lib/OrderLib.sol


pragma solidity >=0.8.0;

library OrderLib {
    event CreateOrder(uint256 indexed orderId);

    struct Order {
        uint256[] GoodsId;
        address Seller;
        uint256 PaymentId;
    }

    function addItem(
        mapping(uint256 => Order) storage map,
        uint256 key,
        Order memory value
    ) internal {
        map[key] = value;

        emit CreateOrder(key);
    }

    function getItem(
        mapping(uint256 => Order) storage map,
        uint256 key
    ) internal view returns (Order storage value) {
        value = map[key];
    }
}

// File: contracts/component/OrderComp.sol


pragma solidity >=0.8.0;


contract OrderComp {

    using OrderLib for mapping(uint256 => OrderLib.Order);

    mapping(uint256 => OrderLib.Order) internal _orders;

    function _addOrder(
        uint256[] memory goods,
        uint256 _orderId,
        address _seller,
        uint256 _paymentId
    ) internal virtual {
        require(getOrder(_orderId).Seller == address(0), "orderId: existed");

        _orders.addItem(
            _orderId,
            OrderLib.Order(
                goods,
                _seller,
                _paymentId
            )
        );
    }


    function getOrder(
        uint256 _orderId
    ) public virtual returns (OrderLib.Order memory order_) {
        order_ = _orders.getItem(_orderId);
    }

}
// File: contracts/lib/GoodsLib.sol


pragma solidity >=0.8;

library GoodsLib {
    event CreateGoods(uint256 indexed goodsId);

    enum GoodsStatus {
        Non,
        OnMarket,
        OffMarket,
        Sold
    }

    struct Goods {
        address Seller;
        address DesignatedBuyer;
        uint256 Price;
        uint256[] AssetIds;
        GoodsStatus Status;
    }

    function addItem(
        mapping(uint256 => Goods) storage map,
        uint256 key,
        Goods memory value
    ) internal {
        map[key] = value;
        emit CreateGoods(key);
    }

    function getItem(
        mapping(uint256 => Goods) storage map,
        uint256 key
    ) internal view returns (Goods storage value) {
        value = map[key];
    }
}
// File: contracts/component/GoodsComp.sol


pragma solidity >=0.8.0;


contract GoodsComp {

    using GoodsLib for mapping(uint256 => GoodsLib.Goods);

    mapping(uint256 => GoodsLib.Goods) internal goodsDict;

    function addGoods(
        uint256[] memory assets,
        uint256 goodsId,
        address seller,
        address designatedBuyer,
        uint256 price
    ) internal virtual{

        require(_getGoods(goodsId).Seller == address(0), "goodsId: existed");

        goodsDict.addItem(
            goodsId,
            GoodsLib.Goods(
                seller,
                designatedBuyer,
                price,
                assets,
                GoodsLib.GoodsStatus.OnMarket
            )
        );
    }

    function _offMarket(uint256 _goodsId, address _operator) internal returns (bool) {
        GoodsLib.Goods storage goods = goodsDict.getItem(_goodsId);
        if (goods.Seller != _operator) {
            return false;
        }
        goods.Status = GoodsLib.GoodsStatus.OffMarket;
        return true;
    }

    function _canSwap(uint256 goodsId, address buyer)
        internal
        view
        returns (bool)
    {
        GoodsLib.Goods storage goods = goodsDict.getItem(goodsId);

        if (goods.Status != GoodsLib.GoodsStatus.OnMarket) {
            return false;
        }


        if (goods.DesignatedBuyer != address(0)) {
            return goods.DesignatedBuyer == buyer;
        }

        return true;
    }

      function _getGoods(uint256 goodsId)
        internal
        view
        returns (GoodsLib.Goods storage goods)
    {
        goods = goodsDict.getItem(goodsId);
    }


}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/lib/AssetLib.sol


pragma solidity >=0.8.0;



library AssetLib {
    enum AssetType {
        Non,
        ERC721,
        ERC1155
    }

    struct Asset {
        address Contract;
        uint256 TokenId;
        uint256 TokenValue;
        AssetType Type;
    }

    function canSell(Asset memory _asset, address _seller) internal view returns (bool) {
        if (_asset.Type == AssetType.ERC721) {
            return canSellERC721(_asset.Contract, _asset.TokenId, _seller);
        } else if (_asset.Type == AssetType.ERC1155) {
            return canSellERC1155(_asset.Contract, _seller, _asset.TokenId, _asset.TokenValue);
        }
        return false;
    }

    function swapNFT(Asset memory _asset, address user, address seller) internal returns (bool) {
        if (_asset.Type == AssetType.ERC721) {
            return swapERC721(_asset.Contract, user, seller, _asset.TokenId);
        } else if (_asset.Type == AssetType.ERC1155) {
            return swapERC1155(_asset.Contract, user, seller, _asset.TokenId, _asset.TokenValue);
        }
        return false;
    }

    function canSellERC721(address _token, uint256 _tokenId, address _seller) internal view returns (bool) {
        IERC721 nft = IERC721(_token);
        return nft.ownerOf(_tokenId) == _seller && nft.isApprovedForAll(_seller, address(this));
    }

    function canSellERC1155(address _token, address _seller, uint256 _tokenId, uint256 _tokenValue) internal view returns (bool) {
        IERC1155 nft = IERC1155(_token);
        return nft.balanceOf(_seller, _tokenId) >= _tokenValue && nft.isApprovedForAll(_seller, address(this));
    }

    function swapERC721(address _token, address _buyer, address _seller, uint256 _tokenId) internal returns (bool) {
        IERC721 nft = IERC721(_token);

        nft.transferFrom(_seller, _buyer, _tokenId);
        return true;
    }

    function swapERC1155(address _token, address _buyer, address _seller, uint256 _tokenId, uint256 _tokenValue) internal returns (bool) {
        IERC1155 nft = IERC1155(_token);
        nft.safeTransferFrom(_seller, _buyer, _tokenId, _tokenValue, "0x");
        return true;
    }

    function addItem(
        mapping(uint256 => Asset) storage map,
        uint256 key,
        Asset calldata value
    ) internal {
        map[key] = value;
    }

    function getItem(
        mapping(uint256 => Asset) storage map,
        uint256 key
    ) internal view returns (Asset storage value) {
        value = map[key];
    }
}
// File: contracts/component/AssetComp.sol


pragma solidity >=0.8.0;


contract AssetComp {
    using AssetLib for mapping(uint256 => AssetLib.Asset);

    mapping(uint256 => AssetLib.Asset) internal assets;

    uint256 private currentId;

    function addAssets(AssetLib.Asset[] calldata _assets) internal virtual returns (uint256[] memory ids_) {
        ids_ = new uint256[](_assets.length);
        for (uint8 i = 0; i < _assets.length; i++) {
            assets.addItem(currentId, _assets[i]);
            ids_[i] = currentId;
            currentId++;
        }
    }

    function getAsset(uint256 assetId)
    internal
    view
    returns (AssetLib.Asset storage asset)
    {
        asset = assets.getItem(assetId);
    }

}
// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: contracts/component/FeeComp.sol


pragma solidity >=0.8.0;




contract FeeComp is Initializable, OwnableUpgradeable {
    address public FEERECEIVER;
    uint256 public SELLERFEEAMOUNT;
    uint256 public BUYERFEEAMOUNT;
    address public FEETOKEN;

    function __FeeComp_init(
        address _feeReceiver,
        uint256 _sellerFeeAmount,
        uint256 _buyerFeeAmount,
        address _feeToken

    ) public initializer {
        _setFee(_feeReceiver, _sellerFeeAmount, _buyerFeeAmount);
        FEETOKEN = _feeToken;
    }

    function setFee(address _feeReceiver, uint256 _sellerFeeAmount, uint256 _buyerFeeAmount) public onlyOwner {
        _setFee(_feeReceiver, _sellerFeeAmount, _buyerFeeAmount);
    }

    function _setFee(address _feeReceiver, uint256 _sellerFeeAmount, uint256 _buyerFeeAmount) internal {
        FEERECEIVER = _feeReceiver;
        SELLERFEEAMOUNT = _sellerFeeAmount;
        BUYERFEEAMOUNT = _buyerFeeAmount;
    }

    function _paySellerFee(address user) internal returns (bool) {
        IERC20 token = IERC20(FEETOKEN);
        return token.transferFrom(user, FEERECEIVER, SELLERFEEAMOUNT);
    }

    function _payBuyerFee(address user) internal returns (bool) {
        if (BUYERFEEAMOUNT == 0) {
            return true;
        }
        IERC20 token = IERC20(FEETOKEN);
        return token.transferFrom(user, FEERECEIVER, BUYERFEEAMOUNT);
    }

    function _payGoodsFee(address user, address to, uint256 amount) internal returns (bool) {
        _paySellerFee(user);
        IERC20 token = IERC20(FEETOKEN);
        return token.transferFrom(user, to, amount - SELLERFEEAMOUNT);
    }
}
// File: contracts/NFTSwap.sol


pragma solidity >=0.8.0;









/// @title NFTSwap Contract
/// @notice NFT peer-to-peer trading
/// @dev Commodities contain multiple assets, and assets contain multiple NFTs
contract NFTSwap is Initializable, ContextUpgradeable, FeeComp, AssetComp, GoodsComp, OrderComp, PaymentComp {
    using AssetLib for AssetLib.Asset;
    function __NFTSwap_init(
        address _feeReceiver,
        uint256 _feeSellerAmount,
        uint256 _feeBuyerAmount,
        address _feeToken
    ) public initializer {
        __FeeComp_init(_feeReceiver, _feeSellerAmount, _feeBuyerAmount, _feeToken);
        __Ownable_init();
    }

    /// @notice Goods listing logic
    /// @param _assets Array of assets containing multiple NFTs
    /// @param _goodsId product id not repeatable
    /// @param _designatedBuyer Used to specify the buyer of the commodity asset
    /// @param _price Used to specify the price of the item
    /// @dev The handling fee is paid at the time of closing
    function sell(
        AssetLib.Asset[] calldata _assets,
        uint256 _goodsId,
        address _designatedBuyer,
        uint256 _price
    ) public virtual returns (bool) {
        for (uint8 i = 0; i < _assets.length; i++) {
            require(_assets[i].canSell(_msgSender()), "sell: can not sell");
        }

        uint256[] memory ids = addAssets(_assets);

        addGoods(
            ids,
            _goodsId,
            _msgSender(),
            _designatedBuyer,
            _price
        );
        return true;
    }

    /// @notice Goods delisting
    /// @param _goodsId Items to be designated for delisting goods id
    /// @dev Only the seller has the authority
    function offMarket(uint256 _goodsId) public virtual {
        require(_offMarket(_goodsId, _msgSender()), "offMarket: you are not seller");
    }

    // 单独购买 可以跟打包购买合为一个
    function swap(uint256[] memory _goodsIds, uint256 _orderId) public virtual returns (bool) {
        uint256 goodsId = _goodsIds[0];
        require(_canSwap(goodsId, _msgSender()), "swap: The item is not on the market or you cannot buy it");
        GoodsLib.Goods storage goods = _getGoods(goodsId);
        for (uint8 j = 0; j < goods.AssetIds.length; j++) {
            AssetLib.Asset storage asset = getAsset(goods.AssetIds[j]);
            require(asset.swapNFT(_msgSender(), goods.Seller), "swapNFT: swapNFT Fail");
        }
        goods.Status = GoodsLib.GoodsStatus.Sold;
        require(_payGoodsFee(_msgSender(), goods.Seller, goods.Price), "paySwapFee: paySwapFee Fail");
        uint256 payId = _addPaymentInfo(_msgSender(), FEETOKEN, goods.Price);
        _addOrder(_goodsIds, _orderId, goods.Seller, payId);
        return true;
    }

    /// @notice One commodity can be traded, multiple commodities can be traded in packages, and only one fee is required
    /// @param _goodsIds An array of item ids used to specify the purchase
    /// @param _orderId Define an order id, not repeatable
    function packSwap(uint256[] memory _goodsIds, uint256 _orderId) public virtual returns (bool) {

        require(_payBuyerFee(_msgSender()), "offMarket: Fee deduction failed");

        uint256 totalPrice;
        address firstSeller;

        for (uint8 i = 0; i < _goodsIds.length; i++) {
            uint256 goodsId = _goodsIds[i];
            require(_canSwap(goodsId, _msgSender()), "swap: The item is not on the market or you cannot buy it");
            GoodsLib.Goods storage goods = _getGoods(goodsId);

            if (i == 0) {
                firstSeller = goods.Seller;
            } else {
                require(firstSeller == goods.Seller, "swap: Packaged items are not from the same store");
            }

            for (uint8 j = 0; j < goods.AssetIds.length; j++) {
                AssetLib.Asset storage asset = getAsset(goods.AssetIds[j]);
                require(asset.swapNFT(_msgSender(), goods.Seller), "swapNFT: swapNFT Fail");
            }
            totalPrice += goods.Price;
            goods.Status = GoodsLib.GoodsStatus.Sold;
        }
        require(_payGoodsFee(_msgSender(), firstSeller, totalPrice), "paySwapFee: paySwapFee Fail");
        uint256 payId = _addPaymentInfo(_msgSender(), FEETOKEN, totalPrice);
        _addOrder(_goodsIds, _orderId, firstSeller, payId);
        return true;
    }
}