/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity ^0.8.0;
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

pragma solidity 0.8.13;

interface IResultOracle {
    function getEighthsRoundResult() external returns (bool[] memory);

    function getFourthRoundResult() external returns (bool[] memory);

    function getSemifinalRoundResult() external returns (bool[] memory);

    function getFinalRoundResult() external returns (bool);
}

interface INFTCollection {
    function getOwnerNftId(uint256 nftId) external view returns (address);

    function mint(address owner, uint16 idTeam) external returns (uint256);
}

contract Pool is Ownable {
    enum Phase {
        VOTING,
        UPDATING_RESULT,
        END
    }

    enum Round {
        EIGHTHS,
        FOURTH,
        SEMIFINAL,
        FINAL
    }
    uint256 private _eighthsRoundParticipants;
    uint256 private _fourthRoundParticipants;
    uint256 private _semifinalRoundParticipants;
    uint256 private _finalRoundParticipants;

    mapping(uint256 => bool[]) private _eighthsRoundSelection;
    mapping(uint256 => bool[]) private _fourthRoundSelection;
    mapping(uint256 => bool[]) private _semifinalRoundSelection;
    mapping(uint256 => bool) private _finalRoundSelection;

    mapping(uint256 => bool) private _voted;

    mapping(uint256 => bool) private _eighthsRoundWinners;
    mapping(uint256 => bool) private _fourthRoundWinners;
    mapping(uint256 => bool) private _semifinalRoundWinners;
    mapping(uint256 => bool) private _finalRoundWinners;

    uint256 private _amountEighthsRoundWinners;
    uint256 private _amountFourthRoundWinners;
    uint256 private _amountSemifinalRoundWinners;
    uint256 private _amountFinalRoundWinners;

    mapping(uint256 => mapping(uint256 => bool)) private _nftIdClaimedInRound;

    uint256 public constant NFT_EIGHTHS_ROUND_PRICE = 10 * (10**18);
    uint256 public constant NFT_FOURTH_ROUND_PRICE = 30 * (10**18);
    uint256 public constant NFT_SEMIFINAL_ROUND_PRICE = 50 * (10**18);
    uint256 public constant NFT_FINAL_ROUND_PRICE = 70 * (10**18);

    Round public actualRound = Round.EIGHTHS;
    Phase public actualPhase = Phase.VOTING;

    bool private _isEvenAEighthsRoundWinner;
    bool private _isEvenAFourthRoundWinner;
    bool private _isEvenASemifinalRoundWinner;
    bool private _isEvenAFinalRoundWinner;

    uint8 private _devsCharged;

    IResultOracle private _resultOracle;
    IERC20 private _stablecoinToken;
    INFTCollection private _nftEighthsRoundContract;
    INFTCollection private _nftFourthRoundContract;
    INFTCollection private _nftSemifinalRoundContract;
    INFTCollection private _nftFinalRoundContract;

    uint256 public immutable lowerBoundEighthNoWinnerRedistribute; //1657594799 11/07 23:59
    uint256 public immutable lowerBoundFourthNoWinnerRedistribute; //1660618799 15/08 23:59
    uint256 public immutable lowerBoundSemifinalNoWinnerRedistribute; //1663037999 12/09 23:59
    uint256 public immutable lowerBoundFinalNoWinnerRedistribute; // 1667617199 04/11 23:59

    constructor(
        IERC20 stablecoinToken,
        INFTCollection nftContract,
        IResultOracle resultOracle,
        uint256 eighthNoWinnerRedistribute,
        uint256 fourthNoWinnerRedistribute,
        uint256 semisNoWinnerRedistribute,
        uint256 finalNoWinnerRedistribute
    ) {
        _stablecoinToken = stablecoinToken;
        _nftEighthsRoundContract = nftContract;
        _resultOracle = resultOracle;
        lowerBoundEighthNoWinnerRedistribute = eighthNoWinnerRedistribute;
        lowerBoundFourthNoWinnerRedistribute = fourthNoWinnerRedistribute;
        lowerBoundSemifinalNoWinnerRedistribute = semisNoWinnerRedistribute;
        lowerBoundFinalNoWinnerRedistribute = finalNoWinnerRedistribute;
    }

    function getEighthsRoundSelection(uint256 nftId)
        external
        view
        returns (bool[] memory)
    {
        return _eighthsRoundSelection[nftId];
    }

    function getFourthRoundSelection(uint256 nftId)
        external
        view
        returns (bool[] memory)
    {
        return _fourthRoundSelection[nftId];
    }

    function getSemifinalRoundSelection(uint256 nftId)
        external
        view
        returns (bool[] memory)
    {
        return _semifinalRoundSelection[nftId];
    }

    function getFinalRoundSelection(uint256 nftId)
        external
        view
        returns (bool)
    {
        return _finalRoundSelection[nftId];
    }

    function getEighthsPoolPrize() public view returns (uint256) {
        return NFT_EIGHTHS_ROUND_PRICE * _eighthsRoundParticipants;
    }

    function getFourthPoolPrize() public view returns (uint256) {
        return NFT_FOURTH_ROUND_PRICE * _fourthRoundParticipants;
    }

    function getSemifinalPoolPrize() public view returns (uint256) {
        return NFT_SEMIFINAL_ROUND_PRICE * _semifinalRoundParticipants;
    }

    function getFinalPoolPrize() public view returns (uint256) {
        return NFT_FINAL_ROUND_PRICE * _finalRoundParticipants;
    }

    function getEighthsRoundEnum() public pure returns (Round) {
        return Round.EIGHTHS;
    }

    function getFourthRoundEnum() public pure returns (Round) {
        return Round.FOURTH;
    }

    function getSemifinalRoundEnum() public pure returns (Round) {
        return Round.SEMIFINAL;
    }

    function getFinalRoundEnum() public pure returns (Round) {
        return Round.FINAL;
    }

    function amountToClaim(Round round, uint256 nftId)
        public
        view
        returns (uint256)
    {
        if (_nftIdClaimedInRound[getIdRound(round)][nftId]) {
            return 0;
        }
        if (round == Round.EIGHTHS) {
            if (
                _eighthsRoundWinners[nftId] && _amountEighthsRoundWinners != 0
            ) {
                return
                    ((getEighthsPoolPrize() * 90) / 100) /
                    _amountEighthsRoundWinners;
            } else if (isNotWinnerInEighthsRound()) {
                return
                    ((getEighthsPoolPrize() * 90) / 100) /
                    _eighthsRoundParticipants;
            }
        }

        if (round == Round.FOURTH) {
            if (_fourthRoundWinners[nftId] && _amountFourthRoundWinners != 0) {
                return
                    ((getFourthPoolPrize() * 90) / 100) /
                    _amountFourthRoundWinners;
            } else if (isNotWinnerInFourthRound()) {
                return
                    ((getFourthPoolPrize() * 90) / 100) /
                    _fourthRoundParticipants;
            }
        }

        if (round == Round.SEMIFINAL) {
            if (
                _semifinalRoundWinners[nftId] &&
                _amountSemifinalRoundWinners != 0
            ) {
                return
                    ((getSemifinalPoolPrize() * 90) / 100) /
                    _amountSemifinalRoundWinners;
            }

            if (isNotWinnerInSemifinalRound()) {
                return
                    ((getSemifinalPoolPrize() * 90) / 100) /
                    _semifinalRoundParticipants;
            }
        }

        if (round == Round.FINAL) {
            if (_finalRoundWinners[nftId] && _amountFinalRoundWinners != 0) {
                return
                    ((getFinalPoolPrize() * 90) / 100) /
                    _amountFinalRoundWinners;
            }

            if (isNotWinnerInFinalRound()) {
                return
                    ((getFinalPoolPrize() * 90) / 100) /
                    _finalRoundParticipants;
            }
        }
        return 0;
    }

    function buyNFT(uint16 teamId) external payable {
        onlyPhase(Phase.VOTING);
        uint256 nftId;
        if (actualRound == Round.EIGHTHS) {
            nftId = buyEighthsRound(teamId);
        } else if (actualRound == Round.FOURTH) {
            nftId = buyFourthRound(teamId);
        } else if (actualRound == Round.SEMIFINAL) {
            nftId = buySemifinalRound(teamId);
        } else if (actualRound == Round.FINAL) {
            nftId = buyFinalRound(teamId);
        }
        //need to have allowance

        emit Minted(msg.sender, actualRound, nftId);
    }

    function buyEighthsRound(uint16 teamId) private returns (uint256 nftId) {
        require(
            _stablecoinToken.transferFrom(
                msg.sender,
                address(this),
                NFT_EIGHTHS_ROUND_PRICE
            ),
            "transferFrom revert"
        );
        require(teamId < 16, "That id is non-existent");
        nftId = _nftEighthsRoundContract.mint(msg.sender, teamId);
        ++_eighthsRoundParticipants;
        _eighthsRoundSelection[nftId] = new bool[](8);
    }

    function buyFourthRound(uint16 teamId) private returns (uint256 nftId) {
        require(
            _stablecoinToken.transferFrom(
                msg.sender,
                address(this),
                NFT_FOURTH_ROUND_PRICE
            ),
            "transferFrom revert"
        );
        require(teamId < 8, "That id is non-existent");
        nftId = _nftFourthRoundContract.mint(msg.sender, teamId);
        ++_fourthRoundParticipants;
        _fourthRoundSelection[nftId] = new bool[](4);
    }

    function buySemifinalRound(uint16 teamId) private returns (uint256 nftId) {
        require(
            _stablecoinToken.transferFrom(
                msg.sender,
                address(this),
                NFT_SEMIFINAL_ROUND_PRICE
            ),
            "transferFrom revert"
        );
        require(teamId < 4, "That id is non-existent");
        nftId = _nftSemifinalRoundContract.mint(msg.sender, teamId);
        ++_semifinalRoundParticipants;
        _semifinalRoundSelection[nftId] = new bool[](2);
    }

    function buyFinalRound(uint16 teamId) private returns (uint256 nftId) {
        require(
            _stablecoinToken.transferFrom(
                msg.sender,
                address(this),
                NFT_FINAL_ROUND_PRICE
            ),
            "transferFrom revert"
        );
        require(teamId < 2, "That id is non-existent");
        nftId = _nftFinalRoundContract.mint(msg.sender, teamId);
        ++_finalRoundParticipants;
    }

    function eighthsRoundVote(uint256 nftId, bool[] memory _vote) external {
        onlyPhase(Phase.VOTING);
        require(
            msg.sender == _nftEighthsRoundContract.getOwnerNftId(nftId),
            "msg.sender does not own this nft"
        );
        require(
            _vote.length == 8,
            "does not meet the characteristics of this vote"
        );
        require(!_voted[nftId], "you already voted");
        _eighthsRoundSelection[nftId] = _vote;

        _voted[nftId] = true;

        emit Voted(msg.sender, actualRound);
    }

    function fourthRoundVote(uint256 nftId, bool[] memory _vote) external {
        onlyPhase(Phase.VOTING);
        require(
            msg.sender == _nftFourthRoundContract.getOwnerNftId(nftId),
            "msg.sender does not own this nft"
        );
        require(
            _vote.length == 4,
            "does not meet the characteristics of this vote"
        );
        require(!_voted[nftId], "you already voted");

        _fourthRoundSelection[nftId] = _vote;

        _voted[nftId] = true;

        emit Voted(msg.sender, actualRound);
    }

    function semifinalRoundVote(uint256 nftId, bool[] memory _vote) external {
        onlyPhase(Phase.VOTING);
        require(
            msg.sender == _nftSemifinalRoundContract.getOwnerNftId(nftId),
            "msg.sender does not own this nft"
        );
        require(
            _vote.length == 2,
            "does not meet the characteristics of this vote"
        );
        require(!_voted[nftId], "you already voted");
        _semifinalRoundSelection[nftId] = _vote;

        _voted[nftId] = true;

        emit Voted(msg.sender, actualRound);
    }

    function finalRoundVote(uint256 nftId, bool _vote) external {
        onlyPhase(Phase.VOTING);
        require(
            msg.sender == _nftFinalRoundContract.getOwnerNftId(nftId),
            "msg.sender does not own this nft"
        );
        require(!_voted[nftId], "you already voted");
        _finalRoundSelection[nftId] = _vote;

        _voted[nftId] = true;

        emit Voted(msg.sender, actualRound);
    }

    function claim(Round round, uint256 nftId) external {
        validateNftId(round, nftId);
        uint256 totalAmount = amountToClaim(round, nftId);
        require(totalAmount != 0, "There is nothing to claim");

        _nftIdClaimedInRound[getIdRound(round)][nftId] = true;

        require(
            _stablecoinToken.transfer(msg.sender, totalAmount),
            "revert transfer"
        );
        emit Claimed(msg.sender, totalAmount);
    }

    function validateNftId(Round round, uint256 nftId) private view {
        if (Round.EIGHTHS == round) {
            require(
                msg.sender == _nftEighthsRoundContract.getOwnerNftId(nftId),
                "msg.sender does not own this nft"
            );
        } else if (Round.FOURTH == round) {
            require(
                msg.sender == _nftFourthRoundContract.getOwnerNftId(nftId),
                "msg.sender does not own this nft"
            );
        } else if (Round.SEMIFINAL == round) {
            require(
                msg.sender == _nftSemifinalRoundContract.getOwnerNftId(nftId),
                "msg.sender does not own this nft"
            );
        } else if (Round.FINAL == round) {
            require(
                msg.sender == _nftFinalRoundContract.getOwnerNftId(nftId),
                "msg.sender does not own this nft"
            );
        }
    }

    function getIdRound(Round round) private pure returns (uint256 result) {
        if (round == Round.EIGHTHS) {
            result = 1;
        }
        if (round == Round.FOURTH) {
            result = 2;
        }
        if (round == Round.SEMIFINAL) {
            result = 3;
        } else {
            result = 4;
        }
    }

    function endVotingTime() external onlyOwner returns (bool) {
        if (actualPhase == Phase.VOTING) {
            actualPhase = Phase.UPDATING_RESULT;
            return true;
        }
        return false;
    }

    function updateEighthsRoundWinnersAndSetFourthRound(
        INFTCollection fourthRoundContract
    ) external onlyOwner {
        onlyPhase(Phase.UPDATING_RESULT);
        onlyRound(Round.EIGHTHS);
        uint256 amountWinners;
        bool[] memory result = _resultOracle.getEighthsRoundResult();

        for (uint256 i = 1; i < _eighthsRoundParticipants + 1; ) {
            if (isWinnerOfEighthsRound(i, result)) {
                _eighthsRoundWinners[i] = true;
                ++amountWinners;
                _isEvenAEighthsRoundWinner = true;
            }
            _voted[i] = false;
            unchecked {
                ++i;
            }
        }
        _amountEighthsRoundWinners = amountWinners;
        actualPhase = Phase.VOTING;
        actualRound = Round.FOURTH;
        _nftFourthRoundContract = fourthRoundContract;
    }

    function isWinnerOfEighthsRound(uint256 nftId, bool[] memory result)
        private
        view
        returns (bool)
    {
        if (!_voted[nftId]) return false;

        bool[] memory selection = _eighthsRoundSelection[nftId];
        uint8 success;
        for (uint256 i; i < selection.length; ) {
            if (selection[i] == result[i]) {
                success++;
            }
            unchecked {
                ++i;
            }
        }
        if (success > 4) return true;
        return false;
    }

    function updateFourthRoundWinnersAndSetSemifinalRound(
        INFTCollection semifinalRoundContract
    ) external onlyOwner {
        onlyPhase(Phase.UPDATING_RESULT);
        onlyRound(Round.FOURTH);
        uint256 amountWinners;
        bool[] memory result = _resultOracle.getFourthRoundResult();

        for (uint256 i = 1; i < _fourthRoundParticipants + 1; ) {
            if (isWinnerOfFourthRound(i, result)) {
                _fourthRoundWinners[i] = true;
                amountWinners += 1;
                _isEvenAFourthRoundWinner = true;
            }
            _voted[i] = false;
            unchecked {
                i++;
            }
        }
        _amountFourthRoundWinners = amountWinners;
        actualPhase = Phase.VOTING;
        actualRound = Round.SEMIFINAL;
        _nftSemifinalRoundContract = semifinalRoundContract;
    }

    function isWinnerOfFourthRound(uint256 nftId, bool[] memory result)
        private
        view
        returns (bool)
    {
        if (!_voted[nftId]) return false;

        bool[] memory selection = _fourthRoundSelection[nftId];
        uint8 success;
        for (uint256 i; i < selection.length; ) {
            if (selection[i] == result[i]) {
                success++;
            }
            unchecked {
                ++i;
            }
        }
        if (success > 2) return true;
        return false;
    }

    function updateSemifinalRoundWinnersAndSetFinal(
        INFTCollection finalRoundContract
    ) external onlyOwner {
        onlyPhase(Phase.UPDATING_RESULT);
        onlyRound(Round.SEMIFINAL);
        uint256 amountWinners;
        bool[] memory result = _resultOracle.getSemifinalRoundResult();
        for (uint256 i = 1; i < _semifinalRoundParticipants + 1; ) {
            if (isWinnerOfSemifinalRound(i, result)) {
                _semifinalRoundWinners[i] = true;
                amountWinners += 1;
                _isEvenASemifinalRoundWinner = true;
            }
            _voted[i] = false;
            unchecked {
                i++;
            }
        }
        _amountSemifinalRoundWinners = amountWinners;
        actualPhase = Phase.VOTING;
        actualRound = Round.FINAL;
        _nftFinalRoundContract = finalRoundContract;
    }

    function isWinnerOfSemifinalRound(uint256 nftId, bool[] memory result)
        private
        view
        returns (bool)
    {
        if (!_voted[nftId]) return false;

        bool[] memory selection = _semifinalRoundSelection[nftId];
        uint8 success;
        for (uint256 i; i < selection.length; ) {
            if (selection[i] == result[i]) {
                success++;
            }
            unchecked {
                ++i;
            }
        }
        if (success == 2) return true;
        return false;
    }

    function updateFinalRoundWinners() external onlyOwner {
        onlyPhase(Phase.UPDATING_RESULT);
        onlyRound(Round.FINAL);
        uint256 amountWinners;
        bool result = _resultOracle.getFinalRoundResult();
        for (uint256 i = 1; i < _finalRoundParticipants + 1; ) {
            if (_voted[i] && result == _finalRoundSelection[i]) {
                _finalRoundWinners[i] = true;
                amountWinners += 1;
                _isEvenAFinalRoundWinner = true;
            }
            _voted[i] = false;
            unchecked {
                i++;
            }
        }
        _amountFinalRoundWinners = amountWinners;
        actualPhase = Phase.END;
    }

    function isNotWinnerInEighthsRound() private view returns (bool) {
        // phase, there does not have to be a winner yet, it has to be after 11/07 23:59
        if (
            !_isEvenAEighthsRoundWinner &&
            block.timestamp > lowerBoundEighthNoWinnerRedistribute
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isNotWinnerInFourthRound() private view returns (bool) {
        // phase, there does not have to be a winner yet, it has to be after 15/08 23:59
        if (
            _isEvenAFourthRoundWinner == false &&
            block.timestamp > lowerBoundFourthNoWinnerRedistribute
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isNotWinnerInSemifinalRound() private view returns (bool) {
        // phase, there does not have to be a winner yet, it has to be after 12/09 23:59
        if (
            _isEvenASemifinalRoundWinner == false &&
            block.timestamp > lowerBoundSemifinalNoWinnerRedistribute
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isNotWinnerInFinalRound() private view returns (bool) {
        // phase, there does not have to be a winner yet, it has to be after 04/11 23:59
        if (
            _isEvenAFinalRoundWinner == false &&
            block.timestamp > lowerBoundFinalNoWinnerRedistribute
        ) {
            return true;
        } else {
            return false;
        }
    }

    function devTeamReceiveFunds() external onlyOwner {
        if (actualRound == Round.EIGHTHS) {
            revert("Is eighths!!");
        }
        uint256 amount;
        if (_devsCharged == 0) {
            amount += (getEighthsPoolPrize() * 10) / 100;
        } else if (_devsCharged == 1 && actualRound != Round.FOURTH) {
            amount += (getFourthPoolPrize() * 10) / 100;
        } else if (_devsCharged == 2 && actualRound != Round.SEMIFINAL) {
            amount += (getSemifinalPoolPrize() * 10) / 100;
        } else if (_devsCharged == 3 && actualPhase == Phase.END) {
            amount += (getFinalPoolPrize() * 10) / 100;
        }
        _devsCharged = _devsCharged + 1;

        require(_stablecoinToken.transfer(owner(), amount), "revert transfer");
        emit Claimed(owner(), amount);
    }

    function getDevsCharged() external view returns (uint8) {
        return _devsCharged;
    }

    function onlyPhase(Phase expected) private view {
        require(
            actualPhase == expected,
            "you can not perform this action in this phase"
        );
    }

    function onlyRound(Round expected) private view {
        require(actualRound == expected);
    }

    event Claimed(address claimer, uint256 amount);
    event Voted(address voter, Round round);
    event Minted(address minter, Round round, uint256 nftId);
}