// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAgreement.sol";
import "./Agreement.sol";

contract Elastic is Ownable {
    struct NFTData {
        address owner;
        uint256 tokenId;
        address nftAddress;
        uint256 collateral;
        uint256 price;
        bool rented;
        string benefits;
    }

    struct RentedNFT {
        address agreementAddress;
        uint256 rentTime;
        uint256 startTime;
        uint256 collateral;
        uint256 price;
    }

    uint256 public nextItemId = 1; // 0 is reserved for items no longer listed

    mapping(address => uint256[]) public nftsListedByOwner;
    mapping(address => uint256[]) public borrowersNfts;
    mapping(uint256 => bool) public activeItem;
    mapping(address => mapping(uint256 => uint256)) public nftListedToItemId; // itemId = 0 means that the NFT is no longer listed
    mapping(uint256 => NFTData) public items;
    mapping(uint256 => RentedNFT) public rentedItems;

    error AccessDenied(uint256 itemId, address caller);
    error NotOwner(address caller);
    error AlreadyRented();
    error InvalidId();
    error LowAmount(uint256 itemId, uint256 rightAmount, uint256 wrongAmount);
    error NotActive();

    event NFTListed(
        address indexed owner,
        uint256 indexed itemId,
        string tokenURI,
        string indexed benefits,
        string benefitsClearText,
        uint256 collateral,
        uint256 price
    );
    event NFTUnlisted(address indexed owner, uint256 indexed itemId);
    event NFTRented(
        address indexed owner,
        address indexed tenant,
        address agreementAddress,
        address nftAddress,
        uint256 indexed itemId,
        uint256 rentTime,
        uint256 startTime
    );
    event ListedNFTDataModified(
        uint256 indexed itemId,
        // address indexed owner,
        uint256 collateral,
        uint256 price
    );
    event NFTReturned(
        address indexed tenant,
        uint256 indexed itemId,
        uint256 timestamp
    );

    /**
    @notice getItemListByOwner returns the list of item owner by the msg.sender
    @param _owner , address to check 
    */
    function getItemListByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return nftsListedByOwner[_owner];
    }

    function getDataItem(uint256 _item) public view returns (NFTData memory) {
        return items[_item];
    }

    /**
    @notice listNFT allows owner of NFT to list his nft to the marketplace
    @param _nft address of ERC721
    @param _tokenId ERC721's tokenID
    @param _price desire price for the full period
    @param _collateral desire collateral for the NFT
    @param _benefits list of the benifits the listed NFT grant
    */
    function listNFT(
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        uint256 _collateral,
        string calldata _benefits
    ) external {
        if (IERC721(_nft).ownerOf(_tokenId) != msg.sender) {
            revert NotOwner(msg.sender);
        }
        IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);

        // add new item to the marketpalce
        NFTData memory item = NFTData(
            msg.sender,
            _tokenId,
            _nft,
            _collateral,
            _price,
            false,
            _benefits
        );

        nftsListedByOwner[msg.sender].push(nextItemId);
        items[nextItemId] = item;
        activeItem[nextItemId] = true;
        nftListedToItemId[_nft][_tokenId] = nextItemId;

        unchecked {
            nextItemId++;
        }

        emit NFTListed(
            msg.sender,
            nextItemId - 1,
            IERC721Metadata(_nft).tokenURI(_tokenId),
            _benefits,
            _benefits,
            _collateral,
            _price
        );
    }

    /**
    @notice unlistNFT allows owner to unlist not rented NFTs
    @param _itemId ID of the listed NFT
    */
    function unlistNFT(uint256 _itemId) external onlyAuthorized(_itemId) {
        if (items[_itemId].rented) {
            revert AlreadyRented();
        }

        if (items[_itemId].owner == msg.sender) {
            IERC721(items[_itemId].nftAddress).transferFrom(
                address(this),
                msg.sender,
                items[_itemId].tokenId
            );
        }

        uint256 jj;
        for (uint256 ii = 0; ii < nftsListedByOwner[msg.sender].length; ii++) {
            if (nftsListedByOwner[msg.sender][ii] == _itemId) {
                delete nftsListedByOwner[msg.sender][ii];
                jj = ii;
            }
            if (ii > jj) {
                nftsListedByOwner[msg.sender][ii - 1] = nftsListedByOwner[
                    msg.sender
                ][ii];
            }
        }
        nftsListedByOwner[msg.sender].pop();

        address owner = items[_itemId].owner;

        activeItem[_itemId] = false;
        delete nftListedToItemId[items[_itemId].nftAddress][
            items[_itemId].tokenId
        ];
        // delete items[_itemId]; // should be deleted though?

        emit NFTUnlisted(owner, _itemId);
    }

    /**
    @notice modifyListedNFT changes the listed NFT data
    @param _itemId ID of listed NFT
    @param _collateral new value of collateral for the listed NFT
    @param _price new value of renting price for the listed NFT
    */
    function modifyListedNFT(
        uint256 _itemId,
        uint256 _collateral,
        uint256 _price
    ) external {
        if (activeItem[_itemId] == false) {
            revert NotActive();
        }
        if (items[_itemId].owner != msg.sender) {
            revert NotOwner(msg.sender);
        }
        if (items[_itemId].rented) {
            revert AlreadyRented();
        }

        items[_itemId].collateral = _collateral;
        items[_itemId].price = _price;

        emit ListedNFTDataModified(_itemId, _collateral, _price);
    }

    /**
    @notice returnNFT sets the rented field of listed NFT to false
    @param _itemId ID of the listed NFT
    @param _borrower borrower address of the rented NFT
    */
    function returnNFT(uint256 _itemId, address _borrower) external {
        if (rentedItems[_itemId].agreementAddress != msg.sender) {
            revert AccessDenied(_itemId, msg.sender);
        }

        items[_itemId].rented = false;

        uint256 jj;
        for (uint256 ii = 0; ii < borrowersNfts[_borrower].length; ii++) {
            if (borrowersNfts[_borrower][ii] == _itemId) {
                delete borrowersNfts[_borrower][ii];
                jj = ii;
            }
            if (ii > jj) {
                borrowersNfts[_borrower][ii - 1] = borrowersNfts[_borrower][ii];
            }
        }
        borrowersNfts[_borrower].pop();
        delete rentedItems[_itemId];

        emit NFTReturned(_borrower, _itemId, block.timestamp);
    }

    /** 
    @notice rent tenant rent the NFT list on the platform
    @param _itemId id of the listed NFT
    @param _rentTime renting time in seconds
    */
    function rent(uint256 _itemId, uint256 _rentTime)
        external
        payable
        returns (address)
    {
        if (activeItem[_itemId] == false) {
            revert NotActive();
        }
        NFTData storage item = items[_itemId];

        if (item.rented) {
            revert AlreadyRented();
        }
        if (msg.sender == item.owner) {
            revert AccessDenied(_itemId, msg.sender);
        }
        if (msg.value < item.collateral) {
            revert LowAmount(_itemId, item.collateral, msg.value);
        }

        Agreement agreement = new Agreement(
            address(this),
            item.owner,
            msg.sender,
            msg.value,
            _rentTime,
            item.tokenId,
            item.nftAddress,
            item.price,
            block.timestamp,
            _itemId
        );

        // transfer NFT to tenant
        IERC721(items[_itemId].nftAddress).transferFrom(
            address(this),
            msg.sender,
            items[_itemId].tokenId
        );
        payable(address(agreement)).transfer(msg.value);

        item.rented = true;
        borrowersNfts[msg.sender].push(_itemId);
        rentedItems[_itemId] = RentedNFT(
            address(agreement),
            _rentTime,
            block.timestamp,
            item.collateral,
            item.price
        );

        emit NFTRented(
            item.owner,
            msg.sender,
            address(agreement),
            items[_itemId].nftAddress,
            _itemId,
            _rentTime,
            block.timestamp
        );
        return address(agreement);
    }

    modifier onlyAuthorized(uint256 _itemId) {
        if (
            items[_itemId].owner != msg.sender &&
            rentedItems[_itemId].agreementAddress != msg.sender
        ) {
            revert AccessDenied(_itemId, msg.sender);
        }

        _;
    }

    fallback() external payable {}

    receive() external payable {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IAgreement {
    struct AgreementData {
        address owner;
        address borrower;
        uint256 collateral;
        uint256 rentTime;
        uint256 tokenId;
        address nftAddress;
        uint256 proposalId;
        uint256 price;
        uint256 startTime;
        uint256 itemId;
    }

    struct NewAgreementData {
        uint256 collateral;
        uint256 rentTime;
        uint256 price;
        bool ownerAccepted;
        bool borrowerAccepted;
    }

    function readPayment() external view returns (uint256);

    function readAgreementData() external view returns (AgreementData memory);

    function updateAgreementData(
        uint256 _collateral,
        uint256 _rentTime,
        uint256 _price
    ) external;

    function acceptUpdatedAgreementData() external;

    function readUpdatedAgreement()
        external
        view
        returns (NewAgreementData memory);

    function returnNFT() external payable;

    function withdrawCollateral() external;

    function getElasticAddress() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IAgreement.sol";
import "./interfaces/IElastic.sol";

contract Agreement is IAgreement {
    address public elasticAddress;

    AgreementData agreement;
    NewAgreementData newAgreement;

    error AgreementNotEnoughFunds(
        uint256 availableFunds,
        uint256 requiredFunds
    );
    error AgreementNotExpired(uint256 endTime);
    error AgreementAccessDenied(address caller);

    event NFTReturnedAgreement(
        address indexed agreement,
        address owner,
        address borrower,
        address indexed nftAddress,
        uint256 indexed itemId
    );
    event CollateralWithdrawed(
        address indexed agreement,
        address indexed owner,
        uint256 collateral
    );
    event NewAgreementProposal(
        address indexed agreement,
        uint256 collateral,
        uint256 rentDays,
        uint256 price
    );
    event AcceptedNewAgreement(
        address indexed agreement,
        address indexed approver,
        uint256 collateral,
        uint256 rentDays,
        uint256 price
    );

    constructor(
        address _elasticAddress,
        address _owner,
        address _borrower,
        uint256 _collateral,
        uint256 _rentTime,
        uint256 _tokenId,
        address _nftAddress,
        uint256 _price,
        uint256 _startTime,
        uint256 _itemId
    ) {
        elasticAddress = _elasticAddress;
        agreement.owner = _owner;
        agreement.borrower = _borrower;
        agreement.collateral = _collateral;
        agreement.rentTime = _rentTime;
        agreement.tokenId = _tokenId;
        agreement.nftAddress = _nftAddress;
        agreement.price = _price;
        agreement.startTime = _startTime;
        agreement.itemId = _itemId;
    }

    function getElasticAddress() public view returns (address) {
        return elasticAddress;
    }

    /**
    @notice readPayment allows the owner, the borrower, and the broker smart contract to read the required payment amount so far
    */
    function readPayment()
        external
        view
        override
        onlyInvolved
        returns (uint256)
    {
        uint256 totalPaymentAmount = (block.timestamp - agreement.startTime) *
            agreement.price;
        return totalPaymentAmount;
    }

    /**
    @notice readAgreementData returns the data of this agreement
    */
    function readAgreementData()
        external
        view
        override
        onlyInvolved
        returns (IAgreement.AgreementData memory)
    {
        return agreement;
    }

    /**
    @notice updateAgreementData allows the owner to update the agreement and change the agreement
    @param _collateral new collateral for the rented NFT
    @param _rentTime new amount of renting time (in seconds) for the rented NFT
    @param _price new rent price value for the rented NFT
    */
    function updateAgreementData(
        uint256 _collateral,
        uint256 _rentTime,
        uint256 _price
    ) external override onlyInvolved {
        newAgreement.collateral = _collateral;
        newAgreement.rentTime = _rentTime;
        newAgreement.price = _price;
        newAgreement.ownerAccepted = msg.sender == agreement.owner
            ? true
            : false;
        newAgreement.borrowerAccepted = msg.sender == agreement.borrower
            ? true
            : false;

        emit NewAgreementProposal(
            address(this),
            _collateral,
            _rentTime,
            _price
        );
    }

    /**
    @notice acceptUpdatedAgreementData allows the borrower or the owner to accept the new proposed agreement
    */
    function acceptUpdatedAgreementData() external override onlyInvolved {
        newAgreement.ownerAccepted = msg.sender == agreement.owner
            ? true
            : false;
        newAgreement.borrowerAccepted = msg.sender == agreement.borrower
            ? true
            : false;

        if (newAgreement.ownerAccepted && newAgreement.borrowerAccepted) {
            agreement.collateral = newAgreement.collateral;
            agreement.rentTime = newAgreement.rentTime;
            agreement.price = newAgreement.price;

            newAgreement.collateral = 0;
            newAgreement.rentTime = 0;
            newAgreement.price = 0;
            newAgreement.ownerAccepted = false;
            newAgreement.borrowerAccepted = false;
        }

        emit AcceptedNewAgreement(
            address(this),
            msg.sender,
            agreement.collateral,
            agreement.rentTime,
            agreement.price
        );
    }

    /**
    @notice readUpdatedAgreement allows the owner, the borrower, and the broker contract to read the new agreement proposal
    */
    function readUpdatedAgreement()
        external
        view
        override
        onlyInvolved
        returns (NewAgreementData memory)
    {
        return newAgreement;
    }

    /**
    @notice returnNFT the borrower should use this function to return the rented NFT, pay the rent price, and receive the collateral back
    */
    function returnNFT() external payable override onlyBorrower {
        uint256 totalPaymentAmount = (block.timestamp - agreement.startTime) *
            agreement.price;

        if (address(this).balance < totalPaymentAmount) {
            revert AgreementNotEnoughFunds(
                address(this).balance,
                totalPaymentAmount
            );
        }

        IERC721(agreement.nftAddress).transferFrom(
            msg.sender,
            elasticAddress,
            agreement.tokenId
        );

        payable(agreement.owner).transfer(totalPaymentAmount);
        payable(agreement.borrower).transfer(address(this).balance);

        IElastic(elasticAddress).returnNFT(agreement.itemId, msg.sender);

        emit NFTReturnedAgreement(
            address(this),
            agreement.owner,
            agreement.borrower,
            agreement.nftAddress,
            agreement.itemId
        );
        _burnAgreement();
    }

    /**
    @notice withdrawCollateral allows NFT owner to get the collateral, if the borrower does not return the NFT back at the agreed time
    */
    function withdrawCollateral() external override onlyOwner {
        if (agreement.startTime + agreement.rentTime < block.timestamp) {
            revert AgreementNotExpired(
                agreement.startTime + agreement.rentTime
            );
        }

        payable(msg.sender).transfer(agreement.collateral);
        payable(elasticAddress).transfer(address(this).balance);

        IElastic(elasticAddress).unlistNFT(agreement.itemId);

        emit CollateralWithdrawed(
            address(this),
            agreement.owner,
            agreement.collateral
        );
        _burnAgreement();
    }

    /**
    @notice _burnAgreement internal function to burn this smart contract after its end
    */
    function _burnAgreement() internal {
        selfdestruct(payable(elasticAddress));
    }

    modifier onlyBorrower() {
        if (agreement.borrower != msg.sender) {
            revert AgreementAccessDenied(msg.sender);
        }
        _;
    }

    modifier onlyOwner() {
        if (agreement.owner != msg.sender) {
            revert AgreementAccessDenied(msg.sender);
        }
        _;
    }

    modifier onlyInvolved() {
        if (
            agreement.owner != msg.sender &&
            agreement.borrower != msg.sender &&
            elasticAddress != msg.sender
        ) {
            revert AgreementAccessDenied(msg.sender);
        }
        _;
    }

    fallback() external payable {}

    receive() external payable {}
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IElastic {
    function unlistNFT(uint256 _itemId) external;

    function returnNFT(uint256 _itemId, address _owner) external;
}