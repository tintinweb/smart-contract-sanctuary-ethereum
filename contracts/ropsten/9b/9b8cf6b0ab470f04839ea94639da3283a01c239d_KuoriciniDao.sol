/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract KuoriciniDao {

  struct DaoGroup {
    string name;
    address[] members;
    uint[] tokenIds;
    uint[] candidatesIds;
    uint[] candidateTokenIds;
    uint voteThreshold;
    string invitationLink;
  }
  
  struct Candidate {
    address candidateAddress;
    uint votes;
    address[] voters;
  }

    /* CandType
    0 : new address
    1 : new token
    2 : change existing token
    3 : new quorum
    */

  struct CandidateToken {
    uint id;
    uint candType;
    string name;
    uint roundSupply;
    uint roundDuration;
    address candidateAddress;
    uint votes;
    address[] voters;
  }

  struct GToken {
    string name;
    uint roundSupply;
    uint roundDuration;
    uint timestamp;
  }

  struct UToken {
    uint tokenId;
    uint gTokenBalance;
    uint xBalance;
  }

  mapping (address => string) names;
  mapping (address => UToken[]) userTokens;
  mapping (string => uint) invitationLinks;
  DaoGroup[] daoGroups;
  GToken[] allTokens;

  // TODO : these two at least, have to become mappings, BUT REFACTOR QUITE
  Candidate[] allCandidates;
  CandidateToken[] allCandidateTokens;

  constructor() {
  }

  function createGroup(string calldata _name) public returns(bool) {
    address[] memory addr = new address[](1);
    addr[0] = msg.sender;
    uint[] memory defaultTokens;
    uint[] memory defaultCandidates;
    uint[] memory defaultCandidateTokens;
    uint threshold = 5;
    string memory invLink = generateInvitationLink(_name);
    DaoGroup memory new_group = DaoGroup({ 
      name: _name, 
      members: addr, 
      tokenIds: defaultTokens, 
      candidatesIds: defaultCandidates, 
      candidateTokenIds: defaultCandidateTokens,
      voteThreshold: threshold,
      invitationLink: invLink
    });
    daoGroups.push(new_group);
    // check invitation link doesn't exist already
    if ( daoGroups.length-1 != 0 ) {
      require ( invitationLinks[invLink] == 0 );
    }
    invitationLinks[invLink]=daoGroups.length-1;
    return true;
  }

  function getGroup(uint _gid) public view returns(DaoGroup memory) {
    return daoGroups[_gid];
  }
  
  function checkInvitationLink(string calldata link) public view returns (uint) {    
    uint groupInv =  invitationLinks[link];
    require(!isAddressInGroup(groupInv, msg.sender), "member already present" );
    uint l = daoGroups[groupInv].candidateTokenIds.length;
    uint[] memory candidateTokenIds = new uint[](l+1);
    for (uint i = 0; i < l; i++) {
      candidateTokenIds[i] = daoGroups[groupInv].candidateTokenIds[i];
      require ( allCandidateTokens[candidateTokenIds[i]].candidateAddress != msg.sender, "candidate already present" );
    }    
    return groupInv;
  }

  function generateInvitationLink(string memory name) private view returns (string memory) {
      uint invLength = 15;
      string memory newString = new string(invLength);
      bytes memory finalString = bytes(newString);
      bytes memory originString = "abcdefghijklmnopqrstuvxyz1234567890";
      for (uint i=0; i< invLength-1; i++) {
          uint r = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, string(finalString), name))) % originString.length;
          finalString[i] = originString[r];
      }
      return string(finalString);
  }    

  
/*
*   Tokens
*
*/

  function getToken(uint _tokenid) public view returns(GToken memory) {
    return allTokens[_tokenid];
  }

  function createGToken(uint tokid, string memory _name, uint _supply, uint _duration, bool present, uint _groupId) private returns(bool){
    require(isAddressInGroup(_groupId, msg.sender), "member cannot vote!" );

    if (present) {
      require(isTokenInGroup(tokid, _groupId), "token not allowed");
      allTokens[tokid].name = _name;
      allTokens[tokid].roundSupply = _supply;
      allTokens[tokid].roundDuration = _duration;
    } 
    else {
      allTokens.push(GToken({
        name: _name,
        roundSupply: _supply,
        roundDuration: _duration,
        timestamp: block.timestamp
      }));
      uint l = allTokens.length;
      daoGroups[_groupId].tokenIds.push(l-1);
    }
    return true;
  }


