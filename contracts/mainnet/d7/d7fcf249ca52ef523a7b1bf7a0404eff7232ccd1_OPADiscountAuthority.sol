/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// File: erc-20.sol

pragma solidity ^0.8.15;

/*

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

contract OPADiscountAuthority is Ownable {

    IERC721 public ecoMaxiNFT;
    IERC721 public liqMaxiNFT;
    IERC721 public magisterNFT;

    event EcosystemMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);
    event LiquidityMaxiNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);
    event MagisterNFTSet(address indexed oldTokenAddress, address indexed newTokenAddress);

    constructor() Ownable(address(0x0A4f3A75D3C039B79CDCea816e010890D7d68445)) {}

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

    function discountRatio(address swapper) external view returns (uint256 numerator, uint256 denominator) {
        numerator = 1;
        denominator = 1;

        if (liqMaxiNFT.balanceOf(swapper) > 0 || magisterNFT.balanceOf(swapper) > 0) {
            // 25% discount
            numerator = 75;
            denominator = 100;
        } else if (ecoMaxiNFT.balanceOf(swapper) > 0) {
            // 10% discount
            numerator = 90;
            denominator = 100;
        }
    }
}