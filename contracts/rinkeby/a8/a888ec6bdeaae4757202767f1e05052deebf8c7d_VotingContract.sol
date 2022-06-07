/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IlandBaronstorage{
    struct choice { string voteName; string choice; }
    struct option{string propertyName; string propertyLink;}
    struct vote{uint voteId; string voteName; uint startTimestamp; uint stopTimestamp; bool status; uint votesCast;}
    function getOwner() external view returns(address);
    function getVoteDetails(string calldata _voteName) external view returns(vote memory);
    function addVote(string calldata _voteName, uint _startTimestamp, uint _stopTimestamp) external;
    function addOption(string calldata _voteName, string calldata _propertyName, string calldata _propertyLink) external;
    function getSubmittedVotes(address _address, string calldata _voteName) external view returns(choice memory);
    function getOptions(string calldata _voteName) external view returns(option[] memory);
    function addSubmittedVotes(address _address, string calldata _voteName, uint _choice) external;
    function addVoter(address _address) external;
    function incrementVoteCount(string calldata _voteName, uint _choice) external;       
}

interface IlandBaronTokenContract{
    function balanceOf(address owner) external view returns (uint256);
}

contract VotingContract{
    address landBaronTokenContractAddress;
    address landBaronStorageContractAddress;
    
    constructor(address _landBaronStorageContractAddress) {
        landBaronStorageContractAddress = _landBaronStorageContractAddress;
    }



    modifier onlyOwner{
        require(msg.sender == IlandBaronstorage(landBaronStorageContractAddress).getOwner(), "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyHolder{
        require(IlandBaronTokenContract(landBaronTokenContractAddress).balanceOf(msg.sender) > 0, "Only the owner of the contract can call this function");
        _;
    }



    function setTokenContract(address _tokenContractAddress) public onlyOwner{
        landBaronTokenContractAddress = _tokenContractAddress;
    }

    struct option{string propertyName; string propertyLink;}

    ////////////////////////////
    function createVote(string calldata _voteName, uint _startTimestamp, uint _stopTimestamp, option[] calldata _options) public onlyOwner{
        require(keccak256(abi.encodePacked(IlandBaronstorage(landBaronStorageContractAddress).getVoteDetails(_voteName).voteName)) != keccak256(abi.encodePacked(_voteName)), "Vote name already exist");
        require(_startTimestamp < _stopTimestamp, "Looks like you are trying to go backwards in time. Check your start and stop times.");
        // 86400 is how many seconds in a day. You can't reserve a property less than 24HRS out.
        require(_startTimestamp > block.timestamp + 86400, "You cannot create a vote that starts in less that 24 HRS.");
        IlandBaronstorage(landBaronStorageContractAddress).addVote(_voteName, _startTimestamp, _stopTimestamp);
        for(uint i = 0; i <= _options.length - 1; i++){
            IlandBaronstorage(landBaronStorageContractAddress).addOption(_voteName, _options[i].propertyName, _options[i].propertyLink);
        }
    }

    function castVote(string calldata _voteName, uint _numberChoice) public onlyHolder{
        require(keccak256(abi.encodePacked(IlandBaronstorage(landBaronStorageContractAddress).getVoteDetails(_voteName).voteName)) == keccak256(abi.encodePacked(_voteName)), "Vote name don't exist");
        require(IlandBaronstorage(landBaronStorageContractAddress).getVoteDetails(_voteName).stopTimestamp > block.timestamp, "The voting time period has expired for the vote you chose");
        require(keccak256(abi.encodePacked(IlandBaronstorage(landBaronStorageContractAddress).getSubmittedVotes(msg.sender, _voteName).voteName)) != keccak256(abi.encodePacked(_voteName)), "Looks like you have already voted");
        require(_numberChoice > 0 && _numberChoice <= IlandBaronstorage(landBaronStorageContractAddress).getOptions(_voteName).length, "You have made an invalid selection");
        
        IlandBaronstorage(landBaronStorageContractAddress).addVoter(msg.sender);
        IlandBaronstorage(landBaronStorageContractAddress).addSubmittedVotes(msg.sender, _voteName, _numberChoice);
        IlandBaronstorage(landBaronStorageContractAddress).incrementVoteCount(_voteName, _numberChoice);
    }
}