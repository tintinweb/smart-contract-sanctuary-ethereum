pragma solidity 0.8.9;


contract SimpleStorage {

    uint256 public balance;
   
    function showBalance() public view returns(uint256){
        return balance;
    }

    function changeVal() public payable {
        balance = msg.value;
    }
}