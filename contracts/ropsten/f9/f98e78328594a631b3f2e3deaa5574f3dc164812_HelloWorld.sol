/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

//声明版本号
pragma solidity 0.8.10;

//合约 有点类似于java中的class
contract HelloWorld{
    //合约属性变量
    string myName = "HelloWorld";
    //合约中方法 注意语法顺序 其中此处view 代表方法只读 不会消耗gas
    function getName() public view returns(string memory){
        return myName;
    }
    //可以修改属性变量的值 消耗gas
    function changeName(string memory _newName) public{
        myName = _newName;
    }
    // pure:不能读取也不能改变状态变量
    function pureName(string memory _name) public pure returns(string memory){
        return _name;
    }
}