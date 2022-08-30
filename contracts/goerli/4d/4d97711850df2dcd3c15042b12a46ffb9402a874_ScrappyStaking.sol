/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;
  constructor() {
    _status = _NOT_ENTERED;
  }
  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}
interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
contract ScrappyStaking is IERC721Receiver, ReentrancyGuard {

  address public owner;
  address public scrappy;
  uint256 public claimFee;
  // uint256 public secPerWeek = 604800;
  uint256 public secPerWeek = 60;
  
  struct staked {
    address owner;
    uint256 stakingtime;
    uint256 claim;
  }

  mapping (uint256 => staked) public stake;

  event _721Received();
  event claimed(uint256 amount);

  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "x");
    _;
  }
  function setToken(address _token) external onlyOwner {
    scrappy = _token;
  }
  function setClaimFee(uint256 _fee) external onlyOwner {
    claimFee = _fee;
  }
  function stakeNFT(uint256[] calldata _id) external nonReentrant{ 
    for (uint256 i = 0; i < _id.length; ++i) {
    IERC721(scrappy).safeTransferFrom(msg.sender, address(this), _id[i]);
    stake[_id[i]].owner = msg.sender;
    stake[_id[i]].stakingtime = block.timestamp;
    }
  }
  function unStakeNFT(uint256 _id) external payable nonReentrant{
    require(msg.sender == stake[_id].owner, "No stake exists");
    claimReward(_id);
    IERC721(scrappy).safeTransferFrom(address(this), stake[_id].owner, _id);
    delete stake[_id];
  }
  function claimReward(uint256 _id) public payable nonReentrant{
    require(msg.sender == stake[_id].owner, "No stake exists");
    uint256 timeStaked = (block.timestamp - stake[_id].stakingtime)/secPerWeek;
    uint256 stakeAmount = timeStaked - stake[_id].claim;
    require(msg.value >= claimFee * stakeAmount, "Eth amount");
    stake[_id].claim = timeStaked;
    emit claimed(stakeAmount);
  }
  function withdraw(address _address) external onlyOwner {
    (bool success, ) = payable(_address).call{value: address(this).balance}("");
    require(success);
  }
  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    emit _721Received();
    return this.onERC721Received.selector;
  }
}