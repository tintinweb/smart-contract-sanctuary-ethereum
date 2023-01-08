/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

pragma solidity >=0.7.3;

contract Auth {
    address private _owner;
    mapping (address => string[]) private userToInfo;
    mapping (address => uint256) private userToInfoNum;

    constructor () {
        _owner= msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == _owner);
        _;
    }

    function addToAddress(address _user, string memory _info) public onlyOwner {
        userToInfo[_user].push(_info);
        ++userToInfoNum[_user];
    }

    function showLenInfo(address _user) public onlyOwner view returns(uint256 len) {
        return userToInfoNum[_user];
    }

    function showInfo(address _user, uint256 index) public onlyOwner view returns(string memory info) {
        return userToInfo[_user][index];
    }
}