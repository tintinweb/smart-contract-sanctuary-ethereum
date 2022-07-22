// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ProductSystem{

    enum RoleType {
        consumer,
        shop,
        wholesaler,
        manufacturer,
        regulator
    }

    struct Product{
        string name;
        string unit;
        string descprition;
        string key;
        uint256 num;
        uint256 date;
        address producter;
    }

    mapping(uint256=>Product) public products;

    struct Warehouse{
        string key;
        uint256 stock;
    }

    struct Message{
        address seller;
        address buyer;
        uint256 time;
        uint256 num;
        uint256 price;
        string key;
        string operation;
    }

    struct Role{
        string name;
        RoleType typ;
        uint256 flag;
        uint256 warehouseCount;
        uint256 messageCount;
        mapping(uint256=>Warehouse) warehouses;
        mapping(uint256=>Message) messages;
    }

    struct User{
        string username;
        string nickname;
        address add;
    }

    struct Report{
        address people;
        string key;
        string content;
    }

    uint256 public productCount;
    uint256 public reportCount;
    uint256 public userCount;

    mapping(address=>Role) public roles;
    mapping(uint256=>Report) public reports;
    mapping(uint256=>User) public users;

    event outLog(string key);

    constructor(){
        productCount=0;
        reportCount=0;
        userCount=0;
    }

    function getUserByUsername(string memory username) public view returns(User memory){
      User memory user;
        for(uint256 i=0;i<userCount;i++){
            if(compare(username,users[i].username)){
                user=users[i];
            }
        }
        return user;
    }

    function roleRegister(string memory _username,string memory _nickname,RoleType _type) public returns(bool)
    {
        uint256 i;
        if(roles[msg.sender].flag==1){
            emit outLog("Role does not allow operation.");
            return false;
        }

        for(i=0;i<userCount;i++){
            if(compare(_username,users[i].username)){
                emit outLog("User name already exists.");
                return false;
            }
        }
        users[userCount].username=_username;
        users[userCount].nickname=_nickname;
        users[userCount].add=msg.sender;
        userCount++;

        string memory rolename;
        if(_type==RoleType.consumer){
            rolename=strConcat("consumerRole-",_nickname);
        }else if(_type==RoleType.shop){
            rolename=strConcat("shopRole-",_nickname);
        }else if(_type==RoleType.wholesaler){
            rolename=strConcat("wholesalerRole-",_nickname);
        }else if(_type==RoleType.manufacturer){
            rolename=strConcat("manufacturerRole-",_nickname);
        }else{
         rolename=strConcat("regulatorRole-",_nickname);
     }

     roles[msg.sender].name=rolename;
     roles[msg.sender].typ=_type;
     roles[msg.sender].flag=1;
     roles[msg.sender].warehouseCount=0;
     roles[msg.sender].messageCount=0;
     emit outLog("Register role success");
     return true;
 }



 function createProduct(
    string memory _key,
    string memory _productName,
    uint256 _price,
    uint256 _num,
    string memory _unit,
    string memory _descprition,
    string memory _operation)public returns(bool){
        uint256 w_key;
        uint256 m_key;
        if(roles[msg.sender].typ == RoleType.consumer){
            emit outLog("Error,role is not manufacturer!");
            return false;
        }

        if(roles[msg.sender].flag==0){
            emit outLog("Error,role does not allow operation!");
            return false;
        }

        uint256 i;
        for(i=0;i<productCount;i++){
            if(compare(_key,products[i].key)){
                emit outLog("Error,product key already exists.");
                return false;
            }
        }

        products[productCount].name=_productName;
        products[productCount].key=_key;
        products[productCount].num=_num;
        products[productCount].unit=_unit;
        products[productCount].descprition=_descprition;
        products[productCount].date=block.timestamp;
        products[productCount].producter=msg.sender;
        productCount=productCount+1;


        m_key=roles[msg.sender].messageCount;
        roles[msg.sender].messages[m_key].buyer=msg.sender;
        roles[msg.sender].messages[m_key].time=block.timestamp;
        roles[msg.sender].messages[m_key].num=_num;
        roles[msg.sender].messages[m_key].price=_price;
        roles[msg.sender].messages[m_key].key=_key;
        roles[msg.sender].messages[m_key].operation=_operation;
        roles[msg.sender].messageCount++;

        w_key=roles[msg.sender].warehouseCount;
        roles[msg.sender].warehouses[w_key].key=_key;
        roles[msg.sender].warehouses[w_key].stock=_num;
        roles[msg.sender].warehouseCount++;
        emit outLog("Product create success.");

        return true;
    }
    function getProductByIndex(uint256 _index) public view returns(Product memory){
        require(_index < productCount,"Error,product id does not exist!");
        Product memory product;
        if(_index<productCount){
            product =products[_index];     
        }
        return product; 
    }

    function getProductBykey(address _account,string memory _key) public view returns (Product memory){
        uint256 i;
        Product memory product;
        for(i=0;i<roles[_account].warehouseCount;i++){
            if(compare(_key,roles[_account].warehouses[i].key)){
                product=products[i]; 
            }
        }
        return product;
    }

    function getMessageLinksByKey(address _account,string memory _key) public view returns (string memory){
        uint256 i;
        string memory results;

        if(roles[_account].flag==0){
            return results;
        }
        for(i=0; i<roles[_account].messageCount; i++){
         if(compare(_key,roles[_account].messages[i].key)){  
            if(roles[_account].messages[i].seller != _account){
             results=getMessageLinksByKey(roles[_account].messages[i].seller,_key);
         }else{
             results=roles[_account].messages[i].operation;
             break;
         }
        }
        }
        results=strConcat("<=",results);
        results=strConcat(roles[_account].name,results);
        return results;
    }


    function tradeProduct(
        address _from,
        address _to, 
        string memory _key,
        string memory _operation,
        uint256 _price,
        uint256 _num
    ) external returns(bool){
        uint256 i;
        uint256 j;
        uint256 w_key;
        uint256 m_key;

        if(roles[_from].typ==RoleType.regulator || roles[_to].typ==RoleType.regulator){
            emit outLog("Error,receiver or sender not regulator!");
            return false;
        }
        if(_from!=msg.sender){
            emit outLog("Error,from address must be sender");
            return false;
        }
        if(roles[_from].flag==0){
            emit outLog("Error,role does not allow operation!");
            return false;
        }

        for(i=0;i<roles[_from].warehouseCount;i++){


            if(compare(_key,roles[_from].warehouses[i].key)){
                uint256 thisStock=roles[_from].warehouses[i].stock;
                if(_num>thisStock){
                    emit outLog("Error,Not enough stock!");
                    return false;
                }

            bool findWarehouse=buyerWarehouse(_to,_key,_num);
             if(!findWarehouse){ 
                w_key=roles[_to].warehouseCount;
                roles[_to].warehouses[w_key].key=roles[_from].warehouses[i].key;
                roles[_to].warehouses[w_key].stock=_num;
                roles[_to].warehouseCount++;
            }

            roles[_from].warehouses[i].stock=roles[_from].warehouses[i].stock-_num;
            if(_num==thisStock){
                for(j=i;j<roles[_from].warehouseCount-1;j++){
                    roles[_from].warehouses[j].key= roles[_from].warehouses[j+1].key;
                    roles[_from].warehouses[j].stock=roles[_from].warehouses[j+1].stock;
                }
                roles[_from].warehouseCount--;
            }

            m_key=roles[_to].messageCount;
            roles[_to].messages[m_key].seller=_from;
            roles[_to].messages[m_key].buyer=_to;
            roles[_to].messages[m_key].time=block.timestamp;
            roles[_to].messages[m_key].num=_num;
            roles[_to].messages[m_key].price=_price;
            roles[_to].messages[m_key].key=roles[_from].warehouses[i].key;
            roles[_to].messages[m_key].operation=_operation;
            roles[_to].messageCount++;
            emit outLog("Transaction success.");
            return true;
        }
    }
    emit outLog("Error,transaction fail!");
    return false;
}

