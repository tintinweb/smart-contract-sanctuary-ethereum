// SPDX-License-Identifier: None
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface HexArtMarkets {
    function isListed(uint256 _tokenId) external view returns (bool);
    function distibuteRemovalFee() external payable returns (bool);
}

interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface ERC20 {
    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface FeesCollector {
    function manageArtistFees(uint256 value) external returns (bool);
}

abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    modifier checkRoyaltyInfo(address receiver, uint256 feeNumerator) {
        require(receiver != address(0), "ERC2981: invalid receiver");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual checkRoyaltyInfo(receiver, feeNumerator) {
        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }
}

contract HexArt is ERC721URIStorage, ERC2981, Ownable {
    HexArtMarkets public marketplace;
    FeesCollector public feeCollector;
    struct NFTDetail {
        uint256 nftTokenId;
        address assettype;
    }
    struct ECR20Detail {
        uint256 balance;
        address assettype;
    }

    uint256 public counter = 0;
    uint256 public amountToRemoveAsset = 369000000000000000;

    mapping(uint256 => address) internal initialOwner;
    mapping(uint256 => NFTDetail[]) internal nftAssetDetails;
    mapping(uint256 => ECR20Detail[]) internal erc20AssetDetails;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => uint256) public assetLockPeriod;

    constructor() ERC721("HEXART", "HXA") {}

    modifier onlyInitialOwner(uint256 _tokenId) {
        require(
            initialOwner[_tokenId] == _msgSender(),
            "Collection: only initial owner can set the royality"
        );
        _;
    }
    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "Not have permission");
        _;
    }

    modifier isNFTOwner(uint256 _nftTokenId) {
        require(
            ownerOf(_nftTokenId) == msg.sender,
            "Collection: caller is not owner nor approved"
        );
        _;
    }

    modifier isNotListedOnSale(uint256 _tokenId) {
        require(
            !marketplace.isListed(_tokenId),
            "Cannot add/remove asset to a listed NFT"
        );
        _;
    }

    modifier isBurnable(uint256 _tokenId) {
        NFTDetail[] memory array = getAssetsOfNFT(_tokenId);
        ECR20Detail[] memory array1 = getERC20AssetsOfNFT(_tokenId);
        require(array.length == 0 && array1.length == 0);
        _;
    }

    event nftMinted(
        uint256 tokenId,
        uint96 feeNumerator,
        uint256 lockperiodInDays,
        uint256 lockperiodInSec
    );
    event assetAdded(uint256 parentNftId, NFTDetail[] _tokenIds);
    event assetRemoved(
        uint256 tokenId,
        uint256[] assetId,
        address assetContract
    );
    event allAssetRemoved(uint256 _nftTokenId, NFTDetail[] array);
    event burnNFT(uint256 _hexartTokenId);

    /**
     * @dev returns true if the contract supports the interface with entered bytecode.
     * @dev 0x2a55205a to test eip 2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets the royalty info for any token.
     */
    function setRoyaltyforToken(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyInitialOwner(_tokenId) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /**
     * @notice Sets the marketplace address.
     */
    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = HexArtMarkets(_marketplace);
    }

    /**
     * @notice Mints single token.
     * @param _tokenURI metadata URI
     * @param _feeNumerator royality percentage (this must be less than max limit)
     */
    function mint(
        string memory _tokenURI,
        uint96 _feeNumerator,
        uint256 _lockperiodInDays
    ) external returns (uint256 tokenId) {
        require(msg.sender != address(0), "Collection: _to address not valid");
        require(
            bytes(_tokenURI).length > 0,
            "Collection: Token URI is not valid"
        );
        counter++;
        tokenId = counter;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        if (_feeNumerator != 0) {
            _setTokenRoyalty(tokenId, msg.sender, _feeNumerator);
        }
        initialOwner[tokenId] = msg.sender;
        assetLockPeriod[tokenId] =
            block.timestamp +
            (1200 * _lockperiodInDays);
        emit nftMinted(
            tokenId,
            _feeNumerator,
            _lockperiodInDays,
            assetLockPeriod[tokenId]
        );
    }

    /**
     * @notice Burns token of entered token id.
     */
    function burn(uint256 _tokenId)
        external
        isNFTOwner(_tokenId)
        isBurnable(_tokenId)
        isNotListedOnSale(_tokenId)
    {
        delete initialOwner[_tokenId];
        delete assetLockPeriod[_tokenId];
        _burn(_tokenId);
        emit burnNFT(_tokenId);
    }

    /**
     * @notice Attach NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _tokenIds, Array of asset(HSI) token Ids
     * @param _tokenId, Hexart token ID.
     */
    function addNFTAsset(
        address _assetContract,
        uint256[] calldata _tokenIds,
        uint256 _tokenId
    )
        external
        isWhitelisted(_assetContract)
        isNFTOwner(_tokenId)
        isNotListedOnSale(_tokenId)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ERC721(_assetContract).transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );

            require(
                ERC721(_assetContract).ownerOf(_tokenIds[i]) == address(this),
                "Asset not added"
            );

            nftAssetDetails[_tokenId].push(
                NFTDetail({nftTokenId: _tokenIds[i], assettype: _assetContract})
            );
        }
        emit assetAdded(_tokenId, nftAssetDetails[_tokenId]);
    }

    /**
     * @notice  Remove NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     */
    function removeNFTAsset(
        uint256 _nftTokenId,
        uint256[] calldata _assetId,
        address _assetContract
    ) external isNFTOwner(_nftTokenId) isNotListedOnSale(_nftTokenId) {
        require(isLockPeriodOver(_nftTokenId));
        removeNFT(_nftTokenId, _assetId, _assetContract);
        emit assetRemoved(_nftTokenId, _assetId, _assetContract);
    }

    /**
     * @notice  Remove NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     */
    function removeNFTPayable(
        uint256 _nftTokenId,
        uint256[] calldata _assetId,
        address _assetContract
    ) public payable isNFTOwner(_nftTokenId) isNotListedOnSale(_nftTokenId) {
        require(msg.value == amountToRemoveAsset, "Not enough funds sent");
        require(!isLockPeriodOver(_nftTokenId));
        require(marketplace.distibuteRemovalFee{value: msg.value}());
        removeNFT(_nftTokenId, _assetId, _assetContract);
        emit assetRemoved(_nftTokenId, _assetId, _assetContract);
    }

    /**
     * @notice  Internal function to remove NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     */
    function removeNFT(
        uint256 _nftTokenId,
        uint256[] calldata _assetId,
        address _assetContract
    ) internal {
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        require(array.length > 0, "No asset is attached to the given NFT.");

        for (uint256 i = 0; i < _assetId.length; i++) {
            (bool check, uint256 index) = isAssetAttached(
                _nftTokenId,
                _assetId[i],
                _assetContract
            );
            if (check) {
                require(
                    transferAsset(_assetContract, _assetId[i]),
                    "Asset not removed"
                );
                removeAssetToken(index, _nftTokenId);
            }
        }
    }

    /**
     * @notice    Find index of the attached asset to a given NFT .
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     * @return index, Asset index.
     */
    function findIndexOfAsset(uint256 _assetId, uint256 _nftTokenId)
        external
        view
        returns (uint256)
    {
        uint256 index;
        for (uint256 i = 0; i < nftAssetDetails[_nftTokenId].length; i++) {
            if (nftAssetDetails[_nftTokenId][i].nftTokenId == _assetId) {
                index = i;
            }
        }
        return index;
    }

    /**
     * @notice  Payable function to remove all NFT(HSI) assets to a given hexart.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeAllNFTAssetsPayable(uint256 _nftTokenId)
        public
        payable
        isNFTOwner(_nftTokenId)
        isNotListedOnSale(_nftTokenId)
    {
        require(!isLockPeriodOver(_nftTokenId));
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        require(
            msg.value == (amountToRemoveAsset * array.length),
            "Not enough funds sent"
        );
        require(marketplace.distibuteRemovalFee{value: msg.value}());
        removeAllNFT(_nftTokenId);
    }

    /**
     * @notice   Function to remove all NFT(HSI) assets to a given hexart.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeAllNFTAssets(uint256 _nftTokenId)
        public
        isNFTOwner(_nftTokenId)
        isNotListedOnSale(_nftTokenId)
    {
        require(isLockPeriodOver(_nftTokenId));
        removeAllNFT(_nftTokenId);
    }

    /**
     * @notice  Internal function to remove all NFT(HSI) assets to a given hexart.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeAllNFT(uint256 _nftTokenId) internal {
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        require(array.length > 0, "No asset is attached to the given NFT.");

        for (uint256 i = 0; i < array.length; i++) {
            require(
                transferAsset(array[i].assettype, array[i].nftTokenId),
                "Asset not removed"
            );
            removeAssetToken(i, _nftTokenId);
        }
        emit allAssetRemoved(_nftTokenId, array);
    }

    /**
     * @notice Attach ERC-20 assets to a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _amount, Amount of erc-20 tokens.
     * @param _tokenId, Hexart token ID.
     */
    function addErc20Asset(
        address _assetContract,
        uint256 _tokenId,
        uint256 _amount
    )
        external
        isWhitelisted(_assetContract)
        isNFTOwner(_tokenId)
        isNotListedOnSale(_tokenId)
    {
        bool check = false;

        TransferHelper.safeTransferFrom(
            _assetContract,
            _msgSender(),
            address(this),
            _amount
        );

        for (uint256 i = 0; i < erc20AssetDetails[_tokenId].length; i++) {
            if (erc20AssetDetails[_tokenId][i].assettype == _assetContract) {
                erc20AssetDetails[_tokenId][i].balance += _amount;
                check = true;
                break;
            }
        }
        if (!check) {
            erc20AssetDetails[_tokenId].push(
                ECR20Detail({balance: _amount, assettype: _assetContract})
            );
        }
    }

    /**
     * @notice  Remove erc-20 assets from a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeErc20Asset(address _assetContract, uint256 _nftTokenId)
        external
        isNFTOwner(_nftTokenId)
        isNotListedOnSale(_nftTokenId)
    {
        require(isLockPeriodOver(_nftTokenId));
        removeErc20(_assetContract, _nftTokenId);
    }

    /**
     * @notice  Remove(payable) erc-20 assets from a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeErc20Assetpayable(
        address _assetContract,
        uint256 _nftTokenId
    ) external payable isNFTOwner(_nftTokenId) isNotListedOnSale(_nftTokenId) {
        require(msg.value == amountToRemoveAsset, "Not enough funds sent");
        require(!isLockPeriodOver(_nftTokenId));
        require(marketplace.distibuteRemovalFee{value: msg.value}());
        removeErc20(_assetContract, _nftTokenId);
    }

    /**
     * @notice  Remove(internal) erc-20 assets from a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeErc20(address _assetContract, uint256 _nftTokenId) internal {

        for (uint256 i = 0; i < erc20AssetDetails[_nftTokenId].length; i++) {
           (bool check, uint256 index) =  isErcAssetAttached(_nftTokenId,_assetContract);
            if(check) {
                TransferHelper.safeTransfer(
                    _assetContract,
                    _msgSender(),
                    erc20AssetDetails[_nftTokenId][i].balance
                );
                removeErcAssetToken(index,_nftTokenId);
            }
        }
    }

    /**
     * @notice Transfers token from 'from' address to 'to' address.
     * @param _tokenId, Hexart token ID.
     * @param _from, From address.
     * @param _to,To address.
     */
    function transferNFT(
        uint256 _tokenId,
        address _from,
        address _to
    ) external returns (bool) {
        _transfer(_from, _to, _tokenId);
        return true;
    }

    /**
    @notice Add asset address to the whitelist.
    @param _addressToWhitelist, Address to whitelist.
    */
    function addAssetToWhitelist(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    /**
    @notice Remove asset address to the whitelist.
    @param _addressToWhitelist, Address to whitelist.
    */
    function removeAssetFromWhitelist(address _addressToWhitelist)
        public
        onlyOwner
    {
        whitelistedAddresses[_addressToWhitelist] = false;
    }

    /**
     * @notice Returns an array of NFT assets associated with a hexart.
     */
    function getAssetsOfNFT(uint256 _tokenId)
        public
        view
        returns (NFTDetail[] memory)
    {
        return nftAssetDetails[_tokenId];
    }

    /**
     * @notice Returns an array of ERC-20  assets associated with a hexart.
     */
    function getERC20AssetsOfNFT(uint256 _tokenId)
        public
        view
        returns (ECR20Detail[] memory)
    {
        return erc20AssetDetails[_tokenId];
    }

    /**
     * @notice Remove  NFT assets associated with a NFT.
     * @param index, Blockchain index of asset.
     * @param _tokenId , Hexart token ID.
     */
    function removeAssetToken(uint256 index, uint256 _tokenId) internal {
        if (index < nftAssetDetails[_tokenId].length - 1) {
            nftAssetDetails[_tokenId][index] = nftAssetDetails[_tokenId][
                nftAssetDetails[_tokenId].length - 1
            ];
        }
        nftAssetDetails[_tokenId].pop();
    }

     /**
     * @notice Remove  NFT assets associated with a NFT.
     * @param index, Blockchain index of asset.
     * @param _tokenId , Hexart token ID.
     */
    function removeErcAssetToken(uint256 index, uint256 _tokenId) internal {
        if (index < erc20AssetDetails[_tokenId].length - 1) {
            erc20AssetDetails[_tokenId][index] = erc20AssetDetails[_tokenId][
                erc20AssetDetails[_tokenId].length - 1
            ];
        }
        erc20AssetDetails[_tokenId].pop();
    }

    /**
     * @notice  Transfer NFT assets associated with a NFT.
     * @param _nftContract,NFT asset contract address.
     * @param _assetId ,NFT asset token ID.
     * @return true.
     */
    function transferAsset(address _nftContract, uint256 _assetId)
        internal
        returns (bool)
    {
        ERC721(_nftContract).transferFrom(address(this), msg.sender, _assetId);
        require(
            ERC721(_nftContract).ownerOf(_assetId) == msg.sender,
            "Asset not removed"
        );
        return true;
    }

    /**
     * @notice To check the lock period .
     * @param _nftTokenId, Hexart token ID.
     * @return check, bool
     */
    function isLockPeriodOver(uint256 _nftTokenId) public view returns (bool) {
        bool check = block.timestamp >= assetLockPeriod[_nftTokenId];
        return check;
    }

    /**
     * @notice To check if asset is attached to any given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     * @return check assetIndex
     */
    function isAssetAttached(
        uint256 _nftTokenId,
        uint256 _assetId,
        address _assetContract
    ) internal view returns (bool, uint256) {
        bool check;
        uint256 assetIndex;
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        for (uint256 i = 0; i < array.length; i++) {
            if (
                array[i].nftTokenId == _assetId &&
                array[i].assettype == _assetContract
            ) {
                check = true;
                assetIndex = i;
                break;
            }
        }
        if (!check) {
            revert("Given Asset Id is not attached to this NFT");
        }
        return (check, assetIndex);
    }


     /**
     * @notice To check if asset is attached to any given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _nftTokenId, Hexart token ID.
     * @return check assetIndex
     */
    function isErcAssetAttached(
        uint256 _nftTokenId,
        address _assetContract
    ) internal view returns (bool, uint256) {
        bool check;
        uint256 assetIndex;
        ECR20Detail[] memory array = getERC20AssetsOfNFT(_nftTokenId);
        require(array.length>0,"No asset is attached to this hexart");
        for(uint256 i = 0; i < array.length; i++) {
            if (
                array[i].assettype == _assetContract
            ) {
                check = true;
                assetIndex = i;
                break;
            }
        }
        if (!check) {
            revert("Given Asset is not attached to this NFT");
        }
        return (check, assetIndex);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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