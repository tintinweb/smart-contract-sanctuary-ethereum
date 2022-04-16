// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.5.16;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.16;

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.16;

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        if(b > a){
            return 0;
        }
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    
    
}

pragma solidity ^0.5.16;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.16;

contract ERC165 is IERC165 {
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.16;

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        emit Transfer(address(0), to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
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

pragma solidity ^0.5.16;

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.16;

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        _ownedTokens[from].length--;
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity ^0.5.16;

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.5.16;

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {

    string internal _name;
    string internal _symbol;

    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

}

pragma solidity ^0.5.16;

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
   }
}
pragma solidity ^0.5.16;

contract IRadicalNFT is IERC165 {
    function round(uint256 _tokenid) external view returns (uint256 _round);
    function price(uint256 _round) public returns (uint256 _price);
    function getBidStartTime(uint256 tokenid)external view returns(uint64);
    function bid(address inviterAddress, uint256 tokenid) external payable;
}
contract RadicalNFT is ERC165,IRadicalNFT {

    bytes4 internal constant _INTERFACE_ID_RADICALNFT = 0x9203c74e;
 //       bytes4(keccak256('round(uint256)')) ^
 //       bytes4(keccak256('price(uint256)')) ^
 //       bytes4(keccak256('getBidStartTime(uint256)')) ^
 //   

    constructor () public {
       _registerInterface(_INTERFACE_ID_RADICALNFT);
    }
}

contract Ownable {
  address  owner;

    constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 internal _status;

    constructor ()public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}



contract MasterCopy  {
    address internal masterCopy;
    address internal _owner;
}
interface ITopMinterSetup {
    function setup_constructor(string calldata name,string calldata symbol,
        address _owner,
        address _coo,
        uint256 _value,
        bool _POWMint
    )  external ;
}
contract TopMinter is MasterCopy,Ownable,ERC721Full,ReentrancyGuard,ITopMinterSetup,RadicalNFT {

    address public cooAddress;
    uint256 public nftNumber;
    uint256 public nftPriceinETH;
    bool public POWMint;
    uint256 public curid;
    bytes32 public merkleRoot;
    
    //ALL
    uint256 public nftMintStartTime;
    uint256 public nftMintEndTime;
    uint256 public singleAddressLimit;
    uint256 public singleTimeLimit;

    //WhiteList
    uint256 nftWLNumber;
    uint256 nftWLMintStartTime;
    uint256 nftWLMintEndTime;
    uint256 WLsingleAddressLimit;
    uint256 WLsingleTimeLimit;

    // map for mint count
    mapping(address => uint256) private mintMap;

   
    constructor() ERC721Full("MasterCopy","")
    public {
       owner=address(1);
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress 
        );
        _;
    }
    function round(uint256 _tokenid) external view returns (uint256 _round){}
    function price(uint256 _round) public returns (uint256 _price){}
    function getBidStartTime(uint256 tokenid)external view returns(uint64){}
    function bid(address inviterAddress, uint256 tokenid) external payable{}

    function setup_constructor(string calldata name,string calldata symbol,
        address _owner,address _coo,
        uint256 _value,
        //uint64 _nftMintStartTime uint64 _nftMintEndTime uint32 _singleAddressLimit uint32 _singleTimeLimit 
        //uint32 _nftNumber uint32 _nftPriceinETH
        bool _POWMint
    )  external {
        require(address(0)==owner,"owner not zero error");
        _name=name;
        _symbol=symbol;
        owner=_owner;
        cooAddress=_coo;
        
        nftNumber= (_value>>32)&0xffff;
        nftPriceinETH= _value&0xffff;
        POWMint= _POWMint;
        nftMintStartTime= (_value>>192)&0xffffffff;
        nftMintEndTime= (_value>>128)&0xffffffff;
        singleAddressLimit= (_value>>96)&0xffff;
        singleTimeLimit= (_value>>64)&0xffff;
        _status = _NOT_ENTERED;
    }
    function setCOO(address _newCOO) external onlyCLevel {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
    function rescueETH(address _address) external onlyCLevel {
        address(uint160(_address)).transfer(address(this).balance);
    }
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return (interfaceId==_INTERFACE_ID_ERC165)
        ||(interfaceId==_ERC721_RECEIVED)
        ||(interfaceId==_INTERFACE_ID_ERC721)
        ||(interfaceId==_INTERFACE_ID_ERC721_ENUMERABLE)
        ||(interfaceId==_INTERFACE_ID_ERC721_METADATA)
        //||(interfaceId==_INTERFACE_ID_RADICALNFT)
;
    }
    function getMaster()
        external view
        returns (address)
    {
        return masterCopy;
    }
    function setMaster(address b)
        external
        onlyCLevel
    {
        masterCopy = b;
    }

    function getOwner()
        external view
        returns (address)
    {
        return owner;
    }

    function blockTimestamp()internal returns(uint256){
        return now;
    }
    //=====================================
    function normalMint(address account,uint256 amount)
        external
    {
        require(mintMap[account]+amount<singleAddressLimit, 'mint exceed max claimed.');
        require(blockTimestamp()>=nftMintStartTime,'Mint not start yet');
        require(blockTimestamp()<=nftMintEndTime,'Mint end yet');
        require(amount<=singleTimeLimit,"exceed one time limit");

        for(uint256 i=0;i<amount;i++){
            _mint(account, curid);
            curid++;
        }
        // Mark it claimed and send the token.
        mintMap[account]+=amount;
    }

    function setWhiteList(bytes32 _mr,
        uint256 _nftWLNumber,
        uint256 _nftWLMintStartTime,
        uint256 _nftWLMintEndTime,
        uint256 _WLsingleAddressLimit,
        uint256 _WLsingleTimeLimit)
        external
    {
        merkleRoot=_mr;
        nftWLNumber=_nftWLNumber;
        nftWLMintStartTime=_nftWLMintStartTime;
        nftWLMintEndTime=_nftWLMintEndTime;
        WLsingleAddressLimit=_WLsingleAddressLimit;
        WLsingleTimeLimit=_WLsingleTimeLimit;
    }
    function WLMint(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external  {
        require(mintMap[account]+amount<WLsingleAddressLimit, 'mint exceed max claimed.');
        require(blockTimestamp()>=nftWLMintStartTime,'WLMint not start yet');
        require(blockTimestamp()<=nftWLMintEndTime,'WLMint end yet');
        require(amount<=WLsingleTimeLimit,"exceed one time limit");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, WLsingleTimeLimit));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        for(uint256 i=0;i<amount;i++){
            _mint(account, curid);
            curid++;
        }
        // Mark it claimed and send the token.
        mintMap[account]+=amount;

    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return "";
    }

 
}