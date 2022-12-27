// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev
 * 아이디와 비밀번호를 확인하는 어플리케이션을 만드려고 합니다.
 * 회원가입은 3가지 input으로 진행됩니다. 현재의 지갑 주소, id 그리고 pw 입니다.
 * 회원가입 여부 확인, 로그인 기능 그리고 로그인 실패시 알려주는 기능을 도입하세요.
 * 현재 회원의 정보를 알려주는 기능도 포함되어야 합니다. 회원 정보는 지갑 주소로 진행하면 됩니다. 
 * 회원 정보는 회원가입 여부, id를 출력하면 됩니다.
 */

contract A {
    /* DB */
    mapping(address => User) UsersMap;
    struct User {
        string username;
        string password;
    }

    /* Create user */
    function setUser(string memory _username, string memory _password) public {
        UsersMap[msg.sender] = User(_username, _password);
    }
    
    /* Read user */
    function getUserName(address _addr) public view returns(string memory) {
        return UsersMap[_addr].username;
    }

    /* Log on */
    function logOn(string memory _username, string memory _password) public view returns(bool) {
        require(
            keccak256(bytes(_username)) == keccak256(bytes(UsersMap[msg.sender].username)) &&
            keccak256(bytes(_password)) == keccak256(bytes(UsersMap[msg.sender].password)),
            "Incorrect username or password"
        );
        return true;
    }
}