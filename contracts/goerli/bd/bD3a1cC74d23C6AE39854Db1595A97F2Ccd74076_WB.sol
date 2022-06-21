/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// File: contracts/t.sol


pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

// import "./IWRLD_Name_Service_Bridge.sol";
// import "./StringUtils.sol";

contract WB {

  function testWRLDNameServiceRegistrarRegisterWithPass(uint tokenId, uint96 expiresAt, address _registerer, string calldata name) public pure returns(bytes memory){
        return abi.encode(tokenId, expiresAt, _registerer, address(0), name);
    }
  
  function testdecode(bytes calldata data) public pure returns(uint256 tokenId, uint96 expiresAt, address registerer, address address0, string memory name){
    (uint256 tokenId, uint96 expiresAt, address registerer, address address0, string memory name) = abi.decode(data, (uint256, uint96, address, address, string));
    return (tokenId, expiresAt, registerer, address0, name);
  }
  
}