// SPDX-License-Identifier: MIT
/**
 *  @title NerwoEscrow
 *  @author: [@sherpya]
 *
 *  @notice This contract implements an escrow system with dispute resolution, allowing secure transactions
 * between a sender and a receiver. The contract holds funds on behalf of the sender until the transaction
 * is completed or a dispute arises. If a dispute occurs, an external arbitrator determines the outcome.
 *
 * The main features of the contract are:
 * 1. Create transactions: The sender initializes a transaction by providing details such as the receiver's
 *    address, the transaction amount, and any associated fees.
 * 2. Make payments: The sender can pay the receiver if the goods or services are provided as expected.
 * 3. Reimbursements: The receiver can reimburse the sender if the goods or services cannot be fully provided.
 * 4. Execute transactions: If the timeout has passed, the receiver can execute the transaction and receive
 *    the transaction amount.
 * 5. Timeouts: Both the sender and receiver can trigger a timeout if the counterparty fails to pay the arbitration fee.
 * 6. Raise disputes and handle arbitration fees: Both parties can raise disputes and pay arbitration fees. The
 *    contract ensures that both parties pay the fees before raising a dispute.
 * 7. Submit evidence: Both parties can submit evidence to support their case during a dispute.
 * 8. Arbitrator ruling: The external arbitrator can provide a ruling to resolve the dispute. The ruling is
 *    executed by the contract, which redistributes the funds accordingly.
 */

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IArbitrator} from "@kleros/erc-792/contracts/IArbitrator.sol";
import {IArbitrable} from "@kleros/erc-792/contracts/IArbitrable.sol";

import {NerwoArbitrable} from "./NerwoArbitrable.sol";