// temporary struct to make the output more verbose

  struct EToken {
    uint tokenId;
    uint gTokenBalance;
    uint xBalance;
    uint blocktimestamp;
    uint newtime;
    bool overtime;
  }


  function getUserTokens(uint gid) public view returns(EToken[] memory) {
    require(isAddressInGroup(gid, msg.sender), "user not authorized"); 


    uint l = daoGroups[gid].tokenIds.length;
    uint m = userTokens[msg.sender].length;
    UToken[] memory utokens = new UToken[](l);
    EToken[] memory etokens = new EToken[](l);

    for ( uint w = 0; w < l; w++ ) { // all the tokens of this group 
      uint tokid = daoGroups[gid].tokenIds[w];
      uint blts = 0;
      bool overtime = false;
      uint newtime = 0;
      utokens[w] = UToken ({ tokenId: tokid, gTokenBalance: 0, xBalance: allTokens[tokid].roundSupply});
      for ( uint j = 0; j < m; j++ ) { // all the tokens of this user
        if (userTokens[msg.sender][j].tokenId == tokid) {
          utokens[w].gTokenBalance = userTokens[msg.sender][j].gTokenBalance;
          newtime = allTokens[tokid].timestamp + allTokens[tokid].roundDuration;
          blts = block.timestamp; 
          if ( blts > newtime ) {
            utokens[w].xBalance = allTokens[tokid].roundSupply;
            overtime = true;
          } 
          else {
            utokens[w].xBalance = userTokens[msg.sender][j].xBalance;
            overtime = false;
          }
        }
      }
      etokens[w].tokenId = utokens[w].tokenId;
      etokens[w].gTokenBalance = utokens[w].gTokenBalance;
      etokens[w].xBalance = utokens[w].xBalance;
      etokens[w].blocktimestamp = blts;
      etokens[w].newtime = newtime;
      etokens[w].overtime = overtime;

    }
    return etokens;
  }

  function transferToken(uint _tokenId, address receiver, uint value) public returns(bool) {
    UToken memory _tokSender;
    bool matchFoundSender = false;
    uint s;
    uint r;
    for (s = 0; s < userTokens[msg.sender].length ; s++) {
      if (userTokens[msg.sender][s].tokenId == _tokenId) {
        _tokSender = userTokens[msg.sender][s];
        matchFoundSender = true;
        break;
      }
    }
    if (matchFoundSender == false){
      _tokSender = UToken({ tokenId: _tokenId, gTokenBalance: 0, xBalance: allTokens[_tokenId].roundSupply});
    }
    
    if (block.timestamp > (allTokens[_tokenId].timestamp + allTokens[_tokenId].roundDuration * 1 seconds) ) {
      _tokSender.xBalance = allTokens[_tokenId].roundSupply;
      uint _newTimestamp = allTokens[_tokenId].timestamp;
      for (uint k = 0; _newTimestamp < block.timestamp ; k++) {
        _newTimestamp += allTokens[_tokenId].roundDuration;
//      _newTimestamp += allTokens[_tokenId].roundDuration * k; // WAS with *k in Ropstein, ARE YOU SURE  ???
      }
      allTokens[_tokenId].timestamp=_newTimestamp;
    }
    
    require(_tokSender.xBalance >= value, "non hai abbastanza token");
    UToken memory _tokReceiver;
    bool matchFoundReceiver = false;
    for ( r = 0; r < userTokens[receiver].length ; r++) {
      if (userTokens[receiver][r].tokenId == _tokenId) {
        _tokReceiver = userTokens[receiver][r];
        matchFoundReceiver = true;
        break;
      }
    }
    if ( matchFoundReceiver == false){
      _tokReceiver= UToken({ tokenId: _tokenId, gTokenBalance: 0, xBalance: allTokens[_tokenId].roundSupply});
    }
    _tokSender.xBalance -= value;
    _tokReceiver.gTokenBalance += value;
    if (matchFoundSender == true) {
      userTokens[msg.sender][s] = _tokSender;
    }
    else {
      userTokens[msg.sender].push( UToken({ tokenId: _tokenId, gTokenBalance: 0, xBalance: _tokSender.xBalance}));
    }
    if (matchFoundReceiver == true) {
      userTokens[receiver][r] = _tokReceiver;
    }
    else {
      userTokens[receiver].push( UToken({ tokenId: _tokenId, gTokenBalance: _tokReceiver.gTokenBalance, xBalance: allTokens[_tokenId].roundSupply}));
    }
    return true;
  }



  function isTokenInGroup(uint tokid, uint gid) private view returns(bool) {
    for ( uint i = 0; i < daoGroups[gid].tokenIds.length; i++){
      if ( daoGroups[gid].tokenIds[i] == tokid ){
        return true;
      }
    }
    return false;
  }

  
 // obsolete, to be removed. replaced by getToken. Remove it from one call from js  
  function getGroupNamefromId(uint _id) public view returns(string memory) {
    return daoGroups[_id].name;
  }

 // obsolete, to be removed. replaced by getToken. Remove it from one call from js  
  function getGroupAddressfromId(uint _id) public view returns(address[] memory) {
    return daoGroups[_id].members;
  }


