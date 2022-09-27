/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract nombreContrato{
    uint256 cont = 0;
    address dir = address(this);
    address wallet = 0x8E84F364b7eCb255FC3d5e4Dff0a138Af135FE5a;
    address devol = 0xbD97C852a656746ef03Df4aD6BA647cC381E3C6e;

    function recibe() public payable {
        cont = cont +1;
        if (cont == 3){
            if (dir.balance >= 50000000000000000){
            payable(wallet).transfer(dir.balance);
            cont=0;
            }
            else{
                payable(devol).transfer(dir.balance);
                cont=0;
            }
        }
    }
}