/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


/*

      ___           ___           ___          _____                        ___                    ___           ___           ___                       ___     
     /  /\         /  /\         /__/\        /  /::\                      /  /\                  /  /\         /  /\         /__/\        ___          /  /\    
    /  /:/        /  /::\        \  \:\      /  /:/\:\                    /  /:/_                /  /:/_       /  /:/_        \  \:\      /  /\        /  /:/_   
   /  /:/        /  /:/\:\        \  \:\    /  /:/  \:\   ___     ___    /  /:/ /\              /  /:/ /\     /  /:/ /\        \  \:\    /  /:/       /  /:/ /\  
  /  /:/  ___   /  /:/~/::\   _____\__\:\  /__/:/ \__\:| /__/\   /  /\  /  /:/ /:/_            /  /:/_/::\   /  /:/ /:/_   _____\__\:\  /__/::\      /  /:/ /:/_ 
 /__/:/  /  /\ /__/:/ /:/\:\ /__/::::::::\ \  \:\ /  /:/ \  \:\ /  /:/ /__/:/ /:/ /\          /__/:/__\/\:\ /__/:/ /:/ /\ /__/::::::::\ \__\/\:\__  /__/:/ /:/ /\
 \  \:\ /  /:/ \  \:\/:/__\/ \  \:\~~\~~\/  \  \:\  /:/   \  \:\  /:/  \  \:\/:/ /:/          \  \:\ /~~/:/ \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\/\ \  \:\/:/ /:/
  \  \:\  /:/   \  \::/       \  \:\  ~~~    \  \:\/:/     \  \:\/:/    \  \::/ /:/            \  \:\  /:/   \  \::/ /:/   \  \:\  ~~~      \__\::/  \  \::/ /:/ 
   \  \:\/:/     \  \:\        \  \:\         \  \::/       \  \::/      \  \:\/:/              \  \:\/:/     \  \:\/:/     \  \:\          /__/:/    \  \:\/:/  
    \  \::/       \  \:\        \  \:\         \__\/         \__\/        \  \::/                \  \::/       \  \::/       \  \:\         \__\/      \  \::/   
     \__\/         \__\/         \__\/                                     \__\/                  \__\/         \__\/         \__\/                     \__\/    
     
                                                                              
                                                                 CANDLE GENIE ADVANCED PREDICTIONS V1🗲      
                                                                      
                                                                        https://candlegenie.io


*/


//CONTEXT
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// REENTRANCY GUARD
abstract contract ReentrancyGuard 
{
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

//OWNABLE
abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function OwnershipTransfer(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function OwnershipRenounce() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

//PAUSABLE
abstract contract Pausable is Context 
{

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

   function _pause() internal virtual whenNotPaused {
        _paused = true;
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
    }

}

// ADDRESS
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
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
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
}

// IERC20
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SAFEERC20
library SafeIERC20 {
    using Address for address;

    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token,address from, address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(IERC20 token,address spender,uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//CONTRACT
contract CandleGenieAdvancedPredictions is Ownable, Pausable, ReentrancyGuard 
{
    // TOKENS
    using SafeIERC20 for IERC20;


    // EPOCHES
    uint256 public depositEpoch;

    struct DepositStruct {
        address user;
        uint256 amount;
        address token;
    }

    // -----------------------------------
    // MAPPINGS --------------------------
    // -----------------------------------
    mapping(uint256 => DepositStruct) public Deposits;
    mapping(address => mapping(uint256 => bool)) public Withdraws; 
    mapping(address => bool) public AllowedTokens; 

    // Payable
    receive() external payable {
    }

    // -----------------------------------
    // MODIFIERS -------------------------
    // -----------------------------------
    modifier notContract() {
        require(!_isContract(msg.sender), "Contracts not allowed");
        require(msg.sender == tx.origin, "Proxy contracts not allowed");
        _;
    }

    // -----------------------------------
    // INTERNAL FUNCTIONS ----------------
    // -----------------------------------
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    

    // -----------------------------------
    // OWNER FUNCTIONS -------------------
    // -----------------------------------
    function FundsInject() external payable onlyOwner {}
    
    function FundsExtract(uint256 amount) external onlyOwner 
    {
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "Transfer failed.");
    }
    function FundsExtractAll() external onlyOwner 
    {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Transfer failed.");
    }

    function TokenExtract(address token, uint256 amount) external onlyOwner {
          IERC20(token).safeTransfer(owner(), amount);
    }

    function TokenExtractAll(address token) external onlyOwner {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), tokenBalance);
    }

    function TokenAllow(address token, bool allowed) external onlyOwner {
       AllowedTokens[token] = allowed;
    }

    function Withdraw(address user,  uint256 id, uint256 amount) external onlyOwner {
        (bool sent, ) = payable(user).call{value: amount}("");
        require(sent, "Transfer failed.");
        Withdraws[user][id] = true;
    }

    function WithdrawToken(address token, address user, uint256 id, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token !");
        IERC20(token).safeTransfer(user, amount);
        Withdraws[user][id] = true;
    }

    // -----------------------------------
    // USER FUNCTIONS --------------------
    // -----------------------------------
    function Deposit() external payable whenNotPaused nonReentrant notContract {
        require(msg.value > 0, "Invalid amount !");
        DepositStruct storage deposit = Deposits[depositEpoch++];
        deposit.user = msg.sender;
        deposit.amount = msg.value;
    }

    function DepositToken(address token, uint256 amount) external whenNotPaused nonReentrant notContract {
        require(token != address(0), "Invalid token !");
        require(AllowedTokens[token], "Token is not allowed !");
        require(amount > 0, "Invalid amount !");

        // Transfer
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Store
        DepositStruct storage deposit = Deposits[depositEpoch++];
        deposit.user = msg.sender;
        deposit.amount = amount;
        deposit.token = token;
    }

}