// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Condor.sol";
import "./Extension.sol";

contract Scondor is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    address backAddress;
    address extensionContractAddress;
    address condorContractAddress;

    uint8 public constant _decimals = 18;
    uint256 _totalSupply = 100000000000 * 10**_decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _burningRate = 500000;
    uint256 private _maxBurningRate = 500000;

    /* Before this function we need to call the setMultiplier and setBuyAmount function 
    in the Extension contract when user buy product by using shop extension */
    constructor(
        address backend,
        address eAddress,
        address cAddress
    ) {
        backAddress = backend;
        extensionContractAddress = eAddress;
        condorContractAddress = cAddress;
    }

    function getReward(address rewardAddress, address backAddress_)
        public
        returns (uint256)
    {
        require(
            backAddress_ == backAddress,
            "User must be buy the products by extension"
        );
        uint256 multiplier = Extension(extensionContractAddress)
            .getMultiplier();
        uint256 _amount = Extension(extensionContractAddress).getBuyAmount();
        mint(rewardAddress, _amount * multiplier);
        burnCondor((_amount * multiplier * _burningRate) / _maxBurningRate);
        return balanceOf(rewardAddress);
    }

    /* This function burns condor token that was in the reservation */

    function burnCondor(uint256 _amount) public returns (bool) {
        Condor(payable(condorContractAddress)).burn(_amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /* Everytime user mints scondor token when then do shopping by extention*/

    function mint(address _to, uint256 _amount) public onlyOwner {
        _totalSupply += _amount;
        _balances[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "Cannot approve zero address");
        require(spender != address(0), "Cannot approve zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function updateBurningRate(uint256 _newBurningRate) external onlyOwner {
        _burningRate = _newBurningRate;
    }
}