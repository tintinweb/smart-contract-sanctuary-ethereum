/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

//Developed by Orcania (https://orcania.io)
pragma solidity ^0.8.0;

library MerkleProof {

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

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
    
    function withdraw(address payable to, uint256 value) external Owner {
        require(to.send(value), "OMS: ISSUE_SENDING_FUNDS");    
    }

    function withdrawERC20(address token, address payable to, uint256 value) external Owner {
        IERC20(token).transfer(to, value);   
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

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() external view override returns(uint256){return _totalSupply;}

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

    
    function burn(uint256 tokenId) external {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _tokenApprovals[tokenId] == msg.sender || isApprovedForAll(owner, msg.sender), "ERC721: Not approved or owner");

        _balances[owner] -= 1;
        _owners[tokenId] = address(0);
        --_totalSupply;

        _approve(address(0), tokenId);

        emit Transfer(owner, address(0), tokenId);
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

contract chaoticDJs is OERC721 {
    using Strings for uint256;

    bytes32 private _glRoot;
    uint256 private _glPrice;
    uint256 private _glUserMintLimit;
    uint256 private _glMintLimit;
    uint256 private _glActive;

    mapping(address => uint256) _glUserMints; //Amount of mints performed by this user
    uint256 private _glMints; //Amount of mints performed in this mint


    bytes32 private _wlRoot;
    uint256 private _wlPrice;
    uint256 private _wlUserMintLimit;
    uint256 private _wlMintLimit;
    uint256 private _wlActive;

    mapping(address => uint256) _wlUserMints; //Amount of mints performed by this user
    uint256 private _wlMints; //Amount of mints performed in this mint


    uint256 private _pmPrice;
    uint256 private _pmUserMintLimit;
    uint256 private _pmActive;

    mapping(address => uint256) _pmUserMints; //Amount of mints performed by this user

    uint256 _maxSupply;

    uint256 private _reveal;

    constructor() {
        _name = "Chaotic DJs";
        _symbol = "CDS";
    }

    //Read Functions===========================================================================================================================================================

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        if(_reveal == 1) {return string(abi.encodePacked(uriLink, tokenId.toString(), ".json"));}

        return string(abi.encodePacked(uriLink, "secret.json"));
    }

    function glData(address user) external view returns(uint256 userMints, uint256 mints, uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, bool active) {
        userMints = _glUserMints[user];
        mints = _glMints;
        price = _glPrice;
        userMintLimit = _glUserMintLimit;
        mintLimit = _glMintLimit;
        active = _glActive == 1;
        root = _glRoot;
    }

    function wlData(address user) external view returns(uint256 userMints, uint256 mints, uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, bool active) {
        userMints = _wlUserMints[user];
        mints = _wlMints;
        price = _wlPrice;
        userMintLimit = _wlUserMintLimit;
        mintLimit = _wlMintLimit;
        active = _wlActive == 1;
        root = _wlRoot;
    }

    function pmData(address user) external view returns(uint256 userMints, uint256 price, uint256 userMintLimit, bool active) {
        userMints = _pmUserMints[user];
        price = _pmPrice;
        userMintLimit = _pmUserMintLimit;
        active = _pmActive == 1;
    }

    function maxSupply() external view returns(uint256) {return _maxSupply;}

    //Moderator Functions======================================================================================================================================================

    function setGlData(uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, uint256 active) external Manager {
        _glPrice = price;
        _glUserMintLimit = userMintLimit;
        _glMintLimit = mintLimit;
        _glActive = active;
        _glRoot = root;
    }

    function setWlData(uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, uint256 active) external Manager {
        _wlPrice = price;
        _wlUserMintLimit = userMintLimit;
        _wlMintLimit = mintLimit;
        _wlActive = active;
        _wlRoot = root;
    }

    function setPmData(uint256 price, uint256 userMintLimit, uint256 active) external Manager {
        _pmPrice = price;
        _pmUserMintLimit = userMintLimit;
        _pmActive = active;
    }

    function setMaxSupply(uint256 maxSupply) external Manager {
        _maxSupply = maxSupply;
    }

    function setReveal(uint256 reveal) external Manager {
        _reveal = reveal;
    }

    //User Functions======================================================================================================================================================

    function glMint(bytes32[] calldata _merkleProof) external payable {
        require(_glMints < _glMintLimit, "CDS: WL has sold out");
        require(_glActive == 1, "CDS: WL minting is closed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _glRoot, leaf), "NOT_GOLD_LISTED");

        uint256 price = _glPrice;

        require(msg.value % price == 0, "CDS: Wrong Value");

        uint256 amount = msg.value / price;

        require((_glMints += amount) <= _glMintLimit, "CDS: Mint Limit Exceeded");
        require((_glUserMints[msg.sender] += amount) <= _glUserMintLimit, "CDS: User Mint Limit Exceeded");

        _mint(msg.sender, amount);

        require(_totalSupply <= _maxSupply, "CDS: Supply Exceeded");
    }

    function wlMint(bytes32[] calldata _merkleProof) external payable {
        require(_wlMints < _wlMintLimit, "CDS: WL has sold out");
        require(_wlActive == 1, "CDS: WL minting is closed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _wlRoot, leaf), "NOT_GOLD_LISTED");

        uint256 price = _wlPrice;

        require(msg.value % price == 0, "CDS: Wrong Value");

        uint256 amount = msg.value / price;

        require((_wlMints += amount) <= _wlMintLimit, "CDS: Mint Limit Exceeded");
        require((_wlUserMints[msg.sender] += amount) <= _wlUserMintLimit, "CDS: User Mint Limit Exceeded");

        _mint(msg.sender, amount);

        require(_totalSupply <= _maxSupply, "CDS: Supply Exceeded");
    }

    function pmMint() external payable {
        require(_pmActive == 1, "CDS: WL minting is closed");

        uint256 price = _pmPrice;

        require(msg.value % price == 0, "CDS: Wrong Value");

        uint256 amount = msg.value / price;

        require((_pmUserMints[msg.sender] += amount) <= _pmUserMintLimit, "CDS: User Mint Limit Exceeded");

        _mint(msg.sender, amount);

        require(_totalSupply <= _maxSupply, "CDS: Supply Exceeded");
    }



}