/*  
*   Tokens Candidates
*
*/


  // propose token change
  function changeToken(uint val, string calldata name, uint supply, uint duration, uint gid, uint candtype) public returns(bool) {

    if ( candtype == 0 ) {
      require(!isAddressInGroup(gid, msg.sender), "member already present!");
      require( invitationLinks[name] == gid, "link not authorized" ); 
      require( gid != 0, "group not authorized" );
    } else {
      require(isAddressInGroup(gid, msg.sender), "member not allowed!");
    }

    // if token is marked as present make sure it really exists and belongs to the right group
    if ( candtype == 2 ) {
      require(isTokenInGroup(val, gid), "token not allowed");
    }
    if (candtype == 3) {
      require(val <= 10, "invalid quorum");
    }

    uint l = daoGroups[gid].candidateTokenIds.length;
    uint[] memory candidateTokenIds = new uint[](l+1);
    
    for (uint i = 0; i < l; i++) {
      candidateTokenIds[i] = daoGroups[gid].candidateTokenIds[i];
       if ( candtype == 0 ) {    
        require(allCandidateTokens[candidateTokenIds[i]].candidateAddress != msg.sender, "candidate already added!");
      }
    }

    // generate a new candidate
    address[] memory vot = new address[](0);
    allCandidateTokens.push(CandidateToken({
      id: val,
      candType: candtype,
      name: name,
      roundSupply: supply,
      roundDuration: duration,
      candidateAddress: msg.sender,
      votes: 0,
      voters: vot
    }));

    // update candidate list in the group
/*    for ( uint i = 0; i < l ; i++ ){
      candidateTokenIds[i] = daoGroups[gid].candidateTokenIds[i];
    }
*/    
    candidateTokenIds[l] = allCandidateTokens.length-1;
    daoGroups[gid].candidateTokenIds = candidateTokenIds;

    return true;

  }

  // get candidate tokens of a group
  function getGroupCandidateTokens(uint gid) public view returns(CandidateToken[] memory) {
    require(isAddressInGroup(gid, msg.sender), "member not allowed!" );
    uint l = daoGroups[gid].candidateTokenIds.length;
    CandidateToken[] memory candidatetokens = new CandidateToken[](l);
    for (uint i = 0; i < l; i++) {
      uint c = daoGroups[gid].candidateTokenIds[i];
      candidatetokens[i] = allCandidateTokens[c];
    }
    return candidatetokens;
  }

  // vote candidate token and eventually promote the change if quorum is passed
  function voteCandidateToken(uint gid, uint candTokId, uint vote) public returns(bool) {
    require(isAddressInGroup(gid, msg.sender), "member cannot vote!" );

    // find candidate
    CandidateToken memory candidatetoken;
    // check it exists in the group
    uint l = daoGroups[gid].candidateTokenIds.length;
    bool candidateTokenFound = false; 
    for (uint i = 0; i < l; i++) {
      if (daoGroups[gid].candidateTokenIds[i] == candTokId) {
        candidatetoken = allCandidateTokens[candTokId];
        candidateTokenFound = true;
        break;
      }
    }
    require(candidateTokenFound, "candidate token doesn't exists");

    // add voter (this would be the same if we merge)
    uint m = candidatetoken.voters.length;
    address[] memory v = new address[](m+1);
    for (uint i = 0; i < m; i++) {
      require(candidatetoken.voters[i] != msg.sender, "address already voted!");
      v[i]=candidatetoken.voters[i];
    }
    v[m]=msg.sender;
    candidatetoken.voters=v;

    // assign vote   
    if (vote > 0) {
      candidatetoken.votes += 1;
    }
    
    // write on chain
    allCandidateTokens[candTokId] = candidatetoken;

    // check if candidate win
    uint quorum = getQuorum(gid);
    if ( candidatetoken.votes > quorum ) {
      if ( candidatetoken.candType == 0 ) {
        addAddresstoGroup(gid, candidatetoken.candidateAddress);
      }       
      if ( ( candidatetoken.candType == 1 ) || ( candidatetoken.candType == 2 ) ) {
        createGToken(candidatetoken.id, candidatetoken.name, candidatetoken.roundSupply, candidatetoken.roundDuration, (candidatetoken.candType == 2), gid);
      }
      if ( candidatetoken.candType == 3 ) {
        daoGroups[gid].voteThreshold = candidatetoken.id;  
      } 

/*
      uint[] memory newCandidateTokenIds;
      for (uint i = 0; i < l; i++) {
        if ( daoGroups[gid].candidateTokenIds[i] != candPos ) {
          newCandidateTokenIds[i] = daoGroups[gid].candidateTokenIds[i];
        }
      }
*/
      // remove element from candidates array
      uint[] memory newCandidateTokenIds = new uint[](l-1);
      uint index;
      uint k;
      for (k = 0; k < l; k++) {
        if ( daoGroups[gid].candidateTokenIds[k] == candTokId ) {
          index = k;
          break;
        }
      }
      for (k = 0; k < l; k++) {
        if ( k < index) {
          newCandidateTokenIds[k] = daoGroups[gid].candidateTokenIds[k];
        }
        if ( k > index) {
          newCandidateTokenIds[k-1] = daoGroups[gid].candidateTokenIds[k];
        }
      }
      
      daoGroups[gid].candidateTokenIds = newCandidateTokenIds;

    }

    return true;
  }



