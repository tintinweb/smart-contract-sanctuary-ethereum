// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "IERC721Receiver.sol";
import "IERC721.sol";
import "Ownable.sol";

contract AuctionHouse is Ownable {
    
    struct DSEntrySchema {
        bool isOccupied;
        uint tokenId;
        uint price;
        address nftAddress;
        address depositor;
        address buyer;
    }
    mapping (address => bool) public nftAddressWhitelist;
    mapping(bytes32 => DSEntrySchema) public depositStore;
    uint public adminFee;

    event NftTransferredByAdmin(address _to, address _nftAddress, uint _tokenId);
    event NftReceived(address _from, address _nftAddress, uint _tokenId);
    event NftClaimed(address _by, address _nftAddress, uint _tokenId, uint price);

    constructor(uint _adminFee) {
        adminFee = _adminFee;
    }

    /// @notice Setter function for `adminFee`
    /// @dev Imposed 20% max fee limit for security reasons
    function setAdminFee(uint _adminFee) external onlyOwner {
        require(_adminFee <= 20, "Admin Fee can't be higher than 20%");
        adminFee = _adminFee;
    }
    
    /// @notice Function for whitelisting multiple address at the same time
    function whitelistNftAddress(address[] calldata addresses) external onlyOwner {
        for (uint i=0; i < addresses.length; i++) {
            nftAddressWhitelist[addresses[i]] = true;
        }
    }

    /// @notice Function for admin to set buyer and price of nft
    function setBuyerAndPrice(
        uint _tokenId,
        address _nftAddress,
        address _buyer,
        uint _price
    )
        external
        onlyOwner
    {
        bytes32 id = keccak256(abi.encodePacked(_tokenId, _nftAddress));
        DSEntrySchema memory DSEntry = depositStore[id];
        require(DSEntry.isOccupied, "id not found");

        DSEntry.price = _price;
        DSEntry.buyer = _buyer;
        depositStore[id] = DSEntry;
    }

    /// @notice Function used by artist to deposit nft 
    function depositNft(uint _tokenId, address _nftAddress) external {
        IERC721 nft = IERC721(_nftAddress);
        bytes32 id = keccak256(abi.encodePacked(_tokenId, _nftAddress));

        require(
            nftAddressWhitelist[_nftAddress] == true,
            "NFT Address is not on the whitelist"
        );
        require(!depositStore[id].isOccupied, "id already registered");

        // No need to check for ownership before since transferFrom checks that already
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        depositStore[id] = DSEntrySchema(true, _tokenId, 0, _nftAddress, msg.sender, address(0));
        emit NftReceived(msg.sender, _nftAddress, _tokenId);
    }

    /// @notice Function used by buyer to claim nft
    function claimNft(uint _tokenId, address _nftAddress) external payable {
        bytes32 id = keccak256(abi.encodePacked(_tokenId, _nftAddress));
        DSEntrySchema memory DSEntry = depositStore[id];

        require(DSEntry.isOccupied, "id not found");
        require(DSEntry.buyer == msg.sender, "Buyer Address and Txn Sender Address Mismatch");
        require(DSEntry.price == msg.value, "Payment Amount Mismatch");

        distributeAmount(DSEntry.price, payable(DSEntry.depositor));

        delete depositStore[id];

        IERC721(DSEntry.nftAddress).transferFrom(address(this), DSEntry.buyer, DSEntry.tokenId);

        emit NftClaimed(DSEntry.buyer, DSEntry.nftAddress, DSEntry.tokenId, DSEntry.price);
    }

    /// @notice Emergency transfer by owner just in case
    function emergencyTransferNft(uint _tokenId, address _nftAddress, address _to)
        external
        onlyOwner
    {

        bytes32 id = keccak256(abi.encodePacked(_tokenId, _nftAddress));
        DSEntrySchema memory DSEntry = depositStore[id];
        require(DSEntry.isOccupied, "id not found");

        delete depositStore[id];

        IERC721(DSEntry.nftAddress).transferFrom(address(this), _to, DSEntry.tokenId);

        emit NftTransferredByAdmin(_to, DSEntry.nftAddress, DSEntry.tokenId);
    }

    /// @notice Renouncing ownership not allowed for obvious reasons
    function renounceOwnership() public virtual override {
        revert("Renouncing Not Allowed");
    }

    /// @dev Function needed to be able to receive ERC-721 tokens
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes  memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Splits the amount between admin and artist (_nftOwner)
    /// @dev No need for SafeMath with Solidity 0.8.x
    function distributeAmount(uint _amount, address payable _nftOwner) private {
        address payable _admin = payable(owner());

        uint _adminAmount = _amount / 100 * adminFee;
        uint _nftOwnerAmount = _amount - _adminAmount;
        
        _admin.transfer(_adminAmount);
        _nftOwner.transfer(_nftOwnerAmount);
    }

}

// SPDX-License-Identifier: MIT
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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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