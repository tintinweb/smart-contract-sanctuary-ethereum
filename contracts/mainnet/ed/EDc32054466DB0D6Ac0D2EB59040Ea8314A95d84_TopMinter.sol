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


interface ITopMinterSetup {
    function setup_constructor(string calldata name,string calldata symbol,
        address _owner,
        address _coo,
        uint256 _value,
        //uint64 _nftMintStartTime uint64 _nftMintEndTime uint32 _singleAddressLimit uint32 _singleTimeLimit 
        //uint32 _nftNumber uint32 _nftPriceinETH
        uint256 _value1,
        //uint8 refund_line uint8 copyright  uint8 POWMint
        string calldata _uri_prefix
    )  external ;
}


interface ITMFactory {
    function newTopMinter(string calldata name,string calldata symbol,
        uint256 _value,
        uint256 _value1
    )  external ;
    function setup_constructor(address _owner,address _auditor,address _am,address _VRFCoordinator,address _linktoken,string calldata _prefix) external;
    function getAdmin()  external view returns (address);
    function setAdmin(address b) external;
    function requestChainlink() external;
}

contract TopMinter is Ownable,ERC721Full,ReentrancyGuard,ITopMinterSetup,RadicalNFT {

    address public cooAddress;
    uint256 public nftNumber;
    uint256 public nftPriceinETH;
    uint256 public curid;
    bytes32 public merkleRoot;

    uint8 public refund_line;
    uint8 public copyright;
    uint8 public POWMint;

    
    //ALL
    uint256 public nftMintStartTime;
    uint256 public nftMintEndTime;
    uint256 public singleAddressLimit;
    uint256 public singleTimeLimit;

    //WhiteList
    uint256 public nftWLNumber;
    uint256 public nftWLPriceinETH;
    uint256 public nftWLMintStartTime;
    uint256 public nftWLMintEndTime;
    uint256 public WLsingleAddressLimit;
    uint256 public WLsingleTimeLimit;

    // map for mint count
    mapping(address => uint256) private mintMap;
    string public uri_prefix;
    uint256 nftWLMint;
    address public factory_address;

   
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
        uint256 _value1,
        //uint8 refund_line uint8 copyright  uint8 POWMint
        string calldata _uri_prefix
    )  external {
        require(address(0)==owner,"owner not zero error");
        _name=name;
        _symbol=symbol;
        owner=_owner;
        cooAddress=_coo;
        factory_address=msg.sender;
        
        nftNumber= (_value>>32)&0xffff;
        nftPriceinETH= _value&0xffff;
        nftPriceinETH=nftPriceinETH*0.01 ether;
        nftMintStartTime= (_value>>192)&0xffffffff;
        nftMintEndTime= (_value>>128)&0xffffffff;
        singleAddressLimit= (_value>>96)&0xffff;
        singleTimeLimit= (_value>>64)&0xffff;

        refund_line=uint8((_value1>>16)&0xff);
        copyright=uint8((_value1>>8)&0xff);
        POWMint=uint8(_value1&0xff);
        _status = _NOT_ENTERED;

        uri_prefix=string(abi.encodePacked(_uri_prefix, name));
    }
    function setCOO(address _newCOO) external onlyCLevel {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
    function setUriPrefix(string calldata _prefix) external onlyCLevel {
        uri_prefix=_prefix;
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


    function getOwner()
        external view
        returns (address)
    {
        return owner;
    }

    function blockTimestamp()internal view returns(uint256){
        return now;
    }
    function getPOWMatchBytes()public view returns(bytes32){

         bytes32 h= keccak256(abi.encodePacked(msg.sender,address(this),owner));
         return h;

        }

    function getVerify(uint256 pow_index)internal view returns(bytes32){

         bytes32 h= keccak256(abi.encodePacked(msg.sender,pow_index));
         return h;

    }

    function verifyPOW(uint256 pow_index,uint256 _nftNumber)internal view returns(bool){

        
        uint256 h= uint256(keccak256(abi.encodePacked(msg.sender,pow_index)));

        uint256 c=uint256(getPOWMatchBytes());
        
        uint256 i=0;
        for(;;){
            i++;
            _nftNumber>>=1;
            if(_nftNumber==0){
                break;
            }
        }
   
        uint256 x=i+POWMint*8;

        uint256 mask=1;
        for(uint256 j=0;j<x-1;j++){
            mask|=mask<<1;
        }

        return (h&mask)==(c&mask);
    }

    //=====================================
    function normalMintPOW(address account,uint256 amount,uint256 pow_index)
        external payable
    {
        require(POWMint>0,"Mustcall normalMint");
        require(verifyPOW(pow_index,amount),"verifyPOW fail");
        _normalMint(account, amount);
    }
    //=====================================
    function normalMint(address account,uint256 amount)nonReentrant
        external payable
    {
        require(POWMint==0,"Mustcall normalMintPOW");
        _normalMint(account, amount);
    }

    function _normalMint(address account,uint256 amount)
        internal
    {
        require(mintMap[account]+amount<=singleAddressLimit, 'mint exceed max claimed.');
        require(blockTimestamp()>=nftMintStartTime,'Mint not start yet');
        require(blockTimestamp()<=nftMintEndTime,'Mint end yet');
        require(amount<=singleTimeLimit,"exceed one time limit");
        require(curid<nftNumber,"nftNumber reached");

        uint256 pprice=amount*nftPriceinETH;
        require(msg.value>=pprice, "ERR_NOT_ENOUGH_MONEY");
        //refund extra money
        msg.sender.send(msg.value-pprice);

        for(uint256 i=0;i<amount;i++){
            _mint(account, curid);
            curid++;
        }
        // Mark it claimed and send the token.
        mintMap[account]+=amount;
    }

    function setWhiteList(bytes32 _mr,
        uint256 _nftWLNumber,
        uint256 _nftWLPriceinETH,
        uint256 _nftWLMintStartTime,
        uint256 _nftWLMintEndTime,
        uint256 _WLsingleAddressLimit,
        uint256 _WLsingleTimeLimit)
        external
        onlyOwner
    {
        merkleRoot=_mr;
        nftWLPriceinETH=_nftWLPriceinETH*0.01 ether;
        nftWLNumber=_nftWLNumber;
        nftWLMintStartTime=_nftWLMintStartTime;
        nftWLMintEndTime=_nftWLMintEndTime;
        WLsingleAddressLimit=_WLsingleAddressLimit;
        WLsingleTimeLimit=_WLsingleTimeLimit;
    }
    function WLMint(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)nonReentrant external payable  {
        require(mintMap[account]+amount<=WLsingleAddressLimit, 'mint exceed max claimed.');
        require(blockTimestamp()>=nftWLMintStartTime,'WLMint not start yet');
        require(blockTimestamp()<=nftWLMintEndTime,'WLMint end yet');
        require(amount<=WLsingleTimeLimit,"exceed one time limit");
        require(nftWLMint+amount<=nftWLNumber,"nft white list number maxed");

        uint256 pprice=amount*nftWLPriceinETH;
        require(msg.value>=pprice, "ERR_NOT_ENOUGH_MONEY");

        //refund extra money
         msg.sender.send(msg.value-pprice);

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, uint256(0x10)));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        for(uint256 i=0;i<amount;i++){
            _mint(account, curid);
            curid++;
        }
        // Mark it claimed and send the token.
        nftWLMint+=amount;
        mintMap[account]+=amount;

    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return append(uri_prefix,"/",tokenId,".json");
    }
    function append(string memory a, string memory b, uint c,string memory end) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, uintToString(c),end));

    }
    function uintToString(uint v) public pure returns (string memory str) {
        uint maxlength = 100;
        if(v==0)return "0";
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function refund() external  {
        //open for online
        require(blockTimestamp()>nftMintEndTime,'Mint not end yet');
        require((curid*100/nftNumber)<refund_line,'refund line not reached');

        //burn all nft the user have and transfer the money back
         uint256[] memory tokenIds = _tokensOfOwner(msg.sender);
        
        uint256 n=100;
        if(tokenIds.length<100){
            n=tokenIds.length;
        }
        for(uint index = 0; index < n; index++) {
            //destroy
            _transferFrom(msg.sender, address(1), tokenIds[index]);
        }
        address(uint160(msg.sender)).transfer(n*nftPriceinETH);
    }
    function withdraw(address pool) external onlyOwner {
        //open for online
        require(blockTimestamp()>nftMintEndTime,'Mint not end yet');
        require((curid*100/nftNumber)>=refund_line,'refund line reached');

        //project owner withdraw all fund
        address(uint160(pool)).transfer(address(this).balance);
    }


    function requestRandom() external payable {
        require(msg.value==0.01 ether, "ERR_NOT_ENOUGH_MONEY");

        ITMFactory it=ITMFactory(factory_address);

        it.requestChainlink();
    }
  
    function getBuildNumber() external pure returns (uint256) {
        return 2030;
    }
 
}