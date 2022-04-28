pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AstraERC20Disperser {
    function disperseERC20(IERC20 token, address[] memory recipients, uint amount_per) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], amount_per));
    }
}