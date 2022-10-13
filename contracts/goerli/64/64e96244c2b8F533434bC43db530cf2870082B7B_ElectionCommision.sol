/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: GPL-3.0
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ElectionCommition.sol


   pragma solidity ^0.8.16;

   contract ElectionCommision is Ownable{
       struct voter{
           uint256 uniqueId;
           string name;
           uint256 wardNo;
           bool votingStatus;
           address voterAddress;
       }
       struct nomini{
           uint256 uniqueId;
           string name;
           uint256 wardNo;
           uint256 vote;
           bool result;
       }
       bool public nomination;
       bool public votingStatus;
       uint256 private voterCount=0;//used for unique id's for voter
       uint256 private voteCounter; // no of vote 
       uint256 private nominiCount=0; //no of nomini's
       mapping (uint256=>voter) public voterData;
       mapping (uint256 =>nomini) public nominiData;
 
       
       // this function is used for insert voter information
       function setVoterInformation(string memory _name,uint256 _wardNo) public {       
           voterCount+=1;
           voterData[voterCount]=voter(voterCount,_name,_wardNo,false,msg.sender);
       }
 
        // this function is used for to do the nomination on or off.
       function nominationFlip() public onlyOwner {
           if (nomination==false){
               nomination=true;
           }else{
               nomination=false;
           } 
       }
 
        // this function is used for to do the voting on or off.
       function votingFlip() public onlyOwner {
           if (votingStatus==false){
               votingStatus=true;
           }else{
               votingStatus=false;
           } 
       }
        
        // this function is used for to do the nomination.
       function doTheNomination(uint256 _uniqueId,string memory _name,uint256 _wardNo) public{
           require(nomination==true,"Nomination is closed now");
           require(_wardNo==voterData[_uniqueId].wardNo,"Please fill the nomination in your ward");
           nominiData[_uniqueId]=nomini(_uniqueId,_name,_wardNo,0,false);
           nominiCount+=1;
       }
        
        // this function is used for to do the voting.
       function voting(uint256 _uniqueId,uint256 _nominiUniqueId) public{
           require(votingStatus==true,"Voting off ");
           require(msg.sender==voterData[_uniqueId].voterAddress,"its not your ward");
           require(voterData[_uniqueId].votingStatus==false,"You have already voted");
           nominiData[_nominiUniqueId].vote+=1;
           voteCounter+=1;
           voterData[_uniqueId].votingStatus=true;
       }
 
        // this function is used for to declear the results.
       function electionResult(uint256 _wardNo,uint256 _nomini1Id,uint256 _nomini2Id) public onlyOwner returns(string memory) {
          require(_wardNo==nominiData[_nomini1Id].wardNo && _wardNo==nominiData[_nomini2Id].wardNo, "Wrong Information " );
           if(nominiData[_nomini1Id].vote>nominiData[_nomini2Id].vote)
           {
               nominiData[_nomini1Id].result=true;
               return nominiData[_nomini1Id].name;
           }else{
               nominiData[_nomini2Id].result=true;
               return nominiData[_nomini2Id].name;
           }
           
           /*function electionResult() public view onlyOwner returns(nomini[] memory) {
           nomini[] memory id=new nomini[](nominiCount);
           for(uint i=0;i<nominiCount;i++){
                nomini storage nom=nominiData[i];
                id[i]=nom;
                }
           return id;*/
       }
    }