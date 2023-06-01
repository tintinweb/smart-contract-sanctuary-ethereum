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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/IEmissionsController.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISchwapMarket.sol";
import "./interfaces/IveSCH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmissionsController is IEmissionsController, Ownable {
    ISchwapMarket public mkt;
    IveSCH public vesch;
    IERC20 public sch;

    mapping(address => mapping(address => mapping(uint => bool))) public _claims;
    mapping(uint => uint) public _votes;
    mapping(address => mapping(uint => uint)) public _pairVotes;
    mapping(address => mapping(uint => bool)) public _voted;

    mapping(address => uint) _pairClaims;
    mapping(address => uint) _userClaims;
    mapping(address => mapping(uint => uint)) _pairEpochClaims;
    mapping(address => mapping(uint => uint)) _userEpochClaims;

    event EmissionsClaimed(address indexed _pair, uint indexed _epoch, uint _emissions, address indexed _user, uint _timestamp);

    constructor (address _mkt, address _vesch, address _sch) {
        mkt = ISchwapMarket(_mkt);
        vesch = IveSCH(_vesch);
        sch = IERC20(_sch);
    }

    function getTotalEmissions()
        public
        pure
        returns (uint)
    {
        return 200_000 * (10 ** 18);
    }

    function getClaimedEmissions()
        public
        view
        returns (uint)
    {
        return getTotalEmissions() - sch.balanceOf(address(this));
    }

    function getPairClaims(
        address _pair
    )
        public
        view
        returns (uint)
    {
        return _pairClaims[_pair];
    }

    function getUserClaims(
        address _user
    )
        public
        view
        returns (uint)
    {
        return _userClaims[_user];
    }

    function getPairEpochClaims(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _pairEpochClaims[_pair][_epoch];
    }

    function getUserEpochClaims(
        address _user,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _userEpochClaims[_user][_epoch];
    }

    function getPairEmissions(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        uint _epochVotes = _votes[_epoch];
        if (_epochVotes > 0) {
            return mkt.getEmissions(_epoch) * _pairVotes[_pair][_epoch] / _epochVotes;
        } else {
            return 0;
        }
    }

    function getPairVotes(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _pairVotes[_pair][_epoch];
    }

    function getTotalVotes(
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _votes[_epoch];
    }

    // ---- Public entrypoints ---- //

    function vote(
        address _pair
    )
        public
    {
        uint _votingPower = vesch.getVotingPower(msg.sender);
        require(_votingPower > 0, "No voting power");
        uint _nextEpoch = mkt.getCurrentEpoch() + 1;
        require(_nextEpoch > 0 && _nextEpoch < 289, "Invalid epoch");
        require(!_voted[msg.sender][_nextEpoch], "Already voted");
        _voted[msg.sender][_nextEpoch] = true;
        _votes[_nextEpoch] += _votingPower;
        _pairVotes[_pair][_nextEpoch] += _votingPower;
    }

    function claim(
        address _pair,
        uint _epoch
    )
        public
    {
        require(mkt.getCurrentEpoch() > _epoch, "Invalid epoch");
        uint _userVolume = mkt.getUserVolume(_pair, msg.sender, _epoch);
        require(_userVolume > 0, "No emissions to claim");
        uint _pairEmissions = getPairEmissions(_pair, _epoch);
        require(_pairEmissions > 0, "No emissions for this pair");
        require(!_claims[_pair][msg.sender][_epoch], "Already claimed");
        _claims[_pair][msg.sender][_epoch] = true;
        uint _emissions = _pairEmissions * _userVolume / mkt.getPairVolume(_pair, _epoch);
        _pairClaims[_pair] += _emissions;
        _userClaims[msg.sender] += _emissions;
        _pairEpochClaims[_pair][_epoch] += _emissions;
        _userEpochClaims[msg.sender][_epoch] += _emissions;
        sch.transfer(msg.sender, _emissions);
        emit EmissionsClaimed(_pair, _epoch, _emissions, msg.sender, block.timestamp);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IEmissionsController {
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface ISchwapMarket {
    function getCurrentEpoch() external view returns (uint);
    function getEmissions(uint _epoch) external view returns (uint);
    function getPairVolume(address _pair, uint _epoch) external view returns (uint);
    function getUserVolume(address _pair, address _user, uint _epoch) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IveSCH {
    function depositFees(uint256 _amount, uint256 _period) external payable;
    function getVotingPower(address _voter) external view returns (uint256);
}