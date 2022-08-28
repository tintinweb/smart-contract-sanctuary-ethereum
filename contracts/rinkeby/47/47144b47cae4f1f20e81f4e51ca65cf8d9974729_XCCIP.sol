//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0;
import "src/Interface.sol";
import "src/Util.sol";

/**
 * @title BENSYC CCIP
 */

abstract contract Clone {

    iBENSYC public BENSYC;
    iENS public ENS;

    // @dev : re-entrancy protectoooor
    fallback() external payable {
        revert();
    }
    receive() external payable{
        revert();
    }
    
    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external {
        require(msg.sender == BENSYC.Dev());
        payable(msg.sender).transfer(address(this).balance);
    }
    
     /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param _token : token to release
     * @param _bal : amount to release
     */
    function withdrawToken(address _token, uint _bal) external {
        require(msg.sender == BENSYC.Dev());
        iToken(_token).transferFrom(address(this), msg.sender, _bal);
    }

    // TESTNET ONLY : REMOVE FROM MAINNET !!!
    function DESTROY() external {
        require(msg.sender == BENSYC.Dev());
        selfdestruct(payable(msg.sender));
    }
}

contract XCCIP is Clone {

    address public PrimaryResolver;
    bytes32 public immutable secondaryLabelHash = keccak256(bytes("bensyc"));
    bytes32 public immutable secondaryDomainHash;
    bytes32 public immutable baseHash;
    bytes32 public immutable primaryDomainHash;
    
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);
    error InvalidTokenID(string id, uint index);
    error InvalidParentDomain(string str);
    error InvalidNamehash(bytes32 expected, bytes32 provided);
    error RequestError(bytes32 expected, bytes32 check, bytes data, uint blknum, bytes result);
    error StaticCallFailed(address resolver, bytes _call, bytes _error);
    
    function supportsInterface(bytes4 sig) external pure returns(bool){
        return (sig == XCCIP.resolve.selector || sig == XCCIP.supportsInterface.selector);
    }
    
    constructor(address _bensyc) {
        baseHash = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        secondaryDomainHash = keccak256(abi.encodePacked(baseHash, secondaryLabelHash));
        primaryDomainHash = keccak256(abi.encodePacked(baseHash,  keccak256(bytes("boredensyachtclub"))));
        BENSYC = iBENSYC(_bensyc);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

     /**
     * @dev : dnsDecode()
     * @param name : name
     */
    function dnsDecode(bytes calldata name) public view returns(bytes32, bool) {
        uint i;
        uint j;
        bytes[] memory labels = new bytes[](4);
        uint len;
        while(name[i] != 0x0){
            unchecked {
                len = uint8(bytes1(name[i : ++i]));
                labels[j] =  name[i : i += len];
                ++j;
            }
        }
        
        i = 0;
        for(j = 0; j < labels[0].length;){
            if(labels[0][j] < 0x30 || labels[0][j] > 0x39){
                return(keccak256(labels[0]), false);
            }
            unchecked {
                i = (i * 10) + (uint8(labels[0][j]) - 48);
                ++j;
            }
        }
        if(i >= BENSYC.totalSupply()){
            revert InvalidTokenID(string(labels[0]), 10_000);
        }
        return(keccak256(labels[0]), true);
    }

    /**
     * @dev : resolve()
     * @param name : name
     * @param data : data
     */
    function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory) {
        bytes32 _callhash;
        bool isNFT;
        if(bytes32(data[4:36]) == secondaryDomainHash){
            _callhash = primaryDomainHash;
        } else {
            (_callhash, isNFT) = dnsDecode(name);
            _callhash = isNFT ? keccak256(abi.encodePacked(primaryDomainHash, _callhash)) 
                : keccak256(abi.encodePacked(baseHash, _callhash));
        }
        
        bytes memory _result = getResult(_callhash, data);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:text/plain,{"data":"{data}"}';
        _urls[1] = 'data:application/json,{"data":"{data}"}';
        revert OffchainLookup(
            address(this),
            _urls,
            _result, // {data} field
            XCCIP.resolveWithoutProof.selector,
            abi.encode(keccak256(abi.encodePacked(msg.sender, address(this), data, block.number, _result)), block.number, data)
        );
    }
    error ResolverNotSet(bytes32 node, bytes data);

    /**
     * @dev : getResult()
     * @param _callhash : _callhash
     * @param data : data
     */
    function getResult(bytes32 _callhash, bytes calldata data) public view returns(bytes memory){
        bytes memory _call =  (data.length > 36) ? abi.encodePacked(data[:4], _callhash, data[36:])
            : abi.encodePacked(data[:4], _callhash);

        address _resolver = ENS.resolver(_callhash);
        if(_resolver == address(0)) {
            revert ResolverNotSet(_callhash, _call);
        }
        (bool _success, bytes memory _result) = _resolver.staticcall(_call);  
        if (!_success || _result.length == 0){
            revert StaticCallFailed(_resolver, _call, _result);
        }
        return _result;
    }

    /**
     * Callback used by CCIP read compatible clients to verify and parse the response.
     */
    function resolveWithoutProof(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (bytes32 hash, uint blknum, bytes memory data) = abi.decode(extraData, (bytes32, uint, bytes));
        bytes32 check = keccak256(abi.encodePacked(msg.sender, address(this), data, blknum, response));
        if(check != hash || block.number > blknum + 5){ // extra check
            revert RequestError(hash, check, data, blknum, response);
        }
        return response;
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