// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../interfaces/ISwapRewards.sol";
import "../interfaces/IOracleFactory.sol";
import "../interfaces/IHelixToken.sol";
import "../interfaces/IReferralRegister.sol";
import "../libraries/Percent.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// Distribute HELIX reward when users swap tokens
contract SwapRewards is ISwapRewards, Ownable, Pausable {
    /// The HELIX reward token
    IHelixToken public helixToken;

    /// Determines the amount of HELIX earned based the swap
    IOracleFactory public oracleFactory;

    /// Generate rewards for the user's referrer
    IReferralRegister public refReg;

    /// The router contract which can call the swap
    address public router;

    // Emitted when a swap is performed
    event Swap(
        address user,
        address indexed tokenIn, 
        uint256 amountIn,
        uint256 helixOut
    );

    // Emitted when the helixToken is set
    event SetHelixToken(address indexed setter, address indexed helixToken);

    // Emitted when the oracleFactory is set
    event SetOracleFactory(address indexed setter, address indexed oracleFactory);

    // Emitted when the refReg is set
    event SetRefReg(address indexed setter, address indexed refReg);

    // Emitted when the router is set
    event SetRouter(address indexed setter, address indexed router);

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "SwapFee: zero address");
        _;
    }

    constructor(
        address _helixToken,
        address _oracleFactory,
        address _refReg,
        address _router
    ) {
        helixToken = IHelixToken(_helixToken);
        oracleFactory = IOracleFactory(_oracleFactory);
        refReg = IReferralRegister(_refReg);
        router = _router;
    }

    /// Accrue HELIX proportional to _amountIn of _tokenIn to the _user performing a swap
    function swap(address _user, address _tokenIn, uint256 _amountIn) 
        external 
        whenNotPaused
    {
        require(msg.sender == router, "SwapFee: not router");
    
        uint256 helixOut = oracleFactory.consult(_tokenIn, _amountIn, address(helixToken));
        if (helixOut > 0) {
            refReg.rewardSwap(_user, helixOut);
        }
        
        emit Swap(_user, _tokenIn, _amountIn, helixOut);
    }

    /// Called by the owner to set the _helixToken
    function setHelixToken(address _helixToken) 
        external 
        onlyOwner 
        onlyValidAddress(_helixToken)
    {
        helixToken = IHelixToken(_helixToken);
        emit SetHelixToken(msg.sender, _helixToken);
    }

    /// Called by the owner to set the _oracleFactory
    function setOracleFactory(address _oracleFactory) 
        external 
        onlyOwner 
        onlyValidAddress(_oracleFactory) 
    {
        oracleFactory = IOracleFactory(_oracleFactory);
        emit SetOracleFactory(msg.sender, _oracleFactory);
    }

    /// Called by the owner to set the _refReg
    function setRefReg(address _refReg) 
        external 
        onlyOwner 
        onlyValidAddress(_refReg) 
    {
        refReg = IReferralRegister(_refReg);
        emit SetRefReg(msg.sender, _refReg);
    }

    /// Called by the owner to set the _router
    function setRouter(address _router) external onlyOwner onlyValidAddress(_router) {
        router = _router;
        emit SetRouter(msg.sender, _router);
    }

    /// Called by the owner to pause swaps
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause swaps
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapRewards {
    function swap(address user, address tokenIn, uint256 amountIn) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracleFactory {
    function create(address token0, address token1) external;
    function update(address token0, address token1) external;
    function consult(address tokenIn, uint256 amountIn, address tokenOut) external view returns (uint256 amountOut);
    function getOracle(address token0, address token1) external view returns (address oracle);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHelixToken {
    function mint(address to, uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixToken.sol";

interface IReferralRegister {
    function toMintPerBlock() external view returns (uint256);
    function helixToken() external view returns (IHelixToken);
    function stakeRewardPercent() external view returns (uint256);
    function swapRewardPercent() external view returns (uint256);
    function lastMintBlock() external view returns (uint256);
    function referrers(address _referred) external view returns (address);
    function rewards(address _referrer) external view returns (uint256);

    function initialize(
        IHelixToken _helixToken, 
        address _feeHandler,
        uint256 _stakeRewardPercent, 
        uint256 _swapRewardPercent,
        uint256 _toMintPerBlock,
        uint256 _lastMintBlock
    ) external; 

    function rewardStake(address _referred, uint256 _stakeAmount) external;
    function rewardSwap(address _referred, uint256 _swapAmount) external;
    function withdraw() external;
    function setToMintPerBlock(uint256 _toMintPerBlock) external;
    function setStakeRewardPercent(uint256 _stakeRewardPercent) external;
    function setSwapRewardPercent(uint256 _swapRewardPercent) external;
    function addReferrer(address _referrer) external;
    function removeReferrer() external;
    function update() external;
    function addRecorder(address _recorder) external returns (bool);
    function removeRecorder(address _recorder) external returns (bool);
    function setLastRewardBlock(uint256 _lastMintBlock) external;
    function pause() external;
    function unpause() external;
    function setFeeHandler(address _feeHandler) external;
    function setCollectorPercent(uint256 _collectorPercent) external;
    function getRecorder(uint256 _index) external view returns (address);
    function getRecorderLength() external view returns (uint256);
    function isRecorder(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

library Percent {
    uint256 public constant MAX_PERCENT = 100;

    modifier onlyValidPercent(uint256 _percent, uint256 _decimals) {
        require(_isValidPercent(_percent, _decimals), "Percent: invalid percent");
        _;
    }

    // Return true if the _percent is valid and false otherwise
    function isValidPercent(uint256 _percent)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, 0);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function isValidPercent(uint256 _percent, uint256 _decimals)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, _decimals);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function _isValidPercent(uint256 _percent, uint256 _decimals)
        private
        pure
        returns (bool)
    {
        return _percent <= MAX_PERCENT * 10 ** _decimals;
    }

    // Return _percent of _amount
    function getPercentage(uint256 _amount, uint256 _percent)
        internal 
        pure
        returns (uint256 percentage) 
    {
        percentage = _getPercentage(_amount, _percent, 0);
    }

    // Return _percent of _amount with _decimals many decimals
    function getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage)
    {
        percentage =_getPercentage(_amount, _percent, _decimals);
    }

    // Return _percent of _amount with _decimals many decimals
    function _getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals) 
        private
        pure
        onlyValidPercent(_percent, _decimals) 
        returns (uint256 percentage)
    {
        percentage = _amount * _percent / (MAX_PERCENT * 10 ** _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    function splitByPercent(uint256 _amount, uint256 _percent) 
        internal 
        pure 
        returns (uint256 percentage, uint256 remainder) 
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, 0);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage, uint256 remainder)
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function _splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        private
        pure
        onlyValidPercent(_percent, _decimals)
        returns (uint256 percentage, uint256 remainder)
    {
        percentage = _getPercentage(_amount, _percent, _decimals);
        remainder = _amount - percentage;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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