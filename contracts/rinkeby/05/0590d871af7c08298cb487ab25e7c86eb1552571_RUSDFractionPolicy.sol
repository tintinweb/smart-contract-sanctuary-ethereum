/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

    pragma solidity 0.7.6;


    /**
    * @title Initializable
    *
    * @dev Helper contract to support initializer functions. To use it, replace
    * the constructor with a function that has the `initializer` modifier.
    * WARNING: Unlike constructors, initializer functions must be manually
    * invoked. This applies both to deploying an Initializable contract, as well
    * as extending an Initializable contract via inheritance.
    * WARNING: When used with inheritance, manual care must be taken to not invoke
    * a parent initializer twice, or ensure that all initializers are idempotent,
    * because this is not dealt with automatically as with constructors.
    */
    contract Initializable {
        /**
        * @dev Indicates that the contract has been initialized.
        */
        bool private initialized;

        /**
        * @dev Indicates that the contract is in the process of being initialized.
        */
        bool private initializing;

        /**
        * @dev Modifier to use in the initializer function of a contract.
        */
        modifier initializer() {
            require(
                initializing || isConstructor() || !initialized,
                "Contract instance has already been initialized"
            );

            bool wasInitializing = initializing;
            initializing = true;
            initialized = true;

            _;

            initializing = wasInitializing;
        }

        /// @dev Returns true if and only if the function is running in the constructor
        function isConstructor() private view returns (bool) {
            // extcodesize checks the size of the code stored in an address, and
            // address returns the current address. Since the code is still not
            // deployed when running a constructor, any checks on its code size will
            // yield zero, making it an effective way to detect if a contract is
            // under construction or not.

            // MINOR CHANGE HERE:

            // previous code
            // uint256 cs;
            // assembly { cs := extcodesize(address) }
            // return cs == 0;

            // current code
            address _self = address(this);
            uint256 cs;
            assembly {
                cs := extcodesize(_self)
            }
            return cs == 0;
        }

        // Reserved storage space to allow for layout changes in the future.
        uint256[50] private ______gap;
    }


    /**
    * @title Ownable
    * @dev The Ownable contract has an owner address, and provides basic authorization control
    * functions, this simplifies the implementation of "user permissions".
    */
    contract Ownable is Initializable {
        address private _owner;

        event OwnershipRenounced(address indexed previousOwner);
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        /**
        * @dev The Ownable constructor sets the original `owner` of the contract to the sender
        * account.
        */
        function initialize(address sender) public virtual initializer {
            _owner = sender;
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
        * @notice Renouncing to ownership will leave the contract without an owner.
        * It will not be possible to call the functions with the `onlyOwner`
        * modifier anymore.
        */
        function renounceOwnership() public onlyOwner {
            emit OwnershipRenounced(_owner);
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

        uint256[50] private ______gap;
    }


    /**
    * @title SafeMath
    * @dev Math operations with safety checks that revert on error
    */
    library SafeMath {
        /**
        * @dev Multiplies two numbers, reverts on overflow.
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
        * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            require(b > 0); // Solidity only automatically asserts when dividing by 0
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        /**
        * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
        */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            require(b <= a);
            uint256 c = a - b;

            return c;
        }

        /**
        * @dev Adds two numbers, reverts on overflow.
        */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a);

            return c;
        }

        /**
        * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
        * reverts when dividing by zero.
        */
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            require(b != 0);
            return a % b;
        }
    }


    /**
    * @title SafeMathInt
    * @dev Math operations for int256 with overflow safety checks.
    */
    library SafeMathInt {
        int256 private constant MIN_INT256 = int256(1) << 255;
        int256 private constant MAX_INT256 = ~(int256(1) << 255);

        /**
        * @dev Multiplies two int256 variables and fails on overflow.
        */
        function mul(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a * b;

            // Detect overflow when multiplying MIN_INT256 with -1
            require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
            require((b == 0) || (c / b == a));
            return c;
        }

        /**
        * @dev Division of two int256 variables and fails on overflow.
        */
        function div(int256 a, int256 b) internal pure returns (int256) {
            // Prevent overflow when dividing MIN_INT256 by -1
            require(b != -1 || a != MIN_INT256);

            // Solidity already throws when dividing by 0.
            return a / b;
        }

        /**
        * @dev Subtracts two int256 variables and fails on overflow.
        */
        function sub(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a - b;
            require((b >= 0 && c <= a) || (b < 0 && c > a));
            return c;
        }

        /**
        * @dev Adds two int256 variables and fails on overflow.
        */
        function add(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a + b;
            require((b >= 0 && c >= a) || (b < 0 && c < a));
            return c;
        }

        /**
        * @dev Converts to absolute value, and fails on overflow.
        */
        function abs(int256 a) internal pure returns (int256) {
            require(a != MIN_INT256);
            return a < 0 ? -a : a;
        }
    }

    library UInt256Lib {
        uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

        /**
        * @dev Safely converts a uint256 to an int256.
        */
        function toInt256Safe(uint256 a) internal pure returns (int256) {
            require(a <= MAX_INT256);
            return int256(a);
        }
    }

    interface IRUSDFraction {
        function totalSupply() external view returns (uint256);

        function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
    }

    interface IProviderPair{
        function getReserves() external view returns (uint112, uint112, uint32);
        function sync() external;
    }

    contract RUSDFractionPolicy is Ownable {
        using SafeMath for uint256;
        using SafeMathInt for int256;
        using UInt256Lib for uint256;

        event LogRebase(
            uint256 indexed epoch,
            uint256 exchangeRate,
            uint256 targetRate,
            int256 requestedSupplyAdjustment,
            uint256 timestampSec
        );

        IRUSDFraction public rusdFracs;
        IProviderPair[] public providerPairs;

        IProviderPair public ratePair;

        // If the current exchange rate is within this fractional distance from the target, no supply
        // update is performed.
        // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
        // DECIMALS Fixed point number.
        uint256 public deviationThreshold;

        // The number of rebase cycles since inception
        uint256 public epoch;

        uint256 private constant DECIMALS = 9;

        // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
        // Both are 9 decimals fixed point numbers.
        uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS; 
        // MAX_SUPPLY = MAX_INT256 / MAX_RATE
        uint256 private constant MAX_SUPPLY = uint256(type(int256).max) / MAX_RATE;

        // This module handles the rebase execution and downstream notification.
        address public handler;

        modifier onlyHandler() {
            require(msg.sender == handler);
            _;
        }

        function numDigits(uint112 number) internal pure returns (uint112) {
            uint8 digits = 0;
            while (number != 0) {
                number= number/10;
                digits++;
            }
            return digits;
        }

        function getpricedata() public view returns (uint256){
            // uint256 totalAverageRate;
            // index 0 will be the max provider with max liquidity
            uint112 reserve0;
            uint112 reserve1;
            uint32 timestamp;
            uint256 exchangeRate;
            (reserve0, reserve1, timestamp) = IProviderPair(ratePair).getReserves();
            // Check which coin is lesser decimal
            uint reserve0Decimal= numDigits(reserve0);
            uint reserve1Decimal= numDigits(reserve1);
            uint256 decimalDiff;
            if(reserve0Decimal>reserve1Decimal){
                decimalDiff= reserve0Decimal-reserve1Decimal;
                reserve1= uint112(reserve1* 10**decimalDiff);
            }else{
                decimalDiff= reserve1Decimal-reserve0Decimal;
                reserve0= uint112(reserve0* 10**decimalDiff);
            }   
            exchangeRate = (uint256(10**DECIMALS *reserve1/reserve0)); 
            // totalAverageRate= totalAverageRate.add(exchangeRate);
            return (exchangeRate);
        }

        /**
        * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
        *
        * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate)
        *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
        *      and targetRate is fixed to 1.
        */
        function rebase() external onlyHandler{
            epoch = epoch.add(1);

            uint256 targetRate= 10**DECIMALS;   // $1
            uint256 exchangeRate;

            (exchangeRate) = getpricedata();
            if (exchangeRate > MAX_RATE) {
                exchangeRate = MAX_RATE;
            }
            int256 supplyDelta = computeSupplyDelta(exchangeRate, targetRate);
            
            if (supplyDelta > 0 && rusdFracs.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
                supplyDelta = (MAX_SUPPLY.sub(rusdFracs.totalSupply())).toInt256Safe();
            }

            uint256 supplyAfterRebase = rusdFracs.rebase(epoch, supplyDelta);
            assert(supplyAfterRebase <= MAX_SUPPLY);
            for(uint i=0;i<providerPairs.length ;i++){
            IProviderPair(providerPairs[i]).sync();
            }
            emit LogRebase(epoch, exchangeRate, targetRate, supplyDelta, block.timestamp);
        }

        /**
        * @notice Adds providers to calculate exchange data.
        * @param _providerPair The address of the providerPair contract.
        */
        function addProviderPair(IProviderPair _providerPair) external onlyOwner {
            if(providerPairs.length == 0){
                ratePair = _providerPair;
            }
            require(providerPairs.length <= 10,"cannot add more than 10");
            providerPairs.push(_providerPair);
        }

        function setRUSDStableProvider(IProviderPair _ratePair) external onlyOwner {
            ratePair= _ratePair;
        }

        /**
        * @notice Sets the reference to the handler.
        * @param handler_ The address of the handler contract.
        */
        function setHandler(address handler_) external onlyOwner {
            handler = handler_;
        }

        /**
        * @notice Sets the deviation threshold fraction. If the exchange rate given by the market
        *         oracle is within this fractional distance from the targetRate, then no supply
        *         modifications are made. DECIMALS fixed point number.
        * @param deviationThreshold_ The new exchange rate threshold fraction.
        */
        function setDeviationThreshold(uint256 deviationThreshold_) external onlyOwner {
            deviationThreshold = deviationThreshold_;
        }

        /**
        * @notice A multi-chain RUSD interface method. The Reflecto monetary policy contract
        *         on the base-chain and XC-ReflectoController contracts on the satellite-chains
        *         implement this method. It atomically returns two values:
        *         what the current contract believes to be,
        *         the globalReflectoEpoch and globalRUSDSupply.
        * @return globalReflectoEpoch The current epoch number.
        * @return globalRUSDSupply The total supply at the current epoch.
        */
        function globalReflectoEpochAndRUSDSupply() external view returns (uint256, uint256) {
            return (epoch, rusdFracs.totalSupply());
        }

        /**
        * @dev ZOS upgradable contract initialization method.
        *      It is called at the time of contract creation to invoke parent class initializers and
        *      initialize the contract's state variables.
        */
        function initialize(
            address owner_,
            IRUSDFraction rusdFracs_
        ) public initializer {
            Ownable.initialize(owner_);
            // deviationThreshold = 0.05e18 = 5e16
            deviationThreshold = 5 * 10**(DECIMALS - 2);
            epoch = 0;
            rusdFracs = rusdFracs_;
        }

        /**
        * @return Computes the total supply adjustment in response to the exchange rate
        *         and the targetRate.
        */
        function computeSupplyDelta(uint256 rate, uint256 targetRate) internal view returns (int256) {
            if (withinDeviationThreshold(rate, targetRate)) {
                return 0;
            }

            // supplyDelta = totalSupply * (rate - targetRate) / targetRate
            int256 targetRateSigned = targetRate.toInt256Safe();
            return
                rusdFracs.totalSupply().toInt256Safe().mul(rate.toInt256Safe().sub(targetRateSigned)).div(
                    targetRateSigned
                );
        }

        /**
        * @param rate The current exchange rate, an 18 decimal fixed point number.
        * @param targetRate The target exchange rate, an 18 decimal fixed point number.
        * @return If the rate is within the deviation threshold from the target rate, returns true.
        *         Otherwise, returns false.
        */

        function withinDeviationThreshold(uint256 rate, uint256 targetRate)
            internal
            view
            returns (bool)
        {
            uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold).div(10**DECIMALS);

            return
                (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold) ||
                (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
        }
    }