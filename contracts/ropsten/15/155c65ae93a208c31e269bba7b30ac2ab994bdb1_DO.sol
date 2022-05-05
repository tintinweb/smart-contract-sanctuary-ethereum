/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity >=0.4.25;
contract DO{
    event SendKey(address from, address to, bytes Key);
    event SendAK1(address from, address to, bytes Key);
    event SendAK2(address from, address to, bytes Key);

    mapping (address => User) public users;
    mapping (string => bytes) public APKmap;
    address public owner;
    address public requester;
    address public AA1;
    address public AA2;
    uint256 public order;
    bytes public generator;
    bytes public Hash;


    struct User{
        address userAddress;
        bytes PK;
        bytes secretKey;
        bytes AK1;
        bytes AK2;
    }

    constructor (address AA1address, address AA2address) {
        owner = msg.sender;
        AA1 = AA1address;
        AA2 = AA2address;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAA {
        require(msg.sender == AA1 || msg.sender == AA2);
        _;
    }
    modifier onlyAA1 {
        require(msg.sender == AA1);
        _;
    }
    modifier onlyAA2 {
        require(msg.sender == AA2);
        _;
    }

    //传输AES密钥
    function sendKey(address useraddress, bytes memory Key)onlyOwner public{
        emit SendKey(msg.sender, useraddress, Key);
        users[useraddress].secretKey = Key;
    }
    function requestKey(address useraddress) public view returns(bytes memory){
        return users[useraddress].secretKey;
    }
    
    //传输属性密钥
    function sendAK1(address useraddress, bytes memory encryptedAK)onlyAA1 public{
        emit SendAK1(msg.sender, useraddress, encryptedAK);
        users[useraddress].AK1 = encryptedAK;
    }
    function requestAK1(address useraddress) public view returns(bytes memory){
        return users[useraddress].AK1;
    }
    
    function sendAK2(address useraddress, bytes memory encryptedAK)onlyAA2 public{
        emit SendAK2(msg.sender, useraddress, encryptedAK);
        users[useraddress].AK2 = encryptedAK;
    }
    function requestAK2(address useraddress) public view returns(bytes memory){
         return users[useraddress].AK2;
    }
    
    //用户公钥上链
    function setPK(bytes memory PK) public{
        requester = msg.sender;
        users[requester].PK = PK;
    }
    function getPK(address useraddress) public view returns(bytes memory){
        return users[useraddress].PK;
    }

    //APK上链
    function sendAPK(string memory attr, bytes memory PK)onlyAA public{
        APKmap[attr] = PK;
    }
    function getAPK(string memory attr) public view returns(bytes memory){
        return APKmap[attr];
    }

    function sendhash(bytes memory hashCT)onlyOwner public{
        Hash = hashCT;
    }
    function gethash()public view returns(bytes memory){
        return Hash;
    }
    function sendOrder(uint256 t)onlyOwner public{
        order = t;
    }
    function sendGenerator(bytes memory t)onlyOwner public{
        generator = t;
    }
    function getOrder()public view returns(uint256){
        return order;
    }
    function getGenerator()public view returns(bytes memory){
        return generator;
    }
}