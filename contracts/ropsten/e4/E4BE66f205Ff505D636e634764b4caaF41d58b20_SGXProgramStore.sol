pragma solidity >=0.4.21 <0.6.0;
import "./interface/ProgramProxyInterface.sol";
import "./interface/OwnerProxyInterface.sol";

contract SGXProgramStore is ProgramProxyInterface{
    struct program_meta{
      string program_url;
      uint256 price;
      bytes32 enclave_hash;
      bool exists;
    }

    mapping(bytes32 => program_meta) public program_info;
    bytes32[] public program_hashes;
    OwnerProxyInterface public owner_proxy;

    constructor(address _owner_proxy) public{
      owner_proxy = OwnerProxyInterface(_owner_proxy);
    }

    event UploadProgram(bytes32 hash, address author);
    function upload_program(string memory _url, uint256 _price, bytes32 _enclave_hash) public returns(bytes32){
      bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _url, _price, _enclave_hash, block.number));
      require(!program_info[_hash].exists, "already exist");
      program_info[_hash].program_url = _url;
      program_info[_hash].price = _price;
      program_info[_hash].enclave_hash = _enclave_hash;
      program_info[_hash].exists = true;
      program_hashes.push(_hash);
      owner_proxy.initOwnerOf(_hash, msg.sender);
      emit UploadProgram(_hash, msg.sender);
      return _hash;
    }

    function program_price(bytes32 hash) public view returns(uint256){
      return program_info[hash].price;
    }

    function program_owner(bytes32 hash) public view returns(address){
      return owner_proxy.ownerOf(hash);
    }

    function get_program_info(bytes32 hash) public view returns(address author,
                                                                string memory program_url,
                                                                uint256 price,
                                                                bytes32 enclave_hash){
      require(program_info[hash].exists, "program not exist");
      program_meta storage m = program_info[hash];
      author = owner_proxy.ownerOf(hash);
      program_url = m.program_url;
      price = m.price;
      enclave_hash = m.enclave_hash;
    }
    function enclave_hash(bytes32 hash) public view returns(bytes32){
      return program_info[hash].enclave_hash;
    }

    function change_program_url(bytes32 hash, string memory _new_url) public returns(bool){
      require(program_info[hash].exists, "program not exist");
      require(owner_proxy.ownerOf(hash) == msg.sender, "only owner can change this");
      program_info[hash].program_url= _new_url;
      return true;
    }

    function change_program_price(bytes32 hash, uint256 _new_price) public returns(bool){
      require(program_info[hash].exists, "program not exist");
      require(owner_proxy.ownerOf(hash) == msg.sender, "only owner can change this");
      program_info[hash].price = _new_price;
      return true;
    }

    function is_program_hash_available(bytes32 hash) public view returns(bool){
      if(!program_info[hash].exists){return false;}
      return true;
    }
}
contract SGXProgramStoreFactory{
  event NewSGXProgramStore(address addr);
  function createSGXProgramStore(address _owner_proxy) public returns(address){
    SGXProgramStore m = new SGXProgramStore(_owner_proxy);
    //m.transferOwnership(msg.sender);
    emit NewSGXProgramStore(address(m));
    return address(m);
  }

}

pragma solidity >=0.4.21 <0.6.0;
contract ProgramProxyInterface{
  function is_program_hash_available(bytes32 hash) public view returns(bool);
  function program_price(bytes32 hash) public view returns(uint256);
  function program_owner(bytes32 hash) public view returns(address);
  function enclave_hash(bytes32 hash) public view returns(bytes32);
}

pragma solidity >=0.4.21 <0.6.0;
contract OwnerProxyInterface{
  function ownerOf(bytes32 hash) public view returns(address);
  function initOwnerOf(bytes32 hash, address owner) external returns(bool);
}