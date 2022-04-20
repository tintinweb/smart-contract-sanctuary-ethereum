//  ,888     8888    ,88'   8 8888                 
// 888^8     8888   ,88'    8 8888         
//   8|8     8888  ,88'     8 8888         
//   8N8     8888 ,88'      8 8888         
//   8G8     888888<        8 8888         
//   8U8     8888 `MP.      8 8888         
//   8|8     8888   `JK.    8 8888         
// /88888\   8888     `JO.  8888888888888 

pragma solidity ^0.5.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

contract ERC165 is IERC165 {
    
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

pragma solidity ^0.5.0;

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.0;

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;


contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping (uint256 => address) private _tokenOwner;

    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => Counters.Counter) private _ownedTokensCount;

    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }


    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        // emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        // emit Transfer(owner, address(0), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }


    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;


contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}


pragma solidity ^0.5.0;

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mintToken(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.5.0;


contract CustomERC721Metadata is ERC165, ERC721Enumerable {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

}

pragma solidity ^0.5.0;

//https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
library Strings {

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity ^0.5.0;

interface SubContract {
    function getAdmin() external view returns (address);
    function getArtist() external view returns (address);
    function setMaster(address _masterAddress) external;
    function setBlockStart(uint256 startDate) external;
    function getBlockStart() external view returns (uint256);
    function getMaxSupply() external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function setMaxSupply(uint256 supply) external;
    function setMaxMintAmount(uint256 _newmaxMintAmount) external;
    function getMaxMintAmount() external view returns (uint256);
    function canMint(bool mintFlag) external;
    function getBaseURI() external view returns (string memory);
    function setBaseURI(string calldata _newBaseURI) external;
    function setMetaDataExt(string calldata _newExt) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function mint(address _to) external returns (uint256);
    function mintId(address _to, uint256 _tokenId) external;
    function addBatchWhitelisted(address[] calldata mintWhitelist) external;
    function checkWhitelisted(address _to) external view returns (bool);
    function removeWhitelisted(address _address) external;
    function upgradeWhitelistVersion() external;
    function setCost(bool isPublic, uint256 _newCost) external;
    function getCost() external view returns(uint256);
    function getSaleType() external view returns(bool);
    function setRandom(bool _flag) external;
}

contract Exposed is CustomERC721Metadata, Ownable {
    using SafeMath for uint256;

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId
    );

    uint256 public royalty = 10000;
    uint256 public pubSaleCost = 3000000000000000000;
    uint256 public prvSaleCost = 3000000000000000000;
    uint256 public nextProjectId = 0;
    uint256 public currentMintWhiteListVersion = 0;

    bool public publicSale = true;
    bool public useMasterPrice = true;

    // SubContract public subContract;

    mapping(uint256 => SubContract) subContract;
    mapping(uint256 => address) project;
    mapping(address => uint256) subContractAddress;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    
    address public admin;

    uint256 ONE_MILLION = 1_000_000;

    mapping(address => bool) public isWhitelisted;
    mapping(uint256 => mapping(address => bool)) public isMintWhitelisted;
    mapping(address => uint256) public balanceOfAddress;
    

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Only whitelisted");
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol) CustomERC721Metadata(_tokenName, _tokenSymbol) public {
        admin = msg.sender;
        isWhitelisted[msg.sender] = true;
        isMintWhitelisted[currentMintWhiteListVersion][msg.sender] = true;
    }

    // admin function
    function setMasterCost(bool isPublic, uint256 _newCost) external onlyAdmin {
        if(isPublic) {
            pubSaleCost = _newCost;
        }
        else {
            prvSaleCost = _newCost;
        }
    }

    function getMasterCost(bool isPublic) public view returns(uint256) {
        if(isPublic) {
            return pubSaleCost;
        }
        return prvSaleCost;
    }

    function setSaleType(bool flag) external onlyAdmin {
        publicSale = flag;
    }

    function setMasterPriceUsage(bool flag) external onlyAdmin {
        useMasterPrice = flag;
    }

    function getSaleType() external view returns(bool) {
        return publicSale;
    }

    function getMintCost(uint256 _projectId) public view returns(uint256) {
        if(useMasterPrice) {
            return getMasterCost(publicSale);
        }
        return getSubCost(_projectId);
    }
    
    function addProject(address _subContractAddress) public onlyWhitelisted {
        project[nextProjectId] = _subContractAddress;
        subContractAddress[_subContractAddress] = nextProjectId;
        subContract[nextProjectId] = SubContract(_subContractAddress);
        nextProjectId = nextProjectId.add(1);
    }

    function setRoyalty(uint256 _newFee) external onlyAdmin {
        royalty = _newFee;
    }

    function updateAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
    
    function addWhitelisted(address _address) public onlyAdmin {
        isWhitelisted[_address] = true;
    }

    function removeWhitelisted(address _address) public onlyAdmin {
        isWhitelisted[_address] = false;
    }

    function addMintWhitelisted(address _address) public onlyAdmin {
        isMintWhitelisted[currentMintWhiteListVersion][_address] = true;
    }

    function upgradeMintWhitelistVersion() public onlyAdmin {
        currentMintWhiteListVersion++;
    }

    function addBatchMintWhitelisted(address[] memory mintWhitelist) public onlyAdmin {
        for(uint256 i=0; i<mintWhitelist.length; i++) {
            addMintWhitelisted(mintWhitelist[i]);
        }
    }

    function setBatchCost(uint256[] memory _newCosts, bool _saleType) public onlyAdmin {
        for(uint256 i=0; i<nextProjectId; i++) {
            setSubCost(i, _saleType, _newCosts[i]);
        }
    }

    function removeMintWhitelisted(address _address, uint256 version) public onlyAdmin {
        isMintWhitelisted[version][_address] = false;
    }

    function withdraw() public {
        address payable wallet = address(msg.sender);
        wallet.transfer(balanceOfAddress[msg.sender]);
    }

    function mint(uint256 _projectId) external payable returns (uint256 _tokenId) {
        require(msg.value >= getMintCost(_projectId), "Value should be more than mint cost.");
        require(publicSale || isMintWhitelisted[currentMintWhiteListVersion][msg.sender] || subContract[_projectId].checkWhitelisted(msg.sender) || subContract[_projectId].getSaleType(), "Mint is not permitted.");
        
        uint256 tokenId = subContract[_projectId].mint(msg.sender);
        tokenIdToProjectId[tokenId + _projectId * ONE_MILLION] = _projectId;
        address artist = subContract[_projectId].getArtist();
        balanceOfAddress[artist] = balanceOfAddress[artist].add(msg.value * royalty / 10000);
        balanceOfAddress[admin] = balanceOfAddress[admin].add(msg.value).sub(msg.value * royalty / 10000);

        _mintToken(msg.sender, tokenId + _projectId * ONE_MILLION);

        emit Mint(msg.sender, tokenId + _projectId * ONE_MILLION);

        return tokenId;
    }

    function mintId(uint256 _projectId, uint256 tokenId) external payable {
        require(msg.value >= getMintCost(_projectId), "Value should be more than mint cost.");
        require(publicSale || isMintWhitelisted[currentMintWhiteListVersion][msg.sender] || subContract[_projectId].checkWhitelisted(msg.sender) || subContract[_projectId].getSaleType(), "Mint is not permitted.");
        require(!_exists(tokenId + _projectId * ONE_MILLION), "TokenId already exists.");

        subContract[_projectId].mintId(msg.sender, tokenId);
        tokenIdToProjectId[tokenId + _projectId * ONE_MILLION] = _projectId;
        address artist = subContract[_projectId].getArtist();
        balanceOfAddress[artist] = balanceOfAddress[artist].add(msg.value * royalty / 10000);
        balanceOfAddress[admin] = balanceOfAddress[admin].add(msg.value).sub(msg.value * royalty / 10000);

        _mintToken(msg.sender, tokenId + _projectId * ONE_MILLION);

        emit Mint(msg.sender, tokenId + _projectId * ONE_MILLION);
    }

    // inside of subContract
    function getAdmin(uint256 _projectId) public view returns (address) {
        // subContract = SubContract(project[_projectId]);
        return subContract[_projectId].getAdmin();
    }

    function getArtist(uint256 _projectId) public view returns (address) {
        return subContract[_projectId].getArtist();
    }

    function setMaster(uint256 _projectId, address _masterAddress) public onlyAdmin {
        subContract[_projectId].setMaster(_masterAddress);
    }

    function setBlockStart(uint256 _projectId, uint256 _newBlockStart) public onlyAdmin {
        subContract[_projectId].setBlockStart(_newBlockStart);
    }

    function getBlockStart(uint256 _projectId) public view returns (uint256) {
        return subContract[_projectId].getBlockStart();
    }

    function getMaxSupply(uint256 _projectId) public view returns (uint256) {
        return subContract[_projectId].getMaxSupply();
    }

    function getTotalSupply(uint256 _projectId) public view returns (uint256) {
        return subContract[_projectId].getTotalSupply();
    }

    function setMaxSupply(uint256 _projectId, uint256 _newMaxSupply) public onlyAdmin {
        subContract[_projectId].setMaxSupply(_newMaxSupply);
    }

    function setMaxMintAmount(uint256 _projectId, uint256 _newmaxMintAmount) public onlyAdmin {
        subContract[_projectId].setMaxMintAmount(_newmaxMintAmount);
    }

    function getMaxMintAmount(uint256 _projectId) public view returns (uint256) {
        return subContract[_projectId].getMaxMintAmount();
    }

    function setMintable(uint256 _projectId, bool mintFlag) public onlyAdmin {
        subContract[_projectId].canMint(mintFlag);
    }

    function getBaseURI(uint256 _projectId) public view returns (string memory) {
        return subContract[_projectId].getBaseURI();
    }

    function setBaseURI(uint256 _projectId, string memory _newBaseURI) public onlyAdmin {
        subContract[_projectId].setBaseURI(_newBaseURI);
    }

    function setMetaDataExt(uint256 _projectId, string memory _newExt) public onlyAdmin {
        subContract[_projectId].setMetaDataExt(_newExt);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return subContract[tokenIdToProjectId[tokenId]].tokenURI(tokenId - tokenIdToProjectId[tokenId] * ONE_MILLION);
    }

    function addSubBatchMintWhitelisted(uint256 _projectId, address[] memory mintWhitelist) public onlyAdmin {
        subContract[_projectId].addBatchWhitelisted(mintWhitelist);
    }

    function removeSubWhitelisted(uint256 _projectId, address _address) public onlyAdmin {
        subContract[_projectId].removeWhitelisted(_address);
    }

    function upgradeSubWhitelistVersion(uint256 _projectId) public onlyAdmin {
        subContract[_projectId].upgradeWhitelistVersion();
    }

    function setSubCost(uint256 _projectId, bool _saleType, uint256 _newCost) public onlyAdmin {
        subContract[_projectId].setCost(_saleType, _newCost);
    }

    function getSubCost(uint256 _projectId) public view returns (uint256) {
        return subContract[_projectId].getCost();
    }
}