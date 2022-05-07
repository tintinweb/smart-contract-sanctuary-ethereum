// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./VestedAuctionUtils.sol";
import "./VestedInterface.sol";

contract ProjectP22 is
    ERC1155Upgradeable,
    OwnableUpgradeable,
    VestedAuctionUtils
{
    string public name;
    string public symbol;

    // Revenue
    uint256 public totalRevenue;
    struct RevenueShares {
        uint32 ownerShare;
        uint32 creatorShare;
        uint32 tokenMembersShare;
    }
    RevenueShares private revenueShares;
    mapping(uint256 => uint256) public perTokenClaimedAmount;
    uint256 public ownerClaimedAmount;
    uint256 public creatorClaimedAmount;
    uint256 private tokenRevenueSharingMembers;
    address public revenueSharingContractAddress;
    Erc721Contract private revenueSharingContract;
    address public revenueSharingCreatorAddress;

    // Randomness
    address public randomnessProviderAddress;

    // Packs
    struct PackDetail {
        bool Active;
        string Name;
        string Type;
        string Description;
        uint32 numOfTokensInPerPack;
        uint32 maxSupply;
        uint32 startTokenId;
        uint32 endTokenId;
        string provenance;
        address tokenContractAddress;
    }
    mapping(uint32 => PackDetail) public PackDetails;
    mapping(uint32 => uint32) public suppliedPacks;
    mapping(uint32 => uint32) private lastSelectedIndex;
    mapping(uint32 => uint32) private maxAvailableIndex;
    mapping(address => uint32) public maxTokenSupply;
    mapping(uint32 => mapping(uint32 => bool)) public isTokenPicked;
    mapping(uint32 => uint256) private numOfDropPointsInPack;

    // Sale
    struct SaleData {
        bool SaleIsActive;
        uint256 saleDuration;
        uint256 saleStartTime;
        uint256 saleStartPrice;
        uint256 saleMinPrice;
    }
    mapping(uint32 => SaleData) public packSaleData;

    // Toadz Free Claim
    mapping(uint32 => mapping(uint32 => bool)) private isToadzIdClaimedFreePack;
    mapping(uint32 => bool) public isToadzFreeClaimPack;
    uint32 private toadzFreeClaimRelease;

    string public baseURI;

    struct AsyncRandomnessProviderRequest {
        uint32 packId;
        address userAddress;
    }
    mapping(uint256 => AsyncRandomnessProviderRequest)
        private asyncRandomnessProviderRequestMapping;

    function initialize() external initializer {
        __Ownable_init();
        name = "projectP22";
        symbol = "PP22";

        revenueShares = RevenueShares(30, 10, 60);
        tokenRevenueSharingMembers = 7025;
        revenueSharingContractAddress = 0xf1183A89c576aa07f5DBE5a13ca4B42855fb6545; // TODO: UPDATE BEFORE GO LIVE
        revenueSharingContract = Erc721Contract(revenueSharingContractAddress);
        revenueSharingCreatorAddress = 0x97EC89056293d8E3e3119865725616769e27236b; // TODO: UPDATE BEFORE GO LIVE
    }

    // ***************************** internal : Start *****************************
    function checkIndexIsAvailbale(uint256 randomNumber, uint32 packId)
        internal
        returns (uint256)
    {
        uint256 j = 0;
        for (j = randomNumber; j <= maxAvailableIndex[packId]; j = j + 1) {
            if (isTokenPicked[packId][uint32(j)] != true) {
                return j;
            }
        }
        maxAvailableIndex[packId] = uint32(randomNumber - 1);
        lastSelectedIndex[packId] = 0;
        return checkIndexIsAvailbale((randomNumber / 2), packId);
    }

    function getElapsedSaleTime(uint32 packId) internal view returns (uint256) {
        return
            packSaleData[packId].saleStartTime > 0
                ? block.timestamp - packSaleData[packId].saleStartTime
                : 0;
    }

    function nowOpenPack(
        address senderAddress,
        uint32 packId,
        uint256 randomNumber
    ) internal {
        uint256 newImageIndex = checkIndexIsAvailbale(
            lastSelectedIndex[packId] + randomNumber,
            packId
        );
        isTokenPicked[packId][uint32(newImageIndex)] = true;

        TokenContract tokenContract = TokenContract(
            PackDetails[packId].tokenContractAddress
        );
        uint256 tokenStartIndex = PackDetails[packId].startTokenId +
            (newImageIndex * PackDetails[packId].numOfTokensInPerPack);
        tokenContract.Mint(
            PackDetails[packId].numOfTokensInPerPack,
            senderAddress,
            tokenStartIndex,
            randomNumber
        );

        if (newImageIndex == maxAvailableIndex[packId]) {
            maxAvailableIndex[packId] -= 1;
            lastSelectedIndex[packId] = 0;
        } else {
            lastSelectedIndex[packId] = uint32(newImageIndex);
        }
        _burn(senderAddress, packId, 1);
    }

    function transferFund(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    // ***************************** internal : End *****************************

    // ***************************** onlyOwner : Start *****************************

    // Packs
    function addNewPack(
        uint32 newPackId,
        string memory _packName,
        string memory _packType,
        string memory _packDescription,
        uint32 _numOfTokensInPerPack,
        uint32 _maxPackSupply,
        address _tokenContractAddress
    ) external onlyOwner {
        require(PackDetails[newPackId].Active == false, "Pack already active");

        PackDetails[newPackId] = PackDetail(
            true,
            _packName,
            _packType,
            _packDescription,
            _numOfTokensInPerPack,
            _maxPackSupply,
            maxTokenSupply[_tokenContractAddress],
            maxTokenSupply[_tokenContractAddress] +
                (_numOfTokensInPerPack * _maxPackSupply) -
                1,
            "",
            _tokenContractAddress
        );

        maxAvailableIndex[newPackId] = _maxPackSupply - 1;
        maxTokenSupply[_tokenContractAddress] =
            PackDetails[newPackId].endTokenId +
            1;
    }

    function setRevenueSharingContractAddress(
        address _revenueSharingContractAddress
    ) external onlyOwner {
        revenueSharingContractAddress = _revenueSharingContractAddress;
        revenueSharingContract = Erc721Contract(revenueSharingContractAddress);
        tokenRevenueSharingMembers = revenueSharingContract.totalSupply();
    }

    function startPackSale(
        uint32 packId,
        uint128 _packStartPrice,
        uint128 _packMinPrice,
        uint256 _saleDuration
    ) external onlyOwner {
        require(PackDetails[packId].Active, "Pack not active");
        require(
            packSaleData[packId].SaleIsActive == false,
            "Sale already begun"
        );
        packSaleData[packId] = SaleData(
            true,
            _saleDuration,
            block.timestamp,
            _packStartPrice,
            _packMinPrice
        );
        numOfDropPointsInPack[packId] = VestedAuctionUtils.getNumOfDropPoints(
            _packStartPrice
        );
    }

    function pausePackSale(uint32 packId) external onlyOwner {
        require(PackDetails[packId].Active, "Pack not active");
        require(
            packSaleData[packId].SaleIsActive == true,
            "Sale already paused"
        );
        packSaleData[packId].SaleIsActive = false;
    }

    function setPackDetails(
        uint32 packId,
        string memory newPackName,
        string memory description,
        string memory newPackType,
        uint128 _packMinPrice
    ) external onlyOwner {
        require(PackDetails[packId].Active, "Pack not active");
        PackDetails[packId].Name = newPackName;
        PackDetails[packId].Description = description;
        PackDetails[packId].Type = newPackType;
        packSaleData[packId].saleMinPrice = _packMinPrice;
    }

    function setPackProvenance(uint32 packId, string memory _provenance)
        external
        onlyOwner
    {
        require(PackDetails[packId].Active, "Pack not active");
        PackDetails[packId].provenance = _provenance;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setRevenueSharingCreatorAddress(address newAddress)
        external
        onlyOwner
    {
        revenueSharingCreatorAddress = newAddress;
    }

    function getRevenueShare(uint32 share) internal view returns (uint256) {
        return (totalRevenue * share) / 100;
    }

    /**
    @notice Claim owner's share
     */
    function claimOwnerShare() external onlyOwner {
        uint256 claimValue = getRevenueShare(revenueShares.ownerShare) -
            ownerClaimedAmount;
        transferFund(msg.sender, claimValue);
        ownerClaimedAmount += claimValue;
    }

    function setRandomnessProvider(address _randomnessProviderAddress)
        external
        onlyOwner
    {
        randomnessProviderAddress = _randomnessProviderAddress;
    }

    function setToadzFreeClaimPack(uint32 packId, bool _isToadzFreeClaimPack)
        external
        onlyOwner
    {
        require(PackDetails[packId].Active, "Pack not active");
        isToadzFreeClaimPack[packId] = _isToadzFreeClaimPack;
    }

    /**
    @notice Only the Owner can call it, it will allow already claimed Toadz owner to claim free pack again
     */
    function resetOGToadTokenFreePacks() external onlyOwner {
        toadzFreeClaimRelease += 1;
    }

    function setRevenueShares(
        uint32 ownerShare,
        uint32 creatorShare,
        uint32 tokenMembersShare
    ) external onlyOwner {
        require(totalRevenue == 0, "You can't change revenue share now");
        require(
            (ownerShare + creatorShare + tokenMembersShare) == 100,
            "The total of revenue share must be 100"
        );
        revenueShares = RevenueShares(
            ownerShare,
            creatorShare,
            tokenMembersShare
        );
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public external : Start *****************************

    function getRemainingSaleTime(uint32 packId) public view returns (uint256) {
        require(
            packSaleData[packId].saleStartTime > 0,
            "Public sale hasn't started yet"
        );
        if (getElapsedSaleTime(packId) >= packSaleData[packId].saleDuration) {
            return 0;
        }
        return
            (packSaleData[packId].saleStartTime +
                packSaleData[packId].saleDuration) - block.timestamp;
    }

    function claimToadzFreePack(uint32 toadzTokenId, uint32 packId) external {
        require(PackDetails[packId].Active, "Pack not active");
        require(
            isToadzIdClaimedFreePack[toadzFreeClaimRelease][toadzTokenId] ==
                false,
            "Free pack already claimed for this toadz token id"
        );
        require(
            revenueSharingContract.ownerOf(toadzTokenId) == msg.sender,
            "Your wallet does not own this token!"
        );
        require(
            isToadzFreeClaimPack[packId],
            "Pack is not toadz free claim pack"
        );
        require(
            suppliedPacks[packId] + 1 <= PackDetails[packId].maxSupply,
            "Count exceeds the maximum allowed supply."
        );
        suppliedPacks[packId] += 1;
        _mint(msg.sender, packId, 1, "");
        isToadzIdClaimedFreePack[toadzFreeClaimRelease][toadzTokenId] = true;
    }

    function claimToadzAllFreePacks(uint32 packId) external {
        uint256 tokenCount = revenueSharingContract.balanceOf(msg.sender);
        require(tokenCount > 0, "you don't own any toadz");
        require(PackDetails[packId].Active, "Pack not active");
        require(
            isToadzFreeClaimPack[packId],
            "Pack is not toadz free claim pack"
        );
        require(
            suppliedPacks[packId] + tokenCount <= PackDetails[packId].maxSupply,
            "Count exceeds the maximum allowed supply of pack."
        );
        uint32 qty = 0;
        uint256 index = 0;
        for (index = 0; index < tokenCount; index++) {
            uint256 tokenId = revenueSharingContract.tokenOfOwnerByIndex(
                msg.sender,
                index
            );
            if (
                isToadzIdClaimedFreePack[toadzFreeClaimRelease][
                    uint32(tokenId)
                ] == false
            ) {
                qty += 1;
                isToadzIdClaimedFreePack[toadzFreeClaimRelease][
                    uint32(tokenId)
                ] = true;
            }
        }
        suppliedPacks[packId] = suppliedPacks[packId] + qty;
        _mint(msg.sender, packId, qty, "");
    }

    function toadzIdAvailableForFreePackClaim(uint32 toadzTokenId)
        external
        view
        returns (bool)
    {
        return isToadzIdClaimedFreePack[toadzFreeClaimRelease][toadzTokenId];
    }

    function MintPrice(uint32 packId) public view returns (uint256) {
        require(PackDetails[packId].Active, "Pack not active");
        uint256 elapsed = getElapsedSaleTime(packId);
        if (elapsed >= packSaleData[packId].saleDuration) {
            return packSaleData[packId].saleMinPrice;
        } else {
            uint256 currentPrice = VestedAuctionUtils.getDroppedPrice(
                ((numOfDropPointsInPack[packId] *
                    getRemainingSaleTime(packId)) /
                    packSaleData[packId].saleDuration) + 1
            );
            return
                currentPrice > packSaleData[packId].saleMinPrice
                    ? currentPrice
                    : packSaleData[packId].saleMinPrice;
        }
    }

    /**
    @notice Open pack and get NFTs
     */
    function OpenPack(uint32 packId) external {
        require(PackDetails[packId].Active, "Pack not active");
        require(
            balanceOf(msg.sender, packId) > 0,
            "You don't have any pack in your account"
        );

        uint256 randomNumberRes = VestedRandomnessContract(
            randomnessProviderAddress
        ).getRandomNumber(
                msg.sender,
                maxAvailableIndex[packId] - lastSelectedIndex[packId] + 1
            );
        asyncRandomnessProviderRequestMapping[
            randomNumberRes
        ] = AsyncRandomnessProviderRequest(packId, msg.sender);
    }

    function receiveRandomness(uint256 requestId, uint256 randomNumber)
        external
    {
        require(
            randomnessProviderAddress == msg.sender,
            "only randomness provider contract can call this function"
        );
        require(
            PackDetails[asyncRandomnessProviderRequestMapping[requestId].packId]
                .Active,
            "Pack not active"
        );
        require(
            balanceOf(
                asyncRandomnessProviderRequestMapping[requestId].userAddress,
                asyncRandomnessProviderRequestMapping[requestId].packId
            ) > 0,
            "You don't have any pack in your account"
        );
        nowOpenPack(
            asyncRandomnessProviderRequestMapping[requestId].userAddress,
            asyncRandomnessProviderRequestMapping[requestId].packId,
            randomNumber
        );
    }

    /**
    @notice Mint pack
     */
    function Mint(uint32 count, uint32 packId) external payable {
        require(PackDetails[packId].Active, "Pack not active");
        require(
            packSaleData[packId].SaleIsActive,
            "Public sale is not active."
        );
        require(
            suppliedPacks[packId] + count <= PackDetails[packId].maxSupply,
            "Count exceeds the maximum allowed supply."
        );
        require(msg.value >= MintPrice(packId) * count, "Not enough ether.");
        suppliedPacks[packId] += count;
        _mint(msg.sender, packId, count, "");
        totalRevenue += msg.value;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(
            PackDetails[uint32(id)].Active,
            "URI requested for invalid pack"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id))
                : baseURI;
    }

    /**
    @notice Enter OG Cryptoadz tokenID to view unclaimed amount
     */
    function unclaimedTokenShare(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return
            (getRevenueShare(revenueShares.tokenMembersShare) /
                tokenRevenueSharingMembers) - perTokenClaimedAmount[tokenId];
    }

    /**
    @notice View unclaimed amount of owner's share
     */
    function unclaimedOwnerShare() external view returns (uint256) {
        return getRevenueShare(revenueShares.ownerShare) - ownerClaimedAmount;
    }

    /**
    @notice View unclaimed amount of OG Cryptoadz Creator's share
     */
    function unclaimedCreatorShare() external view returns (uint256) {
        return
            getRevenueShare(revenueShares.creatorShare) - creatorClaimedAmount;
    }

    /**
    @notice Claim individual token share by OG Cryptoadz tokenID
     */
    function claimTokenShareByToken(uint256 tokenId) external {
        require(
            revenueSharingContract.ownerOf(tokenId) == msg.sender,
            "Your wallet does not own this token!"
        );
        uint256 claimValue = (getRevenueShare(revenueShares.tokenMembersShare) /
            tokenRevenueSharingMembers) - perTokenClaimedAmount[tokenId];
        transferFund(msg.sender, claimValue);
        perTokenClaimedAmount[tokenId] += claimValue;
    }

    /**
    @notice Claim creator's share 
     */
    function claimCreatorShare() external {
        require(
            revenueSharingCreatorAddress == msg.sender,
            "you can't claim creator share"
        );
        uint256 claimValue = getRevenueShare(revenueShares.creatorShare) -
            creatorClaimedAmount;
        transferFund(msg.sender, claimValue);
        creatorClaimedAmount += claimValue;
    }

    /**
    @notice Claim all unclaimed amount for all of your OG Cryptoadz tokenIDs
     */
    function claimTokenShare() external {
        uint256 tokenCount = revenueSharingContract.balanceOf(msg.sender);
        require(tokenCount > 0, "you don't own any token");
        uint256 index;
        uint256 alreadyClaimedAmount = 0;
        uint256 perTokenClaimableAmount = getRevenueShare(
            revenueShares.tokenMembersShare
        ) / tokenRevenueSharingMembers;
        for (index = 0; index < tokenCount; index++) {
            uint256 tokenId = revenueSharingContract.tokenOfOwnerByIndex(
                msg.sender,
                index
            );
            alreadyClaimedAmount += perTokenClaimedAmount[tokenId];
            perTokenClaimedAmount[tokenId] = perTokenClaimableAmount;
        }
        uint256 claimValue = (perTokenClaimableAmount * tokenCount) -
            alreadyClaimedAmount;
        transferFund(msg.sender, claimValue);
    }
    // ***************************** public external : End *****************************
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// 20-04-2022

pragma solidity ^0.8.0;

contract VestedAuctionUtils {
    function getNumOfDropPoints(uint256 maxPrice)
        internal
        pure
        returns (uint256)
    {
        if (maxPrice > 1000000000000000000)
            return (32 +
                ((maxPrice - 1000000000000000000) / 250000000000000000));
        else if (maxPrice > 50000000000000000)
            return (13 + ((maxPrice - 50000000000000000) / 50000000000000000));
        else if (maxPrice > 10000000000000000)
            return (9 + ((maxPrice - 10000000000000000) / 10000000000000000));
        else if (maxPrice > 1000000000000000)
            return ((maxPrice - 1000000000000000) / 1000000000000000);
        else return 0;
    }

    function getDroppedPrice(uint256 droppedPoint)
        internal
        pure
        returns (uint256)
    {
        if (droppedPoint < 1)
            // 0
            return 1000000000000000;
        else if (droppedPoint < 10)
            // 1 ~ 9
            return ((droppedPoint + 1) * 1000000000000000);
        else if (droppedPoint < 14)
            // 10 ~ 13
            return ((droppedPoint - 8) * 10000000000000000);
        else if (droppedPoint < 33)
            // 14 ~ 32
            return ((droppedPoint - 12) * 50000000000000000);
        else if (droppedPoint > 32)
            // 33 ~ ...
            return ((droppedPoint - 28) * 250000000000000000);
        return 1000000000000000;
    }
}

pragma solidity ^0.8.0;

interface Erc721Contract {
    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

interface VestedRandomnessContract {
    function getRandomNumber(address senderAddress, uint256 _modulus)
        external
        returns (uint256);
}

interface TokenContract {
    function Mint(
        uint256 numberOfTokens,
        address toAddress,
        uint256 tokenStartIndex,
        uint256 randomNumber
    ) external;
}

interface IVestedRandomness {
    function receiveRandomness(uint256 requestId, uint256 randomNumber)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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