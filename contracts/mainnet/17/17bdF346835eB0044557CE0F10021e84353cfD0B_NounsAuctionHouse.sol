// SPDX-License-Identifier: GPL-3.0
/// @title The UNouns DAO auction house

/*******************************************************************************
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╠▒▒▒▒▒╠╩╩╩╩               ╩╩╩╩╠▒▒▒▒▒╠╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩  ╠▒╩╩╩╩ε    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╚╩╩╩╠▒▒  ╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩▒▒  ▒▒╩╩    ]▒▒▒▒╩╩╩╩╩╩  ╘╩╩╩╩╩╩▒▒▒▒    ,╩╩▒▒  ▒▒╩╩╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒Γ  ╚╚▒▒╚╚,,╚▒▒▒╩╚╚╚╚,,,,,,  .,,,,,,╚╚╚╚╠▒▒▒≥,,╚╚▒▒╚╚  ╙▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒  ╠▒▒▒╩╚.,,,,▒▒▒▒▒▒  )▒▒▒▒▒▒,,,,╙╚╠▒▒▒╡  ▒▒,,,,╚▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╚╚╠▒╩╚╚▒╠╚╚,,╠▒╚╚½,╔▒▒▒▒▒▒╚╚╚╚  ╘╚╚╚╚▒▒▒▒▒▒,,²╚╚▒▒,,╚╚▒▒╚╚╠▒╩╚╚▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒  ²╚\,,▒Γ  ▒▒▒▒  ]▒▒▒▒▒▒╚╚,,,,  .,,,,╚╚▒▒▒▒▒▒  ]▒▒▒▒  ▒▒,,²╚⌐  ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒,,,,╓▒╠╚╙,,▒▒╚╚,,]▒▒▒╠╚╚,,╠▒▒▒  )▒▒▒▒,,╚╚╠▒▒▒,,/╚╚▒▒,,╚╚╠▒,,,,,▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒▒▒  ▐▒▒▒▒▒▒╓╓▒▒▒▒▒▒  ▐▒▒▒▒▒▒╓╓╢▒▒▒▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  """"  ""╚╬╩╙╙╙╙████╬╬  ║╬╬╙╙╙╙▓███╬╬╙"¬  """"  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╓╓╓╓φ▒╡  ╓╓╓╓╓╓╓╓▄╬Γ    ████▓╬╥╓║╬▌    ████╬╬╦╓   ╓╓╓-  ╠▒╓╓╓╓╓▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒╬╬╜╙╠╬╣╬Γ    ████▓╬╨╙╟╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  ▒▒╬╬  ▐▒╟╬Γ    ████▓╬  ║╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔╔╔φ▒▒╔ε``╠╠╔╔``▐╬▒╗╗╗╗████▒╬  ║╬▌╗╗╗╗████╬╬▒`]╔╔▒▒``╔╔╠▒╔╔╔╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒``╚▒╩`"▒Γ  ▒▒▒▒  ]╠╠╠╠╠╠╠╠╙╙╙╙  ^╙╙╙╙╠╠╠╠╠╠╠╠  ]▒▒▒▒  ▒▒``╠▒╙`"▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔```  ▒╠╔╔``╠▒╔╔ε`╚▒▒▒▒▒▒╔╔╔╔  «╔╔╔╔▒▒▒▒▒▒``╔╔φ▒╠``╔╔▒▒  ``]╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔╔╔╔▒▒▒▒  ╠▒▒▒╦╔⌂````▒▒▒▒▒▒  )▒▒▒▒▒▒````╔╔╠▒▒▒╡  ▒▒▒▒╔╔╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╙`7▒▒`"▒▒╔╔``╚▒▒▒╦╔╔╔╔``````  ```````╔╔╔╔╠▒▒▒╙`"╔╔▒▒``╠▒"`╙▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔ε``  ▒▒▒▒╔╔"```╚▒▒▒▒╔╔╔╔╔╔  «╔╔╔╔╔╔▒▒▒▒````]╔╔▒▒▒▒  ``╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒  ╠▒φφφφ░    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╔φφφφ▒╠  ▒▒φφφφ╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠    ╠▒▒▒▒▒φφφφφ               φφφφ╠▒▒▒▒▒╡    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ╠▒▒▒▒▒▒▒▒▒▒φφφφφφφφφφφφφφφ▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ╠▒▒▒▒▒Γ        ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ]φφφφφφφφ      `φφφφφφφφ    ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒  ╔▒▒▒▒▒Γ  ▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ    δ▒╠▒▒▒▒▒╠▒φ    ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*******************************************************************************/


