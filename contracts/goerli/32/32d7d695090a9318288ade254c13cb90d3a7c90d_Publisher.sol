// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccessControlRegistry {
    
    function name() external view returns (string memory);    
    
    function initializeWithData(bytes memory initData) external;
    
    function getAccessLevel(address, address) external view returns (uint256);
    
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
pragma solidity ^0.8.10;

import {IMetadataRenderer} from "../interfaces/IMetadataRenderer.sol";

/**

 ________   _____   ____    ______      ____
/\_____  \ /\  __`\/\  _`\ /\  _  \    /\  _`\
\/____//'/'\ \ \/\ \ \ \L\ \ \ \L\ \   \ \ \/\ \  _ __   ___   _____     ____
     //'/'  \ \ \ \ \ \ ,  /\ \  __ \   \ \ \ \ \/\`'__\/ __`\/\ '__`\  /',__\
    //'/'___ \ \ \_\ \ \ \\ \\ \ \/\ \   \ \ \_\ \ \ \//\ \L\ \ \ \L\ \/\__, `\
    /\_______\\ \_____\ \_\ \_\ \_\ \_\   \ \____/\ \_\\ \____/\ \ ,__/\/\____/
    \/_______/ \/_____/\/_/\/ /\/_/\/_/    \/___/  \/_/ \/___/  \ \ \/  \/___/
                                                                 \ \_\
                                                                  \/_/

*/

/// @notice Interface for ZORA Drops contract
interface IERC721Drop {
    // Access errors

    /// @notice Only admin can access this function
    error Access_OnlyAdmin();
    /// @notice Missing the given role or admin access
    error Access_MissingRoleOrAdmin(bytes32 role);
    /// @notice Withdraw is not allowed by this user
    error Access_WithdrawNotAllowed();
    /// @notice Cannot withdraw funds due to ETH send failure.
    error Withdraw_FundsSendFailure();

    /// @notice Thrown when the operator for the contract is not allowed
    /// @dev Used when strict enforcement of marketplaces for creator royalties is desired.
    error OperatorNotAllowed(address operator);

    /// @notice Thrown when there is no active market filter DAO address supported for the current chain
    /// @dev Used for enabling and disabling filter for the given chain.
    error MarketFilterDAOAddressNotSupportedForChain();

    /// @notice Used when the operator filter registry external call fails
    /// @dev Used for bubbling error up to clients. 
    error RemoteOperatorFilterRegistryCallFailed();

    // Sale/Purchase errors
    /// @notice Sale is inactive
    error Sale_Inactive();
    /// @notice Presale is inactive
    error Presale_Inactive();
    /// @notice Presale merkle root is invalid
    error Presale_MerkleNotApproved();
    /// @notice Wrong price for purchase
    error Purchase_WrongPrice(uint256 correctPrice);
    /// @notice NFT sold out
    error Mint_SoldOut();
    /// @notice Too many purchase for address
    error Purchase_TooManyForAddress();
    /// @notice Too many presale for address
    error Presale_TooManyForAddress();

    // Admin errors
    /// @notice Royalty percentage too high
    error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
    /// @notice Invalid admin upgrade address
    error Admin_InvalidUpgradeAddress(address proposedAddress);
    /// @notice Unable to finalize an edition not marked as open (size set to uint64_max_value)
    error Admin_UnableToFinalizeNotOpenEdition();

    /// @notice Event emitted for each sale
    /// @param to address sale was made to
    /// @param quantity quantity of the minted nfts
    /// @param pricePerToken price for each token
    /// @param firstPurchasedTokenId first purchased token ID (to get range add to quantity for max)
    event Sale(
        address indexed to,
        uint256 indexed quantity,
        uint256 indexed pricePerToken,
        uint256 firstPurchasedTokenId
    );

    /// @notice Sales configuration has been changed
    /// @dev To access new sales configuration, use getter function.
    /// @param changedBy Changed by user
    event SalesConfigChanged(address indexed changedBy);

    /// @notice Event emitted when the funds recipient is changed
    /// @param newAddress new address for the funds recipient
    /// @param changedBy address that the recipient is changed by
    event FundsRecipientChanged(
        address indexed newAddress,
        address indexed changedBy
    );

