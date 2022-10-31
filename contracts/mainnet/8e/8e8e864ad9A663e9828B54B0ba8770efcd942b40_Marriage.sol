// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract MarriageRegistry {
    address [] public registeredMarriages;
    event ContractCreated(address contractAddress);

    function createMarriage(address[] memory participants, uint _date) public {
        Marriage newMarriage = new Marriage(msg.sender, participants, _date);
        address newMarriageAddress = address(newMarriage);
        emit ContractCreated(newMarriageAddress);
        registeredMarriages.push(newMarriageAddress);
    }

    function getDeployedMarriages() public view returns (address[] memory) {
        return registeredMarriages;
    }
}


/**
 * @title Marriage
 * @dev The Marriage contract provides basic storage for names and vows, and has a simple function
 * that lets people ring a bell to celebrate the wedding
 */
contract Marriage {
    struct Participant {
        bool exists;
        string name;
        string signature;
    }

    struct BellRing {
        address ringer;
        string message;
    }

    event weddingBells(address ringer, string message);

    address public owner;

    uint public marriageDate;
    bool public marriageComplete;
    mapping(address => Participant) public participants;
    address[] public participantAddresses;
    
    BellRing[] public bellRings;

    /**
    * @dev Throws if called by any account other than the owner
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Constructor sets the original `owner` of the contract to the sender account, and
    * commits the marriage details and vows to the blockchain
    */
    constructor(address _owner, address[] memory _participants, uint _date) {
        participantAddresses = _participants;
        for (uint i = 0; i < _participants.length; i++) {
            participants[_participants[i]] = Participant({exists: true, name: '', signature: ''});
        }

        owner = _owner;
        marriageDate = _date; 
        marriageComplete = false;
    }

    
    function setName(string memory name) public {
        assert(participants[msg.sender].exists);
        participants[msg.sender].name = name;
    }

    function sign(string memory signature) public {
        assert(participants[msg.sender].exists);
        participants[msg.sender].signature = signature;
        _checksigned();
    }

    function _checksigned() private {
        for (uint i = 0; i < participantAddresses.length; i++) {
            Participant memory participant = participants[participantAddresses[i]];
            if (bytes(participant.name).length == 0 || bytes(participant.signature).length == 0) {
                return;
            }
        }

        marriageComplete = true;
    }

    /**
    * @dev ringBell is a payable function that allows people to celebrate the couple's marriage, and
    * also send Ether to the marriage contract
    */
    function ringBell(string memory message) public payable {
        BellRing memory ring = BellRing({
            ringer: msg.sender,
            message: message
        });
        bellRings.push(ring);
        emit weddingBells(msg.sender, message);
    }

    /**
    * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
    */
    function collect() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
    * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
    */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
    * @dev returns contract metadata in one function call, rather than separate .call()s
    * Not sure if this works yet
    */
    // function getMarriageDetails() public view returns (
    //     address, string[], uint, uint256) {
    //     return (
    //         owner,
    //         names,
    //         marriageDate,
    //         bellCounter
    //     );
    // }
}