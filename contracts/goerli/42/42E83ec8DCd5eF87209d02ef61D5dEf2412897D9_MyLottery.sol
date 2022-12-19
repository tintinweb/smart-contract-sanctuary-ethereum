// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// import "./lottoGratuity.sol";
import "./lotto.sol";
import "./lottoDAO.sol";

contract MyLottery is LottoDAO {
    constructor() Lotto(5) LottoDAO("Lottery Reward Token", "LRT", 2, 10) {
        _addBeneficiary(_msgSender(), 10);
    }

    function currentBlock() public view returns (uint256) {
        return block.number;
    }

    /**
     * @dev Pays out the contract balance to the winner of the current round.
     */
    function payoutAndRestart() public {
        // Get the contract balance
        uint256 pot = address(this).balance;

        // Revert if the contract balance is less than 1000
        require(pot >= 1000, "pot has to be >= 1000");

        // Revert if the current block number is not greater than the ending block number
        require(block.number > endingBlock(), "round not over yet");

        // Revert if the round has already been paid out
        require(!paid(), "already paid out");

        // Pay out the contract balance to the winner of the current round
        _payout(pot);

        _start();
    }
}

/**

MINT TOKENS TO PEOPLE RESTARTING CONTRACT
ADD UNCHECKED OR OTHER THINGS TO ACCUMULATED ETHER
 */

