pragma solidity =0.4.17;

import "./interfaces/IERC20.sol";

contract Transfer { 
    function transferFromToken(
        address token,
        address from,
        address[] to,
        uint256 amounts
    ) external{
        for(uint256 i =0; i < to.length; i++ ){
            IERC20(token).transferFrom(from, to[i], amounts);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.4.17;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address user, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}