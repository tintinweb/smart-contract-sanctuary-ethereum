/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Multi {
    event Transfer(address _from, address[] recipients, uint256[] values);

    function multi_Ether(address[] recipients, uint256[] values) external payable {
        require(recipients.length == values.length,"recipients values length error");
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        emit Transfer(msg.sender, recipients, values);
    }

    function multi_Token(IERC20 token, address[] recipients, uint256[] values) external {
        require(recipients.length == values.length,"recipients values length error");
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
        emit Transfer(msg.sender, recipients, values);
    }

}