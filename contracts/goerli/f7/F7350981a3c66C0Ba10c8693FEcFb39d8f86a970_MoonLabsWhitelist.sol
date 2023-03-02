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

// SPDX-License-Identifier: MI

pragma solidity ^0.8.0;

interface IDEXRouter {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

  function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
 * ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ ███████╗
 * ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗██╔════╝
 * ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝███████╗
 * ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗╚════██║
 * ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝███████║
 * ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
 *
 * Moon Labs LLC reserves all rights on this code.
 * You may not, except otherwise with prior permission and express written consent by Moon Labs LLC, copy, download, print, extract, exploit,
 * adapt, edit, modify, republish, reproduce, rebroadcast, duplicate, distribute, or publicly display any of the content, information, or material
 * on this smart contract for non-personal or commercial purposes, except for any other use as permitted by the applicable copyright law.
 *
 * This is for ERC20 tokens and should NOT be used for Uniswap LP tokens or ANY other token protocol.
 *
 * Website: https://www.moonlabs.site/
 */

/**
 * @title This is a contract used for creating whitelists for Moon Labs products
 * @author Moon Labs LLC
 * @notice  This contract's intended purpose is for users to purchase whitelists for their desired tokens. Whitelisting a token allows for all fees on
 * related Moon Labs products to be waived. Whitelists may not be transferred from token to token.
 */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDEXRouter.sol";

interface IMoonLabsReferral {
  function checkIfActive(string calldata code) external view returns (bool);

  function getAddressByCode(string memory code) external view returns (address);

  function addRewardsEarnedUSD(string calldata code, uint commission) external;
}

interface IMoonLabsWhitelist {
  function getIsWhitelisted(address _address) external view returns (bool);
}

contract MoonLabsWhitelist is IMoonLabsWhitelist, Ownable {
  constructor(address _usdAddress, uint _costUSD) {
    usdAddress = _usdAddress;
    costUSD = _costUSD;
    usdContract = IERC20(_usdAddress);
  }

  /*|| === STATE VARIABLES === ||*/
  uint public nonce; /// Number of tokens whitelisted
  uint public costUSD; /// Cost in USD
  address public usdAddress; /// Address of desired USD token
  uint32 public codeDiscount; /// Discount in the percentage applied to the customer when using referral code, represented in 10s
  uint32 public codeCommission; /// Percentage of each lock purchase sent to referral code owner, represented in 10s
  IERC20 public usdContract; /// Select USD contract
  IMoonLabsReferral public referralContract; /// Moon Labs referral contract

  /*|| === MAPPINGS === ||*/
  mapping(address => bool) tokenToWhitelist;

  /*|| === EXTERNAL FUNCTIONS === ||*/
  /**
   * @notice Purchase a whitelist for a single token.
   * @param _address Token address to be whitelisted
   */
  function purchaseWhitelist(address _address) external {
    require(!getIsWhitelisted(_address), "Token already whitelisted");
    require(usdContract.balanceOf(msg.sender) >= costUSD, "Insignificant balance");

    usdContract.transferFrom(msg.sender, address(this), costUSD);
    /// Add token to global whitelist
    tokenToWhitelist[_address] = true;
  }

  /**
   * @notice Purchase a whitelist for a single token using a referral code.
   * @param _address Token address to be whitelisted
   * @param code Referral code
   */
  function purchaseWhitelistWithCode(address _address, string calldata code) external {
    require(!getIsWhitelisted(_address), "Token already whitelisted");
    /// Check for referral valid code
    require(referralContract.checkIfActive(code), "Invalid code");
    /// Check for significant balance
    require(usdContract.balanceOf(msg.sender) >= costUSD - (costUSD * codeDiscount) / 100, "Insignificant balance");
    usdContract.transferFrom(msg.sender, address(this), (costUSD * codeDiscount) / 100);
    /// Distribute commission
    distributeCommission(code, (costUSD * codeCommission) / 100);
    /// Add token to global whitelist
    tokenToWhitelist[_address] = true;
  }

  /**
   * @notice Add to whitelist without fee, onlyOwner function.
   * @param _address Token address to be whitelisted
   */
  function ownerWhitelistAdd(address _address) external onlyOwner {
    /// Add token to global whitelist
    tokenToWhitelist[_address] = true;
  }

  /**
   * @notice Remove from whitelist, onlyOwner function.
   * @param _address Token address to be removed from whitelist
   */
  function ownerWhitelistRemove(address _address) external onlyOwner {
    /// Add token to global whitelist
    tokenToWhitelist[_address] = false;
  }

  /**
   * @notice Send all eth in contract to caller.
   */
  function claimETH() external onlyOwner {
    (bool sent, ) = payable(msg.sender).call{ value: address(this).balance }("");
    require(sent, "Failed to send Ether");
  }

  /**
   * @notice Send all USD in contract to caller.
   */
  function claimUSD() external onlyOwner {
    usdContract.transferFrom(address(this), msg.sender, usdContract.balanceOf(address(this)));
  }

  /*|| === PUBLIC FUNCTIONS === ||*/
  /**
   * @notice Check to see if a token is whitelisted.
   * @param _address Token address to check if whitelisted
   */
  function getIsWhitelisted(address _address) public view override returns (bool) {
    if (tokenToWhitelist[_address]) return true;
    return false;
  }

  /*|| === PRIVATE FUNCTIONS === ||*/
  /**
   * @notice Distribute commission to referral code owner.
   * @param code Referral code used
   * @param commission Amount in USD tokens to be distributed
   */
  function distributeCommission(string calldata code, uint commission) private {
    /// Send USD to referral code owner
    usdContract.transfer(referralContract.getAddressByCode(code), commission);
    /// Log rewards in the referral contract
    referralContract.addRewardsEarnedUSD(code, commission);
  }
}