// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....
//                'dXMMWNO;                .......
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

contract CloneforceStakingManager is Ownable, IERC721Receiver, IERC1155Receiver {
    address private _admin;
    bool public contractPaused;

    // Struct for staked tokens
    struct StakedToken {
        address token; // address of token contract
        uint8 tokenType; // 1 = ERC-721, 2 = ERC-1155
        uint32 id; // token id
        uint8 amount; // amount of tokens staked
        uint256 timestamp; // timestamp of staking
    }

    // Holds all staked tokens by users
    mapping(address => StakedToken[]) public stakedTokensByUser;

    // Emitted when a user stakes a token
    event TokenStaked(
        address indexed user,
        address indexed token,
        uint32 indexed id,
        uint8 tokenType,
        uint8 amount,
        uint256 timestamp
    );

    // Emitted when a user unstakes a token
    event TokenUnstaked(
        address indexed user,
        address indexed token,
        uint32 indexed id,
        uint8 tokenType,
        uint8 amount,
        uint256 timestamp
    );

    // Holds whether a user can stake a specific token type
    mapping(address => bool) public isAllowedForStaking;
    mapping(address => bool) private _signatureRequiredToUnstake;
    address private _signatureKey;
    mapping(string => bool) private _usedNonces;

    constructor(address admin, address signatureKey) {
        _admin = admin;
        _signatureKey = signatureKey;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function setAllowedForStaking(
        address token,
        bool allowed,
        bool requireSigToUnstake
    ) external onlyOwnerOrAdmin {
        isAllowedForStaking[token] = allowed;
        _signatureRequiredToUnstake[token] = requireSigToUnstake;
    }

    function depositERC721Token(address token, uint32 id) private {
        // check if token is owned by user
        require(IERC721(token).ownerOf(id) == msg.sender, "Token not owned by user");

        // transfer token to contract
        IERC721(token).safeTransferFrom(msg.sender, address(this), id);
    }

    function depositERC1155Token(address token, uint32 id, uint8 amount) private {
        // check if token is owned by user
        require(
            IERC1155(token).balanceOf(msg.sender, id) >= amount,
            "Not enough tokens owned by user"
        );

        // transfer token to contract
        IERC1155(token).safeTransferFrom(msg.sender, address(this), id, amount, "");
    }

    function stakeToken(
        address token,
        uint8 tokenType,
        uint32 id,
        uint8 amount
    ) public callerIsUser {
        require(!contractPaused, "Contract paused");
        require(isAllowedForStaking[token], "Token not allowed for staking");
        require(tokenType == 1 || tokenType == 2, "Invalid token type");
        require(amount > 0, "Amount must be greater than 0");

        if (tokenType == 1) {
            require(amount == 1, "Amount must be 1 for ERC-721");
            depositERC721Token(token, id);
        } else {
            depositERC1155Token(token, id, amount);
        }

        // add token to user's staked tokens
        stakedTokensByUser[msg.sender].push(
            StakedToken(token, tokenType, id, amount, block.timestamp)
        );

        emit TokenStaked(msg.sender, token, id, tokenType, amount, block.timestamp);
    }

    function withdrawERC721Token(address token, uint32 id) private {
        // transfer token to user
        IERC721(token).safeTransferFrom(address(this), msg.sender, id);
    }

    function withdrawERC1155Token(address token, uint32 id, uint8 amount) private {
        // transfer token to user
        IERC1155(token).safeTransferFrom(address(this), msg.sender, id, amount, "");
    }

    function unstakeToken(
        address token,
        uint8 tokenType,
        uint32 id,
        uint8 amount,
        string calldata nonce,
        bytes memory signature
    ) public callerIsUser {
        require(!contractPaused, "Contract paused");
        require(tokenType == 1 || tokenType == 2, "Invalid token type");
        require(amount > 0, "Amount must be greater than 0");

        // if signature required, check signature
        if (_signatureRequiredToUnstake[token]) {
            require(!_usedNonces[nonce], "Nonce already used");

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }
            bytes32 _hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(token, tokenType, id, amount, nonce))
                )
            );
            require(ecrecover(_hash, v, r, s) == _signatureKey, "Invalid signature");

            _usedNonces[nonce] = true;
        }

        // get user's staked tokens
        StakedToken[] storage stakedTokens = stakedTokensByUser[msg.sender];

        // find token in user's staked tokens
        uint256 index = stakedTokens.length;
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (
                stakedTokens[i].token == token &&
                stakedTokens[i].tokenType == tokenType &&
                stakedTokens[i].id == id
            ) {
                index = i;
                break;
            }
        }

        // check if token was found
        require(index < stakedTokens.length, "Token not found");

        uint stakedAmount = stakedTokens[index].amount;
        require(stakedAmount >= amount, "Not enough tokens staked");

        if (tokenType == 1) {
            require(amount == 1, "Amount must be 1 for ERC-721");
            withdrawERC721Token(token, id);
        } else {
            withdrawERC1155Token(token, id, amount);
        }

        // remove `amount` of tokens from user's staked tokens
        if (stakedAmount > amount) {
            stakedTokens[index].amount -= amount;
        } else {
            stakedTokens[index] = stakedTokens[stakedTokens.length - 1];
            stakedTokens.pop();
        }

        emit TokenUnstaked(msg.sender, token, id, tokenType, amount, block.timestamp);
    }

    struct StakeUnstakeTokenParams {
        address token;
        uint8 tokenType;
        uint32 id;
        uint8 amount;
        string nonce;
        bytes signature;
    }

    struct BatchOperationParam {
        StakeUnstakeTokenParams params;
        bool stake;
    }

    function batchStakeUnstakeTokens(BatchOperationParam[] calldata params) external callerIsUser {
        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].stake) {
                stakeToken(
                    params[i].params.token,
                    params[i].params.tokenType,
                    params[i].params.id,
                    params[i].params.amount
                );
            } else {
                unstakeToken(
                    params[i].params.token,
                    params[i].params.tokenType,
                    params[i].params.id,
                    params[i].params.amount,
                    params[i].params.nonce,
                    params[i].params.signature
                );
            }
        }
    }

    function getStakedTokens(address user) external view returns (StakedToken[] memory) {
        return stakedTokensByUser[user];
    }

    function areNoncesUsed(string[] calldata nonces) external view returns (bool[] memory) {
        bool[] memory isUsed = new bool[](nonces.length);
        for (uint256 i = 0; i < nonces.length; i++) {
            isUsed[i] = _usedNonces[nonces[i]];
        }
        return isUsed;
    }

    function setSignatureKey(address signatureKey) external onlyOwner {
        _signatureKey = signatureKey;
    }

    // Emergency withdraw token from contract. Only owner or admin can call this function.
    // Will be used in case someone sends tokens to contract by mistake.
    function emergencyWithdrawToken(
        uint8 tokenType,
        address token,
        uint32 id,
        uint8 amount,
        address receiver
    ) external onlyOwnerOrAdmin {
        require(tokenType == 1 || tokenType == 2, "Invalid token type");

        // if token is staked, find it and unstake it
        bool staked = false;
        for (uint256 idx = 0; idx < stakedTokensByUser[receiver].length; idx++) {
            if (
                stakedTokensByUser[receiver][idx].token == token &&
                stakedTokensByUser[receiver][idx].tokenType == tokenType &&
                stakedTokensByUser[receiver][idx].id == id
            ) {
                uint stakedAmount = stakedTokensByUser[receiver][idx].amount;
                require(stakedAmount >= amount, "Not enough tokens staked");

                if (stakedAmount > amount) {
                    stakedTokensByUser[receiver][idx].amount -= amount;
                } else {
                    stakedTokensByUser[receiver][idx] = stakedTokensByUser[receiver][
                        stakedTokensByUser[receiver].length - 1
                    ];
                    stakedTokensByUser[receiver].pop();
                }
                staked = true;
                break;
            }
        }

        if (tokenType == 1) {
            require(amount == 1, "Amount must be 1 for ERC-721");
            IERC721(token).safeTransferFrom(address(this), receiver, id);
        } else {
            IERC1155(token).safeTransferFrom(address(this), receiver, id, amount, "");
        }

        if (staked) {
            emit TokenUnstaked(receiver, token, id, tokenType, amount, block.timestamp);
        }
    }

    // IERC721Receiver and IERC1155Receiver functions

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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