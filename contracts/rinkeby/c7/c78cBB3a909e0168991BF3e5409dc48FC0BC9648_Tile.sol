// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./lib/ERC1155NFT.sol";

contract Tile is ERC1155NFT {
    struct Fees {
        // Charged for the first tile minted in a batch.
        uint256 mintFee;
        // Each tile in the same batch is this much cheaper than the previous one.
        uint256 bulkDiscount;
        // Minimum fee to be charged for the last tiles in a batch.
        uint256 mintFeeMin;
    }

    struct Limits {
        // The size of the board.
        uint128 size;
        // The maximum number of tiles that can be minted in one batch.
        uint16 batchSize;
        // The number of tiles that are free for the contract deployer *only*.
        uint256 deployerDiscountedTiles;
    }

    // A contract allowed to stash/unstash tiles (used for making blocks).
    address private _stasher = address(0);

    // Fees - use getMintCost to query.
    Fees private _fees;

    // Limits - use maxTiles / maxMintSize to query.
    Limits private _limits;

    // Account that deployed the contract.
    address private _deployer;

    constructor(
        Limits memory initialLimits,
        Fees memory initialFees,
        string memory apiUrl,
        address proxyRegistryAddress
    ) ERC1155NFT(string(abi.encodePacked(apiUrl, "tiles/")), proxyRegistryAddress) {
        require(initialFees.mintFeeMin < initialFees.mintFee, "Minimum fee exceeds starting fee");
        require(initialLimits.size % 2 == 0, "Size not even");
        _fees = Fees({
            mintFee: initialFees.mintFee * 10**9,
            mintFeeMin: initialFees.mintFeeMin * 10**9,
            bulkDiscount: initialFees.bulkDiscount * 10**9
        });
        _limits = initialLimits;
        _deployer = msg.sender;
    }

    /**
     * @dev Gets the current limit to tiles.
     */
    function maxTiles() public view returns (uint256) {
        return _limits.size**2;
    }

    /**
     * @dev Gets the current number of minted tiles
     * (convenience function identical to mintedTokens)
     */
    function mintedTiles() public view returns (uint256) {
        return mintedTokens;
    }

    /**
     * @dev Gets the current limit for tiles in a single batch.
     * @return the batch limit. If 0, there is no batch limit.
     */
    function maxMintSize() public view returns (uint16) {
        return _limits.batchSize;
    }

    /**
     * @dev Gets the cost of minting tiles.
     * @param amount the amount of tiles to mint.
     * @return the cost of minting the given amount of tiles. Cost may be 0 for deployer.
     */
    function getMintCost(uint16 amount) public view returns (uint256) {
        // Total owed:
        // sum_(x=0)^amount (mintFee - bulkDiscount * x)
        // i.e. each subsequent tile is bulkDiscount cheaper than the previous
        // one, starting at mintFee for the first one, down to mintFeeMin.
        // same as below:
        require(mintedTokens + amount <= maxTiles(), "Amount exceeds available");
        uint16 exemptAmount = 0;
        if (msg.sender == _deployer && _limits.deployerDiscountedTiles > mintedTokens) {
            exemptAmount = uint16(Math.min(_limits.deployerDiscountedTiles - mintedTokens, 2**16));
        }
        if (exemptAmount >= amount) {
            return 0;
        }
        uint256 base = Math.min(
            amount - exemptAmount,
            (_fees.mintFee - _fees.mintFeeMin) / _fees.bulkDiscount
        );
        return
            base *
            (_fees.mintFee - ((base - 1) * _fees.bulkDiscount) / 2) +
            (amount - exemptAmount - base) *
            _fees.mintFeeMin;
    }

    /**
     * @notice Mint `amount` tiles to address `to`.
     * @dev Mints tiles in batch.
     * @param amount the amount of tiles to mint.
     * @param to the address to mint tiles to (does not have to be msg.sender).
     */
    function mintTo(uint16 amount, address to) external payable {
        require(mintedTokens + amount <= maxTiles(), "Amount exceeds available");
        require(maxMintSize() == 0 || amount <= maxMintSize(), "Amount exceeds batch limit");
        uint256 transactionTotal = getMintCost(amount);
        require(msg.value >= transactionTotal, "Must pay for mint");
        uint256[] memory tileIds = new uint256[](amount);
        uint256[] memory ones = new uint256[](amount);
        for (uint16 i = 0; i < amount; i++) {
            tileIds[i] = mintedTokens + i;
            ones[i] = 1;
            _tokenOwners.push(to);
        }
        mintedTokens += amount;
        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, tileIds, ones, "");
        emit TransferBatch(msg.sender, address(0), to, tileIds, ones);
    }

    // Stasher API.

    modifier onlyStasher() {
        require(_stasher == msg.sender, "Not a designated stasher");
        _;
    }

    function stashBatch(address from, uint256[] memory tileIds) external onlyStasher {
        uint256[] memory ones = new uint256[](tileIds.length);
        for (uint256 i = 0; i < tileIds.length; ++i) {
            uint256 id = tileIds[i];

            require(_tokenOwners[id] == from, "ERC1155: insufficient balance");
            _tokenOwners[id] = address(0);
            ones[i] = 1;
        }
        emit TransferBatch(msg.sender, from, address(0), tileIds, ones);
    }

    function unstashBatch(address to, uint256[] memory tileIds) external onlyStasher {
        uint256[] memory ones = new uint256[](tileIds.length);
        for (uint256 i = 0; i < tileIds.length; i++) {
            require(tileIds[i] < mintedTokens, "Token does not exist");
            ones[i] = 1;
        }
        _safeBatchTransferFrom(address(0), to, tileIds, ones, "");
    }

    // Owner API.

    function setFees(Fees memory newFees) external onlyOwner {
        require(newFees.mintFeeMin < newFees.mintFee, "Minimum fee exceeds starting fee");
        _fees = Fees({
            mintFee: newFees.mintFee * 10**9,
            mintFeeMin: newFees.mintFeeMin * 10**9,
            bulkDiscount: newFees.bulkDiscount * 10**9
        });
    }

    function setLimits(Limits memory newLimits) external onlyOwner {
        require(newLimits.size % 2 == 0, "Size not even");
        require(newLimits.size >= _limits.size, "Size smaller than current");
        require(
            newLimits.deployerDiscountedTiles == _limits.deployerDiscountedTiles,
            "Deployer discount changed"
        );
        _limits = newLimits;
    }

    function setBaseUrl(string memory newBaseUrl) public virtual override onlyOwner {
        super.setBaseUrl(string(abi.encodePacked(newBaseUrl, "tile/")));
    }

    function setStasher(address stasherContract) external onlyOwner {
        _stasher = stasherContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ProxyRegistry.sol";
import "./IERC2981.sol";

// This is largely replicating OpenZeppelin's ERC1155 - private access to owner
// mapping was needed for stashing.
contract ERC1155NFT is ERC165, IERC1155, IERC1155MetadataURI, IERC2981, Ownable {
    using Address for address;

    struct RoyaltyConfig {
        // The receiving address of royalty charges.
        address target;
        // The percentage points (in tenths of a %) to charge in royalties.
        uint8 points;
    }

    // Tokens currently minted.
    uint256 public mintedTokens = 0;

    // Mapping to owners (0 for stashed tokens).
    address[] internal _tokenOwners;

    // Wyvern proxy registry address.
    address private _proxyRegistryAddress;

    // Manual proxies.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Base URL of API.
    string private _baseUrl;

    // An address to send royalties for NFT trading to. Can only be set by owner.
    RoyaltyConfig private _royaltyConfig;

    constructor(string memory apiUrl, address proxyRegistryAddress) {
        _baseUrl = apiUrl;
        _proxyRegistryAddress = proxyRegistryAddress;
        _royaltyConfig = RoyaltyConfig({
            target: msg.sender,
            points: 70 // 7%
        });
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns a unique URI for each token, using a
     * "token/<id>" format, for a wider compatibility compared to "{id}"
     * replacement.
     */
    function uri(uint256 id) external view override returns (string memory) {
        require(id < mintedTokens, "Token does not exist");
        return string(abi.encodePacked(_baseUrl, "token/", Strings.toString(id)));
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance for address(0)");
        require(id < mintedTokens, "Token does not exist");
        return _tokenOwners[id] == account ? 1 : 0;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts/ids mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Gets the owner of a given token.
     */
    function getOwningAddress(uint256 id) external view returns (address) {
        return _tokenOwners[id];
    }

    /**
     * @dev Gets the owner(s) of a given batch of tokens.
     */
    function getOwningAddressBatch(uint256[] memory ids) external view returns (address[] memory) {
        address[] memory batchOwners = new address[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            batchOwners[i] = _tokenOwners[ids[i]];
        }

        return batchOwners;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}. This also whitelists the ProxyRegistry used by OpenSea.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) {
            return true;
        }

        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override {
        require(id < mintedTokens, "Token does not exist");
        require(amount == 1, "Cannot transfer amount > 1");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     * @return receiver will always be the address of the deployer of the contract.
     * @return royaltyAmount will always be 7% of value.
     */
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyConfig.target;
        royaltyAmount = (value * _royaltyConfig.points) / 1000;
    }

    /**
     * @dev OpenSea spec metadata for the contract - always "<baseUrl>/contract".
     */
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseUrl, "contract"));
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        require(_tokenOwners[id] == from, "ERC1155: insufficient balance");

        _tokenOwners[id] = to;
        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(ids.length == amounts.length, "ERC1155: ids/amounts mismatch");
        require(to != address(0), "ERC1155: transfer to address(0)");

        uint256[] memory ones = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            require(id < mintedTokens, "Token does not exist");
            require(amount == 1, "Cannot transfer amount > 1");

            require(_tokenOwners[id] == from, "ERC1155: insufficient balance");
            _tokenOwners[id] = to;
            ones[i] = 0;
        }
        emit TransferBatch(msg.sender, from, to, ids, ones);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens.
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, "ERC1155: cannot approve self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver reject");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: to not ERC1155Receiver");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data)
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver reject");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: to not ERC1155Receiver");
            }
        }
    }

    // Owner API.

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        wallet.transfer(amount);
    }

    function setRoyaltyConfig(RoyaltyConfig memory newConfig) external onlyOwner {
        _royaltyConfig = newConfig;
    }

    function setBaseUrl(string memory newBaseUrl) public virtual onlyOwner {
        _baseUrl = newBaseUrl;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract OwnableDelegateProxy {} // solhint-disable-line
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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