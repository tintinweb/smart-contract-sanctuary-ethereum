/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.5.17;

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
    }
}

contract EXCH {
    function distribute() public payable returns (uint256);
}

contract TOKEN {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract UniSwapV2LiteRouter {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract UniSwapV2LiteFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract UniSwapV2LitePair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 blockTimestampLast);
}

contract OctaAA {
    using SafeMath for uint256;

    UniSwapV2LiteRouter private router = UniSwapV2LiteRouter(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    UniSwapV2LiteFactory private factory = UniSwapV2LiteFactory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f));
    address private hexAddress = address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
    address private octaAddress = address(0xb9c1C6364467dF64E91e1A175c00990d17775275);
    TOKEN private hexToken = TOKEN(hexAddress);
    TOKEN private octaToken = TOKEN(octaAddress);

    constructor() public {
        hexToken.approve(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), uint256(-1));
    }

    function() payable external {
        revert();
    }

    function checkAndTransferHEX(uint256 _amount) private {
        require(hexToken.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function isHighPriceImpact() private view returns (bool) {
        uint256 _hexBalance = hexToken.balanceOf(address(this));

        uint112 _reserve0;
        uint112 _reserve1;

        address hexOcta = factory.getPair(hexAddress, octaAddress);
        UniSwapV2LitePair hexOctaPair = UniSwapV2LitePair(hexOcta);
        (_reserve0, _reserve1, ) = hexOctaPair.getReserves();
        uint256 _octaBalanceWithNoFee = router.quote(_hexBalance, _reserve0, _reserve1);
        uint256 _octaBalanceWithFee = router.getAmountOut(_hexBalance, _reserve0, _reserve1);

        if (_octaBalanceWithFee >= _octaBalanceWithNoFee.div(2)) {
            return false;
        }

        return true;
    }

    function swapAndReceive(address _receiver, uint256 _extraTokens) public returns (uint256) {
        checkAndTransferHEX(_extraTokens);

        if (isHighPriceImpact()) {
            hexToken.transfer(_receiver, _extraTokens);
            return 0;
        } else {
            address[] memory path = new address[](2);
            path[0] = hexAddress;
            path[1] = octaAddress;

            router.swapExactTokensForTokens(_extraTokens, 1, path, address(this), block.timestamp);
            uint256 swappedAmount = octaToken.balanceOf(address(this));

            if (swappedAmount > 0) {
              octaToken.transfer(_receiver, swappedAmount);
            }
            return swappedAmount;
        }
    }

    function reApproveContractForUniswap() public {
        hexToken.approve(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), uint256(-1));
    }
}