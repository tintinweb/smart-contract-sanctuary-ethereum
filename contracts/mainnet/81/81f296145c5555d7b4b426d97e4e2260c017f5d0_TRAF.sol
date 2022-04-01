/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

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

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);
    
    function totalSupply() external view returns(uint256);
    
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
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
        require(to.send(value), "OMS: ISSUE_SENDING_FUNDS");
    }

}

abstract contract O_ERC721 is OMS, ERC165, IERC721, IERC721Metadata{ //OrcaniaERC721 Standard
    using Strings for uint256;

    string internal uriLink;
    
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

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view override returns(uint256){return _totalSupply;}

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        return string(abi.encodePacked(uriLink, tokenId.toString(), ".json"));

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

    function adminMint(address to) external payable Manager {
        _mint(to, msg.value);
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

    function setApprovalForAll(address operator, bool approved) public override {
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
        _safeTransfer(from, to, tokenId, _data);
    }

    //Internal Functions======================================================================================================================================================
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_owners[tokenId] != address(0), "ERC721: operator query for nonexistent token");
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

contract TRAF is O_ERC721 {

    constructor() {
        _name = "The Red Ape Family";
        _symbol = "TRAF";
        uriLink = "https://ipfs.io/ipfs/QmNLozPFC34fZuzKWDb35hbmpUUZg9MBBVjBg8c6aUHc2A/EpisodeData";
    }

    mapping(address => uint256) private _holdersMint_Mints;
    bool private _holdersMint_Active;
    function holdersMint() external payable{
        require(_holdersMint_Active, "MINT_OFF");
        require(_balances[msg.sender] > 0, "NOT_HOLDER");
        require(msg.value % 250000000000000000 == 0, "WRONG_VALUE");

        uint256 amount = msg.value / 250000000000000000;
        require((_holdersMint_Mints[msg.sender] += amount) < 11, "USER_MINT_LIMIT_REACHED"); //Total mints of 10 per wallet

        _mint(msg.sender, amount);

        require(_totalSupply < 1778, "MINT_LIMIT_REACHED"); //Max of 1111 NFTs for ep3
    }

    mapping(address => uint256) private _wlPartnersMint_Mints;
    uint256 private _wlPartnersMint_TotalMinted;
    bool private _wlPartnersMint_Active;
    function wlPartnersMint() external payable{
        require(_wlPartnersMint_Active, "MINT_OFF");
        require(
            IERC721(0x219B8aB790dECC32444a6600971c7C3718252539).balanceOf(msg.sender) > 0 ||
            IERC721(0xF1268733C6FB05EF6bE9cF23d24436Dcd6E0B35E).balanceOf(msg.sender) > 0 ||
            IERC721(0x5DF340b5D1618c543aC81837dA1C2d2B17b3B5d8).balanceOf(msg.sender) > 0 ||
            IERC721(0x9ee36cD3E78bAdcAF0cBED71c824bD8C5Cb65a8C).balanceOf(msg.sender) > 0 ||
            IERC721(0x3a4cA1c1bB243D299032753fdd75e8FEc1F0d585).balanceOf(msg.sender) > 0 ||
            IERC721(0xF3114DD5c5b50a573E66596563D15A630ED359b4).balanceOf(msg.sender) > 0
        , "NOT_PARTNER_HOLDER");

        require(msg.value % 350000000000000000 == 0, "WRONG_VALUE");

        uint256 amount = msg.value / 350000000000000000;
        require((_wlPartnersMint_Mints[msg.sender] += amount) < 2, "USER_MINT_LIMIT_REACHED"); //Total mints of 1 per wallet
        require((_wlPartnersMint_TotalMinted += amount) < 889, "MINT_LIMIT_REACHED"); //Total mints of 888 for this mint

        _mint(msg.sender, amount);

        require(_totalSupply < 1778, "MINT_LIMIT_REACHED"); //Max of 1111 NFTs for ep3
    }

    mapping(address => uint256) private _nonWlPartnersMint_Mints;
    bool private _nonWlPartnersMint_Active;
    function nonWlPartnersMint() external payable{
        require(_nonWlPartnersMint_Active, "MINT_OFF");
        require(
            IERC721(0x369156da04B6F313b532F7aE08E661e402B1C2F2).balanceOf(msg.sender) > 0 ||
            IERC721(0x91cc3844B8271337679F8C00cB2d238886917d40).balanceOf(msg.sender) > 0 ||
            IERC721(0x21AE791a447c7EeC28c40Bba0B297b00D7D0e8F4).balanceOf(msg.sender) > 0 
        , "NOT_PARTNER_HOLDER");
        
        require(msg.value % 400000000000000000 == 0, "WRONG_VALUE");

        uint256 amount = msg.value / 400000000000000000;
        require((_nonWlPartnersMint_Mints[msg.sender] += amount) < 11, "USER_MINT_LIMIT_REACHED"); //Total mints of 10 per wallet

        _mint(msg.sender, amount);

        require(_totalSupply < 1778, "MINT_LIMIT_REACHED"); //Max of 1111 NFTs for ep3
    }

    function setMints(bool holdersMint_Active, bool wlPartnersMint_Active, bool nonWlPartnersMint_Active) external Manager {
        _holdersMint_Active = holdersMint_Active;
        _wlPartnersMint_Active = wlPartnersMint_Active;
        _nonWlPartnersMint_Active = nonWlPartnersMint_Active;
    }
 

}