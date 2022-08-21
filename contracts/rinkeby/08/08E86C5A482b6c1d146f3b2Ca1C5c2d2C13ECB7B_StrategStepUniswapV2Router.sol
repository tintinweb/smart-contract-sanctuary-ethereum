// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "../../interfaces/IStratStep.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/* solhint-disable */
contract StrategStepUniswapV2Router is IStratStep {

    struct Parameters {
        address router;
        uint256 tokenInPercent;
        address tokenIn;
        address[] intermediateToken;
        address tokenOut;
    }

    constructor() {
    }

    function enter(bytes calldata _parameters) external {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToSwap = IERC20(parameters.tokenIn).balanceOf(address(this)) * parameters.tokenInPercent / 100;

        IERC20(parameters.tokenIn).approve(address(parameters.router), amountToSwap);
        
        address[] memory path = new address[](2 + parameters.intermediateToken.length);
        path[0] = parameters.tokenIn;
        for (uint i = 0; i < parameters.intermediateToken.length; i++) {
            path[i + 1] = parameters.intermediateToken[i];
        }
        path[1 + parameters.intermediateToken.length] = parameters.tokenOut;

        IUniswapV2Router(parameters.router).swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function exit(bytes calldata _parameters) external {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToSwap = IERC20(parameters.tokenOut).balanceOf(address(this));

        IERC20(parameters.tokenIn).approve(address(parameters.router), amountToSwap);

        address[] memory path = new address[](2 + parameters.intermediateToken.length);
        uint256 intermediateTokenLength = parameters.intermediateToken.length;
        uint256 revertedIndex = intermediateTokenLength - 1;

        path[0] = parameters.tokenOut;
        for (uint i = 0; i < parameters.intermediateToken.length; i++) {
            path[i + 1] = parameters.intermediateToken[revertedIndex - i];
        }
        path[1 + parameters.intermediateToken.length] = parameters.tokenIn;

        IUniswapV2Router(parameters.router).swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function oracleEnter(IStratStep.OracleResponse memory _before, bytes memory _parameters) external view returns (OracleResponse memory) {

        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToSwap = _findTokenAmount(parameters.tokenIn, _before) * parameters.tokenInPercent / 100;
        
        address[] memory path = new address[](2 + parameters.intermediateToken.length);
        path[0] = parameters.tokenIn;
        for (uint i = 0; i < parameters.intermediateToken.length; i++) {
            path[i + 1] = parameters.intermediateToken[i];
        }
        path[1 + parameters.intermediateToken.length] = parameters.tokenOut;

        uint256[] memory amountsOut = IUniswapV2Router(parameters.router).getAmountsOut(amountToSwap, path);

        IStratStep.OracleResponse memory _after = _removeTokenAmount(parameters.tokenIn, amountToSwap, _before);
        _after = _addTokenAmount(parameters.tokenOut, amountsOut[amountsOut.length - 1], _after);
        
        return _after;
    }
    
    function oracleExit(IStratStep.OracleResponse memory _before, bytes memory _parameters) external view returns (OracleResponse memory) {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToSwap = _findTokenAmount(parameters.tokenOut, _before);
        
        address[] memory path = new address[](2 + parameters.intermediateToken.length);
        uint256 intermediateTokenLength = parameters.intermediateToken.length;
        uint256 revertedIndex = intermediateTokenLength - 1;

        path[0] = parameters.tokenOut;
        for (uint i = 0; i < parameters.intermediateToken.length; i++) {
            path[i + 1] = parameters.intermediateToken[revertedIndex - i];
        }
        path[1 + parameters.intermediateToken.length] = parameters.tokenIn;

        uint256[] memory amountsOut = IUniswapV2Router(parameters.router).getAmountsOut(amountToSwap, path);

        IStratStep.OracleResponse memory _after = _removeTokenAmount(parameters.tokenOut, amountToSwap, _before);
        _after = _addTokenAmount(parameters.tokenIn, amountsOut[amountsOut.length - 1], _after);
        
        return _after;
    }

    function _findTokenAmount(address _token, OracleResponse memory _res) internal pure returns (uint256) {
        for (uint i = 0; i < _res.tokens.length; i++) {
            if(_res.tokens[i] == _token) {
                return _res.tokensAmount[i];
            }
        }
        return 0;
    }

    function _addTokenAmount(address _token, uint256 _amount, OracleResponse memory _res) internal pure returns (IStratStep.OracleResponse memory) {
        for (uint i = 0; i < _res.tokens.length; i++) {
            if(_res.tokens[i] == _token) {
                _res.tokensAmount[i] += _amount;
                return _res;
            }
        }

        address[] memory newTokens = new address[](_res.tokens.length + 1);
        uint256[] memory newTokensAmount = new uint256[](_res.tokens.length + 1);

        for (uint i = 0; i < _res.tokens.length; i++) {
            newTokens[i] = _res.tokens[i];
            newTokensAmount[i] = _res.tokensAmount[i];
        }

        newTokens[_res.tokens.length] = _token;
        newTokensAmount[_res.tokens.length] = _amount;

        _res.tokens = newTokens;
        _res.tokensAmount = newTokensAmount;
        return _res;
    }

    function _removeTokenAmount(address _token, uint256 _amount, OracleResponse memory _res) internal pure returns (IStratStep.OracleResponse memory) {
        for (uint i = 0; i < _res.tokens.length; i++) {
            if(_res.tokens[i] == _token) {
                _res.tokensAmount[i] -= _amount;
                return _res;
            }
        }

        return _res;
    }
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface IStratStep {

    struct OracleResponse {
        address[] tokens;
        uint256[] tokensAmount;
    }


    function enter(bytes memory parameters) external;
    function exit(bytes memory parameters) external;

    function oracleEnter(OracleResponse memory previous, bytes memory parameters) external view returns (OracleResponse memory);
    function oracleExit(OracleResponse memory previous, bytes memory parameters) external view returns (OracleResponse memory);
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