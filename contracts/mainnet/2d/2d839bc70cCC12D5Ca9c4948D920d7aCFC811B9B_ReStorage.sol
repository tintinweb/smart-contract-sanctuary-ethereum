/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma experimental ABIEncoderV2;

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



interface IReStorage {
  function contain(bytes32 _name) external view returns(bool);
}


contract ReStorage is IReStorage, Ownable{

    mapping (bytes32 => bool) retainStorage;

    bool storaged;

    event Storage(string _str);
    event UnStorage(string _str);

    constructor(bool _storaged) public{
        storaged =_storaged;
    }

    function addStorage(string[] memory _name) public onlyOwner{
        for (uint i = 0; i < _name.length; i++) {
            bytes32 _label = keccak256(bytes(_name[i]));

            if(!retainStorage[_label]){
                retainStorage[_label] = true;
                emit Storage(_name[i]);
            }
        }
    }

    function rmStorage(string[] memory _name) public onlyOwner{
        for (uint i = 0; i < _name.length; i++) {
            bytes32 _label = keccak256(bytes(_name[i]));

            if(retainStorage[_label]){
                retainStorage[_label] = false;
                emit UnStorage(_name[i]);
            }
        }
    }

    function storageClose()public onlyOwner{
        storaged = false;
    }

    function storageOpen()public onlyOwner{
        storaged = true;
    }

    function contain(bytes32 _labelHash) external view returns(bool){
        if(!storaged)
            return false;
        return retainStorage[_labelHash];
    }
}