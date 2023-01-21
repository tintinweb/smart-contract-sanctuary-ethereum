// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface ICRSSEmission {
    function setRewardPerBlock(uint256 _amount, bool _withUpdate) external;
}

interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface ICRSS is IERC20 {
    function changeAccountantAddress(address _address) external;

    function changeControlCenter(address _address) external;

    function changeTransferFeeExclusionStatus(address target, bool value)
        external;

    function setBotWhitelist(address _target, bool _value) external;

    function changeBotCooldown(uint256 _value) external;

    function bulkTransferExclusionStatusChange(
        address[] memory targets,
        bool value
    ) external;

    function killswitch() external;

    function controlledMint(uint256 _amount) external;

    function cotrolledMintTo(address _to, uint256 _amount) external;

    function addEmissionReceiver(
        address _address,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) external;

    function setEmissionReceiver(
        uint256 _index,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) external;

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    event TradingHalted(uint256 blockNumber);
    event TradingResumed(uint256 blockNumber);
    event TransferFeeExclusionStatusUpdated(address target, bool value);
    event BulkTransferFeeExclusionStatusUpdated(address[] targets, bool value);
}

// CrssToken with Governance.
contract CrssToken is Context, ICRSS {
    using SafeMath for uint256;

    //==================== ERC20 core data ====================
    string private constant _name = "Crosswise Token";
    string private constant _symbol = "CRSS";

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //==================== Constants ====================
    string private constant sForbidden = "CRSS:Restricted access";
    string private constant sSameValue = "CRSS:Already set value";
    uint256 private constant maxSupply = 50 * 1e6 * (10**18);
    uint256 private constant maxCRSSEmission = 5 * (10**18);
    uint8 private constant _decimals = 18;

    //==================== Contract addresses  ====================
    address private controlCenter;
    address private accountant;
    address private adminSetter;
    //address public sCrss;
    //==================== Transfer control attributes and anti-bot ====================
    bool public tradingHalted;
    bool public antiBotActive;
    uint256 public cooldownPeriod;
    mapping(address => uint256) public userLastBuy;
    //must whitelist pairs in order for this to work properly
    mapping(address => bool) public botWhitelisted;
    uint256 public constant rateDenominator = 1000; // 0.1% tax on every CRSS transfer
    mapping(address => bool) private t_whitelisted;

    //==================== Custom emission functionality ====================

    mapping(address => bool) private emissionReceiver;

    struct s_Emission {
        uint256 paidOut;
        uint256 fromBlock;
        uint256 crssPerBlock;
        address receiver;
    }
    s_Emission[] public emissions;
    uint256 public totalEmission;
    mapping(address => uint256) private paidOutPreviously;
    mapping(address => bool) public activeEmissionReceiver;
    mapping(address => uint256) public addressToIndex;
    event RemovedReceiver(
        address receiver,
        uint256 crssPerBlock,
        uint256 index
    );
    event SetEmissionReceiver(
        address receiver,
        uint256 crssPerBlockOld,
        uint256 crssPerBlockNew,
        uint256 index
    );

    receive() external payable {}

    constructor(address _controlCenter, address _accountant) {
        // Mint 1e6 Crss to the caller for testing - MUST BE REMOVED BEFORE DEPLOY
        accountant = _accountant;
        adminSetter = msg.sender;
        controlCenter = _controlCenter;
        _mint(_msgSender(), 1e6 * 10**_decimals);
    }

    modifier onlyControlCenter() {
        require(_msgSender() == controlCenter, sForbidden);
        _;
    }

    function getControlCenter() public view returns (address) {
        return controlCenter;
    }

    function getAccountant() public view returns (address) {
        return accountant;
    }

    function getAdminSetter() public view returns (address) {
        return adminSetter;
    }

    function getMaxSupply() public pure returns (uint256) {
        return maxSupply;
    }

    /* function getSCRSSAddress()public view returns(address){
        return sCrss;
    }

    function sCrssSetup(address _sCrss) public onlyControlCenter {
        require(sCrss == address(0), "CRSS:Only called once");
        sCrss = _sCrss;
        _allowances[address(this)][_sCrss] = type(uint256).max;
    }*/

    /**CRSS:Insufficient allowance
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */

    // 0.1% constant fee on transfer, has an adjustable, in-built anti-frontrunning and anti-arbitrage bot that can be turned off/on
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(amount > 0, "CRSS:Zero value transfer");
        require(tradingHalted == false, "CRSS:Trading halted");
        require(
            sender != address(0) && recipient != address(0),
            "CRSS:Zero address"
        );
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "CRSS:Exceeds balance");
        uint256 transferAmount = amount;
        if (antiBotActive == true) {
            if (!botWhitelisted[sender]) {
                uint256 currentBlock = block.timestamp;
                require(
                    userLastBuy[sender] + cooldownPeriod <= currentBlock,
                    "CRSS:Cooldown period after receiving tokens"
                );
                userLastBuy[recipient] = currentBlock;
            }
        }
        if (t_whitelisted[sender] != true) {
            uint256 taxAmount = amount / rateDenominator;
            _balances[accountant] += taxAmount;
            transferAmount -= taxAmount;
        }
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += transferAmount;
        emit Transfer(sender, recipient, amount);
    }

    function changeTransferFeeExclusionStatus(address target, bool value)
        public
        override
        onlyControlCenter
    {
        require(t_whitelisted[target] != value, sSameValue);
        t_whitelisted[target] = value;
        emit TransferFeeExclusionStatusUpdated(target, value);
    }

    function changeBotCooldown(uint256 _value)
        public
        override
        onlyControlCenter
    {
        cooldownPeriod = _value;
    }

    function bulkTransferExclusionStatusChange(
        address[] memory targets,
        bool value
    ) public override onlyControlCenter {
        for (uint256 i = 0; i < targets.length; i++) {
            t_whitelisted[targets[i]] = value;
        }

        emit BulkTransferFeeExclusionStatusUpdated(targets, value);
    }

    function changeAccountantAddress(address _address)
        public
        override
        onlyControlCenter
    {
        require(accountant != _address, sSameValue);
        accountant = _address;
    }

    function changeControlCenter(address _address) public override {
        require(
            msg.sender == adminSetter || msg.sender == controlCenter,
            "CRSS:Only admin setter and CC"
        );
        require(controlCenter != _address, sSameValue);
        controlCenter = _address;
    }

    //works for sCRSS transfer and DEX swaps in addition to CRSS transfer
    //cannot be bypassed by admin
    function killswitch() public override onlyControlCenter {
        bool isHalted = tradingHalted;
        if (isHalted == false) {
            isHalted = true;
            emit TradingHalted(block.number);
        } else {
            isHalted = false;
            emit TradingResumed(block.number);
        }
    }

    function setBotWhitelist(address _target, bool _value)
        public
        override
        onlyControlCenter
    {
        botWhitelisted[_target] = _value;
    }

    //==================== Custom mint functionality ====================

    function getReceiverEmission(address _receiver)
        public
        view
        returns (uint256)
    {
        uint256 receiverIndex = addressToIndex[_receiver];
        return emissions[receiverIndex].paidOut + paidOutPreviously[_receiver];
    }

    function getTotalEmission() public view returns (uint256) {
        return totalEmission;
    }

    function controlledMint(uint256 _amount) external override {
        require(activeEmissionReceiver[msg.sender] == true, sForbidden);
        uint256 receiverIndex = addressToIndex[msg.sender];
        s_Emission memory emissionObject = emissions[receiverIndex];
        require(
            _amount + emissionObject.paidOut <=
                emissionObject.crssPerBlock *
                    (block.number - emissionObject.fromBlock),
            "CRSS:Minting over allowed amount"
        );
        emissions[receiverIndex].paidOut += _amount;
        _mint(msg.sender, _amount);
    }

    function cotrolledMintTo(address _to, uint256 _amount) external override {
        require(activeEmissionReceiver[msg.sender] == true, sForbidden);
        uint256 receiverIndex = addressToIndex[msg.sender];
        s_Emission memory emissionObject = emissions[receiverIndex];
        require(
            _amount + emissionObject.paidOut <=
                emissionObject.crssPerBlock *
                    (block.number - emissionObject.fromBlock),
            "CRSS:Minting over allowed amount"
        );
        emissions[receiverIndex].paidOut += _amount;
        _mint(_to, _amount);
    }

    function addEmissionReceiver(
        address _address,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) public override onlyControlCenter {
        require(
            activeEmissionReceiver[_address] != true,
            "CRSS:Receiver already exists"
        );
        require(
            _crssPerBlock + totalEmission < maxCRSSEmission,
            "CRSS:Total max emission is 5 CRSS per block"
        );

        emissions.push(
            s_Emission({
                paidOut: 0,
                fromBlock: block.number,
                crssPerBlock: _crssPerBlock,
                receiver: _address
            })
        );
        activeEmissionReceiver[_address] = true;
        addressToIndex[_address] = emissions.length - 1;
        totalEmission += _crssPerBlock;
        if (_hasInterface) {
            ICRSSEmission(_address).setRewardPerBlock(
                _crssPerBlock,
                _withUpdate
            );
        }
    }

    function setEmissionReceiver(
        uint256 _index,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) public override onlyControlCenter {
        s_Emission storage emissionObject = emissions[_index];
        require(_crssPerBlock != emissionObject.crssPerBlock, sSameValue);
        require(
            activeEmissionReceiver[emissionObject.receiver] == true,
            "CRSS:Receiver doesn't exist"
        );
        if (_index == 0) {
            require(
                (_crssPerBlock * 40) / 100 <= totalEmission,
                "CRSS:Max emission percent for protocol is 40%"
            );
            require(_crssPerBlock != 0, "CRSS:Can't be destroyed");
        }
        paidOutPreviously[emissionObject.receiver] += emissionObject.paidOut;
        // s_Emission storage emissionObject = emission[_address];
        if (_crssPerBlock > emissionObject.crssPerBlock) {
            uint256 emissionIncrease = _crssPerBlock -
                emissionObject.crssPerBlock;
            require(
                emissionIncrease + totalEmission <= 5 * (10**18),
                "CRSS:Max per-block emission is 5 CRSS"
            );
            totalEmission += emissionIncrease;
        } else {
            totalEmission -= (emissionObject.crssPerBlock - _crssPerBlock);
            if (_crssPerBlock == 0) {
                emit RemovedReceiver(
                    emissionObject.receiver,
                    emissionObject.crssPerBlock,
                    _index
                );
                activeEmissionReceiver[emissionObject.receiver] = false;
                addressToIndex[emissionObject.receiver] = 0;
                emissions[_index] = emissions[emissions.length - 1];
                emissions.pop();
                if (_hasInterface) {
                    ICRSSEmission(emissionObject.receiver).setRewardPerBlock(
                        _crssPerBlock,
                        _withUpdate
                    );
                }

                return;
            }
        }

        emissionObject.paidOut = 0;
        emissionObject.fromBlock = block.number;
        emit SetEmissionReceiver(
            emissionObject.receiver,
            emissionObject.crssPerBlock,
            _crssPerBlock,
            _index
        );
        emissionObject.crssPerBlock = _crssPerBlock;
        if (_hasInterface) {
            ICRSSEmission(emissionObject.receiver).setRewardPerBlock(
                _crssPerBlock,
                _withUpdate
            );
        }
    }

    //====================Standard ERC20 functions ====================

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "CRSS:Decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "CRSS:Mint to zero address");
        _totalSupply += amount;
        require(_totalSupply <= maxSupply, "CRSS:Max supply reached");
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "CRSS:Burn from zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "CRSS:Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "CRSS:Approve from zero address");
        require(spender != address(0), "CRSS:Approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "CRSS:Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    mapping(address => uint256) private lastClaimed;

    ///TEMP TESTING FUNCTIONS
    function getCRSSTokens() public {
        require(block.number - lastClaimed[msg.sender] >= 1200);
        _mint(msg.sender, 100 * 10**18);
        lastClaimed[msg.sender] = block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}