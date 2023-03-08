// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/INFTMarketplace.sol";
import "./access-control/LuxVestingNFTRoles.sol";

import "./interfaces/ILuxVestingNFT.sol";
import "./LuxFractionalizationManager.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

/// @title A NFT Marketplace
/// @notice You can use this contract to list a ERC721 token in the marketplace, update its price and  sell it
contract NFTMarketplace is INFTMarketplace, LuxVestingNFTRoles {
    uint256 bidId;
    address public nftContractAddress;
    LuxFractionalizationManager public fracContract;

    mapping(uint256 => Listing) public nftIdToListing;
    mapping(uint256 => Bid) public bidIdToBid;
    mapping(address => uint256) public moneyOwed;

    constructor(
        address _nftContractAddress,
        address _tokenAddress,
        address[2] memory _admins
    ) LuxVestingNFTRoles(_admins) {
        nftContractAddress = _nftContractAddress;
        fracContract = new LuxFractionalizationManager(_admins, _tokenAddress);
        emit ChangeNFTAddress(_nftContractAddress, block.timestamp);
    }

    modifier onlyOwner(uint256 _nftId) {
        require(
            msg.sender == IERC721(nftContractAddress).ownerOf(_nftId),
            "sender is not authorized"
        );
        _;
    }

    modifier onlyOwnerOrAdmin(uint256 _nftId) {
        require(
            msg.sender == IERC721(nftContractAddress).ownerOf(_nftId) ||
                IAccessControlEnumerable(nftContractAddress).hasRole(
                    ADMIN_ROLE,
                    msg.sender
                ),
            "sender is not authorized"
        );
        _;
    }

    modifier isApproved(uint256 _nftId) {
        IERC721 nftContract = IERC721(nftContractAddress);
        require(
            nftContract.getApproved(_nftId) == address(this) ||
                nftContract.isApprovedForAll(
                    nftContract.ownerOf(_nftId),
                    address(this)
                ),
            "contract is not approved for selling token"
        );
        _;
    }

    modifier listingExists(uint256 _nftId) {
        Listing memory listing = nftIdToListing[_nftId];
        require(listing.max != 0, "no listing for this nft");
        _;
    }

    function getFractionalizationAddress()
        external
        view
        override
        returns (address)
    {
        return address(fracContract);
    }

    function changeNFTAddress(address _nftContractAddress)
        external
        override
        onlyRole(ADMIN_ROLE)
    {
        nftContractAddress = _nftContractAddress;
        emit ChangeNFTAddress(_nftContractAddress, block.timestamp);
    }

    function getListing(uint256 _nftId)
        external
        view
        override
        listingExists(_nftId)
        returns (Listing memory)
    {
        Listing memory listing = nftIdToListing[_nftId];
        return listing;
    }

    function getListingBid(uint256 _nftId)
        public
        view
        override
        listingExists(_nftId)
        returns (Bid memory)
    {
        Listing memory listing = nftIdToListing[_nftId];

        uint256 _bidId = listing.bidIds[listing.bidRef];
        return bidIdToBid[_bidId];
    }

    function getBid(uint256 _nftId)
        external
        view
        override
        returns (Bid[5] memory _bidData, uint256 _bidRef)
    {
        Listing memory listingData = nftIdToListing[_nftId];
        Bid[5] memory bidData;

        for (uint256 i = 0; i < listingData.bidIds.length; i++) {
            bidData[i] = bidIdToBid[listingData.bidIds[i]];
        }

        return (bidData, listingData.bidRef);
    }

    function createListing(
        uint256 _nftId,
        uint256 _max,
        address _to
    ) external payable override onlyRole(BROKER_ROLE) isApproved(_nftId) {
        require(msg.value > 0, "min price must be above 0 wei");
        require(_max > 0, "max price must be set above 0 wei");
        require(msg.value < _max, "max price must be above starting price");
        require(_to != address(0), "address must not be the 0 address");

        Bid memory newBid = Bid(msg.sender, _to, msg.value);
        bidIdToBid[bidId] = newBid;

        uint256[5] memory bidIds;
        bidIds[0] = bidId;

        nftIdToListing[_nftId] = Listing(_max, false, 0, bidIds);

        fracContract.createPool(_nftId, msg.value);

        emit ListingCreated(
            _nftId,
            IERC721(nftContractAddress).ownerOf(_nftId),
            _max,
            block.timestamp
        );
        emit BidCreated(_nftId, bidId, _to, msg.value, block.timestamp);

        bidId++;
    }

    function updateListingPrice(uint256 _nftId, uint256 _max)
        external
        override
        onlyRole(BROKER_ROLE)
        isApproved(_nftId)
    {
        Listing storage listingData = nftIdToListing[_nftId];
        // Bid[] storage allBids = listingIdToBid[listingData.id];

        require(listingData.sold == false, "can't update already sold nft");
        require(
            _max > bidIdToBid[listingData.bidIds[listingData.bidRef]].value,
            "max price must be above min"
        );

        listingData.max = _max;

        emit ListingChanged(
            _nftId,
            IERC721(nftContractAddress).ownerOf(_nftId),
            _max,
            block.timestamp
        );
    }

    function _createBid(
        uint256 _nftId,
        Bid storage _lastBid,
        address _to
    ) internal {
        moneyOwed[_lastBid.bidder] += _lastBid.value;

        Bid memory newBid = Bid(msg.sender, _to, msg.value);
        bidIdToBid[bidId] = newBid;

        Listing storage listingData = nftIdToListing[_nftId];

        if (listingData.bidRef == 4) {
            listingData.bidRef = 0;
        } else {
            listingData.bidRef++;
        }

        listingData.bidIds[listingData.bidRef] = bidId;

        bidId++;
    }

    function _purchaseListing(uint256 _nftId) internal {
        IERC721 nftContract = IERC721(nftContractAddress);

        address owner = nftContract.ownerOf(_nftId);

        Listing storage listingData = nftIdToListing[_nftId];
        Bid memory winningBid = bidIdToBid[
            listingData.bidIds[listingData.bidRef]
        ];

        nftContract.safeTransferFrom(owner, winningBid.recipient, _nftId);

        listingData.sold = true;

        moneyOwed[owner] += winningBid.value;

        emit ListingSold(
            _nftId,
            owner,
            winningBid.bidder,
            winningBid.recipient,
            winningBid.value
        );
    }

    function createBid(uint256 _nftId, address _to)
        external
        payable
        override
        isApproved(_nftId)
    {
        Listing storage listingData = nftIdToListing[_nftId];

        require(!listingData.sold, "nft is not for sale");
        require(
            msg.value >
                bidIdToBid[listingData.bidIds[listingData.bidRef]].value,
            "bid has to be above current minimum"
        );
        require(
            msg.value <= listingData.max,
            "bid has to be at or below max price"
        );

        _createBid(
            _nftId,
            bidIdToBid[listingData.bidIds[listingData.bidRef]],
            _to
        );

        emit BidCreated(_nftId, bidId, _to, msg.value, block.timestamp);

        if (listingData.max == msg.value) {
            endAuction(_nftId);
        }
    }

    function endAuction(uint256 _nftId)
        public
        override
        onlyRole(BROKER_ROLE)
        isApproved(_nftId)
    {
        _purchaseListing(_nftId);
        uint256 currValue = getListingBid(_nftId).value;
        fracContract.endPool(_nftId, currValue);
    }

    function withdraw() external override {
        payable(msg.sender).transfer(moneyOwed[msg.sender]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTMarketplace {
    /**
     * @dev Bid data
     */
    struct Bid {
        address bidder;
        address recipient;
        uint256 value;
    }

    /**
     * @dev Market item data
     */
    struct Listing {
        uint256 max;
        bool sold;
        uint8 bidRef;
        uint256[5] bidIds;
    }

    /**
     * @dev Change NFT Contract address
     */
    event ChangeNFTAddress(address nftAddress, uint256 timestamp);

    /**
     * @dev Change Fractionalization Contract address
     */
    event ChangeFracAddress(address fracAddress, uint256 timestamp);

    /**
     * @dev Emitted when listing is created
     */
    event ListingCreated(
        uint256 indexed nftId,
        address indexed owner,
        uint256 max,
        uint256 timestamp
    );

    /**
     * @dev Emitted when listing is canceled
     */
    event ListingCanceled(
        uint256 indexed nftId,
        address indexed owner,
        uint256 timestamp
    );

    /**
     * @dev Emitted when listing price is changed
     */
    event ListingChanged(
        uint256 indexed nftId,
        address indexed owner,
        uint256 max,
        uint256 timestamp
    );

    /**
     * @dev Emitted when bid is created
     */
    event BidCreated(
        uint256 indexed nftId,
        uint256 indexed bidId,
        address indexed to,
        uint256 bidAmount,
        uint256 timestamp
    );

    /**
     * @dev Emitted when listing is sold
     */
    event ListingSold(
        uint256 indexed nftId,
        address indexed owner,
        address indexed buyer,
        address receiver,
        uint256 price
    );

    /**
     * @dev Gets address of fractionalization contract
     */
    function getFractionalizationAddress() external view returns (address);

    /**
     * @dev Gets listing data; getter from mapping
     */
    function getListing(uint256 _nftId) external view returns (Listing memory);

    /**
     * @dev Gets most recent bid for listing
     */
    function getListingBid(uint256 _nftId) external view returns (Bid memory);

    /**
     * @dev Changes contract address for nft contract
     */
    function changeNFTAddress(address _nftContractAddress) external;

    /**
     * @dev Get bid data from nft for sale
     */
    function getBid(uint256 _nftId)
        external
        view
        returns (Bid[5] memory _bidIds, uint256 _bidRef);

    /**
     * @dev Creates listing for public selling of NFT
     */
    function createListing(
        uint256 _nftId,
        uint256 _max,
        address _to
    ) external payable;

    /**
     * @dev Changes price of existing listing
     */
    function updateListingPrice(uint256 _nftId, uint256 _max) external;

    /**
     * @dev Creates bid for listing. If bid is for max value, purchase is completed
     */

    function createBid(uint256 _nftId, address _to) external payable;

    /**
     * @dev Ends auction by sending owner of
     */
    function endAuction(uint256 _nftId) external;

    /**
     * @dev Withdraws owed eth to msg.sender
     */
    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev Preparing for future contracts with more roles. Not to be integrated yet
 */
abstract contract LuxVestingNFTRoles is AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant BROKER_ROLE = keccak256("BROKER");

    constructor(address[2] memory admins) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(BROKER_ROLE, ADMIN_ROLE);

        for (uint8 i = 0; i < admins.length; i++) {
            grantRole(ADMIN_ROLE, admins[i]);
            grantRole(BROKER_ROLE, admins[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILuxVestingNFT {
    /**
     * @dev NFT data struct
     */
    struct LuxNFTData {
        bool isPrivate;
    }

    /**
     * @dev Emitted when base URI is changed
     */
    event NewURIPrefix(string newURIPrefix, uint256 timestamp);

    /**
     * @dev Emitted when URI is updated
     */

    event NewURISuffix(
        uint256 indexed nftId,
        string newURISuffix,
        uint256 timestamp
    );

    /**
     * @dev Emitted when privacy settings are changed on NFT
     */
    event ChangePrivacy(uint256 indexed nftId, bool isPrivate);

    /**
     * @dev Changes the base URI
     */
    function setBaseURI(string memory _newURIPrefix) external;

    /**
     * @dev Mints NFTs
     */
    function mintNFT(
        address recipient,
        string memory _tokenURI,
        bool _isPrivate
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./access-control/FractionalizationAccessControl.sol";
import "./interfaces/ILuxFractionalizationManager.sol";
import "./interfaces/INFTMarketplace.sol";
import "./interfaces/ILuxFractionalizationToken.sol";

contract LuxFractionalizationManager is
    ILuxFractionalizationManager,
    FractionalizationAccessControl
{
    mapping(uint256 => Stake[]) public nftIdToStakingData;
    mapping(uint256 => Pool) public nftIdToPool;
    mapping(address => uint256) public tokensOwed;
    address public marketplaceAddress;
    ILuxFractionalizationToken tokenContract;

    constructor(address[2] memory _admins, address _tokenAddress)
        FractionalizationAccessControl(_admins)
    {
        tokenContract = ILuxFractionalizationToken(_tokenAddress);
        marketplaceAddress = msg.sender;
        emit ChangeMarketplace(msg.sender, block.timestamp);
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "must send valid address");
        _;
    }

    modifier fromMarketplace() {
        require(
            msg.sender == marketplaceAddress,
            "sender does not have permission"
        );
        _;
    }

    modifier existingPool(uint256 _nftId) {
        require(nftIdToPool[_nftId].startAmount != 0, "pool does not exist");
        _;
    }

    modifier noExistingPool(uint256 _nftId) {
        require(nftIdToPool[_nftId].startAmount == 0, "pool already exists");
        _;
    }

    function getTokenAddress() external view override returns (address) {
        return address(tokenContract);
    }

    function changeMarketplace(address _marketplaceAddress)
        public
        override
        onlyRole(ADMIN_ROLE)
        validAddress(_marketplaceAddress)
    {
        marketplaceAddress = _marketplaceAddress;

        emit ChangeMarketplace(_marketplaceAddress, block.timestamp);
    }

    function mintTokens(uint256 _amount)
        external
        override
        onlyRole(ADMIN_ROLE)
    {
        require(_amount > 0, "amount minted must be > 0");
        tokenContract.mintTokens(_amount);
    }

    function purchase(address _to, uint256 _amount)
        external
        override
        onlyRole(ADMIN_ROLE)
        validAddress(_to)
        returns (bool)
    {
        bool success = tokenContract.transfer(_to, _amount);
        if (success) emit TokenPurchase(_to, _amount, block.timestamp);

        return success;
    }

    function currentPoolBps(uint256 _nftId)
        public
        view
        override
        existingPool(_nftId)
        returns (uint256)
    {
        Stake[] memory stakes = nftIdToStakingData[_nftId];

        uint256 bps = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            bps += (stakes[i].amount * 10000) / stakes[i].currentAmount;
        }

        return bps;
    }

    function stake(uint256 _nftId, uint256 _amount)
        external
        override
        existingPool(_nftId)
        returns (bool)
    {
        require(_amount > 0, "cannot stake 0");
        require(nftIdToPool[_nftId].startAmount > 0, "Pool does not exist");

        INFTMarketplace.Bid memory bid = INFTMarketplace(marketplaceAddress)
            .getListingBid(_nftId);

        uint256 bps = (_amount * 10000) / bid.value;

        require(currentPoolBps(_nftId) + bps <= 10000, "too high of stake");

        bool success = tokenContract.transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (!success) return success;

        nftIdToStakingData[_nftId].push(Stake(msg.sender, _amount, bid.value));

        emit CreateStake(msg.sender, _nftId, _amount, block.timestamp);

        return success;
    }

    function createPool(uint256 _nftId, uint256 _amount)
        external
        override
        fromMarketplace
        noExistingPool(_nftId)
    {
        require(_amount > 0, "bid cannot start at 0");

        nftIdToPool[_nftId] = Pool(_amount);

        uint256 bps = 1500; // 15 percent
        uint256 initStake = (_amount * bps) / 10000; // get stake

        nftIdToStakingData[_nftId].push(Stake(address(0), initStake, _amount));

        emit CreatePool(_nftId, _amount, block.timestamp);
    }

    function _increaseTokensOwed(address _address, uint256 _amount) internal {
        tokensOwed[_address] = tokensOwed[_address] + _amount;
    }

    function _returnTokens(uint256 _nftId) internal {
        Stake[] storage stakingData = nftIdToStakingData[_nftId];

        for (uint256 i = 1; i < stakingData.length; i++) {
            _increaseTokensOwed(stakingData[i].staker, stakingData[i].amount);
        }
    }

    function _distribute(uint256 _nftId, uint256 _endAmount) internal {
        Stake[] memory stakingData = nftIdToStakingData[_nftId];

        for (uint256 i = 0; i < stakingData.length; i++) {
            uint256 payment = (_endAmount / stakingData[i].currentAmount) *
                stakingData[i].amount;
            _increaseTokensOwed(stakingData[i].staker, payment);
        }
    }

    function endPool(uint256 _nftId, uint256 _endAmount)
        external
        override
        existingPool(_nftId)
        fromMarketplace
    {
        uint256 startAmount = nftIdToPool[_nftId].startAmount;

        if (_endAmount == startAmount) {
            _returnTokens(_nftId);
        } else {
            _distribute(_nftId, _endAmount);
        }

        delete nftIdToStakingData[_nftId];
        delete nftIdToPool[_nftId];
    }

    function getTokens() external override {
        bool success = tokenContract.transferFrom(
            address(this),
            msg.sender,
            tokensOwed[msg.sender]
        );

        require(success, "could not transfer tokens");

        tokensOwed[msg.sender] = 0;
    }

    function getLuxTokens(address _to)
        external
        override
        onlyRole(ADMIN_ROLE)
        validAddress(_to)
    {
        bool success = tokenContract.transferFrom(
            address(this),
            _to,
            tokensOwed[address(0)]
        );

        require(success, "could not transfer tokens");

        tokensOwed[address(0)] = 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev Preparing for future contracts with more roles. Not to be integrated yet
 */
abstract contract FractionalizationAccessControl is AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor(address[2] memory admins) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint8 i = 0; i < admins.length; i++) {
            grantRole(ADMIN_ROLE, admins[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILuxFractionalizationManager {
    /**
    * @dev Staking data struct
     */
    struct Stake {
        address staker;
        uint256 amount;
        uint256 currentAmount;
    }

    /**
    * @dev Pool data struct
     */
    struct Pool {
        uint256 startAmount;
    }

    /**
    * @dev Emitted when the marketplace address changes
     */
    event ChangeMarketplace(address marketplace, uint256 timestamp);

    /**
    * @dev Emitted when tokens are purchased
     */
    event TokenPurchase(address indexed to, uint256 amount, uint256 timestamp);

    /**
    * @dev Emitted when a stake in an nft is created
     */
    event CreateStake(
        address indexed staker,
        uint256 indexed nftId,
        uint256 amount,
        uint256 timestamp
    );

    /**
    * @dev Emitted when a staking pool is created
     */
    event CreatePool(
        uint256 indexed nftId,
        uint256 startAmount,
        uint256 timestamp
    );

    /**
    * @dev Emitted when a staking pool has closed
     */
    event EndPool(
        uint256 indexed nftId,
        uint256 startAmount,
        uint256 endAmount,
        uint256 timestamp
    );

    /**
    * @dev Gets the address of the current staking token ERC20 token contract being used
     */
    function getTokenAddress() external view returns (address);

    /**
    * @dev Callable by ADMIN_ROLE to change the address (_marketplace) of the nft marketplace
     */
    function changeMarketplace(address _marketplace) external;

    /**
    * @dev Callable by ADMIN_ROLE to mint a given amount (_amount) of more tokens from token contract
     */
    function mintTokens(uint256 _amount) external;

    /**
    * @dev Callable by ADMIN_ROLE to give a certain amount of staking tokens (_amount) to a given wallet (_to). 
     */
    function purchase(address _to, uint256 _amount) external returns (bool);

    /**
    * @dev Returns the current BPS in a given staking pool of an nft (_nftId). Max BPS allowed when staking is 10,000 (ten-thousand)
     */
    function currentPoolBps(uint256 _nftId) external view returns (uint256);

    /**
    * @dev Stakes a given amount of staking tokens (_amount) into the given nft (_nftId) in the marketplace from the msg.sender
     */
    function stake(uint256 _nftId, uint256 _amount) external returns (bool);

    /**
    * @dev Callable by the Marketplace contract. Initializes a staking pool (and the inital Lux stake) for the given nft (_nftId) marketplace sale using the initial price (_amount) as the baseline price
     */
    function createPool(uint256 _nftId, uint256 _amount) external;

    /**
    * @dev Callable by the Marketplace contract. Closes a staking pool for given nft (_nftId), and allocates the initial amount of tokens staked + interest for the difference between the price of the nft when staking vs when the nft is sold (_endAmount)
     */
    function endPool(uint256 _nftId, uint256 _endAmount) external;

    /**
    * @dev For non-lux stakers, this function will give tokens that have been allocated to the user after pool(s) has/have closed.
     */
    function getTokens() external;

    /**
    * @dev Callable by ADMIN_ROLE to send allocated tokens to given wallet address (_to)
     */
    function getLuxTokens(address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILuxFractionalizationToken {
    /**
     * @dev Triggered when controller of contract is changed
     */
    event ChangeController(
        address indexed caller,
        address controller,
        uint256 timestamp
    );

    /**
     * @dev Creates more ERC20 tokens
     */
    function mintTokens(uint256 _amount) external;

    /**
     * @dev Transfers user-owned tokens to requested (to) address
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Transfers tokens to requested address. Sender does not need to be owner, only granted an allowance
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Changes the "controller" of the contract, who is responsible for minting tokens
     */
    function setController(address _controller) external;
}