contract NerwoEscrow is Ownable, Initializable, NerwoArbitrable, ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IArbitrable).interfaceId || super.supportsInterface(interfaceId);
    }

    /** @dev contructor
     *  @notice set ownership before calling initialize to avoid front running in deployment
     *  @notice since we are using hardhat-deploy deterministic deployment the sender
     *  @notice is 0x4e59b44847b379578588920ca78fbf26c0b4956c
     */
    constructor() {
        /* solhint-disable avoid-tx-origin */
        _transferOwnership(tx.origin);
    }

    /** @dev initialize (deferred constructor)
     *  @param _owner The initial owner
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     *  @param _feeRecipient Address which receives a share of receiver payment.
     *  @param _feeRecipientBasisPoint The share of fee to be received by the feeRecipient,
     *                                 down to 2 decimal places as 550 = 5.5%
     *  @param _tokensWhitelist List of whitelisted ERC20 tokens
     *  @param _winnerStakeMultiplier The new winner stake multiplier value respect to DENOMINATOR.
     *  @param _loserStakeMultiplier The new loser stake multiplier value respect to DENOMINATOR.
     *  @param _loserAppealPeriodMultiplier The new loser appeal period multiplier respect to DENOMINATOR.
     *                                      Having a value greater than DENOMINATOR has no effect since arbitrator limits appeal period.
     */
    function initialize(
        address _owner,
        address _arbitrator,
        bytes calldata _arbitratorExtraData,
        uint256 _feeTimeout,
        address _feeRecipient,
        uint256 _feeRecipientBasisPoint,
        IERC20[] calldata _tokensWhitelist,
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        uint256 _loserAppealPeriodMultiplier
    ) external onlyOwner initializer {
        _transferOwnership(_owner);
        _setArbitrator(_arbitrator, _arbitratorExtraData, _feeTimeout);
        _setFeeRecipientAndBasisPoint(_feeRecipient, _feeRecipientBasisPoint);
        _setTokensWhitelist(_tokensWhitelist);
        _setMultipliers(_winnerStakeMultiplier, _loserStakeMultiplier, _loserAppealPeriodMultiplier);
    }

    // **************************** //
    // *        Setters           * //
    // **************************** //

    /**
     *  @dev modifies Arbitrator - Internal function without access restriction
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     */
    function _setArbitrator(address _arbitrator, bytes calldata _arbitratorExtraData, uint256 _feeTimeout) internal {
        arbitratorData.arbitrator = IArbitrator(_arbitrator);
        arbitratorExtraData = _arbitratorExtraData;
        arbitratorData.feeTimeout = uint32(_feeTimeout);
    }

    /**
     *  @dev modifies Arbitrator - External function onlyOwner
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     */
    function setArbitrator(
        address _arbitrator,
        bytes calldata _arbitratorExtraData,
        uint256 _feeTimeout
    ) external onlyOwner {
        _setArbitrator(_arbitrator, _arbitratorExtraData, _feeTimeout);
    }

    /**
     * @dev set platform metaEvedence ipfs uri
     * @param _metaevidenceURI The uri pointing to metaEvidence.json
     */
    function setMetaEvidenceURI(string calldata _metaevidenceURI) external onlyOwner {
        _setMetaEvidenceURI(_metaevidenceURI);
    }

    function _setMetaEvidenceURI(string calldata _metaevidenceURI) internal {
        metaevidenceURI = _metaevidenceURI;
    }

    /**
     *  @dev modifies fee recipient and basis point - Internal function without access restriction
     *  @param _feeRecipient Address which receives a share of receiver payment.
     *  @param _feeRecipientBasisPoint The share of fee to be received by the feeRecipient,
     *         down to 2 decimal places as 550 = 5.5%
     */
    function _setFeeRecipientAndBasisPoint(address _feeRecipient, uint256 _feeRecipientBasisPoint) internal {
        uint16 feeRecipientBasisPoint = uint16(_feeRecipientBasisPoint);
        if (feeRecipientBasisPoint > MULTIPLIER_DIVISOR) {
            revert InvalidFeeBasisPoint();
        }

        feeRecipientData.feeRecipient = payable(_feeRecipient);
        feeRecipientData.feeRecipientBasisPoint = feeRecipientBasisPoint;
    }

    /**
     *  @dev modifies fee recipient and basis point - External function onlyOwner
     *  @param _feeRecipient Address which receives a share of receiver payment.
     *  @param _feeRecipientBasisPoint The share of fee to be received by the feeRecipient,
     *         down to 2 decimal places as 550 = 5.5%
     */
    function setFeeRecipientAndBasisPoint(address _feeRecipient, uint256 _feeRecipientBasisPoint) external onlyOwner {
        _setFeeRecipientAndBasisPoint(_feeRecipient, _feeRecipientBasisPoint);
    }

    function setTokensWhitelist(IERC20[] calldata _tokensWhitelist) external onlyOwner {
        _setTokensWhitelist(_tokensWhitelist);
    }

    /**
     * @dev Sets the whitelist of ERC20 tokens
     * @param _tokensWhitelist An array of ERC20 tokens
     */
    function _setTokensWhitelist(IERC20[] calldata _tokensWhitelist) internal {
        delete tokensWhitelist;
        for (uint i = 0; i < _tokensWhitelist.length; i++) {
            tokensWhitelist.push(_tokensWhitelist[i]);
        }
    }

    /** @dev Change Fee Recipient.
     *  @param _newFeeRecipient Address of the new Fee Recipient.
     */
    function setFeeRecipient(address _newFeeRecipient) external {
        if (_msgSender() != feeRecipientData.feeRecipient) {
            revert InvalidCaller(feeRecipientData.feeRecipient);
        }

        if (_newFeeRecipient == address(0)) {
            revert NullAddress();
        }

        feeRecipientData.feeRecipient = _newFeeRecipient;
        emit FeeRecipientChanged(_msgSender(), _newFeeRecipient);
    }

    /** @dev Changes the proportion of appeal fees that must be paid by winner and loser and changes the appeal period portion for losers.
     *  @param _winnerStakeMultiplier The new winner stake multiplier value respect to DENOMINATOR.
     *  @param _loserStakeMultiplier The new loser stake multiplier value respect to DENOMINATOR.
     *  @param _loserAppealPeriodMultiplier The new loser appeal period multiplier respect to DENOMINATOR. Having a value greater than DENOMINATOR has no effect since arbitrator limits appeal period.
     */
    function setMultipliers(
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        uint256 _loserAppealPeriodMultiplier
    ) external onlyOwner {
        _setMultipliers(_winnerStakeMultiplier, _loserStakeMultiplier, _loserAppealPeriodMultiplier);
    }

    function _setMultipliers(
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        uint256 _loserAppealPeriodMultiplier
    ) internal {
        winnerStakeMultiplier = _winnerStakeMultiplier;
        loserStakeMultiplier = _loserStakeMultiplier;
        loserAppealPeriodMultiplier = _loserAppealPeriodMultiplier;
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@mtsalenc*, @hbarcelos*, @unknownunknown1, @MerlinEgalite, @fnanni-0*, @shalzz]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/**
 *  @title This serves as a standard interface for crowdfunded appeals and evidence submission, which aren't a part of the arbitration (erc-792 and erc-1497) standard yet.
    This interface is used in Dispute Resolver (resolve.kleros.io).
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "2.0.0"; // Can be used to distinguish between multiple deployed versions, if necessary.

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param _contributor Caller of fundAppeal function.
     *  @param _amount Contribution amount.
     */
    event Contribution(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 ruling, address indexed _contributor, uint256 _amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the withdrawal was made from.
     *  @param _ruling Indicates the ruling option which contributor gets rewards from.
     *  @param _contributor The beneficiary of withdrawal.
     *  @param _reward Total amount of withdrawal, consists of reimbursed deposits plus rewards.
     */
    event Withdrawal(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 _ruling, address indexed _contributor, uint256 _reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round Number of the round this ruling option was fully funded in.
     *  @param _ruling The ruling option which just got fully funded.
     */
    event RulingFunded(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 indexed _ruling);

    /** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id.
     *  @param _externalDisputeID Dispute id as in arbitrator contract.
     *  @return localDisputeID Dispute id as in arbitrable contract.
     */
    function externalIDtoLocalID(uint256 _externalDisputeID) external virtual returns (uint256 localDisputeID);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256 _localDisputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    function submitEvidence(uint256 _localDisputeID, string calldata _evidenceURI) external virtual;

    /** @dev Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable virtual returns (bool fullyFunded);

    /** @dev Returns appeal multipliers.
     *  @return winnerStakeMultiplier Winners stake multiplier.
     *  @return loserStakeMultiplier Losers stake multiplier.
     *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        virtual
        returns (
            uint256 winnerStakeMultiplier,
            uint256 loserStakeMultiplier,
            uint256 loserAppealPeriodMultiplier,
            uint256 denominator
        );

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _round Number of the round that caller wants to execute withdraw on.
     *  @param _ruling A ruling option that caller wants to execute withdraw on.
     *  @return sum The amount that is going to be transferred to contributor as a result of this function call.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _round,
        uint256 _ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds at once.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to get withdrawable amount from.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external view virtual returns (uint256 sum);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "../IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
/**
 *  @title NerwoArbitrable
 *  @author: [@eburgos, @n1c01a5, @ferittuncer, @sherpya]
 */

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IArbitrator} from "@kleros/erc-792/contracts/IArbitrator.sol";
import {IArbitrable} from "@kleros/erc-792/contracts/IArbitrable.sol";
import {IDisputeResolver} from "@kleros/dispute-resolver-interface-contract/contracts/IDisputeResolver.sol";

import {SafeTransfer} from "./SafeTransfer.sol";

abstract contract NerwoArbitrable is Ownable, ReentrancyGuard, IDisputeResolver {
    using SafeTransfer for address;

    error NullAddress();
    error NoTimeout();
    error InvalidRuling();
    error InvalidCaller(address expected);
    error InvalidStatus(uint256 expected);
    error InvalidAmount();
    error InvalidTransaction();
    error InvalidToken();
    error InvalidFeeBasisPoint();

    error InvalidAppealPeriod();
    error AppealAlreadyPaid();

    // **************************** //
    // *    Contract variables    * //
    // **************************** //
    uint8 private constant AMOUNT_OF_CHOICES = 2;
    uint8 private constant SENDER_WINS = 1;
    uint8 private constant RECEIVER_WINS = 2;
    uint256 internal constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    struct Round {
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid for each ruling option in this round.
        mapping(uint256 => bool) hasPaid; // True if this ruling option was fully funded, false otherwise.
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each side.
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the ruling that ultimately wins a dispute.
        uint256[] fundedRulings; // Stores the ruling options that are fully funded.
    }

    enum Party {
        Sender,
        Receiver
    }

    enum Status {
        NoDispute,
        WaitingSender,
        WaitingReceiver,
        DisputeCreated,
        Resolved
    }

    struct Transaction {
        Status status;
        uint32 lastInteraction; // Last interaction for the dispute procedure.
        address sender;
        address receiver;
        IERC20 token;
        uint256 amount;
        uint256 disputeId; // If dispute exists, the ID of the dispute.
        uint256 senderFee; // Total fees paid by the sender.
        uint256 receiverFee; // Total fees paid by the receiver.
        uint256 ruling;
    }

    uint256 public lastTransaction;

    IERC20[] internal tokensWhitelist; // whitelisted ERC20 tokens

    struct ArbitratorData {
        IArbitrator arbitrator; // Address of the arbitrator contract.
        uint32 feeTimeout; // Time in seconds a party can take to pay arbitration fees before being considered unresponding and lose the dispute.
    }

    ArbitratorData public arbitratorData;

    struct FeeRecipientData {
        address feeRecipient; // Address which receives a share of receiver payment.
        uint16 feeRecipientBasisPoint; // The share of fee to be received by the feeRecipient, in basis points. Note that this value shouldn't exceed Divisor.
    }

    FeeRecipientData public feeRecipientData;

    mapping(uint256 => Transaction) private transactions;
    mapping(uint256 => uint256) private disputeIDtoTransactionID; // One-to-one relationship between the dispute and the transaction.

    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    string public metaevidenceURI;

    /* IDisputeResolver */
    // The required fee stake that a party must pay depends on who won the previous round
    // and is proportional to the arbitration cost such that the fee stake for a round
    // is stake multiplier * arbitration cost for that round.
    uint256 public winnerStakeMultiplier; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points. Default is 1x of appeal fee.
    uint256 public loserStakeMultiplier; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points. Default is 2x of appeal fee.
    uint256 public loserAppealPeriodMultiplier; // Multiplier of the appeal period for losers (any other ruling options) in basis points. Default is 1/2 of original appeal period.
    mapping(uint256 => Round[]) private disputeIDtoRoundArray; // Maps dispute IDs to round arrays.

    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev To be emitted when a party pays or reimburses the other.
     *  @param _transactionID The index of the transaction.
     *  @param _token The token address.
     *  @param _amount The amount paid.
     *  @param _party The party that paid.
     */
    event Payment(uint256 indexed _transactionID, address indexed _token, uint256 _amount, address indexed _party);

    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _transactionID The index of the transaction.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint256 indexed _transactionID, Party _party);

    /** @dev Emitted when a transaction is created.
     *  @param _transactionID The index of the transaction.
     *  @param _sender The address of the sender.
     *  @param _receiver The address of the receiver.
     *  @param _token The token address
     *  @param _amount The initial amount in the transaction.
     */
    event TransactionCreated(
        uint256 _transactionID,
        address indexed _sender,
        address indexed _receiver,
        address indexed _token,
        uint256 _amount
    );

    /** @dev To be emitted when a fee is received by the feeRecipient.
     *  @param _transactionID The index of the transaction.
     *  @param _token The Token Address.
     *  @param _amount The amount paid.
     */
    event FeeRecipientPayment(uint256 indexed _transactionID, address indexed _token, uint256 _amount);

    /** @dev To be emitted when a feeRecipient is changed.
     *  @param _oldFeeRecipient Previous feeRecipient.
     *  @param _newFeeRecipient Current feeRecipient.
     */
    event FeeRecipientChanged(address indexed _oldFeeRecipient, address indexed _newFeeRecipient);

    function _requireValidTransaction(uint256 _transactionID) internal view {
        if (transactions[_transactionID].receiver == address(0)) {
            revert InvalidTransaction();
        }
    }

    modifier onlyValidTransaction(uint256 _transactionID) {
        _requireValidTransaction(_transactionID);
        _;
    }

    // **************************** //
    // *   Arbitrable functions   * //
    // **************************** //

    /** @dev Calculate the amount to be paid in wei according to feeRecipientBasisPoint for a particular amount.
     *  @param _amount Amount to pay in wei.
     */
    function calculateFeeRecipientAmount(uint256 _amount) public view returns (uint256) {
        return (_amount * feeRecipientData.feeRecipientBasisPoint) / MULTIPLIER_DIVISOR;
    }

    /** @dev Create a transaction.
     *  @param _token The ERC20 token contract.
     *  @param _amount The amount of tokens in this transaction.
     *  @param _receiver The recipient of the transaction.
     *  @return transactionID The index of the transaction.
     */
    function createTransaction(
        IERC20 _token,
        uint256 _amount,
        address _receiver
    ) external returns (uint256 transactionID) {
        if (_receiver == address(0)) {
            revert NullAddress();
        }

        if (_amount == 0) {
            revert InvalidAmount();
        }

        // Amount too low to pay fee
        // WTF: solidity, nested if consumes less gas
        if (feeRecipientData.feeRecipientBasisPoint > 0) {
            if ((_amount * feeRecipientData.feeRecipientBasisPoint) < MULTIPLIER_DIVISOR) {
                revert InvalidAmount();
            }
        }

        address sender = _msgSender();
        if (sender == _receiver) {
            revert InvalidCaller(_receiver);
        }

        IERC20 token;
        for (uint i = 0; i < tokensWhitelist.length; i++) {
            if (_token == tokensWhitelist[i]) {
                token = _token;
                break;
            }
        }

        if (address(token) == address(0)) {
            revert InvalidToken();
        }

        // first transfer tokens to the contract
        // NOTE: user must have approved the allowance
        if (!token.transferFrom(sender, address(this), _amount)) {
            revert InvalidAmount();
        }

        unchecked {
            transactionID = ++lastTransaction;
        }

        transactions[transactionID] = Transaction({
            status: Status.NoDispute,
            lastInteraction: uint32(block.timestamp),
            sender: sender,
            receiver: _receiver,
            token: token,
            amount: _amount,
            disputeId: 0,
            senderFee: 0,
            receiverFee: 0,
            ruling: 0
        });

        emit TransactionCreated(transactionID, sender, _receiver, address(_token), _amount);
    }

    /** @dev Pay receiver. To be called if the good or service is provided.
     *  @param _transactionID The index of the transaction.
     *  @param _amount Amount to pay in wei.
     */
    function pay(uint256 _transactionID, uint256 _amount) external onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (_msgSender() != transaction.sender) {
            revert InvalidCaller(transaction.sender);
        }

        if (transaction.status != Status.NoDispute) {
            revert InvalidStatus(uint256(Status.NoDispute));
        }

        if ((_amount == 0) || (transaction.amount == 0) || (_amount > transaction.amount)) {
            revert InvalidAmount();
        }

        // _amount <= transaction.amount
        unchecked {
            transaction.amount -= _amount;
        }

        uint256 feeAmount = calculateFeeRecipientAmount(_amount);
        feeRecipientData.feeRecipient.transferToken(transaction.token, feeAmount);
        emit FeeRecipientPayment(_transactionID, address(transaction.token), feeAmount);

        transaction.receiver.sendToken(transaction.token, _amount - feeAmount);
        emit Payment(_transactionID, address(transaction.token), _amount, _msgSender());
    }

    /** @dev Reimburse sender. To be called if the good or service can't be fully provided.
     *  @param _transactionID The index of the transaction.
     *  @param _amountReimbursed Amount to reimburse in wei.
     */
    function reimburse(
        uint256 _transactionID,
        uint256 _amountReimbursed
    ) external onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (_msgSender() != transaction.receiver) {
            revert InvalidCaller(transaction.receiver);
        }

        if (transaction.status != Status.NoDispute) {
            revert InvalidStatus(uint256(Status.NoDispute));
        }

        if ((_amountReimbursed == 0) || (transaction.amount == 0) || (_amountReimbursed > transaction.amount)) {
            revert InvalidAmount();
        }

        // _amountReimbursed <= transaction.amount
        unchecked {
            transaction.amount -= _amountReimbursed;
        }
        transaction.sender.sendToken(transaction.token, _amountReimbursed);
        emit Payment(_transactionID, address(transaction.token), _amountReimbursed, _msgSender());
    }

    /** @dev Reimburse sender if receiver fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    function timeOutBySender(uint256 _transactionID) external onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (transaction.status != Status.WaitingReceiver) {
            revert InvalidStatus(uint256(Status.WaitingReceiver));
        }

        if (block.timestamp - transaction.lastInteraction < arbitratorData.feeTimeout) {
            revert NoTimeout();
        }

        _executeRuling(_transactionID, SENDER_WINS);
    }

    /** @dev Pay receiver if sender fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    function timeOutByReceiver(uint256 _transactionID) external onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (transaction.status != Status.WaitingSender) {
            revert InvalidStatus(uint256(Status.WaitingSender));
        }

        if (block.timestamp - transaction.lastInteraction < arbitratorData.feeTimeout) {
            revert NoTimeout();
        }

        _executeRuling(_transactionID, RECEIVER_WINS);
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the sender. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw, which will make this function throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     *  @param _transactionID The index of the transaction.
     */
    function payArbitrationFeeBySender(uint256 _transactionID) external payable onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (_msgSender() != transaction.sender) {
            revert InvalidCaller(transaction.sender);
        }

        if (transaction.status >= Status.DisputeCreated) {
            revert InvalidStatus(uint256(Status.DisputeCreated));
        }

        uint256 _arbitrationCost = arbitratorData.arbitrator.arbitrationCost(arbitratorExtraData);

        if (msg.value != _arbitrationCost) {
            revert InvalidAmount();
        }

        transaction.senderFee = msg.value;
        transaction.lastInteraction = uint32(block.timestamp);

        // The receiver still has to pay. This can also happen if he has paid,
        // but arbitrationCost has increased.
        if (transaction.receiverFee == 0) {
            transaction.status = Status.WaitingReceiver;
            emit HasToPayFee(_transactionID, Party.Receiver);
        } else {
            // The receiver has also paid the fee. We create the dispute.
            _raiseDispute(_transactionID, _arbitrationCost);
        }
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the receiver. UNTRUSTED.
     *  Note that this function mirrors payArbitrationFeeBySender.
     *  @param _transactionID The index of the transaction.
     */
    function payArbitrationFeeByReceiver(uint256 _transactionID) external payable onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (_msgSender() != transaction.receiver) {
            revert InvalidCaller(transaction.receiver);
        }

        if (transaction.status >= Status.DisputeCreated) {
            revert InvalidStatus(uint256(Status.DisputeCreated));
        }

        uint256 _arbitrationCost = arbitratorData.arbitrator.arbitrationCost(arbitratorExtraData);

        if (msg.value != _arbitrationCost) {
            revert InvalidAmount();
        }

        transaction.receiverFee = msg.value;
        transaction.lastInteraction = uint32(block.timestamp);

        // The sender still has to pay. This can also happen if he has paid,
        // but arbitrationCost has increased.
        if (transaction.senderFee == 0) {
            transaction.status = Status.WaitingSender;
            emit HasToPayFee(_transactionID, Party.Sender);
        } else {
            // The sender has also paid the fee. We create the dispute.
            _raiseDispute(_transactionID, _arbitrationCost);
        }
    }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _transactionID The index of the transaction.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    function _raiseDispute(uint256 _transactionID, uint256 _arbitrationCost) internal {
        Transaction storage transaction = transactions[_transactionID];
        transaction.status = Status.DisputeCreated;

        transaction.disputeId = arbitratorData.arbitrator.createDispute{value: _arbitrationCost}(
            AMOUNT_OF_CHOICES,
            arbitratorExtraData
        );

        disputeIDtoTransactionID[transaction.disputeId] = _transactionID;
        disputeIDtoRoundArray[_transactionID].push();

        //emit MetaEvidence(_transactionID, metaevidenceURI);
        emit Dispute(arbitratorData.arbitrator, transaction.disputeId, _transactionID, _transactionID);
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _transactionID The index of the transaction.
     *  @param _evidenceURI Link to evidence.
     */
    function submitEvidence(
        uint256 _transactionID,
        string calldata _evidenceURI
    ) external override onlyValidTransaction(_transactionID) {
        Transaction storage transaction = transactions[_transactionID];

        if (_msgSender() != transaction.sender && _msgSender() != transaction.receiver) {
            revert InvalidCaller(address(0));
        }

        if (transaction.status == Status.Resolved) {
            revert InvalidStatus(uint256(Status.Resolved));
        }

        emit Evidence(arbitratorData.arbitrator, _transactionID, _msgSender(), _evidenceURI);
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling
     *  it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator.
     *                 Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external override {
        if (_msgSender() != address(arbitratorData.arbitrator)) {
            revert InvalidCaller(address(arbitratorData.arbitrator));
        }

        if (_ruling > AMOUNT_OF_CHOICES) {
            revert InvalidRuling();
        }

        uint256 transactionID = disputeIDtoTransactionID[_disputeID];
        _requireValidTransaction(transactionID);
        Transaction storage transaction = transactions[transactionID];

        if (transaction.status != Status.DisputeCreated) {
            revert InvalidStatus(uint256(Status.DisputeCreated));
        }

        Round[] storage rounds = disputeIDtoRoundArray[transactionID];
        Round storage lastRound = disputeIDtoRoundArray[transactionID][rounds.length - 1];

        // If only one ruling option is funded, it wins by default.
        // Note that if any other ruling had funded, an appeal would have been created.
        if (lastRound.fundedRulings.length == 1) {
            transaction.ruling = lastRound.fundedRulings[0];
        } else {
            transaction.ruling = _ruling;
        }

        emit Ruling(IArbitrator(_msgSender()), _disputeID, transaction.ruling);

        _executeRuling(transactionID, transaction.ruling);
    }

    /** @dev Execute a ruling of a dispute. It reimburses the fee to the winning party.
     *  @param _transactionID The index of the transaction.
     *  @param _ruling Ruling given by the arbitrator. 1 : Reimburse the receiver. 2 : Pay the sender.
     */
    function _executeRuling(uint256 _transactionID, uint256 _ruling) internal nonReentrant {
        Transaction storage transaction = transactions[_transactionID];

        uint256 amount = transaction.amount;
        uint256 senderArbitrationFee = transaction.senderFee;
        uint256 receiverArbitrationFee = transaction.receiverFee;

        transaction.amount = 0;
        transaction.senderFee = 0;
        transaction.receiverFee = 0;
        transaction.status = Status.Resolved;

        uint256 feeAmount;

        // Give the arbitration fee back.
        // Note that we use send to prevent a party from blocking the execution.
        if (_ruling == SENDER_WINS) {
            transaction.sender.sendToken(transaction.token, amount);
            transaction.sender.sendTo(senderArbitrationFee);
        } else if (_ruling == RECEIVER_WINS) {
            feeAmount = calculateFeeRecipientAmount(amount);
            feeRecipientData.feeRecipient.transferToken(transaction.token, feeAmount);
            emit FeeRecipientPayment(_transactionID, address(transaction.token), feeAmount);

            transaction.receiver.sendToken(transaction.token, amount - feeAmount);
            transaction.receiver.sendTo(receiverArbitrationFee);
        } else {
            uint256 splitArbitration = senderArbitrationFee / 2;
            uint256 splitAmount = amount / 2;

            feeAmount = calculateFeeRecipientAmount(splitAmount);
            feeRecipientData.feeRecipient.transferToken(transaction.token, feeAmount);
            emit FeeRecipientPayment(_transactionID, address(transaction.token), feeAmount);

            // In the case of an uneven token amount, one basic token unit can be burnt.
            transaction.sender.sendToken(transaction.token, splitAmount);
            transaction.receiver.sendToken(transaction.token, splitAmount - feeAmount);

            transaction.sender.sendTo(splitArbitration);
            transaction.receiver.sendTo(splitArbitration);
        }
    }

    /** @dev Retrieves appeal cost for each ruling. It extends the function with the same name on the arbitrator side by adding
     *  _ruling parameter because total to be raised depends on multipliers.
     *  @param _disputeID The dispute this function returns its appeal costs.
     *  @param _ruling The ruling option which the caller wants to return the appeal cost for.
     *  @param _currentRuling The ruling option which the caller wants to return the appeal cost for.
     *  @return originalCost The original cost of appeal, decided by arbitrator.
     *  @return specificCost The specific cost of appeal, including appeal stakes of winner or loser.
     */
    function appealCost(
        uint256 _disputeID,
        uint256 _ruling,
        uint256 _currentRuling
    ) internal view returns (uint256 originalCost, uint256 specificCost) {
        uint256 multiplier = (_ruling == _currentRuling) ? winnerStakeMultiplier : loserStakeMultiplier;
        uint256 appealFee = arbitratorData.arbitrator.appealCost(_disputeID, arbitratorExtraData);
        return (appealFee, appealFee + ((appealFee * multiplier) / MULTIPLIER_DIVISOR));
    }

    /** @dev Reverts if appeal period has expired for given ruling option. It gives less time for funding appeal for losing ruling option (in the last round).
     *  Note that we don't check starting time, as arbitrator already check this. If user contributes before starting time it's effectively an early contibution for the next round.
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _ruling The ruling option to query for.
     *  @param _currentRuling The latest ruling given by Kleros. Note that this ruling is not final at this point, can be appealed.
     */
    function checkAppealPeriod(uint256 _disputeID, uint256 _ruling, uint256 _currentRuling) internal view {
        (uint256 originalStart, uint256 originalEnd) = arbitratorData.arbitrator.appealPeriod(_disputeID);

        if (_currentRuling == _ruling) {
            if (originalEnd > block.timestamp) {
                revert InvalidAppealPeriod();
            }
        } else {
            if (
                (originalStart + ((originalEnd - originalStart) * loserAppealPeriodMultiplier) / MULTIPLIER_DIVISOR) >
                block.timestamp
            ) {
                revert InvalidAppealPeriod();
            }
        }
    }

    /** @dev TRUSTED. Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param _transactionID The index of the transaction.
     *  @param _ruling The ruling to which the caller wants to contribute.
     *  @return fullyFunded Whether _ruling was fully funded after the call.
     */
    function fundAppeal(
        uint256 _transactionID,
        uint256 _ruling
    ) external payable override onlyValidTransaction(_transactionID) returns (bool fullyFunded) {
        if (_ruling > AMOUNT_OF_CHOICES) {
            revert InvalidRuling();
        }

        uint256 disputeID = transactions[_transactionID].disputeId;

        uint256 originalCost;
        uint256 totalCost;
        {
            uint256 currentRuling = arbitratorData.arbitrator.currentRuling(disputeID); // Intermediate variable to make reads cheaper.
            (originalCost, totalCost) = appealCost(disputeID, _ruling, currentRuling);
            checkAppealPeriod(disputeID, _ruling, currentRuling); // Reverts if appeal period has been expired for _ruling.
        }

        Round[] storage rounds = disputeIDtoRoundArray[_transactionID];
        uint256 lastRoundIndex = rounds.length - 1; // Intermediate variable to make reads cheaper.
        Round storage lastRound = rounds[lastRoundIndex];

        // Appeal fee has already been paid.
        if (lastRound.hasPaid[_ruling]) {
            revert AppealAlreadyPaid();
        }
        uint256 paidFeesInLastRound = lastRound.paidFees[_ruling]; // Intermediate variable to make reads cheaper.

        uint256 contribution = (totalCost - paidFeesInLastRound) > msg.value
            ? msg.value
            : totalCost - paidFeesInLastRound;
        lastRound.paidFees[_ruling] += contribution;

        address sender = _msgSender();

        emit Contribution(_transactionID, lastRoundIndex, _ruling, sender, contribution);
        lastRound.contributions[sender][_ruling] += contribution;

        paidFeesInLastRound = lastRound.paidFees[_ruling]; // Intermediate variable to make reads cheaper.

        if (paidFeesInLastRound >= totalCost) {
            lastRound.feeRewards += paidFeesInLastRound;
            lastRound.fundedRulings.push(_ruling);
            lastRound.hasPaid[_ruling] = true;
            emit RulingFunded(_transactionID, lastRoundIndex, _ruling);
        }

        if (lastRound.fundedRulings.length == 2) {
            // Two competing ruling options means we will have another appeal round.
            rounds.push();

            lastRound.feeRewards = lastRound.feeRewards - originalCost;
            arbitratorData.arbitrator.appeal{value: originalCost}(disputeID, arbitratorExtraData);
        }

        // Sending extra value back to contributor. Send preferred over transfer deliberately.
        sender.sendTo(msg.value - contribution);

        return lastRound.hasPaid[_ruling];
    }

    /** @dev Returns withdrawable amount for given parameters.
     *  @param _round The round number to calculate amount for.
     *  @param _contributor The contributor for which to query.
     *  @param _ruling The ruling option to search for potential withdrawal. Caller can obtain this information using Contribution events.
     *  @return amount The total amount available to withdraw.
     */
    function getWithdrawableAmount(
        Round storage _round,
        address _contributor,
        uint256 _ruling,
        uint256 _finalRuling
    ) internal view returns (uint256 amount) {
        if (!_round.hasPaid[_ruling]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = _round.contributions[_contributor][_ruling];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == _finalRuling) {
                // This ruling option is the ultimate winner.
                amount = _round.paidFees[_ruling] > 0
                    ? (_round.contributions[_contributor][_ruling] * _round.feeRewards) / _round.paidFees[_ruling]
                    : 0;
            } else if (!_round.hasPaid[_finalRuling]) {
                // The ultimate winner was not funded in this round. In this case funded ruling option(s) wins by default. Prize is distributed among contributors of funded ruling option(s).
                amount =
                    (_round.contributions[_contributor][_ruling] * _round.feeRewards) /
                    (_round.paidFees[_round.fundedRulings[0]] + _round.paidFees[_round.fundedRulings[1]]);
            }
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param _transactionID The index of the transaction.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling The ruling option that the caller wants to withdraw fees and rewards related to it.
     *  @return amount Reward amount that is to be withdrawn. Might be zero if arguments are not qualifying for a reward or reimbursement, or it might be withdrawn already.
     */
    function withdrawFeesAndRewards(
        uint256 _transactionID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) public override onlyValidTransaction(_transactionID) returns (uint256 amount) {
        Transaction storage transaction = transactions[_transactionID];

        // The dispute should be solved
        if (transaction.status != Status.Resolved) {
            revert InvalidStatus(uint256(Status.Resolved));
        }

        Round storage round = disputeIDtoRoundArray[_transactionID][_roundNumber];

        amount = getWithdrawableAmount(round, _contributor, _ruling, transaction.ruling);

        if (amount != 0) {
            round.contributions[_contributor][_ruling] = 0;
            address(_contributor).sendTo(amount); // Ignoring failure condition deliberately.
            emit Withdrawal(_transactionID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For all rounds at once.
     *  This function has O(m) time complexity where m is number of rounds.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(2^m).
     *  Thus, we can assume this loop will run less than 10 times, and on average just a few times.
     *  @param _transactionID The index of the transaction.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _ruling Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _transactionID,
        address payable _contributor,
        uint256 _ruling
    ) external override onlyValidTransaction(_transactionID) {
        uint256 numberOfRounds = disputeIDtoRoundArray[_transactionID].length;
        for (uint256 roundNumber = 0; roundNumber < numberOfRounds; roundNumber++) {
            withdrawFeesAndRewards(_transactionID, _contributor, roundNumber, _ruling);
        }
    }

    /** @notice Returns the sum of withdrawable amount.
     *  @dev This function has O(m) time complexity where m is number of rounds.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(2^m).
     *  @param _transactionID The index of the transaction.
     *  @param _contributor The contributor for which to query.
     *  @param _ruling The ruling option to search for potential withdrawal. Caller can obtain this information using Contribution events.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _transactionID,
        address payable _contributor,
        uint256 _ruling
    ) external view override returns (uint256 sum) {
        Transaction storage transaction = transactions[_transactionID];

        if (transaction.status != Status.Resolved) {
            return 0;
        }

        uint256 finalRuling = transaction.ruling;

        uint256 numberOfRounds = disputeIDtoRoundArray[_transactionID].length;
        for (uint256 roundNumber = 0; roundNumber < numberOfRounds; roundNumber++) {
            Round storage round = disputeIDtoRoundArray[_transactionID][roundNumber];
            sum += getWithdrawableAmount(round, _contributor, _ruling, finalRuling);
        }
    }

    // **************************** //
    // *   Utils for frontends    * //
    // **************************** //

    /**
     * @dev Get transaction by id
     * @return transaction
     */
    function getTransaction(
        uint256 _transactionID
    ) external view onlyValidTransaction(_transactionID) returns (Transaction memory) {
        return transactions[_transactionID];
    }

    /**
     * @dev Get supported ERC20 tokens
     * @return tokens array of addresses of supported tokens
     */
    function getSupportedTokens() external view returns (IERC20[] memory) {
        return tokensWhitelist;
    }

    /**
     * @dev Ask arbitrator for abitration cost
     * @return cost Amount to be paid.
     */
    function arbitrationCost() external view returns (uint256 cost) {
        cost = arbitratorData.arbitrator.arbitrationCost(arbitratorExtraData);
    }

    /** @dev Returns stake multipliers.
     *  @return _winnerStakeMultiplier Winners stake multiplier.
     *  @return _loserStakeMultiplier Losers stake multiplier.
     *  @return _loserAppealPeriodMultiplier Multiplier for losers appeal period. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return _denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        override
        returns (
            uint256 _winnerStakeMultiplier,
            uint256 _loserStakeMultiplier,
            uint256 _loserAppealPeriodMultiplier,
            uint256 _denominator
        )
    {
        return (winnerStakeMultiplier, loserStakeMultiplier, loserAppealPeriodMultiplier, MULTIPLIER_DIVISOR);
    }

    function externalIDtoLocalID(uint256 _externalDisputeID) external view override returns (uint256 localDisputeID) {
        localDisputeID = disputeIDtoTransactionID[_externalDisputeID];
        _requireValidTransaction(localDisputeID);
    }

    function numberOfRulingOptions(uint256 /*_localDisputeID*/) external pure override returns (uint256 count) {
        count = AMOUNT_OF_CHOICES;
    }
}

// SPDX-License-Identifier: MIT
/**
 *  @title SafeTransfer
 *  @author: [@sherpya]
 */

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeTransfer {
    error TransferFailed(address recipient, address token, uint256 amount, bytes data);

    /** @dev To be emitted if a transfer to a party fails
     *  @param recipient The target of the failed operation
     *  @param token The token address
     *  @param amount The amount
     *  @param data Failed call data
     */
    event SendFailed(address indexed recipient, address indexed token, uint256 amount, bytes data);

    /** @dev Send to recipent, emit a log when fails
     *  @param target To address to send to
     *  @param amount Transaction amount
     */
    function sendTo(address target, uint256 amount) internal {
        (bool success, bytes memory data) = payable(target).call{value: amount}("");
        if (!success) {
            emit SendFailed(target, address(0), amount, data);
        }
    }

    /** @dev Send to recipent, reverts on failure
     *  @param target To address to send to
     *  @param amount Transaction amount
     */
    function transferTo(address payable target, uint256 amount) internal {
        (bool success, bytes memory data) = target.call{value: amount}("");
        if (!success) {
            revert TransferFailed(target, address(0), amount, data);
        }
    }

    /**
     * @dev Transfers token to a specified address
     * @param to The address to transfer to.
     * @param token The address of the token contract.
     * @param amount The amount to be transferred.
     */
    function _safeTransferToken(
        address to,
        IERC20 token,
        uint256 amount
    ) internal returns (bool success, bytes memory data) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, data) = address(token).call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));

        if (success && data.length > 0) {
            success = abi.decode(data, (bool));
        }
    }

    /** @dev Send to recipent, emit a log when fails
     *  @param to To address to send to
     *  @param token The token address
     *  @param amount Transaction amount
     */
    function sendToken(address to, IERC20 token, uint256 amount) internal {
        (bool success, bytes memory data) = _safeTransferToken(to, token, amount);
        if (!success) {
            emit SendFailed(to, address(token), amount, data);
        }
    }

    /** @dev Send to recipent, reverts on failure
     *  @param to To address to send to
     *  @param token The token address
     *  @param amount Transaction amount
     */
    function transferToken(address to, IERC20 token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        (bool success, bytes memory data) = _safeTransferToken(to, token, amount);
        if (!success) {
            revert TransferFailed(to, address(token), amount, data);
        }
    }
}