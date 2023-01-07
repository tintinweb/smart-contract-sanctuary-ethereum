// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Nameable.sol";
import { TokenNonOwner } from "./SetOwnerEnumerable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import { SetApprovable, ApprovableData, TokenNonExistent } from "./SetApprovable.sol";

abstract contract Approvable is OwnerEnumerable {  
    using SetApprovable for ApprovableData; 
    ApprovableData approvable;
 
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return approvable.isApprovedForAll(owner,operator);
    }  

    function approve(address to, uint256 tokenId) public virtual override {  
        if (ownerOf(tokenId) != msg.sender) {
            revert TokenNonOwner(msg.sender,tokenId);
        }        
        approvable.approveForToken(to, tokenId);
        emit Approval(ownerOf(tokenId), to, tokenId);        
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {   
        if (approved) {
            approvable.approveForContract(operator);
        } else {
            approvable.revokeApprovalForContract(operator, msg.sender);
        }        
    }       

    function validateApprovedOrOwner(address spender, uint256 tokenId) internal view {
        address owner = ownerOf(tokenId);
        if (!(spender == owner || isApprovedForAll(owner, spender) || approvable.getApproved(tokenId) == spender)) {
            revert TokenNonOwner(spender, tokenId);
        }
    }  

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        requireMinted(tokenId);
        return approvable.tokens[tokenId].approval;
    }       

    function revokeTokenApproval(uint256 tokenId) internal {
        approvable.revokeTokenApproval(tokenId);
    }

    function revokeApprovals(address holder) internal {
        approvable.revokeApprovals(holder,tokensOwnedBy(holder));                    
    }


    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function requireMinted(uint256 tokenId) internal view virtual {
        if (!exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
    }    

    function exists(uint256 tokenId) internal view virtual returns (bool) {
        return approvable.tokens[tokenId].exists;
    }      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetContractable, ContractableData, AllowedContract, AllowedPath } from "./SetContractable.sol";
import "./Mintable.sol";


