/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract BluePay {
    string public name = "MichaelsAmadi Token";
    string public symbol = "MAT";
    uint256 public decimals = 2;
    uint256 public totalSupply = 100000000;
    address public owner = msg.sender;
    uint public teeShirtPrice = 500;
    uint public joggersPrice = 700;
    uint public canvasPrice = 2000;

constructor(uint _totalSupply) {
        _totalSupply = totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

mapping (address => uint) public balanceOf;
    mapping (address => mapping(address => uint)) public allowance;

event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

function transfer (address _to, uint _value) external returns (bool success) {
        require (balanceOf[msg.sender]>= _value);
        _transfer (msg.sender, _to, _value);
        return true;
    }

    function _transfer (address _from, address _to, uint _value) internal{
        require( _to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer (_from, _to, _value);
    }

    function approve(address _spender, uint _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require (balanceOf [_from] >= _value);
        require (allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer (_from, _to, _value);
        return true;
    }








    string teeShirt = "Tee Shirt";
    string joggers = "Joggers"; 
    string canvas = "Canvas";
    

    

    struct Cart {
        string item;
        uint itemPrice;
        uint quantity;
        uint total;
    }

    Cart [] public cartInfo;

    

    uint [] public totalAmountPerItem;

    uint [] public prices;

    mapping (address => uint) public cartSize;
    


    //function setPrices (uint _teeShirt, uint _joggers, uint _canvas) public {
    //    require (msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
     //   prices.push(_teeShirt);
     //   prices.push(_joggers);
     //   prices.push(_canvas);
        
   // }

    function addTeeShirtToCart (uint _quantity) public returns (string memory) {
        uint totalCost = teeShirtPrice * _quantity;
        cartInfo.push(Cart(teeShirt, teeShirtPrice, _quantity, totalCost));
        totalAmountPerItem.push(uint(totalCost));
        cartSize [msg.sender] = cartSize [msg.sender] + _quantity;
        return "Added to cart!"; 
    }   
        
    function addJoggersToCart (uint _quantity) public returns (string memory) {
        uint totalCost = joggersPrice * _quantity;
        cartInfo.push(Cart(joggers, joggersPrice, _quantity, totalCost));
        totalAmountPerItem.push(uint(totalCost));
        cartSize [msg.sender] = cartSize [msg.sender] + _quantity;
        return "Added to cart!"; 
    }

    function addCanvasToCart (uint _quantity) public returns (string memory) {
        uint totalCost = canvasPrice * _quantity;
        cartInfo.push(Cart(canvas, canvasPrice, _quantity, totalCost));
        totalAmountPerItem.push(uint(totalCost));
        cartSize [msg.sender] = cartSize [msg.sender] + _quantity;
        return "Added to cart!";      
    }

    function itemAmount () public view returns (uint) {
        return cartSize [msg.sender]; 
    }

   function getMyInfo () public view returns (Cart[] memory) {
       return cartInfo;
   }

   function totalPrice () public view returns (uint) {
         uint i;
         uint sum = 0;
         for (i=0;i<totalAmountPerItem.length;i++)
            sum=sum+totalAmountPerItem[i];
        return sum;
   }
   
    function makePayment () public {
        uint i;
         uint sum = 0;
         for (i=0;i<totalAmountPerItem.length;i++)
            sum=sum+totalAmountPerItem[i];
        _transfer(msg.sender, owner, sum);
    }
 }