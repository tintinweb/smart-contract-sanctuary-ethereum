// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/// @author Misterjuiice https://instagram.com/misterjuiice
/// @title Big Cat & Little Cat Stacking

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BigLittleCatStaking is IERC721Receiver {
    // boolean to prevent reentrancy
    bool internal locked;

    // Library usage
    using SafeMath for uint256;

    // Contract owner
    address public owner;

    // ERC20 contract address
    IERC721 public bigCatContract;
    IERC721 public littleCatContract;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
       return this.onERC721Received.selector;
    }

     /**
    @dev tokenId to staking start time (0 = not staking).
     */
    mapping(uint256 => uint256) private stakingStarted;

    mapping(uint256 => uint256) public stakingUsedPoints;

    /**
    @dev BigCat owner address.
     */
    mapping(uint256 => address) public stakedUserBigCat;

    /**
    @dev Little owner address.
     */
    mapping(uint256 => address) public stakedUserLittleCat;

    /**
    @dev associate LittleCat to BigCat.
     */
    mapping(uint256 => uint256) public littleCatLinkToBigCat;

    /**
    @dev Cumulative per-token staking, excluding the current period.
     */
    mapping(uint256 => uint256) private stakingTotal;

    // Events

    /**
    @dev Emitted when a NFT begins staking.
     */
    event Stacked(uint256 indexed tokenId);

    /**
    @dev Emitted when a NFT stops staking; either through standard means or
    by expulsion.
     */
    event Unstacked(uint256 indexed tokenId);

    /**
    @dev Emitted when a NFT is expelled from the stack.
     */
    event Expelled(uint256 indexed tokenId);

    /// @dev Deploys contract and links the ERC20 token which we are staking, also sets owner as msg.sender and sets timestampSet bool to false.
    /// @param bigCatAddress.
    /// @param littleCatAddress.
    constructor(IERC721 bigCatAddress, IERC721 littleCatAddress) {
        // Set contract owner
        owner = msg.sender;
        // Set the erc20 contract address which this timelock is deliberately paired to
        require(address(bigCatAddress) != address(0), "bigCatAddress address can not be zero");
        require(address(littleCatAddress) != address(0), "littleCatAddress address can not be zero");
        bigCatContract = bigCatAddress;
        littleCatContract = littleCatAddress;

        // Initialize the reentrancy variable to not locked
        locked = false;
    }

    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Message sender must be the contract's owner.");
        _;
    }

    /// @dev Stake NFT 
    /// @param bigCatTokenId, BigCat token
    /// @param littleCatTokenId, LittleCat token
    function stakeTokens(uint256 bigCatTokenId, uint256 littleCatTokenId) external noReentrant {
        uint256 start = stakingStarted[bigCatTokenId];
        if (start == 0) {
            require(msg.sender == bigCatContract.ownerOf(bigCatTokenId), "Message sender must be the BigCat owner.");
            require(msg.sender == littleCatContract.ownerOf(littleCatTokenId), "Message sender must be the LittleCat owner.");

            bigCatContract.safeTransferFrom(msg.sender, address(this), bigCatTokenId);
            littleCatContract.safeTransferFrom(msg.sender, address(this), littleCatTokenId);

            stakingStarted[bigCatTokenId] = block.timestamp;
            stakedUserBigCat[bigCatTokenId] = msg.sender;
            littleCatLinkToBigCat[bigCatTokenId] = littleCatTokenId;
            stakedUserLittleCat[littleCatTokenId] = msg.sender;

            emit Stacked(bigCatTokenId);
        } else {
            require(msg.sender == stakedUserBigCat[bigCatTokenId], "Message sender must be the BigCat owner.");
            require(msg.sender == stakedUserLittleCat[littleCatTokenId], "Message sender must be the LittleCat owner.");

            stakingTotal[bigCatTokenId] += block.timestamp - start;
            stakingStarted[bigCatTokenId] = 0;
            bigCatContract.safeTransferFrom(address(this), msg.sender, bigCatTokenId);
            littleCatContract.safeTransferFrom(address(this), msg.sender, littleCatTokenId);

            delete stakedUserBigCat[bigCatTokenId];
            delete stakedUserLittleCat[littleCatTokenId];
            delete littleCatLinkToBigCat[bigCatTokenId];

            emit Unstacked(bigCatTokenId);
        }
    }

    function expelFromStack(uint256 bigCatTokenId, uint256 littleCatTokenId) external onlyOwner {
        require(stakingStarted[bigCatTokenId] != 0, "Stacking: not stacked");
        stakingTotal[bigCatTokenId] += block.timestamp - stakingStarted[bigCatTokenId];
        stakingStarted[bigCatTokenId] = 0;

        bigCatContract.safeTransferFrom(address(this), stakedUserBigCat[bigCatTokenId], bigCatTokenId);
        littleCatContract.safeTransferFrom(address(this), stakedUserLittleCat[littleCatTokenId], littleCatTokenId);

        delete stakedUserBigCat[bigCatTokenId];
        delete stakedUserLittleCat[littleCatTokenId];
        delete littleCatLinkToBigCat[bigCatTokenId];

        emit Unstacked(bigCatTokenId);
        emit Expelled(bigCatTokenId);
    }

     /**
    @notice Returns the length of time, in seconds, that the NFT has
    nested.
    @dev Staking is tied to a specific Big Cat & Little Cat, not to the owner, so it doesn't
    reset upon sale.
    @return staking Whether the NFT is currently staking. MAY be true with
    zero current staking if in the same block as nesting began.
    @return current Zero if not currently staking, otherwise the length of time
    since the most recent staking began.
    @return total Total period of time for which the NFT has staked across
    its life, including the current period.
     */
    function stakingPeriod(uint256 bigCatTokenId)
        external
        view
        returns (
            bool staking,
            uint256 current,
            uint256 total,
            address ownerAddress,
            uint256 littleCatTokenId
        )
    {
        uint256 start = stakingStarted[bigCatTokenId];
        if (start != 0) {
            staking = true;
            current = block.timestamp - start;
            ownerAddress = stakedUserBigCat[bigCatTokenId];
            littleCatTokenId = littleCatLinkToBigCat[bigCatTokenId];
        }
        total = current + stakingTotal[bigCatTokenId] - stakingUsedPoints[bigCatTokenId];
        ownerAddress = stakedUserBigCat[bigCatTokenId];
        littleCatTokenId = littleCatLinkToBigCat[bigCatTokenId];
    }

    function usePoint(uint256 bigCatTokenId, uint256 littleCatTokenId, uint256 points) external noReentrant {
        require(msg.sender == stakedUserBigCat[bigCatTokenId], "Message sender must be the BigCat owner.");
        require(msg.sender == stakedUserLittleCat[littleCatTokenId], "Message sender must be the LittleCat owner.");
        require(stakingStarted[bigCatTokenId] != 0, "Not actually staking");
        uint256 start = stakingStarted[bigCatTokenId];
        uint256 current = block.timestamp - start;
        uint256 total = current + stakingTotal[bigCatTokenId];
        require(total > points, "Not enought points");
        
        stakingUsedPoints[bigCatTokenId] += points;
        stakingTotal[bigCatTokenId] += block.timestamp - stakingStarted[bigCatTokenId];
        stakingStarted[bigCatTokenId] = block.timestamp;
    }

    function changeOwner(address newAddress) external onlyOwner {
        owner = newAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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