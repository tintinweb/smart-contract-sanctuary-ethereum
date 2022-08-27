// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from './NonReentrant.sol';

import { SafeMath } from './libraries/SafeMath.sol';

import { IGMITokenGovernedProxy } from './interfaces/IGMITokenGovernedProxy.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { IUpgradeProposal } from './interfaces/IUpgradeProposal.sol';
import { ISporkRegistry } from './interfaces/ISporkRegistry.sol';
import { IGovernedERC20 } from './interfaces/IGovernedERC20.sol';
import { IOwnedERC20 } from './interfaces/IOwnedERC20.sol';
import { IGMIToken } from './interfaces/IGMIToken.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract GMITokenGovernedProxy is IGMITokenGovernedProxy, IGovernedProxy, NonReentrant {
uint test =0;
    using SafeMath for uint256;

    IGovernedContract public impl;
    IGovernedContract public implementation; // only used for block explorers to detect contract as a proxy

    IGovernedProxy public spork_proxy;

    mapping(address => IGovernedContract) public upgrade_proposals;

    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use impl directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(msg.sender == address(impl), 'Only calls from impl are allowed!');
        _;
    }

    constructor(IGovernedContract _impl) public {
        impl = _impl;
        implementation = _impl; // to allow block explorers to find the impl contract
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy(_sporkProxy);
    }

    function emitAirdropRewardsClaimed(
        address recipient,
        uint256 claimAmount,
        bytes calldata airdropServiceSignature
    ) external onlyImpl {
        emit AirdropRewardsClaimed(recipient, claimAmount, airdropServiceSignature);
    }

    function emitListingRewardsClaimed(
        address recipient,
        uint256 claimAmount,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata listingServiceSignature
    ) external onlyImpl {
        emit ListingRewardsClaimed(
            recipient,
            claimAmount,
            lastClaimNonce,
            claimNonce,
            listingServiceSignature
        );
    }

    // ERC20 standard functions
    //
    function name() external view returns (string memory _name) {
        _name = IGMIToken(address(uint160(address(impl)))).name();
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = IGMIToken(address(uint160(address(impl)))).symbol();
    }

    function decimals() external view returns (uint256 _decimals) {
        _decimals = IGMIToken(address(uint160(address(impl)))).decimals();
    }

    function balanceOf(address account) external view returns (uint256 _balance) {
        _balance = IGovernedERC20(address(uint160(address(impl)))).balanceOf(account);
    }

    function allowance(address owner, address spender) external view returns (uint256 _allowance) {
        _allowance = IGovernedERC20(address(uint160(address(impl)))).allowance(owner, spender);
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = IGovernedERC20(address(uint160(address(impl)))).totalSupply();
    }

    function approve(address spender, uint256 value) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).approve(
            msg.sender,
            spender,
            value
        );
        emit Approval(msg.sender, spender, value);
    }

    function transfer(address to, uint256 value) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).transferFrom(
            msg.sender,
            from,
            to,
            value
        );
        emit Transfer(from, to, value);
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            from,
            msg.sender
        );
        emit Approval(from, msg.sender, newApproveAmount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).increaseAllowance(
            msg.sender,
            spender,
            addedValue
        );
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            msg.sender,
            spender
        );
        emit Approval(msg.sender, spender, newApproveAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool result)
    {
        result = IGovernedERC20(address(uint160(address(impl)))).decreaseAllowance(
            msg.sender,
            spender,
            subtractedValue
        );
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            msg.sender,
            spender
        );
        emit Approval(msg.sender, spender, newApproveAmount);
    }

    // OwnedERC20 functions
    //
    function mint(address recipient, uint256 amount) external {
        IOwnedERC20(address(uint160(address(impl)))).mint(recipient, amount);
        emit Transfer(address(0), recipient, amount);
    }

    function burn(address recipient, uint256 amount) external {
        IOwnedERC20(address(uint160(address(impl)))).burn(recipient, amount);
        emit Transfer(recipient, address(0), amount);
    }

    // Governance functions
    //
    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImpl != impl, 'Already active!');
        require(_newImpl.proxy() == address(this), 'Wrong proxy!');

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImpl,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImpl;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImpl, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(new_impl != impl, 'Already active!'); // in case it changes in the flight
        require(address(new_impl) != address(0), 'Not registered!');
        require(_proposal.isAccepted(), 'Not accepted!');

        IGovernedContract old_impl = impl;

        new_impl.migrate(old_impl);
        impl = new_impl;
        implementation = new_impl;
        old_impl.destroy(new_impl);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(new_impl, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl)
    {
        new_impl = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(address(new_impl) != address(0), 'Not registered!');
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function transferFrom(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function increaseAllowance(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function decreaseAllowance(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function transfer(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function approve(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external pure {
        revert('Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'GMITokenGovernedProxy: delegatecall cannot be used'
            );
        }

        IGovernedContract impl_m = impl;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), impl_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _impl,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256 callGas, uint256 xferGas);
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IOwnedERC20 {
    function owner() external view returns (address _owner);

    function setOwner(address _owner) external;

    function mint(address recipient, uint256 amount) external;

    function burn(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed impl, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed impl, IUpgradeProposal proposal);

    function impl() external view returns (IGovernedContract);

    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IGovernedERC20 {
    function erc20Storage() external view returns (address _erc20Storage);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;

    // function () external payable; // This line (from original Energi IGovernedContract) is commented because it
    // makes truffle migrations fail
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IGMITokenGovernedProxy {
    event AirdropRewardsClaimed(
        address indexed recipient,
        uint256 claimAmount,
        bytes airdropServiceSignature
    );

    event ListingRewardsClaimed(
        address indexed recipient,
        uint256 claimAmount,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes listingServiceSignature
    );

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setSporkProxy(address payable _sporkProxy) external;

    function emitAirdropRewardsClaimed(
        address recipient,
        uint256 claimAmount,
        bytes calldata airdropServiceSignature
    ) external;

    function emitListingRewardsClaimed(
        address recipient,
        uint256 claimAmount,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata listingServiceSignature
    ) external;

    // ERC20 standard interface
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint256 _decimals);

    function balanceOf(address account) external view returns (uint256 _balance);

    function allowance(address owner, address spender) external view returns (uint256 _allowance);

    function totalSupply() external view returns (uint256 _totalSupply);

    function approve(address spender, uint256 value) external returns (bool result);

    function transfer(address to, uint256 value) external returns (bool result);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool result);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool result);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool result);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IGMIToken {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint8 _decimals);

    function getGMIFarmingProxy() external view returns (address _gmiFarmingProxy);

    function getGMIFarmingImpl() external view returns (address _gmiFarmingImpl);

    function getAirdropService() external view returns (address _airdropService);

    function getListingService() external view returns (address _listingService);

    function getLastClaimNonce(address _user) external view returns (uint256 _lastClaimNonce);

    function hasSubmittedAirdropClaim(address _recipient)
        external
        view
        returns (bool _hasSubmittedAirdropClaim);

    function setSporkProxy(address payable _sporkProxy) external;

    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setDecimals(uint8 _decimals) external;

    function setGMIFarmingProxy(address _gmiFarmingProxy) external;

    function setAirdropService(address _airdropService) external;

    function setListingService(address _listingService) external;

    function mint(address recipient, uint256 amount) external;

    function burn(address recipient, uint256 amount) external;

    function claimAirdropRewards(uint256 amount, bytes calldata airdropServiceSignature) external;

    function claimListingRewards(
        uint256 claimAmount,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata listingServiceSignature
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}