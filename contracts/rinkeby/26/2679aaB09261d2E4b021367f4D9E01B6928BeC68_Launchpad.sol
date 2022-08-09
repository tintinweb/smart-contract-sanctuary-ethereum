// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../erc721/ILaunchpadERC721.sol";

contract Launchpad is Ownable, ReentrancyGuard {
    event AddCampaign(
        address contractAddress,
        address payeeAddress,
        uint256 price,
        uint256 maxSupply,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 maxBatch,
        uint256 maxPerAddress
    );
    event UpdateCampaign(
        address contractAddress,
        address payeeAddress,
        uint256 price,
        uint256 maxSupply,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 maxBatch,
        uint256 maxPerAddress
    );
    event Mint(
        address indexed contractAddress,
        address payeeAddress,
        uint256 size,
        uint256 price
    );

    struct Campaign {
        address contractAddress;
        address payeeAddress;
        uint256 price; // wei
        uint256 maxSupply;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 maxBatch;
        uint256 maxPerAddress;
    }

    mapping(address => Campaign) private _campaigns;
    mapping(address => mapping(address => uint256)) private _mintPerAddress;

    function mint(address contractAddress, uint256 batchSize)
        external
        payable
        nonReentrant
    {
        // basic check
        require(
            contractAddress != address(0),
            "contract address can not be empty"
        );
        require(batchSize > 0, "batchSize must greater than 0");
        require(
            _campaigns[contractAddress].contractAddress != address(0),
            "contract not register"
        );

        // activity check
        Campaign memory campaign = _campaigns[contractAddress];
        require(batchSize <= campaign.maxBatch, "reach max batch size");
        require(block.timestamp >= campaign.listingTime, "activity not start");
        require(block.timestamp < campaign.expirationTime, "activity ended");
        require(
            _mintPerAddress[contractAddress][msg.sender] + batchSize <=
                campaign.maxPerAddress,
            "reach max per address limit"
        );
        // NFT contract must impl ERC721Enumerable to have this totalSupply method
        uint256 currentSupply = ILaunchpadERC721(contractAddress)
            .getLaunchpadSupply();
        require(
            currentSupply + batchSize <= campaign.maxSupply,
            "reach campaign max supply"
        );
        uint256 totalPrice = campaign.price * batchSize;
        require(msg.value >= totalPrice, "value not enough");

        // update record
        _mintPerAddress[contractAddress][msg.sender] =
            _mintPerAddress[contractAddress][msg.sender] +
            batchSize;

        // transfer token and mint
        payable(campaign.payeeAddress).transfer(totalPrice);
        ILaunchpadERC721(contractAddress).mintTo(msg.sender, batchSize);

        emit Mint(
            campaign.contractAddress,
            campaign.payeeAddress,
            batchSize,
            campaign.price
        );
        // return
        uint256 valueLeft = msg.value - totalPrice;
        if (valueLeft > 0) {
            payable(_msgSender()).transfer(valueLeft);
        }
    }

    function getMintPerAddress(address contractAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        require(
            _campaigns[contractAddress].contractAddress != address(0),
            "contract address invalid"
        );
        require(userAddress != address(0), "user address invalid");
        return _mintPerAddress[contractAddress][userAddress];
    }

    function getLaunchpadMaxSupply(address contractAddress)
        external
        view
        returns (uint256)
    {
        return ILaunchpadERC721(contractAddress).getMaxLaunchpadSupply();
    }

    function getLaunchpadSupply(address contractAddress)
        external
        view
        returns (uint256)
    {
        return ILaunchpadERC721(contractAddress).getLaunchpadSupply();
    }

    function addCampaign(
        address contractAddress_,
        address payeeAddress_,
        uint256 price_,
        uint256 listingTime_,
        uint256 expirationTime_,
        uint256 maxBatch_,
        uint256 maxPerAddress_
    ) external onlyOwner {
        require(
            contractAddress_ != address(0),
            "contract address can not be empty"
        );
        require(
            _campaigns[contractAddress_].contractAddress == address(0),
            "contract address already exist"
        );
        require(payeeAddress_ != address(0), "payee address can not be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can not be 0");
        uint256 maxSupply_ = ILaunchpadERC721(contractAddress_)
            .getMaxLaunchpadSupply();
        require(maxSupply_ > 0, "max supply can not be 0");
        emit AddCampaign(
            contractAddress_,
            payeeAddress_,
            price_,
            maxSupply_,
            listingTime_,
            expirationTime_,
            maxBatch_,
            maxPerAddress_
        );
        _campaigns[contractAddress_] = Campaign(
            contractAddress_,
            payeeAddress_,
            price_,
            maxSupply_,
            listingTime_,
            expirationTime_,
            maxBatch_,
            maxPerAddress_
        );
    }

    function updateCampaign(
        address contractAddress_,
        address payeeAddress_,
        uint256 price_,
        uint256 listingTime_,
        uint256 expirationTime_,
        uint256 maxBatch_,
        uint256 maxPerAddress_
    ) external onlyOwner {
        require(
            contractAddress_ != address(0),
            "contract address can not be empty"
        );
        require(
            _campaigns[contractAddress_].contractAddress != address(0),
            "contract address not exist"
        );
        require(payeeAddress_ != address(0), "payee address can not be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can not be 0");
        uint256 maxSupply_ = ILaunchpadERC721(contractAddress_)
            .getMaxLaunchpadSupply();
        require(maxSupply_ > 0, "max supply can not be 0");
        emit UpdateCampaign(
            contractAddress_,
            payeeAddress_,
            price_,
            maxSupply_,
            listingTime_,
            expirationTime_,
            maxBatch_,
            maxPerAddress_
        );
        _campaigns[contractAddress_] = Campaign(
            contractAddress_,
            payeeAddress_,
            price_,
            maxSupply_,
            listingTime_,
            expirationTime_,
            maxBatch_,
            maxPerAddress_
        );
    }

    function getCampaign(address contractAddress)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Campaign memory a = _campaigns[contractAddress];
        return (
            a.contractAddress,
            a.payeeAddress,
            a.price,
            a.maxSupply,
            a.listingTime,
            a.expirationTime,
            a.maxBatch,
            a.maxPerAddress
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC2981.sol";

interface ILaunchpadERC721 is IERC721, IERC2981 {
    event Received(address, uint256);
    event SplitPortionUpdated(uint16 splitPortion);
    event SplitAddressUpdated(address split);
    event PayeeAddressUpdated(address payee);
    event LaunchpadUpdate(address _launchpad, uint256 _maxSupply);
    event MaxSupplyUpdate(uint256 _maxSupply);

    function updateSplitPortion(uint16 _splitPortion) external;

    function updateSplitAddress(address _split) external;

    function updatePayeeAddress(address _payee) external;

    function updateLaunchpad(address _launchpad, uint256 _maxSupply) external;

    function setBaseURI(string calldata baseURI_) external;

    function withdraw() external;

    function mintTo(address _to, uint256 _size) external;

    function updateMaxSupply(uint256 _maxSupply) external;

    function getMaxLaunchpadSupply() external view returns (uint256);

    function getLaunchpadSupply() external view returns (uint256);

    function launchpadMaxSupply(address _launchpad)
        external
        view
        returns (uint256);

    function launchpadSupply(address _launchpad)
        external
        view
        returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);

    function LAUNCH_SUPPLY() external view returns (uint256);

    function netBalance() external view returns (uint256);

    function split() external view returns (address);

    function splitPortion() external view returns (uint16);

    function payee() external view returns (address);

    function baseURI() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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