// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.15;

contract NFBT {
  uint256 private _currentIndex = 0;
  address public savageParadiseCollection;

  struct nfbtDatas {
    address owner;
    uint96 savageParadiseNFTId;
  }

  event NFBTMinted(address indexed holder, uint96 indexed savageParadiseId, uint256 nfbtId);
  event Burnt(uint256 savageParadiseId);

  mapping(uint256 => nfbtDatas) private _datas;

  constructor(address _savageParadiseCollection) {
    savageParadiseCollection = _savageParadiseCollection;
  }

  function mint(address holder, uint96 savageParadiseId, uint256 count) external {
    require(msg.sender == savageParadiseCollection, "Invalid sender");
    require(holder != address(0), "Invalid dest");
    for(uint256 i = 0; i < count; i++) {
      _currentIndex++;
      _datas[_currentIndex] = nfbtDatas(holder, savageParadiseId);
      emit NFBTMinted(holder, savageParadiseId, _currentIndex);
    }
  }

  function burn(uint256 nfbtId) external {
    require(_datas[nfbtId].owner == msg.sender, "Invalid Owner");
    delete _datas[nfbtId];
    emit Burnt(nfbtId);
  }

  function sourceOf(uint256 nfbtId) external view returns (uint256 sourceId) {
    sourceId = _datas[nfbtId].savageParadiseNFTId;
    require(sourceId > 0, "Invalid Id");
  }

  function ownerOf(uint256 nfbtId) external view returns (address owner) {
    owner = _datas[nfbtId].owner;
    require(owner != address(0), "Invalid Id");
  }

  function totalSupply() public view virtual returns (uint256) {
    return _currentIndex;
  }

  function name() public view virtual returns (string memory) {
    return "NFBT";
  }

  function symbol() public view virtual returns (string memory) {
      return "NFBT";
  }
}