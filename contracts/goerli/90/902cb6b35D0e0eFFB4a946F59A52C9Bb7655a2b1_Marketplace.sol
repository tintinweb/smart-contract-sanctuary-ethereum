// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INFT is IERC1155 {
    function mint(
        address buyer,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Protected.sol";
import "./interfaces/INFT.sol";

error CurrencyNotSupported(address currency);
error NotEnoughNativeTokens();
error NotEnoughTokensApproved();

error TooEarly(uint256 startTime, uint256 currentTime);
error TooLate(uint256 endTime, uint256 currentTime);

contract Marketplace is Protected {
    mapping(address => bool) public supportedCurrencies;
    address public internalNFT;
    address private _trustedForwarder;

    event InitialPurchase(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id,
        uint256 editions,
        string meta,
        address currency,
        uint256 price
    );

    event ERC1155Purchase(
        address indexed seller,
        address indexed buyer,
        address indexed token,
        uint256 id,
        uint256 editions,
        address currency,
        uint256 price
    );

    event ERC721Purchase(
        address indexed seller,
        address indexed buyer,
        address indexed token,
        uint256 id,
        address currency,
        uint256 price
    );

    constructor(address nft) {
        internalNFT = nft;
    }

    function isTrustedForwarder(
        address forwarder
    ) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /// @notice Mint new tokens and buy it with permit
    /// @param params Struct with mint parameters
    /// @param sig Struct with signature
    function mintSigned(
        MintParams calldata params,
        Signature calldata sig
    ) external payable {
        _checkActive(params.startTime, params.endTime);
        _checkMoney(
            _msgSender(),
            params.currency,
            params.price,
            params.editions
        );

        if (!_checkMintSignature(params, sig)) revert WrongSignature();

        _mint(
            _msgSender(),
            params.id,
            params.editions,
            params.meta,
            params.royaltyReceiver,
            params.royalty
        );
        _pay(
            params.seller,
            _msgSender(),
            params.currency,
            params.price,
            params.editions
        );

        emit InitialPurchase(
            params.seller,
            _msgSender(),
            params.id,
            params.editions,
            params.meta,
            params.currency,
            params.price
        );
    }

    /// @notice Buy existing ERC1155 with permit
    /// @param params Struct with purchase parameters
    /// @param sig Struct with signature
    function buyERC1155Signed(
        BuyERC1155Params calldata params,
        Signature calldata sig
    ) external payable {
        _checkActive(params.startTime, params.endTime);
        _checkMoney(
            _msgSender(),
            params.currency,
            params.price,
            params.editions
        );

        if (!_checkERC1155Signature(params, sig)) revert WrongSignature();

        _transferERC1155(
            params.seller,
            _msgSender(),
            params.token,
            params.id,
            params.editions
        );
        _pay(
            params.seller,
            _msgSender(),
            params.currency,
            params.price,
            params.editions
        );

        emit ERC1155Purchase(
            params.seller,
            _msgSender(),
            params.token,
            params.id,
            params.editions,
            params.currency,
            params.price
        );
    }

    /// @notice Buy existing ERC721 with permit
    /// @param params Struct with purchase parameters
    /// @param sig Struct with signature
    function buyERC721Signed(
        BuyERC721Params calldata params,
        Signature calldata sig
    ) external payable {
        _checkActive(params.startTime, params.endTime);
        _checkMoney(_msgSender(), params.currency, params.price, 1);

        if (!_checkERC721Signature(params, sig)) revert WrongSignature();

        _transferERC721(params.seller, _msgSender(), params.token, params.id);
        _pay(params.seller, _msgSender(), params.currency, params.price, 1);

        emit ERC721Purchase(
            params.seller,
            _msgSender(),
            params.token,
            params.id,
            params.currency,
            params.price
        );
    }

    /// @notice Check if permit active
    /// @param startTime Time when permit starts to be active
    /// @param endTime Time when permit ends to be active
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (block.timestamp < startTime)
            revert TooEarly(startTime, block.timestamp);
        if (block.timestamp > endTime) revert TooLate(endTime, block.timestamp);
    }

    /// @notice Check payment
    /// @param buyer Address of buyer
    /// @param currency Address of token to pay (zero if native)
    /// @param price Price per token to purchase
    /// @param editions Quantity of token to purchase
    function _checkMoney(
        address buyer,
        address currency,
        uint256 price,
        uint256 editions
    ) internal view {
        if (!supportedCurrencies[currency])
            revert CurrencyNotSupported(currency);
        else if (currency == address(0)) {
            if (msg.value < price * editions) revert NotEnoughNativeTokens();
        } else if (
            IERC20(currency).allowance(buyer, address(this)) < price * editions
        ) revert NotEnoughTokensApproved();
    }

    /// @notice Mint new internal ERC1155
    /// @param buyer Address of future owner of tokens
    /// @param id ID of tokens to mint
    /// @param editions Quantity of tokens to mint
    /// @param meta URL of tokens' metadata (will be overwritten if already stored)
    function _mint(
        address buyer,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    ) internal {
        INFT(internalNFT).mint(
            buyer,
            id,
            editions,
            meta,
            royaltyReceiver,
            royalty
        );
    }

    /// @notice Pay for tokens
    /// @param seller Receiver of payment
    /// @param buyer Payer
    /// @param currency Address of token to pay (zero if native)
    /// @param price Price per token to purchase
    /// @param editions Quantity of token to purchase
    function _pay(
        address payable seller,
        address buyer,
        address currency,
        uint256 price,
        uint256 editions
    ) internal {
        if (currency == address(0)) {
            seller.transfer(price * editions);
        } else {
            IERC20(currency).transferFrom(buyer, seller, price * editions);
        }
    }

    /// @notice Deliver token to buyer
    /// @param seller Sender of token
    /// @param buyer Receiver of token
    /// @param token Token to deliver
    /// @param id Tokens' id
    /// @param editions Quantity of token to deliver
    function _transferERC1155(
        address seller,
        address buyer,
        address token,
        uint256 id,
        uint256 editions
    ) internal {
        IERC1155(token).safeTransferFrom(seller, buyer, id, editions, "");
    }

    /// @notice Deliver token to buyer
    /// @param seller Sender of token
    /// @param buyer Receiver of token
    /// @param token Token to deliver
    /// @param id Tokens' id
    function _transferERC721(
        address seller,
        address buyer,
        address token,
        uint256 id
    ) internal {
        IERC721(token).transferFrom(seller, buyer, id);
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function addSupportedCurrency(address currency) external onlyOwner {
        supportedCurrencies[currency] = true;
    }

    function removeSupportedCurrency(address currency) external onlyOwner {
        supportedCurrencies[currency] = false;
    }

    function setTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarder = forwarder;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

error WrongSignature();
error UsedDigest();

abstract contract Protected is Ownable {
    bytes32 internal constant _EIP_712_DOMAIN_TYPEHASH =
        // prettier-ignore
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainID,address verifyingContract)'
        );
    bytes32 internal constant _MINT_TYPEHASH =
        // prettier-ignore
        keccak256(
            "MintParams(address seller,uint256 id,uint256 editions,string meta,address currency,uint256 price,uint256 startTime,uint256 endTime,address royaltyReceiver,uint96 royalty)"
        );
    bytes32 internal constant _ERC1155_TYPEHASH =
        // prettier-ignore
        keccak256(
            "ERC1155Params(address seller,address token,uint256 id,uint256 editions,address currency,uint256 price,uint256 startTime,uint256 endTime)"
        );
    bytes32 internal constant _ERC721_TYPEHASH =
        // prettier-ignore
        keccak256(
            "ERC721Params(address seller,address token,uint256 id,address currency,uint256 price,uint256 startTime,uint256 endTime)"
        );

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    struct MintParams {
        address payable seller;
        uint256 id;
        uint256 editions;
        string meta;
        address currency;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        address royaltyReceiver;
        uint96 royalty;
    }
    struct BuyERC1155Params {
        address payable seller;
        address token;
        uint256 id;
        uint256 editions;
        address currency;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }
    struct BuyERC721Params {
        address payable seller;
        address token;
        uint256 id;
        address currency;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(bytes32 => bool) internal _usedDigests;

    /// @notice Check the signature for signed mint
    /// @param params Struct with mint parameters
    /// @param sig Struct with signature
    function _checkMintSignature(
        MintParams calldata params,
        Signature calldata sig
    ) internal returns (bool) {
        bytes32 digest = _getDigest(_getMintHashStruct(params));
        if (_usedDigests[digest]) revert UsedDigest();
        _usedDigests[digest] = true;
        return _isSignatureValid(digest, sig, params.seller);
    }

    /// @notice Check the signature for buying existing ERC1155
    /// @param params Struct with mint parameters
    /// @param sig Struct with signature
    function _checkERC1155Signature(
        BuyERC1155Params calldata params,
        Signature calldata sig
    ) internal returns (bool) {
        bytes32 digest = _getDigest(_getERC1155HashStruct(params));
        if (_usedDigests[digest]) revert UsedDigest();
        _usedDigests[digest] = true;
        return _isSignatureValid(digest, sig, params.seller);
    }

    /// @notice Check the signature for buying existing ERC721
    /// @param params Struct with mint parameters
    /// @param sig Struct with signature
    function _checkERC721Signature(
        BuyERC721Params calldata params,
        Signature calldata sig
    ) internal returns (bool) {
        bytes32 digest = _getDigest(_getERC721HashStruct(params));
        if (_usedDigests[digest]) revert UsedDigest();
        _usedDigests[digest] = true;
        return _isSignatureValid(digest, sig, params.seller);
    }

    /// @notice Decrypt signature, check if signer correct
    /// @param digest Parameters hash
    /// @param sig Struct with signature
    /// @return Validness of signature, true or false
    function _isSignatureValid(
        bytes32 digest,
        Signature calldata sig,
        address seller
    ) internal pure returns (bool) {
        return ecrecover(digest, sig.v, sig.r, sig.s) == seller;
    }

    /// @notice Calculate domain hash
    /// @return Domain hash
    function _deriveDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH,
                    keccak256("NFTMarketplace"),
                    keccak256("1.0"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /// @notice Calculate mint hash struct
    /// @param params Struct with mint parameters
    /// @return Mint hash struct
    function _getMintHashStruct(
        MintParams calldata params
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _MINT_TYPEHASH,
                    params.seller,
                    params.id,
                    params.editions,
                    params.meta,
                    params.currency,
                    params.price,
                    params.startTime,
                    params.endTime,
                    params.royaltyReceiver,
                    params.royalty
                )
            );
    }

    /// @notice Calculate buying hash struct
    /// @param params Struct with buying parameters
    /// @return Mint buying struct
    function _getERC1155HashStruct(
        BuyERC1155Params calldata params
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _ERC1155_TYPEHASH,
                    params.seller,
                    params.token,
                    params.id,
                    params.editions,
                    params.currency,
                    params.price,
                    params.startTime,
                    params.endTime
                )
            );
    }

    /// @notice Calculate buying hash struct
    /// @param params Struct with buying parameters
    /// @return Mint buying struct
    function _getERC721HashStruct(
        BuyERC721Params calldata params
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _ERC721_TYPEHASH,
                    params.seller,
                    params.token,
                    params.id,
                    params.currency,
                    params.price,
                    params.startTime,
                    params.endTime
                )
            );
    }

    /// @notice Calculate digest from domain and parameters hashes
    /// @param hashStruct Parameters hash
    /// @return Hash, used to decrypt the signature
    function _getDigest(bytes32 hashStruct) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes2(0x1901),
                    _deriveDomainSeparator(),
                    hashStruct
                )
            );
    }
}