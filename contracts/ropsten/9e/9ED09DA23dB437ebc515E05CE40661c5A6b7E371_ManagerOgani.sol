// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";

contract ManagerOgani is Ownable {
    uint256 public transactionCount;
    uint256 public orderNumber;
    mapping (uint => PaymentObject) public listPayments;
    mapping (uint => UserPayment) public listUserOrder;
    mapping (address => uint256) public IndexUsers;
    mapping (uint256 => address) public AddressUsers;
    mapping (address => bool) public includeUser;
    receive() external payable {}
    fallback() external payable {}
    struct PaymentObject {
        string idProduct;
        uint256 totalPayment;
        address supplier;
        address currentAdmin;
    } 
    struct UserPayment{
        string idOrder;
        uint256 totalPayment;
        address userAddress;
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function userPaymentOrder(string memory _idOrder) public payable {
       UserPayment memory newUserOrder = UserPayment({
            idOrder: _idOrder,
            totalPayment: msg.value,
            userAddress: msg.sender
        });
        if(!includeUser[msg.sender]){
            uint256 index = orderNumber++;
            includeUser[msg.sender] = true;
            IndexUsers[msg.sender] = index;
            AddressUsers[index]= msg.sender;
            listUserOrder[index] = newUserOrder;
        }else{
            uint256 IndexUser;
            for (uint i = 0; i < orderNumber; i++) {
               address findIndexuser = AddressUsers[i];
               if(findIndexuser == msg.sender){
                    IndexUser= i;
               }
            }
            listUserOrder[IndexUser]= newUserOrder ;
        }
       
    }
    // function getPaymentOrderUser() public view returns (UserPayment[] memory){
    //     UserPayment[]  memory listOrder  = new UserPayment[](orderNumber);
    //     for (uint i = 0; i < orderNumber; i++) {
    //        uint currentUser  = listUser[msg.sender];
    //        if(currentUser == i)
    //        { 
    //         UserPayment storage currentObject = listUserOrder[i];
    //         listOrder[i] = currentObject;
    //        }
    //     }
    //     return listOrder;
    // }
    function getAllPaymentOrder() public view returns (UserPayment[] memory){
        UserPayment[]  memory listOrder  = new UserPayment[](orderNumber);
        for (uint i = 0; i < orderNumber; i++) {
            UserPayment storage currentObject = listUserOrder[i];
            listOrder[i]= currentObject;
        }
        return listOrder;
    }
   
    
    function transferToSupplier(string memory _idProduct, address _supplier) public payable includeManagementList(msg.sender) {
        listPayments[transactionCount] = PaymentObject(_idProduct,msg.value,_supplier,msg.sender);
        transactionCount++;
        payable(_supplier).transfer(msg.value);
    }
    function  getTransaction(uint256 index) public view returns (PaymentObject memory){
        PaymentObject[]    memory listTransaction = new PaymentObject[](transactionCount);
        for (uint i = 0; i < transactionCount; i++) {
            PaymentObject storage currentObject = listPayments[i];
            listTransaction[i] = currentObject;
        }
        return listTransaction[index];
    }
    function getAllTransaction () external view returns (PaymentObject[] memory){
        PaymentObject[]  memory listTransaction = new PaymentObject[](transactionCount);
        for (uint i = 0; i < transactionCount; i++) {
            PaymentObject storage currentObject = listPayments[i];
            listTransaction[i] = currentObject;
        }
        return listTransaction;
    }
    
    
    function withdraw(address _to) external payable{
        payable(_to).transfer(msg.value);
    }
    function withdrawMoneyTo(address payable _to) public {
        _to.transfer(getBalance());
    }
    
}