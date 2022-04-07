/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

//建立合約
contract AddressBook {
    address  public owner; //將OWNER設置為public變數


    struct Student{ //設置student 框架
        address account; //address 型態變數
        string phone; //STR 型態變數
        string email; //STR 型態變數
    }

    //學號陣列
    string[] idArray;

    //Student排序
    mapping (string=>Student) studentMap; //建立數值(string)與鍵(student)的對應

    //檢查是否為該合約的擁有著
    modifier onlyOwner(){ //使用MODIFIER
        require(owner ==msg.sender,"not only owner");//判斷如果OWNER非為該合約擁有著顯示not only owner
        _;//上面的成立才能做後面的事情
    }

    //設定OWNER變數為使用者帳戶號
    constructor() {  
        owner = msg.sender;
    }

    //轉換owner
    function setOwner(address newOwner) public onlyOwner{
        owner = newOwner;//將newowner設定為合約的OWNER
    }

    //新增學生資料
    function create(string memory _id,address _account,string memory _phone,string memory _email)public onlyOwner{ //透過memory新增類區域變數該變數只能存在該方法中使用
        require(_account == address(_account),"Invalid address");
        require(studentMap[_id].account == address(0),"ID already exists");
        
        studentMap[_id]= Student({ account:_account, phone:_phone,email:_email});
        idArray.push(_id);
    }

    //更新學生資料
    function update(string memory _id,address _account,string memory _phone,string memory _email)public onlyOwner{ //OWNER 才能使用該方法
        require(_account == address(_account),"Invalid address"); //判斷是否有該學生，若無回傳Invalid address
        require(studentMap[_id].account != address(0),"ID not found");//判斷address不為空值或0，如果以上狀況回傳ID not found
        
        studentMap[_id]= Student({ account:_account, phone:_phone,email:_email});//That's update the student data.
    }

    //刪除學生資料
    function destory(string memory _id) public onlyOwner{ //OWNER 才能使用該方法
        (bool find,uint256 index) = getIndexById(_id); //透過FIND 及 INDEX 變數接住getIndexById方法的回傳值
        if(find == true && index>=0){//判斷使否有找到並且是正確的
            delete studentMap[_id];//刪除該學生資料
            deleteIDByIndex(index); //使用方法deleteIDByIndex依據學號刪除學號資料index位置

        }
    }

    //查詢學生資料總數
    function total()public view returns(uint256 length){
        return idArray.length; //目前儲存數
    }
    
    //依據學號刪除學號資料index位置
    function deleteIDByIndex(uint256 index) private{
        if(index >idArray.length) //確定查詢數值使否正確
            revert("Index error");//查詢數值超過目前儲存數

        for(uint256 i = index; i< idArray.length-1 ;i++) { //FOR迴圈
            idArray[i]=idArray[i+1];//後面的資料往前放，刪除(取代)學號資料
        }
        idArray.pop();//刪除最後一個不需要重複的學號資料
    }

    //尋找
    function selectById(string memory _id) public view returns(address _account,string memory _phone,string memory _email) {
        return(studentMap[_id].account,studentMap[_id].phone,studentMap[_id].email);//回傳student資料
    }

    //查詢學生索引
    function getIndexById(string memory _id) private view returns (bool find,uint256 index){
        for(uint256 i=0; i<idArray.length; i++){ //for迴圈尋找正確學號位置索引
            if(compareStrings(idArray[i],_id)==true)//透過compareStrings方法確定學號是否相同
            return (true,i);//回傳該index位置
        }
        return (false,0);//找不到回傳0
    }
    //比較兩者是否一樣
    function compareStrings(string memory a,string memory b) private pure returns(bool){//輸入兩個變數回傳布林值並且因為pure不會影響數值得內容
        return (keccak256 (abi.encodePacked(a))) == keccak256(abi.encodePacked(b));//透過演算法計算兩個學號的雜湊值是否相同來判斷狀況
    }
}