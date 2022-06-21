// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./LANDAuctionStorage.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./InterfaceERC20.sol";




contract LANDAuction is Ownable, LANDAuctionStorage {
    using SafeMath for uint256;
    using Address for address;
    // using SafeERC20 for IERC20;

    /**
    * @dev Constructor of the contract.
    * Note that the last value of _xPoints will be the total duration and
    * the first value of _yPoints will be the initial price and the last value will be the endPrice
    * @param _xPoints - uint256[] of seconds
    * @param _yPoints - uint256[] of prices
    * @param _startTime - uint256 timestamp in seconds when the auction will start
    * @param _landsLimitPerBid - uint256 LAND limit for a single bid
    * @param _manaToken - address of the MANA token
    * @param _landRegistry - address of the LANDRegistry
    */
    constructor(
        uint256[] memory _xPoints, 
        uint256[] memory _yPoints, 
        uint256 _startTime,
        uint256 _landsLimitPerBid,
        InterfaceERC20 _manaToken,
        LANDRegistry _landRegistry
    ) public {
        require(
            PERCENTAGE_OF_TOKEN_BALANCE == 5, 
            "Balance of tokens required should be equal to 5%"
        );
        // Initialize owneable

        Ownable.owner();
        // Ownable.initialize(msg.sender);

        // Schedule auction
        require(_startTime > block.timestamp, "Started time should be after now");
        startTime = _startTime;

        // Set LANDRegistry
        require(
            address(_landRegistry).isContract(),
            "The LANDRegistry token address must be a deployed contract"
        );
        landRegistry = _landRegistry;

        // Set MANAToken
        allowToken(
            address(_manaToken), 
            18,
            true, 
            false, 
            address(0)
        );
        manaToken = _manaToken;

        // Set total duration of the auction
        duration = _xPoints[_xPoints.length - 1];
        require(duration > 1 days, "The duration should be greater than 1 day");

        // Set Curve
        _setCurve(_xPoints, _yPoints);

        // Set limits
        setLandsLimitPerBid(_landsLimitPerBid);
        
        // Initialize status
        status = Status.created;      

        emit AuctionCreated(
            msg.sender,
            startTime,
            duration,
            initialPrice, 
            endPrice
        );
    }

    /**
    * @dev Make a bid for LANDs
    * @param _xs - uint256[] x values for the LANDs to bid
    * @param _ys - uint256[] y values for the LANDs to bid
    * @param _beneficiary - address beneficiary for the LANDs to bid
    * @param _fromToken - token used to bid
    */
    function bid(
        int[] memory _xs, 
        int[] memory _ys, 
        address _beneficiary, 
        InterfaceERC20 _fromToken
    )
        external 
    {
        _validateBidParameters(
            _xs, 
            _ys, 
            _beneficiary, 
            _fromToken
        );
        
        uint256 bidId = _getBidId();
        uint256 bidPriceInMana = _xs.length.mul(getCurrentPrice());
        uint256 manaAmountToBurn = bidPriceInMana;

        // if (address(_fromToken) != address(manaToken)) {
            // require(
            //     address(dex).isContract(), 
            //     "Paying with other tokens has been disabled"
            // );
            // Convert from the other token to MANA. The amount to be burned might be smaller
            // because 5% will be burned or forwarded without converting it to MANA.
            // manaAmountToBurn = _convertSafe(bidId, _fromToken, bidPriceInMana);
        // } else {
            // Transfer MANA to this contract
            require( _fromToken.transferFrom(msg.sender, address(this), bidPriceInMana),"Insuficient balance or unauthorized amount (transferFrom failed)");
        // }

        // Process funds (burn or forward them)
        _processFunds(bidId, _fromToken);

        // Assign LANDs to the beneficiary user
        landRegistry.assignMultipleParcels(_xs, _ys, _beneficiary);

        emit BidSuccessful(
            bidId,
            _beneficiary,
            address(_fromToken),
            getCurrentPrice(),
            manaAmountToBurn,
            _xs,
            _ys
        );  

        // Update stats
        _updateStats(_xs.length, manaAmountToBurn);        
    }

    /** 
    * @dev Validate bid function params
    * @param _xs - int[] x values for the LANDs to bid
    * @param _ys - int[] y values for the LANDs to bid
    * @param _beneficiary - address beneficiary for the LANDs to bid
    * @param _fromToken - token used to bid
    */
    function _validateBidParameters(
        int[] memory _xs, 
        int[] memory _ys, 
        address _beneficiary, 
        InterfaceERC20 _fromToken
    ) internal view 
    {
        require(startTime <= block.timestamp, "The auction has not started");
        require(
            status == Status.created && 
            block.timestamp.sub(startTime) <= duration, 
            "The auction has finished"
        );
        require(_beneficiary != address(0), "The beneficiary could not be the 0 address");
        require(_xs.length > 0, "You should bid for at least one LAND");
        require(_xs.length <= landsLimitPerBid, "LAND limit exceeded");
        require(_xs.length == _ys.length, "X values length should be equal to Y values length");
        require(tokensAllowed[address(_fromToken)].isAllowed, "Token not allowed");
        for (uint256 i = 0; i < _xs.length; i++) {
            require(
                -150 <= _xs[i] && _xs[i] <= 150 && -150 <= _ys[i] && _ys[i] <= 150,
                "The coordinates should be inside bounds -150 & 150"
            );
        }
    }

    /**
    * @dev Current LAND price. 
    * Note that if the auction has not started returns the initial price and when
    * the auction is finished return the endPrice
    * @return uint256 current LAND price
    */
    function getCurrentPrice() public view returns (uint256) { 
        // If the auction has not started returns initialPrice
        if (startTime == 0 || startTime >= block.timestamp) {
            return initialPrice;
        }

        // If the auction has finished returns endPrice
        uint256 timePassed = block.timestamp - startTime;
        if (timePassed >= duration) {
            return endPrice;
        }

        return _getPrice(timePassed);
    }

    /**
    * @dev Convert allowed token to MANA and transfer the change in the original token
    * Note that we will use the slippageRate cause it has a 3% buffer and a deposit of 5% to cover
    * the conversion fee.
    * @param _bidId - uint256 of the bid Id
    * @param _fromToken - ERC20 token to be converted
    * @param _bidPriceInMana - uint256 of the total amount in MANA
    * @return uint256 of the total amount of MANA to burn
    */
    // function _convertSafe(
    //     uint256 _bidId,
    //     ERC20 _fromToken,
    //     uint256 _bidPriceInMana
    // ) internal returns (uint256 requiredManaAmountToBurn)
    // {
    //     requiredManaAmountToBurn = _bidPriceInMana;
    //     Token memory fromToken = tokensAllowed[address(_fromToken)];

    //     uint256 bidPriceInManaPlusSafetyMargin = _bidPriceInMana.mul(conversionFee).div(100);

    //     // Get rate
    //     // uint256 tokenRate = getRate(manaToken, _fromToken, bidPriceInManaPlusSafetyMargin);

    //     // Check if contract should burn or transfer some tokens
    //     uint256 requiredTokenBalance = 0;
        
    //     if (fromToken.shouldBurnTokens || fromToken.shouldForwardTokens) {
    //         requiredTokenBalance = _calculateRequiredTokenBalance(requiredManaAmountToBurn, tokenRate);
    //         requiredManaAmountToBurn = _calculateRequiredManaAmount(_bidPriceInMana);
    //     }

    //     // Calculate the amount of _fromToken to be converted
    //     uint256 tokensToConvertPlusSafetyMargin = bidPriceInManaPlusSafetyMargin
    //         .mul(tokenRate)
    //         .div(10 ** 18);

    //     // Normalize to _fromToken decimals
    //     if (MAX_DECIMALS > fromToken.decimals) {
    //         requiredTokenBalance = _normalizeDecimals(
    //             fromToken.decimals, 
    //             requiredTokenBalance
    //         );
    //         tokensToConvertPlusSafetyMargin = _normalizeDecimals(
    //             fromToken.decimals,
    //             tokensToConvertPlusSafetyMargin
    //         );
    //     }

    //     // Retrieve tokens from the sender to this contract
    //     require(
    //         _fromToken.safeTransferFrom(msg.sender, address(this), tokensToConvertPlusSafetyMargin),
    //         "Transfering the totalPrice in token to LANDAuction contract failed"
    //     );
        
    //     // Calculate the total tokens to convert
    //     uint256 finalTokensToConvert = tokensToConvertPlusSafetyMargin.sub(requiredTokenBalance);

    //     // Approve amount of _fromToken owned by contract to be used by dex contract
    //     // require(_fromToken.safeApprove(address(dex), finalTokensToConvert), "Error approve");

    //     // Convert _fromToken to MANA
    //     // uint256 change = dex.convert(
    //     //         _fromToken,
    //     //         manaToken,
    //     //         finalTokensToConvert,
    //     //         requiredManaAmountToBurn
    //     // );

    //    // Return change in _fromToken to sender
    //     // if (change > 0) {
    //     //     // Return the change of src token
    //     //     require(
    //     //         _fromToken.safeTransfer(msg.sender, change),
    //     //         "Transfering the change to sender failed"
    //     //     );
    //     // }

    //     // Remove approval of _fromToken owned by contract to be used by dex contract
    //     // require(_fromToken.clearApprove(address(dex)), "Error clear approval");

    //     emit BidConversion(
    //         _bidId,
    //         address(_fromToken),
    //         requiredManaAmountToBurn,
    //         // tokensToConvertPlusSafetyMargin.sub(change),
    //         requiredTokenBalance
    //     );
    // }

    /**
    * @dev Get exchange rate
    * @param _srcToken - IERC20 token
    * @param _destToken - IERC20 token 
    * @param _srcAmount - uint256 amount to be converted
    * @return uint256 of the rate
    */
    // function getRate(
    //     IERC20 _srcToken, 
    //     IERC20 _destToken, 
    //     uint256 _srcAmount
    // ) public view returns (uint256 rate) 
    // {
    //     (rate,) = dex.getExpectedRate(_srcToken, _destToken, _srcAmount);
    // }

    /** 
    * @dev Calculate the amount of tokens to process
    * @param _totalPrice - uint256 price to calculate percentage to process
    * @param _tokenRate - rate to calculate the amount of tokens
    * @return uint256 of the amount of tokens required
    */
    function _calculateRequiredTokenBalance(
        uint256 _totalPrice,
        uint256 _tokenRate
    ) 
    internal pure returns (uint256) 
    {
        return _totalPrice.mul(_tokenRate)
            .div(10 ** 18)
            .mul(PERCENTAGE_OF_TOKEN_BALANCE)
            .div(100);
    }

    /** 
    * @dev Calculate the total price in MANA
    * Note that PERCENTAGE_OF_TOKEN_BALANCE will be always less than 100
    * @param _totalPrice - uint256 price to calculate percentage to keep
    * @return uint256 of the new total price in MANA
    */
    function _calculateRequiredManaAmount(
        uint256 _totalPrice
    ) 
    internal pure returns (uint256)
    {
        return _totalPrice.mul(100 - PERCENTAGE_OF_TOKEN_BALANCE).div(100);
    }

    /**
    * @dev Burn or forward the MANA and other tokens earned
    * Note that as we will transfer or burn tokens from other contracts.
    * We should burn MANA first to avoid a possible re-entrancy
    * @param _bidId - uint256 of the bid Id
    * @param _token - ERC20 token
    */
    function _processFunds(uint256 _bidId, InterfaceERC20 _token) internal {
        // Burn MANA
        _burnTokens(_bidId, manaToken);

        // Burn or forward token if it is not MANA
        Token memory token = tokensAllowed[address(_token)];
        if (_token != manaToken) {
            if (token.shouldBurnTokens) {
                _burnTokens(_bidId, _token);
            }
            if (token.shouldForwardTokens) {
                _forwardTokens(_bidId, token.forwardTarget, _token);
            }   
        }
    }

    /**
    * @dev LAND price based on time
    * Note that will select the function to calculate based on the time
    * It should return endPrice if _time < duration
    * @param _time - uint256 time passed before reach duration
    * @return uint256 price for the given time
    */
    function _getPrice(uint256 _time) internal view returns (uint256) {
        for (uint256 i = 0; i < curves.length; i++) {
            Func storage func = curves[i];
            if (_time < func.limit) {
                return func.base.sub(func.slope.mul(_time));
            }
        }
        revert("Invalid time");
    }

    /** 
    * @dev Burn tokens
    * @param _bidId - uint256 of the bid Id
    * @param _token - ERC20 token
    */
    function _burnTokens(uint256 _bidId, InterfaceERC20 _token) private {
        uint256 balance = _token.balanceOf(address(this));

        // Check if balance is valid
        require(balance > 0, "Balance to burn should be > 0");
        
        _token.burn(balance);

        emit TokenBurned(_bidId, address(_token), balance);

        // Check if balance of the auction contract is empty
        balance = _token.balanceOf(address(this));
        require(balance == 0, "Burn token failed");
    }

    /** 
    * @dev Forward tokens
    * @param _bidId - uint256 of the bid Id
    * @param _address - address to send the tokens to
    * @param _token - ERC20 token
    */
    function _forwardTokens(uint256 _bidId, address _address, InterfaceERC20 _token) private {
        uint256 balance = _token.balanceOf(address(this));

        // Check if balance is valid
        require(balance > 0, "Balance to burn should be > 0");
        
        _token.transfer(_address, balance);

        emit TokenTransferred(
            _bidId, 
            address(_token), 
            _address,balance
        );

        // Check if balance of the auction contract is empty
        balance = _token.balanceOf(address(this));
        require(balance == 0, "Transfer token failed");
    }

    /**
    * @dev Set conversion fee rate
    * @param _fee - uint256 for the new conversion rate
    */
    // function setConversionFee(uint256 _fee) external onlyOwner {
    //     require(_fee < 200 && _fee >= 100, "Conversion fee should be >= 100 and < 200");
    //     emit ConversionFeeChanged(msg.sender, conversionFee, _fee);
    //     conversionFee = _fee;
    // }

    /**
    * @dev Finish auction 
    */
    function finishAuction() public onlyOwner {
        require(status != Status.finished, "The auction is finished");

        uint256 currentPrice = getCurrentPrice();

        status = Status.finished;
        endTime = block.timestamp;

        emit AuctionFinished(msg.sender, block.timestamp, currentPrice);
    }

    /**
    * @dev Set LAND for the auction
    * @param _landsLimitPerBid - uint256 LAND limit for a single id
    */
    function setLandsLimitPerBid(uint256 _landsLimitPerBid) public onlyOwner {
        require(_landsLimitPerBid > 0, "The LAND limit should be greater than 0");
        emit LandsLimitPerBidChanged(msg.sender, landsLimitPerBid, _landsLimitPerBid);
        landsLimitPerBid = _landsLimitPerBid;
    }

    /**
    * @dev Set gas price limit for the auction

    */

    /**
    * @dev Set dex to convert ERC20
    * @param _dex - address of the token converter
    */
    // function setDex(address _dex) public onlyOwner {
    //     require(_dex != address(dex), "The dex is the current");
    //     if (_dex != address(0)) {
    //         require(_dex.isContract(), "The dex address must be a deployed contract");
    //     }
    //     emit DexChanged(msg.sender, dex, _dex);
    //     dex = ITokenConverter(_dex);
    // }

    /**
    * @dev Allow ERC20 to to be used for bidding
    * Note that if _shouldBurnTokens and _shouldForwardTokens are false, we 
    * will convert the total amount of the ERC20 to MANA
    * @param _address - address of the ERC20 Token
    * @param _decimals - uint256 of the number of decimals
    * @param _shouldBurnTokens - boolean whether we should burn funds
    * @param _shouldForwardTokens - boolean whether we should transferred funds
    * @param _forwardTarget - address where the funds will be transferred
    */
    function allowToken(
        address _address,
        uint256 _decimals,
        bool _shouldBurnTokens,
        bool _shouldForwardTokens,
        address _forwardTarget
    ) 
    public onlyOwner 
    {
        require(
            _address.isContract(),
            "Tokens allowed should be a deployed ERC20 contract"
        );
        require(
            _decimals > 0 && _decimals <= MAX_DECIMALS,
            "Decimals should be greather than 0 and less or equal to 18"
        );
        require(
            !(_shouldBurnTokens && _shouldForwardTokens),
            "The token should be either burned or transferred"
        );
        require(
            !_shouldForwardTokens || 
            (_shouldForwardTokens && _forwardTarget != address(0)),
            "The token should be transferred to a deployed contract"
        );
        require(
            _forwardTarget != address(this) && _forwardTarget != _address, 
            "The forward target should be different from  this contract and the erc20 token"
        );
        
        require(!tokensAllowed[_address].isAllowed, "The ERC20 token is already allowed");

        tokensAllowed[_address] = Token({
            decimals: _decimals,
            shouldBurnTokens: _shouldBurnTokens,
            shouldForwardTokens: _shouldForwardTokens,
            forwardTarget: _forwardTarget,
            isAllowed: true
        });

        emit TokenAllowed(
            msg.sender, 
            _address, 
            _decimals,
            _shouldBurnTokens,
            _shouldForwardTokens,
            _forwardTarget
        );
    }

    /**
    * @dev Disable ERC20 to to be used for bidding
    * @param _address - address of the ERC20 Token
    */
    function disableToken(address _address) public onlyOwner {
        require(
            tokensAllowed[_address].isAllowed,
            "The ERC20 token is already disabled"
        );
        delete tokensAllowed[_address];
        emit TokenDisabled(msg.sender, _address);
    }

    /** 
    * @dev Create a combined function.
    * note that we will set N - 1 function combinations based on N points (x,y)
    * @param _xPoints - uint256[] of x values
    * @param _yPoints - uint256[] of y values
    */
    function _setCurve(uint256[] memory _xPoints, uint256[] memory _yPoints) internal {
        uint256 pointsLength = _xPoints.length;
        require(pointsLength == _yPoints.length, "Points should have the same length");
        for (uint256 i = 0; i < pointsLength - 1; i++) {
            uint256 x1 = _xPoints[i];
            uint256 x2 = _xPoints[i + 1];
            uint256 y1 = _yPoints[i];
            uint256 y2 = _yPoints[i + 1];
            require(x1 < x2, "X points should increase");
            require(y1 > y2, "Y points should decrease");
            (uint256 base, uint256 slope) = _getFunc(
                x1, 
                x2, 
                y1, 
                y2
            );
            curves.push(Func({
                base: base,
                slope: slope,
                limit: x2
            }));
        }

        initialPrice = _yPoints[0];
        endPrice = _yPoints[pointsLength - 1];
    }

    // /**
    // * @dev Calculate base and slope for the given points
    // * It is a linear function y = ax - b. But The slope should be negative.
    // * As we want to avoid negative numbers in favor of using uints we use it as: y = b - ax
    // * Based on two points (x1; x2) and (y1; y2)
    // * base = (x2 * y1) - (x1 * y2) / (x2 - x1)
    // * slope = (y1 - y2) / (x2 - x1) to avoid negative maths
    // * @param _x1 - uint256 x1 value
    // * @param _x2 - uint256 x2 value
    // * @param _y1 - uint256 y1 value
    // * @param _y2 - uint256 y2 value
    // * @return uint256 for the base
    // * @return uint256 for the slope
    // */
    function _getFunc(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1, 
        uint256 _y2
    ) internal pure returns (uint256 base, uint256 slope) 
    {
        base = ((_x2.mul(_y1)).sub(_x1.mul(_y2))).div(_x2.sub(_x1));
        slope = (_y1.sub(_y2)).div(_x2.sub(_x1));
    }

    /**
    * @dev Return bid id
    * @return uint256 of the bid id
    */
    function _getBidId() private view returns (uint256) {
        return totalBids;
    }

    /** 
    * @dev Normalize to _fromToken decimals
    * @param _decimals - uint256 of _fromToken decimals
    * @param _value - uint256 of the amount to normalize
    */
    function _normalizeDecimals(
        uint256 _decimals, 
        uint256 _value
    ) 
    internal pure returns (uint256 _result) 
    {
        _result = _value.div(10**MAX_DECIMALS.sub(_decimals));
    }

    /** 
    * @dev Update stats. It will update the following stats:
    * - totalBids
    * - totalLandsBidded
    * - totalManaBurned
    * @param _landsBidded - uint256 of the number of LAND bidded
    * @param _manaAmountBurned - uint256 of the amount of MANA burned
    */
    function _updateStats(uint256 _landsBidded, uint256 _manaAmountBurned) private {
        totalBids = totalBids.add(1);
        totalLandsBidded = totalLandsBidded.add(_landsBidded);
        totalManaBurned = totalManaBurned.add(_manaAmountBurned);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InterfaceERC20.sol";

/**
* @title ERC20 Interface with burn
* @dev IERC20 imported in ItokenConverter.sol
*/
abstract contract ERC20 is IERC20 {
    function burn(uint256 _value) public virtual;
}


/**
* @title Interface for contracts conforming to ERC-721
*/
abstract contract LANDRegistry {
    function assignMultipleParcels(int[] calldata x, int[] calldata y, address   beneficiary) external virtual;
}


contract LANDAuctionStorage {
    uint256 constant public PERCENTAGE_OF_TOKEN_BALANCE = 5;
    uint256 constant public MAX_DECIMALS = 18;

    enum Status { created, finished }

    struct Func {
        uint256 slope;
        uint256 base;
        uint256 limit;
    }

    struct Token {
        uint256 decimals;
        bool shouldBurnTokens;
        bool shouldForwardTokens;
        address forwardTarget;
        bool isAllowed;
    }

    uint256 public conversionFee = 105;
    uint256 public totalBids = 0;
    Status public status;
    uint256 public landsLimitPerBid;
    InterfaceERC20 public manaToken;
    LANDRegistry public landRegistry;
    mapping (address => Token) public tokensAllowed;
    uint256 public totalManaBurned = 0;
    uint256 public totalLandsBidded = 0;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public initialPrice;
    uint256 public endPrice;
    uint256 public duration;

    Func[] internal curves;

    event AuctionCreated(
      address indexed _caller,
      uint256 _startTime,
      uint256 _duration,
      uint256 _initialPrice,
      uint256 _endPrice
    );

    event BidConversion(
      uint256 _bidId,
      address indexed _token,
      uint256 _requiredManaAmountToBurn,
      uint256 _amountOfTokenConverted,
      uint256 _requiredTokenBalance
    );

    event BidSuccessful(
      uint256 _bidId,
      address indexed _beneficiary,
      address indexed _token,
      uint256 _pricePerLandInMana,
      uint256 _manaAmountToBurn,
      int[] _xs,
      int[] _ys
    );

    event AuctionFinished(
      address indexed _caller,
      uint256 _time,
      uint256 _pricePerLandInMana
    );

    event TokenBurned(
      uint256 _bidId,
      address indexed _token,
      uint256 _total
    );

    event TokenTransferred(
      uint256 _bidId,
      address indexed _token,
      address indexed _to,
      uint256 _total
    );

    event LandsLimitPerBidChanged(
      address indexed _caller,
      uint256 _oldLandsLimitPerBid, 
      uint256 _landsLimitPerBid
    );

    event GasPriceLimitChanged(
      address indexed _caller,
      uint256 _oldGasPriceLimit
    );

    // event DexChanged(
    //   address indexed _caller,
    //   address indexed _oldDex,
    //   address indexed _dex
    // );

    event TokenAllowed(
      address indexed _caller,
      address indexed _address,
      uint256 _decimals,
      bool _shouldBurnTokens,
      bool _shouldForwardTokens,
      address indexed _forwardTarget
    );

    event TokenDisabled(
      address indexed _caller,
      address indexed _address
    );

    // event ConversionFeeChanged(
    //   address indexed _caller,
    //   uint256 _oldConversionFee,
    //   uint256 _conversionFee
    // );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface InterfaceERC20 {
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

    function burn(uint256 balance) external returns (uint256);

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