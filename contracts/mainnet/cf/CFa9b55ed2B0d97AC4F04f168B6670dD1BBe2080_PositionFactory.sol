// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CloneFactory.sol";
import "./Position.sol";
import "./IFrankencoin.sol";

contract PositionFactory is CloneFactory {

    function createNewPosition(address _owner, address _zchf, address _collateral, 
        uint256 _minCollateral, uint256 _initialCollateral, 
        uint256 _initialLimit, uint256 _duration, uint256 _challengePeriod, 
        uint32 _mintingFeePPM, uint256 _liqPrice, uint32 _reserve) 
        external returns (address) 
    {
        return address(new Position(_owner, msg.sender, _zchf, _collateral, 
            _minCollateral, _initialCollateral, _initialLimit, _duration, 
            _challengePeriod, _mintingFeePPM, _liqPrice, _reserve));
    }

    /**
    * @notice clone an existing position. This can be a clone of another clone,
    * or an origin position. If it's another clone, then the liquidation price
    * is taken from the clone and the rest from the origin. Limit is "inherited"
    * (and adjusted) from the origin.
    * @param _existing     address of the position we want to clone
    * @return address of the newly created clone position
    */
    function clonePosition(address _existing) external returns (address) {
        Position existing = Position(_existing);
        Position clone = Position(createClone(existing.original()));
        return address(clone);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReserve.sol";

interface IFrankencoin is IERC20 {

    function suggestMinter(address _minter, uint256 _applicationPeriod, 
      uint256 _applicationFee, string calldata _message) external;

    function registerPosition(address position) external;

    function denyMinter(address minter, address[] calldata helpers, string calldata message) external;

    function reserve() external view returns (IReserve);

    function isMinter(address minter) external view returns (bool);

    function isPosition(address position) external view returns (address);
    
    function mint(address target, uint256 amount) external;

    function mint(address target, uint256 amount, uint32 reservePPM, uint32 feePPM) external;

    function burn(uint256 amountIncludingReserve, uint32 reservePPM) external;

    function burnFrom(address payer, uint256 targetTotalBurnAmount, uint32 _reservePPM) external returns (uint256);

    function burnWithReserve(uint256 amountExcludingReserve, uint32 reservePPM) external returns (uint256);

    function burn(address target, uint256 amount) external;

    function notifyLoss(uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IPosition.sol";
import "./IReserve.sol";
import "./IFrankencoin.sol";
import "./Ownable.sol";
import "./IERC677Receiver.sol";
import "./MathUtil.sol";

/**
 * A collateralized minting position.
 */
contract Position is Ownable, IERC677Receiver, IPosition, MathUtil {

    uint256 public constant INITIALIZATION_PERIOD = 7 days;
    uint256 public constant PRICE_ADJUSTMENT_COOLDOWN = 3 days;

    uint256 public price; // the zchf price per unit of the collateral below which challenges succeed, 18 to 36 digits
    uint256 public minted; // how much has been minted so far, including reserve
    uint256 public challengedAmount; // amount of the collateral that is currently under a challenge
    uint256 public immutable challengePeriod; //challenge period in timestamp units (seconds) for liquidation

    uint256 public cooldown;
    uint256 public limit; // how many zchf can be minted at most, including reserve
    uint256 public immutable expiration;

    address public immutable original; // originals point to themselves, clone to their origin
    address public immutable hub;
    IFrankencoin public immutable zchf; // currency
    IERC20 public override immutable collateral; // collateral
    uint256 public override immutable minimumCollateral; // prevent dust amounts

    uint32 public immutable mintingFeePPM;
    uint32 public immutable reserveContribution; // in ppm

    event PositionDenied(address indexed sender, string message);
    event MintingUpdate(uint256 collateral, uint256 price, uint256 minted, uint256 limit);
    event PositionOpened(address indexed owner, address original, address zchf, address collateral, uint256 price);

    /**
    * @param _owner             position owner address
    * @param _hub               address of minting hub
    * @param _zchf              ZCHF address
    * @param _collateral        collateral address
    * @param _minCollateral     minimum collateral required to prevent dust amounts
    * @param _initialCollateral amount of initial collateral to be deposited
    * @param _initialLimit      maximal amount of ZCHF that can be minted by the position owner (includes reserve)
    * @param _duration          position tenor in unit of timestamp (seconds) from 'now'
    * @param _challengePeriod   challenge period. Longer for less liquid collateral.
    * @param _mintingFeePPM     fee to enter position in parts per million of ZCHF amount
    * @param _liqPrice          Liquidation price (dec18) that together with the reserve and
    *                           fees determines the minimal collateralization ratio
    * @param _reservePPM        ZCHF pool reserve requirement in parts per million of ZCHF amount
    */
    constructor(address _owner, address _hub, address _zchf, address _collateral, 
        uint256 _minCollateral, uint256 _initialCollateral, 
        uint256 _initialLimit, uint256 _duration, uint256 _challengePeriod, uint32 _mintingFeePPM, 
        uint256 _liqPrice, uint32 _reservePPM) Ownable(_owner) {
        original = address(this);
        hub = _hub;
        price = _liqPrice;
        zchf = IFrankencoin(_zchf);
        collateral = IERC20(_collateral);
        mintingFeePPM = _mintingFeePPM;
        reserveContribution = _reservePPM;
        require(_initialCollateral >= _minCollateral);
        minimumCollateral = _minCollateral;
        expiration = block.timestamp + _duration;
        challengePeriod = _challengePeriod;
        restrictMinting(INITIALIZATION_PERIOD);
        limit = _initialLimit;
        
        emit PositionOpened(_owner, original, _zchf, address(collateral), _liqPrice);
    }

    function initializeClone(address owner, uint256 _price, uint256 _limit, uint256 _coll, uint256 _mint) external onlyHub {
        require(_coll >= minimumCollateral, "coll not enough");
        transferOwnership(owner);
        
        price = _mint * ONE_DEC18 / _coll;
        require(price <= _price, "can only reduce price on clone");
        limit = _limit;
        mintInternal(owner, _mint, _coll);

        emit PositionOpened(owner, original, address(zchf), address(collateral), _price);
    }

    /**
     * @notice adjust this position's limit to give away some limit to the clone
     *         invariant: global limit stays constant
     * @param _minimum  amount that clone wants to mint initially
     * @return limit for the clone
     */
    function reduceLimitForClone(uint256 _minimum) external noMintRestriction onlyHub returns (uint256) {
        require(minted + _minimum <= limit, "limit exceeded");
        uint256 reduction = (limit - minted - _minimum)/2;
        limit -= reduction + _minimum;
        return reduction + _minimum;
    }

    function deny(address[] calldata helpers, string calldata message) public {
        require(minted == 0, "minted"); // must deny before any tokens are minted
        require(IReserve(zchf.reserve()).isQualified(msg.sender, helpers), "not qualified");
        cooldown = expiration;
        emit PositionDenied(msg.sender, message);
    }

    /**
     * This is how much the minter can actually use when minting ZCHF, with the rest being used
     * to buy reserve pool shares.
     */
    function getUsableMint(uint256 totalMint, bool beforeFees) public view returns (uint256){
        if (beforeFees){
            return totalMint * (1000_000 - reserveContribution) / 1000_000;
        } else {
            return totalMint * (1000_000 - reserveContribution - mintingFeePPM) / 1000_000;
        }
    }

    function adjust(uint256 newMinted, uint256 newCollateral, uint256 newPrice) public {
        if (newPrice != price){
            adjustPrice(newPrice);
        }
        uint256 colbal = collateralBalance();
        if (newCollateral > colbal){
            collateral.transferFrom(msg.sender, address(this), newCollateral - colbal);
        }
        if (newMinted < minted){
            zchf.burnFrom(msg.sender, minted - newMinted, reserveContribution);
            minted = newMinted;
        }
        if (newCollateral < colbal){
            withdrawCollateral(msg.sender, colbal - newCollateral);
        }
        if (newMinted > minted){
            mint(msg.sender, newMinted - minted);
        }
    }

    function adjustPrice(uint256 newPrice) public onlyOwner noChallenge {
        if (newPrice > price) {
            restrictMinting(PRICE_ADJUSTMENT_COOLDOWN);
        } else {
            require(isWellCollateralized(collateralBalance(), newPrice));
        }
        price = newPrice;
        emitUpdate();
    }

    function collateralBalance() internal view returns (uint256){
        return IERC20(collateral).balanceOf(address(this));
    }

    function mint(address target, uint256 amount) public onlyOwner noChallenge noMintRestriction {
        mintInternal(target, amount, collateralBalance());
    }

    function mintInternal(address target, uint256 amount, uint256 collateral_) internal {
        require(minted + amount <= limit, "limit exceeded");
        zchf.mint(target, amount, reserveContribution, mintingFeePPM);
        minted += amount;

        require(isWellCollateralized(collateral_, price), "not well collateralized");
        emitUpdate();
    }

    function restrictMinting(uint256 period) internal {
        uint256 horizon = block.timestamp + period;
        if (horizon > cooldown){
            cooldown = horizon;
        }
    }
    
    function onTokenTransfer(address, uint256 amount, bytes calldata) override external returns (bool) {
        if (msg.sender == address(zchf)){
            repayInternal(amount);
        } else {
            require(false);
        }
        return true;
    }

    function repay(uint256 amount) public onlyOwner {
        IERC20(zchf).transferFrom(msg.sender, address(this), amount);
        repayInternal(amount);
    }

    function repayInternal(uint256 burnable) internal noChallenge {
        uint256 actuallyBurned = IFrankencoin(zchf).burnWithReserve(burnable, reserveContribution);
        notifyRepaidInternal(actuallyBurned);
        emitUpdate();
    }

    function notifyRepaidInternal(uint256 amount) internal {
        require(amount <= minted);
        minted -= amount;
    }

    /**
     * Withdraw any token that might have ended up on this address, except for collateral
     * and reserve tokens, which also serve as a collateral.
     */
    function withdraw(address token, address target, uint256 amount) external onlyOwner {
        if (token == address(collateral)){
            withdrawCollateral(target, amount);
        } else {
            IERC20(token).transfer(target, amount);
        }
    }

    function withdrawCollateral(address target, uint256 amount) public onlyOwner noChallenge {
        uint256 balance = internalWithdrawCollateral(target, amount);
        require(isWellCollateralized(balance, price));
    }

    function internalWithdrawCollateral(address target, uint256 amount) internal returns (uint256) {
        IERC20(collateral).transfer(target, amount);
        uint256 balance = collateralBalance();
        if (balance < minimumCollateral){
            // Close
            cooldown = expiration;
        }
        emitUpdate();
        return balance;
    }

    function isWellCollateralized(uint256 collateralReserve, uint256 atPrice) internal view returns (bool) {
        return collateralReserve * atPrice >= minted * ONE_DEC18;
    }

    function emitUpdate() internal {
        emit MintingUpdate(collateralBalance(), price, minted, limit);
    }

    function notifyChallengeStarted(uint256 size) external onlyHub {
        uint256 colbal = collateralBalance();
        // require minimum size, note that collateral balance can be below minimum if it was partially challenged before
        require(size >= minimumCollateral || size == colbal, "challenge too small");
        require(size <= colbal, "challenge too large");
        challengedAmount += size;
    }

    /**
     * @notice check whether challenge can be averted
     * @param _collateralAmount   amount of collateral challenged (dec18)
     * @param _bidAmountZCHF      bid amount in ZCHF (dec18)
     * @return true if challenge can be averted
     */
    function tryAvertChallenge(uint256 _collateralAmount, uint256 _bidAmountZCHF) external onlyHub returns (bool) {
        if (block.timestamp >= expiration){
            return false; // position expired, let every challenge succeed
        } else if (_bidAmountZCHF * ONE_DEC18 >= price * _collateralAmount){
            // challenge averted, bid is high enough
            challengedAmount -= _collateralAmount;
            // don't allow minter to close the position immediately so challenge can be repeated
            restrictMinting(1 days);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Notifies the position that a challenge was successful.
     * Triggers the payout of the challenged part of the collateral.
     * Returns three important numbers:
     *  - repay: the amount that is needed to repay for the actually minted zchf wit the challenged collateral
     *  - minted: the number of zchf that where actually minted and used using the challenged collateral
     *  - mintmax: the maximum number of zchf that could have been minted and used using the challenged collateral 
     * @param _bidder   address of the bidder that receives the collateral
     * @param _bid      bid amount in ZCHF (dec18)
     * @param _size     size of the collateral bid for (dec 18)
     * @return adjusted bid size, repaied xchf, reserve contribution ppm
     */
    function notifyChallengeSucceeded(address _bidder, uint256 _bid, uint256 _size) 
        external onlyHub returns (address, uint256, uint256, uint256, uint32) {
        challengedAmount -= _size;
        uint256 colBal = collateralBalance();
        uint256 volumeZCHF = _mulD18(price, _size);
        uint256 mintable = _mulD18(price, colBal);
        if (volumeZCHF > mintable){
            _bid = _divD18(_mulD18(_bid, mintable), volumeZCHF);
            volumeZCHF = mintable;
            _size = colBal;
        }
        uint256 repayment = minted >= volumeZCHF ? volumeZCHF : minted;
        notifyRepaidInternal(repayment); // we assume the caller takes care of the actual repayment
        internalWithdrawCollateral(_bidder, _size); // transfer collateral to the bidder
        return (owner, _bid, volumeZCHF, repayment, reserveContribution);
    }

    modifier noMintRestriction() {
       require(cooldown < block.timestamp, "cooldown");
       require(block.timestamp <= expiration, "expired");
        _;
    }

    modifier noChallenge() {
        require(challengedAmount == 0, "challenges pending");
        _;
    }

    modifier onlyHub() {
        require(msg.sender == address(hub), "not hub");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Functions for share valuation
 */
contract MathUtil {

    uint256 internal constant ONE_DEC18 = 10**18;
    uint256 internal constant THRESH_DEC18 =  10000000000000000;//0.01
    /**
     * @notice Cubic root with Halley approximation
     *         Number 1e18 decimal
     * @param _v     number for which we calculate x**(1/3)
     * @return returns _v**(1/3)
     */
    function _cubicRoot(uint256 _v) internal pure returns (uint256) {
        uint256 x = ONE_DEC18;
        uint256 xOld;
        bool cond;
        do {
            xOld = x;
            uint256 powX3 = _mulD18(_mulD18(x, x), x);
            x = _mulD18(x, _divD18( (powX3 + 2 * _v) , (2 * powX3 + _v)));
            cond = xOld > x ? xOld - x > THRESH_DEC18 : x - xOld > THRESH_DEC18;
        } while ( cond );
        return x;
    }

    function _mulD18(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return _a * _b / ONE_DEC18;
    }

    function _divD18(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return (_a * ONE_DEC18) / _b ;
    }

    function _power3(uint256 _x) internal pure returns(uint256) {
        return _mulD18(_mulD18(_x, _x), _x);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT
//
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
//
// Modifications:
// - Replaced Context._msgSender() with msg.sender
// - Made leaner
// - Extracted interface

pragma solidity ^0.8.0;

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
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        require(initialOwner != address(0), "0x0");
        owner = initialOwner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) virtual public onlyOwner {
        require(newOwner != address(0), "0x0");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    modifier onlyOwner() {
        require(owner == msg.sender || owner == address(0x0), "not owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserve {
   function isQualified(address sender, address[] calldata helpers) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReserve.sol";
import "./IFrankencoin.sol";

interface IPosition {

    function collateral() external returns (IERC20);

    function minimumCollateral() external returns (uint256);

    function challengePeriod() external returns (uint256);

    function price() external returns (uint256);

    function reduceLimitForClone(uint256 amount) external returns (uint256);

    function initializeClone(address owner, uint256 _price, uint256 _limit, uint256 _coll, uint256 _mint) external;

    function deny(address[] calldata helpers, string calldata message) external;

    function notifyChallengeStarted(uint256 size) external;

    function tryAvertChallenge(uint256 size, uint256 bid) external returns (bool);

    function notifyChallengeSucceeded(address bidder, uint256 bid, uint256 size) external returns (address, uint256, uint256, uint256, uint32);

}

/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferAndCall(address recipient, uint256 amount, bytes calldata data) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}