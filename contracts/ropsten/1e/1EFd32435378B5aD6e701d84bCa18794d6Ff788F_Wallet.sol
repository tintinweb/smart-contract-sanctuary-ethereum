/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

/**
* MIT License
* 
* Copyright (c) 2022 Giant Shiba Inu
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
* 
* @title Wallet Contract | Binance Smart Chain [Mainnet]
* 
* @author       Name : Rajesh Kumar Roy
*            Country : The Republic of India
*           Email ID : [email protected]
*            Twitter : https://twitter.com/exploroy
*           Telegram : https://t.me/exploroy
* 
* @notice This wallet contract is protected by username and password, unlike
*         private key/recovery phrase
* 
* @dev Only the owner of this contract can add/remove new tarnsaction signer but 
*      for adding the second security layer the transaction signer have to set 
*      his/her username and password, there is no limit in number of transaction
*      signer and the transaction signer can change his/her username and password
*      whenever he/she want but this may cost gas fee of the particular EVM
*      blockchain
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface iToken
{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address account, uint256 amount) external returns (bool);
}

contract Wallet
{
    event EtherExtracted(address indexed from, address indexed to, uint256 amount, uint256 time);
    event TokenExtracted(address indexed from, address indexed to, uint256 amount, uint256 time);

    address private _owner;

    struct _authData
    {
        string _username;
        string _password;
    }

    mapping(address => _authData) private _authDatabase;
    mapping(address => bool) private _isRegdAddr;

    constructor()
    {
        _owner = msg.sender;
        _isRegdAddr[_owner] = true;
        _authDatabase[_owner]._username = "username"; //Temporary Username
        _authDatabase[_owner]._password = "password"; //Temporary Password
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Permission Denied, You're not the contract owner!");
        _;
    }

    function regAddr(address account) onlyOwner external returns (bool)
    {
        require(_isRegdAddr[account] == false, "Already Registered!");
        _authDatabase[account]._username = "username";
        _authDatabase[account]._password = "password";
        _isRegdAddr[account] = true;
        return true;
    }

    function deRegAddr(address account) onlyOwner external returns (bool)
    {
        require(account != _owner, "Owner can't Resign!");
        require(_isRegdAddr[account] == true, "Not Registered!");
        _authDatabase[account]._username = "";
        _authDatabase[account]._password = "";
        _isRegdAddr[account] = false;
        return true;
    }

    function signUp(string memory tempUsername, string memory tempPassword, string memory newUsername, string memory newPassword) Auth(tempUsername, tempPassword) external returns (bool)
    {
        _authDatabase[msg.sender]._username = newUsername;
        _authDatabase[msg.sender]._password = newPassword;
        return true;
    }

    function changePassword(string memory username, string memory oldPassword, string memory newPassword) Auth(username, oldPassword) external returns (bool)
    {
        _authDatabase[msg.sender]._password = newPassword;
        return true;
    }

    modifier Auth(string memory username, string memory password)
    {
        require(_isRegdAddr[msg.sender] == true, "Permission Denied, You're not a registered user!");
        require(keccak256(abi.encodePacked(username)) == keccak256(abi.encodePacked(_authDatabase[msg.sender]._username)) && keccak256(abi.encodePacked(password)) == keccak256(abi.encodePacked(_authDatabase[msg.sender]._password)), "Permission Denied, Authentication Failed!");
        _;
    }

    receive() external payable {}

    function extractEther(address payable account, uint256 amount, string memory username, string memory password) Auth(username, password) external returns (bool)
    {
        require(address(this).balance > 0, "Zero Balance!");
        require(address(this).balance >= amount, "Low Balance!");
        account.transfer(amount);
        emit EtherExtracted(address(this), account, amount, block.timestamp);
        return true;
    }

    function extractToken(address tokenAddress, address account, uint256 amount, string memory username, string memory password) Auth(username, password) external returns (bool)
    {
        require(iToken(tokenAddress).balanceOf(address(this)) > 0, "Zero Balance!");
        require(iToken(tokenAddress).balanceOf(address(this)) >= amount, "Low Balance!");
        iToken(tokenAddress).transfer(account, amount);
        emit TokenExtracted(address(this), account, amount, block.timestamp);
        return true;
    }
}