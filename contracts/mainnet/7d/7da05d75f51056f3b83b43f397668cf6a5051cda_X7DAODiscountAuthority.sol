/**
 *Submitted for verification at Etherscan.io on 2022-09-19
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

Contract: Smart Contract for X7DAO fee discounts

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setEcosystemMaxiNFT(address tokenAddress) external onlyOwner {
        require(address(ecoMaxiNFT) != tokenAddress);
        address oldTokenAddress = address(ecoMaxiNFT);
        ecoMaxiNFT = IERC721(tokenAddress);
        emit EcosystemMaxiNFTSet(oldTokenAddress, tokenAddress);
    }

    function setLiquidityMaxiNFT(address tokenAddress) external onlyOwner {
        require(address(liqMaxiNFT) != tokenAddress);
        address oldTokenAddress = address(liqMaxiNFT);
        liqMaxiNFT = IERC721(tokenAddress);
        emit LiquidityMaxiNFTSet(oldTokenAddress, tokenAddress);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

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

interface IDiscountAuthority {
    function discountRatio(address) external view returns (uint256, uint256);
}

contract X7DAODiscountAuthority is Ownable {

    IERC721 public ecoMaxiNFT;
    IERC721 public liqMaxiNFT;

    event EcosystemMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);
    event LiquidityMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);

    constructor() Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {}

    function setEcosystemMaxiNFT(address tokenAddress) external onlyOwner {
        require(address(ecoMaxiNFT) != tokenAddress);
        address oldTokenAddress = address(ecoMaxiNFT);
        ecoMaxiNFT = IERC721(tokenAddress);
        emit EcosystemMaxiNFTSet(oldTokenAddress, tokenAddress);
    }

    function setLiquidityMaxiNFT(address tokenAddress) external onlyOwner {
        require(address(liqMaxiNFT) != tokenAddress);
        address oldTokenAddress = address(liqMaxiNFT);
        liqMaxiNFT = IERC721(tokenAddress);
        emit LiquidityMaxiNFTSet(oldTokenAddress, tokenAddress);
    }

    function discountRatio(address swapper) external view returns (uint256 numerator, uint256 denominator) {
        numerator = 1;
        denominator = 1;

        if (liqMaxiNFT.balanceOf(swapper) > 0) {
            // 15% discount
            numerator = 85;
            denominator = 100;
        } else if (ecoMaxiNFT.balanceOf(swapper) > 0) {
            // 10% discount
            numerator = 90;
            denominator = 100;
        }
    }
}