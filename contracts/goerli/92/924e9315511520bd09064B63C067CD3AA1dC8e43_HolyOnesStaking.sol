pragma solidity ^0.8.19;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tag.sol";

/// @title HolyOnesStaking
/// @author Atlas C.O.R.P.

type UC is uint256;

UC constant ONE = UC.wrap(1);

using { add as +, lt as < } for UC global;

/// @notice Sums up `x` and `y` without checked arithmetic.
function add(UC x, UC y) pure returns (UC) {
    unchecked {
        return UC.wrap(UC.unwrap(x) + UC.unwrap(y));
    }
}

/// @notice Checks if `x` is lower than `y`.
function lt(UC x, UC y) pure returns (bool) {
    return UC.unwrap(x) < UC.unwrap(y);
}

contract HolyOnesStaking is Ownable {
    address public immutable holyOnesContract;

    struct StakingData {
        uint256 timestamp;
        address walletAddress;
    }

    bool public active;
    mapping(uint256 tokenId => StakingData stakingData)
        public timestampByTokenId;

    event TokenStaked(uint256 tokenId);
    event TokenUnstaked(uint256 tokenId);
    event ActiveToggled(bool active);

    constructor(address _holyOnesContract) {
        holyOnesContract = _holyOnesContract;
        active = false;
    }

    /// @param _tokenId HolyOne token Id
    /// @param _owner Owner address
    function _stakeHolyOne(uint256 _tokenId, address _owner) internal {
        require(
            IERC721(holyOnesContract).ownerOf(_tokenId) == _owner,
            "_stakeHolyOnes: caller must own token"
        );
        timestampByTokenId[_tokenId] = StakingData(block.timestamp, _owner);
        emit TokenStaked(_tokenId);
    }

    /// @param _tokenId HolyOne token Id
    /// @param _owner Owner address
    function _unstakeHolyOne(uint256 _tokenId, address _owner) internal {
        require(
            IERC721(holyOnesContract).ownerOf(_tokenId) == _owner,
            "stakeHolyOnes: caller must own token"
        );
        require(
            timestampByTokenId[_tokenId].timestamp != 0,
            "_unstakeHolyOne: token must be staked"
        );
        timestampByTokenId[_tokenId].timestamp = 0;
        emit TokenUnstaked(_tokenId);
    }

    /// @param _tokenIds array of HolyOne token Ids
    function stakeHolyOnes(uint256[] calldata _tokenIds) external {
        for (UC i = UC.wrap(0); i < UC.wrap(_tokenIds.length); i = i + ONE) {
            _stakeHolyOne(_tokenIds[UC.unwrap(i)], msg.sender);
        }
    }

    /// @param _tokenIds array of HolyOne token Ids
    function unstakeHolyOnes(uint256[] calldata _tokenIds) external {
        for(UC i = UC.wrap(0); i < UC.wrap(_tokenIds.length); i = i + ONE){
            _unstakeHolyOne(_tokenIds[UC.unwrap(i)], msg.sender);
        }
    }

    /// @param _active new active state
    function toggleActive(bool _active) external onlyOwner {
        active = _active;
        emit ActiveToggled(active);
    }

    function getTimeStaked(uint256 _tokenId) public view returns (uint256) {
        return
            timestampByTokenId[_tokenId].timestamp == 0
                ? 0
                : block.timestamp - timestampByTokenId[_tokenId].timestamp;
    }

    function getTimesStaked(
        uint256[] calldata _tokenIds
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256[] memory timesStaked = new uint256[](_tokenIds.length);
            for (UC i = UC.wrap(0); i < UC.wrap(_tokenIds.length); i = i + ONE) {
                timesStaked[UC.unwrap(i)] = getTimeStaked(_tokenIds[UC.unwrap(i)]);
            }
            return timesStaked;
        }
    }

    function getStakedTokens(
        uint256[] calldata _tokenIds
    ) external view returns (StakingData[] memory stakedTokens) {
        stakedTokens = new StakingData[](_tokenIds.length);
        for(UC i = UC.wrap(0); i < UC.wrap(_tokenIds.length); i = i + ONE ) {
            stakedTokens[UC.unwrap(i)] = timestampByTokenId[_tokenIds[UC.unwrap(i)]];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//                      ---------------[ ]---------------
//                      -------[ ]-------------[ ]-------
//                      ---------------------------------
//                      ----[ ]--------[ ]--------[ ]----
//                      ---------------------------------
//                      -------[ ]-------------[ ]-------
//                      ---------------[ ]---------------

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