/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.11;
 
contract OperatorMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "OperatorMath: addition overflow");
        return c;    }
 
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;}
            uint256 c = a * b;
            require(c / a == b, "OperatorMath: multiplication overflow");
            return c;}
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "OperatorMath: division by zero");
        uint256 c = a / b;
        return c;    }
}
 
interface IToken{
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function transfer(address receiver, uint tokens) external returns (bool success);
}
 
interface IAsset{}
 
contract OperatorContract is OperatorMath{
    address tokenAddress;
    address thisContract;
    address assetContract;
    address operator;
    address [] operatorLocations;
 
    struct Location {address _location; address [] _managers; Asset[] assets;}
    struct Manager  {address _location; address _manager; address [] subManagers; address [] sellers;}
    struct Seller {address manager; bool active; address seller; string seller_name; uint sellerId;}
 
    mapping(address => Location) locations;
    mapping(address => Manager) managers;
    mapping(address => Seller )  sellers;
 
    struct Record {address operator; string items; string sellerId; string customerLocation; string customer;}
    mapping(address => Record) RecordOwners;
    Record[] public records;
 
    struct Post {
        address _customer;
        address _operator;
        address _location;
        uint _items;
        uint _customerLocation;
        bool _accepted;
        uint _acceptanceDeadline;
        address _asset;
        uint _deliveryDeadline;
        bool _delivered;
        bool _received;
        uint _itemTotal;
        uint _deliveryFee;}
    mapping(address => Post) PostOrders;
    Post[] public posts;
 
    struct Menu {string item; string price;}
    mapping (address => Menu) LocationMenus;
    Menu[] public menus;
 
    struct Asset {address asset; address location; address verifier; bool verified; uint expiration; uint assetRate; uint assetRange; uint assetRating; uint balance;}
    mapping(address => Asset) operatorAssets;
    Asset[] public asset_array;
 
    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        thisContract = address(this);
        operator = msg.sender;
    }
 
   
 
 
   modifier onlyOperator(){
        require(msg.sender == operator, "You are not the operator");
        _;}
    modifier LocationAccess(){
        require(msg.sender == locations[msg.sender]._location || msg.sender == operator,'Address not location or operator');
        _;}
    modifier ManagerAccess(){
        require(msg.sender == managers[msg.sender]._manager,'Address not manager');
        _;}
    modifier ActiveSeller(address _seller){
        require(sellers[_seller].active == true);
        _;}
    modifier VerifiedAsset(address _asset){
        require(operatorAssets[_asset].verified == true);
        _;}
    modifier RegisteredAsset(address _asset){
        require(msg.sender == operatorAssets[_asset].asset);
        _;}    
    modifier TokenHolder(){
        require(IToken(tokenAddress).balanceOf(msg.sender) > 0,"You don't have any tokens");
        _;
    }
   
 
   
    function createLocation(address location) public LocationAccess{
        operatorLocations.push(location);
        locations[msg.sender]._location = location;
        }
    function createManager(address manager) public {
        if(managers[msg.sender]._manager == msg.sender){
        //Sub-Manager
        managers[msg.sender].subManagers.push(manager);
        managers[manager]._manager == msg.sender;
        managers[manager]._location == msg.sender;
        }
        else{
        locations[msg.sender]._managers.push(manager);
 
        }}
    function createSeller(address seller, string memory _seller_name, uint _sellerId) public {
        managers[seller].sellers.push(seller);
        sellers[seller].manager = msg.sender;
        sellers[seller].active = false;
        sellers[seller].seller = seller;
        sellers[seller].seller_name = _seller_name;
        sellers[seller].sellerId = _sellerId;}
    function createMenuItem(string memory _item, string memory _price) public{
        menus.push(Menu({
            item:_item,
            price:_price
        }));}
    function createMenu(Menu[] memory _items) public{
        for(uint i = 0; i < _items.length; i++ ){
            menus.push(_items[i]);
        }
    }
 
    function getLocations() public view returns(address[] memory){
        return operatorLocations;}
    function getManagers() public view returns(address[] memory){
        return locations[msg.sender]._managers;}
    function getSubManagers() public view returns(address[] memory){
        return managers[msg.sender].subManagers;}
    function getsellers() public view returns(address[] memory){
        return managers[msg.sender].sellers;}
    function getLocationManagers(address _myLocation) public view returns(address[] memory){
        //require(locations[_myLocation].operator== msg.sender, 'locations[_myLocation].operator != msg.sender');
        return locations[_myLocation]._managers;}
    function getManagerssellers(address _myManager) public view returns(address[] memory){
        require(managers[_myManager]._location == msg.sender);
        return managers[_myManager].sellers;}
    function getMenu(address _manager) public view returns(Menu  memory){
        return LocationMenus[_manager];}
    function getAssetInfo(address _asset) public view returns(Asset memory){
        return operatorAssets[_asset];}
    function getAssets() public view returns(Asset[] memory){
        return locations[msg.sender].assets;
    }
   
    //Delete functions
    function deleteLocation(address _location) public onlyOperator{
         for(uint i = 0; i < operatorLocations.length; i++ ){
            if(operatorLocations[i] ==_location){
                operatorLocations[i] = operatorLocations[operatorLocations.length - 1];
                operatorLocations.pop();
                delete locations[_location]._managers;
                delete managers[_location].sellers;
            }}}
    function deleteManager(address manager) public LocationAccess{
        for(uint i = 0; i < locations[msg.sender]._managers.length; i++ ){
            //Regular Manager
            if(locations[msg.sender]._managers[i] == manager){
                address toDelete = locations[msg.sender]._managers[i];
                address [] storage arraytoDelete = locations[msg.sender]._managers;
                toDelete = arraytoDelete[arraytoDelete.length - 1];
                arraytoDelete.pop();
                delete managers[manager].sellers;
            }else{
                address toDelete = managers[manager].subManagers[i];
                address [] storage arraytoDelete = managers[manager].subManagers;
                toDelete = arraytoDelete[arraytoDelete.length - 1];
                arraytoDelete.pop();
                delete managers[manager].sellers;
            }}}
    function deleteSeller(address _seller) public ManagerAccess{
           for(uint i = 0; i < managers[msg.sender].sellers.length; i++ ){
            if(managers[msg.sender].sellers[i] ==_seller){
                delete managers[msg.sender].sellers[i];
            }}}
    function deleteAllLocations() public onlyOperator{
        delete operatorLocations;}
    function deleteAllManagers() public LocationAccess{
        delete locations[msg.sender]._managers;}
    function deleteAllsellers() public ManagerAccess{
        delete managers[msg.sender].sellers;
    }
 
    //Activate/Deactivate functions    
    function activateSeller(address _seller) public view ManagerAccess{
        require(msg.sender == sellers[msg.sender].manager);
        sellers[_seller].active == true;}
    function activatesellers(address [] memory _sellers) public view ManagerAccess{
         for (uint i=0; i <managers[msg.sender].sellers.length; i++){
         if(managers[msg.sender].sellers[i] ==_sellers[i]){
         sellers[managers[msg.sender].sellers[i]].active == true;
         }}}
    function deactivateSeller(address _seller) public view ManagerAccess{
        require(msg.sender == sellers[msg.sender].manager);
        sellers[_seller].active ==false;}
    function deactivatesellers(address [] memory _sellers) public view ManagerAccess{
        for (uint i=0; i <managers[msg.sender].sellers.length; i++){
         if(managers[msg.sender].sellers[i] ==_sellers[i]){
         sellers[managers[msg.sender].sellers[i]].active == false;
         }}
    }
 
    //Registration/Verification functions
    function registerAsset(address location) public {
        operatorAssets[msg.sender] = Asset(
            msg.sender, //asset
            0x000000000000000000000000000000000000dEaD, //verifier
            location,
            false, //verified
            0, //expiration
            0, //MiniMuMrate
            0, //region
            100, //rating
            IToken(tokenAddress).balanceOf(msg.sender)); //balance
    }    
    function verifyAsset(address _asset, uint _expiration) public LocationAccess{
        operatorAssets[_asset].verifier = msg.sender;  
        operatorAssets[_asset].verified = true;
        operatorAssets[_asset].expiration = _expiration;
        operatorAssets[_asset].location = managers[msg.sender]._location;
    }
   
    //Monetary functions
    function addSale(
        address _operator,
        address _seller,
        string memory _items,
        string memory _sellerId,
        string memory _customerLocation,
        string memory _customer,
        uint itemTotal,
        uint cost
        //uint _burnAmount
        ) public ActiveSeller(_seller){
        require(itemTotal >= cost);
        records.push(Record({
            operator: _operator,
            items: _items,
            sellerId: _sellerId,
            customerLocation: _customerLocation,
            customer: _customer
        }));
        //_burnAmount = mul((div(current_rate,100000000000000000)),msg.value);
        //emit Burn(msg.sender, _burnAmount);
        IToken(tokenAddress).transfer(thisContract, cost);}
    function getToeknBalance() public view returns (uint){
        return IToken(tokenAddress).balanceOf(msg.sender);}
   
    function post(
        address __operator,
        address tolocation,
        uint __items,
        uint __customerLocation,
        uint __itemTotal,
        uint __deliveryFee,
        uint __blockDeadline) public{
        require(locations[tolocation]._location == tolocation, "You are trying to send to the wrong location");
        posts.push(Post({
            _operator:__operator,
            _customer: msg.sender,
            _location: tolocation,
            _items: __items,
            _customerLocation: __customerLocation,
            _accepted: false,
            _acceptanceDeadline: __blockDeadline,
            _deliveryDeadline: __blockDeadline + 450,
            _delivered: false,
            _received: false,
            _itemTotal:__itemTotal,
            _deliveryFee:__deliveryFee,
            _asset:0x000000000000000000000000000000000000dEaD
        }));
        bool success = IToken(tokenAddress).transferFrom(msg.sender,thisContract,__itemTotal);
        require(success,"Transaction was not sucessful");}
