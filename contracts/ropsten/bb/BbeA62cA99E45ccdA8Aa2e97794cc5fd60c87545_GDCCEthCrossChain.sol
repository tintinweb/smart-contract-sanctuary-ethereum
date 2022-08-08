/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface IERC20 {

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(address target,bool success,bytes memory returndata,string memory errorMessage) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token,address from,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

        address _beforeOwner = _owner;
        _transferOwnership(newOwner);

        emit TransferOwnerShip(_beforeOwner, newOwner ,block.timestamp);
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

    using Address for address;

    address public signer;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(address => bool) private approvedToken;
    mapping(bytes32 => bool) private signStatus;
    mapping(address => uint) private _nonce;

    event DepositToken(
        address indexed user, 
        address indexed token, 
        uint256 indexed amount, 
        uint time
    );
    
    event WithdrawToken(
        address indexed user, 
        address indexed token, 
        uint256 indexed amount, 
        uint time
    );
    
    event DepositEth(
        address indexed user, 
        uint256 indexed amount, 
        uint time
    );

    event WithdrawEth(
        address indexed user, 
        uint256 indexed amount, 
        uint time
    );

    event AddToken(
        address indexed token, 
        uint256 indexed amount,
        uint time
    );

    event FailSafeForToken(
        address indexed token, 
        address indexed user, 
        uint256 indexed amount, 
        uint time
    );
    
    event FailSafeForEther(
        address indexed user, 
        uint256 indexed amount, 
        uint time
    );

    event FallBack(
        address indexed user, 
        uint256 indexed amount, 
        uint time
    );

    modifier isContractCheck(address _user) {
        require(!Address.isContract(_user), "INVALID ADDRESS");
        _;
    }

    constructor(address _signer){
        signer = _signer;
    }

    receive() external payable onlyOwner{
        emit FallBack(_msgSender(), msg.value, block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addTokenBalance(address _token, uint _amount) external onlyOwner {
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(approvedToken[_token], "NOT AN APPROVED TOKEN");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        SafeERC20.safeTransferFrom(IERC20(_token), _msgSender(), address(this), _amount);
        emit AddToken(_token, _amount, block.timestamp);
    }

    function tokenDeposit(address _token, uint _amount) external whenNotPaused isContractCheck(_msgSender()) nonReentrant{
        require(_token != address(0), "ENTERING_ZERO_ADDRESS");
        require(approvedToken[_token], "NOT AN APPROVED TOKEN");
        require(_amount > 0, "INVALID TOKEN AMOUNT");

        SafeERC20.safeTransferFrom(IERC20(_token), _msgSender(), address(this), _amount);
        emit DepositToken(_msgSender(), address(_token), _amount, block.timestamp);
    }

    function tokenWithdraw(
        Sig memory _sig, 
        address _user, 
        address _token, 
        uint256 _amount, 
        uint _expiry
    ) external whenNotPaused isContractCheck(_user) nonReentrant{
        require(_token != address(0) && _amount > 0, "ENTERING_ZERO_ADDRESS || INVALID TOKEN_AMOUNT");
        require(approvedToken[_token], "NOT AN APPROVED_TOKEN");
        require(_selectorBalanceOf(_token, address(this)) >= _amount, "INSUFFICIENT_CONTRACT_FUND");
        require(block.timestamp <= _expiry, "EXPIRY_TIME_OUT");
        require(validateSignature(_sig, _user, _token, _amount, _expiry) == signer, "INVALID_SIGNATURE");

        SafeERC20.safeTransfer(IERC20(_token), _user, _amount);
        emit WithdrawToken(_user, address(_token), _amount, block.timestamp);
    }

    function etherDeposit() external payable whenNotPaused isContractCheck(_msgSender()) nonReentrant{
        require(msg.value > 0, "INVALID ETHER");
        emit DepositEth(_msgSender(), msg.value, block.timestamp);
    }

    function etherWithdraw(
        Sig memory _sig, 
        address _user, 
        uint256 _amount, 
        uint _expiry
    ) external whenNotPaused isContractCheck(_user) nonReentrant{
        require(block.timestamp <= _expiry,"EXPIRY_TIME_OUT");
        require(address(this).balance >= _amount, "INSUFFICIENT_ETHER_IN_CONTRACT");
        require(validateSignature(_sig, _user, address(0), _amount, _expiry) == signer , "INVALID_SIGNATURE");

        Address.sendValue(payable(_user), _amount);
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

    function failSafeForToken(address _token, address _user, uint256 _amount) external onlyOwner {
        require(_token != address(0) && _user != address(0), "ENTERING_ZERO_ADDRESS");
        require(_amount > 0, "INVALID TOKEN AMOUNT");
        require(_selectorBalanceOf(_token, address(this)) >= _amount,"INSUFFICIENT_TOKEN_BALANCE");

        SafeERC20.safeTransfer(IERC20(_token), _user, _amount);
        emit FailSafeForToken(_token, _user, _amount, block.timestamp);
    }

    function failSafeForEther(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "ENTERING_ZERO_ADDRESS");
        require(_amount > 0, "INVALID AMOUNT");
        require(address(this).balance >= _amount, "INSUFFICIENT FUND");

        Address.sendValue(payable(_user), _amount);
        emit FailSafeForEther(_user, _amount, block.timestamp);
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

    function nonce(address _user) external view returns(uint){
        return _nonce[_user];
    }

    function _selectorBalanceOf(address _token, address _account) private view returns(uint256 _balances){
        bytes memory data = _token.functionStaticCall(abi.encodeWithSelector(IERC20(_token).balanceOf.selector,_account));
        _balances = abi.decode(data,(uint256));
    }

    function validateSignature(
        Sig memory _sig, 
        address _user,
        address _token, 
        uint256 _amount, 
        uint _expiry
    ) private returns(address){
        bytes32 hash = messageHash(
            _user,
            _token,
            _amount,
            _expiry,
            _nonce[_user]
        );
        require(!signStatus[hash], "ALREADY_SIGNED");
        _nonce[_user]++;
        signStatus[hash] = true;
        return ecrecover(hash, _sig.v, _sig.r, _sig.s);
    }

    function messageHash(
        address _user, 
        address _token, 
        uint256 _amount, 
        uint _expiry, 
        uint _nonces
    ) private view returns(bytes32){
        bytes32 hash = keccak256(
            abi.encodePacked(
                _user,
                _token,
                _amount,
                _expiry,
                _nonces,
                address(this)
            )
        );
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}