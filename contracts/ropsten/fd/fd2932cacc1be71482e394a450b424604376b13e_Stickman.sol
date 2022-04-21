/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract Stickman {

    //合約owner
    address C_owner;

    // Token 的 name（長）
    string private _name;

    // Token 的 symbol（短）
    string private _symbol;

    //儲存tokenid對應的tokenURI
    mapping(uint256 => string) private _URIs;

    // 紀錄tokenid 對 持有者地址
    mapping(uint256 => address) private _owners;

    // 記錄持有者的token數量
    mapping(address => uint256) private _balances;

    // token ID 對 approved 的地址
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //token id 的 counter
    uint256 _tokenIdCounter=0;

    //最大可發行量
    uint32 maxTokenSupply=3;

    modifier onlyOwner() {
        require(msg.sender == C_owner, "not owner");
        _;
    }

    //初始傳入_name以及_symbol
    constructor() {//在初始時指定owner
        C_owner = msg.sender;
        _name= "Stickman";
        _symbol= "STMN";
    }



/*----------interface ERC721Metadata---------*/
    function name() external view returns (string memory){
        return _name;
    }

    function symbol() external view returns (string memory){
        return _symbol;
    }

    //設定metadata的資料夾位置為baseuri
    function _baseURI() internal pure returns (string memory) {
        return "ipfs://QmVMxy2MELmQbFk5CPhafNuKymKpuqKhEP4wcMXX6EwEmk";//設定baseuri為圖片資料夾的ipfs位置
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory){//使用String.sol中的string.concat來組合字串
        string memory base = _baseURI();//利用base儲存_baseURI()
        return string(abi.encodePacked(base,"/",toString(tokenId),".json"));//利用abi.encodePacked組合字串，利用下方的toString()將uint256的tokenId轉成string
    }

    function toString(uint256 value) internal pure returns (string memory) {//把uint轉成string的函式
        if (value == 0) {
            return "0"; //如果數值0回傳字串0
        }
        uint256 temp = value;//將value用temp暫存
        uint256 digits; //宣告digit作為計算位數之用
        while (temp != 0) { //每次迴圈/10直到temp變成0，最後的digits即為位數
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);//將digits存為bytes
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); //利用取餘數一個一個抓每位的值
            value /= 10;
        }
        return string(buffer);
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _URIs[tokenId] = _tokenURI;
    }

/*----------interface ERC721Enumerable---------*/

    //owner擁有的token的token id們
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    //紀錄token index 對 token id
    mapping(uint256 => uint256) private _ownedTokensIndex;

    //之後要拿來遞增的index值
    uint256 T_index=0;

    //回傳使用_tokenIdCounter紀錄的Supply數量
    function totalSupply() external view returns (uint256){
        return _tokenIdCounter;
    }
    //回傳使用_ownedTokensIndex紀錄的index對token值
    function tokenByIndex(uint256 _index) external view returns (uint256){
        return _ownedTokensIndex[_index];
    }



/*----------interface ERC721---------*/

    // 寫入log的event
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //  查詢持有者的token數量
    function balanceOf(address _owner) public view returns (uint256){
        require(_owner != address(0), "ERC721: address zero is not a valid owner"); //檢查地址是不是0
        return _balances[_owner];
    }

    //以token id查詢owner
    function ownerOf(uint256 _tokenId) public view returns (address){
        address NFTowner = _owners[_tokenId];//以NFTowner儲存address
        require(NFTowner != address(0), "ERC721: owner query for nonexistent token");//如果address值則表示沒有對應token
        return NFTowner;
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual{
        safeTransferFrom(_from, _to, _tokenId, ""); //叫下面那函式
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual{
        require(_owners[_tokenId] != address(0), "ERC721: nonexistent token");  //TokenID對不到地址的require
        require(ownerOf(_tokenId)==_from, "ERC721: transfer caller is not owner"); //Transfer發起人不是owner的require

        _safeTransfer(_from, _to, _tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        //checkOnERC721Received is unavailable now maybe I will add it soon
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        //checkOnERC721Received is unavailable now maybe I will add it soon
    }



    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(msg.sender==_from, "ERC721: transfer caller is not owner nor approved"); //檢查要發起transfer的address是否正確

        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal  {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");//檢查owner
        require(to != address(0), "ERC721: transfer to the zero address");//檢查傳送地址是否為空值


        // 清除前一個owner的approval
        approve(address(0), tokenId);

        _balances[from] -= 1;//前一個owner的balances -1
        _balances[to] += 1;//新owner的balances +1
        _owners[tokenId] = to;//更新_owners中的資料

        emit Transfer(from, to, tokenId); //觸發Transfer事件

    }

    function approve(address _approved, uint256 _tokenId) public {
        address A_owner = ownerOf(_tokenId); //宣告A_owner暫存對應tokenID的address
        require(_approved != A_owner, "ERC721: approval to current owner"); //檢查要approve的address是否與該token的owner一致否則發出require

        require(
            msg.sender == A_owner || isApprovedForAll(A_owner, msg.sender), //檢查msg.sender是否等於A_owner，或是已經有Approve for all過了
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(_approved, _tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;//加入_tokenApprovals的mapping
        emit Approval(ownerOf(tokenId), to, tokenId);//觸發Approval的事件
    }



    function setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");//檢查owner和operator是否一樣，一樣則不予執行
        _operatorApprovals[owner][operator] = approved;//加入_operatorApprovals的mapping
        emit ApprovalForAll(owner, operator, approved);//觸發ApprovalForAll的事件
    }




    function getApproved(uint256 _tokenId) external view returns (address){
        require(_owners[_tokenId] != address(0), "ERC721: approved query for nonexistent token"); //若對應tokenID的持有者為空則發出require
        return _tokenApprovals[_tokenId];
    }


    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator]; //回傳_operatorApprovals mapping中的值
    }


/*----------interface ERC165---------*/
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x80ac58cd; //0x80ac58cd為ERC721的interface identifier
    }




    //mint token的函式
    function _mint(address to) public onlyOwner {

        //取得目前要mint的tokenId
        uint256 tokenId = _tokenIdCounter;

        //如果mint超過3個就不給用
        require(tokenId < maxTokenSupply, "Mint service is unavailable");

        //持有者的NFT數量
        _balances[to] += 1;

        // 觸發Transfer 的事件
        emit Transfer(address(0), to, tokenId);

        _owners[tokenId]=to;

        //setTokenURI
        _setTokenURI(tokenId, tokenURI(tokenId));

        _ownedTokensIndex[T_index]=tokenId;
        T_index++;
        //每mint一次tokenId會增加
        _tokenIdCounter+=1;
    }









}