// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/** 
 * @title Contract Typeを学ぼう
 * 全Contractはそれ自身の型を定義できる
 * Address型に明示的に変換できる
 * Contract型のローカル変数を宣言できる（MyContract c）
 * Contractをインスタンス化することができる(new)
 */
contract Contract {
    /// @dev constructorやfunctionにpayableを付与、宣言すると、コントラクトはETHを受け取れるようになる
    constructor() payable {}

     

    /// @dev thisは現コントラクト(Contract)を意味する
    function getContractAddress() public view returns (address) {
        return address(this);
    }

    /// @dev 現コントラクトを破棄し、その資金を与えられたアドレスに送る。本当に削除されるのはトランザクション終了時。
    function destruct() public {
        selfdestruct(payable(msg.sender));
    }
 
}

/** 
 * @title Address Typeを学ぼう
 */
contract Address {


    /// @dev msg.senderはクエリ/トランザクション元アカウントアドレスが入っているグロー
    address public fromAddr;

    constructor() {
        fromAddr = msg.sender;
    }

    /// @dev アカウントアドレス(EOA)の所有ETHを取得
    function getBalance() public view returns (uint256) {
        uint256 balance = fromAddr.balance;
        return balance;
    }

    /// @dev コントラクトのバイトコードを取得
    function getByteCode() public view returns (bytes memory) {
        return address(this).code;
    }

    /// @dev コントラクトのバイトコードハッシュを取得
    function getByteCodeHash() public view returns (bytes32) {
        return address(this).codehash;
    }


    /// @dev transferでETHを移転
    function transfer(address payable to) public payable {
        to.transfer(msg.value);
    }

    /// @dev sendでETHを移転
    function send(address payable to) public payable returns (bool) {
        bool result = to.send(msg.value);
        require(result, "failed");
        return result;
    }

    /// @dev callでETHを移転
    function call(address payable to) public payable returns (bool, bytes memory) {
        (bool result, bytes memory data) = to.call{value: msg.value}("");
        require(result, "failed");
        return (result, data);
    }

}