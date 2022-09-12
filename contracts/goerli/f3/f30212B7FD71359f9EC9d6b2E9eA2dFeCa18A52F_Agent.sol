//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IPair.sol";
import "./interfaces/IAgent.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";
import "./uniswap/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Agent is Ownable, IAgent {
    IRouter public immutable ROUTER;
    IFactory public immutable FACTORY;

    address public token;
    address public WETH;
    address public pair;
    uint256 public liquidityStock;
    uint256 public threshold;

    constructor(address _router, uint256 _threshold) {
        require(_threshold >= 100, "Low threshold");
        ROUTER = IRouter(_router);
        FACTORY = IFactory(IRouter(_router).factory());
        threshold = _threshold;
    }

    function initialize(address _token, address _WETH) external onlyOwner {
        require(_token != address(0) && token == address(0));
        require(_WETH != address(0) && WETH == address(0));
        token = _token;
        WETH = _WETH;
        if (FACTORY.getPair(token, WETH) == address(0)) {
            FACTORY.createPair(token, WETH);
        }
        pair = FACTORY.getPair(token, WETH);
    }

    function changeThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 100, "Low threshold");
        threshold = _threshold;
    }

    function withdrawTokens(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (token == _token) balance -= liquidityStock;
        if (balance > 0) TransferHelper.safeTransfer(token, owner(), balance);
    }

    function increaseStock(uint256 amount) external override {
        require(_msgSender() == token, "Only Token");
        liquidityStock += amount;
    }

    function autoLiquidity() external override {
        if (_msgSender() != token)
            require(liquidityStock >= threshold, "Low liquidity stock");
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        if (_pairExisting(path)) {
            IERC20(token).approve(address(ROUTER), liquidityStock);
            (uint256 reserve0, uint256 reserve1, ) = IPair(pair).getReserves();
            uint256 half = getOptimalAmountToSell(
                int256(token == IPair(pair).token0() ? reserve0 : reserve1),
                int256(liquidityStock)
            );
            uint256 anotherHalf = liquidityStock - half;
            uint256 WETHAmount = _swapTokensForTokens(half);
            if (WETHAmount != 0) {
                IERC20(WETH).approve(address(ROUTER), WETHAmount);
                anotherHalf = _addLiquidity(anotherHalf, WETHAmount);
                liquidityStock -= (anotherHalf + half);
            }
        }
    }

    function getStock() external view override returns (uint256) {
        return liquidityStock;
    }

    function getThreshold() external view override returns (uint256) {
        return threshold;
    }

    function _addLiquidity(uint256 amount0, uint256 amount1)
        internal
        returns (uint256 amount)
    {
        (amount, , ) = ROUTER.addLiquidity(
            token,
            WETH,
            amount0,
            amount1,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _swapTokensForTokens(uint256 tokenAmount)
        internal
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        try
            ROUTER.swapExactTokensForTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            return amounts[1];
        } catch {
            return 0;
        }
        // uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
        //     tokenAmount,
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );
        // return amounts[1];
    }

    function _pairExisting(address[] memory path) internal view returns (bool) {
        uint8 len = uint8(path.length);

        address _pair;
        uint256 reserve0;
        uint256 reserve1;

        for (uint8 i; i < len - 1; i++) {
            _pair = FACTORY.getPair(path[i], path[i + 1]);
            if (_pair != address(0)) {
                (reserve0, reserve1, ) = IPair(_pair).getReserves();
                if ((reserve0 == 0 || reserve1 == 0)) return false;
            } else {
                return false;
            }
        }

        return true;
    }

    function getOptimalAmountToSell(int256 X, int256 dX)
        private
        pure
        returns (uint256)
    {
        int256 feeDenom = 1000000;
        int256 f = 997000; // 1 - fee
        unchecked {
            int256 T1 = X * (X * (feeDenom + f)**2 + 4 * feeDenom * dX * f);

            // square root
            int256 z = (T1 + 1) / 2;
            int256 sqrtT1 = T1;
            while (z < sqrtT1) {
                sqrtT1 = z;
                z = (T1 / z + z) / 2;
            }

            return
                uint256(
                    (2 * feeDenom * dX * X) / (sqrtT1 + X * (feeDenom + f))
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgent {
    function increaseStock(uint256 amount) external;

    function autoLiquidity() external;

    function getStock() external view returns (uint256);

    function getThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {

    function factory() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
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