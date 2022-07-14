// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./utils/SignedWadMath.sol";

struct Whip {
    uint256 balance;
    uint256 speed;
    uint256 y;
    address driver;
}

enum ActionType {
    SPEED_CAP_INCREASE,
    ACCELERATE,
    SHELL
}

contract Monaco {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_PLAYERS = 3;

    uint256 public constant STARTING_BALANCE = 10000;

    uint256 public constant FINISH_DISTANCE = 1000;

    // amongus

    int256 public constant SHELL_STARTING_PRICE = 200e18;
    int256 public constant SHELL_PER_PERIOD_DECREASE = 0.33e18;
    int256 public constant SHELL_SELL_PER_TICK = 0.2e18;

    int256 public constant ACCELERATE_STARTING_PRICE = 10e18;
    int256 public constant ACCELERATE_PER_PERIOD_DECREASE = 0.33e18;
    int256 public constant ACCELERATE_SELL_PER_TICK = 2e18;

    /*//////////////////////////////////////////////////////////////
                              VRGDA STORAGE
    //////////////////////////////////////////////////////////////*/

    uint128 public idleTicks;

    mapping(ActionType => uint256) public actionsSold;

    /*//////////////////////////////////////////////////////////////
                              WHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] public drivers;

    mapping(address => Whip) public whips;

    /*//////////////////////////////////////////////////////////////
                               GAME STATE
    //////////////////////////////////////////////////////////////*/

    bool public cap;

    /*//////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    function register() public {
        require(
            address(whips[msg.sender].driver) == address(0),
            "my fucking homie in christ you cant do that sam wont like it"
        );

        whips[msg.sender] = Whip({balance: STARTING_BALANCE, speed: 0, y: 0, driver: msg.sender});

        drivers.push(msg.sender);

        require(drivers.length <= MAX_PLAYERS, "ur cappin on god tryna fool me like that");

        if (drivers.length == MAX_PLAYERS) createNewBatch();
    }

    /*//////////////////////////////////////////////////////////////
                                  TICK
    //////////////////////////////////////////////////////////////*/

    struct Batch {
        address[] order;
        uint256 movesPerformed;
    }

    Batch public batch;
    uint256 public batchCount;

    function getBatchOrder() public view returns (address[] memory orders) {
        return batch.order;
    }

    function getMovesPerformedInBatch() public view returns (uint256 movesPerformed) {
        return batch.movesPerformed;
    }

    function getCurrentDriver() public view returns (address driver) {
        return batch.order[batch.movesPerformed];
    }

    // todo this randomness seems to lying but idk
    function createNewBatch() internal {
        address[] memory newDrivers = new address[](drivers.length);
        for (uint256 i = 0; i < drivers.length; i++) {
            newDrivers[i] = drivers[i];
        }

        for (uint256 i = 0; i < drivers.length; i++) {
            uint256 n = i + (uint256(keccak256(abi.encodePacked(block.timestamp))) % (drivers.length - i));
            address temp = newDrivers[n];
            newDrivers[n] = newDrivers[i];
            newDrivers[i] = temp;
        }

        batch = Batch({order: newDrivers, movesPerformed: 0});
        ++batchCount;
    }

    function moveTick(ActionType[] calldata actions) public {
        require(!cap, "ur cappin");
        require(drivers.length == MAX_PLAYERS, "race hasnt started goofy");
        require(getCurrentDriver() == msg.sender, "out of order goofy not cash money");

        for (uint256 i = 0; i < actions.length; i++) {
            ActionType action = actions[i];

            if (action == ActionType.SHELL) buyShell();
            else if (action == ActionType.ACCELERATE) buyAcceleration();
        }

        idleTick();

        if (++batch.movesPerformed == drivers.length) createNewBatch();
    }

    function idleTick() internal {
        ++idleTicks;

        for (uint256 i = 0; i < drivers.length; i++) {
            Whip storage whip = whips[drivers[i]];

            whip.y += whip.speed;

            if (whip.y >= FINISH_DISTANCE) cap = true;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                  MOVES
    //////////////////////////////////////////////////////////////*/

    function buyAcceleration() internal {
        uint256 gdaPrice = getAcceleratePrice(1);

        Whip storage whip = whips[msg.sender];

        whip.speed += 1;
        whip.balance -= (gdaPrice); // this will underflow if we cant afford

        ++actionsSold[ActionType.ACCELERATE];
    }

    function buyShell() internal {
        uint256 gdaPrice = getShellPrice(1);

        Whip storage whip = whips[msg.sender];
        whip.balance -= (gdaPrice); // this will underflow if we cant afford

        ++actionsSold[ActionType.SHELL];

        uint256 distanceFromClosestWhip = type(uint256).max;
        address closestDriver;

        for (uint256 i = 0; i < drivers.length; i++) {
            Whip memory nextWhip = whips[drivers[i]];

            if (nextWhip.y <= whip.y) continue;

            uint256 distanceFromNextWhip = nextWhip.y - whip.y;

            if (distanceFromNextWhip < distanceFromClosestWhip) {
                distanceFromClosestWhip = distanceFromNextWhip;
                closestDriver = drivers[i];
            }
        }

        if (address(closestDriver) != address(0)) whips[closestDriver].speed = 0; // fucking smoked
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function getNumDrivers() public view returns (uint256) {
        return drivers.length;
    }

    function getWhips() public view returns (Whip[] memory results) {
        results = new Whip[](drivers.length);
        for (uint256 i = 0; i < drivers.length; i++) {
            results[i] = whips[drivers[i]];
        }
    }

    function getAcceleratePrice(uint256 count) public view returns (uint256) {
        uint256 sum;

        for (uint256 i = 0; i < count; i++) {
            sum +=
                getPrice(
                    ACCELERATE_STARTING_PRICE,
                    ACCELERATE_PER_PERIOD_DECREASE,
                    idleTicks,
                    actionsSold[ActionType.ACCELERATE] + i,
                    ACCELERATE_SELL_PER_TICK
                ) /
                1e18;
        }

        return sum;
    }

    function getShellPrice(uint256 count) public view returns (uint256) {
        uint256 sum;

        for (uint256 i = 0; i < count; i++) {
            sum +=
                getPrice(
                    SHELL_STARTING_PRICE,
                    SHELL_PER_PERIOD_DECREASE,
                    idleTicks,
                    actionsSold[ActionType.SHELL] + i,
                    SHELL_SELL_PER_TICK
                ) /
                1e18;
        }

        return sum;
    }

    function getPrice(
        int256 initialPrice,
        int256 periodPriceDecrease,
        uint256 ticksSinceStart,
        uint256 sold,
        int256 sellPerTickWad
    ) public pure returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(
                wadMul(initialPrice, wadExp(unsafeWadMul(wadLn(1e18 - periodPriceDecrease),
                // Theoretically calling toWadUnsafe with ticksSinceStart and sold can overflow without
                // detection, but under any reasonable circumstance they will never be large enough.
                toWadUnsafe(ticksSinceStart) - (wadDiv(toWadUnsafe(sold), sellPerTickWad))
            ))));
        }
    }

    function getForClient()
        public
        view
        returns (
            uint256 blockNum,
            uint256 chainID,
            uint256 numDrivers,
            uint256 maxPlayers,
            Whip[] memory _whips,
            uint256 _batchCount,
            address[] memory batchOrder,
            uint256 movesPerformed,
            address currentDriver,
            bool _cap
        )
    {
        blockNum = block.number;
        chainID = block.chainid;
        numDrivers = getNumDrivers();
        maxPlayers = MAX_PLAYERS;
        _whips = getWhips();
        _batchCount = batchCount;
        if (numDrivers == maxPlayers) {
            batchOrder = getBatchOrder();
            movesPerformed = getMovesPerformedInBatch();
            currentDriver = getCurrentDriver();
            _cap = cap;
        }
    }

    function getCalcsForClient(uint256 pendingShells, uint256 pendingAccels)
        public
        view
        returns (
            uint256 pendingShellPrice,
            uint256 pendingAccelPrice,
            uint256 nextShellPrice,
            uint256 nextAccelPrice
        )
    {
        pendingShellPrice = getShellPrice(pendingShells);
        pendingAccelPrice = getAcceleratePrice(pendingAccels);
        nextShellPrice = getShellPrice(pendingShells + 1) - pendingShellPrice;
        nextAccelPrice = getAcceleratePrice(pendingAccels + 1) - pendingAccelPrice;
    }
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
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

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
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
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
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
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