// SPDX-License-Identifier: MIT

import "Ownable.sol";
import "IERC20.sol";
import "IERC20Extended.sol";

pragma solidity 0.8.12;

/**
 * @title Blender is exchange contract for MILK2 => SHAKE tokens
 *
 * @dev Don't forget permit mint and burn in tokens contracts
 */
 contract Blender is Ownable {
        
    uint256 public constant  SHAKE_PRICE_STEP = 1e18;  // MILK2
    address public immutable MILK_ADDRESS;
    address public immutable SHAKE_ADDRESS;
    
    bool    public paused;
    uint256 public currShakePrice;
    uint256 public mintShakeLimit;
    uint256 public shakeMinted;
    
    /**
     * @dev Sets the values for {MILK_ADDRESS}, 
     * {SHAKE_ADDRESS}, initializes {currShakePrice} with
     */ 
    constructor (
        address _milkAddress,
        address _shakeAddress,
        uint256  _currShakePrice
    )
    {
        MILK_ADDRESS     = _milkAddress;
        SHAKE_ADDRESS    = _shakeAddress;
        currShakePrice   = _currShakePrice; // MILK2
    }
    
    /**
     * @dev Just exchage your MILK2 for one(1) SHAKE.
     * Caller must have MILK2 on his/her balance, see `currShakePrice`
     * Each call will increase SHAKE price with one step, see `SHAKE_PRICE_STEP`.
     *
     */
    function getOneShake() external {
        require(!paused, "Blender is paused");

        IERC20Extended milk2Token = IERC20Extended(MILK_ADDRESS);
        require(milk2Token.burn(msg.sender, currShakePrice), "Can't burn your MILK2");
        currShakePrice  += SHAKE_PRICE_STEP;

        IERC20Extended shakeToken = IERC20Extended(SHAKE_ADDRESS);
        shakeToken.mint(msg.sender, 1e18);
        shakeMinted += 1e18;
        require(shakeMinted <= mintShakeLimit, "Mint limit exceeded");
    }

    /////////////////////////////////////////////////////////////
    ////      Admin Function                               //////
    /////////////////////////////////////////////////////////////

    /**
    *@dev set pause state
    *for owner use ONLY!!
    */
    function setPauseState(bool _isPaused) external onlyOwner {
        paused = _isPaused;
    }

    /**
    *@dev set Mint Limit
    *for owner use ONLY!!
    */ 
    function setMintLimit(uint256 _value) external onlyOwner {
        mintShakeLimit = _value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity 0.8.12;

import "IERC20.sol";

interface IERC20Extended is  IERC20 {
     function mint(address _to, uint256 _value) external returns (bool);
     function burn(address _to, uint256 _value) external returns (bool);
}