/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address _to, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RealBuilding {

    struct Property {
        uint256 marketPrice;
        uint256 lvl;
        bool onsale;
        uint256 timestamp;
        address owner;
    }

    struct TokenInfo {
        IERC20 token;
    }

    TokenInfo[] public allowedCrypto;

    // uint public bank;
    uint SHARE_SPLIT;
    uint SHARE_AMOUNT_SPLIT;

    mapping(address => uint256) public bank; // uid => amount
    // mapping(uint => uint) TAXES;
    uint public SHARE_RATE; 
    uint public UID;
    address private owner;
    uint256 propertyCounter;
    uint256 MAX_PROPERTIES;
    uint256 PRICE;
    // uint256 LAST_PRICE;
    bool locked = false;

    mapping(uint256 => Property) public properties;
    mapping(address => mapping(address => uint256)) public balances;

    event PropertyMinted(uint256 indexed propertyId, address indexed owner, uint256 price);
    event PropertyPriceUpdated(uint256 indexed propertyId, uint256 newPrice);
    event PropertyListedForSale(uint256 indexed propertyId, bool indexed isForSale, uint256 indexed price);
    event PropertyPurchased(uint256 indexed propertyId, address indexed newOwner, uint256 price);

    function getTokens() external view returns(address[] memory list) {
        address[] memory listTokens;

        for(uint i = 0 ; i< allowedCrypto.length ;i++){
            listTokens[i] = address(allowedCrypto[i].token);
        }

        return listTokens;    
    }

    // 0xedcce4020e8f2f84a4b923d3d3f2c4e2906d2c48 sepolia usdt_TEST
    // 
    constructor(address _addr) {

        owner = msg.sender;
        // allowedCrypto.push(
        //     TokenInfo({token: IERC20(address(0x55d398326f99059fF775485246999027B3197955))}) // USDT_BSC
        // );
        allowedCrypto.push(
            TokenInfo({token: IERC20(_addr)}) // USDT_BSC
        );

        UID = 0;
        bank[address(allowedCrypto[UID].token)] = 0;
        propertyCounter = 0;
        MAX_PROPERTIES = 1000; // 
        PRICE = 5 ether; 
        SHARE_RATE = 0; 
        SHARE_SPLIT = 5120000;
        SHARE_AMOUNT_SPLIT = 0;
        freashMint();
    } 

    function freashMint() internal {
        for(uint i=0; i< 10; i++ ){
            mint(10240, owner);
        }
    }

    fallback() external payable {}

    receive() external payable {}

    function getEthBalance() external view returns(uint256){
        return address(this).balance;
    }

    function withdrawEth() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier propertyExists(uint256 _id) {
        require(_id < propertyCounter, "Invalid property ID");
        _;
    }

    modifier ownerOf(uint _id, address _sender) {
        require(_id < propertyCounter, "Invalid property ID");
        require(properties[_id].owner == _sender, "Not property owner");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    function updatePrice() internal {
        if(SHARE_AMOUNT_SPLIT < SHARE_RATE){
            SHARE_AMOUNT_SPLIT += SHARE_SPLIT; // 1) 0 + 512 2) 512 + 256 3) 768 + 128
            SHARE_SPLIT /= 2; // 1) 2560 2) 1280 3) 560 4) 320) 5) 160 6) 80 7) 60 8) 40 9) 20 10) 10,000
            PRICE *=2; // 1) 5*2=10 2) 20 3) 40 4) 80 5) 160 6) 320 7) 640 8) 1280 9)2560 10)5,012
        }
    }

    function getPropertyAddress(uint _id) external view propertyExists(_id) returns(address) {
        return properties[_id].owner;
    }

    function getPropertyLevel(uint _id) external view propertyExists(_id) returns(uint) {
        return properties[_id].lvl;
    }

    function mintProperty(uint _lvl) external noReentrancy {
        updatePrice();
        require(_lvl <= 10240 && _lvl > 0 , "lvl 1 to 100 required");
        require(propertyCounter <= MAX_PROPERTIES,"Exided max properties");
        _allowance(msg.sender, PRICE * _lvl);
        _transferFrom(msg.sender, address(this), PRICE * _lvl);
        balances[address(allowedCrypto[UID].token)][owner] += PRICE * _lvl;
        
        mint(_lvl, msg.sender); 
    }

    function mint(uint _lvl, address _msgSender) internal {
        Property storage prop = properties[propertyCounter];
        prop.marketPrice = PRICE * _lvl;
        prop.lvl = _lvl; 
        prop.onsale = false;
        prop.owner = payable(_msgSender);
        prop.timestamp = block.timestamp;
        propertyCounter++;
        SHARE_RATE += _lvl; 
    }

    // # used in a private sale
    function transferToAddress(uint _id, address _to) public ownerOf(_id, msg.sender) noReentrancy{
        if(properties[_id].owner != owner){
            _allowance(msg.sender, 1000 ether);
            _transferFrom(msg.sender, address(this), 1000 ether);
            balances[address(allowedCrypto[UID].token)][owner] += 1000 ether;
        }

        properties[_id].owner = payable(_to);
        properties[_id].timestamp = block.timestamp;
    }

    function _allowance(address _from, uint _amount) internal view {
        require(allowedCrypto[UID].token.balanceOf(_from) >= _amount, "Insufficent balance");
        require(allowedCrypto[UID].token.allowance(_from, address(this)) >= _amount, "insuficent allowance");

    }
    function _transferFrom(address _from, address _to, uint _amount) internal {
        require(allowedCrypto[UID].token.transferFrom(_from, _to, _amount), "Transfer Fail" );
    }

    function purchaseProperty(uint256 _id) external propertyExists(_id) noReentrancy {
        updatePrice();
        Property storage prop = properties[_id];
        require(prop.onsale == true);

        uint256 tax;
        if(prop.lvl > 10000){
            tax = prop.marketPrice / 100;
        } else {
            tax = (prop.marketPrice * 20) / 100; // PRICE  10$ LVL 70 4 = 9$
        }

        uint256 amount = prop.marketPrice - tax;
        uint levelsUp = tax / PRICE; 
        _transferFrom(msg.sender, address(this), tax);
        _transferFrom(msg.sender, prop.owner, amount);


        if(prop.owner == owner){
            SHARE_RATE += prop.lvl;
        }

        balances[address(allowedCrypto[UID].token)][owner] += amount;
        prop.owner = payable(msg.sender);
        prop.timestamp = block.timestamp;  
        upgrade(levelsUp ,_id);
                
        emit PropertyPurchased(_id, msg.sender, prop.marketPrice);
    }

    function hijackProperty(uint _id) external propertyExists(_id) noReentrancy {
        updatePrice();
        Property storage prop = properties[_id];
        require(prop.lvl < 10000, "none hijactable");
        require(prop.timestamp + 35 days <= block.timestamp, "can't hijact prop.timestamp" );

        uint price = prop.lvl * PRICE;
        uint256 tax = (prop.lvl * PRICE) / 100;
        uint256 tax1 = (price/100) * 12;
        uint256 tax2 = (price/100) * 20;

        // uint256 amount = price + tax1 + tax2;
        uint256 sum = tax2 / PRICE;

        _transferFrom(msg.sender, prop.owner, price + tax1);
        _transferFrom(msg.sender, address(this), tax2);

        balances[address(allowedCrypto[UID].token)][owner] += tax;
        prop.owner = payable(msg.sender);
        prop.timestamp = block.timestamp;  
        
        if(sum >= 1){
            upgrade( sum, _id);
        }
    }

    function upgrade(uint amount, uint _id) internal {

        Property storage prop = properties[_id];

        if(amount * PRICE >= 500 ether) {
            prop.timestamp = block.timestamp; 
        }

        if(prop.lvl + amount >= 10240) {
            SHARE_RATE += amount - ((prop.lvl + amount) - 10240);
            prop.lvl = 10240;
        } else {
            prop.lvl += amount; 
            SHARE_RATE += amount;
        }
    }

    function upgradeProperty(uint _id, uint _amount) external noReentrancy ownerOf(_id, msg.sender) {
        updatePrice();
        Property memory prop = properties[_id];
        require(prop.owner != owner);
        require(_amount >= 1 && _amount <= 100, "upgrade up to 100 lvls");
        require(_amount + prop.lvl <= 1000, "Max level hit");
        require(prop.lvl > 0, "Property dosn't exist");
        _allowance(msg.sender, _amount * PRICE);
        _transferFrom(msg.sender, address(this), _amount);
        balances[address(allowedCrypto[UID].token)][owner] += _amount;
        upgrade(_amount, _id);
    }

    function buyFromBank(uint _id) public {
        require(properties[_id].owner == address(this));
        uint price = PRICE * properties[_id].lvl;    
        _allowance(msg.sender, price);
        _transferFrom(msg.sender, address(this), price);
        bank[address(allowedCrypto[UID].token)] += price;
        properties[_id].owner = msg.sender;
        properties[_id].timestamp = block.timestamp;
    }

    function sellToBank(uint _id, uint _uid) external propertyExists(_id) noReentrancy ownerOf(_id , msg.sender) {
        updatePrice();
        Property storage prop = properties[_id];
        uint price = prop.lvl * PRICE;
        require(prop.lvl >= 10000, "allowed in lvl 10000 only");
        require(prop.owner == msg.sender);
        require(bank[address(allowedCrypto[_uid].token)] >= price);
        
        uint256 priceFloor = (price * 20) / 100;
        bank[address(allowedCrypto[_uid].token)] -= price;
        balances[address(allowedCrypto[_uid].token)][prop.owner] += (price - priceFloor);
        prop.owner = address(this);
        prop.marketPrice = price;
        prop.onsale = true;
        SHARE_RATE -= prop.lvl;
    }

    function uploadPropertyForSale(uint _id, uint256 _price) external noReentrancy ownerOf(_id, msg.sender) {
        Property storage prop = properties[_id];
        require(prop.owner == msg.sender, "You are not the owner of the property");
        require(prop.lvl > 0, "you can't upload this property for sale under level 10");

        prop.marketPrice = _price;
        prop.onsale = true;

        emit PropertyListedForSale(_id, true, _price);
    }

    function cancelPropertySale(uint _id) external ownerOf(_id, msg.sender) {
        Property storage prop = properties[_id];
        prop.onsale = false;

        emit PropertyListedForSale(_id, false, 0);
    }

    function getBalance() external view returns(uint256){
        return balances[address(allowedCrypto[UID].token)][msg.sender];
    }

    // function getSharePrice() external {
    //     return PRICE;
    // }

    function withdrawBalance(uint _uid) external {
        uint256 amount = balances[address(allowedCrypto[_uid].token)][msg.sender];
        require(amount > 0, "No balance available for withdrawal");

        balances[address(allowedCrypto[_uid].token)][msg.sender] = 0;
        
        require(allowedCrypto[_uid].token.transfer(
            msg.sender, 
            amount
        ), "Transfer failed");    
    }

    function depositeContract(uint _uid, uint256 _amount) public {
        require(allowedCrypto[_uid].token.balanceOf(msg.sender) >= _amount);
        require(allowedCrypto[_uid].token.allowance(msg.sender, address(this)) >= _amount);
        require(allowedCrypto[_uid].token.transferFrom(
            msg.sender,
            address(this), 
            _amount
        ), "Transfer failed");
        balances[address(allowedCrypto[_uid].token)][msg.sender] += _amount;

    }

    function depositePropertyOwner(uint256 _id, uint256 _amount, uint _uid) public onlyOwner  {
        require(allowedCrypto[_uid].token.balanceOf(msg.sender) >= _amount, "not enaugh funds");
        require(allowedCrypto[_uid].token.allowance(msg.sender, address(this)) >= _amount, "allownce not valid");        
        require(balances[address(allowedCrypto[_uid].token)][msg.sender] >= _amount);
        balances[address(allowedCrypto[_uid].token)][msg.sender] -= _amount;
        balances[address(allowedCrypto[_uid].token)][properties[_id].owner] += _amount;
    }

    function addCurenecy(address _token) onlyOwner public  {
        allowedCrypto.push(
            TokenInfo({token: IERC20(_token)})
        );
    }

    function plusPropertyBank(uint256 _amount, uint _uid) public onlyOwner {
        require(balances[address(allowedCrypto[_uid].token)][msg.sender] >= _amount, "Low amount");
        balances[address(allowedCrypto[_uid].token)][msg.sender] -= _amount;
        bank[address(allowedCrypto[_uid].token)] += _amount;
    }

    function minusPropertyBank(uint256 _amount, uint _uid) public onlyOwner {
        require(bank[address(allowedCrypto[_uid].token)] >= _amount, "Low amount");
        bank[address(allowedCrypto[_uid].token)] -= _amount;
        balances[address(allowedCrypto[_uid].token)][msg.sender] += _amount;
    }

    function getLowestPriceAvilable() public view returns(uint256 _id) {
        uint lowPrice = 1000000 ether;
        uint lowId = 0;
        for(uint i = 0; i < propertyCounter; i++){
            if(properties[i].onsale){
                if(lowPrice > properties[i].marketPrice){
                    lowPrice = properties[i].marketPrice;
                    lowId = i;
                }
            }
        }
        return lowId;
    }

    function getShareRate() external view returns(uint) {
        return SHARE_RATE;
    }
        
    function getTokenAddressByUid(uint _uid) public view returns(address) {
        require(_uid < allowedCrypto.length, "Uid number doesnt exist" );
        return address(allowedCrypto[_uid].token);
    }

    function getPropertyPrice(uint _id) internal view propertyExists(_id) returns(uint256 price)  {
        return properties[_id].lvl * PRICE;
    }
    
    function setTradingUid(uint _uid) public onlyOwner {
        UID = _uid;
    }
}