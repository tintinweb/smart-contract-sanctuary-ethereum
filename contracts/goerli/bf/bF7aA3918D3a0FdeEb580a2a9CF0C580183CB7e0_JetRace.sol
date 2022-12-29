/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract JetRace is Ownable {

    address public signer;

    mapping(uint256 => mapping(uint256 => uint256)) public jetRaceInfo;
    mapping (bytes32 => bool) public hashVerify;

    event Deposit(address User, uint256 Amount, uint256 RaceID, uint256 DepositTime);
    event Withdraw(address User, uint256 Amount, uint256 WithdrawTime);

    constructor(address _signer) {
        signer = _signer;
    }

    function deposit(uint256 _raceID,uint256 _jetID, uint256 _blockTime, uint8 _V, bytes32 _R, bytes32 _S) external payable{
        require(jetRaceInfo[_raceID][_jetID] == 0,"already deposited");

        bytes32 msgHash = toSigEthMsg(msg.sender, msg.value, _blockTime);
        require(!hashVerify[msgHash],"Claim :: signature already used");
        require(verifySignature(msgHash, _V, _R, _S) == signer,"Claim :: not a signer address");
        hashVerify[msgHash] = true;

        jetRaceInfo[_raceID][_jetID] = msg.value;
        emit Deposit(msg.sender, msg.value, _raceID, block.timestamp);
    }

    function withdraw(uint256 _amount, uint256 _blockTime, uint8 _V, bytes32 _R, bytes32 _S) external {
        require(_blockTime >= block.timestamp,"Time Expired");
        bytes32 msgHash = toSigEthMsg(msg.sender, _amount, _blockTime);
        require(!hashVerify[msgHash],"Claim :: signature already used");
        require(verifySignature(msgHash, _V, _R, _S) == signer,"Claim :: not a signer address");
        hashVerify[msgHash] = true;

        require(payable(msg.sender).send(_amount),"transfer fails");
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    function verifySignature(bytes32 msgHash, uint8 v,bytes32 r, bytes32 s)public pure returns(address signerAdd){
        signerAdd = ecrecover(msgHash, v, r, s);
    }
    
    function toSigEthMsg(address _user, uint256 _tokenAmount, uint256 _blockTime)internal view returns(bytes32){
        bytes32 hash = getHash(_user, _tokenAmount, _blockTime);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function getHash(address _user, uint256 _tokenAmount, uint256 _blockTime)public view returns(bytes32){
        return keccak256(abi.encodePacked(abi.encodePacked(_user, _tokenAmount, _blockTime),address(this)));
    }

    function setSigner(address _signer)external onlyOwner{
        require(_signer != address(0) && signer != _signer,"signer address not Zero address");
        signer = _signer;
    }

    function recover(address _to, uint256 _amount) external onlyOwner {
        require(payable(_to).send(_amount),"recover fail");
    }

}