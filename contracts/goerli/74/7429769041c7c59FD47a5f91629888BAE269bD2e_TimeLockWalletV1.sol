//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
            locktime: block.timestamp + 1 minutes,
            canOpen: true
    });
        Info[msg.sender].push(newLocker);
        emit Deposit (msg.value, msg.sender, Info[msg.sender].length-1);
}
    function withdraw (uint txid) external{
        require (block.timestamp >= Info[msg.sender][txid].locktime, "Lock time is not yet expired");
        require (Info[msg.sender][txid].canOpen == true);
        Info[msg.sender][txid].canOpen = false; //Cannot call the same txId again

        emit Withdraw(Info[msg.sender][txid].value, msg.sender, txid);
        payable(msg.sender).transfer(Info[msg.sender][txid].value);
}
    function showTimeLeft (address _depositer, uint txid) external view returns (uint) {
        uint timeLeft= Info[_depositer][txid].locktime - block.timestamp;
        return timeLeft;
    }
}
    /*function showThisBalance () external view returns(uint){
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