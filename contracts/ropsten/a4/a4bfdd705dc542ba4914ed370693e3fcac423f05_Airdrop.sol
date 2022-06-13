/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract Airdrop{
    constructor(){}
    function airdrop(IERC20 _token,address[] calldata _to,uint256[] calldata _value) public{
        require (_to.length == _value.length,"Recievers and amounts are different length");
        for (uint256 i=0; i < _to.length; i++){
            require(_token.transferFrom(msg.sender,_to[i],_value[i]));
        }
    }
}