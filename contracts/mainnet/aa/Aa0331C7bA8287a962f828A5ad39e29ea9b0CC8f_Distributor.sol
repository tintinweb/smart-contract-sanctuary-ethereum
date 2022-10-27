// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

import "./libs/SafeMath.sol";
import "./libs/SafeERC20.sol";
import "./libs/Address.sol";
import "./libs/Policy.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";

contract Distributor is Policy {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ====== VARIABLES ====== */

    address public immutable PSI;
    address public immutable treasury;

    uint public immutable epochLength;
    uint public nextEpochBlock;

    mapping(uint => Adjust) public adjustments;


    /* ====== STRUCTS ====== */

    struct Info {
        uint rate; // in ten-thousandths ( 5000 = 0.5% )
        address recipient;
    }

    Info[] public info;

    struct Adjust {
        bool add;
        uint rate;
        uint target;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(address _treasury, address _psi, uint _epochLength) {
        require(_treasury != address(0));
        treasury = _treasury;
        require(_psi != address(0));
        PSI = _psi;
        epochLength = _epochLength;
        nextEpochBlock = block.number;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external returns (bool) {
        if (nextEpochBlock <= block.number) {
            nextEpochBlock = nextEpochBlock.add(epochLength);
            // set next epoch block

            // distribute rewards to each recipient
            for (uint i = 0; i < info.length; i++) {
                if (info[i].rate > 0) {
                    ITreasury(treasury).mintRewards(// mint and send from treasury
                        info[i].recipient,
                        nextRewardAt(info[i].rate)
                    );
                    adjust(i);
                    // check for adjustment
                }
            }
            return true;
        } else {
            return false;
        }
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    /**
        @notice increment reward rate for collector
     */
    function adjust(uint _index) internal {
        Adjust memory adjustment = adjustments[_index];
        if (adjustment.rate != 0) {
            if (adjustment.add) {// if rate should increase
                info[_index].rate = info[_index].rate.add(adjustment.rate);
                // raise rate
                if (info[_index].rate >= adjustment.target) {// if target met
                    adjustments[_index].rate = 0;
                    // turn off adjustment
                }
            } else {// if rate should decrease
                info[_index].rate = info[_index].rate.sub(adjustment.rate);
                // lower rate
                if (info[_index].rate <= adjustment.target) {// if target met
                    adjustments[_index].rate = 0;
                    // turn off adjustment
                }
            }
        }
    }



    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt(uint _rate) public view returns (uint) {
        return IERC20(PSI).totalSupply().mul(_rate).div(1000000);
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
    function nextRewardFor(address _recipient) public view returns (uint) {
        uint reward;
        for (uint i = 0; i < info.length; i++) {
            if (info[i].recipient == _recipient) {
                reward = nextRewardAt(info[i].rate);
            }
        }
        return reward;
    }



    /* ====== POLICY FUNCTIONS ====== */

    /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
    function addRecipient(address _recipient, uint _rewardRate) external onlyPolicy() {
        require(_recipient != address(0));
        info.push(Info({
        recipient : _recipient,
        rate : _rewardRate
        }));
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
        @param _recipient address
     */
    function removeRecipient(uint _index, address _recipient) external onlyPolicy() {
        require(_recipient == info[_index].recipient);
        info[_index].recipient = address(0);
        info[_index].rate = 0;
    }

    function updateRewardRate(uint _index, uint _rewardRate) external onlyPolicy() {
        info[_index].rate = _rewardRate;
    }

    /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
    function setAdjustment(uint _index, bool _add, uint _rate, uint _target) external onlyPolicy() {
        adjustments[_index] = Adjust({
        add : _add,
        rate : _rate,
        target : _target
        });
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IPolicy.sol";

contract Policy is IPolicy {

    address internal _policy;
    address internal _newPolicy;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _policy = msg.sender;
        emit OwnershipTransferred(address(0), _policy);
    }

    function policy() public view override returns (address) {
        return _policy;
    }

    modifier onlyPolicy() {
        require(_policy == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renouncePolicy() public virtual override onlyPolicy() {
        emit OwnershipTransferred(_policy, address(0));
        _policy = address(0);
    }

    function pushPolicy(address newPolicy_) public virtual override onlyPolicy() {
        require(newPolicy_ != address(0), "Ownable: new owner is the zero address");
        _newPolicy = newPolicy_;
    }

    function pullPolicy() public virtual override {
        require(msg.sender == _newPolicy);
        emit OwnershipTransferred(_policy, _newPolicy);
        _policy = _newPolicy;
    }
}

pragma solidity 0.7.5;

interface ITreasury {

    function deposit(uint _amount, address _token, uint _profit) external returns (uint send_);

    function mintRewards(address _recipient, uint _amount) external;

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

interface IPolicy {

    function policy() external view returns (address);

    function renouncePolicy() external;

    function pushPolicy(address newPolicy_) external;

    function pullPolicy() external;
}