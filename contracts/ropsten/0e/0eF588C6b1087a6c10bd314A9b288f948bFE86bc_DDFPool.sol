/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DepositDai: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ERC721 is Context, ERC165, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual lock override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual lock override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual lock override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual lock override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual lock override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721{
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

interface IDDFERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenURI(uint256 tokenId) external view  returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IDDFERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IDDFPool is IERC721Enumerable{
    function depositNFT(uint256 tokenId) external;
    function retrieveNFT(uint256 lpTokenId) external;
    function extractNFTInterest(uint256 lpTokenId) external;
    function findDepositNFTInterest(uint256 lpTokenId)
        external
		view
		returns (uint256 amount);
    function findUserNFTTokens(address amount) external view returns (uint256[] memory,string[] memory);
    function findUserLPTokens(address account) 
        external
        view
		returns (uint256[] memory,uint256[] memory,string[] memory,uint256[] memory);
    function depositDDF(uint256 amount) external;
    function retrieveDDF(uint256 lpTokenId) external;
    function retrieveAllDDF() external;
    function extractDDFInterest(uint256 lpTokenId) external;
    function extractAllDDF() external;
    function findDepositDDFInterest(uint256 lpTokenId)
        external
		view
        returns (uint256 amount,uint256 interest);
    function findDepositDDFAllInterest(address account)
        external
		view
        returns (uint256 amount,uint256 interest);
    function setNFTAddress(address _nftAddress) external;
    function setDDFAddress(address _ddfAddress) external;
    function updateTokenURI(string memory _tokenURI) external;
}

contract DDFPool is IDDFPool, ERC721Enumerable, Ownable{
    using EnumerableMap for EnumerableMap.UintToUintMap;

    address private nftAddress;
    address private ddfAddress;
    uint32  private blockStartTime;

    uint32 constant private DAY_PROFIT = 300000;
    uint8 constant private PDOG_PRV = 3;
    uint16 constant private PDOG_PRV_M = 100;

    string private baseURI;

    EnumerableMap.UintToUintMap private _lpNFTTokens;
    EnumerableMap.UintToUintMap private _lpNFTTokensTimes;
    EnumerableMap.UintToUintMap private _lpDDFTokens;
    EnumerableMap.UintToUintMap private _lpDDFTokensTimes;

    constructor(address _nftAddress, address _ddfAddress) ERC721("DDF LP", "DDFLP")  {
        nftAddress = _nftAddress;
        ddfAddress = _ddfAddress;
        blockStartTime = uint32(block.timestamp % 2 ** 32);
    }

    function depositNFT(uint256 tokenId) external lock override {
        require(msg.sender == IDDFERC721(nftAddress).ownerOf(tokenId), "ERC721: transfer of token that is not owner");
        
        uint256 lpTokenId = totalSupply()+1;
        _safeMint(msg.sender, lpTokenId);
        IDDFERC721(nftAddress).transferFrom(msg.sender,address(this),tokenId);

        _lpNFTTokens.set(lpTokenId, tokenId);
        _lpNFTTokensTimes.set(lpTokenId, block.timestamp);
    }

    function retrieveNFT(uint256 lpTokenId) external lock override {
        require(lpTokenId > 0, "ERC721: deposit query for nonexistent token");
        require(ownerOf(lpTokenId) == msg.sender, "ERC721: retrieveNFT of token that is not owner");
        uint256 _tokenId = _lpNFTTokens.get(lpTokenId);
        require(_tokenId > 0, "ERC721: deposit query for existent token");
        
        uint32 startTime = uint32(_lpNFTTokensTimes.get(lpTokenId) % 2 ** 32);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 amount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,DAY_PROFIT);

        if(amount > 0 ){
            IDDFERC20(ddfAddress).transferFrom(ddfAddress,msg.sender,amount);
        }

        IDDFERC721(nftAddress).transferFrom(address(this),msg.sender,_tokenId);

        _lpNFTTokens.remove(lpTokenId);
        _lpNFTTokensTimes.remove(lpTokenId);
        _burn(lpTokenId);
    }

    function extractNFTInterest(uint256 lpTokenId) external lock override {
        require(lpTokenId > 0, "ERC721: deposit query for nonexistent token");
        require(ownerOf(lpTokenId) == msg.sender, "ERC721: extractNFT of token that is not owner");
        uint256 _tokenId = _lpNFTTokens.get(lpTokenId);
        require(_tokenId > 0, "ERC721: deposit query for existent token");

        uint32 startTime = uint32(_lpNFTTokensTimes.get(lpTokenId) % 2 ** 32);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 amount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,DAY_PROFIT);

        if(amount > 0 ) {
            IDDFERC20(ddfAddress).transferFrom(ddfAddress,msg.sender,amount);
            _lpNFTTokensTimes.set(lpTokenId,endTime);
        }
    }

    function findDepositNFTInterest(uint256 lpTokenId)
        public
		view
		virtual 
        override 
        returns (uint256 amount) {
        require(lpTokenId > 0, "ERC721: deposit query for nonexistent token");
       uint256 _tokenId = _lpNFTTokens.get(lpTokenId);
        require(_tokenId > 0, "ERC721: deposit query for existent token");

        uint32 startTime = uint32(_lpNFTTokensTimes.get(lpTokenId) % 2 ** 32);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        amount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,DAY_PROFIT);
    }

    function depositDDF(uint256 amount) external lock override {
        require(amount <= IDDFERC20(ddfAddress).balanceOf(msg.sender), "depositDDF amount not enough");

        IDDFERC20(ddfAddress).transferFrom(msg.sender, address(this), amount);

        uint256 lpTokenId = totalSupply()+1;
        _safeMint(msg.sender, lpTokenId);

        _lpDDFTokens.set(lpTokenId,amount);
        _lpDDFTokensTimes.set(lpTokenId, block.timestamp);
    }

    function retrieveDDF(uint256 lpTokenId) external lock override  {
        require(lpTokenId > 0, "DDLLP: deposit query for nonexistent token");
        require(ownerOf(lpTokenId) == msg.sender, "ERC721: retrieveDai of token that is not owner");
        uint256 amount = _lpDDFTokens.get(lpTokenId);
        require(amount > 0, "deposit DDL amount not enough"); 

        uint32 startTime = uint32(_lpDDFTokensTimes.get(lpTokenId) % 2 ** 32);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 interest = CalProfitMath.colProfitAmount(startTime, endTime, amount, PDOG_PRV, PDOG_PRV_M);
        
        if(interest > 0){
            IDDFERC20(ddfAddress).transferFrom(ddfAddress, msg.sender, interest);
        }
        IDDFERC20(ddfAddress).approve(address(this),amount);
        IDDFERC20(ddfAddress).transferFrom(address(this), msg.sender, amount);
        
        _lpDDFTokens.remove(lpTokenId);
        _burn(lpTokenId);
    }

    function retrieveAllDDF() external lock override  {
        uint256 lpsNum = balanceOf(msg.sender);
        require(lpsNum > 0, "deposit DDL amount not enough"); 

        uint32 startTime;
        uint32 endtime = uint32(block.timestamp % 2 ** 32);

        uint256 interest = 0;
        uint256 lpTokenId;
        uint256 _amount;
        uint256 amount = 0;
        for(uint i=0;i<lpsNum;i++){
            lpTokenId = tokenOfOwnerByIndex(msg.sender, i);
            _amount = _lpDDFTokens.get(lpTokenId);

            if(_amount > 0){
                startTime = uint32(_lpDDFTokensTimes.get(lpTokenId) % 2 ** 32);
                amount += _amount;
                interest += CalProfitMath.colProfitAmount(startTime, endtime, _amount, PDOG_PRV, PDOG_PRV_M);
                _lpDDFTokens.remove(lpTokenId);
                _lpDDFTokensTimes.remove(lpTokenId);
                _burn(lpTokenId);
            }
        }
        require(amount > 0, "deposit DDL amount not enough"); 

        if(interest > 0){
            IDDFERC20(ddfAddress).transferFrom(ddfAddress,msg.sender,interest);
        }
        IDDFERC20(ddfAddress).approve(address(this),amount);
        IDDFERC20(ddfAddress).transferFrom(address(this),msg.sender,amount);
    }
        

    function extractDDFInterest(uint256 lpTokenId) external lock override {
        require(lpTokenId > 0, "DDLLP: deposit query for nonexistent token");
        require(ownerOf(lpTokenId) == msg.sender, "ERC721: retrieveDai of token that is not owner");
  
        uint256 amount = _lpDDFTokens.get(lpTokenId);
        require(amount > 0, "deposit DDL amount not enough"); 

        uint32 startTime = uint32(_lpDDFTokensTimes.get(lpTokenId) % 2 ** 32);
        uint32 endtime = uint32(block.timestamp % 2 ** 32);
        uint256 interest = CalProfitMath.colProfitAmount(startTime, endtime, amount, PDOG_PRV, PDOG_PRV_M);
        
        require(interest > 0, "deposit DDL amount not enough"); 

        if(interest > 0) {
            IDDFERC20(ddfAddress).transferFrom(ddfAddress, msg.sender, interest);
        }
        _lpDDFTokensTimes.set(lpTokenId, endtime);
    }

    function extractAllDDF() external lock override {
        uint256 lpsNum = balanceOf(msg.sender);
        require(lpsNum > 0, "deposit DDL amount not enough"); 

        uint32 startTime;
        uint32 endtime = uint32(block.timestamp % 2 ** 32);

        uint256 interest = 0;
        uint256 lpTokenId;
        uint256 _amount;
        uint256 amount = 0;
        for(uint i=0;i<lpsNum;i++){
            lpTokenId = tokenOfOwnerByIndex(msg.sender, i);
            _amount = _lpDDFTokens.get(lpTokenId);

            if(_amount > 0){
                startTime = uint32(_lpDDFTokensTimes.get(lpTokenId) % 2 ** 32);
                amount += _amount;
                interest += CalProfitMath.colProfitAmount(startTime, endtime, _amount, PDOG_PRV, PDOG_PRV_M);
                _lpDDFTokensTimes.set(lpTokenId, endtime);
            }
        }
        require(amount > 0 , "deposit DDL amount not enough"); 

        if(interest > 0){
            IDDFERC20(ddfAddress).transferFrom(ddfAddress, msg.sender, interest);
        }
    }

    function findDepositDDFInterest(uint256 lpTokenId)
        public
		view
		virtual 
        override 
        returns (uint256 amount, uint256 interest) {
        require(ownerOf(lpTokenId) != address(0), "This lpTokenId non-existent");

        interest = 0;
        amount =  _lpDDFTokens.get(lpTokenId);
        if(amount > 0){
            uint32 startTime = uint32(_lpDDFTokensTimes.get(lpTokenId) % 2 ** 32);
            interest = CalProfitMath.colProfitAmount(startTime, uint32(block.timestamp % 2 ** 32), amount, PDOG_PRV, PDOG_PRV_M);
        } 
    }

    function findDepositDDFAllInterest(address account)
        public
		view
		virtual 
        override 
        returns (uint256 amount,uint256 interest) {
        uint256 lpsNum = balanceOf(account);
        require(lpsNum > 0, "This account deposit DDL amount not enough");

        uint32 startTime;
        uint32 endtime = uint32(block.timestamp % 2 ** 32);
        uint256 lpTokenId;
         uint256 _amount = 0;
        amount = 0;
        interest = 0;
        for(uint i=0;i<lpsNum;i++){
            lpTokenId = tokenOfOwnerByIndex(msg.sender,i);
            _amount = _lpDDFTokens.get(lpTokenId);
            if(_amount > 0){
                startTime = uint32(_lpDDFTokensTimes.get(lpTokenId) % 2 ** 32);
                amount += _amount;
                interest += CalProfitMath.colProfitAmount(startTime,endtime,_amount,PDOG_PRV,PDOG_PRV_M);
            }
        }
    }

    function findUserLPTokens(address account) 
        public
        view
		virtual
        override
		returns (uint256[] memory,uint256[] memory,string[] memory,uint256[] memory){
        uint256 len = balanceOf(account);
        require(len > 0, "This account deposit not enough"); 

        uint256[] memory _lpTokens = new uint256[](len);
        uint[] memory _tokens = new uint256[](len);
        string[] memory _URIs = new string[](len);
        uint[] memory _amounts = new uint256[](len);

        uint32 startTime;
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        IDDFERC721 erc721 = IDDFERC721(nftAddress);
        address owner = account;
        uint256 _lpTokenId;
        uint256 _tokenId;
        uint256 _amount;
        for(uint32 i=0;i<len;i++){
            _lpTokenId = tokenOfOwnerByIndex(owner, i);
            _tokenId = _lpNFTTokens.get(_lpTokenId);
            _amount = _lpDDFTokens.get(_lpTokenId);
            if(_tokenId > 0) {
                startTime = uint32(_lpNFTTokensTimes.get(_lpTokenId) % 2 ** 32);
                _lpTokens[i] = _lpTokenId;
                _tokens[i] = _tokenId;
                _URIs[i] = erc721.tokenURI(_tokenId);
                _amounts[i] = CalProfitMath.calStepProfitAmount(blockStartTime, startTime, endTime, DAY_PROFIT); 
            }else if(_amount > 0){
                startTime = uint32(_lpDDFTokensTimes.get(_lpTokenId) % 2 ** 32);
                _lpTokens[i] = _lpTokenId;
                _tokens[i] = _amount;
                _amounts[i] = CalProfitMath.colProfitAmount(startTime,endTime,_amount,PDOG_PRV,PDOG_PRV_M);
            }
        }
        return (_lpTokens,_tokens,_URIs,_amounts);
    }
    
    function findUserNFTTokens(address account) public view virtual override returns (uint256[] memory,string[] memory) {
        require(account != address(0), "ERC721: balance query for the zero address");

        IDDFERC721 erc721 = IDDFERC721(nftAddress);
        uint256 balances = erc721.balanceOf(account);

        uint256[] memory tokens = new uint256[](balances); 
        string[] memory tokenURIs  = new string[](balances);
        if(balances>0){
            for(uint i=0;i<balances;i++){
                tokens[i] = erc721.tokenOfOwnerByIndex(account, i);
                tokenURIs[i] = erc721.tokenURI(tokens[i]);
            }
        }
        return (tokens,tokenURIs);
    }
    
    function setNFTAddress(address _nftAddress) external onlyOwner lock override {
        nftAddress = _nftAddress;
    }
    function setDDFAddress(address _ddfAddress) external onlyOwner lock override {
        ddfAddress = _ddfAddress;
    }

    function updateTokenURI(string memory _tokenURI) external virtual onlyOwner lock override {
        baseURI = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseURI;
    }
}

