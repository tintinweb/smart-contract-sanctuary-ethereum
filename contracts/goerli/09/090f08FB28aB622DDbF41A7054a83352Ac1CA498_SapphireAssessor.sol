// SPDX-License-Identifier: MIT
// prettier-ignore

pragma solidity 0.8.4;

import {Ownable} from "../lib/Ownable.sol";
import {Address} from "../lib/Address.sol";
import {PassportScoreVerifiable} from "../lib/PassportScoreVerifiable.sol";
import {SapphireTypes} from "./SapphireTypes.sol";
import {ISapphireMapper} from "./ISapphireMapper.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

contract SapphireAssessor is Ownable, ISapphireAssessor, PassportScoreVerifiable {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Variables ========== */

    ISapphireMapper public mapper;

    uint16 public maxScore;

    /* ========== Events ========== */

    event MapperSet(address _newMapper);

    event PassportScoreContractSet(address _newCreditScoreContract);

    event MaxScoreSet(uint16 _maxScore);

    /* ========== Constructor ========== */

    constructor(
        address _mapper,
        address _passportScores,
        uint16 _maxScore
    ) {
        require(
            _mapper.isContract() &&
            _passportScores.isContract(),
            "SapphireAssessor: mapper and passport scores must be valid contracts"
        );

        mapper = ISapphireMapper(_mapper);
        passportScoresContract = ISapphirePassportScores(_passportScores);
        setMaxScore(_maxScore);
    }

    /* ========== View Functions ========== */

    function getPassportScoresContract() 
        external 
        view
        override
        returns (address)
    {
        return address(passportScoresContract);
    }
    
    /* ========== Public Functions ========== */

    /**
     * @notice  Takes a lower and upper bound, and based on the user's credit score
     *          and given its proof, returns the appropriate value between these bounds.
     *
     * @param _lowerBound       The lower bound
     * @param _upperBound       The upper bound
     * @param _scoreProof       The score proof
     * @param _isScoreRequired  The flag, which require the proof of score if the account already
                                has a score
     * @return A value between the lower and upper bounds depending on the credit score
     */
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired
    )
        external
        view
        override
        checkScoreProof(_scoreProof, _isScoreRequired, false)
        returns (uint256)
    {
        require(
            _upperBound > 0,
            "SapphireAssessor: The upper bound cannot be zero"
        );

        require(
            _lowerBound < _upperBound,
            "SapphireAssessor: The lower bound must be smaller than the upper bound"
        );

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        // If the proof is passed, use the score from the score proof since at this point
        // the proof should be verified if the score is > 0
        uint256 result = mapper.map(
            isProofPassed ? _scoreProof.score : 0,
            maxScore,
            _lowerBound,
            _upperBound
        );

        require(
            result >= _lowerBound &&
            result <= _upperBound,
            "SapphireAssessor: The mapper returned a value out of bounds"
        );

        return result;
    }

    function assessBorrowLimit(
        uint256 _borrowAmount,
        SapphireTypes.ScoreProof calldata _borrowLimitProof
    )
        external
        view
        override
        checkScoreProof(_borrowLimitProof, true, false)
        returns (bool)
    {

        require(
            _borrowAmount > 0,
            "SapphireAssessor: The borrow amount cannot be zero"
        );

        bool _isBorrowAmountValid = _borrowAmount <= _borrowLimitProof.score;

        return _isBorrowAmountValid;
    }

    function setMapper(
        address _mapper
    )
        external
        onlyOwner
    {
        require(
            _mapper.isContract(),
            "SapphireAssessor: _mapper is not a contract"
        );

        require(
            _mapper != address(mapper),
            "SapphireAssessor: The same mapper is already set"
        );

        mapper = ISapphireMapper(_mapper);

        emit MapperSet(_mapper);
    }

    function setPassportScoreContract(
        address _creditScore
    )
        external
        onlyOwner
    {
        require(
            _creditScore.isContract(),
            "SapphireAssessor: _creditScore is not a contract"
        );

        require(
            _creditScore != address(passportScoresContract),
            "SapphireAssessor: The same credit score contract is already set"
        );

        passportScoresContract = ISapphirePassportScores(_creditScore);

        emit PassportScoreContractSet(_creditScore);
    }

    function setMaxScore(
        uint16 _maxScore
    )
        public
        onlyOwner
    {
        require(
            _maxScore > 0,
            "SapphireAssessor: max score cannot be zero"
        );

        maxScore = _maxScore;

        emit MaxScoreSet(_maxScore);
    }

    function renounceOwnership()
        public
        view
        onlyOwner
        override
    {
        revert("SapphireAssessor: cannot renounce ownership");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the address type.
 *      Take from OpenZeppelin at
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {Address} from "./Address.sol";

import {ISapphirePassportScores} from "../sapphire/ISapphirePassportScores.sol";
import {SapphireTypes} from "../sapphire/SapphireTypes.sol";

/**
 * @dev Provides the ability of verifying users' credit scores
 */
contract PassportScoreVerifiable {

    using Address for address;

    ISapphirePassportScores public passportScoresContract;

    /**
     * @dev Verifies that the proof is passed if the score is required, and
     *      validates it.
     *      Additionally, it checks the proof validity if `scoreProof` has a score > 0
     */
    modifier checkScoreProof(
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired,
        bool _enforceSameCaller
    ) {
        if (_scoreProof.account != address(0) && _enforceSameCaller) {
            require (
                msg.sender == _scoreProof.account,
                "PassportScoreVerifiable: proof does not belong to the caller"
            );
        }

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        if (_isScoreRequired || isProofPassed || _scoreProof.score > 0) {
            passportScoresContract.verify(_scoreProof);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SapphireTypes {

    struct ScoreProof {
        address account;
        bytes32 protocol;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 normalizedBorrowedAmount;
        uint256 principal;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        address borrowAssetAddress;
        Operation operation;
        address userToLiquidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISapphireMapper {

    /**
     * @notice Maps the `_score` to a value situated between
     * the given lower and upper bounds
     *
     * @param _score The user's credit score to use for the mapping
     * @param _scoreMax The maximum value the score can be
     * @param _lowerBound The lower bound
     * @param _upperBound The upper bound
     */
    function map(
        uint256 _score,
        uint256 _scoreMax,
        uint256 _lowerBound,
        uint256 _upperBound
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphirePassportScores {
    function currentEpoch() external view returns (uint256);

    function rootsHistory(uint256 _epoch) external view returns (bytes32, uint256);

    function isPaused() external view returns (bool);

    function merkleRootDelayDuration() external view returns (uint256);

    function merkleRootUpdater() external view returns (address);
    
    function pauseOperator() external view returns (address);

    /**
     * Reverts if proof is invalid
     */
    function verify(SapphireTypes.ScoreProof calldata _proof) external view returns(bool);
    
    function updateMerkleRoot(bytes32 _newRoot) external;

    function setMerkleRootUpdater(address _merkleRootUpdater) external;

    function setMerkleRootDelay(uint256 _delay) external;

    function setPause(bool _status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphireAssessor {
    function getPassportScoresContract() external view returns (address);
    
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof calldata _scoreProof,
        bool _isScoreRequired
    )
        external
        returns (uint256);

    function assessBorrowLimit(
        uint256 _borrowedAmount,
        SapphireTypes.ScoreProof calldata _borrowLimitProof
    )
        external
        returns (bool);
}