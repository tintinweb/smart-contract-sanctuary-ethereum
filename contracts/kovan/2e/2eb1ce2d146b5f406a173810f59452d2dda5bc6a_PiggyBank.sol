/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
//pragma solidity >=0.4.22 <0.8.0;
pragma solidity 0.8.7;

/* 新目標
1. 升級solidity版本                              >done
2. 解決任何人都能觸發selfdestruct，把錢拿走        >done
3. 解決任何address都能使用takeMoney               >done 
4. 只有owner存錢時才會自動觸發withdraw             >done
*/
contract PiggyBank{
    uint public goal;    //目標金額，可被查詢，單位wei
    address payable owner;
    address payable sender;
    constructor(uint _goal){
        goal = _goal;
        owner = payable(msg.sender);
    }
    receive() external payable{   //可收ether
        if(payable(msg.sender) == owner){
            withdraw();     //是owner的話，看balance是否大於goal
        }
        //withdraw();     //大於goal直接selfdistruct
        sender = payable(msg.sender);
    }     
    
    modifier onlyOwner{         //建立owner
        require(
            owner == payable(msg.sender), 
            "only owner can take money"
        );
        _;
    }

    function getMyBalance()  public view returns(uint){
        return address(this).balance;
    }
    function getOwnerAddress() public view returns(address){ return owner; }
    function getSenderAddress() public view returns(address){ return sender; }

    function takeMoney(uint want) onlyOwner public returns (bool) {      //領設定的金額
        payable(msg.sender).transfer(want);
        return true;
    }
    function withdraw() onlyOwner public{
        if(getMyBalance() >= goal){        //儲蓄大於目標金額
            // require(
            //     owner == payable(msg.sender), 
            //     "only owner can withdraw"
            // );
            selfdestruct(payable(msg.sender));     //摧毀後送錢給msg.sender
        }
    }
    //msg.sender: 最後一個呼叫(操作)contract的address
}