/**
 * The LottoDAO contract is a decentralized autonomous organization (DAO) that handles a lottery
 * game. It is based on the LottoGratuity contract, which is an abstract contract that handles the
 * distribution of winnings to beneficiaries. The LottoDAO contract also includes a
 * LottoRewardsToken contract, which is an ERC20 token that allows users to start staking and
 * receive rewards.
 *
 * The LottoDAO contract has several functions that allow users to interact with the contract. The
 * startStaking() function allows users to start staking their tokens and receive rewards. The
 * withdrawFees() function allows users to withdraw any accumulated fees they have earned through
 * the DAO. The _logWinningPlayer() function records the winner, winnings, and block number in the
 * winning history array.
 *
 * The LottoDAO contract also has two private functions that are used to calculate the accumulated
 * ether for a user. The _accumulatedEtherLinear() function uses a linear search to find the
 * accumulated ether for a user, while the _accumulatedEtherBinary() function uses a binary search
 * to find the accumulated ether for a user. Both functions take in an address as a parameter and
 * return the accumulated ether as a uint256 value.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lottoGratuity.sol";
import "./ERC80085.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LottoRewardsToken is ERC80085, Ownable {
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC20Permit(name) {} // solhint-disable-line no-empty-blocks

    receive() external payable onlyOwner {} // solhint-disable-line no-empty-blocks

    function startStaking() public {
        _startStaking(_msgSender());
    }

    function startStaking(address account) public onlyOwner {
        _startStaking(account);
    }

    function transferEth(address to, uint256 amount) public onlyOwner {
        _transferEth(to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

abstract contract LottoDAO is LottoGratuity {
    using Math for uint256;

    // will handle each lotto win
    struct WinningInfoDAO {
        address winner;
        uint256 winningAmount;
        uint256 blockNumber;
        uint256 feeAmount;
        uint256 totalStakedSupply;
    }

    WinningInfoDAO[] private _winningHistory;

    LottoRewardsToken public lottoRewardsToken;

    uint256 private _daoGratuity;
    uint256 private _lastPot;

    uint256 private _rewardsPerBlock;

    /**
     * @dev Constructor for the LottoGratuity contract. Initializes the LottoRewardsToken contract,
     * sets the rewards per block and DAO gratuity, and allows the caller to start staking tokens.
     * @param maxBeneficiaries The maximum number of beneficiaries allowed for the contract.
     * @param daoGratuity_ The percentage of winnings that go to the DAO gratuity * 1000
     */
    constructor(
        string memory rewardTokenName_,
        string memory rewardTokenSymbol_,
        uint8 maxBeneficiaries,
        uint256 daoGratuity_
    ) LottoGratuity(maxBeneficiaries, _msgSender(), 0) {
        lottoRewardsToken = new LottoRewardsToken(
            rewardTokenName_,
            rewardTokenSymbol_
        );
        _rewardsPerBlock = 21e18;
        _daoGratuity = daoGratuity_;
        _swapBeneficiary(0, address(lottoRewardsToken), daoGratuity_);
        lottoRewardsToken.mint(_msgSender(), 1);
        startStaking();
    }

    /**
     * @dev Allows the caller to start staking tokens.
     */
    function startStaking() public {
        lottoRewardsToken.startStaking(_msgSender());
    }

    /**
     * @dev Withdraws accumulated fees for the caller, using either a linear search or binary
     * search depending on the length of the caller's transfer history.
     */
    function withdrawFees() public {
        address account = _msgSender();
        uint256 len = lottoRewardsToken
            .holderData(account)
            .transferSnaps
            .length;
        if (len < 19) {
            lottoRewardsToken.transferEth(
                account,
                _accumulatedEtherLinear(account) -
                    lottoRewardsToken.holderData(account).rewardsWithdrawn
            );
        } else {
            lottoRewardsToken.transferEth(
                account,
                _accumulatedEtherBinary(account) -
                    lottoRewardsToken.holderData(account).rewardsWithdrawn
            );
        }
    }

    /**
     * @dev Pays out the specified amount to the contract owner and updates the last pot value.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual override {
        _lastPot = amount;
        super._payout(amount);
    }

    /**
     * @dev Records the winner, winnings, and block number in the winning history array.
     * @param account The address of the winning player.
     * @param winnings The amount won by the player.
     */
    function _logWinningPlayer(
        address account,
        uint256 winnings
    ) internal virtual override {
        _winningHistory.push(
            WinningInfoDAO({
                winner: account,
                winningAmount: winnings,
                blockNumber: endingBlock(),
                // feeAmount: (_lastPot * _daoGratuity) / 1000,
                feeAmount: _lastPot.mulDiv(_daoGratuity, 1000),
                totalStakedSupply: lottoRewardsToken.totalStakedSupply()
            })
        );
    }

    /**
     * @notice Rewards the caller with tokens based on the number of blocks that have passed since
     * the last reward was issued.
     * @dev Rewards per block decrease by 0.1% every block.
     */
    function _start() internal virtual override {
        super._start();

        uint256 blockDif = block.number -
            _winningHistory[_winningHistory.length - 1].blockNumber;

        uint256 tokensToReward = 0;
        uint256 tmpRewardsPerBlock = _rewardsPerBlock;

        for (uint256 i = 0; i < blockDif; ++i) {
            tokensToReward += tmpRewardsPerBlock;
            tmpRewardsPerBlock = tmpRewardsPerBlock.mulDiv(
                999,
                1000,
                Math.Rounding.Up
            );
        }

        _rewardsPerBlock = tmpRewardsPerBlock;
        lottoRewardsToken.mint(_msgSender(), tokensToReward);
    }

    /// @notice Calculates the accumulated ether of a given account using binary search
    /// @param account Address of the account to check
    /// @return eth Accumulated ether of the given account
    function _accumulatedEtherBinary(
        address account
    ) private view returns (uint eth) {
        // get person whos accumulated ether we're checking
        ERC80085.Snapshot[] memory array1 = lottoRewardsToken
            .holderData(account)
            .transferSnaps;

        // get array of winning information
        WinningInfoDAO[] memory array2 = _winningHistory;

        // loop through each value in array2
        for (uint i = 0; i < array2.length; i++) {
            // initialize low and high indices for binary search in array1
            uint low = 0;
            uint high = array1.length - 1;

            // binary search for closest but not greater value in array1
            while (low <= high) {
                uint mid = (low + high) / 2;
                // check if value at mid is equal to current value in array2
                if (array1[mid].blockNumber == array2[i].blockNumber) {
                    // exact match found
                    // add value to eth
                    eth += array2[i].feeAmount.mulDiv(
                        array1[mid].snapBalance,
                        array2[i].totalStakedSupply
                    );
                    // exit loop
                    break;
                } else if (array1[mid].blockNumber > array2[i].blockNumber) {
                    // value at mid is greater than current value in array2
                    // search left of mid
                    high = mid - 1;
                } else {
                    // value at mid is lesser than current value in array2
                    // search right of mid
                    low = mid + 1;
                }
            }
            // check if closest but not greater value was not found
            if (low > high) {
                // check if value is not between first and last values in array1
                if (low != 0 || high != array1.length - 1) {
                    // check if value is after last value in array1
                    if (high == array1.length - 1) {
                        // use last value in array1 as closest but not greater value
                        eth += array2[i].feeAmount.mulDiv(
                            array1[high].snapBalance,
                            array2[i].totalStakedSupply
                        );
                    } else if (low != 0) {
                        // value is between first and last values in array1
                        // find value with smallest difference
                        if (
                            array2[i].blockNumber - array1[high].blockNumber <
                            array1[low].blockNumber - array2[i].blockNumber
                        ) {
                            // use value before current value in array1 as closest but not greater
                            // value
                            eth += array2[i].feeAmount.mulDiv(
                                array1[high].snapBalance,
                                array2[i].totalStakedSupply
                            );
                        } else {
                            // use value after current value in array1 as closest but not greater
                            // value
                            eth += array2[i].feeAmount.mulDiv(
                                array1[low].snapBalance,
                                array2[i].totalStakedSupply
                            );
                        }
                    }
                }
            }
        }
    }

    /// @notice Calculates the accumulated ether of a given account using a linear search
    /// @param account Address of the account to check
    /// @return eth Accumulated ether of the given account
    function _accumulatedEtherLinear(
        address account // address of the account to check
    ) private view returns (uint eth) {
        // returns the accumulated ether of the account
        // get the transfer snapshot data for the given account
        ERC80085.Snapshot[] memory array1 = lottoRewardsToken
            .holderData(account)
            .transferSnaps;

        // get the winning history data for the contract
        WinningInfoDAO[] memory array2 = _winningHistory;

        // initialize loop variables
        uint i = 0;
        uint j = 0;

        // loop through both arrays simultaneously
        while (i < array1.length && j < array2.length) {
            // if the block numbers are the same
            if (array1[i].blockNumber == array2[j].blockNumber) {
                // increment the accumulated ether by the fee amount multiplied by the snap balance
                // of the account and divided by the total staked supply
                eth += array2[j].feeAmount.mulDiv(
                    array1[i].snapBalance,
                    array2[j].totalStakedSupply
                );
                // move to the next block in both arrays
                i++;
                j++;
            }
            // if the block number in "array1" is greater than the block number in "array2"
            else if (array1[i].blockNumber > array2[j].blockNumber) {
                // if this is not the first block in "array1"
                if (i != 0) {
                    // check which snap balance has a smaller difference in block numbers
                    if (
                        array2[j].blockNumber - array1[i - 1].blockNumber <
                        array1[i].blockNumber - array2[j].blockNumber
                    ) {
                        // increment the accumulated ether by the fee amount multiplied by the snap
                        // balance of the previous block in "array1" and divided by the total
                        // staked supply
                        eth += array2[j].feeAmount.mulDiv(
                            array1[i - 1].snapBalance,
                            array2[j].totalStakedSupply
                        );
                    }
                    // if the current block in "array1" has a smaller difference in block numbers
                    else {
                        // increment the accumulated ether by the fee amount multiplied by the snap
                        // balance of the current lock in "array1" and divided by the total staked
                        // supply
                        eth += array2[j].feeAmount.mulDiv(
                            array1[i].snapBalance,
                            array2[j].totalStakedSupply
                        );
                    }
                }
                // move to the next block in "array2"
                j++;
            }
            // if the block number in "array2" is greater than the block number in "array1"
            else {
                // move to the next block in "array1"
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./lottoTickets.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// TODO
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// add comments
/// subtract before sending funds
/// see if loop runs out of gas
/// make sure ALL eth gets sent
/// is setting `bHash` worth it?

/**
 * @title Lotto
 * @dev Lotto contract that allows users to purchase tickets and participate in a lottery.
 * The contract has a fixed duration, after which a winner is chosen and the contract balance
 * is paid out to the winner.
 */

contract Lotto is LottoTickets, Context {
    // will handle each lotto win
    struct WinningInfo {
        address winner;
        uint256 winningAmount;
    }

    // the block the lottery will be ending on
    uint256 private _endingBlock;

    // has the winner been paid out?
    bool private _paid;

    // how long the lottery should last
    uint256 private _blocksToWait;

    address private _lastWinner;

    WinningInfo[] private _winningHistory;

    event Payout(address account, uint256 amount);

    /// @notice sets up lottery configuration
    /// @dev starts lottery technically immediately except `_paid` is false not true
    /// @param blocksToWait_ how long the lotto should last
    constructor(uint256 blocksToWait_) {
        _blocksToWait = blocksToWait_;
        _endingBlock = block.number + blocksToWait_;
        // _paid = true;
    }

    /// @notice buys tickets
    /// @dev where 1 = 1 wei and mints to msg.sender
    function buyTickets() public payable virtual {
        require(block.number <= _endingBlock, "passed deadline");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);
    }

    // /**
    //  * @dev Pays out the contract balance to the winner of the current round.
    //  */
    // function payout() public virtual {
    //     // Get the contract balance
    //     uint256 pot = address(this).balance;

    //     // Revert if the contract balance is less than 1000
    //     require(pot >= 1000, "pot has to be >= 1000");

    //     // Revert if the current block number is not greater than the ending block number
    //     require(block.number > _endingBlock, "round not over yet");

    //     // Revert if the round has already been paid out
    //     require(!_paid, "already paid out");

    //     // Pay out the contract balance to the winner of the current round
    //     _payout(pot);
    // }

    function addTime() public {
        _addTime();
    }

    /// @notice the block the lottery ends on
    function endingBlock() public view returns (uint256) {
        return _endingBlock;
    }

    function paid() public view returns (bool) {
        return _paid;
    }

    function lastWinner() public view returns (address) {
        return _lastWinner;
    }

    /// @dev starts the lottery timer enabling purchases of ticket bundles.
    /// can't start if one is in progress and the last winner has not been paid.
    /// cannot be from a contract - humans only-ish
    function _start() internal virtual {
        require(block.number > _endingBlock, "round not over yet");
        require(_paid, "haven't _paid out yet");

        // since a new round is starting, we do not have a winner yet to be paid
        _paid = false;

        // `_endingblock` is the current block + how many blocks we said earlier
        _endingBlock = block.number + _blocksToWait;
    }

    /// @dev this updates the placeholder winning info for the current nonce and
    /// sets it to... the winning info
    function _logWinningPlayer(
        address account,
        uint256 winnings
    ) internal virtual {
        _winningHistory.push(
            WinningInfo({ winner: account, winningAmount: winnings })
        );
    }

    /**
     * @dev Pays out the specified amount to the winner of the current round.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual {
        // Calculate the winning ticket number
        uint256 winningTicket = _calculateWinningTicket();

        // Get the owner of the winning ticket
        address roundWinner = findTicketOwner(winningTicket);

        // Store the winner in the contract storage
        _lastWinner = roundWinner;

        // Reset the contract state
        _reset();

        // Mark the round as paid out
        _paid = true;

        // Log the winning player and payout amount
        _logWinningPlayer(roundWinner, amount);

        // Transfer the payout amount to the winner
        payable(roundWinner).transfer(amount);

        // Emit the Payout event
        emit Payout(roundWinner, amount);
    }

    /**
     * @dev Adds time to the current round.
     */
    function _addTime() internal virtual {
        require(block.number > _endingBlock, "round not over yet");
        require(!_paid, "already paid out");
        require(currentTicketId() < 1000, "only add time if < 1000 bets");
        _endingBlock = block.number + _blocksToWait;
    }

    /**
     * @dev Calculates the winning ticket number based on the ending block hash, current ticket ID,
     * block timestamp, block base fee, and remaining gas.
     * @return winningTicket The winning ticket number.
     *
     * The winning ticket number is calculated by hashing the packed encoding of the following:
     * - The block hash of the block with the specified `_endingBlock` number.
     * - The current ticket ID, which is the total number of tickets that have been sold so far.
     * - The block timestamp of the current block.
     * - The block base fee of the current block.
     * - The remaining gas available in the current block.
     *
     * The resulting hash is then converted to a uint256 and reduced modulo the current ticket ID
     * to obtain a number in the range [0, current ticket ID).
     */
    function _calculateWinningTicket()
        internal
        view
        virtual
        returns (uint256 winningTicket)
    {
        // Get the block hash for the ending block
        bytes32 bHash = blockhash(_endingBlock);

        // Revert if the block hash is 0
        require(bHash != 0, "wait a few confirmations");

        // Hash the packed encoding of the block hash, current ticket ID, block timestamp, block
        // base fee, and remaining gas
        winningTicket =
            uint256(
                keccak256(
                    abi.encodePacked(
                        bHash,
                        currentTicketId(),
                        block.timestamp, // solhint-disable-line not-rely-on-time
                        block.basefee,
                        gasleft()
                    )
                )
            ) %
            currentTicketId();
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title A "special" ERC20 rewards token
/// @author Dr. Doofenshmirtz
/// @notice Withdraw Ethereum fee earnings through holding this token!
/// @dev Tokens are earned by helping (re)start the lottery after the previous
/// one ends. Token holders are rewarded with fees taken from lottery winners
/// and may withdraw Ethereum relative to their % makeup of the total supply.
/// TODO
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// add comments
/// subtract before sending funds
/// see if loop runs out of gas
/// make sure ALL eth gets sent
/// is setting `fromBalance` variable worth it

abstract contract ERC80085 is ERC20, ERC20Permit {
    // logs each token transaction to help calculate withdrawable eth rewards
    struct Snapshot {
        uint256 blockNumber;
        uint256 snapBalance;
    }

    // keeps track of every token holder's balance and eth already withdrawn
    struct TokenHolder {
        Snapshot[] transferSnaps;
        uint256 rewardsWithdrawn;
        uint256 stakedOnBlock;
        uint256 balance;
    }

    // the total supply of tokens
    uint256 private _totalSupply;

    // the total supply of staked tokens
    uint256 private _totalStakedSupply;

    // a mapping of every token holder for easy lookup
    mapping(address => TokenHolder) private _holders;

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _holders[account].balance;
    }

    function holderData(
        address account
    ) public view virtual returns (TokenHolder memory) {
        return _holders[account];
    }

    /// @dev makes total staked supply accessible from external contracts
    /// @return shows total staked supply of tokens
    function totalStakedSupply() public view virtual returns (uint256) {
        return _totalStakedSupply;
    }

    /// @notice transfer out some eth
    /// @dev this function makes transfering eth accessible to external people
    /// or contracts with `MINTER_ROLE` and will be used for withdrawing rewards
    /// @param to the lucky sole to get some eth
    /// @param amount the amount of eth to send
    function _transferEth(address to, uint256 amount) internal virtual {
        _holders[to].rewardsWithdrawn += amount;
        payable(to).transfer(amount);
    }

    /// @notice enables earning ethereum fee rewards
    /// @param account to enable staking for
    function _startStaking(address account) internal virtual {
        _holders[account].stakedOnBlock = block.number;

        uint256 amount = balanceOf(account);

        _logTokenTransaction(account, amount);

        _totalStakedSupply += amount;
    }

    /// @notice transfers tokens from one person to another
    /// @dev unlike "normal" ERC20 tokens- LT token data is stored in structs.
    /// This makes it possible to create a snapshot of every transaction in
    /// order to calculate eth rewards for people who've held coins but not
    /// redeemed in a few rounds, or even transferred their coins before
    /// withdrawing
    /// @param from person who's transferring these tokens
    /// @param to person who's getting these tokens
    /// @param amount the amount of tokens to be sent * 10 ** -18
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "send amount exceeds balance");
        unchecked {
            _logTokenTransaction(from, fromBalance - amount);
        }

        _updateStakedSupply(from, to, amount);

        _logTokenTransaction(to, balanceOf(to) + amount);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /// @notice mints a certain amount of tokens to someone
    /// @dev same situation as `_transfer` in that info is stored in structs
    /// @param account person getting tokens minted to
    /// @param amount of tokens being minted * 10 ** -18
    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _updateStakedSupply(address(0), account, amount);

        _logTokenTransaction(account, balanceOf(account) + amount);

        // _logTokenTransaction(account);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _updateWithdrawals(address account, uint256 amount) internal {
        unchecked {
            _holders[account].rewardsWithdrawn += amount;
        }
    }

    /// @notice logs each token transaction
    /// @dev thought it'd be prettier to make a function instead of writing this
    /// out for both `_transfer` and `_mint`. This takes a snapshot of the block
    /// number and new balance for posterity and calculating eth rewards
    /// @param account the person we are logging the transaction for
    function _logTokenTransaction(address account, uint256 amount) private {
        if (_holders[account].stakedOnBlock > 0) {
            _holders[account].transferSnaps.push(
                Snapshot({ blockNumber: block.number, snapBalance: amount })
            );
        }
        _holders[account].balance = amount;
    }

    /// @notice adjusts `_totalStakedSupply` according to whether tokens are
    /// being transferred to or from an account that has staking enabled
    /// @dev if `from` is enabled and `to` isn't, remove tokens from staked
    /// supply. if `from` isn't enabled and `to` is, add tokens from staked
    /// supply. in any other case, staked supply stays the same.
    /// @param from whom the tokens are being sent
    /// @param to whom the tokens are being sent
    /// @param amount of tokens * 10 ** -18 to be sent
    function _updateStakedSupply(
        address from,
        address to,
        uint256 amount
    ) private {
        if (_holders[from].stakedOnBlock > 0) {
            if (_holders[to].stakedOnBlock == 0) {
                unchecked {
                    _totalStakedSupply -= amount;
                }
            }
        } else {
            if (_holders[to].stakedOnBlock > 0) {
                _totalStakedSupply += amount;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lotto.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LottoGratuity
 * @dev A lotto contract that allows the creator to specify a number of beneficiaries who will
 * receive a percentage of the winnings as gratuity.
 */

abstract contract LottoGratuity is Lotto {
    using Math for uint256;

    // Struct representing a beneficiary.
    struct Beneficiary {
        address beneficiary;
        uint256 gratuity; //The gratuity percentage for the beneficiary * 1000
    }

    uint256 private _gratuitiesSum;

    uint8 private _maxBeneficiaries;

    Beneficiary[] private _beneficiaries;

    /**
     * @dev Constructor for the contract.
     * @param maxBeneficiaries_ The maximum number of beneficiaries allowed.
     * @param beneficiary The first beneficiary to be added.
     * @param gratuity The gratuity percentage for the first beneficiary.
     */
    constructor(
        uint8 maxBeneficiaries_,
        address beneficiary,
        uint256 gratuity
    ) {
        require(maxBeneficiaries_ > 0, "need to be more than 1 bene");
        _maxBeneficiaries = maxBeneficiaries_;
        if (beneficiary != address(0)) {
            _addBeneficiary(beneficiary, gratuity);
        }
    }

    /**
     * @notice Swaps the beneficiary for a given beneficiary number.
     * @param beneficiaryNumber The number of the beneficiary to swap.
     * @param beneficiary The new beneficiary address.
     * @param gratuity The gratuity to be paid to the new beneficiary.
     */
    function swapBeneficiary(
        uint256 beneficiaryNumber,
        address beneficiary,
        uint256 gratuity
    ) public virtual {
        _swapBeneficiary(beneficiaryNumber, beneficiary, gratuity);
    }

    function beneficiaryGratuity() public view returns (Beneficiary[] memory) {
        return _beneficiaries;
    }

    function beneficiarySpotsLeft() public view returns (uint256) {
        return _maxBeneficiaries;
    }

    /**
     * @notice Add a beneficiary to the contract
     * @param beneficiary The address of the beneficiary to be added
     * @param gratuity The amount of gratuity to be given to the beneficiary
     * @dev This function adds a beneficiary to the contract and updates the gratuity sum. It will
     * revert if the maximum number of beneficiaries has already been reached or if the gratuity
     * sum would exceed 1000.
     */
    function _addBeneficiary(
        address beneficiary,
        uint256 gratuity
    ) internal virtual {
        require(_maxBeneficiaries != 0, "max beneficiaries added");
        require(beneficiary != address(0), "cant be 0 address");
        uint256 tmpGratutiesSum = _gratuitiesSum + gratuity;
        require(tmpGratutiesSum < 1000, "gratuity too great");
        _gratuitiesSum = tmpGratutiesSum;
        _maxBeneficiaries--;

        _beneficiaries.push(
            Beneficiary({ beneficiary: beneficiary, gratuity: gratuity })
        );
    }

    /**
     * @notice Swaps the beneficiary for a given beneficiary number.
     * @param beneficiaryNumber The number of the beneficiary to swap.
     * @param beneficiary The new beneficiary address.
     * @param gratuity The gratuity to be paid to the new beneficiary.
     * @dev This function swaps the beneficiary for a given beneficiary number. It requires that
     * the caller is the current beneficiary, and that the new beneficiary is not the zero address.
     * It also requires that the sum of the gratuities does not exceed 1000.
     */
    function _swapBeneficiary(
        uint256 beneficiaryNumber,
        address beneficiary,
        uint256 gratuity
    ) internal virtual {
        Beneficiary memory tmpBene = beneficiaryGratuity()[beneficiaryNumber];
        require(tmpBene.beneficiary == _msgSender(), "only current can swap");
        require(beneficiary != address(0), "must not be 0 address");
        uint256 tmpGratuitiesSum = _gratuitiesSum - tmpBene.gratuity + gratuity;
        require(tmpGratuitiesSum < 1000, "sum of gratuities is >= 1000");
        _gratuitiesSum = tmpGratuitiesSum;
        _beneficiaries[beneficiaryNumber].beneficiary = beneficiary;
        _beneficiaries[beneficiaryNumber].gratuity = gratuity;
    }

    /**
     * @dev Pays out a given amount to the beneficiaries based on their gratuity percentage.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual override {
        Beneficiary[] memory tempBene = _beneficiaries;
        uint256 len = tempBene.length;
        for (uint256 i = 0; i < len; ++i) {
            if (tempBene[i].gratuity > 0) {
                payable(tempBene[i].beneficiary).transfer(
                    amount.mulDiv(tempBene[i].gratuity, 1000)
                );
            }
        }

        super._payout(address(this).balance);
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
pragma solidity ^0.8.16;

/// @title LottoTickets
/// @author The name of the author
/// @notice The contract that will be interacting with the tickets
/// @dev allows the minting of tickets, finding a specific ticket holder's address, and resetting
/// all ticket holdings

/// TODO
/// Interpolation Search?
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// add comments
/// subtract before sending funds
/// see if loop runs out of gas
/// make sure ALL eth gets sent
/// pretty sure "mid - 1" will never underflow for `_findTicketOwner` because
///     mid would have to = 0 which would mean high < low which can't happen
///     because we would have iterated through all numbers by then?

contract LottoTickets {
    // the starting ticket of each bundle purchased
    uint256[] private _bundleFirstTicketNum;

    // checks what bundle was bought by who
    mapping(uint256 => address)[] private _bundleBuyer;

    // what is the next ticket number to be purchased
    uint256 private _currentTicketId;

    // tickets were minted/bought
    event TicketsMinted(address account, uint256 amount);

    /// @dev _bundleBuyer is an array so we can easily delete all maps and thus need to give it a
    /// length of 1 initiallys
    constructor() {
        _bundleBuyer.push();
    }

    /// @return uint256 gets the ticket ID of the next purchaed ticket
    function currentTicketId() public view returns (uint256) {
        return _currentTicketId;
    }

    /// @notice finding ticket number owner
    /// @param ticketId of the ticket who's address we are trying to find
    /// @return address of the person who's ticket we had
    function findTicketOwner(uint256 ticketId) public view returns (address) {
        require(ticketId < _currentTicketId, "ticket ID out of bounds");
        return _findTicketOwner(ticketId);
    }

    /// @notice updates amount of tickets purchased and by who
    /// @dev first initialized a new bundle using `_currentTicketId` and adds it to an array to
    /// help loop through the map. Then changes `_currentTicketId` to take into account the `amount`
    /// that was just minted.
    /// @param to the wallet tickets are to be bought for
    /// @param amount of tickets that are to be bought
    function _mintTickets(address to, uint256 amount) internal {
        _bundleBuyer[0][_currentTicketId] = to;

        _bundleFirstTicketNum.push(_currentTicketId);

        _currentTicketId += amount;

        emit TicketsMinted(to, amount);
    }

    /// @notice deletes all records of tickets and ticket holders
    function _reset() internal virtual {
        delete _bundleBuyer;
        delete _bundleFirstTicketNum;
        _currentTicketId = 0;
        _bundleBuyer.push();
    }

    /// @notice finds ticket number owner
    /// @dev uses binary search (as opposed to linear/jump/interpolation).
    /// "unchecked" as there'd be no way to overflow/underflow/divide by zero (supposedly).
    /// there's a lot of lingo on the "net", but what I've found is that binary search is well worth
    /// it even with only a small array length. I've heard interpolation can be better but I'm not
    /// sure if it would be worth it in solidity because of all the mathematical equations it'd have
    /// to solve- even if it runs fewer times it might be more gas intensive.
    /// @param ticketId of the ticket who's address we are trying to find
    /// @return address of the person who's ticket we had
    function _findTicketOwner(
        uint256 ticketId
    ) internal view returns (address) {
        unchecked {
            uint256 high = _bundleFirstTicketNum.length;
            uint256 len = high;
            uint256 low = 1;
            uint256 mid = (low + high) / 2;
            while (mid < len) {
                if (ticketId > _bundleFirstTicketNum[mid]) {
                    low = mid + 1;
                } else if (ticketId < _bundleFirstTicketNum[mid]) {
                    if (ticketId < _bundleFirstTicketNum[mid - 1]) {
                        high = mid - 1;
                    } else if (ticketId >= _bundleFirstTicketNum[mid - 1]) {
                        return _bundleBuyer[0][_bundleFirstTicketNum[mid - 1]];
                    }
                } else if (ticketId == _bundleFirstTicketNum[mid]) {
                    return _bundleBuyer[0][_bundleFirstTicketNum[mid]];
                }
                mid = (low + high) / 2;
            }
            return _bundleBuyer[0][_bundleFirstTicketNum[len - 1]];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}