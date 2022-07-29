/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier:Unlicense
pragma solidity ^0.8.13;

library SafeMathAssembly {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            c := add(a,b)
        }
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath subraction overFloe");
        assembly {
            c := sub(a,b)
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        assembly {
            c := mul(a,b)
        }
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0,  "SafeMath: division by zero");
        assembly {
            c := div(a,b)
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 res) {
        require(b != 0, "SafeMath: modulo by zero");
        assembly {
            res := mod(a,b)
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal pure returns(bytes memory){
        return(msg.data);
    }
}

abstract contract Pausable is Context {

    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns(bool){
        return _paused;
    }

    modifier whenNotPaused{
        require(!paused(),"Pasuable : Paused");
        _;
    }

    modifier whenPaused(){
        require(paused(),"Pasuable : Not Paused");
        _;
    }

    function _pause() internal whenNotPaused{
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal whenPaused{
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context{

    address private _owner;

    event TransferOwnerShip(address indexed oldOwner, address indexed newOwner);

    constructor () {
        _owner = _msgSender();
        emit TransferOwnerShip(address(0), _owner);
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(),"Only allowed to Owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0),"ZEROADDRESS");
        require(_newOwner != _owner, "Entering OLD_OWNER_ADDRESS");
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal onlyOwner {
        _owner = _newOwner;
        emit TransferOwnerShip(_owner, _newOwner);
    }

    function renonceOwnerShip() external onlyOwner {
        _owner = address(0);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract MyDeposit is Ownable, Pausable, ReentrancyGuard{

    using SafeMathAssembly for uint256;

    address public signerAddress;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(address => uint) public balanceOf;
    mapping(bytes32 => bool) private Signstatus;

    event Deposit(address indexed _account,uint indexed amount);
    event Withdrawal(address indexed _account,uint indexed amount);

    constructor(address _signerAddress){
        assembly{
            sstore(signerAddress.slot,_signerAddress)
        }
    }

    function deposit() external whenNotPaused payable{
        require(msg.value !=0 ,"INVALID ETHER");

        balanceOf[_msgSender()] = balanceOf[_msgSender()].add(msg.value);

        emit Deposit(_msgSender(),msg.value);
    }

    function withdraw(uint256 _amount ,Sig memory _sig) external whenNotPaused nonReentrant{
        require(balanceOf[_msgSender()]>=_amount,"INSUFFICIENT FUND");

        validateSignature(_msgSender(), _amount, _sig);

        balanceOf[_msgSender()] = balanceOf[_msgSender()].sub(_amount);

        bool success;
        assembly{
            success := call(gas(), caller(),  _amount,0,0,0,0)
        }
        require(success, "WITHDRAW FAILED");

        emit Withdrawal(_msgSender(),_amount);
    }

    function balance() public view returns(uint){
       return (address(this).balance);
    }

    function updateSigner(address _newSigner) external onlyOwner returns(bool){
        require(_newSigner != address(0), "INVALID NEW SIGNER ADDRESS");

        assembly{
            sstore(signerAddress.slot,_newSigner)
        }

        return true;
    }

    function validateSignature(address _user, uint _amount, Sig memory _sig) private {
        bytes32 hash = prepareHash(_user,address(this),_amount);
        require(!Signstatus[hash], "ALREADY_SIGNED");
        Signstatus[hash] = true;
        require(ecrecover(hash, _sig.v, _sig.r, _sig.s) == signerAddress , "INVALID_SIGNATURE");
    }

    function prepareHash(address _user, address _contract, uint _amount)private pure returns(bytes32){
        bytes32 hash = keccak256(
            abi.encodePacked(
                _user,
                _contract,
                _amount
            )
        );
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}