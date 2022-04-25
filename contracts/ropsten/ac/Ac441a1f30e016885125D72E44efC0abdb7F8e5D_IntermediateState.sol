/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// File: @openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


contract IntermediateState is Ownable{
    event _removeAdmin(address indexed _remover,address indexed  other,uint _complaintTime);
    event _enternewAdmin(address indexed adder,address indexed  newAdmin);
    event _voteCasted(address indexed voter,address indexed  voterFor);
    event _adminRights(address indexed Caller,address indexed adminRemoved);

    struct adminData{
        bool member;
        bool suspend;
        uint8 noOfVotes;
    }

    mapping(address=>adminData) adminshipList;
    mapping (address=>mapping(address=>bool)) intermediateVoteFor;

    constructor(){
        adminshipList[msg.sender]=adminData(true,false,0);
    }

    function isAdmin(address _admin) external view returns(bool){
        return adminshipList[_admin].member;
    }
    function adminVotes(address _admin) external view returns(uint8){
        return adminshipList[_admin].noOfVotes;
    }

    function isAdminSuspended(address _admin) external view returns(bool){
        return adminshipList[_admin].suspend;
    }


    // I will add 5 admin to the list
    function enterNewAdmin(address _admin) external onlyOwner{
        adminshipList[_admin]=adminData(true,false,0);
        emit _enternewAdmin(msg.sender, _admin);
    }

    function removeAdmin(address _admin) external{
        require(adminshipList[msg.sender].member,"IntermediateState: Only admin can remove the other admin");
        require(!adminshipList[msg.sender].suspend,"IntermediateState: Only non suspended admin can remove the other admin");
        intermediateState(_admin);
        emit _removeAdmin(msg.sender,_admin,block.timestamp);


        // If ther is no intermediate state function;
        // adminshipList[_admin].member=false;


    }
     function intermediateState(address _admin) private{
        adminshipList[_admin].suspend=true;
        adminshipList[msg.sender].suspend=true;
    }



    function adminVote(address _voteFor) external{
        require(adminshipList[msg.sender].member,"IntermediateState: only admin allowed to call this function");
        require(!adminshipList[msg.sender].suspend,"IntermediateState: Only non suspended admin can vote for the other admin");
        require(!intermediateVoteFor[msg.sender][_voteFor],"IntermediateState:You have already vote for this admin");
        require(msg.sender!=_voteFor,"IntermediateState:You can not vote for your self");

        intermediateVoteFor[msg.sender][_voteFor]=true;
        adminshipList[_voteFor].noOfVotes +=1;

        emit _voteCasted(msg.sender, _voteFor);
    }

    function useRight(address _admin) external {
        require(adminshipList[msg.sender].member,"IntermediateState: only admin allowed to call this function");
        require(adminshipList[msg.sender].noOfVotes>=2,"IntermediateState:The admin who has high votes can cal this function");
        require(adminshipList[_admin].suspend,"IntermediateState: Only suspended admin can be remove from the administration");

        adminshipList[_admin].member=false;
        adminshipList[msg.sender].suspend=false;
        adminshipList[msg.sender].noOfVotes=0;

        emit _adminRights(msg.sender, _admin);
    }



}