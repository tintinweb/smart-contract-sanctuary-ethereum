// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAccessControl} from "../../../core/interfaces/IAccessControl.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC721Press} from "../../../core/interfaces/IERC721Press.sol";

/**
* @title HybridAccess
* @notice Facilitates role based access control for admin/manager roles, and erc721 ownership based access for curator role
* @author Max Bochman
*/
contract HybridAccess is IAccessControl {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    
    
    struct RoleDetails {
        address account;
        uint8 role;
    } 

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Account does not have admin role
    error RequiresAdmin();
    /// @notice Account does not have high enough role
    error RequiresHigherRole();
    /// @notice Invalid role being set
    error RoleDoesntExist();    
    /// @notice Initialization coming from unauthorized contract
    error UnauthorizedInitializer();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when curationGate address updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param newGate new address set for curationGate
    event CuratorGateUpdated(
        address targetPress,
        address sender,
        address newGate
    );            

    /// @notice Event emitted when a new admin/manager/no_role role is granted
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param account account receiving new role
    /// @param role role being granted
    event RoleGranted(
        address targetPress,
        address sender,
        address account,
        uint8 role 
    );    


    /// @notice Event emitted when a role is revoked from an account
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param account account being revoked
    /// @param role account role be updated to NO_ROLE
    event RoleRevoked(
        address targetPress,
        address sender,
        address account,
        uint8 role 
    );         

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    string public constant name = "HybridAccess";

    // Role constants
    uint8 constant ADMIN = 3;
    uint8 constant MANAGER = 2;
    uint8 constant NO_ROLE = 0;    

    // Press contract to ERC721 being used to gate curator functionality
    mapping(address => address) public curatorGateInfo;

    // Press contract to account to role for determining admin/manager functionality
    mapping(address => mapping(address => uint8)) public roleInfo;

    //////////////////////////////////////////////////
    // ADMIN
    //////////////////////////////////////////////////    

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdmin(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin
        return roleInfo[targetPress][account] != ADMIN ? false : true;
    }

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdminOrManager(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin or manager
        return roleInfo[targetPress][account] != NO_ROLE ? true : false;
    }        
    

    /// @notice Only allowed for contract admin
    /// @param targetPress target Press 
    /// @dev only allows approved admin of target Press (from msg.sender)
    modifier onlyAdmin(address targetPress) {
        if (!_isAdmin(targetPress, msg.sender)) {
            revert RequiresAdmin();
        }

        _;
    }

    /// @notice Only allowed for contract admin
    /// @param targetPress target Press 
    /// @dev only allows approved managers or admins of targetPress (from msg.sender)
    modifier onlyAdminOrManager(address targetPress) {
        if (!_isAdminOrManager(targetPress, msg.sender)) {
            revert RequiresHigherRole();
        }

        _;
    }       

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice initializes mapping of access control
    /// @dev contract initializing access control => admin address
    /// @dev called by other contracts initiating access control
    /// @dev data format: admin
    function initializeWithData(address targetPress, bytes memory data) external {

        // Ensure that only the expected CurationLogic contract is calling this function
        if (msg.sender != address(IERC721Press(targetPress).getLogic())) {
            revert UnauthorizedInitializer();
        }

        // abi.decode initial gate information set on access control initialization
        (address curatorGate, RoleDetails[] memory initialRoles) = abi.decode(data, (address, RoleDetails[]));

        // call internal grant roles function 
        _grantRoles(targetPress, initialRoles);

        // check if curatorGate was set to non zero address and update its value + emit event if it was
        if (curatorGate != address(0)) {
            curatorGateInfo[targetPress] = curatorGate;
            emit CuratorGateUpdated(targetPress, msg.sender, curatorGate);
        }
    }

    /// @notice Grants new roles for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
    function grantRoles(address targetPress, RoleDetails[] memory roleDetails) 
        onlyAdmin(targetPress) 
        external
    {
        _grantRoles(targetPress, roleDetails);
    }    

    /// @notice Revokes roles for given Press 
    /// @param targetPress target Press
    /// @param accounts array of addresses to revoke roles from
    function revokeRoles(address targetPress, address[] memory accounts) 
        onlyAdmin(targetPress) 
        external
    {
        // revoke roles from each account provided
        for (uint256 i; i < accounts.length; ++i) {
            // revoke role from account
            roleInfo[targetPress][accounts[i]] = NO_ROLE;

            emit RoleRevoked({
                targetPress: targetPress,
                sender: msg.sender,
                account: accounts[i],
                role: NO_ROLE
            });
        }    
    }      

    /// @notice internal grant new roles for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
    function _grantRoles(address targetPress, RoleDetails[] memory roleDetails) internal {
        // grant roles to each [account, role] provided
        for (uint256 i; i < roleDetails.length; ++i) {
            // check that role being granted is a valid role
            if (roleDetails[i].role != ADMIN && roleDetails[i].role != MANAGER) {
                revert RoleDoesntExist();
            }
            // give role to account
            roleInfo[targetPress][roleDetails[i].account] = roleDetails[i].role;

            emit RoleGranted({
                targetPress: targetPress,
                sender: msg.sender,
                account: roleDetails[i].account,
                role: roleDetails[i].role
            });
        }    
    }        

    /// @notice Changes the address of the curatorGate in use for a given targetPress
    /// @param targetPress target Press index
    /// @param newCuratorGate new address for the curatorGate
    function setCuratorGate(address targetPress, address newCuratorGate) external onlyAdmin(targetPress) {
        curatorGateInfo[targetPress] = newCuratorGate;

        emit CuratorGateUpdated({
            targetPress: targetPress,
            sender: msg.sender,
            newGate: newCuratorGate
        });
    }

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getAccessLevel(address accessMappingTarget, address addressToGetAccessFor)
        external
        view
        returns (uint256)
    {
        // cache role for given target address
        uint8 role = roleInfo[accessMappingTarget][addressToGetAccessFor];

        // first check if address has admin/manager role, return that role if it does
        // if no admin/manager role, check if address has a balance of > 0 of the curationGate contract, return 1 if it does
        // return 0 if all of the above is false
        if (role != NO_ROLE) {
            return role;
        } else if (IERC721(curatorGateInfo[accessMappingTarget]).balanceOf(addressToGetAccessFor) != 0) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @notice returns mintPrice for a given Press + account + mintQuantity
    /// @dev called via the logic contract that has been set for a given Press
    function getMintPrice(address accessMappingTarget, address addressToGetAccessFor, uint256 mintQuantity)
        external
        view
        returns (uint256)
    {
        // always returns zero to hardcode no fee necessary
        return 0;
    }        
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAccessControl {
    
    function name() external view returns (string memory);    
    
    function initializeWithData(address, bytes memory initData) external;
    
    function getAccessLevel(address, address) external view returns (uint256);

    function getMintPrice(address, address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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

import {IERC721PressLogic} from "./IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./IERC721PressRenderer.sol";

interface IERC721Press {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @param _fundsRecipient Address that receives funds from sale
    /// @param _maxSupply uint64 max supply value
    /// @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty
    /// @param _primarySaleFeeRecipient Funds recipient on primary sales    
    /// @param _primarySaleFeeBPS Optional fee to set on primary sales
    struct Configuration {
        address payable fundsRecipient;
        address payable primarySaleFeeRecipient;
        uint64 maxSupply;
        uint16 royaltyBPS;
        uint16 primarySaleFeeBPS;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have mint access for given Press
    error No_Mint_Access();
    /// @notice msg.sender does not have config access for given Press
    error No_Config_Access();
    /// @notice msg.sender does not have withdraw access for given Press
    error No_Withdraw_Access();    
    /// @notice msg.sender does not have burn access for given Press
    error No_Burn_Access();

    // Constraint/failure errors
    /// @notice Exceeds maxSupply
    error Exceeds_Max_Supply();
    /// @notice Royalty percentage too high
    error Setup_PercentageTooHigh(uint16 bps);
    /// @notice cannot set address to address(0)
    error Cannot_Set_Zero_Address();
    /// @notice msg.value incorrect for mint call
    error Incorrect_Msg_Value();
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();
    /// @notice error setting config varibles
    error Set_Config_Fail();
    /// @notice error when transferring non-transferrable token
    error Non_Transferrable_Token();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Event emitted if primary sale fee is set during Press initialization
    /// @param feeRecipient address that will recieve primary sale fees
    /// @param feeBPS fee basis points (divide by 10_000 for %)
    event PrimarySaleFeeSet(address indexed feeRecipient, uint16 feeBPS);

    /// @notice Event when Press config is initialized
    /// @param sender address that sent update txn
    /// @param logic address of external logic contract
    /// @param renderer address of external renderer contract
    /// @param fundsRecipient address that will recieve funds stored in Press contract upon withdraw
    /// @param royaltyBPS ERC2981 compliant secondary sales basis points (divide by 10_000 for %)
    /// @param primarySaleFeeRecipient recipient address of optional primary sale fees
    /// @param primarySaleFeeBPS percent BPS of optimal primary sale fee
    /// @param soulbound false = tokens in contract are transferrable, true = non-transferrable
    event ERC721PressInitialized(
        address indexed sender,
        IERC721PressLogic indexed logic,
        IERC721PressRenderer indexed renderer,
        address payable fundsRecipient,
        uint16 royaltyBPS,
        address payable primarySaleFeeRecipient,
        uint16 primarySaleFeeBPS,
        bool soulbound
    );

    /// @notice Event emitted for each mint
    /// @param recipient address nfts were minted to
    /// @param quantity quantity of the minted nfts
    /// @param firstMintedTokenId first minted token ID for historic txn detail reconstruction
    /// @param totalMintPrice msg.value of mint txn
    event MintWithData(
        address indexed recipient,
        uint256 indexed quantity,
        uint256 indexed firstMintedTokenId,
        uint256 totalMintPrice
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

    /// @notice Event emitted when logic is updated post initialization
    /// @param sender address that sent update txn
    /// @param logic new logic contract address
    event UpdatedLogic(
        address indexed sender,
        IERC721PressLogic logic 
    );    

    /// @notice Event emitted when renderer is updated post initialization
    /// @param sender address that sent update txn
    /// @param renderer new renderer contract address
    event UpdatedRenderer(
        address indexed sender,
        IERC721PressRenderer renderer
    );        

    /// @notice Event emitted when config is updated post initialization
    /// @param sender address that sent update txn
    /// @param fundsRecipient new fundsRecipient
    /// @param maxSupply new maxSupply
    /// @param royaltyBPS new royaltyBPS
    event UpdatedConfig(
        address indexed sender,
        address fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS
    );

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice initializes a Press contract instance
    function initialize(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        IERC721PressLogic _logic,
        bytes memory _logicInit,
        IERC721PressRenderer _renderer,
        bytes memory _rendererInit,
        bool _soulbound,
        Configuration memory configuration
    ) external;

    /// @notice allows user to mint token(s) from the Press contract
    function mintWithData(uint64 mintQuantity, bytes memory mintData)
        external
        payable
        returns (uint256);

    /// @notice Function to set config.fundsRecipient
    /// @dev Cannot set `fundsRecipient` to the zero address
    /// @param newFundsRecipient payable address to receive funds via withdraw
    function setFundsRecipient(address payable newFundsRecipient) external;    

    /// @notice Function to set logic
    /// @dev cannot set logic to address(0)
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setLogic(IERC721PressLogic newLogic, bytes memory newLogicInit) external;

    /// @notice Function to set renderer
    /// @dev cannot set renderer to address(0)
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    function setRenderer(IERC721PressRenderer newRenderer, bytes memory newRendererInit) external;

    /// @notice Function to set config
    /// @dev Cannot set fundsRecipient or logic or renderer to address(0)
    /// @dev Max `newRoyaltyBPS` value = 5000
    /// @param fundsRecipient payable address to recieve funds via withdraw
    /// @param maxSupply uint64 value of maxSupply
    /// @param royaltyBPS uint16 value of royaltyBPS
    function setConfig(
        address payable fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS
    ) external;    

    /// @notice This withdraws ETH from the contract to the contract owner.
    function withdraw() external;

    /// @notice Public owner setting that can be set by the contract admin
    function owner() external view returns (address); 

    /// @notice Contract uri getter
    /// @dev Call proxies to renderer
    function contractURI() external view returns (string memory);

    /// @notice Token uri getter
    /// @dev Call proxies to renderer
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) external view returns (string memory);    

    /// @notice Getter for maxSupply stored in config
    function getMaxSupply() external view returns (uint64);    

    /// @notice Getter for fundsRecipent address stored in config
    function getFundsRecipient() external view returns (address payable);

    /// @notice Getter for renderer contract stored in config
    function getRenderer() external view returns (IERC721PressRenderer);    

    /// @notice Getter for logic contract stored in config
    function getLogic() external view returns (IERC721PressLogic);    

    /// @notice Getter for primarySaleFeeRecipient & BPS details stored in config
    function getPrimarySaleFeeDetails() external view returns (address payable, uint16);    

    /// @notice Getter for contract tokens' non-transferability status
    function isSoulbound() external view returns (bool);

    /// @notice Function to return global config details for the given Press
    function getConfigDetails() external view returns (Configuration memory);       

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool); 

    /// @dev Get royalty information for token
    /// @param _salePrice sale price for the token
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);    

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
    function lastMintedTokenId() external view returns (uint256);

    /// @notice Getter that returns number of tokens minted for a given address
    function numberMinted(address ownerAddress) external view returns (uint256);

    // @notice Getter that returns true if token has been minted and not burned
    function exists(uint256 tokenId) external view returns (bool);    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.16;

interface IERC721PressLogic {  

    // Initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    
    /// @notice updates logic file with arbitary data
    function updateLogicWithData(address targetPress, bytes memory logicData) external;

    // Access control functions
    /// @notice checks if a certain address can update the Config struct on a given Press 
    function canUpdateConfig(address targetPress, address updateCaller) external view returns (bool);
    /// @notice checks if a certain address can access mint functionality for a given Press + quantity combination
    function canMint(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (bool);
    /// @notice checks if a certain address can edit metadata post metadata initialization for a given Press
    function canEditMetadata(address targetPress, address editCaller) external view returns (bool);    
    /// @notice checks if a certain address can call the withdraw function for a given Press
    function canWithdraw(address targetPress, address withdrawCaller) external view returns (bool);    
    /// @notice checks if a certain address can call the burn function for a given Press
    function canBurn(address targetPress, uint256 tokenId, address burnCaller) external view returns (bool);       
    
    // Informative view functions
    /// @notice calculates total mintPrice based on mintCaller, mintQuantity, and targetPress
    function totalMintPrice(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (uint256);    
    /// @notice checks if a given Press has been initialized
    function isInitialized(address targetPress) external view returns (bool);    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC721PressRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory rendererInit) external;
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