function getMessageByIndex(address _operator,uint256 _index) external view returns(Message memory){
    require(_index < roles[_operator].messageCount,"error,_index>=message count!");
    Message memory message;
    if(_index<roles[msg.sender].messageCount){
     message=roles[msg.sender].messages[_index];
 }
 return message;
}

function getWarehouseByIndex(address _operator,uint256 _index) external view returns(Warehouse memory){
    require(_index < roles[_operator].warehouseCount,"error,_index>=warehouse count!");
    Warehouse memory warehouse;
    if(_index<roles[_operator].warehouseCount) { 
        warehouse=roles[_operator].warehouses[_index];
    } 
    return warehouse;
}

function getWarehouseStock(address _operator,string memory _key) public view returns(uint256){
    uint256 i;
    uint256 j;
    uint256 sum=0;
    require(roles[_operator].typ==RoleType.regulator,"Error,role of the operator must be regulator!");
    for(i=0; i<userCount; i++){
        //取得地址
        address add=users[i].add;
        for(j=0; j<roles[add].warehouseCount; j++){//遍历所有仓库
            if(compare(_key,roles[add].warehouses[j].key)){
                sum=sum+roles[add].warehouses[j].stock;
            }
        }
    }
    return sum;
}

function submitReport(address _account, string memory _key,string memory _content)public returns(bool){
    if(_account==msg.sender){
        emit outLog("Error,can't report yourself!");
        return false;
    } else {
        reports[reportCount].people=_account;
        reports[reportCount].key=_key;
        reports[reportCount].content=_content;
        reportCount++;
    }
    emit outLog("Report success.");
    return true;
}


