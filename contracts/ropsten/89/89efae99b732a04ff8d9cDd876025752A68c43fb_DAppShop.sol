/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.16;
contract DAppShop{
    address payable Owner;
    constructor(){
        Owner = payable(msg.sender);
    }
    struct Product{
        uint Id;
        string Title;
        uint Price;
        uint Stock;
        string Image;
        string Descrption;
    }
    enum Status{
        Waiting,Sent,Reject
    }
    struct Order{
        uint Id;
        address User;
        uint Date;
        uint Amount;
        Status OrderStatus;
        uint [] ProductsId;
        uint [] ProductsCount;
    }
    struct User{
        address Wallet;
        string FullName;
        string Email;
        string UserAddress;
        uint TotalPaid;
        uint TotalOrders;
    }
    uint public ProductCount = 1;
    uint OrderCount;
    mapping (uint => Product) public Products;
    mapping (uint => Order) Orders;
    mapping (address => uint[]) UserOrders;
    mapping (address => User) Users;
    event AddProductEvent (uint indexed _Id ,string indexed _Title , address indexed _Address);
    event EditProductEvent (uint indexed _Id,string indexed _Title , address indexed _Address);
    event RemoveProductEvent (uint indexed _Id, address indexed _Address);
    event AddOrderEvent (uint indexed _Id,address indexed _CostumerAddress , uint indexed _Amount);
    event EditOrderEvent (uint indexed _Id,Status indexed _Status);
    modifier OnlyOwner() {
        require (msg.sender==Owner,"Access Denide");
        _;
    }
    function AddProduct (string memory _Title , uint _Price , uint _Stock , string memory _Image , string memory _Description) public OnlyOwner{
    Products[ProductCount]=Product({Id:ProductCount , Title:_Title , Price : _Price , Stock : _Stock , Image : _Image , Descrption : _Description });   
    emit AddProductEvent (ProductCount,_Title,msg.sender);
    ProductCount ++ ;
    }
    function EditProduct (uint _id , string memory _Title , uint _Price , uint _Stock , string memory _Image , string memory _Description ) public OnlyOwner{
    Products[_id].Title=_Title;
    Products[_id].Price=_Price;
    Products[_id].Stock=_Stock;
    Products[_id].Image=_Image;
    Products[_id].Descrption=_Description;
    emit EditProductEvent(Products[_id].Id,Products[_id].Title,msg.sender);
    }
    function DeletProduct(uint _id) public OnlyOwner{
        delete Products[_id];
        emit RemoveProductEvent(_id,msg.sender);
    }
    function ProductList() public view returns(Product[] memory _Products) {
        Product [] memory List;
        for (uint i=1 ;i <= ProductCount ; i++){
            Product memory obj = Products[i];
            List[i]=obj;
        }
        return List;
    }
    function AddOrder (uint[] memory _ProductsId , uint [] memory _ProductsCount , string memory _UserName , string memory _UserEmail , string memory _PostAddress) public payable{
        uint _Amount=0;
        for (uint i=0 ; i<=_ProductsId.length ; i++ ){
            require (Products[_ProductsId[i]].Stock >= _ProductsCount[i],"Out Of Stock");
            _Amount += (Products[_ProductsId[i]].Price)*(_ProductsCount[i]);
        }
        require (_Amount==msg.value);
        for (uint i=0 ; i<=_ProductsId.length ; i++ ){
            Products[_ProductsId[i]].Stock -= (Products[_ProductsId[i]].Price)*(_ProductsCount[i]);
        }
        Orders[OrderCount]=Order({Id:OrderCount,User:msg.sender,Date:block.timestamp,Amount:_Amount,ProductsId :_ProductsId ,ProductsCount :_ProductsCount , OrderStatus : Status.Waiting});
        User memory user = Users[msg.sender];
        user.Wallet=msg.sender;
        user.FullName=_UserName;
        user.Email=_UserEmail;
        user.UserAddress=_PostAddress;
        user.TotalPaid += _Amount;
        user.TotalOrders += 1;
        Owner.transfer(msg.value);
        UserOrders[msg.sender].push(OrderCount);
        emit AddOrderEvent (OrderCount,msg.sender,_Amount);
        OrderCount ++;
    }
    function EditOrderStatus (uint _Id , Status _NewStatus) public OnlyOwner{
        Orders[_Id].OrderStatus = _NewStatus;
        emit EditOrderEvent (_Id,Orders[_Id].OrderStatus);
    }
    function OrderDetails (uint _Id) public view returns(Order memory){
        return Orders[_Id];
    }
    function MyOrders() public view returns(Order[] memory){
        Order[] memory List;
        for (uint i=0;i<= UserOrders[msg.sender].length ;i++){
            Order memory obj = Orders[UserOrders[msg.sender][i]];
            List[i]=obj;
        }
        return List;
    }
    function OrderList () public view OnlyOwner returns(Order[] memory){
        Order[] memory ListOfOrders;
        for (uint i=0;i<= OrderCount ;i++){
            Order memory obj = Orders[i];
            ListOfOrders[i]=obj;
        }
        return ListOfOrders;
    }
    }