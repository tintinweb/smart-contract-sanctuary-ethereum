/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: ERC-20 Token X7101

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setLiquidityHub(address liquidityHub_) external onlyOwner {
        require(!liquidityHubFrozen);
        liquidityHub = ILiquidityHub(liquidityHub_);
    }

    function setDiscountAuthority(address discountAuthority_) external onlyOwner {
        require(!discountAuthorityFrozen);
        discountAuthority = IDiscountAuthority(discountAuthority_);
    }

    function setFeeNumerator(uint256 feeNumerator_) external onlyOwner {
        require(feeNumerator_ <= maxFeeNumerator);
        feeNumerator = feeNumerator_;
    }

    function setAMM(address ammAddress, bool isAMM) external {
        require(msg.sender == address(liquidityHub) || msg.sender == owner(), "Only the owner or the liquidity hub may add a new pair");
        ammPair[ammAddress] = isAMM;
    }

    function setOffRampPair(address ammAddress) external {
        require(msg.sender == address(liquidityHub) || msg.sender == owner(), "Only the owner or the liquidity hub may add a new pair");
        offRampPair = ammAddress;
    }

    function freezeLiquidityHub() external onlyOwner {
        require(!liquidityHubFrozen);
        liquidityHubFrozen = true;
    }

    function freezeDiscountAuthority() external onlyOwner {
        require(!discountAuthorityFrozen);
        discountAuthorityFrozen = true;
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
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

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
}

interface ILiquidityHub {
    function processFees(address) external;
}

interface IDiscountAuthority {
    function discountRatio(address) external returns (uint256, uint256);
}

contract X7101 is ERC20, Ownable {

    IDiscountAuthority public discountAuthority;
    ILiquidityHub public liquidityHub;

    mapping(address => bool) public ammPair;
    address public offRampPair;

    // max 6% fee
    uint256 public maxFeeNumerator = 600;

    // 2 % fee
    uint256 public feeNumerator = 200;
    uint256 public feeDenominator = 10000;

    bool discountAuthorityFrozen;
    bool liquidityHubFrozen;

    event LiquidityHubSet(address indexed liquidityHub);
    event DiscountAuthoritySet(address indexed discountAuthority);
    event FeeNumeratorSet(uint256 feeNumerator);
    event AMMSet(address indexed pairAddress, bool isAMM);
    event OffRampPairSet(address indexed offRampPair);
    event LiquidityHubFrozen();
    event DiscountAuthorityFrozen();

    constructor(
        address discountAuthority_,
        address liquidityHub_
    ) ERC20("X7101", "X7101") Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        discountAuthority = IDiscountAuthority(discountAuthority_);
        liquidityHub = ILiquidityHub(liquidityHub_);

        _mint(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105), 100000000 * 10**18);
    }

    function setLiquidityHub(address liquidityHub_) external onlyOwner {
        require(!liquidityHubFrozen);
        liquidityHub = ILiquidityHub(liquidityHub_);
        emit LiquidityHubSet(liquidityHub_);
    }

    function setDiscountAuthority(address discountAuthority_) external onlyOwner {
        require(!discountAuthorityFrozen);
        discountAuthority = IDiscountAuthority(discountAuthority_);
        emit DiscountAuthoritySet(discountAuthority_);
    }

    function setFeeNumerator(uint256 feeNumerator_) external onlyOwner {
        require(feeNumerator_ <= maxFeeNumerator);
        feeNumerator = feeNumerator_;
        emit FeeNumeratorSet(feeNumerator_);
    }

    function setAMM(address ammAddress, bool isAMM) external {
        require(msg.sender == address(liquidityHub) || msg.sender == owner(), "Only the owner or the liquidity hub may add a new pair");
        ammPair[ammAddress] = isAMM;
        emit AMMSet(ammAddress, isAMM);
    }

    function setOffRampPair(address ammAddress) external {
        require(msg.sender == address(liquidityHub) || msg.sender == owner(), "Only the owner or the liquidity hub may add a new pair");
        offRampPair = ammAddress;
        emit OffRampPairSet(ammAddress);
    }

    function freezeLiquidityHub() external onlyOwner {
        require(!liquidityHubFrozen);
        liquidityHubFrozen = true;
        emit LiquidityHubFrozen();
    }

    function freezeDiscountAuthority() external onlyOwner {
        require(!discountAuthorityFrozen);
        discountAuthorityFrozen = true;
        emit DiscountAuthorityFrozen();
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(address(0)) - balanceOf(address(0x000000000000000000000000000000000000dEaD));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 transferAmount = amount;

        if (
            from == address(liquidityHub)
            || to == address(liquidityHub)
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (
            ammPair[to] || ammPair[from]
        ) {
            (uint256 feeModifierNumerator, uint256 feeModifierDenominator) = discountAuthority.discountRatio(msg.sender);
            if (feeModifierNumerator > feeModifierDenominator || feeModifierDenominator == 0) {
                feeModifierNumerator = 1;
                feeModifierDenominator = 1;
            }

            uint256 feeAmount = amount * feeNumerator * feeModifierNumerator / feeDenominator / feeModifierDenominator;

            super._transfer(from, address(liquidityHub), feeAmount);
            transferAmount = amount - feeAmount;
        }

        if (
            to == offRampPair
        ) {
            liquidityHub.processFees(address(this));
        }

        super._transfer(from, to, transferAmount);
    }

    function rescueETH() external {
        (bool success,) = payable(address(liquidityHub)).call{value: address(this).balance}("");
        require(success);
    }

    function rescueTokens(address tokenAddress) external {
        IERC20(tokenAddress).transfer(address(liquidityHub), IERC20(tokenAddress).balanceOf(address(this)));
    }

}