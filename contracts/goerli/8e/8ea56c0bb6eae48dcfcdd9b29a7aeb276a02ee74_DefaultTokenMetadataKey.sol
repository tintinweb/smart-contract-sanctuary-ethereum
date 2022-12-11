// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ITokenMetadataKey} from "./interfaces/ITokenMetadataKey.sol";
import {IPublisher} from "./interfaces/IPublisher.sol";

/** 
 * @title DefaultTokenMetadataKey
 * @dev 
 * @dev Can be used by any contract
 * @author Max Bochman
 */
contract DefaultTokenMetadataKey is ITokenMetadataKey, IPublisher  {



/* UPDATES TO MAKE

Figure out how to make Publisher.sol (createArtifact) result in the decoding of the bytes metadata
in the appropriate token specific metadata renderer (prob by just requiring initilaizeWithData
in ITokenMetadaKey -- and then in that process the tokenURI string is decipphered and set to storage)

Then figure out how to make editing only possible from Publisher.sol, and whenever u hit editArtifact,
if the artifactRenderer address is being adjusted u make sure to clear the tokenURI out of the old renderer,
before initilaiizng the newone

*/ 

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    mapping(address => mapping(uint256 => string)) public tokenUriInfo;  

    address publisherProxy;

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||     
    constructor(address _publisherProxy) {
        publisherProxy = _publisherProxy;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZE FUNCTION ||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Initializer called by Publisher.sol when a new artifact is created
    /// @notice tokenURI must be set to non blank string value 
    /// @param artifactMetadata data to init with
    function setTokenMetadata(bytes memory artifactMetadata) public {

        if (!isPublisher(msg.sender)) {
            revert MsgSender_NotPublisher();
        }

        // data format: zoraDrop, tokenId, tokenURI
        (
            address zoraDrop, 
            uint256 tokenId, 
            string memory tokenURI
        ) = abi.decode(artifactMetadata, (address, uint256, string));

        // check if tokenURI is being set to empty string
        if (bytes(tokenURI).length == 0) {
            revert Cannot_SetBlank();
        }

        tokenUriInfo[zoraDrop][tokenId] = tokenURI;
        
        emit TokenUriSet({
            zoraDrop: zoraDrop,
            tokenId: tokenId,
            tokenURI: tokenURI
        });
    }   

    // ||||||||||||||||||||||||||||||||
    // ||| EDIT FUNCTION ||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    function deleteTokenMetadata(address zoraDrop, uint256 tokenId) external {
        if (!isPublisher(msg.sender)) {
            revert MsgSender_NotPublisher();
        }

        delete tokenUriInfo[zoraDrop][tokenId];
    }

    // ||||||||||||||||||||||||||||||||
    // ||| HELPER FUNCTION ||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Checks if local storage is being updated by publisher contract
    /// @notice reverts if setTokenMetadata is being updated by address other than publisher 
    /// @param msgSender address to check if is Publisher  
    function isPublisher(address msgSender) public view returns (bool) {
        // if msgSender = publisherProxy adddress, return true
        if (msgSender == publisherProxy) {
            return true;
        }
        // else return false
        return false;
    }


    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTION ||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice viewTokenURI
    /// @dev returns blank if token not initialized
    /// @return tokenURI uri for given token of collection address (if set)
    function viewTokenURI(address zoraDrop, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return tokenUriInfo[zoraDrop][tokenId];
    }
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