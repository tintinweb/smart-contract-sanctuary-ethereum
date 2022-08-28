//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";
import "src/Resolver.sol";
import "src/Util.sol";
import "src/Base.sol";

/**
 * @author 0xc0de4c0ffee, sshmatrix
 * @title BENSYC Core
 */
 
contract BoredENSYachtClub is BENSYC, Resolver {
    using Util for uint256;
    using Util for bytes;

    // @dev : maximum supply of subdomains
    uint256 public immutable maxSupply = 100;

    /// @dev : namehash of 'boredensyachtclub.eth'
    bytes32 public immutable DomainHash;
    
    /**
     * @dev Constructor
     */
    constructor() {
        Dev = msg.sender;
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        DefaultResolver = address(this);
        bytes32 _hash = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        DomainHash = keccak256(abi.encodePacked(_hash, keccak256("boredensyachtclub")));

        // Interface
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
        supportsInterface[type(iERC2981).interfaceId] = true;
    }

    /**
     * @dev EIP721: token name
     * @return : token name
     */
    function name() external view returns(string memory){
        return _name;
    }

    /**
     * @dev EIP721: returns owner of token ID
     * @param id : token ID 
     * @return : address of owner
     */
    function ownerOf(uint256 id) public view isValidToken(id) returns (address) {
        return _ownerOf[id];
    }

    /**
     * @dev returns namehash of token ID
     * @param id : token ID 
     * @return : namehash of corresponding subdomain
     */
    function ID2Namehash(uint256 id) public view isValidToken(id) returns (bytes32) {
        return keccak256(abi.encodePacked(DomainHash, ID2Labelhash[id]));
    }

    /**
     * @dev mint() function for single sudomain 
     */
    function mint() external payable {
        if (!active)
            revert ContractPaused();

        if (totalSupply > maxSupply)
            revert MintEnded();

        if (msg.value < mintPrice)
            revert InsufficientEtherSent(mintPrice, msg.value);
        
        uint256 _id = totalSupply;
        bytes32 _labelhash = keccak256(abi.encodePacked(_id.toString()));
        ENS.setSubnodeRecord(
            DomainHash, _labelhash, msg.sender, DefaultResolver, 0
        );
        ID2Labelhash[_id] = _labelhash;
        Namehash2ID[keccak256(abi.encodePacked(DomainHash, _labelhash))] = _id;
        unchecked {
            ++totalSupply;
            ++balanceOf[msg.sender];
        }
        _ownerOf[_id] = msg.sender;
        emit Transfer(address(0), msg.sender, _id);
    }

    /**
     * @dev : batchMint() function for sudomains 
     * @param batchSize : number of subdomains to mint in the batch (maximum batchSize = 12)
     */
    function batchMint(uint256 batchSize) external payable {
        if (!active)
            revert ContractPaused();

        if (totalSupply > maxSupply)
            revert MintEnded();

        if (batchSize > 12) // maximum batchSize = 12
            revert OversizedBatch();

        if (msg.value < mintPrice * batchSize)
            revert InsufficientEtherSent(mintPrice * batchSize, msg.value);

        uint256 _id = totalSupply;
        uint256 _mint = _id + batchSize;
        if (_mint > maxSupply)
            revert MintEnded();
        bytes32 _labelhash;
        while (_id < _mint) {
            _labelhash = keccak256(abi.encodePacked(_id.toString()));
            ENS.setSubnodeRecord(
                DomainHash, _labelhash, msg.sender, DefaultResolver, 0
            );
            ID2Labelhash[_id] = _labelhash;
            Namehash2ID[keccak256(abi.encodePacked(DomainHash, _labelhash))] = _id;
            _ownerOf[_id] = msg.sender;
            emit Transfer(address(0), msg.sender, _id);
            unchecked{
                ++_id;
            }
        }
        unchecked {
            totalSupply = _mint;
            balanceOf[msg.sender] += batchSize;
        }
    }

    /**
     * @dev : generic _transfer function
     * @param from : address of sender
     * @param to : address of receiver
     * @param id : subdomain token ID
     */
    function _transfer(address from, address to, uint256 id, bytes memory data) internal {
        if (!active)
            revert ContractPaused();

        if (to == address(0))
            revert ZeroAddress();

        if (_ownerOf[id] != from)
            revert NotSubdomainOwner(_ownerOf[id], from, id);

        if (
            msg.sender != _ownerOf[id] 
            && !isApprovedForAll[from][msg.sender] 
            && msg.sender != getApproved[id]
        ) revert Unauthorized(msg.sender, from, id);

        ENS.setSubnodeOwner(
            DomainHash, ID2Labelhash[id], to
        );
        unchecked {
            --balanceOf[from];  // subtract from owner
            ++balanceOf[to];    // add to receiver
        }
        _ownerOf[id] = to;      // change ownership
        delete getApproved[id]; // reset approved
        if (to.code.length > 0) {
            try iERC721Receiver(to).onERC721Received(msg.sender, from, id, data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector)
                    revert ERC721IncompatibleReceiver(to);
            } catch {
                revert ERC721IncompatibleReceiver(to);
            }
        }
        emit Transfer(from, to, id);
    }

    /**
     * @dev : transfer function
     * @param from : from address
     * @param to : to address
     * @param id : token ID
     */
    function transferFrom(address from, address to, uint256 id) external payable {
        _transfer(from, to, id, "");
    }

    /**
     * @dev : safeTransferFrom function with extra data
     * @param from : from address
     * @param to : to address
     * @param id : token ID
     * @param data : extra data
     */
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external payable {
        _transfer(from, to, id, data);
    }

    /**
     * @dev : safeTransferFrom function
     * @param from : from address
     * @param to : to address
     * @param id : token ID
     */
    function safeTransferFrom(address from, address to, uint256 id) external payable {
        _transfer(from, to, id, "");
    }

    /**
     * @dev : grants approval for a token ID
     * @param approved : operator address to be approved
     * @param id : token ID
     */
    function approve(address approved, uint256 id) external payable {
        if(msg.sender != _ownerOf[id])
            revert Unauthorized(msg.sender, _ownerOf[id], id);

        getApproved[id] = approved;
        emit Approval(msg.sender, approved, id);
    }

    /**
     * @dev : sets approval for all tokens
     * @param operator : operator address to be approved for all
     * @param approved : bool to set
     */
    function setApprovalForAll(address operator, bool approved) external payable {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev : generate metadata path corresponding to token ID
     * @param id : token ID
     * @return : IPFS path to metadata directory
     */
    function tokenURI(uint256 id) external view isValidToken(id) returns (string memory) {
        return string.concat("ipfs://", metaIPFS, "/", id.toString(), ".json");
    }

    /**
     * @dev : royalty payment to Dev (or multi-sig)
     * @param id : token ID
     * @param _salePrice : sale price
     * @return : ether amount to be paid as royalty to Dev (or multi-sig)
     */
    function royaltyInfo(uint256 id, uint256 _salePrice) external view returns (address, uint256){
        id; //silence warning
        return (Dev, (_salePrice/100) * royalty);
    }

    // Contract Management

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev : get owner of contract
     * @return : address of controlling dev or multi-sig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev : Toggle if contract is active or paused, only Dev can toggle
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev : sets Default Resolver
     * @param _resolver : resolver address
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        DefaultResolver = _resolver;
    }

    /**
     * @dev : sets OpenSea contractURI 
     * @param _contractURI : URI value
     */
    function setContractURI(string calldata _contractURI) external onlyDev {
        contractURI = _contractURI;
    }

    // 
    /**
     * @dev EIP2981 royalty standard
     * @param _royalty : royalty (1 = 1 %)
     */
    function setRoyalty(uint256 _royalty) external onlyDev {
        royalty = _royalty;
    }
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);
    function addr(bytes32 node) external view returns (address payable);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function name(bytes32 node) external view returns (string memory);
    
}

interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}

interface iERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface iENS {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);

    function setRecord(bytes32 node,address owner,address resolver,uint64 ttl) external;
    function setSubnodeRecord(bytes32 node,bytes32 label,address owner,address resolver,uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface iERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
}

interface iERC721 {
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

interface iERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

interface iERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
interface iBENSYC{
    function totalSupply() external view returns(uint);
    function Dev() external view returns(address);
    function Namehash2ID(bytes32 node) external view returns(uint);
    function ID2Namehash(uint256 id) external view returns(bytes32);
    function ownerOf(uint256 id) external view returns (address);

}

interface iToken{
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";
import "src/Util.sol";
import "src/Base.sol";

/**
 * @title BENSYC Resolver
 */

abstract contract Resolver is BENSYC {
    using Util for uint256;
    using Util for bytes;
    
    bytes public DefaultContenthash;

    constructor() {
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;
    }

    /**
     * @dev : sets default contenthash
     * @param _content : default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external onlyDev {
        DefaultContenthash = _content;
    }

    /**
     * @dev : verify ownership of subdomain
     * @param node : subdomain
     */
    modifier isOwner(bytes32 node) {
        require(msg.sender == ENS.owner(node), "Resolver: NOT_AUTHORISED");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;
    /**
     * @dev : return default contenhash if no contenthash set
     * @param node : subdomain
     */
    function contenthash(bytes32 node) public view returns(bytes memory _hash) {
        _hash = _contenthash[node];
        if (_hash.length == 0) {
            return DefaultContenthash;
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);
    /**
     * @dev : change contenthash of subdomain
     * @param node: subdomain
     * @param _hash: new contenthash
     */
    function setContenthash(bytes32 node, bytes memory _hash) external isOwner(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;
    event AddressChanged(bytes32 indexed node, address a);
    /**
     * @dev : change address of subdomain
     * @param node : subdomain
     * @param _addr : new address
     */
    function setAddress(bytes32 node, address _addr) external isOwner(node) {
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddressChanged(node, _addr);
    }

    event CoinAddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);
    /**
     * @dev : change address of subdomain for <coin>
     * @param node : subdomain
     * @param coinType : <coin>
     */
    function setCoinAddress(bytes32 node, uint256 coinType, bytes memory _addr) external isOwner(node) {
        _addrs[node][coinType] = _addr;
        emit CoinAddressChanged(node, coinType, _addr);
    }

    /**
     * @dev : resolve subdomain to owner if no address is set
     * @param node : sundomain
     * @return : resolved address 
     */
    function addr(bytes32 node) external view returns(address payable) {
        bytes memory _addr = _addrs[node][60];
        if (_addr.length == 0) {
            return payable(ENS.owner(node));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }
    mapping(bytes32 => PublicKey) public pubkey;
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    /**
     * @dev : change public key record
     * @param node : subdomain
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external isOwner(node) {
        pubkey[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    mapping(bytes32 => mapping(string => string)) public _text;
    event TextRecordChanged(bytes32 indexed node, string indexed key, string value);
    /**
     * @dev : change text record
     * @param node : subdomain
     * @param key : key to change
     * @param value : value to set
     */
    function setText(bytes32 node, string calldata key, string calldata value) external isOwner(node) {
        _text[node][key] = value;
        emit TextRecordChanged(node, key, value);
    }

    /**
     * @dev : get text records
     * @param node : subdomain
     * @param key : key to query
     * @return value : value
     */
    function text(bytes32 node, string calldata key) external view returns(string memory value) {
        value = _text[node][key];
        if (bytes(value).length == 0) {
            if (bytes32(bytes(key)) == bytes32(bytes("avatar"))) {
                return string.concat(
                    "eip155:", block.chainid.toString(),
                    "/erc721:", abi.encodePacked(DefaultResolver).toHexString(), 
                    "/", Namehash2ID[node].toString()
                );
            } else {
                return _text[bytes32(0)][key];
            }
        }
    }

    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev : change name record
     * @param node : subdomain
     * @param _name : new name
     */
    function setName(bytes32 node, string calldata _name) external isOwner(node) {
        _text[node]["name"] = _name;
        emit NameChanged(node, _name);
    }

    /**
     * @dev : get default name at mint
     * @param node : subdomain
     * @return _name : default name
     */
    function name(bytes32 node) external view returns(string memory _name) {
        _name = _text[node]["name"];
        if(bytes(_name).length == 0) {
            _name = string.concat(
                Namehash2ID[node].toString(),
                ".BENSYC.ETH"
            );
        }
    }
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

// Utility functions
library Util{
        
    /**
     * @dev Convert uint value to string number
     * @param value : uint value to be converted
     * @return : number as string
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev
     * @param buffer : bytes to be converted to hex
     * @return : hex string
     */
    function toHexString(bytes memory buffer)
        internal
        pure
        returns (string memory)
    {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint256 i; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / 16];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % 16];
        }
        return string(abi.encodePacked("0x", converted));
    }

}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";

/**
 * @title BENSYC Definitions
 */
 
abstract contract BENSYC {

    // TESTNET ONLY : REMOVE FROM MAINNET !!!
    function DESTROY() external payable onlyDev {
        selfdestruct(payable(msg.sender));
    }

    /// @dev : ENS Contract Interface
    iENS public ENS;

    /// @dev Pause/Resume contract 
    bool public active = true;

    /// @dev : Controller/Dev address 
    address public Dev;

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if(msg.sender != Dev)
            revert OnlyDev(Dev, msg.sender);
        _;
    }


    // ERC721 details
    string internal _name = "BoredENSYachtClub.eth";
    string public symbol = "BENSYC";

    /// @dev : Default resolver used by this contract: NEEDS TO BE SET FOR MAINNET !!!
    address public DefaultResolver;

    /// @dev : Current/Live supply of subdomains
    uint256 public totalSupply;

    /// @dev : $ETH per subdomain mint
    uint256 public mintPrice = 0.01 ether;

    /// @dev : Opensea Contract URI
    string public contractURI = "ipfs://QmVYtPt9LG2wjzAsosKt5c5182tmqwVfc3vNJ1thpNQJR9"; // opensea contract uri hash

    /// @dev : ERC2981 Royalty info; 5 = 5%
    uint256 public royalty = 5;
    
    /// @dev : IPFS hash of metadata directory
    string public metaIPFS = "Qmeeseyvfcx3Ur65y7awVRywwAvBRBDSdsX2GKgyUxgnJP";


    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) internal _ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(bytes4 => bool) public supportsInterface;
    mapping(uint256 => bytes32) public ID2Labelhash;
    mapping(bytes32 => uint) public Namehash2ID;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed _owner, address indexed approved, uint256 indexed id);
    event ApprovalForAll(address indexed _owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error Unauthorized(address operator, address owner, uint256 id);
    error NotSubdomainOwner(address owner, address from, uint256 id);
    error InsufficientEtherSent(uint256 size, uint256 yourSize);
    error ERC721IncompatibleReceiver(address addr);
    error OnlyDev(address _dev, address _you);
    error InvalidTokenID(uint256 id);
    error ContractPaused();
    error MintEnded();
    error ZeroAddress();
    error OversizedBatch();

    modifier isValidToken(uint id) {
        if (id >= totalSupply)
            revert InvalidTokenID(id);
        _;
    }
    
    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external payable onlyDev {
        require(
            payable(msg.sender).send(address(this).balance)
            , "ETH_TRANSFER_FAILED"
        );
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable onlyDev {
        require(
            iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)))
            , "TOKEN_TRANSFER_FAILED"
        );
    }
    
    // @dev : re-entrancy protectoooor
    fallback() external payable {
        revert();
    }
    receive() external payable {
        revert();
    }
}