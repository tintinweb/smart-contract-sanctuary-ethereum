// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Permit.sol";

/// @title Hashkey token contract
contract HashkeyTokenV0 is ERC20Permit {
    receive() external payable {
        require(false, "Contract is not payable");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IERC20.sol";
import "./library/Fund.sol";

/// @title Implement ERC20 token of Hashkey.
abstract contract ERC20 is Ownable, IERC20 {
    using SafeMath for uint256;

    /// @dev describe the account state for user, user's fund is consist of 3 parts
    struct AccountState {
        bool                    freezed;
        Fund.VestFund[]         vestFunds;
        Fund.EvenVestFund[]     evenVestFunds;
        uint256                 available;
    }

    // mock for test
    uint256 private constant BLOCKS_PER_YEAR  = 300;
    /// @dev consider 12 seconds as block producing duration.
    // uint256 private constant BLOCKS_PER_YEAR  = 300 * 24 * 365;

    string  private constant NAME             = "Hashkey Token";
    string  private constant SYMBOL           = "HSK";
    uint8   private constant DECIMALS         = 18;

    bool    private _initialized              = true;
    uint256 private _platformShare;
    uint256 private _reserveShare;
    uint256 private _teamShare;
    uint256 private _investorShare;
    uint256 private _totalSupply;

    mapping(address => AccountState) private accounts;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Mint(address indexed recipient, uint256 amount);
    event Burn(address indexed owner, uint256 amount);
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);
    event RecallVesting(address indexed account, uint256 amount);

    constructor() {
        // set owner to zero address.
        renounceOwnership();
    }

    /// @dev initialize token parameters.
    function init(address _owner) external {
        // not initialized in proxy
        require(!_initialized, "Already initialized");

        _initialized        = true;
        _platformShare      = 90000000 * 10 ** DECIMALS;
        _reserveShare       = 20000000 * 10 ** DECIMALS;
        _teamShare          = 70000000 * 10 ** DECIMALS;
        _investorShare      = 20000000 * 10 ** DECIMALS;
        _totalSupply        = 200000000 * 10 ** DECIMALS;

        _transferOwnership(_owner);
    }

    ///////////////////////////// ERC20 methods /////////////////////////////

    /// @dev see in IERC20
    function name() public pure override returns (string memory) {
        return NAME;
    }

    /// @dev see in IERC20.
    function symbol() public pure override returns (string memory) {
        return SYMBOL;
    }

    /// @dev see in IERC20.
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /// @dev see in IERC20.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev see in IERC20.
    /// @notice balance is consist of 3 parts: available, vested and even vested
    function balanceOf(address _owner) public view override returns (uint256) {
        AccountState storage state = accounts[_owner];
        uint256 balance = state.available;

        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                (, uint256 released) = Fund.getVestFund(fund, block.number);
                balance = balance.add(released);
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                (, uint256 released) = Fund.getEvenVestFund(fund, block.number);
                balance = balance.add(released);
            }
        }

        return balance;
    }

    /// @dev see in IERC20.
    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    /// @dev see in IERC20.
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @dev see in IERC20.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @dev see in IERC20.
    /// @notice if _allowance is max of uint256, it means allowance is not limited.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 _allowance = allowance(from, msg.sender);
        if (_allowance != type(uint256).max) {
            require(amount <= _allowance, "ERC20: Insufficient allowance");
            _allowances[from][msg.sender] = _allowance.sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    ///////////////////////////// HSK methods ///////////////////////////// 

    /// @dev batch execute transfer tokens.
    function batchTransfer(address[] memory tos, uint256[] memory amounts) external {
        require(tos.length == amounts.length, "unmatched array length");

        for (uint256 i = 0; i < tos.length; i++) {
            _transfer(msg.sender, tos[i], amounts[i]);
        }
    }

    /// @dev batch execute transferFrom tokens.
    /// @notice if _allowance is max of uint256, it means allowance is not limited.
    function batchTransferFrom(address from, address[] memory tos, uint256[] memory amounts) external {
        require(tos.length == amounts.length, "unmatched array length");
        uint256 _allowance = allowance(from, msg.sender);

        for (uint256 i = 0; i < tos.length; i++) {
            if (_allowance != type(uint256).max) {
                require(amounts[i] <= _allowance, "ERC20: Insufficient allowance");
                _allowance = _allowance.sub(amounts[i]);
            }
            _transfer(from, tos[i], amounts[i]);
        }

        _allowances[from][msg.sender] = _allowance;
    }

    /// @dev return _platformShare.
    function platformShare() public view returns (uint256) {
        return _platformShare;
    }

    /// @dev return _reserveShare.
    function reserveShare() public view returns (uint256) {
        return _reserveShare;
    }

    /// @dev return _investorShare.
    function investorShare() public view returns (uint256) {
        return _investorShare;
    }

    /// @dev return _teamShare.
    function teamShare() public view returns (uint256) {
        return _teamShare;
    }

    /// @dev vesting amount of vest fund and even vest fund.
    function vestingBalanceOf(address _owner) public view returns (uint256) {
        AccountState storage state = accounts[_owner];
        uint256 balance = 0;

        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                (uint256 vesting, ) = Fund.getVestFund(fund, block.number);
                balance = balance.add(vesting);
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                (uint256 vesting, ) = Fund.getEvenVestFund(fund, block.number);
                balance = balance.add(vesting);
            }
        }

        return balance;
    }

    /// @dev mint for platform share, no time locking.
    function mintTo(address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "Mint amount too less");
        require(amount <= _platformShare, "Insufficient platform share");
        _platformShare = _platformShare.sub(amount);

        AccountState storage state = accounts[recipient];
        _mint(state, amount);

        emit Mint(recipient, amount);
    }

    /// @dev batch mint for platform share
    function batchMintTo(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintTo(recipients[i], amounts[i]);
        }
    }

    /// @dev mint for reserve token, no time locking.
    function mintForReserve(address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "Mint amount too less");
        require(amount <= _reserveShare, "Insufficient reserve share");
        _reserveShare = _reserveShare.sub(amount);

        AccountState storage state = accounts[recipient];
        _mint(state, amount);

        emit Mint(recipient, amount);
    }

    /// @dev batch mint reserve tokens
    function batchMintForReserve(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintForReserve(recipients[i], amounts[i]);
        }
    }

    /// @dev mint to investors, lock for 1 year.
    function mintToInvestor(address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "Mint amount too less");
        require(amount <= _investorShare, "Insufficient investor share");
        _investorShare = _investorShare.sub(amount);

        AccountState storage state = accounts[recipient];
        _mintVestFund(state, Fund.FundType.Investor, amount, block.number.add(BLOCKS_PER_YEAR));

        emit Mint(recipient, amount);
    }

    /// @dev batch mint to investors
    function batchMintToInvestor(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintToInvestor(recipients[i], amounts[i]);
        }
    }

    /// @dev mint to team members, 10% will lock for 1 year, 90% will release in 2 more years evenly.
    function mintToTeamMember(address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "Mint amount too less");
        require(amount <= _teamShare, "Insufficient team share");
        _teamShare = _teamShare.sub(amount);

        AccountState storage state = accounts[recipient];
        
        uint256 vestAmount = amount.div(10);
        uint256 deadline = block.number.add(BLOCKS_PER_YEAR);
        _mintVestFund(state, Fund.FundType.Team, vestAmount, deadline);
        
        uint256 evenVestAmount = amount.sub(vestAmount);
        _mintEvenVestFund(state, Fund.FundType.Team, evenVestAmount, deadline, deadline.add(BLOCKS_PER_YEAR * 2));

        emit Mint(recipient, amount);
    }

    // batch mint to team members
    function batchMintToTeamMember(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintToTeamMember(recipients[i], amounts[i]);
        }
    }

    /// @dev freeze the account.
    function freeze(address account) external onlyOwner {
        accounts[account].freezed = true;

        emit Freeze(account);
    }

    /// @dev unfreeze the account.
    function unfreeze(address account) external onlyOwner {
        accounts[account].freezed = false;

        emit Unfreeze(account);
    }

    /// @dev recall vesting amount of team member.
    function recallVesting(address account) external onlyOwner {
        AccountState storage state = accounts[account];
        uint256 recycling = 0;

        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active && fund.fundType == Fund.FundType.Team) {
                fund.active = false;
                recycling = recycling.add(fund.amount);
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active && fund.fundType == Fund.FundType.Team) {
                fund.active = false;
                recycling = recycling.add(fund.amount);
            }
        }

        // recycle to teamShare
        _teamShare = _teamShare.add(recycling);

        emit RecallVesting(account, recycling);
    }

    /// @dev reduce amount of platform share, add reduce _totalSupply.
    function burnPlatformShare(uint256 amount) external onlyOwner {
        require(amount < _platformShare, "Insufficient platform share");
        _platformShare = _platformShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(msg.sender, amount);
    }

    /// @dev reduce amount of reserve share, add reduce _totalSupply.
    function burnReserveShare(uint256 amount) external onlyOwner {
        require(amount < _reserveShare, "Insufficient reserve share");
        _reserveShare = _reserveShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(msg.sender, amount);
    }

    /// @dev reduce amount of investor share, add reduce _totalSupply.
    function burnInvestorShare(uint256 amount) external onlyOwner {
        require(amount < _investorShare, "Insufficient investor share");
        _investorShare = _investorShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(msg.sender, amount);
    }

    /// @dev reduce amount of team share, add reduce _totalSupply.
    function burnTeamMemberShare(uint256 amount) external onlyOwner {
        require(amount < _teamShare, "Insufficient team share");
        _teamShare = _teamShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(msg.sender, amount);
    }

    /// @dev burn tokens of self.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /// @dev burn tokens from allowance.
    function burnFrom(address from, uint256 amount) public {
        uint256 _allowance = allowance(from, msg.sender);
        require(amount <= _allowance, "ERC20: Insufficient allowance");
        _allowances[from][msg.sender] = _allowance.sub(amount);
        _burn(from, amount);
    }

    ///////////////////////////// Internal Methods /////////////////////////////

    /// @dev compute the releasing amount of vest part and even vest part.
    function _updateAccountState(AccountState storage state) internal {
        require(!state.freezed, "Account is freezed");

        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                (uint256 vesting, uint256 released) = Fund.getVestFund(fund, block.number);
                if (released > 0) {
                    state.available = state.available.add(released);
                }
                fund.amount = vesting;
                if (vesting == 0) {
                    fund.active = false;
                }
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                (uint256 vesting, uint256 released) = Fund.getEvenVestFund(fund, block.number);
                if (released > 0) {
                    state.available = state.available.add(released);
                }
                fund.amount = vesting;
                if (vesting > 0) {
                    fund.start = uint64(block.number);
                } else {
                    fund.active = false;
                }
            }
        }
    }

    /// @dev add amount directly to user available.
    function _mint(AccountState storage state, uint256 amount) internal {
        state.available = state.available.add(amount);
    }

    /// @dev push the specified vest fund into user account state.
    function _mintVestFund(
        AccountState storage state,
        Fund.FundType fundType,
        uint256 amount,
        uint256 deadline
    ) internal {
        state.vestFunds.push(Fund.VestFund({
            active: true,
            fundType: fundType,
            amount: amount,
            deadline: uint64(deadline)
        }));
    }

    /// @dev push the specified even vest fund into user account state.
    function _mintEvenVestFund(
        AccountState storage state,
        Fund.FundType fundType,
        uint256 amount,
        uint256 start,
        uint256 end
    ) internal {
        state.evenVestFunds.push(Fund.EvenVestFund({
            active: true,
            fundType: fundType,
            amount: amount,
            start: uint64(start),
            end: uint64(end)
        }));
    }

    /// @dev transfer {amount} from {_from} to {_to}.
    /// @notice update account state firstly.
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "To should not be zero");

        AccountState storage fromState = accounts[from];
        _updateAccountState(fromState);
        require(fromState.available >= amount, "ERC20: Insufficient balance");
        fromState.available = fromState.available.sub(amount);

        AccountState storage toState = accounts[to];
        toState.available = toState.available.add(amount);

        emit Transfer(from, to, amount);
    }

    /// @dev approve {amount} of {spender} from {owner}
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(spender != address(0), "Spender should not be zero");

        _allowances[_owner][spender] = amount;
        
        emit Approval(_owner, spender, amount);
    }

    /// @dev burn {amount} of {owner}, and reduce _totalSupply.
    function _burn(address _owner, uint256 amount) internal {
        AccountState storage state = accounts[_owner];

        state.available = state.available.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(_owner, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "./interface/IERC20Permit.sol";
import "./ERC20.sol";

/// @title ERC20 with permit, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]
/// @notice ERC20 tokens which supports approvement via signature
abstract contract ERC20Permit is IERC20Permit, ERC20 {
    mapping(address => uint256) private _nonces;

    bytes32 private constant NAME_HASH = keccak256(bytes("Hashkey Token"));

    bytes32 private constant VERSION_HASH = keccak256(bytes("1"));

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @dev return user's current nonce and increase it.
    function increaseNonce(address account) internal virtual returns (uint256) {
        uint256 n = _nonces[account];
        _nonces[account]++;
        return n;
    }

    /// @dev See in IERC20Permit
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
    }

    /// @dev See in IERC20Permit.
    function nonces(address account) public view override returns (uint256) {
        return _nonces[account];
    }

    /// @dev See in IERC20Permit.
    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, _owner, spender, value, increaseNonce(_owner), deadline));
        bytes32 digest =
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

        if (_owner.code.length > 0) {
            // _owner is a contract
            require(IERC1271(_owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e, "ERC1271: Unauthorized");
        } else {
            address signer = ecrecover(digest, v, r, s);
            require(signer != address(0), "ERC20Permit: Invalid signature");
            require(signer == _owner, "ERC20Permit: Unauthorized");
        }

        _approve(_owner, spender, value);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
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
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Fund {
    using SafeMath for uint256;

    enum FundType {
        Investor,
        Team
    }

    /// @dev Vest fund means token will lock for a fixed period, 
    struct VestFund {
        bool            active;
        FundType        fundType;
        uint64          deadline;
        uint256         amount;
    }

    /// @dev Even Vest Fund means token will unlock evenly from start block to end block. 
    struct EvenVestFund {
        bool            active;
        FundType        fundType;
        uint64          start;
        uint64          end;
        uint256         amount;
    }

    /// @dev compute (vesting, vested) amount of VestFund.
    function getVestFund(VestFund storage fund, uint256 height) internal view returns (uint256, uint256) {
        require(fund.active, "Vest fund is not active");

        if (height >= fund.deadline) {
            return (0, fund.amount);
        } else {
            return (fund.amount, 0);
        }
    }

    /// @dev compute (vesting, vested) amount of EvenVestFund.
    function getEvenVestFund(EvenVestFund storage fund, uint256 height) internal view returns (uint256, uint256) {
        require(fund.active, "Even vest fund is not active");

        if (height <= fund.start) {
            return (fund.amount, 0);
        } else if (height > fund.start && height < fund.end) {
            uint256 vesting = fund.amount.mul(fund.end - height).div(fund.end - fund.start);
            return (vesting, fund.amount.sub(vesting));
        } else {
            return (0, fund.amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}