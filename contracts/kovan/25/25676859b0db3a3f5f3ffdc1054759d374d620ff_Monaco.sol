// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./whips/Whip.sol";
import "./utils/SignedWadMath.sol";

import "solmate/utils/SafeCastLib.sol";

/// @title 0xMonaco: On-Chain Racing Game
/// @author robertabbott <[email protected]>
/// @author transmissions11 <[email protected]>
contract Monaco {
    using SafeCastLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TurnCompleted(uint256 indexed turn, WhipData[] whips, uint256 acceleratePrice, uint256 shellPrice);

    event Shelled(uint256 indexed turn, Whip indexed smoker, Whip indexed smoked, uint256 amount, uint256 cost);

    event Accelerated(uint256 indexed turn, Whip indexed whip, uint256 amount, uint256 cost);

    event Registered(uint256 indexed turn, Whip indexed whip);

    event Punished(uint256 indexed turn, Whip indexed whip);

    event Rewarded(uint256 indexed turn, Whip indexed whip);

    event Dub(uint256 indexed turn, Whip indexed winner);

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////111111////////////////////////////////////*/

    // Miscellaneous constants:

    uint72 internal constant PLAYERS_REQUIRED = 3;

    uint24 internal constant POST_SHELL_SPEED = 1;

    uint24 internal constant STARTING_BALANCE = 10000;

    uint256 internal constant FINISH_DISTANCE = 1000;

    /*////////////////////////////////////////////////////////////*/

    // Gas usage punishment/reward constants:

    // TODO: Change how punishment works, just bill coins per gas used.
    uint24 internal constant GUZZLER_PUNISHMENT_FACTOR = 9.8e2;
    uint24 internal constant TESLA_KICKBACK_FACTOR = 1.10e2;

    /*////////////////////////////////////////////////////////////*/

    // VRGDA pricing constants:

    int256 internal constant SHELL_STARTING_PRICE = 200e18;
    int256 internal constant SHELL_PER_PERIOD_DECREASE = 0.33e18;
    int256 internal constant SHELL_SELL_PER_TURN = 0.2e18;

    int256 internal constant ACCELERATE_STARTING_PRICE = 10e18;
    int256 internal constant ACCELERATE_PER_PERIOD_DECREASE = 0.33e18;
    int256 internal constant ACCELERATE_SELL_PER_TURN = 2e18;

    /*//////////////////////////////////////////////////////////////
                               GAME STATE
    //////////////////////////////////////////////////////////////*/

    enum State {
        WAITING,
        ACTIVE,
        DONE
    }

    State public state; // The current state of the game: pre-start, started, done.

    uint16 public turns; // Number of turns played since the game started.

    uint72 public entropy; // Random data used to choose the next turn.

    Whip public currentWhip; // The whip currently making a move.

    /*//////////////////////////////////////////////////////////////
                            VRGDA SALES STATE
    //////////////////////////////////////////////////////////////*/

    enum ActionType {
        ACCELERATE,
        SHELL
    }

    mapping(ActionType => uint256) public getActionsSold;

    /*//////////////////////////////////////////////////////////////
                              WHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    struct WhipData {
        uint24 gasConsumedLastTurn;
        uint24 balance; // Where 0 means the whip has no money.
        uint24 speed; // Where 0 means the whip isn't moving.
        uint24 y; // Where 0 means the whip hasn't moved.
        Whip whip;
    }

    Whip[] public whips;

    mapping(Whip => WhipData) public getWhipData;

    /*//////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    function register(Whip whip) external {
        // Prevent accidentally or intentionally registering a whip multiple times.
        require(address(getWhipData[whip].whip) == address(0), "DOUBLE_REGISTER");

        // Register the caller as a whip in the race.
        getWhipData[whip] = WhipData({gasConsumedLastTurn: 0, balance: STARTING_BALANCE, whip: whip, speed: 0, y: 0});

        whips.push(whip); // Append to the list of whips.

        uint256 totalWhips = whips.length;

        // If the game is now full, kick things off.
        if (totalWhips == PLAYERS_REQUIRED) {
            // Use the timestamp as random input.
            entropy = uint72(block.timestamp);

            // Mark the game as active.
            state = State.ACTIVE;
        } else require(totalWhips < PLAYERS_REQUIRED, "MAX_PLAYERS");

        emit Registered(0, whip);
    }

    /*//////////////////////////////////////////////////////////////
                                CORE GAME
    //////////////////////////////////////////////////////////////*/

    function play() external onlyDuringActiveGame {
        Whip currentTurnWhip = getCurrentTurnWhip();

        unchecked {
            currentWhip = currentTurnWhip; // Set the current whip temporarily.

            // TODO: We can likely optimize the extra array allocation here.
            // Get all whip data and the current turn whip's index so we can pass it via takeYourTurnYoungBlood.
            (WhipData[] memory allWhipData, uint256 yourWhipIndex) = getAllWhipDataAndFindWhip(currentTurnWhip);

            // Call the whip to have it take its turn, and measure its gas usage.
            uint256 gasStart = gasleft();
            try currentTurnWhip.takeYourTurnYoungBlood(allWhipData, yourWhipIndex) {} catch {}
            uint256 gasConsumed = gasStart - gasleft();

            delete currentWhip; // Restore the current whip to the zero address.

            // Update the whip's stored gas consumption so we can punish/reward it.
            getWhipData[currentTurnWhip].gasConsumedLastTurn = uint24(gasConsumed);

            // TODO: Should this be ++turns or turns++? Fuck.
            bool wasLastTurnInBatch = ++turns % PLAYERS_REQUIRED == 0;

            Whip[] memory allWhips = wasLastTurnInBatch ? sortWhipsDescendinglyBy(WhipDataField.GAS) : whips;

            for (uint256 i = 0; i < PLAYERS_REQUIRED; i++) {
                Whip whip = allWhips[i]; // Get the whip.

                // Get a pointer to the whip's data struct.
                WhipData storage whipData = getWhipData[whip];

                // If the whip is now past the finish line after moving:
                if ((whipData.y += whipData.speed) >= FINISH_DISTANCE) {
                    // TODO: should update turns later or earlier idk
                    emit Dub(turns, whip); // It won.

                    state = State.DONE;

                    return; // Exit early.
                }

                // If this is the last turn in the batch:
                if (wasLastTurnInBatch) {
                    // If the whip is in the upper
                    // half of whips by gas usage:
                    if (i < PLAYERS_REQUIRED / 2) {
                        // Cut its balance by 10%, they've been naughty.
                        whipData.balance = (whipData.balance * GUZZLER_PUNISHMENT_FACTOR) / 100;

                        // TODO: should update turns later or earlier idk
                        emit Punished(turns, whip);
                    } else {
                        // Otherwise increase its balance for being frugal.
                        whipData.balance = (whipData.balance * TESLA_KICKBACK_FACTOR) / 100;

                        emit Rewarded(turns, whip);

                        // If this was the last whip in this batch,
                        // we'll start shuffling to create a new one.
                        if (i == (PLAYERS_REQUIRED - 1)) {
                            // TODO: We may be able to reuse a memory array above.
                            Whip[] memory tempWhips = whips; // Allocate a temporary array.

                            // Knuth shuffle over the whips using our entropy as randomness.
                            for (uint256 j = 0; j < PLAYERS_REQUIRED; ++j) {
                                uint256 j2 = j + (newEntropy() % (PLAYERS_REQUIRED - j));

                                Whip temp = tempWhips[j];
                                tempWhips[j] = tempWhips[j2];
                                tempWhips[j2] = temp;
                            }

                            whips = tempWhips; // Reorder whips using the new shuffled ones.
                        }
                    }
                }
            }

            // TODO: This is incredibly wasteful gas-wise.
            emit TurnCompleted(turns, getAllWhipData(), getAccelerateCost(1), getShellCost(1));
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ACTIONS
    //////////////////////////////////////////////////////////////*/

    function buyAcceleration(uint256 amount) external onlyDuringActiveGame onlyCurrentWhip returns (uint256 cost) {
        cost = getAccelerateCost(amount); // Get the cost of the acceleration.

        // Get a storage pointer to the calling whip's data struct.
        WhipData storage whip = getWhipData[Whip(msg.sender)];

        whip.balance -= cost.safeCastTo24(); // This will underflow if we cant afford.

        unchecked {
            whip.speed += uint24(amount); // Increase their speed by the amount.

            // Increase the number of accelerates sold.
            getActionsSold[ActionType.ACCELERATE] += amount;
        }

        // TODO: should update turns later or earlier idk
        emit Accelerated(turns, Whip(msg.sender), amount, cost);
    }

    function buyShell(uint256 amount) external onlyDuringActiveGame onlyCurrentWhip returns (uint256 cost) {
        cost = getShellCost(amount); // Get the cost of the shells.

        // Get a storage pointer to the calling whip's data struct.
        WhipData storage whip = getWhipData[Whip(msg.sender)];

        whip.balance -= cost.safeCastTo24(); // This will underflow if we cant afford.

        uint256 y = whip.y; // Retrieve and cache the whip's y.

        unchecked {
            // Increase the number of shells sold.
            getActionsSold[ActionType.SHELL] += amount;

            Whip closestWhip; // Used to determine who to shell.
            uint256 distanceFromClosestWhip = type(uint256).max;

            for (uint256 i = 0; i < PLAYERS_REQUIRED; i++) {
                WhipData memory nextWhip = getWhipData[whips[i]];

                // If the whip is behind or on us, skip it.
                if (nextWhip.y <= y) continue;

                // Measure the distance from the whip to us.
                uint256 distanceFromNextWhip = nextWhip.y - y;

                // If this whip is closer than all other whips we've
                // looked at so far, we'll make it the closest one.
                if (distanceFromNextWhip < distanceFromClosestWhip) {
                    closestWhip = nextWhip.whip;
                    distanceFromClosestWhip = distanceFromNextWhip;
                }
            }

            // If there is a closest whip, shell it.
            if (address(closestWhip) != address(0)) {
                // Set the speed to POST_SHELL_SPEED unless its already at that speed or below, as to not speed it up.
                if (getWhipData[closestWhip].speed > POST_SHELL_SPEED) getWhipData[closestWhip].speed = POST_SHELL_SPEED;
            }

            // TODO: should update turns later or earlier idk
            emit Shelled(turns, Whip(msg.sender), closestWhip, amount, cost);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              VRGDA PRICING
    //////////////////////////////////////////////////////////////*/

    function getAccelerateCost(uint256 amount) public view returns (uint256 sum) {
        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                sum += computeActionPrice(
                    ACCELERATE_STARTING_PRICE,
                    ACCELERATE_PER_PERIOD_DECREASE,
                    turns,
                    getActionsSold[ActionType.ACCELERATE] + i,
                    ACCELERATE_SELL_PER_TURN
                );
            }
        }
    }

    function getShellCost(uint256 amount) public view returns (uint256 sum) {
        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                sum += computeActionPrice(
                    SHELL_STARTING_PRICE,
                    SHELL_PER_PERIOD_DECREASE,
                    turns,
                    getActionsSold[ActionType.SHELL] + i,
                    SHELL_SELL_PER_TURN
                );
            }
        }
    }

    function computeActionPrice(
        int256 initialPrice,
        int256 periodPriceDecrease,
        uint256 turnsSinceStart,
        uint256 sold,
        int256 sellPerTurnWad
    ) internal pure returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(
                wadMul(initialPrice, wadExp(unsafeWadMul(wadLn(1e18 - periodPriceDecrease),
                // Theoretically calling toWadUnsafe with turnsSinceStart and sold can overflow without
                // detection, but under any reasonable circumstance they will never be large enough.
                toWadUnsafe(turnsSinceStart) - (wadDiv(toWadUnsafe(sold), sellPerTurnWad))
            )))) / 1e18;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyDuringActiveGame() {
        require(state == State.ACTIVE, "GAME_NOT_ACTIVE");

        _;
    }

    modifier onlyCurrentWhip() {
        require(Whip(msg.sender) == currentWhip, "NOT_CURRENT_WHIP");

        _;
    }

    function getAllWhipData() public view returns (WhipData[] memory results) {
        results = new WhipData[](PLAYERS_REQUIRED); // Allocate the array.

        // Get a list of whips sorted descendingly by their y position.
        Whip[] memory sortedWhips = sortWhipsDescendinglyBy(WhipDataField.Y);

        unchecked {
            // Copy over each whip's data into the results array.
            for (uint256 i = 0; i < PLAYERS_REQUIRED; i++) results[i] = getWhipData[sortedWhips[i]];
        }
    }

    function getAllWhipDataAndFindWhip(Whip whipToFind)
        public
        view
        returns (WhipData[] memory results, uint256 foundWhipIndex)
    {
        results = new WhipData[](PLAYERS_REQUIRED); // Allocate the array.

        // Get a list of whips sorted descendingly by their y position.
        Whip[] memory sortedWhips = sortWhipsDescendinglyBy(WhipDataField.Y);

        unchecked {
            // Copy over each whip's data into the results array.
            for (uint256 i = 0; i < PLAYERS_REQUIRED; i++) {
                Whip whip = sortedWhips[i];

                // Once we find the whip, we can return the index.
                if (whip == whipToFind) foundWhipIndex = i;

                results[i] = getWhipData[whip];
            }
        }
    }

    function getCurrentTurnWhip() public view returns (Whip) {
        return whips[turns % PLAYERS_REQUIRED];
    }

    function newEntropy() internal returns (uint72) {
        return (entropy = uint72(uint256(keccak256(abi.encode(entropy)))));
    }

    /*//////////////////////////////////////////////////////////////
                              SORTING LOGIC
    //////////////////////////////////////////////////////////////*/

    enum WhipDataField {
        Y,
        GAS
    }

    function sortWhipsDescendinglyBy(WhipDataField field) internal view returns (Whip[] memory sortedWhips) {
        unchecked {
            sortedWhips = whips;

            // Implements a descending BubbleSort algorithm.
            for (uint256 i = 0; i < PLAYERS_REQUIRED; i++) {
                for (uint256 j = i + 1; j < PLAYERS_REQUIRED; j++) {
                    if (
                        field == WhipDataField.GAS
                            ? getWhipData[sortedWhips[j]].gasConsumedLastTurn >
                                getWhipData[sortedWhips[i]].gasConsumedLastTurn
                            : getWhipData[sortedWhips[j]].y > getWhipData[sortedWhips[i]].y
                    ) {
                        Whip temp = sortedWhips[i];
                        sortedWhips[i] = sortedWhips[j];
                        sortedWhips[j] = temp;
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Monaco.sol";

abstract contract Whip {
    Monaco internal immutable monaco;

    constructor(Monaco _monaco) {
        monaco = _monaco;
    }

    // Note: The allWhips array comes sorted in descending order of each whip's y position.
    function takeYourTurnYoungBlood(Monaco.WhipData[] calldata allWhips, uint256 yourWhipIndex) external virtual;

    // Note: Override this to identify your whip for viewers of the races your whip is in.
    function name() external virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Signed Wad Math
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Efficient signed wad arithmetic.

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) {
            return 0;
        }

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) {
            revert("EXP_OVERFLOW");
        }

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5 ** 18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = (x << 96) / 54916777467707473351141471128 + 2 ** 95 >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = (y * x >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = (p * y >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = (q * x >> 96) + 50020603652535783019961831881945;
        q = (q * x >> 96) - 533845033583426703283633433725380;
        q = (q * x >> 96) + 3604857256930695427073651918091429;
        q = (q * x >> 96) - 14423608567350463180887372962807573;
        q = (q * x >> 96) + 26449188498355588339934803723976023;

        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256(uint256(r) * 3822833074963236453042738258902158003155416615667 >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = (p * x >> 96) + 24828157081833163892658089445524;
        p = (p * x >> 96) + 43456485725739037958740375743393;
        p = (p * x >> 96) - 11111509109440967052023855526967;
        p = (p * x >> 96) - 45023709667254063763336534515857;
        p = (p * x >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = (q * x >> 96) + 71694874799317883764090561454958;
        q = (q * x >> 96) + 283447036172924575727196451306956;
        q = (q * x >> 96) + 401686690394027663651624208769553;
        q = (q * x >> 96) + 204048457590392012362485061816622;
        q = (q * x >> 96) + 31853899698501571402653359427138;
        q = (q * x >> 96) + 909429971244387300277376558375;
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}