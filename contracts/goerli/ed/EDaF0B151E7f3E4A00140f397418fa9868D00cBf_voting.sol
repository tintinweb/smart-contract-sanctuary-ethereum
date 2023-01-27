//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract voting {
    address owner;
    uint256 i = 0;
    uint256 k = 0;
    uint256 p = 0;

    constructor() {
        owner = msg.sender;
    }

    struct candidate {
        string name;
        // uint256 dob; //date of birth
        uint256 index;
        uint256 count;
        address addr;
        bool exist;
    }

    candidate[] cRegisterVoting;
    mapping(address => candidate) cNameMap;

    struct voter {
        string name;
        // uint256 dob; //date of birth
        uint256 index;
        bool voted;
        address addr;
        bool exist;
    }

    voter[] vRegisterVoting;
    mapping(address => voter) vNameToAddMap;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function registerCandidate(string memory _name, address _addr)
        public
        onlyOwner
    {
        require(
            vNameToAddMap[_addr].exist != true,
            "Address already registered"
        );

        require(cNameMap[_addr].exist != true, "Address already registered");

        cRegisterVoting.push(candidate(_name, k, 0, _addr, true));

        cNameMap[_addr] = cRegisterVoting[k];
        k = k + 1;
    }

    function registerVoter(string memory _name) public {
        require(
            vNameToAddMap[msg.sender].exist != true,
            "Address already registered"
        );

        require(
            cNameMap[msg.sender].exist != true,
            "Address already registered"
        );

        vRegisterVoting.push(voter(_name, p, false, msg.sender, true));

        vNameToAddMap[msg.sender] = vRegisterVoting[p];
        p = p + 1;
    }

    function voteForCandidate(address _candidateAddress, uint256 _value)
        public
    {
        require(
            vRegisterVoting[vNameToAddMap[msg.sender].index].exist == true,
            "Not in voter list"
        );
        require(
            vRegisterVoting[vNameToAddMap[msg.sender].index].voted == false,
            "Already Voted"
        );

        if (_value == 1) {
            i = i + 1;

            cRegisterVoting[cNameMap[_candidateAddress].index].count = i;

            vRegisterVoting[vNameToAddMap[msg.sender].index].voted = true;
        }
    }

    function retrieveCandidateList() public view returns (candidate[] memory) {
        return (cRegisterVoting);
    }

    function retrieveVoterList() public view returns (voter[] memory) {
        return (vRegisterVoting);
    }

    //    function getvariable() public view returns (uint256,uint256,uint256){
    //        return(i,k,p);
    //    }

    //    function getCandidate(address _addr) public view returns(uint256, uint256, bool){
    //
    //      return (cNameMap[_addr].index,cNameMap[_addr].count,cNameMap[_addr].exist);

    //    }

    //   function getVoter(address _addr) public view returns(uint256, bool, bool){

    //        return (vNameToAddMap[_addr].index,vNameToAddMap[_addr].voted,vNameToAddMap[_addr].exist);

    //   }
}