function getReport(address _reporter) public view returns(Report memory){
    Report memory report;
    for(uint256 i=0; i<reportCount;i++){
        if(_reporter==reports[i].people){
            report=reports[i];
        }
    }
    return report;
}


function deleteReport(address _operator, address _reporter) public returns(bool){
   
    uint256 i;
    uint256 j;
    if(roles[_operator].typ!=RoleType.regulator){
        emit outLog("Error,role of the operator must be regulator!");
        return false;
    }
    for(i=reportCount-1;i>=0;i--){
        if(_reporter==reports[i].people){
            for(j=i;j<reportCount-1;j++){
                reports[j].people=reports[j+1].people;
                reports[j].key=reports[j+1].key;
            }
            reportCount--;
            emit outLog("Process report success.");
            return true;
        }
    }
    return false;
}

function stopAccount(address _operator,address _account)public returns(bool){

    if(roles[_operator].typ!=RoleType.regulator){
        emit outLog("Error,role of the operator must be regulator!");
        return false;
    }

    roles[_account].flag=0;
    emit outLog("Stop account success.");
    return true;
}


function startAccount(address _operator,address _account)public returns(bool){
    if(roles[_operator].typ!=RoleType.regulator){
        emit outLog("Error,role of the operator must be regulator!");
        return false;
    }
    roles[_account].flag=1;
    emit outLog("Start account success.");
    return true;
}


//----------------------------private--------------------------
function strConcat(string memory _a, string memory _b) private pure returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ret = new string(_ba.length + _bb.length);
    bytes memory bret = bytes(ret);
    uint256 k = 0;
    for (uint256 i = 0; i < _ba.length; i++){
        bret[k++] = _ba[i];
    } 
    for (uint256 i = 0; i < _bb.length; i++){
        bret[k++] = _bb[i];
    }
    return string(bret);
}


function compare(string memory _a,string memory _b) private pure returns(bool){
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    if (a.length != b.length){
       return false;
   }
   // @todo unroll this loop
   for (uint256 i = 0; i < a.length; i ++){
    if (a[i] != b[i]){
        return false;
    }     
}
return true;
}

function buyerWarehouse(address _to , string memory _key,uint256 _num) private returns(bool){
    for(uint256 i = 0; i<roles[_to].warehouseCount; i ++){
        if(compare(_key,roles[_to].warehouses[i].key)){
            roles[_to].warehouses[i].stock=roles[_to].warehouses[i].stock+_num;
            return true;
        }
    }
    return false;
}

}