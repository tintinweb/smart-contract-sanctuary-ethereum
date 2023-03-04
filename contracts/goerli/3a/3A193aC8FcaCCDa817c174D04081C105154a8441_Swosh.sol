// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

/*
             _____                    _____                   _______         
           /::\    \                /::\____\               /::::\    \       
          /::::\    \              /:::/    /              /::::::\    \      
         /::::::\    \            /:::/   _/___           /::::::::\    \     
        /:::/\:::\    \          /:::/   /\    \         /:::/~~\:::\    \    
       /:::/__\:::\    \        /:::/   /::\____\       /:::/    \:::\    \   
       \:::\   \:::\    \      /:::/   /:::/    /      /:::/    / \:::\    \  
     ___\:::\   \:::\    \    /:::/   /:::/   _/___   /:::/____/   \:::\____\ 
    /\   \:::\   \:::\    \  /:::/___/:::/   /\    \ |:::|    |     |:::|    |
   /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\|:::|____|     |:::|    |
   \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    / \:::\    \   /:::/    / 
    \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /   \:::\    \ /:::/    /  
     \:::\   \:::\    \       \::::::/   /:::/    /     \:::\    /:::/    /   
      \:::\   \:::\____\       \::::/___/:::/    /       \:::\__/:::/    /    
       \:::\  /:::/    /        \:::\__/:::/    /         \::::::::/    /     
        \:::\/:::/    /          \::::::::/    /           \::::::/    /      
         \::::::/    /            \::::::/    /             \::::/    /       
          \::::/    /              \::::/    /               \::/____/        
           \::/    /                \::/____/                 ~~              
            \/____/                  ~~                                       
                        _____                    _____
                      /::\    \                /::\____\
                     /::::\    \              /:::/    /
                    /::::::\    \            /:::/    /
                   /:::/\:::\    \          /:::/    /
                  /:::/__\:::\    \        /:::/____/
                  \:::\   \:::\    \      /::::\    \
                ___\:::\   \:::\    \    /::::::\    \   _____
               /\   \:::\   \:::\    \  /:::/\:::\    \ /\    \
              /::\   \:::\   \:::\____\/:::/  \:::\    /::\____\
              \:::\   \:::\   \::/    /\::/    \:::\  /:::/    /
               \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /
                \:::\   \:::\    \               \::::::/    /
                 \:::\   \:::\____\               \::::/    /
                  \:::\  /:::/    /               /:::/    /
                   \:::\/:::/    /               /:::/    /
                    \::::::/    /               /:::/    /
                     \::::/    /               /:::/    /
                      \::/    /                \::/    /
                       \/____/                  \/____/

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

/**
    @notice Error thrown when invalid parameters are passed
*/
error INVALID_PARAM();

/**
    @notice Error thrown when the operation is forbidden
*/
error FORBIDDEN();

/**
 * @notice
 *  ERC20 Batch Transfer Structure format
 *
 * @param tokens ERC20 token addresses to be sent
 * @param recipient recipient address
 * @param amounts amounts to be sent
 */
struct ERC20Param {
    address[] tokens;
    address recipient;
    uint256[] amounts;
}

/**
 * @notice
 *  ERC721 Batch Transfer Structure format
 *
 * @param tokens ERC721 token addresses to be sent
 * @param recipient recipient address
 * @param tokenIds tokenIds to be sent
 */
struct ERC721Param {
    address[] tokens;
    address recipient;
    uint256[] tokenIds;
}

/**
 * @notice
 *  ERC1155 Batch Transfer Structure format
 *
 * @param tokens ERC1155 token addresses to be sent
 * @param recipient recipient address
 * @param tokenIds tokenIds to be sent
 * @param amounts amounts to be sent
 */
struct ERC1155Param {
    address[] tokens;
    address recipient;
    uint256[] tokenIds;
    uint256[] amounts;
}

/**
 * @notice
 *  Multiple Recipients ERC20 Batch Transfer Structure format
 *
 * @param tokens ERC20 token addresses to be sent
 * @param recipients recipients addresses
 * @param amounts amounts to be sent
 */
struct MultiERC20Param {
    address[] tokens;
    address[] recipients;
    uint256[] amounts;
}

/**
 * @notice
 *  Multiple Recipients ERC721 Batch Transfer Structure format
 *
 * @param tokens ERC721 token addresses to be sent
 * @param recipients recipients addresses
 * @param tokenIds tokenIds to be sent
 */
struct MultiERC721Param {
    address[] tokens;
    address[] recipients;
    uint256[] tokenIds;
}

/**
 * @notice
 *  Multiple Recipients ERC1155 Batch Transfer Structure format
 *
 * @param tokens ERC1155 token addresses to be sent
 * @param recipients recipients addresses
 * @param tokenIds tokenIds to be sent
 * @param amounts amounts to be sent
 */
struct MultiERC1155Param {
    address[] tokens;
    address[] recipients;
    uint256[] tokenIds;
    uint256[] amounts;
}

