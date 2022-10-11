/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: NONE
// This code is copyright protected.
// All rights reserved © coinbird 2022
// The unauthorized reproduction, modification, expansion upon or redeployment of this work is illegal.
// Improvement suggestions are more than welcome. If you have any, please let the coinbird know and they will be examined.
// You are using this code at your own risk. We do not give any warranties and will not be liable for any loss, direct or indirect through use of this code.

pragma solidity 0.8.17;

// https://coinbird.io - BIRD!
// https://twitter.com/coinbirdtoken
// https://github.com/coinbirdtoken
// https://t.me/coinbirdtoken
// [email protected] - COINBIRD!

abstract contract SOLIDITY_CONTRACT {
    function name() external virtual view returns (string memory);

    function symbol() external virtual view returns (string memory);
    
    function decimals() external virtual view returns (uint8);
    
    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address account) external virtual view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (address);

    function transfer(address recipient, uint256 amount) external virtual returns (address);
}


abstract contract COINBIRD_CONNECTOR {
    function balanceOf(address account) external virtual view returns (uint256);
}


contract COINBIRD_TOKEN_LOCKER {
    COINBIRD_CONNECTOR public BIRD_FINDER;
    SOLIDITY_CONTRACT private USD_Accessor;

    address private cryptBIRD = 0xcC070A7c0f8993Fa4Eb4a6f6A372e2341fa743CC; // cryptBIRD is a friend of coinbird

    uint private _coinbirdThreshold;

    struct COINBIRD_LOCKS {
        address contractAccessed;
        string contractName;
        string contractSymbol;
        uint contractDecimals;
        uint amountLocked;
        uint lockDuration;
    }

    // _ProtectedFromBIRD[] is a mapping used in retrieving lock data

    mapping(address => COINBIRD_LOCKS[]) private _ProtectedFromBIRD;

    // safetyBIRD[] is a mapping designed to prevent creating multiple locks on an individual contract with the same wallet

    mapping(address => mapping(address => bool)) private safetyBIRD;

    constructor() {
        USD_Accessor = SOLIDITY_CONTRACT(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USD
    }

    // connectBirdy() returns the amount of BIRD a wallet needs to hold in order to create a new lock or modify an existing one

    function connectBirdy(address HookMeUp) public {
        require(msg.sender == cryptBIRD, "Thy attempts to tamper with holy values beyond your grasp have failed.");
        BIRD_FINDER = COINBIRD_CONNECTOR(HookMeUp);
    }

    // adjustLockerEntranceFee() allows the cryptBIRD to modify the coinbirdBouncer() entry value. Doesn't affect the claimUnlockedTokens() function.

    function adjustLockerEntranceFee(uint BIRDamount) public {
        require(msg.sender == cryptBIRD, "Thy attempts to tamper with holy values beyond your grasp have failed.");
        _coinbirdThreshold = BIRDamount;
    }

    // coinbirdBouncer() returns the amount of BIRD a wallet needs to hold in order to create a new lock or modify an existing one

    function coinbirdBouncer() public view returns (uint) {
        return _coinbirdThreshold;
    }

    // ownedBIRD() returns the amount of BIRD tokens the "user" address currently holds

    function ownedBIRD(address user) public view returns (uint) {
        return BIRD_FINDER.balanceOf(user);
    }

    // activeLocks() returns the number of locks that were created from the "user" address and are currently active

    function activeLocks(address user) public view returns (uint) {
        return _ProtectedFromBIRD[user].length;
    }

    // totalSupplyOfAccessedContract() returns the totalSupply of the "scanned" solidity based contract

    function totalSupplyOfAccessedContract(SOLIDITY_CONTRACT scanned) public view returns (uint) {
        return scanned.totalSupply();
    }

    // decimalsOfAccessedContract() returns the decimals of the "scanned" solidity based contract

    function decimalsOfAccessedContract(SOLIDITY_CONTRACT scanned) public view returns (uint) {
        return scanned.decimals();
    }

    // nameOfAccessedContract() returns the name of the "scanned" solidity based contract

    function nameOfAccessedContract(SOLIDITY_CONTRACT scanned) public view returns (string memory) {
        return scanned.name();
    }

    // symbolOfAccessedContract() returns the symbol of the "scanned" solidity based contract

    function symbolOfAccessedContract(SOLIDITY_CONTRACT scanned) public view returns (string memory) {
        return scanned.symbol();
    }

    // lockableTokensInAccessedContract() returns the amount of tokens the "user" address hold in the scanned solidity based contract

    function lockableTokensInAccessedContract(SOLIDITY_CONTRACT scanned, address user) public view returns (uint) {
        return scanned.balanceOf(user);
    }

    // lockBIRD() return the values stored in the _ProtectedFromBIRD mapping, position [locker][value]

    function lockBIRD(address locker, uint value) public view returns (address, string memory, string memory, uint, uint, uint) {
        require(value < _ProtectedFromBIRD[locker].length, "Invalid value entered.");
        return (
            _ProtectedFromBIRD[locker][value].contractAccessed,
            _ProtectedFromBIRD[locker][value].contractName,
            _ProtectedFromBIRD[locker][value].contractSymbol,
            _ProtectedFromBIRD[locker][value].contractDecimals,
            _ProtectedFromBIRD[locker][value].amountLocked,
            _ProtectedFromBIRD[locker][value].lockDuration);
    }

    // createNewLock() is a function used in order to create a new lock in the SolidityContract specified in the input

    function createNewLock(address SolidityContract, uint amount, uint time) public {
        if (BIRD_FINDER == COINBIRD_CONNECTOR(0x0000000000000000000000000000000000000000)  || (BIRD_FINDER != COINBIRD_CONNECTOR(0x0000000000000000000000000000000000000000) && ownedBIRD(msg.sender) < coinbirdBouncer())) {
            USD_Accessor.transferFrom(msg.sender, cryptBIRD, 10000000);
        }
        require(safetyBIRD[msg.sender][SolidityContract] == false, "You already have an active lock in this contract.");
        SOLIDITY_CONTRACT contractBIRD = SOLIDITY_CONTRACT(SolidityContract);
        require(amount > 0 && time > 0, "Trivial.");
        require(contractBIRD.balanceOf(msg.sender) >= amount, "Amount entered exceeds amount owned.");
        safetyBIRD[msg.sender][SolidityContract] = true;
        contractBIRD.transferFrom(msg.sender, address(this), amount);
        COINBIRD_LOCKS memory newLock = COINBIRD_LOCKS(SolidityContract, contractBIRD.name(), contractBIRD.symbol(), contractBIRD.decimals(), amount, block.timestamp+time);
        _ProtectedFromBIRD[msg.sender].push(newLock);
    }

    // increaseLockDuration() can be called whenever the msg.sender wishes to increase the duration of an active lock they previously created
    
    function increaseLockDuration(uint hatchling, uint time) public {
        if (BIRD_FINDER == COINBIRD_CONNECTOR(0x0000000000000000000000000000000000000000)  || (BIRD_FINDER != COINBIRD_CONNECTOR(0x0000000000000000000000000000000000000000) && ownedBIRD(msg.sender) < coinbirdBouncer())) {
            USD_Accessor.transferFrom(msg.sender, cryptBIRD, 4000000);
        }
        require(safetyBIRD[msg.sender][_ProtectedFromBIRD[msg.sender][hatchling].contractAccessed] == true, "You do not have an active lock in this contract.");
        require(time > 0, "Trivial.");
        _ProtectedFromBIRD[msg.sender][hatchling].lockDuration += time;
    }

    // increaseLockedAmount() can be called whenever the msg.sender wishes to increase the amount of tokens within an active lock they previously created

    function increaseLockedAmount(uint hatchling, uint amount) public {
        if (BIRD_FINDER == COINBIRD_CONNECTOR(0x0000000000000000000000000000000000000000)  || (BIRD_FINDER != COINBIRD_CONNECTOR(0x0000000000000000000000000000000000000000) && ownedBIRD(msg.sender) < coinbirdBouncer())) {
            USD_Accessor.transferFrom(msg.sender, cryptBIRD, 4000000);
        }
        address protectionBIRD = _ProtectedFromBIRD[msg.sender][hatchling].contractAccessed;
        require(safetyBIRD[msg.sender][protectionBIRD] == true, "You do not have an active lock in this contract.");
        require(amount > 0, "Trivial.");
        SOLIDITY_CONTRACT contractBIRD = SOLIDITY_CONTRACT(protectionBIRD);
        require(contractBIRD.balanceOf(msg.sender) >= amount, "Amount entered exceeds amount owned.");
        contractBIRD.transferFrom(msg.sender, address(this), amount);
        _ProtectedFromBIRD[msg.sender][hatchling].amountLocked += amount;
    }

    // claimUnlockedTokens() can be called whenever the msg.sender wishes to retrieve tokens they had stored in a lock which has now expired

    function claimUnlockedTokens(uint hatchling) public {
        require(_ProtectedFromBIRD[msg.sender][hatchling].lockDuration < block.timestamp, "The lock is still active."); 
        address accessBIRD = _ProtectedFromBIRD[msg.sender][hatchling].contractAccessed;
        SOLIDITY_CONTRACT contractBIRD = SOLIDITY_CONTRACT(accessBIRD);
        require(safetyBIRD[msg.sender][accessBIRD] == true, "Reentrancy protection.");
        safetyBIRD[msg.sender][accessBIRD] = false;
        contractBIRD.transfer(msg.sender, _ProtectedFromBIRD[msg.sender][hatchling].amountLocked);
        uint dummyBIRD = _ProtectedFromBIRD[msg.sender].length - 1;
        COINBIRD_LOCKS memory killerBIRD = _ProtectedFromBIRD[msg.sender][dummyBIRD];
        _ProtectedFromBIRD[msg.sender][hatchling] = killerBIRD;
        _ProtectedFromBIRD[msg.sender].pop();
    }
}