/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract ReentrancyGuard {
 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    
    function mintOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
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


library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

 
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }


    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }


    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }


    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }


    function released(address account) public view returns (uint256) {
        return _released[account];
    }


    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }



  
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

 
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }


    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }


    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}



interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}





interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    function mintOf(address owner) external view returns (uint256 balance);
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
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




interface IERC721Enumerable is IERC721 {
 
    function totalSupply() external view returns (uint256);

 
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);


    function tokenByIndex(uint256 index) external view returns (uint256);
}






interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function tokenURI(uint256 tokenId) external view returns (string memory);
}





abstract contract ERC721P is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    string private _name;
    string private _symbol;
    address[] internal _owners;
    address[] internal _minters;
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
        uint count = 0;
        uint length = _owners.length;
        for( uint i = 0; i < length; ++i ){
          if( owner == _owners[i] ){
            ++count;
          }
        }
        delete length;
        return count;
    }

    function mintOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint count = 0;
        uint length = _minters.length;
        for( uint i = 0; i < length; ++i ){
          if( owner == _minters[i] ){
            ++count;
          }
        }
        delete length;
        return count;
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721P.ownerOf(tokenId);
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
    ) public virtual override {
        //solhint-disable-next-line max-line-length
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
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }
	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721P.ownerOf(tokenId);
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
        _owners.push(to);
        _minters.push(to);

        emit Transfer(address(0), to, tokenId);
    }
	function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721P.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
	function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721P.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
	function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721P.ownerOf(tokenId), to, tokenId);
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
// File: pagzi/ERC721Enum.sol




abstract contract ERC721Enum is ERC721P, IERC721Enumerable {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721P) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
        uint count;
        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }
        require(false, "ERC721Enum: owner ioob");
    }
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        require(0 < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enum.totalSupply(), "ERC721Enum: global ioob");
        return index;
    }
}
// File: beepos.sol


// Author: Beepos;






contract Beepos is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard {
	using Strings for uint256;
	string public baseURI;
	//sale settings
	uint256 public cost = 0.055 ether;
	uint256 public maxSupply = 10000;
	uint256 public maxMint = 3;
	uint256 public MaxMintPerWallet = 3;
	struct User {
		uint256 minted;
    }
	mapping (address => User) public users;

	bool public status = false;
	//presale settings
	uint256 public presaleDate = 1637132400;
	mapping(address => uint256) public presaleWhitelist;
	//share settings
	address[] private addressList = [
	0xB80DA8531034854c01BF61Ee6CC2A191f3569FE4,
	0xCfEfF78B5e8bc1cf6C495a61720e05e373e40C57,
	0xa68C9b9558F4706331DC410706FB6Dde90788286,
	0xE2d7AAb994eeC70A6e0B172D306b75A870f3b7b7
	];
	uint[] private shareList = [25,25,25,25];
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) ERC721P(_name, _symbol)
	PaymentSplitter( addressList, shareList ){
	setBaseURI(_initBaseURI);
	}
	// internal
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}
	// public minting
	function mint(uint256 _mintAmount) public payable nonReentrant{
	require(users[msg.sender].minted + _mintAmount <= MaxMintPerWallet || msg.sender==owner(), "Exceeds max mint limit per wallet");
	uint256 s = totalSupply();
	require(status, "Off" );
	require(_mintAmount > 0, "Duh" );
	require(_mintAmount <= maxMint, "Too many" );
	require(s + _mintAmount <= maxSupply, "Sorry" );
	require(msg.value >= cost * _mintAmount);
	for (uint256 i = 0; i < _mintAmount; ++i) {
	  _safeMint(msg.sender, s + i, "");
	}
	users[msg.sender].minted = users[msg.sender].minted + _mintAmount;
	delete s;
	}
    
	function mintPresale(uint256 _mintAmount) public payable {
	require(presaleDate <= block.timestamp, "Not yet");
	require(users[msg.sender].minted + _mintAmount <= MaxMintPerWallet || msg.sender==owner(), "Exceeds max mint limit per wallet");
	uint256 s = totalSupply();
	uint256 reserve = presaleWhitelist[msg.sender];
	require(!status, "Off");
	require(reserve > 0, "Low reserve");
	require(_mintAmount <= reserve, "Try less");
	require(s + _mintAmount <= maxSupply, "More than max");
	require(cost * _mintAmount == msg.value, "Wrong amount");
	presaleWhitelist[msg.sender] = reserve - _mintAmount;
	delete reserve;
	for(uint256 i; i < _mintAmount; i++){
	_safeMint(msg.sender, s + i, "");
	}
	users[msg.sender].minted = users[msg.sender].minted + _mintAmount;
	delete s;
	}
	// admin minting
	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
	require(quantity.length == recipient.length, "Provide quantities and recipients" );
	uint totalQuantity = 0;
	uint256 s = totalSupply();
	for(uint i = 0; i < quantity.length; ++i){
	totalQuantity += quantity[i];
	}
	require( s + totalQuantity <= maxSupply, "Too many" );
	delete totalQuantity;
	for(uint i = 0; i < recipient.length; ++i){
	for(uint j = 0; j < quantity[i]; ++j){
	_safeMint( recipient[i], s++, "" );
	}
	}
	delete s;	
	}
	// admin functionality
	function presaleSet(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
	for(uint256 i; i < _addresses.length; i++){
	presaleWhitelist[_addresses[i]] = _amounts[i];
	}
	}
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	function setCost(uint256 _newCost) public onlyOwner {
	cost = _newCost;
	}
	function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
	maxMint = _newMaxMintAmount;
	}
	function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	maxSupply = _newMaxSupply;
	}
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}
	function setSaleStatus(bool _status) public onlyOwner {
	status = _status;
	}
	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	} 
	function updateMintPerWalletLimit(uint256 newLimit) external onlyOwner {
       MaxMintPerWallet = newLimit;
    }
}