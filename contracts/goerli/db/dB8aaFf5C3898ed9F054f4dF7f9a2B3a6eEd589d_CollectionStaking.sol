// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne
 * @title CollectionStaking
 */

contract CollectionStaking is Pausable {
    struct Bank { uint256 uid; address erc20address; uint256 reserved; uint256 amount; address erc721address; uint256 min_per_staking; uint256 max_per_staking; address owner_of; }
    struct Period { uint256 uid; uint256 bank_uid; uint256 time; uint256 reward; }
    struct BulkPeriod { uint256 time; uint256 reward; }
    struct Staking { uint256 uid; uint256 period_uid; address owner_of; uint256 start_time; bool closed; }
    struct Metadata { string file_uri; string title; string description; }

    mapping(address => mapping(uint256 => uint256[])) private _staked_tokens;

    Bank[] private _banks;
    Staking[] private _stakings;
    Period[] private _periods;

    constructor(address owner_of_) Pausable(_owner_of) {}
    
    event bankCreated(uint256 uid, string file_url, string title, string description, address erc20address, uint256 amount, address erc721address, uint256 min_per_user, uint256 max_per_user, address owner_of);
    event periodCreated(uint256 uid, uint256 bank_uid, uint256 time, uint256 reward);
    event stakingCreated(uint256 uid, uint256 bank_uid, uint256 period_uid, address erc721address, uint256 start_time, address owner_of, bool closed);
    event tokensAdded(address owner_of, uint256 staking_uid, uint256 bank_uid, uint256[] token_ids, address erc721address);
    event withdrawed(address owner_of, uint256 amount, uint256 bank_uid);

    function createBank(Metadata memory metadata, address erc20address, uint256 amount, address erc721address, uint256 min_per_user, uint256 max_per_user, BulkPeriod[] memory periods) public {
        uint256 newBankId = _banks.length;
        _banks.push(Bank(newBankId, erc20address, 0, amount, erc721address, min_per_user, max_per_user, msg.sender));
        emit bankCreated(newBankId, metadata.file_uri, metadata.title, metadata.description, erc20address, amount, erc721address, min_per_user, max_per_user, msg.sender);
        IERC20(erc20address).transferFrom(msg.sender, address(this), amount);
        for (uint256 i = 0; i < periods.length; i++) {
            uint256 newPeriodId = _periods.length;
            _periods.push(Period(newPeriodId, newBankId, periods[i].time, periods[i].reward));
            emit periodCreated(newPeriodId, newBankId, periods[i].time, periods[i].reward);
        }
    }

    function stake(address erc721address, uint256[] memory token_ids, uint256 period_checked_uid) public {
        IERC721 token = IERC721(erc721address);
        for (uint256 i = 0; i < token_ids.length; i++) {
            require(token.ownerOf(token_ids[i]) == msg.sender, "You are not an owner of token");
        }
        Period memory period = _periods[period_checked_uid];
        Bank memory bank = _banks[period.bank_uid];
        require(token_ids.length >= bank.min_per_staking, "No such tokens for staking");
        require(token_ids.length <= bank.max_per_staking, "Too much tokens for staking");
        require((token_ids.length * period.reward) + bank.reserved <= bank.amount, "Not enough tokens in bank for staking");
        require(bank.erc721address == erc721address, "Period is not available");
        for (uint256 i = 0; i < token_ids.length; i++) {
            token.safeTransferFrom(msg.sender, address(this), token_ids[i], "");
        }
        uint256 newStakingId = _stakings.length;
        _stakings.push(Staking(newStakingId, period_checked_uid, msg.sender, block.timestamp, false));
        emit stakingCreated(newStakingId, period.bank_uid, period_checked_uid, erc721address, block.timestamp, msg.sender, false);
        _staked_tokens[msg.sender][newStakingId] = token_ids;
        emit tokensAdded(msg.sender, newStakingId, period.bank_uid, token_ids, erc721address);
        _banks[period.bank_uid].reserved += token_ids.length * period.reward;
    }

    function claim(uint256 staking_uid) public {
        Staking memory staking = _stakings[staking_uid];
        require(staking.owner_of == msg.sender, "Permission denied! Not your staking");
        Period memory period = _periods[staking.period_uid];
        require(staking.start_time + period.time >= block.timestamp, "Staking does not finished");
        require(!staking.closed, "Staking has been resolved");
        Bank memory bank = _banks[period.bank_uid];
        for (uint256 i = 0; i < _staked_tokens[msg.sender][staking_uid].length; i++) {
            IERC721(bank.erc721address).transferFrom(address(this), staking.owner_of, _staked_tokens[staking.owner_of][staking_uid][i]);
        }
        IERC20(bank.erc20address).transfer(staking.owner_of, period.reward * _staked_tokens[msg.sender][staking_uid].length);
        _stakings[staking_uid].closed = true;
    }

    function withdraw(uint256 bank_uid) public {
        Bank memory bank = _banks[bank_uid];
        require(msg.sender == bank.owner_of, "You are not an owner");
        require(bank.amount - bank.reserved > 0, "Nothing to withdraw");
        IERC20(bank.erc20address).transfer(msg.sender, bank.amount - bank.reserved);
        emit withdrawed(msg.sender, bank.amount - bank.reserved, bank_uid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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