/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        // Fronthand Backhand custom contract. copypasta devs better brass up.
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Factory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract arbBot is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public master;
    address WETH =  //0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;//FTM
                    0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a;//ONE
                    //0x98878B06940aE243284CA214f92Bb71a2b032B8A;//MOVR

    mapping (uint256 => address) _stableNo;

    mapping (address => bool) _isRouter;
    mapping (address => string) _routerName;
    mapping (string => routerDetails) routerData;
    address[] routerDetails_routerData;
    
    struct routerDetails {
        string routerName;
        address routerAddress;
        address routerCA;
        address routerFactory;
    }

    constructor() {
        master = msg.sender;
    }

    // ACTIVE FUNCTIONS
    
    function storeRouter(address router, string memory rName) public onlyOwner {
        routerDetails storage info = routerData[rName];
            info.routerName = rName;
            info.routerAddress = router;
            info.routerCA = router;
        address factory = IUniswapV2Router02(router).factory();
            info.routerFactory = factory;
    }

        function everybodyBreakdance(
            address _router1, 
            address _router2,
            address music, 
            address dancePartner, 
            uint256 _amount, 
            uint256 decimals,
            bool takeProfit
                ) external onlyOwner {
            uint spotOne = IERC20(music).balanceOf(address(this));
            uint spotTwo = IERC20(dancePartner).balanceOf(address(this));
            uint256 val = _amount.mul(10 ** decimals);
            swingLow(_router1, music, dancePartner, val);

            uint spotTwoTwo = IERC20(dancePartner).balanceOf(address(this));
            uint swingVal = spotTwoTwo - spotTwo;
            swingLow(_router2, dancePartner, music, swingVal);

            uint spotOneTwo = IERC20(music).balanceOf(address(this));
            require(spotOneTwo >= spotOne, "Done messed up AyAyron");

            if(takeProfit == true) {
                uint256 profit = spotOneTwo.sub(spotOne);
                IERC20(music).transfer(master, profit);
            }
        }

        function compoundingYeets(
            address _router1,
            address _router2,
            address swinger
                ) public onlyOwner {
            uint256 spotOne = IERC20(WETH).balanceOf(address(this));
            uint256 spotTwo = IERC20(swinger).balanceOf(address(this));
            swingLow(_router1, WETH, swinger, spotOne);

            uint256 spotTwoTwo = IERC20(swinger).balanceOf(address(this));
            uint256 swingVal = spotTwoTwo.sub(spotTwo);
            swingLow(_router2, swinger, WETH, swingVal);

            uint256 spotOneTwo = IERC20(WETH).balanceOf(address(this));
            require(spotOneTwo >= spotOne, "Done messed up AyAyron");
        }

        function everybodyBreakdancebutWithTechno(
            string memory _router1, 
            string memory _router2, 
            address dancePartner, 
            uint256 _amount, 
            bool takeProfit
                ) external {
            routerDetails memory info1 = routerData[_router1];
                address rout1 = info1.routerAddress;
            routerDetails memory info2 = routerData[_router2];
                address rout2 = info2.routerAddress;

            uint256 spotOne = IERC20(WETH).balanceOf(address(this));
            uint256 spotTwo = IERC20(dancePartner).balanceOf(address(this));
            uint256 wVal = _amount.mul(10 ** 18);

            swingLow(rout1, WETH, dancePartner, wVal);

            uint spotTwoTwo = IERC20(dancePartner).balanceOf(address(this));
            uint tradeableAmount = spotTwoTwo - spotTwo;

            swingLow(rout2, dancePartner, WETH, tradeableAmount);

            uint endBalance = IERC20(WETH).balanceOf(address(this));
            require(endBalance > spotOne, "Trade Reverted, No Profit Made");

            if(takeProfit == true) {
                uint256 profit = endBalance.sub(spotOne);
                IERC20(WETH).transfer(master, profit);
            }
        }

        function threePartTango(
            address _router1, 
            address _router2,
            address _router3,
            address music, 
            address cutIn,
            address dancePartner, 
            uint256 _amount, 
            uint256 decimals
                ) external onlyOwner {
            uint256 spotOne = IERC20(music).balanceOf(address(this));
            uint256 spotTwo = IERC20(cutIn).balanceOf(address(this));
            uint256 spotThree = IERC20(dancePartner).balanceOf(address(this));
            uint256 aVal = _amount.mul(10 ** decimals);
            swingLow(_router1, music, cutIn, aVal);

            uint256 spotTwoTwo = IERC20(cutIn).balanceOf(address(this));
            uint256 swingVal = spotTwoTwo.sub(spotTwo);
            swingLow(_router2, cutIn, dancePartner, swingVal);

            uint256 spotThreeTwo = IERC20(dancePartner).balanceOf(address(this));
            uint256 swingVal2 = spotThreeTwo.sub(spotThree);
            swingLow(_router3, dancePartner, music, swingVal2);

            uint endBalance = IERC20(music).balanceOf(address(this));
            require(endBalance > spotOne, "Trade Reverted, No Profit Made");
        }

        function threePartYeet(
            address _router1, 
            address _router2,
            address _router3,
            address cutIn,
            address dancePartner
                ) external onlyOwner {
            uint256 spotOne = IERC20(WETH).balanceOf(address(this));
            uint256 spotTwo = IERC20(cutIn).balanceOf(address(this));
            uint256 spotThree = IERC20(dancePartner).balanceOf(address(this));
            uint256 aVal = IERC20(WETH).balanceOf(address(this));
            swingLow(_router1, WETH, cutIn, aVal);

            uint256 spotTwoTwo = IERC20(cutIn).balanceOf(address(this));
            uint256 swingVal = spotTwoTwo.sub(spotTwo);
            swingLow(_router2, cutIn, dancePartner, swingVal);

            uint256 spotThreeTwo = IERC20(dancePartner).balanceOf(address(this));
            uint256 swingVal2 = spotThreeTwo.sub(spotThree);
            swingLow(_router3, dancePartner, WETH, swingVal2);

            uint endBalance = IERC20(WETH).balanceOf(address(this));
            require(endBalance > spotOne, "Trade Reverted, No Profit Made");
        }

        function gibsNuggies() external onlyOwner {
            payable(msg.sender).transfer(address(this).balance);
        }

        function gibsTendies(address tendies) external onlyOwner {
            IERC20(tendies).transfer(
                msg.sender, 
                IERC20(tendies).balanceOf(address(this)));
        }


    // INTERNAL FUNCTIONS

        function swingLow(
            address router, 
            address _tokenIn, 
            address _tokenOut, 
            uint256 _amount
                ) internal {
                    if(IERC20(_tokenIn).allowance(address(this), router) < 1) {
                        uint256 aVal = IERC20(_tokenIn).totalSupply();
                        IERC20(_tokenIn).approve(router, aVal); }
            address[] memory path;
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
            //uint deadline = block.timestamp + 5;
            IUniswapV2Router02(router).swapExactTokensForTokens(
                _amount, 
                0, 
                path, 
                address(this), 
                block.timestamp);
        }

        function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
            address[] memory path;
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
            uint256[] memory amountOutMins = IUniswapV2Router02(router).getAmountsOut(_amount, path);
            return amountOutMins[path.length -1];
        }

    // VIEW FUCKTIONS

        function estimateDualDexTrade(
            address _router1, 
            address _router2, 
            address _token1, 
            address _token2, 
            uint256 _amount
                ) external view returns (uint256) {
            uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
            uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
                return amtBack2;
        }
                    
        function estimateTriDexTrade(
            address _router1, 
            address _router2, 
            address _router3, 
            address _token1, 
            address _token2, 
            address _token3, 
            uint256 _amount
                ) external view returns (uint256) {
            uint amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
            uint amtBack2 = getAmountOutMin(_router2, _token2, _token3, amtBack1);
            uint amtBack3 = getAmountOutMin(_router3, _token3, _token1, amtBack2);
            return amtBack3;
        }

}