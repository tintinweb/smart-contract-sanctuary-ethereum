/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

contract EthernalLock {
    event LockCreated(address indexed _from, address indexed _lovee, uint indexed lockIndex, string _txt);
    event AdminCommandExecuted(address indexed _from);

    struct Color {
        uint8 R;
        uint8 G;
        uint8 B;
    }
    
    struct Lock {
        Color LockColor;
        Color TextColor;
        Color CustomColor1;
        Color CustomColor2;
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
        emit AdminCommandExecuted(msg.sender);

        owners[adr] = isOwner;
    }
    
    function setHighestValidLockType(uint count) public onlyowner {
        emit AdminCommandExecuted(msg.sender);

        highestValidLockType = count;
    }

    function disableLockCreation(uint number) public onlyowner {
        emit AdminCommandExecuted(msg.sender);

        lockCreationDisabled[number] = true;
    }

    //We want to be able to configure the lock prices incase the Ethereum price increases
    //This way we can keep the price of locks largely the same
    function setDefaultLockPrice(uint lockPrice) public onlyowner {
        emit AdminCommandExecuted(msg.sender);
        
        defaultLockPrice = lockPrice;
    }

    function setLockTypePrice(uint lockType, uint lockPrice) public onlyowner {
        require(lockType > 0, "Lock type should be bigger then 0");

        emit AdminCommandExecuted(msg.sender);

        customLockPrices[lockType] = lockPrice;
    }
    
    function cashOut() public onlyowner {
        emit AdminCommandExecuted(msg.sender);

        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function getLockPrice(uint lockType) public view returns (uint lockPrice) {
        uint thisLockPrice = customLockPrices[lockType];
        if (thisLockPrice == 0) {
            return defaultLockPrice;
        }
        return thisLockPrice;
    }

    function createLock(uint lockIndex, Color calldata lockColor, Color calldata textColor, Color calldata customColor1, Color calldata customColor2, uint lockType, string calldata text, bool encrypted, address lovee) public payable returns (uint pos) {
        uint curPrice = getLockPrice(lockType);
        require(msg.value >= curPrice, "Payment is not enough");

        uint txtLength = bytes(text).length;
        require(txtLength > 0, "Text length should be at least 1");
        require(txtLength <= 512, "Text length should be less than or equal 512");
        require(lockType <= highestValidLockType, "You can only create a lock with a type that's allowed");
        require(lockType > 0, "You can only create locks with a type that's > 0");
        require(locks[lockIndex].LockType == 0, "There's already a lock on this position"); //The lock does not exist yet (LockType == 0 means no lock)
        require(lockCreationDisabled[lockType] == false, "The lock type that's being created is disabled");

        locks[lockIndex] = Lock(
            {
                LockColor: lockColor,
                TextColor: textColor,
                CustomColor1: customColor1,
                CustomColor2: customColor2, 
                LockType: lockType,
                Text: text,
                Encrypted: encrypted,
                Lovee: lovee
            });
        
        lockCount++;
        
        emit LockCreated(msg.sender, lovee, lockIndex, text);

        return lockIndex;
    }

    function getLocksSet(uint start, uint count) public view returns (Lock[] memory lockSet) {
        Lock[] memory b = new Lock[](count);
        for (uint i=0; i < b.length; i++) {
            b[i] = locks[i + start];
        }
        return b;
    }
}