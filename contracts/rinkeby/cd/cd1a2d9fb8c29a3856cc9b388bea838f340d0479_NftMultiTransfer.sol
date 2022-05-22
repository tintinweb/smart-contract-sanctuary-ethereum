// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
  function transfer(address to, uint256 amount) external;
  function balanceOf(address owner) external view returns (uint256);
}

contract NftMultiTransfer {

  struct TransferRequest {
    address project;
    address to;
    uint256 tokenId;
  }

  uint256 public immutable MAX_TRANSFER_FEE = 5e14; // 0.0005, approx 5% tx fee

  address public owner;
  uint256 public transferFee;

  constructor() {
    transferFee = 1e14; // 0.0001, approx 0.1% tx fee
    owner = msg.sender;
  } 

  function setOwner(address _owner) external {
    require(msg.sender == owner, "PERMISSION_DENIED");
    owner = _owner;
  }

  function setTransferFee(uint256 _transferFee) external {
    require(msg.sender == owner, "PERMISSION_DENIED");
    require(_transferFee <= MAX_TRANSFER_FEE, "INVALID_FEE");
    transferFee = _transferFee;
  }

  function multiTransfer(TransferRequest[] calldata _transferRequests) external payable {
    require(msg.value == _transferRequests.length * transferFee, "INVALID_FEE");
    for (uint256 i = 0; i < _transferRequests.length; i++) {
      TransferRequest memory request = _transferRequests[i];
      IERC721(request.project).transferFrom(msg.sender, request.to, request.tokenId);
    }
  }  
  
  function withdraw() external payable {
    require(msg.sender == owner, "PERMISSION_DENIED");
    require(payable(owner).send(address(this).balance), "NO_TRANSFER");
  }

  function extract(address _token) external {
    require(msg.sender == owner, "PERMISSION_DENIED");
    IERC20 token = IERC20(_token);
    token.transfer(owner, token.balanceOf(address(this)));
  }

  function getTransferFee(TransferRequest[] calldata _transferRequests) external view returns (uint256) {
    return _transferRequests.length * transferFee;
  } 
}