/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/SwapProxy.sol

pragma solidity 0.8.19;


//SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address user) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function approve(address spender, uint256 amount) external;

    function deposit() external payable;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function allowance(address user, address spender)
        external
        view
        returns (uint256);
}


contract SwapProxy is Ownable {
    uint256 public constant DIVISOR = 10000;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable router;

    constructor(address router_) {
        router = router_;
    }

    event Swap(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeAmt
    );

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 fee,
        address feeCollector,
        bytes calldata data
    ) public payable returns (bytes memory) {
        bool s1;
        if (msg.value == 0) {
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
            IERC20(tokenIn).approve(router, amount);
        }
        (bool s2, bytes memory returnData) = router.call{value:msg.value}(
            data
        );
        require(s2, "E2");
        uint256 balance;
        uint256 feeAmt;
        if (address(this).balance > 0) {
            balance=address(this).balance;
            feeAmt = (balance * fee) / DIVISOR;
            (s1, ) = feeCollector.call{value: feeAmt}("");
            require(s1, "E3");
            (s1, ) = msg.sender.call{value: balance - feeAmt}("");
            require(s1, "E4");
        } else {
            balance = IERC20(tokenOut).balanceOf(address(this));
            feeAmt = (balance * fee) / DIVISOR;
            IERC20(tokenOut).transfer(feeCollector, feeAmt);
            IERC20(tokenOut).transfer(msg.sender, balance - feeAmt);
        }
        emit Swap(msg.sender, tokenIn, tokenOut, amount, balance, feeAmt);
        return returnData;
    }

    function emergencyWithdraw(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = payable(owner()).call{
                value: address(this).balance
            }("");
            require(success);
        } else {
            IERC20(token).transfer(
                owner(),
                IERC20(token).balanceOf(address(this))
            );
        }
    }
    receive() external payable {}

}