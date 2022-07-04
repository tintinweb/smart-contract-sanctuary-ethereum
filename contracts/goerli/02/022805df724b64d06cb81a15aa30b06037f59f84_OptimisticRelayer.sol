// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ICollybus} from "fiat/interfaces/ICollybus.sol";
import {Guarded} from "fiat/utils/Guarded.sol";
import {IValidator} from "./interfaces/IValidator.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract OptimisticRelayer is Guarded {
    error OptimisticRelayer__registerRate_rateAlreadyRegistered(
        bytes32 encodedId_
    );
    error OptimisticRelayer__registerRate_rateNotFound(bytes32 encodedId_);

    error OptimisticRelayer__propose_invalidBlockNumber(bytes32 encodedId_);
    error OptimisticRelayer__propose_inDispute(bytes32 encodedId_);
    error OptimisticRelayer__propose_rateNotRegistered(bytes32 encodedId_);
    error OptimisticRelayer__proposal_rateNotRegistered(bytes32 encodedId_);

    error OptimisticRelayer__shift_invalidPreviousProposal(bytes32 encodedId_);
    error OptimisticRelayer__shift_invalidValue(bytes32 encodedId_);
    error OptimisticRelayer__shift_cantExecute(bytes32 encodedId_);

    error OptimisticRelayer__dispute_rateNotRegistered(bytes32 encodedId_);
    error OptimisticRelayer__dispute_notInDisputeWindow(bytes32 encodedId_);
    error OptimisticRelayer__dispute_valueAlreadyDisputed(bytes32 encodedId_);

    error OptimisticRelayer__setParam_unrecognizedParam(
        bytes32 encodedId_,
        bytes32 param_
    );

    event SetParam(bytes32 encodedId_, bytes32 param_, bytes32 value_);
    event ProposeValue(address proposed_, bytes32 encodedId_, uint256 value_);
    event DisputeValue(
        address disputer_,
        bytes32 encodedId_,
        uint256 verifiedValue_,
        uint256 proposedValue_,
        bool disputeIsValid_
    );

    enum Type {
        DiscountRate,
        SpotPrice,
        COUNT
    }

    enum ProposalState{
        Inactive,
        Active,
        Disputed
    }

    struct Rate {
        uint160 validator;
        uint64 deviation;
        uint32 rateType;
    }

    mapping(bytes32 => ProposalState) public proposals;
    mapping(bytes32 => Rate) public rates;

    address public immutable collybus;

    constructor(address collybus_) {
        collybus = collybus_;
    }

    /// @notice Sets a OptimisticRelayer parameter
    /// Supported parameters are:
    /// - validator
    /// - deviation
    /// @param param_ The identifier of the parameter that should be updated
    /// @param value_ The new value
    /// @dev Reverts if parameter is not found
    function setParam(
        bytes32 encodedId_,
        bytes32 param_,
        bytes32 value_
    ) public checkCaller {
        if (param_ == "deviation") {
            rates[encodedId_].deviation = uint64(uint256(value_));
        } else if (param_ == "validator") {
            rates[encodedId_].validator = uint160(uint256(value_));
        } else
            revert OptimisticRelayer__setParam_unrecognizedParam(
                encodedId_,
                param_
            );

        emit SetParam(encodedId_, param_, value_);
    }

    function register(
        bytes32 encodedId_,
        uint256 rateType_,
        address validator_,
        uint256 deviation_,
        uint256 initValue_,
        bytes32 initAuxData_
    ) external checkCaller {
        if (rates[encodedId_].validator != 0) {
            revert OptimisticRelayer__registerRate_rateAlreadyRegistered(
                encodedId_
            );
        }

        rates[encodedId_].validator = uint160(validator_);
        rates[encodedId_].deviation = uint64(deviation_);
        rates[encodedId_].rateType = uint32(rateType_);

        bytes32 defaultHash = bytes32(uint256(1));//keccak256(abi.encodePacked(keccak256(abi.encodePacked(initValue_,initAuxData_)),encodedId_));
        proposals[defaultHash] = ProposalState.Active;
    }

    function unregister(bytes32 encodedId_)
        external
        checkCaller
    {
        if (rates[encodedId_].validator == 0) {
            revert OptimisticRelayer__registerRate_rateNotFound(encodedId_);
        }
        rates[encodedId_].validator = 0;
    }

    function generateHash(bytes32 encodedId_, uint256 value_, bytes32 auxData_) public view returns (bytes32) {
        unchecked {
            return keccak256(abi.encodePacked(keccak256(abi.encodePacked(value_,auxData_)),encodedId_));    
        }
    }

    function shift(bytes32 encodedId_, uint256 prevValue_, bytes32 prevAuxData_, uint256 newValue_, bytes32 newAuxData_) external checkCaller returns (bool collybusWasUpdated){
        bytes32 prevPropHash = bytes32(uint256(1));//generateHash(encodedId_,prevValue_, prevAuxData_);
        ProposalState state = proposals[prevPropHash];
        if(state == ProposalState.Inactive){
            //revert OptimisticRelayer__shift_invalidPreviousProposal(encodedId_);
        }
        
        IValidator validator = IValidator(address(rates[encodedId_].validator));
        if(validator.canExecute(prevValue_, prevAuxData_)){
        } else {
            revert OptimisticRelayer__shift_cantExecute(encodedId_);
        }

        if(state == ProposalState.Active){
            collybusWasUpdated = execute(encodedId_,prevValue_);
        } else {
            collybusWasUpdated = false;
        }

        proposals[prevPropHash] = ProposalState.Inactive;
        if(!validator.canPropose(newValue_, newAuxData_)){
            revert OptimisticRelayer__shift_invalidValue(encodedId_);
        }

        unchecked {
            bytes32 propHash = bytes32(uint256(2));//generateHash(encodedId_,newValue_, newAuxData_);
            proposals[propHash] = ProposalState.Active;    
        }
    }

    function execute(bytes32 encodedId_, uint256 value_) internal returns(bool) {
        return updateCollybus(
            encodedId_,
            rates[encodedId_].rateType,
            rates[encodedId_].deviation,
            value_
        );
    }

    // function propose(
    //     bytes32 encodedId_,
    //     uint256 value_,
    //     uint256 blockNumber_
    // )
    //     external
    //     payable
    //     override(IOptimisticRelayer)
    //     checkCaller
    //     returns (bool collybusWasUpdated)
    // {
    //     if (
    //         blockNumber_ > block.number ||
    //         block.number - blockNumber_ >= proposeWindow
    //     ) {
    //         revert OptimisticRelayer__propose_invalidBlockNumber(encodedId_);
    //     }

    //     if (rates[encodedId_].validator == address(0)) {
    //         revert OptimisticRelayer__propose_rateNotRegistered(encodedId_);
    //     }

    //     Proposal storage proposal = proposals[encodedId_];
    //     if (proposal.blockNumber + disputeBlockWindow >= block.number) {
    //         revert OptimisticRelayer__propose_inDispute(encodedId_);
    //     }

    //     if (!proposal.disputed) {
    //         collybusWasUpdated = updateCollybus(
    //             encodedId_,
    //             rates[encodedId_].rateType,
    //             rates[encodedId_].deviation,
    //             proposal.proposedValue
    //         );
    //     } else {
    //         collybusWasUpdated = false;
    //     }

    //     // Update the new Proposal
    //     proposal.proposer = msg.sender;
    //     proposal.proposedValue = value_;
    //     proposal.blockNumber = blockNumber_;
    //     proposal.disputed = false;

    //     emit ProposeValue(msg.sender, encodedId_, value_);
    // }

    // function dispute(
    //     bytes32 encodedId_,
    //     bytes memory blockHeaderRlpBytes_,
    //     bytes memory proofRlpBytes_
    // ) external override(IOptimisticRelayer) returns (bool) {
    //     if (rates[encodedId_].validator == address(0)) {
    //         revert OptimisticRelayer__dispute_rateNotRegistered(encodedId_);
    //     }

    //     if (
    //         block.number >
    //         proposals[encodedId_].blockNumber + disputeBlockWindow
    //     ) {
    //         revert OptimisticRelayer__dispute_notInDisputeWindow(encodedId_);
    //     }

    //     if (proposals[encodedId_].disputed) {
    //         revert OptimisticRelayer__dispute_valueAlreadyDisputed(encodedId_);
    //     }

    //     proposals[encodedId_].disputed = true;
    //     uint256 proposedValue = proposals[encodedId_].proposedValue;
    //     IValidator validator = IValidator(rates[encodedId_].validator);
    //     (bool isValid, uint256 verifiedValue) = validator.validate(
    //         proposedValue,
    //         proposals[encodedId_].blockNumber,
    //         blockHeaderRlpBytes_,
    //         proofRlpBytes_
    //     );

    //     if (!isValid) {
    //         proposals[encodedId_].proposedValue = verifiedValue;
    //         // send collateral to disputer
    //     }

    //     updateCollybus(
    //         encodedId_,
    //         rates[encodedId_].rateType,
    //         rates[encodedId_].deviation,
    //         verifiedValue
    //     );
    //     emit DisputeValue(
    //         msg.sender,
    //         encodedId_,
    //         verifiedValue,
    //         proposedValue,
    //         !isValid
    //     );

    //     return !isValid;
    // }

    function getValidator(bytes32 encodedId_)
        external
        view
        returns (address)
    {
        return address(rates[encodedId_].validator);
    }

    function value(bytes32 encodedId_)
        external
        pure
        returns (
            uint256 value_
        )
    {
        return 0;
    }

    function updateCollybus(
        bytes32 encodedId_,
        uint256 rateType_,
        uint256 deviation_,
        uint256 value_
    ) internal returns (bool) {
        // Do not update Collybus if the current value is 0
        // This will happen on the first proposal
        if (value_ == 0) {
            return false;
        }

        if (rateType_ == uint256(Type.DiscountRate)) {
            return updateDiscountRate(uint256(encodedId_), deviation_, value_);
        } else if (rateType_ == uint256(Type.SpotPrice)) {
            return
                updateSpot(
                    address(uint160(uint256(encodedId_))),
                    deviation_,
                    value_
                );
        }

        return false;
    }

    function updateSpot(
        address tokenAddress,
        uint256 deviation_,
        uint256 nextValue_
    ) internal returns (bool) {
        // read from collybus
        uint256 currentValue = ICollybus(collybus).spots(tokenAddress);

        if (!checkDeviation(currentValue, nextValue_, deviation_)) {
            return false;
        }

        ICollybus(collybus).updateSpot(tokenAddress, nextValue_);
        return true;
    }

    function updateDiscountRate(
        uint256 rateId,
        uint256 deviation_,
        uint256 nextValue_
    ) internal returns (bool) {
        // read from collybus
        uint256 currentValue = ICollybus(collybus).rates(rateId);
        if (!checkDeviation(currentValue, nextValue_, deviation_)) {
            return false;
        }

        ICollybus(collybus).updateDiscountRate(rateId, nextValue_);
        return true;
    }

    /// @notice Returns true if the percentage difference between the two values is larger than the percentage
    /// @param baseValue_ The value that the percentage is based on
    /// @param newValue_ The new value
    /// @param percentage_ The percentage threshold value (100% = 100_00, 50% = 50_00, etc)
    function checkDeviation(
        uint256 baseValue_,
        uint256 newValue_,
        uint256 percentage_
    ) public pure returns (bool) {
        uint256 deviation = (baseValue_ * percentage_) / 100_00;

        if (
            baseValue_ + deviation <= newValue_ ||
            baseValue_ - deviation >= newValue_
        ) return true;

        return false;
    }

    function getCollybusValue(bytes32 encodedId_, uint256 rateType_)
        private
        view
        returns (uint256)
    {
        if (rateType_ == uint256(Type.DiscountRate)) {
            return ICollybus(collybus).rates(uint256(encodedId_));
        } else if (rateType_ == uint256(Type.SpotPrice)) {
            return
                ICollybus(collybus).spots(
                    address(uint160(uint256(encodedId_)))
                );
        }

        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";

interface IPriceFeed {
    function peek() external returns (bytes32, bool);

    function read() external view returns (bytes32);
}

interface ICollybus {
    function vaults(address) external view returns (uint128, uint128);

    function spots(address) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function rateIds(address, uint256) external view returns (uint256);

    function redemptionPrice() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external;

    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external;

    function updateDiscountRate(uint256 rateId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;

    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view returns (uint256 price);

    function lock() external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import {IGuarded} from "../interfaces/IGuarded.sol";

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IValidator {
    function canPropose(uint256 value_, bytes32 auxiliaryData_) external view returns (bool);
    function canExecute(uint256 value_, bytes32 auxiliaryData_) external view returns (bool);

    function validate(
        uint256 value_,
        uint256 blockNumber_,
        bytes memory blockHeaderRlpBytes_,
        bytes memory proofRlpBytes_
    ) external returns (bool, uint256);

    function value() external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function lock() external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}