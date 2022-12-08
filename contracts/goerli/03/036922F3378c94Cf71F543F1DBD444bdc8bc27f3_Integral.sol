// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Tools {
    function stringToBytes32(string memory source)  internal pure  returns (bytes32 result) {
        //字符串转bytes32
        assembly {
            result := mload(add(source, 32))
        }
    }
    function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
            }
        return string(bytesArray);
    }
}

contract Integral is Tools {
    uint all_integral;
    uint settlement_integral = 0;
    address owner;  // 合约发布者
    
    struct Customer {
        // 消费者
        address addr;  // 消费者账号
        bytes32 passwd;  // 消费者密码
        uint amount; // 账户积分余额
        bytes32[] buy_goods;
    }

    struct Integral_goods {
        bytes32 goodId;
        uint price;
        string goodname;
    }
    mapping (address => Customer) customer;  // 所有用户
    mapping (bytes32 => Integral_goods) integral_goods; // 商品池

    address[] users;  // 注册信息
    bytes32[] public goods; // 商品信息

    modifier onlyOwner(){
        require(msg.sender == owner);  // 限制合约的调用者
        _;
    }

    modifier validWalletOwn(address ownAddress){
        require(msg.sender == ownAddress);  // 判断是否是当前用户钱包
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register(address _useraddr, string memory _password) validWalletOwn(_useraddr) public {
        // 注册账号
        require(!isexistence(_useraddr));
        customer[_useraddr].addr = _useraddr;
        customer[_useraddr].passwd = stringToBytes32(_password);
        users.push(_useraddr);  // 用户数组追加一个用户
    }       

    function isexistence(address customer_addr) internal view returns(bool){
        // 判断是否存在此用户
        for (uint i = 0; i < users.length; i++) 
        {   
            if (users[i] == customer_addr){
                return true;
            }
        }
        return false;
    }

    function SendScore(address receiver, uint number) onlyOwner public {
        // 发送积分
        require(isexistence(receiver), "Account does not exist");  // 保证用户存在
        all_integral += number;
        customer[receiver].amount += number;  // 发送积分成功
    }

    function get_Score(address useraddr) view public returns (uint) {
        // 查看积分
        return customer[useraddr].amount;
    }

    function Score_transfer(address _sender, address _receiver, uint number) validWalletOwn(_sender) public returns(string memory) {
        // 积分交易
        require(isexistence(_receiver), "Destination account does not exist");
        if (customer[_sender].amount >= number) {

            customer[_sender].amount -= number;
            customer[_receiver].amount += number;
            return "transfer success";
        }
        else {
            return "transfer fail";
        }
    }

    function get_all_score() public view returns(uint) {
        // 获取所有的积分
        return all_integral;
    }

    function get_settlement_score() public view returns(uint) {
        // 获取已经清算的积分
        return settlement_integral;
    }

    function grounding(string memory name, uint price) onlyOwner public {
        // 上架商品
        bytes32 goodid = stringToBytes32(name);
        require(!isProductalreadyexists(goodid));  // 判断商品是否存在
        integral_goods[goodid].goodId = goodid;
        integral_goods[goodid].price = price;
        integral_goods[goodid].goodname = name;
        goods.push(goodid);  // 商品池追加此商品
    }

    function isProductalreadyexists(bytes32 _goodId) internal view returns (bool) {
        for (uint i = 0; i < goods.length; i++) {
            if (goods[i] == _goodId) {
                return true;
            }
        }
        return false;
    }

    function buy_Good(address c_addr, string memory name) validWalletOwn(c_addr) public returns (string memory){
        // 商品购买
        bytes32 goodid = stringToBytes32(name);
        require(isProductalreadyexists(goodid));
        if (customer[c_addr].amount < integral_goods[goodid].price) {
            return "Insufficient balance";  // 余额不足
        }
        else {
            customer[c_addr].amount -= integral_goods[goodid].price;
            settlement_integral += integral_goods[goodid].price;
            customer[c_addr].buy_goods.push(goodid);
            return "buy success";
        }
    }

    function GetPurchased(address caddr) view public returns (bytes32[] memory) {
        // 获取用户的购买记录
        return customer[caddr].buy_goods;
    }

    function get_good_list() public view returns(string[] memory, uint[] memory){
        // 获取商品列表
        string[] memory name_list = new string[](goods.length);
        uint[] memory price_list = new uint[](goods.length);
        for(uint i = 0; i < goods.length; i++){
            bytes32 good_id = goods[i];
            name_list[i] = integral_goods[good_id].goodname;
            price_list[i] = integral_goods[good_id].price;
        }
        return (name_list, price_list);
    }
    
}