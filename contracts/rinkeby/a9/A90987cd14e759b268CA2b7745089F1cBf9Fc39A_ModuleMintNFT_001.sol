/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
// File: contracts/NFT Contract/ModuleContext.sol



pragma solidity ^0.8.0;

interface INFTDatabase {
    function AddNFT(string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress) external returns (bool);
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
    INFTDatabase internal database = INFTDatabase(0x928c1c7f5De2Cab89114306fb04518aC8c41eF9a);
    IToken internal token = IToken(0x752fbCcafFBb6E67e24AAE441EC3B471BC82953d);

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
// File: contracts/NFT Contract/ModuleMintNFT_001.sol



pragma solidity ^0.8.0;


contract ModuleMintNFT_001 is ModuleContext {
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint256 priceOfNFT = 10 ** 18;


    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(toBytes(_str)));
        return rand % dnaModulus;
    }

    function _createNFT(string memory _name, uint _dna, address ownerOfThisNFT) private {
        database.AddNFT(_name, _dna, 1, 0, 0, ownerOfThisNFT);
    }

    function createRandomNFT(string memory _name) external {
        token.transferFrom(msg.sender, devWallet, priceOfNFT);
        uint randDna = _generateRandomDna(_name);
        randDna = randDna - randDna % 100;
        _createNFT(_name, randDna, msg.sender);
    }
}