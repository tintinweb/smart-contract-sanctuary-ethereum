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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface WharfInterface {
    
    // event PayEth(address indexed from, uint256 amount, string orderId);
    // event WithdrawEth(address indexed to, uint256 amount, string billId);

    event PayERC20(address indexed from, uint256 amount, string orderId, address indexed tokenAddress);
    event WithdrawERC20(address indexed to, uint256 amount, string billId, address indexed tokenAddress);
    event RefundERC20(address indexed to, uint256 amount, string billId, address indexed tokenAddress);
    
    // orderId 中心化系统订单ID
    // function payEth(string calldata orderId) payable external;
    // amount 提现金额
    // billId 中心化系统结算ID
    // function withdrawEth(uint256 amount, string calldata billId) external;

    // from 支出钱包地址
    // amount 支出金额
    // orderId 中心化系统订单ID 发出事件需要
    // tokenAdress erc20 token 合约地址
    function payERC20(uint256 amount, string calldata orderId, address tokenAddress) external;
    function payERC20From(address from, uint256 amount, string calldata orderId, address tokenAddress) external;

    
    // amount 提现金额
    // currency erc20 合约地址
    // billId 中心化系统结算ID
    function withdrawERC20(uint256 amount, string calldata billId, address tokenAddress) external;

    // frome : 发起退款的账户
    // to : 退款地址
    // amount : 退款金额
    // billId : 账单 Id
    // tokenAdress erc20 token 合约地址
    function refundERC20(address to, uint256 amount, string calldata billId, address tokenAddress) external;
    function refundERC20From(address from, address to, uint256 amount, string calldata billId, address tokenAddress) external;
}

library BeeCheck {
    function containsKey(mapping(address => bool) storage aMap, address aKey) internal view returns (bool) {
        return aMap[aKey];
    }
}

contract BeeWharf is WharfInterface, Ownable {

    using BeeCheck for mapping (address => bool);
    // token address => support ?
    mapping (address => bool) private tokenSupported;
    // token address --> totalBalance ?
    mapping (address => uint256) private totalBalances;

    constructor () {
        // Ethereum USDT
        tokenSupported[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true;
        // Ethereum USDC
        tokenSupported[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true;
    }

    // 支持新的 token 支付
    function addNewSupportToken(address tokenAddress) external onlyOwner {
        if (tokenSupported.containsKey(tokenAddress) == false) {
            tokenSupported[tokenAddress] = true;
        }
    }

    function balanceOf(address tokenAddress) external view returns (uint256) {
        require(tokenSupported.containsKey(tokenAddress), "Unsurpported token!");
        return totalBalances[tokenAddress];
    }

    // from 支出钱包地址
    // amount 支出金额
    // orderId 中心化系统订单ID 发出事件需要
    // currency erc20 合约地址
    function payERC20(
        uint256 amount, 
        string calldata orderId, 
        address tokenAddress
        ) external {
        this.payERC20From(msg.sender, amount, orderId, tokenAddress);
    }

    function payERC20From(
        address from, 
        uint256 amount, 
        string calldata orderId, 
        address tokenAddress
        ) external {
        require(tokenSupported.containsKey(tokenAddress), "Unsurpported token!");
        require(IERC20(tokenAddress).balanceOf(from) >= amount, "Insufficient balance funds");
        require(IERC20(tokenAddress).transferFrom(from, address(this), amount));
        totalBalances[tokenAddress] += amount;
        emit PayERC20(from, amount, orderId, tokenAddress);
    }

    function withdrawERC20(
        uint256 amount, 
        string calldata billId,
        address tokenAddress
        ) external onlyOwner {
        require(tokenSupported.containsKey(tokenAddress), "Not supported token");
        require(totalBalances[tokenAddress] >= amount, 'Insufficient funds');
        require(IERC20(tokenAddress).transfer(msg.sender, amount));
        totalBalances[tokenAddress] -= amount;
        emit WithdrawERC20(msg.sender, amount, billId, tokenAddress);
    }

    function refundERC20(
        address to, 
        uint256 amount, 
        string calldata billId, 
        address tokenAddress
        ) external onlyOwner {
        this.refundERC20From(address(this), to, amount, billId, tokenAddress);
    }

    function refundERC20From(
        address from, 
        address to, 
        uint256 amount, 
        string calldata billId, 
        address tokenAddress
        ) external onlyOwner {
        require(tokenSupported.containsKey(tokenAddress), "Unsurpported token!");
        require(IERC20(tokenAddress).balanceOf(from) >= amount, "Insufficient balance funds");
        require(IERC20(tokenAddress).transferFrom(from, to, amount));
        if (from == address(this)) {
            totalBalances[tokenAddress] -= amount;
        }
        emit RefundERC20(to, amount, billId, tokenAddress);
    }

}