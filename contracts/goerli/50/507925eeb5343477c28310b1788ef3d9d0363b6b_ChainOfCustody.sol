/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.21 <0.9.0;

contract ChainOfCustody {

    uint32 public participant_id = 0;
	uint32 public chain_of_custody_id = 0;
	string[] pulsemediaIds;

	struct participant {
        string	userName;
        string	password;
        string	participantType;
        address	participantAddress;
    }
    mapping(uint32 => participant) public participants;
	
    struct media {
		string	mediaProperty1;
		string	mediaProperty2;
	}
	mapping(string => media) public media_artifacts;

	struct ownershipXfer {
		string mediaId;
		uint32 ownerFrom;
		uint32 ownerTo;
		uint trxTimeStamp;
	}
	mapping(uint32 => ownershipXfer) public ownershipXfer_list; 	// ownershipXfer_list by ownership ID
	mapping(string => uint32[]) public mediaHistory;				// ownershipXfer_list by Pulse media id
 	
	event TransferOwnership (string _mediaId);						// Ownerhsip history of a particular product
	
	function addParticipant (string memory _name, string memory _pass, string memory _pType, address _pAdd) public returns (uint32) {
		uint32 userId = participant_id++;
		participants[userId].userName = _name;
		participants[userId].password = _pass;
		participants[userId].participantType = _pType;
		participants[userId].participantAddress = _pAdd;
		return userId;
	}

	function getParticipantCount () public view returns (uint32) {
        return (participant_id);
    }
	
    function getParticipantFields (uint32 _participant_id) public view returns (string memory, string memory, address) {
		participant memory p = participants[_participant_id];
        return (p.userName, p.participantType, p.participantAddress);
    }
	
	function getParticipant (uint32 _participant_id) public view returns (participant memory) {
        return (participants[_participant_id]);
    }
	
	function addMedia (string memory _pulseMediaId, string memory _mediaP1, string memory _mediaP2) public {
		pulsemediaIds.push(_pulseMediaId);
		media_artifacts[_pulseMediaId].mediaProperty1 = _mediaP1;
		media_artifacts[_pulseMediaId].mediaProperty2 = _mediaP2;
	}
	
	function getMediaCount () public view returns (uint256) {
        return (pulsemediaIds.length);
    }
	
	function getMediaIds () public view returns (string[] memory) {
        return (pulsemediaIds);
    }
	
	function getMediaFields (string memory _pulseMediaId) public view returns (string memory, string memory) {
        return (media_artifacts[_pulseMediaId].mediaProperty1, media_artifacts[_pulseMediaId].mediaProperty2);
    }
	
	function getMedia (string memory _pulseMediaId) public view returns (media memory) {
        return (media_artifacts[_pulseMediaId]);
    }
	
	modifier onlyOwner (uint32 _userId) {
         require(msg.sender == participants[_userId].participantAddress,"");
         _;
    }
	
	function newOwner (string memory _pulseMediaId, uint32 _userFrom, uint32 _userTo) onlyOwner(_userFrom) public returns (bool) {
		uint32 coc_id = chain_of_custody_id++;
        //participant memory p1 = participants[_userNew];
        //participant memory p2 = participants[_userOld];

        ownershipXfer_list[coc_id].mediaId = _pulseMediaId;
        ownershipXfer_list[coc_id].ownerFrom = _userFrom;
		ownershipXfer_list[coc_id].ownerTo = _userTo;
        ownershipXfer_list[coc_id].trxTimeStamp = uint(block.timestamp);

        mediaHistory[_pulseMediaId].push(coc_id);

        emit TransferOwnership(_pulseMediaId);
		return (true);
    }
		
	
	function getOwnershipChange (uint32 _OwnershipId) public view returns (string memory, string memory, address, string memory, address, uint) {
		ownershipXfer memory o = ownershipXfer_list[_OwnershipId];
		participant memory pFrom = participants[o.ownerFrom];
        participant memory pTo = participants[o.ownerTo];
        return (o.mediaId, pFrom.userName, pFrom.participantAddress, pTo.userName, pTo.participantAddress, o.trxTimeStamp);
    }
	
	function whoAmI () public view returns (address) {
        return (msg.sender);
    }
	
	function whoIsTheMiner () public view returns (address) {
        return (block.coinbase);
    }
	
	function getTS () public view returns (uint) {
        return (block.timestamp);
    }
	
	function getHistory (string memory _pulseMediaId) external view returns (uint32[] memory) {
		return mediaHistory[_pulseMediaId];
    }
	
    function authenticateParticipant (uint32 _uid, string memory _uname, string memory _pass, string memory _utype) public view returns (bool) {
        if(keccak256(abi.encodePacked(participants[_uid].participantType)) == keccak256(abi.encodePacked(_utype))) {
            if(keccak256(abi.encodePacked(participants[_uid].userName)) == keccak256(abi.encodePacked(_uname))) {
                if(keccak256(abi.encodePacked(participants[_uid].password)) == keccak256(abi.encodePacked(_pass))) {
                    return (true);
                }
            }
        }
        return (false);
    }
}