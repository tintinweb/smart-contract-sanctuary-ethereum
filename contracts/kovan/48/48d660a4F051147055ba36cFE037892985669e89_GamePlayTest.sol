// File: @opengsn/gsn/contracts/interfaces/IRelayRecipient.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// File: @opengsn/gsn/contracts/BaseRelayRecipient.sol


// solhint-disable no-inline-assembly
pragma solidity >=0.6.2;


/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// File: contracts/TestGasLessGame.sol


// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */


contract GamePlayTest is BaseRelayRecipient {

    uint public entryPrice;
    address  payable public contractOwner;
    uint public active_houses; 
    uint public completed_houses; 
    
    struct PlayHouse{
        string housename;
        string gameDescription;
        uint bettingPrice;
        uint totalPool;
        uint totalEntries;
        bool isActive;
        address creator;
        address winner;
        address[] entries;
        mapping(address => bool)  isInGame;
        mapping (address => bool) hasConfirmedToProceed;
        uint totalApprovals;
        uint gasUsed;
    }
    //here house id will map to individual playHouse
    mapping(uint => PlayHouse) playhouses;
    uint public totalPlayHouses; 
   
	//string public override versionRecipient = "2.0.0";
     function versionRecipient() public override view returns (string memory){
         return "2.0.0";
     }

    modifier only_owner(uint playHouseId){
        require( playhouses[playHouseId].creator==_msgSender());
        _;
    }
    modifier only_contract_creator(){
        require( _msgSender()==contractOwner);
        _;
    }

    constructor(uint _entryPrice, address _forwarder) {
        trustedForwarder = _forwarder;
        contractOwner = payable(_msgSender());
        entryPrice = _entryPrice;
    }

    function getApprovalCount(uint _hid) public view returns(uint){
      return  playhouses[_hid].totalApprovals;
    }
    

    function createPlayHouse(string memory _name , string memory _description ,uint _bettingPrice) public payable{
            
            
            require(msg.value>=(_bettingPrice+entryPrice));


            PlayHouse storage p1 =  playhouses[totalPlayHouses];
            p1.housename = _name;
            p1.gameDescription = _description;
            p1.bettingPrice = _bettingPrice;
            p1.creator = _msgSender();
            p1.isActive = true;
            p1.isInGame[_msgSender()] = true; 
            p1.totalPool += _bettingPrice; 
            p1.totalEntries++;
            p1.entries.push(_msgSender());
            totalPlayHouses++;
            active_houses++;
          
    }


    

    function getPlayHouseDatas(uint playHouseId) public view returns(
        string memory _name ,
        string memory _description ,
        address _creator ,
        uint _poolPrice,
        bool isActive,
        uint bettingPrice,
        address[] memory players,
        address _winner
        ){
          PlayHouse storage p5 =  playhouses[playHouseId];
        return(
        p5.housename,
        p5.gameDescription,
        p5.creator,
        p5.totalPool,
       p5.isActive, 
       p5.bettingPrice, 
       p5.entries,
       p5.winner
       );

    }

    function entry(uint _playHouseId) public payable{

        address _newPlayer = _msgSender();
            
            require(playhouses[_playHouseId].isActive);
            require(msg.value >(playhouses[_playHouseId].bettingPrice+entryPrice),'Insufficient entry price');
            require( !playhouses[_playHouseId].isInGame[_newPlayer],'Player is already in the game');
            require(playhouses[_playHouseId].entries.length==1 );

               playhouses[_playHouseId].entries.push(_msgSender());
        playhouses[_playHouseId].totalPool += playhouses[_playHouseId].bettingPrice; 
        playhouses[_playHouseId].totalEntries++;
        playhouses[_playHouseId].isInGame[_msgSender()]=true;


    }

    function withdraw() public only_contract_creator payable only_contract_creator{
       uint currentBalance= address(this).balance;
        payable(contractOwner).transfer(currentBalance);
    } 
    
    function getContractBalance() public only_contract_creator view returns(uint) {
        return (address(this).balance);
    } 

    function cancelGame(uint _playhouseId) public payable{
        require (playhouses[_playhouseId].creator == _msgSender());
        require(playhouses[_playhouseId].totalEntries==1);
        require(playhouses[_playhouseId].isActive);
        playhouses[_playhouseId].isActive = false;
        payable(_msgSender()).transfer(entryPrice+playhouses[_playhouseId].bettingPrice);
        
    }

    function getGasUsed(uint _playHouseId) public view returns(uint){
        return  playhouses[_playHouseId].gasUsed;
    }

    function startGame(uint _playHouseId) public {
         require (playhouses[_playHouseId].creator == _msgSender());
         playhouses[_playHouseId].totalApprovals = 1;
         playhouses[_playHouseId].hasConfirmedToProceed[_msgSender()] = true;
    }
   

    function approveByOtherPlayer(uint _playHouseId,uint randomNum) public{
        PlayHouse storage p3 =  playhouses[_playHouseId];
        require(p3.isInGame[_msgSender()]);
        require(!p3.hasConfirmedToProceed[_msgSender()]);
         p3.hasConfirmedToProceed[_msgSender()] = true;
        p3.totalApprovals +=1;

        pickWinner(_playHouseId,randomNum);

         
    }

    function changeEntryPrice(uint _entryPrice) public only_contract_creator{
            entryPrice = _entryPrice;
    }
    function leaveGame(uint _playHouseId) public payable{
        
        PlayHouse storage p2 =  playhouses[_playHouseId];
        require(p2.isInGame[_msgSender()]);
        
        require(p2.isActive);
        p2.isInGame[_msgSender()] = false;
        p2.totalEntries = p2.totalEntries-1;
        if(p2.creator==_msgSender()){
            address _secondPerson = p2.entries[1]; 
            p2.winner=_secondPerson;
            p2.isActive = false;
            payable(_secondPerson).transfer(p2.totalPool);
        }else{
            p2.isInGame[_msgSender()]=false;
            
            //Here, for the coin flip, we give out the result almost instantly,, 
            //but for others game, user may leave game before its completion... soooo

            if(p2.hasConfirmedToProceed[_msgSender()]){
                p2.hasConfirmedToProceed[_msgSender()] = false;
                p2.totalApprovals -=1;

            }

        }

    }

    function pickWinner (uint _homeId,uint _index) public payable{

       PlayHouse storage p4 =  playhouses[_homeId];
       require(getApprovalCount(_homeId)==2);
       address _winnerAddress = p4.entries[_index];
       p4.winner = _winnerAddress;
       p4.isActive = false;
       active_houses--;
       completed_houses++;
       payable(_winnerAddress).transfer(p4.totalPool);
    }

  
}