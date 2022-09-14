/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



interface IWhitelist {
  function pass(address whiteAddress) external view returns(bool);
}


contract WhiteList is Ownable, IWhitelist{

    // open white mint 
    bool public whiteMinted;

    bool public minted;

    uint public len;

    mapping (uint => uint) public activityTimes;
    mapping (uint => bool) public activities;
    
    mapping (address => mapping (uint => bool)) public whiteMints;


    event Whited(address addr, uint id);
    event UnWhited(address addr, uint id);
    event Activity(uint id);

    constructor() public{
        whiteMinted = true;
        minted = true;
    }

    function addActivity(uint _duration) public onlyOwner{
        uint _end = _duration == 0 ? 0 : _duration + now;
        len++;
        activityTimes[len] = _end;
        activities[len] = true;
        emit Activity(len);
    }

    function setActivity(uint _id, uint _duration) public onlyOwner{
        require(activities[_id]);
        uint _end = _duration == 0 ? 0 : _duration + now;
        activityTimes[_id] = _end;
    }

    function rmActivity(uint _id) public onlyOwner{
        require(activities[_id]);
        activities[_id] = false;
        activityTimes[_id] = 0;
    }
    
    function addToWhitelist(address[] memory _addr, uint  _id) public onlyOwner{
        _addToWhiteLists(_addr, _id);
    }

    function _addToWhiteLists(address [] memory _addr, uint  _id) private{
        require(activities[_id]);
        if(activityTimes[_id] > 0)
            require(activityTimes[_id] > now);

        for(uint i = 0; i < _addr.length; i++){
            if(!whiteMints[_addr[i]][_id]){
                whiteMints[_addr[i]][_id] = true;
                emit Whited(_addr[i], _id);
            }
        }
    }

    function rmWhite(address _addr, uint []  memory _ids)public onlyOwner{
         for(uint i = 0; i < _ids.length; i++){
             require(activities[_ids[i]]);
             if(whiteMints[_addr][_ids[i]]){
                whiteMints[_addr][_ids[i]] =false;
                emit UnWhited(_addr, _ids[i]);
             }
         }
    }

    function pass(address _address) public view returns(bool){
        if(!minted)
            return false;
        if(!whiteMinted)
            return true;
        for(uint i = 1; i <= len; i++){
            if(!activities[i])
                continue;
            if(activityTimes[i] < now && activityTimes[i] != 0)
                continue;
            if(whiteMints[_address][i])
                return true;
        }
        return false;
    }

    function whiteOpened() public onlyOwner{
        whiteMinted = true;
    }

    function whiteClosed()  public onlyOwner{
        whiteMinted = false;
    }

    function mintOpened() public onlyOwner{
        minted = true;
    }

    function mintClosed()  public onlyOwner{
        minted = false;
    }
}