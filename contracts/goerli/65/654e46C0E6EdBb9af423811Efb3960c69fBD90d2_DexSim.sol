// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract DexSim {
    address _user;
    mapping(string => uint256) liquidityPool;
    mapping(address => mapping(string => uint256)) balance;  

    constructor() {
        liquidityPool["Buterins"] = 6;
        liquidityPool["Nakamotos"] = 2;
    }
  
    function calculateReturn(int amount, string memory tokenTrading) public view returns (int){
        int tradeReturn;
        uint bLiquidity = liquidityPool["Buterins"];
        uint nLiquidity = liquidityPool["Nakamotos"];
        int buterinsLiquidity = int(bLiquidity);
        int nakamotosLiquidity = int(nLiquidity);

        if(keccak256(abi.encodePacked(tokenTrading)) == keccak256(abi.encodePacked("Nakamotos"))) {
            tradeReturn = -1 * (((buterinsLiquidity * nakamotosLiquidity) - ((nakamotosLiquidity + amount) * buterinsLiquidity)) 
                     / (nakamotosLiquidity + amount));
        } else {
            tradeReturn = -1 * (((buterinsLiquidity * nakamotosLiquidity) - ((buterinsLiquidity + amount) * nakamotosLiquidity)) 
                     / (buterinsLiquidity + amount));
        }

        return tradeReturn;
    }

    function swap(string memory tokenTrading, int amount) public returns (int){
        int tradeReturn;
        if(keccak256(abi.encodePacked(tokenTrading)) == keccak256(abi.encodePacked("Nakamotos"))) {
            require(balance[_user][tokenTrading] >= uint(amount), "Not enough funds!");
            tradeReturn = calculateReturn(amount, tokenTrading);
            balance[_user][tokenTrading] -= uint(amount);
            balance[_user]["Buterins"] += uint(tradeReturn);
            liquidityPool["Nakamotos"] += uint(amount);
            liquidityPool["Buterins"] -= uint(tradeReturn);
        } else {
            require( balance[_user][tokenTrading] >= uint(amount), "Not enough funds!");
            tradeReturn = calculateReturn(amount, tokenTrading);
            balance[_user][tokenTrading] -= uint(amount);
            balance[_user]["Nakamotos"] += uint(tradeReturn);
            liquidityPool["Buterins"] += uint(amount);
            liquidityPool["Nakamotos"] -= uint(tradeReturn);
        }

        return tradeReturn;
    }

    function addUser(address user) external {
        _user = user;
    }

    function addLiquidity(uint256 amountNakamotos, uint256 amountButerins) external {
        liquidityPool["Nakamotos"] += amountNakamotos;
        liquidityPool["Buterins"] += amountButerins;
    }

    function fundUser(string memory tokenName, uint256 amount) external {
        balance[_user][tokenName] = amount;
    }

    function reset() public {
        liquidityPool["Buterins"] = 6;
        liquidityPool["Nakamotos"] = 2;
        balance[_user]["Buterins"] = 0;
        balance[_user]["Nakamotos"] = 0;
    }

    function getUserBalance(string memory tokenName) public view returns(uint256){
        return balance[_user][tokenName];
    }

    function getButerins() external view returns (uint256){
        return liquidityPool["Buterins"];
    }

    function getNakamotos() external view returns (uint256){
        return liquidityPool["Nakamotos"];
    }
}