/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Indentifier: MIT

/*

-   あなたの名前がコントラクト名
-   状態変数は名前、年齢、性別、住所をそれぞれ public で宣言
    -   名前、性別は constant にして初期値を与える。年齢は immutable にする
    -   住所は public のみで宣言
-   Ethereum のアドレス変数 owner を public のみで宣言
-   constructor で年齢は 初期値を与えて、owner にコントラクト作成者のアドレスを保存する
-   住所を変えれる関数を作ってあげる

    -   住所を変更してみる
*/

pragma solidity ^0.8.7;

contract kogawa {
    string public constant name = "Kogawa";
    uint public immutable AGE;
    string public constant gender = 'm';
    string public real_address;
    address public owner;

    constructor(uint _age) {
        owner = msg.sender;
        AGE = _age;
    }

    function changeAdd(string memory _address) public {
        real_address = _address;
    }
}