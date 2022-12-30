// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity >=0.5.15;

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "tinlake-math/math.sol";

/// @notice Discounting contract without a state which defines the relevant formulas for the navfeed
contract Discounting is Math {
    /// @notice calculates the discount for a given loan
    /// @param discountRate the discount rate
    /// @param fv the future value of the loan
    /// @param normalizedBlockTimestamp the normalized block time (each day to midnight)
    /// @param maturityDate the maturity date of the loan
    /// @return result discount for the loan
    function calcDiscount(uint256 discountRate, uint256 fv, uint256 normalizedBlockTimestamp, uint256 maturityDate)
        public
        pure
        returns (uint256 result)
    {
        return rdiv(fv, rpow(discountRate, safeSub(maturityDate, normalizedBlockTimestamp), ONE));
    }

    /// @notice calculate the future value based on the amount, maturityDate interestRate and recoveryRate
    /// @param loanInterestRate the interest rate of the loan
    /// @param amount of the loan (principal)
    /// @param maturityDate the maturity date of the loan
    /// @param recoveryRatePD the recovery rate together with the probability of default of the loan
    /// @return fv future value of the loan
    function calcFutureValue(uint256 loanInterestRate, uint256 amount, uint256 maturityDate, uint256 recoveryRatePD)
        public
        view
        returns (uint256 fv)
    {
        uint256 nnow = uniqueDayTimestamp(block.timestamp);
        uint256 timeRemaining = 0;
        if (maturityDate > nnow) {
            timeRemaining = safeSub(maturityDate, nnow);
        }

        return rmul(rmul(rpow(loanInterestRate, timeRemaining, ONE), amount), recoveryRatePD);
    }

    /// @notice substracts to values if the result smaller than 0 it returns 0
    /// @param x the first value (minuend)
    /// @param y the second value (subtrahend)
    /// @return result result of the subtraction
    function secureSub(uint256 x, uint256 y) public pure returns (uint256 result) {
        if (y > x) {
            return 0;
        }
        return safeSub(x, y);
    }

    /// @notice normalizes a timestamp to round down to the nearest midnight (UTC)
    /// @param timestamp the timestamp which should be normalized
    /// @return nTimestamp normalized timestamp
    function uniqueDayTimestamp(uint256 timestamp) public pure returns (uint256 nTimestamp) {
        return (1 days) * (timestamp / (1 days));
    }
    /// @notice rpow peforms a math pow operation with fixed point number
    /// adopted from ds-math
    /// @param x the base for the pow operation
    /// @param n the exponent for the pow operation
    /// @param base the base of the fixed point number
    /// @return z the result of the pow operation

    function rpow(uint256 x, uint256 n, uint256 base) public pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 { z := base }
                default { z := 0 }
            }
            default {
                switch mod(n, 2)
                case 0 { z := base }
                default { z := x }
                let half := div(base, 2) // for rounding.
                for { n := div(n, 2) } n { n := div(n, 2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0, 0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0, 0) }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0, 0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018  Rain <[email protected]>, Centrifuge
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "tinlake-auth/auth.sol";
import {Discounting} from "../feed/discounting.sol";

struct Loan {
    address registry;
    uint256 tokenId;
}

interface ShelfLike {
    function shelf(uint256) external view returns (Loan memory);
}

interface PileLike {
    function changeRate(uint256, uint256) external;
}

interface FeedLike {
    function pile() external view returns (address);
    function shelf() external view returns (address);
    function nftID(uint256 loan) external view returns (bytes32);
    function maturityDate(bytes32 nft_) external view returns (uint256);
}

interface RootLike {
    function borrowerDeployer() external view returns (address);
}

interface BorrowerDeployerLike {
    function pile() external view returns (address);
    function shelf() external view returns (address);
    function feed() external view returns (address);
}

/// @notice WriteOff contract can move overdue loans into a write off group
/// The wrapper contract manages multiple different pools
contract WriteOffWrapper is Auth, Discounting {
    mapping(address => uint256) public writeOffRates;

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);

        writeOffRates[address(0x05739C677286d38CcBF0FfC8f9cdbD45904B47Fd)] = 1000; // Bling Series 1
        writeOffRates[address(0xAAEaCfcCc3d3249f125Ba0644495560309C266cB)] = 1001; // Pezesha 1
        writeOffRates[address(0x9E39e0130558cd9A01C1e3c7b2c3803baCb59616)] = 1001; // GIG Pool
        writeOffRates[address(0x11C14AAa42e361Cf3500C9C46f34171856e3f657)] = 1000; // Fortunafi 1
        writeOffRates[address(0xE7876f282bdF0f62e5fdb2C63b8b89c10538dF32)] = 1000; // Harbor Trade 2
        writeOffRates[address(0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f)] = 1000; // New Silver 2
        writeOffRates[address(0xe17F3c35C18b2Af84ceE2eDed673c6A08A671695)] = 1000; // Branch Series 3
        writeOffRates[address(0x99D0333f97432fdEfA25B7634520d505e58B131B)] = 1000; // FactorChain 1
        writeOffRates[address(0x37c8B836eA1b89b7cC4cFdDed4C4fbC454CcC679)] = 1000; // Paperchain 3
        writeOffRates[address(0xB7d1DE24c0243e6A3eC4De9fAB2B19AB46Fa941F)] = 1001; // UP Series 1
        writeOffRates[address(0x3fC72dA5545E2AB6202D81fbEb1C8273Be95068C)] = 1000; // ConsolFreight 4
        writeOffRates[address(0xdB07B21109117208a0317adfbed484C87c9c2aFf)] = 1000; // databased.FINANCE 1
        writeOffRates[address(0x4b0f712Aa9F91359f48D8628De8483B04530751a)] = 1001; // Peoples 1
    }

    /// @notice writes off an overdue loan
    /// @param root the address of the root contract
    function writeOff(address root, uint256 loan) public auth {
        BorrowerDeployerLike deployer = BorrowerDeployerLike(RootLike(root).borrowerDeployer());
        FeedLike feed = FeedLike(deployer.feed());
        PileLike pile = PileLike(deployer.pile());
        require(writeOffRates[address(pile)] != 0, "WriteOffWrapper/pile-has-no-write-off-group");
        ShelfLike shelf = ShelfLike(deployer.shelf());
        require(shelf.shelf(loan).tokenId != 0, "WriteOffWrapper/loan-does-not-exist");
        uint256 nnow = uniqueDayTimestamp(block.timestamp);
        bytes32 nftID = feed.nftID(loan);
        uint256 maturityDate = feed.maturityDate(nftID);

        require(maturityDate < nnow, "WriteOffWrapper/loan-not-overdue");

        pile.changeRate(loan, writeOffRates[address(pile)]);
    }

    function file(bytes32 what, address addr, uint256 data) public auth {
        if (what == "writeOffRates") {
            writeOffRates[addr] = data;
        }
    }
}