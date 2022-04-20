// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.0;

contract ContractRenounce {

    address contractAddress;
    address payable feeWallet;
    uint256 _lockFee;
    uint256 _breakGlassFee;

    struct Lock {
        uint Id;
        address wallet;
        address currentOwner;
        address contractAddress;
        uint unlockTime;
        bool isDeleted;
        bool isLocked;
        uint createdAt;
    }

    modifier _feeWalletHolder() {
        require( feeWallet == msg.sender, "Only the owner fee wallet can call this!");
        _; 
    }

    mapping (address => uint) internal payment;
    mapping (address => uint) internal numContracts;
    mapping ( uint => Lock ) public locks;
    uint256 _nextLocktId;

    uint unlockTime = 0;

    constructor(){
        contractAddress = msg.sender;
        feeWallet = payable(msg.sender);
        _lockFee = 100000000000000000; // 0.1 ETH
        _breakGlassFee = 1000000000000000000; // 1 ETH
        _nextLocktId = 0;
    }

    function lockContract( address _contract, uint _timeInTicks ) payable public {
        require(msg.value == _lockFee, "ERROR: Fee not paid!");
        address contractOwner = getOwner(_contract);
        require(contractOwner == msg.sender, "ERROR: Wallet is not the owner of this contract!");
        numContracts[msg.sender] += 1;
        locks[_nextLocktId] = Lock( _nextLocktId, msg.sender, address(this), _contract, block.timestamp + _timeInTicks, false, true, block.timestamp );
        _nextLocktId += 1;
        payFee(_lockFee, feeWallet);
    }

    function returnContract( address _contract ) payable public returns (bool _success){
        require(msg.value == _lockFee, "ERROR: Fee not paid!");
        _success = false;
        for (uint i = 0; i < _nextLocktId; i++) {
            if ( locks[i].contractAddress == _contract && locks[i].currentOwner == address(this) ){
                require( numContracts[msg.sender] > 0, "ERROR: No contracts recorded for this account!");
                require( locks[i].wallet == msg.sender, "ERROR: Wallet is not the original owner of this contract!");
                require( locks[i].unlockTime <= block.timestamp, "Error: Contract still locked!");
                locks[i].isLocked = false;
                bool _transferSuccess = transferContract(_contract, msg.sender);
                require(_transferSuccess == true, "ERROR: Contract not transferred!");

                if (numContracts[msg.sender] > 1){
                    numContracts[msg.sender] -= 1;
                }
                locks[i].currentOwner = msg.sender;
                locks[i].isDeleted = true;
                payFee(_lockFee, feeWallet);
                _success = true;
            }
        }
        return _success;
    }

    function breakGlass( address _contract ) payable public returns (bool _success){
        require(msg.value == _breakGlassFee, "ERROR: Fee not paid!");
        _success = false;
        for (uint i = 0; i < _nextLocktId; i++) {
            if ( locks[i].contractAddress == _contract  && locks[i].currentOwner == address(this) ){
                require( numContracts[msg.sender] > 0, "ERROR: No contracts recorded for this account!");
                require( locks[i].wallet == msg.sender, "ERROR: Wallet is not the original owner of this contract!");
                locks[i].isLocked = false;
                bool _transferSuccess = transferContract(_contract, msg.sender);
                require(_transferSuccess == true, "ERROR: Contract not transferred!");
                if (numContracts[msg.sender] > 1){
                    numContracts[msg.sender] -= 1;
                }
                locks[i].currentOwner = msg.sender;
                locks[i].isDeleted = true;
                payFee(_breakGlassFee, feeWallet);
                _success = true;
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

    function getContracts() public view returns (Lock[] memory){
        //require( numContracts[msg.sender] >= 0 , "ERROR: No contracts recorded for account!");
        uint contractNum = numContracts[msg.sender];
        uint contractId = 0;
        Lock[] memory contracts = new Lock[](contractNum);
        for (uint i = 0; i < _nextLocktId; i++) {
            if ( locks[i].wallet == msg.sender && locks[i].isDeleted == false && locks[i].createdAt > 0 ){
                contracts[contractId] = locks[i];
                contractId += 1;
            }
        }
        return contracts;
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