/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ERC20{
    function transferFrom(address sender, address recipient ,uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract BulkAirdrop {
    constructor(){}

    function AirdropERC20 (ERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
        require(_to.length == _value.length, "Receivers and amounts are different length");
        for(uint256 i=0; i<_to.length; i++){
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }

}