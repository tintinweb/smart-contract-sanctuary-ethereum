// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./19_ERC165.sol";

//繼承ERC165, IERC721, IERC721Metadata, IERC721Enumerable的ERC721合約
contract ERC721 is ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    //IERC721Receiver介面的InterfaceId
    //bytes4(keccak256('onERC721Received(address,address,uint256,bytes)') = 0x150b7a02
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    //ERC721介面的InterfaceId
    //bytes4(keccak256('balanceOf(address)')) = 0x70a08231
    //bytes4(keccak256('ownerOf(uint256)')) = 0x6352211e
    //bytes4(keccak256('approve(address,uint256)')) = 0x095ea7b3
    //bytes4(keccak256('getApproved(uint256)')) = 0x081812fc
    //bytes4(keccak256('setApprovalForAll(address,bool)')) = 0xa22cb465
    //bytes4(keccak256('isApprovedForAll(address,address)')) = 0xe985e9c5
    //bytes4(keccak256('transferFrom(address,address,uint256)')) = 0x23b872dd
    //bytes4(keccak256('safeTransferFrom(address,address,uint256)')) = 0x42842e0e
    //bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) = 0xb88d4fde
    //0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^ 0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde = 0x80ac58cd
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    //ERC721_METADATA介面的InterfaceId
    //bytes4(keccak256('name()')) = 0x06fdde03
    //bytes4(keccak256('symbol()')) = 0x95d89b41
    //bytes4(keccak256('tokenURI(uint256)')) = 0xc87b56dd
    //0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd = 0x5b5e139f
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    //ERC721_ENUMERABLE介面的InterfaceId
    //bytes4(keccak256('totalSupply()')) = 0x18160ddd
    //bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) = 0x2f745c59
    //bytes4(keccak256('tokenByIndex(uint256)')) = 0x4f6ccce7
    //0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 = 0x780e9d63
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    //合約管理員
    address payable _owner;									

    //記錄持有者帳戶持有的代幣
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    //代幣的持有者
    EnumerableMap.UintToAddressMap private _tokenOwners;

    //代幣的操作者
    mapping (uint256 => address) private _tokenApprovals;

    //持有者授權的操作者
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    //代幣名稱
    string private _name;

    //代幣的代稱
    string private _symbol;

    //每個代幣的資源URI
    mapping (uint256 => string) private _tokenURIs;

    //Base URI
    string private _baseURI;

    modifier onlyOwner() {
        if( msg.sender != _owner) {	
            revert();
        }
        _;
    }
    
    //建構式，部署合約時設定代幣名稱及簡稱
    //name：代幣的名稱
    //symbol：代幣的代稱
    constructor (string memory name_, string memory symbol_) {

        _owner = payable(msg.sender);		

        _name = name_;
        _symbol = symbol_;

        //依據ERC165註冊本合約支援的ERC721相關介面
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    //查詢合約管理者帳號
    function getOwner() public view returns(address account) {
        return _owner;
    }

    //設定合約管理者帳號
    function setOwner(address newOwner) public onlyOwner {
        _owner = payable(newOwner);
    }

    //合約的以太幣轉帳給合約管理員
    function reap() public onlyOwner{
        _owner.transfer(address(this).balance);
    }

    //查詢持有者帳戶持有的代幣數量
    //owner：持有者帳戶
    //[returns]：持有者的代幣數量
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return _holderTokens[owner].length();
    }

    //查詢代幣的持有者帳戶
    //tokenId：代幣ID
    //[returns]：持有者帳戶
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "Owner query for nonexistent token");
    }

    //查詢代幣的名稱
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    //查詢代幣的代稱
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    //查詢代幣的資源URI
    //tokenId：代幣ID
    //[returns]：代幣的資源URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");   //檢查tokenID是否存在

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();
       
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        //連接base和_tokenURI字串
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        //只有baseURI，沒有_tokenURI時，連接base和tokenId
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    //查詢baseURI
    //[returns]：baseURI
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    //依據帳戶及索引值查詢代幣ID，與balanceOf一起使用來列舉指定帳戶所有的代幣ID
    //owner：持有者帳戶
    //index：索引值
    //tokenID：代幣ID
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    //查詢代幣的總發行量
    //[returns]：總發行量
    function totalSupply() public view virtual override returns (uint256) {
        //_tokenOwners儲存代幣的持有者，所以_tokenOwners的長度即為代幣的總發行量
        return _tokenOwners.length();
    }

    //依據索引值查詢代幣ID
    //index：索引值
    //[returns]：代幣ID
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    //授權代幣的操作者，當代幣轉移時清除操作者，一次只能授權一個操作者。發出Approval事件
    //to：操作者帳戶，設為0時，表示沒有授權的操作者
    //tokenId：代幣ID，必須存在，並且是執行者持有的代幣
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);            //取得tokenId的owner
        require(to != owner, "Approval to current owner");  //檢查操作者是否為持有者

        require(msg.sender == owner || ERC721.isApprovedForAll(owner, msg.sender), "Approve caller is not owner nor approved for all"); //檢查執行者是否為持有者

        _approve(to, tokenId);
    }

    //查詢代幣的操作者帳戶
    //tokenId：代幣ID，必須存在
    //operator：操作者帳戶
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    //設定啟用或禁用操作者管理代幣，每個持有者可以有多個操作者。發出ApprovalForAll事件
    //operator：操作者帳戶
    //approved：true啟用、false禁用
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //查詢持有者的操作者
    //owner：持有者帳戶
    //operator：操作者帳戶
    //[returns]：true是、flase否
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    //將指定的代幣從來源帳戶轉移給目的帳戶，但執行者需自行確認目的帳戶是否有能力接收代幣，否則可能永久丟失。發出Transfer事件
    //不建議使用此方法，應該盡可能使用safeTransferFrom方法
    //from：來源帳戶，不可以是0，並且必須是代幣[tokenId]的持有者或操作者
    //to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721Receiver-onERC721Received介面
    //tokenId：代幣ID，必須存在，並且是來源帳戶持有的代幣或操作者可操作的代幣
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");  //檢查執行者是否有權限可轉移代幣
        _transfer(from, to, tokenId);
    }

    //安全的將指定的代幣從來源帳戶轉移給目的帳戶。發出Transfer事件
    //from：來源帳戶，不可以是0，並且必須是代幣[tokenId]的持有者或操作者
    //to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721Receiver-onERC721Received介面
    //tokenId：代幣ID，必須存在，並且是來源帳戶持有的代幣或操作者可操作的代幣
    //data：附加的參數
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    //將指定的代幣從來源帳戶轉移給目的帳戶。發出Transfer事件
    //from：來源帳戶，不可以是0，並且必須是代幣[tokenId]的持有者或操作者
    //to：目的帳戶，不可以是0。若是CA合約帳戶，則該合約必須實做IERC721Receiver-onERC721Received介面
    //tokenId：代幣ID，必須存在，並且是來源帳戶持有的代幣或操作者可操作的代幣
    //data：附加的參數
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Transfer to non ERC721Receiver implementer");
    }

    //查詢指定的tokenId是否已存在
    //tokenId：代幣ID
    //[returns]：true是、false否
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    //查詢spender帳戶是否為tokenId的持有者或操作者
    //spender：檢查的帳戶
    //tokenId：代幣ID
    //[returns]：true是、false否
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "Operator query for nonexistent token");  //檢查tokenID是否存在
        address owner = ERC721.ownerOf(tokenId);    //取得tokenID的持有者
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    //鑄造一個代幣並轉移給持有者，發出Transfer事件
    //to：持有者帳戶, 若是CA合約帳戶，則該合約必須實做IERC721Receiver-onERC721Received介面
    //tokenId：代幣ID
    //_data：轉發給IERC721Receiver-onERC721Received的參數資料
    function safeMint(uint256 tokenId, string memory _tokenURI) public virtual payable{
        if(msg.value == 1 ether) {		    	
           _mint(msg.sender, tokenId, _tokenURI);
        } else {
            revert();						
        }
        require(_checkOnERC721Received(address(0), msg.sender, tokenId, ""), "Transfer to non ERC721Receiver implementer");
    }

    //鑄造一個代幣並轉移給持有者，發出Transfer事件
    //to：持有者帳戶, 若是CA合約帳戶，則該合約必須實做IERC721Receiver-onERC721Received介面
    //tokenId：代幣ID
    //_data：轉發給IERC721Receiver-onERC721Received的參數資料
    function safeMint(uint256 tokenId, string memory _tokenURI, bytes memory _data) public virtual payable{
        if(msg.value == 1 ether) {		    	
           _mint(msg.sender, tokenId, _tokenURI);
        } else {
            revert();						
        }
        require(_checkOnERC721Received(address(0), msg.sender, tokenId, _data), "Transfer to non ERC721Receiver implementer");
    }

    //鑄造一個代幣並轉移給持有者
    function _mint(address to, uint256 tokenId, string memory _tokenURI) internal virtual {
        require(tokenId < 1000, "TokenID must be less than 1000"); //tokenID必須小於1000
        require(to != address(0), "Mint to the zero address");      //持有者帳戶不可為0
        require(!_exists(tokenId), "Token already minted");         //檢查tokenId是否存在

        _holderTokens[to].add(tokenId); //持有者增加一個代幣
        _tokenOwners.set(tokenId, to);  //設定tokenId的持有者
        _tokenURIs[tokenId] = _tokenURI;

        emit Transfer(address(0), to, tokenId); //發出Transfer事件，from為0，表示為to帳戶鑄造tokenId
    }

    //燒毀一個代幣
    //tokenId：代幣ID
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _approve(address(0), tokenId);  //清除tokenId的操作者

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId]; //清除tokenId的URI
        }

        _holderTokens[owner].remove(tokenId);   //移除owner的tokenId

        _tokenOwners.remove(tokenId);           //移除token

        emit Transfer(owner, address(0), tokenId);  //發出Transfer事件，to為0, 表示owner帳戶燒毀tokenId
    }

    //將代幣tokenId從from帳戶轉移至to帳戶
    //from：來源帳戶
    //to：目的帳戶
    //tokenId：代幣ID
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "Transfer of token that is not own");  //檢查來源帳戶是否為帳戶的持有者
        require(to != address(0), "Transfer to the zero address");  //檢查目的帳戶是否為0

        _approve(address(0), tokenId);//清除tokenId的操作者

        _holderTokens[from].remove(tokenId);    //來源帳戶移除tokenId
        _holderTokens[to].add(tokenId);         //目的帳戶增加tokenId

        _tokenOwners.set(tokenId, to);          //設定tokenId的持有者

        emit Transfer(from, to, tokenId);       //發出Transfer事件
    }

    //設定tokenId的資源URI
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyOwner {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    //設定基本的資源URI
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    //確認帳戶是否收到代幣
    //from：來源帳戶
    //to：目的帳戶
    //tokenId：代幣ID
    //_data：附加的參數
    //[returns]：true是、false否
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)
    {
        if (!to.isContract())   //檢查to是否為合約帳戶
            return true;        //不是合約帳戶直接回傳true

        //呼叫執行合約帳戶的onERC721Received函數，並檢查回傳值
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ), "Transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    //設定tokenId的操作者
    //to：操作者帳戶
    //tokenId：代幣ID
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;  //設定tokenId的操作者
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); //發出Approval事件
    }
}