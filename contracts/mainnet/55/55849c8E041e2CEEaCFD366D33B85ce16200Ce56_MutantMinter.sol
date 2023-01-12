/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!");_; }
    function transferOwnership(address new_) external onlyOwner {address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface iCGO {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface iMSC {
    function controllerMint(address to_, uint256 amount_) external;
}

contract MutantMinter is Ownable {

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint8 public saleState = 0; //1-CGO 2-PUB
    uint256 public totalSupply = 0;
    uint256 public constant maxToken = 999;
    mapping(address => uint256) public psMinted;

    iCGO public CGO = iCGO(0x5923Ef0e180d286c3441cb9879EBab06bB2182c9);
    iMSC public MSC = iMSC(0xEE0e0b6c76d528B07113bB5709b30822DE46732B);

    modifier onlySender {
        require(msg.sender == tx.origin, "No smart contract"); _; 
    }

    function setToken(address address_) external onlyOwner {
        MSC = iMSC(address_);
    }

    function setCGO(address address_) external onlyOwner {
        CGO = iCGO(address_); 
    }

    function setSaleState(uint8 _state) external onlyOwner {
        saleState = _state;
    }

    function ownerMint(uint256 amount_) external onlyOwner {
        require(amount_ + totalSupply <= maxToken, "No more NFTs");
        internalmintM(msg.sender, amount_);
    }

    function mintWithCGO(uint256 amount_) external onlySender {
        require(saleState == 1, "Inactive");
        require(amount_ + totalSupply <= maxToken, "No more NFTs");
        require(amount_ <= CGO.balanceOf(msg.sender, 0), "You do not own enough CGO");

        CGO.safeTransferFrom(msg.sender, burnAddress, 0, amount_, "0x00");
        internalmintM(msg.sender, amount_);
    }

    function mintPublic() external onlySender {
        require(saleState == 2, "Inactive");
        require(1 + totalSupply <= maxToken, "No more NFTs");
        require(psMinted[msg.sender] == 0, "No mints remaining");

        psMinted[msg.sender] ++;
        internalmintM(msg.sender, 1);
    }

    function internalmintM(address to_, uint256 amount_) internal {
        for (uint256 i = 0; i < amount_; i++) {
          totalSupply ++;
          MSC.controllerMint(to_, totalSupply);
        }
    }
}