// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { EIP712 } from "./draft-EIP712.sol";
import { ECDSA } from "./ECDSA.sol";

import { IERC20 } from "./IERC20.sol";
import { Ownable } from "./Ownable.sol";
import { TransactionThrottler } from "./TransactionThrottler.sol";
import { Constants } from "./Constants.sol";

contract Jigen is IERC20, EIP712, Ownable, TransactionThrottler {
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    constructor(address _admin) EIP712(Constants.getName(), "1") {
        _setOwner(_admin);
        _mint(_admin, 100_000_000 * 10**18);
    }

    function name() external pure returns (string memory) {
        return Constants.getName();
    }

    function symbol() external pure returns (string memory) {
        return Constants.getSymbol();
    }

    function decimals() external pure override returns (uint8) {
        return Constants.getDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external override returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
        return true;
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        if (currentAllowance < type(uint256).max) {
            // DEXes can use max allowance
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private transactionThrottler(sender, recipient, amount) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount is 0");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // Revert faster here then later on signature (gas saving for user)
        require(_owner != address(0), "ERC20Permit: Permit from zero address");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, spender, value, nonces[_owner]++, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == _owner, "ERC20Permit: invalid signature");

        _approve(_owner, spender, value);
    }
}