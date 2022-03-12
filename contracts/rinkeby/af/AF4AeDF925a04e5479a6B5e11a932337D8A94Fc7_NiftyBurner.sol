// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Withdrawable.sol";
import "../interfaces/IERC721Burnable.sol";

contract NiftyBurner is Withdrawable {

    constructor(address niftyRegistryContract_) {
        initializeNiftyEntity(niftyRegistryContract_);
    }

    function burnBatch(address tokenContract, uint256[] calldata tokenIds) external {
        require(tokenIds.length <= 500, "Burns up to 500 tokens per tx");
        IERC721Burnable burnableTokenContract = IERC721Burnable(tokenContract);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            burnableTokenContract.burn(tokenIds[i]);
        }
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RejectEther.sol";
import "./NiftyPermissions.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";

abstract contract Withdrawable is RejectEther, NiftyPermissions {

    /**
     * @dev Slither identifies an issue with sending ETH to an arbitrary destianation.
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     * Recommended mitigation is to "Ensure that an arbitrary user cannot withdraw unauthorized funds."
     * This mitigation has been performed, as only the contract admin can call 'withdrawETH' and they should
     * verify the recipient should receive the ETH first.
     */
    function withdrawETH(address payable recipient, uint256 amount) external {
        _requireOnlyValidSender();
        require(amount > 0, ERROR_ZERO_ETH_TRANSFER);
        require(recipient != address(0), "Transfer to zero address");

        uint256 currentBalance = address(this).balance;
        require(amount <= currentBalance, ERROR_INSUFFICIENT_BALANCE);

        //slither-disable-next-line arbitrary-send        
        (bool success,) = recipient.call{value: amount}("");
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
    }
        
    function withdrawERC20(address tokenContract, address recipient, uint256 amount) external {
        _requireOnlyValidSender();
        bool success = IERC20(tokenContract).transfer(recipient, amount);
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
    }
    
    function withdrawERC721(address tokenContract, address recipient, uint256 tokenId) external {
        _requireOnlyValidSender();
        IERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId, "");
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC721Burnable {    
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title A base contract that may be inherited in order to protect a contract from having its fallback function 
 * invoked and to block the receipt of ETH by a contract.
 * @author Nathan Gang
 * @notice This contract bestows on inheritors the ability to block ETH transfers into the contract
 * @dev ETH may still be forced into the contract - it is impossible to block certain attacks, but this protects from accidental ETH deposits
 */
 // For more info, see: "https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56"
abstract contract RejectEther {    

    /**
     * @dev For most contracts, it is safest to explicitly restrict the use of the fallback function
     * This would generally be invoked if sending ETH to this contract with a 'data' value provided
     */
    fallback() external payable {        
        revert("Fallback function not permitted");
    }

    /**
     * @dev This is the standard path where ETH would land if sending ETH to this contract without a 'data' value
     * In our case, we don't want our contract to receive ETH, so we restrict it here
     */
    receive() external payable {
        revert("Receiving ETH not permitted");
    }    
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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