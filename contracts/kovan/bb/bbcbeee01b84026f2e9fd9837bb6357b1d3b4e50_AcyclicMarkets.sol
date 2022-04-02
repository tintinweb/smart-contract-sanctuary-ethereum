/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// File: interfaces/IOracle.sol

/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

contract IOracle {
  
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 _roundIdUsed);

  function getLatestPrice() external view returns(uint256 _value);
}
// File: interfaces/IUserLevels.sol

pragma solidity 0.5.7;

contract IUserLevels {
    function getUserLevelAndMultiplier(address _user) external view returns(uint256 _userLevel, uint256 _multiplier);
    function getUserLevelAndPerks(address _user) external view returns(uint256 _userLevel, uint64 _multiplier, uint64 _feeDiscount);
}
// File: interfaces/IAllMarkets.sol

pragma solidity 0.5.7;

contract IAllMarkets {

	enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    function createMarket(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _createdBy, uint64 _initialLiquidity) public returns(uint64 _marketIndex);

    function createMarketWithVariableLiquidity(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _marketCreator, uint64[] memory _initialLiquidities) 
    public 
    returns(uint64 _marketIndex);

    function settleMarket(uint256 _marketId, uint256 _value) external;

    function addInitialAuthorizedAddress(address _address) external;

    function getTotalMarketsLength() external view returns(uint64);

    function getTotalPredictionPoints(uint _marketId) public view returns(uint64 predictionPoints);

    function getUserPredictionPoints(address _user, uint256 _marketId, uint256 _option) external view returns(uint64);

    function marketStatus(uint256 _marketId) public view returns(PredictionStatus);

    function marketSettleTime(uint256 _marketId) public view returns(uint32);

    function burnDisputedProposalTokens(uint _proposaId) external;

    function getTotalStakedValueInPLOT(uint256 _marketId) public view returns(uint256);

    function getTotalStakedWorthInPLOT(uint256 _marketId) public view returns(uint256 _tokenStakedWorth);

    function getMarketCurrencyData(bytes32 currencyType) external view returns(address);

    function getMarketOptionPricingParams(uint _marketId, uint _option) public view returns(uint[] memory,uint32);

    function getMarketData(uint256 _marketId) external view returns
       (uint64[] memory _optionRanges, uint[] memory _tokenStaked,uint _predictionTime,uint _expireTime, PredictionStatus _predictionStatus);
 
    function setMarketStatus(uint256 _marketId, PredictionStatus _status) public;
 
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external;

    function getTotalOptions(uint256 _marketId) external view returns(uint);
 
    function getTotalStakedByUser(address _user) external view returns(uint);

    function depositAndPredictFor(address _predictFor, uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external;

    function setClaimFlag(address _user, uint _userNonce) public;
}

// File: interfaces/IReferral.sol

pragma solidity 0.5.7;

contract IReferral {
    
    function setReferralRewardData(address _referee, address _token, uint _referrerFee, uint _refereeFee) external returns(bool _isEligible);

}
// File: interfaces/IAuth.sol

/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

contract IAuth {

    address public authorized;

    /// @dev modifier that allows only the authorized addresses to execute the function
    modifier onlyAuthorized() {
        require(authorized == msg.sender, "Not authorized");
        _;
    }

    /// @dev checks if an address is authorized to govern
    function isAuthorized(address _toCheck) public view returns(bool) {
        return (authorized == _toCheck);
    }

    function changeAuthorizedAddress(address _newAuth) external onlyAuthorized {
        authorized = _newAuth;
    }

}
// File: interfaces/IbPLOTToken.sol

pragma solidity 0.5.7;

contract IbPLOTToken {
    function convertToPLOT(address _of, address _to, uint256 amount) public;
    function transfer(address recipient, uint256 amount) public returns (bool);
    function renounceMinter() public;
}
// File: interfaces/IToken.sol

pragma solidity 0.5.7;

contract IToken {

    function decimals() external view returns(uint8);

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Gets the balance of the specified address.
    * @param account The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev Transfer token for a specified address
    * @param recipient The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) external returns (bool);
    
     /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) external;

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
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
    * @dev Transfer tokens from one address to another
    * @param sender address The address which you want to send tokens from
    * @param recipient address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function lockForGovernanceVote(address _of, uint256 _period) public;

    function isLockedForGV(address _of) public view returns (bool);

    function changeOperator(address _newOperator) public returns (bool);
}

// File: external/EIP712/Initializable.sol

pragma solidity 0.5.7;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}
// File: external/EIP712/EIP712Base.sol

pragma solidity 0.5.7;


contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := 137
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}
// File: external/proxy/Proxy.sol

