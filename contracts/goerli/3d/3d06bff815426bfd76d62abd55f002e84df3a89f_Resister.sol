/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// コンパイラのバージョン指定（0.5.0以上）
pragma solidity >= 0.5.0;

contract Resister {

    // アカウント情報
    struct Data {
        string name; // 名前
        uint256 age; // 年齢
        string hobby; // 趣味
    }

    address[] public users; // 全ユーザーのアドレスを格納

    mapping(address => Data) accounts;

    // アカウントを登録する関数
    function registerAccount(string memory _name, uint256 _age, string memory _hobby)
        public
        returns (bool)
    {
        //アカウントが登録されていなければ新規会員登録をする
        if (!isUserExist(msg.sender)) {
            users.push(msg.sender);
        }
        accounts[msg.sender].name = _name;
        accounts[msg.sender].age = _age;
        accounts[msg.sender].hobby = _hobby;
        return true;
    }

    // アカウントが登録されているかどうかを確認
    function isUserExist(address user) public view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return true;
            }
        }
        return false;
    }

    // アカウント情報を読み込む
    function viewAccount(address user) public view returns (string memory, uint256, string memory) {
        string memory _name = accounts[user].name;
        uint256 _age = accounts[user].age;
        string memory _hobby = accounts[user].hobby;

        return (_name, _age, _hobby);
    }   
}