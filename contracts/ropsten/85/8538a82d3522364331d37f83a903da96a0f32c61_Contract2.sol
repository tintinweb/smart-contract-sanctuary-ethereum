/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

pragma solidity ^0.7.0;

contract Contract2 {


    function sendETH(address _to,uint256 _amount) public payable {
        address payable receiver = payable(_to);
        receiver.transfer(_amount);
    }

    function balance() public view returns(uint256){
        address self = address(this);
        uint256 balances = self.balance;
        return balances;
    }

}