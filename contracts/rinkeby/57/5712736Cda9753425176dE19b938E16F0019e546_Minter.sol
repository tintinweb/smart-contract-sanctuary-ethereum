// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniV3Pool {
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Minter {
    struct Params {
        address pool;
        address token0;
        address token1;
        uint24 fee;
        address recipient;
        int24 tickLower;
        int24 tickUpper;
        uint128 amount;
    }
    
    struct MintCallbackData {
        PoolKey poolKey;
        address payer;
    }

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
    // 0x25fe7AF8a080A76575e256E0328d8834AC304CF2
    // ["0x101c6dCE02ABe4AaF6dD26021881BE1D2f702394", "0x400c206db9325509a183eba192fd2228bc3eb1fa", "0x9beb54320420da7e3346ba6b7c49b0131cfc1eab", 3000, "0x2ca935e866AC764F563344D7be6f0D0c9253d796", -23160, 23160, "123123000000000000000"]
    function mint(Params memory params) external {
        IUniV3Pool(params.pool).mint(
            params.recipient,
            params.tickLower,
            params.tickUpper,
            params.amount,
            abi.encode(
                MintCallbackData(
                    PoolKey({
                        token0: params.token0,
                        token1: params.token1,
                        fee: params.fee
                    }),
                    msg.sender
                )
            )
        );
    }

    

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));

        if (amount0 > 0)
            pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0);
        if (amount1 > 0)
            pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1);
    }

    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        IUniV3Pool(token).transferFrom(payer, recipient, value);
    }
}