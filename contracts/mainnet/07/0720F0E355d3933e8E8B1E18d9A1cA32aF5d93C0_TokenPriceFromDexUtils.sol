// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts, https://www.starblockdao.io/

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

import "./Ownable.sol";

interface IDexPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ITokenPriceUtils {
    function getTokenPrice(address _token) external view returns (uint256);
}

contract TokenPriceFromDexUtils is Ownable, ITokenPriceUtils {
    uint256 public constant PRECISION = 1e18;

    IDexPair public dexPair; // dex tokens pair
    
    event SetDexPair(IDexPair _dexPair);
    
    constructor(IDexPair _dexPair) {
        require(address(_dexPair) != address(0), "TokenPriceFromDexUtil: _dexPair can not be zero!");
        dexPair = _dexPair;
    }
    
    function setDexPair(IDexPair _dexPair) external onlyOwner {
        require(address(_dexPair) != address(0), "TokenPriceFromDexUtil: _dexPair can not be zero!");
        dexPair = _dexPair;
        emit SetDexPair(_dexPair);
    }
    
    function getTokenPrice(address _token) external view returns (uint256) { 
        require(_token != address(0), "TokenPriceFromDexUtil: token can not be zero!");
        if(_token != dexPair.token0() && _token != dexPair.token1()){
            return 0;
        }
        (uint112 reserve0, uint112 reserve1, ) = dexPair.getReserves();
        if(_token == dexPair.token1()){
            if(reserve1 > 0){
                return reserve0 * PRECISION / reserve1;
            }
        }else{
            if(reserve0 > 0){
                return reserve1 * PRECISION / reserve0;
            }
        }
        return 0;
    }
}