//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract BundleExecutor {
    address private immutable owner;
    address private immutable executor;

    IWETH public WETH = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    modifier onlyExecutor() {
        require(msg.sender == executor, "Only executor");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _executor) {
        owner = msg.sender;
        executor = _executor;
    }

    function setWeth(address _new) external onlyOwner {
        WETH = IWETH(_new);
    }

    function s(
        IERC20 token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        token.transfer(_to, _amount);
    }

    function hi(
        uint256 _amountIn,
        address[] calldata _targets,
        uint256[2][] calldata _amountsOut
    ) public onlyExecutor {
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));

        WETH.transfer(_targets[0], _amountIn);
        uint256 n = _targets.length;
        for (uint256 i = 0; i < n - 1; i = unsafe_inc(i)) {
            IUniswapV2Pair(_targets[i]).swap(
                _amountsOut[i][0],
                _amountsOut[i][1],
                _targets[i + 1],
                ""
            );
        }
        IUniswapV2Pair(_targets[n - 1]).swap(
            _amountsOut[n - 1][0],
            _amountsOut[n - 1][1],
            address(this),
            ""
        );

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore, "not profitable");
    }

    // function hi2(
    //     uint256[] calldata _amountIn,
    //     address[][] calldata _targets,
    //     uint256[2][][] calldata _amountsOut
    // ) external onlyExecutor {
    //     uint256 n = _amountIn.length;
    //     for (uint256 i = 0; i < n; i = unsafe_inc(i)) {
    //         hi(_amountIn[i], _targets[i], _amountsOut[i]);
    //     }
    // }

    // function hp(
    //     uint256 _amountIn,
    //     address[] calldata _targets,
    //     bytes[] calldata _payloads
    // ) public onlyExecutor {
    //     uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
    //     bool success = WETH.transfer(_targets[0], _amountIn);
    //     require(success, "f");
    //     for (uint256 i = 0; i < _targets.length; i = unsafe_inc(i)) {
    //         (bool _success, bytes memory _response) = _targets[i].call(
    //             _payloads[i]
    //         );
    //         require(_success, "l");
    //         _response;
    //     }
    //     uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
    //     require(_wethBalanceAfter > _wethBalanceBefore, "np");
    // }

    // function hp2(
    //     uint256[] calldata _amountIn,
    //     address[][] calldata _targets,
    //     bytes[][] calldata _payloads
    // ) external onlyExecutor {
    //     uint256 n = _amountIn.length;
    //     for (uint256 i = 0; i < n; i = unsafe_inc(i)) {
    //         hp(_amountIn[i], _targets[i], _payloads[i]);
    //     }
    // }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}