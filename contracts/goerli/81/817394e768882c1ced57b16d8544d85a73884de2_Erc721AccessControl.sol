// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IAccessControlRegistry} from "./interfaces/IAccessControlRegistry.sol";

contract Erc721AccessControl is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // ERRORS 
    //////////////////////////////////////////////////
    
    error Access_OnlyAdmin();

    //////////////////////////////////////////////////
    // EVENTS 
    //////////////////////////////////////////////////

    /// @notice Event for updated curatorAccess
    event CuratorAccessUpdated(
        address indexed target,
        IERC721Upgradeable curatorAccess
    );    

    /// @notice Event for updated managerAccess
    event ManagerAccessUpdated(
        address indexed target,
        IERC721Upgradeable managerAccess
    );        

    /// @notice Event for updated adminAccess
    event AdminAccessUpdated(
        address indexed target,
        IERC721Upgradeable adminAccess
    );       

    /// @notice Event for updated AccessLevelInfo
    event AllAccessUpdated(
        address indexed target,
        IERC721Upgradeable curatorAccess,
        IERC721Upgradeable managerAccess,
        IERC721Upgradeable adminAccess
    );           

    /// @notice Event for a new access control initialized
    /// @dev admin function indexer feedback
    event AccessControlInitialized(
        address indexed target,
        IERC721Upgradeable curatorAccess,
        IERC721Upgradeable managerAccess,
        IERC721Upgradeable adminAccess
    );    

    //////////////////////////////////////////////////
    // VARIABLES 
    //////////////////////////////////////////////////

    // struct that contains addresses which gate different levels of access to curation contract
    struct AccessLevelInfo {
        IERC721Upgradeable curatorAccess;
        IERC721Upgradeable managerAccess;
        IERC721Upgradeable adminAccess;
    }

    /// @notice access information mapping storage
    /// @dev curation contract => AccessLevelInfo struct
    mapping(address => AccessLevelInfo) public accessMapping;

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS 
    //////////////////////////////////////////////////

    /// @dev updates ERC721 address used to define curator access
    function updateCurator(
        address target,
        IERC721Upgradeable newCuratorAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].curatorAccess = newCuratorAccess; 

        emit CuratorAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess
        });
    }

    /// @dev updates ERC721 address used to define manager access
    function updateManagerAccess(
        address target,
        IERC721Upgradeable newManagerAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].managerAccess = newManagerAccess; 

        emit ManagerAccessUpdated({
            target: target,
            managerAccess: newManagerAccess
        });
    }    

    /// @dev updates ERC721 address used to define admin access
    function updateAdminAccess(
        address target,
        IERC721Upgradeable newAdminAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].adminAccess = newAdminAccess; 

        emit AdminAccessUpdated({
            target: target,
            adminAccess: newAdminAccess
        });
    }      

    /// @dev updates ERC721 address used to define curator, manager, and admin access
    function updateAllAccess(
        address target,
        IERC721Upgradeable newCuratorAccess,
        IERC721Upgradeable newManagerAccess,
        IERC721Upgradeable newAdminAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].curatorAccess = newCuratorAccess; 
        accessMapping[target].managerAccess = newManagerAccess; 
        accessMapping[target].adminAccess = newAdminAccess; 

        emit AllAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess,
            managerAccess: newManagerAccess,
            adminAccess: newAdminAccess
        });
    }              

    /// @dev called by other contracts initiating access control
    ///     initializes mapping of contract getting access control => erc721 addresses used for access control of different roles
    function initializeWithData(bytes memory data) external {
        // data format: curatorAccess, managerAccess, adminAccess
        (
            IERC721Upgradeable curatorAccess,
            IERC721Upgradeable managerAccess,
            IERC721Upgradeable adminAccess
        ) = abi.decode(data, (IERC721Upgradeable, IERC721Upgradeable, IERC721Upgradeable));

        accessMapping[msg.sender] = AccessLevelInfo({
            curatorAccess: curatorAccess,
            managerAccess: managerAccess,
            adminAccess: adminAccess
        });

        emit AccessControlInitialized({
            target: msg.sender,
            curatorAccess: curatorAccess,
            managerAccess: managerAccess,
            adminAccess: adminAccess
        });
    }

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS 
    //////////////////////////////////////////////////

    /// @dev returns access level of a user address calling function
    ///     via the external contract that has initialized access control
    function getAccessLevel(address addressToCheckLevel)
        external
        view
        returns (uint256)
    {
        address target = msg.sender;

        AccessLevelInfo memory info = accessMapping[target];

        if (info.adminAccess.balanceOf(addressToCheckLevel) != 0) {
            return 3;
        } 

        if (info.managerAccess.balanceOf(addressToCheckLevel) != 0) {
            return 2;
        } 

        if (info.curatorAccess.balanceOf(addressToCheckLevel) != 0) {
            return 1;
        }         

        return 0;
    }

    /// @dev returns the addresses being used for access control
    function getAccessInfo(address addressToCheck) 
        external 
        view 
        returns (AccessLevelInfo memory)
    {
        return accessMapping[addressToCheck];
    }    

    /// @dev returns the erc721 address being used for curator access control
    function getCuratorInfo(address addressToCheck) 
        external 
        view 
        returns (IERC721Upgradeable)
    {
        return accessMapping[addressToCheck].curatorAccess;
    }    

    /// @dev returns the erc721 address being used for manager access control
    function getManagerInfo(address addressToCheck) 
        external 
        view 
        returns (IERC721Upgradeable)
    {
        return accessMapping[addressToCheck].managerAccess;
    }        

    /// @dev returns the erc721 address being used for admin access control
    function getAdminInfo(address addressToCheck) 
        external 
        view 
        returns (IERC721Upgradeable)
    {
        return accessMapping[addressToCheck].adminAccess;
    }        
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccessControlRegistry {
    
    function initializeWithData(bytes memory initData) external;
    
    function getAccessLevel(address) external view returns (uint256);
    
}