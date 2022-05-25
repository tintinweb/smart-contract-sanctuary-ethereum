// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStrategy.sol";

contract RebalancingStrategyV1 is IStrategy, Ownable {

    IERC20 internal depositToken;
    IERC20 internal investToken;

    uint public maxPriceAge = 6 * 60 * 60; // use prices old 6h max (in Kovan prices are updated every few hours)
    uint public targetInvestPerc;
    uint public rebalancingThreshold;
    address poolAddress;

    constructor(address _depositTokenAddress, address _investTokenAddress, uint _targetInvestPerc, uint _rebalancingThreshold) public {
        depositToken = IERC20(_depositTokenAddress);
        investToken = IERC20(_investTokenAddress);
        targetInvestPerc = _targetInvestPerc;
        rebalancingThreshold = _rebalancingThreshold;
    }

    function setPoolAddress(address _poolAddress) public onlyOwner {
        require(poolAddress == address(0), "Pool address alreadt set");
        poolAddress = _poolAddress;
    }

    function setMaxPriceAge(uint secs) public onlyOwner {
        maxPriceAge = secs;
    }

    function name() public override view returns(string memory _) {
        return "RebalancingStrategyV1";
    }

    function description() public override view returns(string memory _) {
        return "A simple rebalancing strategy";
    }

    function evaluate(int investTokenPrice, uint time) public override view returns(StrategyAction action, uint amountIn) {

        require(investTokenPrice >= 0, "Price is negative");
        require(poolAddress != address(0), "poolAddress is 0");

        // don't use old prices
        if (block.timestamp > time && (block.timestamp - time) > maxPriceAge) return (StrategyAction.NONE, 0);

        uint price = uint(investTokenPrice);

        uint256 depositTokenBalance = depositToken.balanceOf(poolAddress);
        uint256 investTokenBalance = investToken.balanceOf(poolAddress);

        uint depositTokenValue = depositTokenBalance;
        uint investTokenValue = investTokenBalance * price;
        uint poolValue = investTokenValue + depositTokenValue;

        action = StrategyAction.NONE;
        uint investPerc = (100 * investTokenValue / poolValue);

        if (investPerc > targetInvestPerc) {
            // delta := 85 - 60
            uint deltaPerc = investPerc - targetInvestPerc;
            if (deltaPerc >= rebalancingThreshold) {   // 25%
                // need to sell some investment tokens for deposit tokens
                // calcualte amount of investment tokens to SWAP
                action = StrategyAction.SELL;
                uint targetInvestTokenValue = poolValue * targetInvestPerc / 100;
                amountIn = (investTokenValue - targetInvestTokenValue) / price;
            }
        } else {
            uint targetDepositPerc = 100 - targetInvestPerc;
            uint depositPerc = (100 * depositTokenValue / poolValue);
            uint deltaPerc = depositPerc - targetDepositPerc;
            if (deltaPerc >= rebalancingThreshold) {    // 25%
                // need to sell some deposit tokens for invest tokens
                // calculate amount of deposit tokens to SWAP
                action = StrategyAction.BUY;
                uint targetDepositValue = poolValue * targetDepositPerc / 100;
                amountIn = depositTokenValue - targetDepositValue;
            }
        }

        return (action, amountIn);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

enum StrategyAction { BUY, SELL, NONE }

interface IStrategy {

    function description() external view returns(string memory _);
    function name() external view returns(string memory _);

    function evaluate(int price, uint time) external view returns(StrategyAction action, uint amount);

}