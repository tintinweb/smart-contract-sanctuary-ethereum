/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity ^0.4.2;

library DMSLibrary {
  struct data {
    address trustees;
    string data; //有工具可以處理string和byte32的轉換 沒時間研究先用這個 這個牽扯的gas的用量 
    bool isValue;
    uint256 expiration_time;
   }
}



contract DMSContract {

  using DMSLibrary for DMSLibrary.data;
  mapping (address => DMSLibrary.data) DMS_data;

 

  function CreateDMSContract(address trustees, string data) public returns(bool) {
    if( DMS_data[msg.sender].isValue) revert("already exist"); // already exists 檢查合約使用者(sender)有沒有create過，有的話revert 沒有的話創建。


    DMS_data[msg.sender].isValue = true;
    DMS_data[msg.sender].trustees = trustees; // 受益人地址
    DMS_data[msg.sender].data = data; //secret
    DMS_data[msg.sender].expiration_time = now+20 ; // 期限為現在時間+3天
  }

  function kick() public //sender更新截止日期
  {
    if( !DMS_data[msg.sender].isValue) revert("does not exist"); // does not exist  檢查合約使用者(sender)的address有沒有註冊過
    
    DMS_data[msg.sender].expiration_time = now +  20 seconds; //sender按這個函數讓合約期限+3天(可能用button自動+日期之類的)
  }


  function getTimeLeft() public view returns(uint256 return_time) { //sender查看截止日期 (可以改成end-now)
    if( !DMS_data[msg.sender].isValue) revert("does not exist"); // does not exist
    require (now<=DMS_data[msg.sender].expiration_time, "time is up");
    return (DMS_data[msg.sender].expiration_time-now)   ;  //合約使用者(sender)查看截止時間 單位 秒
  }

  function getExpirationTimeFromAddress(address sender) public view returns(uint256) { //受益人或任何人輸入地址查看該地址的截止時間
    if( !DMS_data[sender].isValue) revert("does not exist"); // does not exist  //檢查輸入的地址有沒有合約在。

    return DMS_data[sender].expiration_time;   //透過sender的地址 得到截止日 只能得到unix的時間戳記 這個透過web3.js直接從前端改比較方便 solidity的時間包很爛
  }

  function getExpirationTime() public view returns(uint256) { //sender自己查看截止日期
    if( !DMS_data[msg.sender].isValue) revert("does not exist"); // does not exist

    return DMS_data[msg.sender].expiration_time;  //sender檢查截止日
  }

  function isAddressExpired(address sender) public view returns (bool) { //受益人或sender檢查合約是否過期
    if( !DMS_data[sender].isValue) revert("does not exist"); // does not exist 

    return now >= DMS_data[sender].expiration_time; //查看現在時間有沒有超過截止日
    
  }

  function getDataFromAddress(address sender) public view returns (string) { //受益人或任何人得到data
    
    if( !DMS_data[sender].isValue) revert("does not exist"); // does not exist 看address有沒有被註冊過

    if ((msg.sender != DMS_data[sender].trustees) || !isAddressExpired(sender)) revert("you can't get that"); //如果不是受益人的話revert u can't get that

    //或者過期你都不能拿到秘密
    return DMS_data[sender].data; //合約使用者是受益人的話 得到string的data
  }

}