    /// @notice Event emitted when the funds are withdrawn from the minting contract
    /// @param withdrawnBy address that issued the withdraw
    /// @param withdrawnTo address that the funds were withdrawn to
    /// @param amount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event FundsWithdrawn(
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount,
        address feeRecipient,
        uint256 feeAmount
    );

    /// @notice Event emitted when an open mint is finalized and further minting is closed forever on the contract.
    /// @param sender address sending close mint
    /// @param numberOfMints number of mints the contract is finalized at
    event OpenMintFinalized(address indexed sender, uint256 numberOfMints);

    /// @notice Event emitted when metadata renderer is updated.
    /// @param sender address of the updater
    /// @param renderer new metadata renderer address
    event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

    /// @notice General configuration for NFT Minting and bookkeeping
    struct Configuration {
        /// @dev Metadata renderer (uint160)
        IMetadataRenderer metadataRenderer;
        /// @dev Total size of edition that can be minted (uint160+64 = 224)
        uint64 editionSize;
        /// @dev Royalty amount in bps (uint224+16 = 240)
        uint16 royaltyBPS;
        /// @dev Funds recipient for sale (new slot, uint160)
        address payable fundsRecipient;
    }

    /// @notice Sales states and configuration
    /// @dev Uses 3 storage slots
    struct SalesConfiguration {
        /// @dev Public sale price (max ether value > 1000 ether with this value)
        uint104 publicSalePrice;
        /// @notice Purchase mint limit per address (if set to 0 === unlimited mints)
        /// @dev Max purchase number per txn (90+32 = 122)
        uint32 maxSalePurchasePerAddress;
        /// @dev uint64 type allows for dates into 292 billion years
        /// @notice Public sale start timestamp (136+64 = 186)
        uint64 publicSaleStart;
        /// @notice Public sale end timestamp (186+64 = 250)
        uint64 publicSaleEnd;
        /// @notice Presale start timestamp
        /// @dev new storage slot
        uint64 presaleStart;
        /// @notice Presale end timestamp
        uint64 presaleEnd;
        /// @notice Presale merkle root
        bytes32 presaleMerkleRoot;
    }

    /// @notice Return value for sales details to use with front-ends
    struct SaleDetails {
        // Synthesized status variables for sale and presale
        bool publicSaleActive;
        bool presaleActive;
        // Price for public sale
        uint256 publicSalePrice;
        // Timed sale actions for public sale
        uint64 publicSaleStart;
        uint64 publicSaleEnd;
        // Timed sale actions for presale
        uint64 presaleStart;
        uint64 presaleEnd;
        // Merkle root (includes address, quantity, and price data for each entry)
        bytes32 presaleMerkleRoot;
        // Limit public sale to a specific number of mints per wallet
        uint256 maxSalePurchasePerAddress;
        // Information about the rest of the supply
        // Total that have been minted
        uint256 totalMinted;
        // The total supply available
        uint256 maxSupply;
    }

    /// @notice Return type of specific mint counts and details per address
    struct AddressMintDetails {
        /// Number of total mints from the given address
        uint256 totalMints;
        /// Number of presale mints from the given address
        uint256 presaleMints;
        /// Number of public mints from the given address
        uint256 publicMints;
    }

    /// @notice External purchase function (payable in eth)
    /// @param quantity to purchase
    /// @return first minted token ID
    function purchase(uint256 quantity) external payable returns (uint256);

    /// @notice External purchase presale function (takes a merkle proof and matches to root) (payable in eth)
    /// @param quantity to purchase
    /// @param maxQuantity can purchase (verified by merkle root)
    /// @param pricePerToken price per token allowed (verified by merkle root)
    /// @param merkleProof input for merkle proof leaf verified by merkle root
    /// @return first minted token ID
    function purchasePresale(
        uint256 quantity,
        uint256 maxQuantity,
        uint256 pricePerToken,
        bytes32[] memory merkleProof
    ) external payable returns (uint256);

    /// @notice Function to return the global sales details for the given drop
    function saleDetails() external view returns (SaleDetails memory);

    /// @notice Function to return the specific sales details for a given address
    /// @param minter address for minter to return mint information for
    function mintedPerAddress(address minter)
        external
        view
        returns (AddressMintDetails memory);

    /// @notice This is the opensea/public owner setting that can be set by the contract admin
    function owner() external view returns (address);

    /// @notice Update the metadata renderer
    /// @param newRenderer new address for renderer
    /// @param setupRenderer data to call to bootstrap data for the new renderer (optional)
    function setMetadataRenderer(
        IMetadataRenderer newRenderer,
        bytes memory setupRenderer
    ) external;

    /// @notice This is an admin mint function to mint a quantity to a specific address
    /// @param to address to mint to
    /// @param quantity quantity to mint
    /// @return the id of the first minted NFT
    function adminMint(address to, uint256 quantity) external returns (uint256);

    /// @notice This is an admin mint function to mint a single nft each to a list of addresses
    /// @param to list of addresses to mint an NFT each to
    /// @return the id of the first minted NFT
    function adminMintAirdrop(address[] memory to) external returns (uint256);

    /// @dev Getter for admin role associated with the contract to handle metadata
    /// @return boolean if address is admin
    function isAdmin(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {IERC721DropMinter} from "./interfaces/IERC721DropMinter.sol";
import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";
import {IPublisher} from "./interfaces/IPublisher.sol";
import {ITokenMetadataKey} from "./interfaces/ITokenMetadataKey.sol";
import {PublisherStorage} from "./PublisherStorage.sol";

/** 
 * @title Publisher.sol
 * @dev Minting module & registry that initializes rendering strategy + metadata upon collection init + token mint 
 *      for specific token Ids of a given zora ERC721Drop collection
 * @dev Can be used by any zora ERC721Drop collection
 * @author Max Bochman
 */
contract Publisher is 
    IMetadataRenderer, 
    IPublisher,
    PublisherStorage,
    Ownable, 
    ReentrancyGuard 
{
    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZATION FUNCTION ||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Default initializer for collection level data of a specific zora ERC721 drop contract
    /// @notice contractURI must be set to non blank string value 
    /// @param data data to init with
    function initializeWithData(bytes memory data) external {
        // data format: contractURI, mintPricePerToken, accessControlModule, accessControlInit
        (
            string memory contractUriInit, 
            uint256 mintPriceInit,
            address accessControlModule, 
            bytes memory accessControlInit
        ) = abi.decode(data, (string, uint256, address, bytes));

        // check if contractURI is being set to empty string
        if (bytes(contractUriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURIInfo[msg.sender] = contractUriInit;

        mintPricePerToken[msg.sender] = mintPriceInit;

        emit MintPriceEdited(msg.sender, msg.sender, mintPriceInit);        

        IAccessControlRegistry(accessControlModule).initializeWithData(accessControlInit);

        dropAccessControl[msg.sender] = accessControlModule;    
        
        emit CollectionInitialized({
            target: msg.sender,
            contractURI: contractUriInit,
            mintPricePerToken: mintPriceInit,
            accessControl: accessControlModule,
            accessControlInit: accessControlInit
        });
    }   

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL MINTING FUNCTION ||
    // |||||||||||||||||||||||||||||||| 

    /// @notice allows you to mint a token with arbitrary metadata + arbitrary metadata structure
    /// @dev calls adminMint function in ZORA Drop contract + initializes artifactStructure
    /// @param zoraDrop ZORA Drop contract to mint from
    /// @param mintRecipient address to recieve minted tokens
    /// @param artifactDetails ArtifactDetails struct array of renderer + init to use for token being minted 
    function createArtifacts(
        address zoraDrop,
        address mintRecipient,
        ArtifactDetails[] memory artifactDetails
    ) external payable nonReentrant {

        // check if Publisher.sol contract has MINTER_ROLE on target ZORA Drop contract
        if (
            !IERC721DropMinter(zoraDrop).hasRole(
                MINTER_ROLE,
                address(this)
        )) {
            revert MinterNotAuthorized();
        }

        // check if msg.sender has publication access
        if (IAccessControlRegistry(dropAccessControl[zoraDrop]).getAccessLevel(address(this), msg.sender) < 1) {
            revert No_PublicationAccess();
        }        

        // check if total mint price is correct
        if (msg.value != mintPricePerToken[zoraDrop] * artifactDetails.length) {            
            revert WrongPrice();
        }

        // set artifactInfo storage for a given ZORA ERC721Drop contract => tokenId
        (bool artifactSuccess) = _createArtifacts(zoraDrop, mintRecipient, artifactDetails);

        // if storage update fails revert transaction
        if (!artifactSuccess) {
            revert CreateArtifactFail();
        }

        // Transfer funds to zora drop contract
        (bool bundleSuccess, ) = zoraDrop.call{value: msg.value}("");

        // if msg.value transfer fails revert transaction
        if (!bundleSuccess) {
            revert TransferNotSuccessful();
        }
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL MINTING FUNCTION ||
    // ||||||||||||||||||||||||||||||||

    function _createArtifacts(
        address zoraDrop,
        address mintRecipient,
        ArtifactDetails[] memory artifactDetails      
    ) internal returns (bool) {

        // calculate number of artifacts to mint
        uint256 numArtifacts = artifactDetails.length;        

        // call admintMint function on target ZORA contract and store last tokenId minted
        uint256 lastTokenMinted = IERC721DropMinter(zoraDrop).adminMint(mintRecipient, numArtifacts);        

        // for length of numArtifacts array, emit CreateArtifact event
        for (uint256 i = 0; i < numArtifacts; i++) {            

            // get current tokenId to process
            uint256 tokenId = lastTokenMinted - (numArtifacts - (i + 1));                     

            // check if target collection has been initialized
            if (bytes(contractURIInfo[zoraDrop]).length == 0) {
                revert Address_NotInitialized();
            }        

            // check if tokenRenderer is zero address
            if (artifactDetails[i].artifactRenderer == address(0)){
                revert Cannot_SetToZeroAddress();
            }

            // check if tokenMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }        

            artifactInfo[zoraDrop][tokenId] = artifactDetails[i];

            ITokenMetadataKey(artifactDetails[i].artifactRenderer).setTokenMetadata(artifactDetails[i].artifactMetadata);

            emit ArtifactCreated(
                msg.sender,
                zoraDrop,
                mintRecipient,
                tokenId,
                artifactDetails[i].artifactRenderer,
                artifactDetails[i].artifactMetadata
            );                 
        }
        return true;
    }           

    // ||||||||||||||||||||||||||||||||
    // ||| EXTNERAL EDIT FUNCTIONS ||||
    // ||||||||||||||||||||||||||||||||   

    /// @notice function that enables editing artifactDetails for a given tokenId
    /// @param zoraDrop collection address to target
    /// @param tokenIds uint256 tokenIds to target
    /// @param artifactDetails ArtifactDetails struct array of renderer + init to use for token being minted 
    function editArtifacts(
        address zoraDrop, 
        uint256[] memory tokenIds, 
        ArtifactDetails[] memory artifactDetails 
    )   external {

        // prevents users from submitting invalid inputs
        if (tokenIds.length != artifactDetails.length) {
            revert INVALID_INPUT_LENGTH();
        }

        // check if msg.sender has access to update metadata for a token
        if (IAccessControlRegistry(dropAccessControl[zoraDrop]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_EditAccess();
        }          

        // edit artifactInfo storage for a given ZORA ERC721Drop contract => tokenId
        (bool editSuccess) = _editArtifacts(zoraDrop, tokenIds, artifactDetails);

        // if storage update fails revert transaction
        if (!editSuccess) {
            revert EditArtifactFail();
        }
    }           

    /// @notice function to update contractURI
    /// @param newContractURI new contractURI
    function editContractURI(address target, string memory newContractURI)
        external
    {
        // check if msg.sender has access to edit access for a collection
        if (IAccessControlRegistry(dropAccessControl[target]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_EditAccess();
        }

        // check if contract has been initialized + if 
        if (bytes(contractURIInfo[target]).length == 0) {
            revert Address_NotInitialized();
        }

        // check if contractURI is being set to empty string
        if (bytes(newContractURI).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURIInfo[target] = newContractURI;

        emit ContractURIUpdated({
            target: target,
            sender: msg.sender,
            contractURI: newContractURI
        });
    }      

    /// @dev updates uint256 value in mintPricePerToken mapping
    /// @param newMintPricePerToken new mintPrice value
    function editMintPrice(address target, uint256 newMintPricePerToken) public {

        // check if msg.sender has access to edit access for a collection
        if (IAccessControlRegistry(dropAccessControl[target]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_EditAccess();
        }

        mintPricePerToken[target] = newMintPricePerToken;

        emit MintPriceEdited(msg.sender, target, newMintPricePerToken);
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL EDIT FUNCTIONS ||||
    // ||||||||||||||||||||||||||||||||   

    function _editArtifacts(
        address zoraDrop, 
        uint256[] memory tokenIds, 
        ArtifactDetails[] memory artifactDetails
    ) internal returns (bool) {

        for (uint256 i = 0; i < tokenIds.length; i++) {
        
            // check to see if token exists
            if (IERC721DropMinter(zoraDrop).saleDetails(zoraDrop).totalMinted < tokenIds[i]) {
                revert Token_DoesntExist();
            } 

            // check if tokenRenderer is zero address
            if (artifactDetails[i].artifactRenderer == address(0)) {
                revert Cannot_SetToZeroAddress();
            }   

            // check if tokenMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }   


            // check if tokenRenderer is different than currentRenderer, if so clear the old tokenInfo from the 
            //      old metadataRenderer
            if (artifactDetails[i].artifactRenderer != artifactInfo[zoraDrop][tokenIds[i]].artifactRenderer ) {                            
               ITokenMetadataKey(artifactInfo[zoraDrop][tokenIds[i]].artifactRenderer).deleteTokenMetadata(zoraDrop, tokenIds[i]);
            }           

            ITokenMetadataKey(artifactDetails[i].artifactRenderer).setTokenMetadata(artifactDetails[i].artifactMetadata);          

            artifactInfo[zoraDrop][tokenIds[i]] = artifactDetails[i]; 

            // emit ArtifactEdited event
            emit ArtifactEdited(
                msg.sender,
                zoraDrop,
                tokenIds[i],
                artifactDetails[i].artifactRenderer,
                artifactDetails[i].artifactMetadata
            );   
        }
        return true;         
    }

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice A contract URI for the given drop contract
    /// @dev reverts if a contract uri has not been initialized
    /// @return contract uri for the collection address (if set)
    function contractURI() 
        external 
        view 
        override 
        returns (string memory) 
    {
        string memory uri = contractURIInfo[msg.sender];
        if (bytes(uri).length == 0) {
            // if contractURI return is blank, means the contract has not been initialize
            //      or is being called by an address other than zoraDrop that has been initd
            revert NotInitialized_Or_NotZoraDrop();
        }
        return uri;
    }

    /// @notice Token URI information getter
    /// @dev reverts if token does not exist
    /// @param tokenId to get uri for
    /// @return tokenURI uri for given token of collection address (if set)
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory uri = ITokenMetadataKey(artifactInfo[msg.sender][tokenId].artifactRenderer).viewTokenURI(msg.sender, tokenId);
        if (bytes(uri).length == 0) revert Token_DoesntExist();
        return uri;
    }

    /// @notice contractURI + tokenUri information custom getter
    /// @dev reverts if token does not exist
    /// @param zoraDrop to get contractURI for    
    /// @param tokenId to get tokenURI for
    function publicTokenUriExplorer(address zoraDrop, uint256 tokenId)
        external
        view
        returns (string memory, string memory)
    {
        
        if (bytes(contractURIInfo[zoraDrop]).length == 0) {
            revert Address_NotInitialized();
        }
        
        if (bytes(contractURIInfo[zoraDrop]).length == 0) {
            return (contractURIInfo[zoraDrop], "");
        }

        return (IMetadataRenderer(zoraDrop).contractURI(), IMetadataRenderer(zoraDrop).tokenURI(tokenId));
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPublisher} from "./interfaces/IPublisher.sol";

/**
 @notice Publisher.sol storage variables contract
 @author Max Bochman
 */
contract PublisherStorage is IPublisher {

    /// @notice zora collection immutable minter_role value storage
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");

    /// @notice mintPricePerToken storage
    mapping(address => uint256) public mintPricePerToken;
    
    // zora collection => access control module in use
    mapping(address => address) public dropAccessControl; 

    /// @notice ContractURI mapping storage
    mapping(address => string) public contractURIInfo;

    /// @notice zora collection -> tokenId -> {tokenRenderer, tokenMetadata}
    mapping(address => mapping(uint256 => ArtifactDetails)) public artifactInfo;     

    // /// @notice Storage gap
    // uint256[49] __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";

interface IERC721DropMinter {
    function adminMint(address recipient, uint256 quantity)
        external
        returns (uint256);

    function hasRole(bytes32, address) external returns (bool);

    function isAdmin(address) external returns (bool);

    function saleDetails(address) external returns (IERC721Drop.SaleDetails memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPublisher {

    /// @notice Shared listing struct for both access and storage ***CHANGE THIS  
    struct ArtifactDetails {
        address artifactRenderer;
        bytes artifactMetadata;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // /// @notice CHANGE
    // function initializeArtifact(ArtifactDetails memory artifactDetails) external returns (bool);   

    // /// @notice CHANGE
    // function updateArtifact(address, uint256, address, string memory) external returns (bool);

    // /// @notice CHANGE
    // function updateContractURI(address, string memory) external; 

    // /// @notice function that enables editing artifactDetails for a given tokenId
    // function editArtifacts(
    //     address zoraDrop, 
    //     uint256[] memory tokenIds, 
    //     ArtifactDetails[] memory artifactDetails 
    // )   external {    

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice create artifact notice
    event ArtifactCreated(
        address creator, 
        address zoraDrop, 
        address mintRecipient, 
        uint256 tokenId, 
        address tokenRenderer,
        bytes tokenMetadata
    ) ; 

    /// @notice edit artifact notice
    event ArtifactEdited(
        address editor, 
        address zoraDrop,
        uint256 tokenId, 
        address tokenRenderer, 
        bytes tokenMetadata
    );           
    
    /// @notice mint notice
    // event Mint(address minter, address mintRecipient, uint256 tokenId, string tokenURI);
    event Mint(address minter, address mintRecipient, uint256 tokenId, address artifactRegistry, bytes artifactMetadata);    
    
    /// @notice mintPrice edited notice
    event MintPriceEdited(address sender, address target, uint256 newMintPrice);

    /// @notice metadataRenderer updated notice
    event MetadataRendererUpdated(address sender, address newRenderer);     

    /// @notice Event for initialized Artifact
    event ArtifactInitialized(
        address indexed target,
        address sender,
        uint256 indexed tokenId,
        string indexed tokenURI
    );    

    /// @notice Event for updated Artifact
    event ArtifactUpdated(
        address indexed target,
        address sender,
        uint256 indexed tokenId,
        string indexed tokenURI
    );

    /// @notice Event for updated contractURI
    event ContractURIUpdated(
        address indexed target,
        address sender,
        string indexed contractURI
    );    

    /// @notice Event for a new collection initialized
    /// @dev admin function indexer feedback
    event CollectionInitialized(
        address indexed target,
        string indexed contractURI,
        uint256 mintPricePerToken,
        address indexed accessControl,
        bytes accessControlInit
    );         

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    error Cannot_SetToZeroAddress();

    /// @notice Action is unable to complete because msg.value is incorrect
    error WrongPrice();

    /// @notice Action is unable to complete because minter contract has not recieved minting role
    error MinterNotAuthorized();

    /// @notice Funds transfer not successful to drops contract
    error TransferNotSuccessful();

    /// @notice Caller is not an admin on target zora drop
    error Access_OnlyAdmin();

    /// @notice Artifact creation update failed
    error CreateArtifactFail();     

    /// @notice Artifact edit update failed
    error EditArtifactFail();           

    /// @notice CHANGEEEEEEEE
    error No_MetadataAccess();

    /// @notice CHANGEEEEEEEE
    error No_PublicationAccess();    

    /// @notice CHANGEEEEEEEE
    error No_EditAccess();      

    /// @notice if contractURI return is blank, means the contract has not been initialize
    ///      or is being called by an address other than zoraDrop that has been initd
    error NotInitialized_Or_NotZoraDrop();    

    /// @notice CHANGEEEEEEEE    
    error Cannot_SetBlank();

    /// @notice CHANGEEEEEEEE    
    error Token_DoesntExist();

    /// @notice CHANGEEEEEEEE    
    error Address_NotInitialized();

    /// @notice CHANGEEEEEEEE  
    error INVALID_INPUT_LENGTH();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenMetadataKey {
    // function decodeTokenURI(bytes memory artifactMetadata) external returns (string memory);
    function setTokenMetadata(bytes memory initData) external;
    function viewTokenURI(address zoraDrop, uint256 tokenId) external view returns (string memory);
    function isPublisher(address msgSender) external view returns (bool);
    function deleteTokenMetadata(address zoraDrop, uint256 tokenId) external;

    //error
    error MsgSender_NotPublisher();


    // events

    // @notice Event for initialized Artifact
    event TokenUriSet(
        address indexed zoraDrop,
        uint256 indexed tokenId,
        string tokenURI
    );  
}