/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
            if (returndata.length > 0) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
    ) internal virtual {}
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
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract CRT is ERC721, Ownable, ReentrancyGuard {
    bytes32 whroot=0;
    bytes32 raroot=0;
    uint256 public currentTokenId;
    string public baseTokenURI = "";
    uint256 public mintprice = 0.05 ether;
    uint256 public collectionsize = 10000;
    uint256 public reservedsize = 200;
    uint256 public maxminteditems = 2;
    uint256 public mintpause = 0;
    uint256 public whitelistmintopen = 0;
    uint256 public rafflemintopen = 0;
    uint256 public publicmintopen = 1;
    mapping(address => uint256) public mintedq;
constructor() ERC721("Cryptomus Test", "CRT"){}
    function _onlyMinter() private view 
    { 
	require(msg.sender == tx.origin);
    }
    modifier onlyMinter 
    {
	_onlyMinter();
	_;
    }
    function merkle(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) 
    {
	bytes32 cHa = leaf;
        for (uint256 i = 0; i < proof.length; i++) 
	{
	    bytes32 pEl = proof[i];
            if (cHa <= pEl) 
	    {
                cHa = keccak256(abi.encodePacked(cHa, pEl));
            } else {
                cHa = keccak256(abi.encodePacked(pEl, cHa));
            }
        }
        return cHa;
    }
    function mintTo(address recipient) public onlyOwner returns (uint256) 
    {
	currentTokenId += 1;
	_safeMint(recipient, currentTokenId);
	return currentTokenId;
    }
    function totalSupply() public view virtual returns (uint256) 
    {
        return currentTokenId;
    }
    function calculateq(uint256 ev) internal view returns (uint256) 
    {
        uint256 r=ev%mintprice;
        require(r==0,"Bad ammount of ETH");
        uint256 a=ev/mintprice;
        require(a>0,"Input amount=0");
        require(currentTokenId + a <= collectionsize - reservedsize, "Sold out!" );
        return a;
    }
    function mintNFT(bytes32[] memory proof) external payable onlyMinter nonReentrant 
    {
	uint256 st=0;
	bytes32 leaf;
	bytes32 comp;
	require(mintpause==0, "Minting is not live yet!");
	if ( whitelistmintopen == 1 )
	{
	    leaf = keccak256(abi.encodePacked(msg.sender));
	    comp = merkle ( proof, leaf );
	    if ( comp==whroot ) st=1;
	}
	if ( rafflemintopen == 1 )
	{
	    leaf = keccak256(abi.encodePacked(msg.sender));
	    comp = merkle ( proof, leaf );
	    if ( comp==raroot ) st=1;
	}
	if ( publicmintopen == 1 )
	{
	    st=1;
	}
	require( st==1, "You are not eligible for Whitelist or Raffle mint!" );
	uint256 a=calculateq(msg.value);
        require(mintedq[msg.sender]+a<=maxminteditems,"This would exceed the maximum NFTs/address!");
        mintedq[msg.sender]+=a;
        for (uint256 i=0;i<a;i++) 
	{
	    currentTokenId+=1;
	    _mint(msg.sender, currentTokenId);
        }
    }
    function _baseURI() internal view virtual override returns (string memory) 
    {
	return baseTokenURI;
    }
    function setBaseTokenURI(string memory _b) public onlyOwner 
    {
	baseTokenURI = _b;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), "")) : "";
    }
    function _sendmoney(address _address, uint256 _amount) private 
    {
        (bool success, ) = _address.call{value: _amount}("");
	require(success, "Transfer failed.");
    }
    function withdraw(address payable to, uint256 amount) public onlyOwner 
    {
	require( address(this).balance >= amount, "Insufficient balance to withdraw");
	if (amount == 0) { 
	    amount = address(this).balance;
	}
	to = payable(owner());
	_sendmoney(to,amount);
    }
    function getprice() public view virtual returns (string memory) 
    {
	return Strings.toString(mintprice);
    }
    function getminted() public view returns (string memory) 
    {
	return Strings.toString(currentTokenId);
    }
    function setprice(uint256 _p) public onlyOwner 
    {
	mintprice=_p;
    }
    function setmaxminteditem(uint256 _p) public onlyOwner 
    {
	maxminteditems=_p;
    }
    function setmintpause(uint256 _st) external onlyOwner
    {
        mintpause = _st;
    }
    function setwhitelistmintopen(uint256 _st) external onlyOwner
    {
        whitelistmintopen = _st;
    }
    function setrafflemintopen(uint256 _st) external onlyOwner
    {
        rafflemintopen = _st;
    }
    function setpublicmintopen(uint256 _st) external onlyOwner
    {
        publicmintopen = _st;
    }
    function getmintstatus() public view virtual returns (string memory) 
    {
	return string(abi.encodePacked("mintpause:",Strings.toString(mintpause),";whitelist:",Strings.toString(whitelistmintopen), ";raffle:",Strings.toString(rafflemintopen), ";public:",Strings.toString(publicmintopen), ";maxminteditems:",Strings.toString(maxminteditems), ";mintprice:",Strings.toString(mintprice) ));
    }
    function setwhitelistroot(bytes32 _mr) public onlyOwner
    {
	whroot = _mr;
    }
    function getwhitelistroot() public view virtual returns (bytes32) 
    {
	return whroot;
    }
    function setraffleroot(bytes32 _mr) public onlyOwner
    {
	raroot = _mr;
    }
    function getraffleroot() public view virtual returns (bytes32) 
    {
	return raroot;
    }
}