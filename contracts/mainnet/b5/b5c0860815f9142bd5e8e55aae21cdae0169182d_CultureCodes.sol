/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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

interface ERC721TokenReceiver{
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

library SafeMath {


    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
	
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
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



contract CultureCodes is IERC721, Ownable {

    using SafeMath for uint256;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
	
	string public proof;
	uint256 internal numTokens = 0;
	uint256 public constant TOKEN_LIMIT = 1000;
	uint256 public price = 0.15 ether;	//1000000000000000000 wei = 1 ETH

    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping (uint256 => address) internal idToOwner;
    mapping (uint256 => address) internal idToApproval;
	mapping (uint256 => uint256) internal idToOwnerIndex;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    mapping (address => uint256[]) internal ownerToIds;
    

    string internal NFTname = "CultureCodes";
    string internal NFTsymbol = "CC";
	string private _contractURI;
	string private _tokenBaseURI;
	bool public locked;
	bool public publicsale;
    bool public holdermint;
	
	
	
	//Grants:
	mapping(address => bool) internal grants;
	mapping(address => mapping (uint256 => bool)) private _grantedToken;
	address private _signerAddress;

    

    uint[TOKEN_LIMIT] internal indices;
	// location where token(the key) is available, the value of map in range from 1 to TOKEN_LIMIT:
	mapping ( uint256 => uint256) internal availablein;
	


	
	modifier notLocked {
        require(!locked, "Locked");
        _;
    }
	

    bool private reentrancyLock = false;

    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Cannot operate.");
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender], "Cannot transfer."
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    constructor() { 
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
		grants[0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D] = true;	//free mint granted for BAYC
		_signerAddress = 0xfeFF9016EFBb5fccAdb87444285BFEd17E1a071A;
    }


    //ERC 721 and 165

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) external view override returns (address _owner) {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) external view override validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }
	
	
	
	
    function randomIndex() internal returns (uint) {
        uint totalSize = TOKEN_LIMIT - numTokens;
        uint index = uint(keccak256(abi.encodePacked(numTokens, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;
        } else {
            indices[index] = indices[totalSize - 1];
        }
       
        return value.add(1);
    }


	

	
	function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {

		require(signature.length == 65);		
		

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);
        return ecrecover(hash, v, r, s);

    }

	
	
	function HolderMint(bytes calldata signature, uint256 token ) external payable reentrancyGuard {
		require(holdermint, "HOLDERS MINT CLOSED");
		require(idToOwner[token] == address(0),"Token Already Migrated");
		
		bytes32 hash = keccak256(
								abi.encodePacked("\x19Ethereum Signed Message:\n32",
												keccak256(
															abi.encodePacked(
																			msg.sender,token,address(this)
																			)
														)
												)
								);

		require(recover(hash, signature)==_signerAddress, "INVALID SIGNATURE");

		uint256 index = TOKEN_LIMIT - numTokens - 1 ;
		uint256 value = indices[index] ;//last available value		
		
		uint256 loc;

		if(availablein[token-1] == 0)
			loc = token-1;
		else
			loc = availablein[token-1]-1;
		
		if( value == 0 ){
			indices[ loc ] = index;		
			}
		else{
			indices[ loc ] = value;
			}
		availablein[ indices[loc] ] = loc + 1 ;



		
		numTokens = numTokens + 1;
        _addNFToken(msg.sender, token);
        emit Transfer(address(0), msg.sender, token);

    }
	
	
	function HolderMintBatch(bytes calldata signature, uint256[] calldata tokens ) external payable reentrancyGuard {
		require(holdermint, "HOLDERS MINT CLOSED");
		
		string memory tokenlist = toString(tokens[0]);
		for(uint256 i = 1; i < tokens.length; i++) {
			tokenlist = string(                
                abi.encodePacked( tokenlist, ",", toString(tokens[i]) )
                );
			}
		
		
		bytes32 hash = keccak256(
								abi.encodePacked("\x19Ethereum Signed Message:\n32",
												keccak256(
															abi.encodePacked(
																			msg.sender,tokenlist,address(this)
																			)
														)
												)
								);

		require(recover(hash, signature)==_signerAddress, "INVALID SIGNATURE");

		for(uint256 i = 0; i < tokens.length; i++) {
				if(idToOwner[tokens[i]] == address(0)){
		

				uint256 index = TOKEN_LIMIT - numTokens - 1 ;
				uint256 value = indices[index] ;//last available value		
		
				uint256 loc;


				if(availablein[tokens[i]-1] == 0)
					loc = tokens[i]-1;
				else
					loc = availablein[tokens[i]-1]-1;
		
				if( value == 0 ){
					indices[ loc ] = index;		
					}
				else{
					indices[ loc ] = value;
					}
				availablein[ indices[loc] ] = loc + 1 ;
		
		
				numTokens = numTokens + 1;
				_addNFToken(msg.sender, tokens[i]);
				emit Transfer(address(0), msg.sender, tokens[i]);
				}
		}

		

    }

	
	function GrantMint(address collection, uint useId) external payable reentrancyGuard {
		require(publicsale, "PUBLIC SALE NOT OPEN");
		require(grants[collection], "Collection not granted");
		require(IERC721(collection).ownerOf(useId) == msg.sender, "Not the token owner");
		require(!_grantedToken[collection][useId],"Token Already Granted");
        require(numTokens.add(1) <= TOKEN_LIMIT, "Exceed supply");
		
		_mint(msg.sender);
		
		_grantedToken[collection][useId] = true;
    }

	function PublicMint(uint quantity) external payable reentrancyGuard {
		require(publicsale, "PUBLIC SALE NOT OPEN");
        require(quantity > 0 , "Can't be 0");
        require(numTokens.add(quantity) <= TOKEN_LIMIT, "Exceed supply");
        require(msg.value >= price.mul(quantity), "Insufficient funds.");
		for(uint i = 0; i < quantity; i++) {			
			_mint(msg.sender);			
        }
    }	
	
    function _mint(address _to ) internal {     
        uint256 _id = randomIndex(); 
		numTokens = numTokens + 1;
        _addNFToken(_to, _id);
        emit Transfer(address(0), _to, _id);
    }
	
	
	
	function withdraw() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
		}
		



    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "Already owned.");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == _ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }





    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public pure returns (uint256) {
        require(index >= 0 && index < TOKEN_LIMIT);
        return index+1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }




	
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    function name() external view returns (string memory _name) {
        _name = NFTname;
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = NFTsymbol;
    }

    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked(_tokenBaseURI, toString(_tokenId)));
    }
	
	function contractURI() public view returns (string memory) {
        return _contractURI;
    }
	
	
	
	
	
	
	function lockMetadata() external onlyOwner {
        locked = true;
    }
	
	function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }
	
	function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
	
	function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
	
	function toggleCollection(address collection) external onlyOwner {
        grants[collection] = !grants[collection];
    }
	
	function toggleHolderMint() external onlyOwner {
        holdermint = !holdermint;
    }

	function togglePublicSale() external onlyOwner {
        publicsale = !publicsale;
    }
	
	function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
	
	function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }
	
}