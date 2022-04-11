/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Function {

    function is_Prime(uint x) public pure returns (bool b) 
    //fonksiyon girdisi ve çıktısı tanımlandı
    {
        //Bölen bulma algoritması
        for(uint i=2; i < x; i++){
            if(x % i == 0){
                return (false);     //bölen varsa asal değildir
            }
        }
        return (true);      //bölen yok ise asaldır
    }
}
//Alperen Demir 
//Mühendislik Fakültesi - Endüstri Mühendisliği
//191120025