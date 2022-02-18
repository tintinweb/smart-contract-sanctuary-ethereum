/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
// File: contracts/NFT Contract/ModuleContext.sol



pragma solidity ^0.8.0;

interface INFTDatabase {
    function AddNFT(string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress) external returns (bool);
    function GetNFTsByOwner(address _ownerAddress) external view returns (uint[] memory);
}

interface IToken {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
}

abstract contract ModuleContext {
    address internal devWallet = 0x1331A37f2E68a58ABCE998fC9E53Ad32a049baF8;
    INFTDatabase internal database = INFTDatabase(0x4e8B997243e050d158c1160A87868BEf031A0ac7);
    IToken internal token = IToken(0x754A573286b561db566681fA08902b161a9599FD);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    function toBytes(string memory str) internal pure returns (bytes memory b) {
    b = new bytes(32);
    assembly { mstore(add(b, 32), str) }
}
}
// File: contracts/NFT Contract/ModuleGetNFT_001.sol



pragma solidity ^0.8.0;


contract ModuleGetNFT_001 is ModuleContext {

    function _getNFTs(address dd) public view returns (uint[] memory) {
        return database.GetNFTsByOwner(dd);
    }
}