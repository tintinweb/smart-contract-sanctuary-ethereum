// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "Clones.sol";
import "EthRaffle.sol";

contract EthRaffleCloneFactory {

    address immutable ethRaffleImplementation;
    address[] public raffleArray;
    address public owner;
    address public  rngesusContract;

    event ethRaffleImplementationEvent(address);
    event newRaffleCreated(address);

    constructor(address _rngesusContract) {

        // set the owner and RNGesus contract address
        owner = msg.sender;
        rngesusContract = _rngesusContract;
        
        // set the address of the implementation contract and emit event
        ethRaffleImplementation = address(new EthRaffle());
        emit ethRaffleImplementationEvent(ethRaffleImplementation);
    }

    // create a new raffle
    function createEthRaffle (
        string memory _raffleName,
        address _raffleCreator,  // will recieve the funds after the winner gets the prize
        uint256 _prizePoolAllocationPercentage,
        EthRaffle.PriceTier[] calldata _priceTiers
    ) public {

        require(owner == msg.sender, "You can't use this function");
        require(_prizePoolAllocationPercentage < 100, "Prize allocation should be less than 100.");
        require(_prizePoolAllocationPercentage >= 50, "Prize Pool allocation should be at least 50.");
        require(rngesusContract != address(0), "You need a RNGesus contract address.");

        // clone the raffle implementation and emit event
        address newEthRaffleAddress = Clones.clone(ethRaffleImplementation);
        raffleArray.push(newEthRaffleAddress);
        emit newRaffleCreated(newEthRaffleAddress);
        
        // initialize the raffle
        EthRaffle(newEthRaffleAddress).initialize(
            _raffleName,
            _raffleCreator,
            _prizePoolAllocationPercentage,
            rngesusContract,
            _priceTiers
        );

    }

    // get array with all raffle addresses
    function getRaffleArray() external view returns (address[] memory) {
        
        return raffleArray;
    
    }

    // set new RNGesus contract address
    function setRngesusContract(address _rngesusContract) public {

        require(owner == msg.sender, "You can't use this function");
    
        rngesusContract = _rngesusContract;

    }

    // withdraw all funds
    function withdrawAll() public {

        require(owner == msg.sender, "You can't use this function");

        payable(msg.sender).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "ReentrancyGuard.sol";
import "Math.sol";

interface IRNGesus {
    function prayToRngesus(uint256 _gweiForFulfillPrayer) external payable returns (uint256);
    function randomNumbers(uint256 _requestId) external view returns (uint256);
}

contract EthRaffle is ReentrancyGuard {

    // check if contract is already initialized
    bool private initialized;

    // contract variables
    string public raffleName;
    address public raffleCreator;
    uint256 public prizePoolAllocationPercentage;
    uint256 public prizePool;
    uint256 public totalTicketsBought;
    address public winner;
    
    // contract address and request id for RNGesus
    address public rngesusContract;
    uint256 public rngesusRequestId;

    // different price tiers when buying multiple tickets
    struct PriceTier {
        uint256 price;
        uint256 amountOfTickets;
    }
    mapping(uint256 => PriceTier) public priceTiers;

    // keep track of how many tickets bought by which address
    struct TicketsBought {
        uint256 currentTicketsBought; // current total amount of tickets bought in the raffle
        address player; // the player's wallet address
    }

    TicketsBought[] public raffleBox;

    // raffle states
    // TICKET_SALE_OPEN     - once the NFT has been trasfered to this contract, players can now join the raffle (buy tickets)
    // WAITING_FOR_PAYOUT   - once the random number has been created, execute the payout function and the winner will get the ETH prize, 
    //                          the remainder will go to the raffleCreator
    // RAFFLE_FINISHED      - the raffle is finished, thank you for playing
    
    enum RAFFLE_STATE {
        TICKET_SALE_OPEN,
        WAITING_FOR_PAYOUT,
        RAFFLE_FINISHED
    }

    // raffleState variable
    RAFFLE_STATE public raffleState;

    // events
    event TicketSale(
        address buyer,
        uint256 amountOfTickets,
        uint256 pricePaid,
        uint256 timestamp
    );

    event Winner(
        address winner,
        uint256 prize
    );

    function initialize(
        string memory _raffleName,
        address _raffleCreator,
        uint256 _prizePoolAllocationPercentage,
        address _rngesusContract,
        PriceTier[] calldata _priceTiers

    ) external nonReentrant {

        // check if contract is already initialized
        require(!initialized, "Contract is already initialized.");
        initialized = true;

        // set the raffle variables
        raffleName = _raffleName;
        raffleCreator = _raffleCreator;
        rngesusContract = _rngesusContract;
        prizePoolAllocationPercentage = _prizePoolAllocationPercentage;

        require(_priceTiers.length > 0, "No price tiers found.");

        // set the ticket price tiers
        for (uint256 i = 0; i < _priceTiers.length; i++) {

            require(_priceTiers[i].amountOfTickets > 0, "Amount of tickets should be more than 0.");

            // create PriceTier and map to priceTiers 
            priceTiers[i] =  PriceTier({
                price: _priceTiers[i].price,
                amountOfTickets: _priceTiers[i].amountOfTickets
            });            

        }

    }

    function addEthToPrizePool() external payable {

        require(msg.sender == raffleCreator, "Only the Raffle Creator can add ETH to the prize pool.");
        prizePool += msg.value;

    }

    function buyTicket(uint256 _priceTier) external payable nonReentrant {

        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "Can't buy tickets anymore.");

        uint256 amountOfTickets = priceTiers[_priceTier].amountOfTickets;
        uint256 ticketsPrice = priceTiers[_priceTier].price;

        require(msg.value == ticketsPrice, "Please pay the correct amount.");

        // create new TicketsBought struct
        TicketsBought memory ticketsBought = TicketsBought({
            player: msg.sender,
            currentTicketsBought: totalTicketsBought + amountOfTickets
        });

        // push TicketsBought struct to raffleBox
        raffleBox.push(ticketsBought);

        // add amountOfTickets to totalTicketsBought
        totalTicketsBought += amountOfTickets;

        // add eth to the prize pool
        prizePool += msg.value / 100 * prizePoolAllocationPercentage;

        emit TicketSale(msg.sender, amountOfTickets, ticketsPrice, block.timestamp);

    }

    function drawWinner(uint256 _gweiForFulfillPrayer) public payable nonReentrant {

        // only the raffle creator can execute this function
        require(msg.sender == raffleCreator, "Only the Raffle Creator can draw the winner.");

        // check if raffle state is TICKET_SALE_OPEN
        require(raffleState == RAFFLE_STATE.TICKET_SALE_OPEN, "Can't draw a winner at this time.");

        // pray to RNGesus to request a random number
        rngesusRequestId = IRNGesus(rngesusContract).prayToRngesus{value: msg.value}(_gweiForFulfillPrayer);

        // set raffle state to WAITING_FOR_PAYOUT
        raffleState = RAFFLE_STATE.WAITING_FOR_PAYOUT;

    }

    function payOut() public nonReentrant {

        // only the raffle creator can execute this function
        require(msg.sender == raffleCreator, "Only the Raffle Creator can pay out.");

        // check if the raffle_state is WAITING_FOR_PAYOUT
        require(raffleState == RAFFLE_STATE.WAITING_FOR_PAYOUT, "You can't pay out at this time.");

        // get random number from RNGesus
        uint256 randomNumber = IRNGesus(rngesusContract).randomNumbers(rngesusRequestId);

        // make sure that RNGesus created a random number, it will return 0 if it has not been created yet
        require(randomNumber != 0, "RNGesus has not created a random number yet, please wait a few minutes.");

        // get the winning ticket (modulo can have 0 as a value, that's why we add 1)
        uint256 winningTicket = (randomNumber % totalTicketsBought) + 1;

        // find the index of raffle box for the winner
        uint winnerIndex = findWinnerIndex(winningTicket);

        // get the winner addres from the raffle box
        winner = raffleBox[winnerIndex].player;

        // pay the winner the prize pool
        payable(winner).transfer(prizePool);

        emit Winner(winner, prizePool);

        // transfer remaining balance to the raffle creator
        payable(raffleCreator).transfer(address(this).balance);

        // the raffle is finished, thanks for playing
        raffleState = RAFFLE_STATE.RAFFLE_FINISHED;

    }

    // find the index of the raffle box to determine the winner based on the ticket number
    function findWinnerIndex(uint256 winningTicket) internal view returns (uint256) {

        // set low to 0 and high to the raffle box length
        uint256 low = 0;
        uint256 high = raffleBox.length;

        while (low < high) {

            // get the average of low and high (Math will round down)
            uint256 mid = Math.average(low, high);

            // check if current tickets bought for index mid is greater than winning ticket number
            if (raffleBox[mid].currentTicketsBought > winningTicket) {

                // if so, set high to mid and run again
                high = mid;

            } else {
                // if current tickets bought is lower than winning ticket, set low to mid + 1
                low = mid + 1;
            }
        }

        // once we break out of the while loop, currentTicketsBought is either exact for the raffle box index low -1
        // if not, the winning raffle box index is equal to low
        if (low > 0 && raffleBox[low - 1].currentTicketsBought == winningTicket) {
            return low - 1;
        } else {
            return low;
        }
    }

    // get contract variables
    function getContractVariables() public view returns (bytes memory) {

        bytes memory contractVariables = abi.encode(
            raffleName, prizePoolAllocationPercentage, prizePool, totalTicketsBought, winner
        );

        return contractVariables;

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}