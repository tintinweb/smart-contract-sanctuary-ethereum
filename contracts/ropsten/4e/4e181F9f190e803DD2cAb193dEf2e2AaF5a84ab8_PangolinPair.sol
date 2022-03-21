// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PangolinPair {
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    // function needed by the agent to read reserves values.
    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // function we added to set reserves values within tests.
    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    // events monitored by the agent.
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );

    // function modified to emit `Mint` event with defined amounts.
    function mint(
        address to,
        uint amount0,
        uint amount1
    ) external {
        reserve0 = uint112(reserve0 + amount0);
        reserve1 = uint112(reserve1 + amount1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // function modified too emit `Burn` event with defined amounts.
    function burn(
        address to,
        uint amount0,
        uint amount1
    ) external {
        // require amounts to be bellow reserves.
        require(
            reserve0 >= amount0 && reserve1 >= amount1,
            " Insufficient reserves!"
        );
        reserve0 = uint112(reserve0 - amount0);
        reserve1 = uint112(reserve0 - amount0);

        emit Burn(msg.sender, amount0, amount1, to);
    }
}