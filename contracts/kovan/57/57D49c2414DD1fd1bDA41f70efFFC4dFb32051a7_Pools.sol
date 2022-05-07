// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";
import "KayiUniswap.sol";

contract Pools is KayiUniswap {
    address[] public allowedTokens;

    mapping(address => mapping(address => uint256)) public userBalance;
    mapping(address => address) public realTokenToTestnetAaveToken;

    constructor(address _daiTokenAddress, address _aaveTestnetDaiTokenAddress) {
        allowedTokens.push(_daiTokenAddress);
        realTokenToTestnetAaveToken[_daiTokenAddress] = _aaveTestnetDaiTokenAddress;
    }

    function depositTokens(uint256 _amount, address _token) public {
        require(_amount >= 1 ether, "Amount must be at least 1");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        userBalance[_token][msg.sender] += _amount;
        _swap(
            _token,
            realTokenToTestnetAaveToken[_token],
            _amount,
            _getAmountOutMin(_token, realTokenToTestnetAaveToken[_token], _amount),
            address(this)
        );
    }

    function withdrawTokens(uint256 _amount, address _token) public {
        require(_amount >= 1 ether, "Amount must be at least 1");
        require(
            userBalance[_token][msg.sender] >= _amount,
            "Amount must be less than or equal to the staking balance"
        );
        _swap(
            realTokenToTestnetAaveToken[_token],
            _token,
            _getAmountOutMin(_token, realTokenToTestnetAaveToken[_token], _amount),
            _getAmountOutMin(realTokenToTestnetAaveToken[_token], _token, _amount),
            address(this)
        );
        IERC20(_token).transfer(msg.sender, _amount);
        userBalance[_token][msg.sender] -= _amount;
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

pragma solidity 0.8.13;

import "IERC20.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router.sol";

contract KayiUniswap {
    address private UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal {
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    function _getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256) {
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}