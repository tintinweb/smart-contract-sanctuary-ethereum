/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.6.12;

contract HashBet is Ownable, ReentrancyGuard {
    // Modulo is the number of equiprobable outcomes in a game:
    //  2 for coin flip
    //  6 for dice roll
    //  6*6 = 36 for double dice
    //  37 for roulette
    //  100 for polyroll
    uint constant MAX_MODULO = 100;

    // Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes. 
    // For example in a dice roll (modolo = 6), 
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint constant MAX_MASK_MODULO = 40;
    
    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions dice2.win croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

     // This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // These are constants taht make O(1) population count in placeBet possible.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    // Sum of all historical deposits and withdrawals. Used for calculating profitability. Profit = Balance - cumulativeDeposit + cumulativeWithdrawal
    uint public cumulativeDeposit;
    uint public cumulativeWithdrawal;

    // In addition to house edge, wealth tax is added every time the bet amount exceeds a multiple of a threshold.
    // For example, if wealthTaxIncrementThreshold = 3000 ether,
    // A bet amount of 3000 ether will have a wealth tax of 1% in addition to house edge.
    // A bet amount of 6000 ether will have a wealth tax of 2% in addition to house edge.
    uint public wealthTaxIncrementThreshold = 3000 ether;
    uint public wealthTaxIncrementPercent = 1;

    // The minimum and maximum bets.
    uint public minBetAmount = 0.01 ether;
    uint public maxBetAmount = 10000 ether;

    // max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit = 300000 ether;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollEdge),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollEdge;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
        // Random number used to settle bet.
        uint randomNumber;
        // Keccak256 hash of some secret "reveal" random number.
        uint commit;
        // Comparation method.
        bool method;
    }
    
    // Each bet is deducted dynamic
    uint public houseEdgePercent = 1;

    // Mapping from commits to all currently active & processed bets.
    mapping (uint => Bet) bets;

    // Events
    event BetPlaced(address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollEdge, uint40 mask, uint commit);
    event BetSettled(address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollEdge, uint40 mask, uint outcome, uint winAmount);
    event BetRefunded(address indexed gambler, uint amount);

    // Fallback payable function used to top up the bank roll.
    fallback() external payable {
        cumulativeDeposit += msg.value;
    }
    receive() external payable {
        cumulativeDeposit += msg.value;
    }

    // See ETH balance.
    function balance() external view returns (uint) {
        return address(this).balance;
    }
    
    // Set min house edge percent
    function setHouseEdgePercent(uint _houseEdgePercent) external onlyOwner {
        require ( _houseEdgePercent >= 1 && _houseEdgePercent <= 100, "houseEdgePercent must be a sane number");
        houseEdgePercent = _houseEdgePercent;
    }

    // Set min bet amount. minBetAmount should be large enough such that its house edge fee can cover the Chainlink oracle fee.
    function setMinBetAmount(uint _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount * 1 gwei;
    }

    // Set max bet amount.
    function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
        require (_maxBetAmount < 5000000 ether, "maxBetAmount must be a sane number");
        maxBetAmount = _maxBetAmount;
    }

    // Set max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint _maxProfit) external onlyOwner {
        require (_maxProfit < 50000000 ether, "maxProfit must be a sane number");
        maxProfit = _maxProfit;
    }

    // Set wealth tax percentage to be added to house edge percent. Setting this to zero effectively disables wealth tax.
    function setWealthTaxIncrementPercent(uint _wealthTaxIncrementPercent) external onlyOwner {
        wealthTaxIncrementPercent = _wealthTaxIncrementPercent;
    }

    // Set threshold to trigger wealth tax.
    function setWealthTaxIncrementThreshold(uint _wealthTaxIncrementThreshold) external onlyOwner {
        wealthTaxIncrementThreshold = _wealthTaxIncrementThreshold;
    }

    // Owner can withdraw funds not exceeding balance minus potential win prizes by open bets
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Withdrawal amount larger than balance.");
        require (withdrawAmount <= address(this).balance - lockedInBets, "Withdrawal amount larger than balance minus lockedInBets");
        beneficiary.transfer(withdrawAmount);
        cumulativeWithdrawal += withdrawAmount;
    }

    function emitBetPlacedEvent(address gambler, uint amount, uint8 modulo, uint8 rollEdge, uint40 mask, uint commit) private
    {
        // Record bet in event logs
        emit BetPlaced(gambler, amount, uint8(modulo), uint8(rollEdge), uint40(mask), commit);
    }

    // Place bet
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bool method, bytes32 r, bytes32 s) external payable nonReentrant {

        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");
        // Validate input data.
        uint amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (amount >= minBetAmount && amount <= maxBetAmount, "Bet amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");
        
        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        require (owner() == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        uint rollEdge;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games can specify exact bet outcomes via bit mask.
            // rollEdge is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. 
            rollEdge = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollEdge = betMask;
        }

        // Winning amount.
        uint possibleWinAmount = getDiceWinAmount(amount, modulo, rollEdge, method);

        // Enforce max profit limit. Bet will not be placed if condition is not met.
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

        // Check whether contract has enough funds to accept this bet.
        require (lockedInBets + possibleWinAmount <= address(this).balance, "Unable to accept bet due to insufficient funds");

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        // Store bet
        bet.amount=amount;
        bet.modulo=uint8(modulo);
        bet.rollEdge=uint8(rollEdge);
        bet.mask=uint40(mask);
        bet.placeBlockNumber=block.number;
        bet.gambler=payable(msg.sender);
        bet.isSettled=false;
        bet.outcome=0;
        bet.winAmount=0;
        bet.randomNumber=0;
        bet.commit=commit;
        bet.method=method;

        // Record bet in event logs
        emitBetPlacedEvent(bet.gambler, amount, uint8(modulo), uint8(rollEdge), uint40(mask), commit);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollEdge, bool method) private view returns (uint winAmount) {
        require (0 < rollEdge && rollEdge <= modulo, "Win probability out of range.");
        uint houseEdge = amount * (houseEdgePercent + getWealthTax(amount)) / 100;
        uint realRollEdge = rollEdge;
        if (modulo == MAX_MODULO && method) {
            realRollEdge = MAX_MODULO - rollEdge;
        }
        winAmount = (amount - houseEdge) * modulo / realRollEdge;
    }

    // Get wealth tax 
    function getWealthTax(uint amount) private view returns (uint wealthTax) {
        wealthTax = amount / wealthTaxIncrementThreshold * wealthTaxIncrementPercent;
    }
    
    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(uint reveal, bytes32 blockHash) external onlyOwner {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number >= placeBlockNumber, "settleBet before placeBet");
        // require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, blockHash);
    }

    // This method is used to settle a bet that was mined into an uncle block. At this
    // point the player was shown some bet outcome, but the blockhash at placeBet height
    // is different because of Ethereum chain reorg. We supply a full merkle proof of the
    // placeBet transaction receipt to provide untamperable evidence that uncle block hash
    // indeed was present on-chain at some point.
    function settleBetUncleMerkleProof(uint reveal, uint40 canonicalBlockNumber) external onlyOwner {
        // "commit" for bet settlement can only be obtained by hashing a "reveal".
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];

        // Check that canonical block hash can still be verified.
        require (block.number <= canonicalBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

        // Verify placeBet receipt.
        requireCorrectReceipt(4 + 32 + 32 + 4);

        // Reconstruct canonical & uncle block hashes from a receipt merkle proof, verify them.
        bytes32 canonicalHash;
        bytes32 uncleHash;
        (canonicalHash, uncleHash) = verifyMerkleProof(commit, 4 + 32 + 32);
        require (blockhash(canonicalBlockNumber) == canonicalHash);

        // Settle bet using reveal and uncleHash as entropy sources.
        settleBetCommon(bet, reveal, uncleHash);
    }

    // Common settlement code for settleBet & settleBetUncleMerkleProof.
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        
        // Validation check
        require (amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        bool method = bet.method;
        
        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint outcome = uint(entropy) % modulo;

        // Win amount if gambler wins this bet
        uint possibleWinAmount = getDiceWinAmount(amount, modulo, rollEdge, method);

        // Actual win amount by gambler
        uint winAmount = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (method){
                if (outcome > rollEdge) {
                    winAmount = possibleWinAmount;
                }
            }
            else{
                if (outcome < rollEdge) {
                    winAmount = possibleWinAmount;
                }
            }
            
        }
        
        emitSettledEvent(bet, outcome, winAmount);

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.randomNumber = uint(entropy);
        bet.outcome = outcome;

        // Send win amount to gambler.
        if (winAmount > 0) {
            gambler.transfer(winAmount);
        }
    }

    function emitSettledEvent(Bet storage bet, uint outcome, uint winAmount) private
    {
        uint amount = bet.amount;
        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        // Record bet settlement in event log.
        emit BetSettled(gambler, amount, uint8(modulo), uint8(rollEdge), bet.mask, outcome, winAmount);
    }

    // Return the bet in extremely unlikely scenario it was not settled by Chainlink VRF. 
    // In case you ever find yourself in a situation like this, just contact Polyroll support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(uint commit) external nonReentrant payable {
        
        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        bool method = bet.method;

        // Validation check
        require (amount > 0, "Bet does not exist."); // Check that bet exists
        require (bet.isSettled == false, "Bet is settled already."); // Check that bet is still open
        require (block.number > bet.placeBlockNumber + 43200, "Wait after placing bet before requesting refund.");

        uint possibleWinAmount = getDiceWinAmount(amount, bet.modulo, bet.rollEdge, method);

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(bet.gambler, amount);
    }

    // This helpers are used to verify cryptographic proofs of placeBet inclusion into
    // uncle blocks. They are used to prevent bet outcome changing on Ethereum reorgs without
    // compromising the security of the smart contract. Proof data is appended to the input data
    // in a simple prefix length format and does not adhere to the ABI.
    // Invariants checked:
    //  - receipt trie entry contains a (1) successful transaction (2) directed at this smart
    //    contract (3) containing commit as a payload.
    //  - receipt trie entry is a part of a valid merkle proof of a block header
    //  - the block header is a part of uncle list of some block on canonical chain
    // The implementation is optimized for gas cost and relies on the specifics of Ethereum internal data structures.
    // Read the whitepaper for details.

    // Helper to verify a full merkle proof starting from some seedHash (usually commit). "offset" is the location of the proof
    // beginning in the calldata.
    function verifyMerkleProof(uint seedHash, uint offset) pure private returns (bytes32 blockHash, bytes32 uncleHash) {
        // (Safe) assumption - nobody will write into RAM during this method invocation.
        uint scratchBuf1;  assembly { scratchBuf1 := mload(0x40) }

        uint uncleHeaderLength; uint blobLength; uint shift; uint hashSlot;

        // Verify merkle proofs up to uncle block header. Calldata layout is:
        //  - 2 byte big-endian slice length
        //  - 2 byte big-endian offset to the beginning of previous slice hash within the current slice (should be zeroed)
        //  - followed by the current slice verbatim
        for (;; offset += blobLength) {
            assembly { blobLength := and(calldataload(sub(offset, 30)), 0xffff) }
            if (blobLength == 0) {
                // Zero slice length marks the end of uncle proof.
                break;
            }

            assembly { shift := and(calldataload(sub(offset, 28)), 0xffff) }
            require (shift + 32 <= blobLength, "Shift bounds check.");

            offset += 4;
            assembly { hashSlot := calldataload(add(offset, shift)) }
            require (hashSlot == 0, "Non-empty hash slot.");

            assembly {
                calldatacopy(scratchBuf1, offset, blobLength)
                mstore(add(scratchBuf1, shift), seedHash)
                seedHash := keccak256(scratchBuf1, blobLength)
                uncleHeaderLength := blobLength
            }
        }

        // At this moment the uncle hash is known.
        uncleHash = bytes32(seedHash);

        // Construct the uncle list of a canonical block.
        uint scratchBuf2 = scratchBuf1 + uncleHeaderLength;
        uint unclesLength; assembly { unclesLength := and(calldataload(sub(offset, 28)), 0xffff) }
        uint unclesShift;  assembly { unclesShift := and(calldataload(sub(offset, 26)), 0xffff) }
        require (unclesShift + uncleHeaderLength <= unclesLength, "Shift bounds check.");

        offset += 6;
        assembly { calldatacopy(scratchBuf2, offset, unclesLength) }
        memcpy(scratchBuf2 + unclesShift, scratchBuf1, uncleHeaderLength);

        assembly { seedHash := keccak256(scratchBuf2, unclesLength) }

        offset += unclesLength;

        // Verify the canonical block header using the computed sha3Uncles.
        assembly {
            blobLength := and(calldataload(sub(offset, 30)), 0xffff)
            shift := and(calldataload(sub(offset, 28)), 0xffff)
        }
        require (shift + 32 <= blobLength, "Shift bounds check.");

        offset += 4;
        assembly { hashSlot := calldataload(add(offset, shift)) }
        require (hashSlot == 0, "Non-empty hash slot.");

        assembly {
            calldatacopy(scratchBuf1, offset, blobLength)
            mstore(add(scratchBuf1, shift), seedHash)

            // At this moment the canonical block hash is known.
            blockHash := keccak256(scratchBuf1, blobLength)
        }
    }


    // Helper to check the placeBet receipt. "offset" is the location of the proof beginning in the calldata.
    // RLP layout: [triePath, str([status, cumGasUsed, bloomFilter, [[address, [topics], data]])]
    function requireCorrectReceipt(uint offset) view private {
        uint leafHeaderByte; assembly { leafHeaderByte := byte(0, calldataload(offset)) }

        require (leafHeaderByte >= 0xf7, "Receipt leaf longer than 55 bytes.");
        offset += leafHeaderByte - 0xf6;

        uint pathHeaderByte; assembly { pathHeaderByte := byte(0, calldataload(offset)) }

        if (pathHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (pathHeaderByte >= 0x80 && pathHeaderByte <= 0xb7, "Path is an RLP string.");
            offset += pathHeaderByte - 0x7f;
        }

        uint receiptStringHeaderByte; assembly { receiptStringHeaderByte := byte(0, calldataload(offset)) }
        require (receiptStringHeaderByte == 0xb9, "Receipt string is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint receiptHeaderByte; assembly { receiptHeaderByte := byte(0, calldataload(offset)) }
        require (receiptHeaderByte == 0xf9, "Receipt is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint statusByte; assembly { statusByte := byte(0, calldataload(offset)) }
        require (statusByte == 0x1, "Status should be success.");
        offset += 1;

        uint cumGasHeaderByte; assembly { cumGasHeaderByte := byte(0, calldataload(offset)) }
        if (cumGasHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (cumGasHeaderByte >= 0x80 && cumGasHeaderByte <= 0xb7, "Cumulative gas is an RLP string.");
            offset += cumGasHeaderByte - 0x7f;
        }

        uint bloomHeaderByte; assembly { bloomHeaderByte := byte(0, calldataload(offset)) }
        require (bloomHeaderByte == 0xb9, "Bloom filter is always 256 bytes long.");
        offset += 256 + 3;

        uint logsListHeaderByte; assembly { logsListHeaderByte := byte(0, calldataload(offset)) }
        require (logsListHeaderByte == 0xf8, "Logs list is less than 256 bytes long.");
        offset += 2;

        uint logEntryHeaderByte; assembly { logEntryHeaderByte := byte(0, calldataload(offset)) }
        require (logEntryHeaderByte == 0xf8, "Log entry is less than 256 bytes long.");
        offset += 2;

        uint addressHeaderByte; assembly { addressHeaderByte := byte(0, calldataload(offset)) }
        require (addressHeaderByte == 0x94, "Address is 20 bytes long.");

        uint logAddress; assembly { logAddress := and(calldataload(sub(offset, 11)), 0xffffffffffffffffffffffffffffffffffffffff) }
        require (logAddress == uint(address(this)));
    }

    // Memory copy.
    function memcpy(uint dest, uint src, uint len) pure private {
        // Full 32 byte words
        for(; len >= 32; len -= 32) {
            assembly { mstore(dest, mload(src)) }
            dest += 32; src += 32;
        }

        // Remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(payable(owner()));
    }
}