abstract contract Contractable is Mintable {  
    using SetContractable for ContractableData;
    ContractableData contractables;
    function balanceOfAllowance(address wallet) public view returns (uint256) {
        return contractables.balanceOfAllowance(wallet);
    }
    function allowances(address wallet) public view returns (AllowedContract [] memory) {
        return contractables.allowances(wallet);
    }
    function allowContract(address allowed, string calldata urlPath, string calldata erc, uint256 balanceRequired, bool isStaking, bool isProxy) public {
        contractables.allowContract(allowed, urlPath, erc, balanceRequired, isStaking, isProxy);
    }
    function pathAllows(string calldata path) public view returns (AllowedPath memory) {
        return contractables.pathAllows(path);
    }
    function revokeContract(address revoked) public {
        contractables.revokeContract(revoked);
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Ownable.sol";
import { SetFlexibleMetadataData, FlexibleMetadataData } from "./SetFlexibleMetadata.sol";
uint256 constant DEFAULT = 1;
uint256 constant FLAG = 2;
uint256 constant PRE = 3;
abstract contract FlexibleMetadata is Ownable, Context, ERC165, IERC721, IERC721Metadata {  
    using SetFlexibleMetadataData for FlexibleMetadataData;
    FlexibleMetadataData flexible;   

    string tokenName;
    string tokenSymbol;
    constructor(string memory _name, string memory _symbol) {
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    function name() public virtual override view returns (string memory) {
        return tokenName;
    }  

    function symbol() public virtual override view returns (string memory) {
        return tokenSymbol;
    }      
    
    function setContractUri(string memory uri) public onlyOwner {
        flexible.setContractMetadataURI(uri);
    }

    function reveal(bool _reveal) public onlyOwner {
        flexible.reveal(_reveal);
    }

    function setTokenUri(string memory uri, uint256 tokenType) public {
        if (tokenType == FLAG) {
            flexible.setFlaggedTokenMetadataURI(uri);
        }
        else if (tokenType == PRE) {
            flexible.setPrerevealTokenMetadataURI(uri);
        } else {
            flexible.setDefaultTokenMetadataURI(uri);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }   

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {        
        return flexible.getTokenMetadata(tokenId);
    }          
    function contractURI() public view returns (string memory) {
        return flexible.getContractMetadata();
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Approvable.sol";
import { SetLockable, LockableStatus,  LockableData, WalletLockedByOwner } from "./SetLockable.sol";
abstract contract Lockable is Approvable {    
    using SetLockable for LockableData; 
    LockableData lockable;

    function custodianOf(uint256 id)
        public
        view
        returns (address)
    {             
        return lockable.findCustodian(ownerOf(id));
    }     

    function lockWallet(uint256 id) public {   
        address owner = ownerOf(id);
        revokeApprovals(owner);
        lockable.lockWallet(owner);
    }

    function unlockWallet(uint256 id) public {              
        lockable.unlockWallet(ownerOf(id));
    }    

    function _forceUnlock(uint256 id) internal {  
        lockable.forceUnlock(ownerOf(id));
    }    

    function setCustodian(uint256 id, address custodianAddress) public {       
        lockable.setCustodian(custodianAddress,ownerOf(id));
    }

    function isLocked(uint256 id) public view returns (bool) {     
        return lockable.lockableStatus[ownerOf(id)].isLocked;
    } 

    function lockedSince(uint256 id) public view returns (uint256) {     
        return lockable.lockableStatus[ownerOf(id)].lockedAt;
    }     

    function validateLock(uint256 tokenId) internal view {
        if (isLocked(tokenId)) {
            revert WalletLockedByOwner();
        }
    }

    function initializeLockable(address wallet, LockableStatus memory status) internal {
       lockable.lockableStatus[wallet] = status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Lockable.sol";
import { LockableStatus } from "./SetLockable.sol";

error InvalidTransferRecipient();
error NotApprovedOrOwner();
error InvalidOwner();
error OnlyOneSubscriptionPerWallet(uint256 balance);
error ContractIsNot721Receiver();

abstract contract LockableTransferrable is Lockable {  
    using Address for address;

    function approve(address to, uint256 tokenId) public virtual override {  
        validateLock(tokenId);
        super.approve(to,tokenId);      
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {   
        validateLock(tokensOwnedBy(msg.sender)[0]);
        super.setApprovalForAll(operator,approved);     
    }        

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {        
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _transfer(from,to,tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
                
        if (balanceOf(to) > 0) {
            revert OnlyOneSubscriptionPerWallet(balanceOf(to));
        } 
        if(to == address(0)) {
            revert InvalidTransferRecipient();
        }

        revokeTokenApproval(tokenId);   

        swapOwner(from,to,tokenId);     

        completeTransfer(from,to,tokenId);    
    }   

    function completeTransfer(
        address from,
        address to,
        uint256 tokenId) internal {

        emit Transfer(from, to, tokenId);

        address[] memory approvedAll;
    
        initializeLockable(to,LockableStatus(false,0,address(0),0,approvedAll,true)); 
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }    

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }     

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ContractIsNot721Receiver();
        }        
        _transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert InvalidTransferRecipient();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./LockableTransferrable.sol";

error InvalidRecipient(address zero);
error TokenAlreadyMinted(uint256 tokenId);
error MintIsNotLive();

abstract contract Mintable is LockableTransferrable {  
    bool isLive;
    uint256 tokenCount;

    function setMintLive(bool _isLive) public onlyOwner {
        isLive = _isLive;
    } 

    function _mint(address to, uint256 tokenId) internal virtual {
        if (!isLive) {
            revert MintIsNotLive();
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        if (exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        tokenCount +=1;

        enumerateMint(to, tokenId);

        completeTransfer(address(0),to,tokenId);
    }         

    function totalSupply() public view returns (uint256) {
        return tokenCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


abstract contract Nameable is IERC721Metadata {      
    string tokenName;
    string tokenSymbol;
    constructor(string memory _name, string memory _symbol) {
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    function name() public virtual override view returns (string memory) {
        return tokenName;
    }  

    function symbol() public virtual override view returns (string memory) {
        return tokenSymbol;
    }          
      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./TokenReceiver.sol";
import "./Mintable.sol";
import "./Nameable.sol";
import { DiscountIsInvalid } from "./SetSubscribable.sol";

error ZeroAddress(address zero);
contract OSMSubscription is TokenReceiver {  
    event CommissionPaid(address wallet, uint256 amount); 
    constructor(string memory name, string memory symbol) Subscribable(name,symbol) {}          

    function payOutFees(uint256 numberOfDays, string memory discountCode) internal {
        uint256 fee = determineFee(numberOfDays,discountCode);
        address payable partner = payable(subs.promoDiscounts[discountCode].partner);
        uint256 commission = determineCommission(fee, discountCode);
            
        if (commission > 0) {
            partner.transfer(commission);
            emit CommissionPaid(subs.promoDiscounts[discountCode].partner, commission);
        }        
        OSM_TREASURY_WALLET.transfer(fee-commission);
        subs.promoDiscounts[discountCode].timesUsed = subs.promoDiscounts[discountCode].timesUsed + 1; 
    }       

    function mint(uint256 numberOfDays) external payable {
        payOutFees(numberOfDays, blank);
        _mintTokenFor(msg.sender,numberOfDays);     
    }  

    function discountMint(uint256 numberOfDays, string calldata discountCode) external payable {          
        if (!subs.promoDiscounts[discountCode].exists || subs.promoDiscounts[discountCode].expires < block.timestamp) {
            revert DiscountIsInvalid(discountCode);
        }        
        payOutFees(numberOfDays, discountCode);
        subs.promoDiscounts[discountCode].timesUsed = subs.promoDiscounts[discountCode].timesUsed + 1;
        _mintTokenFor(msg.sender,numberOfDays,discountCode);          
    }    

    function mintForRecipient(address recipient, uint256 numberOfDays) external onlyOwner { 
        establishSubscription(incrementMint(recipient),numberOfDays);  
    }

    function _mintTokenFor(address recipient, uint256 numberOfDays) internal {
        _mintTokenFor(recipient,numberOfDays,blank);
    }
    function _mintTokenFor(address recipient, uint256 numberOfDays, string memory discountCode) internal {
        commitSubscription(incrementMint(recipient), numberOfDays, discountCode);  
    }

    function incrementMint(address recipient) private returns (uint256) {
        uint256 tokenId = totalSupply()+1;
        _mint(recipient,tokenId);
        return tokenId;
    }

    function renewOSM(uint256 tokenId, uint256 numberOfDays) public payable {
        renewOSM(tokenId, numberOfDays, blank);
    }

    function renewOSM(uint256 tokenId, uint256 numberOfDays, string memory discountCode) public payable {
        payOutFees(numberOfDays, discountCode);
        renewSubscription(tokenId, numberOfDays, discountCode);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
abstract contract Ownable {
    address private _owner;

    error CallerIsNotOwner(address caller);
    error OwnerCannotBeZeroAddress();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert CallerIsNotOwner(msg.sender);
        }
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
        if(newOwner == address(0)) {
            revert OwnerCannotBeZeroAddress();
        }
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
pragma solidity ^0.8.17;
import { SetOwnerEnumerable, OwnerEnumerableData, TokenNonOwner, InvalidOwner } from "./SetOwnerEnumerable.sol";
import { FlexibleMetadata } from "./FlexibleMetadata.sol";


abstract contract OwnerEnumerable is FlexibleMetadata {  
    using SetOwnerEnumerable for OwnerEnumerableData;
    OwnerEnumerableData enumerable;
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        return enumerable.ownerOf(tokenId);
    }

    function tokensOwnedBy(address holder) public view returns (uint256[] memory) {
        return enumerable.findTokensOwned(holder);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        validateNonZeroAddress(owner);
        return enumerable.ownedTokens[owner].length;
    }   
    function validateNonZeroAddress(address owner) internal pure {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
    }
    
    function enumerateMint(address to, uint256 tokenId) internal {
        enumerable.addTokenToEnumeration(to, tokenId);
    }

    function swapOwner(address from, address to, uint256 tokenId) internal {
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.addTokenToEnumeration(to, tokenId);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ApprovableData { 

    mapping(address => uint256) contractApprovals;
    mapping(address => address[]) approvedForAll;
    mapping(address => mapping(address => uint256)) approvedForAllIndex;

    mapping(uint256 => uint256) tokenApprovals;
    mapping(uint256 => TokenApproval[]) approvedForToken;
    mapping(uint256 => mapping(address => uint256)) approvedForTokenIndex;

    mapping(uint256 => TokenApproval) tokens;

    bool exists;
}    

struct TokenApproval {
    address approval;
    bool exists;
}

error AlreadyApproved(address operator, uint256 tokenId);
error AlreadyApprovedContract(address operator);
error AlreadyRevoked(address operator, uint256 tokenId);
error AlreadyRevokedContract(address operator);
error TokenNonExistent(uint256 tokenId);


library SetApprovable {     

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);    

    function isApprovedForAll(ApprovableData storage self, address owner, address operator) public view returns (bool) {        
        return self.approvedForAll[owner].length > self.approvedForAllIndex[owner][operator] ? 
            (self.approvedForAll[owner][self.approvedForAllIndex[owner][operator]] != address(0)) :
            false;
    }   

    function revokeApprovals(ApprovableData storage self, address owner, uint256[] memory ownedTokens) public {            
        
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            revokeTokenApproval(self,ownedTokens[i]);
        }
        
        address[] memory contractApprovals = self.approvedForAll[owner];
        for (uint256 i = 0; i < contractApprovals.length; i++) {
            address approved = contractApprovals[i];    
            revokeApprovalForContract(self, approved, owner);             
        }
    }   

    function revokeTokenApproval(ApprovableData storage self, uint256 token) public {            
        TokenApproval[] memory approvals = self.approvedForToken[token];
        for (uint256 j = 0; j < approvals.length; j++) {
            revokeApprovalForToken(self, approvals[j].approval, token);
        }         
    }       

    function getApproved(ApprovableData storage self, uint256 tokenId) public view returns (address) {
        return self.approvedForToken[tokenId].length > 0 ? self.approvedForToken[tokenId][0].approval : address(0);
    }     

    function approveForToken(ApprovableData storage self, address operator, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][operator];
        if (index < self.approvedForToken[tokenId].length && self.approvedForToken[tokenId][index].exists) {
            revert AlreadyApproved(operator, tokenId);
        }
   
        self.approvedForToken[tokenId].push(TokenApproval(operator,true));
        self.approvedForTokenIndex[tokenId][operator] = self.approvedForToken[tokenId].length-1;
        self.tokenApprovals[tokenId]++;
        
        emit Approval(msg.sender, operator, tokenId); 
    } 

    function revokeApprovalForToken(ApprovableData storage self, address revoked, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][revoked];
        if (!self.approvedForToken[tokenId][index].exists) {
            revert AlreadyRevoked(revoked,tokenId);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForToken[tokenId].length - 1) {
            TokenApproval storage tmp = self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1];
            self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1] = self.approvedForToken[tokenId][index];
            self.approvedForToken[tokenId][index] = tmp;
            self.approvedForTokenIndex[tokenId][tmp.approval] = index;            
        }

        // This also deletes the contents at the last position of the array
        delete self.approvedForTokenIndex[tokenId][revoked];
        self.approvedForToken[tokenId].pop();

        self.tokenApprovals[tokenId]--;
    }

    function approveForContract(ApprovableData storage self, address operator) public {
        uint256 index = self.approvedForAllIndex[msg.sender][operator];
        if (self.approvedForAll[msg.sender].length > index &&
            self.approvedForAll[msg.sender][index] != address(0)) {
            revert AlreadyApprovedContract(self.approvedForAll[msg.sender][index]);
        }
   
        self.approvedForAll[msg.sender].push(operator);
        self.approvedForAllIndex[msg.sender][operator] = self.approvedForAll[msg.sender].length-1;
        self.contractApprovals[msg.sender]++;

        emit ApprovalForAll(msg.sender, operator, true); 
    } 

    function revokeApprovalForContract(ApprovableData storage self, address revoked, address owner) public {
        uint256 index = self.approvedForAllIndex[owner][revoked];
        address revokee = self.approvedForAll[owner][index];
        if (revokee != revoked) {
            revert AlreadyRevokedContract(revoked);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForAll[owner].length - 1) {
            address tmp = self.approvedForAll[owner][self.approvedForAll[owner].length - 1];
            self.approvedForAll[owner][self.approvedForAll[owner].length - 1] = self.approvedForAll[owner][index];
            self.approvedForAll[owner][index] = tmp;
            self.approvedForAllIndex[owner][tmp] = index;            
        }
        // This also deletes the contents at the last position of the array
        delete self.approvedForAllIndex[owner][revoked];
        self.approvedForAll[owner].pop();

        self.contractApprovals[owner]--;

        emit ApprovalForAll(owner, revoked, false); 
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct AllowedContract {
    address addressed;
    string urlPath;
    string erc;
    uint256 balanceRequired;
    bool isStaking;
    bool isProxy;
    bool exists;
}

struct AllowedPath {
    address[] addresses;
    address wallet;
    bool exists;
}

struct ContractableData { 
    mapping(address => AllowedContract[]) contractAllowlist;
    mapping(string => AllowedPath) paths;
    mapping(address => mapping(address => uint256)) contractIndexList;
    
    mapping(address => uint256) allowanceBalances;
}    

library SetContractable {

    error AlreadyAllowed(address requester, address contracted);  
    error PathAlreadyInUse(string path);   
    error PathDoesNotExist(string path);  
    error WTF(bool success,address wtf);
    error IsNotAllowed(address requester, address contracted); 
    
    function balanceOfAllowance(ContractableData storage self, address wallet) public view returns (uint256) {        
        return self.allowanceBalances[wallet];
    }     

    function allowances(ContractableData storage self, address wallet) public view returns (AllowedContract [] memory) {
        return self.contractAllowlist[wallet];
    }

    function addAllowance(ContractableData storage self, address allowed, string calldata urlPath, string calldata erc, uint256 balanceRequired, bool isStaking, bool isProxy) public {
        self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self,msg.sender);
        self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,erc,balanceRequired,isStaking,isProxy,true));        
        self.allowanceBalances[msg.sender]++;
    }

    function allowContract(
        ContractableData storage self, 
        address allowed, 
        string calldata urlPath, 
        string calldata erc,
        uint256 balanceRequired,
        bool isStaking, 
        bool isProxy) public {
        if (self.paths[urlPath].exists && self.paths[urlPath].wallet != msg.sender) {
            revert PathAlreadyInUse(urlPath);
        } else if (balanceOfAllowance(self, msg.sender) > 0 && !self.paths[urlPath].exists) {
            for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
                AllowedContract storage existing = self.contractAllowlist[msg.sender][i];
                if (self.paths[existing.urlPath].exists) {
                    delete self.paths[existing.urlPath];
                }
                existing.urlPath = urlPath;
            }
        } 
        if (balanceOfAllowance(self,msg.sender) != 0) {
            uint256 index = self.contractIndexList[msg.sender][allowed];
            if (self.contractAllowlist[msg.sender][index].addressed == allowed) {
                revert AlreadyAllowed(msg.sender,allowed);
            }
        }
        addAllowance(self,allowed,urlPath,erc,balanceRequired,isStaking,isProxy);

        address[] memory addressed = new address[](balanceOfAllowance(self, msg.sender));
        for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
            addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
        }
        self.paths[urlPath] = AllowedPath(addressed,msg.sender,balanceOfAllowance(self, msg.sender) > 0);
    } 

    function removeAllowance(ContractableData storage self, address allowed, string calldata urlPath, string calldata erc, uint256 balanceRequired, bool isStaking, bool isProxy) public {
        self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self,msg.sender);
        self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,erc,balanceRequired,isStaking,isProxy,true));        
        self.allowanceBalances[msg.sender]++;
    }    

    function revokeContract(ContractableData storage self, address revoked) public {
        uint256 length = self.contractAllowlist[msg.sender].length;
        uint256 revokedIndex = self.contractIndexList[msg.sender][revoked];
        AllowedContract storage revokee = self.contractAllowlist[msg.sender][revokedIndex];
        // When the token to delete is the last token, the swap operation is unnecessary
        if (revokedIndex < length - 1) {
            AllowedContract memory lastItem = self.contractAllowlist[msg.sender][length - 1];
            self.contractAllowlist[msg.sender][revokedIndex] = lastItem; // Move the last token to the slot of the to-delete token
            self.contractIndexList[msg.sender][lastItem.addressed] = revokedIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.contractIndexList[msg.sender][revoked];
        self.contractAllowlist[msg.sender].pop();
        self.allowanceBalances[msg.sender]--;

        uint256 balanced = balanceOfAllowance(self, msg.sender);
        if (balanced > 0) {            
            address[] memory addressed = new address[](balanceOfAllowance(self, msg.sender));
            for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
                addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
            }
            self.paths[revokee.urlPath] = AllowedPath(addressed,msg.sender,true);
        } else {
            address[] memory addressed = new address[](0);
            self.paths[revokee.urlPath] = AllowedPath(addressed,msg.sender,false);      
        }

        
    }

    function pathAllows(ContractableData storage self, string calldata path) public view returns (AllowedPath memory) {
        if (!self.paths[path].exists) {
            revert PathDoesNotExist(path);
        }
        return self.paths[path];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct FlexibleMetadataData { 
    string defaultTokenMetadata;
    string prerevealTokenMetadata;
    string flaggedTokenMetadata;
    string contractMetadata;
    mapping(uint256 => bool) tokenFlag;
    bool tokenReveal; 
}    
bytes16 constant _SYMBOLS = "0123456789abcdef";
library SetFlexibleMetadataData {
    function setDefaultTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.defaultTokenMetadata = uri;
    }  
    function setPrerevealTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.prerevealTokenMetadata = uri;
    }  
    function setFlaggedTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.flaggedTokenMetadata = uri;
    }  
    function setContractMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.contractMetadata = uri;
    }  
    function reveal(FlexibleMetadataData storage self, bool revealed) public {
        self.tokenReveal = revealed;
    }

    function flagToken(FlexibleMetadataData storage self, uint256 tokenId, bool flagged) public {
        self.tokenFlag[tokenId] = flagged;
    }

    function getTokenMetadata(FlexibleMetadataData storage self, uint256 tokenId) public view returns (string memory) {
        if (self.tokenFlag[tokenId]) {
            return encodeURI(self.flaggedTokenMetadata,tokenId);
        } 
        if (!self.tokenReveal) {
            return encodeURI(self.prerevealTokenMetadata,tokenId);
        }
        return encodeURI(self.defaultTokenMetadata,tokenId);
    }

    function getContractMetadata(FlexibleMetadataData storage self) public view returns (string memory) { 
        return self.contractMetadata;
    }    

    function encodeURI(string storage uri, uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(uri, "/", toString(tokenId)));
    }

    function toString(uint256 value) public pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) public pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }        
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { InvalidOwner } from "./SetOwnerEnumerable.sol";
struct LockableData { 

    mapping(address => uint256) lockableStatusIndex; 

    mapping(address => LockableStatus) lockableStatus;  
} 


struct LockableStatus {
    bool isLocked;
    uint256 lockedAt;
    address custodian;
    uint256 balance;
    address[] approvedAll;
    bool exists;
}

uint64 constant MAX_INT = 2**64 - 1;

error OnlyCustodianCanLock();

error OnlyOwnerCanSetCustodian();

error WalletLockedByOwner();


library SetLockable {           

    function lockWallet(LockableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];    
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }       
        status.isLocked = true;
        status.lockedAt = block.timestamp;
    }

    function unlockWallet(LockableData storage self, address holder) public {        
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }                   
        
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }

    function setCustodian(LockableData storage self, address custodianAddress,  address holder) public {
        if (msg.sender != holder) {
            revert OnlyOwnerCanSetCustodian();
        }    
        LockableStatus storage status = self.lockableStatus[holder];
        status.custodian = custodianAddress;
    }

    function findCustodian(LockableData storage self, address wallet) public view returns (address) {
        return self.lockableStatus[wallet].custodian;
    }

    function forceUnlock(LockableData storage self, address owner) public {        
        LockableStatus storage status = self.lockableStatus[owner];
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }
            
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OwnerEnumerableData { 
    mapping(uint256 => TokenOwnership) tokens;
    mapping(address => uint256[]) ownedTokens;

    mapping(address => mapping(uint256 => uint256)) ownedTokensIndex; 

    uint256 totalSupply;    
}    

