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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IHoldFarming {
    function curateCollection (address nftAddress) external;
    function holdFarmingBlocks(address nftAddress) external view returns (uint256, uint256);
    function initiateHoldFarmingForNFT(address nftAddress, uint256 tokenId) external;
    function updateCollectionPools() external;
    function updatePoolFor(address nftAddress) external;
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.8.0;

interface INFTRegistry {

    // Enums
    enum NamingCurrency {
        Ether,
        RNM,
        NamingCredits
    }
   
    function changeName(address nftAddress, uint256 tokenId, string calldata newName, NamingCurrency namingCurrency) external payable;
    function namingPriceEther() external view returns (uint256);
    function namingPriceRNM() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INamingCredits {
    function credits(address sender) external view returns (uint256);
    function reduceNamingCredits(address sender, uint256 numberOfCredits) external;
    function assignNamingCredits(address user, uint256 numberOfCredits) external;
    function shutOffAssignments() external;
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IPunks {

    function punkIndexToAddress(uint punkIndex) external view returns (address);
    function totalSupply() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IRNM is IERC20 {
    function SUPPLY_CAP() external view returns (uint256);

    function mint(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./IPunks.sol";
import "./IERC721.sol"; 
import "./ReentrancyGuard.sol";
import "./INamingCredits.sol";
import "./IWETH.sol";
import "./INFTRegistry.sol";
import "./IHoldFarming.sol";
import "./IRNM.sol"; 

/**
 * @title NFTRegistry
 * @notice NFTR's main contract. The registry. Where the magic happens.
 */
contract NFTRegistry is ReentrancyGuard, Ownable {

    // Structs
    struct Token {
        address collectionAddress;
        uint256 tokenId;
    }

    // Enums
    enum NamingCurrency {
        Ether,
        RNM,
        NamingCredits
    }
 
    enum NamingState {
        NotReadyYet,
        ReadyForNaming
    }

    NamingState public namingState = NamingState.NotReadyYet;

    // Naming prices, fee recipients, and control parameters
    uint256 public namingPriceEther = 0.05 ether;
    uint256 public immutable MIN_NAMING_PRICE_ETHER;
    uint256 public immutable MIN_NAMING_PRICE_RNM;
    uint256 public namingPriceRNM = 1000 * 10**18;
    address public protocolFeeRecipient;
    uint256 public constant INFINITE_BLOCK = 100000000000;
    uint256 public rnmNamingStartBlock = INFINITE_BLOCK;
    uint256 public constant MAX_NUMBER_CURATED_COLLECTIONS = 10;
    uint256 public numberCuratedCollections;
    uint256 public constant MAX_ASSIGNABLE_NAMING_CREDITS = 10;
    uint256 public constant MAX_TOTAL_ASSIGNABLE_NAMING_CREDITS = 1000;
    uint256 public totalNumberAssignedCredits;
    bool public allowUpdatingFeeRecipient = true;

    // Golden Tickets & Special Names
    uint256 public constant MAX_SPECIAL_NAMES_COUNT = 1000;
    uint256 public numberSpecialNames = 0;
    IERC20 public immutable goldenTicketAddress;
    mapping(string => bool) public specialNames; // List of special (reserved) names. Stored in lowercase.

    // Relevant contract addresses
    IPunks public immutable punksAddress;
    address public immutable WETH;
    IRNM public rnmToken;
    INamingCredits public namingCreditsAddress;
    IHoldFarming public holdFarmingAddress;
    address public marketplaceAddress;

    // Marketplace transfer allowance
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public allowances;

    // Name mappings
    mapping(address => mapping(uint256 => string)) public tokenName;
    mapping(string => Token) public tokenByName; // Stored in lowercase
    mapping(address => mapping(uint256 => uint256)) public firstNamed;

    // Events
    event NameChange(
        address indexed nftAddress,
        uint256 indexed tokenId,
        string newName,
        address sender,
        NamingCurrency namingCurrency,
        uint256 currencyQuantity
    );
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewNamingPriceEther(uint256 namingPriceEther);
    event NewNamingPriceRNM(uint256 namingPriceRNM);
    event NewRnmNamingStartBlock(uint256 rnmNamingStartBlock);
    event TransferAllowed(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );
    event TransferDisAllowed(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );
    event NameTransfer(
        address indexed nftAddressFrom,
        uint256 tokenIdFrom,
        address indexed nftAddressTo,
        uint256 tokenIdTo,
        string name,
        address transferer
    );

    /**
     * @notice Constructor
     * @param _punksAddress address of the CryptoPunks contract. Input to constructor for testing purposes
     * @param _goldenTicketAddress address of Golden Ticket contract
     * @param _WETH address of the WETH contract. Input to constructor for testing purposes
     * @param _protocolFeeRecipient protocol fee recipient
     * @param _minNamingPriceEther min naming price that can be set (in Ether)
     * @param _minNamingPriceRNM minimum naming price that can be set (in RNM)
     */
    constructor(
        address _punksAddress,
        address _goldenTicketAddress,
        address _WETH,
        address _protocolFeeRecipient,
        uint256 _minNamingPriceEther,
        uint256 _minNamingPriceRNM
    ) {
        require(_punksAddress != address(0), "NFTRegistry: In constructor, can't set punksAddress to zero");
        require(_goldenTicketAddress != address(0), "NFTRegistry: In constructor, can't set goldenTicketAddress to zero");
        require(_WETH != address(0), "NFTRegistry: In constructor, can't set WETH address to zero");
        require(_protocolFeeRecipient != address(0), "NFTRegistry: In constructor, can't set protocolFeeRecipient to zero");
        require(_minNamingPriceEther > 0, "NFTRegistry: min naming price in Ether must be non-zero");
        require(_minNamingPriceRNM > 0, "NFTRegistry: min naming price in RNM must be non-zero");
        punksAddress = IPunks(_punksAddress);
        goldenTicketAddress = IERC20(_goldenTicketAddress);
        WETH = address(_WETH);
        protocolFeeRecipient = _protocolFeeRecipient;
        MIN_NAMING_PRICE_ETHER = _minNamingPriceEther;
        MIN_NAMING_PRICE_RNM = _minNamingPriceRNM;
    }

    /**
     * @notice Set the RNM address (only once)
     * @param _rnmToken address of the RNM token
     */
    function setRnmTokenAddress(IRNM _rnmToken) external onlyOwner {
        require(
            address(rnmToken) == address(0),
            "NFTRegistry: RNM address has already been set"
        );
        rnmToken = _rnmToken;
    }

    /**
     * @notice Set the Naming Credits contract address once deployed
     * @param _namingCreditsAddress address of the marketplace contract
     */
    function setNamingCreditsAddress(INamingCredits _namingCreditsAddress)
        external
        onlyOwner
    {
        require(
            address(namingCreditsAddress) == address(0),
            "NFTRegistry: naming credits contract address can only be set once"
        );
        namingCreditsAddress = _namingCreditsAddress;
    }

    /**
     * @notice Set the Hold Farming contract address once deployed
     * @param _holdFarmingAddress address of the marketplace contract
     */
    function setHoldFarmingAddress(IHoldFarming _holdFarmingAddress)
        external
        onlyOwner
    {
        require(
            address(holdFarmingAddress) == address(0),
            "NFTRegistry: hold farming contract address can only be set once"
        );
        holdFarmingAddress = _holdFarmingAddress;
    }

    /**
     * @notice Set the Marketplace contract address once deployed
     * @param _marketplaceAddress address of the marketplace contract
     */
    function setMarketplaceAddress(address _marketplaceAddress)
        external
        onlyOwner
    {
        require(
            marketplaceAddress == address(0),
            "NFTRegistry: marketplace contract address can only be set once"
        );
        marketplaceAddress = _marketplaceAddress;
    }

    /**
     * @notice Give the marketplace contract permission to transfer name (for a name sale) for a particular NFT. Care is taken so that if the NFT changes owners, the allowance doesn't hold.
     * @param nftAddress address of the NFT Collection from which name is being transferred
     * @param tokenId token id of the NFT from which the name is being transferred
     */
    function allowTransfer(address nftAddress, uint256 tokenId) external {
        require(
            marketplaceAddress != address(0),
            "NFTRegistry: Marketplace address hasn't been set yet"
        );
        checkOwnership(nftAddress, tokenId); // allowance setter must be the NFT owner

        allowances[msg.sender][nftAddress][tokenId] = true;

        emit TransferAllowed(msg.sender, nftAddress, tokenId);
    }

    /**
     * @notice Disallow marketplace contract to transfer name for a particular NFT
     * @param nftAddress address of the NFT Collection from which name is being transferred
     * @param tokenId token id of the NFT from which the name is being transferred
     */
    function disallowTransfer(address nftAddress, uint256 tokenId) external {
        require(
            marketplaceAddress != address(0),
            "NFTRegistry: Marketplace address hasn't been set yet"
        );
        checkOwnership(nftAddress, tokenId);

        allowances[msg.sender][nftAddress][tokenId] = false;

        emit TransferDisAllowed(msg.sender, nftAddress, tokenId);
    }

    /**
     * @notice Used by the marketplace contract to transfer a name from one NFT to another. Transfer allowance isn't reset, so if the NFT is named again it doesn't have to be allowed again to transfer its name, as long as it's still owned by the same allower. Transfer allowance is per owner, so doesn't travel with the NFT.
     * @param nftAddressFrom address of the NFT Collection from which name is being transferred
     * @param tokenIdFrom token id of the NFT from which the name is being transferred
     * @param nftAddressTo address of the NFT Collection to which name is being transferred
     * @param tokenIdTo token id of the NFT to which the name is being transferred
     */
    function transferName(
        address nftAddressFrom,
        uint256 tokenIdFrom,
        address nftAddressTo,
        uint256 tokenIdTo
    ) external {
        require(
            marketplaceAddress != address(0),
            "NFTRegistry: Marketplace address hasn't been set yet"
        );
        require(
            msg.sender == marketplaceAddress,
            "NFTRegistry: Only the Marketplace contract can make this call"
        );

        // Obtain current NFT owner
        address nftOwner = getOwner(nftAddressFrom, tokenIdFrom);

        // Check that name can be transferred
        require(
            allowances[nftOwner][nftAddressFrom][tokenIdFrom],
            "NFTRegistry: NFT hasn't been allowed for name transfer"
        );

        // Check that token mapping is set
        string memory _tokenName = tokenName[nftAddressFrom][tokenIdFrom];
        require(
            bytes(_tokenName).length > 0,
            "NFTRegistry: Can't transfer name as it isn't set"
        );
        // Transfer name
        tokenName[nftAddressFrom][tokenIdFrom] = "";
        tokenName[nftAddressTo][tokenIdTo] = _tokenName;
        tokenByName[toLower(_tokenName)] = Token(nftAddressTo, tokenIdTo);

        emit NameTransfer(
            nftAddressFrom,
            tokenIdFrom,
            nftAddressTo,
            tokenIdTo,
            _tokenName,
            nftOwner
        );
    }

    /**
     * @notice Update the naming price in ETH
     * @param _namingPriceEther naming price in Ether
     */
    function updateNamingPriceEther(uint256 _namingPriceEther)
        external
        onlyOwner
    {
        require(
            _namingPriceEther >= MIN_NAMING_PRICE_ETHER,
            "NFTRegistry: ETHER naming price too low"
        );
        namingPriceEther = _namingPriceEther;

        emit NewNamingPriceEther(namingPriceEther);
    }

    /**
     * @notice Update the naming price in RNM
     * @param _namingPriceRNM naming price in RNM
     */
    function updateNamingPriceRNM(uint256 _namingPriceRNM) external onlyOwner {
        require(
            _namingPriceRNM >= MIN_NAMING_PRICE_RNM,
            "NFTRegistry: RNM naming price too low"
        );
        namingPriceRNM = _namingPriceRNM;

        emit NewNamingPriceRNM(namingPriceRNM);
    }

    /**
     * @notice Update the recipient of protocol (naming) fees in WETH
     * @param _protocolFeeRecipient protocol fee recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        require(allowUpdatingFeeRecipient, "NFTRegistry: Updating the protocol fee recipient has been shut off");
        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }

    /**
     * @notice Update starting block for RNM naming
     * @param _rnmNamingStartBlock starting block of RNM naming
     */
    function updateRnmNamingStartBlock(uint256 _rnmNamingStartBlock)
        external
        onlyOwner
    {
        require(
            rnmNamingStartBlock == INFINITE_BLOCK,
            "NFTRegistry: rnmNamingStartBlock can only be set once"
        );
        require(
            _rnmNamingStartBlock > block.number,
            "NFTRegistry: RNM naming start block can't be set to past"
        );
        require(
            _rnmNamingStartBlock < block.number + 192000, // + 1 month
            "NFTRegistry: RNM naming start block can't be set so far in advance"
        );
        rnmNamingStartBlock = _rnmNamingStartBlock;

        emit NewRnmNamingStartBlock(rnmNamingStartBlock);
    }

    /**
     * @notice Returns name of the NFT at (address, index).
     * @param nftAddress Address of NFT collection
     * @param index token index of NFT within collection
     */
    function tokenNameByIndex(address nftAddress, uint256 index)
        external
        view
        returns (string memory)
    {
        return tokenName[nftAddress][index];
    }

    /**
     * @notice Sets/Changes the name of an NFT
     * @param nftAddress address of the NFT collection
     * @param tokenId NFT token id
     * @param newName name to register for the NFT with tokenId
     * @param namingCurrency currency used for naming fee
     * @param currencyQuantity quantity of naming currency to spend. This disables the contract owner from being able to front-run naming to extract unintended quantiy of assets (WETH or RNM)
     */
    function changeName(
        address nftAddress,
        uint256 tokenId,
        string memory newName,
        NamingCurrency namingCurrency,
        uint256 currencyQuantity
    ) external payable nonReentrant {
        require(
            namingState == NamingState.ReadyForNaming,
            "NFTRegistry: Not ready for naming yet"
        );
        checkOwnership(nftAddress, tokenId);
        require(
            validateName(newName),
            "NFTRegistry: Not a valid new name"
        );
        require(
            sha256(bytes(newName)) !=
                sha256(bytes(tokenName[nftAddress][tokenId])),
            "NFTRegistry: New name is same as the current one"
        );
        require(
            isTokenStructEmpty(tokenByName[toLower(newName)]),
            "NFTRegistry: Name already reserved"
        );
        if (namingCurrency == NamingCurrency.NamingCredits) {
            require(currencyQuantity == 1, "NFTRegistry: currencyQuantity must be 1 when naming with Naming Credits");
        }
        else if (namingCurrency == NamingCurrency.RNM) {
            require(currencyQuantity == namingPriceRNM, "NFTRegistry: currencyQuantity must be equal to namingPriceRNM when naming with RNM");            
        }
        else { // namingCurrency is Ether
            require(currencyQuantity == namingPriceEther, "NFTRegistry: currencyQuantity must be equal to namingPriceEther when naming with Ether");               
        }

        // Check if the name is from the special list and thus golden ticket is required and available
        if (specialNames[toLower(newName)]) {
            IERC20(goldenTicketAddress).transferFrom(
                msg.sender,
                address(this),
                1
            );
        }

        if (
            namingCurrency == NamingCurrency.RNM &&
            block.number < rnmNamingStartBlock
        ) {
            revert("NFTRegistry: Not ready for naming paid with RNM");
        }

        bool freeNaming = false;
        if (address(holdFarmingAddress) != address(0) && firstNamed[nftAddress][tokenId] == 0) {
            // Check if the NFT being named is curated and is still in hold farming period
            (uint256 startBlock, uint256 lastBlock) = 
                holdFarmingAddress.holdFarmingBlocks(nftAddress);
            if (block.number >= startBlock && block.number <= lastBlock) {
                // Hold farming is still enabled for this collection. Allow free naming.
                holdFarmingAddress.initiateHoldFarmingForNFT(
                    nftAddress,
                    tokenId
                );

                freeNaming = true;
            }
        }

        if (!freeNaming) {
            if (namingCurrency == NamingCurrency.Ether) {
                // If not enough ETH to cover the price, use WETH
                if (namingPriceEther > msg.value) {
                    require(
                        IERC20(WETH).balanceOf(msg.sender) >=
                            (namingPriceEther - msg.value),
                        "NFTRegistry: Not enough ETH sent or WETH available"
                    );
                    IERC20(WETH).transferFrom(
                        msg.sender,
                        address(this),
                        (namingPriceEther - msg.value)
                    );
                } else {
                    require(
                        namingPriceEther == msg.value,
                        "NFTRegistry: Too much Ether sent for naming"
                    );
                }

                // Wrap ETH sent to this contract 
                IWETH(WETH).deposit{value: msg.value}();
                IERC20(WETH).transfer(
                    protocolFeeRecipient,
                    namingPriceEther
                );
            } else if (namingCurrency == NamingCurrency.NamingCredits) {
                require(
                    address(namingCreditsAddress) != address(0),
                    "NFTRegistry: Naming Credits contract isn't set yet"
                );
                namingCreditsAddress.reduceNamingCredits(
                    msg.sender,
                    1
                );
            } else if (namingCurrency == NamingCurrency.RNM) {
                require(
                    address(rnmToken) != address(0),
                    "NFTRegistry: RNM contract isn't set yet"
                );
                IERC20(rnmToken).transferFrom(
                    msg.sender,
                    address(this),
                    namingPriceRNM
                );
                IRNM(rnmToken).burn(namingPriceRNM);
            } else {
                revert("NFTRegistry: The currency isn't supported for naming");
            }   
        }

        // If already named, dereserve old name
        if (bytes(tokenName[nftAddress][tokenId]).length > 0) {
            releaseTokenByName(tokenName[nftAddress][tokenId]);
        }
        tokenByName[toLower(newName)] = Token(nftAddress, tokenId);
        tokenName[nftAddress][tokenId] = newName;

        if (firstNamed[nftAddress][tokenId] == 0) {
            firstNamed[nftAddress][tokenId] = block.number;
        }
        emit NameChange(
            nftAddress,
            tokenId,
            newName,
            msg.sender,
            namingCurrency,
            currencyQuantity
        );
    }

    /**
     * @notice Check if the message sender owns the NFT
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function checkOwnership(address nftAddress, uint256 tokenId) internal view {
        require(msg.sender == getOwner(nftAddress, tokenId), "NFTRegistry: Caller is not the NFT owner");
    }

    /**
     * @notice Get NFT's owner
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function getOwner(address nftAddress, uint256 tokenId)
        internal
        view
        returns (address)
    {
        if (nftAddress == address(punksAddress)) {
            return IPunks(punksAddress).punkIndexToAddress(tokenId);
        } else {
            return IERC721(nftAddress).ownerOf(tokenId);
        }
    }

    /**
     * @notice Check if a Token structure is empty
     * @param token_in token to check
     */
    function isTokenStructEmpty(Token memory token_in)
        internal
        pure
        returns (bool)
    {
        return (token_in.collectionAddress == address(0) && token_in.tokenId == 0);
    }

    /**
     * @notice Returns NFT collection contract address and tokenId in Token struct if the name is reserved
     * @param nameString name of the NFT
     */
    function getTokenByName(string memory nameString)
        external
        view
        returns (Token memory)
    {
        return tokenByName[toLower(nameString)];
    }

    /**
     * @notice Releases the name so another person can register it
     * @param str name to deregister
     */
    function releaseTokenByName(string memory str) internal {
        delete tokenByName[toLower(str)];
    }

    /**
     * @notice Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     * @param str name to validate
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @notice Converts the string to lowercase
     * @param str string to convert
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @notice Adds special names to the special names list. Unfortunately can't be handled with a Merkle Tree as they can only be used to prove that a nem is in a set, but not that a name is not in a set. That is, non-special names can't be checked against such Merkle Tree. So we are only left with burning the special names into the contract state.
     * @param _specialNames array of special names to reserve
     */
    function setSpecialNames(string[] memory _specialNames) external onlyOwner {
        require(
            numberSpecialNames + _specialNames.length <=
                MAX_SPECIAL_NAMES_COUNT,
            "NFTRegistry: This would make special names list longer than allowed"
        );
        for (uint256 i = 0; i < _specialNames.length; i++) {
            require(
                !specialNames[toLower(_specialNames[i])],
                "NFTRegistry: At least one of the names is already in the special list"
            );
            specialNames[toLower(_specialNames[i])] = true;
            numberSpecialNames++;
        }
        if (numberSpecialNames == MAX_SPECIAL_NAMES_COUNT) {
            namingState = NamingState.ReadyForNaming;
        }
    }

    /**
     * @notice Assign naming credits in the NamingCredits contract. Avoids mistakes assigning more than 10 credits.
     * @param user address of the user assigning credits to
     * @param numberOfCredits number of credits to assign
     */
    function assignNamingCredits(address user, uint256 numberOfCredits)
        external
        onlyOwner
    {
        require(
            address(namingCreditsAddress) != address(0),
            "NFTRegistry: Naming Credits contract isn't set yet"
        );
        require(numberOfCredits <= MAX_ASSIGNABLE_NAMING_CREDITS, "NFTRegistry: Can't assign that number of credits in a single call");
        require(totalNumberAssignedCredits + numberOfCredits <= MAX_TOTAL_ASSIGNABLE_NAMING_CREDITS, "NFTRegistry: Assigning that number of credits would take total assigned credits over the limit");
        totalNumberAssignedCredits += numberOfCredits;
        namingCreditsAddress.assignNamingCredits(
            user,
            numberOfCredits
        );
    }

    /**
     * @notice Shut off naming credit assignments in the NamingCredits contract
     */
    function shutOffAssignments() external onlyOwner {
        require(
            address(namingCreditsAddress) != address(0),
            "NFTRegistry: Naming Credits contract isn't set yet"
        );
        namingCreditsAddress.shutOffAssignments();
    }

    /**
     * @notice Shut off protocol fee recipient updates
     */
    function shutOffFeeRecipientUpdates() external onlyOwner {
        allowUpdatingFeeRecipient = false;
    }    

    /**
     * @notice Update protocol fee recipient in the NamingCredits contract
     */
    function updateNamingCreditsProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external onlyOwner {
        require(
            address(namingCreditsAddress) != address(0),
            "NFTRegistry: Naming Credits contract isn't set yet"
        );
        require(allowUpdatingFeeRecipient, "NFTRegistry: Updating the protocol free recipient has been shut off");
        namingCreditsAddress.updateProtocolFeeRecipient(
            _protocolFeeRecipient
        );
    }

    /**
     * @notice Call the HoldFarming contract curateCollection function
     * @param nftAddress address of the NFT collection contract to be curated
     */
    function curateCollection(address nftAddress) external onlyOwner {
        require(
            address(holdFarmingAddress) != address(0),
            "NFTRegistry: Hold Farming contract isn't set yet"
        );
        require(numberCuratedCollections < MAX_NUMBER_CURATED_COLLECTIONS, "NFTRegistry: Number of curated collections has been maxed out");
        numberCuratedCollections++;
        holdFarmingAddress.curateCollection(nftAddress);
    }

    /**
     * @notice Withdraw any RNM that got sent to the contract by accident
     */
    function withdrawRNM() external onlyOwner {
        require(
            address(rnmToken) != address(0),
            "NFTRegistry: RNM contract isn't set yet"
        );
        uint256 withdrawableRNM = IERC20(rnmToken).balanceOf(address(this));
        require(
            withdrawableRNM != 0,
            "NFTRegistry: There is no RNM to withdraw"
        );
        IERC20(rnmToken).transfer(
            msg.sender,
            withdrawableRNM
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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