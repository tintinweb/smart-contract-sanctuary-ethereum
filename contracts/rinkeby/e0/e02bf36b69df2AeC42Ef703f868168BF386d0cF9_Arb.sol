//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./SafeMath.sol";

contract IERC20 {
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    function approve(address guy, uint wad) public returns (bool) {
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        return true;
    }
}

interface Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}


contract Arb {
    using SafeMath for uint;
    address payable private owner; 
    address public WAVAX;
    constructor(address _WAVAX) {
        owner = payable(msg.sender);
        WAVAX = _WAVAX;
    }

    function safeTransfer(address token,address to,uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountsOut(uint amountIn, address[] memory pairs) internal view returns (uint[] memory amounts) {
        amounts = new uint[](pairs.length);
        amounts[0] = amountIn;
        for (uint i; i < pairs.length - 1; i++) {
            (uint reserveIn, uint reserveOut, ) = Pair(pairs[i]).getReserves();
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function _swap(uint[] memory amounts,address[] calldata pairs, address[] calldata path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            address to = i < path.length - 2 ? pairs[i+1] : _to;
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            Pair(pairs[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    function arb(address[] calldata tokens, address[] calldata pairs, uint amountIn) external{
        require(msg.sender == owner, "OWNER");
        uint prevBalance = IERC20(WAVAX).balanceOf(address(this));
        safeTransfer(tokens[0],pairs[0], amountIn);
        uint[] memory amounts = getAmountsOut(amountIn, pairs);
        _swap(amounts, pairs, tokens, address(this));
        require(IERC20(WAVAX).balanceOf(address(this)) > prevBalance, "Failed Arb");
    }

    function redeem(address[] calldata tokens) external {
        require(msg.sender == owner, "OWNER");
        for (uint i = 0; i < tokens.length; i++){
            if (tokens[i] != address(0)) {
                uint balance = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).transfer(owner, balance);
            }
            else{
                (bool sent, ) = owner.call{value: address(this).balance}("");
                require(sent, "NOT SENT");
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}