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
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUniswapRouterV3 {
    function refundETH() external payable;
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

pragma solidity 0.8.17;

interface IUniswapV2Pair {
    function token0() external view returns(address);
    function getReserves() external view returns(uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapRouterV3.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./Ownable.sol";


contract UniswapConnector is Ownable {
    address public wethAddress;
    address public uniswapV3Router02;
    address[] public routers; // storing V3 router address or V2 pairs addresses
    mapping(address => Token) public tokens;

    struct Token {
        uint8 router; // UniswapV2Pair or any other V2 fork pairs
        uint24 fee;
    }

    constructor(
        address _wethAddress,
        address _uniswapV3Router02
    ) {
        wethAddress = _wethAddress;
        uniswapV3Router02 = _uniswapV3Router02;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) private pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997; // V2 fee is 0.3%
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        uint256 amountOut = numerator / denominator;
        return amountOut;
    }

    function getTokenFee(address _token) external view returns(uint24) {
        return tokens[_token].fee;
    }

    function setRoutersOrPairs(address[] calldata _address) external onlyOwner {
        routers = _address;
    }

    function setToken(address _token, uint8 _routerIndex, uint24 _fee) external onlyOwner {
        require(routers[_routerIndex] != address(0), "ERR: INVALID_ROUTER");

        Token memory token = Token({
            router: _routerIndex, 
            fee: _fee
        });
        tokens[_token] = token; 
    }

    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256) {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amount); 
        
        if (routers[tokens[_tokenIn].router] != uniswapV3Router02) {
            uint256 amountOut;
            if (_tokenOut == wethAddress) {
                amountOut = _swapV2(routers[tokens[_tokenIn].router], _tokenIn, _amount, _to);
                require(amountOut >= _amountOutMin, "ERR: amountOutMin");
                return amountOut;
            } else {
                amountOut = _swapV2(routers[tokens[_tokenIn].router], _tokenIn, _amount, address(this));
                // Supporting both V2 => V2 and V2 => V3
                return swapETHForToken(_tokenOut, amountOut, _amountOutMin, _to);
            }
        } else {
            bytes memory path;
            if (_tokenOut == wethAddress) {
                path = abi.encodePacked(_tokenIn, tokens[_tokenIn].fee, wethAddress);
            } else {
                if(_tokenIn==wethAddress){
                    path = abi.encodePacked(wethAddress, tokens[_tokenOut].fee, _tokenOut);
                }else{
                    path = abi.encodePacked(_tokenIn, tokens[_tokenIn].fee, wethAddress, tokens[_tokenOut].fee, _tokenOut);
                }
            }
            return _swapV3(path, _tokenIn, _amount, _amountOutMin, _to);
        }
    }

    function swapTokenForTokenV3ExactOutput(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountInMaximum, address _to) external payable returns(uint256) {
        bytes memory path;
        bool msgValue = false;
        if (msg.value != 0) {
            msgValue = true;
        } else {
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountInMaximum); 
        }

        // in ExactOutput the path is reversed
        if (_tokenIn == wethAddress) {
            path = abi.encodePacked(_tokenOut, tokens[_tokenOut].fee, wethAddress);
        } else if (_tokenOut == wethAddress) {
            path = abi.encodePacked(wethAddress, tokens[_tokenIn].fee, _tokenIn);
        } else {
            path = abi.encodePacked(_tokenOut, tokens[_tokenOut].fee, wethAddress, tokens[_tokenIn].fee, _tokenIn);
        }
        return _swapV3ExactOutput(path, _tokenIn, _amount, _amountInMaximum, _to, msgValue);
    }

    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) public payable returns(uint256) {
        uint256 swapAmount;
        if (msg.value != 0) {
            swapAmount = msg.value;
            (bool success, ) = payable(wethAddress).call{value: msg.value}("");
            require(success, "ERR: FAIL_SENDING_ETH");
        } else {
            require(_amount > 0, "ERR: INVALID_AMOUNT");
            swapAmount = _amount;
        }

        if (routers[tokens[_tokenOut].router] != uniswapV3Router02) {
            uint256 amountOut = _swapV2(routers[tokens[_tokenOut].router], wethAddress, swapAmount, _to);
            require(amountOut >= _amountOutMin, "ERR: amountOutMin");
            
            return amountOut;
        } else {
            bytes memory path = abi.encodePacked(wethAddress, tokens[_tokenOut].fee, _tokenOut);
            return _swapV3(path, wethAddress, swapAmount, _amountOutMin, _to);
        }
    }

    function _swapV2(address _router, address _tokenIn, uint256 _amount, address _to) public returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_router);
        IERC20(_tokenIn).transfer(_router, _amount);

        (uint256 token0Bal, uint256 token1Bal, ) = pair.getReserves();
        uint256 amountOut;
        if (_tokenIn == pair.token0()) {
            amountOut = getAmountOut(_amount, token0Bal, token1Bal);
            pair.swap(0, amountOut, _to, "");
        } else {
            amountOut = getAmountOut(_amount, token1Bal, token0Bal);
            pair.swap(amountOut, 0, _to, "");
        }
        require(amountOut > 0, 'ERR: INVALID_V2_SWAP');

        return amountOut;
    }

    function _swapV3(bytes memory _path, address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) public returns(uint256) {
        if (IERC20(_tokenIn).allowance(address(this), uniswapV3Router02) == 0) {
            IERC20(_tokenIn).approve(uniswapV3Router02, 2**256 - 1); 
        }

        IUniswapRouterV3.ExactInputParams memory params = IUniswapRouterV3.ExactInputParams({
            path: _path,
            recipient: _to,
            amountIn: _amount,
            amountOutMinimum: _amountOutMin
        });
        uint256 swapResult = IUniswapRouterV3(uniswapV3Router02).exactInput(params);
        require(swapResult > 0, 'ERR: INVALID_V3_SWAP');

        return swapResult;
    }

    function _swapV3ExactOutput(bytes memory _path, address _tokenIn, uint256 _amount, uint256 _amountInMaximum, address _to, bool msgValue) private returns(uint256) {
        if (IERC20(_tokenIn).allowance(address(this), uniswapV3Router02) == 0) {
            IERC20(_tokenIn).approve(uniswapV3Router02, 2**256 - 1); 
        }

        IUniswapRouterV3.ExactOutputParams memory params = IUniswapRouterV3.ExactOutputParams({
            path: _path,
            recipient: _to,
            amountOut: _amount,
            amountInMaximum: _amountInMaximum
        });

        if (msgValue) {
            uint256 swapResult = IUniswapRouterV3(uniswapV3Router02).exactOutput{value: _amountInMaximum}(params);
            // refunding unused ETH back to proxy
            IUniswapRouterV3(uniswapV3Router02).refundETH();

            (bool success, ) = payable(_to).call{value: address(this).balance}("");
            require(success, "ERR: FAIL_SENDING_ETH");

            return swapResult;
        } else {
            uint256 swapResult = IUniswapRouterV3(uniswapV3Router02).exactOutput(params);
            // refunding unused tokens back to proxy
            if (swapResult < _amountInMaximum) {
                IERC20(_tokenIn).transfer(_to, _amountInMaximum - swapResult);
            }
            return swapResult;
        }
    }

    receive() external payable {} 
    fallback() external payable {}
}