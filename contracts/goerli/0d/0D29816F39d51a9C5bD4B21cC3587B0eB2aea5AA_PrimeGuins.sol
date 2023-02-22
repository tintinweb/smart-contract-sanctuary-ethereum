// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
	
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
	
    function functionCallWithValue(address target, bytes memory data, uint256 value ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
	
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
		
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
	
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
	
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
	
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
	
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
		
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
	
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

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
	
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
	
    function safeTransferFrom( address from, address to, uint256 tokenId ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
	
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
	
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
	
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
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
	
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
	
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
	
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
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
	
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
	mapping(uint256 => uint256) private _allTokensIndex;

    uint256[] private _allTokens;

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
	
    function _beforeTokenTransfer(address from, address to, uint256 tokenId ) internal virtual override {
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

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
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


interface IBPebbles {
   function mint(address user, uint256 amount) external;
}

contract PrimeGuins is ERC721, Ownable, ERC721Enumerable, ReentrancyGuard {
    using Strings for uint256;
	
	uint256 public SalePrice = 0.055 ether;
	
	uint256[4] public SaleNFT = [10,90,900,4500]; // Giveaway 10, Genesis PrimeGuins (90), Genesis PrimeGuins (900), PrimeGuins (4500)
    uint256[4] public BatchStarted = [1,11,100,1001];
	uint256[4] public NFTMinted = [0,0,0,0];
	
    uint256 public LimitPerTrx = 3;
	uint256 public LimitPerWallet = 5555;
	uint256 public initialize = block.timestamp;
	
	bool public SaleEnable = false;
	bool public GameMintEnable = false;
	
	address public GameAddress;
	address public BPebblesAddress;
	
	struct User {
	  uint256 MintedNFT;
	}
	
	struct NFTInfo {
	  uint256 BPebblesClaimed;
	  uint256 startTime;
	  uint256 endTime;
    }
	
	mapping (address => User) public users;
	mapping (uint256 => NFTInfo) public mapNFTInfo;
	
	event SalePriceUpdated(uint256 price);
	event SaleStatusUpdated(bool status);
	event GameMintStatusUpdated(bool status);
	event MintLimitUpdatedForWallet(uint256 limit);
	event MintLimitUpdatedForTransection(uint256 limit);
	event BaseURIUpdated(string uri);
	event FundWithdraw(uint256 fund);
	event GameAddressUpdated(address newAddress);
	event BPebblesAddressUpdated(address newAddress);
    string private baseURI;
	
    constructor() ERC721("PrimeGuins", "PG") {}
	
	/**************** Giveaway NFT Minting ******************************/
	function mintGiveawayNFT(address receiverAddress, uint256 NFTCount) external onlyOwner{
	    require(
		   NFTCount > 0, 
		   "Mint atleast one NFT"
		);
		require(
		   NFTMinted[0] + NFTCount <= SaleNFT[0], 
		   "Max limit reached"
		);
		for (uint256 i = 0; i < NFTCount; i++) {
		   uint256 tokenId = NFTMinted[0] + BatchStarted[0];
           _safeMint(receiverAddress, tokenId);
		   NFTMinted[0] += 1;
		   
		   mapNFTInfo[tokenId].startTime = block.timestamp;
		   mapNFTInfo[tokenId].endTime = block.timestamp + 157680000;
        }
    }
	
    /**************** Sale NFT Minting ******************************/
	function mintSaleNFT(uint256 NFTCount) external payable nonReentrant{
		require(
		    NFTCount > 0, 
			"Mint atleast one NFT"
		);
		require(
			SaleEnable, 
			"Sale is not enable"
		);
        require(
		   NFTMinted[1] + NFTMinted[3] + NFTCount <= SaleNFT[1] + SaleNFT[3], 
		   "Exceeds max mint limit"
		);
		require(
			users[msg.sender].MintedNFT + NFTCount <= LimitPerWallet,
			"Exceeds max mint limit per wallet"
		);
		require(
			NFTCount <= LimitPerTrx,
			"Exceeds max mint limit per trx"
		);
		require(
			msg.value == SalePrice * NFTCount,
			"Value below price"
		);
		for (uint256 i = 0; i < NFTCount; i++) {
		    if(SaleNFT[1] > NFTMinted[1])
			{
			   uint256 tokenId = NFTMinted[1] + BatchStarted[1];
			   _safeMint(msg.sender, tokenId);
			   NFTMinted[1] += 1;
			   
			   mapNFTInfo[tokenId].startTime = initialize;
		       mapNFTInfo[tokenId].endTime = initialize + 157680000;
			}
			else
			{
			   uint256 tokenId = NFTMinted[3] + BatchStarted[3];
			   _safeMint(msg.sender, tokenId);
			   NFTMinted[3] += 1; 
			}
        }
		users[msg.sender].MintedNFT += NFTCount;
    }
	
	/**************** Game NFT Minting ******************************/
	function mintGameNFT(address receiverAddress) external nonReentrant{
		require(
		   GameMintEnable, 
		   "Game mint is not enable"
		);
		require(
		   msg.sender == address(GameAddress),
		   "Caller is not correct"
		);
        require(
		   NFTMinted[2] + 1 <= SaleNFT[2], 
		   "Exceeds max mint limit"
		);
		uint256 tokenId = NFTMinted[2] + BatchStarted[2];
	    _safeMint(receiverAddress, tokenId);
		NFTMinted[2] += 1;
		
		mapNFTInfo[tokenId].startTime = initialize;
		mapNFTInfo[tokenId].endTime = initialize + 157680000;
    }
	
	function withdrawBPebbles(uint256[] calldata NFT) external {
		for(uint i=0; i < NFT.length; i++) {
			require(
			  ownerOf(NFT[i]) == address(msg.sender),
			  "Owner of NFT is not correct"
			);
		    uint256 pending = pendingBPebbles(NFT[i]);
			if (pending > 0) {
			    IBPebbles(BPebblesAddress).mint(address(msg.sender), pending);
			    mapNFTInfo[NFT[i]].BPebblesClaimed += pending;
			}
		}
    }
	
	function pendingBPebbles(uint256 NFT) public view returns (uint256) {
		if(10 < NFT && 901 > NFT)
		{
		   uint256 _startTime = initialize;
		   uint256 _endTime = initialize + 157680000;
		   
		   if(_endTime > block.timestamp)
		   {
			   uint256 pending = ((block.timestamp - _startTime) / 86400) * 10 * 10**18 - mapNFTInfo[NFT].BPebblesClaimed;
			   return pending;
		   }
		   else
		   {
			   uint256 pending = ((_endTime - _startTime) / 86400) * 10 * 10**18 - mapNFTInfo[NFT].BPebblesClaimed;
			   return pending;
		   }
		}
		else
		{
		    if(mapNFTInfo[NFT].startTime > 0) 
			{
				if(mapNFTInfo[NFT].endTime > block.timestamp)
				{
				   uint256 pending = ((block.timestamp - mapNFTInfo[NFT].startTime) / 86400) * 10 * 10**18 - mapNFTInfo[NFT].BPebblesClaimed;
				   return pending;
				}
				else
				{
				   uint256 pending = ((mapNFTInfo[NFT].endTime - mapNFTInfo[NFT].startTime) / 86400) * 10 * 10**18 - mapNFTInfo[NFT].BPebblesClaimed;
				   return pending;
				}
			} 
			else 
			{
			   return 0;
			}
		}
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }
	
	function withdraw() external onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
		
		emit FundWithdraw(address(this).balance);
    }
	
	function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
		emit BaseURIUpdated(newBaseURI);
    }
	
	function updateMintLimitPerTransection(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Incorrect value");
		LimitPerTrx = newLimit;
		emit MintLimitUpdatedForTransection(newLimit);
    }
	
	function updateMintLimitPerWallet(uint256 newLimit) external onlyOwner {
	    require(newLimit > 0, "Incorrect value");
        LimitPerWallet = newLimit;
		emit MintLimitUpdatedForWallet(newLimit);
    }
	
	function setSaleStatus(bool status) external onlyOwner {
        require(SaleEnable != status, "Incorrect value");
		SaleEnable = status;
		emit SaleStatusUpdated(status);
    }
	
	function setGameMintStatus(bool status) external onlyOwner {
        require(GameMintEnable != status, "Incorrect value");
		GameMintEnable = status;
		emit GameMintStatusUpdated(status);
    }
	
	function setGameAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Incorrect value");
		GameAddress = address(newAddress);
		emit GameAddressUpdated(newAddress);
    }
	
	function setBPebblesAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Incorrect value");
		BPebblesAddress = address(newAddress);
		emit BPebblesAddressUpdated(newAddress);
    }
	
	function updateSalePrice(uint256 NewPrice) external onlyOwner {
	    SalePrice = NewPrice;
	    emit SalePriceUpdated(NewPrice);
	}
}