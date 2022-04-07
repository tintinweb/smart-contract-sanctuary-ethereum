/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
// File: Astro_Contracts/interface/IpAstroToken.sol


pragma solidity ^ 0.8.7;

interface IpAstroToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function getOwner() external view returns (address);
    function getCirculatingSupply() external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function setOwner(address owner) external;
    function setInitialDistributionFinished(bool value) external;
    function clearStuckBalance(address receiver) external;
    function rescueToken(address tokenAddress, uint256 tokens) external returns (bool success);
    function setPresaleFactory(address presaleFactory) external;
    function setAutoRebase(bool autoRebase) external;
    function setRebaseFrequency(uint256 rebaseFrequency) external;
    function setRewardYield(uint256 rewardYield, uint256 rewardYieldDenominator) external;
    function setNextRebase(uint256 nextRebase) external;
    function manualRebase() external;
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Astro_Contracts/PresaleFactory.sol


pragma solidity ^ 0.8.7;




contract PresaleFactory is Ownable {
    IpAstroToken pAstro;
    IERC20 usdcAddress;

    uint256 public minCap                                   = 65625 * 10 ** 3 * 10 ** 18;
    uint256 public maxCap                                   = 13125 * 10 ** 4 * 10 ** 18;
    uint256 pTokenPrice_USDC                                = 8 * 10 ** 15;
    uint256 pTokenPrice_AVAX                                = 954996 * 10 ** 10;
    
    uint256 start_time;
    uint256 end_time;

    address payable presaleOwnerAddress                     = payable(0xbAB8E9cA493E21d5A3f3e84877Ba514c405be0e1);

    constructor(address _pAstro, address _usdc) {
        pAstro = IpAstroToken(_pAstro);
        usdcAddress = IERC20(_usdc);
    }

    function getMinCap() external view returns (uint256) {
        return minCap;
    }

    function getMaxCap() external view returns (uint256) {
        return maxCap;
    }

    function presale(uint256 _amountToken, uint cType) external payable {
        require(_amountToken >= minCap && _amountToken <= maxCap, "PresaleFactory: The amount is not allowed for presale.");
        require(block.timestamp >= start_time && block.timestamp <= end_time, "not presale time");
        require(pAstro.balanceOf(address(this)) >= _amountToken, "PresaleFactory: The token balance of factory is low.");

        if (cType == 0) {                               // buy using AVAX
            require(msg.value == _amountToken / 10 ** 18 * pTokenPrice_AVAX, "incorrect avax amount");
            presaleOwnerAddress.transfer(msg.value);
        }
        else {                                          // buy using USDC
            usdcAddress.transferFrom(msg.sender, presaleOwnerAddress, _amountToken * pTokenPrice_USDC);
        }
        
        // transfer pASTRO token to user
        pAstro.transfer(msg.sender, _amountToken);

        emit Presale(address(this), msg.sender, _amountToken);
    }

    function setMinCap(uint256 _minCap) external onlyOwner {
        minCap = _minCap;

        emit SetMinCap(_minCap);
    }

    function setMaxCap(uint256 _maxCap) external onlyOwner {
        maxCap = _maxCap;

        emit SetMaxCap(_maxCap);
    }

    function setStartTime(uint256 _time) external onlyOwner {
        start_time = _time;

        emit SetStartTime(_time);
    }

    function setEndTime(uint256 _time) external onlyOwner {
        end_time = _time;

        emit SetEndTime(_time);
    }

    function setpTokenPriceUSDC(uint256 _pTokenPrice) external onlyOwner {
        pTokenPrice_USDC = _pTokenPrice;

        emit SetpTokenPrice(_pTokenPrice, 1);
    }

    function setpTokenPriceAVAX(uint256 _pTokenPrice) external onlyOwner {
        pTokenPrice_AVAX = _pTokenPrice;

        emit SetpTokenPrice(_pTokenPrice, 0);
    }

    function setPresaleOwnerAddress(address _add) external onlyOwner {
        presaleOwnerAddress = payable(_add);

        emit SetPresaleOwnerAddress (_add);
    }

    event Presale(address _from, address _to, uint256 _amount);
    event SetMinCap(uint256 _amount);
    event SetMaxCap(uint256 _amount);
    event SetpTokenPrice(uint256 _price, uint _type);
    event SetPresaleOwnerAddress(address _add);
    event SetStartTime(uint256 _time);
    event SetEndTime(uint256 _time);

    receive() payable external {}

    fallback() payable external {}
}