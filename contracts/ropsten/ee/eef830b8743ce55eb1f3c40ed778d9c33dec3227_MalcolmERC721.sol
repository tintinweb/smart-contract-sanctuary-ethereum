pragma solidity ^0.8.14;

import "./Counters.sol";

interface ERC721 {
    //fns
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address to, uint256 tokenId) external payable;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    //events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

contract Pausible {
    event PausedEvent(address account);
    event UnpausedEvent(address account);
    bool private paused;

    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public whenNotPaused {
        paused = true;
        emit PausedEvent(msg.sender);
    }

    function unpause() public whenPaused {
        paused = false;
        emit UnpausedEvent(msg.sender);
    }
}

contract MalcolmERC721 is ERC721, Pausible {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _name;
    string private _symbol;
    Art[] public arts;
    uint256 private pendingArtCount;
    mapping( uint256 => address ) private _tokenOwner;
    mapping( address => uint256 ) _ownedTokensCount;
    mapping( uint256 => address ) private _tokenApprovals;
    mapping( address => mapping( address => bool ) ) private _operatorApprovals;
    mapping( uint256 => ArtTxn[] ) private artTxns;
    //uint256 public index;

    event LogArtTokenCreate(uint _tokenId, string _title, string _category, string _authorName,
                    uint256 _price, address _author, address _current_owner);
    event LogArtSold(uint _tokenId, string _title, string _authorName, uint256 _price, address _author, 
                    address _current_owner, address _buyer);
    event LogArtResell(uint _tokenId, uint _status, uint256 _price);

    struct Art {
        uint256 id;
        string title;
        string description;
        uint256 price;
        string date;
        string authorName;
        address payable author;
        address payable owner;
        uint status;
        string image;
    }

    struct ArtTxn {
       uint256 id; 
       uint256 price;
       address seller;
       address buyer;
       uint txnDate;
       uint status;
    }

    constructor() {
        _name = "MalcolmERC721";
        _symbol = "M721";
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function isOwnerOf(uint256 tokenId, address account) public view returns (bool) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner == account;
    }

    function isApproved(address to, uint256 tokenId) private view returns (bool) {
        return _tokenApprovals[tokenId] == to;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _ownedTokensCount[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address _owner) {
        _owner = _tokenOwner[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        _ownedTokensCount[to]++;
        _ownedTokensCount[from]--;
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function transfer(address to, uint256 tokenId) public {
        require(to != address(0));
        require(isOwnerOf(tokenId, msg.sender));
        _transfer(msg.sender, to, tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        //not impltd
        return;
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable {
        //not impltd
        return;
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable {
        require(to != address(0));
        require(isOwnerOf(tokenId, from));
        require(isApproved(to, tokenId));
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external payable {
        //approve another entity's permission in order to transfer token on owner's behalf
        require(isOwnerOf(tokenId, msg.sender));
        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function setApprovalForAll(address operator, bool approved) external{
        //enable/disable the approval of a third party(operator) to manage all assets for msg.sender
        require(operator != msg.sender);
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        //gets approved address for a single NFT
        require(_exist(tokenId));
        return _tokenApprovals[tokenId];
    }

    function _exist(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        //check if another address is allowed for an operator
        return _operatorApprovals[owner][operator];
    }

    function createTokenAndSellArt(string memory _title, string memory _desc, string memory _date,
            string memory _authorName, uint256 _price, string memory _image) public {
        //Not impltd yet
        uint256 _tokenId;
        //emit LogArtTokenCreate(_tokenId, _title, _date, _authorName, _price, msg.sender, msg.sender);
        //index++;
        _tokenIdTracker.increment();
        pendingArtCount++;
        return;
    }

    function buyArt(uint256 tokenId) payable public {
        //Not impltd yet
        pendingArtCount--;
        //emit LogArtSold(_tokenId, _title, _authorName, _price, _author, _current_owner, msg.sender);
        return;
    }

    function resellArt(uint tokenId, uint256 price) payable public {
        require(msg.sender != address(0));
        require(isOwnerOf(tokenId, msg.sender));
        arts[tokenId].status = 1;
        arts[tokenId].price = price;
        pendingArtCount++;
        emit LogArtResell(tokenId, 1, price);
        return;
    }

    function findArt(uint256 tokenId) public view returns (
            uint256, string memory, string memory, uint256, uint status, string memory, 
            string memory, address, address payable, string memory) {
        Art memory art = arts[tokenId];
        return (art.id, art.title, art.description, art.price, art.status, art.date,
            art.authorName, art.author, art.owner, art.image);
    }

    function findAllArt() public view returns (
            uint256[] memory, address[] memory, address[] memory, uint[] memory) {
        uint256 arrLength = arts.length;
        uint256[] memory ids = new uint256[](arrLength);
        address[] memory authors = new address[](arrLength);
        address[] memory owners = new address[](arrLength);
        uint[] memory status = new uint[](arrLength);
        for (uint i = 0; i <= arrLength - 1; i++) {
            Art memory art = arts[i];
            ids[i] = art.id;
            authors[i] = art.author;
            owners[i] = art.owner;
            status[i] = art.status;
        }
        return (ids, authors, owners, status);
    }
    
    function findAllPendingArt() public view returns (
            uint256[] memory, address[] memory, address[] memory,  uint[] memory) {
        if (pendingArtCount == 0) {
            return (new uint256[](0),new address[](0), new address[](0), new uint[](0));  
        } 
        else {
            uint256 arrLength = arts.length;
            uint256[] memory ids = new uint256[](pendingArtCount);
            address[] memory authors = new address[](pendingArtCount); 
            address[] memory owners= new address[](pendingArtCount); 
            uint[] memory status = new uint[](pendingArtCount);
            uint256 idx = 0;
            for (uint i = 0; i <= arrLength - 1; i++) {
                Art memory art = arts[i];
                if (art.status == 1) {
                    ids[idx] = art.id;
                    authors[idx] = art.author;
                    owners[idx] = art.owner;
                    status[idx] = art.status; 
                    idx++;
                }
            }
            return (ids,authors, owners, status);
        }  
    }

    function findMyArts() public view returns (uint256[] memory myArts) {
        require(msg.sender != address(0));
        uint256 numOftokens = balanceOf(msg.sender);
        if (numOftokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory myArts = new uint256[](numOftokens);
            uint256 idx = 0;
            uint256 arrLength = arts.length;
            for (uint256 i = 0; i < arrLength; i++) {
                if (_tokenOwner[i] == msg.sender) {
                    myArts[idx] = i;
                    idx++;
                }
            }
            return myArts;
        }
    }

    function getArtAllTxns(uint256 tokenId) public view returns (
            uint256[] memory _id, uint256[] memory _price,address[] memory seller, 
            address[] memory buyer, uint[] memory _txnDate) {
        ArtTxn[] memory artTxnList = artTxns[tokenId];
        uint256 arrLength = artTxnList.length;
        uint256[] memory ids = new uint256[](arrLength);
        uint256[] memory prices = new uint256[](arrLength);
        address[] memory sellers = new address[](arrLength);
        address[] memory buyers = new address[](arrLength);
        uint[] memory txnDates = new uint[](arrLength);
        for (uint i = 0; i <= artTxnList.length - 1; i++) {
           ArtTxn memory artTxn = artTxnList[i];
           ids[i] = artTxn.id;
           prices[i] = artTxn.price; 
           sellers[i] = artTxn.seller; 
           buyers[i] = artTxn.buyer; 
           txnDates[i] = artTxn.txnDate; 
        }
        return (ids,prices,sellers,buyers, txnDates);
    }

    function burn(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _tokenOwner[tokenId];
        //clear approval
        _approve(address(0), tokenId);
        _ownedTokensCount[owner] -= 1;
        delete _tokenOwner[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function mint(address to) public {
        //mint w auto increment ID
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exist(tokenId));
        _ownedTokensCount[to]++;
        _tokenOwner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }


}