/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

pragma solidity >=0.7.0 < 0.9.0;

contract Voting {
    address private owner;
    uint256 public voteCount = 0;
    uint256 public Count = 0;

        struct Party {
        uint256 id;
        string name;
        uint256 voteCount;
    }

        struct Voter {
        uint256 party_id;
        address voter_address;
    }

    constructor() {
    owner = msg.sender; 
    addParty("PTI");
    addParty("PMLN");
    addParty("PMLQ");
    }

    mapping(address => bool) public isVote;
    mapping(address => uint256[]) private votersId;
    Party[] public allParties;
    Voter[] public allVote;

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
 

      function addParty(
        string memory _name
    ) public isOwner{
        allParties.push(
            Party(
                Count,
                _name,
                voteCount
            )
        );
        Count++;
    }

        function getAllParties() public view returns(Party[] memory){
         Party[] memory partydata = new Party[](allParties.length);
        for (uint256 i = 0; i < allParties.length; i++) {
            partydata[i] = allParties[i];
        }
         return partydata;
    }

     function addVote(
        uint256 _party_id
    ) public {
        require(isVote[msg.sender] != true);
        address userAddress = msg.sender;
        allVote.push(
            Voter(
                _party_id,
                userAddress
            )
        );
           voteCount++;
           votersId[msg.sender].push(voteCount);
           isVote[msg.sender] = true;

            Party storage party = allParties[_party_id];
            party.voteCount = party.voteCount + 1;
    }


}