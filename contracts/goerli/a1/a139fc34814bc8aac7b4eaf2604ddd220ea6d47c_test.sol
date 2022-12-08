/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// File: ITM_Test/test.sol

pragma solidity ^0.8.13;

contract test {

    // * 方法一所使用的Struct
    struct Info_1 {
        string description;
    }

    // * 方法二所使用的Struct   
    struct Info_2 {
        bytes description;
    }

    // * 方法一所使用的Mapping
    mapping(address => Info_1) public userInfo_1;

    // * 方法二所使用的Mapping
    mapping(address => Info_2) public userInfo_2;

    // * [方法一]
    // * 傳入的_description要先轉成Unicdoe
    function setUserInfo_1(string memory _description) public {
       Info_1 storage _info = userInfo_1[msg.sender];
       _info.description = _description;
    }

    // * [方法二]
    function setUserInfo_2(string memory _description) public {
        Info_2 storage _info = userInfo_2[msg.sender];
        _info.description = abi.encode(_description);
    }

    function decodeString(bytes memory _data) public pure returns (string memory result) {
        result = abi.decode(_data, (string));
    }
}

// 方法一： [缺點：當字串太長會很貴]
// String _description = "ITM的合約測試，加上標點符號。"
// String _description [unicode] = "ITM\u7684\u5408\u7d04\u6e2c\u8a66\uff0c\u52a0\u4e0a\u6a19\u9ede\u7b26\u865f\u3002"

// 方法二： [優點：省錢 ｜ 缺點：需要User多一步驟去解密出原先的中文 (但無需要gas fee)]
// Step1: 先把中文字串透過abi.encode()轉成bytes [稱為B]
// Step2: 再把B存入到Mapping裡description的變數中
// Step3: User取得B之後，再透過寫好的abi.decode function去解讀出原先的中文字串