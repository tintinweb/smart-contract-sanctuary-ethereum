/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity 0.8.7; 

interface IERC20{
    function transferfrom(
        address sender,
        address recipient,
        uint256 amount
    )external returns (bool);

    function balanceOf(address account)external view returns (uint256);

    function allowence(address owner, address spender)external view returns (uint256);
}

contract Airdrop{
    constructor() {}

    function AirdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public{
        require(_to.length == _value.length, "Receivers and amounts are different");
        for (uint256 i=0; i < _to.length; i++){
            require(_token.transferfrom(msg.sender, _to[i], _value[i]));
        }
    }

}