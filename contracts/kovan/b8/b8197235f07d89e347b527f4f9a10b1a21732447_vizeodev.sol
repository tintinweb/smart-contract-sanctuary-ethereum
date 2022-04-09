/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

pragma solidity ^0.4.22;

contract vizeodev{
    uint a= 3;
    string asal = "Kod başında tanımlanan a sayisi asal sayidir!";
    string dasal = "Kod başında tanımlanan a sayisi asal sayi degildir!";

    function asalSayi() public view returns(string) {
        if (a %2==0 ) {
            return dasal;
        } else {
            return asal ;
        }
    }

    function birdenGirilenSayiyaKadarToplamiBulma(uint _n)public pure returns(uint){
        uint b;
        for(uint i=1;i<=_n;i++){
            b+=i;
        }
        return b;
    }
}