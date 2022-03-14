// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFYC is IERC721 {
    function totalSupply() external view returns(uint256 number);
    function getTierNumberOf(uint256 _tokenId) external view returns(uint8 tierNumber);
    function getTierPrice(uint8 tierNumber) external view returns(uint256 tierPrice);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address roalityReceiver, uint256 royaltyAmount);
    function setRoality(address receiver, uint96 feeNumerator) external;
}

contract Leasing is Ownable {
    event ApproveLeasing(uint tokenId);

    IFYC _nft;
    uint8 private _refundPercentFee = 98;

    struct LeaseOffer {
        address from;
        uint256 price;
        uint32 expiresIn;
    }
    mapping (uint256 => LeaseOffer) private _lease;
    mapping(uint256 => mapping(address => bool)) _offerState;
    mapping (uint256 => LeaseOffer[]) leaseOffers;
    mapping (uint256 => bool) leasable;
    uint256 leasableTokenCount = 0;
    mapping (uint256 => uint256) leasePrices;
    
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == address(_nft.ownerOf(_tokenId)), "caller is not the owner of token");
        _;
    }

    function getNFTAddress() external view returns(address) {
        return address(_nft);
    }

    function setNFTAddress(address nft_address) external onlyOwner {
        _nft = IFYC(nft_address);
    }

    function withDraw() external onlyOwner {
        address payable tgt = payable(owner());
        (bool success1, ) = tgt.call{value:address(this).balance}("");
        require(success1, "Failed to Withdraw VET");
    }

    function getRoalityInfo(uint256 _tokenId, uint256 _salePrice) public view returns(address, uint256) {
        (address roalityReceiver, uint256 royaltyAmount) = _nft.royaltyInfo(_tokenId, _salePrice);

        return (roalityReceiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points.
     */
    function setRoality(address receiver, uint96 feeNumerator) external onlyOwner {
        _nft.setRoality(receiver, feeNumerator);
    }

    function getRefundFee() external view returns(uint8) {
        return _refundPercentFee;
    }

    function setRefundFee(uint8 fee) external onlyOwner {
        require(fee > 0 && fee <100, "Invalied percentage value");
        _refundPercentFee = fee;
    }

    function getLeasable(uint256 _tokenId) external view returns(bool) {
        if(leasable[_tokenId]) return true;
        else return false;
    }

    function setLeasable(uint256 _tokenId, uint256 _price) external onlyOwnerOf(_tokenId) {
        leasable[_tokenId] = true;
        leasePrices[_tokenId] = _price;
        leasableTokenCount++;
    }

    function getLeasePrice(uint256 _tokenId) external view returns(uint256) {
        return leasePrices[_tokenId];
    }

    function setLeasePrice(uint256 _tokenId, uint256 _price) external onlyOwnerOf(_tokenId) {
        leasePrices[_tokenId] = _price;
    }

    function getLeaseOffers(uint256 _tokenId) external view onlyOwnerOf(_tokenId) returns(LeaseOffer[] memory) {
        return leaseOffers[_tokenId];
    }

    function approveLeaseOffer(uint256 _tokenId, address _from) external onlyOwnerOf(_tokenId) {
        LeaseOffer[] memory tokenLeaseOffers = leaseOffers[_tokenId];

        for(uint256 i = 0; i < tokenLeaseOffers.length; i++) {
            if(tokenLeaseOffers[i].from == _from) {
                (address royaltyReceiver, uint256 roaltyAmount) = getRoalityInfo(_tokenId, tokenLeaseOffers[i].price);
                address payable _royaltyReceiver = payable(royaltyReceiver);
                (bool success1, ) = _royaltyReceiver.call{ value: roaltyAmount }("");
                require(success1, "Failed to Pay Royalty fee");
                _lease[_tokenId] = tokenLeaseOffers[i];
                delete leaseOffers[_tokenId][i];

                emit ApproveLeasing(_tokenId);
                break;
            }
        }
        _offerState[_tokenId][_from] = false;
        leasableTokenCount--;
    }

    function calcenLeaseOffer(uint256 _tokenId) external {
        require(_nft.ownerOf(_tokenId) != msg.sender, "You can't buy yours.");
        require(_nft.ownerOf(_tokenId) != address(0), "You can't send offer no-owner token");
        LeaseOffer[] memory tokenLeaseOffers = leaseOffers[_tokenId];

        for(uint256 i = 0; i < tokenLeaseOffers.length; i++) {
            if(tokenLeaseOffers[i].from == msg.sender) {
                (bool success1, ) = msg.sender.call{ value: tokenLeaseOffers[i].price * _refundPercentFee / 100 }("");
                require(success1, "Failed to refund");
                delete leaseOffers[_tokenId][i];

                emit ApproveLeasing(_tokenId);
                break;
            }
        }

        _offerState[_tokenId][msg.sender] = false;
    }

    function getLeasableTokens() external view returns(uint256[] memory) {
        uint256[] memory leasableTokenIds = new uint256[](leasableTokenCount);

        uint256 counter = 0;
        for(uint256 i = 1; i <= _nft.totalSupply(); i++) {
            if (leasable[i]) {
                leasableTokenIds[counter] = i;
                counter++;
            }
        }

        return leasableTokenIds;
    }

    function sendLeaseOffer(uint256 _tokenId, uint32 _expiresIn) public payable {
        require(_nft.ownerOf(_tokenId) != msg.sender, "You can't buy yours.");
        require(_nft.ownerOf(_tokenId) != address(0), "You can't send offer no-owner token");
        require(msg.value >= _nft.getTierPrice(_nft.getTierNumberOf(_tokenId)) / 10, "Amount of ether sent not correct.");
        require(_expiresIn >= 30, "The minimum to lease the membership is 30 days.");
        require(_offerState[_tokenId][msg.sender] != true, "You can't send mutli offer");
        leaseOffers[_tokenId].push(LeaseOffer(msg.sender, msg.value, _expiresIn));
        _offerState[_tokenId][msg.sender] = true;
    }

    function lease(uint256 _tokenId, uint32 _expiresIn) external payable {
        require(_nft.ownerOf(_tokenId) != msg.sender, "You can't buy yours.");
        require(leasable[_tokenId], "Token is not public");
        require(_nft.ownerOf(_tokenId) != address(0), "You can't send offer no-owner token");
        require(msg.value >= leasePrices[_tokenId], "Amount of ether sent not enough.");

        (address royaltyReceiver, uint256 roaltyAmount) = getRoalityInfo(_tokenId, msg.value);
        address payable _royaltyReceiver = payable(royaltyReceiver);
        (bool success1, ) = _royaltyReceiver.call{ value: roaltyAmount }("");
        require(success1, "Failed to Pay Royalty fee");

        _lease[_tokenId] = LeaseOffer(msg.sender, msg.value, _expiresIn);
        leasable[_tokenId] = false;
        leasableTokenCount--;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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