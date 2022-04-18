/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: contracts/DeathWish.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;




/*
                __                   __   __                                                                             __            __       ____  
                |  \                 |  \ |  \                                                                           |  \          |  \     /    \ 
    __   __   __ | $$____    ______  _| $$_| $$ _______        __    __   ______   __    __   ______         __   __   __  \$$  _______ | $$____|  $$$$\
    |  \ |  \ |  \| $$    \  |      \|   $$ \\$ /       \      |  \  |  \ /      \ |  \  |  \ /      \       |  \ |  \ |  \|  \ /       \| $$    \\$$| $$
    | $$ | $$ | $$| $$$$$$$\  \$$$$$$\\$$$$$$  |  $$$$$$$      | $$  | $$|  $$$$$$\| $$  | $$|  $$$$$$\      | $$ | $$ | $$| $$|  $$$$$$$| $$$$$$$\ /  $$
    | $$ | $$ | $$| $$  | $$ /      $$ | $$ __  \$$    \       | $$  | $$| $$  | $$| $$  | $$| $$   \$$      | $$ | $$ | $$| $$ \$$    \ | $$  | $$|  $$ 
    | $$_/ $$_/ $$| $$  | $$|  $$$$$$$ | $$|  \ _\$$$$$$\      | $$__/ $$| $$__/ $$| $$__/ $$| $$            | $$_/ $$_/ $$| $$ _\$$$$$$\| $$  | $$ \$$  
    \$$   $$   $$| $$  | $$ \$$    $$  \$$  $$|       $$       \$$    $$ \$$    $$ \$$    $$| $$             \$$   $$   $$| $$|       $$| $$  | $$|  \  
    \$$$$$\$$$$  \$$   \$$  \$$$$$$$   \$$$$  \$$$$$$$        _\$$$$$$$  \$$$$$$   \$$$$$$  \$$              \$$$$$\$$$$  \$$ \$$$$$$$  \$$   \$$ \$$  
                                                            |  \__| $$                                                                                
                                                                \$$    $$                                                                                
                                                                \$$$$$$              
                                                                                                     🐬WhaleGoddess🐬                                                                           
    Note: Interacting with an unaudited protocol is always a risk. 
    Deployer guarantee:
    ✔️ Due diligence was taken by the developer(s) 
    ✔️ Interactable thru trusted dapps or EtherScan at this address
    ✔️ No backdoors or BS
    We do not guarantee:
    ❌ Refunds for *any reason*
    ❌ Legal responsibility for any asset exposed to the protocol

*/
contract DeathWish is ReentrancyGuard {
    
    struct Switch {
        uint8 tokenType; //1 - ERC20 , 2 - ERC721 - 3 - ERC1155
        uint64 unlock;
        address user;
        address tokenAddress;
        uint256 tokenId; //for ERC721/ERC1155
        uint256 amount; //for ERC20/ERC1155
    }

    uint256 counter;
    mapping(uint256 => Switch) switches;
    mapping(uint256 => bool) switchClaimed;
    mapping(address => uint256[]) userSwitches;
    mapping(address => uint256[]) userBenefactor;
    mapping(uint256 => address[]) benefactors;

    uint64 public MAX_TIMESTAMP = type(uint64).max;
    
    function getCounter() external view returns (uint256) {
        return counter;
    }

    function inspectSwitch(uint256 id) external view returns (uint256, address, address, uint8, uint256, uint256) {
        require(id < counter, "Out of range");
        Switch memory _switch = switches[id];
        return (switchClaimableByAt(id, msg.sender), _switch.user, _switch.tokenAddress, _switch.tokenType, _switch.tokenId, _switch.amount);
    }

    function isSwitchClaimed(uint256 id) external view returns (bool) {
        return switchClaimed[id];
    }

    function switchClaimableByAt(uint256 id, address _user) internal view returns (uint64) {
        if (switchClaimed[id]) return MAX_TIMESTAMP;
        Switch memory _switch = switches[id];
        if (_user == _switch.user) return 0;
        uint256 length = benefactors[id].length;
        for(uint256 i = 0; i < length; i++) {
            if (benefactors[id][i] == _user) {
                return (_switch.unlock + uint64((i * 60 days)));
            }
        }
        return MAX_TIMESTAMP;
    }

    function isSwitchClaimableBy(uint256 id, address _user) public view returns (bool) {
        return (block.timestamp > switchClaimableByAt(id, _user));
    }

    function getBenefactorsForSwitch(uint256 id) external view returns (address[] memory) {
        require(id < counter, "Out of range");
        return benefactors[id];
    }

    function getOwnedSwitches(address _user) external view returns (uint256[] memory) {
        return userSwitches[_user];
    }

    function getBenefactorSwitches(address _user) external view returns (uint256[] memory) {
        return userBenefactor[_user];
    }

    function createNewERC20Switch(uint64 unlockTimestamp, address tokenAddress, uint256 amount, address[] memory _benefactors) external {
        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "No allowance set");
        switches[counter] = Switch(
            1,
            unlockTimestamp,
            msg.sender,
            tokenAddress,
            0, //null
            amount
        );
        benefactors[counter] = _benefactors;
        userSwitches[msg.sender].push(counter);
        uint256 length = _benefactors.length;
        for(uint256 i = 0; i < length; i++) {
            userBenefactor[_benefactors[i]].push(counter);
        }
        emit SwitchCreated(counter, switches[counter].tokenType);
        counter++;
    }

    function createNewERC721Switch(uint64 unlockTimestamp, address tokenAddress, uint256 tokenId, address[] memory _benefactors) external {
        require(IERC721(tokenAddress).isApprovedForAll(msg.sender, address(this)), "No allowance set");
        switches[counter] = Switch(
            2,
            unlockTimestamp,
            msg.sender,
            tokenAddress,
            tokenId, 
            0 //null
        );
        benefactors[counter] = _benefactors;
        userSwitches[msg.sender].push(counter);
        uint256 length = _benefactors.length;
        for(uint256 i = 0; i < length; i++) {
            userBenefactor[_benefactors[i]].push(counter);
        }
        emit SwitchCreated(counter, switches[counter].tokenType);
        counter++;
    }

    function createNewERC1155Switch(uint64 unlockTimestamp, address tokenAddress, uint256 tokenId, uint256 amount, address[] memory _benefactors) external {
        require(IERC1155(tokenAddress).isApprovedForAll(msg.sender, address(this)), "No allowance set");
        switches[counter] = Switch(
            3,
            unlockTimestamp,
            msg.sender,
            tokenAddress,
            tokenId,
            amount
        );
        benefactors[counter] = _benefactors;
        userSwitches[msg.sender].push(counter);
        uint256 length = _benefactors.length;
        for(uint256 i = 0; i < length; i++) {
            userBenefactor[_benefactors[i]].push(counter);
        }
        emit SwitchCreated(counter, switches[counter].tokenType);
        counter++;
    }

    event SwitchCreated(uint256 id, uint8 switchType);
    event SwitchClaimed(uint256 id, uint8 switchType);
    event UnlockTimeUpdated(uint256 id, uint64 unlock_time);
    event TokenAmountUpdated(uint256 id, uint256 unlock_time);
    event BenefactorsUpdated(uint256 id);

    function updateUnlockTime(uint256 id, uint64 newUnlock) external {
        require(id < counter, "out of range");
        Switch storage _switch = switches[id];
        require(_switch.user == msg.sender, "You are not the locker");
        _switch.unlock = newUnlock;
        emit UnlockTimeUpdated(id, newUnlock);
    }

    function updateTokenAmount(uint256 id, uint256 newAmount) external {
        require(id < counter, "out of range");
        Switch storage _switch = switches[id];
        require(_switch.user == msg.sender, "You are not the locker");
        require(_switch.tokenType != 2, "Not valid for ERC721");
        _switch.amount = newAmount;
        emit TokenAmountUpdated(id, newAmount);
    }

    function updateBenefactors(uint256 id, address[] memory _benefactors) external {
        require(id < counter, "out of range");
        Switch memory _switch = switches[id];
        require(_switch.user == msg.sender, "You are not the locker");
        benefactors[id] = _benefactors;
        emit BenefactorsUpdated(id);
    }

    function claimSwitch(uint256 id) external nonReentrant {
        Switch memory _switch = switches[id];
        require(isSwitchClaimableBy(id, msg.sender), "sender is not a benefactor or owner");
        if (_switch.tokenType == 1) {
            IERC20(_switch.tokenAddress).transferFrom(_switch.user, msg.sender, 
            // use min here in case someone sold some of their token
            min(IERC20(_switch.tokenAddress).balanceOf(_switch.user), _switch.amount));
        } else if (_switch.tokenType == 2) {
            IERC721(_switch.tokenAddress).safeTransferFrom(_switch.user, msg.sender, _switch.tokenId);
        } else if (_switch.tokenType == 3) {
            IERC1155(_switch.tokenAddress).safeTransferFrom(_switch.user, msg.sender, _switch.tokenId, 
            // use min here in case someone sold 1/2 of their 1155
            min(IERC1155(_switch.tokenAddress).balanceOf(_switch.user, _switch.tokenId), _switch.amount), '');
        } else { revert("FUD"); }
        switchClaimed[id] = true;
        emit SwitchClaimed(id, _switch.tokenType);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > y) {
            return y;
        }
        return x;
    }
}