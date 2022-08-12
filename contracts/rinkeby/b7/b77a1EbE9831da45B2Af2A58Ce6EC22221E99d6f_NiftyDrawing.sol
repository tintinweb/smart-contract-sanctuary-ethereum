//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

//                ,|||||<              ~|||||'         `_+7ykKD%RDqmI*~`          
//                [email protected]@@@@@8'           `[email protected]@@@@`     `^[email protected]@@@@@@@@@@@@@@@@R|`       
//               [email protected]@@@@@@@Q;          [email protected]@@@@J    '}[email protected]@@@@@[email protected]@@@@@@Q,      
//               [email protected]@@@@@@@@@j        `[email protected]@@@Q`  `[email protected]@@@@@h^`         `[email protected]@@@@*      
//              [email protected]@@@@@@@@@@@D.      [email protected]@@@@i  [email protected]@@@@w'              ^@@@@@*      
//              [email protected]@@@@[email protected]@@@@@@Q!    `@@@@@Q  ;@@@@@@;                .txxxx:      
//             |@@@@@u *@@@@@@@@z   [email protected]@@@@* `[email protected]@@@@^                              
//            `[email protected]@@@Q`  '[email protected]@@@@@@R.'@@@@@B  [email protected]@@@@%        :DDDDDDDDDDDDDD5       
//            [email protected]@@@@7    `[email protected]@@@@@@[email protected]@@@@+  [email protected]@@@@K        [email protected]@@@@@@*       
//           `@@@@@Q`      ^[email protected]@@@@@@@@@@W   [email protected]@@@@@;             ,[email protected]@@@@@#        
//           [email protected]@@@@L        ,[email protected]@@@@@@@@@!   '[email protected]@@@@@u,        [email protected]@@@@@@@^        
//          [email protected]@@@@Q           }@@@@@@@@D     '[email protected]@@@@@@@gUwwU%[email protected]@@@@@@@@@g         
//          [email protected]@@@@<            [email protected]@@@@@@;       ;[email protected]@@@@@@@@@@@@@@Wf;[email protected]@@;         
//          ~;;;;;              .;;;;;~           '!Lx5mEEmyt|!'    ;;;~          
//
// Powered By:    @niftygateway
// Author:        @niftynathang

import "../interfaces/INiftyDrawing.sol";
import "../structs/DrawingResult.sol";
import "../utils/NiftyPermissions.sol";

