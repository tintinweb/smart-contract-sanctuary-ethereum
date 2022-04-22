// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.0;

contract ContractRenounce {

    address contractAddress;
    address payable feeWallet;
    uint256 _lockFee;
    uint256 _breakGlassFee;

    struct Lock {
        address originalOwner;
        address currentOwner;
        address contractAddress;
        uint256 unlockTime;
        uint256 createdAt;
    }

    struct ContractLock {
        Lock[] lock;
    }

    modifier _feeWalletHolder() {
        require( feeWallet == msg.sender, "Only the owner fee wallet can call this!");
        _; 
    }

    mapping (address => uint) internal payment;
    //mapping (address => uint) internal numContracts;
    //mapping ( uint => Lock ) public locks;

    mapping ( address => ContractLock ) contractLocks;

    //uint256 _nextLocktId;

    uint unlockTime = 0;

    constructor(){
        contractAddress = msg.sender;
        feeWallet = payable(msg.sender);
        _lockFee = 100000000000000000; // 0.1 ETH
        _breakGlassFee = 1000000000000000000; // 1 ETH
        //_nextLocktId = 0;
    }

    function lockContract( address _contractAddress, uint _timeLock ) payable public {
        require( msg.value == _lockFee, "ERROR: Fee not paid!" );
        address _contractOwner = getOwner( _contractAddress );
        require( _contractOwner == msg.sender, "ERROR: Wallet is not the owner of this contract!" );
        Lock memory newLock = Lock( msg.sender, address(this), _contractAddress, block.timestamp + _timeLock, block.timestamp );
        contractLocks[msg.sender].lock.push( newLock );
        payFee(_lockFee, feeWallet);
    }

    function returnContract( address _contractAddress ) payable public returns (bool _success){
        require(msg.value == _lockFee, "ERROR: Fee not paid!");
        _success = false;
    //     for (uint i = 0; i < _nextLocktId; i++) {
    //         if ( locks[i].contractAddress == _contract && locks[i].currentOwner == address(this) ){
    //             require( numContracts[msg.sender] > 0, "ERROR: No contracts recorded for this account!");
    //             require( locks[i].wallet == msg.sender, "ERROR: Wallet is not the original owner of this contract!");
    //             require( locks[i].unlockTime <= block.timestamp, "Error: Contract still locked!");
    //             locks[i].isLocked = false;
    //             bool _transferSuccess = transferContract(_contract, msg.sender);
    //             require(_transferSuccess == true, "ERROR: Contract not transferred!");

    //             if (numContracts[msg.sender] > 1){
    //                 numContracts[msg.sender] -= 1;
    //             }
    //             locks[i].currentOwner = msg.sender;
    //             locks[i].isDeleted = true;
    //             payFee(_lockFee, feeWallet);
    //             _success = true;
    //         }
    //     }
    //     return _success;
        for ( uint256 i = 0 ; i < contractLocks[msg.sender].lock.length; i++ ){
            if ( contractLocks[msg.sender].lock[i].contractAddress == _contractAddress && contractLocks[msg.sender].lock[i].currentOwner == address(this) ){
                require( contractLocks[msg.sender].lock[i].unlockTime <= block.timestamp, "Error: Contract still locked!");
                bool _transferSuccess = transferContract( _contractAddress, msg.sender );
                require( _transferSuccess == true, "ERROR: Contract not transferred!" );
                contractLocks[msg.sender].lock[i]= contractLocks[msg.sender].lock[contractLocks[msg.sender].lock.length - 1];
                contractLocks[msg.sender].lock.pop();
                payFee(_lockFee, feeWallet);
                _success = true;
                break;
            }
        }
        return _success;
    }

    function breakGlass( address _contractAddress ) payable public returns (bool _success){
        require(msg.value == _breakGlassFee, "ERROR: Fee not paid!");
        _success = false;
    //     for (uint i = 0; i < _nextLocktId; i++) {
    //         if ( locks[i].contractAddress == _contract  && locks[i].currentOwner == address(this) ){
    //             require( numContracts[msg.sender] > 0, "ERROR: No contracts recorded for this account!");
    //             require( locks[i].wallet == msg.sender, "ERROR: Wallet is not the original owner of this contract!");
    //             locks[i].isLocked = false;
    //             bool _transferSuccess = transferContract(_contract, msg.sender);
    //             require(_transferSuccess == true, "ERROR: Contract not transferred!");
    //             if (numContracts[msg.sender] > 1){
    //                 numContracts[msg.sender] -= 1;
    //             }
    //             locks[i].currentOwner = msg.sender;
    //             locks[i].isDeleted = true;
    //             payFee(_breakGlassFee, feeWallet);
    //             _success = true;
    //         }
    //     }
    //     return _success;
        for ( uint256 i = 0 ; i < contractLocks[msg.sender].lock.length; i++ ){
            if ( contractLocks[msg.sender].lock[i].contractAddress == _contractAddress && contractLocks[msg.sender].lock[i].currentOwner == address(this) ){
                bool _transferSuccess = transferContract(_contractAddress, msg.sender);
                require(_transferSuccess == true, "ERROR: Contract not transferred!");
                contractLocks[msg.sender].lock[i]= contractLocks[msg.sender].lock[contractLocks[msg.sender].lock.length - 1];
                contractLocks[msg.sender].lock.pop();
                payFee(_breakGlassFee, feeWallet);
                _success = true;
                break;
            }
        }
        return _success;
    }

    function getOwner(address _contract) private returns (address){
        (bool success, bytes memory _data) = _contract.call(abi.encodeWithSignature("owner()"));
        require(success == true, "ERROR: Call to owner() failed!");
        address _address = abi.decode(_data, (address));
        return _address;
    }

    function transferContract(address _contract, address _newOwner) private returns (bool){
        (bool _success,) = _contract.call(abi.encodeWithSignature("transferOwnership(address)", _newOwner ));
        return _success;
    }

    function getLocks() public view returns (Lock[] memory){
        return contractLocks[msg.sender].lock;
    }

    function setFeeWallet(address payable _wallet) public _feeWalletHolder {
        feeWallet = _wallet;
    }

    function feeWalletHolder() public view returns (address){
        return feeWallet;
    }

    function setLockFee(uint256 _amount) public _feeWalletHolder{
        _lockFee = _amount;
    }

    function lockFee() public view returns (uint256){
        return _lockFee;
    }

    function setBreakGlassFee(uint256 _amount) public _feeWalletHolder{
        _breakGlassFee = _amount;
    }

    function breakGlassFee() public view returns (uint256){
        return _breakGlassFee;
    }

    function payFee( uint256 _amount, address payable _recipient) public payable {
        require( _amount == _lockFee || _amount == _breakGlassFee, "Incorrect fee amount provided!" );
        _recipient.transfer(_amount);
    }

    receive() external payable {}

}