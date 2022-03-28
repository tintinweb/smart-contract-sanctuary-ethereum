/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}




interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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



contract LCXVestingToken is Ownable {
    using SafeMath for uint256;

    address private immutable LCX_TOKEN; // Contract Address of LCX Token
    address private SaleContract; // Contract Address of Sale Tiamond

    struct VestedToken {
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 releasedToken;
        uint256 totalToken;
        bool revoked;
    }

    // mapped with token id
    mapping(address => VestedToken) public vestedUser;

    modifier onlySaleContract(){
        require(SaleContract == _msgSender(), "Only Sale Contract can call");
        _;
    }

    event TokenReleased(address indexed account, uint256 amount);
    event VestingRevoked(address indexed account);
    event SetSaleContractAddress(address);

    constructor(address _lcxAddress){
        require(_lcxAddress != address(0), "Address should not be zero address");
        LCX_TOKEN = _lcxAddress;
    }

    function setSaleAddress(address _saleAddress) external onlyOwner {
        require(_saleAddress != address(0), "Must be an address");
        SaleContract = _saleAddress;
        emit SetSaleContractAddress(_saleAddress);
    }
    

    /**
     * @dev this will set the beneficiary with vesting
     * parameters provided
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vesting
     * @param duration In seconds of total vesting
     * @param startAt UNIX timestamp in seconds from where vesting will start
     */
    function setVesting(
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 duration,
        uint256 startAt
    ) external onlySaleContract returns (bool) {
        VestedToken storage vested = vestedUser[account];
        if (vested.start > 0) {
            require(vested.revoked, "Account vesting is still going on");
            uint256 unclaimedTokens = _vestedAmount(account).sub(
                vested.releasedToken
            );
            require(unclaimedTokens == 0, "Account vesting is still going on");
        }
        IERC20(LCX_TOKEN).transferFrom(_msgSender(), address(this), amount);
        _setVesting(account, amount, cliff, duration, startAt);
        return true;
    }

    function userDetails(address account)
        external
        view
        returns (uint256, uint256)
    {
        return (vestedUser[account].duration, vestedUser[account].totalToken);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param account address of the user
     */
    function vestedToken(address account) external view returns (uint256) {
        return _vestedAmount(account);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param account address of user
     */
    function releasableToken(address account) external view returns (uint256) {
        return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }

    /**
     * @dev Internal function to set default vesting parameters
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vestin
     * @param duration In seconds of total vesting duration
     * @param startAt UNIX timestamp in seconds from where vesting will start
     *
     */
    function _setVesting(
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 duration,
        uint256 startAt
    ) internal {
        require(account != address(0), "Address should not be zero address");
        require(startAt >= block.timestamp, "Vesting should start after current block time");
        require(cliff <= duration, "Cliff should be less that duration");
        VestedToken storage vested = vestedUser[account];
        vested.cliff = cliff;
        vested.start = startAt;
        vested.duration = duration;
        vested.totalToken = amount;
        vested.releasedToken = 0;
        vested.revoked = false;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * anyone can release their token
     */
    function releaseMyToken() external returns (bool) {
        releaseToken(msg.sender);
        return true;
    }

    /**
     * @notice Transfers vested tokens to the given account.
     * @param account address of the vested user
     */
    function releaseToken(address account) public {
        require(account != address(0), "Address should not be zero address");
        VestedToken storage vested = vestedUser[account];
        uint256 unreleasedToken = _releasableAmount(account); // total releasable token currently
        require(unreleasedToken > 0, "No unreleased tokens in vesting");
        vested.releasedToken = vested.releasedToken.add(unreleasedToken);
        IERC20(LCX_TOKEN).transfer(account, unreleasedToken);
        emit TokenReleased(account, unreleasedToken);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param account address of user
     */
    function _releasableAmount(address account)
        internal
        view
        returns (uint256)
    {
        return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param account address of the user
     */
    function _vestedAmount(address account) internal view returns (uint256) {
        VestedToken storage vested = vestedUser[account];
        uint256 totalToken = vested.totalToken;
        if (block.timestamp < vested.start.add(vested.cliff)) {
            return 0;
        } else if (
            block.timestamp >= vested.start.add(vested.duration) ||
            vested.revoked
        ) {
            return totalToken;
        } else {
            uint256 numberOfPeriods = (block.timestamp.sub(vested.start)).div(
                vested.cliff
            );
            return
                totalToken.mul(numberOfPeriods.mul(vested.cliff)).div(
                    vested.duration
                );
        }
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param account address in which the vesting is revoked
     */
    function revoke(address account) external onlyOwner returns (bool) {
        VestedToken storage vested = vestedUser[account];
        require(!vested.revoked, "Already revoked");
        uint256 balance = vested.totalToken;
        uint256 vestedAmount = _vestedAmount(account);
        uint256 refund = balance.sub(vestedAmount);
        require(refund > 0, "Refund amount should be more than zero");
        vested.revoked = true;
        vested.totalToken = vestedAmount;
        IERC20(LCX_TOKEN).transfer(owner(), refund);
        emit VestingRevoked(account);
        return true;
    }
}