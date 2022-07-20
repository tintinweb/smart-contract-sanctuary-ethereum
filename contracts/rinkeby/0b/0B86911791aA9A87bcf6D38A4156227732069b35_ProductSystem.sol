// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ProductSystem{
    struct Product{//产品生产信息
        string name; //产品名称
        uint256 num;//库存量
        string key;//
        uint256 date;//生产时间
        address producter;//生产厂商
    }
    mapping(uint256=>Product) public products;  //产品数组

    struct Warehouse{//仓库
        string product_name;//产品名称
        string product_key;//批号
        uint256 num;//库存量
        uint256 price;//价格
    }

    struct Message{//流通信息
        address seller;//卖方
        address buyer;//买方
        uint256 time;//交易日期
        uint256 num;//数量
        string product_key;//批号
    }
    struct Role{//角色
        string name;//名称
        uint256 typ;//角色类型:0消费者,1商店,2批发商,3生产商,4监管部门
        uint256 flag;//可操作标记(0不可操作;1可以操作)
        uint256 warehouse_id;
        uint256 message_id;
        mapping(uint256=>Warehouse) warehouses;//仓库数据
        mapping(uint256=>Message) messages;//购买记录
    }
    struct User{//昵称与地址的映射
        string name;
        address add;
    }

    struct Report{//举报信息
        address people;//举报人
        string product_key;//产品批号
    }

    uint256 product_id;//批号的基准值
    uint256 report_id;//举报信息的基准值

    uint256 public user_id;//账户的基准值

    mapping(address=>Role) public roles;
    mapping(uint256=>Report) public reports;
    mapping(uint256=>User) public users;

    event roleRegisterLog(string key);
    event productCreateLog(string key);
    event transactionLog(string key);
    event reporting_key(bool key);
    event accountLog(string key);
 


    // function Productsystem() public{//初始化
    //     product_id=0;
    //     report_id=0;
    //     userid=0;
    // }

    constructor(){
        product_id=0;
        report_id=0;
        user_id=0;
    }

    //查询用户地址
    function userQuery(string memory username) public view returns(address){
        uint256 i;
        for(i=0;i<user_id;i++){
            //如何没有重复把当前昵称和地址绑定
            if(compare(username,users[i].name)){
                return users[i].add;
            }
        }
        return msg.sender;
    }

    //注册角色
    function roleRegister(string memory userName,uint256 _type) public returns(bool)
    {
        uint256 i;
        //1可以操作
        if(roles[msg.sender].flag==1){
            emit roleRegisterLog("Role does not allow operation.");
            return false;
        }

        for(i=0;i<user_id;i++){
            if(compare(userName,users[i].name)){
                emit roleRegisterLog("User name already exists.");
                return false;
            }
        }
        users[user_id].name=userName;
        users[user_id].add=msg.sender;
        user_id++;

        roles[msg.sender].name=userName;
        roles[msg.sender].typ=_type;
        roles[msg.sender].flag=1;
        roles[msg.sender].warehouse_id=0;
        roles[msg.sender].message_id=0;

        emit roleRegisterLog("Register role success");
        return true;
    }



    //生产产品:可以是 1商店,2批发商,3生产商
    function productCreate(string memory productName,uint256 _num,string memory _key)public returns(bool){
        uint256 w_key;

        //消费者角色不允许生产商品
        require(roles[msg.sender].typ==0,"Error,role is not manufacturer!");

        require(roles[msg.sender].flag==0,"Error,role does not allow operation!");
        uint256 i;
        for(i=0;i<product_id;i++){
            if(compare(_key,products[i].key)){
                emit productCreateLog("Error,product key already exists.");
                return false;
            }
        }
        products[product_id].name=productName;
        products[product_id].num=_num;
        products[product_id].key=_key;
        products[product_id].date=block.timestamp;
        products[product_id].producter=msg.sender;
        product_id=product_id+1;

        //添加库存
        w_key=roles[msg.sender].warehouse_id;
        roles[msg.sender].warehouses[w_key].product_name=productName;
        roles[msg.sender].warehouses[w_key].product_key=_key;
        roles[msg.sender].warehouses[w_key].num=_num;
        roles[msg.sender].warehouses[w_key].price=0;
        roles[msg.sender].warehouse_id++;
        emit productCreateLog("Product create success.");

        return true;
    }

    /*根据产品数组下标查询产品信息*/
    function productQueryByIndex(uint256 _index) public view returns(string memory,string memory,uint256,uint256,address){
         require(_index > product_id,"Error,product id does not exist!");
         if(_index<=product_id)return (
            products[_index].name,
            products[_index].key,
            products[_index].num,
            products[_index].date,
            products[_index].producter
        );
    }

    //监管者查询仓库中某产品的数量
    function managementQueryProductNum(address account,string memory productName) public view returns (uint256){
        uint256 sum=0;
        uint256 i;
        require(roles[msg.sender].typ!=4,"Error,role is not regulator!");

        for(i=0;i<roles[account].warehouse_id;i++){
            if(compare(productName,roles[account].warehouses[i].product_name)){
                sum+=roles[account].warehouses[i].num;
            }
        }
        return sum;
    }

    //查询本人仓库中某产品的数量
    function queryProductNum(string memory productName) public view returns (uint256){
        uint256 sum=0;
        uint256 i;
        for(i=0;i<roles[msg.sender].warehouse_id;i++){
            if(compare(productName,roles[msg.sender].warehouses[i].product_name)){
                sum+=roles[msg.sender].warehouses[i].num;
            }
        }
        return sum;
    }


    //产品流通
    function transactionProduct(address _from,address to,string memory productName,string memory productKey,uint256 _price) public returns(bool){
        uint256 i;
        uint256 j;
        uint256 w_key;
        uint256 m_key;

        if(roles[_from].typ==4 || roles[to].typ==4){
            emit transactionLog("Error,no transactions are allowed between manufacturers!");
            return false;
        }
        if(_from!=msg.sender){
            emit transactionLog("Error,from address must be sender");
            return false;
        }
        if(roles[_from].flag==0){
            emit transactionLog("Error,role does not allow operation!");
            return false;
        }


        for(i=0;i<roles[_from].warehouse_id;i++){
            if(compare(productKey,roles[_from].warehouses[i].product_key)){
                if(!compare(roles[_from].warehouses[i].product_name,productName)){
                    emit transactionLog("Error,product name already exists.");
                    return false;
                }
                w_key=roles[to].warehouse_id;//将交易产品的信息写入买方的仓库
                roles[to].warehouses[w_key].product_name=productName;
                roles[to].warehouses[w_key].product_key=productKey;
                roles[to].warehouses[w_key].price=_price;
                roles[to].warehouses[w_key].num=roles[_from].warehouses[i].num;
               
                for(j=i;j<roles[_from].warehouse_id-1;j++){//从卖方仓库中删除交易产品的信息
                    roles[_from].warehouses[j].product_name=roles[_from].warehouses[j+1].product_name;
                    roles[_from].warehouses[j].product_key= roles[_from].warehouses[j+1].product_key;
                    roles[_from].warehouses[j].num=roles[_from].warehouses[j+1].num;
                    roles[_from].warehouses[j].price=roles[_from].warehouses[j+1].price;
                }
                roles[to].warehouse_id++;
                roles[_from].warehouse_id--;
                m_key=roles[to].message_id;//交易信息写入买方的交易信息数组
                roles[to].messages[m_key].seller=_from;
                roles[to].messages[m_key].buyer=to;
                roles[to].messages[m_key].time=block.timestamp;
                roles[to].messages[m_key].num=roles[to].warehouses[w_key].num;
                roles[to].messages[m_key].product_key=productKey;
                roles[to].message_id++;
                emit transactionLog("transaction success.");
                return true;
            }
        }
        emit transactionLog("Error,transaction fail!");
        return false;
    }

   

    //查询产品交易信息链
    function transactionQuery(address account,string memory productKey) public returns (string memory){
        uint256 i;
        string memory results;
        results="";
        if(roles[account].flag==0){
            return "error,account is flag 0!";
        }
        if(0==roles[account].typ){
            results=roles[account].name;
            return results;
        }
        for(i=0;i<roles[account].message_id;i++){
            if(compare(productKey,roles[account].messages[i].product_key)){
                results=transactionQuery(roles[account].messages[i].seller,productKey);
                break;
            }
        }
        if(i==roles[account].message_id){
            return "errer!!!";
        }
        results=strConcat("<=",results);
        results=strConcat(roles[account].name,results);
        return results;
    }



    

    //根据交易下标查询消费记录
    function messageQueryByIndex(uint256 _int) public view returns(address,address,uint256,uint256,string memory){
        require(_int >= roles[msg.sender].message_id,"error,messages id is null!");
       if(_int<roles[msg.sender].message_id)
            return (
                roles[msg.sender].messages[_int].seller,
                roles[msg.sender].messages[_int].buyer,
                roles[msg.sender].messages[_int].time,
                roles[msg.sender].messages[_int].num,
                roles[msg.sender].messages[_int].product_key
      );
    }

    //根据仓库下标返回仓库信息
    function warehouseQueryByIndex(uint256 _int) public view returns(string memory,string memory,uint256,uint256){
        require(_int >= roles[msg.sender].warehouse_id,"error,warehouse id is null!");
        if(_int<roles[msg.sender].warehouse_id)
            return (
                roles[msg.sender].warehouses[_int].product_name,
                roles[msg.sender].warehouses[_int].product_key,
                roles[msg.sender].warehouses[_int].num,
                roles[msg.sender].warehouses[_int].price
            );
       
    }


    //消费者提交举报信息
    function submitReport(address _account,string memory productKey)public returns(bool){
        if(_account!=msg.sender){
            emit reporting_key(false);
            return false;
        }
        else
        {
            reports[report_id].people=_account;
            reports[report_id].product_key=productKey;
            report_id++;
        }
        emit reporting_key(true);
        return true;
    }





    //处理举报信息
    function processReport(address _account) public returns(string memory){
        uint256 i;
        uint256 j;
        string memory results;

        if(roles[msg.sender].typ!=4){
            emit accountLog("Error,role is not regulator!");
            return "Error,role is not regulator!";
        }

        for(i=report_id-1;i>=0;i--){
            if(_account==reports[i].people){
                results=transactionQuery(reports[i].people,reports[i].product_key);
                for(j=i;j<report_id-1;j++){
                    reports[j].people=reports[j+1].people;
                    reports[j].product_key=reports[j+1].product_key;
                }
                report_id--;
                break;
            }
        }
        return results;
    }

    //处理违规账户
    function stopAccount(address _account)public returns(bool){

        if(roles[msg.sender].typ!=4){
            emit accountLog("Error,role is not regulator");
            return false;
        }

        //停用违规账户
        roles[_account].flag=0;
        emit accountLog("Stop account success.");
        return true;
    }

    
    //恢复违规账户
    function startAccount(address _account)public returns(bool){
        if(roles[msg.sender].typ!=4){
            emit accountLog("Error,role is not regulator");
            return false;
        }
        //恢复违规账户
        roles[_account].flag=1;
        emit accountLog("Start account success.");
        return true;
    }


    //----------------------------private--------------------------
     //字符串拼接
    function strConcat(string memory _a, string memory _b) private returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        /*
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++){
            bret[k++] = _ba[i];
        } 

        for (uint256 i = 0; i < _bb.length; i++){
            bret[k++] = _bb[i];
        }*/
        return string(ret);
    }


     //判断字符串是否相等
    function compare(string memory _a,string memory _b) private view returns(bool){
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint256 i = 0; i < a.length; i ++)
            if (a[i] != b[i])
                return false;
        return true;
    }

}