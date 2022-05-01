pragma solidity >=0.7.0 <0.9.0;

interface Sale {
  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface Token {
  function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

contract Sender {
  address public land;
  address public token;

  constructor(address _land, address _token) {
    land = _land;
    token = _token;
  }

  function transferIn(address payable to) payable public {
    Token(token).transferFrom(msg.sender, to, 610000000000000000000);
    to.transfer(msg.value);
  }

  function send(address to) payable public {
    uint256 bal = Sale(land).balanceOf(msg.sender);
    require(bal >= 1);
    uint256 tokenInd = Sale(land).tokenOfOwnerByIndex(msg.sender, 0);
    for (uint256 i = 0; i < bal; i++) {
      Sale(land).safeTransferFrom(msg.sender, to, tokenInd + i);
    }
    block.coinbase.transfer(msg.value);
  }
}