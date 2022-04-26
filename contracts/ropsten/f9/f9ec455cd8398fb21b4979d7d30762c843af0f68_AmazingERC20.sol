/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

        (bool success, bytes memory returndata) = target.call{value: value}(data);

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

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {

        return interfaceId == type(IERC165).interfaceId;

    }

}

interface IERC1363Receiver {

    function onTransferReceived(

        address operator,

        address sender,

        uint256 amount,

        bytes calldata data

    ) external returns (bytes4);

}

interface IERC1363Spender {

    function onApprovalReceived(

        address sender,

        uint256 amount,

        bytes calldata data

    ) external returns (bytes4);

}

interface IERC20 {

    

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from,address to,uint256 amount) external returns (bool);

}

interface IERC1363 is IERC20, IERC165 {

    function transferAndCall(address to, uint256 amount) external returns (bool);

    function transferAndCall(

        address to,

        uint256 amount,

        bytes calldata data

    ) external returns (bool);

    function transferFromAndCall(

        address sender,

        address to,

        uint256 amount

    ) external returns (bool);

    function transferFromAndCall(

        address sender,

        address to,

        uint256 amount,

        bytes calldata data

    ) external returns (bool);

    function approveAndCall(address spender, uint256 amount) external returns (bool);

    function approveAndCall(

        address spender,

        uint256 amount,

        bytes calldata data

    ) external returns (bool);

}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}

contract AmazingERC20 is Context, IERC20, IERC20Metadata, Ownable, ERC165, IERC1363 {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint256 private _initialSupply;

    uint8 private _decimals;

    string private _name;

    string private _symbol;

    constructor(string memory name_, string memory symbol_, uint8 decimal_ , uint256 initialSupply_, uint totalSupply_) {

        _name = name_;

        _symbol = symbol_;

        _decimals = decimal_;

        uint256 temp = totalSupply_;

        temp = 0;

        _initialSupply = initialSupply_;

        _totalSupply = 0;

        _balances[msg.sender] = _initialSupply;

    }

    function name() public view virtual override returns (string memory) {

        return _name;

    }

    function symbol() public view virtual override returns (string memory) {

        return _symbol;

    }

    function decimals() public view virtual override returns (uint8) {

        return _decimals;

    }

    function totalSupply() public view virtual override returns (uint256) {

        return _totalSupply;

    }

    function initialSuppply() public view returns(uint){

        return _initialSupply;

    }

    function balanceOf(address account) public view virtual override returns (uint256) {

        return _balances[account];

    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {

        address owner = _msgSender();

        _transfer(owner, to, amount);

        return true;

    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {

        return _allowances[owner][spender];

    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {

        address owner = _msgSender();

        _approve(owner, spender, amount);

        return true;

    }

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) public virtual override returns (bool) {

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        _transfer(from, to, amount);

        return true;

    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        address owner = _msgSender();

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;

    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        address owner = _msgSender();

        uint256 currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {

            _approve(owner, spender, currentAllowance - subtractedValue);

        }

        return true;

    }

    function _transfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {

        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {

            _balances[from] = fromBalance - amount;

        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);

    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;

        _balances[account] += amount;

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {

            _balances[account] = accountBalance - amount;

        }

        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);

    }

    function _approve(

        address owner,

        address spender,

        uint256 amount

    ) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }

    function _spendAllowance(

        address owner,

        address spender,

        uint256 amount

    ) internal virtual {

        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {

            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            unchecked {

                _approve(owner, spender, currentAllowance - amount);

            }

        }

    }

    function _beforeTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

    function _afterTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

    function mint(address to, uint256 amount) public onlyOwner {

        _mint(to, amount);

    }

    function burn(uint256 amount) public virtual {

        _burn(_msgSender(), amount);

    }

    function burnFrom(address account, uint256 amount) public virtual {

        _spendAllowance(account, _msgSender(), amount);

        _burn(account, amount);

    }  

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {

        IERC20(tokenAddress).transfer(owner(), tokenAmount);

    }

    using Address for address;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {

        return interfaceId == type(IERC1363).interfaceId || super.supportsInterface(interfaceId);

    }

    function transferAndCall(address to, uint256 amount) public virtual override returns (bool) {

        return transferAndCall(to, amount, "");

    }

    function transferAndCall(

        address to,

        uint256 amount,

        bytes memory data

    ) public virtual override returns (bool) {

        transfer(to, amount);

        require(_checkAndCallTransfer(_msgSender(), to, amount, data), "ERC1363: _checkAndCallTransfer reverts");

        return true;

    }

    function transferFromAndCall(

        address from,

        address to,

        uint256 amount

    ) public virtual override returns (bool) {

        return transferFromAndCall(from, to, amount, "");

    }

    function transferFromAndCall(

        address from,

        address to,

        uint256 amount,

        bytes memory data

    ) public virtual override returns (bool) {

        transferFrom(from, to, amount);

        require(_checkAndCallTransfer(from, to, amount, data), "ERC1363: _checkAndCallTransfer reverts");

        return true;

    }

    function approveAndCall(address spender, uint256 amount) public virtual override returns (bool) {

        return approveAndCall(spender, amount, "");

    }

    function approveAndCall(

        address spender,

        uint256 amount,

        bytes memory data

    ) public virtual override returns (bool) {

        approve(spender, amount);

        require(_checkAndCallApprove(spender, amount, data), "ERC1363: _checkAndCallApprove reverts");

        return true;

    }

    function _checkAndCallTransfer(

        address sender,

        address recipient,

        uint256 amount,

        bytes memory data

    ) internal virtual returns (bool) {

        if (!recipient.isContract()) {

            return false;

        }

        bytes4 retval = IERC1363Receiver(recipient).onTransferReceived(_msgSender(), sender, amount, data);

        return (retval == IERC1363Receiver(recipient).onTransferReceived.selector);

    }

    function _checkAndCallApprove(

        address spender,

        uint256 amount,

        bytes memory data

    ) internal virtual returns (bool) {

        if (!spender.isContract()) {

            return false;

        }

        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data);

        return (retval == IERC1363Spender(spender).onApprovalReceived.selector);

    }

}