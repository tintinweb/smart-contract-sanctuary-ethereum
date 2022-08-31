/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// File: Utils.sol



pragma solidity ^0.8.0;

/// @notice 管理者権限の実装
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
    }
}

/// @notice 発行権限の実装
abstract contract Mintable {
    mapping(address => bool) public minters;

    constructor() {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }

    function setMinter(address newMinter, bool mintable) public virtual onlyMinter {
        require(
            newMinter != address(0),
            "Mintable: new minter is the zero address"
        );
        minters[newMinter] = mintable;
    }
}

/// @notice 焼却権限の実装
abstract contract Burnable {
    mapping(address => bool) public burners;

    constructor() {
        burners[msg.sender] = true;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "Burnable: caller is not burner");
        _;
    }

    function setBurner(address newBurner, bool burnable) public virtual onlyBurner {
        require(
            newBurner != address(0),
            "Burnable: new burner is the zero address"
        );
        burners[newBurner] = burnable;
    }
}

/// @notice 署名の実装
abstract contract SupportSig {

    function getSigner(bytes memory contents, bytes memory sig) internal pure returns (address) {
        bytes32 hash_ = keccak256(contents);
        return _recover(hash_, sig);
    }

    function _recover(bytes32 hash_, bytes memory sig) private pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash_, v, r, s);
        }
    }
}

/// @notice トークン更新履歴の実装
abstract contract SupportTokenUpdateHistory {

    struct  TokenUpdateHistoryItem {
        uint256 tokenId;
        uint256 updatedAt;
    }

    uint256 public tokenUpdateHistoryCount;
    TokenUpdateHistoryItem[] public tokenUpdateHistory;

    constructor() {
        TokenUpdateHistoryItem memory dummy;
        tokenUpdateHistory.push(dummy);  // 1-based index
    }

    function onTokenUpdated(uint256 tokenId) internal {
        tokenUpdateHistory.push(TokenUpdateHistoryItem(tokenId, block.timestamp));
        tokenUpdateHistoryCount++;
    }
}
// File: IEggBuilder.sol



pragma solidity ^0.8.0;

interface IEggBuilder {

    /// @notice Shardトークンを組み合わせてEggを生成する。
    /** @dev
    処理概要：
    * 要求元からAnimaを回収
    * 入力されたShardから新しいgeneを計算
    * Shardトークンをburn
    * Eggトークンをmint
    */
    function compose(uint256 shardId1, uint256 shardId2, string calldata metadataHash, address to) external returns (uint256);
}
// File: IMatrix.sol



pragma solidity ^0.8.0;

interface IMatrix {
    /// @notice Eggを生成する。
    function spawn(string calldata metadataHash, address to) external returns (uint256);

    /// @notice Eggの生成に必要とするAnimaの量を取得する。
    function getPrice() external view returns (uint256);
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


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

// File: Matrix.sol



pragma solidity ^0.8.0;






interface IShardToken is IERC1155 {
    function tokensOfOwner(address account) external view returns (uint256);
    function tokenOfOwnerByIndex(address account, uint256 index) external view returns (uint256);
}

contract Matrix is IMatrix, Ownable, IERC1155Receiver {

    uint256 private price;
    IEggBuilder builder;
    IShardToken shardToken;
    address matrixMaster;
    uint256 nonce;

    function setPrice(uint256 price_) external onlyOwner
    {
        price = price_;
    }

    function setEggBuilder(address address_) external onlyOwner
    {
        builder = IEggBuilder(address_);
    }

    function setShardToken(address address_) external onlyOwner
    {
        shardToken = IShardToken(address_);
    }

    function setMatrixMaster(address address_) external onlyOwner
    {
        matrixMaster = address_;
    }

    /// @notice Eggを生成する。
    function spawn(string calldata metadataHash, address to) override external returns (uint256)
    {
        require(
            (msg.sender == matrixMaster) || (msg.sender == Ownable.owner),
            "Matrix: caller is not MatrixMaster nor owner"
        );
        (uint256 shardId1, uint256 shardId2) = _getShardPairRandomly();
        shardToken.setApprovalForAll(address(builder), true);
        uint256 eggId = builder.compose(shardId1, shardId2, metadataHash, to);
        shardToken.setApprovalForAll(address(builder), false);
        return eggId;
    }

    /// @notice Eggの生成に必要とするArcanaの量を取得する。
    function getPrice() override external view returns (uint256)
    {
        return price;
    }

    function _getShardPairRandomly() internal returns (uint256, uint256)
    {
        uint256 numOfGenes = shardToken.tokensOfOwner(address(this));
        require(numOfGenes >= 2, "Matrix: insufficient shard");
        uint256 index1 = uint256(keccak256(abi.encodePacked(block.timestamp, nonce))) % numOfGenes;
        nonce++;
        uint256 index2 = uint256(keccak256(abi.encodePacked(block.timestamp, nonce))) % (numOfGenes - 1);
        nonce++;
        if (index2 >= index1) {
            index2 += 1;
        }
        uint256 tokenId1 = shardToken.tokenOfOwnerByIndex(address(this), index1);
        uint256 tokenId2 = shardToken.tokenOfOwnerByIndex(address(this), index2);
        return (tokenId1, tokenId2);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) override public view virtual returns (bool)
    {
        return interfaceId == type(IERC1155Receiver).interfaceId ||
               interfaceId == type(IMatrix).interfaceId;
    }

    // ERC1155Receiver

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) override external pure returns (bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) override external pure returns (bytes4)
    {
       return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}