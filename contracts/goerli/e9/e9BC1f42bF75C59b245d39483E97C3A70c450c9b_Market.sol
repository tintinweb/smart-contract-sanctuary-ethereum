// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IBet } from "./IBet.sol";
import "./IVault.sol";
import "./IMarket.sol";

// Put these in the ERC721 contract
struct Bet {
    bytes32 propositionId;
    uint256 amount;
    uint256 payout;
    uint256 payoutDate;
    bool settled;
    address owner;
}

contract Market is Ownable, IMarket {

    uint256 private constant MAX = 32;
    uint256 private constant PRECESSION = 1_000;

    IERC721 private _bet;
    uint8 private immutable _fee;
    address private immutable _vault;
    address private immutable _self;

    uint256 private _count; // running count of bets

    Bet[] private _bets;

    // MarketID => amount bet
    mapping(bytes32 => uint256) private _marketTotal;

    // MarketID => Bets Indexes
    mapping(bytes32 => uint256[]) private _marketBets;

    // MarketID => PropositionID => amount bet
    mapping(bytes32 => mapping(uint16 => uint256)) private _marketBetAmount;

    // PropositionID => amount bet
    mapping(bytes32 => uint256) private _potentialPayout;

    uint256 private _totalInPlay;
    uint256 private _totalLiability;

    // Can claim after this period regardless
    uint256 public immutable timeout;
    uint256 public immutable min;

    function getTarget() external view returns (uint8) {
        return _fee;
    }

    function getTotalInplay() external view returns (uint256) {
        return _totalInPlay;
    }

    function getTotalLiablity() external view returns (uint256) {
        return _totalLiability;
    }

    function getVaultAddress() external view returns (address) {
        return _vault;
    }

    function getExpiry(uint64 id) external view returns (uint256) {
        return _getExpiry(id);
    }

    function getMarketTotal(bytes32 marketId) external view returns (uint256) {
        return _marketTotal[marketId];
    }

    function _getExpiry(uint64 id) private view returns (uint256) {
        return _bets[id].payoutDate + timeout;
    }

    constructor(address vault, uint8 fee) {
        require(vault != address(0), "Invalid address");
        _self = address(this);
        _vault = vault;
        // _bet = IERC721(erc721);
        _fee = fee;
        
        timeout = 30 days;
        min = 1 hours;
    }

    // function getBetById(bytes32 id) external view returns (uint256, uint256, uint256, bool, address) {
    //     uint64 index = _betsIndexes[id];
    //     return _getBet(index);
    // }

    function getBetByIndex(uint256 index) external view returns (uint256, uint256, uint256, bool, address) {
        return _getBet(index);
    }

    function _getBet(uint256 index) private view returns (uint256, uint256, uint256, bool, address) {
        // bytes32 index = _betsIndexes[id];
        Bet memory bet = _bets[index];
        return (bet.amount, bet.payout, bet.payoutDate, bet.settled, bet.owner);
    }

    // function getBetById(bytes32 id) external view returns (uint256, uint256, uint256, bool, address) {
    //     // bytes32 index = _betsIndexes[id];
    //     // Bet memory bet = _bets[id];
    //     // return (bet.amount, bet.payout, bet.payoutDate, bet.claimed, bet.owner);
    //     return 0;
    // }

    function getOdds(int wager, int256 odds, bytes32 propositionId) external view returns (int256) {
        return _getOdds(wager, odds, propositionId);
    }
    
    function _getOdds(int wager, int256 odds, bytes32 propositionId) private view returns (int256) {
        require(odds > 0, "Cannot have negative odds");
        int256 p = int256(IVault(_vault).totalAssets());

        if (p == 0) {
            return 0;
        }

        // f(wager) = odds - odds*(wager/pool) 

        if (_potentialPayout[propositionId] > uint256(p)) {
            return 0;
        }

        // do not include this guy in the return
        p -= int256(_potentialPayout[propositionId]);

        return odds - (odds * (wager * 1_000 / p) / 1_000);
    }

    function getPotentialPayout(bytes32 propositionId, uint256 wager, uint256 odds) external view returns (uint256) {
        return _getPayout(propositionId, wager, odds);
    }

    function _getPayout(bytes32 propositionId, uint256 wager, uint256 odds) private view returns (uint256) {
        // add underlying to the market
        int256 trueOdds = _getOdds(int256(wager), int256(odds), propositionId);
        // assert(trueOdds > 0);

        return uint256(trueOdds) * wager / 1_000_000;
    }

    function back(bytes32 nonce, bytes32 propositionId, bytes32 marketId, uint256 wager, uint256 odds, uint256 close, uint256 end, bytes calldata signature) external returns (uint256) {
        require(_vault != address(0), "Vault address not set");
        require(end > block.timestamp && block.timestamp > close, "Invalid date");
        
        bytes32 messageHash = keccak256(abi.encodePacked(nonce, propositionId, marketId, wager, odds, close, end));
        // bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // require(recoverSigner(ethSignedMessageHash, signature) == owner(), "Invalid signature");
        address underlying = IVault(_vault).asset();

        // add underlying to the market
        int256 trueOdds = _getOdds(int256(wager), int256(odds), propositionId);
        assert(trueOdds > 0);

        uint256 payout = _getPayout(propositionId, wager, odds);

        // escrow
        IERC20(underlying).transferFrom(msg.sender, _self, wager);
        IERC20(underlying).transferFrom(_vault, _self, (payout - wager));

        // assert(IERC20(underlying).balanceOf(_self) >= payout);

        // add to the market
        _marketTotal[marketId] += wager;

        _bets.push(Bet(propositionId, wager, payout, end, false, msg.sender));
        _marketBets[marketId].push(_count);
        _count++;

        // Mint the 721
        // uint256 tokenId = IBet(_bet).mint(msg.sender);

        _totalInPlay += payout;
        _totalLiability += (payout - wager);

        emit Placed(propositionId, wager, payout, msg.sender);

        return _count; // token ID
    }

    function settle(uint256 id, bytes calldata signature) external {
        bytes32 message = keccak256(abi.encodePacked(id));
        address marketOwner = recoverSigner(message, signature);
        require(marketOwner == owner(), "Invalid signature");

        _settle(id);
    }

    function settleMarket(bytes32 nonce, bytes32 marketId, bytes32 propositionId, bytes calldata signature) public {
        require(marketId != 0 && propositionId != 0, "Invalid ID");

        bytes32 message = keccak256(abi.encodePacked(nonce, propositionId, marketId));
        address marketOwner = recoverSigner(message, signature);
        require(marketOwner == owner(), "Invalid signature");
        
        uint256 count = _marketBets[marketId].length;
        assert(count < MAX);
        for (uint256 i = 0; i < count; i++) {
            uint256 index = _marketBets[marketId][i];

            if (!_bets[index].settled && _bets[index].propositionId == propositionId) {
                _settle(i);
            }
        }
    }

    // function claim(bytes32 id, bytes calldata signature) external {
    //     bytes32 message = keccak256(abi.encodePacked(id));
    //     address marketOwner = recoverSigner(message, signature);
    //     require(marketOwner == owner(), "Invalid signature");

    //     require(_bets[id].claimed == false, "Bet has already been claimed");
    //     require(_bets[id].payoutDate < block.timestamp + _bets[id].payoutDate, "Market not closed");

    //     _bets[id].claimed = true;
    //     _totalInPlay -= _bets[id].amount;

    //     IERC20(_vault).transferFrom(_self, _bets[id].owner, _bets[id].payout);

    //     emit Claimed(id, _bets[id].payout, _bets[id].owner);
    // }

    function _settle(uint256 id) private {
        require(_bets[id].settled == false, "Bet has already been settled");
        require(_bets[id].payoutDate < block.timestamp + _bets[id].payoutDate, "Market not closed");

        _bets[id].settled = true;
        _totalInPlay -= _bets[id].payout;

        IERC20(_vault).transferFrom(_self, _bets[id].owner, _bets[id].payout);

        emit Settled(id, _bets[id].payout, _bets[id].owner);
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 message, bytes memory signature)
        private
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(signature);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory signature)
        private
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    event Placed(bytes32 propositionId, uint256 amount, uint256 payout, address indexed owner);
    event Settled(uint256 id, uint256 payout, address indexed owner);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function asset() external view returns (address assetTokenAddress);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function getPerformance() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function withdraw() external;

    event Deposit(address indexed who, uint256 value);
    event Withdraw(address indexed who, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IMarket {
    function getTarget() external view returns (uint8);
    function getTotalInplay() external view returns (uint256);
    //function getInplayCount() external view returns (uint256);
    function getBetByIndex(uint256 index) external view returns (uint256, uint256, uint256, bool, address);
    function getOdds(int wager, int256 odds, bytes32 propositionId) external view returns (int256);
    function getVaultAddress() external view returns (address);
    function back(bytes32 nonce, bytes32 propositionId, bytes32 marketId, uint256 wager, uint256 odds, uint256 close, uint256 end, bytes calldata signature) external returns (uint256);
    function settle(uint256 id, bytes calldata signature) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IBet {
    function mint(address to) external returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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