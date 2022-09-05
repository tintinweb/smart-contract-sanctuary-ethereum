/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
    );

}
interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value)external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => string) internal _uri;
    mapping(uint256 => uint256) public tokenlock;
    bool public allunlock;
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
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

        return _uri[tokenId];
    }

    function approve(address to, uint256 tokenId) public virtual override {
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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // useridlist[to].ids.push(tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        // findindex(tokenId,owner);
        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(tokenlock[tokenId] <= block.timestamp || allunlock,"your token is lock");
        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

library SafeMath {

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MelonVers is ERC721, Ownable{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private tokenId;
    mapping(uint256 => address) private creator;

    mapping(address => bool) private isMinter;

    event Register(address registeraddress,uint256 registertime);
    event onMint(uint256 TokenId, int256 xaxis,int256 yaxis, address creator,uint256 USDT,uint256 BNB);
    event onCollectionMint(uint256 collections, uint256 totalIDs, string URI, uint256 royalty);
    event mainevent(address _address,uint256 _Amount);
    event main(address _address);

    address public usdt = 0x22e89Ff177081927d202A6BEdefBE068515C99b3;
    uint256 public lockdays;
    address public Admin;
    constructor(string[] memory countryName,uint256[] memory _Totalblock,address _admin) ERC721("MELONVERS", "MV"){
        lockdays = lockdays + 300;
        Admin = _admin;
        newcountry(countryName,_Totalblock);
        plateformFee = msg.sender;
    }

    function RemoveLock(bool _b) public onlyOwner returns(bool){
        allunlock = _b;
        return true;
    }

    struct ParselData{
        int256 xaxis;
        int256 yaxis;
        string countryname;
    }
    mapping(uint256 => ParselData) public parseldata;
    mapping(int256 => mapping (int256 => bool)) public axis;
    mapping(int256 => mapping (int256 =>address)) private checkowner;
    mapping(int256 => mapping (int256 => string)) private checkstring;
    mapping(int256 => mapping (int256 => ParselData)) private Alldata;
    mapping(string => bool) public iscountry;

    uint256 public lasttime = 5;
    mapping(string => bool) public code_;
    modifier onlyAdmin() {
        require(Admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function Addcode(string[] memory _codelist) public onlyAdmin returns(bool){
        require(_codelist.length > 0,"is not morethan ZERO");
        for(uint256 i=0;i<_codelist.length;i++){
            code_[_codelist[i]] = true;
        }
        return true;
    }
    function newcountry(string[] memory _nc,uint256[] memory _totalBlock) public onlyOwner returns(bool){
        for(uint256 i=0;i<_nc.length;i++){
            require(!iscountry[_nc[i]],"country is minted");
            iscountry[_nc[i]] = true;
            totalblock[_nc[i]] = _totalBlock[i];
        }
        return true;
    }
    function changeLockDays(uint256 _days) public onlyOwner returns(bool){
        lockdays = _days;
        return true;
    }
    function changetokenaddress(address _usdt) public onlyOwner returns(bool){
        usdt = _usdt;
        return true;
    }
    function CheckOwner(int256 _x,int256 _y)public view returns(address,string memory,ParselData memory){
        return (checkowner[_x][_y],checkstring[_x][_y],Alldata[_x][_y]);
    }
    event upd(uint256 letestprice,uint256 buyprice);
    event mainlog(address user,uint256 totalblock,uint256 totalUSDamount,uint256 totalBNBamount,bool isregister);
    
    function AssignToken(int[] memory x,int[] memory y,address[] memory _a,string memory _countryname) public onlyAdmin returns(bool){
        require(x.length == y.length && y.length == _a.length,"not same list");
        mintedblock[_countryname] = mintedblock[_countryname] + x.length ;
        require(mintedblock[_countryname] <= totalblock[_countryname],"end of the minting block");

        for(uint256 i=0;i<x.length;i++){
            tokenId.increment();
            uint256 id = tokenId.current();
            parseldata[id] = ParselData({
                    xaxis : x[i],
                    yaxis : y[i],
                countryname : _countryname
            });

            Alldata[x[i]][y[i]] = parseldata[id];
            axis[x[i]][y[i]] = true;
            checkowner[x[i]][y[i]] = _a[i];
            checkstring[x[i]][y[i]] = "";
            creator[id] = _a[i];

            _mint(_a[i], id);
            emit onMint(id, x[i], y[i], _a[i],0,0);

            tokenlock[id] = block.timestamp + (1 days * lockdays);

            if(!isMinter[_a[i]]){
                isMinter[_a[i]] = true;
                emit Register(msg.sender,block.timestamp);
            }
        }
        
        return true;
    }
    function plentblockMint(int256 x,int256 y,string memory _countryname) private {
        tokenId.increment();
        uint256 id = tokenId.current();
        parseldata[id] = ParselData({
                xaxis : x,
                yaxis : y,
                countryname : _countryname
        });
        Alldata[x][y] = parseldata[id];
        axis[x][y] = true;
        checkowner[x][y] = _msgSender();
        // checkstring[x][y] = _ptype;
        creator[id] = _msgSender();

        _mint(_msgSender(), id);
        emit onMint(id, x, y, msg.sender,0,0);
        tokenlock[id] = block.timestamp + (1 days * lockdays);
    }
    mapping(string => uint256) public totalblock;
    mapping(string => uint256) public mintedblock;
    uint256[] private amount;
    mapping(string => mapping(uint256 => uint256)) public mintedamountblock;
    mapping(string => bool) public iscodeuse;

    function GetData(string memory _cname) public view returns(uint256[] memory,uint256[] memory,uint256,uint256){
        uint256[] memory count = new uint256[](amount.length);
        for(uint256 i=0;i<amount.length;i++){
            count[i] = mintedamountblock[_cname][amount[i]];
        }
        return (count,amount,totalblock[_cname],mintedblock[_cname]);
    }
    function multibuyparsel(uint256 _amount,uint256 _time,string memory code,bytes memory signature,int256 _x,int256 _y,string memory _countryname)public returns(bool) {
        
        require(block.timestamp <= _time + (1 minutes * lasttime),"is expride time");
        require(iscountry[_countryname],"country not minted");

        mintedblock[_countryname] = mintedblock[_countryname] + 1 ;
        require(mintedblock[_countryname] <= totalblock[_countryname],"end of the minting block");

        require(IERC20(usdt).transferFrom(msg.sender,address(this),_amount),"is not appove token");
        require(verify(Admin,address(this),_amount,_time,code,_x,_y,signature),"is change the user");
        require(!axis[_x][_y],"alreday mint");
        plentblockMint(_x,_y,_countryname);
        if(bytes(code).length > 0 ){
            iscodeuse[code] = true;
        }
        if(!isMinter[msg.sender]){
            isMinter[msg.sender] = true;
            emit Register(msg.sender,block.timestamp);
        }
        return true;
    }
    function creatorOf(uint256 _tokenId) public view returns(address){
        return creator[_tokenId];
    }

    function totalSupply() public view returns(uint256){
        return tokenId.current();
    }
    function changeAdmin(address _admin) public onlyOwner returns(bool){
        Admin = _admin;
        return true;
    }
    function Givemetoken(address _a,uint256 _v)public onlyOwner returns(bool){
        require(_a != address(0x0) && address(this).balance >= _v,"not bnb in contract ");
        payable(_a).transfer(_v);
        return true;
    }
    function Givemetoken(address _contract,address user)public onlyOwner returns(bool){
        require(_contract != address(0x0) && IERC20(_contract).balanceOf(address(this)) >= 0,"not bnb in contract ");
        IERC20(_contract).transfer(user,IERC20(_contract).balanceOf(address(this)));
        return true;
    }
    function getMessageHash(
        address _contractaddress,
        uint _amount,
        uint _time,
        int x,
        int y,
        string memory code
    ) public view returns (bytes32) {
        require(!iscodeuse[code],"code is use");
         // keccak256(abi.encodePacked('Solidity')) == keccak256(abi.encodePacked(_language))
        return keccak256(abi.encodePacked(_contractaddress, _amount,_time, x,y,code));
    }
    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address _signer,
        address _contractaddress,
        uint _amount,
        uint _time,
        string memory code,
        int x,
        int y,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_contractaddress, _amount,_time, x,y,code);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    // Marketpalce Buy-Sell-RemoveSell
    uint256 public nativecommision = 500;
    address public plateformFee;

    mapping(uint256 => bool) private sellstatus;

    mapping(uint256 => Sell) public sellDetails;
    mapping(uint256 => bool) public isnative;

    struct Sell{
        address seller;
        address buyer;
        uint256 price;
        bool isnative;
        bool open;
        address tcontract;
    }
    event closed(uint256 tokenId, uint auctionId);
    event sell_auction_create(uint256 tokenId, address beneficiary, uint256 startTime, uint256 endTime, uint256 reservePrice, bool isNative);
    event onCommision(uint256 tokenid, uint256 adminCommision, uint256 creatorRoyalty, uint256 ownerAmount);
    function changePlateFormFee(uint256 _amount)public onlyOwner returns(bool){
        nativecommision = _amount;
        return true;
    }
    function changeplateformFee(address _address) public onlyOwner returns(bool){
        plateformFee = _address;
        return true;
    }
    function sell(uint256[] memory _tokenId, uint256[] memory _price,address _contract) public returns(bool){
        require(_tokenId.length == _price.length,"list is not same ");
        for(uint256 i=0;i<_tokenId.length;i++){
            require(_exists(_tokenId[i]), "ERC721: operator query for nonexistent token");
            require(_price[i] > 0, "Price set to zero");
            require(ownerOf(_tokenId[i]) == _msgSender(), "NFT: Not owner");
            require(!sellstatus[_tokenId[i]], "NFT: Open auction found");
            
            bool _isnative = false;
            isnative[_tokenId[i]] = false;
            if(_contract == address(0)){
                isnative[_tokenId[i]] = true;
                _isnative = true;
            }
            sellDetails[_tokenId[i]]= Sell({
                    seller: _msgSender(),
                    buyer: address(0x0),
                    price:  _price[i],
                    isnative : _isnative,
                    open: true,
                    tcontract : _contract
            });
            sellstatus[_tokenId[i]] = true;
            IERC721(address(this)).transferFrom(_msgSender(), address(this), _tokenId[i]);
            emit sell_auction_create(_tokenId[i], _msgSender(), 0, 0, sellDetails[_tokenId[i]].price, true);
            }
        return true;
    }
    function nativeBuy(uint256 _tokenId) public payable returns(bool){
        uint256 _price = sellDetails[_tokenId].price;
        require(sellstatus[_tokenId],"tokenid not buy");
        require(_msgSender() != sellDetails[_tokenId].seller, "owner can't buy");
        require(sellDetails[_tokenId].open, "already open");

        uint256 _commision4admin = uint256(_price.mul(nativecommision).div(10000));
        uint256 _amount4owner = uint256(_price.sub(_commision4admin));

        if(sellDetails[_tokenId].isnative){
            require(msg.value >= _price, "not enough balance");
            payable(sellDetails[_tokenId].seller).transfer(_amount4owner);
            payable(plateformFee).transfer(_commision4admin);
        }else{
            require(IERC20(sellDetails[_tokenId].tcontract).balanceOf(msg.sender) >= _price, "not enough balance");
            require(IERC20(sellDetails[_tokenId].tcontract).transferFrom(msg.sender,address(this),_price),"token not appove");
            IERC20(sellDetails[_tokenId].tcontract).transfer(sellDetails[_tokenId].seller,_amount4owner);
            IERC20(sellDetails[_tokenId].tcontract).transfer(plateformFee,_commision4admin);
        }
        IERC721(address(this)).transferFrom(address(this), _msgSender(),_tokenId);
        emit onCommision(_tokenId, _commision4admin, 0, _amount4owner);

        sellstatus[_tokenId] = false;
        sellDetails[_tokenId].isnative = false;
        sellDetails[_tokenId].buyer = _msgSender();
        sellDetails[_tokenId].open = false;
        return true;
    }
    function removeSell(uint256 _tokenId) public returns(bool){
        require(sellstatus[_tokenId],"not for sell");
        require(sellDetails[_tokenId].seller == msg.sender,"Only owner can remove this sell item");
        require(sellDetails[_tokenId].open, "The collectible is not for sale");

        IERC721(address(this)).transferFrom(address(this), _msgSender(), _tokenId);
        sellstatus[_tokenId] = false;
        sellDetails[_tokenId].open = false;
        sellDetails[_tokenId].isnative = false;
        emit closed(_tokenId, _tokenId);
        return true;
    }
}