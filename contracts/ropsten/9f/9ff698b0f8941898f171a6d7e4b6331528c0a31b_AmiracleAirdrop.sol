/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address who)  external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    // function transfer(address to, uint256 value) external returns(bool);
}

contract AmiracleAirdrop {
    constructor(){}
    function Airdop(ERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
        require(_to.length == _value.length, "Receivers and amounts are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }
}