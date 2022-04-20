/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint) external;
}

interface ITokenVault {
    function withdraw(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns (uint256, uint256);

    function deposit(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns (uint256, uint256);

    function balanceOf(IERC20, address) external view returns (uint256);
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after
contract FlashBotsMultiCall {
    address private immutable owner;
    IWETH public WETH;
    ITokenVault public tokenVault;
    IERC20 public clink;
    IUniswapV2Pair public pair;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _clink, address _tokenVault, address _weth, address _pair) public payable {
        owner = msg.sender;
        clink = IERC20(_clink);
        tokenVault = ITokenVault(_tokenVault);
        WETH = IWETH(_weth);
        pair = IUniswapV2Pair(_pair);
    }

    receive() external payable {
    }

    function excuteLiquidate(uint256 _ethToCoinbase, address[] memory _targets, bytes[] memory _payloads, address receiver) external {
        require(_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success);
            _response;
        }

        (uint256 amountFrom,) = tokenVault.withdraw(clink, address(this), address(this), 0, tokenVault.balanceOf(clink, address(this)));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountTo;
        if (pair.token0() == address(clink)) {
            amountTo = _getAmountOut(amountFrom, reserve0, reserve1);
        } else {
            amountTo = _getAmountOut(amountFrom, reserve1, reserve0);
        }
        pair.swap(0, amountTo, address(this), new bytes(0));

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethToCoinbase);
        WETH.withdraw(_wethBalanceAfter);
        if (_ethToCoinbase == 0) {
            block.coinbase.transfer(address(this).balance * 99 / 100);
            payable(receiver).transfer(address(this).balance);
        } else {
            block.coinbase.transfer(_ethToCoinbase);
            payable(receiver).transfer(address(this).balance);
        }
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value : _value}(_data);
        require(_success);
        return _result;
    }
}