pragma solidity 0.5.7;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
            }
    }

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);
}
// File: external/proxy/UpgradeabilityProxy.sol

pragma solidity 0.5.7;



/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

    /**
    * @dev Constructor function
    */
    constructor() public {}

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImplementation address representing the new implementation to be set
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
        sstore(position, _newImplementation)
        }
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}
// File: external/proxy/OwnedUpgradeabilityProxy.sol

pragma solidity 0.5.7;



/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.govblocks.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor(address _implementation) public {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param _implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}
// File: external/openzeppelin-solidity/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath128 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint128 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint128 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath64 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b <= a, errorMessage);
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint64 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint64 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath32 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint32 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint32 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
// File: external/NativeMetaTransaction.sol

pragma solidity 0.5.7;



contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function _msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
// File: AcyclicMarkets.sol

pragma solidity 0.5.7;











contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}
contract AcyclicMarkets is IAuth, NativeMetaTransaction {
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    event MarketParams(uint256 indexed marketIndex, string _question, uint64[] _optionRanges, uint32[] _marketTimes, uint256 _stakingFactorMinStake,uint32 _minTimePassed, address marketCreator, bytes8 _marketType, bytes32 _marketCurrency);
    event MarketCreatorReward(address indexed createdBy, uint256 indexed marketIndex, uint256 tokenIncentive);
    event ClaimedMarketCreationReward(address indexed user, uint reward, address predictionToken);

    uint32 public minTimePassed;

    struct PricingData {
      uint256 stakingFactorMinStake;
      uint32 stakingFactorWeightage;
      uint32 timeWeightage;
      uint32 minTimePassed;
    }

    struct MarketData {
      address marketCreator;
      PricingData pricingData;
    }

    struct MarketFeeParams {
      uint32 cummulativeFeePercent;
      uint32 daoCommissionPercent;
      uint32 referrerFeePercent;
      uint32 refereeFeePercent;
      uint32 marketCreatorFeePercent;
      mapping (uint256 => uint64) daoFee;
      mapping (uint256 => uint64) marketCreatorFee;
    }

    MarketFeeParams internal marketFeeParams;

    bool public paused;

    address internal masterAddress;
    address internal plotToken;
    IAllMarkets internal allMarkets;
    IReferral internal referral;
    IUserLevels internal userLevels;

    mapping(uint256 => MarketData) internal marketData;
    mapping(address => uint256) public marketCreationReward;
    mapping (address => uint256) public relayerFeeEarned;
    mapping(address => bool) public whiteListedMarketCreators;
    mapping(address => bool) public oneTimeMarketCreator;

    mapping(address => mapping(uint256 => bool)) public multiplierApplied;

    // uint internal totalOptions;
    uint internal stakingFactorMinStake;
    uint32 internal stakingFactorWeightage;
    uint32 internal timeWeightage;
    uint internal predictionDecimalMultiplier;
    uint internal minPredictionAmount;
    uint internal maxPredictionAmount;
    uint64 internal minLiquidityByCreator;

    modifier onlyAllMarkets {
      require(msg.sender == address(allMarkets));
      _;
    }

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      allMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      authorized = _authorizedMultiSig;
      stakingFactorMinStake = uint(20000).mul(10**8);
      stakingFactorWeightage = 40;
      timeWeightage = 60;
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      _marketFeeParams.cummulativeFeePercent = 200;
      _marketFeeParams.daoCommissionPercent = 1000;
      _marketFeeParams.refereeFeePercent = 1000;
      _marketFeeParams.referrerFeePercent = 2000;
      _marketFeeParams.marketCreatorFeePercent = 4000;
      minPredictionAmount = 10 ether; // Need to be updated
      maxPredictionAmount = 100000 ether; // Need to be updated
      minTimePassed = 10 hours; // need to set
      predictionDecimalMultiplier = 10;
      minLiquidityByCreator = 100 * 10**8;
      _initializeEIP712("AC");
    }

    /**
    * @dev Whitelist a Market Creator temporarily for one market
    * @param _userAdd Address of the creator
    */
    function addTemporaryMarketCreator(address _userAdd) external onlyAuthorized {
      require(_userAdd != address(0));
      oneTimeMarketCreator[_userAdd] = true;
    }

    /**
    * @dev Whitelisting Market Creators
    * @param _userAdd Address of the creator
    */
    function whitelistMarketCreator(address _userAdd) external onlyAuthorized {
      require(_userAdd != address(0));
      whiteListedMarketCreators[_userAdd] = true;
    }

    /**
    * @dev Removing user from whitelist
    * @param _userAdd Address of the creator
    */
    function deWhitelistMarketCreator(address _userAdd) external onlyAuthorized {
      require(_userAdd != address(0));
      whiteListedMarketCreators[_userAdd] = false;
    }

    /**
    * @dev Set the referral contract address, to handle referrals and their fees.
    * @param _referralContract Address of the referral contract
    */
    function setReferralContract(address _referralContract) external onlyAuthorized {
      require(address(referral) == address(0));
      referral = IReferral(_referralContract);
    }

    /**
    * @dev Unset the referral contract address
    */
    function removeReferralContract() external onlyAuthorized {
      require(address(referral) != address(0));
      delete referral;
    }

    /**
    * @dev Set the User levels contract address, to handle user multiplier.
    * @param _userLevelsContract Address of the UserLevels contract
    */
    function setUserLevelsContract(address _userLevelsContract) external onlyAuthorized {
      require(address(userLevels) == address(0));
      userLevels = IUserLevels(_userLevelsContract);
    }

    /**
    * @dev Unset the User levels contract address
    */
    function removeUserLevelsContract() external onlyAuthorized {
      require(address(userLevels) != address(0));
      delete userLevels;
    }

    /**
    * @dev Create the market.
    */
    function createMarket(string calldata _questionDetails, uint64[] calldata _optionRanges, uint32[] calldata _marketTimes,bytes8 _marketType, bytes32 _marketCurr, uint64 _marketInitialLiquidity) external {
      require(!paused);
      // address _marketCreator = _msgSender();
      require(whiteListedMarketCreators[_msgSender()] || oneTimeMarketCreator[_msgSender()]);
      delete oneTimeMarketCreator[_msgSender()];
      require(_marketInitialLiquidity >= minLiquidityByCreator);
      uint32[] memory _timesArray = new uint32[](_marketTimes.length+1);
      _timesArray[0] = uint32(now);
      _timesArray[1] = _marketTimes[0].sub(uint32(now));
      _timesArray[2] = _marketTimes[1].sub(uint32(now));
      _timesArray[3] = _marketTimes[2];
      uint64 _marketId = allMarkets.getTotalMarketsLength();
      
      marketData[_marketId].pricingData = PricingData(stakingFactorMinStake, stakingFactorWeightage, timeWeightage, minTimePassed);
      marketData[_marketId].marketCreator = _msgSender();
      allMarkets.createMarket(_timesArray, _optionRanges, _msgSender(), _marketInitialLiquidity);

      emit MarketParams(_marketId, _questionDetails, _optionRanges,_marketTimes, stakingFactorMinStake, minTimePassed, _msgSender(), _marketType, _marketCurr);
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    */
    function settleMarket(uint256 _marketId, uint _answer) public onlyAuthorized {
      allMarkets.settleMarket(_marketId, _answer);
      if(allMarkets.marketStatus(_marketId) >= IAllMarkets.PredictionStatus.InSettlement) {
        _transferAsset(plotToken, masterAddress, (10**predictionDecimalMultiplier).mul(marketFeeParams.daoFee[_marketId]));
        delete marketFeeParams.daoFee[_marketId];

    	  marketCreationReward[marketData[_marketId].marketCreator] = marketCreationReward[marketData[_marketId].marketCreator].add((10**predictionDecimalMultiplier).mul(marketFeeParams.marketCreatorFee[_marketId]));
        emit MarketCreatorReward(marketData[_marketId].marketCreator, _marketId, marketFeeParams.marketCreatorFee[_marketId]);
        delete marketFeeParams.marketCreatorFee[_marketId];
      }
    }


    /**
     * @dev Internal function to deduct fee from the prediction amount
     * @param _marketId Index of the market
     * @param _cummulativeFee Total fee amount
     * @param _msgSenderAddress User address
     */
    function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer) external onlyAllMarkets {
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      // _fee = _calculateAmulBdivC(_marketFeeParams.cummulativeFeePercent, _amount, 10000);
      uint64 _referrerFee = _calculateAmulBdivC(_marketFeeParams.referrerFeePercent, _cummulativeFee, 10000);
      uint64 _refereeFee = _calculateAmulBdivC(_marketFeeParams.refereeFeePercent, _cummulativeFee, 10000);
      bool _isEligibleForReferralReward;
      if(address(referral) != address(0)) {
      _isEligibleForReferralReward = referral.setReferralRewardData(_msgSenderAddress, plotToken, _referrerFee, _refereeFee);
      }
      if(_isEligibleForReferralReward){
        _transferAsset(plotToken, address(referral), (10**predictionDecimalMultiplier).mul(_referrerFee.add(_refereeFee)));
      } else {
        _refereeFee = 0;
        _referrerFee = 0;
      }
      uint64 _daoFee = _calculateAmulBdivC(_marketFeeParams.daoCommissionPercent, _cummulativeFee, 10000);
      uint64 _marketCreatorFee = _calculateAmulBdivC(_marketFeeParams.marketCreatorFeePercent, _cummulativeFee, 10000);
      _marketFeeParams.daoFee[_marketId] = _marketFeeParams.daoFee[_marketId].add(_daoFee);
      _marketFeeParams.marketCreatorFee[_marketId] = _marketFeeParams.marketCreatorFee[_marketId].add(_marketCreatorFee);
      _setRelayerFee(_relayer, _cummulativeFee, _daoFee, _referrerFee, _refereeFee, _marketCreatorFee);
    }

    /**
    * @dev Internal function to set the relayer fee earned in the prediction 
    */
    function _setRelayerFee(address _relayer, uint _cummulativeFee, uint _daoFee, uint _referrerFee, uint _refereeFee, uint _marketCreatorFee) internal {
      relayerFeeEarned[_relayer] = relayerFeeEarned[_relayer].add(_cummulativeFee.sub(_daoFee).sub(_referrerFee).sub(_refereeFee).sub(_marketCreatorFee));
    }

    /**
    * @dev Internal function to calculate prediction points  and multiplier
    * @param _user User Address
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _stake Amount staked by the user
    */
    function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) external returns(uint64 predictionPoints){
      bool isMultiplierApplied;
      (predictionPoints, isMultiplierApplied) = calculatePredictionPoints(_marketId, _prediction, _user, multiplierApplied[_user][_marketId], _stake);
      if(isMultiplierApplied) {
        multiplierApplied[_user][_marketId] = true; 
      }
    }

    /**
    * @dev Internal function to calculate prediction points
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _user User Address
    * @param multiplierApplied Flag defining if user had already availed multiplier
    * @param _predictionStake Amount staked by the user
    */
    function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      uint _stakeValue = _predictionStake.mul(1e10);
      if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
        return (0, isMultiplierApplied);
      }
      uint64 _optionPrice = getOptionPrice(_marketId, _prediction);
      predictionPoints = uint64(_predictionStake).div(_optionPrice);
      if(!multiplierApplied) {
        uint256 _predictionPoints = predictionPoints;
        if(address(userLevels) != address(0)) {
          (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
        }
        predictionPoints = uint64(_predictionPoints);
      }
    }

    /**
    * @dev Check if user gets any multiplier on his positions
    * @param _user User address
    * @param _predictionPoints The actual positions user got during prediction.
    * @return uint256 representing multiplied positions
    * @return bool returns true if multplier applied
    */
    function checkMultiplier(address _user, uint _predictionPoints) internal view returns(uint, bool) {
      bool _multiplierApplied;
      uint _muliplier = 100;
      (uint256 _userLevel, uint256 _levelMultiplier) = userLevels.getUserLevelAndMultiplier(_user);
      if(_userLevel > 0) {
        _muliplier = _muliplier + _levelMultiplier;
        _multiplierApplied = true;
      }
      return (_predictionPoints.mul(_muliplier).div(100), _multiplierApplied);
    }

    /**
    * @dev Claim fees earned by the relayer address
    */
    function claimRelayerRewards() external {
      uint _decimalMultiplier = 10**predictionDecimalMultiplier;
      address _relayer = msg.sender;
      uint256 _fee = (_decimalMultiplier).mul(relayerFeeEarned[_relayer]);
      delete relayerFeeEarned[_relayer];
      require(_fee > 0);
      _transferAsset(plotToken, _relayer, _fee);
    }

    /**
    * @dev Basic function to perform mathematical operation of (`_a` * `_b` / `_c`)
    * @param _a value of variable a
    * @param _b value of variable b
    * @param _c value of variable c
    */
    function _calculateAmulBdivC(uint64 _a, uint64 _b, uint64 _c) internal pure returns(uint64) {
      return _a.mul(_b).div(_c);
    }

    /**
    * @dev function to reward user for initiating market creation calls as per the new incetive calculations
    */
    function claimCreationReward() external {
      address payable _msgSenderAddress = _msgSender();
      uint256 rewardEarned = marketCreationReward[_msgSenderAddress];
      delete marketCreationReward[_msgSenderAddress];
      require(rewardEarned > 0, "No pending");
      _transferAsset(plotToken, _msgSenderAddress, rewardEarned);
      emit ClaimedMarketCreationReward(_msgSenderAddress, rewardEarned, plotToken);
    }

    /**
    * @dev Transfer the assets to specified address.
    * @param _asset The asset transfer to the specific address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

    /**
    * @dev function to get pending reward of user for initiating market creation calls as per the new incetive calculations
    * @param _user Address of user for whom pending rewards to be checked
    * @return tokenIncentive Incentives given for creating market as per the gas consumed
    * @return pendingTokenReward prediction token Reward pool share of markets created by user
    */
    function getPendingMarketCreationRewards(address _user) external view returns(uint256 tokenIncentive){
      return marketCreationReward[_user];
    }

    /**
    * @dev Set the flag to pause/resume market creation of particular market type
    */
    function toggleMarketCreation(bool _flag) external onlyAuthorized {
      require(paused != _flag);
      paused = _flag;
    }

    /**
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      require(marketData[_marketId].marketCreator != address(0),"Invalid Market id");
      uint optionLen = allMarkets.getTotalOptions(_marketId);
      (uint[] memory _optionPricingParams,) = allMarkets.getMarketOptionPricingParams(_marketId,_prediction);
      PricingData storage _marketPricingData = marketData[_marketId].pricingData;
      
      // Checking if current stake in market reached minimum stake required for considering staking factor.
      if(_optionPricingParams[1] < _marketPricingData.stakingFactorMinStake || _optionPricingParams[0] == 0)
      {

        return uint64(uint(100000).div(optionLen));

      } else {
        return uint64(uint(100000).mul(_optionPricingParams[0]).div(_optionPricingParams[1]));
      }

    }

    /**
     * @dev Gets price for all the options in a market
     * @param _marketId  Market ID
     * @return _optionPrices array consisting of prices for all available options
     **/
    function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
     uint optionLen = allMarkets.getTotalOptions(_marketId);
     _optionPrices = new uint64[](optionLen);
      for(uint i=0;i<optionLen;i++) {
        _optionPrices[i] = getOptionPrice(_marketId,i+1);
      }

    }

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "CPW") { // Acyclic contracts don't have Current price weighage but time weightage
        value = timeWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        value = stakingFactorMinStake;
      } else if(code == "MINP") { // Minimum prediction amount
        value = minPredictionAmount;
      } else if(code == "MAXP") { // Maximum prediction amount
        value = maxPredictionAmount;
      } else if(code == "CMFP") { // Cummulative fee percent
        value = marketFeeParams.cummulativeFeePercent;
      } else if(code == "DAOF") { // DAO Fee percent in Cummulative fee
        value = marketFeeParams.daoCommissionPercent;
      } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
        value = marketFeeParams.referrerFeePercent;
      } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
        value = marketFeeParams.refereeFeePercent;
      } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
        value = marketFeeParams.marketCreatorFeePercent;
      } else if(code == "MTP") {
        value = minTimePassed;
      } else if(code == "MLC") {
        value = minLiquidityByCreator;
      }
    }

    /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "CPW") { // Acyclic contracts don't have Current price weighage but time weightage
        require(value <= 100);
        timeWeightage = uint32(value);
        //Staking factor weightage% = 100% - timeWeightage%
        stakingFactorWeightage = 100 - timeWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        stakingFactorMinStake = value;
      } else if(code == "MINP") { // Minimum prediction amount
        minPredictionAmount = value;
      } else if(code == "MAXP") { // Maximum prediction amount
        maxPredictionAmount = value;
      } else if(code == "MTP") {
        uint32 _val = uint32(value);
        require(_val == value); // to avoid overflow while type casting
        minTimePassed = _val;
      } else if(code == "MLC") {
        uint64 _val = uint64(value);
        require(_val == value); // to avoid overflow while type casting
        minLiquidityByCreator = _val;
      } else {
        MarketFeeParams storage _marketFeeParams = marketFeeParams;
        require(value < 10000);
        if(code == "CMFP") { // Cummulative fee percent
          _marketFeeParams.cummulativeFeePercent = uint32(value);
        } else {
          if(code == "DAOF") { // DAO Fee percent in Cummulative fee
            _marketFeeParams.daoCommissionPercent = uint32(value);
          } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
            _marketFeeParams.referrerFeePercent = uint32(value);
          } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
            _marketFeeParams.refereeFeePercent = uint32(value);
          } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
            _marketFeeParams.marketCreatorFeePercent = uint32(value);
          } else {
            revert("Invalid code");
          } 
          require(
            _marketFeeParams.daoCommissionPercent + 
            _marketFeeParams.referrerFeePercent + 
            _marketFeeParams.refereeFeePercent + 
            _marketFeeParams.marketCreatorFeePercent
            < 10000);
        }
      }
    }
}