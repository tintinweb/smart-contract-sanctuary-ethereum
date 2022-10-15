/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


    // 接口合约
interface IERC721 {
    // 总量
    function totalSupply() external view returns (uint);


    // 铸造方法
    function freemint(uint amount) external payable;


    // 发送方法
function transferFrom(
  address from,
  address to,
  uint tokenId
  ) external;
}


// 铸造合约
contract ERC721Mint {
  // 构造函数(nft合约地址, 归集地址)
  constructor(address ERC721, address owner) payable {
  // 获取总量
  uint t = IERC721(ERC721).totalSupply();
// 铸造(0.05购买总价)(5购买数量)
IERC721(ERC721).freemint{value:0.05 ether}(5);
// 归集
for (uint i = 1; i <= 5; i++) {
  // 发送操作,(当前合约地址,归集地址,tokenId)
  IERC721(ERC721).transferFrom(address(this), owner, t + i);
}
// 自毁(收款地址,归集地址)
selfdestruct(payable(owner));
}
}


// 工厂合约
contract MintFactory {
// 所有者地址
address owner;


constructor() {
// 所有者 = 合约部署者
 owner = msg.sender;
}


// 部署方法,(NFT合约地址,抢购数量)
function deploy(address ERC721, uint count) public payable {
// 用抢购数量进行循环
for (uint i; i < count; i++) {
  // 部署合约(抢购总价)(NFT合约地址,所有者地址)
  new ERC721Mint{value:0.05 ether}(ERC721, owner);
 }
}
}