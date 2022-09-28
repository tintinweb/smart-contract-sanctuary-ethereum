/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// File: NFT.sol


pragma solidity ^0.8.17;

type NFTHash is bytes32;

/**
 * @dev Struct representing an individual NFT
 */
struct NFT {
    address token;
    uint256 tokenId;
}

/**
 * @dev Creates a hash of an NFT type
 */
function hashNFT(NFT memory nft) pure returns (NFTHash) {
    return NFTHash.wrap(keccak256(abi.encodePacked(nft.token, nft.tokenId)));
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: NFTBorrow.sol


pragma solidity ^0.8.17;





/**
 * Defines an NFT "borrow" contract that holds NFTs for a specified amount of
 * time. The contract owner can always return an NFT to its depositor, and
 * depositors can forcibly take back their NFTs after the hold period is over.
 *
 * Deposits to the contract are done using the callback of a `safeTransferFrom`
 * call to the NFT or by first approving the NFT for use by this contract and
 * making a `deposit` transaction.
 *
 * The contract owner can recover NFTs accidentally sent directly to the
 * contract address but is unable to steal tokens deposited correctly.
 */
contract NFTBorrow is IERC721Receiver, Ownable {
    
    /**
     * @dev Maps individual NFTs to their original depositors, which are the
     * withdrawal destination addresses
     */
    mapping (NFTHash => address) public depositors;
    /**
     * @dev Maps individual NFTs to their unlock times
     */
    mapping (NFTHash => uint256) public unlockTime;
    
    /**
     * @dev Stores the amount of time an NFT is held in the contract before it can be
     * withdrawn
     */
    uint256 public holdPeriod;
    
    /**
     * @dev Emitted when an NFT is deposited to the contract
     * `unlockTime` describes when the contract owner can withdraw the NFTs
     */
    event Deposit(NFT nft, address depositor, uint256 unlockTime);
    
    /**
     * @dev Emitted when an NFT is withdrawn from the contract
     */
    event Withdrawal(NFT nft, address depositor);

    /**
     * @dev Initializes the contract with a specified hold period and the sender
     * as the owner.
     */
    constructor(uint _holdPeriod) {
        setHoldPeriod(_holdPeriod);
    }
    
    // ---------- Public methods ---------- //
    
    /**
     * @dev Sets the hold period for new NFTs, in seconds
     * The owner could frontrun deposits and set an increased hold period using
     * this function, so there is an upper bound to prevent the owner from
     * locking a token forever.
     */
    function setHoldPeriod(uint _holdPeriod) public onlyOwner {
        require(
            _holdPeriod < 36 weeks,
            "Hold period must be shorter than 36 weeks"
        );
        holdPeriod = _holdPeriod;
    }
    
    /**
     * @dev Deposits an NFT using the approve-transferFrom style.
     * Required for NFTs that do not implement safeTransferFrom.
     */
    function deposit(NFT calldata nft) public {
        IERC721(nft.token).transferFrom(msg.sender, address(this), nft.tokenId);
        registerDeposit(nft, msg.sender);
    }
    
    /**
     * @dev Withdraws an NFT to its original owner. May be called either by
     * the owner of the smart contract or the depositor.
     */
    function withdraw(NFT calldata nft, bool safe) public {
        NFTHash nfth = hashNFT(nft);
        address depositor = depositors[nfth];
        require(msg.sender != address(0), "NFT not registered");
        require(msg.sender == depositor || msg.sender == owner(),
            "You must be the NFT depositor or contract owner");
        require(block.timestamp >= unlockTime[nfth] || msg.sender == owner(),
            "You cannot withdraw the NFT yet");
        
        // Unregister NFT
        delete depositors[nfth];
        delete unlockTime[nfth];
        
        // Send the NFT
        transferNFT(nft, depositor, safe);
    }
    
    /**
     * @dev Accepts NFTs and records the deposit. The NFT must have been transferred
     * via the `safeTransferFrom` function or similar that uses a callback.
     *
     * Returns `IERC721Receiver.onERC721Received.selector` if the transfer is accepted.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public virtual override returns (bytes4) {
        // Record owner and unlock time
        NFT memory nft = NFT(msg.sender, tokenId);
        registerDeposit(nft, from);
        
        return this.onERC721Received.selector;
    }
    
    /**
     * @dev Allows for the recovery of an unregistered NFT that did not trigger a
     * deposit via `onERC721Received`.
     */
    function recoverUnregisteredNFT(NFT calldata nft, address dest, bool safe) public onlyOwner {
        // Ensure this NFT has not been registered (or was minted to this address)
        NFTHash nfth = hashNFT(nft);
        require(depositors[nfth] == address(0), "NFT already registered");
        // Transfer to destination
        transferNFT(nft, dest, safe);
    }
    
    /**
     * @dev Convenience function to help with creating keys for the public mappings
     */
    function getNFTHash(NFT calldata nft) public pure returns (NFTHash) {
        return hashNFT(nft);
    }
    
    // ---------- Private methods ---------- //
    
    /**
     * @dev Registers an NFT as having been deposited
     * This method assumes that the NFT depositor's address is verified.
     */
    function registerDeposit(NFT memory nft, address from) private {
        // Prevents a case where the owner recovers an NFT to this contract
        require(from != address(this), "Depositor cannot be this contract");
        NFTHash nfth = hashNFT(nft);
        depositors[nfth] = from;
        unlockTime[nfth] = block.timestamp + holdPeriod;
        
        emit Deposit(nft, depositors[nfth], unlockTime[nfth]);
    }
    
    /**
     * @dev Transfers an NFT from this contract to a destination address
     * This method assumes the operation has already been authorized
     */
    function transferNFT(NFT memory nft, address to, bool safe) private {
        if (safe) {
            IERC721(nft.token).safeTransferFrom(address(this), to, nft.tokenId);
        } else {
            // Unsafe transfer for special NFTs (CryptoKitties) that do not support
            // safeTransferFrom
            // The CryptoKitties contract does not consider the owner to be approved,
            // so we must call the approve function on ourselves
            IERC721(nft.token).approve(address(this), nft.tokenId);
            IERC721(nft.token).transferFrom(address(this), to, nft.tokenId);
        }
        emit Withdrawal(nft, to);
    }
}