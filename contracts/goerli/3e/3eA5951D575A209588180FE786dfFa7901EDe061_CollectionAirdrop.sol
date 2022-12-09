// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title CollectionAirdrop
 */
contract CollectionAirdrop is Pausable {
    struct Metadata { string title; string description; string file_uri; }
    struct Airdrop { uint256 uid; address owner_of; uint256 claimed; uint256 amount; address token_address; uint256 start_time; uint256 limit_per_wallet; address access_token_address; uint256 access_fee; }
    struct Token { uint256 uid; uint256 airdrop_id; uint256 token_id; address token_address; bool claimed; }

    mapping(address => mapping(uint256 => uint256)) private _drop_received;

    Airdrop[] private _airdrops;
    Token[] private _tokens;

    constructor(address owner_of_) Pausable(_owner_of) {}

    event airdropCreated(uint256 uid, address owner_of, uint256 amount, address token_address, uint256 limit, Metadata metadata, uint256 start_time, address access_token_address, uint256 access_fee);
    event tokenSubmited(uint256 uid, uint256 token_id, address token_address);
    event tokenClaimed(uint256 uid, uint256 airdrop_uid, address claimer);
    event withdrawed(address owner_of, uint256 amount, uint256 airdrop_uid);

    function createDrop(Metadata memory metadata, address token_address, uint256 limit_per_wallet, uint256 start_time, uint256[] memory token_ids, address access_token_address, uint256 access_fee) public notPaused {
        IERC721 token = IERC721(token_address);
        uint256 newIdAirdrop = _airdrops.length;
        uint256 token_len = token_ids.length;
        _airdrops.push(Airdrop(newIdAirdrop, msg.sender, 0, token_len, token_address, start_time, limit_per_wallet, access_token_address, access_fee));
        emit airdropCreated(newIdAirdrop, msg.sender, token_len, token_address, limit_per_wallet, metadata, start_time, access_token_address, access_fee);
        for (uint256 i = 0; i < token_len; i++) {
            token.transferFrom(msg.sender, address(this), token_ids[i]);
            _tokens.push(Token(newIdAirdrop, newIdAirdrop, token_ids[i], token_address, false));
            emit tokenSubmited(newIdAirdrop, token_ids[i], token_address);
        }
    }

    function claim(uint256 uid, uint256 amount) public {
        Airdrop memory airdrop = _airdrops[uid];
        if (airdrop.access_token_address != address (0) && airdrop.access_fee != 0){
            require(IERC20(airdrop.access_token_address).balanceOf(msg.sender) >= airdrop.access_fee, "Balance of access token should be greater then access fee");
        }
        require(_drop_received[msg.sender][uid] + amount <= airdrop.limit_per_wallet, "Denied! Limit per wallet");
        require(airdrop.claimed + amount <= airdrop.amount, "Denied! Airdrop limit");
        require(_airdrops[uid].start_time < block.timestamp, "Denied! Airdrop hasn't start");
        uint256 matches = 0;
        _drop_received[msg.sender][uid] += amount;
        IERC721 erc721 = IERC721(airdrop.token_address);
        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory token = _tokens[i];
            if (token.airdrop_id == uid && !token.claimed) {
                if (matches >= amount) {
                    break;
                }
                erc721.transferFrom(address(this), msg.sender, token.token_id);
                _tokens[i].claimed = true;
                matches += 1;
                
            }
        }
    }

    function withdraw(uint256 uid) public {
        Airdrop memory airdrop = _airdrops[uid];
        require(msg.sender == airdrop.owner_of, "You are not an owner");
        require(airdrop.amount - airdrop.claimed > 0, "Nothing to withdraw");
        IERC721 erc721 = IERC721(airdrop.token_address);
        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory token = _tokens[i];
            if (token.airdrop_id == uid && !token.claimed) {
                erc721.transferFrom(address(this), msg.sender, token.token_id);
                emit tokenClaimed(uid, token.airdrop_id, msg.sender);
                _tokens[i].claimed = true;
            }
        }
        emit withdrawed(msg.sender, airdrop.amount - airdrop.claimed, uid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne DAO
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
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