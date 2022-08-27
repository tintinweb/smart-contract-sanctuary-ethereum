/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeMath {

 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a, "SafeMath: addition overflow");

 return c;
 }

 
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 return sub(a, b, "SafeMath: subtraction overflow");
 }

 
 function sub(
 uint256 a,
 uint256 b,
 string memory errorMessage
 ) internal pure returns (uint256) {
 require(b <= a, errorMessage);
 uint256 c = a - b;

 return c;
 }

 
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
 // benefit is lost if 'b' is also tested.
 // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

 
 function div(
 uint256 a,
 uint256 b,
 string memory errorMessage
 ) internal pure returns (uint256) {
 require(b > 0, errorMessage);
 uint256 c = a / b;
 // assert(a == b * c + a % b); // There is no case in which this doesn't hold

 return c;
 }

 
 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
 return mod(a, b, "SafeMath: modulo by zero");
 }

 
 function mod(
 uint256 a,
 uint256 b,
 string memory errorMessage
 ) internal pure returns (uint256) {
 require(b != 0, errorMessage);
 return a % b;
 }
}

interface IERC20 {
 function totalSupply() external view returns (uint256);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address owner, address spender) external view returns (uint256);
 function mint(address _to, uint256 _amount) external returns (bool);
 function burn(uint256 _amount) external ;
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom( address sender, address recipient,uint256 amount) external returns (bool);
 event Mint(address indexed minter, address indexed to, uint256 amount);
 event Burn(address indexed burner, uint256 amount);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner,address indexed spender,uint256 value);
}

abstract contract AbstractToken is IERC20 {
 function _approve(
 address owner,
 address spender,
 uint256 value
 ) internal virtual;

 function _transfer(
 address from,
 address to,
 uint256 value
 ) internal virtual;

 function _increaseAllowance(
 address owner,
 address spender,
 uint256 increment
 ) internal virtual;

 function _decreaseAllowance(
 address owner,
 address spender,
 uint256 decrement
 ) internal virtual;
}

contract Ownable {
 address private _owner;
 event OwnershipTransferred(address previousOwner, address newOwner);

 constructor() public {
 setOwner(msg.sender);
 }

 function owner() external view returns (address) {
 return _owner;
 }

 function setOwner(address newOwner) internal {
 _owner = newOwner;
 }

 modifier onlyOwner() {
 require(msg.sender == _owner, "Ownable: caller is not the owner");
 _;
 }

 function transferOwnership(address newOwner) external onlyOwner {
 require(
 newOwner != address(0),
 "Ownable: new owner is the zero address"
 );
 emit OwnershipTransferred(_owner, newOwner);
 setOwner(newOwner);
 }
}

contract Pausable is Ownable {
 event Pause();
 event Unpause();
 event PauserChanged(address indexed newAddress);

 bool public paused = false;

 modifier whenNotPaused() {
 require(!paused, "Pausable: paused");
 _;
 }


 function pause() external onlyOwner {
 paused = true;
 emit Pause();
 }

 
 function unpause() external onlyOwner {
 paused = false;
 emit Unpause();
 }


}

contract Blacklistable is Ownable {
 mapping(address => bool) internal blacklisted;

 event Blacklisted(address indexed _account);
 event UnBlacklisted(address indexed _account);
 event BlacklisterChanged(address indexed newBlacklister);

 
 modifier notBlacklisted(address _account) {
 require(
 !blacklisted[_account],
 "Blacklistable: account is blacklisted"
 );
 _;
 }

 function isBlacklisted(address _account) external view returns (bool) {
 return blacklisted[_account];
 }

 function blacklist(address _account) external onlyOwner {
 blacklisted[_account] = true;
 emit Blacklisted(_account);
 }

 function unBlacklist(address _account) external onlyOwner {
 blacklisted[_account] = false;
 emit UnBlacklisted(_account);
 }

}

