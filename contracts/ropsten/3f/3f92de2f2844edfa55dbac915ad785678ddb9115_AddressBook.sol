/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract AddressBook {
    address public owner; 

    struct Student {
        address account;
        string phone;
        string email;
    }
    // mapping 不會知道裡面有多少資料
    mapping (string => Student) studentMap; // id -> student
    string[] idArray; // 學號陣列

    // check only owner can do the following function, otherwise, throw "not owner" exception
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // call when deploy the contract
    constructor() { 
        owner = msg.sender;
    }

    function setOwner( address newOwner) public onlyOwner {
        owner = newOwner;
    }

    // create, address 放在 calldata, 存在時不可新增
    function create( string memory _id, address _account, string memory _phone, string memory _email) public onlyOwner {
        require(_account == address(_account), "Invalid address"); // 強轉型失敗代表 address 無效
        require(studentMap[_id].account == address(0), "ID already exists"); // check duplicate id
        
        studentMap[_id] = Student({ account:_account, phone:_phone, email:_email});
        idArray.push(_id);
    }

    
    // update, 不存在時不能修改
    function update( string memory _id, address _account, string memory _phone, string memory _email) public onlyOwner {
        require(_account == address(_account), "Invalid address");
        require(studentMap[_id].account != address(0), "ID not found");
        
        studentMap[_id] = Student({ account:_account, phone:_phone, email:_email});
    }

    // delete 會和關鍵字衝突
    function destroy(string memory _id) public onlyOwner {
        // 檢查反而會浪費 gas, 因為都要刪除
        (bool find, uint256 index) = getIndexById(_id);
        if(find == true && index >= 0){
            delete studentMap[_id];
            deleteIdByIndex(index);
        }
    }

    // 學生總數
    function total() public view returns(uint256 length) {
        return idArray.length;
    }

    // 依據學號刪除學號資料
    function deleteIdByIndex(uint256 index) private {
        if(index > idArray.length)
            revert("Index error");
        
        for(uint256 i=index; i<idArray.length-1; i++){
            idArray[i] = idArray[i+1];
        }
        idArray.pop();
    }

    // select
    function selectById( string memory _id) public view returns(address _account, string memory _phone, string memory _email){
        return(studentMap[_id].account, studentMap[_id].phone, studentMap[_id].email);
    }

    function getIndexById(string memory _id) private view returns(bool find, uint256 index) {
        for(uint256 i=0; i<idArray.length; i++){
            if(compareStrings(idArray[i], _id) == true)
                return (true, i);
        }
        return (false, 0);
    }

    // 比較雜湊值->固定長度，比較短的字會浪費錢
    function compareStrings(string memory a, string memory b) private pure returns(bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}