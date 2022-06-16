/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Presale {
    using SafeERC20 for IERC20;
	address private _owner;
	
	IERC20 private _token;
	IERC20 private _wdf;
	uint256 private _pricetoken;
	uint256 private _priceeth;
	
    constructor() {
        _owner = msg.sender;
        emit OwnerSet(address(0), _owner);
    }

    function token() public view virtual returns (IERC20) {
		return _token;
    }
	
    function wdf() public view virtual returns (IERC20) {
		return _wdf;
    }
	
    function pricetoken() public view virtual returns (uint256) {
		return _pricetoken;
    }
	
    function priceeth() public view virtual returns (uint256) {
		return _priceeth;
    }
	
    function Config(IERC20 token_addr, IERC20 wdf_addr, uint256 pricetoken_amount, uint256 priceeth_amount) public isOwner returns (bool success) {
		require(pricetoken_amount > 0, "Config: missing by token price");
		require(priceeth_amount > 0, "Config: missing by eth price");
		_token = token_addr;
		_wdf = wdf_addr;
		_pricetoken = pricetoken_amount;
		_priceeth = priceeth_amount;
        return true;
    }
	
    event WDFSale(address receiver, uint256 paid, uint256 received);
	function BuyWDF(uint256 amount) public returns (bool success) {
        require(amount > 0, "BuyWDF: amount is not positive");
        require(_pricetoken > 0, "BuyWDF: price not configured");
        uint256 diff = 0;
        if(_wdf.decimals() > _token.decimals() ){
            diff = _wdf.decimals() - _token.decimals();
        }
        if(_token.decimals() > _wdf.decimals() ){
            diff = _token.decimals() - _wdf.decimals();
        }
        uint256 up = 1;
        for(uint8 i = 0; i < diff; i++){
            up *= 10;
        }
        uint256 paid = ( amount / 100 ) * _pricetoken;
        if(_wdf.decimals() > _token.decimals() ){
            paid /= up;
        }
        if(_token.decimals() > _wdf.decimals() ){
            paid *= up;
        }
        require(paid > 0, "BuyWDF: amount for paid is not positive");
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= paid, "BuyWDF: Check the token allowance");
        require(_token.transferFrom(msg.sender, address(this), paid) == true, "BuyWDF: Couldn't transfer tokens to WDF Team");
        require(_wdf.transfer(msg.sender, amount) == true, "BuyWDF: Couldn't transfer WDF tokens to buyer");
		emit WDFSale(msg.sender, paid, amount);
        return true;
    }
	
	//IF BUY FOR ETHER
	function BuyWDFETH() payable public {
        uint256 amount = msg.value;
        require(amount > 0, "BuyWDFETH: amount is not positive");
        require(_priceeth > 0, "BuyWDFETH: price not configured");
        uint256 diff = 18 - _wdf.decimals();
        uint256 up = 1;
        for (uint8 i = 0; i < diff; i++){
            up *= 10;
        }
        uint256 getwdf = ( amount * _priceeth ) / up;
        require(getwdf > 0, "BuyWDF: received WDF amount is not positive");
        require(_wdf.transfer(msg.sender, getwdf) == true, "BuyWDFETH: Couldn't transfer WDF tokens to buyer");
        emit WDFSale(msg.sender, amount, getwdf);
    }
	
	function WithdrawSale(IERC20 token_address) public isOwner {
        address payable to = payable(_owner);
        uint256 balance = address(this).balance;
        if(balance > 0){
            to.transfer(balance);
        }
        uint256 balance_ = token_address.balanceOf(address(this));
        if(balance_ > 0){
            token_address.approve(address(this), balance_);
            token_address.transferFrom(address(this), _owner, balance_);
        }
    }

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    function getOwner() external view returns (address) {
        return _owner;
    }
	
    function setOwner(address newOwner) public isOwner {
		require(newOwner != address(0), "WDF: missing new Owner address");
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    modifier isOwner() {
        require(msg.sender == _owner, "WDF Caller is not owner");
        _;
    }
}

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "WDF SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "WDF SafeMath: subtraction overflow");
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
        require(c / a == b, "WDF SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "WDF SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "WDF SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "WDF Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "WDF Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "WDF Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "WDF Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "WDF Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "WDF Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.8.7;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "WDF: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "WDF: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "WDF: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "WDF: ERC20 operation did not succeed");
        }
    }
}