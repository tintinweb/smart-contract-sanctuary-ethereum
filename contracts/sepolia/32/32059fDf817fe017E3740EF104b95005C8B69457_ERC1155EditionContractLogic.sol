// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155PressContractLogic} from "../../../core/interfaces/IERC1155PressContractLogic.sol";
import {IERC1155Press} from "../../../core/interfaces/IERC1155Press.sol";

/**
* @title ERC1155EditionContractLogic
* @notice Edition contract level logic impl for AssemblyPress ERC1155 architecture
*
* @author Max Bochmanx
* @author Salief Lewis
*/
contract ERC1155EditionContractLogic is IERC1155PressContractLogic {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @dev 0 = Not initialized, 1 = Initialized
    struct ContractConfig {
        uint256 mintNewPrice;
        uint8 initialized;
    }        

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Target Press has not been initialized
    error Press_Not_Initialized();
    /// @notice Cannot set address to the zero address
    error Cannot_Set_Zero_Address();
    /// @notice Address does not have admin role
    error Not_Admin();
    /// @notice Role value is not available 
    error Invalid_Role();
    /// @notice Cannot check results for given mintNew params
    error Invalid_MintNew_Inputs();    
    /// @notice Array input lengths don't match for access control updates
    error Invalid_Input_Length();    

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when mintNew price updated
    /// @param targetPress Press that updated logic file
    /// @param mintNewPrice mintNew price for contract
    event MintNewPriceUpdated(
        address indexed targetPress,
        uint256 mintNewPrice
    );        

    /// @notice Event emitted when access role is granted to an address
    /// @param sender address that sent txn
    /// @param targetPress Press contract role is being issued for
    /// @param receiver address recieving role
    /// @param role role being given
    event RoleGranted(
        address indexed sender,
        address indexed targetPress,
        address indexed receiver,
        uint256 role
    );              

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    // Public constants for access roles
    uint16 public constant NO_ACCESS = 0;
    uint16 public constant MINTER = 1;
    uint16 public constant ADMIN = 2;

    /// @notice Press -> wallet -> uint256 access role
    mapping(address => mapping(address => uint16)) public accessInfo;         

    /// @notice Press -> {mintNewPrice, initialized}
    mapping(address => ContractConfig) public contractInfo;

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 
    
    /// @notice Checks if target Press has been initialized
    modifier requireInitialized(address targetPress) {

        if (contractInfo[targetPress].initialized == 0) {
            revert Press_Not_Initialized();
        }

        _;
    }           

    /// @notice Checks if msg.sender has admin level privileges for given Press contract
    modifier requireSenderAdmin(address target) {

        if (msg.sender != target && accessInfo[target][msg.sender] != ADMIN) { 
            revert Not_Admin();
        }

        _;
    }          

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS CONTROL CHECKS ||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintCaller address of mintCaller to check access for
    /// @param recipients recipients to check access for
    /// @param quantity quantity to check access for    
    function canMintNew(
        address targetPress, 
        address mintCaller,
        address[] memory recipients,
        uint256 quantity
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if mintQuantity + mintCaller are valid inputs
        if (quantity == 0 || mintCaller == address(0)) {
            return false;
        }

        // check is any of the recipients are address(0)
        for (uint256 i; i < recipients.length; ++i) {
            if (recipients[i] == address(0)) {
                return false;
            }
        }        

        // check if mint caller has minting access for given mint quantity for given targetPress
        if (accessInfo[targetPress][mintCaller] < MINTER) {
            return false;
        }
        
        return true;
    }            
    
    // ||||||||||||||||||||||||||||||||
    // ||| STATUS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice checks value of initialized variable in mintInfo mapping for target Press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {

        // return false if targetPress has not been initialized
        if (contractInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }          

    /// @notice Checks mint price for provided combination
    /// @param targetPress press contract to check
    /// @param mintCaller address of mintCaller to check
    /// @param recipients recipients to check
    /// @param quantity quantity to check
    function mintNewPrice(
        address targetPress, 
        address mintCaller,
        address[] memory recipients,
        uint256 quantity
    ) external view requireInitialized(targetPress) returns (uint256) {
        // return mintNewPrice for targetPress
        return contractInfo[targetPress].mintNewPrice * quantity;
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC SETUP FUNCTIONS ||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @notice admin cannot be set to the zero address
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(bytes memory logicInit) external {
        // data format: adminInit, mintPriceInit
        (address adminInit, uint256 mintNewPriceInit) = abi.decode(logicInit, (address, uint256));

        // check if admin set to the zero address
        if (adminInit == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // set initial admin in accessInfo mapping
        accessInfo[msg.sender][adminInit] = ADMIN;

        // update mutable values in contractInfo mapping
        contractInfo[msg.sender].mintNewPrice = mintNewPriceInit;

        // update immutable values in mintInfo mapping
        contractInfo[msg.sender].initialized = 1;

        emit MintNewPriceUpdated({
            targetPress: msg.sender,
            mintNewPrice: mintNewPriceInit
        });
    }       

    /// @notice Update access control
    /// @param targetPress target Press to update access control for
    /// @param receivers addresses to give roles to
    /// @param roles roles to give receiver addresses
    function setAccessControl(
        address targetPress,
        address[] memory receivers,
        uint16[] memory roles
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // check for input mismatch between receivers & roles
        if (receivers.length != roles.length) {
            revert Invalid_Input_Length();
        }

        // initiate for loop for length of receivers array
        for (uint256 i; i < receivers.length; i++) {

            // cannot give address(0) a role
            if (receivers[i] == address(0)) {
                revert Cannot_Set_Zero_Address();
            }
            // check to see if role value is valid 
            if (roles[i] > ADMIN ) {
                revert Invalid_Role();
            }            

            // grant access role to designated receiever
            accessInfo[targetPress][receivers[i]] = roles[i];
            
            // emit new role as event
            emit RoleGranted({
                sender: msg.sender,
                targetPress: targetPress,
                receiver: receivers[i],
                role: roles[i]
            });
        }
    }     

    /// @notice Update mintNewPrie
    /// @param targetPress target for contract to update minting logic for
    /// @param newPrice new mintNewPrice 
    function updateMintNewPrice(
        address targetPress,
        uint256 newPrice
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // update mintNewPrice for target Press
        contractInfo[targetPress].mintNewPrice = newPrice;

        emit MintNewPriceUpdated({
            targetPress: msg.sender,
            mintNewPrice: newPrice
        });
    }           
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

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintNewPrice(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}

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
import {IERC1155PressTokenRenderer} from "./IERC1155PressTokenRenderer.sol";
import {IERC1155PressContractLogic} from "./IERC1155PressContractLogic.sol";
import {IERC1155Skeleton} from "./IERC1155Skeleton.sol";

interface IERC1155Press is IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // stores token level logic + renderer + funds + token transferability related information
    struct Configuration {
        address payable fundsRecipient;
        IERC1155PressTokenLogic logic;
        IERC1155PressTokenRenderer renderer;
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
        IERC1155PressTokenRenderer renderer,
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
    function getRenderer(uint256 tokenId) external view returns (IERC1155PressTokenRenderer); 

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

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress, uint256 tokenId) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintExistingPrice(address targetPress, uint256 tokenId, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressTokenRenderer {
    function uri(uint256 tokenId) external view returns (string memory);
    function initializeWithData(uint256 tokenId, bytes memory rendererInit) external;    
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