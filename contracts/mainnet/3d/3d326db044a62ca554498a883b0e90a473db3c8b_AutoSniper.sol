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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./helpers/SniperStructs.sol";
import "./helpers/IWETH.sol";
import "./helpers/IPunk.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";

error InsufficientBalance();
error FailedToWithdraw();
error MaxTipExceeded();
error MarketplaceNotAllowed();
error TokenContractNotAllowed();
error OrderFailed();
error TipBelowMinimum();
error CallerNotFulfiller();

/// @title AutoSniper for oSnipe
/// @author 0xQuit

contract AutoSniper is Ownable {
    event SnipeSuccessful(address nftContractAddress, uint256 tokenId, address sniper);

    address private FULFILLER_ADDRESS;
    uint256 public minimumTip = 0.005 ether;
    mapping(address => bool) public allowedMarketplaces;
    mapping(address => uint256) public sniperBalances;
    mapping(address => SniperGuardrails) public sniperGuardrails;

    /**
    ** @param _fulfiller This address is controlled by the oSnipe discord bot,
    ** and is responsible for fulfilling orders. Only the fulfiller can call `fulfillOrder`.
    */
    constructor(address _fulfiller) { 
        FULFILLER_ADDRESS = _fulfiller;
    }

    /**
    ** @notice fulfillOrder conducts its own checks to ensure that the passed order is a valid sniper
    ** before forwarding the snipe on to the appropriate marketplace. Snipers can block orders by setting
    ** up guardrails that prevent orders from being fulfilled outside of allowlisted marketplaces or
    ** nft contracts, or with tips that exceed a maximum tip amount. WETH is used to subsidize
    ** the order in case the Sniper's deposited balance is too low. WETH must be approved in order for this to
    ** work. Calculation is done off-chain and passed in via wethAmount. If for some reason there is an overpay,
    ** the marketplace will refund the difference, which is added to the Sniper's balance.
    ** @param wethAmount the amount of WETH that needs to be converted.
    */
    function fulfillOrder(SniperOrder calldata order, uint256 wethAmount) external onlyFulfiller {
        if (wethAmount > 0) _swapWeth(wethAmount, order.to);
        _checkSniperGuardrails(order.tokenAddress, order.marketplace, order.tip, order.to);
        uint256 totalValue = order.value + order.tip;
        if (!allowedMarketplaces[order.marketplace]) revert MarketplaceNotAllowed();
        if (sniperBalances[order.to] < totalValue) revert InsufficientBalance();

        uint256 balanceBefore = address(this).balance;

        (bool transferred, ) = payable(FULFILLER_ADDRESS).call{value: order.tip}("");
        if (!transferred) revert FailedToWithdraw();
        (bool success,) = order.marketplace.call{value: order.value}(order.data);
        if (!success) revert OrderFailed();

        uint256 balanceAfter = address(this).balance;
        uint256 spent = balanceBefore - balanceAfter;

        unchecked { sniperBalances[order.to] -= spent; }

        _transferNftToSniper(order.tokenType, order.tokenAddress, order.tokenId, order.to);
        emit SnipeSuccessful(order.tokenAddress, order.tokenId, order.to);
    }

    /**
    ** @notice deposit Ether into the contract. 
    ** @param sniper is the address who's balance is affected.
    */
    function deposit(address sniper) public payable {
        sniperBalances[sniper] += msg.value;
    }

    /**
    ** @notice deposit Ether into your own contract balance.
    */
    function depositSelf() external payable {
        deposit(msg.sender);
    }

    /**
    ** @notice withdraw Ether from your contract balance
    ** @param amount the amount of Ether to be withdrawn 
    */
    function withdraw(uint256 amount) external {
        if (sniperBalances[msg.sender] < amount) revert InsufficientBalance();
        unchecked { sniperBalances[msg.sender] -= amount; }
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedToWithdraw();
    }

    /**
    ** @notice set up a marketplace allowlist.
    ** @param guardEnabled if false then marketplace allowlist will not be checked for this user
    ** @param marketplaceAllowed boolean indicating whether the marketplace is allowed or not
    */
    function setUserAllowedMarketplaces(bool guardEnabled, bool marketplaceAllowed, address[] calldata marketplaces) external {
        sniperGuardrails[msg.sender].marketplaceGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < marketplaces.length;) {
            sniperGuardrails[msg.sender].allowedMarketplaces[marketplaces[i]] = marketplaceAllowed;
            unchecked { ++i; }
        }
    }

    /**
    ** @notice Set up a maximum tip guardrail (in wei). If set to 0, guardrail will be disabled.
    */
    function setUserMaxTip(uint256 maxTipInWei) external {
        if (maxTipInWei < minimumTip && maxTipInWei != 0) revert TipBelowMinimum();
        sniperGuardrails[msg.sender].maxTip = maxTipInWei;
    }

    /**
    ** @notice set up NFT contract allowlist
    ** @param guardEnabled if false then NFT contract allowlist will not be checked for this user
    ** @param nftAllowed boolean indicating whether the NFT contract is allowed or not
    */
    function setUserAllowedNfts(bool guardEnabled, bool nftAllowed, address[] calldata nfts) external {
        sniperGuardrails[msg.sender].nftContractGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < nfts.length;) {
            sniperGuardrails[msg.sender].allowedNftContracts[nfts[i]] = nftAllowed;
            unchecked { ++i; }
        }
    }

    /**
    ** @notice Owner function to set up global marketplace allowlist.
    */
    function configureMarket(address marketplace, bool status) external onlyOwner {
        allowedMarketplaces[marketplace] = status;
    }

    /**
    ** @notice Owner function to change fulfiller address if needed.
    */
    function setFulfillerAddress(address _fulfiller) external onlyOwner {
        FULFILLER_ADDRESS = _fulfiller;
    }

    /**
    ** @notice Owner function to change minimum tip amount (minimum tip should
    ** always be approximately enough to cover gas, which is paid by the fulfiller)
    */
    function setMinimumTip(uint256 tip) external onlyOwner {
        minimumTip = tip;
    }

    // getters to simplify web3js calls
    function marketplaceApprovedBySniper(address sniper, address marketplace) external view returns (bool) {
        return sniperGuardrails[sniper].allowedMarketplaces[marketplace];
    }

    function nftContractApprovedBySniper(address sniper, address nftContract) external view returns (bool) {
        return sniperGuardrails[sniper].allowedNftContracts[nftContract];
    }

    // internal helpers
    function _swapWeth(uint256 wethAmount, address sniper) private onlyFulfiller {
        IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        weth.transferFrom(sniper, address(this), wethAmount);
        weth.withdraw(wethAmount);

        unchecked { sniperBalances[sniper] += wethAmount; }
    }

    function _transferNftToSniper(ItemType tokenType, address tokenAddress, uint256 tokenId, address sniper) private {
        if (tokenType == ItemType.ERC721) {
            IERC721(tokenAddress).transferFrom(address(this), sniper, tokenId);
        } else if (tokenType == ItemType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(address(this), sniper, tokenId, 1, "");
        } else if (tokenType == ItemType.CRYPTOPUNKS) {
            IPunk(tokenAddress).transferPunk(sniper, tokenId);
        }
    }

    function _checkSniperGuardrails(address tokenAddress, address marketplace, uint256 tip, address sniper) private view {
        SniperGuardrails storage guardrails = sniperGuardrails[sniper];

        if (guardrails.maxTip > 0 && tip > guardrails.maxTip) revert MaxTipExceeded();
        if (guardrails.marketplaceGuardEnabled && !guardrails.allowedMarketplaces[marketplace]) revert MarketplaceNotAllowed();
        if (guardrails.nftContractGuardEnabled && !guardrails.allowedNftContracts[tokenAddress]) revert TokenContractNotAllowed();
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external {
        IERC20 token = IERC20(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }

    modifier onlyFulfiller() {
        if (msg.sender != FULFILLER_ADDRESS) revert CallerNotFulfiller();
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IPunk {
  function transferPunk(address to, uint punkIndex) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IWETH {
  function transferFrom(address src, address dst, uint wad) external;
  function deposit() external payable;
  function withdraw(uint wad) external;
  function balanceOf(address user) external view returns (uint256);
  function approve(address guy, uint wad) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// from Seaport
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA,

    // 6: CryptoPunks
    CRYPTOPUNKS
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./SniperEnums.sol";

struct SniperOrder {
    address to;
    address marketplace;
    uint256 value;
    uint256 tip;
    ItemType tokenType;
    bytes data;
    address tokenAddress;
    uint256 tokenId;
}

struct SniperGuardrails {
    bool marketplaceGuardEnabled;
    bool nftContractGuardEnabled;
    mapping(address => bool) allowedMarketplaces;
    mapping(address => bool) allowedNftContracts;
    uint256 maxTip;
}