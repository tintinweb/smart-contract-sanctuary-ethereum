pragma solidity =0.8.10;

import "./interfaces/IERC20.sol";

contract Transfer { 
    receive() external payable {}
    fallback() external payable {}
    event  Withdrawal(address indexed src, uint wad);

    function transferFromToken(
        address token,
        address from,
        address[] calldata to,
        uint256[] calldata amounts
    ) external{
        for(uint256 i =0; i < to.length; i++ ){
            IERC20(token).transferFrom(from, to[i], amounts[i]);
        }
    }

    function functionSendMultiCoin(address payable [] calldata _to) external payable  { 
        for(uint256 i =0; i < _to.length; i++) {
            (bool sent, bytes memory data) = _to[i].call{value: msg.value}("");
            require(sent, "Failed to send Ether");
            emit  Withdrawal(_to[i], msg.value);

        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address user, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}