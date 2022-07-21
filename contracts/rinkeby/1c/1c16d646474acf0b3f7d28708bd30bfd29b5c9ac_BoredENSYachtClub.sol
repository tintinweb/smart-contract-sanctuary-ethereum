//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >= 0.8 .15;

import "src/Interface.sol";
import "src/Metadata.sol";
import "src/Resolver.sol";

/**
 * @summary: 
 * @author: 
 */


/**
 * @title contract 
 */
abstract contract BENSYC {

    iENS public ENS;
    address public Dev; //multisig

    bool public active = true;

    // NFT Details
    string public name = "BoredENSYachtClub.eth";
    string public symbol = "BENSYC";

    /// @dev : namehash of BoredENSYachtclub.eth
    bytes32 public DomainHash;

    /// @dev : Default resolver used by this contract
    address public DefaultResolver;

    /// @dev : Curent Total Supply of NFT
    uint public totalSupply;

    // @dev : Maximum supply of NFT
    uint public immutable maxSupply = 100;

    /// @dev : ERC20 Token used to buy NFT
    // iERC20 public ERC20;

    /// @dev : ERC20 token price to buy 1 NFT
    uint public mintingPrice;

    Metadata public metadata; // metadata generator contract

    /// @dev : Opensea Contract URI 
    string public contractURI; // opensea contract uri hash

    /// @dev : ERC2981 Royalty info, 100 = 1%
    uint public royalty = 100;

    mapping(address => uint) public balanceOf;
    mapping(uint => address) public _ownerOf;
    mapping(uint => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(bytes4 => bool) public supportsInterface;

    mapping(uint => bytes32) public ID2Namehash;
    mapping(uint => bytes32) public ID2Labelhash;

    //mapping(bytes32 => uint) public Hash2ID;

    event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    error InvalidTokenID(uint id);
    error ERC721IncompatibleReceiver(address addr);
    error NotAuthorized(address operator, address owner, uint id);
    error NotOwner(address owner, address from, uint id);
    error ContractPaused();
    error MintingCompleted();
    error NotEnoughPaid(uint value);
    error TransferToSelf();
    error NotSubdomainOwner();
}

/**
 * @title contract 
 */
contract BoredENSYachtClub is BENSYC {


    /**
     * @dev
     * @param _metadata :
     * @param _resolver :
     */
    constructor(address _metadata, address _resolver) {

        Dev = msg.sender;
        metadata = Metadata(_metadata);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        DefaultResolver = _resolver;

        //ERC20 = iERC20(_token); // token used for NFT minting
        mintingPrice = 0.01 ether; // tokens per NFT minting

        bytes32 _hash = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        DomainHash = keccak256(abi.encodePacked(_hash, keccak256(abi.encodePacked("boredensyachtclub"))));

        //metadata = "ipfs://<hash of .json dir>"; // ipfs://<hash>
        //contractURI = "";


        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

        // EIP165
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
        supportsInterface[type(iERC2981).interfaceId] = true;
    }

    /**
     * @dev
     * @param _tokenId :
     * @return :
     */
    function ownerOf(uint _tokenId) public view returns(address) {
        if(_tokenId >= totalSupply) {
            revert InvalidTokenID(_tokenId);
        }
        address _owner = ENS.owner(ID2Namehash[_tokenId]);
        if(_owner == _ownerOf[_tokenId]) {
            return _owner;
        }
        return address(this);
    }

    /**
     * @dev
     */
    function mint() external payable {
        if(!active) {
            revert ContractPaused();
        }
        if(totalSupply > maxSupply) {
            revert MintingCompleted();
        }
        if(msg.value < mintingPrice) {
            revert NotEnoughPaid(msg.value);
        }

        //transfer erc20 token 
        //require(ERC20.transferFrom(msg.sender, address(Dev), mintingPrice), "ERC20:TOKEN_TRANSFER_FAILED");

        uint _id = totalSupply;
        bytes32 _labelhash = keccak256(abi.encodePacked(toString(_id)));
        ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, address(DefaultResolver), 0);
        bytes32 _namehash = keccak256(abi.encodePacked(DomainHash, _labelhash));
        ID2Namehash[_id] = _namehash;
        ID2Labelhash[_id] = _labelhash;
        //Hash2ID[_labelhash] = _id;
        //Hash2ID[_namehash] = _id;
        unchecked {
            ++totalSupply;
            ++balanceOf[msg.sender];
        }
        _ownerOf[_id] = msg.sender;
        //emit Transfer(address(0), address(this), _id);
        emit Transfer(address(this), msg.sender, _id);
    }


    /**
     * @dev
     */
    function batchMint(uint num) external payable {
        if(!active) {
            revert ContractPaused();
        }
        if(totalSupply + num > maxSupply) {
            revert MintingCompleted();
        }
        if(msg.value < mintingPrice * num) {
            revert NotEnoughPaid(msg.value);
        }
        uint _id = totalSupply;
        uint _mint = _id + num;
        for(; _id < _mint; _id++){
            bytes32 _labelhash = keccak256(abi.encodePacked(toString(_id)));
            ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, address(DefaultResolver), 0);
            ID2Namehash[_id] = keccak256(abi.encodePacked(DomainHash, _labelhash));
            ID2Labelhash[_id] = _labelhash;
            _ownerOf[_id] = msg.sender;
            emit Transfer(address(this), msg.sender, _id);
        }
        unchecked {
            totalSupply = _mint;
            balanceOf[msg.sender] += num;
        }
    }

    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function _transfer(address _from, address _to, uint _tokenId, bytes memory _data) private {
        if(!active) {
            revert ContractPaused();
        }
        //require(_to != address(0), "ERC721:ZERO_ADDRESS");
        if(_ownerOf[_tokenId] != _from){
            revert NotOwner(_ownerOf[_tokenId], _from, _tokenId);
        }
        //require(ENS.owner(ID2Namehash[_tokenId]) == _from, "ERC721:ENS_OWNER_MISMATCH");
        if(msg.sender != _ownerOf[_tokenId] &&
            !isApprovedForAll[_from][msg.sender] &&
            msg.sender != getApproved[_tokenId]) {
            revert NotAuthorized(msg.sender, _from, _tokenId);
        }
        // hard reset sub.domain ownership, users should change DefaultResolver/records
        ENS.setSubnodeOwner(DomainHash, ID2Labelhash[_tokenId], _to);
        unchecked {
            --balanceOf[_from]; // subtract from owner
            ++balanceOf[_to]; // add to receiver
        }
        _ownerOf[_tokenId] = _to; // change ownership
        delete getApproved[_tokenId]; // reset approved
        if(_to.code.length > 0){
            try iERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector){
                    revert ERC721IncompatibleReceiver(_to);
                }
            } catch (bytes memory) {
                revert ERC721IncompatibleReceiver(_to);
            }
        }
        emit Transfer(_from, _to, _tokenId);
    }
    //error ERC721ReceiverRejected(address to);
    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function transferFrom(address _from, address _to, uint _tokenId) external payable {
        _transfer(_from, _to, _tokenId, "");
    }

    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory _data) external payable {
        _transfer(_from, _to, _tokenId, _data);
    }

    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable {
        _transfer(_from, _to, _tokenId, "");
    }

    /**
     * @dev
     * @param _manager :
     * @param _tokenId :
     */
    function approve(address _manager, uint _tokenId) external payable {
        require(msg.sender == ownerOf(_tokenId), "ERC721:NOT_OWNER");
        getApproved[_tokenId] = _manager;
        emit Approval(msg.sender, _manager, _tokenId);
    }

    /**
     * @dev
     * @param _operator :
     * @param _approved :
     */
    function setApprovalForAll(address _operator, bool _approved) external payable {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev
     * @param _tokenId :
     * @return :
     */
    function tokenURI(uint _tokenId) external view returns(string memory) {
        if(_tokenId >= totalSupply) {
            revert InvalidTokenID(_tokenId);
        }
        return metadata.generate(_tokenId);
    }

    /**
     * @dev
     * @param _tokenId :
     * @param _salePrice :
     * @return :
     */
    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns(address, uint) {
        _tokenId; // silence warning
        return (address(this), (_salePrice / royalty));
    }

    // extra function, if ownership of sub.domain was changed on ENS contract
    // new sub.domain owner can reclaim wrapped NFT
    /**
     * @dev
     * @param _tokenId :
     */
    function reclaim(uint _tokenId) external {
        if(_tokenId >= totalSupply) {
            revert InvalidTokenID(_tokenId);
        }
        address _to = msg.sender;
        if(ENS.owner(ID2Namehash[_tokenId]) != _to) {
            revert NotSubdomainOwner();
        }

        address _from = _ownerOf[_tokenId];
        if(_from == _to) {
            revert TransferToSelf();
        }
        unchecked {
            --balanceOf[_from];
            ++balanceOf[_to];
        }
        delete getApproved[_tokenId]; // reset approved
        _ownerOf[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        if(_to.code.length > 0 &&
            iERC721Receiver(_to).onERC721Received(_to, _from, _tokenId, "") !=
            iERC721Receiver.onERC721Received.selector) {
            revert ERC721IncompatibleReceiver(_to);
        }
    }

    // Contract Management
    modifier onlyDev {
        require(msg.sender == Dev);
        _;
    }

    /**
     * @dev
     * @param newDev :
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev 
     * @return : address of controlling dev/multisig wallet
     */
    function owner() external view returns(address) {
        return Dev;
    }

    /**
     * @dev Toggle if contract is active or paused, only Dev can toggle
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev
     * @param _resolver :
     */
    function setResolver(address _resolver) external onlyDev {
        DefaultResolver = _resolver;
    }
    
    /**
     * @dev
     * @param _metadata :
     */
    function setMetadata(address _metadata) external onlyDev {
        metadata = Metadata(_metadata);
    }

    // used my opensea
    /**
     * @dev
     * @param _contractURI :
     */
    function setContractURI(string calldata _contractURI) external onlyDev {
        contractURI = _contractURI;
    }

    // EIP2981 royalty standard, percent * 100 units
    /**
     * @dev
     * @param _royalty :
     */
    function setRoyalty(uint _royalty) external onlyDev {
        royalty = _royalty;
    }

    /**
     * @dev
     */
    function withdraw() external payable onlyDev {
        require(payable(msg.sender).send(address(this).balance), "ETH_TRANSFER_FAILED");
    }

    // in case erc20 token is locked/royalty
    /**
     * @dev used in case some tokens are locked in this contract
     * @param _token : 
     * @param _value :
     */
    function approveToken(address _token, uint _value) external payable onlyDev {
        iERC721(_token).approve(msg.sender, _value);
    }

    /**
     * @dev
     * @param _sig :
     * @param _ok:
     */
    function setInterface(bytes4 _sig, bool _ok) external payable onlyDev {
        require(_sig != 0xffffffff);
        supportsInterface[_sig] = _ok;
    }

    // utility functions
    /**
     * @dev Convert uint value to string number
     * @param value : uint value to be converted
     * @return : number as string
     */
    function toString(uint value) internal pure returns(string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if(value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev
     * @param buffer : bytes to be converted to hex
     * @return : hex string 
     */
    function toHexString(bytes memory buffer) internal pure returns(string memory) {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint i; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / 16];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % 16];
        }
        return string(abi.encodePacked("0x", converted));
    }

    function DESTROY() public {
        require (msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;


interface iOverloadResolver{
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
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
interface iERC20{
        
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
}

interface iENS {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
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
    function royaltyInfo(uint _tokenId,uint _salePrice) external view returns (address receiver,uint royaltyAmount);
}

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


interface iERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() view external returns(address);
    function transferOwnership(address _newOwner) external;	
}

interface iERC721 {
    event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint);
    function ownerOf(uint _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable;
    function transferFrom(address _from, address _to, uint _tokenId) external payable;
    function approve(address _approved, uint _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface iERC721Receiver {
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes memory _data) external returns(bytes4);
}

interface iERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint _tokenId) external view returns (string memory);
}

pragma solidity >= 0.8 .0;

contract Metadata {
    address public Dev;
    string a = '<svg xmlns="http://www.w3.org/2000/svg" width="830" height="830" style="-webkit-user-select: none;-moz-user-select: none;-ms-user-select: none;user-select: none;"><defs><radialGradient id="rgrad" cx="50%" cy="50%" r="40%">';
    string b = '</radialGradient></defs><rect x="0" y="0" width="100%" height="100%" fill="url(#rgrad)"/><g dx="20" dy="0" transform="scale(23)" style="opacity:0.9"><g><animate attributeName="fill" values="';
    string c = '" dur="42s" repeatCount="indefinite"/><path d="M5 16c0-4-5-3-4 1s3 5 3 5l1-6zm26 0c0-4 5-3 4 1s-3 5-3 5l-1-6z"/><path d="M32.65 21.736c0 10.892-4.691 14.087-14.65 14.087S3.349 32.628 3.349 21.736 8.042.323 18 .323s14.65 10.521 14.65 21.413z"/></g> <path fill="#66757f" d="M27.567 23c1.49-4.458 2.088-7.312-.443-7.312H8.876c-2.532 0-1.933 2.854-.444 7.312C3.504 34.201 17.166 34.823 18 34.823S32.303 33.764 27.567 23z"/><g><animate attributeName="fill" values="';
    string d = '" dur="21s" repeatCount="indefinite"/><path d="M15 18.003a2 2 0 1 1-4 0c0-1.104.896-1 2-1s2-.105 2 1zm10 0a2 2 0 1 1-4 0c0-1.104.896-1 2-1s2-.105 2 1z"/></g><g><ellipse cx="15.572" cy="23.655" rx="1.428" ry="1"/><path d="M21.856 23.655c0 .553-.639 1-1.428 1s-1.429-.447-1.429-1 .639-1 1.429-1 1.428.448 1.428 1z"/></g><path fill="#99aab5" d="M21.02 21.04c-1.965-.26-3.02.834-3.02.834s-1.055-1.094-3.021-.834c-3.156.417-3.285 3.287-1.939 3.105.766-.104.135-.938 1.713-1.556s3.247.66 3.247.66 1.667-1.276 3.246-.659.947 1.452 1.714 1.556c1.346.181 1.218-2.689-1.94-3.106z"/><path fill="#31373d" d="M24.835 30.021c-1.209.323-3.204.596-6.835.596s-5.625-.272-6.835-.596c-3.205-.854-1.923-1.735 0-1.477s3.631.415 6.835.415 4.914-.156 6.835-.415 3.204.623 0 1.477z"/><path fill="#66757f"    d="M4.253 16.625c1.403-1.225-1.078-3.766-2.196-2.544-.341.373.921-.188 1.336 1.086.308.942.001 2.208.86 1.458zm27.493 0c-1.402-1.225 1.078-3.766 2.196-2.544.341.373-.921-.188-1.337 1.086-.306.942 0 2.208-.859 1.458z"/></g><rect y="750" width="100%" height="80" fill="#ffffff55"/><text x="25" y="810" style="font-size:4em;" font-family="monospace" textLength="775" lengthAdjust="spacingAndGlyphs">';
    string[] radMap = ["0", "10", "20", "30", "40", "50", "60", "70", "80", "90", "100"];

    function toHexColor(bytes memory _input) internal pure returns(string[] memory _output, string memory _list) {
        uint fill = ((_input.length * 2) / 6) + 1;
        _output = new string[](fill);
        bytes memory _base = "0123456789abcdef";
        uint j;
        uint k;
        uint _len = (_input.length / 6) * 6;
        bytes memory _hex = new bytes(6);
        for (uint i; i < _len; i++) {
            _hex[k * 2] = _base[uint8(_input[i]) / 16];
            _hex[k * 2 + 1] = _base[uint8(_input[i]) % 16];
            k++;
            if (k == 3) {
                _output[j] = string.concat(string(_hex));
                _list = string.concat(_list, "#", string(_hex), ";");
                j++;
                k = 0;
                _hex = new bytes(6);
            }
        }
        _list = string.concat(_list, "#",_output[0], ";");
        _output[fill - 1] = _output[0];
    }

    function image(uint id) internal view returns(string memory) {
        (string[] memory _arr, string memory _list) = toHexColor(abi.encodePacked(keccak256(abi.encodePacked(id))));
        string memory _stop;
        for (uint i = 0; i < 10; i++) {
            _stop = string.concat(_stop, '<stop offset="', radMap[i], '%" style="stop-color:#', _arr[i], ';"/>');
        }
        // <stop offset="100%"><animate attributeName="stop-color" values="#4b216c;#96deb6;#6b955e;#456077;#fb64cc;#fa152d;#595716;#17979d;#84472c;#863d0c;4b216c" dur="100s" repeatCount="indefinite"></animate></stop>
        _stop = string.concat(_stop, '<stop offset="100%"><animate attributeName="stop-color" values="', _list, '" dur="111s" repeatCount="indefinite"></animate></stop>');
        return string.concat("data:image/svg+xml;base64,", encode64(bytes(string.concat(a, _stop, b, _list, c, _list, d, toString(id), ".BoredENSYachtClub.eth</text></svg>"))));
    }

    function generate(uint id) public view returns(string memory) {
        string memory _name = string.concat(toString(id), ".BoredENSYachtClub.eth");
        return string.concat(
            'data:text/plain,{"name":"', _name, '",', 
            '"description":"1 of 10K Bored ENS Yacht Club Membership Card.",',
            '"external_url": "https://', _name, '.limo",',
            '"image":"', image(id), '",',
            attrib(id),      
            '}');
    }
    string[] NumList = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"];
    function attrib(uint id) internal view returns(string memory){
        string memory _pat;
        for(uint i = 10; i > 0; i--){
            if(id % i == 0){
                _pat = string.concat('"', NumList[i], '": true');
                break;
            }
        }
        return string.concat(
            (id <= 250) ? '"Alpha": true,' : (id >=9750) ? '"Omega" : true,' : "", 
            _pat
        );
    }

    function toString(uint value) internal pure returns(string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license 
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Base64 
    // @author Brecht Devos - <[email protected]>
    // @notice Provides functions for encoding/decoding base64
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode64(bytes memory data) internal pure returns(string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE_ENCODE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {}
            lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function DESTROY() public {
        require (msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }
    // add approve and fallback/receiver
}

//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;
import "src/Interface.sol";

/**
 * @title contract 
 */
contract Resolver {
    address Dev;
    iENS public ENS;
    mapping(bytes4 => bool) public supportsInterface;
    bytes public DefaultContenthash;
    constructor(){

        Dev = msg.sender;
        
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        // resolver
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;
        // CCIP
        // supportsInterface[iCCIP.resolve.selector] = true;
    }

    error OnlyDev();
    /**
    * @dev : 
    * @param _content : Default contenthash to set
    */
    function setDefaultContenthash(bytes memory _content) external {
        if(msg.sender != Dev){
            revert OnlyDev();
        }
        DefaultContenthash = _content;
    }

    modifier isAuthorised(bytes32 node) {
        address _owner = ENS.owner(node);
        require(msg.sender == _owner, "Resolver:Not_Authorised");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;
    function contenthash(bytes32 node) public view returns(bytes memory _hash){
        _hash = _contenthash[node];
        if(_hash.length == 0){
            return DefaultContenthash;
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);

    /**
     * @dev
     * @param node:
     * @param _hash:
     */
    function setContenthash(
        bytes32 node,
        bytes memory _hash
    ) external isAuthorised(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint => bytes)) internal _addrs;
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * @dev
     * @param node :
     * @param _addr :
     */
    function setAddr(bytes32 node, address _addr) external isAuthorised(node) {
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddrChanged(node, _addr);
    }

    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    /**
     * @dev
     * @param node :
     * @param coinType :
     */
    function setAddr(bytes32 node, uint coinType, bytes memory _addr) virtual public isAuthorised(node) {
        if (coinType == 60) {
            emit AddrChanged(node, address(uint160(uint256(bytes32(_addr)))));
        } else {
            emit AddressChanged(node, coinType, _addr);
        }
        _addrs[node][coinType] = _addr;
    }

    /**
     * @dev
     * @param node :
     * @return :
     */
    function addr(bytes32 node) external view returns(address payable) {
        bytes memory _addr = _addrs[node][60];
        if (_addr.length == 0) {
            return payable(ENS.owner(node));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev
     * @param node :
     * @param coinType :
     * @return :
     */
    function addr(bytes32 node, uint coinType) external view returns(bytes memory) {
        bytes memory _addr = _addrs[node][coinType];
        if (_addr.length == 0 && coinType == 60) {
            return abi.encodePacked(ENS.owner(node));
        }
        return _addr;
    }

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }
    mapping(bytes32 => PublicKey) public pubkey;
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    /**
     * @dev
     * @param node :
     * @param x :
     * @param y :
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external isAuthorised(node) {
        pubkey[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    mapping(bytes32 => mapping(string => string)) public text;
    event TextChanged(bytes32 indexed node, string indexed key, string value);
    /**
     * @dev
     * @param node :
     * @param key :
     * @param value :
     */
    function setText(bytes32 node, string calldata key, string calldata value) virtual external isAuthorised(node) {
        text[node][key] = value;
        emit TextChanged(node, key, value);
    }
    
    mapping(bytes32 => string) public name;
    event NameChanged(bytes32 indexed node, string name);
    /**
    * @dev
    * @param node :
    * @param _name :
    */
    function setName(bytes32 node, string calldata _name) external isAuthorised(node) {
            name[node] = _name;
            emit NameChanged(node, _name);
    }
    
    /// 
    error NotAllowed();
    fallback() external payable{
        revert NotAllowed();
    }

    receive() external payable{
        revert NotAllowed();
    }
    function DESTROY() public {
        require(msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }    
}