/*  
*   Candidates
*
*/
/*
  function addCandidate(uint _gid, string calldata invitation) public returns(bool) {
    require( !isAddressInGroup(_gid, msg.sender), "member already present!");
    require( invitationLinks[invitation] == _gid, "link not authorized" ); 
    require( _gid != 0, "group not authorized" );
    
    // check if candidate already present in current candidate list
    uint l = daoGroups[_gid].candidatesIds.length;
    uint[] memory candidatesIds = new uint[](l+1);
    for (uint i = 0; i < l; i++) {
      candidatesIds[i] = daoGroups[_gid].candidatesIds[i];
      require(allCandidates[candidatesIds[i]].candidateAddress != msg.sender, "candidate already added!");
    }
    // generate a new candidate
    address[] memory vot = new address[](0);
    allCandidates.push(Candidate({
      candidateAddress: msg.sender,
      votes: 0,
      voters: vot
    }));
    // update candidate list in the group
    candidatesIds[l] = allCandidates.length-1;
    daoGroups[_gid].candidatesIds = candidatesIds;

    return true;
  }

  function voteCandidate(uint gid, uint candPos, uint vote) public returns(bool) {
    require(isAddressInGroup(gid, msg.sender), "member cannot vote!" );

    // find candidate 
    Candidate memory candidate;
    // check if exists
    uint l = daoGroups[gid].candidatesIds.length;
    bool candidateFound = false;
    for (uint i = 0; i < l; i++) {
      if (daoGroups[gid].candidatesIds[i] == candPos) {
        candidate = allCandidates[candPos];
        candidateFound = true;
        break;
      }
    }
    require(candidateFound, "candidate address doesn't exists");

    // add voter
    uint m = candidate.voters.length;
    address[] memory v = new address[](m+1);
    for (uint i = 0; i < m; i++) {
      require(candidate.voters[i] != msg.sender, "address already voted!");
      v[i]=candidate.voters[i];
    }
    v[m]=msg.sender;
    candidate.voters=v;

    // assign vote
    if (vote > 0) {
      candidate.votes += 1;
    }
    
    // write on chain
    allCandidates[candPos] = candidate;    

    // check if candidate win
    uint quorum = getQuorum(gid);
    if ( candidate.votes > quorum ) {
      addAddresstoGroup(gid, candidate.candidateAddress);

      uint[] memory newCandidatesIds = new uint[](l-1);
      uint index;
      uint k;
      
      for (k = 0; k < l; k++) {
        if ( daoGroups[gid].candidatesIds[k] == candPos ) {
          index = k;
          break;
        }
      }
      
      for (k = 0; k < l; k++) {
        if ( k < index) {
          newCandidatesIds[k] = daoGroups[gid].candidatesIds[k];
        }
        if ( k > index) {
          newCandidatesIds[k-1] = daoGroups[gid].candidatesIds[k];
        }
      }
      
      daoGroups[gid].candidatesIds = newCandidatesIds;
    
    }
    return true;
  }
  */

  function getQuorum(uint gid) private view returns(uint) {
    require(isAddressInGroup(gid, msg.sender));
    return daoGroups[gid].members.length * daoGroups[gid].voteThreshold / 10 ;
  }
