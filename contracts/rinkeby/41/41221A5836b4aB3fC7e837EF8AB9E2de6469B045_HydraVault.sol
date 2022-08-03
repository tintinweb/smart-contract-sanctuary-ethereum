// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// Contract @title Hydra Bundle Vault
/// Contract @author Stinky (@nomamesgwei)
/// Description @dev: Pluto Pawn is an unadited prototype in development by Degen Dwarfs, DYOR before using.
/// Version: 0.69

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { Bundle } from "./Structs/Bundle.sol";
import  { IHydraTicket } from "./Interfaces/IHydraTicket.sol";

contract HydraVault is Ownable, ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    /// @dev beneficiary address
    address private beneficiary;
    /// @dev Bundle Ticket Contract
    address private ticketContract;
    /// @dev Degen Dwarf Contract
    address private dwarfContract;    
    /// @notice Custody fee Amount
    uint256 public custodyFee;
    /// @notice Counter for number of bundles
    Counters.Counter public bundleCounter;
    /// @notice Bundle protocol on/off switch
    bool public bundleOpen;
    /// @notice Bundle tracker
    mapping(uint256 => Bundle) public bundles;

    bytes4 private constant INTERFACE_ERC71155 = 0xd9b67a26;
    bytes4 private constant INTERFACE_ERC721 = 0x80ac58cd;

    error InactiveBundle();
    error InvalidBundle();
    error InvalidCustodyFee();    
    error BundlingNotOpen();
    error NotAuthorized();
    error NotBundleOwner();

    /// @dev Declare Bundle Created Event
    event Bundled(
        uint256 _bundleId,
        address _lender
    );

    /// @dev Declare Bundle Destroyed Event
    event UnBundled(
        uint256 _bundleId,
        address _lender
    );

    /// @dev For ERC-1155 Receiver
    event Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    /// @dev Updated Protocol Value
    event UpdatedValue(
        bytes14 changeType,
        uint256 oldValue,
        uint256 newValue
    );

    /// @notice Construct the Bundles Contract
    /// @param benefic Beneficiary Address
    /// @param dwarf Degen Dwarf Address    
    constructor(address benefic, address dwarf) {
        beneficiary = benefic;
        bundleOpen = true;
        custodyFee = 0.0001 ether;
        dwarfContract = dwarf;
    }

    /// @notice Create a Bundle for Batch PlutoPawn
    /// @dev nfts and tokenIds index must match up
    /// @param nft Address of NFT Collection
    /// @param nftIds ID Array of the NFT IDs
    function createBundle(
        address nft,
        uint256[] calldata nftIds
    ) external payable nonReentrant {
        if(!bundleOpen){revert BundlingNotOpen();}

        uint256 tokenCount = nftIds.length;

        //Check if you are a Dwarf Holder, if so you can bundle more
        if(IERC721(dwarfContract).balanceOf(_msgSender()) > 0) {
            if(tokenCount > 5) { revert InvalidBundle(); }
        } else {
            if(tokenCount > 3) { revert InvalidBundle(); }
        }

        uint256 bundleID = bundleCounter.current();
        Bundle storage newBundle = bundles[bundleID];
        newBundle.id = bundleID;
        newBundle.bundledDate = block.timestamp;
        newBundle.isActive = true;
        newBundle.creator = _msgSender();        
        newBundle.nft = nft;
        newBundle.nftIds = nftIds;

        _transferCollaterals(_msgSender(), address(this),  nft,  nftIds);        
        IHydraTicket(ticketContract).issue(bundleID, _msgSender());
        bundleCounter.increment();
                
        emit Bundled(bundleID, _msgSender());
    }
    
    /// @notice Only the Pawn Ticket NFT holder can call this
    /// @dev Burn ticket NFT and transfer the collateral NFT
    /// @param bundleId Bundle ID #
    function unBundle(uint256 bundleId) external payable nonReentrant {
        address pawnTicketOwner = IHydraTicket(ticketContract).ownerOf(bundleId);
        // Only the Pawn Ticket NFT Holder can call for the appropriate Bundle
        if(pawnTicketOwner != _msgSender()) { revert NotBundleOwner(); }
        Bundle memory myBundle = bundles[bundleId];
        if(!myBundle.isActive) { revert InactiveBundle(); }

        // If liquidation fee is greater than 0 then the fee is active
        if (custodyFee > 0) {
            if (msg.value != custodyFee) revert InvalidCustodyFee();
            payable(beneficiary).transfer(msg.value);
        }

        // Burn the Pawn Ticket NFT
        IHydraTicket(ticketContract).redeem(bundleId, pawnTicketOwner);
        // Transfer Collateral to Pawn Ticket Burner
        _transferCollaterals(address(this), pawnTicketOwner,  myBundle.nft,  myBundle.nftIds);
        // Bundle is no longer active
        bundles[bundleId].isActive = false;

        emit UnBundled(bundleId, _msgSender());
    }

    /// @notice Set Custody fee
    /// @param fee Protocol Fee paid for Custody
    function setFees(uint256 fee) external onlyOwner {
        emit UpdatedValue("FEE", custodyFee, fee);        
        custodyFee = fee;
    }

    /// @notice Toggles the bundling status from on/off
    function togglBundelingOpen() external onlyOwner {
        if(bundleOpen)
            emit UpdatedValue("STATUS", 1, 0);
        else
            emit UpdatedValue("STATUS", 0, 1);
        bundleOpen = !bundleOpen;
    }

    /// @notice Upgrade Hydra Ticket contracts
    /// @param newTicket Address of new PawnTicket NFT contract
    function upgradeContracts(
        address newTicket
    ) external onlyOwner {
        ticketContract = newTicket;
    }

    ///@notice In the event user UnBundling fails, and team needs to assist 
    ///@dev This is sent to the beneficiary, Dwarf team can then send this to the necessary party
    ///@param bundleId Bundle ID #  
    function backupUnBundle(uint256 bundleId) external nonReentrant onlyOwner {
        Bundle memory stuckBundle = bundles[bundleId];
        _transferCollaterals(address(this), beneficiary,  stuckBundle.nft,  stuckBundle.nftIds);
        IHydraTicket(ticketContract).redeem(bundleId, _msgSender());     
        bundles[bundleId].isActive = false;            
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // required function to allow receiving ERC-1155
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external pure
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }  

    /// @notice Transfers ERC721 or ERC115 standard tokens
    /// @param sender Who is sending the Token
    /// @param receiver Who will receive the Token
    /// @param nft NFT Token Address
    /// @param tokenIds NFT Token Id
    function _transferCollaterals(address sender, address receiver, address nft, uint256[] memory tokenIds) internal returns(bool) {
        uint256 tokenCount = tokenIds.length;       

        // Check if interface supports 721 standard
        if(IERC721(nft).supportsInterface(INTERFACE_ERC721)) {
            for(uint i; i < tokenCount;) {
                IERC721(nft).safeTransferFrom(sender,  receiver, tokenIds[i]);
                unchecked { i++; }                  
            }
            return true;
        }         

        // Check if interface supports 1155 standard
        if(ERC165(nft).supportsInterface(INTERFACE_ERC71155)) {
            for(uint i; i < tokenCount;) {
                IERC1155(nft).safeTransferFrom(sender, receiver, tokenIds[i], 1, "");
                unchecked { i++; }            
            }
            return true;            
        } 

        return false;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Bundle {
    // Bundle #ID
    uint256 id;
    // Bundle Date
    uint256 bundledDate;
    // Bundle creator Address
    address creator;
    // Status
    bool isActive;
    // NFT Collection
    address nft;
    // NFT IDs
    uint256[] nftIds;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IHydraTicket {
    /// @notice a new bundle is created, issue NFT ticket
    /// @param id Bundle id
    /// @param bundler Bundlers Address
    function issue(uint256 id, address bundler) external;

    ///@notice NFT ticket holder can redeem the Bundles contents
    ///@dev tokenSupply is only used to track the number of active Hydra Tickets
    ///@param id Bundle id
    ///@param bundler Bundlers Address
    function redeem(uint256 id, address bundler) external;

    ///@notice Gets the current NFT Supply
    function totalSupply() external;

    ///@notice Returns the baseURI
    ///@dev Metadata is base64 encoded (on-chain metadata)
    ///@param tokenId the token id you are trying to retrieve the tokenURI for
    function tokenURI(uint256 tokenId) external;

    /// @notice Returns the owner of specific token
    /// @dev Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address owner);
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