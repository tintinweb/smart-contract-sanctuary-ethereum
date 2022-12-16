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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IAjnaPool.sol";

contract AjnaPoc is Ownable{

    address collateralToken;
    address debtToken; 
    address pool;

    constructor(address _collateral, address _token, address _pool) {
        collateralToken = _collateral;
        debtToken = _token;
        pool = _pool;
    }

    function drawTokens(address token, uint256 amount) public onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }

    function depositCollateral(uint256 amount) public onlyOwner{
        IERC20(collateralToken).approve(pool, amount);
        IAnjaPool(pool).drawDebt(msg.sender, 0,  0/*WTF IS THAT*/, amount);
    }

    function withdrawCollateral(uint256 amount) public onlyOwner{
        IAnjaPool(pool).repayDebt(msg.sender, 0, amount);
    }

    function drawDebt(uint256 amount) public onlyOwner{
        IAnjaPool(pool).drawDebt(msg.sender, amount, 0/*WTF IS THAT*/, 0);
    }

    function repayDebt(uint256 amount) public onlyOwner{
        IERC20(collateralToken).approve(pool, amount);
        IAnjaPool(pool).drawDebt(msg.sender, amount, 0/*WTF IS THAT*/, 0);
    }

//price - price of uint (10**decimals) collateral token in debt token (10**decimals) with 3 decimal points for instance
// 1WBTC = 16,990.23 USDC   translates to: 16990230
    function supplyQuote(uint256 amount, uint256 price) public onlyOwner{
        IERC20(collateralToken).approve(pool, amount);
        uint256 index_ = convertPriceToIndex(price, IERC20Metadata(collateralToken).decimals(), IERC20Metadata(debtToken).decimals());
        IAnjaPool(pool).addCollateral(amount, index_);
    }

//price - price of uint (10**decimals) collateral token in debt token (10**decimals) with 3 decimal points for instance
// 1WBTC = 16,990.23 USDC   translates to: 16990230
    function withdrawQuote(uint256 amount, uint256 price) public onlyOwner{
        uint256 index_ = convertPriceToIndex(price, IERC20Metadata(collateralToken).decimals(), IERC20Metadata(debtToken).decimals());
        IAnjaPool(pool).removeCollateral(amount, index_);
    }

    function moveQuote(uint256 amount, uint256 price, uint256 newPrice) public onlyOwner{
        withdrawQuote(amount, price);
        supplyQuote(amount, newPrice);
    }

    function openAndDraw(uint256 debtAmount, uint256 collateralAmount) public onlyOwner{

        IERC20(collateralToken).approve(pool, collateralAmount);
        IAnjaPool(pool).drawDebt(msg.sender, debtAmount,  0/*WTF IS THAT*/, collateralAmount);
    }

    function convertPriceToIndex(uint256 price, uint256 collateralDecimals, uint256 debtDecimals) public pure returns(uint256){
        //TODO: implement
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IAnjaPool {
    
    function collateralScale() external pure returns (uint256);

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    function drawDebt(
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external;

    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_
    ) external;


    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    function addCollateral(
        uint256 collateralAmountToAdd_,
        uint256 index_
    ) external returns (uint256 bucketLPs_) ;

    function removeCollateral(
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256 collateralAmount_, uint256 lpAmount_);

}