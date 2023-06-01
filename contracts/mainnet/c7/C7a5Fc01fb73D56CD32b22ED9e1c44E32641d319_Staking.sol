/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)
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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IStaking {
    // events
    event Stake(
        address indexed fromAddress,
        address indexed toAddress,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 schema,
        uint256 orderId,
        uint256 orderType
    );

    event Redeem(
        address indexed fromAddress,
        address indexed toAddress,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 schema,
        uint256 orderId
    );

    function stake(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256[] memory schemas,
        uint256[] memory orderIds,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs,
        uint8[] memory sigVs,
        uint256[] memory types
    ) external;

    function redeem(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256[] memory schemas,
        uint256[] memory orderIds,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs,
        uint8[] memory sigVs
    ) external;
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/Initializable.sol
 */
contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/EIP712Base.sol
 */
contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(
        bytes32 messageHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

interface IAddressesProvider {
    function addSigner(address signer) external;

    function removeSigner(address signer) external;

    function isSigner(address signer) external view returns (bool);

    function setAddress(bytes32 key, address addr) external;

    function getAddress(bytes32 key) external view returns (address);

    function setPlatformAccount(address platformAccount) external;

    function getPlatformAccount() external view returns (address);

    function safeGetPlatformAccount() external view returns (address);
}

contract Staking is IStaking, Ownable, ERC165, IERC1155Receiver, EIP712Base {
    IAddressesProvider private _addressesProvider;

    function getAddressesProvider() public view returns (address) {
        return address(_addressesProvider);
    }

    function setAddressesProvider(
        address addressesProviderAddress
    ) public onlyOwner {
        _addressesProvider = IAddressesProvider(addressesProviderAddress);
    }

    bytes32 constant STAKING_REQUEST_TYPEHASH =
        keccak256(
            "StakingRequest(address nftAddress,uint256 tokenId,uint256 amount,uint256 schema,uint256 orderId)"
        );

    struct StakingRequest {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 schema;
        uint256 orderId;
    }

    // setter
    function hashStakingRequest(
        StakingRequest memory request
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    STAKING_REQUEST_TYPEHASH,
                    request.nftAddress,
                    request.tokenId,
                    request.amount,
                    request.schema,
                    request.orderId
                )
            );
    }

    string private _name = "Staking";

    constructor() {
        _initializeEIP712(_name);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    mapping(uint256 => address) private _orderUser;
    mapping(uint256 => uint256) private _orderAmount;

    function stake(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256[] memory schemas,
        uint256[] memory orderIds,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs,
        uint8[] memory sigVs,
        uint256[] memory types
    ) external override {
        require(
            nftAddresses.length == tokenIds.length,
            "Stake: nftAddresses length does not match tokenIds length"
        );
        require(
            nftAddresses.length == amounts.length,
            "Stake: nftAddresses length does not match amounts length"
        );
        require(
            nftAddresses.length == schemas.length,
            "Stake: nftAddresses length does not match schemas length"
        );
        require(
            nftAddresses.length == orderIds.length,
            "Stake: nftAddresses length does not match orderIds length"
        );
        require(
            nftAddresses.length == sigRs.length,
            "Stake: nftAddresses length does not match sigR length"
        );
        require(
            nftAddresses.length == sigSs.length,
            "Stake: nftAddresses length does not match sigS length"
        );
        require(
            nftAddresses.length == sigVs.length,
            "Stake: nftAddresses length does not match sigV length"
        );
        require(
            nftAddresses.length <= 30,
            "Stake: batch amount must less than 30"
        );

        uint256 _len = nftAddresses.length;

        for (uint256 _i; _i < _len; _i++) {
            address nftAddress = nftAddresses[_i];
            uint256 tokenId = tokenIds[_i];
            uint256 amount = amounts[_i];
            uint256 schema = schemas[_i];
            uint256 orderId = orderIds[_i];
            bytes32 sigR = sigRs[_i];
            bytes32 sigS = sigSs[_i];
            uint8 sigV = sigVs[_i];
            uint256 orderType = types[_i];

            StakingRequest memory request = StakingRequest({
                nftAddress: nftAddress,
                tokenId: tokenId,
                amount: amount,
                schema: schema,
                orderId: orderId
            });

            require(
                verifyStaking(request, sigR, sigS, sigV),
                "Staking: invalid signature"
            );

            _transferNFT(
                schema,
                nftAddress,
                msg.sender,
                address(this),
                tokenId,
                amount
            );
            _orderUser[orderId] = msg.sender;
            _orderAmount[orderId] = amount;

            emit Stake(
                msg.sender,
                address(this),
                nftAddress,
                tokenId,
                amount,
                schema,
                orderId,
                orderType
            );
        }
    }

    function redeem(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256[] memory schemas,
        uint256[] memory orderIds,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs,
        uint8[] memory sigVs
    ) external override {
        require(
            nftAddresses.length == tokenIds.length,
            "redeem: nftAddresses length does not match tokenIds length"
        );
        require(
            nftAddresses.length == amounts.length,
            "redeem: nftAddresses length does not match amounts length"
        );
        require(
            nftAddresses.length == schemas.length,
            "redeem: nftAddresses length does not match schemas length"
        );
        require(
            nftAddresses.length == orderIds.length,
            "redeem: nftAddresses length does not match orderIds length"
        );
        require(
            nftAddresses.length == sigRs.length,
            "Stake: nftAddresses length does not match sigR length"
        );
        require(
            nftAddresses.length == sigSs.length,
            "Stake: nftAddresses length does not match sigS length"
        );
        require(
            nftAddresses.length == sigVs.length,
            "Stake: nftAddresses length does not match sigV length"
        );
        require(
            nftAddresses.length <= 30,
            "redeem: batch amount must less than 30"
        );

        uint256 _len = nftAddresses.length;

        for (uint256 _i; _i < _len; _i++) {
            address nftAddress = nftAddresses[_i];
            uint256 tokenId = tokenIds[_i];
            uint256 amount = amounts[_i];
            uint256 schema = schemas[_i];
            uint256 orderId = orderIds[_i];
            bytes32 sigR = sigRs[_i];
            bytes32 sigS = sigSs[_i];
            uint8 sigV = sigVs[_i];

            StakingRequest memory request = StakingRequest({
                nftAddress: nftAddress,
                tokenId: tokenId,
                amount: amount,
                schema: schema,
                orderId: orderId
            });

            require(
                verifyStaking(request, sigR, sigS, sigV),
                "Staking: invalid signature"
            );

            require(
                _orderUser[orderId] == msg.sender,
                "redeem: order owner does not match"
            );
            require(
                _orderAmount[orderId] == amount,
                "redeem: order amount does not match"
            );

            _transferNFT(
                schema,
                nftAddress,
                address(this),
                msg.sender,
                tokenId,
                amount
            );

            delete _orderUser[orderId];
            delete _orderAmount[orderId];

            emit Redeem(
                address(this),
                msg.sender,
                nftAddress,
                tokenId,
                amount,
                schema,
                orderId
            );
        }
    }

    function verifyStaking(
        StakingRequest memory request,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(
            address(_addressesProvider) != address(0),
            "Staking: addresses provider is not set"
        );
        return
            _addressesProvider.isSigner(
                ecrecover(
                    toTypedMessageHash(hashStakingRequest(request)),
                    sigV,
                    sigR,
                    sigS
                )
            );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public view override returns (bytes4) {
        return IERC1155Receiver(this).onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public view override returns (bytes4) {
        return IERC1155Receiver(this).onERC1155BatchReceived.selector;
    }

    function _transferNFT(
        uint256 schema,
        address nftAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (schema == 721) {
            require(amount == 1, "Stake: erc721 amount must be 1");
            IERC721(nftAddress).transferFrom(from, to, tokenId);
        } else if (schema == 1155) {
            require(amount > 0, "Stake: erc1155 amount must be greater than 0");
            IERC1155(nftAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        } else {
            revert("Stake: unknown schema");
        }
    }
}