/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier:No-license

pragma solidity 0.8.9;

contract withdrawRinkebyEth{
    address owner = 0x5eE0af63B28584dd818484a4C74603Ae57cA7941;
    modifier justAdmin{
        require(msg.sender == owner,"");
        _;
    }
    function deposit() public payable returns(string memory){
        return "Deposit is successful";
    }

    function withdraw(address from, uint amount) public payable justAdmin{
        payable(from).transfer(amount);
    }

  
}