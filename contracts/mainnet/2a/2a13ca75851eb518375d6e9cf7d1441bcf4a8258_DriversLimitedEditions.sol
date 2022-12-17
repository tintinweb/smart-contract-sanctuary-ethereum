// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized and flexible operator filterer to abide to OpenSea's
/// mandatory on-chain royalty enforcement in order for new collections to
/// receive royalties.
/// For more information, see:
/// See: https://github.com/ProjectOpenSea/operator-filter-registry
abstract contract OperatorFilterer {
    /// @dev The default OpenSea operator blocklist subscription.
    address internal constant _DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev The OpenSea operator filter registry.
    address internal constant _OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev Registers the current contract to OpenSea's operator filter,
    /// and subscribe to the default OpenSea operator blocklist.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering() internal virtual {
        _registerForOperatorFiltering(_DEFAULT_SUBSCRIPTION, true);
    }

    /// @dev Registers the current contract to OpenSea's operator filter.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            let functionSelector := 0x7d3e3dbe // `registerAndSubscribe(address,address)`.

            // Clean the upper 96 bits of `subscriptionOrRegistrantToCopy` in case they are dirty.
            subscriptionOrRegistrantToCopy := shr(96, shl(96, subscriptionOrRegistrantToCopy))

            for {} iszero(subscribe) {} {
                if iszero(subscriptionOrRegistrantToCopy) {
                    functionSelector := 0x4420e486 // `register(address)`.
                    break
                }
                functionSelector := 0xa0af2903 // `registerAndCopyEntries(address,address)`.
                break
            }
            // Store the function selector.
            mstore(0x00, shl(224, functionSelector))
            // Store the `address(this)`.
            mstore(0x04, address())
            // Store the `subscriptionOrRegistrantToCopy`.
            mstore(0x24, subscriptionOrRegistrantToCopy)
            // Register into the registry.
            if iszero(call(gas(), _OPERATOR_FILTER_REGISTRY, 0, 0x00, 0x44, 0x00, 0x04)) {
                // If the function selector has not been overwritten,
                // it is an out-of-gas error.
                if eq(shr(224, mload(0x00)), functionSelector) {
                    // To prevent gas under-estimation.
                    revert(0, 0)
                }
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, because of Solidity's memory size limits.
            mstore(0x24, 0)
        }
    }

    /// @dev Modifier to guard a function and revert if the caller is a blocked operator.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            if (!_isPriorityOperator(msg.sender)) {
                if (_operatorFilteringEnabled()) _revertIfBlocked(msg.sender);
            }
        }
        _;
    }

    /// @dev Modifier to guard a function from approving a blocked operator..
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (!_isPriorityOperator(operator)) {
            if (_operatorFilteringEnabled()) _revertIfBlocked(operator);
        }
        _;
    }

    /// @dev Helper function that reverts if the `operator` is blocked by the registry.
    function _revertIfBlocked(address operator) private view {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `isOperatorAllowed(address,address)`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xc6171134001122334455)
            // Store the `address(this)`.
            mstore(0x1a, address())
            // Store the `operator`.
            mstore(0x3a, operator)

            // `isOperatorAllowed` always returns true if it does not revert.
            if iszero(staticcall(gas(), _OPERATOR_FILTER_REGISTRY, 0x16, 0x44, 0x00, 0x00)) {
                // Bubble up the revert if the staticcall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // We'll skip checking if `from` is inside the blacklist.
            // Even though that can block transferring out of wrapper contracts,
            // we don't want tokens to be stuck.

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev For deriving contracts to override, so that operator filtering
    /// can be turned on / off.
    /// Returns true by default.
    function _operatorFilteringEnabled() internal view virtual returns (bool) {
        return true;
    }

    /// @dev For deriving contracts to override, so that preferred marketplaces can
    /// skip operator filtering, helping users save gas.
    /// Returns false for all inputs by default.
    function _isPriorityOperator(address) internal view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Simple owner and admin authentication
 * @notice Allows the management of a contract by using simple ownership and admin modifiers.
 */
abstract contract Auth {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Current owner of the contract
    address public owner;

    /// @notice Current admins of the contract
    mapping(address => bool) public admins;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract owner is updated
     * @param user The account that updated the new owner
     * @param newOwner The new owner of the contract
     */
    event OwnerUpdated(address indexed user, address indexed newOwner);

    /**
     * @notice When an admin is added to the contract
     * @param user The account that added the new admin
     * @param newAdmin The admin that was added
     */
    event AdminAdded(address indexed user, address indexed newAdmin);

    /**
     * @notice When an admin is removed from the contract
     * @param user The account that removed an admin
     * @param prevAdmin The admin that got removed
     */
    event AdminRemoved(address indexed user, address indexed prevAdmin);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Only the owner can call
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only an admin can call
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only the owner or an admin can call
     */
    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner || admins[msg.sender]), "UNAUTHORIZED");
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Sets the initial owner and a first admin upon creation.
     * @param owner_ The initial owner of the contract
     * @param admin_ An initial admin of the contract
     */
    constructor(address owner_, address admin_) {
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);

        admins[admin_] = true;
        emit AdminAdded(address(0), admin_);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Transfers ownership of the contract to `newOwner`
     * @dev Can only be called by the current owner or an admin
     * @param newOwner The new owner of the contract
     */
    function setOwner(address newOwner) public virtual onlyOwnerOrAdmin {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @notice Adds `newAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param newAdmin A new admin of the contract
     */
    function addAdmin(address newAdmin) public virtual onlyOwnerOrAdmin {
        admins[newAdmin] = true;
        emit AdminAdded(address(0), newAdmin);
    }

    /**
     * @notice Removes `prevAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param prevAdmin The admin to remove
     */
    function removeAdmin(address prevAdmin) public virtual onlyOwnerOrAdmin {
        admins[prevAdmin] = false;
        emit AdminRemoved(address(0), prevAdmin);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC1155/IERC1155.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Fount Gallery Card Check
 * @notice Utility functions to check ownership of a Fount Gallery Patron Card NFT
 */
contract FountCardCheck {
    /// @dev Address of the Fount Gallery Patron Card contract
    IERC1155 internal _fountCard;

    /// @dev Does not own a Fount Gallery Patron Card
    error NotFountCardHolder();

    /**
     * @dev Does not own enough Fount Gallery Patron Cards
     * @param required The minimum amount of cards that need to be owned
     * @param owned The actualy amount of cards owned
     */
    error DoesNotHoldEnoughFountCards(uint256 required, uint256 owned);

    /**
     * @dev Init with the Fount Gallery Patron Card contract address
     * @param fountCard The Fount Gallery Patron Card contract address
     */
    constructor(address fountCard) {
        _fountCard = IERC1155(fountCard);
    }

    /**
     * @dev Modifier that only allows the caller to do something if they hold
     * a Fount Gallery Patron Card
     */
    modifier onlyWhenFountCardHolder() {
        if (_getFountCardBalance(msg.sender) < 1) revert NotFountCardHolder();
        _;
    }

    /**
     * @dev Modifier that only allows the caller to do something if they hold
     * at least a specific amount Fount Gallery Patron Cards
     * @param minAmount The minimum amount of cards that need to be owned
     */
    modifier onlyWhenHoldingMinFountCards(uint256 minAmount) {
        uint256 balance = _getFountCardBalance(msg.sender);
        if (minAmount > balance) revert DoesNotHoldEnoughFountCards(minAmount, balance);
        _;
    }

    /**
     * @dev Get the number of Fount Gallery Patron Cards an address owns
     * @param owner The owner address to query
     * @return balance The balance of the owner
     */
    function _getFountCardBalance(address owner) internal view returns (uint256 balance) {
        balance = _fountCard.balanceOf(owner, 1);
    }

    /**
     * @dev Check if an address holds at least one Fount Gallery Patron Card
     * @param owner The owner address to query
     * @return isHolder If the owner holds at least one card
     */
    function _isFountCardHolder(address owner) internal view returns (bool isHolder) {
        isHolder = _getFountCardBalance(owner) > 0;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Swappable metadata module
 * @notice Allows the use of a separate and swappable metadata contract
 */
abstract contract SwappableMetadata {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Address of metadata contract
    address public metadata;

    /// @notice Flag for whether the metadata address can be updated or not
    bool public isMetadataLocked;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error MetadataLocked();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @dev When the metadata contract has been set
     * @param metadataContract The new metadata contract address
     */
    event MetadataContractSet(address indexed metadataContract);

    /**
     * @dev When the metadata contract has been locked and is no longer swappable
     * @param metadataContract The final locked metadata contract address
     */
    event MetadataContractLocked(address indexed metadataContract);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param metadata_ The address of the initial metadata contract
     */
    constructor(address metadata_) {
        metadata = metadata_;
        emit MetadataContractSet(metadata_);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Sets the metadata address
     * @param metadata_ The new address of the metadata contract
     */
    function _setMetadataAddress(address metadata_) internal {
        if (isMetadataLocked) revert MetadataLocked();
        metadata = metadata_;
        emit MetadataContractSet(metadata_);
    }

    /**
     * @notice Sets the metadata address
     * @param metadata The new address of the metadata contract
     */
    function setMetadataAddress(address metadata) public virtual;

    /**
     * @dev Locks the metadata address preventing further updates
     */
    function _lockMetadata() internal {
        isMetadataLocked = true;
        emit MetadataContractLocked(metadata);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/interfaces/IERC2981.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Royalty payments
 * @notice Support for the royalty standard (ERC-2981)
 */
abstract contract Royalties is IERC2981 {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Store information about token royalties
    struct RoyaltyInfo {
        address receiver;
        uint96 amount;
    }

    /// @dev The current royalty information
    RoyaltyInfo internal _royaltyInfo;

    /// @dev Interface id for the royalty information standard
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 internal constant ROYALTY_INTERFACE_ID = 0x2a55205a;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error MoreThanOneHundredPercentRoyalty();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event RoyaltyInfoSet(address indexed receiver, uint256 indexed amount);
    event RoyaltyInfoUpdated(address indexed receiver, uint256 indexed amount);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param royaltiesReceiver The receiver of royalty payments
     * @param royaltiesAmount The royalty percentage with two decimals (10,000 = 100%)
     */
    constructor(address royaltiesReceiver, uint256 royaltiesAmount) {
        _royaltyInfo = RoyaltyInfo(royaltiesReceiver, uint96(royaltiesAmount));
        emit RoyaltyInfoSet(royaltiesReceiver, royaltiesAmount);
    }

    /* ------------------------------------------------------------------------
                                  E R C 2 9 8 1
    ------------------------------------------------------------------------ */

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 100_00;
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @dev Internal function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function _setRoyaltyInfo(address receiver, uint256 amount) internal {
        if (amount > 100_00) revert MoreThanOneHundredPercentRoyalty();
        _royaltyInfo = RoyaltyInfo(receiver, uint24(amount));
        emit RoyaltyInfoUpdated(receiver, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC1155/IERC1155.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Withdraw ETH and tokens module
 * @notice Allows the withdrawal of ETH, ERC20, ERC721, an ERC1155 tokens
 */
abstract contract Withdraw {
    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error CannotWithdrawToZeroAddress();
    error WithdrawFailed();
    error BalanceTooLow();
    error ZeroBalance();

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    function _withdrawETH(address to) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check there is eth to withdraw
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();

        // Transfer funds
        (bool success, ) = payable(to).call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function _withdrawToken(address tokenAddress, address to) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check there are tokens to withdraw
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert ZeroBalance();

        // Transfer tokens
        bool success = IERC20(tokenAddress).transfer(to, balance);
        if (!success) revert WithdrawFailed();
    }

    function _withdrawERC721Token(
        address tokenAddress,
        uint256 id,
        address to
    ) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check the NFT is in this contract
        address owner = IERC721(tokenAddress).ownerOf(id);
        if (owner != address(this)) revert ZeroBalance();

        // Transfer NFT
        IERC721(tokenAddress).transferFrom(address(this), to, id);
    }

    function _withdrawERC1155Token(
        address tokenAddress,
        uint256 id,
        uint256 amount,
        address to
    ) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check the tokens are owned by this contract, and there's at least `amount`
        uint256 balance = IERC1155(tokenAddress).balanceOf(address(this), id);
        if (balance == 0) revert ZeroBalance();
        if (amount > balance) revert BalanceTooLow();

        // Transfer tokens
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, id, amount, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

  ##########      ##########      #####   #####    #####   ############   ##########        ##########
  ############    ############    #####   #####    #####   ############   ############     ############
  #####   #####   #####  ######   #####   #####    #####   ############   #####  ######   ######  ######
  #####   #####   #####   #####   #####   #####    #####   #####          #####   #####   ######  ######
  #####   #####   #####   #####   #####    ####    ####    #####          #####   #####   #######
  #####   #####   #####  #####    #####    ####    ####    ##########     #####  #####     ##########
  #####   #####   ###########     #####    ####    ####    ##########     ###########       ###########
  #####   #####   ############    #####    ####    ####    #####          ############           #######
  #####   #####   #####   #####   #####     ####  ####     #####          #####   #####   ######  ######
  #####   #####   #####   #####   #####     ##########     ############   #####   #####   ######  ######
  ############    #####   #####   #####      ########      ############   #####   #####    ############
  ##########      #####   #####   #####        ####        ############   #####   #####     ##########

  By Everfresh

*/

import "./ERC721Base.sol";
import "fount-contracts/utils/Withdraw.sol";
import "./interfaces/IDriversPayments.sol";

/**
 * @author Fount Gallery
 * @title  Drivers Limited Editions by Everfresh
 * @notice Drivers is celebrated motion artist Everfresh's first Fount Gallery release. Driven by
 * the rhythm of skate culture and dance, the Drivers collection delivers an immersive world of
 * form and flow.
 *
 * Features:
 *   - Mixed 1/1 and limited edition NFTs
 *   - Auctions with "Buy it now" for 1/1 NFTs
 *   - Flexible collecting conditions with EIP-712 signatures or on-chain Fount Card checks
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
contract DriversLimitedEditions is ERC721Base, Withdraw {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Cap for edition sizes. Also used to generate token ids for editions.
    uint256 internal constant MAX_EDITION_SIZE = 1000;

    /// @dev Stores information about a sale for a given token
    struct TokenData {
        uint128 price;
        uint16 editionSize;
        uint16 collected;
        bool fountExclusive;
        bool requiresSig;
        bool freeToCollect;
    }

    /// @dev Mapping of base token id to token data
    mapping(uint256 => TokenData) internal _baseIdToTokenData;

    /// @dev General auction config
    uint256 public auctionTimeBuffer = 5 minutes;
    uint256 public auctionIncPercentage = 10;

    /// @dev Auction config for a specific token auction
    struct AuctionData {
        uint32 duration;
        uint32 startTime;
        uint32 firstBidTime;
        address highestBidder;
        uint128 highestBid;
        uint128 reservePrice;
    }

    /// @dev Mapping of base token id to auction data
    mapping(uint256 => AuctionData) public auctions;

    /// @dev Counter to keep track of active auctions. Prevents withdrawals unless zero.
    uint256 public activeAuctions;

    /// @notice Address where proceeds should be sent
    address public payments;

    /// @dev Toggle to allow collecting
    bool internal _isSaleLive;

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Makes sure that the sale is live before proceeding
     */
    modifier onlyWhenSaleIsLive() {
        if (!_isSaleLive) revert SaleNotLive();
        _;
    }

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    /** TOKEN DATA ---------------------------------------------------------- */
    error TokenDataDoesNotExist();
    error TokenDataAlreadyExists();
    error InvalidBaseId();
    error CannotSetEditionSizeToZero();

    /** SALE CONDITIONS ---------------------------------------------------- */
    error SaleNotLive();
    error RequiresFountCard();
    error RequiresSignature();
    error InvalidSignature();

    /** PURCHASING --------------------------------------------------------- */
    error NotForSale();
    error IncorrectPaymentAmount();

    /** ONE OF ONES -------------------------------------------------------- */
    error NotOneOfOne();

    /** AUCTIONS ----------------------------------------------------------- */
    error AuctionDoesNotExist();
    error AuctionNotStarted();
    error AuctionAlreadyExists();
    error AuctionAlreadyStarted();
    error AuctionReserveNotMet(uint256 reserve, uint256 sent);
    error AuctionMinimumBidNotMet(uint256 minBid, uint256 sent);
    error AuctionNotEnded();
    error AuctionEnded();
    error AuctionAlreadySettled();
    error AlreadySold();
    error CannotSetAuctionDurationToZero();
    error CannotSetAuctionStartTimeToZero();
    error CannotSetAuctionReservePriceToZero();
    error CannotWithdrawWithActiveAuctions();

    /** EDITIONS ----------------------------------------------------------- */
    error NotEdition();
    error EditionSoldOut();
    error EditionSizeLessThanCurrentlySold();
    error EditionSizeExceedsMaxValue();

    /** PAYMENTS ----------------------------------------------------------- */
    error CannotSetPaymentAddressToZero();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event TokenDataAdded(uint256 indexed id, TokenData tokenData);
    event TokenDataSalePriceUpdated(uint256 indexed id, TokenData tokenData);
    event TokenDataSaleConditionsUpdated(uint256 indexed id, TokenData tokenData);

    event AuctionCreated(uint256 indexed id, AuctionData auction);
    event AuctionBid(uint256 indexed id, AuctionData auction);
    event AuctionSettled(uint256 indexed id, AuctionData auction);
    event AuctionSoldEarly(uint256 indexed id, AuctionData auction);
    event AuctionCancelled(uint256 indexed id);

    event AuctionDurationUpdated(uint256 indexed id, uint256 indexed duration);
    event AuctionStartTimeUpdated(uint256 indexed id, uint256 indexed startTime);
    event AuctionReservePriceUpdated(uint256 indexed id, uint256 indexed reservePrice);

    event CollectedOneOfOne(uint256 indexed id);
    event CollectedEdition(
        uint256 indexed baseId,
        uint256 indexed editionNumber,
        uint256 indexed tokenId
    );

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param payments_ The address where payments should be sent
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     * @param fountCard_ The address of the Fount Gallery Patron Card
     */
    constructor(
        address owner_,
        address admin_,
        address payments_,
        uint256 royaltiesAmount_,
        address metadata_,
        address fountCard_
    ) ERC721Base(owner_, admin_, payments_, royaltiesAmount_, metadata_, fountCard_) {
        payments = payments_;
    }

    /* ------------------------------------------------------------------------
       O N E   O F   O N E S
    ------------------------------------------------------------------------ */

    /** BUY NOW ------------------------------------------------------------ */

    /**
     * @notice Collects a 1/1 NFT that's available for sale
     * @dev Calls internal `_collectOneOfOne` for additional logic and minting.
     *
     * Reverts if:
     *  - the sale requires an off-chain signature
     *  - see `_collectOneOfOne` for other conditions
     *
     * @param baseId The base id of the token to collect
     * @param to The address to collect the token to
     */
    function collectOneOfOne(uint256 baseId, address to) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig) revert RequiresSignature();
        _collectOneOfOne(baseId, to, tokenData);
    }

    /**
     * @notice Collects a 1/1 NFT that's available for sale using an off-chain signature
     * @dev Calls internal `_collectOneOfOne` for additional logic and minting.
     *
     * Reverts if:
     *  - the signature provided is not valid
     *  - see `_collectOneOfOne` for other conditions
     *
     * @param baseId The base id of the token to collect
     * @param to The address to collect the token to
     * @param signature The off-chain signature that permits a mint
     */
    function collectOneOfOne(
        uint256 baseId,
        address to,
        bytes calldata signature
    ) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig && !_verifyMintSignature(baseId, to, signature)) {
            revert InvalidSignature();
        }
        _collectOneOfOne(baseId, to, tokenData);
    }

    /**
     * @notice Internal logic for minting 1/1 NFTs
     * @dev Handles collecting a 1/1 when there's also an active auction e.g. "Buy it now"
     *
     * Reverts if:
     *  - the token is not a 1/1
     *  - msg.value does not equal the required amount
     *  - the token requires a Fount Card, but `to` does not hold one
     *  - the token has already been minted
     *
     * @param baseId The base id of the token to collect
     * @param to The address to collect the token to
     * @param tokenData Information about the token
     */
    function _collectOneOfOne(
        uint256 baseId,
        address to,
        TokenData memory tokenData
    ) internal {
        if (tokenData.editionSize != 1) revert NotOneOfOne();
        if (!tokenData.freeToCollect && tokenData.price == 0) revert NotForSale();
        if (tokenData.price != msg.value) revert IncorrectPaymentAmount();
        if (tokenData.fountExclusive && !_isFountCardHolder(to)) revert RequiresFountCard();

        // If there is an auction for this token and it has bids,
        // then refund the highest bidder, and end the auction early.
        AuctionData memory auction = auctions[baseId];
        if (auction.firstBidTime > 0) {
            // End the auction by setting the duration to "end" at the current block timestamp.
            // This will prevent new bids on the auction since it will revert with `AuctionEnded`.
            auction.duration = uint32(block.timestamp - auction.firstBidTime);
            auctions[baseId] = auction;

            // Refund the highest bidder
            _transferETHWithFallback(auction.highestBidder, auction.highestBid);

            // Decrease the active auctions count
            unchecked {
                --activeAuctions;
            }

            emit AuctionSoldEarly(baseId, auction);
        }

        // Record the mint in the token data
        unchecked {
            ++tokenData.collected;
        }
        _baseIdToTokenData[baseId] = tokenData;

        // Transfer the NFT from Everfresh to the `to` address
        _transferFromArtist(to, baseId);
        emit CollectedOneOfOne(baseId);
    }

    /** AUCTION BIDS ------------------------------------------------------- */

    /**
     * @notice Places a bid for a token
     * @dev Calls internal `_placeBid` function for logic.
     *
     * Reverts if:
     *   - the token requires an off-chain signature
     *   - see `_placeBid` for other conditions
     *
     * @param baseId The base id of the token to register a bid for
     */
    function placeBid(uint256 baseId) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig) revert RequiresSignature();
        _placeBid(baseId, tokenData);
    }

    /**
     * @notice Places a bid for a token with an off-chain signature
     * @dev Calls internal `_placeBid` function for logic.
     *
     * Reverts if:
     *   - the token requires an off-chain signature and the signature is invalid
     *   - see `_placeBid` for other conditions
     *
     * @param baseId The base id of the token to register a bid for
     * @param signature The off-chain signature that permits a mint
     */
    function placeBid(uint256 baseId, bytes calldata signature)
        external
        payable
        onlyWhenSaleIsLive
    {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig && !_verifyMintSignature(baseId, msg.sender, signature)) {
            revert InvalidSignature();
        }
        _placeBid(baseId, tokenData);
    }

    /**
     * @notice Internal function to place a bid for a token
     * @dev Takes the amount of ETH sent as the bid. If the bid is the new highest bid,
     * then the previous highest bidder is refunded (in WETH if the refund fails with ETH).
     * If a bid is placed within the auction time buffer then the buffer is added to the
     * time remaining on the auction e.g. extends by 5 minutes.
     *
     * Reverts if:
     *   - the token requires a Fount Card, but msg.sender does not hold one
     *   - the auction has not yet started
     *   - the auction has ended
     *   - the auction reserve bid has not been met if it's the first bid
     *   - the bid does not meet the minimum (increment percentage of current highest bid)
     *
     * @param baseId The base id of the token to register a bid for
     * @param tokenData Information about the token
     */
    function _placeBid(uint256 baseId, TokenData memory tokenData) internal {
        // Check msg.sender qualifies to bid
        if (tokenData.fountExclusive && !_isFountCardHolder(msg.sender)) revert RequiresFountCard();

        // Load the auction
        AuctionData memory auction = auctions[baseId];

        // Check auction is ready to accept bids
        if (auction.startTime == 0 || auction.startTime > block.timestamp) {
            revert AuctionNotStarted();
        }

        // If first bid, start the auction
        if (auction.firstBidTime == 0) {
            // Check the first bid meets the reserve
            if (auction.reservePrice > msg.value) {
                revert AuctionReserveNotMet(auction.reservePrice, msg.value);
            }

            // Save the bid time
            auction.firstBidTime = uint32(block.timestamp);
        } else {
            // Check it hasn't ended
            if (block.timestamp > (auction.firstBidTime + auction.duration)) revert AuctionEnded();

            // Check the value sent meets the minimum price increase
            uint256 highestBid = auction.highestBid;
            uint256 minBid;
            unchecked {
                minBid = highestBid + ((highestBid * auctionIncPercentage) / 100);
            }
            if (minBid > msg.value) revert AuctionMinimumBidNotMet(minBid, msg.value);

            // Refund the previous highest bid
            _transferETHWithFallback(auction.highestBidder, highestBid);
        }

        // Save the new highest bid and bidder
        auction.highestBid = uint96(msg.value);
        auction.highestBidder = msg.sender;

        // Calculate the time remaining
        uint256 timeRemaining;
        unchecked {
            timeRemaining = auction.firstBidTime + auction.duration - block.timestamp;
        }

        // If bid is placed within the time buffer of the auction ending, increase the duration
        if (timeRemaining < auctionTimeBuffer) {
            unchecked {
                auction.duration += uint32(auctionTimeBuffer - timeRemaining);
            }
        }

        // Save the new auction data
        auctions[baseId] = auction;

        // Emit event
        emit AuctionBid(baseId, auction);
    }

    /** AUCTION SETTLEMENT ------------------------------------------------- */

    /**
     * @notice Allows the winner to settle the auction which mints of their new NFT
     * @dev Mints the NFT to the highest bidder (winner) only once the auction is over.
     * Can be called by anyone so Fount Gallery can pay the gas if needed.
     *
     * Reverts if:
     *   - the auction hasn't started yet
     *   - the auction is not over
     *   - the token has already been sold via `collectOneOfOne`
     *
     * @param baseId The base id of token to settle the auction for
     */
    function settleAuction(uint256 baseId) external {
        AuctionData memory auction = auctions[baseId];

        // Check auction has started
        if (auction.firstBidTime == 0) revert AuctionNotStarted();

        // Check auction has ended
        if (auction.firstBidTime + auction.duration > block.timestamp) revert AuctionNotEnded();

        // Transfer the NFT to the highest bidder
        if (_ownerOf[baseId] != everfresh) revert AlreadySold();
        _transferFromArtist(auction.highestBidder, baseId);
        emit CollectedOneOfOne(baseId);

        // Decrease the active auctions count
        unchecked {
            --activeAuctions;
        }

        // Emit event
        emit AuctionSettled(baseId, auction);
    }

    /* ------------------------------------------------------------------------
       L I M I T E D   E D I T I O N S
    ------------------------------------------------------------------------ */

    /**
     * @notice Mints the next edition of a limited edition NFT
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature
     *  - see `_collectEdition` for other conditions
     *
     * @param baseId The base NFT id of the edition
     * @param to The address to mint the token to
     */
    function collectEdition(uint256 baseId, address to) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig) revert RequiresSignature();
        _collectEdition(baseId, to, tokenData);
    }

    /**
     * @notice Mints the next edition of a limited edition NFT with an off-chain signature
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature and the signature is invalid
     *  - see `_collectEdition` for other conditions
     *
     * @param baseId The base NFT id of the edition
     * @param to The address to mint the token to
     * @param signature The off-chain signature which permits a mint
     */
    function collectEdition(
        uint256 baseId,
        address to,
        bytes calldata signature
    ) external payable onlyWhenSaleIsLive {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.requiresSig && !_verifyMintSignature(baseId, to, signature)) {
            revert InvalidSignature();
        }
        _collectEdition(baseId, to, tokenData);
    }

    /**
     * @notice Internal function to collect the next edition with some conditions
     * @dev Allows collecting to a different address from msg.sender.
     *
     * Reverts if:
     *  - the token is not an edition
     *  - the edition is sold out
     *  - msg.value does not equal the required amount
     *  - the edition requires a Fount Card, but `to` does not hold one
     *
     * @param baseId The base NFT id of the edition
     * @param to The address to collect the token to
     * @param tokenData Information about the token
     */
    function _collectEdition(
        uint256 baseId,
        address to,
        TokenData memory tokenData
    ) internal {
        // Check to see if the next edition is collectable and the price is correct
        if (tokenData.editionSize < 2) revert NotEdition();
        if (tokenData.collected + 1 > tokenData.editionSize) revert EditionSoldOut();
        if (!tokenData.freeToCollect && tokenData.price == 0) revert NotForSale();
        if (tokenData.price != msg.value) revert IncorrectPaymentAmount();

        // Check if it's a Fount Gallery exclusive
        if (tokenData.fountExclusive && !_isFountCardHolder(to)) revert RequiresFountCard();

        // Get the next edition number and token id
        uint256 editionNumber = tokenData.collected + 1;
        uint256 tokenId = _getEditionTokenId(baseId, editionNumber);

        // Add the new mint to the token data
        unchecked {
            ++tokenData.collected;
        }
        _baseIdToTokenData[baseId] = tokenData;

        // Transfer the NFT from Everfresh to the `to` address
        _transferFromArtist(to, tokenId);
        emit CollectedEdition(baseId, editionNumber, tokenId);
    }

    /** UTILS -------------------------------------------------------------- */

    /**
     * @notice Internal function to get the token id for an edition
     * @param baseId The base NFT id of the edition
     * @param editionNumber The edition number to make the token id for
     * @return tokenId The token id for the edition
     */
    function _getEditionTokenId(uint256 baseId, uint256 editionNumber)
        internal
        pure
        returns (uint256)
    {
        return baseId * MAX_EDITION_SIZE + editionNumber;
    }

    /**
     * @notice Get the token id for a specific edition number
     * @param baseId The base NFT id of the edition
     * @param editionNumber The edition number to make the token id for
     * @return tokenId The token id for the edition
     */
    function getEditionTokenId(uint256 baseId, uint256 editionNumber)
        external
        pure
        returns (uint256)
    {
        return _getEditionTokenId(baseId, editionNumber);
    }

    /**
     * @notice Get the edition number from a token id
     * @dev Returns `0` if it's not an edition
     * @param tokenId The token id for the edition
     * @return editionNumber The edition number e.g. 2 of 10
     */
    function getEditionNumberFromTokenId(uint256 tokenId) external pure returns (uint256) {
        if (tokenId >= MAX_EDITION_SIZE) return 0;
        return tokenId % MAX_EDITION_SIZE;
    }

    /**
     * @notice Get the base NFT id from a token id
     * @dev Returns the token id argument if it's not an edition
     * @param tokenId The token id for the edition
     * @return baseId The base NFT id e.g. 2 from "2004"
     */
    function getEditionBaseIdFromTokenId(uint256 tokenId) external pure returns (uint256) {
        if (tokenId >= MAX_EDITION_SIZE) return tokenId;
        return tokenId / MAX_EDITION_SIZE;
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /** ADD TOKEN DATA ----------------------------------------------------- */

    /**
     * @notice Admin function to make a token available for sale
     * @dev As soon as the token data is registered, the NFT will be available to collect provided
     * a price has been set. This prevents auctions without a "buy it now" price from being
     * purchased for free unintentionally.
     *
     * If a free mint is intended, set `price` to zero and `freeMint` to true.
     *
     * Reverts if:
     *  - the edition size exeeds the max allowed value (`MAX_EDITION_SIZE`)
     *  - the token data already exists (to update token data, use the other admin
     *    functions to set price and sale conditions)
     *
     * @param baseId The base NFT id
     * @param price The sale price (buy it now for auctions)
     * @param editionSize The size of the edition. Set to 1 for one of one NFTs.
     * @param fountExclusive If the sale requires a Fount Gallery Patron card
     * @param requiresSig If the sale requires an off-chain signature
     * @param freeMint If the sale requires an off-chain signature
     */
    function addTokenForSale(
        uint256 baseId,
        uint128 price,
        uint16 editionSize,
        bool fountExclusive,
        bool requiresSig,
        bool freeMint
    ) external onlyOwnerOrAdmin {
        // Check the baseId is valid
        if (baseId > type(uint256).max / MAX_EDITION_SIZE) revert InvalidBaseId();

        // Check a valid edition size has been used
        if (editionSize == 0) revert CannotSetEditionSizeToZero();

        // Check the edition size does not exceed the max
        if (editionSize > MAX_EDITION_SIZE - 1) revert EditionSizeExceedsMaxValue();

        TokenData memory tokenData = _baseIdToTokenData[baseId];

        // Check the token data is empty before adding
        if (tokenData.editionSize != 0) revert TokenDataAlreadyExists();

        // Set the new token data
        tokenData.price = price;
        tokenData.editionSize = editionSize;
        tokenData.fountExclusive = fountExclusive;
        tokenData.requiresSig = requiresSig;
        tokenData.freeToCollect = freeMint;
        _baseIdToTokenData[baseId] = tokenData;
        emit TokenDataAdded(baseId, tokenData);

        // Mint to Everfresh
        if (editionSize == 1) {
            _mint(everfresh, baseId);
        } else {
            for (uint256 i = 0; i < editionSize; i++) {
                _mint(everfresh, _getEditionTokenId(baseId, i + 1));
            }
        }
    }

    /** SET SALE PRICE ----------------------------------------------------- */

    /**
     * @notice Admin function to update the sale price for a token
     * @dev Reverts if the token data does not exist. Must be added with `addTokenForSale` first.
     * @param baseId The base NFT id
     * @param price The new sale price
     * @param freeMint If the NFT can be minted for free
     */
    function setTokenSalePrice(
        uint256 baseId,
        uint128 price,
        bool freeMint
    ) external onlyOwnerOrAdmin {
        TokenData memory tokenData = _baseIdToTokenData[baseId];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.editionSize == 0) revert TokenDataDoesNotExist();

        // Set the new sale price
        tokenData.price = price;
        tokenData.freeToCollect = freeMint;
        _baseIdToTokenData[baseId] = tokenData;
        emit TokenDataSalePriceUpdated(baseId, tokenData);
    }

    /** SET SALE CONDITIONS ------------------------------------------------ */

    /**
     * @notice Admin function to update the sale conditions for a token
     * @dev Reverts if the token data does not exist. Must be added with `addTokenForSale` first.
     * @param baseId The base NFT id
     * @param fountExclusive If the sale requires a Fount Gallery Patron card
     * @param requiresSig If the sale requires an off-chain signature
     */
    function setTokenSaleConditions(
        uint256 baseId,
        bool fountExclusive,
        bool requiresSig
    ) external onlyOwnerOrAdmin {
        TokenData memory tokenData = _baseIdToTokenData[baseId];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.editionSize == 0) revert TokenDataDoesNotExist();

        tokenData.fountExclusive = fountExclusive;
        tokenData.requiresSig = requiresSig;
        _baseIdToTokenData[baseId] = tokenData;
        emit TokenDataSaleConditionsUpdated(baseId, tokenData);
    }

    /** AUCTION CREATION --------------------------------------------------- */

    /**
     * @notice Admin function to create an auction for a 1/1
     * @dev Can only create auctions for 1/1 NFTs, not editions.
     *
     * Reverts if:
     *  - the token is not a 1/1
     *  - the auction already exists
     *
     * @param baseId The base NFT id
     */
    function createAuction(
        uint256 baseId,
        uint32 duration,
        uint32 startTime,
        uint128 reservePrice
    ) external onlyOwnerOrAdmin {
        if (duration == 0) revert CannotSetAuctionDurationToZero();
        if (startTime == 0) revert CannotSetAuctionStartTimeToZero();

        // Check if the token data exists and it's a 1/1
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        if (tokenData.editionSize != 1) revert NotOneOfOne();

        // Load the auction data
        AuctionData memory auction = auctions[baseId];

        // Check there's no auction already
        if (auction.startTime > 0) revert AuctionAlreadyExists();

        // Create the auction data
        auction.duration = duration;
        auction.startTime = startTime;
        auction.reservePrice = reservePrice;
        auctions[baseId] = auction;

        // Increment active auctions counter
        unchecked {
            ++activeAuctions;
        }

        // Emit created event
        emit AuctionCreated(baseId, auction);
    }

    /** AUCTION CANCELLATION ----------------------------------------------- */

    /**
     * @notice Admin function to cancel an auction
     * @dev Calls internal `_cancelAuction` for logic.
     * @param baseId The base NFT id
     */
    function cancelAuction(uint256 baseId) external onlyOwnerOrAdmin {
        AuctionData memory auction = auctions[baseId];
        _cancelAuction(baseId, auction);
    }

    /**
     * @notice Internal function for cancelling an auction
     * @dev Cancels the auction by refunding the highest bid and deleting the data
     *
     * Reverts if:
     *  - the auctions has ended (in case it hasn't been settled yet)
     *
     * @param baseId The base NFT id
     * @param auction The auction data to determine conditions and refunds
     */
    function _cancelAuction(uint256 baseId, AuctionData memory auction) internal {
        if (auction.firstBidTime > 0) {
            // Prevent cancelling if the auction has ended in case it hasn't been settled yet
            if (block.timestamp > (auction.firstBidTime + auction.duration)) revert AuctionEnded();
            // Refund the highest bidder
            _transferETHWithFallback(auction.highestBidder, auction.highestBid);
        }

        // Delete the auction data and reduce the active auction count
        delete auctions[baseId];
        unchecked {
            --activeAuctions;
        }

        emit AuctionCancelled(baseId);
    }

    /** AUCTION DURATION --------------------------------------------------- */

    /**
     * @notice Admin function to set the duration of a specific auction
     * @dev Emits an `AuctionDurationUpdated` event if successful
     *
     * Reverts if:
     *  - `duration` is zero
     *  - the auction does not exist
     *  - the auction already has bids
     *
     * @param baseId The base NFT id
     * @param duration The new auction duration
     */
    function setAuctionDuration(uint256 baseId, uint32 duration) external onlyOwnerOrAdmin {
        if (duration == 0) revert CannotSetAuctionDurationToZero();

        AuctionData memory auction = auctions[baseId];
        if (auction.startTime == 0) revert AuctionDoesNotExist();
        if (auction.firstBidTime > 0) revert AuctionAlreadyStarted();

        auction.duration = duration;
        auctions[baseId] = auction;
        emit AuctionDurationUpdated(baseId, duration);
    }

    /** AUCTION START TIME ------------------------------------------------- */

    /**
     * @notice Admin function to set the start time of a specific auction
     * @dev Emits an `AuctionStartTimeUpdated` event if successful
     *
     * Reverts if:
     *  - `startTime` is zero
     *  - the auction does not exist
     *  - the auction already has bids
     *
     * @param baseId The base NFT id
     * @param startTime The new auction start time
     */
    function setAuctionStartTime(uint256 baseId, uint32 startTime) external onlyOwnerOrAdmin {
        if (startTime == 0) revert CannotSetAuctionStartTimeToZero();

        AuctionData memory auction = auctions[baseId];
        if (auction.startTime == 0) revert AuctionDoesNotExist();
        if (auction.firstBidTime > 0) revert AuctionAlreadyStarted();

        auction.startTime = startTime;
        auctions[baseId] = auction;
        emit AuctionStartTimeUpdated(baseId, startTime);
    }

    /** AUCTION RESERVE PRICE ---------------------------------------------- */

    /**
     * @notice Admin function to set the reserve price of a specific auction
     * @dev Emits an `AuctionReservePriceUpdated` event if successful
     *
     * Reverts if:
     *  - `reservePrice` is zero
     *  - the auction does not exist
     *  - the auction already has bids
     *
     * @param baseId The base NFT id
     * @param reservePrice The new auction start time
     */
    function setAuctionReservePrice(uint256 baseId, uint128 reservePrice)
        external
        onlyOwnerOrAdmin
    {
        if (reservePrice == 0) revert CannotSetAuctionReservePriceToZero();

        AuctionData memory auction = auctions[baseId];
        if (auction.startTime == 0) revert AuctionDoesNotExist();
        if (auction.firstBidTime > 0) revert AuctionAlreadyStarted();

        auction.reservePrice = reservePrice;
        auctions[baseId] = auction;
        emit AuctionReservePriceUpdated(baseId, reservePrice);
    }

    /** TAKE SALE LIVE ----------------------------------------------------- */

    /**
     * @notice Admin function to set the sale live state
     * @dev If set to false, then collecting will be paused.
     * @param isLive Whether the sale is live or not
     */
    function setSaleLiveState(bool isLive) external onlyOwnerOrAdmin {
        _isSaleLive = isLive;
    }

    /** PAYMENTS ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the payment address for withdrawing funds
     * @param paymentAddress The new address where payments should be sent upon withdrawal
     */
    function setPaymentAddress(address paymentAddress) external onlyOwnerOrAdmin {
        if (paymentAddress == address(0)) revert CannotSetPaymentAddressToZero();
        payments = paymentAddress;
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    function tokenPrice(uint256 baseId) external view returns (uint256) {
        return _baseIdToTokenData[baseId].price;
    }

    function tokenIsOneOfOne(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].editionSize == 1;
    }

    function tokenIsEdition(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].editionSize > 1;
    }

    function tokenEditionSize(uint256 baseId) external view returns (uint256) {
        return _baseIdToTokenData[baseId].editionSize;
    }

    function tokenCollectedCount(uint256 baseId) external view returns (uint256) {
        return _baseIdToTokenData[baseId].collected;
    }

    function tokenIsFountExclusive(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].fountExclusive;
    }

    function tokenRequiresOffChainSignatureToCollect(uint256 baseId) external view returns (bool) {
        return _baseIdToTokenData[baseId].requiresSig;
    }

    function tokenIsFreeToCollect(uint256 baseId) external view returns (bool) {
        TokenData memory tokenData = _baseIdToTokenData[baseId];
        return tokenData.price == 0 && tokenData.freeToCollect;
    }

    function auctionHasStarted(uint256 baseId) external view returns (bool) {
        return auctions[baseId].firstBidTime > 0;
    }

    function auctionStartTime(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].startTime;
    }

    function auctionHasEnded(uint256 baseId) external view returns (bool) {
        AuctionData memory auction = auctions[baseId];
        bool hasStarted = auctions[baseId].firstBidTime > 0;
        return hasStarted && block.timestamp >= auction.firstBidTime + auction.duration;
    }

    function auctionEndTime(uint256 baseId) external view returns (uint256) {
        AuctionData memory auction = auctions[baseId];
        bool hasStarted = auctions[baseId].firstBidTime > 0;
        return hasStarted ? auction.startTime + auction.duration : 0;
    }

    function auctionDuration(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].duration;
    }

    function auctionFirstBidTime(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].firstBidTime;
    }

    function auctionHighestBidder(uint256 baseId) external view returns (address) {
        return auctions[baseId].highestBidder;
    }

    function auctionHighestBid(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].highestBid;
    }

    function auctionReservePrice(uint256 baseId) external view returns (uint256) {
        return auctions[baseId].reservePrice;
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw ETH from this contract
     * @dev Withdraws to the `payments` address.
     *
     * Reverts if:
     *  - there are active auctions
     *  - the payments address is set to zero
     *
     */
    function withdrawETH() public onlyOwnerOrAdmin {
        // Check there are no active auctions
        if (activeAuctions > 0) revert CannotWithdrawWithActiveAuctions();
        // Send the eth to the payments address
        _withdrawETH(payments);
    }

    /**
     * @notice Admin function to withdraw ETH from this contract and release from payments contract
     * @dev Withdraws to the `payments` address, then calls `releaseAllETH` as a splitter.
     *
     * Reverts if:
     *  - there are active auctions
     *  - the payments address is set to zero
     *
     */
    function withdrawAndReleaseAllETH() public onlyOwnerOrAdmin {
        // Check there are no active auctions
        if (activeAuctions > 0) revert CannotWithdrawWithActiveAuctions();
        // Send the eth to the payments address
        _withdrawETH(payments);
        // And then release all the ETH to the payees
        IDriversPayments(payments).releaseAllETH();
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @dev Withdraws to the `payments` address.
     *
     * Reverts if:
     *  - the payments address is set to zero
     *
     */
    function withdrawTokens(address tokenAddress) public onlyOwnerOrAdmin {
        // Send the tokens to the payments address
        _withdrawToken(tokenAddress, payments);
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @param to The address to send the ERC-20 tokens to
     */
    function withdrawTokens(address tokenAddress, address to) public onlyOwnerOrAdmin {
        _withdrawToken(tokenAddress, to);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "solmate/tokens/ERC721.sol";
import "fount-contracts/auth/Auth.sol";
import "fount-contracts/community/FountCardCheck.sol";
import "fount-contracts/extensions/SwappableMetadata.sol";
import "fount-contracts/utils/Royalties.sol";
import "closedsea/OperatorFilterer.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/cryptography/EIP712.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IWETH.sol";

/**
 * @author Fount Gallery
 * @title  ERC721Base
 * @notice Base contract for Drivers Limited Editions to inherit from
 *
 * Features:
 *   - EIP-712 signature minting and verification
 *   - On-chain checking of Fount Gallery Patron cards for minting
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 *   - Safe transferring of ETH with WETH fallback
 */
abstract contract ERC721Base is
    ERC721,
    Auth,
    FountCardCheck,
    SwappableMetadata,
    Royalties,
    EIP712,
    OperatorFilterer
{
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice everfresh.eth
    address public everfresh = 0xBb3444a06E9928dDA9a739CdAb3E0c5cf6890099;

    /// @notice Contract information
    string public contractURI;

    /// @notice EIP-712 signing domain
    string public constant SIGNING_DOMAIN = "DriversLimitedEditions";

    /// @notice EIP-712 signature version
    string public constant SIGNATURE_VERSION = "1";

    /// @notice EIP-712 signed data type hash for minting with an off-chain signature
    bytes32 public constant MINT_SIGNATURE_TYPEHASH =
        keccak256("MintSignatureData(uint256 id,address to,uint256 nonce)");

    /// @dev EIP-712 signed data struct for minting with an off-chain signature
    struct MintSignatureData {
        uint256 id;
        address to;
        uint256 nonce;
        bytes signature;
    }

    /// @notice Approved signer public addresses
    mapping(address => bool) public approvedSigners;

    /// @notice Nonce management to avoid signature replay attacks
    mapping(address => uint256) public nonces;

    /// @notice If operator filtering is applied
    bool public operatorFilteringEnabled;

    /// @notice Wrapped ETH contract address for safe ETH transfer fallbacks
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event Init();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param royaltiesReceiver_ The address where royalties should be sent
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     * @param fountCard_ The address of the Fount Gallery Patron Card
     */
    constructor(
        address owner_,
        address admin_,
        address royaltiesReceiver_,
        uint256 royaltiesAmount_,
        address metadata_,
        address fountCard_
    )
        ERC721("Drivers Limited Editions by Everfresh", "DRIVERS")
        Auth(owner_, admin_)
        FountCardCheck(fountCard_)
        SwappableMetadata(metadata_)
        Royalties(royaltiesReceiver_, royaltiesAmount_)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        emit Init();
    }

    /* ------------------------------------------------------------------------
       A R T I S T   M I N T I N G
    ------------------------------------------------------------------------ */

    function _transferFromArtist(address to, uint256 id) internal {
        require(everfresh == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[everfresh]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        delete getApproved[id];

        emit Transfer(everfresh, to, id);
    }

    /* ------------------------------------------------------------------------
       S I G N A T U R E   V E R I F I C A T I O N
    ------------------------------------------------------------------------ */

    /**
     * @notice Internal function to verify an EIP-712 minting signature
     * @param id The base NFT id
     * @param to The account that has approval to mint
     * @param signature The EIP-712 signature
     * @return bool If the signature is verified or not
     */
    function _verifyMintSignature(
        uint256 id,
        address to,
        bytes calldata signature
    ) internal returns (bool) {
        MintSignatureData memory data = MintSignatureData({
            id: id,
            to: to,
            nonce: nonces[to],
            signature: signature
        });

        // Hash the data for verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINT_SIGNATURE_TYPEHASH, data.id, data.to, nonces[data.to]++))
        );

        // Verifiy signature is ok
        address addr = ECDSA.recover(digest, data.signature);
        return approvedSigners[addr] && addr != address(0);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /** SIGNERS ------------------------------------------------------------ */

    /**
     * @notice Admin function to set an EIP-712 signer address
     * @param signer The address of the new signer
     * @param approved If the signer is approved
     */
    function setSigner(address signer, bool approved) external onlyOwnerOrAdmin {
        approvedSigners[signer] = approved;
    }

    /** METADATA ----------------------------------------------------------- */

    /**
     * @notice Admin function to set the metadata contract address
     * @param metadata The new metadata contract address
     */
    function setMetadataAddress(address metadata) public override onlyOwnerOrAdmin {
        _setMetadataAddress(metadata);
    }

    /**
     * @notice Admin function to set the contract URI for marketplaces
     * @param contractURI_ The new contract URI
     */
    function setContractURI(string memory contractURI_) external onlyOwnerOrAdmin {
        contractURI = contractURI_;
    }

    /** ROYALTIES ---------------------------------------------------------- */

    /**
     * @notice Admin function to set the royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10,000 = 100%)
     */
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyOwnerOrAdmin {
        _setRoyaltyInfo(receiver, amount);
    }

    /**
     * @notice Admin function to set whether OpenSea's Operator Filtering should be enabled
     * @param enabled If the operator filtering should be enabled
     */
    function setOperatorFilteringEnabled(bool enabled) external onlyOwnerOrAdmin {
        operatorFilteringEnabled = enabled;
    }

    function registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        external
        onlyOwnerOrAdmin
    {
        _registerForOperatorFiltering(subscriptionOrRegistrantToCopy, subscribe);
    }

    /* ------------------------------------------------------------------------
       S A F E   T R A N S F E R S
    ------------------------------------------------------------------------ */

    /**
     * @notice Safely transfer ETH by wrapping as WETH if the ETH transfer fails
     * @param to The address to transfer ETH/WETH to
     * @param amount The amount of ETH/WETH to transfer
     */
    function _transferETHWithFallback(address to, uint256 amount) internal {
        if (!_transferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @param to The address to transfer ETH to
     * @param amount The amount of ETH to transfer
     */
    function _transferETH(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}(new bytes(0));
        return success;
    }

    /* ------------------------------------------------------------------------
       R O T A L T I E S
    ------------------------------------------------------------------------ */

    /**
     * @notice Add interface for on-chain royalty standard
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == ROYALTY_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Repeats the OpenSea Operator Filtering registration
     */
    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    /**
     * @notice Override ERC-721 `setApprovalForAll` to support OpenSea Operator Filtering
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override ERC-721 `approve` to support OpenSea Operator Filtering
     */
    function approve(address operator, uint256 id)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, id);
    }

    /**
     * @notice Override ERC-721 `transferFrom` to support OpenSea Operator Filtering
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, id);
    }

    /**
     * @notice Override ERC-721 `safeTransferFrom` to support OpenSea Operator Filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id);
    }

    /**
     * @notice Override ERC-721 `safeTransferFrom` to support OpenSea Operator Filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, data);
    }

    /**
     * @dev Overrde `OperatorFilterer._operatorFilteringEnabled` to return whether
     * the operator filtering is enabled in this contract.
     */
    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    /* ------------------------------------------------------------------------
       E R C 7 2 1
    ------------------------------------------------------------------------ */

    /**
     * @notice Returns the token metadata
     * @return id The token id to get metadata for
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return IMetadata(metadata).tokenURI(id);
    }

    /**
     * @notice Burn a token. You can only burn tokens you own.
     * @param id The token id to burn
     */
    function burn(uint256 id) external {
        require(ownerOf(id) == msg.sender, "NOT_OWNER");
        _burn(id);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IDriversPayments {
    function releaseAllETH() external;

    function releaseAllToken(address tokenAddress) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}