/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;
contract EtherCoin{
    EtherPool public etherpool;
    mapping (address=>uint) Balances;
    function hasFunds(address user) public view returns(bool){
        if(Balances[user]>0){return true;}else{return false;}
    }
    function creator(address payable user) internal{
        etherpool=(new EtherPool){value:Balances[user]}({_ethercoinAddress:address(this),user:user});
        Balances[user] = 0; //set balance to zero
    }
    function deposit() external payable{
        Balances[msg.sender]+=msg.value;
    }
    function withdrawAll() external {
        creator(payable(msg.sender));
    }

}
contract EtherPool{
    EtherCoin public ethercoin;
    constructor(address _ethercoinAddress,address payable user) payable{
        if(user!=address(0)){
            ethercoin=EtherCoin(_ethercoinAddress);
            if(ethercoin.hasFunds(user)){
                (bool success,)=user.call{value:msg.value}("");
                require(success,"revert");
            }
        }
    }
}