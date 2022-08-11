/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Oylama{

struct oyKullanan{
    bool oy_durumu;
    uint  aday;
    uint oy_index;
}

struct aday{
    string adi_soyadi;
    uint oy_sayisi;
}
 
  mapping(string => uint) private _users;

uint public toplam_oy_sayisi = 0;

mapping(address => oyKullanan) oyKullananlar;
aday[] public adaylar;

function aday_ekle(string memory _adi_soyadi) public {
    adaylar.push(aday({
        adi_soyadi: _adi_soyadi, 
        oy_sayisi:0
        }));
}

function oy_kullan(uint aday_no ) public {
    oyKullanan storage sender = oyKullananlar[msg.sender];
    require(!sender.oy_durumu, "zaten oy kullanildi.");
    sender.oy_durumu = true;
    sender.aday = aday_no;
    sender.oy_index = toplam_oy_sayisi;
    adaylar[aday_no].oy_sayisi += 1;
    toplam_oy_sayisi += 1;
}

function kazanani_bul() public view returns(uint kazan_aday_index){
    uint kazanan_oysayisi = 0;
    for(uint x=0; x < adaylar.length; x++){
        if(adaylar[x].oy_sayisi > kazanan_oysayisi){
            kazanan_oysayisi = adaylar[x].oy_sayisi;
            kazan_aday_index = x;
        }
    }
}

function kazanan_aday_ismi() public view returns(string memory aday_ismi) {
    aday_ismi = adaylar[kazanani_bul()].adi_soyadi;
}

function aday_sayisi() public view returns (uint){
     return adaylar.length;
}

 function adayisimleri() public view returns (string[] memory){
     string[] memory List = new string[](adaylar.length);
     for(uint x=0; x < adaylar.length; x++){
         List[x] = adaylar[x].adi_soyadi;
     }
    return List;
}


}