/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// File: diamond/SbtLib.sol


pragma solidity ^0.8.16;

library  SbtLib {
    bytes32 constant SBT_STRUCT_POSITION = keccak256("xyz.ukishima.sbt.struct");

    struct SbtStruct {
        address contractOwner;
        string name;
        string symbol;
        string baseURI;
        bytes32 validator;
        mapping(bytes4 => bool) interfaces;
        mapping(address => uint256) balances;
        mapping(uint256 => address) owners;
        mapping(uint256 => SbbStruct[]) sbbs;
        mapping(bytes32 => uint256) sbbIndex;
    }

    struct SbbStruct {
        uint256 chainId;
        address contractAddress;
        uint256 tokenId;
    }

  function sbtStorage()
    internal 
    pure 
    returns (SbtStruct storage sbtstruct) 
  {
    bytes32 position = SBT_STRUCT_POSITION;
    assembly {
      sbtstruct.slot := position
    }
  }


}
// File: diamond/impSbt.sol


pragma solidity ^0.8.16;


contract impSbt {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event ContractOwnerChanged(address _newOwner);
    event ValidatorChanged(bytes32 _newValidator);


    //0x731133e9000000000000000000000000535b72f4c4370f416348eb5a9525a408ac8d8acb00000000000000000000000000000000000000000000000006c7a8a61bc20000000000000000000000000000000000000000000000000000000001824dd01a2900000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000041fc94a054160f2a0882c38a232607ba892de1b54f37eef174b6b86d0728480d56487bb125399f5f1da0f5064a3699e1aed89be2a57a0e858681c5ad321cbf87df1b00000000000000000000000000000000000000000000000000000000000000
    function mint(address _address, uint256 _tokenId, uint256 _salt, bytes calldata _signature) external {
        bytes32 _messagehash = keccak256(abi.encode(msg.sender,_address, _tokenId, _salt));
        require(verify(_messagehash,_signature),"INVAILED");
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        sbtstruct.owners[_tokenId] = _address;
        emit Transfer(address(0), _address, _tokenId);
    }

    //0xc7be22f60000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000041fc94a054160f2a0882c38a232607ba892de1b54f37eef174b6b86d0728480d56487bb125399f5f1da0f5064a3699e1aed89be2a57a0e858681c5ad321cbf87df1b00000000000000000000000000000000000000000000000000000000000000
    function setContractOwner(address _newContactOwner, uint256 _salt, bytes memory _signature) external {
        bytes32 _messagehash = keccak256(abi.encode(msg.sender, _newContactOwner, _salt));
        require(verify(_messagehash,_signature),"INVAILED");
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        sbtstruct.contractOwner = _newContactOwner;
        emit ContractOwnerChanged(_newContactOwner);
    }

    //0x34a53c01ddc8e02dcd816f76b8a3f185785cd995996e1d01d976b1d4c05a9bc7718a3b1d
    function setValidator(bytes32 _newValidator) external {
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        require(msg.sender == sbtstruct.contractOwner,"OWNER ONLY");
        sbtstruct.validator = _newValidator;
        emit ValidatorChanged(_newValidator);
    }

    //0x1195e07e
    function getValidator() external view returns (bytes32){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        return sbtstruct.validator;
    }

    //0x258ae582d3ffebb030cd02b9cf8022577e0e9fd4fb3eebcd9ac2e1643518d126a3c6928300000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041871466a95ccb2349c6fd73e6b1ac05c65d175b31e2408ce6fe9ea1a15c53e7e0311905a1f3c6e82b0a45187bbe926aa634e4c837161a7d316866f67f09823b2e1b00000000000000000000000000000000000000000000000000000000000000
    function verify(bytes32 _hash,bytes memory _signature) public view returns (bool) {
        require(_signature.length == 65,"INVAILED");
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        bytes32 _r;
        bytes32 _s;
        uint8 _v;
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := byte(0, mload(add(_signature, 96)))
        }
        return keccak256(abi.encodePacked(ecrecover(_hash, _v, _r, _s))) == sbtstruct.validator;
    }
}