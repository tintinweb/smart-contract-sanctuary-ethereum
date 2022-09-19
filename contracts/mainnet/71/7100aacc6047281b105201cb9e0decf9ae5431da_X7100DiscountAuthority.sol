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

Contract: Smart Contract for X7100 series token fee discounts

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

    function setMagisterNFT(address tokenAddress) external onlyOwner {
        require(address(magisterNFT) != tokenAddress);
        address oldTokenAddress = address(magisterNFT);
        magisterNFT = IERC721(tokenAddress);
        emit MagisterNFTSet(oldTokenAddress, tokenAddress);
    }

    function setX7DAO(address tokenAddress) external onlyOwner {
        require(address(x7dao) != tokenAddress);
        address oldTokenAddress = address(x7dao);
        x7dao = IERC20(tokenAddress);
        emit X7DAOTokenSet(oldTokenAddress, tokenAddress);
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

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
}

interface IDiscountAuthority {
    function discountRatio(address) external view returns (uint256, uint256);
}

contract X7100DiscountAuthority is Ownable {

    IERC721 public ecoMaxiNFT;
    IERC721 public liqMaxiNFT;
    IERC721 public magisterNFT;
    IERC20 public x7dao;

    event EcosystemMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);
    event LiquidityMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);
    event MagisterNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);
    event X7DAOTokenSet(address indexed oldTokenAddress, address indexed newTokenAddress);

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

    function setMagisterNFT(address tokenAddress) external onlyOwner {
        require(address(magisterNFT) != tokenAddress);
        address oldTokenAddress = address(magisterNFT);
        magisterNFT = IERC721(tokenAddress);
        emit MagisterNFTSet(oldTokenAddress, tokenAddress);
    }

    function setX7DAO(address tokenAddress) external onlyOwner {
        require(address(x7dao) != tokenAddress);
        address oldTokenAddress = address(x7dao);
        x7dao = IERC20(tokenAddress);
        emit X7DAOTokenSet(oldTokenAddress, tokenAddress);
    }

    function discountRatio(address swapper) external view returns (uint256 numerator, uint256 denominator) {
        numerator = 1;
        denominator = 1;

        if (liqMaxiNFT.balanceOf(swapper) > 0 || x7dao.balanceOf(swapper) >= 50000 * 10**18) {
            // 50% Fee Discount
            numerator = 50;
            denominator = 100;
        } else if (ecoMaxiNFT.balanceOf(swapper) > 0 || magisterNFT.balanceOf(swapper) > 0) {
            // 25% Fee Discount
            numerator = 75;
            denominator = 100;
        }
    }
}