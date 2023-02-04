/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address sender, address recipiemt, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
contract sample {

    constructor() {}

    function airdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public
    {
        require(_to.length == _value.length, "shit");
        for(uint256 i = 0; i < _to.length; i++)
        {
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }
}