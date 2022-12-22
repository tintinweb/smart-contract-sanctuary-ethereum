/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.9.0;

interface UniswapFunctions{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function symbol() external view returns (string memory);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

contract token {
    uint8 public decimals;
}

contract MultiCallSacha{

    function priceMulticall(address[] calldata addresses) external view returns(uint112[] memory,uint112[] memory){
        uint112[] memory array0 = new uint112[](addresses.length);
        uint112[] memory array1 = new uint112[](addresses.length);
        for(uint112 i = 0; i < addresses.length; i++){
            (array0[i], array1[i],) = UniswapFunctions(addresses[i]).getReserves();
        }
        return (array0,array1);
    }

    
    function decimalMulticall(address[] calldata addresses) external view returns(uint8[] memory){
        uint8[] memory array0 = new uint8[](addresses.length);
        for(uint112 i = 0; i < addresses.length; i++){
            (array0[i]) = token(addresses[i]).decimals();
        }
        return (array0);
    }

    /*function symbol_Multicall(address[] calldata Lp) external view returns(address[] memory, address[] memory ){
        address[] memory token0_ = new address[](Lp.length);
        address[] memory token1_ = new address[](Lp.length);

        for(uint i = 0; i < Lp.length; i++){
            token0_[i] = UniswapFunctions(Lp[i]).token0();
            token1_[i] = UniswapFunctions(Lp[i]).token1();
        }
        return (token0_,token1_);
    }*/

    /*function symbol_Names_Multicall(address[] calldata tokenA, address[] calldata tokenB) external view returns(string[] memory, string[] memory ){
        require(tokenA.length == tokenB.length,"Merci d'envoyer des tableaux de meme taille. ");
        string[] memory token0_symbol = new string[](tokenA.length);
        string[] memory token1_symbol = new string[](tokenA.length);

        for(uint i = 0; i < tokenA.length; i++){

            try UniswapFunctions(tokenA[i]).symbol() {
                token0_symbol[i] = UniswapFunctions(tokenA[i]).symbol();
            } catch  {       
                token0_symbol[i] = "NOT_WORKING";
            }

            try UniswapFunctions(tokenB[i]).symbol() {
                token1_symbol[i] = UniswapFunctions(tokenB[i]).symbol();
            } catch  {       
                token1_symbol[i] = "NOT_WORKING";
            }
            
        }
        return (token0_symbol,token1_symbol);
    }*/



    function get_chosen_pairs(address[] calldata tokenA,address[] calldata tokenB, address[] calldata factory) external view returns(address[] memory){
        require(tokenA.length == tokenB.length && tokenB.length == factory.length,"Merci d'envoyer des tableaux de meme taille. ");
        address[] memory Lps = new address[](tokenA.length);
        for(uint i = 0; i < tokenA.length; i++){
            //on met comme contract le factory du broker donné
            Lps[i] = UniswapFunctions(factory[i]).getPair(tokenA[i],tokenB[i]);
        }
        return (Lps);
    }

    

    function get_all_pairs(address factory, uint start, uint finish) external view returns(address[] memory,address[] memory,address[] memory, uint112[] memory, uint112[] memory){//return : Lp, token0 address, token1 address, token0 symbol, token1 symbol       
        uint len = finish - start;
        address[] memory Lps = new address[](len);
        address[] memory token0_address = new address[](len);
        address[] memory token1_address = new address[](len);
        uint112[] memory reserve0 = new uint112[](len);
        uint112[] memory reserve1 = new uint112[](len);

        for(uint i = start; i < finish; i++){
            //on filtre par factory :
            uint newi = i-start;
            //on met comme contract le factory du broker donné
            Lps[newi] = UniswapFunctions(factory).allPairs(i);
            token0_address[newi] = UniswapFunctions(Lps[newi]).token0();
            token1_address[newi] = UniswapFunctions(Lps[newi]).token1();
            (reserve0[newi], reserve1[newi],) = UniswapFunctions(Lps[newi]).getReserves();
        }
        return (Lps,token0_address,token1_address,reserve0,reserve1);//
    }

}