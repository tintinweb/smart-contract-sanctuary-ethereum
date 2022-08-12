//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILLC.sol";
import "./interfaces/ILLCTier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LLCGift is Ownable, Pausable, ReentrancyGuard {
    /// @dev LLC NFT contract
    address public LLC;

    /// @dev ETH-AGOV Staking contract
    address public ETH_AGOV_STAKING;

    /// @dev LLC Claimers
    mapping(address => uint256) public claimers;

    /// @dev LLC Claim Status
    mapping(address => uint256) public claimStatuses;

    constructor(address _llc, address _staking) {
        LLC = _llc;
        ETH_AGOV_STAKING = _staking;
        _pause();
    }

    /// @dev Set LLC contract address
    function setLLC(address _llc) external onlyOwner {
        LLC = _llc;
        emit SetLLC(_llc);
    }

    /// @dev Set ETH-AGOV Staking contract address
    function setStaking(address _staking) external onlyOwner {
        ETH_AGOV_STAKING = _staking;
        emit SetStaking(_staking);
    }

    /// @dev Mint LLCs
    function mint(uint256 _amount) external onlyOwner {
        getLLC().mint(address(this), _amount);
    }

    /// @dev Pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Add claimer to the list of claimers
    function addClaimer(address _claimer, uint256 _amount)
        external
        onlyStakingOrOwner
    {
        claimers[_claimer] = _amount;
        emit Claimer(_claimer, _amount);
    }

    /// @dev Claim LLC
    function claim(address _who, uint256[] calldata _tokenIds)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 amount = _tokenIds.length;
        require(amount > 0, "Empty TokenIds");

        uint256 status = claimStatuses[_msgSender()] + amount;
        if (owner() != _msgSender()) {
            require(status <= claimers[_msgSender()], "Overflow");
        }

        uint256 tokenId;
        ILLC llc = getLLC();
        for (uint256 i = 0; i < amount; i++) {
            tokenId = _tokenIds[i];
            llc.transferFrom(address(this), _who, tokenId);
            emit Claimed(_who, tokenId);
        }

        claimStatuses[_msgSender()] = status;
    }

    /// @dev Withdraw LLCs
    function withdrawTokens(address _who, uint256[] calldata _tokenIds)
        external
        onlyOwner
    {
        uint256 amount = _tokenIds.length;
        require(amount > 0, "Empty TokenIds");
        ILLC llc = getLLC();
        uint256 tokenId;
        for (uint256 i = 0; i < amount; i++) {
            tokenId = _tokenIds[i];
            llc.transferFrom(address(this), _who, tokenId);
            emit Claimed(_who, tokenId);
        }
    }

    /// @dev Get LLC contract
    function getLLC() public view returns (ILLC) {
        return ILLC(LLC);
    }

    /// @dev Get Staking contract
    function getStaking() public view returns (address) {
        return ETH_AGOV_STAKING;
    }

    modifier onlyStakingOrOwner() {
        require(
            _msgSender() == getStaking() || _msgSender() == owner(),
            "Only staking contract can call this function"
        );
        _;
    }

    event SetLLC(address llc);
    event SetStaking(address staking);
    event Claimer(address claimer, uint256 amount);
    event Claimed(address claimer, uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILLC {
    function mint(address, uint256) external;

    function totalSupply() external view returns (uint256);

    function tokenCount() external view returns (uint256);

    function mintedTotalSupply() external view returns (uint256);

    function tokenByIndex(uint256) external view returns (uint256);

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILLCTier {
    function LEGENDARY_RARITY() external returns (uint256);

    function SUPER_RARE_RARITY() external returns (uint256);

    function RARE_RARITY() external returns (uint256);

    function LLCRarities(uint256) external returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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