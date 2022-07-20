// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";

contract ProductSystem{
    struct Product{//产品生产信息
        string name; //产品名称
        uint num;//库存量
        string key;//批号
        uint date;//生产时间
        address producter;//生产厂商
    }
    mapping(uint=>Product) public products;  //产品数组

    struct Warehouse{//仓库
        string product_name;//产品名称
        string product_key;//批号
        uint num;//库存量
        uint price;//价格
    }

    struct Message{//流通信息
        address seller;//卖方
        address buyer;//买方
        uint time;//交易日期
        uint num;//数量
        string product_key;//批号
    }
    struct Role{//角色
        string name;//名称
        uint typ;//角色类型
        uint flag;//可操作标记(0不可操作;1可以操作)
        uint warehouse_id;
        uint message_id;
        mapping(uint=>Warehouse) warehouses;//仓库数据
        mapping(uint=>Message) messages;//购买记录
    }
    struct User{//昵称与地址的映射
        string name;
        address add;
    }

    struct Report{//举报信息
        address people;//举报人
        string product_key;//产品批号
    }

    uint product_id;//批号的基准值
    uint report_id;//举报信息的基准值

    uint public user_id;//账户的基准值

    mapping(address=>Role) public roles;
    mapping(uint=>Report) public reports;
    mapping(uint=>User) public users;

    event enroll_key(bool key);
    event product_production_key(bool key);
    event transaction_key(bool key);
    event reporting_key(bool key);
    event process_account_key(bool key);
    event huifu_account_key(bool key);


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

    //昵称和地址绑定
    function bindUser(string memory username) public view returns(address){
        uint i;
        for(i=0;i<user_id;i++){
            //如何没有重复把当前昵称和地址绑定
            if(compare(username,users[i].name)){
                return users[i].add;
            }
        }
        return msg.sender;
    }

    //注册角色
    function enroll(string memory userName,uint _type) public returns(bool)
    {

        uint i;
        //1可以操作
        if(roles[msg.sender].flag==1){
            emit enroll_key(false);
            return false;
        }

        for(i=0;i<user_id;i++){
            if(compare(userName,users[i].name)){
                emit enroll_key(false);
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

        emit enroll_key(true);
        return true;
    }

    /*根据产品数组下标查询产品名称*/

    function product_inquire(uint i) public returns(string memory){
        string memory results;
        results="product Name:";
        results=strConcat(results,products[i].name);
        return results;
    }

    //生产产品
    function product_production(string memory productName,uint _num,string memory _key,address _producter)public returns(bool){
        uint w_key;
        if(roles[_producter].typ!=0||roles[_producter].flag!=1){
            emit product_production_key(false);
            return false;
        }
        if(_producter!=msg.sender){
            emit product_production_key(false);
            return false;
        }
        uint i;
        for(i=0;i<product_id;i++){
            if(compare(_key,products[i].key)){
                emit product_production_key(false);
                return false;
            }
        }
        products[product_id].name=productName;
        products[product_id].num=_num;
        products[product_id].key=_key;
        products[product_id].date=block.timestamp;
        products[product_id].producter=_producter;

        w_key=roles[_producter].warehouse_id;
        product_id=product_id+1;

        roles[_producter].warehouses[w_key].product_name=productName;
        roles[_producter].warehouses[w_key].product_key=_key;
        roles[_producter].warehouses[w_key].num=_num;
        roles[_producter].warehouses[w_key].price=0;
        roles[_producter].warehouse_id++;
        emit product_production_key(true);
        return true;
    }

    //function product_management_add(address account,Warehouse _ware)public{
    //    roles[account].ware.push(_ware);
    //}


    //判断字符串是否相等
    function compare(string memory _a,string memory _b) public view returns(bool){
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
            if (a[i] != b[i])
                return false;
        return true;
    }

    //监管者查询仓库中某产品的数量
    function product_management_inquire(address account,string memory _name) public returns (uint){
        uint sum=0;
        uint i;
        //检查是否为监管者
        if(roles[msg.sender].typ!=4)
            return sum;
        for(i=0;i<roles[account].warehouse_id;i++){
            if(compare(_name,roles[account].warehouses[i].product_name)){
                sum+=roles[account].warehouses[i].num;
            }
        }
        return sum;
    }

    //查询本人仓库中某产品的数量
    function inquire_product(string memory productName) public returns (uint){
        uint sum=0;
        uint i;
        for(i=0;i<roles[msg.sender].warehouse_id;i++){
            if(compare(productName,roles[msg.sender].warehouses[i].product_name)){
                sum+=roles[msg.sender].warehouses[i].num;
            }
        }
        return sum;
    }

    //产品交易函数
    function transaction(address _from,address to,string memory productName,string memory productKey,uint _price) public returns(bool){
        uint i;
        uint j;
        uint w_key;
        uint m_key;

        if(roles[_from].typ==4||roles[to].typ==4||roles[to].typ==0){
            emit transaction_key(false);
            return false;
        }
        if(_from!=msg.sender){
            emit transaction_key(false);
            return false;
        }
        if(roles[_from].flag==0){
            emit transaction_key(false);
            return false;
        }
        for(i=0;i<roles[_from].warehouse_id;i++){
            if(compare(productKey,roles[_from].warehouses[i].product_key)){
                if(!compare(roles[_from].warehouses[i].product_name,productName)){
                    emit transaction_key(false);
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
                emit transaction_key(true);
                return true;
            }
        }
        emit transaction_key(false);
        return false;
    }

    //字符串拼接
    function strConcat(string memory _a, string memory _b) public returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++){
            bret[k++] = _ba[i];
        } 

        for (uint i = 0; i < _bb.length; i++){
            bret[k++] = _bb[i];
        }
        return string(ret);
    }

    //查询产品交易信息链
    function inquire(address account,string memory productKey) public returns (string memory){
        uint i;
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
                results=inquire(roles[account].messages[i].seller,productKey);
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

    //消费者提交举报信息
    function reporting(address _account,string memory productKey)public returns(bool){
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

    //返回消费记录
    function buyer_inquire_mess(uint _int) public returns(address,address,uint,uint,string memory){
        /*uint i;
        string memory results;
        for(i=0;i<roles[_account].message_id;i++){
            results=strConcat(results,"seller:");
            results=strConcat(results,roles[roles[_account].messages[i].seller].name);
            results=strConcat(results,"   ");
            results=strConcat(results,"buyer:");
            results=strConcat(results,roles[roles[_account].messages[i].buyer].name);
            results=strConcat(results,"   ");
            results=strConcat(results,"key:");
            results=strConcat(results,roles[_account].messages[i].product_key);
            results=strConcat(results,"\n ");
        }*/

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

    //返回仓库信息
    function buyer_inquire_ware(uint _int) public returns(string memory,string memory,uint,uint){
        /*uint i;
        string memory results;
        for(i=0;i<roles[_account].warehouse_id;i++){
            results=strConcat(results,"name:");
            results=strConcat(results,roles[_account].warehouses[i].name);
            results=strConcat(results,"   ");
            results=strConcat(results,"key:");
            results=strConcat(results,roles[_account].warehouses[i].key);
            results=strConcat(results,"\n ");
        }*/


        require(_int >= roles[msg.sender].warehouse_id,"error,warehouse id is null!");


        if(_int<roles[msg.sender].warehouse_id)
            return (
                roles[msg.sender].warehouses[_int].product_name,
                roles[msg.sender].warehouses[_int].product_key,
                roles[msg.sender].warehouses[_int].num,
                roles[msg.sender].warehouses[_int].price
            );
       
    }

    //处理举报信息
    function process_report(address _account) public returns(string memory){
        uint i;
        uint j;
        string memory results;
        require(roles[msg.sender].typ!=4,"error,account role type not is 4!");
        for(i=report_id-1;i>=0;i--){
            if(_account==reports[i].people){
                results=inquire(reports[i].people,reports[i].product_key);
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
    function process_account(address _account)public returns(bool){
        if(roles[msg.sender].typ!=4){
            emit process_account_key(false);
            return false;
        }
        roles[_account].flag=0;
        emit process_account_key(true);
        return true;
    }

    //恢复违规账户
    function huifu_account(address _account)public returns(bool){
        if(roles[msg.sender].typ!=4){
            emit huifu_account_key(false);
            return false;
        }
        roles[_account].flag=1;
        emit huifu_account_key(true);
        return true;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}