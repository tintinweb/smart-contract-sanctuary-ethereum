/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol


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

// File: sale2.sol



pragma solidity ^0.8.9;







/*
 * @title MarketPlace to sell ERC1155 and ERC721 tokens
 * @author Jay singh dhakd
 * @notice this contract allows user to sell there tokens with ERC20 token of there choice or WETh and ETh
 * @custom:experimental This is an experimental contract.
 */
contract MarketPlace is ReentrancyGuard {
    address ownerMarketPlace;
    address public contractERC1155;
    uint256 public assetIDERC1155;
    uint256 public assetQuantityERC1155;
    uint256 public assetPriceERC1155;
    address public paymentTokenERC1155;
    address ownerERC1155;
    address tokenWETH;
    uint256 public feeRateNumerator;
    uint256 public feeRateDenominator;
    address public contractERC721;
    uint256 public assetIDERC721;
    uint256 public assetPriceERC721;
    address ownerERC721;
    address public paymentTokenERC721;
    bool isERC721AssetSold;
    mapping(uint256 => mapping(address => uint256)) saleRecords;

    event TokenTransferERC1155(
        address indexed from,
        address indexed to,
        uint256 tokenID,
        uint256 amount
    );
    event TokenTransferERC721(
        address indexed from,
        address indexed to,
        uint256 tokenID
    );

    /*
     * @notice provides initial parameters of feeRateNumerator and feeRateDenominator which can be used to create fee rate for Market place in any percent and     gives the address of
     * WETH token address
     * @params _feeRateNumerator - numerator of fee rate
     * @params _feeRateDenominator- denominator (should be a multiple of 10 and greater than 100)
     * @params _tokenWETH - address of WETH token
     */
    constructor(
        uint256 _feeRateNumerator,
        uint256 _feeRateDenominator,
        address _tokenWETH
    ) public {
        ownerMarketPlace = msg.sender;
        feeRateNumerator = _feeRateNumerator;
        feeRateDenominator = _feeRateDenominator;
        tokenWETH = _tokenWETH;
    }

    /*
     * @notice checks if quantity asked is less then remaining quantity of ERC1155 assest
     * @params Quantity to compare with
     */
    modifier _CheckQuantity(uint256 quantity) {
        require(
            quantity <= assetQuantityERC1155,
            " _checkQuantity: assets number are less than the required purchasing quatity"
        );
        _;
    }

    /*
     * @notice checks if the ERC721 asset is sold or not
     */
    modifier _checkAvailability() {
        require(
            !isERC721AssetSold,
            "_checkAvailability: ERC721 token already sold"
        );
        _;
    }

    /*
     * @notice sets the sale for ERC1155 token
     * @params _contractERC1155 - address of ERC1155 token
     * @params _assetIDERC1155 - id of the token
     * @params _assetQuantityERC1155 - quantity of the token
     * @params _assetPriceERC1155 - price for an asset
     * @arams _paymentTokenERC1155 - address for the paymenttoken you want to use
     */
    function setERC1155TokenSale(
        address _contractERC1155,
        uint256 _assetIDERC1155,
        uint256 _assetQuantityERC1155,
        uint256 _assetPriceERC1155,
        address _paymentTokenERC1155
    ) external {
        contractERC1155 = _contractERC1155;
        assetIDERC1155 = _assetIDERC1155;
        assetQuantityERC1155 = _assetQuantityERC1155;
        assetPriceERC1155 = _assetPriceERC1155;
        paymentTokenERC1155 = _paymentTokenERC1155;
        ownerERC1155 = msg.sender;
    }

    /*
     * @notice sets the sale for ERC721 token
     * @params _contractERC721 - address of ERC721 token
     * @params _assetIDERC721 - id of the token
     * @params _assetPriceERC721 - price for an asset
     * @arams _paymentTokenERC721 - address for the paymenttoken you want to use
     */
    function setERC721TokenSale(
        address _contractERC721,
        uint256 _assetIDERC721,
        uint256 _assetPriceERC721,
        address _paymentTokenERC721
    ) external {
        contractERC721 = _contractERC721;
        assetIDERC721 = _assetIDERC721;
        assetPriceERC721 = _assetPriceERC721;
        paymentTokenERC721 = _paymentTokenERC721;
        ownerERC721 = msg.sender;
        isERC721AssetSold = false;
    }

    /*
     * @notice function to buy ERC1155 asset with owner specified token
     * @params quantity of the asset
     * @params address of the purchaser
     */
    function getERC1155AssetToken(uint256 quantity, address purchaser)
        external
        _CheckQuantity(quantity)
    {
        require(
            paymentTokenERC1155 != address(0),
            "getERC1155AssetToken: user getERC1155AssetWETH or getERC1155AssetETH to buy ERC1155Asset"
        );
        IERC20 paymentToken = IERC20(paymentTokenERC1155);
        _checkAllowance(
            paymentToken,
            purchaser,
            _getCost(quantity, assetPriceERC1155)
        );
        _cutMarketPlacefee(
            paymentToken,
            _getCost(quantity, assetPriceERC1155),
            purchaser
        );
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC1155,
            (_getCost(quantity, assetPriceERC1155) *
                (feeRateDenominator - feeRateNumerator))
        );
        require(sent, "getERC1155AssetToken : tokenTransfer failed");
        _tranferERC1155Asset(assetIDERC1155, quantity, purchaser);
        saleRecords[assetIDERC1155][purchaser] += quantity;
        assetQuantityERC1155 = assetQuantityERC1155 - quantity;
        emit TokenTransferERC1155(
            ownerERC1155,
            purchaser,
            assetIDERC1155,
            quantity
        );
    }

    /*
     * @notice function to buy ERC721 asset with owner specified token
     * @params address of the purchaser
     */
    function getERC721AssetToken(address purchaser)
        external
        _checkAvailability
    {
        require(
            paymentTokenERC721 != address(0),
            "getERC721AssetToken: user getERC721AssetWETH or getERC721AssetETH to buy ERC721Asset"
        );
        IERC20 paymentToken = IERC20(paymentTokenERC721);
        _checkAllowance(paymentToken, purchaser, assetPriceERC721);
        _cutMarketPlacefee(paymentToken, assetPriceERC721, purchaser);
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC721,
            assetPriceERC721 * (feeRateDenominator - feeRateNumerator)
        );
        require(sent, "getERC721AssetToken : tokenTransfer failed");
        _tranferERC721Asset(ownerERC721, purchaser, assetIDERC721);
         saleRecords[assetIDERC1155][purchaser] = 1;
        isERC721AssetSold = true;
        emit TokenTransferERC721(ownerERC721, purchaser, assetIDERC721);
    }

    /*
     * @notice function to buy ERC1155 asset with WETH
     * @params quantity of the asset
     * @params address of the purchaser
     */
    function getERC1155AssetWETH(uint256 quantity, address purchaser)
        external
        _CheckQuantity(quantity)
    {
        require(
            paymentTokenERC1155 == address(0),
            "getERC1155AssetWETH: use getERC1155AssetToken to buy ERC1155Asset"
        );
        IERC20 paymentToken = IERC20(tokenWETH);
        _checkAllowance(
            paymentToken,
            purchaser,
            _getCost(quantity, assetPriceERC1155)
        );
        _cutMarketPlacefee(
            paymentToken,
            _getCost(quantity, assetPriceERC1155),
            purchaser
        );
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC1155,
            (_getCost(quantity, assetPriceERC1155) *
                (feeRateDenominator - feeRateNumerator))
        );
        require(sent, "getERC1155AssetWETH : tokenTransfer failed");
        _tranferERC1155Asset(assetIDERC1155, quantity, purchaser);
        saleRecords[assetIDERC1155][purchaser] += quantity;
        assetQuantityERC1155 = assetQuantityERC1155 - quantity;
        emit TokenTransferERC1155(
            ownerERC1155,
            purchaser,
            assetIDERC1155,
            quantity
        );
    }

    /*
     * @notice function to buy ERC721 asset with WETH
     * @params address of the purchaser
     */
    function getERC721AssetWETH(address purchaser) external _checkAvailability {
        require(
            paymentTokenERC721 == address(0),
            "getERC721AssetWETH: use getERC7215AssetToken to buy ERC721Asset"
        );
        IERC20 paymentToken = IERC20(tokenWETH);
        _checkAllowance(paymentToken, purchaser, assetPriceERC721);
        _cutMarketPlacefee(paymentToken, assetPriceERC721, purchaser);
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC721,
            assetPriceERC721 * (feeRateDenominator - feeRateNumerator)
        );
        require(sent, "getERC721AssetToken : tokenTransfer failed");
        _tranferERC721Asset(ownerERC721, purchaser, assetIDERC721);
        saleRecords[assetIDERC1155][purchaser] = 1;
        isERC721AssetSold = true;
        emit TokenTransferERC721(ownerERC721, purchaser, assetIDERC721);
    }

    /*
     * @notice function to buy ERC1155 asset with ethers
     * @params quantity of the asset
     * @params address of the purchaser
     */
    function getERC1155AssetETH(uint256 quantity, address purchaser)
        external
        payable
        nonReentrant
        _CheckQuantity(quantity)
    {
        require(
            paymentTokenERC1155 == address(0),
            "getERC1155AssetETH: use getERC1155AssetToken to buy ERC1155Asset"
        );
        require(
            msg.value / 10**18 >= quantity * assetPriceERC1155,
            "getERC1155AssetETH: Ether send less than the required ammount to purchase asset"
        );
        uint256 balance = address(this).balance;
        uint256 fees = (((quantity * assetPriceERC1155) * 10**18) *
            feeRateNumerator) / feeRateDenominator;
        uint256 cost = (((quantity * assetPriceERC1155) * 10**18) *
            (feeRateDenominator - feeRateNumerator)) / feeRateDenominator;
        payable(ownerERC1155).transfer(cost);
        uint256 remainingAmount = msg.value - fees - cost;
        payable(purchaser).transfer(remainingAmount);

        require(
            balance ==
                (address(this).balance +
                    (quantity * assetPriceERC1155) *
                    10**18),
            "getERC1155AssetETH: ether tranfer failed"
        );
        _tranferERC1155Asset(assetIDERC1155, quantity, purchaser);
        saleRecords[assetIDERC1155][purchaser] += quantity;
        assetQuantityERC1155 = assetQuantityERC1155 - quantity;
        emit TokenTransferERC1155(
            ownerERC1155,
            purchaser,
            assetIDERC1155,
            quantity
        );
    }

    /*
     * @notice function to buy ERC721 asset with ether
     * @params address of the purchaser
     */
    function getERC721AssetETH(address purchaser)
        external
        payable
        nonReentrant
        _checkAvailability
    {
        require(
            paymentTokenERC721 == address(0),
            "getERC721AssetETH: use getERC7215AssetToken to buy ERC721Asset"
        );
        require(
            msg.value / 10**18 >= assetPriceERC721,
            "getERC721AssetETH: Ether send less than the required ammount to purchase asset"
        );
        uint256 balance = address(this).balance;
        uint256 fees = ((assetPriceERC721 * 10**18) * feeRateNumerator) /
            feeRateDenominator;
        uint256 cost = ((assetPriceERC721 * 10**18) *
            (feeRateDenominator - feeRateNumerator)) / feeRateDenominator;
        payable(ownerERC721).transfer(cost);
        uint256 remainingAmount = msg.value - fees - cost;
        payable(purchaser).transfer(remainingAmount);
        require(
            balance == (address(this).balance + assetPriceERC721 * 10**18),
            "getERC721AssetETH: ether tranfer failed"
        );
        _tranferERC721Asset(ownerERC721, purchaser, assetIDERC721);
        saleRecords[assetIDERC1155][purchaser] = 1;
        isERC721AssetSold = true;
        emit TokenTransferERC721(ownerERC721, purchaser, assetIDERC721);
    }

    /*
     * @notice tranfers ERC721 asset
     * @params from - address of the owner of asset
     * @params to  - address of the purchaser of he asset
     * @params tokenID - the ID of the asset
     */
    function _tranferERC721Asset(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        IERC721 token = IERC721(contractERC721);
        if (isContract(to)) _checkOnIERC721Receiver(tokenId, to);
        token.transferFrom(from, to, tokenId);
    }

    /*
     * @notice tranfers ERC1155 asset
     * @params purchaser - address of the buyer of asset
     * @params quantity  - the quantity of he asset
     * @params assetID - the ID of the asset
     */
    function _tranferERC1155Asset(
        uint256 assetID,
        uint256 quantity,
        address purchaser
    ) internal {
        IERC1155 token = IERC1155(contractERC1155);
        if (isContract(purchaser))
            _checkIERC1155Receiver(purchaser, assetID, quantity);
        token.safeTransferFrom(ownerERC1155, purchaser, assetID, quantity, "");
    }

    /*
     * @notice checks if the contract address can handle ERC721 token
     * @params purchaser - address of buyer contract
     * @params assetID - the ID of the asset
     */
    function _checkOnIERC721Receiver(uint256 assetID, address purchaser)
        internal
    {
        bool output = IERC721Receiver(purchaser).onERC721Received(
            purchaser,
            ownerERC721,
            assetID,
            ""
        ) == IERC721Receiver.onERC721Received.selector;
        if (!output)
            revert("_checkOnIERC721Receiver : contract not a ERC721 reciver ");
    }

    /*
     * @notice checks if the contract address can handle ERC721 token
     * @params purchaser - address of buyer contract
     * @params assetID - the ID of the asset
     */
    function _checkIERC1155Receiver(
        address purchaser,
        uint256 assetID,
        uint256 quantity
    ) internal {
        bool output = IERC1155Receiver(purchaser).onERC1155Received(
            purchaser,
            ownerERC1155,
            assetID,
            quantity,
            ""
        ) == IERC1155Receiver.onERC1155Received.selector;
        if (!output)
            revert("_checkIERC1155Receiver : contract not a ERC721 reciver ");
    }

    /*
     * @notice cuts the market fee in case of token swap transaction
     * @params purchaser - address of buyer contract
     * @params token - the token which is swaped for Asset
     * @param cost - the cost of asset in given token
     */
    function _cutMarketPlacefee(
        IERC20 token,
        uint256 cost,
        address purchaser
    ) internal {
        bool sent = token.transferFrom(
            purchaser,
            ownerMarketPlace,
            (cost * feeRateNumerator)
        );
        require(sent, " _cutMarketPlacefee: tokenTransfer failed");
    }

    /*
     * @notice checks for the allowance in the given token to swap
     * @params purchaser - address of buyer contract
     * @params token - the token which is swaped for Asset
     * @param cost - the cost of asset in given token
     */
    function _checkAllowance(
        IERC20 token,
        address purchaser,
        uint256 cost
    ) internal {
        require(
            token.allowance(purchaser, address(this)) >= cost,
            "_checkAllowance : spending allowance less than amount"
        );
    }

    /*
     * @notice get the cost in given token to swap for asset
     * @params amount - the quantity of asset to be baught
     * @params tokenPurchasePrice - price in token per asset
     */
    function _getCost(uint256 amount, uint256 tokenPurchasePrice)
        internal
        returns (uint256)
    {
        return (amount * tokenPurchasePrice);
    }

    /*
     * @notice checks if the address given is that of a contract
     * @params address to be checked
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /*
     *@notcie withDraws ether to the market place owners account
     */
    function withDrawal() external{
        require(
            ownerMarketPlace == msg.sender,
            "withDrawal: not Authorised to withdraw ethers"
        );
        payable(msg.sender).transfer(address(this).balance);
    }
}