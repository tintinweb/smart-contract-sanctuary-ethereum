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

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Operator.sol";
import "./lib/IBAYCSewerPass.sol";
import "./lib/YugaVerify.sol";

//      |||||\          |||||\               |||||\           |||||\
//      ||||| |         ||||| |              ||||| |          ||||| |
//       \__|||||\  |||||\___\|               \__|||||\   |||||\___\|
//          ||||| | ||||| |                      ||||| |  ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|          Sewer Pass      |||||\___\|
//          ||||| |                 Claim        ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

error ClaimIsNotActive();
error TokenAlreadyClaimed();
error UnauthorizedOwner();

/**
 * @title BAYC Sewer Pass Claim Smart Contract
 */
contract BAYCSewerPassClaim is Operator, YugaVerify, ReentrancyGuard {
    uint64 constant TIER_FOUR = 4;
    uint64 constant TIER_THREE = 3;
    uint64 constant TIER_TWO = 2;
    uint64 constant TIER_ONE = 1;
    uint256 constant NO_DOGGO = 10000;
    address public immutable BAYC_CONTRACT;
    address public immutable MAYC_CONTRACT;
    address public immutable BAKC_CONTRACT;
    bool public claimIsActive;
    mapping(uint256 => bool) public baycClaimed;
    mapping(uint256 => bool) public maycClaimed;
    mapping(uint256 => bool) public bakcClaimed;
    IBAYCSewerPass public immutable sewerPassContract;

    event SewerPassMinted(
        uint256 indexed sewerPassTokenId,
        uint256 indexed tier,
        uint256 indexed baycMaycTokenId,
        uint256 bakcTokenId
    );

    modifier claimable() {
        if (!claimIsActive) revert ClaimIsNotActive();
        _;
    }

    constructor(
        address _baycContract,
        address _maycContract,
        address _bakcContract,
        address _warmContract,
        address _delegateCashContract,
        address _sewerPassContract,
        address _operator
    ) Operator(_operator) YugaVerify(_warmContract, _delegateCashContract) {
        BAYC_CONTRACT = _baycContract;
        MAYC_CONTRACT = _maycContract;
        BAKC_CONTRACT = _bakcContract;
        sewerPassContract = IBAYCSewerPass(_sewerPassContract);
    }

    /**
     * @notice Claim Sewer Pass with BAYC and BAKC pair - TIER 4
     * @param baycTokenId token id of the ape
     * @param bakcTokenId token id of the dog
     */
    function claimBaycBakc(
        uint256 baycTokenId,
        uint256 bakcTokenId
    ) external claimable nonReentrant {
        _checkBaycClaim(baycTokenId);
        _checkBakcClaim(bakcTokenId);
        _mintSewerPass(TIER_FOUR, baycTokenId, bakcTokenId);
    }

    /**
     * @notice Claim Sewer Pass with with BAYC - TIER 3
     * @param baycTokenId token id of the ape
     */
    function claimBayc(uint256 baycTokenId) external claimable nonReentrant {
        _checkBaycClaim(baycTokenId);
        _mintSewerPass(TIER_THREE, baycTokenId, NO_DOGGO);
    }

    /**
     * @notice Claim Sewer Pass with MAYC and BAKC pair - TIER 2
     * @param maycTokenId token id of the mutant
     * @param bakcTokenId token id of the dog
     */
    function claimMaycBakc(
        uint256 maycTokenId,
        uint256 bakcTokenId
    ) external claimable nonReentrant {
        _checkMaycClaim(maycTokenId);
        _checkBakcClaim(bakcTokenId);
        _mintSewerPass(TIER_TWO, maycTokenId, bakcTokenId);
    }

    /**
     * @notice Claim Sewer Pass with MAYC - TIER 1
     * @param maycTokenId token id of the mutant
     */
    function claimMayc(uint256 maycTokenId) external claimable nonReentrant {
        _checkMaycClaim(maycTokenId);
        _mintSewerPass(TIER_ONE, maycTokenId, NO_DOGGO);
    }

    // Manage token checks and claim status

    function _checkBaycClaim(uint256 tokenId) private {
        if (!verifyTokenOwner(BAYC_CONTRACT, tokenId))
            revert UnauthorizedOwner();
        if (baycClaimed[tokenId]) revert TokenAlreadyClaimed();
        baycClaimed[tokenId] = true;
    }

    function _checkMaycClaim(uint256 tokenId) private {
        if (!verifyTokenOwner(MAYC_CONTRACT, tokenId))
            revert UnauthorizedOwner();
        if (maycClaimed[tokenId]) revert TokenAlreadyClaimed();
        maycClaimed[tokenId] = true;
    }

    function _checkBakcClaim(uint256 tokenId) private {
        if (!verifyTokenOwner(BAKC_CONTRACT, tokenId))
            revert UnauthorizedOwner();
        if (bakcClaimed[tokenId]) revert TokenAlreadyClaimed();
        bakcClaimed[tokenId] = true;
    }

    function _mintSewerPass(
        uint64 tier,
        uint256 baycMaycTokenId,
        uint256 bakcTokenId
    ) private {
        // prepare mint data for storage
        uint256 mintData = uint256(tier);
        mintData |= baycMaycTokenId << 64;
        mintData |= bakcTokenId << 128;

        uint256 sewerPassTokenId = sewerPassContract.mintSewerPass(
            _msgSender(),
            mintData
        );
        emit SewerPassMinted(
            sewerPassTokenId,
            tier,
            baycMaycTokenId,
            bakcTokenId
        );
    }

    /**
     * @notice Check BAYC/MAYC/BAKC token claim status - bayc = 0, mayc = 1, bakc = 2
     * @param collectionId id of the collection see above
     * @param tokenId id of the ape, mutant or dog
     */
    function checkClaimed(
        uint8 collectionId,
        uint256 tokenId
    ) external view returns (bool) {
        if (collectionId == 0) {
            return baycClaimed[tokenId];
        } else if (collectionId == 1) {
            return maycClaimed[tokenId];
        } else if (collectionId == 2) {
            return bakcClaimed[tokenId];
        }
        return false;
    }

    // Operator functions

    /**
     * @notice Flip the claim state
     */
    function flipClaimIsActiveState() external onlyOperator {
        claimIsActive = !claimIsActive;
    }

    /**
     * @notice Withdraw erc-20 tokens sent to the contract by error
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOperator {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(operator, balance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBAYCSewerPass {
    function mintSewerPass(
        address to,
        uint256 mintdata
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

error OnlyOperatorError();
error OperatorZeroAddressCheck();

contract Operator is Ownable {
    address public operator;

    event OperatorChanged(address operator);

    modifier onlyOperator() {
        if (operator != _msgSender()) revert OnlyOperatorError();
        _;
    }

    constructor(address _operator) {
        if (_operator == address(0)) revert OperatorZeroAddressCheck();
        operator = _operator;
    }

    /**
     * @notice change operator
     */
    function setOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert OperatorZeroAddressCheck();

        operator = _operator;
        emit OperatorChanged(_operator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface WarmInterface {
    function ownerOf(
        address contractAddress,
        uint256 tokenId
    ) external view returns (address);
}

interface DelegateCashInterface {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

error ZeroAddressCheck();

/**
 * @title YugaVerify - check for token ownership via contract, warm wallet and delegate cash
 * Warm Wallet https://github.com/wenewlabs/public/tree/main/HotWalletProxy
 * Delegate.cash https://github.com/delegatecash/delegation-registry
 */
contract YugaVerify {
    address public immutable WARM_WALLET_CONTRACT;
    address public immutable DELEGATE_CASH_CONTRACT;

    constructor(address _warmWalletContract, address _delegateCashContract) {
        if (
            _warmWalletContract == address(0) ||
            _delegateCashContract == address(0)
        ) revert ZeroAddressCheck();
        WARM_WALLET_CONTRACT = _warmWalletContract;
        DELEGATE_CASH_CONTRACT = _delegateCashContract;
    }

    /**
     * @notice verify contract token based claim using warm wallet and delegate cash
     * @param tokenContract the smart contract address of the token
     * @param tokenId the tokenId
     */
    function verifyTokenOwner(
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);

        // 1. check contract token owner
        // 2. check warm wallet delegation - ownerOf()
        //      all delegation
        //      is a mapping of token owner's wallet to hot wallet
        //      coldWalletToHotWallet[owner].walletAddress
        // 3. check delegate.cash delegation - checkDelegateForToken()
        //      checks three forms of delegation all, contract, and contract/token id
        return (msg.sender == tokenOwner ||
            msg.sender ==
            WarmInterface(WARM_WALLET_CONTRACT).ownerOf(
                tokenContract,
                tokenId
            ) ||
            DelegateCashInterface(DELEGATE_CASH_CONTRACT).checkDelegateForToken(
                    msg.sender,
                    tokenOwner,
                    tokenContract,
                    tokenId
                ));
    }
}