// SPDX-License-Identifier: NFT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";

interface Team{
    function team(address from_) external returns (address);
    function bindingTesla(address from_ , address to_) external returns (bool);
}
/**
 * 特斯拉的合约 Tesla
 */
contract Tesla is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    string private __baseURI;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => uint256) private _horsePower;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    //URL扩展
    mapping(uint256 => string) private _tokenURIs;
    //Enumerable扩展
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    //合约白名单
    address private _WhiteListContract;
    modifier WhiteList {   //合约白名单
        require(_WhiteListContract == msg.sender);
        _;
    }
    //管理员
    address public _owner;
    modifier Owner {   //管理员
        require(_owner == msg.sender);
        _;
    }
    //绑定上下级合约地址
    address public TeamContract = address(0x00);
    //最小马力
    uint256 public _horsePowerMin;
    //马力增加幅度
    uint256 public _horsePowerrange;
    /**
    ** 初始化代币名称       name_   Model3  Modely Modelx Models Roadster SpaceX
    ** 初始化代币简称       symbol_ Model3  Modely Modelx Models Roadster SpaceX
    ** 初始化URL前缀地址    baseURI_ Model3  Modely Modelx Models Roadster SpaceX
    ** 本车最小马力值       horsePowerMin_    90  480   600   700   860   1200
    ** 马力加大幅度         horsePowerrange_  0   60    60    60    920   60
    ** 上下级合约地址       TeamContract_
    */
    constructor(string memory name_, string memory symbol_,string memory baseURI_,uint256 horsePowerMin_,uint256 horsePowerrange_,address TeamContract_) {
        _name = name_;
        _symbol = symbol_;
        __baseURI = baseURI_;
        _horsePowerMin = horsePowerMin_;
        _horsePowerrange = horsePowerrange_;
        //上下级合约
        TeamContract = TeamContract_;
        _owner = msg.sender; //默认自己为管理员
    }

    /**
    * 修改管理员
    */
    function setOwner(address owner_) public Owner returns (bool){
        _owner = owner_;
        return true;
    }
    /**
    * 修改合约白名单
    */
    function setWhiteListContract(address WhiteListContract_) public Owner returns (bool){
        _WhiteListContract = WhiteListContract_;
        return true;
    }
    /**
    * 修改上下级合约地址
    */
    function setTeamContract(address newaddress_) public Owner returns (bool){
        TeamContract = newaddress_;
        return true;
    }
    
    /**
    * 当前合约白名单
    */
    function WhiteListContract() public view returns (address){
        return _WhiteListContract;
    }
    /**
    * 抽盲盒开特斯拉
    */
    function toMint(address to_) public WhiteList returns (bool){
        uint256 tokenId = totalSupply() + 10000000;
        _safeMint(to_,tokenId,'');
        _setTokenURI(tokenId, _name);
        _horsePower[tokenId] = _PoweRand(_horsePowerMin,_horsePowerrange);
        return true;
    }
    /**
    * 生成马力数
    */
    function _PoweRand(uint256 min_,uint256 poor_) internal view returns(uint256 PoweRand){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        if(poor_ != 0){
            uint256 rand = random % poor_;
            return (min_ + rand);
        }else{
            return min_;
        }
    }
    /**
    * 返回车辆的马力
    */
    function horsePower(uint256 tokenId_) public view virtual returns (uint256) {
        return _horsePower[tokenId_];
    }
    /**
    * 转移车辆
    */
    function toTransfer(address from_,address to_,uint256 tokenId_) public WhiteList returns(bool){
        _transfer(from_,to_,tokenId_);
        return true;
    }


    /**
    * 以下是标准合约的代码
    */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < Tesla.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < Tesla.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenURIs[tokenId])) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return __baseURI;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Tesla.ownerOf(tokenId);
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
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
        address owner = Tesla.ownerOf(tokenId);
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
        address owner = Tesla.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
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
        require(Tesla.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(Tesla.ownerOf(tokenId), to, tokenId);
    }
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    ) internal virtual {
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
        if(from != address(0) && to != address(0)){
            Team Teams = Team(TeamContract);
            if(Teams.team(to) == address(0x00)){
                Teams.bindingTesla(to,from); 
            }
        }
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = Tesla.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex; 
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = Tesla.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
}