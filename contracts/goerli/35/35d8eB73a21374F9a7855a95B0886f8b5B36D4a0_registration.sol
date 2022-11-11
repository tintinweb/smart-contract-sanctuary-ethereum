//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract registration {
    uint256 regFee;
    mapping(address => bool) isBilled;
    address[] public paidMembers;
    uint256 public memberCount;
    Member[] registeredMembers;
    uint256 regCode = 10000;
    uint256 id = 1;

    struct Member {
        string firstName;
        string lastName;
        uint256 regCode;
        uint256 id;
    }

    Member member;

    address owner;

    modifier admin() {
        require(
            msg.sender == owner,
            "You are not authorized to perform this action."
        );
        _;
    }

    constructor() public {
        regFee = 100;
        owner = msg.sender;
    }

    function addMember(
        string memory _firstName,
        string memory _lastName,
        address memAddress
    ) public admin {
        member = Member({
            firstName: _firstName,
            lastName: _lastName,
            regCode: regCode,
            id: id
        });
        regCode++;
        id++;
        registeredMembers.push(member);
        isBilled[memAddress] = true;
    }

    function pay() public payable {
        require(
            msg.value == regFee,
            "This amount does not match the fee amount."
        );
        require(isBilled[msg.sender], "You need to register first.");
        paidMembers.push(msg.sender);

        memberCount++;
    }

    function viewMembers(uint256 _memberCount)
        public
        view
        returns (Member memory)
    {
        return registeredMembers[_memberCount];
    }

    function withdraw() public payable admin {
        payable(msg.sender).transfer(address(this).balance);
    }
}