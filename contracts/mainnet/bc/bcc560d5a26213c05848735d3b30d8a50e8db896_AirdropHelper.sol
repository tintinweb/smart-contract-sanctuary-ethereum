/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface ILightERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function ownerOf(uint256 _tokenId) external view returns (address);
}

contract AirdropHelper {
  ILightERC721 public llamascape = ILightERC721(0xE5C7D9A18df4fDc12DB723761A862845612917bA);
  address public llama = 0xe8d939F1a9CC4e85E09AFf3d60d137a1Bea17b21;
  address public admin = 0x000000003604223ecc88b0205fc02efBe35F437f;

  mapping(address => uint[]) public wl;

  function addToWhitelist(address _addr,  uint _tokenId) internal {
    wl[_addr].push(_tokenId);
  }

  modifier onlyLlama {
    require(msg.sender == llama || msg.sender == admin);
    _;
  }

  function resetWhitelistForUser(address _addr) public onlyLlama {
    wl[_addr] = new uint[](0);
  }

  function uploadWhitelist(address[] calldata addresses, uint[] calldata tokenIds) public onlyLlama {
    for (uint i = 0; i < addresses.length; i++) {
      addToWhitelist(addresses[i], tokenIds[i]);
    }
  }

  function mint() public {
    uint[] storage ids = wl[msg.sender];
    for (uint i = 0; i < ids.length; i++) {
      llamascape.transferFrom(llama, msg.sender, ids[i]);
    }
  }

  function isWhitelisted(address user) public view returns (bool){
    // If llama doesn't own the token anymore, it has already been transferred
    return wl[user].length > 0 && llamascape.ownerOf(wl[user][0]) == llama;
  }
}