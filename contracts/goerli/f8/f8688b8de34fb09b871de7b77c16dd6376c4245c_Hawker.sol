/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.11;

interface IToken{
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function transfer(address receiver, uint tokens) external returns (bool success);
}

interface IHub{
    function writePosition(string memory name, string memory position) external returns (bool success);
}

contract Hawker {
    address tokenAddress;
    address thisContract;
    address hubAddress;
    address operator;
    string activationString;
    string welcomemessage;
    bool status;
    struct Seller {address seller; uint sellerId;}
    struct Record {address seller; string items; uint256 tip; uint sellerId;  bytes32 code; bool completed; string location; uint sessionId; }
    struct Menu {string menuItem; string menuPrice;}
    mapping(address => Seller) public sellerMap;


    Record[] public recordArray;
    Menu[] public menuArray;
    string[] menuItems;
    address [] public sellerArray;
    uint [] numberArray;
    uint session;
    mapping(address =>bool) existingSeller;
    mapping(address =>bool) activeSeller;

    constructor(address _tokenAddress, address _hubAddress){
        tokenAddress = _tokenAddress;
        hubAddress = _hubAddress;
        thisContract = address(this);
        operator = msg.sender;
    }

    modifier onlyOpen{
        require(status == true, "Not open");
        _;
    }
    modifier onlyOperator(){
        require(msg.sender == operator, "You are not the operator");
        _;
    }
    modifier TokenHolder(){
        require(IToken(tokenAddress).balanceOf(msg.sender) > 0,"You don't have any tokens");
        _;
    }
    modifier ActiveSeller(address _seller){
        require(activeSeller[_seller] == true, "Seller in inactive");
        _;
    }

    function getRecordArraySize() public view returns(uint256){
        return recordArray.length;
    }

    function setStoreMessage(string memory _welcomemessage) public onlyOperator{
        welcomemessage = _welcomemessage;
        } 

    
    function setStatus(bool _status) public onlyOperator{
        status = _status;
        if(status)
        session = session+1;
    }

    function getSession() public view returns (uint){
        return session; 
    }





    function createActivationCode(string memory _activationHash) public onlyOperator{
        activationString = _activationHash;
    }

    function getActivationString() public view returns(string memory){
        return activationString;
    }

    function activateStore(string memory _name, string memory _location) public onlyOperator{
        IHub(hubAddress).writePosition(_name, _location);
    }

    function createMenuItem(string[] memory _item, string[] memory _price) public onlyOperator {
        for(uint i = 0; i < _item.length;i++){
        menuItems.push(_item[i]);
        menuArray.push(Menu({   
            menuItem: _item[i],
            menuPrice: _price[i]
        }));
        }
        
    }

    function getMenu() public view returns(string [] memory){
        return menuItems;
    }

    function getMenuArray() public view returns (Menu[] memory){
        return menuArray;
    }

    function createSeller(address _seller, uint _sellerId) public onlyOperator {
        require(existingSeller[_seller] == false, "Seller already exist");
        sellerArray.push(_seller);
        numberArray.push(_sellerId);
        sellerMap[_seller].seller = _seller;
        sellerMap[_seller].sellerId = _sellerId;
        existingSeller[_seller] = true;
    }

    function updateSellers(address[] memory _seller, uint[] memory _sellerId) public{
        delete sellerArray;
        delete numberArray;
        for(uint i =0; i<_seller.length; i++){
            sellerArray.push(_seller[i]);
            numberArray.push(_sellerId[i]);
        }
    }

    function getSellers() public view returns(address[] memory){
        return sellerArray;
    }
    function getSellerNumbers() public view returns(uint[] memory){
        return numberArray;
    }
    function deleteSeller(address _seller) public onlyOperator{
        for(uint i = 0; i < sellerArray.length; i++ ){
            if(sellerArray[i] == _seller){
                sellerArray[i] = sellerArray[sellerArray.length - 1];
                numberArray[i] = numberArray[numberArray.length - 1];
                sellerArray.pop();
                numberArray.pop();
                delete sellerMap[sellerArray[i]];
            }}
    }
    function deleteAllSellers() public onlyOperator{
        delete sellerArray;
        delete numberArray;
    }
    function activateSeller(address _seller) public onlyOperator{
        activeSeller[_seller] = true;
    }
    function deactivateSeller(address _seller) public onlyOperator{
        activeSeller[_seller] = false;
    }
    function deactivateSellers(address [] memory _seller) public view onlyOperator{
        for (uint i=0; i < sellerArray.length; i++){
            if(sellerArray[i] == _seller[i]){
                activeSeller[_seller[i]] == false;
            }}
    }


    function addSale(
        address _seller,
        uint _sellerId,
        string memory _items,
        uint _tip,
        uint cost,
        bytes32 _code,
        string memory _location
    ) public ActiveSeller(_seller){
        require(_sellerId == sellerMap[_seller].sellerId, "Seller id does not match");
        //require(itemTotal >= cost, "You're trying to send less than the cost");
        require(IToken(tokenAddress).balanceOf(msg.sender) > (_tip + cost));
        require(status);
        recordArray.push(Record({
        seller: _seller,
        sellerId: _sellerId,
        items: _items,
        completed: false,
        code: _code,
        tip: _tip,
        location:_location,
        sessionId: session
        }));
        IToken(tokenAddress).transferFrom(msg.sender,thisContract, cost);
        if(_tip>0){
        IToken(tokenAddress).transferFrom(msg.sender,_seller, _tip);    
        }
    }

    function completeSale(string memory _code, uint _id) public ActiveSeller(msg.sender)returns (bytes32){
        require(recordArray[_id].completed == false,"Already accepted");
        require(sha256(abi.encodePacked(_code)) == recordArray[_id].code, "Wrong code");
        recordArray[_id].completed = true;
        return sha256(abi.encodePacked(_code));
    }

    function returnToCustomer(address _customer) public payable onlyOperator{
        IToken(tokenAddress).transferFrom(msg.sender,_customer, msg.value);
    }
    function getTokenBalance() public view returns (uint){
        return IToken(tokenAddress).balanceOf(msg.sender);
    }

}