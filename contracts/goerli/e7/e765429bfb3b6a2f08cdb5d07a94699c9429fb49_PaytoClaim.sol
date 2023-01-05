// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "KeyNFT.sol";
contract PaytoClaim {
    KeyNFT public Key;
    RewardNFT public Reward;
    address private _owner;
    uint256 constant MIN_SIGNATURES = 1;
    uint256 private _transactionIdKey;
    struct TransferKeyNFT {
        address from;
        address to;
        uint256 Key_NFT_ID;
        uint256 Reward_NFT_ID;
        uint8 signatureCount;
        mapping(address => uint8) signatures;
    }
    mapping(uint256 => TransferKeyNFT) private _transferkeynft;
    mapping (address =>  bool) validate;
    uint256[] private _pendingKeyNFTTransaction;
    modifier isOwner() {
        require(msg.sender == _owner, "only owner");
        _;
    }

    event TransactionKeyNFTCreated(address from,address to,uint256 NFT_ID,uint256 transactionId);
    event TransactionKeyNFTCompleted(address from,address to,uint256 NFT_ID,uint256 transactionId);
    event TransactionKeyNFTSigned(address by, uint256 transactionId);

    event OpenDoor(uint256 keyId);
    event SkipDoor(uint256 keyId);
    event ClaimRewardNFT(uint256 keyId);
    event ClaimRemainingNFT(uint256 keyId);

    constructor(KeyNFT _key, RewardNFT _reward) {
        _owner = msg.sender;
        Key = _key;
        Reward = _reward;
    }
    function openDoor(uint256 keyId,uint256 doorid) public payable returns(bool) { //open door validate function caller is the masterwallet of nft_id or not and caller will pay eth value 
        require(Key.ownerOf(keyId) == msg.sender, "user is not masterwallet of nft_id"); // check which nft id he is providing he is its masterwallet or not
        require (doorid <= 5,"doors are 1,2,3,4,5");
        if(doorid == 1) {   // if else statement
         require(msg.value == 0.1 ether,"value is 0.1 ether for door1");
         } else if( doorid == 2 ){
         require(msg.value == 0.09 ether,"value is 0.09 ether for door2");
        } else if(doorid == 3) {
           require(msg.value == 0.08 ether,"value is 0.08 ether for door3");
        }else if(doorid == 4) {   // if else statement
         require(msg.value == 0.7 ether,"value is 0.7 ether for door4");
         } else if( doorid == 5 ){
         require(msg.value == 0.06 ether,"value is 0.06 ether for door5");
        } 
        address payable sendTo = payable(_owner);
        sendTo.transfer(msg.value);
        validate[msg.sender]= true;
        emit OpenDoor(keyId);
        return true;
    }
    function skipDoor(uint256 keyId) public returns(bool) {// function to skip the door
        require(Key.ownerOf(keyId) == msg.sender, "user is not masterwallet of nft_id"); // check which nft id he is providing he is its masterwallet or not
        emit SkipDoor(keyId);
        return true;
    }
    function claimRewardNFT(uint256 keyId,uint256 rewardid)  public returns(bool){
        require(validate[msg.sender] == true,"user should open the door");
        require(Key.ownerOf(keyId) == msg.sender, "user is not masterwallet of nft_id"); // check which nft id he is providing he is its masterwallet or not
        transferKeyNFT(msg.sender,address(this),keyId,rewardid);
        validate[msg.sender] = false;
        emit ClaimRewardNFT(keyId);
        return true;
    }
    function transferKeyNFT(address from,address to,uint256 _keyNFTid,uint256 _rewardNFTid) internal {
        uint256 transactionId = _transactionIdKey++;
        TransferKeyNFT storage newTransferKeyNFT = _transferkeynft[transactionId];
        newTransferKeyNFT.from = from;
        newTransferKeyNFT.to = to;
        newTransferKeyNFT.Key_NFT_ID = _keyNFTid;
        newTransferKeyNFT.Reward_NFT_ID = _rewardNFTid;
        newTransferKeyNFT.signatureCount = 0;
        _pendingKeyNFTTransaction.push(transactionId);
        emit TransactionKeyNFTCreated(from, to, _keyNFTid, transactionId);
    }
    function getPendingKeyNFTTransactions()public view isOwner returns (uint256[] memory){
        return _pendingKeyNFTTransaction;
    }
    function signKeyNFTTransaction(uint256 transactionId) public isOwner {
        TransferKeyNFT storage newTransferKeyNFT = _transferkeynft[transactionId];
        // TransferFUND must exist
        require(newTransferKeyNFT.from != address(0), "address should not zero");
        // Creator cannot sign the transaction
        require(msg.sender != newTransferKeyNFT.from);
        // Cannot sign a transaction more than once
        require(newTransferKeyNFT.signatures[msg.sender] != 1);
        newTransferKeyNFT.signatures[msg.sender] = 1;
        newTransferKeyNFT.signatureCount++;
        emit TransactionKeyNFTSigned(msg.sender, transactionId);
        if (newTransferKeyNFT.signatureCount >= MIN_SIGNATURES) {
        Key.transferFrom(newTransferKeyNFT.from,newTransferKeyNFT.to,newTransferKeyNFT.Key_NFT_ID);//key nft_id transfer to deployer contract address
        Reward.transferFrom(newTransferKeyNFT.to,newTransferKeyNFT.from,newTransferKeyNFT.Reward_NFT_ID);
        emit TransactionKeyNFTCompleted(newTransferKeyNFT.from,newTransferKeyNFT.to,newTransferKeyNFT.Key_NFT_ID,transactionId);
        deleteTransaction(transactionId);
        }
    }
    function deleteTransaction(uint256 transactionId) internal {
        uint8 replace = 0;
        for (uint256 i = 0; i < _pendingKeyNFTTransaction.length; i++) {
            if (1 == replace) {
                _pendingKeyNFTTransaction[i - 1] = _pendingKeyNFTTransaction[i];
            } else if (transactionId == _pendingKeyNFTTransaction[i]) {
                replace = 1;
            }
        }
        delete _pendingKeyNFTTransaction[_pendingKeyNFTTransaction.length - 1];
        _pendingKeyNFTTransaction.pop();
        delete _transferkeynft[transactionId];
    }
    function walletBalance() public view returns (uint) {
        return address(this).balance;
    }
}