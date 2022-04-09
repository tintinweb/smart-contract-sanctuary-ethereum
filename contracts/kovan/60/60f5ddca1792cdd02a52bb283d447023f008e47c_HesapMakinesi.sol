/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT //MIT lisansı girilir
pragma solidity 0.8.0; //compiler versiyonu
contract HesapMakinesi //sözleşme adı girilir
{

    uint ilkDeger;   //ilk sayi 
    uint ikinciDeger; //ikinci sayi 
 

    function ilk(uint a) public //ilk sayi inputu
    {
        ilkDeger = a; //input degiskene atanir
    }
 

    function ikinci(uint b) public //ikinci sayi inputu
    {
        ikinciDeger = b; //input degiskene atanir
    }
 
    function Carpma() view public returns (uint) //çarpma fonksiyonu
    {
        uint carp = ilkDeger * ikinciDeger; //a*b
        return carp;
    }

    function Bolme() view public returns (uint) //bölme fonksiyonu
    {
        uint bol = ilkDeger / ikinciDeger; // a/b
        return bol;
    }

    function Cikarma() view public returns (uint) //çıkarma fonksiyonu
    {
        uint cikar = ilkDeger - ikinciDeger; //a-b
        return cikar;
    }


    function Toplama() view public returns (uint) //toplama fonksiyonu
    {
        uint topla = ilkDeger + ikinciDeger;  //a+b
        return topla;
    }
    
}