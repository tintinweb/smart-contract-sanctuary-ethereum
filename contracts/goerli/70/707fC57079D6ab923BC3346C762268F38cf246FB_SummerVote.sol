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

import "./ISummerVote.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public constant VOTE_TYPEHASH =
        keccak256(
            "Vote(address voter,uint256 taskId,uint256 ticket, uint8 side, uint256 salt)"
        );

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 DOMAIN_SEPARATOR;

    function _hashDomain(
        EIP712Domain memory eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function _hashVote(
        OneVote memory oneVote
    ) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(VOTE_TYPEHASH, oneVote.voter, oneVote.taskId, oneVote.ticket, uint8(oneVote.side), oneVote.salt)
                )
            );
    }

    function _hashToSign(
        bytes32 voteHash
    ) internal view returns (bytes32 hash) {
        return
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, voteHash));
    }

    function _verifyOracle(
        OneVote calldata oneVote, address oracle
    ) internal view returns (bool) {
        bytes calldata extraSignature = oneVote.extraSignature;
        bytes32 voteHash = _hashVote(oneVote);
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            v := calldataload(extraSignature.offset)
            r := calldataload(add(extraSignature.offset, 0x20))
            s := calldataload(add(extraSignature.offset, 0x40))
        }

        return _verify(oracle, _hashToSign(voteHash), v, r, s);
    }

    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        require(v == 27 || v == 28, "Invalid v parameter");
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0)) {
            return false;
        } else {
            return signer == recoveredSigner;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IExtendERC721 is IERC721 {
    function exists(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum VoteSide {
    Creator,
    Worker,
    None
}
enum VoteStatus {
    Pending,
    Open,
    Closed
}

struct VoteMeta {
    uint256 voteId;
    uint256 taskId;
    uint256 expiredAt;
    uint256 tkWorker;
    uint256 tkCreator;
    uint256 tkLimit;
    VoteStatus status;
    VoteSide winner;
}

struct OneVote {
    address voter;
    uint256 taskId;
    VoteSide side;
    uint256 ticket;
    uint256 salt;
    bytes extraSignature;
}

interface ISummerVote {
    function vote(OneVote calldata oneVote) external returns (VoteMeta memory);

    function changeVoteTokenLimit(uint256) external;

    function voteSetURI(string calldata) external;

    function voteTokenURI(uint256) external returns (string memory);

    function startVote(uint256 taskId, uint256 tkLimit) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./IExtendERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISummerVote.sol";
import "./EIP712.sol";

contract SummerVote is Ownable, ISummerVote, EIP712 {
    IERC20 voteToken;
    string tokenURI;
    

    uint256 VOTE_TIME_LIMIT = 604800; // 1 week
    string baseURI;

    mapping(uint256 => VoteMeta) voteMapping;
    uint256 voteBalanceLimit = 10000000000000000000; // 10 SUMMER

    event VoteFinish(uint256 indexed voteId, VoteSide indexed winner);
    event VoteStart(uint256 indexed voteId, uint256 indexed taskId, address indexed creator); // 0: creator, 1: worker;

    address ORACLE;

    constructor(address aVoteToken, address oracle) {
        voteToken = IERC20(aVoteToken);
        ORACLE = oracle;

        DOMAIN_SEPARATOR = _hashDomain(EIP712Domain({
            name              : "SummerVote",
            version           : "1.0",
            // chainId           : block.chainid,
            chainId           : 1,
            verifyingContract : address(this)
        }));
    }

    function startVote(uint256 taskId, uint256 tkLimit) external {
        require(voteMapping[taskId].voteId == 0, 'vote exists can not restart a vote!');

        voteMapping[taskId] = VoteMeta(taskId, taskId, block.timestamp + VOTE_TIME_LIMIT, 0, 0, tkLimit, VoteStatus.Open, VoteSide.None);
        emit VoteStart(taskId, taskId, msg.sender);
    }

    function vote(OneVote calldata oneVote) external returns (VoteMeta memory) {
        require(voteToken.balanceOf(msg.sender) > voteBalanceLimit, 'You not have enough SUMMER to vote!');
        require(voteMapping[oneVote.taskId].voteId > 0, 'Task not in vote!');
        require(voteMapping[oneVote.taskId].status == VoteStatus.Open, 'Vote closed!');
        require(_verifyOracle(oneVote, ORACLE), 'Signature not match!');
        uint taskId = oneVote.taskId;

        if (oneVote.side == VoteSide.Worker) {
            voteMapping[taskId].tkWorker += oneVote.ticket;
        } else {
            voteMapping[taskId].tkCreator += oneVote.ticket;
        }

        // if (
        //     voteMapping[taskId].expiredAt > block.timestamp ||
        //     voteMapping[taskId].tkWorker + voteMapping[taskId].tkCreator >= voteMapping[taskId].tkLimit
        // ) {
        //     voteMapping[taskId].status = VoteStatus.Closed;

        //     if (voteMapping[taskId].tkWorker > voteMapping[taskId].tkCreator) {
        //         voteMapping[taskId].winner = VoteSide.Worker;
        //         emit VoteFinish(taskId, VoteSide.Worker);
        //     } else {
        //         voteMapping[taskId].winner = VoteSide.Creator;
        //         emit VoteFinish(taskId, VoteSide.Creator);
        //     }
        // }

        return voteMapping[taskId];
    }

    function changeVoteStatus(uint256 taskId, VoteStatus status, VoteSide winner) external onlyOwner {
        voteMapping[taskId].status = status;
        voteMapping[taskId].winner = winner;

        emit VoteFinish(taskId, VoteSide.Worker);
    }

    function changeVoteTokenLimit(uint256 limit) external onlyOwner {
        voteBalanceLimit = limit;
    }

    function voteSetURI(string memory uri) external onlyOwner {
        tokenURI = uri;
    }

    function voteTokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit),
        // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
        // We will need 1 32-byte word to store the length,
        // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
        // Update the free memory pointer to allocate.
            mstore(0x40, str)

        // Cache the end of the memory to calculate the length later.
            let end := str

        // We write the string from rightmost digit to leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
            // Write the character to the pointer.
            // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
            // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
        // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
        // Store the length.
            mstore(str, length)
        }
    }
}