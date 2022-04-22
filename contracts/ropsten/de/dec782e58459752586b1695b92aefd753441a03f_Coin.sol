/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Coin {

    // キーワード「public」は、他のコントラクトから変数にアクセスできます
    address public minter;
    mapping (address => uint) public balances;

    // イベントは、宣言した特定のコントラクトの変更にクライアントが反応することを可能にします
    event Sent(address from, address to, uint amount);

    // コンストラクタのコードは、コントラクトが作成されるときにのみ実行されます
    constructor() {
        minter = msg.sender;
    }

    // 新しく作成されたコインの量をアドレスに送ります
    // コントラクトの作成者のみが呼び出すことができます
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    // エラーは操作に失敗した理由についての情報を提供できます
    // エラーは関数の呼び出し側に返されます
    error InsufficientBalance(uint requested, uint available);

    // 任意のコールしたアカウントのコインの量をアドレスに送ります
    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

}