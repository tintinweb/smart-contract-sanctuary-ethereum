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
        uint256 amounts
    ) external{
        for(uint256 i =0; i < to.length; i++ ){
            IERC20(token).transferFrom(from, to[i], amounts);
        }
    }

    function sendEthers(address payable[] memory receivers, uint256 amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            receivers[i].transfer(amounts);
            emit  Withdrawal(receivers[i], amounts);
        }
        payable(msg.sender).transfer(address(this).balance);

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