struct TokenOwnership {
    address ownedBy;
    bool exists;
}

error TokenNonOwner(address requester, uint256 tokenId); 
error InvalidOwner();

library SetOwnerEnumerable {
    function addTokenToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {        
        self.ownedTokens[to].push(tokenId);        
        uint256 length = self.ownedTokens[to].length;
        self.ownedTokensIndex[to][tokenId] = length-1;
        self.tokens[tokenId] = TokenOwnership(to,true);
    }    

    function removeTokenFromEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {

        uint256 length = self.ownedTokens[to].length;
        if (self.ownedTokensIndex[to][tokenId] > 0 && self.ownedTokensIndex[to][tokenId] != length - 1) {
            uint256 lastTokenId = self.ownedTokens[to][length - 1];
            self.ownedTokens[to][self.ownedTokensIndex[to][tokenId]] = lastTokenId; 
            self.ownedTokensIndex[to][lastTokenId] = self.ownedTokensIndex[to][tokenId];
        }

        delete self.ownedTokensIndex[to][tokenId];
        if (self.ownedTokens[to].length > 0) {
            self.ownedTokens[to].pop();
        }
    }    

    function findTokensOwned(OwnerEnumerableData storage self, address wallet) public view returns (uint256[] storage) {
        return self.ownedTokens[wallet];
    }  

    function tokenIndex(OwnerEnumerableData storage self, address wallet, uint256 index) public view returns (uint256) {
        return self.ownedTokens[wallet][index];
    }    

    function ownerOf(OwnerEnumerableData storage self, uint256 tokenId) public view returns (address) {
        address owner = self.tokens[tokenId].ownedBy;
        if (owner == address(0)) {
            revert TokenNonOwner(owner,tokenId);
        }
        return owner;
    }      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
struct ReceivableData { 
    mapping(address => mapping(address => uint256[])) receivedTokens;

    mapping(address => address[]) stakedContracts;

    mapping(address => mapping(address => uint256)) stakedContractIndex;

    mapping(address => mapping(uint256 => uint256)) receivedTokensIndex;    
    
    mapping(address => mapping(address => uint256)) walletBalances;
} 

interface Holdable {
    function balanceOf(address owner) external returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
}
error MintNotLive();

error ReceivedTokenNonExistent(uint256 tokenId);

error ReceivedTokenNonOwner(address requester, uint256 tokenId);  

library SetReceivable {    
 
    function balanceOfWallet(ReceivableData storage self, address wallet, address contracted) public view returns (uint256) {        
        return self.walletBalances[wallet][contracted];
    }

    function receivedFromWallet(ReceivableData storage self, address wallet, address contracted) public view returns (uint256[] memory) {        
        return self.receivedTokens[wallet][contracted];
    }    

    function _addTokenToReceivedEnumeration(ReceivableData storage self, address from, address contracted, uint256 tokenId) public {
        uint256 length = balanceOfWallet(self,from,contracted);
        
        if (length >= self.receivedTokens[from][contracted].length) {
            length = self.receivedTokens[from][contracted].length;
            self.receivedTokens[from][contracted].push(tokenId);
            // revert ReceivedTokenNonExistent(self.receivedTokens[from][contracted][0]);
        } else {
            self.receivedTokens[from][contracted][length] = tokenId;    
            
        }
        self.receivedTokensIndex[contracted][tokenId] = length;
        self.walletBalances[from][contracted]++;
        if (self.receivedTokens[from][contracted].length < 1) {
            revert ReceivedTokenNonExistent(tokenId);
        }     

        if (length < 1) {
            self.stakedContracts[from].push(contracted);
            self.stakedContractIndex[from][contracted] = self.stakedContracts[from].length;
        }    
    }    

    function _removeTokenFromReceivedEnumeration(ReceivableData storage self, address from, address contracted, uint256 tokenId) public {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).  

        // if (self.receivedTokens[from][contracted].length < 1) {
        //     revert ReceivedTokenNonExistent(tokenId);
        // }      

        // When the token to delete is the last token, the swap operation is unnecessary
        if (self.receivedTokens[from][contracted].length > self.receivedTokensIndex[contracted][tokenId] && 
        self.receivedTokensIndex[contracted][tokenId] != self.receivedTokens[from][contracted].length - 1) {
            uint256 lastTokenId = self.receivedTokens[from][contracted][balanceOfWallet(self,from,contracted) - 1];
            
            self.receivedTokens[from][contracted][self.receivedTokensIndex[contracted][tokenId]] = lastTokenId; // Move the last token to the slot of the to-delete token
            self.receivedTokensIndex[contracted][lastTokenId] = self.receivedTokensIndex[contracted][tokenId]; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.receivedTokensIndex[contracted][tokenId];
        self.receivedTokens[from][contracted].pop();
        self.walletBalances[from][contracted]--;

        uint256 left = balanceOfWallet(self,from,contracted);

        if (left < 1) {
            if (self.stakedContracts[from].length > self.stakedContractIndex[from][contracted] && 
                self.stakedContractIndex[from][contracted] != self.stakedContracts[from].length - 1) {
                
                address lastContract = self.stakedContracts[from][self.stakedContracts[from].length - 1];

                self.stakedContracts[from][self.stakedContracts[from].length - 1] = contracted;
                self.stakedContracts[from][self.stakedContractIndex[from][contracted]] = lastContract;                
            }

            self.stakedContracts[from].pop();
            delete self.stakedContractIndex[from][contracted];
        } 
    }    

    function tokenReceivedByIndex(ReceivableData storage self, address wallet, address contracted, uint256 index) public view returns (uint256) {
        return self.receivedTokens[wallet][contracted][index];
    }    

    function swapOwner(ReceivableData storage self, address from, address to) public {
        for (uint256 contractIndex = 0; contractIndex < self.stakedContracts[from].length; contractIndex++) {
            address contractToSwap = self.stakedContracts[from][contractIndex];
            
            uint256 tokenId = self.receivedTokens[from][contractToSwap][0];
            while (self.receivedTokens[from][contractToSwap].length > 0) {
                _removeTokenFromReceivedEnumeration(self,from,contractToSwap,tokenId);
                _addTokenToReceivedEnumeration(self,to,contractToSwap,tokenId);
                if ((self.receivedTokens[from][contractToSwap].length > 0)) {
                    tokenId = self.receivedTokens[from][contractToSwap][0];
                }
            }
        }
    }

    function withdraw(ReceivableData storage self, address contracted, uint256[] calldata tokenIds) public {        
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Holdable held = Holdable(contracted);
            if (held.ownerOf(tokenId) != address(this)) {
                revert ReceivedTokenNonOwner(address(this),tokenId);
            }
            // uint256 tokenIndex = self.receivedTokensIndex[contracted][tokenId];
            // if (self.receivedTokens[msg.sender][contracted].length > tokenIndex &&
            //     tokenReceivedByIndex(self,msg.sender,contracted,tokenIndex) != tokenId) {
            //     revert ReceivedTokenNonOwner(msg.sender,tokenIndex);
            // }            
            _removeTokenFromReceivedEnumeration(self,msg.sender,contracted,tokenId);
            IERC721(contracted).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SubscriptionSpans {
    uint256 one;
    uint256 three;
    uint256 six;
    uint256 twelve;
}

struct FeeStructure {
    uint256 baseMultiplier;
    uint256 baseDiscount;
    uint256 annual;
}

struct PromoDiscount {
    uint256 amount;
    uint256 commission;
    uint256 timesUsed;
    uint256 expires;
    address partner;
    bool exists;
}

struct SubscribableData { 
    // day number to rate
    // mapping(uint256 => RateStructure) spanToRate;
    // tokenId to expiration
    mapping(uint256 => uint256) subscriptions;
    mapping(string => PromoDiscount) promoDiscounts;
    SubscriptionSpans subscriptionSpans;
    FeeStructure feeStructure;
}    

error InvalidNumberOfDays(uint256 numberOfDays);
error InvalidAmountForDays(uint256 numberOfDays, uint256 amount, uint256 required);
error DiscountIsInvalid(string discountCode);

address constant defaultPayable = 0x5aE09f46967A92f3cF976e98f82B6FDd00784815;
string constant blank = " ";
uint256 constant never = 9999999999999999999999999999;

library SetSubscribable {

    event SubscriptionUpdate(uint256 indexed tokenId, uint256 expiration);
       
    function initialize(SubscribableData storage self) public {
        setSpans(self, 4 * 7, 12 * 7, 24 * 7, 48 * 7); // 4 weeks, 12 weeks, 24 weeks, 48 weeks
        setFeeStructure(self,4, 25, 52); // base multiplier, base discount, annual period
        self.promoDiscounts[blank] = PromoDiscount(0,0,0,never,defaultPayable,true);
    }

    function setSpans(SubscribableData storage self, uint256 one, uint256 three, uint256 six, uint256 twelve) public {
        self.subscriptionSpans = SubscriptionSpans(one,three,six,twelve);
    }

    function setFeeStructure(SubscribableData storage self, uint256 multiplier, uint256 discount, uint256 annual) public {
        self.feeStructure =  FeeStructure(multiplier,discount,annual);                
    }    

    function setRateParams(SubscribableData storage self, uint256 multiplier, uint256 discount) public {
        setSpans(self,28, 84, 168, 336);
        setFeeStructure(self,multiplier, discount, 52);
    }

    function establishSubscription(SubscribableData storage self, uint256 tokenId, uint256 numberOfDays) public {
        uint256 expiration;
        if (block.timestamp > self.subscriptions[tokenId]) {
            expiration = block.timestamp + numberOfDays * 1 days;
        } else {
            expiration = self.subscriptions[tokenId] + numberOfDays * 1 days;
        }        
        self.subscriptions[tokenId] = expiration;
        emit SubscriptionUpdate(tokenId, expiration);
    }      
    
    function calculateExpiration(SubscribableData storage self, uint256 tokenId, uint256 numberOfDays) public view returns (uint256) {
        if (block.timestamp > self.subscriptions[tokenId]) {
            return block.timestamp + numberOfDays * 1 days;
        } 
        return self.subscriptions[tokenId] + numberOfDays * 1 days;                     
    }

    function calculateBaseRate(SubscribableData storage self, uint256 numberOfDays) public view returns (uint256) {
        uint256 discountMultiplier = numberOfDays == self.subscriptionSpans.one ? 0 :
        numberOfDays == self.subscriptionSpans.three ? 1 :
        numberOfDays == self.subscriptionSpans.six ? 2 :
        3;

        uint256 spans = numberOfDays / 7;

        uint256 periodDiscount = discountMultiplier * self.feeStructure.baseDiscount * (1 ether);

        return ((self.feeStructure.baseMultiplier * 100 * (1 ether)) - periodDiscount) / 100 / self.feeStructure.annual * spans;
    } 

    function calculateDiscount(uint256 promoDiscount) public pure returns (uint256) {
        return 100-promoDiscount;
    }         

    function calculateFee(SubscribableData storage self, uint256 numberOfDays) public view returns (uint256) {    
        return calculateFee(self, numberOfDays, blank);                                           
    }   

    function calculateFee(SubscribableData storage self, uint256 numberOfDays, string memory discountCode) public view returns (uint256) {

        validateDays(self,numberOfDays);        

        uint256 baseRate = calculateBaseRate(self,numberOfDays);

        uint256 discount = calculateDiscount(self.promoDiscounts[discountCode].amount);

        baseRate = baseRate * discount / 100;

        return floor(baseRate);        
    }       
    function calculateCommission(SubscribableData storage self, uint256 originalAmount, string memory discountCode) public view returns (uint256) {
        uint256 commissionRate = self.promoDiscounts[discountCode].commission > 0 ? 10000/self.promoDiscounts[discountCode].commission : 0;
        
        uint256 commission = 0;
        if (commissionRate >= 1) {
            commission = originalAmount / commissionRate * 100;            
        }     

        return commission;      
    }         
      
    function validateDays(SubscribableData storage self, uint256 numberOfDays) public view {
        if (numberOfDays != self.subscriptionSpans.one &&
            numberOfDays != self.subscriptionSpans.three && 
            numberOfDays != self.subscriptionSpans.six && 
            numberOfDays != self.subscriptionSpans.twelve ) {
            revert InvalidNumberOfDays(numberOfDays);
        }
    }

    function validatePayment(SubscribableData storage self, uint256 numberOfDays, string memory promoDiscount) public view {        
        uint256 cost = calculateFee(self, numberOfDays, promoDiscount);
        
        if (msg.value != cost) {
            revert InvalidAmountForDays(numberOfDays, msg.value, cost);
        }
    }

    function validateSubscription(SubscribableData storage self, uint256 numberOfDays, string calldata discountCode) public view {
        validateDays(self,numberOfDays);
        validatePayment(self,numberOfDays,discountCode);
    }    

    function validateSubscription(SubscribableData storage self, uint256 numberOfDays) public view {
        validateDays(self,numberOfDays);
        validatePayment(self,numberOfDays,blank);
    }     

    function floor(uint256 amount) public pure returns (uint256) {        
        return amount - (amount % 10000000000000000);
    }

    function expiresAt(SubscribableData storage self, uint256 tokenId) public view returns(uint256) {
        return self.subscriptions[tokenId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Contractable.sol";
import "./FlexibleMetadata.sol";
import {SetSubscribable, SubscribableData, PromoDiscount, defaultPayable, InvalidNumberOfDays } from "./SetSubscribable.sol";

abstract contract Subscribable is Contractable {
    using SetSubscribable for SubscribableData; // this is the crucial change
    SubscribableData subs;

    string constant blank = " ";

    address payable internal OSM_TREASURY_WALLET = payable(defaultPayable);

    constructor(string memory name, string memory symbol) FlexibleMetadata(name,symbol) {
        subs.initialize();
    }  

    function standardFee(uint256 numberOfDays) public view returns (uint256) {
        return subs.calculateFee(numberOfDays);        
    }     

    function determineFee(uint256 numberOfDays, string memory discountCode) public view returns (uint256) {
        return subs.calculateFee(numberOfDays,discountCode);        
    }      

    function determineCommission(uint256 amount, string memory discountCode) public view returns (uint256) {
        return subs.calculateCommission(amount,discountCode);
    }

    function floor(uint256 amount) internal pure returns (uint256) {
        return amount - (amount % 1000000000000000);
    }

    function expiresAt(uint256 tokenId) external view returns (uint256) {
        return subs.expiresAt(tokenId);
    }

    function setRecipient(address recipient) external onlyOwner {        
        OSM_TREASURY_WALLET = payable(recipient);    
    }

    function addPromoDiscount(string calldata discountCode, uint256 amount, uint256 commission, address partner) external onlyOwner {    
        subs.promoDiscounts[discountCode] = PromoDiscount(amount,commission,0,block.timestamp + (4 * 7 days),partner,true);
    }   

    function getPromoDiscount(string calldata discountCode) external view returns (PromoDiscount memory) {    
        return subs.promoDiscounts[discountCode];
    }       

    function setRateParams(uint256 multiplier, uint256 discount) external onlyOwner {
        subs.setRateParams(multiplier,discount);
    }

    function commitSubscription(uint256 tokenId, uint numberOfDays) internal {
        commitSubscription(tokenId, numberOfDays, blank);      
    }

    function establishSubscription(uint256 tokenId, uint numberOfDays) internal {
        subs.establishSubscription(tokenId, numberOfDays);      
    }    
    
    function commitSubscription(uint256 tokenId, uint numberOfDays, string memory discountCode) internal {
        subs.validateSubscription(numberOfDays,discountCode);
        subs.establishSubscription(tokenId,numberOfDays);        
    }

    function renewSubscription(uint256 tokenId, uint numberOfDays, string memory discountCode) internal {
        validateApprovedOrOwner(msg.sender, tokenId);
        subs.validateSubscription(numberOfDays, discountCode);
        commitSubscription(tokenId, numberOfDays, discountCode);
    }

    function isRenewable(uint256 tokenId) external view returns(bool) {
        return exists(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Subscribable.sol";
import "./LockableTransferrable.sol";
import { SetReceivable, ReceivableData, ReceivedTokenNonExistent, ReceivedTokenNonOwner, MintNotLive } from "./SetReceivable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error ReceiverNotImplemented();

abstract contract TokenReceiver is Subscribable,IERC721Receiver {
    using Address for address;
    using SetReceivable for ReceivableData; // this is the crucial change
    ReceivableData receivables;
      

    function balanceOfWallet(address wallet, address contracted) public view returns (uint256) {
        return receivables.balanceOfWallet(wallet,contracted);
    }  

    function hasReceived(address wallet, address contracted) public view returns (uint256[] memory) {
        return receivables.receivedFromWallet(wallet,contracted);
    }

    function _addTokenToReceivedEnumeration(address from, address contracted, uint256 tokenId) private {
        receivables._addTokenToReceivedEnumeration(from,contracted,tokenId);
    }    

    function _removeTokenFromReceivedEnumeration(address from, address contracted, uint256 tokenId) private {
        receivables._removeTokenFromReceivedEnumeration(from,contracted,tokenId);
    }

    function tokenReceivedByIndex(address wallet, address contracted, uint256 index) public view returns (uint256) {
        return receivables.tokenReceivedByIndex(wallet,contracted,index);
    }

    function withdraw(address contracted, uint256[] calldata tokenIds) public {
        return receivables.withdraw(contracted,tokenIds);
    }
 
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
        _addTokenToReceivedEnumeration(from, msg.sender, tokenId);
        return this.onERC721Received.selector;
    }     

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, "");
        receivables.swapOwner(from,to);
    }   

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
        receivables.swapOwner(from,to);
    }
     
}