contract NiftyDrawing is NiftyPermissions, INiftyDrawing {
    
    address public drawingOrchestrator;
    address public nftContract;
    uint256 public niftyType;
    uint256 public numberOfEntries;
    uint256 public prizeTokenIdBegin;
    uint256 public prizeTokenIdEnd;    
    uint256 public randomWord;
    bool internal initializedDrawing;

    constructor() {}    

    function supportsInterface(bytes4 interfaceId) public view virtual override(NiftyPermissions, IERC165) returns (bool) {
        return         
        interfaceId == type(INiftyDrawing).interfaceId ||
        super.supportsInterface(interfaceId);
    }       

    function initializeDrawing(
        address drawingOrchestrator_,
        address nftContract_,
        uint256 niftyType_,
        uint256 numberOfEntries_, 
        uint256 prizeTokenIdBegin_, 
        uint256 prizeTokenIdEnd_) external override {
        
        require(!initializedDrawing, ERROR_REINITIALIZATION_NOT_PERMITTED);
        require(numberOfEntries_ > 0, "At least one entry required");
        require(prizeTokenIdEnd_ >= prizeTokenIdBegin_, "Invalid prize id range");
        drawingOrchestrator = drawingOrchestrator_;
        nftContract = nftContract_;
        niftyType = niftyType_;
        numberOfEntries = numberOfEntries_;
        prizeTokenIdBegin = prizeTokenIdBegin_;
        prizeTokenIdEnd = prizeTokenIdEnd_;
        initializedDrawing = true;
    }    

    function onDrawingRandomnessFulfilled(uint256 randomWord_) external override {
        require(_msgSender() == address(drawingOrchestrator), "Call not drawing orchestrator");
        require(randomWord == 0, "Randomness already fulfilled.");
        randomWord = randomWord_;
    }    

    function listWinners() public override view returns (DrawingResult[] memory) {
        require(randomWord != 0, "Randomness not yet fulfilled.");

        uint256 numberOfUsers = numberOfEntries;

        uint256[] memory tickets = new uint256[](numberOfUsers);
        for (uint256 i = 0; i < numberOfUsers; i++) {
            tickets[i] = i;
        }        

        uint256 firstPrizeId = prizeTokenIdBegin;
        uint256 lastPrizeId = prizeTokenIdEnd;
        uint256 numberOfPrizes = lastPrizeId - firstPrizeId + 1;
        uint256 numberOfWinners = numberOfPrizes > numberOfUsers ? numberOfUsers : numberOfPrizes;
        DrawingResult[] memory winners = new DrawingResult[](numberOfWinners);

        bytes32 currentRandomHash = keccak256(abi.encodePacked(randomWord));
        uint256 entryTicketsRemaining = tickets.length; 
        for(uint256 prizeIndex = 0; prizeIndex < numberOfPrizes; prizeIndex++) {            
            uint256 entryTicketsRemaining = entryTicketsRemaining;
            uint256 winningTicketIndex = entryTicketsRemaining > 0 ? uint256(currentRandomHash) % entryTicketsRemaining : 0;
            winners[prizeIndex] = DrawingResult(tickets[winningTicketIndex], prizeIndex + firstPrizeId);
            --entryTicketsRemaining;
            (tickets[winningTicketIndex], tickets[entryTicketsRemaining]) = (tickets[entryTicketsRemaining], tickets[winningTicketIndex]);
            currentRandomHash = keccak256(abi.encodePacked(currentRandomHash));
            if(entryTicketsRemaining == 0) {
                break;
            }
        }      

        return winners;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";
import "../structs/DrawingResult.sol";

interface INiftyDrawing is IERC165 {    
    function initializeDrawing(
        address drawingOrchestrator_,
        address nftContract_,
        uint256 niftyType_,
        uint256 numberOfEntries_, 
        uint256 prizeTokenIdBegin_, 
        uint256 prizeTokenIdEnd_) external;

    function onDrawingRandomnessFulfilled(uint256 randomWord_) external;
    function listWinners() external view returns (DrawingResult[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct DrawingResult {
    uint256 ticketNumber;
    uint256 tokenId;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC165.sol";
import "./GenericErrors.sol";
import "../interfaces/INiftyEntityCloneable.sol";
import "../interfaces/INiftyRegistry.sol";
import "../libraries/Context.sol";

abstract contract NiftyPermissions is Context, ERC165, GenericErrors, INiftyEntityCloneable {    

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    // Only allow Nifty Entity to be initialized once
    bool internal initializedNiftyEntity;

    // If address(0), use enable Nifty Gateway permissions - otherwise, specifies the address with permissions
    address public admin;

    // To prevent a mistake, transferring admin rights will be a two step process
    // First, the current admin nominates a new admin
    // Second, the nominee accepts admin
    address public nominatedAdmin;

    // Nifty Registry Contract
    INiftyRegistry internal permissionsRegistry;    

    function initializeNiftyEntity(address niftyRegistryContract_) public {
        require(!initializedNiftyEntity, ERROR_REINITIALIZATION_NOT_PERMITTED);
        permissionsRegistry = INiftyRegistry(niftyRegistryContract_);
        initializedNiftyEntity = true;
    }       
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return         
        interfaceId == type(INiftyEntityCloneable).interfaceId ||
        super.supportsInterface(interfaceId);
    }        

    function renounceAdmin() external {
        _requireOnlyValidSender();
        _transferAdmin(address(0));
    }    

    function nominateAdmin(address nominee) external {
        _requireOnlyValidSender();
        nominatedAdmin = nominee;
    }

    function acceptAdmin() external {
        address nominee = nominatedAdmin;
        require(_msgSender() == nominee, ERROR_INVALID_MSG_SENDER);
        _transferAdmin(nominee);
    }
    
    function _requireOnlyValidSender() internal view {       
        address currentAdmin = admin;     
        if(currentAdmin == address(0)) {
            require(permissionsRegistry.isValidNiftySender(_msgSender()), ERROR_INVALID_MSG_SENDER);
        } else {
            require(_msgSender() == currentAdmin, ERROR_INVALID_MSG_SENDER);
        }
    }        

    function _transferAdmin(address newAdmin) internal {
        address oldAdmin = admin;
        admin = newAdmin;
        delete nominatedAdmin;        
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

import "../interfaces/IERC165.sol";

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

pragma solidity 0.8.9;

abstract contract GenericErrors {
    string internal constant ERROR_INPUT_ARRAY_EMPTY = "Input array empty";
    string internal constant ERROR_INPUT_ARRAY_SIZE_MISMATCH = "Input array size mismatch";
    string internal constant ERROR_INVALID_MSG_SENDER = "Invalid msg.sender";
    string internal constant ERROR_UNEXPECTED_DATA_SIGNER = "Unexpected data signer";
    string internal constant ERROR_INSUFFICIENT_BALANCE = "Insufficient balance";
    string internal constant ERROR_WITHDRAW_UNSUCCESSFUL = "Withdraw unsuccessful";
    string internal constant ERROR_CONTRACT_IS_FINALIZED = "Contract is finalized";
    string internal constant ERROR_CANNOT_CHANGE_DEFAULT_OWNER = "Cannot change default owner";
    string internal constant ERROR_UNCLONEABLE_REFERENCE_CONTRACT = "Uncloneable reference contract";
    string internal constant ERROR_BIPS_OVER_100_PERCENT = "Bips over 100%";
    string internal constant ERROR_NO_ROYALTY_RECEIVER = "No royalty receiver";
    string internal constant ERROR_REINITIALIZATION_NOT_PERMITTED = "Re-initialization not permitted";
    string internal constant ERROR_ZERO_ETH_TRANSFER = "Zero ETH Transfer";
    string internal constant ERROR_IPFS_HASH_ALREADY_SET = "IPFS hash already set";
    string internal constant ERROR_INVALID_METADATA_GENERATOR = "Invalid Metadata Generator";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface INiftyEntityCloneable is IERC165 {
    function initializeNiftyEntity(address niftyRegistryContract_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INiftyRegistry {
   function isValidNiftySender(address sendingKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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