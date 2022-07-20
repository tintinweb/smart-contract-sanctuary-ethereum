// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./Agreement.sol";

contract Elastic {
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
        address borrower;
        uint256 rentTime;
        uint256 startTime;
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
    error NFTAlreadyListed(address caller, address nftAddress, uint256 tokenId);

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
        uint256 indexed itemId,
        address agreementAddress,
        address nftAddress,
        uint256 rentTime,
        uint256 startTime
    );
    event ListedNFTDataModified(
        address indexed owner,
        uint256 indexed itemId,
        uint256 collateral,
        uint256 price
    );
    event NFTReturned(
        address indexed owner,
        address indexed tenant,
        uint256 indexed itemId,
        uint256 timestamp,
        string CID
    );
    event NFTRemoved(
        address indexed owner,
        address indexed borrower,
        uint256 indexed itemId,
        string CID
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

    /**
    @notice getDataItem returns the data of the listed NFT
    @param _itemId ID of the listed NFT
    */
    function getDataItem(uint256 _itemId) public view returns (NFTData memory) {
        return items[_itemId];
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
        if (nftListedToItemId[_nft][_tokenId] > 0) {
            revert NFTAlreadyListed(msg.sender, _nft, _tokenId);
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
    function unlistNFT(uint256 _itemId) external {
        if (items[_itemId].owner != msg.sender) {
            revert AccessDenied(_itemId, msg.sender);
        }
        if (items[_itemId].rented) {
            revert AlreadyRented();
        }

        IERC721(items[_itemId].nftAddress).transferFrom(
            address(this),
            msg.sender,
            items[_itemId].tokenId
        );

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

        activeItem[_itemId] = false;
        delete nftListedToItemId[items[_itemId].nftAddress][
            items[_itemId].tokenId
        ];
        // delete items[_itemId]; // should be deleted though?

        emit NFTUnlisted(items[_itemId].owner, _itemId);
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

        emit ListedNFTDataModified(msg.sender, _itemId, _collateral, _price);
    }

    /** 
    @notice rent tenant rent the NFT list on the platform
    @param _itemId ID of the listed NFT
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
            item.collateral,
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
            msg.sender,
            _rentTime,
            block.timestamp
        );

        emit NFTRented(
            item.owner,
            msg.sender,
            _itemId,
            address(agreement),
            items[_itemId].nftAddress,
            _rentTime,
            block.timestamp
        );
        return address(agreement);
    }

    /**
    @notice returnNFT sets the rented field of listed NFT to false
    @param _itemId ID of the listed NFT
    @param _CID CID of the receipts stored on IPFS
    */
    function returnNFT(uint256 _itemId, string calldata _CID) public {
        if (rentedItems[_itemId].agreementAddress != msg.sender) {
            revert AccessDenied(_itemId, msg.sender);
        }

        items[_itemId].rented = false;
        address borrower = rentedItems[_itemId].borrower;

        uint256 jj;
        for (uint256 ii = 0; ii < borrowersNfts[borrower].length; ii++) {
            if (borrowersNfts[borrower][ii] == _itemId) {
                delete borrowersNfts[borrower][ii];
                jj = ii;
            }
            if (ii > jj) {
                borrowersNfts[borrower][ii - 1] = borrowersNfts[borrower][ii];
            }
        }
        borrowersNfts[borrower].pop();
        delete rentedItems[_itemId];

        emit NFTReturned(
            items[_itemId].owner,
            borrower,
            _itemId,
            block.timestamp,
            _CID
        );
    }

    /**
    @notice removeNFT removes the rented NFT when the borrower does not return it
    @param _itemId ID of the listed NFT
    @param _CID CID of the receipts stored on IPFS
    */
    function removeNFT(uint256 _itemId, string calldata _CID) external {
        if (rentedItems[_itemId].agreementAddress != msg.sender) {
            revert AccessDenied(_itemId, msg.sender);
        }

        address owner = items[_itemId].owner;
        address borrower = rentedItems[_itemId].borrower;

        // Deleting renting info
        uint256 jj;
        for (uint256 ii = 0; ii < borrowersNfts[borrower].length; ii++) {
            if (borrowersNfts[borrower][ii] == _itemId) {
                delete borrowersNfts[borrower][ii];
                jj = ii;
            }
            if (ii > jj) {
                borrowersNfts[borrower][ii - 1] = borrowersNfts[borrower][ii];
            }
        }
        borrowersNfts[borrower].pop();
        delete rentedItems[_itemId];

        // Unlisting
        jj = 0;
        for (uint256 ii = 0; ii < nftsListedByOwner[owner].length; ii++) {
            if (nftsListedByOwner[owner][ii] == _itemId) {
                delete nftsListedByOwner[owner][ii];
                jj = ii;
            }
            if (ii > jj) {
                nftsListedByOwner[owner][ii - 1] = nftsListedByOwner[owner][ii];
            }
        }
        nftsListedByOwner[owner].pop();

        activeItem[_itemId] = false;
        delete nftListedToItemId[items[_itemId].nftAddress][
            items[_itemId].tokenId
        ];

        emit NFTRemoved(owner, borrower, _itemId, _CID);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IAgreement.sol";
import "./interfaces/IElastic.sol";

contract Agreement is IAgreement {
    address public elasticAddress;

    AgreementData agreement;
    NewAgreementData newAgreement;
    string CID;

    error AgreementNotEnoughFunds(
        uint256 availableFunds,
        uint256 requiredFunds
    );
    error AgreementNotExpired(uint256 endTime, uint256 timestamp);
    error AgreementAccessDenied(address caller);

    event NFTReturnedAgreement(
        address indexed owner,
        address indexed borrower,
        uint256 indexed itemId,
        address nftAddress,
        address agreement
    );
    event CollateralWithdrawed(
        address indexed owner,
        address indexed borrower,
        uint256 indexed itemId,
        address agreement,
        uint256 collateral
    );
    event NewAgreementProposal(
        address indexed owner,
        address indexed borrower,
        address indexed agreement,
        uint256 collateral,
        uint256 rentDays,
        uint256 price
    );
    event AcceptedNewAgreement(
        address indexed owner,
        address indexed borrower,
        address indexed agreement,
        address approver,
        uint256 collateral,
        uint256 rentDays,
        uint256 price
    );
    event AgreementReceipt(
        address indexed owner,
        address indexed borrower,
        string indexed CID,
        string CIDClearText,
        address agreement,
        string status
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

    /**
    @notice getElasticAddress returns the Elastic smart contract address
    */
    function getElasticAddress() external view override returns (address) {
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
            agreement.owner,
            agreement.borrower,
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
            agreement.owner,
            agreement.borrower,
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
    @param _CID CID of the receipts stored on IPFS
    */
    function returnNFT(string calldata _CID)
        external
        payable
        override
        onlyBorrower
    {
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

        IElastic(elasticAddress).returnNFT(agreement.itemId, _CID);

        emit NFTReturnedAgreement(
            agreement.owner,
            agreement.borrower,
            agreement.itemId,
            agreement.nftAddress,
            address(this)
        );

        _writeCID(_CID);
        _burnAgreement("NFT Returned");
    }

    /**
    @notice withdrawCollateral allows NFT owner to get the collateral, if the borrower does not return the NFT back at the agreed time
    @param _CID CID of the receipts stored on IPFS 
    */
    function withdrawCollateral(string calldata _CID)
        external
        override
        onlyOwner
    {
        uint256 endTime = agreement.startTime + agreement.rentTime;
        if (block.timestamp < endTime) {
            revert AgreementNotExpired(endTime, block.timestamp);
        }

        payable(agreement.owner).transfer(agreement.collateral);
        payable(elasticAddress).transfer(address(this).balance);

        IElastic(elasticAddress).removeNFT(agreement.itemId, _CID);

        emit CollateralWithdrawed(
            agreement.owner,
            agreement.borrower,
            agreement.itemId,
            address(this),
            agreement.collateral
        );

        _writeCID(_CID);
        _burnAgreement("Collateral withdrawed");
    }

    /**
    @notice _writeCID write the CID for IPFS
    @param _CID the new IPFS CID
    */
    function _writeCID(string calldata _CID) internal {
        CID = _CID;
    }

    /**
    @notice _burnAgreement internal function to burn this smart contract after its end
    @param _status status of the closing agreement
    */
    function _burnAgreement(string memory _status) internal {
        emit AgreementReceipt(
            agreement.owner,
            agreement.borrower,
            CID,
            CID,
            address(this),
            _status
        );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IAgreement {
    struct AgreementData {
        address owner;
        address borrower;
        address nftAddress;
        uint256 tokenId;
        uint256 itemId;
        uint256 collateral;
        uint256 price;
        uint256 rentTime;
        uint256 startTime;
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

    function returnNFT(string calldata _CID) external payable;

    function withdrawCollateral(string calldata _CID) external;

    function getElasticAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IElastic {
    function removeNFT(uint256 _itemId, string calldata _CID) external;

    function returnNFT(uint256 _itemId, string calldata _CID) external;
}