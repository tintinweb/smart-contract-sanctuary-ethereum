/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IERC20 {

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface ICustomERC20 is IERC20, IERC20Metadata {

    function deposit(uint256 _amount) external payable;

    function addBeneficiaries(address[] memory _beneficiaries, uint256 _amount)
        external;

    function addBeneficiary(address _beneficiary, uint256 _amount) external;

    function decreaseReward(address _beneficiary, uint256 _amount) external;

    function emergencyWithdraw(uint256 _amount) external;

    function lockRewards(bool isLock) external;

    function claim()external payable;

    event AdddedBeneficiary(address indexed _beneficiary, uint256 _amount);

    event BeneficiaryReward(address indexed _beneficiary, uint256 _amount);
}


contract CustomERC20 is ICustomERC20, Ownable {
    struct Beneficiar {
        uint256 reward;
        bool isClaimed;
    }

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool public isLocked;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => Beneficiar) public beneficiaries;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return balances[_account];
    }

    function transfer(address to, uint256 value)
        public
        override
        returns (bool)
    {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function allowance(address _account, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_account][spender];
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            balances[from] = fromBalance - amount;
        }
        balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function getBalance() public view returns (uint256) {
        return balances[address(this)];
    }

    function deposit(uint256 _amount) public payable override onlyOwner {
        require(balances[msg.sender] >= _amount, "Not enough funds");
        transfer(address(this), _amount);
    }

    function _addBeneficiary(address _beneficiary, uint256 _amount) private {
        require(
            beneficiaries[_beneficiary].reward == 0,
            "Beneficiary is already added"
        );
        beneficiaries[_beneficiary].reward = _amount;
        emit AdddedBeneficiary(_beneficiary, _amount);
    }

    function addBeneficiaries(address[] memory _beneficiaries, uint256 _amount)
        public
        override
        onlyOwner
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _addBeneficiary(_beneficiaries[i], _amount);
        }
    }

    function addBeneficiary(address _beneficiary, uint256 _amount)
        public
        override
        onlyOwner
    {
        _addBeneficiary(_beneficiary, _amount);
    }

    function decreaseReward(address _beneficiary, uint256 _amount)
        public
        override
        onlyOwner
    {
        require(
            beneficiaries[_beneficiary].reward != 0,
            "Beneficiary is not exists"
        );
        require(
            beneficiaries[_beneficiary].reward > _amount,
            "Beneficiary reward amount is less or equals zero"
        );

        beneficiaries[_beneficiary].reward -= _amount;
        emit BeneficiaryReward(
            _beneficiary,
            beneficiaries[_beneficiary].reward
        );
    }

    function emergencyWithdraw(uint256 _amount) public override onlyOwner {
        require(
            balances[address(this)] >= _amount,
            "Contract doesn`t have enough money! "
        );
        _transfer(address(this), msg.sender, _amount);
    }

    function lockRewards(bool isLock) public override onlyOwner {
        isLocked = isLock;
    }

    function claim() public payable override {
        require(!isLocked, "Reward is locked");
        require(
            !beneficiaries[msg.sender].isClaimed,
            "Reward tokens is already withdrow"
        );
        require(
            balances[address(this)] > beneficiaries[msg.sender].reward,
            "Contract doesn`t have enough money! "
        );
        _transfer(address(this), msg.sender, beneficiaries[msg.sender].reward);
        beneficiaries[msg.sender].isClaimed = true;
    }
}