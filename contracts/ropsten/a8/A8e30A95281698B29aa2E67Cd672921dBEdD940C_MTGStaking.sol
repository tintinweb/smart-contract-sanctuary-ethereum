// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IArcada {
    function gamerNFTMint(address to, uint256 amount) external;
}

interface IMTG {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract MTGStaking is Ownable, ReentrancyGuard {
    IArcada public Arcada;
    IMTG public MTG;

    uint256 public constant DAY = 5;
    uint256 public constant SEVEN_DAYS = 7 * DAY;

    uint256 public START;
    uint256 public GAMER_RATE = Math.ceilDiv(8 * 10 ** 18, DAY);
    uint256 public ROYAL_GAMER_RATE = Math.ceilDiv(12 * 10 ** 18, DAY);

    address public MTGAddress = 0x9fF4995C87CBaf1ab0C8626d0B094992fa10038b;
    address public ArcadaAddress = 0xaa5C32766309e877426711834280A31416C451Dc;
    bool public emergencyUnstakePaused = true;

    struct stakeRecord {
        address tokenOwner;
        uint256 tokenId;
        uint256 lockInEndAt;
        uint256 stakedAt;
    }

    mapping(uint256 => stakeRecord) public stakingRecords;

    mapping(address => uint256) public numOfTokenStaked;

    event Staked(address owner, uint256 amount);

    event Claimed(address owner, uint256 rewards);

    event Unstaked(address owner, uint256 amount);

    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {
        START = block.timestamp;
        MTG = IMTG(MTGAddress);
        Arcada = IArcada(ArcadaAddress);
    }

    // STAKING
    function batchStake(
        uint256[] calldata tokenIds
    )
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(_msgSender(), tokenIds[i]);
        }
    }

    function _stake(
        address _user,
        uint256 _tokenId
    ) internal {
        require(
            MTG.ownerOf(_tokenId) == _msgSender(),
            "You must own the NFT."
        );
        uint256 lockInEndAt = block.timestamp + SEVEN_DAYS;

        stakingRecords[_tokenId] = stakeRecord(
            _user,
            _tokenId,
            lockInEndAt,
            block.timestamp
        );
        numOfTokenStaked[_user] = numOfTokenStaked[_user] + 1;
        MTG.safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId);
    }

    // RESTAKE
    function batchRestakeAndClaim(
        uint256[] calldata tokenIds
    )
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _restakeAndClaim(_msgSender(), tokenIds[i]);
        }
    }

    function _restakeAndClaim(
        address _user,
        uint256 _tokenId
    ) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].lockInEndAt,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == _msgSender(),
            "Token does not belong to you."
        );

        uint256 rewards = getPendingRewards(_tokenId);

        stakingRecords[_tokenId].lockInEndAt = block.timestamp + SEVEN_DAYS;
        stakingRecords[_tokenId].stakedAt = block.timestamp;
        Arcada.gamerNFTMint(_user, rewards);

        emit Staked(_user, _tokenId);
        emit Claimed(_user, rewards);
    }

    // UNSTAKE
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(_msgSender(), tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].lockInEndAt,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == _msgSender(),
            "Token does not belong to you."
        );

        uint256 rewards = getPendingRewards(_tokenId);
        delete stakingRecords[_tokenId];
        numOfTokenStaked[_user]--;
        MTG.safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );
        Arcada.gamerNFTMint(_user, rewards);

        emit Unstaked(_user, _tokenId);
        emit Claimed(_user, rewards);
    }

    function getStakingRecords(address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](numOfTokenStaked[user]);
        uint256[] memory expiries = new uint256[](numOfTokenStaked[user]);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < MTG.totalSupply();
            i++
        ) {
            if (stakingRecords[i].tokenOwner == user) {
                tokenIds[counter] = stakingRecords[i].tokenId;
                expiries[counter] = stakingRecords[i].lockInEndAt;
                counter++;
            }
        }
        return (tokenIds, expiries);
    }

    function getPendingRewards(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(stakingRecords[tokenId].stakedAt > START, "NFT is not staked.");
        return (block.timestamp - stakingRecords[tokenId].stakedAt) * GAMER_RATE;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // MIGRATION ONLY.
    function setMTGNFTContract(address operator) public onlyOwner {
        MTG = IMTG(operator);
    }

    function setArcadaContract(address operator) public onlyOwner {
        Arcada = IArcada(operator);
    }

    // EMERGENCY ONLY.
    function setEmergencyUnstakePaused(bool paused)
        public
        onlyOwner
    {
        emergencyUnstakePaused = paused;
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        require(
            stakingRecords[tokenId].tokenOwner == _msgSender(),
            "Token does not belong to you."
        );
        _unstake(_msgSender(), tokenId);
        emit EmergencyUnstake(_msgSender(), tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
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