//driver accepting order - to Timelock
//expiration must be greater than block.number
    function accept(address _customer, uint _amount) public RegisteredAsset(msg.sender) returns (address){
        require(block.number < PostOrders[_customer]._acceptanceDeadline, "This customer has waited too long");
        if(operatorAssets[msg.sender].verified == false){
        require(_amount == PostOrders[_customer]._itemTotal);
        bool success = IToken(tokenAddress).transferFrom(msg.sender,thisContract,_amount);
        require(success ,"This transaction failed")  ;
        }else{
          PostOrders[_customer]._accepted = true;
          PostOrders[_customer]._asset = msg.sender;
        }
        return (PostOrders[_customer]._operator);
        //require(_time == post.time);
        //require(msg.sender == _verified_asset[i]);
        }
 
    function delivered(address customer)public{
        PostOrders[customer]._delivered = true;}
    function received(address _operator, string memory _items, string memory _sellerAddress) public {
         records.push(Record({
             operator: _operator,
             items: _items,
             sellerId: _sellerAddress,
             customerLocation: "null",
             customer: "null"
         }));
        bool success = IToken(tokenAddress).transferFrom(thisContract, (PostOrders[msg.sender]._asset),(PostOrders[msg.sender]._deliveryFee));
        require(success, "Transaction failed");
        delete PostOrders[msg.sender];}
    function cancelPost(address _post) public {
        if(msg.sender == PostOrders[_post]._customer){
        require(PostOrders[_post]._accepted == false, "The order has already been accepted");
        delete PostOrders[_post];}
        if(msg.sender == PostOrders[_post]._asset){
        require(PostOrders[_post]._accepted == false, "The order has already been accepted");
        delete PostOrders[_post];    
        }
        if(msg.sender == PostOrders[_post]._location || msg.sender == PostOrders[_post]._operator){
        delete PostOrders[_post];  
        }}    
     
   
    function returnToCustomer(address _post) public {
        IToken(tokenAddress).transfer(PostOrders[_post]._customer,PostOrders[_post]._itemTotal);
    }
 
 
 
 
 
 
 
 
 
 
}