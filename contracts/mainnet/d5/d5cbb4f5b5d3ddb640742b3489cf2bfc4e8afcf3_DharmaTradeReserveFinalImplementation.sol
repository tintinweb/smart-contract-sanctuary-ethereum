/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract DharmaTradeReserveFinalImplementation {
    address public constant recipient = 0x67e1b186e6dA49917922C040FD07bE1827978CE7;

    function sendAll(address token) public {
        if (token == address(0)) {
            recipient.call{value: address(this).balance}("");
        } else {
            IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
        }
    }

    function batchSendAll(address[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; ++i) {
            sendAll(tokens[i]);
        }
    }
}