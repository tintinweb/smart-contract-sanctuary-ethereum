/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.8.0;

interface IWaifus {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 id) external view returns (address);
    function tokenNameByIndex(uint256 id) external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract Accoomulator {
  IWaifus WAIFUS = IWaifus(0x2216d47494E516d8206B70FCa8585820eD3C4946);
    
    struct WaifuInfo {
        uint256 tokenId;
        address owner;
        string name;
    }
  
  function accoomulatedTokenIdsOwned(uint256[] calldata tokenIds) external view returns (WaifuInfo[] memory) {
    uint256 _length = tokenIds.length;
    WaifuInfo[] memory tokenInfos = new WaifuInfo[](_length);
    for (uint256 i = 0; i < _length; i++) {
      uint256 id = tokenIds[i];
      address _owner = WAIFUS.ownerOf(id);
      string memory name = WAIFUS.tokenNameByIndex(id);
      tokenInfos[i] = WaifuInfo(id, _owner, name);
    }
    return tokenInfos;
  }
}