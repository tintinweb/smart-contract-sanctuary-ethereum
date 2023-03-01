// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Called by the ProxyBot contract to determine if a given wallet holds a special
// edition-granting NFT. Intended to be expanded and deployed repeatedly as new
// editions are released.
contract ProxyBotSpecialEditionInspector {

  // Contract addresses to edition names, where specific token IDs don't matter. (e.g. 721s)
  mapping(address => string) public e721Names;
   
  // Contract addresses to edition names, where specific token IDs do matter. (e.g. 1155s)
  mapping(uint256 => mapping(uint256 => string)) public e1155Names;
  
  // Our 1155 naming scheme requires a lot of duplicative uses of the same contract address, so we use a mapping of mappings to keep the contract slim.
  mapping(address => uint256) public e1155Contracts;

  constructor() {

    // DEF
    e721Names[0x3193046D450Dade9ca17F88db4A72230140E64dC] = "def";

    // 1155 address mapping scheme:
    e1155Contracts[0x11f12D907df7841558119cc28C05d9f402a1e562] = 1; // Turf Carts
    e1155Contracts[0x495f947276749Ce646f68AC8c248420045cb7b5e] = 2; // OpenSea

    // These are 1155s, so we need to check specific token IDs.
    e1155Names[1][1] = 'proxyBot_g';
    e1155Names[1][2] = 'proxyBot_l';
    e1155Names[1][3] = 'proxyBot_w';
    e1155Names[1][4] = 'proxyBot_s';
    e1155Names[1][5] = 'proxyBot_go';
    e1155Names[1][6] = 'proxyBot_r';
    e1155Names[1][7] = 'proxyBot_c';
    e1155Names[1][8] = 'sheebQuest';
    e1155Names[1][9] = 'turf';
    e1155Names[1][10] = 'toads';
    e1155Names[1][11] = 'prsh';
    e1155Names[1][12] = 'guardian';
    e1155Names[1][13] = 'fite';
    e1155Names[1][14] = 'iceWiz';
    e1155Names[1][15] = 'starX';
    e1155Names[1][16] = 'fps';
    e1155Names[1][17] = 'rnbwKtty';
    e1155Names[1][18] = 'tomo';
    e1155Names[1][19] = 'brokemon';
    e1155Names[1][20] = 'gawds';
    e1155Names[1][21] = 'kruton';

    // Turf Founders Pass, on OpenSea
    e1155Names[2][61698571352970599780028340077565043568807973171180656351546342299815261503688] = 'beta';
  }

  // Confirms if a given wallet holds an NFT that grants them a special edition Proxy Bot.
  // Returns a tuple containing a boolean and a string. The boolean indicating if they do, and the string is the name of that special edition. We'll use that for metadata purposes.
  // Also pass in the contract in question, and whether or not we're checking a specific token ID.
  // Most likely the contract will be a 721, but we'll check for 1155s too, probably (universally?) for those that have a specific token ID to check.
  function validateSpecialEdition(address _ownerAddress, address _contractToCheck, bool checkSpecificTokenId, uint256 tokenId) external view returns (bool, string memory) {
    if(checkSpecificTokenId){
      // So far this is just about 1155s. Not likely you'd have a special edition about a single unique ERC721 token ID.
      if(ERC1155BalanceOf(_ownerAddress, _contractToCheck, tokenId)){
        
        uint256 addressId = e1155Contracts[_contractToCheck];
        return (true, e1155Names[addressId][tokenId]);
      } else {
        return (false, "");
      }

    } else { // Check these basic "do you have at least 1" contracts, where we don't check specific tokens. 721s in other words.
      if(ERC721BalanceOf(_ownerAddress, _contractToCheck)){
        return (true, e721Names[_contractToCheck]);
      } else {
        return (false, "");
      }
    }
  }

  function ERC1155BalanceOf(address _ownerAddress, address _contractToCheck, uint256 _tokenId) private view returns (bool){
    bytes memory data = abi.encodeWithSignature("balanceOf(address,uint256)", _ownerAddress, _tokenId);
    (bool success, bytes memory returnData) = _contractToCheck.staticcall(data);
    uint256 count = abi.decode(returnData, (uint256));
    if(success){
      return count > 0;
    } else {
      return false;
    }
  }

  function ERC721BalanceOf(address _ownerAddress, address _contractToCheck) private view returns (bool){
    bytes memory data = abi.encodeWithSignature("balanceOf(address)", _ownerAddress);
    (bool success, bytes memory result) = address(_contractToCheck).staticcall(data);
    if(success){
      uint256 balance = abi.decode(result, (uint256));
      return balance > 0;
    } else {
      return false;
    }
  }
}