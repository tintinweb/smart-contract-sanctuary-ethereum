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
import "./Ownable.sol";
import "./IPosition.sol";

/**
 * A hub for creating collateralized minting positions for a given collateral.
 */
contract MintingHub {
    uint256 public constant OPENING_FEE = 1000 * 10**18;

    uint32 public constant BASE = 1000_000;
    uint32 public constant CHALLENGER_REWARD = 20000; // 2%

    IPositionFactory private immutable POSITION_FACTORY; // position contract to clone

    IFrankencoin public immutable zchf; // currency
    Challenge[] public challenges;

    struct Challenge {
        address challenger;
        IPosition position;
        uint256 size;
        uint256 end;
        address bidder;
        uint256 bid;
    }

    event ChallengeStarted(address indexed challenger, address indexed position, uint256 size, uint256 number);
    event ChallengeAverted(address indexed position, uint256 number);
    event ChallengeSucceeded(address indexed position, uint256 bid, uint256 number);
    event NewBid(uint256 challengedId, uint256 bidAmount, address bidder);

    constructor(address _zchf, address factory) {
        zchf = IFrankencoin(_zchf);
        POSITION_FACTORY = IPositionFactory(factory);
    }

    /**
     * @notice open a collateralized loan position
     * @param _collateralAddress        address of collateral token
     * @param _minCollateral     minimum collateral required to prevent dust amounts
     * @param _initialCollateral amount of initial collateral to be deposited
     * @param _mintingMaximum    maximal amount of ZCHF that can be minted by the position owner
     * @param _expirationSeconds position tenor in unit of timestamp (seconds) from 'now'
     * @param _challengeSeconds  challenge period. Longer for less liquid collateral.
     * @param _mintingFeePPM     percentage minting fee that will be added to reserve,
     *                           basis 1000_000
     * @param _liqPriceE18       Liquidation price (dec18) that together with the reserve and
     *                           fees determines the minimal collateralization ratio
     * @param _reservePPM        percentage reserve amount that is added as the
     *                           borrower's stake into reserve, basis 1000_000
     * @return address of resulting position
     */
    function openPosition(
        address _collateralAddress, uint256 _minCollateral, uint256 _initialCollateral,
        uint256 _mintingMaximum, uint256 _expirationSeconds, uint256 _challengeSeconds,
        uint32 _mintingFeePPM, uint256 _liqPriceE18, uint32 _reservePPM) public returns (address) {
        IPosition pos = IPosition(
            POSITION_FACTORY.createNewPosition(
                msg.sender,
                address(zchf),
                _collateralAddress,
                _minCollateral,
                _initialCollateral,
                _mintingMaximum,
                _expirationSeconds,
                _challengeSeconds,
                _mintingFeePPM,
                _liqPriceE18,
                _reservePPM
            )
        );
        zchf.registerPosition(address(pos));
        zchf.transferFrom(msg.sender, address(zchf.reserve()), OPENING_FEE);
        IERC20(_collateralAddress).transferFrom(msg.sender, address(pos), _initialCollateral);

        return address(pos);
    }

    function clonePosition(address position, uint256 _initialCollateral, uint256 _initialMint) public returns (address) {
        require(zchf.isPosition(position) == address(this), "not our pos");
        IPosition existing = IPosition(position);
        uint256 limit = existing.reduceLimitForClone(_initialMint);
        address pos = POSITION_FACTORY.clonePosition(position);
        zchf.registerPosition(pos);
        existing.collateral().transferFrom(msg.sender, address(pos), _initialCollateral);
        IPosition(pos).initializeClone(msg.sender, existing.price(), limit, _initialCollateral, _initialMint);
        return address(pos);
    }

    function reserve() external view returns (IReserve) {
        return IReserve(zchf.reserve());
    }

    /**
     * @notice Launch a challenge on a position
     * @param _positionAddr      address of the position we want to challenge
     * @param _collateralAmount  size of the collateral we want to challenge (dec 18)
     * @return index of the challenge in challenge-array
     */
    function launchChallenge(address _positionAddr, uint256 _collateralAmount) external returns (uint256) {
        IPosition position = IPosition(_positionAddr);
        IERC20(position.collateral()).transferFrom(msg.sender, address(this), _collateralAmount);
        uint256 pos = challenges.length;
        /*
        struct Challenge {address challenger;IPosition position;uint256 size;uint256 end;address bidder;uint256 bid;
        */
        challenges.push(Challenge(msg.sender, position, _collateralAmount, block.timestamp + position.challengePeriod(), address(0x0), 0));
        position.notifyChallengeStarted(_collateralAmount);
        emit ChallengeStarted(msg.sender, address(position), _collateralAmount, pos);
        return pos;
    }

    function splitChallenge(uint256 _challengeNumber, uint256 splitOffAmount) external returns (uint256) {
        Challenge storage challenge = challenges[_challengeNumber];
        require(challenge.challenger != address(0x0));
        Challenge memory copy = Challenge(
            challenge.challenger,
            challenge.position,
            splitOffAmount,
            challenge.end,
            challenge.bidder,
            (challenge.bid * splitOffAmount) / challenge.size
        );
        challenge.bid -= copy.bid;
        challenge.size -= copy.size;

        uint256 min = IPosition(challenge.position).minimumCollateral();
        require(challenge.size >= min);
        require(copy.size >= min);

        uint256 pos = challenges.length;
        challenges.push(copy);
        emit ChallengeStarted(challenge.challenger, address(challenge.position), challenge.size, _challengeNumber);
        emit ChallengeStarted(copy.challenger, address(copy.position), copy.size, pos);
        return pos;
    }

    function minBid(uint256 challenge) public view returns (uint256) {
        return minBid(challenges[challenge]);
    }

    function minBid(Challenge storage challenge) internal view returns (uint256) {
        return (challenge.bid * 1005) / 1000; // should be at least 0.5% higher
    }

    /**
     * @notice Post a bid (ZCHF amount) for an existing challenge (given collateral amount)
     * @param _challengeNumber   index of the challenge in the challenges array
     * @param _bidAmountZCHF     how much to bid for the collateral of this challenge (dec 18)
     */
    function bid(uint256 _challengeNumber, uint256 _bidAmountZCHF, uint256 expectedSize) external {
        Challenge storage challenge = challenges[_challengeNumber];
        if (block.timestamp >= challenge.end) {
            // if bid is too late, the transaction ends the challenge
            _end(_challengeNumber);
        } else {
            require(expectedSize == challenge.size, "s");
            if (challenge.bid > 0) {
                zchf.transfer(challenge.bidder, challenge.bid); // return old bid
            }
            emit NewBid(_challengeNumber, _bidAmountZCHF, msg.sender);
            if (challenge.position.tryAvertChallenge(challenge.size, _bidAmountZCHF)) {
                // bid above Z_B/C_C >= (1+h)Z_M/C_M, challenge averted, end immediately by selling challenger collateral to bidder
                zchf.transferFrom(msg.sender, challenge.challenger, _bidAmountZCHF);
                IERC20(challenge.position.collateral()).transfer(msg.sender, challenge.size);
                emit ChallengeAverted(address(challenge.position), _challengeNumber);
                delete challenges[_challengeNumber];
            } else {
                require(_bidAmountZCHF >= minBid(challenge), "below min bid");
                uint256 earliestEnd = block.timestamp + 30 minutes;
                if (earliestEnd >= challenge.end) {
                    // bump remaining time to 10 minutes if we are near the end of the challenge
                    challenge.end = earliestEnd;
                }
                require(challenge.size * challenge.position.price() > _bidAmountZCHF * 10**18, "whot");
                zchf.transferFrom(msg.sender, address(this), _bidAmountZCHF);
                challenge.bid = _bidAmountZCHF;
                challenge.bidder = msg.sender;
            }
        }
    }

    /**
     * @notice
     * Ends a challenge successfully after the auction period ended.
     *
     * Example: A challenged position had 1000 ABC tokens as collateral with a minting limit of 200,000 ZCHF, out
     * of which 60,000 have been minted and thereof 15,000 used to buy reserve tokens. The challenger auctioned off
     * 400 ABC tokens, challenging 40% of the position. The highest bid was 75,000 ZCHF, below the
     * 40% * 200,000 = 80,000 ZCHF needed to avert the challenge. The reserve ratio of the position is 25%.
     *
     * Now, the following happens when calling this method:
     * - 400 ABC from the position owner are transferred to the bidder
     * - The challenger's 400 ABC are returned to the challenger
     * - 40% of the reserve bought with the 15,000 ZCHF is sold off (approximately), yielding e.g. 5,600 ZCHF
     * - 40% * 60,000 = 24,000 ZCHF are burned
     * - 80,000 * 2% = 1600 ZCHF are given to the challenger as a reward
     * - 40% * (100%-25%) * (200,000 - 60,000) = 42,000 are given to the position owner for selling off unused collateral
     * - The remaining 75,000 + 5,600 - 1,600 - 24,000 - 42,000 = 13,000 ZCHF are sent to the reserve pool
     *
     * If the highest bid was only 60,000 ZCHF, then we would have had a shortfall of 2,000 ZCHF that would in the
     * first priority be covered by the reserve and in the second priority by minting unbacked ZCHF, triggering a
     * balance alert.
     * @param _challengeNumber  number of the challenge in challenge-array
     */
    function end(uint256 _challengeNumber) external {
        _end(_challengeNumber);
    }

    function isChallengeOpen(uint256 _challengeNumber) external view returns (bool) {
        return challenges[_challengeNumber].end > block.timestamp;
    }

    /**
     * @dev internal end function
     * @param _challengeNumber  number of the challenge in challenge-array
     */
    function _end(uint256 _challengeNumber) internal {
        Challenge storage challenge = challenges[_challengeNumber];
        IERC20 collateral = challenge.position.collateral();
        require(block.timestamp >= challenge.end, "period has not ended");
        // challenge must have been successful, because otherwise it would have immediately ended on placing the winning bid
        collateral.transfer(challenge.challenger, challenge.size); // return the challenger's collateral
        // notify the position that will send the collateral to the bidder. If there is no bid, send the collateral to msg.sender
        address recipient = challenge.bidder == address(0x0) ? msg.sender : challenge.bidder;
        (address owner, uint256 effectiveBid, uint256 volume, uint256 repayment, uint32 reservePPM) = challenge.position.notifyChallengeSucceeded(recipient, challenge.bid, challenge.size);
        if (effectiveBid < challenge.bid) {
            // overbid, return excess amount
            IERC20(zchf).transfer(challenge.bidder, challenge.bid - effectiveBid);
        }
        uint256 reward = (volume * CHALLENGER_REWARD) / BASE;
        uint256 fundsNeeded = reward + repayment;
        if (effectiveBid > fundsNeeded){
            zchf.transfer(owner, effectiveBid - fundsNeeded);
        } else if (effectiveBid < fundsNeeded){
            zchf.notifyLoss(fundsNeeded - effectiveBid); // ensure we have enough to pay everything
        }
        zchf.transfer(challenge.challenger, reward); // pay out the challenger reward
        zchf.burn(repayment, reservePPM); // Repay the challenged part
        emit ChallengeSucceeded(address(challenge.position), challenge.bid, _challengeNumber);
        delete challenges[_challengeNumber];
    }
}

interface IPositionFactory {
    function createNewPosition(
        address _owner,
        address _zchf,
        address _collateral,
        uint256 _minCollateral,
        uint256 _initialCollateral,
        uint256 _initialLimit,
        uint256 _duration,
        uint256 _challengePeriod,
        uint32 _mintingFeePPM,
        uint256 _liqPrice,
        uint32 _reserve
    ) external returns (address);

    function clonePosition(address _existing) external returns (address);
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