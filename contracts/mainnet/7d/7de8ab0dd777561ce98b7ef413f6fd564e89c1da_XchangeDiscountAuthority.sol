/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for Xchange fee discounts

The trading fee discount is 50%. It is represented as the fee amount as a fraction of 100000
This discount is hard coded into this contract.
If it should need to change, a new discount authority contract would be deployed.

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setDEXMaxiNFT(address tokenAddress) external onlyOwner {
        require(address(dexMaxiNFT) != tokenAddress);
        address oldTokenAddress = address(dexMaxiNFT);
        dexMaxiNFT = IERC721(tokenAddress);
        emit DEXMaxiNFTSet(oldTokenAddress, tokenAddress);
    }

This function will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface IXchangeDiscountAuthority {
    function fee(address) external view returns (uint256);
}

contract XchangeDiscountAuthority is Ownable, IXchangeDiscountAuthority {

    IERC721 public dexMaxiNFT;

    event DEXMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);

    constructor() Ownable(msg.sender) {}

    function setDEXMaxiNFT(address tokenAddress) external onlyOwner {
        require(address(dexMaxiNFT) != tokenAddress);
        address oldTokenAddress = address(dexMaxiNFT);
        dexMaxiNFT = IERC721(tokenAddress);
        emit DEXMaxiNFTSet(oldTokenAddress, tokenAddress);
    }

    function fee(address swapper) external view returns (uint256 feeAmount) {
        if (dexMaxiNFT.balanceOf(swapper) > 0) {
            feeAmount = 100;
        } else {
            feeAmount = 200;
        }
    }
}