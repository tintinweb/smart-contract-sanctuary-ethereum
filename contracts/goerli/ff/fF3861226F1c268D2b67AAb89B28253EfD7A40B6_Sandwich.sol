// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

// import "./lib/UniswapV2Library.sol";
import "./lib/TransferHelper.sol";

interface IWETH {
  function deposit() external payable;
  function transfer(address dst, uint wad) external returns (bool);
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Sandwich {
   address owner;
   IWETH public WETH;
   address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
   address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

   constructor(address _WETH) public {
     owner = msg.sender;
     WETH = IWETH(_WETH);
   }

   receive() external payable {
     WETH.deposit{value:msg.value}();
   }

   function swap(uint amountIn, uint amountOutMin, address[] memory path, address to) public view returns (uint256[] memory amounts){
     // uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
     amounts = IUniswapV2Router(router).getAmountsOut(amountIn, path);
     // require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
     // TransferHelper.safeTransferFrom(
        // path[0], address(this), UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
     // );
     // _swap(amounts, path, address(this));
   }

   // function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
     // for (uint i; i < path.length - 1; i++) {
       // (address input, address output) = (path[i], path[i + 1]);
       // (address token0,) = UniswapV2Library.sortTokens(input, output);
       // uint amountOut = amounts[i + 1];
       // (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
       // address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
       // IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
         // amount0Out, amount1Out, to, new bytes(0)
       // );
      // }
    // }

   function withdraw(address token, uint amount) external onlyOwner {
     require(IERC20(token).balanceOf(address(this)) >= amount);
     IERC20(token).transfer(owner, amount);
   }

   modifier onlyOwner {
     require(msg.sender == owner);
     _;
   }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}