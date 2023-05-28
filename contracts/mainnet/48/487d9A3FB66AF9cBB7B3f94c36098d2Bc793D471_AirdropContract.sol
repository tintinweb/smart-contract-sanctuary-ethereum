/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract AirdropContract {
    function distributeTokens(address[] memory _recipients, uint256[] memory _amounts,address _tokenAddress) public {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");

        IERC20 token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
}