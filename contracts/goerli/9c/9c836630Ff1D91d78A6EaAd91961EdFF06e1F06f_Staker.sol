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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staker is ReentrancyGuard, Pausable, Ownable {
    struct Position {
        address erc20Token;
        uint256 positionID;
        address walletAddress;
        uint256 createdDate;
        uint256 unlockDate;
        uint256 percentInerest;
        uint256 tokenStaked;
        uint256 tokenInterest;
        bool open;
    }

    Position position;

    uint256 public currentPositionId;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public positionIdsByAddress;
    mapping(address => uint256[]) public balances;
    mapping(uint256 => uint256) public tiers;
    uint256[] public lockPeriods;
    event Staked(address stakeHolder, uint256 amount);
    event Withdraw(address stakeHolder, uint256 amount);
    event RewardsPaid(address stakeHolder, uint256 amount);
    event StakingTokenAdded(address _token, uint256 _amount);
    event ClosedPosition(address _token, address _walletAddress);

    constructor() payable {
        currentPositionId = 0;
        tiers[30] = 700;
        tiers[60] = 1000;
        tiers[90] = 1200;
        tiers[120] = 1500;

        lockPeriods.push(30);
        lockPeriods.push(60);
        lockPeriods.push(90);
        lockPeriods.push(120);
    }

    function addStakingToken(address _token, uint256 _amount) public {
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        emit StakingTokenAdded(_token, _amount);
    }

    function stakeToken(
        uint256 _numDays,
        uint256 _amountTokens,
        address _token
    ) external {
        require(
            _numDays == 30 ||
                _numDays == 60 ||
                _numDays == 90 ||
                _numDays == 120,
            "Invalid lock period"
        );
        require(_amountTokens > 0, "Invalid amount");
        require(_token != address(0), "Invalid token address");

        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(msg.sender) >= _amountTokens,
            "Insufficient balance"
        );

        uint256 interest = (_amountTokens * tiers[_numDays]) / 10000;
        uint256 unlockDate = block.timestamp + (_numDays * 1 days);

        currentPositionId++;
        position = Position({
            erc20Token: _token,
            positionID: currentPositionId,
            walletAddress: msg.sender,
            createdDate: block.timestamp,
            unlockDate: unlockDate,
            percentInerest: tiers[_numDays],
            tokenStaked: _amountTokens,
            tokenInterest: interest,
            open: true
        });

        positions[currentPositionId] = position;
        balances[msg.sender].push(currentPositionId);

        token.transferFrom(msg.sender, address(this), _amountTokens);
        emit Staked(msg.sender, _amountTokens);
    }

    function withdraw(uint256 _positionId) external {
        require(_positionId > 0, "Invalid position id");
        require(positions[_positionId].open, "Position is already closed");

        position = positions[_positionId];
        require(position.walletAddress == msg.sender, "Invalid user");
        require(block.timestamp >= position.unlockDate, "Position is locked");

        IERC20 token = IERC20(position.erc20Token);
        uint256 amount = position.tokenStaked + position.tokenInterest;
        token.transfer(msg.sender, amount);

        position.open = false;
        emit Withdraw(msg.sender, amount);
    }

    function getBalance(address _token) public view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    function calculateInterest(uint256 basisPoints, uint256 tokenAmount)
        public
        pure
        returns (uint256)
    {
        return (basisPoints / 10000) * tokenAmount;
    }

    function modifyLockPeriod(uint256 _basisPoints, uint256 _numDays) external {
        tiers[_numDays] = _basisPoints;
        lockPeriods.push(_numDays);
    }

    function getStakingTokenName(address _token)
        public
        view
        returns (string memory)
    {
        IERC20Metadata token = IERC20Metadata(_token);
        return token.name();
    }

    function getPositionById(uint256 _positionId)
        public
        view
        returns (Position memory)
    {
        return positions[_positionId];
    }

    function getPositionsByAddress(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return positionIdsByAddress[_address];
    }

    function getInterestRate(uint256 numDays) external view returns (uint256) {
        return tiers[numDays];
    }

    function withDrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withDrawAlltokens(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }

    function withdrawSomeTokens(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(_amount > 0, "Invalid amount");
        require(
            _amount <= getBalance(_token),
            "Insufficient balance in contract"
        );
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function changeUnlockDate(uint256 positionId, uint256 _newUnlockDate)
        external
        onlyOwner
    {
        positions[positionId].unlockDate = _newUnlockDate;
    }

    function closePosition(uint256 positionId) external onlyOwner {
        require(
            positions[positionId].walletAddress == msg.sender,
            "Invalid user"
        );
        require(
            (positions[positionId].open == true),
            "Position is already closed"
        );
        positions[positionId].open = false;
        if (block.timestamp > positions[positionId].unlockDate) {
            uint256 amount = positions[positionId].tokenStaked +
                positions[positionId].tokenInterest;
            IERC20 token = IERC20(positions[positionId].erc20Token);
            token.transfer(msg.sender, amount);
            emit ClosedPosition(
                positions[positionId].erc20Token,
                positions[positionId].walletAddress
            );
        }
    }
}