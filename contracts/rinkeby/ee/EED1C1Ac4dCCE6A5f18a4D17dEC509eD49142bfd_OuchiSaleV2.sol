/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

pragma solidity =0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _amount, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

contract OuchiSaleV2 {
    struct PurchaseRecord {
        uint256 tokenId;
        uint256 price;
        uint256 purchaseDate;
    }

    mapping(address => bool ) public owners;
    address stockHolder;
    address public erc1155addr;
    address public paymentTokenAddr;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => PurchaseRecord) public lastPurchased; //_merchandiseTokenAddr => PurchaseRecord
    mapping(uint256 => uint256) stocks;
   
    event SetPrice(uint256 tokenId, uint256 price);
    event Purchase(address indexed buyer, uint256 tokenId, uint256 amount, uint256 price, uint256 timestamp);

    modifier isOwner(){
        require(owners[msg.sender]);
        _;
    }
    
    constructor(address _erc1155addr, address _paymentTokenAddr, address _stockHolder) public{
        erc1155addr = _erc1155addr;
        paymentTokenAddr = _paymentTokenAddr;
        stockHolder = _stockHolder;
        owners[msg.sender] = true;
    }
    
    function setPrice(uint256 _tokenId, uint256 _price) external isOwner returns(bool){
        price[_tokenId] = _price;
        emit SetPrice(_tokenId, _price);
        return true;
    }
    
    function getNumStock(uint256 _tokenId) external view returns(uint256){
        uint256 bal = IERC1155(erc1155addr).balanceOf(stockHolder, _tokenId);
        return bal  < stocks[_tokenId] ? bal : stocks[_tokenId]; 
    }
    
    function setStock(uint256 _tokenId, uint256 amount) external isOwner returns(uint256){
        require(IERC1155(erc1155addr).isApprovedForAll(stockHolder, address(this)));
        stocks[_tokenId] += amount;
        return this.getNumStock(_tokenId);
    }
    
    function purchase(uint256 _tokenId, uint256 amount) external returns(bool){
        require(amount <= this.getNumStock(_tokenId), 'Not enough stock.');
        IERC20(paymentTokenAddr).transferFrom(msg.sender, stockHolder, price[_tokenId] * amount);
        IERC1155(erc1155addr).safeTransferFrom(stockHolder, msg.sender, _tokenId, amount, "");
        
        PurchaseRecord memory record = PurchaseRecord(_tokenId, price[_tokenId], block.timestamp);
        lastPurchased[_tokenId] = record;

        emit Purchase(msg.sender, _tokenId, amount, price[_tokenId], block.timestamp);
        
        return true;
    }
    
    function setOwner(address target) external isOwner {
        owners[target] = true;   
    }
    
    function removeOwner(address target) external isOwner {
        owners[target] = false;   
    }
}