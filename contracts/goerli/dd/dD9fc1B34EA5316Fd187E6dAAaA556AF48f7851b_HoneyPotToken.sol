/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    // Token adı
    string public name = "My Token";

    // Token simgesi
    string public symbol = "MYT";

    // Token ondalık sayısı
    uint8 public decimals = 18;

    // Token toplam arzı
    uint256 public totalSupply;

    // Kullanıcı bakiyeleri
    mapping(address => uint256) public balances;

    // Token transfer olayı
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Yapılandırıcı
    constructor(uint256 _totalSupply) {
        // Toplam arz, yapılandırıcı ile belirlenir
        totalSupply = _totalSupply;

        // Yapılandırıcı gönderenin bakiyesi toplam arz ile ayarlanır
        balances[msg.sender] = totalSupply;
    }

    // Token transfer fonksiyonu
    function transfer(address _to, uint256 _value) public {
        // Gönderenin bakiyesi, transfer edilmek istenen değerden fazla olmalıdır
        require(balances[msg.sender] >= _value, "Insufficient balance.");

        // Gönderenin bakiyesi transfer edilen değer kadar azaltılır
        balances[msg.sender] -= _value;

        // Alıcının bakiyesi transfer edilen değer kadar artırılır
        balances[_to] += _value;

        // Transfer olayı tetiklenir
        emit Transfer(msg.sender, _to, _value);
    }

    // Kullanıcının bakiyesini döndürür
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract HoneyPotToken is Token {
    // Kontrat sahibi
    address owner;

    // Honeypot yatırımları
    mapping(address => uint256) public deposits;

    // Honeypot yatırım olayı
    event HoneyPotDeposit(address sender, uint256 value);

    // Honeypot durumu (aktif/pasif)
    bool public active;

    // Yapılandırıcı
    constructor(uint256 _totalSupply) Token(_totalSupply) {
        // Kontrat sahibi, gönderen ile ayarlanır
        owner = msg.sender;

        // Honeypot pasifleştirilir
        active = false;
    }

    // Honeypot yatırım fonksiyonu
    function fallForTheTrap() public payable {
        // Honeypot aktif değilse işlem yapılamaz
        require(active, "Honeypot is currently inactive.");

        // Yatırım yapılacak Ether miktarı 0 dan büyük olmalıdır
        require(msg.value > 0, "Cannot deposit 0 Ether.");

        // Yatırılan Ether miktarı token'e çevrilir
        uint256 tokens = msg.value * 10 ** uint256(decimals);

        // Kullanıcının bakiyesi, toplam arzdan fazla olamaz
        require(tokens <= totalSupply - balances[msg.sender], "Insufficient total supply.");

        // Honeypot yatırımı kaydedilir
        deposits[msg.sender] += tokens;

        // Kullanıcının bakiyesi artırılır
        balances[msg.sender] += tokens;

        // Toplam arz azaltılır
        totalSupply -= tokens;

        // Honeypot yatırım olayı tetiklenir
        emit HoneyPotDeposit(msg.sender, tokens);
    }

    // Kullanıcının honeypot yatırımını döndürür
    function getDeposit(address account) public view returns (uint256) {
        return deposits[account];
    }

    // Honeypot yatırımlarının toplamını döndürür
    function getTotalDeposits() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < address(this).balance; i++) {
            address account = address(uint160(i));
            if (deposits[account] > 0) {
                total += deposits[account];
            }
        }
        return total;
    }

    // Honeypot bakiyesini çeker
    function withdraw() public payable {
        // Sadece kontrat sahibi bakiyeyi çekebilir
        require(msg.sender == owner, "Only the contract owner can withdraw funds.");
        address payable sender = payable(msg.sender);
        sender.transfer(address(this).balance);
    }

    // Honeypot'u aktifleştirir
    function activateHoneyPot() public {
        // Sadece kontrat sahibi honeypot'u aktifleştirebilir
        require(msg.sender == owner, "Only the contract owner can activate the honeypot.");
        active = true;
    }

    // Honeypot'u deaktifleştirir
    function deactivateHoneyPot() public {
        // Sadece kontrat sahibi honeypot'u deaktifleştirebilir
        require(msg.sender == owner, "Only the contract owner can deactivate the honeypot.");
        active = false;
    }
}