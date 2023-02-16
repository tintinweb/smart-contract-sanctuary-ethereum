// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MultiSig {
    // a contract that receives and send ethers
    //allows atleast 70% approval of admins before withdrawal is made.
    //allows atleast 70% approval of admins before removal of admin;
    //allows atleast 70% approval of admins before addition of admin;
    //minimum of 3 admins at every point in time
    address[] Admins;

    address MasterOwner;

    //    // admin ==> newAdmin ==> bool
    mapping(address => mapping(address => bool)) votesStatus;
    // newAmin ==> no of vote
    mapping(address => uint256) voteCount;
    mapping(address => bool) isAdmin;

    constructor(address[] memory _admins, address _owner) {
        require(_admins.length >= 3, "minimum Admins not met");
        Admins = _admins;
        for (uint256 i = 0; i < _admins.length; i++) {
            isAdmin[_admins[i]] = true;
        }
        MasterOwner = _owner;
    }

    modifier onlyAdmin(address _admin) {
        bool valid;
        for (uint256 i = 0; i < Admins.length; i++) {
            if (_admin == Admins[i]) {
                valid = true;
                break;
            }
        }
        require(valid, "not admin");
        _;
    }

    receive() external payable {}

    function addAdmin(address _newAdmin) external onlyAdmin(msg.sender) {
        require(
            isAdmin[_newAdmin] == false && _newAdmin != address(0),
            "cannot address(0) as admin"
        );
        bool status = votesStatus[msg.sender][_newAdmin];
        require(status == false, "previously voted");
        voteCount[_newAdmin]++;
        votesStatus[msg.sender][_newAdmin] = true;
        uint256 _perc = calcPercentage();
        if (voteCount[_newAdmin] >= _perc) {
            Admins.push(_newAdmin);
            isAdmin[_newAdmin] = true;
            voteCount[_newAdmin] = 0;
        }
    }

    function calcPercentage() public view returns (uint256 _perc) {
        uint256 size = Admins.length;
        _perc = (size * 70) / 100;
    }

    function returnAdmins() public view returns (address[] memory _admins) {
        uint256 size = Admins.length;
        _admins = new address[](size);
        _admins = Admins;
    }
}