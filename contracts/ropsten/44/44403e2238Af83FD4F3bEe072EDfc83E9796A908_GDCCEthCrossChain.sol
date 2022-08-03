/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Context {

    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal pure returns(bytes memory){
        return(msg.data);
    }

}

abstract contract Pausable is Context {

    event Paused(address indexed account, uint indexed time);
    event Unpaused(address indexed account, uint indexed time);

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
        emit Paused(_msgSender(),block.timestamp);
    }

    function _unpause() internal whenPaused{
        _paused = false;
        emit Unpaused(_msgSender(),block.timestamp);
    }

}

abstract contract Ownable is Context{

    address private _owner;

    event TransferOwnerShip(address indexed oldOwner, address indexed newOwner, uint256 indexed time);

    constructor () {
        _owner = _msgSender();
        emit TransferOwnerShip(address(0), _owner ,block.timestamp);
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(),"NOT AN OWNER");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"ZEROADDRESS");
        require(newOwner != _owner, "ENTERING OLD_OWNER_ADDRESS");
        emit TransferOwnerShip(_owner, newOwner ,block.timestamp);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal onlyOwner {
        _owner = newOwner;
    }

    function renonceOwnerShip() public onlyOwner {
        _owner = address(0);
    }

}

abstract contract ReentrancyGuard {
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;
    uint8 private _status;

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

contract GDCCEthCrossChain is Ownable, Pausable, ReentrancyGuard {

    address public signer;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes4 private constant SELECTORTRANSFERFROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant SELECTORTRANFSFER = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant SELECTORBALANCEOF = bytes4(keccak256(bytes('balanceOf(address)')));

    mapping (address => bool) private approvedToken;
    mapping (bytes32 => bool) private Signstatus;

    event DepositToken (address indexed user, address indexed token, uint256 indexed amount, uint time);
    event WithdrawToken (address indexed user, address indexed token, uint256 indexed amount, uint time);
    event DepositEth (address indexed user, uint256 indexed amount, uint time);
    event WithdrawEth (address indexed user, uint256 indexed amount, uint time);
    event AddToken (address indexed token, uint256 indexed amount, uint time);
    event FailSafeForToken(address indexed token, address indexed user, uint256 indexed amount, uint time);
    event FailSafeForEther(address indexed user, uint256 indexed amount, uint time);
    event FallBack(address indexed user, uint256 indexed amount, uint time);

    modifier isContractCheck(address _user) {
        require(!isContract(_user), "INVALID ADDRESS");
        _;
    }

    constructor(address _signer){
        signer = _signer;
    }

    receive() external payable {
        emit FallBack(_msgSender(), msg.value, block.timestamp);
    }

    function addTokenBalance(address _token, uint _amount) external onlyOwner {
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        _selectorTransferFrom(_token, _amount);

        emit AddToken(_token, _amount, block.timestamp);
    }

    function tokenDeposit(address _token, uint _amount) external whenNotPaused isContractCheck(_msgSender()) nonReentrant{
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(approvedToken[_token], "NOT AN APPROVED TOKEN");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        _selectorTransferFrom(_token, _amount);

        emit DepositToken(_msgSender(), address(_token), _amount, block.timestamp);
    }

    function tokenWithdraw(Sig memory _sig, address _user, address _token, uint256 _amount, uint _expiry) external whenNotPaused isContractCheck(_user) nonReentrant{
        require(_token != address(0) && _amount > 0, "ENTERING_ZERO_ADDRESS || INVALID TOKEN_AMOUNT");
        require(approvedToken[_token], "NOT AN APPROVED_TOKEN");
        require(_selectorBalanceOf(_token, address(this)) >= _amount, "INSUFFICIENT_CONTRACT_FUND");
        require(block.timestamp <= _expiry, "EXPIRY_TIME_OUT");

        validateSignatureForToken(_user, _sig, _token, _amount, _expiry);

        _selectorTransfer(_token, _user, _amount);

        emit WithdrawToken(_user, address(_token), _amount, block.timestamp);
    }

    function etherDeposit() external payable whenNotPaused isContractCheck(_msgSender()) nonReentrant{
        require(msg.value > 0, "INVALID ETHER");

        emit DepositEth(_msgSender(), msg.value, block.timestamp);
    }

    function etherWithdraw(Sig memory _sig, address _user, uint256 _amount, uint _expiry) external whenNotPaused isContractCheck(_user) nonReentrant{
        require(block.timestamp <= _expiry,"EXPIRY_TIME_OUT");
        require(address(this).balance >= _amount, "INSUFFICIENT_ETHER_IN_CONTRACT");

        validateSignatureForEth(_user, _sig, _amount, _expiry);

        bool success = payable(_user).send(_amount);
        require(success, "WITHDRAW FAILED");

        emit WithdrawEth(_user, _amount, block.timestamp);
    }

    function setTokenStatus(address _token, bool _status) external onlyOwner returns(bool){
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(approvedToken[_token] != _status, "INVALID STATUS");

        approvedToken[_token] = _status;
        return true;
    }

    function setSigner(address _newSigner) external onlyOwner returns(bool){
        require(_newSigner != address(0), "ENTERING_ZERO_ADDRESS");

        signer = _newSigner;
        return true;
    }

    function checkEtherBalance() external view returns(uint){
        return address(this).balance;
    }

    function checkTokenBalance(address _token, address _account) external view returns(uint){
        return _selectorBalanceOf(_token, _account);
    }

    function checkTokenStatus(address _token) external view returns(bool){
        return approvedToken[_token];
    }

    function _selectorTransfer(address _token, address _receiver, uint256 _tokenAmount) internal {
        (bool suc, ) = _token.call(abi.encodeWithSelector(SELECTORTRANFSFER,_receiver,_tokenAmount));
        require(suc,"TRANSFER_FAILED");
    }

    function _selectorTransferFrom(address _token, uint256 _amount) internal {
        (bool success, ) = _token.call(abi.encodeWithSelector(SELECTORTRANSFERFROM,_msgSender(),address(this),_amount));
        require(success, "TRANSFERFROM_FAILED");
    }

    function _selectorBalanceOf(address _token, address _account) internal view returns(uint256 _balances){
        ( ,bytes memory data) = _token.staticcall(abi.encodeWithSelector(SELECTORBALANCEOF,_account));
        _balances = abi.decode(data,(uint256));
    }

    function validateSignatureForToken(address _user, Sig memory _sig, address _token, uint256 _amount, uint _expiry) private {
        bytes32 hash = prepareHashForToken(
            _user,
            _token,
            _amount,
            _expiry,
            address(this)
        );
        require(!Signstatus[hash], "ALREADY_SIGNED");
        Signstatus[hash] = true;
        require(ecrecover(hash, _sig.v, _sig.r, _sig.s) == signer , "INVALID_SIGNATURE");
    }

    function prepareHashForToken(address _user, address _token, uint256 _amount, uint _expiry, address _contract)private pure returns(bytes32){
        bytes32 hash = keccak256(
            abi.encodePacked(
                _user,
                _token,
                _amount,
                _expiry,
                _contract
            )
        );
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function validateSignatureForEth(address _user, Sig memory _sig, uint256 _amount, uint _expiry) private {
        bytes32 hash = prepareHashForEth(
            _user,
            _amount,
            _expiry,
            address(this)
        );
        require(!Signstatus[hash], "ALREADY_SIGNED");
        Signstatus[hash] = true;
        require(ecrecover(hash, _sig.v, _sig.r, _sig.s) == signer , "INVALID_SIGNATURE");
    }

    function prepareHashForEth(address _user, uint256 _amount, uint _expiry, address _contract)private pure returns(bytes32){
        bytes32 hash = keccak256(
            abi.encodePacked(
                _user,
                _amount,
                _expiry,
                _contract
            )
        );
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function failSafeForToken(address _token, address _user, uint256 _amount) external onlyOwner {
        require(_token != address(0) && _user != address(0), "ENTERING_ZERO_ADDRESS");
        require(_amount > 0, "INVALID TOKEN AMOUNT");
        require(_selectorBalanceOf(_token, address(this)) >= _amount,"INSUFFICIENT_TOKEN_BALANCE");

        _selectorTransfer(_token, _user, _amount);

        emit FailSafeForToken(_token, _user, _amount, block.timestamp);
    }

    function failSafeForEther(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "ENTERING_ZERO_ADDRESS");
        require(_amount > 0, "INVALID AMOUNT");
        require(address(this).balance >= _amount, "INSUFFICIENT FUND");

        bool success = payable(_user).send(_amount);
        require(success, "WITHDRAW FAILED");

        emit FailSafeForEther(_user, _amount, block.timestamp);
    }

    function isContract(address _account) private view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0){
            return true;
        }
        return false;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}