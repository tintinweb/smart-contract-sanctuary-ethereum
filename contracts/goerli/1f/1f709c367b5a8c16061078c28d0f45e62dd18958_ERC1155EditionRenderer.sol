// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*


                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.


*/

import {IERC1155PressTokenLogic} from "./IERC1155PressTokenLogic.sol";
import {IERC1155TokenRenderer} from "./IERC1155TokenRenderer.sol";
import {IERC1155PressContractLogic} from "./IERC1155PressContractLogic.sol";
import {IERC1155Skeleton} from "./IERC1155Skeleton.sol";

interface IERC1155Press is IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // stores token level logic + renderer + funds + transferability related information
    struct Configuration {
        address payable fundsRecipient;
        IERC1155PressTokenLogic logic;
        IERC1155TokenRenderer renderer;
        address payable primarySaleFeeRecipient;
        bool soulbound;
        uint16 royaltyBPS;
        uint16 primarySaleFeeBPS;        
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have mint new access for given Press
    error No_MintNew_Access();    
    /// @notice msg.sender does not have mint existing access for given Press
    error No_MintExisting_Access();
    /// @notice msg.sender does not have config access for given Press + tokenId
    error No_Config_Access();     
    /// @notice msg.sender does not have withdraw access for given Press
    error No_Withdraw_Access();    
    /// @notice cannot withdraw balance from a tokenId with no associated funds  
    error No_Withdrawable_Balance(uint256 tokenId);     
    /// @notice msg.sender does not have burn access for given Press + tokenId
    error No_Burn_Access();    
    /// @notice msg.sender does not have upgrade access for given Press
    error No_Upgrade_Access();     
    /// @notice msg.sender does not have owernship transfer access for given Press
    error No_Transfer_Access();       

    // Constraint/invalid/failure errors
    /// @notice invalid input
    error Invalid_Input();
    /// @notice If minted total supply would exceed max supply
    error Exceeds_MaxSupply();    
    /// @notice invalid contract inputs due to parameter.length mismatches
    error Input_Length_Mismatch();
    /// @notice token doesnt exist error
    error Token_Doesnt_Exist(uint256 tokenId);    
    /// @notice incorrect msg.value for transaction
    error Incorrect_Msg_Value();    
    /// @notice cant set address
    error Cannot_Set_Zero_Address();
    /// @notice cannot set royalty or finders fee bps this high
    error Setup_PercentageTooHigh(uint16 maxBPS);    
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();    
    /// @notice error setting config varibles
    error Set_Config_Fail(); 

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Event emitted upon ERC1155Press initialization
    /// @param sender msg.sender calling initialization function
    /// @param owner initial owner of contract
    /// @param contractLogic logic contract set 
    event ERC1155PressInitialized(
        address indexed sender,        
        address indexed owner,
        IERC1155PressContractLogic indexed contractLogic
    );          

    /// @notice Event emitted when minting a new token
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender calling mintNew function
    /// @param recipient recipient of tokens
    /// @param quantity quantity of tokens received by recipient 
    event NewTokenMinted(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed recipient,
        uint256 quantity
    );    

    /// @notice Event emitted when minting an existing token
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender calling mintExisting function
    /// @param recipient recipient of tokens
    /// @param quantity quantity of tokens received by recipient 
    event ExistingTokenMinted(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed recipient,
        uint256 quantity
    );

    /// @notice Event emitted when adding to a tokenId's funds tracking
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender passing value
    /// @param amount value being added to tokenId's funds tracking
    event TokenFundsIncreased(
        uint256 indexed tokenId,        
        address indexed sender,
        uint256 amount
    );    

    /// @notice Event emitted when the funds generated by a given tokenId are withdrawn from the minting contract
    /// @param tokenId tokenId to withdraw generated funds from
    /// @param sender address that issued the withdraw
    /// @param fundsRecipient address that the funds were withdrawn to
    /// @param fundsAmount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event TokenFundsWithdrawn(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed fundsRecipient,        
        uint256 fundsAmount,
        address feeRecipient,
        uint256 feeAmount
    );    

    /// @notice Event emitted when config is updated post initialization
    /// @param tokenId tokenId config being updated
    /// @param sender address that sent update txn
    /// @param logic logic contract address
    /// @param renderer renderer contract address
    /// @param fundsRecipient fundsRecipient
    /// @param royaltyBPS royaltyBPS
    /// @param soulbound soulbound bool
    event UpdatedConfig(
        uint256 indexed tokenId,
        address indexed sender,        
        IERC1155PressTokenLogic logic,
        IERC1155TokenRenderer renderer,
        address fundsRecipient,
        uint16 royaltyBPS,
        bool soulbound
    );    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Public owner setting that can be set by the contract admin
    function owner() external view returns (address);

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Getter for logic contract stored in configInfo for a given tokenId
    function getTokenLogic(uint256 tokenId) external view returns (IERC1155PressTokenLogic); 

    /// @notice Getter for renderer contract stored in configInfo for a given tokenId
    function getRenderer(uint256 tokenId) external view returns (IERC1155TokenRenderer); 

    /// @notice Getter for fundsRecipent address stored in configInfo for a given tokenId
    function getFundsRecipient(uint256 tokenId) external view returns (address payable); 

    /// @notice Config level details
    /// @return Configuration (defined in IERC1155Press) 
    function getConfigDetails(uint256 tokenId) external view returns (Configuration memory);

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressContractLogic {  
    
    // Initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    // Access control functions
    /// @notice checks if a certain address can access mintnew functionality for a given Press + recepients + quantity combination
    function canMintNew(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (bool);    
    /// @notice checks if a certain address can set ownership of a given Press
    function canSetOwner(address targetPress, address transferCaller) external view returns (bool);    
    /// @notice checks if a certain address can upgrade the underlying implementation for a given Press
    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool);    

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintNewPrice(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressTokenLogic {  
    
    // Initialize function
    /// @notice initializes logic file for a given tokenId + Press with arbitrary data
    function initializeWithData(uint256 tokenId, bytes memory initData) external;    

    // Access control functions
    /// @notice checks if a certain address can edit metadata post metadata initialization for a given Press + tokenId
    function canEditMetadata(address targetPress, uint256 tokenId, address editCaller) external view returns (bool);        
    /// @notice checks if a certain address can update the Config struct on a given tokenId for a given Press 
    function canUpdateConfig(address targetPress, uint256 tokenId, address updateCaller) external view returns (bool);
    /// @notice checks if a certain address can access mint functionality for a given tokenId for a given Press + recipient + quantity combination
    function canMintExisting(address targetPress, address mintCaller, uint256 tokenId, address[] memory recipients, uint256 quantity) external view returns (bool);
    /// @notice checks if a certain address can call the withdraw function for a given tokenId for a given Press
    function canWithdraw(address targetPress, uint256 tokenId, address withdrawCaller) external view returns (bool);
    /// @notice checks if a certain address can call the burn function for a given tokenId for a given Press
    function canBurn(address targetPress, uint256 tokenId, uint256 quantity, address burnCaller) external view returns (bool);    

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress, uint256 tokenId) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintExistingPrice(address targetPress, uint256 tokenId, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Amount of existing (minted & not burned) tokens with a given tokenId
    function totalSupply(uint256 tokenId) external view returns (uint256);

    /// @notice getter for internal _numMinted counter which keeps track of quantity minted per tokenId per wallet address
    function numMinted(uint256 tokenId, address account) external view returns (uint256);    

    /// @notice Getter for last minted tokenId
    function tokenCount() external view returns (uint256);

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155TokenRenderer {
    function uri(uint256 tokenId) external view returns (string memory);
    function initializeWithData(uint256 tokenId, bytes memory rendererInit) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155TokenRenderer} from "../interfaces/IERC1155TokenRenderer.sol";
import {IERC1155PressTokenLogic} from "../interfaces/IERC1155PressTokenLogic.sol";
import {IERC1155Press} from "../interfaces/IERC1155Press.sol";

/**
 @notice ERC1155EditionRenderer
 @author Max Bochman
 @author Salief Lewis
 */
contract ERC1155EditionRenderer is IERC1155TokenRenderer {

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice supplied value cannot be empty
    error Cannot_SetBlank();
    /// @notice caller does not have permission to edit
    error No_Edit_Access();
    /// @notice address cannot be zero
    error Cannot_SetToZeroAddress();
    /// @notice supplied token does not exist or is yet to be minted
    error Token_DoesntExist();
    /// @notice target Press contract is uninitialized or being accessed by the wrong contract
    error NotInitialized_Or_NotPress();

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    // ERC1155Press => tokenId => uri string
    mapping(address => mapping(uint256 => string)) public tokenUriInfo;

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @dev MUST emit when the URI is updated for a tokenId as defined in EIP-1155
    /// @param _value string value of URI
    /// @param _id tokenId
    event URI(string _value, uint256 indexed _id);     

    // ||||||||||||||||||||||||||||||||
    // ||| URI FUNCTIONS ||||||||||||||
    // ||||||||||||||||||||||||||||||||         

    /// @notice uri must be set to non blank string value 
    /// @param tokenId tokenId to init
    /// @param rendererInit data to init with
    function initializeWithData(uint256 tokenId, bytes memory rendererInit) external {
        // data format: uri
        (string memory uriInit) = abi.decode(rendererInit, (string));

        // check if contractURI is being set to empty string
        if (bytes(uriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        // store string URI for given Press for given tokenId
        tokenUriInfo[msg.sender][tokenId] = uriInit;

        // emit URI update event as defined in EIP-1155
        emit URI(uriInit, tokenId);
    }   

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param targetPress address of press to update
    /// @param tokenId tokenId to target
    /// @param newURI new string URI for token
    function setTokenURI(address targetPress, uint256 tokenId, string memory newURI) external {

        if (IERC1155Press(targetPress).getTokenLogic(tokenId).canEditMetadata(targetPress, tokenId, msg.sender) != true) {
            revert No_Edit_Access();
        } 
        
        // check if newURI is being set to empty string
        if (bytes(newURI).length == 0) {
            revert Cannot_SetBlank();
        }

        // update string URI stored for given Press + tokenId
        tokenUriInfo[targetPress][tokenId] = newURI;

        // emit URI update event as defined in EIP-1155
        emit URI(newURI, tokenId);
    }           

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice contract uri for the given Press contract
    /// @dev reverts if a contract uri has not been initialized
    /// @return tokenId uri for the given tokenId of calling contract (if set)
    function uri(uint256 tokenId) 
        external 
        view  
        returns (string memory) 
    {
        string memory tokenURI = tokenUriInfo[msg.sender][tokenId];
        if (bytes(tokenURI).length == 0) {
            /*
            * if uri returns blank, the contract + token has not been initialized
            * or this function is being called by the wrong contract
            */      
            revert NotInitialized_Or_NotPress();
        }
        return tokenURI;
    }

    /// @notice custom getter for contractURI + tokenURI information
    /// @dev reverts if token does not exist
    /// @param targetPress to get contractURI for    
    /// @param tokenId to get tokenURI for
    function uriLookup(address targetPress, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        
        // check if token exists
        if (IERC1155Press(targetPress).tokenCount() < tokenId) {
            revert Token_DoesntExist();
        }         

        // return string uri value for given Press + tokenID
        return tokenUriInfo[targetPress][tokenId];
    }    
}