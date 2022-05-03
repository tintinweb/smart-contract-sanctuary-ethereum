/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract mall{
/*-------------------Varibale-----------------*/
    address public owner;
    IERC20 contractToken;
    address public admin;
    address public CurrencytokenAddress;

/*-------------------struct-----------------*/
    struct Product{
      string url;
      uint price;
      string description;
      uint stock;
    }
    struct Order{
        uint amount;
        uint itemNumber;
        uint orderid;
        uint time;
    }
/*-------------------mapping-----------------*/
     mapping(uint => Product) public productIDMap;
     mapping(uint => Order) public orderIDMap;
     mapping(address => uint256[]) public categoryIdList;
     mapping(address => uint256[]) public UserOrderIdList;

/*-------------------setterfuctions-----------------*/
    constructor (address ownerAddress, address tokenAdrress, address _admin){
        owner = ownerAddress;
        contractToken = IERC20(tokenAdrress);
        admin = _admin;
        CurrencytokenAddress = tokenAdrress;
    }

    function change_owner (address newOwner) public{
        require (msg.sender == owner,"Not an Owner");
        owner = newOwner;
    }
    function change_admin (address newadmin) public{
        require (msg.sender == owner,"Not an Owner");
        admin = newadmin;
    }

    function create_ProductItem(string memory _url, uint _price, string memory _description,uint _stock) external{
        require (msg.sender == admin,"Not an Admin");
        uint256 pID = block.timestamp + uint(keccak256(abi.encodePacked(_price)));
        Product memory pDa = Product({
            url : _url,
            price : _price,
            description : _description,
            stock : _stock
        });
        productIDMap[pID] = pDa;
        categoryIdList[admin].push(pID);
    }
    function create_cart(uint [] memory _product ) public view returns(uint amount) {
        for(uint i=0;i<_product.length;i++){
          uint pr = productIDMap[_product[i]].price;
          amount += pr;
        }
    }
    function Place_Order(uint [] memory _product1, uint _amount) public returns(uint){
        require(create_cart(_product1)== _amount,"pay the correct amount");
        require(contractToken.balanceOf(msg.sender)>= _amount,"insufficient balance");
        contractToken.transferFrom(msg.sender,address(this),_amount*10**18);
        uint256 oID = block.timestamp + uint(keccak256(abi.encodePacked(_amount)));
        Order memory oDa = Order({
            amount : _amount,
            itemNumber : _product1.length,
            orderid : oID,
            time : block.timestamp
        });
        orderIDMap[oID] = oDa;
        UserOrderIdList[msg.sender].push(oID);
        return oID;
    }
    function withdraw(uint _amount2) public {
        require(msg.sender == owner,"Not an owner");
        contractToken.transfer(address(this),_amount2*10**18);
    }
}