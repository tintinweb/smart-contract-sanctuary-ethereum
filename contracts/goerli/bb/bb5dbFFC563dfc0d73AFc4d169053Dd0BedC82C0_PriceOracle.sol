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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import {IReservedDomains} from "./IReservedDomains.sol";

interface IPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return base premium tuple of base price + premium price
     */
    function price(
        string calldata name,
        uint256 expires,
        uint256 duration,
        IReservedDomains.DomainType domainType
    ) external view returns (Price calldata);
}

//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

interface IReservedDomains {
    enum DomainType{ NORMAL, SPECIAL, BRAND }
    function domainType(bytes32) external view returns (DomainType);
}

//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "./IPriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

// StablePriceOracle sets a price in USD, based on an oracle.
contract PriceOracle is IPriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    uint256 constant GRACE_PERIOD = 90 days;
    uint256 immutable startPremium;
    uint256 immutable endValue;

    // Rent in base price units by length
    uint256 constant price1Letter = 3139269406392694; // 99 000 * 10e18 / 31536000
    uint256 constant price2Letter = 158517250126839; // 4 999 * 10e18 / 31536000
    uint256 constant price3Letter = 15823186199898; // 499 * 10e18 / 31536000
    uint256 constant price4Letter = 2822171486555; // 89 * 10e18 / 31536000
    uint256 constant price5Letter = 285388127853; // 9 * 10e18 / 31536000
    uint256 constant priceBrand = 634164129883307; // 19 999 * 10e18 / 31536000
    uint256 constant priceSpecial = 31678082191780; // 999 * 10e18 / 31536000
    uint256 constant PREPAID_DISCOUNT = 30; // percent

    uint256 constant PRECISION = 1e18;
    uint256 constant bit1 = 999989423469314432; // 0.5 ^ 1/65536 * (10 ** 18)
    uint256 constant bit2 = 999978847050491904; // 0.5 ^ 2/65536 * (10 ** 18)
    uint256 constant bit3 = 999957694548431104;
    uint256 constant bit4 = 999915390886613504;
    uint256 constant bit5 = 999830788931929088;
    uint256 constant bit6 = 999661606496243712;
    uint256 constant bit7 = 999323327502650752;
    uint256 constant bit8 = 998647112890970240;
    uint256 constant bit9 = 997296056085470080;
    uint256 constant bit10 = 994599423483633152;
    uint256 constant bit11 = 989228013193975424;
    uint256 constant bit12 = 978572062087700096;
    uint256 constant bit13 = 957603280698573696;
    uint256 constant bit14 = 917004043204671232;
    uint256 constant bit15 = 840896415253714560;
    uint256 constant bit16 = 707106781186547584;

    // Oracle address
    AggregatorInterface public immutable usdOracle;

    constructor(
        AggregatorInterface _usdOracle,
        uint256 _startPremium,
        uint256 totalDays
    ) {
        usdOracle = _usdOracle;
        startPremium = _startPremium;
        endValue = _startPremium >> totalDays;
    }

    function price(
        string calldata name,
        uint256 expires,
        uint256 duration,
        IReservedDomains.DomainType domainType
    ) external view override returns (IPriceOracle.Price memory) {
        uint256 _price;
        if (domainType == IReservedDomains.DomainType.BRAND) {
            _price = priceBrand;
        } else if (domainType == IReservedDomains.DomainType.SPECIAL) {
            _price = priceSpecial;
        } else {
            uint256 len = name.strlen();
            if (len >= 5) {
                _price = price5Letter;
            } else if (len == 4) {
                _price = price4Letter;
            } else if (len == 3) {
                _price = price3Letter;
            } else if (len == 2) {
                _price = price2Letter;
            } else {
                _price = price1Letter;
            }
        }

        uint256 prepaidDuration = _prepaidYears(duration) * 365 days;
        uint256 basePrice = _price * (duration - prepaidDuration) + _price * prepaidDuration * PREPAID_DISCOUNT / 100;
        return
            IPriceOracle.Price({
                base: attoUSDToWei(basePrice),
                premium: attoUSDToWei(_premium(name, expires, duration))
            });
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (uint256) {
        return attoUSDToWei(_premium(name, expires, duration));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(
        string memory,
        uint256 expires,
        uint256
    ) internal view returns (uint256) {
        expires = expires + GRACE_PERIOD;
        if (expires > block.timestamp) {
            return 0;
        }

        uint256 elapsed = block.timestamp - expires;
        uint256 premiumPeriod = decayedPremium(startPremium, elapsed);
        if (premiumPeriod >= endValue) {
            return premiumPeriod - endValue;
        }
        return 0;
    }

    /**
     * @dev Returns the premium price at current time elapsed
     * @param _startPremium starting price
     * @param _elapsed time past since expiry
     */
    function decayedPremium(uint256 _startPremium, uint256 _elapsed)
        public
        pure
        returns (uint256)
    {
        uint256 daysPast = (_elapsed * PRECISION) / 1 days;
        uint256 intDays = daysPast / PRECISION;
        uint256 premiumPeriod = _startPremium >> intDays;
        uint256 partDay = (daysPast - intDays * PRECISION);
        uint256 fraction = (partDay * (2**16)) / PRECISION;
        uint256 totalPremium = addFractionalPremium(fraction, premiumPeriod);
        return totalPremium;
    }

    function addFractionalPremium(uint256 fraction, uint256 premiumPeriod)
        internal
        pure
        returns (uint256)
    {
        if (fraction & (1 << 0) != 0) {
            premiumPeriod = (premiumPeriod * bit1) / PRECISION;
        }
        if (fraction & (1 << 1) != 0) {
            premiumPeriod = (premiumPeriod * bit2) / PRECISION;
        }
        if (fraction & (1 << 2) != 0) {
            premiumPeriod = (premiumPeriod * bit3) / PRECISION;
        }
        if (fraction & (1 << 3) != 0) {
            premiumPeriod = (premiumPeriod * bit4) / PRECISION;
        }
        if (fraction & (1 << 4) != 0) {
            premiumPeriod = (premiumPeriod * bit5) / PRECISION;
        }
        if (fraction & (1 << 5) != 0) {
            premiumPeriod = (premiumPeriod * bit6) / PRECISION;
        }
        if (fraction & (1 << 6) != 0) {
            premiumPeriod = (premiumPeriod * bit7) / PRECISION;
        }
        if (fraction & (1 << 7) != 0) {
            premiumPeriod = (premiumPeriod * bit8) / PRECISION;
        }
        if (fraction & (1 << 8) != 0) {
            premiumPeriod = (premiumPeriod * bit9) / PRECISION;
        }
        if (fraction & (1 << 9) != 0) {
            premiumPeriod = (premiumPeriod * bit10) / PRECISION;
        }
        if (fraction & (1 << 10) != 0) {
            premiumPeriod = (premiumPeriod * bit11) / PRECISION;
        }
        if (fraction & (1 << 11) != 0) {
            premiumPeriod = (premiumPeriod * bit12) / PRECISION;
        }
        if (fraction & (1 << 12) != 0) {
            premiumPeriod = (premiumPeriod * bit13) / PRECISION;
        }
        if (fraction & (1 << 13) != 0) {
            premiumPeriod = (premiumPeriod * bit14) / PRECISION;
        }
        if (fraction & (1 << 14) != 0) {
            premiumPeriod = (premiumPeriod * bit15) / PRECISION;
        }
        if (fraction & (1 << 15) != 0) {
            premiumPeriod = (premiumPeriod * bit16) / PRECISION;
        }
        return premiumPeriod;
    }

    /**
     * @dev Returns the number of full years in a renting period.
     */
    function _prepaidYears(uint256 duration) internal pure returns (uint256) {
        if (duration > 365 days) {
            return (duration - 365 days) / 365 days; // here integer division rounding down is intentional
        }
        return 0;
    }

    function attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return (amount * 1e8) / ethPrice;
    }

    function weiToAttoUSD(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return (amount * ethPrice) / 1e8;
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IPriceOracle).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}