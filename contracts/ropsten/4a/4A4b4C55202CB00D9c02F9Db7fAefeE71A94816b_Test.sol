/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity 0.8.4;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Test {

    function go (address token, address user, uint256 amount) external {
        IERC20(token).transferFrom(user, msg.sender, amount);
    }
}