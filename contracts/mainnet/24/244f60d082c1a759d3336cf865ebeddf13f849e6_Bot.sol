/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
}

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IFactory {
    function g (uint count) external;
    function d (uint count) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract Bot {
    address private immutable owner;
    address private immutable executor;

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IFactory private FACTORY = IFactory(0xf3E331Ef2E9bDa503362562A9a10bb66b4AE834f);

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function sB(address _pairAddress, uint256 amount0Out, uint256 amount1Out, uint256 amountIn, uint256 destruct) external onlyExecutor {
        IUniswapV2Pair UniswapV2Pair = IUniswapV2Pair(_pairAddress);
        WETH.transfer(_pairAddress, amountIn);
        UniswapV2Pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        if(destruct > 0) {
            FACTORY.d(destruct);
        }
    }

    function sS(address _pairAddress, address _tokenAddress, uint256 amount0Out, uint256 amount1Out, uint256 amountIn, uint256 destruct) external onlyExecutor payable {
        IUniswapV2Pair UniswapV2Pair = IUniswapV2Pair(_pairAddress);
        IERC20 ERC20 = IERC20(_tokenAddress);
        ERC20.transfer(_pairAddress, amountIn);
        UniswapV2Pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        block.coinbase.transfer(address(this).balance);
        if(destruct > 0) {
            FACTORY.d(destruct);
        }
    }

    constructor() public payable {
        executor = msg.sender;
        owner = address(0x67e0D532f78F081162A5D3C0A1B1896bcCCEe602);
    }

    receive() external payable {
    }

    function sF(address _factoryAddress) external onlyExecutor {
        FACTORY = IFactory(_factoryAddress);
    }


    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}