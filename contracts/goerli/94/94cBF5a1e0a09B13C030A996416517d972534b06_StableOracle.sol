pragma solidity 0.5.8;

import "../interfaces/IOracle.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract StableOracle is IOracle, Ownable {
    using SafeMath for uint256;

    IOracle public oracle;
    uint256 public lastPrice;
    uint256 public evictPercentage; //% multiplid by 10**16

    bool public manualOverride;
    uint256 public manualPrice;

    /*solium-disable-next-line security/no-block-members*/
    event ChangeOracle(address _oldOracle, address _newOracle);
    event ChangeEvictPercentage(uint256 _oldEvictPercentage, uint256 _newEvictPercentage);
    event SetManualPrice(uint256 _oldPrice, uint256 _newPrice);
    event SetManualOverride(bool _override);

    /**
      * @notice Creates a new stable oracle based on existing oracle
      * @param _oracle address of underlying oracle
      */
    constructor(address _oracle, uint256 _evictPercentage) public {
        require(_oracle != address(0), "Invalid oracle");
        oracle = IOracle(_oracle);
        evictPercentage = _evictPercentage;
    }

    /**
      * @notice Updates medianizer address
      * @param _oracle Address of underlying oracle
      */
    function changeOracle(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Invalid oracle");
        /*solium-disable-next-line security/no-block-members*/
        emit ChangeOracle(address(oracle), _oracle);
        oracle = IOracle(_oracle);
    }

    /**
      * @notice Updates eviction percentage
      * @param _evictPercentage Percentage multiplied by 10**16
      */
    function changeEvictPercentage(uint256 _evictPercentage) public onlyOwner {
        emit ChangeEvictPercentage(evictPercentage, _evictPercentage);
        evictPercentage = _evictPercentage;
    }

    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address) {
        return oracle.getCurrencyAddress();
    }

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32) {
        return oracle.getCurrencySymbol();
    }

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32) {
        return oracle.getCurrencyDenominated();
    }

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external returns(uint256) {
        if (manualOverride) {
            return manualPrice;
        }
        uint256 currentPrice = oracle.getPrice();
        if ((lastPrice == 0) || (_change(currentPrice, lastPrice) >= evictPercentage)) {
            lastPrice = currentPrice;
        }
        return lastPrice;
    }

    function _change(uint256 _newPrice, uint256 _oldPrice) internal pure returns(uint256) {
        uint256 diff = _newPrice > _oldPrice ? _newPrice.sub(_oldPrice) : _oldPrice.sub(_newPrice);
        return diff.mul(10**18).div(_oldPrice);
    }

    /**
      * @notice Set a manual price. NA - this will only be used if manualOverride == true
      * @param _price Price to set
      */
    function setManualPrice(uint256 _price) public onlyOwner {
        /*solium-disable-next-line security/no-block-members*/
        emit SetManualPrice(manualPrice, _price);
        manualPrice = _price;
    }

    /**
      * @notice Determine whether manual price is used or not
      * @param _override Whether to use the manual override price or not
      */
    function setManualOverride(bool _override) public onlyOwner {
        manualOverride = _override;
        /*solium-disable-next-line security/no-block-members*/
        emit SetManualOverride(_override);
    }

}

pragma solidity 0.5.8;

interface IOracle {
    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address currency);

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32 symbol);

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32 denominatedCurrency);

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external returns(uint256 price);

}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;

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