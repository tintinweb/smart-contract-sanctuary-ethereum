/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.5.13;

contract SimpleWallet {


    function withdownMoney(address payable _to, uint _amount) public {
        _to.transfer(_amount);
    }

    function () external payable {

    }
}