/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// File: EthernalLock.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;
pragma experimental ABIEncoderV2;

contract EthernalLock {
    event LockCreated(address indexed _from, address indexed _lovee, string _txt);

    struct Color {
        uint8 R;
        uint8 G;
        uint8 B;
    }
    
    struct Lock {
        Color BackgroundColor;
        Color LockColor;
        Color LabelColor;
        Color TextColor;
        uint LockType;
        
        string Text;
        bool Encrypted;

        address Lovee;
    }
    
    uint public defaultLockPrice;
    mapping(uint => Lock) public locks;
    uint public lockCount;
    
    mapping(address => bool) public owners;

    mapping(uint => uint) public customLockPrices;
    mapping(uint => bool) public lockCreationDisabled;
    uint public highestValidLockType;    
    
    modifier onlyowner() {
        require(owners[msg.sender] == true, "Caller is not owner");
        _;
    }    
    
    constructor() {
        defaultLockPrice = 0.01 ether;
        owners[msg.sender] = true;
    }    
    
    function setOwner(address adr, bool isOwner) public onlyowner {
        owners[adr] = isOwner;
    }
    
    function setHighestValidLockType(uint count) public onlyowner {
        highestValidLockType = count;
    }

    function disableLockCreation(uint number) public onlyowner {
        lockCreationDisabled[number] = true;
    }

    //We want to be able to configure the lock prices incase the Ethereum price increases
    //This way we can keep the price of locks largely the same
    function setDefaultLockPrice(uint lockPrice) public onlyowner {
        defaultLockPrice = lockPrice;
    }

    function setLockTypePrice(uint lockType, uint lockPrice) public onlyowner {
        customLockPrices[lockType] = lockPrice;
    }
    
    function cashOut() public onlyowner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getLockPrice(uint lockType) public view returns (uint lockPrice) {
        uint thisLockPrice = customLockPrices[lockType];
        if (thisLockPrice == 0) {
            return defaultLockPrice;
        }
        return thisLockPrice;
    }

    function testStruct(uint lockIndex, Color calldata backgroundColor) public {
        
    }
    
    function createLock(uint lockIndex, Color calldata backgroundColor, Color calldata lockColor, Color calldata labelColor, Color calldata textColor, uint lockType, string calldata text, bool encrypted, address lovee) public payable returns (uint pos) {
        uint curPrice = getLockPrice(lockType);
        require(msg.value >= curPrice, "Payment is not enough");

        require(bytes(text).length > 0, "Text length should be at least 1");
        require(bytes(text).length <= 512, "Text length should be less than or equal 512");
        require(lockType <= highestValidLockType, "You can only created a lock with a type that's allowed");
        require(lockType > 0, "You can only create locks with a type that's > 0");
        require(locks[lockIndex].LockType == 0); //The lock does not exist yet (LockType == 0 means no lock)

        locks[lockIndex] = Lock(
            {
                BackgroundColor: backgroundColor, 
                LockColor: lockColor,
                LabelColor: labelColor,
                TextColor: textColor,
                LockType: lockType,
                Text: text,
                Encrypted: encrypted,
                Lovee: lovee
            });
        
        lockCount++;
        
        emit LockCreated(msg.sender, lovee, text);

        return lockIndex;
    }
    
    function getLockCount() public view returns (uint count) {
        return lockCount;
    }

    function getLocksSet(uint start, uint count) public view returns (Lock[] memory lockSet) {
        Lock[] memory b = new Lock[](count);
        for (uint i=0; i < b.length; i++) {
            b[i] = locks[i + start];
        }
        return b;
    }
}