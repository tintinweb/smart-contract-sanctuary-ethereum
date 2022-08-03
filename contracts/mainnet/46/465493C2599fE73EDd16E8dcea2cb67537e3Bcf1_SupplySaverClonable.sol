//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWgmisPrimaryPhase0 {
  function mintMerkleWhitelist(bytes32[] calldata _merkleProof, uint96 _quantity) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract SupplySaverClonable {

  IWgmisPrimaryPhase0 public wgmis;
  address public destinationAddress;

  function initialize(address _wgmis, address _destinationAddress) external {
    require(address(wgmis) == address(0), "Already initialized");
    wgmis = IWgmisPrimaryPhase0(_wgmis);
    destinationAddress = _destinationAddress;
  }

  function saveSupply(bytes32[] calldata _merkleProof, uint96 _quantity) external {
    wgmis.mintMerkleWhitelist(_merkleProof, _quantity);
  }

  function transferToDestination(uint16 _quantity, uint256 _startTokenId) external {
    for(uint16 i = 0; i < _quantity; i++) {
      wgmis.transferFrom(address(this), destinationAddress, _startTokenId + i);
    }
  }

}