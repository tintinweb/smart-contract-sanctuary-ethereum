/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    struct Users {
        bool verify;
        string certificate;
        uint256 certificateId;
    }

    struct UserInfo {
        address userAddress;
        string name;
        string surName;
        uint256 year;
        uint256 tc;
    }

    address public owner;
    mapping(address => Users) public users;

    UserInfo[] private info;

    constructor() {
        owner = msg.sender;
    }

    function verify(
        string memory _certificate,
        uint256 _certificateId,
        address _userAddress,
        string memory _name,
        string memory _surName,
        uint256 _year,
        uint256 _tc
    ) external {
        Users storage sender = users[_userAddress];
        require(msg.sender == owner, "Only Owner Can Add New Certificate.");
        require(!sender.verify, "Already verified.");
        sender.verify = true;
        sender.certificate = _certificate;
        sender.certificateId = _certificateId;
        info.push(
            UserInfo({
                userAddress: _userAddress,
                name: _name,
                surName: _surName,
                year : _year,
                tc: _tc
            })
        );
    }

    function getUserInfo(address _userAddress)
        public
        view
        returns (address, string memory,string memory,uint256,uint256)
    {
        for (uint256 p = 0; p < info.length; p++) {
            if (info[p].userAddress == _userAddress) {
               return (info[p].userAddress,info[p].name,info[p].surName,info[p].year,info[p].tc);
            }
        }

    }

    function getVerify(address _userAddress)
        public
        view
        returns (bool, string memory,uint256)
    {
       return (users[_userAddress].verify,users[_userAddress].certificate,users[_userAddress].certificateId);

    }

}