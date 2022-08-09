/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

//SPDX-License-Identifier:Unlicensed
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

abstract contract Ownable is Context{

    address private _owner;

    event TransferOwnerShip(address oldOwner, address newOwner);

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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"ZEROADDRESS");
        require(newOwner != _owner, "Entering OLD_OWNER_ADDRESS");
        emit TransferOwnerShip(_owner, newOwner);
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

contract Presale is Ownable, ReentrancyGuard{

    error rateError(string _msg, uint256 _amount);

    uint256 private _rate = 1;
    bool private status;
    uint256 private weiRaised;

    mapping(address => bool) private _approvedToken;
    mapping(address => mapping(address => uint256)) private balances;

    event AddToken(
        address indexed _token,
        uint256 indexed _numToken,
        uint time
    );

    event BuyToken(
        address  _spender, 
        address indexed _user, 
        address indexed _token,
        uint256 indexed _numToken,
        uint time
    );

    event ClaimToken(
        address indexed _claimer, 
        address indexed _token,
        uint256 indexed _numToken,
        uint time
    );

    event FailSafeToken(
        address indexed _token,
        address indexed _user,
        uint256 indexed _numtoken,
        uint time
    );

    event FailSafeEther(
        address indexed _user,
        uint256 indexed _amount,
        uint time
    );

    function startSale() external onlyOwner {
        require(!status, "SALE_ALREADY_STARTED");
        status = true;
    }

    function stopSale() external onlyOwner {
        require(status, "SALE_ALREADY_STOPED");
        status = false;
    }

    function addToken(address _token, uint256 _numTokens) external onlyOwner{
        require(_token != address(0) && _numTokens > 0, "INVALID_PARAMS");
        require(_approvedToken[_token], "NOT AN APPROVED_TOKEN");

        SafeERC20.safeTransferFrom(IERC20(_token), _msgSender(), address(this), _numTokens);
        emit AddToken(_token, _numTokens, block.timestamp);
    }

    function buyToken(address _user, address _token, uint256 _numTokens) external payable nonReentrant {
        require(_token != address(0) && _user != address(0) && _numTokens > 0, "INVALID_PARAMS");
        require(status, "SALE_NOT_STARTED");
        require(_approvedToken[_token], "NOT AN APPROVED_TOKEN");
        if(msg.value != rate(_numTokens)) revert rateError("PRICE_IS",rate(_numTokens));

        weiRaised = weiRaised + msg.value;
        balances[_user][_token] = balances[_user][_token] + _numTokens;
        Address.sendValue(payable(owner()), msg.value);
        emit BuyToken(_msgSender(), _user, _token, _numTokens, block.timestamp);
    }

    function claimToken(address _token) external nonReentrant{
        require(_token != address(0), "INVALID_PARAMS");
        require(_approvedToken[_token], "NOT AN APPROVED_TOKEN");
        require(!status, "SALE_NOT_STOPPED");
        require(balances[_msgSender()][_token] > 0, "INSUFFICIENT_TOKENS");

        uint256 _numTokens = balances[_msgSender()][_token];
        balances[_msgSender()][_token] = balances[_msgSender()][_token] - _numTokens;

        SafeERC20.safeTransfer(IERC20(_token), _msgSender(), _numTokens);
        emit ClaimToken(_msgSender(), _token, _numTokens, block.timestamp);
    }

    function approveToken(address _token) external onlyOwner {
        _approvedToken[_token] = true;
    }

    function checkTokenStatus(address _token) external view returns(bool){
        return _approvedToken[_token];
    }

    function balanceOf(address _account, address _token) external view returns(uint){
        return balances[_account][_token];
    }

    function saleStatus() external view returns(bool){
        return status;
    }

    function failSafeToken(address _token, address _user, uint256 _numTokens) external onlyOwner {
        require(_token != address(0) && _user != address(0) && _numTokens > 0, "INVALID_PARAMS");
        require(_approvedToken[_token], "NOT_AN_APPROVED_TOKEN");
        
        SafeERC20.safeTransfer(IERC20(_token), _user, _numTokens);
        emit FailSafeToken(_token, _user, _numTokens, block.timestamp);
    }

    function failSafeEther(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0) && _amount > 0, "INVALID_PARAMS");
        
        Address.sendValue(payable(_user),_amount);
        emit FailSafeEther(_user, _amount, block.timestamp);
    }

    function rate(uint256 _numTokens) public view returns(uint256){
        return _rate * _numTokens;
    }

}