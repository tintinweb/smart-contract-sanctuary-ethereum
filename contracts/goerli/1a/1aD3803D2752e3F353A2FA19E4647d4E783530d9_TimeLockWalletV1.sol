//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/* This is a TimeLockWallet.
To start with, you need to send eth into this contract.
Then you can withdraw that amount of eth after a certain period of time i.e., 5 mins. 
Go to "write contract" on etherscan and click the "withdraw" function. 
Type in the number on txid row, the number is which deposit you want to withdraw minus 1. If you want to
withdraw the eth on your first deposit, type in "0". If you want to withdraw the eth on your second 
deposit, type in "1" and vice versa.

In "Read Contract", there are more functions. You can check any available deposit you can withdraw in 
"Info" function. You can also check when you are able to wtihdraw certain deposit in "showTimeLeft" function.*/

contract TimeLockWalletV1{
    event Deposit(uint amount,address depositer, uint indexed txid);
    event Withdraw(uint amount, address withdrawer, uint indexed txid);
    mapping (address => Locker[]) public Info; //The elements in [] is Locker type

    struct Locker{
        uint value;
        uint locktime;
        bool canOpen;
    }

    receive() external payable{ 
        Locker memory newLocker = Locker({  //Locker is a type
            value: msg.value,
            locktime: block.timestamp + 5 minutes,
            canOpen: true
    });
        Info[msg.sender].push(newLocker);
        emit Deposit (msg.value, msg.sender, Info[msg.sender].length-1);
}
    function withdraw (uint txid) external{
        require (block.timestamp >= Info[msg.sender][txid].locktime, "Lock time is not yet expired");
        require (Info[msg.sender][txid].canOpen == true);
        Info[msg.sender][txid].canOpen = false;

        emit Withdraw(Info[msg.sender][txid].value, msg.sender, txid);
        payable(msg.sender).transfer(Info[msg.sender][txid].value);
}
    function showTimeLeft (address _depositer, uint txid) external view returns (uint) {
        uint timeLeft= Info[_depositer][txid].locktime - block.timestamp;
        return timeLeft;
    }

    function showThisBalance () external view returns(uint){
        return address(this).balance;
    }
}
// uint256 k = uint256(12);
// uint256[] kk;
// kk.push(k);



/* stack: fixed-size memory/known size memory
eg, uint8 > need to use 8bits to store
eg, uint256> 256 bits
eg, bool > 256 bits
All these put in stack

heap: non-known size memory
eg, string > unknown as may have many words
need to save in memory or call-data
*/