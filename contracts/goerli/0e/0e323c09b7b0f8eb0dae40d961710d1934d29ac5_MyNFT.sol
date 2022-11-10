/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;//建议用 0.8.10之上
interface IERC165 {
    //查询一个合同是否实现了一个接口 ,存在某方会调用这个函数，来判断你是否实现了相应的接口
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721  is IERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface IERC721Metadata  is IERC721  {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
//也是必须的，如果用于应对如果接收者是智能合约的情况。
interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}
contract ERC721 is IERC721Metadata{
    //实现METADATA
    string public name="Ybl  NFT Project";
    string public symbol="YBLNFT";
    mapping(uint256=>string) public tokenURI;

    mapping(uint => address) internal _ownerOf;
    mapping(address=>uint) internal _balanceOf;
    mapping(uint=>address) internal _approvals;
    mapping(address=>mapping(address=>bool)) public isApprovedForAll;//这里对应上面的函数function isApprovedForAll 所以不需要手动实现
    
    //查询一个合同是否实现了一个接口，存在某方会调用这个函数，来判断你是否实现了相应的接口
    function supportsInterface(bytes4 interfaceId) external view returns (bool){
        return interfaceId==type(IERC721).interfaceId||interfaceId==type(IERC165).interfaceId;
    }
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner!=address(0),"owner =zero address");
        return _balanceOf[_owner];
    }
    function ownerOf(uint256 _tokenId) external view returns (address owner){
        owner=_ownerOf[_tokenId];
        require(owner!=address(0),"owner =zero address");
        return owner;
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        isApprovedForAll[msg.sender][_operator]=_approved;
        emit ApprovalForAll(msg.sender,_operator,_approved);
    }
    function approve(address _approved, uint256 _tokenId) external payable{
        address owner= _ownerOf[_tokenId];
        require(msg.sender==owner||isApprovedForAll[owner][msg.sender],"not authorized");
        _approvals[_tokenId]=_approved;
        emit Approval(owner,_approved,_tokenId);
    }
    function getApproved(uint256 _tokenId) external view returns (address){
        require(_ownerOf[_tokenId]!=address(0),"token dose not exist");
        return _approvals[_tokenId];
    }
    //自己提取的函数 用于确认某个spender是否是owner或者被授权了。
    function _isApprovedOrOwner(address _owner,address _spender, uint _tokenId) internal view returns(bool){
        return (_owner==_spender||isApprovedForAll[_owner][_spender]||_approvals[_tokenId]==_spender);
    }
    //这里从external改成publc是因为会在 safeTranserfrom里面用，可见性修改是没问题的。
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
        require(_from==_ownerOf[_tokenId],"from != owner");
        require(_to!=address(0),"to == zero address");
        require(_isApprovedOrOwner(_from,msg.sender,_tokenId),"not authorized");
        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId]=_to;

        delete _approvals[_tokenId];
        emit Transfer(_from,_to,_tokenId);
    }
    //这个和普通的transfer的区别是 ，如果接收者是一个合约就要额外执行onERC721Received 这个函数
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        transferFrom(_from,_to,_tokenId);
        //接下来判断 _to是否是合约地址 _to.code.length==0 表示目的地址不是合约地址或者目的地址是刚刚再次交易中部署的合约
        //如果是智能合约，则显示的转化为IERC721TokenReceiver（to），然后调用onERC721Received方法（所以要确保接收的合约实现了这个nERC721Received方法）
        //返回的字节需要和IERC721TokenReceiver.onERC721Received.selector比较，
        //如果都不满足就输出unsafe receipent
        require(_to.code.length==0||IERC721TokenReceiver(_to).onERC721Received(msg.sender,_from,_tokenId,"")==IERC721TokenReceiver.onERC721Received.selector,"unsafe receipent");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable{
        transferFrom(_from,_to,_tokenId);
        require(_to.code.length==0||IERC721TokenReceiver(_to).onERC721Received(msg.sender,_from,_tokenId,data)==IERC721TokenReceiver.onERC721Received.selector,"unsafe receipent");
    }
    //一些不是接口必须的函数 但是主流函数都实现的
    function _mint(address _to,uint _tokenId) internal{
        require(_to !=address(0)," to=zero address");
        require(_ownerOf[_tokenId]==address(0),"token exists");
        _balanceOf[_to]++;
        _ownerOf[_tokenId]=_to;
        emit Transfer(address(0),_to,_tokenId);
    }
    function _burn(uint _tokenId) internal{
        address owner=_ownerOf[_tokenId];
        //require(owner==msg.sender,"not owner"); 不能写这个，因为在这个例子中，我们用MYNFT这个合约来调用这个合约的
        require(owner!=address(0),"token does not exist");
        _balanceOf[owner]--;
        delete _ownerOf[_tokenId];
        delete _approvals[_tokenId];
        emit Transfer(owner,address(0),_tokenId);
    }
    function _setTokenUrl(uint _tokenId,string calldata _url) internal{
        tokenURI[_tokenId]=_url;
    }
}
//0x0e323c09b7b0f8eb0dae40d961710d1934d29ac5
contract MyNFT is ERC721{
    //这里的tokenId在实际应用里可能就是某个图片的hash值，当然这里是uint，我或许可以修改
    function mint(address to, uint tokenId,string calldata url) external{
        _mint(to,tokenId);
        _setTokenUrl(tokenId,url);
    }
    function burn(uint tokenId) external{
        require(msg.sender==_ownerOf[tokenId],"not owner");
        _burn(tokenId);
    }
}