// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";

contract ManagerOgani is Ownable {
    uint256 private orderId;
    mapping (address => UserPayment[]) public userOrders;
    mapping (address => PaymentToSupplier[]) public paymentsToSupplier;
    mapping (address => bool) private isCustomer;
    mapping (address => bool) private isSupplier;
    event refundsForUser(
        address indexed _walletUser,
        uint indexed _amount
    );
    event transferSupplierSuccess( 
        string idProduct,
        uint amount
    );
  
    receive() external payable {}
    fallback() external payable {}
   
    struct PaymentToSupplier {
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
    function userPaymentOrder(string memory _idOrder) external payable {
        UserPayment memory newUserOrder = UserPayment({
            idOrder: _idOrder,
            totalPayment: msg.value,
            userAddress: msg.sender
        });
        if(!isCustomer[msg.sender]){
            isCustomer[msg.sender] = true;
            userOrders[msg.sender].push(newUserOrder);
        }else{
            userOrders[msg.sender].push(newUserOrder);
        }
    }
    function getAllOrderUser(address _addressUser) public view returns (UserPayment[] memory){
        require(isCustomer[_addressUser]," User has never placed an order");
        UserPayment[]  memory orders  = new UserPayment[](userOrders[_addressUser].length);
        for (uint i = 0; i < userOrders[_addressUser].length; i++) {
            UserPayment memory order = userOrders[_addressUser][i];
            orders[i]= order;
        }
        return orders;
    }
    function transferToSupplier(string memory _idProduct, address _supplier) external payable onlyManagers {
        paymentsToSupplier[_supplier].push(PaymentToSupplier(_idProduct,msg.value,_supplier,msg.sender));
        isSupplier[_supplier] = true;
        payable(_supplier).transfer(msg.value);
        emit transferSupplierSuccess(_idProduct, msg.value);
    }
    function getPaymentsToSupplier(address _addressSupplier) external view returns (PaymentToSupplier[] memory) {
        require(isSupplier[_addressSupplier], "This wallet address is not a supplier");
        uint lenghtPayment = paymentsToSupplier[_addressSupplier].length;
        PaymentToSupplier[] memory payments = new PaymentToSupplier[](lenghtPayment);
        for( uint i = 0; i < lenghtPayment; i++) {
            PaymentToSupplier memory payment  = paymentsToSupplier[_addressSupplier][i];
            payments[i] = payment;
        }
        return payments;
    }

    function withdrawAll(address payable _to) external onlyOwner {
      _to.transfer(getBalance());
    }
    function withdrawAmount(address payable _to, uint _amount) external onlyOwner {
       _to.transfer(_amount);
    }
    function refundsOrderUser(address payable _walletuser,uint _amount) external payable onlyManagers {
        _walletuser.transfer(_amount);
        emit refundsForUser(_walletuser, _amount);
    } 
}