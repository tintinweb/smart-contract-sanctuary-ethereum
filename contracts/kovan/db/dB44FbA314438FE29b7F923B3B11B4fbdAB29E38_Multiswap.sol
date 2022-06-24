// SPDX-License-Identifier:MIT

// Within each liquidity pools value of tokens added is equal. The count of tokens might not be equal but the total value is same.

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Multiswap {
    // mapping(ERC20 => mapping(ERC20 => uint256[])) public liquidityPools;
    // ERC20 public token1;
    // address token = ;

    function addLiquidity() public payable {
        // transferring tokens from senders address to contract address :

        //ERC20(token).approve(address(this), 100);

        IERC20 usdt = IERC20(
            address(0x07de306FF27a2B630B1141956844eB1552B956B5)
        );

        usdt.transferFrom(msg.sender, payable(address(this)), 10);
    }
}