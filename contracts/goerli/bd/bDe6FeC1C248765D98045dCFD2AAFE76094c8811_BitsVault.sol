// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract BitsVault is Ownable {
    IDexRouter public dexRouter;
    address public weth;
    address public tokenAddress;
    event TransferForeignToken(address token, uint256 amount);
    event tokenDepositComplete(address tokenAddress, uint256 amount);
    event approved(address tokenAddress, address sender, uint256 amount);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        address _dexRouter;
        _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        // initialize router
        dexRouter = IDexRouter(_dexRouter);
        weth = dexRouter.WETH();
        IERC20(tokenAddress).approve(
            address(this),
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        IERC20(weth).approve(
            address(this),
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    // userAddress => tokenAddress => token amount
    mapping(address => mapping(address => uint256)) userTokenBalance;

    receive() external payable {
        depositEth();
    }

    function depositToken(uint256 amount) public {
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= amount,
            "Your token amount must be greater then you are trying to deposit"
        );
        require(IERC20(tokenAddress).approve(address(this), amount));
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount)
        );

        userTokenBalance[msg.sender][tokenAddress] += amount;
        emit tokenDepositComplete(tokenAddress, amount);
    }

    event tokenWithdrawalComplete(address tokenAddress, uint256 amount);

    function depositEth() public payable {
        require(msg.value > 0, "You must send some ETH");
        userTokenBalance[msg.sender][weth] += msg.value;
    }

    function swapToToken(uint256 amount, address to) public {
        require(userTokenBalance[msg.sender][weth] >= amount);
        unchecked {
            userTokenBalance[msg.sender][weth] -= amount;
        }

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = tokenAddress;
        dexRouter.swapExactETHForTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function swapToEth(uint256 amount, address to) public {
        require(userTokenBalance[msg.sender][tokenAddress] >= amount);
        unchecked {
            userTokenBalance[msg.sender][tokenAddress] -= amount;
        }
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = weth;
        IERC20(tokenAddress).approve(address(dexRouter), amount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function withDrawAll() public {
        require(
            userTokenBalance[msg.sender][tokenAddress] > 0,
            "User doesnt has funds on this vault"
        );
        uint256 amount = userTokenBalance[msg.sender][tokenAddress];
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "the transfer failed"
        );
        userTokenBalance[msg.sender][tokenAddress] = 0;
        emit tokenWithdrawalComplete(tokenAddress, amount);
    }

    function withDrawAllETH() public {
        require(
            userTokenBalance[msg.sender][weth] > 0,
            "User doesnt has funds on this vault"
        );
        uint256 amount = userTokenBalance[msg.sender][weth];
        bool success;
        unchecked {
            userTokenBalance[msg.sender][weth] = 0;
        }

        (success, ) = address(msg.sender).call{value: amount}("");
        emit tokenWithdrawalComplete(weth, amount);
    }

    function withDrawAmount(uint256 amount) public {
        require(userTokenBalance[msg.sender][tokenAddress] >= amount);
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "the transfer failed"
        );
        userTokenBalance[msg.sender][tokenAddress] -= amount;
        emit tokenWithdrawalComplete(tokenAddress, amount);
    }

    function withDrawAmountETH(uint256 amount) public {
        require(userTokenBalance[msg.sender][weth] >= amount);
        bool success;
        unchecked {
            userTokenBalance[msg.sender][weth] -= amount;
        }

        (success, ) = address(msg.sender).call{value: amount}("");
        emit tokenWithdrawalComplete(weth, amount);
    }

    function updateToken(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function getUserBalance(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userTokenBalance[_userAddress][tokenAddress];
    }

    function getUserBalanceETH(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userTokenBalance[_userAddress][weth];
    }

    function getVaultBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getVaultETHbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = dexRouter.WETH();

        // approve token transfer to cover all possible scenarios
        IERC20(tokenAddress).approve(address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        userTokenBalance[msg.sender][weth] = 0;

        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);

        emit TransferForeignToken(_token, _contractBalance);
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