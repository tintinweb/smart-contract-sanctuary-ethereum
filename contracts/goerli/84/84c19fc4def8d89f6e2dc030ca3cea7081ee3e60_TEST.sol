/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * TiFiToken = The integrated Finance Token
 * A new type of contract that designed and implemented by TiFi Community
 */
contract TEST is IBEP20, Context, Ownable {
    struct Values {
        uint256 rSendAmount;
        uint256 rReceiveAmount;
        uint256 rRflx;
        uint256 rBurn;
        uint256 tSendAmount;
        uint256 tReceiveAmount;
        uint256 tRflx;
        uint256 tReward;
        uint256 tBurn;
        uint256 tCmty;
    }
    event ApplyReward(address indexed account, uint256 reward);
    event SetCommunityAccount(address indexed account);
    event SetDBank(address indexed account);
    event UpdatePairs(address indexed account, bool enable);
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _noFee;
    mapping(address => bool) private _pairs;
    address[] private _pairList;

    string private constant _NAME = "TESTING";
    string private constant _SYMBOL = "TEST";
    uint256 private constant _DECIMALS = 9;
    address public constant ZERO_ADDR = address(0);
    address public CMTY_ADDR; // Community Address
    address public BANK_ADDR; // DBank Address

    uint256 private constant _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR = 10**_DECIMALS;
    uint256 private constant _GRANULARITY = 10000;

    uint256 private _tTotal = (10**7) * _DECIMALFACTOR; // Total supply: 1 Quadrillion
    uint256 private _rTotal = _MAX - (_MAX % _tTotal);
    uint256 private _rtRate = _rTotal / _tTotal;

    uint256 private _tRflxTotal;
    uint256 private _tBurnTotal;

    uint256 public SEND_REWARD = 0; // 3%
    uint256 public RECV_CHARGE = 0; // 3%
    uint256 public BUY_RATE = 300; // 3%
    uint256 public SELL_RATE = 300; // 3%
    uint256 public RFLX_RATE = 0; // 60% of (charge - reward)
    uint256 public BURN_RATE = 0; // 20% of (charge - reward)
    uint256 public CMTY_RATE = 0; // 20% of (charge - reward)

    constructor() payable {
        _owner = _msgSender();
        CMTY_ADDR = _owner;
        BANK_ADDR = _owner;
        _rOwned[_owner] = _rTotal;
        _noFee[_owner] = true;
        _noFee[ZERO_ADDR] = true;
        _pairs[ZERO_ADDR] = true;

        _msgSender().transfer(msg.value);
        emit Transfer(ZERO_ADDR, _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return uint8(_DECIMALS);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_pairs[account] || account == ZERO_ADDR) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external override returns (bool) {
        uint256 allow = _allowances[sender][_msgSender()];
        require(allow >= amount, "Transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allow - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 allow = _allowances[_msgSender()][spender];
        require(allow >= subtractedValue, "Decreased allowance below zero");
        _approve(_msgSender(), spender, allow - subtractedValue);
        return true;
    }

    function hasFee(address account) public view returns (bool) {
        return !_noFee[account];
    }

    function totalRflx() public view returns (uint256) {
        return _tRflxTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function reflectionFromToken(uint256 tAmount)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        return tAmount * _rtRate;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "Amount must be less than reflections");
        return rAmount / _rtRate;
    }

    function setCommunityAccount(address account) external onlyOwner {
        require(CMTY_ADDR != account, "The same address is already set");
        if (
            BANK_ADDR == owner() ||
            BANK_ADDR == ZERO_ADDR ||
            BANK_ADDR == CMTY_ADDR
        ) {
            // If bank address is not set yet, set to community address.
            // If bank address is community address, the bank address is set as well (Bank/Community Affiliation).
            BANK_ADDR = account;
        }
        if (CMTY_ADDR != owner() && CMTY_ADDR != BANK_ADDR) {
            _noFee[CMTY_ADDR] = false; // Re-enable fee to original community address
        }
        CMTY_ADDR = account;
        _noFee[account] = true; // Disable fee for new community address
        emit SetCommunityAccount(account);
    }

    function setDBank(address account) external onlyOwner {
        // Set DBank's smart contract address
        require(BANK_ADDR != account, "The same address is already set");
        _noFee[BANK_ADDR] = false;
        BANK_ADDR = account;
        _noFee[BANK_ADDR] = true;
        emit SetDBank(account);
    }

    function setFee(address account, bool enable) external onlyOwner {
        require(_noFee[account] == enable, "Already set");
        _noFee[account] = (!enable);
    }

    function setPairAddress(address account) external onlyOwner {
        require(
            !_pairs[account] && account != ZERO_ADDR,
            "Cannot set pair address"
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _pairs[account] = true;
        _pairList.push(account);
        _updateRTRate();
        emit UpdatePairs(account, true);
    }

    function unsetPairAddress(address account) external onlyOwner {
        require(
            _pairs[account] && account != ZERO_ADDR,
            "Cannot remove pair address"
        );
        for (uint256 i = 0; i < _pairList.length; i++) {
            if (_pairList[i] == account) {
                _pairList[i] = _pairList[_pairList.length - 1];
                _tOwned[account] = 0;
                _pairs[account] = false;
                _pairList.pop();
                _updateRTRate();
                break;
            }
        }
        emit UpdatePairs(account, false);
    }

    function getRewardCharge(address sender, address recipient)
        public
        view
        returns (uint256, uint256)
    {
        require(
            _allowances[sender][_msgSender()] > 0 ||
                sender == _msgSender() ||
                recipient == _msgSender(),
            "Ineligible to view reward or charge"
        );
        if (_noFee[sender] || _noFee[recipient]) {
            return (0, 0);
        }
        if (_pairs[sender]) {
            return (0, BUY_RATE);
        }
        if (_pairs[recipient]) {
            return (0, SELL_RATE);
        }
        return (SEND_REWARD, RECV_CHARGE);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        require(
            sender != ZERO_ADDR && recipient != ZERO_ADDR,
            "Transfer from/to the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(sender) >= amount, "Transfer amount exceeds balance");

        (uint256 reward, uint256 charge) = getRewardCharge(sender, recipient);
        Values memory v = _getValues(amount, reward, charge);
        _rOwned[sender] -= v.rSendAmount;
        _rOwned[recipient] += v.rReceiveAmount;
        if (_pairs[sender]) _tOwned[sender] -= v.tSendAmount;
        if (_pairs[recipient]) _tOwned[recipient] += v.tReceiveAmount;
        _reflectFee(v, sender);
        _updateRTRate();
        emit Transfer(sender, recipient, v.tReceiveAmount);
        emit ApplyReward(recipient, v.tReward);
        return true;
    }

    function _reflectFee(Values memory v, address sender) private {
        _sendToBank(v.tCmty, sender);
        _rTotal -= (v.rRflx + v.rBurn);
        _tRflxTotal += v.tRflx;
        _tBurnTotal += v.tBurn;
        _tTotal -= v.tBurn;
        emit Transfer(address(this), address(0), v.tBurn);
    }

    function _getValues(
        uint256 tAmount,
        uint256 rewardRate,
        uint256 chargeRate
    ) private view returns (Values memory) {
        (
            uint256 tCharge,
            uint256 tReward,
            uint256 tRflx,
            uint256 tBurn,
            uint256 tCmty
        ) = _getTBasics(tAmount, rewardRate, chargeRate);
        uint256 tSendAmount = tAmount - tReward;
        uint256 tReceiveAmount = tAmount - tCharge;
        (uint256 rSendAmount, uint256 rRflx) = _getRBasics(tSendAmount, tRflx);
        uint256 rReceiveAmount = _getRReceiveAmount(
            rSendAmount,
            rRflx,
            tBurn,
            tCmty
        );
        uint256 rBurn = tBurn * _rtRate;
        return
            Values(
                rSendAmount,
                rReceiveAmount,
                rRflx,
                rBurn,
                tSendAmount,
                tReceiveAmount,
                tRflx,
                tReward,
                tBurn,
                tCmty
            );
    }

    function _getTBasics(
        uint256 tAmount,
        uint256 rewardRate,
        uint256 chargeRate
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tCharge = (tAmount * chargeRate) / _GRANULARITY;
        uint256 tReward = (tAmount * rewardRate) / _GRANULARITY;
        uint256 income = tCharge - tReward;
        uint256 tRflx = (income * RFLX_RATE) / _GRANULARITY;
        uint256 tBurn = (income * BURN_RATE) / _GRANULARITY;
        uint256 tCmty = (income * CMTY_RATE) / _GRANULARITY;
        return (tCharge, tReward, tRflx, tBurn, tCmty);
    }

    function _getRBasics(uint256 tSendAmount, uint256 tRflx)
        private
        view
        returns (uint256, uint256)
    {
        return (tSendAmount * _rtRate, tRflx * _rtRate);
    }

    function _getRReceiveAmount(
        uint256 rSendAmount,
        uint256 rRflx,
        uint256 tBurn,
        uint256 tCmty
    ) private view returns (uint256) {
        return rSendAmount - rRflx - tBurn * _rtRate - tCmty * _rtRate;
    }

    function _updateRTRate() private {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _pairList.length; i++) {
            if (
                _rOwned[_pairList[i]] > rSupply ||
                _tOwned[_pairList[i]] > tSupply
            ) {
                _rtRate = _rTotal / _tTotal;
                return;
            }
            rSupply -= _rOwned[_pairList[i]];
            tSupply -= _tOwned[_pairList[i]];
        }
        _rtRate = (rSupply < _rTotal / _tTotal)
            ? _rTotal / _tTotal
            : rSupply / tSupply;
    }

    function _sendToBank(uint256 tCmty, address sender) private {
        _rOwned[BANK_ADDR] += tCmty * _rtRate;
        if (_pairs[BANK_ADDR]) _tOwned[BANK_ADDR] += tCmty;
        emit Transfer(sender, BANK_ADDR, tCmty);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != ZERO_ADDR, "Burn from the zero address");
        require(balanceOf(account) >= amount, "Burn amount exceeds balance");
        _rOwned[account] -= amount * _rtRate;
        if (_pairs[account]) _tOwned[account] -= amount;
        uint256 rBurn = amount * _rtRate;
        _rTotal -= rBurn;
        _tBurnTotal += amount;
        _tTotal -= amount;
        _updateRTRate();
        emit Transfer(account, ZERO_ADDR, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}