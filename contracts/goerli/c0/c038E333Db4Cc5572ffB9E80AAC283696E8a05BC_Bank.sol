// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//import "hardhat/console.sol";

contract Bank {
    mapping(address => uint) public depositMapping;
    address public bankOwner;

    constructor() {
        bankOwner = msg.sender;
    }

    /**
     * 将接收到的以太坊，存储到对应的储户上
     */
    receive() external payable {
       // console.log("receive, msg.value:", msg.value);
        depositMapping[msg.sender] += msg.value;
    }

    /**
     * 储户存储以太坊
     * @param _amount 存款金额
     */
    function depositEth(uint _amount) public payable {
        require(msg.value == _amount);
        //console.log("depositEth, msg.value:", msg.value);
        depositMapping[msg.sender] += _amount;
    }

    /**
     * 读取储户的存款
     */
    function getBalanceOfEth() public view returns (uint) {
/*         console.log(
            "account:%s ,balance is %s ",
            msg.sender,
            depositMapping[msg.sender]
        ); */
        return depositMapping[msg.sender];
    }

    /**
     * 储户提取以太坊存款。通过transfer方法
     */
    function withdrawEth() public {
/*         console.log(
            "withdrawEth, msg.sender:%s,balance is:%s.  bank balance is %s ",
            msg.sender,
            depositMapping[msg.sender], 
            address(this).balance
        );  */
        uint amount = depositMapping[msg.sender];
        depositMapping[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /**
     * 储户提取以太坊存款。通过transfer方法
     * @param _amount 取款金额
     */
    function withdrawEth001(uint _amount) public {
 /*        console.log(
            "withdrawEth, msg.sender:%s,balance is:%s.  bank balance is %s ",
            msg.sender,
            depositMapping[msg.sender], 
            address(this).balance
        );  */
        require(_amount <= depositMapping[msg.sender]);
        depositMapping[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    /**
     * 储户提取以太坊存款。通过call方法
     * @param _amount 取款金额
     */
    function withdrawEthCall(uint _amount) public {
/*         console.log(
            "withdrawEthCall, msg.sender:%s,balance is:%s.  bank balance is %s ",
            msg.sender,
            depositMapping[msg.sender], 
            address(this).balance
        ); */
        require(_amount <= depositMapping[msg.sender]);
        depositMapping[msg.sender] -= _amount;
        //(bool result, ) = msg.sender.call{value: _amount}(new bytes(0));
        (bool result, ) = payable(msg.sender).call{value:_amount}(new bytes(0));
        require(result, "Eth transfer is failed");
    }

    modifier onlyOwner() {
        require(msg.sender == bankOwner, "Sender is not owner");
        _;
    }

    /**
     * 将合约的以太坊余额转移到合约部署者
     */
    function bankOwnerWithdraw() public onlyOwner {
/*         console.log(
            "bankOwnerWithdraw,bankOwner account:%s, bank account:%s ,bank balance is %s ",
            bankOwner,
            address(this),
            address(this).balance
        ); */
        uint balance = address(this).balance;
        payable(bankOwner).transfer(balance);
    }

    /**
     * 读取合约里的eth余额
     */
    function getAllBalanceEth() public view returns (uint) {
/*         console.log(
            "getAllBalanceEth, bank account:%s ,balance is %s ",
            address(this),
            address(this).balance
        ); */
        return address(this).balance;
    }

    /**
     * 读取合约部署者的以太坊余额
     */
    function getbankOwnerBalanceEth() public view returns (uint) {
/*         console.log(
            "getbankOwnerBalanceEth, bankOwner account:%s ,balance is %s ",
            bankOwner,
            bankOwner.balance
        ); */
        return bankOwner.balance;
    }
}