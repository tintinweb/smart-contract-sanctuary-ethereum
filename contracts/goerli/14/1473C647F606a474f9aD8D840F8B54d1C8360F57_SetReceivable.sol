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
        if (self.receivedTokens[from][contracted].length > self.receivedTokensIndex[contracted][tokenId]) {
            if (self.receivedTokensIndex[contracted][tokenId] != self.receivedTokens[from][contracted].length - 1) {
                uint256 lastTokenId = self.receivedTokens[from][contracted][balanceOfWallet(self,from,contracted) - 1];
                
                self.receivedTokens[from][contracted][self.receivedTokensIndex[contracted][tokenId]] = lastTokenId; // Move the last token to the slot of the to-delete token
                self.receivedTokensIndex[contracted][lastTokenId] = self.receivedTokensIndex[contracted][tokenId]; // Update the moved token's index
            }
        } 
        

        // This also deletes the contents at the last position of the array
        delete self.receivedTokensIndex[contracted][tokenId];
        self.receivedTokens[from][contracted].pop();
        self.walletBalances[from][contracted]--;

        uint256 left = balanceOfWallet(self,from,contracted);

        if (left < 1) {
            if (self.stakedContracts[from].length > self.stakedContractIndex[from][contracted]) {
                if (self.stakedContractIndex[from][contracted] != self.stakedContracts[from].length - 1) {
                
                    address lastContract = self.stakedContracts[from][self.stakedContracts[from].length - 1];

                    self.stakedContracts[from][self.stakedContracts[from].length - 1] = contracted;
                    self.stakedContracts[from][self.stakedContractIndex[from][contracted]] = lastContract;                
                }
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