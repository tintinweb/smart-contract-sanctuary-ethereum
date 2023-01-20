// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBAYCSewerPass {
    function mint(address to, uint256 index) external;
    function totalSupply() external returns (uint256);
}

error ClaimIsNotActive();
error TokenAlreadyClaimed();
error UnauthorizedOwner();

/**
 * @title BAYC Sewer Pass Claim Smart Contract
 */
contract BAYCSewerPassClaim is ReentrancyGuard {
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
        address _sewerPassContract
    ) {
        BAYC_CONTRACT = _baycContract;
        MAYC_CONTRACT = _maycContract;
        BAKC_CONTRACT = _bakcContract;
        sewerPassContract = IBAYCSewerPass(_sewerPassContract);
        claimIsActive = true;
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
        if (baycClaimed[tokenId]) revert TokenAlreadyClaimed();
        baycClaimed[tokenId] = true;
    }

    function _checkMaycClaim(uint256 tokenId) private {
        if (maycClaimed[tokenId]) revert TokenAlreadyClaimed();
        maycClaimed[tokenId] = true;
    }

    function _checkBakcClaim(uint256 tokenId) private {
        if (bakcClaimed[tokenId]) revert TokenAlreadyClaimed();
        bakcClaimed[tokenId] = true;
    }

    function _mintSewerPass(
        uint64 tier,
        uint256 baycMaycTokenId,
        uint256 bakcTokenId
    ) private {
        // prepare mint data for storage
        // uint256 mintData = uint256(tier);
        // mintData |= baycMaycTokenId << 64;
        // mintData |= bakcTokenId << 128;

        uint256 sewerPassTokenId = sewerPassContract.totalSupply();
        sewerPassContract.mint(
            msg.sender,
            sewerPassTokenId
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