// LICENSE
// NounsAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by UNounders DAO.

pragma solidity ^0.8.6;

import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { INounsAuctionHouse } from './interfaces/INounsAuctionHouse.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract NounsAuctionHouse is INounsAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The UNouns ERC721 token contract
    INounsToken public nouns;

    // The address of the WETH contract
    address public weth;

    // The address of Nouns DAO treasury
    address public nounsDAOTreasury;

    // The address of hall of fame
    address public halloffame;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The time that Nouns DAO treasury stops receiving rewards
    uint256 public proceedsShareEndTime;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    INounsAuctionHouse.Auction public auction;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        INounsToken _nouns,
        address _weth,
        address _nounsDAOTreasury,
        address _halloffame,
        uint256 _timeBuffer,
        uint256 _proceedsShareEndTime,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();


        require(
            _nounsDAOTreasury != address(0) && _halloffame != address(0) && _weth != address(0),
            "ZERO ADDRESS"
        );
        require(_reservePrice > 0, "Reserve price is zero");
        require(_minBidIncrementPercentage <= 100, "Min bid increment percentange too high");

        nouns = _nouns;
        weth = _weth;
        nounsDAOTreasury = _nounsDAOTreasury;
        halloffame = _halloffame;
        timeBuffer = _timeBuffer;
        proceedsShareEndTime = _proceedsShareEndTime;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction, mint a new Noun, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Noun, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 unounId) external payable override nonReentrant {
        INounsAuctionHouse.Auction memory _auction = auction;

        require(_auction.unounId == unounId, 'Noun not up for auction');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.unounId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.unounId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the UNouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Finish the proceeds share to Nouns DAO Treasury.
     * @dev This function can only be called by the owner.
     */
    function finishNounsDAOTreasuryShare() external onlyOwner {
        proceedsShareEndTime = 0;
    }

    /**
     * @notice Unpause the UNouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try nouns.mint() returns (uint256 unounId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                unounId: unounId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(unounId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction() internal {
        INounsAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            nouns.transferFrom(address(this), halloffame, _auction.unounId);
        } else {
            nouns.transferFrom(address(this), _auction.bidder, _auction.unounId);
        }

        if (_auction.amount > 0) {
            if (block.timestamp < proceedsShareEndTime) {
                // transfer to UNouns DAO Treasury
                if (_auction.unounId % 100 == 88) {
                    _safeTransferETHWithFallback(nounsDAOTreasury, _auction.amount);
                } else {
                    // transfer to UNouns DAO
                    _safeTransferETHWithFallback(owner(), _auction.amount);
                }
            } else {
                // transfer to UNouns DAO
                _safeTransferETHWithFallback(owner(), _auction.amount);
            }
        }

        if (_auction.bidder == address(0)) {
            emit AuctionSettled(_auction.unounId, halloffame, _auction.amount);
        } else {
            emit AuctionSettled(_auction.unounId, _auction.bidder, _auction.amount);
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

/*******************************************************************************
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╠▒▒▒▒▒╠╩╩╩╩               ╩╩╩╩╠▒▒▒▒▒╠╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩  ╠▒╩╩╩╩ε    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╚╩╩╩╠▒▒  ╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩▒▒  ▒▒╩╩    ]▒▒▒▒╩╩╩╩╩╩  ╘╩╩╩╩╩╩▒▒▒▒    ,╩╩▒▒  ▒▒╩╩╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒Γ  ╚╚▒▒╚╚,,╚▒▒▒╩╚╚╚╚,,,,,,  .,,,,,,╚╚╚╚╠▒▒▒≥,,╚╚▒▒╚╚  ╙▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒  ╠▒▒▒╩╚.,,,,▒▒▒▒▒▒  )▒▒▒▒▒▒,,,,╙╚╠▒▒▒╡  ▒▒,,,,╚▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╚╚╠▒╩╚╚▒╠╚╚,,╠▒╚╚½,╔▒▒▒▒▒▒╚╚╚╚  ╘╚╚╚╚▒▒▒▒▒▒,,²╚╚▒▒,,╚╚▒▒╚╚╠▒╩╚╚▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒  ²╚\,,▒Γ  ▒▒▒▒  ]▒▒▒▒▒▒╚╚,,,,  .,,,,╚╚▒▒▒▒▒▒  ]▒▒▒▒  ▒▒,,²╚⌐  ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒,,,,╓▒╠╚╙,,▒▒╚╚,,]▒▒▒╠╚╚,,╠▒▒▒  )▒▒▒▒,,╚╚╠▒▒▒,,/╚╚▒▒,,╚╚╠▒,,,,,▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒▒▒  ▐▒▒▒▒▒▒╓╓▒▒▒▒▒▒  ▐▒▒▒▒▒▒╓╓╢▒▒▒▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  """"  ""╚╬╩╙╙╙╙████╬╬  ║╬╬╙╙╙╙▓███╬╬╙"¬  """"  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╓╓╓╓φ▒╡  ╓╓╓╓╓╓╓╓▄╬Γ    ████▓╬╥╓║╬▌    ████╬╬╦╓   ╓╓╓-  ╠▒╓╓╓╓╓▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒╬╬╜╙╠╬╣╬Γ    ████▓╬╨╙╟╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  ▒▒╬╬  ▐▒╟╬Γ    ████▓╬  ║╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔╔╔φ▒▒╔ε``╠╠╔╔``▐╬▒╗╗╗╗████▒╬  ║╬▌╗╗╗╗████╬╬▒`]╔╔▒▒``╔╔╠▒╔╔╔╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒``╚▒╩`"▒Γ  ▒▒▒▒  ]╠╠╠╠╠╠╠╠╙╙╙╙  ^╙╙╙╙╠╠╠╠╠╠╠╠  ]▒▒▒▒  ▒▒``╠▒╙`"▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔```  ▒╠╔╔``╠▒╔╔ε`╚▒▒▒▒▒▒╔╔╔╔  «╔╔╔╔▒▒▒▒▒▒``╔╔φ▒╠``╔╔▒▒  ``]╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔╔╔╔▒▒▒▒  ╠▒▒▒╦╔⌂````▒▒▒▒▒▒  )▒▒▒▒▒▒````╔╔╠▒▒▒╡  ▒▒▒▒╔╔╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╙`7▒▒`"▒▒╔╔``╚▒▒▒╦╔╔╔╔``````  ```````╔╔╔╔╠▒▒▒╙`"╔╔▒▒``╠▒"`╙▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔ε``  ▒▒▒▒╔╔"```╚▒▒▒▒╔╔╔╔╔╔  «╔╔╔╔╔╔▒▒▒▒````]╔╔▒▒▒▒  ``╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒  ╠▒φφφφ░    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╔φφφφ▒╠  ▒▒φφφφ╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠    ╠▒▒▒▒▒φφφφφ               φφφφ╠▒▒▒▒▒╡    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ╠▒▒▒▒▒▒▒▒▒▒φφφφφφφφφφφφφφφ▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ╠▒▒▒▒▒Γ        ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ]φφφφφφφφ      `φφφφφφφφ    ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒  ╔▒▒▒▒▒Γ  ▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ    δ▒╠▒▒▒▒▒╠▒φ    ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*******************************************************************************/


pragma solidity ^0.8.6;

interface INounsAuctionHouse {
    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 unounId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed unounId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed unounId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed unounId, uint256 endTime);

    event AuctionSettled(uint256 indexed unounId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 unounId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

/*******************************************************************************
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╠▒▒▒▒▒╠╩╩╩╩               ╩╩╩╩╠▒▒▒▒▒╠╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩  ╠▒╩╩╩╩ε    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╚╩╩╩╠▒▒  ╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩▒▒  ▒▒╩╩    ]▒▒▒▒╩╩╩╩╩╩  ╘╩╩╩╩╩╩▒▒▒▒    ,╩╩▒▒  ▒▒╩╩╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒Γ  ╚╚▒▒╚╚,,╚▒▒▒╩╚╚╚╚,,,,,,  .,,,,,,╚╚╚╚╠▒▒▒≥,,╚╚▒▒╚╚  ╙▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒  ╠▒▒▒╩╚.,,,,▒▒▒▒▒▒  )▒▒▒▒▒▒,,,,╙╚╠▒▒▒╡  ▒▒,,,,╚▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╚╚╠▒╩╚╚▒╠╚╚,,╠▒╚╚½,╔▒▒▒▒▒▒╚╚╚╚  ╘╚╚╚╚▒▒▒▒▒▒,,²╚╚▒▒,,╚╚▒▒╚╚╠▒╩╚╚▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒  ²╚\,,▒Γ  ▒▒▒▒  ]▒▒▒▒▒▒╚╚,,,,  .,,,,╚╚▒▒▒▒▒▒  ]▒▒▒▒  ▒▒,,²╚⌐  ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒,,,,╓▒╠╚╙,,▒▒╚╚,,]▒▒▒╠╚╚,,╠▒▒▒  )▒▒▒▒,,╚╚╠▒▒▒,,/╚╚▒▒,,╚╚╠▒,,,,,▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒▒▒  ▐▒▒▒▒▒▒╓╓▒▒▒▒▒▒  ▐▒▒▒▒▒▒╓╓╢▒▒▒▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  """"  ""╚╬╩╙╙╙╙████╬╬  ║╬╬╙╙╙╙▓███╬╬╙"¬  """"  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╓╓╓╓φ▒╡  ╓╓╓╓╓╓╓╓▄╬Γ    ████▓╬╥╓║╬▌    ████╬╬╦╓   ╓╓╓-  ╠▒╓╓╓╓╓▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒╬╬╜╙╠╬╣╬Γ    ████▓╬╨╙╟╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  ▒▒╬╬  ▐▒╟╬Γ    ████▓╬  ║╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔╔╔φ▒▒╔ε``╠╠╔╔``▐╬▒╗╗╗╗████▒╬  ║╬▌╗╗╗╗████╬╬▒`]╔╔▒▒``╔╔╠▒╔╔╔╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒``╚▒╩`"▒Γ  ▒▒▒▒  ]╠╠╠╠╠╠╠╠╙╙╙╙  ^╙╙╙╙╠╠╠╠╠╠╠╠  ]▒▒▒▒  ▒▒``╠▒╙`"▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔```  ▒╠╔╔``╠▒╔╔ε`╚▒▒▒▒▒▒╔╔╔╔  «╔╔╔╔▒▒▒▒▒▒``╔╔φ▒╠``╔╔▒▒  ``]╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔╔╔╔▒▒▒▒  ╠▒▒▒╦╔⌂````▒▒▒▒▒▒  )▒▒▒▒▒▒````╔╔╠▒▒▒╡  ▒▒▒▒╔╔╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╙`7▒▒`"▒▒╔╔``╚▒▒▒╦╔╔╔╔``````  ```````╔╔╔╔╠▒▒▒╙`"╔╔▒▒``╠▒"`╙▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔ε``  ▒▒▒▒╔╔"```╚▒▒▒▒╔╔╔╔╔╔  «╔╔╔╔╔╔▒▒▒▒````]╔╔▒▒▒▒  ``╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒  ╠▒φφφφ░    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╔φφφφ▒╠  ▒▒φφφφ╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠    ╠▒▒▒▒▒φφφφφ               φφφφ╠▒▒▒▒▒╡    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ╠▒▒▒▒▒▒▒▒▒▒φφφφφφφφφφφφφφφ▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ╠▒▒▒▒▒Γ        ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ]φφφφφφφφ      `φφφφφφφφ    ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒  ╔▒▒▒▒▒Γ  ▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ    δ▒╠▒▒▒▒▒╠▒φ    ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*******************************************************************************/


pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';
import { INounsSeeder } from './INounsSeeder.sol';

interface INounsToken is IERC721 {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event NoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(INounsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setUNoundersDAO(address noundersDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INounsSeeder seeder) external;

    function lockSeeder() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

/*******************************************************************************
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╠▒▒▒▒▒╠╩╩╩╩               ╩╩╩╩╠▒▒▒▒▒╠╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩  ╠▒╩╩╩╩ε    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╚╩╩╩╠▒▒  ╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩▒▒  ▒▒╩╩    ]▒▒▒▒╩╩╩╩╩╩  ╘╩╩╩╩╩╩▒▒▒▒    ,╩╩▒▒  ▒▒╩╩╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒Γ  ╚╚▒▒╚╚,,╚▒▒▒╩╚╚╚╚,,,,,,  .,,,,,,╚╚╚╚╠▒▒▒≥,,╚╚▒▒╚╚  ╙▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒  ╠▒▒▒╩╚.,,,,▒▒▒▒▒▒  )▒▒▒▒▒▒,,,,╙╚╠▒▒▒╡  ▒▒,,,,╚▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╚╚╠▒╩╚╚▒╠╚╚,,╠▒╚╚½,╔▒▒▒▒▒▒╚╚╚╚  ╘╚╚╚╚▒▒▒▒▒▒,,²╚╚▒▒,,╚╚▒▒╚╚╠▒╩╚╚▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒  ²╚\,,▒Γ  ▒▒▒▒  ]▒▒▒▒▒▒╚╚,,,,  .,,,,╚╚▒▒▒▒▒▒  ]▒▒▒▒  ▒▒,,²╚⌐  ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒,,,,╓▒╠╚╙,,▒▒╚╚,,]▒▒▒╠╚╚,,╠▒▒▒  )▒▒▒▒,,╚╚╠▒▒▒,,/╚╚▒▒,,╚╚╠▒,,,,,▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒▒▒  ▐▒▒▒▒▒▒╓╓▒▒▒▒▒▒  ▐▒▒▒▒▒▒╓╓╢▒▒▒▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  """"  ""╚╬╩╙╙╙╙████╬╬  ║╬╬╙╙╙╙▓███╬╬╙"¬  """"  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╓╓╓╓φ▒╡  ╓╓╓╓╓╓╓╓▄╬Γ    ████▓╬╥╓║╬▌    ████╬╬╦╓   ╓╓╓-  ╠▒╓╓╓╓╓▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒╬╬╜╙╠╬╣╬Γ    ████▓╬╨╙╟╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  ▒▒╬╬  ▐▒╟╬Γ    ████▓╬  ║╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔╔╔φ▒▒╔ε``╠╠╔╔``▐╬▒╗╗╗╗████▒╬  ║╬▌╗╗╗╗████╬╬▒`]╔╔▒▒``╔╔╠▒╔╔╔╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒``╚▒╩`"▒Γ  ▒▒▒▒  ]╠╠╠╠╠╠╠╠╙╙╙╙  ^╙╙╙╙╠╠╠╠╠╠╠╠  ]▒▒▒▒  ▒▒``╠▒╙`"▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔```  ▒╠╔╔``╠▒╔╔ε`╚▒▒▒▒▒▒╔╔╔╔  «╔╔╔╔▒▒▒▒▒▒``╔╔φ▒╠``╔╔▒▒  ``]╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔╔╔╔▒▒▒▒  ╠▒▒▒╦╔⌂````▒▒▒▒▒▒  )▒▒▒▒▒▒````╔╔╠▒▒▒╡  ▒▒▒▒╔╔╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╙`7▒▒`"▒▒╔╔``╚▒▒▒╦╔╔╔╔``````  ```````╔╔╔╔╠▒▒▒╙`"╔╔▒▒``╠▒"`╙▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔ε``  ▒▒▒▒╔╔"```╚▒▒▒▒╔╔╔╔╔╔  «╔╔╔╔╔╔▒▒▒▒````]╔╔▒▒▒▒  ``╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒  ╠▒φφφφ░    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╔φφφφ▒╠  ▒▒φφφφ╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠    ╠▒▒▒▒▒φφφφφ               φφφφ╠▒▒▒▒▒╡    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ╠▒▒▒▒▒▒▒▒▒▒φφφφφφφφφφφφφφφ▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ╠▒▒▒▒▒Γ        ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ]φφφφφφφφ      `φφφφφφφφ    ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒  ╔▒▒▒▒▒Γ  ▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ    δ▒╠▒▒▒▒▒╠▒φ    ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*******************************************************************************/


pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*******************************************************************************
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╠▒▒▒▒▒╠╩╩╩╩               ╩╩╩╩╠▒▒▒▒▒╠╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩  ╠▒╩╩╩╩ε    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╚╩╩╩╠▒▒  ╩╩▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠╩╩▒▒  ▒▒╩╩    ]▒▒▒▒╩╩╩╩╩╩  ╘╩╩╩╩╩╩▒▒▒▒    ,╩╩▒▒  ▒▒╩╩╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒Γ  ╚╚▒▒╚╚,,╚▒▒▒╩╚╚╚╚,,,,,,  .,,,,,,╚╚╚╚╠▒▒▒≥,,╚╚▒▒╚╚  ╙▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒  ╠▒▒▒╩╚.,,,,▒▒▒▒▒▒  )▒▒▒▒▒▒,,,,╙╚╠▒▒▒╡  ▒▒,,,,╚▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╚╚╠▒╩╚╚▒╠╚╚,,╠▒╚╚½,╔▒▒▒▒▒▒╚╚╚╚  ╘╚╚╚╚▒▒▒▒▒▒,,²╚╚▒▒,,╚╚▒▒╚╚╠▒╩╚╚▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒  ²╚\,,▒Γ  ▒▒▒▒  ]▒▒▒▒▒▒╚╚,,,,  .,,,,╚╚▒▒▒▒▒▒  ]▒▒▒▒  ▒▒,,²╚⌐  ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒,,,,╓▒╠╚╙,,▒▒╚╚,,]▒▒▒╠╚╚,,╠▒▒▒  )▒▒▒▒,,╚╚╠▒▒▒,,/╚╚▒▒,,╚╚╠▒,,,,,▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒▒▒  ▐▒▒▒▒▒▒╓╓▒▒▒▒▒▒  ▐▒▒▒▒▒▒╓╓╢▒▒▒▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  """"  ""╚╬╩╙╙╙╙████╬╬  ║╬╬╙╙╙╙▓███╬╬╙"¬  """"  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╓╓╓╓φ▒╡  ╓╓╓╓╓╓╓╓▄╬Γ    ████▓╬╥╓║╬▌    ████╬╬╦╓   ╓╓╓-  ╠▒╓╓╓╓╓▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒""╠▒╙"╙▒╡  ▒▒╬╬╜╙╠╬╣╬Γ    ████▓╬╨╙╟╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒╙"╙▒╠"╙▒▒▒▒▒▒
▒▒▒▒▒▒▒╓╓""  ]▒╡  ▒▒╬╬  ▐▒╟╬Γ    ████▓╬  ║╬▌    ████╬╬▒▒Γ  ▒▒▒▒  ╠▒  '"└╓╓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔╔╔φ▒▒╔ε``╠╠╔╔``▐╬▒╗╗╗╗████▒╬  ║╬▌╗╗╗╗████╬╬▒`]╔╔▒▒``╔╔╠▒╔╔╔╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒``╚▒╩`"▒Γ  ▒▒▒▒  ]╠╠╠╠╠╠╠╠╙╙╙╙  ^╙╙╙╙╠╠╠╠╠╠╠╠  ]▒▒▒▒  ▒▒``╠▒╙`"▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒╔╔```  ▒╠╔╔``╠▒╔╔ε`╚▒▒▒▒▒▒╔╔╔╔  «╔╔╔╔▒▒▒▒▒▒``╔╔φ▒╠``╔╔▒▒  ``]╔╔▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔╔╔╔▒▒▒▒  ╠▒▒▒╦╔⌂````▒▒▒▒▒▒  )▒▒▒▒▒▒````╔╔╠▒▒▒╡  ▒▒▒▒╔╔╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╙`7▒▒`"▒▒╔╔``╚▒▒▒╦╔╔╔╔``````  ```````╔╔╔╔╠▒▒▒╙`"╔╔▒▒``╠▒"`╙▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒╔╔ε``  ▒▒▒▒╔╔"```╚▒▒▒▒╔╔╔╔╔╔  «╔╔╔╔╔╔▒▒▒▒````]╔╔▒▒▒▒  ``╔╔φ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒  ╠▒φφφφ░    ▒▒▒▒▒▒  )▒▒▒▒▒▒    ╔φφφφ▒╠  ▒▒φφφφ╠▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠    ╠▒▒▒▒▒φφφφφ               φφφφ╠▒▒▒▒▒╡    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠φφφφ╠▒▒▒▒▒▒▒▒▒▒φφφφφφφφφφφφφφφ▒▒▒▒▒▒▒▒▒▒╠φφφφ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ╠▒▒▒▒▒Γ        ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ]φφφφφφφφ      `φφφφφφφφ    ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒  ╔▒▒▒▒▒Γ  ▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ    δ▒╠▒▒▒▒▒╠▒φ    ╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*******************************************************************************/


pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 unounId, INounsDescriptorMinimal descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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