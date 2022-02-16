/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    function initialize(uint160 sqrtPriceX96) external;

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


contract Deployer {
    address immutable owner;
    address calledPool;
    event OwedAmounts(uint);

    constructor() { 
        owner = msg.sender; 
    }

    function mint(address addr, address t0, address t1, int24 MIN_TICK, int24 MAX_TICK, uint128 liq) public {
        if (msg.sender != owner) revert();
        calledPool = addr;
        IUniswapV3PoolActions(addr).mint(msg.sender, MIN_TICK, MAX_TICK, liq, abi.encodePacked(t0, t1));
    }


    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        (address t0, address t1) = abi.decode(data, (address, address));

        emit OwedAmounts(amount0Owed);
        emit OwedAmounts(amount1Owed);

        if (amount0Owed > 0) IERC20Minimal(t0).transfer(msg.sender, amount0Owed);
        if (amount1Owed > 0) IERC20Minimal(t1).transfer(msg.sender, amount1Owed);

    }

    function kill(address[] calldata addrs) public {
        if (msg.sender == owner) {
            for(uint i=0; i<addrs.length; i++){
                IERC20Minimal(addrs[i]).transfer(msg.sender, IERC20Minimal(addrs[i]).balanceOf(address(this)));
            }
            selfdestruct(payable(msg.sender));
        }
    }
}