/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

pragma solidity ^0.4.24;

contract MyContract {
        string value; //宣告一個儲存變數 整個智能合約都可以使用該變數

function get() public view returns(string) { // public view 意思為 可見度 開啟 , returns(string) 意思為 函數回傳(字串)
                return value; //(回傳value這個變數)
        }

function set(string _value) public { //set (string _value) 意思為 設定變更數值的方法(字串類型參數 _函數) , public 公開
        value = _value; 
        }
}