library Address {
 
 function isContract(address account) internal view returns (bool) {
 bytes32 codehash;
 bytes32 accountHash= 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
 // solhint-disable-next-line no-inline-assembly
 assembly {
 codehash := extcodehash(account)
 }
 return (codehash != accountHash && codehash != 0x0);
 }


function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

 
 function functionCall(address target, bytes memory data)
 internal
 returns (bytes memory)
 {
 return functionCall(target, data, "Address: low-level call failed");
 }


 function functionCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal returns (bytes memory) {
 return _functionCallWithValue(target, data, 0, errorMessage);
 }

 
 function functionCallWithValue(
 address target,
 bytes memory data,
 uint256 value
 ) internal returns (bytes memory) {
 return
 functionCallWithValue(
 target,
 data,
 value,
 "Address: low-level call with value failed"
 );
 }


 function functionCallWithValue(
 address target,
 bytes memory data,
 uint256 value,
 string memory errorMessage
 ) internal returns (bytes memory) {
 require(
 address(this).balance >= value,
 "Address: insufficient balance for call"
 );
 return _functionCallWithValue(target, data, value, errorMessage);
 }

 function _functionCallWithValue(
 address target,
 bytes memory data,
 uint256 weiValue,
 string memory errorMessage
 ) private returns (bytes memory) {
 require(isContract(target), "Address: call to non-contract");

 // solhint-disable-next-line avoid-low-level-calls
 (bool success, bytes memory returndata) = target.call{
 value: weiValue
 }(data);
 if (success) {
 return returndata;
 } else {
 // Look for revert reason and bubble it up if present
 if (returndata.length > 0) {
 // The easiest way to bubble the revert reason is using memory via assembly

 // solhint-disable-next-line no-inline-assembly
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

library ECRecover {

 function recover( bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
 if (uint256(s) >0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
 revert("ECRecover: invalid signature 's' value");
 }

 if (v != 27 && v != 28) {
 revert("ECRecover: invalid signature 'v' value");
 }

 address signer = ecrecover(digest, v, r, s);
 require(signer != address(0), "ECRecover: invalid signature");

 return signer;
 }
}


library EIP712 {

 function makeDomainSeparator(string memory name, string memory version) internal view returns (bytes32) {
 uint256 chainId;
 assembly {
 chainId := chainid()
 }
 return
 keccak256(
 abi.encode(
 // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
 keccak256(bytes(name)),
 keccak256(bytes(version)),
 chainId,
 address(this)
 )
 );
 }

 function recover(bytes32 domainSeparator,uint8 v,bytes32 r,bytes32 s,bytes memory typeHashAndData) internal pure returns (address) {
 bytes32 digest = keccak256(
 abi.encodePacked(
 "\x19\x01",
 domainSeparator,
 keccak256(typeHashAndData)
 )
 );
 return ECRecover.recover(digest, v, r, s);
 }
}


contract EIP712Domain {

 bytes32 public DOMAIN_SEPARATOR;
}


abstract contract EIP3009 is AbstractToken, EIP712Domain {
 // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
 bytes32
 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

 // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
 bytes32
 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

 // keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
 bytes32
 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

 /**
 * @dev authorizer address => nonce => bool (true if nonce is used)
 */
 mapping(address => mapping(bytes32 => bool)) private _authorizationStates;

 event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
 event AuthorizationCanceled(
 address indexed authorizer,
 bytes32 indexed nonce
 );


 function authorizationState(address authorizer, bytes32 nonce)
 external
 view
 returns (bool)
 {
 return _authorizationStates[authorizer][nonce];
 }

 function _transferWithAuthorization(
 address from,
 address to,
 uint256 value,
 uint256 validAfter,
 uint256 validBefore,
 bytes32 nonce,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) internal {
 _requireValidAuthorization(from, nonce, validAfter, validBefore);

 bytes memory data = abi.encode(
 TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
 from,
 to,
 value,
 validAfter,
 validBefore,
 nonce
 );
 require(
 EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
 "FiatTokenV2: invalid signature"
 );

 _markAuthorizationAsUsed(from, nonce);
 _transfer(from, to, value);
 }

 function _receiveWithAuthorization(
 address from,
 address to,
 uint256 value,
 uint256 validAfter,
 uint256 validBefore,
 bytes32 nonce,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) internal {
 require(to == msg.sender, "FiatTokenV2: caller must be the payee");
 _requireValidAuthorization(from, nonce, validAfter, validBefore);

 bytes memory data = abi.encode(
 RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
 from,
 to,
 value,
 validAfter,
 validBefore,
 nonce
 );
 require(
 EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
 "FiatTokenV2: invalid signature"
 );

 _markAuthorizationAsUsed(from, nonce);
 _transfer(from, to, value);
 }


 function _cancelAuthorization(
 address authorizer,
 bytes32 nonce,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) internal {
 _requireUnusedAuthorization(authorizer, nonce);

 bytes memory data = abi.encode(
 CANCEL_AUTHORIZATION_TYPEHASH,
 authorizer,
 nonce
 );
 require(
 EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == authorizer,
 "FiatTokenV2: invalid signature"
 );

 _authorizationStates[authorizer][nonce] = true;
 emit AuthorizationCanceled(authorizer, nonce);
 }


 function _requireUnusedAuthorization(address authorizer, bytes32 nonce)
 private
 view
 {
 require(
 !_authorizationStates[authorizer][nonce],
 "FiatTokenV2: authorization is used or canceled"
 );
 }

 function _requireValidAuthorization(
 address authorizer,
 bytes32 nonce,
 uint256 validAfter,
 uint256 validBefore
 ) private view {
 require(
 now > validAfter,
 "FiatTokenV2: authorization is not yet valid"
 );
 require(now < validBefore, "FiatTokenV2: authorization is expired");
 _requireUnusedAuthorization(authorizer, nonce);
 }

 function _markAuthorizationAsUsed(address authorizer, bytes32 nonce)
 private
 {
 _authorizationStates[authorizer][nonce] = true;
 emit AuthorizationUsed(authorizer, nonce);
 }
}


abstract contract EIP2612 is AbstractToken, EIP712Domain {
 // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
 bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
 mapping(address => uint256) private _permitNonces;

 function nonces(address owner) external view returns (uint256) {
 return _permitNonces[owner];
 }

 function _permit(
 address owner,
 address spender,
 uint256 value,
 uint256 deadline,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) internal {
 require(deadline >= now, "FiatTokenV2: permit is expired");

 bytes memory data = abi.encode(
 PERMIT_TYPEHASH,
 owner,
 spender,
 value,
 _permitNonces[owner]++,
 deadline
 );
 require(
 EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
 "EIP2612: invalid signature"
 );

 _approve(owner, spender, value);
 }
}


contract DEOReservoir is AbstractToken, Ownable, Pausable, Blacklistable,EIP2612 {
 using SafeMath for uint256;

 string public name;
 string public symbol;
 uint8 public decimals;
 address public masterMinter;
 bool internal initialized;

 mapping(address => uint256) internal balances;
 mapping(address => mapping(address => uint256)) internal allowed;
 uint256 internal totalSupply_ = 0;
 mapping(address => bool) internal minters;
 mapping(address => uint256) internal minterAllowed;

 event Mint(address indexed minter, address indexed to, uint256 amount);
 event Burn(address indexed burner, uint256 amount);
 event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
 event MinterRemoved(address indexed oldMinter);
 event MasterMinterChanged(address indexed newMasterMinter);

 function initialize(
 string memory tokenName,
 string memory tokenSymbol,
 uint8 tokenDecimals,
 address newMasterMinter,
 address newOwner
 ) public {
 require(!initialized, "FiatToken: contract is already initialized");
 require(
 newMasterMinter != address(0),
 "FiatToken: new masterMinter is the zero address"
 );
 require(
 newOwner != address(0),
 "FiatToken: new owner is the zero address"
 );

 name = tokenName;
 symbol = tokenSymbol;
 decimals = tokenDecimals;
 masterMinter = newMasterMinter;
 setOwner(newOwner);
 initialized = true;
 }


 modifier onlyMinters() {
 require(minters[msg.sender], "FiatToken: caller is not a minter");
 _;
 }

 function rescueERC20(
 IERC20 tokenContract,
 address to,
 uint256 amount
 ) external onlyOwner {
 tokenContract.transfer(to, amount);
 }

 function mint(address _to, uint256 _amount)
 external
 override
 whenNotPaused
 onlyMinters
 notBlacklisted(msg.sender)
 notBlacklisted(_to)
 returns (bool)
 {
 require(_to != address(0), "FiatToken: mint to the zero address");
 require(_amount > 0, "FiatToken: mint amount not greater than 0");

 uint256 mintingAllowedAmount = minterAllowed[msg.sender];
 require(
 _amount <= mintingAllowedAmount,
 "FiatToken: mint amount exceeds minterAllowance"
 );

 totalSupply_ = totalSupply_.add(_amount);
 balances[_to] = balances[_to].add(_amount);
 minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
 emit Mint(msg.sender, _to, _amount);
 emit Transfer(address(0), _to, _amount);
 return true;
 }

 /**
 * @dev Throws if called by any account other than the masterMinter
 */
 modifier onlyMasterMinter() {
 require(
 msg.sender == masterMinter,
 "FiatToken: caller is not the masterMinter"
 );
 _;
 }


 function minterAllowance(address minter) external view returns (uint256) {
 return minterAllowed[minter];
 }

 function isMinter(address account) external view returns (bool) {
 return minters[account];
 }


 function allowance(address owner, address spender)
 external
 override
 view
 returns (uint256)
 {
 return allowed[owner][spender];
 }

 /**
 * @dev Get totalSupply of token
 */
 function totalSupply() external override view returns (uint256) {
 return totalSupply_;
 }

 /**
 * @dev Get token balance of an account
 * @param account address The account
 */
 function balanceOf(address account)
 external
 override
 view
 returns (uint256)
 {
 return balances[account];
 }

 
 function approve(address spender, uint256 value)
 external
 override
 whenNotPaused
 notBlacklisted(msg.sender)
 notBlacklisted(spender)
 returns (bool)
 {
 _approve(msg.sender, spender, value);
 return true;
 }

 function _approve(
 address owner,
 address spender,
 uint256 value
 ) internal override {
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");
 allowed[owner][spender] = value;
 emit Approval(owner, spender, value);
 }

 function transferFrom(
 address from,
 address to,
 uint256 value
 )
 external 
 override
 whenNotPaused
 notBlacklisted(msg.sender)
 notBlacklisted(from)
 notBlacklisted(to)
 returns (bool)
 {
 require(
 value <= allowed[from][msg.sender],
 "ERC20: transfer amount exceeds allowance"
 );
 _transfer(from, to, value);
 allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
 return true;
 }


 function transfer(address to, uint256 value)
 external
 override
 whenNotPaused
 notBlacklisted(msg.sender)
 notBlacklisted(to)
 returns (bool)
 {
 _transfer(msg.sender, to, value);
 return true;
 }


 function _transfer(
 address from,
 address to,
 uint256 value
 ) internal override {
 require(from != address(0), "ERC20: transfer from the zero address");
 require(to != address(0), "ERC20: transfer to the zero address");
 require(
 value <= balances[from],
 "ERC20: transfer amount exceeds balance"
 );

 balances[from] = balances[from].sub(value);
 balances[to] = balances[to].add(value);
 emit Transfer(from, to, value);
 }

 function configureMinter(address minter, uint256 minterAllowedAmount)
 external
 whenNotPaused
 onlyMasterMinter
 returns (bool)
 {
 minters[minter] = true;
 minterAllowed[minter] = minterAllowedAmount;
 emit MinterConfigured(minter, minterAllowedAmount);
 return true;
 }


 function removeMinter(address minter)
 external
 onlyMasterMinter
 returns (bool)
 {
 minters[minter] = false;
 minterAllowed[minter] = 0;
 emit MinterRemoved(minter);
 return true;
 }


 function burn(uint256 _amount)
 external 
 override
 {
 uint256 balance = balances[msg.sender];
 require(_amount > 0, "FiatToken: burn amount not greater than 0");
 require(balance >= _amount, "FiatToken: burn amount exceeds balance");

 totalSupply_ = totalSupply_.sub(_amount);
 balances[msg.sender] = balance.sub(_amount);
 emit Burn(msg.sender, _amount);
 emit Transfer(msg.sender, address(0), _amount);
 }

 function updateMasterMinter(address _newMasterMinter) external onlyOwner {
 require(
 _newMasterMinter != address(0),
 "FiatToken: new masterMinter is the zero address"
 );
 masterMinter = _newMasterMinter;
 emit MasterMinterChanged(masterMinter);
 }


 function increaseAllowance(address spender, uint256 increment)
 external
 whenNotPaused
 notBlacklisted(msg.sender)
 notBlacklisted(spender)
 returns (bool)
 {
 _increaseAllowance(msg.sender, spender, increment);
 return true;
 }


 function decreaseAllowance(address spender, uint256 decrement)
 external
 whenNotPaused
 notBlacklisted(msg.sender)
 notBlacklisted(spender)
 returns (bool)
 {
 _decreaseAllowance(msg.sender, spender, decrement);
 return true;
 }


 function _increaseAllowance(
 address owner,
 address spender,
 uint256 increment
 ) internal override {
 _approve(owner, spender, allowed[owner][spender].add(increment));
 }


 function _decreaseAllowance(
 address owner,
 address spender,
 uint256 decrement
 ) internal override {
 _approve(
 owner,
 spender,
 allowed[owner][spender].sub(
 decrement,
 "ERC20: decreased allowance below zero"
 )
 );
 }

}