// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";
import "./libs/SafeERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IsPSI.sol";
import "./interfaces/IWarmup.sol";
import "./interfaces/IDistributor.sol";

contract Staking is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable PSI;
    address public immutable sPSI;

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
    }

    Epoch public epoch;

    address public distributor;

    address public locker;
    uint public totalBonus;

    address public warmupContract;
    uint public warmupPeriod;

    constructor (
        address _PSI,
        address _sPSI,
        uint _epochLength
    ) {
        require(_PSI != address(0));
        PSI = _PSI;
        require(_sPSI != address(0));
        sPSI = _sPSI;

        epoch = Epoch({
        length : _epochLength,
        number : 1,
        endBlock : block.number,
        distribute : 0
        });
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }

    mapping(address => Claim) public warmupInfo;

    /**
        @notice stake PSI to enter warmup
        @param _amount uint
        @return bool
     */
    function stake(uint _amount, address _recipient) external returns (bool) {
        rebase();

        IERC20(PSI).safeTransferFrom(msg.sender, address(this), _amount);

        Claim memory info = warmupInfo[_recipient];
        require(!info.lock, "Deposits for account are locked");

        warmupInfo[_recipient] = Claim({
        deposit : info.deposit.add(_amount),
        gons : info.gons.add(IsPSI(sPSI).gonsForBalance(_amount)),
        expiry : epoch.number.add(warmupPeriod),
        lock : false
        });

        IERC20(sPSI).safeTransfer(warmupContract, _amount);
        return true;
    }

    /**
        @notice retrieve sPSI from warmup
        @param _recipient address
     */
    function claim(address _recipient) public {
        Claim memory info = warmupInfo[_recipient];
        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_recipient];
            IWarmup(warmupContract).retrieve(_recipient, IsPSI(sPSI).balanceForGons(info.gons));
        }
    }

    /**
        @notice forfeit sPSI in warmup and retrieve PSI
     */
    function forfeit() external {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        IWarmup(warmupContract).retrieve(address(this), IsPSI(sPSI).balanceForGons(info.gons));
        IERC20(PSI).safeTransfer(msg.sender, info.deposit);
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
        @notice redeem sPSI for PSI
        @param _amount uint
        @param _trigger bool
     */
    function unstake(uint _amount, bool _trigger) external {
        if (_trigger) {
            rebase();
        }
        IERC20(sPSI).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(PSI).safeTransfer(msg.sender, _amount);
    }

    /**
        @notice returns the sPSI index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint) {
        return IsPSI(sPSI).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.endBlock <= block.number) {
            IsPSI(sPSI).rebase(epoch.distribute, epoch.number);

            epoch.endBlock = epoch.endBlock.add(epoch.length);
            epoch.number++;

            if (distributor != address(0)) {
                IDistributor(distributor).distribute();
            }

            uint balance = contractBalance();
            uint staked = IsPSI(sPSI).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked);
            }
        }
    }

    /**
        @notice returns contract PSI holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns (uint) {
        return IERC20(PSI).balanceOf(address(this)).add(totalBonus);
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(uint _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.add(_amount);
        IERC20(sPSI).safeTransfer(locker, _amount);
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus(uint _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.sub(_amount);
        IERC20(sPSI).safeTransferFrom(locker, address(this), _amount);
    }

    enum CONTRACTS {DISTRIBUTOR, WARMUP, LOCKER}

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
    function setContract(CONTRACTS _contract, address _address) external onlyManager() {
        if (_contract == CONTRACTS.DISTRIBUTOR) {// 0
            distributor = _address;
        } else if (_contract == CONTRACTS.WARMUP) {// 1
            require(warmupContract == address(0), "Warmup cannot be set more than once");
            warmupContract = _address;
        } else if (_contract == CONTRACTS.LOCKER) {// 2
            require(locker == address(0), "Locker cannot be set more than once");
            locker = _address;
        }
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup(uint _warmupPeriod) external onlyManager() {
        warmupPeriod = _warmupPeriod;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IsPSI {
    function rebase(uint256 psiProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance(uint amount) external view returns (uint);

    function balanceForGons(uint gons) external view returns (uint);

    function index() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IStaking {

    function stake(uint _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IDistributor {
    function distribute() external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IWarmup {
    function retrieve(address staker_, uint amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {

    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}