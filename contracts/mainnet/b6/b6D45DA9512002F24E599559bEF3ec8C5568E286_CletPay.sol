// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
/// @title Clet Name Service
/// @author Clet Inc.
/// @notice This contract serves as a payment gateway for acquiring clet names
/// @dev All function inputs must be lowercase to prevent undesirable results
/// @custom:contact [email protected]

import "./PriceConverter.sol";
import "./StringManipulation.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error CletPay__Empty();
error CletPay__Expired();
error CletPay__NotForSale();
error CletPay__Unauthorized();
error CletPay__InValidToken();
error CletPay__PaymentFailed();
error CletPay__NameUnavailable();
error CletPay__InsufficientFunds();

contract CletPay is Ownable {
    using StringManipulation for *;
    using PriceConverter for uint256;

    uint256 private NC1 = 399;
    uint256 private NC2 = 199;
    uint256 private NC3 = 99;
    uint256 private NC4 = 29;
    uint256 private NC5_ = 9;
    uint256 private LISTING_FEE = 3;
    uint256 private PARTNER_COMMISSION = 5;
    uint256 private constant TenPow18 = 10**18;
    address private constant CLDGR = 0x47732543a272c54cCAEd2F0983AF47458DC36958;
    AggregatorV3Interface constant priceFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    mapping(address => bool) public isPartner;
    mapping(string => bool) public nameForSale;
    mapping(string => bool) private name_Exists;
    mapping(string => address) public name_ToOwner;
    mapping(string => uint256) public name_ToPrice;
    mapping(string => uint256) public name_ToExpiry;
    mapping(string => uint256) public listedName_ID;
    mapping(address => uint256) public dBalance;
    string[] public listedNames;

    event Paid(
        string _name,
        uint256 _years,
        address indexed _user,
        string _soldBy,
        uint256 _amtPaid_USD,
        uint256 _partnerWeiSent
    );

    event AcquireListed(
        string _name,
        address indexed _buyer,
        address indexed _seller,
        uint256 _amtPaid_USD,
        uint256 _sellerWeiSent,
        uint256 _cletWeiCommission
    );

    /// @notice Unlocks any available name on the SKALE Chain
    function pay(
        string memory _name,
        uint256 _years,
        address _partner
    ) public payable noNull(_name) available(_name.toLower()) {
        uint256 PRICE_USD = getAmountToPay(_name, _years);
        if (isPartner[_partner] == false && dBalance[msg.sender] > 0) {
            PRICE_USD = workDiscount(PRICE_USD);
        }
        string memory soldBy = "CLET INC.";
        uint256 partnercut = 0;
        if (msg.value.getConversionRate(priceFeed) < PRICE_USD) {
            revert CletPay__InsufficientFunds();
        } else {
            if (isPartner[_partner] == true) {
                soldBy = Strings.toHexString(uint256(uint160(_partner)), 20);
                partnercut = (msg.value * PARTNER_COMMISSION) / 100;
                uint256 remainder = msg.value - partnercut;
                payable(CLDGR).transfer(remainder);
                payable(_partner).transfer(partnercut);
            } else {
                payable(CLDGR).transfer(msg.value);
            }
            unlock(_name, _years, msg.sender, PRICE_USD, soldBy, partnercut);
        }
    }

    /// @notice Unlocks any available name on the SKALE Chain (non-partner)
    function pay(string memory _name, uint256 _years) public payable {
        pay(_name, _years, 0x0000000000000000000000000000000000000000);
    }

    function unlock(
        string memory _name,
        uint256 _years,
        address _address,
        uint256 _amountPaid,
        string memory _soldBy,
        uint256 _partnerCut
    ) private {
        name_Exists[_name] = true;
        name_ToOwner[_name] = _address;
        if (nameForSale[_name] == true) {
            deleteListedName(_name);
        }
        name_ToExpiry[_name] = block.timestamp + (_years * 365 days);
        emit Paid(
            _name,
            _years,
            _address,
            _soldBy,
            _amountPaid / TenPow18,
            _partnerCut
        );
    }

    /// @notice Used by Clet Token Pay contracts
    function externalUnlock(
        string memory _name,
        uint256 _years,
        address _address,
        uint256 _amountPaid
    ) public onlyOwner available(_name.toLower()) {
        unlock(_name, _years, _address, _amountPaid, "CLET INC.", 0);
    }

    /// @notice Adds specified number of years to an existing name
    function addYears(string memory _name, uint256 _years)
        public
        payable
        noNull(_name)
    {
        if (name_Exists[_name.toLower()] == true) {
            uint256 PRICE_USD = getAmountToPay(_name, _years);
            if (dBalance[msg.sender] > 0) {
                PRICE_USD = workDiscount(PRICE_USD);
            }
            if (msg.value.getConversionRate(priceFeed) < PRICE_USD) {
                revert CletPay__InsufficientFunds();
            } else {
                payable(CLDGR).transfer(msg.value);
                name_ToExpiry[_name] =
                    (_years * 365 days) +
                    name_ToExpiry[_name];
            }
        } else {
            revert CletPay__NameUnavailable();
        }
    }

    /// @notice Returns the price of a name based on number of years
    function getAmountToPay(string memory _name, uint256 _years)
        public
        view
        returns (uint256)
    {
        uint256 _name_count = bytes(_name).length;
        uint256 PRICE_USD = NC5_ * TenPow18;
        if (_name_count == 1) {
            PRICE_USD = NC1 * TenPow18;
        } else if (_name_count == 2) {
            PRICE_USD = NC2 * TenPow18;
        } else if (_name_count == 3) {
            PRICE_USD = NC3 * TenPow18;
        } else if (_name_count == 4) {
            PRICE_USD = NC4 * TenPow18;
        }
        PRICE_USD = PRICE_USD * _years;
        return PRICE_USD;
    }

    /// @notice Returns the current ETH value in USD
    function getEthPrice() public view returns (uint256) {
        return TenPow18.getConversionRate(priceFeed);
    }

    /// @notice Allows a user to set or update the cost price of an owned name
    function setListingPrice(string memory _name, uint256 _amount)
        public
        isNameOwner(name_ToOwner[_name])
        nonExpired(_name.toLower())
    {
        if (nameForSale[_name] == false) {
            listedNames.push(_name);
            listedName_ID[_name] = listedNames.length - 1;
        }
        nameForSale[_name] = true;
        name_ToPrice[_name] = _amount * TenPow18;
    }

    // @notice Delists an existing owned name
    function delistName(string memory _name)
        public
        isNameOwner(name_ToOwner[_name.toLower()])
    {
        if (nameForSale[_name] == true) {
            deleteListedName(_name);
        }
    }

    /// @notice Acquires a non-expired listed name
    function buyListedName(string memory _name)
        public
        payable
        nonExpired(_name.toLower())
    {
        if (nameForSale[_name] == true) {
            uint256 amtBroughtForward = msg.value.getConversionRate(priceFeed);
            if (amtBroughtForward < name_ToPrice[_name]) {
                revert CletPay__InsufficientFunds();
            } else {
                uint256 cletcut = (msg.value * LISTING_FEE) / 100;
                uint256 remainder = msg.value - cletcut;
                payable(CLDGR).transfer(cletcut);
                payable(name_ToOwner[_name]).transfer(remainder);
                address seller = name_ToOwner[_name];
                name_ToOwner[_name] = msg.sender;
                deleteListedName(_name);
                emit AcquireListed(
                    _name,
                    msg.sender,
                    seller,
                    amtBroughtForward / TenPow18,
                    remainder,
                    cletcut
                );
            }
        } else {
            revert CletPay__NotForSale();
        }
    }

    // @notice Returns all listed names
    function getAllListedNames() public view returns (string[] memory) {
        return listedNames;
    }

    // @notice Returns number of listed names
    function getListedNamesCount() public view returns (uint256) {
        return listedNames.length;
    }

    // @notice Transfers an owned name to a new owner
    // @dev Call this function before transfer on SKALE Chain
    function transferName(string memory _name, address _newOwner)
        public
        isNameOwner(name_ToOwner[_name.toLower()])
        nonExpired(_name.toLower())
    {
        if (nameForSale[_name] == true) {
            deleteListedName(_name);
        }
        name_ToOwner[_name] = _newOwner;
    }

    // @notice Checks if a name is available
    function nameExists(string memory _name) public view returns (bool) {
        return name_Exists[_name];
    }

    function deleteListedName(string memory _name) private {
        for (uint i = listedName_ID[_name]; i < listedNames.length - 1; i++) {
            listedNames[i] = listedNames[i + 1];
            listedName_ID[listedNames[i]] = listedName_ID[listedNames[i]] - 1;
        }
        listedNames.pop();
        nameForSale[_name] = false;
        name_ToPrice[_name] = 0;
        listedName_ID[_name] = 0;
    }

    function updatePrice(uint256 _index, uint256 _newAmount) public onlyOwner {
        if (_index == 1) {
            NC1 = _newAmount;
        } else if (_index == 2) {
            NC2 = _newAmount;
        } else if (_index == 3) {
            NC3 = _newAmount;
        } else if (_index == 4) {
            NC4 = _newAmount;
        } else if (_index == 5) {
            NC5_ = _newAmount;
        }
    }

    function setCommision(uint256 _commisionPercentage) public onlyOwner {
        PARTNER_COMMISSION = _commisionPercentage;
    }

    function setPartner(address _partner, bool _validity) public onlyOwner {
        isPartner[_partner] = _validity;
    }

    function withdraw() public onlyOwner {
        payable(CLDGR).transfer(address(this).balance);
    }

    function expiryCheck(string memory _name) private {
        if (block.timestamp >= name_ToExpiry[_name]) {
            name_Exists[_name] = false;
            nameForSale[_name] = false;
            name_ToPrice[_name] = 0;
        }
    }

    function isExpired(string memory _name) public view returns (bool) {
        bool res = false;
        if (block.timestamp >= name_ToExpiry[_name]) {
            res = true;
        }
        return res;
    }

    modifier isNameOwner(address _address) {
        if (_address != msg.sender) {
            revert CletPay__Unauthorized();
        }
        _;
    }

    modifier available(string memory _name) {
        expiryCheck(_name);
        if (name_Exists[_name] == true) {
            revert CletPay__NameUnavailable();
        }
        _;
    }

    modifier nonExpired(string memory _name) {
        expiryCheck(_name);
        if (block.timestamp >= name_ToExpiry[_name]) {
            revert CletPay__Expired();
        }
        _;
    }

    modifier noNull(string memory _string) {
        if (_string.isEqual("")) {
            revert CletPay__Empty();
        }
        if (_string.hasEmptyString() == true) {
            revert CletPay__Empty();
        }
        _;
    }

    function workDiscount(uint256 _price) private returns (uint256) {
        uint256 PRICE_USD = 0;
        if (_price > dBalance[msg.sender]) {
            PRICE_USD = _price - dBalance[msg.sender];
            dBalance[msg.sender] = 0;
        } else {
            dBalance[msg.sender] = dBalance[msg.sender] - _price;
            PRICE_USD = 0;
        }
        return PRICE_USD;
    }

    function creditAccount(uint256 _amount, address _address) public onlyOwner {
        dBalance[_address] = dBalance[_address] + (_amount * TenPow18);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringManipulation {
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function hasEmptyString(string memory str) internal pure returns (bool) {
        for (uint i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == 0x20) {
                return true;
            }
        }
        return false;
    }

    function isEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        bool res = false;
        if (
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2))
        ) {
            res = true;
        }
        return res;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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