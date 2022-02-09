/**
 *Submitted for verification at Etherscan.io on 2022-02-08
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
    address location;
    address manager;
    address seller;
    //address [] verified_assets;

    struct Operator { address operator; address [] locations;}
    mapping(address => Operator)  public Operators;

    struct Location {address operator; address location; address [] managers; Asset[] assets;}
    mapping(address => Location)   public Locations;
    Location[] public locations;

    struct Manager {address location; address manager; address [] subManagers; address [] sellers;}
    mapping(address => Manager)   public Managers;

    struct Seller {address manager; bool active; address seller; string seller_name; uint sellerId;}
    mapping(address => Seller )  public Sellers;

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
    }

    modifier onlyNewOperator(){
        require(Operators[msg.sender].operator != msg.sender, 'Address already operator');
        _;}
    modifier OperatorAccess(){
        require(msg.sender == Operators[msg.sender].operator, 'Address not operator');
        _;}
    modifier LocationAccess(){
        require(msg.sender == Locations[msg.sender].location,'Address not location');
        _;}
    modifier ManagerAccess(){
        require(msg.sender == Managers[msg.sender].manager,'Address not manager');
        _;}
    modifier ActiveSeller(address _seller){
        require(Sellers[_seller].active == true);
        _;}
    modifier VerifiedAsset(address _asset){
        require(operatorAssets[_asset].verified == true);
        _;}
    modifier RegisteredAsset(address _asset){
        require(msg.sender == operatorAssets[_asset].asset);
        _;}    
    modifier TokenHolder(){
        require(IToken(tokenAddress).balanceOf(msg.sender) > 0,"You don't have any tokens");
        _;}
    

    function createOperator() public onlyNewOperator {
        Operators[msg.sender].operator = msg.sender;}
    function createLocation(address _location) public {
        Operators[msg.sender].locations.push(_location);
        Locations[_location].location = _location;
        Locations[_location].operator = msg.sender;}
    function createManager(address _manager) public {
        if(Managers[msg.sender].manager == msg.sender){
        //Sub-Manager
        Managers[msg.sender].subManagers.push(_manager);
        Managers[_manager].manager == msg.sender;
        Managers[_manager].location == msg.sender;
        }
        else{
        Locations[msg.sender].managers.push(_manager);
        Managers[_manager].manager == _manager;
        Managers[_manager].location == msg.sender;
        }}
    function createSeller(address _seller, string memory _seller_name, uint _sellerId) public {
        Sellers[msg.sender].manager = msg.sender;
        Sellers[msg.sender].active = false;
        Sellers[msg.sender].seller = _seller;
        Sellers[msg.sender].seller_name = _seller_name;
        Sellers[msg.sender].sellerId = _sellerId;
        Managers[msg.sender].sellers.push(_seller);}
    function createMenuItem(string memory _item, string memory _price) public{
        menus.push(Menu({
            item:_item,
            price:_price
        }));}
    function createMenu(Menu[] memory _items) public{
        for(uint i = 0; i < _items.length; i++ ){
            menus.push(_items[i]);
        }}
 
    function registerAsset(address _location) public {
        operatorAssets[msg.sender] = Asset(
            msg.sender, //asset
            0x000000000000000000000000000000000000dEaD, //verifier
            _location,
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
        operatorAssets[_asset].location = Locations[msg.sender].location;}
    function getLocations() public view returns(address[] memory){
        return Operators[msg.sender].locations;}
    function getManagers() public view returns(address[] memory){
        return Locations[msg.sender].managers;}
    function getSubManagers() public view returns(address[] memory){
        return Managers[msg.sender].subManagers;}
    function getSellers() public view returns(address[] memory){
        return Managers[msg.sender].sellers;}
    function getLocationManagers(address _myLocation) public view returns(address[] memory){
        //require(Locations[_myLocation].operator== msg.sender, 'Locations[_myLocation].operator != msg.sender');
        return Locations[_myLocation].managers;}
    function getManagersSellers(address _myManager) public view returns(address[] memory){
        require(Managers[_myManager].location == msg.sender);
        return Managers[_myManager].sellers;}
    function getMenu(address _manager) public view returns(Menu  memory){
        return LocationMenus[_manager];}
    function getAssetInfo(address _asset) public view returns(Asset memory){
        return operatorAssets[_asset];}
    function getAssets() public view returns(Asset[] memory){
        return Locations[msg.sender].assets;}
    function deleteLocation(address _location) public OperatorAccess{
         for(uint i = 0; i < Operators[msg.sender].locations.length; i++ ){
            if(Operators[msg.sender].locations[i] ==_location){
                delete Operators[msg.sender].locations[i];
            }}}
    function deleteManager(address _manager) public LocationAccess{
        for(uint i = 0; i < Locations[msg.sender].managers.length; i++ ){
            if(Locations[msg.sender].managers[i] ==_manager){
                delete Locations[msg.sender].managers[i];
            }}}
    function deleteSeller(address _seller) public ManagerAccess{
           for(uint i = 0; i < Managers[msg.sender].sellers.length; i++ ){
            if(Managers[msg.sender].sellers[i] ==_seller){
                delete Managers[msg.sender].sellers[i];
            }}}
    function deleteAllLocations() public OperatorAccess{
        delete Operators[msg.sender].locations;}
    function deleteAllManagers() public LocationAccess{
        delete Locations[msg.sender].managers;}
    function deleteAllSellers() public ManagerAccess{
        delete Managers[msg.sender].sellers;}
    function activateSeller(address _seller) public view ManagerAccess{
        require(msg.sender == Sellers[msg.sender].manager);
        Sellers[_seller].active == true;}
    function activateSellers(address [] memory _sellers) public view ManagerAccess{
         for (uint i=0; i <Managers[msg.sender].sellers.length; i++){
         if(Managers[msg.sender].sellers[i] ==_sellers[i]){
         Sellers[Managers[msg.sender].sellers[i]].active == true;
         }}}
    function deactivateSeller(address _seller) public view ManagerAccess{
        require(msg.sender == Sellers[msg.sender].manager);
        Sellers[_seller].active ==false;}
    function deactivateSellers(address [] memory _sellers) public view ManagerAccess{
        for (uint i=0; i <Managers[msg.sender].sellers.length; i++){
         if(Managers[msg.sender].sellers[i] ==_sellers[i]){
         Sellers[Managers[msg.sender].sellers[i]].active == false;
         }}}
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
    function checkDigiBalance() public view returns (uint){
        return IToken(tokenAddress).balanceOf(msg.sender);}
    function LocationCheck(address __location) public view returns (address){
        return Locations[__location].location;}
    function post(
        address __operator,
        address __location,
        uint __items,
        uint __customerLocation,
        uint __itemTotal,
        uint __deliveryFee,
        uint __blockDeadline) public{
        require(Locations[__location].location == __location, "You are trying to send to the wrong location");
        posts.push(Post({
            _operator:__operator,
            _customer: msg.sender,
            _location: __location,
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
        }
    }    
      
    
    function returnToCustomer(address _post) public {
        IToken(tokenAddress).transfer(PostOrders[_post]._customer,PostOrders[_post]._itemTotal);
    }










}