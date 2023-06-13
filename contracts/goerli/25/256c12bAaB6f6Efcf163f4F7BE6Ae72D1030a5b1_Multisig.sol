/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract Multisig {
    // словарь админов
    mapping(address => bool) admins;
    // кол-во админов
    uint256 adminsCount;
    uint256 public nonce;

    constructor(address[] memory _admins) {
        adminsCount = _admins.length;
        for(uint256 i = 0; i < adminsCount; i++) {
            admins[_admins[i]] = true;
        }
    }

    function verify(
        uint256 _nonce,
        address target,
        bytes calldata payload,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) public {
        // проверка nonce
        require(_nonce == nonce, "Bad nonce");
        // проверяем размеры массивов
        require(v.length == r.length && r.length == s.length, "Bad arrays length");
        // получаем хэш сообщения из исходных данных
        bytes32 messagehash = getMessageHash(nonce, target, payload);
        nonce++;
        // получаем кол-во правильных подписей
        uint256 signerCount = _verify(messagehash, v, r, s);
        // проверяем сколько админов подписало сообщение
        require (signerCount > adminsCount / 2, "Not enough signatures");
        // совершаем вызов
        (bool success,) = target.call(payload);
        require(success);
    }

    function _verify(
        bytes32 messageHash,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) internal view returns(uint256) {
        // кол-во админов, которые подписали это сообщение
        uint256 signed = 0;
        // массив админов, которые подписали сообщение
        address[] memory adrs = new address[](v.length);
        // востанавливаем адреса и считываем сколько там админов 
        for(uint256 i = 0; i < v.length; i++) {
            // востонавливаем очередной адрес
            address adr = ecrecover(messageHash, v[i], r[i], s[i]);
            // проверяем ест-ли этот адрес среди админов
            if (admins[adr] == true) {
                // проверяем нет ли уже этой подписи среди подписавших
                bool check = true;
                // перебираем адреса тех, кто уже пописался, 
                // смотрим есть ли там адрес adr, 
                // если нет - добавляем
                for(uint256 j = 0; j < signed; j++) {
                    if (adrs[i] == adr) {
                        check = false;
                        break;
                    }
                }
                if (check) {
                    adrs[signed] = adr;
                    signed++;
                }
            }
        }
        return signed;
    }

    // это функция для сборки чуша сщщбщения из исходных данных
    function getMessageHash(
        uint256 _nonce,
        address target,
        bytes calldata payload
    ) internal view returns(bytes32) {
        bytes memory message = abi.encodePacked(_nonce, address(this), target, payload);
        bytes memory prefix = "\x19Ethereum Signed Messge:\n";
        bytes memory digest = abi.encodePacked(prefix, toBytes(message.length), message);
        return keccak256(digest);
    }

    // это вариант когда сообщение перед подписью хешируется
    function getMessageHash2(
        uint256 _nonce,
        address target,
        bytes calldata payload
    ) internal view returns(bytes32) {
        bytes32 message = keccak256(abi.encodePacked(_nonce, address(this), target, payload));
        bytes memory prefix = "\x19Ethereum Signed Messge:\n32";
        bytes memory digest = abi.encodePacked(prefix, message);
        return keccak256(digest);
    }
    
    // функция для перевода числа в строку
    function toBytes(uint256 value) internal pure returns(bytes memory) {
        uint256 temp = value;
        uint256 digits;
        do {
            digits++;
            temp /= 10;
        } while (temp != 0);
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }
}