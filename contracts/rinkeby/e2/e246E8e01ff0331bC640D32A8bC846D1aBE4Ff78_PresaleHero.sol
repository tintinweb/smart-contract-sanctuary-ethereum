/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTDatabase {
    function AddNFT(string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress) external returns (bool);

    function ReOwnerNFT(uint256 _nftId, address _newOwner) external returns (bool);

    function BurnNFT(uint _nftId) external returns (bool);

    function GetNFTsByOwner(address _owner) external view returns (uint[] memory);

    function GetNFTByID(uint _nftID) external view returns (string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress);
}

interface IETH {
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

contract PresaleHero {
    address private devWallet = 0x1331A37f2E68a58ABCE998fC9E53Ad32a049baF8;
    INFTDatabase private database = INFTDatabase(0x928c1c7f5De2Cab89114306fb04518aC8c41eF9a);
    IETH private eth = IETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint256 priceDefaultOfNFT = 0.1*10**18;

    string[] nftPresaleIds = ["1a", "2a", "3a", "4a", "5a", "6a", "7a", "8a", "9a", "10a"];

    function GetNftPresaleIds() public view returns (string[] memory){
        return nftPresaleIds;
    }

    function toBytes(string memory str) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {mstore(add(b, 32), str)}
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(toBytes(_str)));
        return rand % dnaModulus;
    }

    function _createNFT(string memory _name, uint _dna, address ownerOfThisNFT) private {
        database.AddNFT(_name, _dna, 1, 0, 0, ownerOfThisNFT);
    }

    function GetNFTNumberOfAddress(address account) public view returns (uint){
        return database.GetNFTsByOwner(account).length;
    }

    function IdIsExistOnPresale(string memory _idNft) public view returns (bool){
        for (uint i = 0; i < nftPresaleIds.length; i++) {
            if (keccak256(abi.encodePacked(nftPresaleIds[i])) == keccak256(abi.encodePacked(_idNft))) {
                return true;
            }
        }
        return false;
    }

    function BuyPresaleNftWithId(string memory _name) external payable {
        require(IdIsExistOnPresale(_name), "Id of this does not exist in this presale !");
        require(eth.balanceOf(msg.sender)>=priceDefaultOfNFT, "sufficient amount !");
        eth.transferFrom(msg.sender, devWallet, priceDefaultOfNFT);
        uint randDna = _generateRandomDna(_name);
        randDna = randDna - randDna % 100;
        _createNFT(_name, randDna, msg.sender);
    }
}