/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/*
	bytes32 internal constant POOL_INIT_CODE_HASH = 0x4a9ce393638f9009293b4f23a551ee90f2b9af7b5cf3f45cf13f15e851693e02;   //自己部署的UniswapV3Pool的字节码
	struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
*/

contract calc_pool_addr{

    	function computeAddress(address factory, bytes32 POOL_INIT_CODE_HASH,address token0,address token1,uint24 fee) public pure returns (address pool) {
        require(token0 < token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(token0, token1, fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}