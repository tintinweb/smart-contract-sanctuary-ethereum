// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ProductSystem{

    enum RoleType { //角色类型:0消费者,1商店,2批发商,3生产商,4监管部门
        consumer,
        shop,
        wholesaler,
        manufacturer,
        regulator
    }

    struct Product{//产品生产信息
        string name; //产品名称
        uint256 num;//产品数量
        string  key;//产品唯一关键值
        uint256 date;//生产时间
        address producter;//生产厂商
    }

    mapping(uint256=>Product) public products;  //产品数组

    struct Warehouse{//仓库
        string key;//批号
        uint256 num;//库存量
        uint256 price;//价格
    }

    struct Message{//流通信息
        address seller;//卖方
        address buyer;//买方
        uint256 time;//交易日期
        uint256 num;//数量
        string key;//批号
        string descprition;//流通说明
    }

    struct Role{//角色
        string name;//名称
        RoleType typ;//
        uint256 flag;//可操作标记(0不可操作;1可以操作)
        uint256 warehouseCount; //仓库数量
        uint256 messageCount;//流通次数
        mapping(uint256=>Warehouse) warehouses;//仓库数据
        mapping(uint256=>Message) messages;//购买记录
    }

    struct User{//昵称与地址的映射
        string username;
        string nickname;//昵称
        address add;
    }

    struct Report{//举报信息
        address people;//举报人
        string product_key;//产品批号
    }

    uint256 productCount;//批号的基准值
    uint256 reportCount;//举报信息的基准值
    uint256 userCount;//账户的基准值

    mapping(address=>Role) public roles;
    mapping(uint256=>Report) public reports;
    mapping(uint256=>User) public users;

    event outLog(string key);
 
    //初始化
    constructor(){
        productCount=0;
        reportCount=0;
        userCount=0;
    }

    //查询用户地址
    function userQuery(string memory username) public view returns(address){
        uint256 i;
        for(i=0;i<userCount;i++){ //遍历所有用户直到找到为止
            //如何没有重复把当前昵称和地址绑定
            if(compare(username,users[i].username)){
                return users[i].add;
            }
        }
        return msg.sender;
    }

    //注册角色
    function roleRegister(string memory _username,string memory _nickname,RoleType _type) public returns(bool)
    {
        uint256 i;
        //1可以操作
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
        roles[msg.sender].warehouseCount=0; //仓库计数器
        roles[msg.sender].messageCount=0;//流通计数器
        emit outLog("Register role success");
        return true;
    }



    //生产产品:可以是 1商店,2批发商,3生产商
    function productCreate(string memory _productName,
        uint256 _num,
        uint256 _price,
        string memory _key,string memory _descprition)public returns(bool){
        uint256 w_key;
        uint256 m_key;
 
        //消费者角色不允许生产商品
        if(roles[msg.sender].typ == RoleType.consumer){
            emit outLog("Error,role is not manufacturer!");
            return false;
        }

        if(roles[msg.sender].typ==RoleType.consumer){
            emit outLog("Error,role does not allow operation!");
            return false;
        }

        uint256 i;
        for(i=0;i<productCount;i++){//遍历所有的产品数组
            if(compare(_key,products[i].key)){ //如何有重复返回false
                emit outLog("Error,product key already exists.");
                return false;
            }
        }

        products[productCount].name=_productName;
        products[productCount].num=_num;
        products[productCount].key=_key;
        products[productCount].date=block.timestamp;
        products[productCount].producter=msg.sender;
        productCount=productCount+1;

        //添加库存
        w_key=roles[msg.sender].warehouseCount;
        roles[msg.sender].warehouses[w_key].key=_key;
        roles[msg.sender].warehouses[w_key].num=_num;
        roles[msg.sender].warehouses[w_key].price=_price;
        roles[msg.sender].warehouseCount++;

        //添加流通数据
        m_key=roles[msg.sender].messageCount;
        roles[msg.sender].messages[m_key].buyer=msg.sender;
        roles[msg.sender].messages[m_key].time=block.timestamp;
        roles[msg.sender].messages[m_key].num=_num;
        roles[msg.sender].messages[m_key].key=_key;
        roles[msg.sender].messages[m_key].descprition=_descprition;
        roles[msg.sender].messageCount++;
        emit outLog("Product create success.");

        return true;
    }

    /*根据产品数组下标查询产品信息*/
    function productQueryByIndex(uint256 _index) public view returns(Product memory){
        require(_index < productCount,"Error,product id does not exist!");
         Product memory product;
         if(_index<productCount){
            product =products[_index];     
         }
         return product; 
    }

     

    //监管者查询仓库中某产品的数量
    function managementQueryProductNum(address _account,string memory _key) public view returns (uint256){
        uint256 sum=0;
        uint256 i;
        require(roles[_account].typ==RoleType.regulator,"Error,role is not regulator!");
        for(i=0;i<roles[_account].warehouseCount;i++){
            if(compare(_key,roles[_account].warehouses[i].key)){
                sum+=roles[_account].warehouses[i].num;
            }
        }
        return sum;
    }

    //查询本人仓库中某产品的数量
    function queryProductNum(address _account,string memory _key) public view returns (uint256){
        uint256 sum=0;
        uint256 i;
        for(i=0;i<roles[_account].warehouseCount;i++){
            if(compare(_key,roles[_account].warehouses[i].key)){
                sum+=roles[_account].warehouses[i].num;
            }
        }
        return sum;
    }


    //产品流通
    function tradeProduct(address _from,address _to, 
    string memory _productKey,
    string memory _descprition,
    uint256 _price
    ) external returns(bool){
        uint256 i;
        uint256 j;
        uint256 w_key;
        uint256 m_key;

        if(roles[_from].typ==RoleType.regulator || roles[_to].typ==RoleType.regulator){
            emit outLog("Error,no transactions are allowed between manufacturers!");
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
            if(compare(_productKey,roles[_from].warehouses[i].key)){
                
                w_key=roles[_to].warehouseCount;//将交易产品的信息写入买方的仓库
                roles[_to].warehouses[w_key].key=_productKey;
                roles[_to].warehouses[w_key].price=_price;
                roles[_to].warehouses[w_key].num=roles[_from].warehouses[i].num;
               
                for(j=i;j<roles[_from].warehouseCount-1;j++){//从卖方仓库中删除交易产品的信息
                    roles[_from].warehouses[j].key= roles[_from].warehouses[j+1].key;
                    roles[_from].warehouses[j].num=roles[_from].warehouses[j+1].num;
                    roles[_from].warehouses[j].price=roles[_from].warehouses[j+1].price;
                }
                roles[_to].warehouseCount++;
                roles[_from].warehouseCount--;
                m_key=roles[_to].messageCount;//交易信息写入买方的交易信息数组
                roles[_to].messages[m_key].seller=_from;
                roles[_to].messages[m_key].buyer=_to;
                roles[_to].messages[m_key].time=block.timestamp;
                roles[_to].messages[m_key].num=roles[_to].warehouses[w_key].num;
                roles[_to].messages[m_key].key=_productKey;
                roles[_to].messages[m_key].descprition=_descprition;
                roles[_to].messageCount++;
                emit outLog("Transaction success.");
                return true;
            }
        }
        emit outLog("Error,transaction fail!");
        return false;
    }


    //根据产品唯一关键值查询产品交易信息链
    function inquire(address _account,string memory _key) public view returns (string memory){
        uint256 i;
        string memory results;

        if(roles[_account].flag==0){
            return results;
        }
        /*
                if(roles[_account].typ==RoleType.consumer){
                    results=roles[_account].name;
                    return results;
                }
        */
        //查询生产商
        for(i=0; i<roles[_account].messageCount; i++){
           if(compare(_key,roles[_account].messages[i].key)){  
                if(roles[_account].messages[i].seller != _account){
                   results=inquire(roles[_account].messages[i].seller,_key);
                }else{
                   results=roles[_account].messages[i].descprition;
                   break;
                }
            }
        }
       /*
        if(roles[_account].messageCount==i){
            return "errer!!!";
        }
        */
        results=strConcat("<=",results);
        results=strConcat(roles[_account].name,results);
        return results;
    }


    //根据交易下标查询消费记录
    function messageQueryByIndex(address _account,uint256 _index) public view returns(Message memory){
    require(_index < roles[_account].messageCount,"error,_index>=message count!");
    Message memory message;
     if(_index<roles[_account].messageCount){
           message=roles[_account].messages[_index];
       }
     return message;
    }

    //根据仓库下标返回仓库信息
    function warehouseQueryByIndex(address _account,uint256 _index) public view returns(Warehouse memory){
        require(_index < roles[_account].warehouseCount,"error,_index>=warehouse count!");
        Warehouse memory warehouse;
        if(_index<roles[_account].warehouseCount) { 
            warehouse=roles[_account].warehouses[_index];
        } 
       return warehouse;
    }


    //消费者提交举报信息
    function submitReport(address _account, string memory productKey)public returns(bool){
        if(_account!=msg.sender){
            emit outLog("Error,can't report yourself!");
            return false;
        } else {
            reports[reportCount].people=_account;
            reports[reportCount].product_key=productKey;
            reportCount++;
        }
        emit outLog("Report success.");
        return true;
    }





    //处理举报信息
    function processReport(address _account) public returns(string memory){
        uint256 i;
        uint256 j;
        string memory results;

        if(roles[msg.sender].typ!=RoleType.regulator){
            emit outLog("Error,role is not regulator!");
            return "Error,role is not regulator!";
        }

        for(i=reportCount-1;i>=0;i--){
            if(_account==reports[i].people){
                results=inquire(reports[i].people,reports[i].product_key);
                for(j=i;j<reportCount-1;j++){
                    reports[j].people=reports[j+1].people;
                    reports[j].product_key=reports[j+1].product_key;
                }
                reportCount--;
                break;
            }
        }
        return results;
    }

    //处理违规账户
    function stopAccount(address _account)public returns(bool){

        if(roles[msg.sender].typ!=RoleType.regulator){
            emit outLog("Error,role is not regulator");
            return false;
        }

        //停用违规账户
        roles[_account].flag=0;
        emit outLog("Stop account success.");
        return true;
    }

    
    //恢复违规账户
    function startAccount(address _account)public returns(bool){
        if(roles[msg.sender].typ!=RoleType.regulator){
            emit outLog("Error,role is not regulator");
            return false;
        }
        //恢复违规账户
        roles[_account].flag=1;
        emit outLog("Start account success.");
        return true;
    }


    //----------------------------private--------------------------
     //字符串拼接
    function strConcat(string memory _a, string memory _b) public view returns (string memory){
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
        }/**/
        return string(bret);
    }


     //判断字符串是否相等
    function compare(string memory _a,string memory _b) private view returns(bool){
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

}