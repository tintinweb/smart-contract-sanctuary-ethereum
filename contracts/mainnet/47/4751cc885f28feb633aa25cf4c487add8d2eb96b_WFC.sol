/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

interface IERC20{
         
    function transfer(address recipient, uint256 amount) external;
    
}

abstract contract OMS { //Orcania Management Standard

    address private _owner;
    mapping(address => bool) private _manager;

    event OwnershipTransfer(address indexed newOwner);
    event SetManager(address indexed manager, bool state);

    receive() external payable {}

    constructor() {
        _owner = msg.sender;
        _manager[msg.sender] = true;

        emit SetManager(msg.sender, true);
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }

    modifier Manager() {
      require(_manager[msg.sender], "OMS: MOT_MANAGER");
      _;  
    }

    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }

    function manager(address user) external view returns(bool) {
        return _manager[user];
    }

    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }

    function setManager(address user, bool state) external Owner {
        _manager[user] = state;
        emit SetManager(user, state);
    }

    //===============
    
    function withdraw(address payable to, uint256 value) external Manager {
        sendValue(to, value);  
    }

    function withdrawERC20(address token, address to, uint256 value) external Manager {
        IERC20(token).transfer(to, value);   
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "UNABLE_TO_SEND_VALUE RECIPIENT_MAY_HAVE_REVERTED");
    }

}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
}

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
    
    function totalSupply() external view returns(uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

abstract contract OERC721 is OMS, ERC165, IERC721, IERC721Metadata{ //OrcaniaERC721 Standard
    using Strings for uint256;

    string internal uriLink = "https://server.worldfantasycup.com/metadata?id=";
    
    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals;

    //Read Functions======================================================================================================================================================
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() external view override returns(uint256){return _totalSupply;}

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        return string(abi.encodePacked(uriLink, tokenId.toString()));

    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokensOf(address user, uint256 limit) external view returns(uint256[] memory nfts) {
        nfts = new uint256[](limit);
        uint256 index;

        for(uint256 t=1; t <= _totalSupply && index < limit; ++t) {
            if(_owners[t] == user) {nfts[index++] = t;}
        }
    }
    
    //Moderator Functions======================================================================================================================================================

    function changeURIlink(string calldata newUri) external Manager {
        uriLink = newUri;
    }

    function changeData(string calldata name, string calldata symbol) external Manager {
        _name = name;
        _symbol = symbol;
    }

    function adminMint(address to, uint256 amount) external Manager {
        _mint(to, amount);
    }

    function adminMint(address[] calldata to, uint256[] calldata amount) external Manager {
        uint256 size = to.length;

        for(uint256 t; t < size; ++t) {
            _mint(to[t], amount[t]);
        }
    }

    //User Functions======================================================================================================================================================
    function approve(address to, uint256 tokenId) external override {
        address owner = _owners[tokenId];

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    //Internal Functions======================================================================================================================================================
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        require(spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender), "ERC721: Not approved or owner");
        return true;
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _mint(address user, uint256 amount) internal {
        uint256 tokenID = _totalSupply;

        _balances[user] += amount;
        _totalSupply += amount;
        
        for(uint256 t; t < amount; ++t) {
            
            _owners[++tokenID] = user;
                
            emit Transfer(address(0), user, tokenID);
        }
        
    }

}

contract WFC is OERC721 { //OrcaniaERC721 Standard
    
    uint256 private _price = 50000000000000000;

    //Read functions=====================================================================================================================================
    function getPrice() external  view returns(uint256) {return _price;}

    //Mod functions======================================================================================================================================
    function changePrice(uint256 newPrice) external Manager {
        _price = newPrice;
    }

    //User functions=====================================================================================================================================
    function publicMint() external payable {
        uint256 price = _price;
        require(msg.value % price == 0, "INVALID_ETH_AMOUNT");

        uint256 amount = msg.value / price;
        require(_totalSupply + amount <= 100000);

        _mint(msg.sender, amount);
    }

    function publicMintTo(address to) external payable {
        uint256 price = _price;
        require(msg.value % price == 0, "INVALID_ETH_AMOUNT");
         
        uint256 amount = msg.value / price;
        require(_totalSupply + amount <= 100000);
         
        _mint(to, amount);
    }

}