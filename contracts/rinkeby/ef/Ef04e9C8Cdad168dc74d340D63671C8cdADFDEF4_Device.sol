/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
// フロントエンドから機器登録・機器情報閲覧を行うことを想定した機器管理スマートコントラクト
pragma solidity ^0.8.1;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract RoleBasedAcl is Ownable {
    address creator;
    mapping(address => mapping(string => bool)) roles;

    function BasedAcl() public {
        creator = msg.sender;
    }

    function assignRole(address entity, string memory role)
        public
        adminRole("superadmin")
    {
        roles[entity][role] = true;
    }

    function unassignRole(address entity, string memory role)
        public
        adminRole("superadmin")
    {
        roles[entity][role] = false;
    }

    function isAssignedRole(address entity, string memory role)
        public
        view
        returns (bool)
    {
        return roles[entity][role];
    }

    modifier adminRole(string memory role) {
        require(roles[msg.sender][role] && msg.sender == creator);
        _;
    }

    modifier userRole(string memory role) {
        require(roles[msg.sender][role]);
        _;
    }
    modifier deviceRole(string memory role) {
        require(roles[msg.sender][role]);
        _;
    }
}

contract Device is RoleBasedAcl {
    event DoEvent(address indexed users, uint256 number);
    struct Data {
        string device_name;
        uint256 check_date;
        uint256 device_ver;
    }

    uint8 update_cnt = 0;
    uint256[] update_date; //updat_dateを配列に格納

    address[] public users; //address配列にusersを格納

    mapping(address => Data) userToData; //userとDataを関連付ける

    function firstResistData(string memory device_name, uint256 device_ver)
        public
        returns (bool)
    {
        uint256 check_date = block.timestamp;
        if (!isUserExist(msg.sender)) {
            users.push(msg.sender);
        }
        userToData[msg.sender].device_name = device_name;
        userToData[msg.sender].device_ver = device_ver;
        userToData[msg.sender].check_date = check_date;
        emit DoEvent(msg.sender, check_date);

        return true;
    }

    function viewDeviceState(address user)
        public
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        string memory device_name = userToData[user].device_name;
        uint256 device_ver = userToData[user].device_ver;
        uint256 check_date = userToData[user].check_date;
        return (device_name, device_ver, check_date);
    }

    function isUserExist(address user) public view returns (bool) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return true;
            }
        }
        return false;
    }

    /*
    constructor() public{
        BasedAcl();
        roles[creator]["superadmin"] = true;
        set_init(19700101);
    }
        
    function set_init(uint32 date) internal{
        update_date.push(date);
        update_cnt++;
    }
    */
    /*function debug_creator() public view returns(address){
        return creator;
    }*/

    function user_regist(address user) public adminRole("superadmin") {
        roles[user]["user"] = true;
    }

    /*
    function debug_user_regist(address user) public view returns(bool){
        return roles[user]["user"];
    }*/

    /*
    function check_ver() public view userRole("user") returns(uint256){
        return device_ver;
    }
    
    function check_date_ret() public view userRole("user") returns (uint256){
        return check_date;
    }
    */
    function update_chcek_date(uint256 _check_date)
        public
        adminRole("superadmin")
    {
        //check_date = _check_date;
        userToData[msg.sender].check_date = _check_date;
    }

    function check_update_date()
        public
        view
        userRole("user")
        returns (uint256)
    {
        return update_date[update_cnt - 1];
    }

    function update_ver(uint256 date, uint256 ver) public deviceRole("device") {
        //check_date = date;
        //device_ver = ver;
        userToData[msg.sender].check_date = date;
        userToData[msg.sender].device_ver = ver;
        update_date.push(date);
        update_cnt++;
    }
}