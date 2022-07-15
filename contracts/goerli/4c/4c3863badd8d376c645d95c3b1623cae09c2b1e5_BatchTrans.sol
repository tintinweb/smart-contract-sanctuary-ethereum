/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract BatchTrans is Ownable {
    function batchToken(address token, address[] memory toAddrs, uint256[] memory amounts) public {
        require(Address.isContract(token), "BatchTrans: not a token");
        require(toAddrs.length > 0, "BatchTrans: to addresses is empty");
        require(toAddrs.length <= 100, "BatchTrans: to addresses more than 100");
        require(toAddrs.length == amounts.length, "BatchTrans: amounts error");

        for (uint256 i = 0 ; i < toAddrs.length ; i++) {
            Address.functionCall(token, abi.encodeWithSelector(0x23b872dd, _msgSender(), toAddrs[i], amounts[i]));
        }
    }

    function batchToken(address token, address[] memory toAddrs, uint256 amount) public {
        require(Address.isContract(token), "BatchTrans: not a token");
        require(toAddrs.length > 0, "BatchTrans: to addresses is empty");
        require(toAddrs.length <= 100, "BatchTrans: to addresses more than 100");

        for (uint256 i = 0 ; i < toAddrs.length ; i++) {
            Address.functionCall(token, abi.encodeWithSelector(0x23b872dd, _msgSender(), toAddrs[i], amount));
        }
    }

    function batchETH(address[] memory toAddrs, uint256[] memory amounts) public payable {
        require(toAddrs.length > 0, "BatchTrans: to addresses is empty");
        require(toAddrs.length <= 100, "BatchTrans: to addresses more than 100");
        require(toAddrs.length == amounts.length, "BatchTrans: amounts error");

        uint256 totalAmount = 0;
        for (uint256 i = 0 ; i < toAddrs.length ; i++) {
            totalAmount += amounts[i];
        }

        require(msg.value >= totalAmount, "BatchTrans: insufficient amount");

        for (uint256 i = 0 ; i < toAddrs.length ; i++) {
            address payable to = payable(toAddrs[i]);
            to.transfer(amounts[i]);
        }
    }

    function batchETH(address[] memory toAddrs, uint256 amount) public payable {
        require(toAddrs.length > 0, "BatchTrans: to addresses is empty");
        require(toAddrs.length <= 100, "BatchTrans: to addresses more than 100");

        uint256 totalAmount = toAddrs.length * amount;

        require(msg.value >= totalAmount, "BatchTrans: insufficient amount");

        for (uint256 i = 0 ; i < toAddrs.length ; i++) {
            address payable to = payable(toAddrs[i]);
            to.transfer(amount);
        }
    }
}