library CalProfitMath {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function calStepProfit(uint256 amount, uint8 p, uint8 d) internal pure returns (uint256 z) {
        z = mul(amount,p);
        z = div(z,d);
    }
    function calProfit(uint256 dayProfit, uint second) internal pure returns (uint256 z) {
        z = mul(dayProfit,second);
        z = div(z,SECONDS_PER_DAY);
    }

    function calStepProfitAmount(uint32 blockStartTime, uint32 startime, uint32 endtime,uint32 DAY_PROFIT) internal pure returns (uint256 totalAmount) {
        totalAmount = 0;
        uint32 stepTime = blockStartTime;
        uint256 stepAmount = DAY_PROFIT;
        uint8 step = 0;
        while(true){
            stepTime = uint32(DateUtil.addMonths(stepTime,1) % 2 ** 32);
            if(stepTime > startime){
                if(endtime < stepTime){
                    totalAmount = add(totalAmount,calProfit(stepAmount,sub(endtime,startime)));
                    break;
                }else{
                    totalAmount = add(totalAmount,calProfit(stepAmount,sub(stepTime,startime)));
                    startime = stepTime;
                } 
            }
            if(step < 12){
                stepAmount = calStepProfit(stepAmount,95,100);
                step++;
            }
        }
        return totalAmount;
    }
    function colProfitAmount(uint32 startime, uint32 endtime, uint256 depositAmount, uint256 m, uint256 d) internal pure returns (uint256 totalAmount) {
        uint dayAmount = div(mul(depositAmount,m),d);
        totalAmount = calProfit(dayAmount,sub(endtime,startime));
        return totalAmount;
    }
}

library DateUtil {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);
 
        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;
 
        _days = uint(__days);
    }
 
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);
 
        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
 
        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

 
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
}
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        mapping (bytes32 => uint256) _indexes;
    }

    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { 
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;
            MapEntry storage lastEntry = map._entries[lastIndex];

            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1; 
            map._entries.pop();

            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if(keyIndex != 0){
            return map._entries[keyIndex - 1]._value; 
        }else{
            return bytes32(0);
        }
    }

    struct UintToUintMap {
        Map _inner;
    }

    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key)));
    }
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}