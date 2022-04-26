/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: WTFPL v6.9
// 0xc0de4c0ffee
// https://github.com/namesys-eth

pragma solidity >0.8.0;

/**
 * The ENS registry contract interface
 */
interface iENS {
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
}


contract Namesys {

    address payable public BDFL;
    iENS public immutable ENS;
    
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);
    error InvalidTLD(string tld);
    error InvalidDomainLength(uint _length, bytes _name);
    error DomainNotActive(bytes32 _namehash);
    error RequestError(bytes32 expected, bytes32 result, bytes data, uint blknum);
    error InvalidNamehash(bytes32 _expected, bytes32 _provided);
    error NotAuthorised(string _domain, address _notOwner);

    bytes32 immutable public eth_hash = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    
    modifier onlyBDFL(){
        require(msg.sender == BDFL, "only Owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address payable _newOwner) external onlyBDFL{
        emit OwnershipTransferred(BDFL, _newOwner);
        BDFL = _newOwner;
    }

    constructor(){
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        supportsInterface[Namesys.resolve.selector] = true;
        sig2Word[0x3b3b57de] ="addr";
        BDFL = payable(msg.sender);
    }

    event ThankYou(address _donator, uint _value);
    modifier donation(){
        if(msg.value > 0) { // accept donation
            emit ThankYou(msg.sender, msg.value);
        }
        _;
    }
    enum GatewayType{
        URL,
        IPFS,
        IPNS
    }


    struct Record {
        bool _active;
        string _label;
        string _gateway;
        GatewayType _type;
        bool _catchall;
    }
    
    mapping(bytes32 => Record) public records; // records for domains
    mapping(bytes4 => string) public sig2Word; // sig to word
    mapping(bytes4 => bool) public supportsInterface;

    event DomainUpdate(bytes32 indexed _namehash, uint8 _type, bool _catchall, string _gateway);

    
    function dnsDecode(bytes calldata name) private pure returns(bytes32 _mainhash, bytes32 _subhash, string memory _label) {
        uint i;
        uint len;
        uint j;
        bytes[3] memory _labels;
        while(name[i] != 0x0){
            len = uint8(bytes1(name[i : ++i]));
            _labels[j] =  name[i : i += len];
            j++;
        }
        if(j == 3){
           //is sub.domain.eth
            _mainhash = keccak256(abi.encodePacked(bytes32(0), keccak256(_labels[2]))); // .eth
            _mainhash = keccak256(abi.encodePacked(_mainhash, keccak256(_labels[1]))); // domain.eth
            _subhash = keccak256(abi.encodePacked(_mainhash, keccak256(_labels[0]))); // sub.domain.eth
        } else if (j == 2){
            //is domain.eth
            _mainhash = keccak256(abi.encodePacked(bytes32(0), keccak256(_labels[1])));
            _mainhash = keccak256(abi.encodePacked(_mainhash, keccak256(_labels[0])));
            _subhash = _mainhash;
        } else {
            revert InvalidDomainLength(j, name);
        }
        _label = string(_labels[0]);
    }

    /**
     * Resolves a name, as specified by ENSIP 10.
     * @param name The DNS-encoded name to resolve.
     * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     * @return The return data, ABI encoded identically to the underlying function.
     */
    function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory) {
        (bytes32 _mainhash, bytes32 _subhash, string memory _label) = dnsDecode(name); // tld.eth's namehash
        if(_subhash != bytes32(data[4:36])){
            revert InvalidNamehash(_mainhash, bytes32(data[4:36]));
        }
        Record memory _rec = records[_mainhash];
        string memory _prefix;// = string.concat("https://", records[_mainhash]._gateway, "/.well-known/ens/");
        string memory _suffix = string.concat("/",sig2Word[bytes4(data[:4])], ".json?{data}");
        string[] memory urls;
        if(_rec._type == GatewayType(0)){
            _prefix = string.concat("https://", _rec._gateway, "/.well-known/ens/");
            if(_rec._catchall){
                urls = new string[](2);
                urls[0] = string.concat(_prefix, _label, _suffix); // if this fails
                urls[1] = string.concat(_prefix, "*/", _suffix); // retry for * catch all
            } else {
                urls = new string[](1);
                urls[0] = string.concat(_prefix, _suffix);
            }
        } else {
            _prefix = string.concat(_rec._type == GatewayType(1) ? "ipfs/" : "ipns/", _rec._gateway, "/.well-known/ens/");
            if(_rec._catchall){
                urls = new string[](4);
                urls[0] = string.concat("https://ipfs.io/", _prefix, _label, _suffix); // if this fails
                urls[1] = string.concat("https://dweb.link/", _prefix, _label, _suffix); // retry for * catch all
                urls[2] = string.concat("https://ipfs.io/", _prefix, "*", _suffix); // if this fails
                urls[3] = string.concat("https://dweb.link/", _prefix, "*", _suffix); // retry for * catch all
            } else {
                urls = new string[](2);
                urls[0] = string.concat("https://ipfs.io/", _prefix, _label, _suffix); // if this fails
                urls[1] = string.concat("https://dweb.link/", _prefix, _label, _suffix); // retry for * catch all
            }
        }
        revert OffchainLookup(
            address(this),
            urls,
            abi.encodePacked(bytes6(0xc0de4c0ffeee)),
            Namesys.resolveWithoutProof.selector,
            abi.encode(keccak256(abi.encodePacked(msg.sender, address(this), data, block.number)), block.number, data)
        );
    }

    /**
     * Callback used by CCIP read compatible clients to verify and parse the response.
     */
    function resolveWithoutProof(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (bytes32 hash, uint blknum, bytes memory data) = abi.decode(extraData, (bytes32, uint, bytes));
        bytes32 check = keccak256(abi.encodePacked(msg.sender, address(this), data, blknum));
        if(check != hash || block.number > blknum + 6){
            revert RequestError(hash, check, data, blknum);
        }
        return response;
    }


    function addSig2Word(bytes4 _sig, string calldata _word) external onlyBDFL {
        sig2Word[_sig] = _word;
    }

    function disable(bytes32 _namehash) external payable donation {
        Record storage _rec = records[_namehash];
        if(!_rec._active){
            revert DomainNotActive(_namehash);
        }
        if(msg.sender != ENS.owner(_namehash)){
            revert NotAuthorised(string.concat(_rec._label, ".eth"), msg.sender);
        }
        _rec._active = false;
    }

    function activate(string calldata _label, string calldata _gateway, uint8 _type, bool _catchall) external payable donation {
        bytes32 _namehash = keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("eth"))));
        _namehash = keccak256(abi.encodePacked(_namehash, keccak256(abi.encodePacked(_label))));

        if(msg.sender != ENS.owner(_namehash)){
            revert NotAuthorised(string.concat(_label, ".eth"), msg.sender);
        }
        records[_namehash] = Record(true, _label, _gateway, GatewayType(_type), _catchall);
        emit DomainUpdate(_namehash, _type, _catchall, _gateway);
    }

    function updateGateway(bytes32 _namehash, string calldata _gateway, uint8 _type, bool _catchall) external payable donation {
        Record storage _rec = records[_namehash];
        if(!_rec._active){
            revert DomainNotActive(_namehash);
        } 
        if(msg.sender != ENS.owner(_namehash)){
            revert NotAuthorised(string.concat(_rec._label, ".eth"), msg.sender);
        }
        _rec._gateway = _gateway;
        _rec._type = GatewayType(_type);
        _rec._catchall = _catchall;
    }

    function withdraw() external onlyBDFL{
        (BDFL).transfer(address(this).balance);
    }

    //testnet selfdestruct
    function destroy() external onlyBDFL{
        selfdestruct(BDFL);
    }
}