/*
  function getGroupCandidates(uint gid) public view returns(Candidate[] memory) {
    require(isAddressInGroup(gid, msg.sender), "member cannot vote!" );
    uint l = daoGroups[gid].candidatesIds.length;
    Candidate[] memory candidates = new Candidate[](l);
    for (uint i = 0; i < l; i++) {
      uint c = daoGroups[gid].candidatesIds[i];
      candidates[i] = allCandidates[c];
    }
    return candidates;
  }
*/
/*
*
*   Group Members
*/

  function addAddresstoGroup(uint gid, address addr) private returns(bool) {
    require(!isAddressInGroup(gid, addr), "member already present!" );
    uint l = daoGroups[gid].members.length;
    address[] memory members = new address[](l+1);
    for (uint i = 0; i < l; i++) {
      members[i] = daoGroups[gid].members[i];
    }
    members[l] = addr;
    daoGroups[gid].members = members;
    return true;
  }

  function removeMeFromGroup(uint gid) public returns(bool) {
    require(isAddressInGroup(gid, msg.sender), "member not in group!" );

    uint l = daoGroups[gid].members.length;
    address[] memory members = new address[](l-1);
    uint index;
    uint k;
    for (k = 0; k < l; k++) {
      if ( daoGroups[gid].members[k] != msg.sender ) {
        index = k;
        break;
      }
    }
    for (k = 0; k < l; k++) {
      if ( k < index) {
        members[k] = daoGroups[gid].members[k];
      }
      if ( k > index) {
        members[k-1] = daoGroups[gid].members[k];
      }
    }
    daoGroups[gid].members = members;
    return true;
  }



  function isAddressInGroup(uint gid, address addr) private view returns(bool) {
    bool exists = false;
    for (uint i = 0; i < daoGroups[gid].members.length; i++) {
      if( daoGroups[gid].members[i] == addr ) {
        exists=true;
        break;
      }
    }
    return exists;
  }

  function myGroups() public view returns(uint[] memory) {
    uint lg = daoGroups.length;
    uint[] memory mygroups;
    for (uint i = 0; i < lg; i++) {
      uint lm = daoGroups[i].members.length;
      for (uint q = 0; q < lm; q++) {
        if(daoGroups[i].members[q] == msg.sender) {
          uint gl = mygroups.length;
          uint[] memory groups = new uint[](gl+1);
          for (uint w = 0; w < gl; w++) {
            groups[w] = mygroups[w];
          }
          groups[gl] = i;
          mygroups = groups;
        }
      }
    }
    return mygroups;
  }

  function groupNameByInvitation(uint gid, string calldata invitation) public view returns(string memory){
    require( invitationLinks[invitation] == gid, "user not authorized" ); 
    return daoGroups[gid].name;
  }
  
  // names are public
  function nameOf(address owner) public view returns(string memory) {
    return names[owner];
  }

  function nameSet(string calldata name) public returns(bool) {
    names[msg.sender]=name;
    return true;
  }

/*
*   Round functions that probably should be removed
*    
*/
/*
  function tellmeNow() public view returns (uint) {
    return block.timestamp;
  }

  function resetRound(uint _tokenId, uint _groupId) public returns(bool) {
    address[] memory _members = daoGroups[_groupId].members;
    uint l = _members.length;
    for (uint s = 0; s < l ; s++) {
      address member = _members[s];
      uint lu = userTokens[member].length;
      for (uint w = 0; w < lu; w++) {
        if (userTokens[member][w].tokenId == _tokenId) {
          userTokens[member][w].xBalance = allTokens[_tokenId].roundSupply;
        }
      }
    }
    return true;
  }
*/
}