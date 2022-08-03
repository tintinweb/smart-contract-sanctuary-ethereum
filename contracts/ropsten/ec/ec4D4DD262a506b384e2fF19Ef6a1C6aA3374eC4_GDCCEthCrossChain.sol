/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

contract GDCCEthCrossChain is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    address public signer;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes4 private constant SELECTORTRANSFERFROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant SELECTORTRANFSFER = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant SELECTORBALANCEOF = bytes4(keccak256(bytes('balanceOf(address)')));

    mapping (address => mapping(address => uint256)) private tokenUserBalance;
    mapping (address => uint256) private ethUserBalance;
    mapping (address => bool) private approvedToken;
    mapping (bytes32 => bool) private Signstatus;

    event DepositToken (address indexed user, address indexed token, uint256 indexed amount, uint time);
    event WithdrawToken (address indexed user, address indexed token, uint256 indexed amount, uint time);
    event DepositEth (address indexed user, uint256 indexed amount, uint time);
    event WithdrawEth (address indexed user, uint256 indexed amount, uint time);
    event FailSafeForToken(address indexed token, address indexed user, uint256 indexed amount, uint time);
    event FailSafeForEther(address indexed user, uint256 amount, uint time);
    event FallBack(address indexed user, uint256 indexed amount, uint time);

    constructor(address _signer){
        signer = _signer;
    }

    receive() external payable {
        emit FallBack(_msgSender(), msg.value, block.timestamp);
    }

    function addTokenBalance(address _token, uint _amount) external onlyOwner returns(bool) {
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        _selectorTransferFrom(_token, _amount);

        return true;
    }

    function tokenDeposit(address _token, uint _amount) external whenNotPaused nonReentrant{
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(approvedToken[_token], "NOT AN APPROVED TOKEN");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        _selectorTransferFrom(_token, _amount);
        tokenUserBalance[_msgSender()][_token] = tokenUserBalance[_msgSender()][_token].add(_amount);

        emit DepositToken(_msgSender(), address(_token), _amount, block.timestamp);
    }

    function tokenWithdraw(Sig memory _sig, address _token, uint256 _amount, uint _expiry) external whenNotPaused nonReentrant{
        require(_token != address(0) && _amount > 0, "ENTERING_ZERO_ADDRESS || INVALID TOKEN AMOUNT");
        require(_selectorBalanceOf(_token) >= _amount, "INSUFFICIENT_CONTRACT_FUND");
        require(block.timestamp <= _expiry,"EXPIRY_TIME_OUT");

        validateSignatureForToken(_msgSender(), _sig, _token, _amount, _expiry);

        tokenUserBalance[_msgSender()][_token] = tokenUserBalance[_msgSender()][_token].sub(_amount);
        _selectorTransfer(_token, _msgSender(), _amount);

        emit WithdrawToken(_msgSender(), address(_token), _amount, block.timestamp);
    }

    function etherDeposit() external payable whenNotPaused nonReentrant{
        require(msg.value > 0, "INVALID ETHER");

        ethUserBalance[_msgSender()] = ethUserBalance[_msgSender()].add(msg.value);
        emit DepositEth(_msgSender(), msg.value, block.timestamp);
    }

    function etherWithdraw(Sig memory _sig, uint256 _amount, uint _expiry) external whenNotPaused nonReentrant{
        require(block.timestamp <= _expiry,"EXPIRY_TIME_OUT");
        require(address(this).balance >= _amount, "INSUFFICIENT_ETHER_IN_CONTRACT");

        validateSignatureForEth(_msgSender(), _sig, _amount, _expiry);

        ethUserBalance[_msgSender()] = ethUserBalance[_msgSender()].sub(_amount);
        bool success = payable(_msgSender()).send(_amount);
        require(success, "WITHDRAW FAILED");

        emit WithdrawEth(_msgSender(), _amount, block.timestamp);
    }

    function setTokenStatus(address _token, bool _status) external onlyOwner returns(bool){
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");

        approvedToken[_token] = _status;
        return true;
    }

    function setSigner(address _newSigner) external onlyOwner returns(bool){
        require(_newSigner != address(0), "ENTERING_ZERO_ADDRESS");

        signer = _newSigner;
        return true;
    }

    function checkBalance() external view returns(uint){
        return address(this).balance;
    }

    function checkUserTokenBalance(address _account, address _token) external view returns(uint256){
        return tokenUserBalance[_account][_token];
    }

    function checkUserEthBalance(address _account) external view returns(uint256){
        return ethUserBalance[_account];
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

    function _selectorBalanceOf(address _token) internal view returns(uint256 _balances){
        ( ,bytes memory data) = _token.staticcall(abi.encodeWithSelector(SELECTORBALANCEOF, address(this)));
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
        require(tokenUserBalance[_user][_token] >= _amount, "INSUFFICIENT FUND");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        tokenUserBalance[_user][_token] = tokenUserBalance[_user][_token].sub(_amount);
        _selectorTransfer(_token, _user, _amount);

        emit FailSafeForToken(_token, _user, _amount, block.timestamp);
    }

    function failSafeForEther(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "ENTERING_ZERO_ADDRESS");
        require(ethUserBalance[_user] >= _amount, "INSUFFICIENT FUND");

        ethUserBalance[_user] = ethUserBalance[_user].sub(_amount);
        bool success = payable(_user).send(_amount);
        require(success, "WITHDRAW FAILED");

        emit FailSafeForEther(_user, _amount, block.timestamp);
    }

}