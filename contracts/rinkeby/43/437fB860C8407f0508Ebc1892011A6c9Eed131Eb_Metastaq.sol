// SPDX-License-Identifier: MIT
      // https://metastaq.mypinata.cloud/ipfs/QmYgsYugp5makRBagkxQ9RG96Q2qGN8jLn29wryrtoey4f/
      pragma solidity ^0.8.4;
      
      import "./ERC721A.sol";
      import "./IMetastaq.sol";
      import "./ERC721AQueryable.sol";
      import "./Ownable.sol";
      import "./ReentrancyGuard.sol";
      import "./ERC2981.sol";
      import "./SafeMath.sol";
      import "./Address.sol";
      
      /// @title A AirDrop Contract
/// @notice You can use this contract for  AirDrop Only
/// @dev All function calls are currently implemented without side effects
contract Metastaq is
    IMetastaq,
    ERC721AQueryable,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    /// maxPerAddressDuringMint the max token user can hold
    uint256 public immutable maxPerAddressDuringMint;
    /// amountForDevs number of token for dev
    uint256 public immutable amountForDevs;
    address[] private whitelistAddress;

    uint256 internal immutable collectionSize;
    uint256 internal immutable maxBatchSize;
    address private hotWallet;

    using SafeMath for uint256;
    using SafeMath for uint96;
    struct SaleConfig {
        bool isPublicSaleStarted;
        uint96 allowListPrice;
        uint96 publicPrice;
    }

    SaleConfig public saleConfig;

    mapping(address => uint256) public allowList;

    // // metadata URI
    string private _baseTokenURI;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    /// @notice Constructor of Contract
    /// @param tokenName_ The name of token
    /// @param tokenSymbol_ The symbol of token
    /// @param maxBatchSize_ max batch to mint at once
    /// @param collectionSize_ The total supply allow to be minted
    /// @param hotWallet_ The wallet used to perform action as owner
    /// @param amountForDevs_ The amount token for dev
    /// @param isPublicSaleStarted_ The public sale started falg
    /// @param royaltyFeesInBips_ The BIPS for royalty
    /// @param publicPrice_  public price of Token
    /// @param allowListPrice_ mint list price in wei
    /// @param baseTokenURI_ base uri of collection
    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        address hotWallet_,
        uint256 amountForDevs_,
        bool isPublicSaleStarted_,
        uint96 royaltyFeesInBips_,
        uint96 publicPrice_,
        uint96 allowListPrice_,
        string memory baseTokenURI_
    ) ERC721A(tokenName_, tokenSymbol_) {
        maxPerAddressDuringMint = 4;
        amountForDevs = amountForDevs_;
        _baseTokenURI = baseTokenURI_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
        hotWallet = hotWallet_;
        saleConfig.isPublicSaleStarted = isPublicSaleStarted_;
        saleConfig.allowListPrice = allowListPrice_;
        saleConfig.publicPrice = publicPrice_;
        _setDefaultRoyalty(_msgSenderERC721A(), royaltyFeesInBips_);
    }

    // =============================================================
    //                  Function Modifers
    // =============================================================

    modifier isOwnerOrHotWallet() {
        if (
            !(owner() == _msgSenderERC721A() ||
                _msgSenderERC721A() == getHotWallet())
        ) revert NotAllowedToCall();
        _;
    }

    modifier callerIsUser() {
        if (!(tx.origin == _msgSenderERC721A()))
            revert ContractNotAllowedToMint();
        _;
    }

    // =============================================================
    //                   Royalty Operation
    // =============================================================

    /**
     * @dev setUp royaltyFeesInBips to address receiver.
     * The Perivous Royalty will be overirden.
     *
     * This function setup single Royalty for all tokens.
     *
     * Requirements:
     *
      *
     * - The caller must be current  owner of contract or hot wallet.
     *
     */

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        external
        isOwnerOrHotWallet
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
        emit RoyaltyInfoUpdated(_receiver, _royaltyFeesInBips);
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * interfaceId. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // The Contract would Check for ERC2981 Interface Support and ERC721A.
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    // =============================================================
    //                         Air Drop  Operations
    // =============================================================

    /**
     * @dev Setup AirDrop Values  isPublicSaleStarted isPublicSaleStarted  allowListPriceWei allowListPriceWei publicPriceWei publicPriceWei
     *  setup values for Air Drop and On public and allowlist sale
     *
     */
    function setupSaleInfo(
        bool isPublicSaleStarted,
        uint96 allowListPriceWei,
        uint96 publicPriceWei
    ) external isOwnerOrHotWallet {
        saleConfig = SaleConfig(
            isPublicSaleStarted,
            allowListPriceWei,
            publicPriceWei
        );
    }

    /**
     * @dev Mint Token to to quantity quantity _type _Type
     *  Mint token to allowlist users, the record of allowlist token would be updated
     *
     * Requirement
     * - The _type is provided to handle between ETH and Fiat Payment
     * - In case of _type fiat the contract assume that Owner has received payment and The Caller is AllowedUser
     * - Check For Available Token Supply
     * - Check For Max Mint limit
     * - Check For allowLint Mint Price
     * - Would return Fund if Provided More then Price
     */
    function allowlistMint(
        address to,
        uint256 quantity,
        bytes32 _type /*callerIsUser*/
    ) external payable {
        if (!(_type == "fiat" || _type == "crypto"))
            revert InvalidPaymentType();

        uint96 price = uint96(saleConfig.allowListPrice);
        if (price == 0) revert AllowListMintNotStarted();
        if (allowList[to] == 0) revert NotInAllowList();
        if (quantity > allowList[to]) revert ExceedsAllowListLimit();
        if (numberMinted(to).add(quantity) > maxPerAddressDuringMint)
            revert ExceedsMaxMintLimit();
        if (totalSupply().add(quantity) > collectionSize)
            revert ExceedsSupply();
        if (_type == "fiat") {
            if (
                !(_msgSenderERC721A() == getHotWallet() ||
                    _msgSenderERC721A() == owner())
            ) revert NotAllowedToCall();
            allowList[to] = allowList[to].sub(quantity);
            _setAux(to, uint64(quantity.add(balanceOf(to))));
            _safeMint(to, quantity);
        } else {
            allowList[to] = allowList[to].sub(quantity);
            _setAux(to, uint64(quantity.add(balanceOf(to))));
            _safeMint(to, quantity);
            refundIfOver(price.mul(quantity));
        }
        emit AllowListMint(to, quantity);
    }

    /**
     * @dev Mint Token to to quantity quantity _type _type
     *  Mint token during Public Sale and receive Fund
     *
     * Requirement
     * - The _type is provided to handle between ETH and Fiat Payment
     * - In case of _type fiat the contract assume that Owner has received payment and The Caller is AllowedUser
     * - Check For Available Token Supply
     * - Check For Max Mint limit
     * - Check For Public Sale On
     * - Would return Fund if Provided More then Price
     */
    function publicSaleMint(
        address to,
        uint256 quantity,
        bytes32 _type /*callerIsUser*/
    ) external payable {
        if (!(_type == "fiat" || _type == "crypto"))
            revert InvalidPaymentType();
        // SaleConfig memory config = saleConfig;
        uint96 publicPrice = uint96(saleConfig.publicPrice);
        if (!isPublicSaleOn()) revert PublicSaleNotStarted();
        if (numberMinted(to).add(quantity) > maxPerAddressDuringMint)
            revert ExceedsMaxMintLimit();
        if (totalSupply().add(quantity) > collectionSize)
            revert ExceedsSupply();
        if (_type == "fiat") {
            if (
                !(_msgSenderERC721A() == getHotWallet() ||
                    _msgSenderERC721A() == owner())
            ) revert NotAllowedToCall();
            _safeMint(to, quantity);
        } else {
            _safeMint(to, quantity);
            refundIfOver(publicPrice.mul(quantity));
        }
        emit PublicSaleMint(to, quantity, publicPrice);
    }

    /**
     * @dev Add Allow List addresses  addresses numSlots numSlots
     *  Add Allow list users with Number of Token allowed to mint
     *
     * Requirement
     * - The Length of Addresses and numSlot array must be equal
     * - Will remove current Allow list
     */
    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external isOwnerOrHotWallet {
        if (addresses.length != numSlots.length)
            revert ArraysLengthNotMatched();
        if (whitelistAddress.length > 0) {
            for (uint256 i = 0; i < whitelistAddress.length; i++) {
                delete allowList[whitelistAddress[i]];
            }
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numSlots[i];
        }
        whitelistAddress = addresses;
        emit WhiteListUpdated();
    }

    /**
     * @dev mint quantity  quantity to caller
     * quantity will be Minted to Caller
     *
     * Requirement
     * - The DevMint Token will immediately minted after contract deployment
     * - Will check for amountForDevs
     * - Will check for Supply
     * - will check for Max batch size
     */

    function devMint(uint256 quantity) external isOwnerOrHotWallet {
        if (totalSupply().add(quantity) > amountForDevs)
            revert ExceedsDevMintLimit();
        if (totalSupply().add(quantity) > collectionSize)
            revert ExceedsSupply();
        if (quantity.mod(maxBatchSize) != 0) revert NotMultipleOfMaxBatchSize();
        uint256 numChunks = quantity / maxBatchSize;
        //--solc-disable-warnings
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(_msgSenderERC721A(), maxBatchSize);
        }
        emit DevMint(_msgSenderERC721A(), quantity);
    }

    /**
     * @dev Returns the isPublicSaleOn flag. true if public sale is on.
     */
    function isPublicSaleOn() public view returns (bool) {
        return bool(saleConfig.isPublicSaleStarted);
    }

    /**
     * @dev Returns the getHotWallet address.
     */
    function getHotWallet() public view returns (address) {
        return hotWallet;
    }

    /**
     * @dev Returns the updateHotWallet address.
     *  will help Dev Team to Rotate Hot wallet
     * Requirements
     * - the caller must be owner
     * - The address Must be EOA
     */
    function updateHotWallet(address hotWallet_) public onlyOwner {
        if (Address.isContract(hotWallet_)) revert ContractAddressNotAllowed();
        hotWallet = hotWallet_;
    }

    // =============================================================
    //                         ERC721A Operations
    // =============================================================

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the baseURI and the tokenId
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set Base URI for computing {tokenURI}. will be Set for All tokens, the resulting URI for each
     * token will be the concatenation of the baseURI and the tokenId
     */
    function setBaseURI(string calldata baseURI) external isOwnerOrHotWallet {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Number Minted of owner owner
     * Returns Number of Token Minted By owner
     */
    function numberMinted(address owner_) public view returns (uint256) {
        return _numberMinted(owner_);
    }

    /**
     * @dev Get  Aux of owner owner
     * Returns  auxiliary data for owner. in our case will return AllowList Token minted
     */
    function getAux(address owner) external view returns (uint64) {
        return _getAux(owner);
    }

    /**
     * @dev get OwnerShip Data of Token id tokenId
     * Returns Token OwnerShip data of token id.
     */
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    // =============================================================
    //                            Fund Operations
    // =============================================================

    /**
     * @dev With Draw Money  will be used withdraw eth from contract
     *  Reenrrant Gurad inplace to block  recuseve calling
     *
     * Requirement
     * - The Caller must be Owner or Hot Wallet
     *
     */
    function withdrawMoney() external isOwnerOrHotWallet nonReentrant {
        (bool success, bytes memory error) = _msgSenderERC721A().call{
            value: address(this).balance
        }("");
        require(success, string(error));
    }

    /**
     * @dev Refund If Over check price price
     * if insufficient ETH value supplied it will revert
     * return extra ETH to caller
     *
     */
    function refundIfOver(uint256 price) private {
        if (msg.value < price) revert InsufficientPayment();
        if (msg.value > price) {
            (bool success, bytes memory returnError) = payable(
                _msgSenderERC721A()
            ).call{value: (msg.value).sub(price)}("");
            require(success, string(returnError));
        }
    }

    /**
     * @dev contract can receive Ether.  msg.data is not empty
     */
    receive() external payable {}

    /**
     * @dev contract can receive Ether.
     */
    fallback() external payable {}
}