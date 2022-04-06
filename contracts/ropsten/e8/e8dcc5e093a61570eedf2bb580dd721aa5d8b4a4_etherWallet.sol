/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract etherWallet {

    // Kontratin sahibini tutmak icin tanimlandi.
    address payable public owner;

    // constructor: Kontrat deploy edilirken yalnizca bir kere calisan, 
    // daha sonrada bir daha cagirilamayan istege bagli bir fonksiyondur.
    constructor() {
        owner = payable(msg.sender);
    }

    fallback() external payable {}

    // Herkesin bu hesaba eth göndermesini saglar.
    receive() external payable {}

    // Sadece kontratin sahibinin eth transferini gerceklestirir.
    function withdraw(uint256 _amount) external {
        // Herkesin bu kontrattan para çekmesini onlemek icin kontrol islemi gerceklestirir
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    // external: Bu fonksiyonu disaridan kullanicilar cagirabilir fakat kontrat icerisinden cagirilamaz
    // view: Fonksiyonun blokchain'den veri okuyacagini fakat uzerinde degisiklik yapmayacagini bildirir.
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}