contract Swosh {
    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Send different types of tokens to one recipient address
     *
     * @param _erc20Params Parameters for ERC20 batch transfer (refer to ERC20Param structure)
     * @param _erc721Params Parameters for ERC721 batch transfer (refer to ERC721Param structure)
     * @param _erc1155Params Parameters for ERC1155 batch transfer (refer to ERC1155Param structure)
     */
    function megaTransfer(
        ERC20Param calldata _erc20Params,
        ERC721Param calldata _erc721Params,
        ERC1155Param calldata _erc1155Params
    ) external {
        // Check if there are ERC20 tokens to be sent
        if (_erc20Params.tokens.length > 0) {
            _batchTransferERC20(
                _erc20Params.tokens,
                _erc20Params.recipient,
                _erc20Params.amounts
            );
        }

        // Check if there are ERC721 tokens to be sent
        if (_erc721Params.tokens.length > 0) {
            _batchTransferERC721(
                _erc721Params.tokens,
                _erc721Params.recipient,
                _erc721Params.tokenIds
            );
        }

        // Check if there are ERC1155 tokens to be sent
        if (_erc1155Params.tokens.length > 0) {
            _batchTransferERC1155(
                _erc1155Params.tokens,
                _erc1155Params.recipient,
                _erc1155Params.tokenIds,
                _erc1155Params.amounts
            );
        }
    }

    /**
     * @notice
     *  Send different types of tokens to one recipient address
     *
     * @param _erc20Params Parameters for ERC20 multi recipients batch transfer (refer to MultiERC20Param structure)
     * @param _erc721Params Parameters for ERC721 multi recipients batch transfer (refer to MultiERC721Param structure)
     * @param _erc1155Params Parameters for ERC1155 multi recipients batch transfer (refer to MultiERC1155Param structure)
     */
    function multiMegaTransfer(
        MultiERC20Param calldata _erc20Params,
        MultiERC721Param calldata _erc721Params,
        MultiERC1155Param calldata _erc1155Params
    ) external {
        // Check if there are ERC20 tokens to be sent
        if (_erc20Params.tokens.length > 0) {
            _multiBatchTransferERC20(
                _erc20Params.tokens,
                _erc20Params.recipients,
                _erc20Params.amounts
            );
        }

        // Check if there are ERC721 tokens to be sent
        if (_erc721Params.tokens.length > 0) {
            _multiBatchTransferERC721(
                _erc721Params.tokens,
                _erc721Params.recipients,
                _erc721Params.tokenIds
            );
        }

        // Check if there are ERC1155 tokens to be sent
        if (_erc1155Params.tokens.length > 0) {
            _multiBatchTransferERC1155(
                _erc1155Params.tokens,
                _erc1155Params.recipients,
                _erc1155Params.tokenIds,
                _erc1155Params.amounts
            );
        }
    }

    //     __________  ______   ___   ____
    //    / ____/ __ \/ ____/  |__ \ / __ \
    //   / __/ / /_/ / /       __/ // / / /
    //  / /___/ _, _/ /___    / __// /_/ /
    // /_____/_/ |_|\____/   /____/\____/

    /**
     * @notice
     *  Send multiple ERC20 to one recipient
     *
     * @param _tokens ERC20 token addresses to be sent
     * @param _recipient recipient address
     * @param _amounts amounts to be sent
     */
    function batchTransferERC20(
        address[] calldata _tokens,
        address _recipient,
        uint256[] calldata _amounts
    ) external {
        _batchTransferERC20(_tokens, _recipient, _amounts);
    }

    /**
     * @notice
     *  Send multiple ERC20 to multiple recipients
     *
     * @param _tokens ERC20 token addresses to be sent
     * @param _recipients recipients addresses
     * @param _amounts amounts to be sent
     */
    function multiBatchTransferERC20(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external {
        _multiBatchTransferERC20(_tokens, _recipients, _amounts);
    }

    //     __________  ______   ________  ___
    //    / ____/ __ \/ ____/  /__  /__ \<  /
    //   / __/ / /_/ / /         / /__/ // /
    //  / /___/ _, _/ /___      / // __// /
    // /_____/_/ |_|\____/     /_//____/_/

    /**
     * @notice
     *  Send multiple ERC721 to one recipient
     *
     * @param _tokens ERC721 token addresses to be sent
     * @param _recipient recipient address
     * @param _tokenIds tokenIds to be sent
     */
    function batchTransferERC721(
        address[] calldata _tokens,
        address _recipient,
        uint256[] calldata _tokenIds
    ) external {
        _batchTransferERC721(_tokens, _recipient, _tokenIds);
    }

    /**
     * @notice
     *  Send multiple ERC721 to multiple recipients
     *
     * @param _tokens ERC721 token addresses to be sent
     * @param _recipients recipients addresses
     * @param _tokenIds tokenIds to be sent
     */
    function multiBatchTransferERC721(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds
    ) external {
        _multiBatchTransferERC721(_tokens, _recipients, _tokenIds);
    }

    //     __________  ______   __________________
    //    / ____/ __ \/ ____/  <  <  / ____/ ____/
    //   / __/ / /_/ / /       / // /___ \/___ \
    //  / /___/ _, _/ /___    / // /___/ /___/ /
    // /_____/_/ |_|\____/   /_//_/_____/_____/

    /**
     * @notice
     *  Send multiple ERC1155 to one recipient
     *
     * @param _tokens ERC1155 token addresses to be sent
     * @param _recipient recipient address
     * @param _tokenIds tokenIds to be sent
     * @param _amounts amounts to be sent
     */
    function batchTransferERC1155(
        address[] calldata _tokens,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external {
        _batchTransferERC1155(_tokens, _recipient, _tokenIds, _amounts);
    }

    /**
     * @notice
     *  Send multiple ERC1155 to multiple recipients
     *
     * @param _tokens ERC1155 token addresses to be sent
     * @param _recipients recipients addresses
     * @param _tokenIds tokenIds to be sent
     * @param _amounts amounts to be sent
     */
    function multiBatchTransferERC1155(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external {
        _multiBatchTransferERC1155(_tokens, _recipients, _tokenIds, _amounts);
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Send multiple ERC20 to one recipient
     *
     * @param _tokens ERC20 token addresses to be sent
     * @param _recipient recipient address
     * @param _amounts amounts to be sent
     */
    function _batchTransferERC20(
        address[] calldata _tokens,
        address _recipient,
        uint256[] calldata _amounts
    ) internal {
        if (msg.sender != tx.origin) revert FORBIDDEN();
        // Check parameters correctness
        if (_tokens.length != _amounts.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC20(_tokens[i]).transferFrom(
                msg.sender,
                _recipient,
                _amounts[i]
            );
        }
    }

    /**
     * @notice
     *  Send multiple ERC20 to multiple recipients
     *
     * @param _tokens ERC20 token addresses to be sent
     * @param _recipients recipients addresses
     * @param _amounts amounts to be sent
     */
    function _multiBatchTransferERC20(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) internal {
        if (msg.sender != tx.origin) revert FORBIDDEN();

        // Check parameters correctness
        if (_tokens.length != _recipients.length) revert INVALID_PARAM();
        if (_tokens.length != _amounts.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC20(_tokens[i]).transferFrom(
                msg.sender,
                _recipients[i],
                _amounts[i]
            );
        }
    }

    /**
     * @notice
     *  Send multiple ERC721 to one recipient
     *
     * @param _tokens ERC721 token addresses to be sent
     * @param _recipient recipient address
     * @param _tokenIds tokenIds to be sent
     */
    function _batchTransferERC721(
        address[] calldata _tokens,
        address _recipient,
        uint256[] calldata _tokenIds
    ) internal {
        if (msg.sender != tx.origin) revert FORBIDDEN();

        // Check parameters correctness
        if (_tokens.length != _tokenIds.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC721(_tokens[i]).transferFrom(
                msg.sender,
                _recipient,
                _tokenIds[i]
            );
        }
    }

    /**
     * @notice
     *  Send multiple ERC721 to multiple recipients
     *
     * @param _tokens ERC721 token addresses to be sent
     * @param _recipients recipients addresses
     * @param _tokenIds tokenIds to be sent
     */
    function _multiBatchTransferERC721(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds
    ) internal {
        if (msg.sender != tx.origin) revert FORBIDDEN();

        // Check parameters correctness
        if (_tokens.length != _tokenIds.length) revert INVALID_PARAM();
        if (_tokens.length != _recipients.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC721(_tokens[i]).transferFrom(
                msg.sender,
                _recipients[i],
                _tokenIds[i]
            );
        }
    }

    /**
     * @notice
     *  Send multiple ERC1155 to one recipient
     *
     * @param _tokens ERC1155 token addresses to be sent
     * @param _recipient recipient address
     * @param _tokenIds tokenIds to be sent
     * @param _amounts amounts to be sent
     */
    function _batchTransferERC1155(
        address[] calldata _tokens,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) internal {
        if (msg.sender != tx.origin) revert FORBIDDEN();

        // Check parameters correctness
        if (_tokens.length != _tokenIds.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC1155(_tokens[i]).safeTransferFrom(
                msg.sender,
                _recipient,
                _tokenIds[i],
                _amounts[i],
                ''
            );
        }
    }

    /**
     * @notice
     *  Send multiple ERC1155 to multiple recipients
     *
     * @param _tokens ERC1155 token addresses to be sent
     * @param _recipients recipients addresses
     * @param _tokenIds tokenIds to be sent
     * @param _amounts amounts to be sent
     */
    function _multiBatchTransferERC1155(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) internal {
        if (msg.sender != tx.origin) revert FORBIDDEN();

        // Check parameters correctness
        if (_tokens.length != _tokenIds.length) revert INVALID_PARAM();
        if (_tokens.length != _recipients.length) revert INVALID_PARAM();

        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC1155(_tokens[i]).safeTransferFrom(
                msg.sender,
                _recipients[i],
                _tokenIds[i],
                _amounts[i],
                ''
            );
        }
    }
}