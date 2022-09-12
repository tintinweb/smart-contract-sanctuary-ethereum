// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YearVault is IVault, Ownable {
    struct Share {
        uint256 amount;
        uint256 uncounted;
        uint256 counted;
    }

    address[] voters;
    mapping (address => uint256) voterIds;
    mapping (address => uint256) voterClaims;

    mapping (address => uint256) public totalRewardsToVoter;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public constant decimals = 10 ** 36;

    address public vehrd;
    IERC20 public immutable USDH;

    bool public canSetVEHRD = true;

    constructor () {
        vehrd = msg.sender;
        USDH = IERC20(0xe350E32ca91B04F2D7307185BB352F0b7E7BcE35);
    }

    function _getCumulativeUSDH(uint256 _share) private view returns (uint256) {
        return _share * rewardsPerShare / decimals;
    }

    function setBalance(address _voter, uint256 _amount) external override {
        require(msg.sender == vehrd);
        if (_amount > 0 && shares[_voter].amount == 0) {
            voterIds[_voter] = voters.length;
            voters.push(_voter);
        } else if (_amount == 0 && shares[_voter].amount > 0) {
            voters[voterIds[_voter]] = voters[voters.length - 1];
            voterIds[voters[voters.length - 1]] = voterIds[_voter];
            voters.pop();
        }
        totalShares = totalShares - shares[_voter].amount + _amount;
        shares[_voter].amount = _amount;
        shares[_voter].uncounted = _getCumulativeUSDH(shares[_voter].amount);
    }

    function claimUSDH(address _voter) external override returns (uint256) {
        require(msg.sender == vehrd);
        if (shares[_voter].amount == 0) return 0;
        uint256 _amount = getUnclaimedUSDH(_voter);
        if (_amount > 0) {
            voterClaims[_voter] = block.timestamp;
            shares[_voter].counted = shares[_voter].counted + _amount;
            shares[_voter].uncounted = _getCumulativeUSDH(shares[_voter].amount);
            USDH.transfer(vehrd, _amount);
            totalDistributed = totalDistributed + _amount;
            totalRewardsToVoter[_voter] = totalRewardsToVoter[_voter] + _amount;
            return _amount;
        } else {
            return 0;
        }
    }

    function deposit(uint256 _amount) external override {
        require(msg.sender == vehrd);
        require(USDH.balanceOf(msg.sender) >= _amount, "Insufficient Balance");
        require(USDH.allowance(msg.sender, address(this)) >= _amount, "Insufficient Allowance");
        uint256 balance = USDH.balanceOf(address(this));
        USDH.transferFrom(msg.sender, address(this), _amount);
        require(USDH.balanceOf(address(this)) == balance + _amount, "Transfer Failed");
        totalRewards = totalRewards + _amount;
        rewardsPerShare = rewardsPerShare + (decimals * _amount / totalShares);
    }

    function getUnclaimedUSDH(address _voter) public view returns (uint256) {
        if (shares[_voter].amount == 0) return 0;
        uint256 _voterRewards = _getCumulativeUSDH(shares[_voter].amount);
        uint256 _voterUncounted = shares[_voter].uncounted;
        if (_voterRewards <= _voterUncounted) return 0;
        return _voterRewards - _voterUncounted;
    }

    function getClaimedRewardsTotal() external view returns (uint256) {
        return totalDistributed;
    }

    function getClaimedRewards(address _voter) external view returns (uint256) {
        return totalRewardsToVoter[_voter];
    }

    function getLastClaim(address _voter) external view returns (uint256) {
        return voterClaims[_voter];
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return shares[_voter].amount;
    }

    function setVEHRD(address _vehrd, bool _canSetVEHRD) external onlyOwner {
        require(canSetVEHRD);
        vehrd = _vehrd;
        canSetVEHRD = _canSetVEHRD;
    }

    function rescue(address token) external onlyOwner {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(token != address(USDH));
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IVault {
    function setBalance(address _voter, uint256 _amount) external;
    function deposit(uint256 _amount) external;
    function claimUSDH(address _voter) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}