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
// File: diamond/Sbt.sol


pragma solidity ^0.8.16;


contract Sbt{

    function init(address _contractOwner, string calldata _name, string calldata _symbol, string calldata _baseURI, bytes32 _validator) external {
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        require(sbtstruct.contractOwner == address(0),"INITED ALREADY");
        sbtstruct.contractOwner = _contractOwner;
        sbtstruct.name = _name;          
        sbtstruct.symbol = _symbol;
        sbtstruct.baseURI = _baseURI;
        sbtstruct.validator = _validator;
        sbtstruct.interfaces[(bytes4)(0x01ffc9a7)] = true; //ERC165
        sbtstruct.interfaces[(bytes4)(0x5b5e139f)] = true; //ERC721metadata
    }

    mapping(bytes4 => address) public implementations;

    function setImplementation(bytes4[] calldata _sigs, address[] calldata _impAddress) external {
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage(); 
        require(msg.sender == sbtstruct.contractOwner,"OWNER ONLY");
        require(_sigs.length == _impAddress.length,"INVAILED LENGTH");
        for(uint256 i = 0;i < _sigs.length;i++){
            unchecked{
                implementations[_sigs[i]] = _impAddress[i];
            }
        } 
    }

    function contractOwner() external view returns(address){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();        
        return sbtstruct.contractOwner;
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();        
        return sbtstruct.interfaces[_interfaceID];
    }

   function name() external view returns (string memory){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();        
        return sbtstruct.name;
    }

    //0x95d89b41
    function symbol() external view returns (string memory){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();        
        return sbtstruct.symbol;
    }



    //0xc87b56dd0000000000000000000000000000000000000000000000000000000000000001
    function tokenURI(uint256 _tokenId) external view returns(string memory){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        return string(abi.encodePacked(sbtstruct.baseURI,toString(_tokenId),".json"));
    }

    //0x6352211e0000000000000000000000000000000000000000000000000000000000000001
    function ownerOf(uint256 _tokenId) external view returns(address){
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();        
        return sbtstruct.owners[_tokenId];
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            unchecked{
                digits++;
                temp /= 10;
            }

        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked{
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }


    fallback() external payable {
        address _imp = implementations[msg.sig];
        require(_imp != address(0), "Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}    
}