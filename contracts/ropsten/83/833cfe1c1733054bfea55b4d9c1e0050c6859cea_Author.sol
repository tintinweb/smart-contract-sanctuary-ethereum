/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity >=0.6.12;

contract Author{

    // 注册作者事件
    event RegisteredAuthor(
        address _author,
        string _url,
        string _name,
        string _introduction
    );
    
    /**
    @dev 管理员有权限的注册作者
     */
    function registeredAuthor(
        address _author,
        string memory _url,
        string memory _name,
        string memory _introduction
    ) public  {
        emit RegisteredAuthor(_author, _url, _name, _introduction);
    }

    
}