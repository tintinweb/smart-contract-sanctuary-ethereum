pragma solidity ^0.8.7;
//SPDX-License-Identifier: Unlicensed

import "./libraries/Ownable.sol";
import "./interfaces/IRaffleWorldStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RaffleWorldNft is Ownable, VRFConsumerBaseV2 {
    using SafeMath for uint256;

    IRaffleWorldStorage raffleStorage;
    VRFCoordinatorV2Interface vrfCoordinator;

    uint64 vrfSubscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;

    struct RaffleRandom {
        uint256 raffleId;
        uint256 random;
    }

    struct Refferals {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
        uint256 diamond;
        uint256 total;
    }

    mapping(uint256 => RaffleRandom) public raffleRandom;
    mapping(address => Refferals) public refferals;
    mapping(address => mapping(uint256 => uint256[]))
        public raffleEntriesPositionById;

    constructor(
        uint64 _vrfSubscritpionId,
        address _raffleWorldStorageAddress,
        address _vrfCoordinatorAddress,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinatorAddress) {
        vrfSubscriptionId = _vrfSubscritpionId;
        raffleStorage = IRaffleWorldStorage(_raffleWorldStorageAddress);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = 1;
    }

    modifier checkTicketsAcquisition(
        uint256 _raffleId,
        uint256 _ticketsNumber
    ) {
        require(!raffleStorage.IsCanceled(_raffleId), "Raffle is canceled!");
        require(
            keccak256(bytes(raffleStorage.GetRaffleStatus(_raffleId))) !=
                keccak256(bytes("ended")),
            "Raffle has ended!"
        );
        require(
            raffleStorage.GetRaffleEntriesLength(_raffleId).add(
                _ticketsNumber
            ) <= raffleStorage.GetRaffleTicketsNumber(_raffleId),
            "You need to buy less tickets!"
        );
        require(
            raffleStorage.GetRaffleStartDate(_raffleId) < block.timestamp,
            "Raffle has not started yet!"
        );
        _;
    }

    function _getTicketsValue(uint256 _raffleId, uint256 _ticketsNumber)
        internal
        view
        returns (uint256)
    {
        uint256 discount = raffleStorage.GetMaximumApplicableDiscount(
            _raffleId,
            _ticketsNumber
        );
        uint256 ticketPrice = raffleStorage.GetRaffleTicketPrice(_raffleId);
        if (discount == 0) return ticketPrice.mul(_ticketsNumber);
        return ticketPrice.mul(_ticketsNumber).mul(discount).div(10000);
    }

    function _receiveFunds(address _tokenAddress, uint256 _amount) internal {
        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "Not enough funds!");
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(
                token.allowance(_msgSender(), address(this)) >= _amount,
                "Not enough funds!"
            );
            token.transferFrom(_msgSender(), address(this), _amount);
        }
    }

    function _giveFunds(
        address _user,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        if (_tokenAddress == address(0)) {
            payable(_user).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            token.transfer(_user, _amount);
        }
    }

    function _beforeWithdraw(uint256 _raffleId) internal view returns (bool) {
        uint256 numberOfTickets = raffleEntriesPositionById[_msgSender()][
            _raffleId
        ].length;
        require(numberOfTickets != 0, "You don't have any tickets!");
        if (
            keccak256(bytes(raffleStorage.GetRaffleType(_raffleId))) ==
            keccak256(bytes("ended"))
        ) {
            return false;
        }
        if (raffleStorage.IsCanceled(_raffleId)) return true;

        uint256 timeOfLastTicketBought = raffleStorage.GetBuyTimeOfTicket(
            _raffleId,
            raffleEntriesPositionById[_msgSender()][_raffleId][
                numberOfTickets - 1
            ]
        );

        if (
            timeOfLastTicketBought +
                raffleStorage.GetRaffleLockDays(_raffleId) <=
            block.timestamp
        ) {
            return true;
        }
        return false;
    }

    function _decideRaffle(uint256 _requestId) internal {
        uint256 raffleId = raffleRandom[_requestId].raffleId;
        uint256 random = raffleRandom[_requestId].random;
        uint256 ticketsBought = raffleStorage.GetRaffleEntriesLength(raffleId);
        uint256 prizesLength = raffleStorage.GetRafflePrizesLength(raffleId);

        raffleStorage.EndRaffle(raffleId);
        if (ticketsBought != 0) {
            for (uint256 i = 0; i < prizesLength; i++) {
                uint256 index = uint256(keccak256(abi.encode(random, i))).mod(
                    ticketsBought
                );
               raffleStorage.AddRaffleWinner(raffleId, i, index);
            }
            // (, address partnerAddress, uint256 amount) = raffleStorage
            //     .GetRafflePartner(raffleId);
            // _giveFunds(
            //     partnerAddress,
            //     raffleStorage.GetRaffleTokenContract(raffleId),
            //     amount
            // );
        }
    }

    function changeCallbackGasLimit(uint32 _callbackGasLimit)
        external
        onlyOwner
    {
        callbackGasLimit = _callbackGasLimit;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _random)
        internal
        override
    {
        raffleRandom[_requestId].random = _random[0];
        _decideRaffle(_requestId);
    }

    function getRandomNumber(uint256 _raffleId) internal {
        require(
            raffleStorage.GetRaffleEntriesLength(_raffleId) ==
                raffleStorage.GetRaffleTicketsNumber(_raffleId),
            "Not all tickets were bought!"
        );

        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            vrfSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        raffleRandom[requestId] = RaffleRandom({
            raffleId: _raffleId,
            random: 0
        });
    }

    function subscribeToRaffle(
        uint256 _raffleId,
        uint256 _ticketsNumber,
        address _refferdBy
    ) external payable checkTicketsAcquisition(_raffleId, _ticketsNumber) {
        uint256 ticketsValue = _getTicketsValue(_raffleId, _ticketsNumber);
        _receiveFunds(
            raffleStorage.GetRaffleTokenContract(_raffleId),
            ticketsValue
        );

        for (uint256 i = 0; i < _ticketsNumber; i++) {
            raffleEntriesPositionById[_msgSender()][_raffleId].push(
                raffleStorage.GetRaffleEntriesLength(_raffleId)
            );
            raffleStorage.AddRaffleEntry(
                _raffleId,
                _msgSender()
            );
        }

        if (_refferdBy != address(0) && _refferdBy != _msgSender()) {
            refferals[_refferdBy].total = refferals[_refferdBy].total.add(
                _ticketsNumber
            );
            bytes32 raffleType = keccak256(
                bytes(raffleStorage.GetRaffleType(_raffleId))
            );
            if (raffleType == keccak256(bytes("bronze"))) {
                refferals[_refferdBy].bronze = refferals[_refferdBy].bronze.add(
                    _ticketsNumber
                );
            } else if (raffleType == keccak256(bytes("silver"))) {
                refferals[_refferdBy].silver = refferals[_refferdBy].silver.add(
                    _ticketsNumber
                );
            } else if (raffleType == keccak256(bytes("gold"))) {
                refferals[_refferdBy].gold = refferals[_refferdBy].gold.add(
                    _ticketsNumber
                );
            } else {
                refferals[_refferdBy].diamond = refferals[_refferdBy]
                    .diamond
                    .add(_ticketsNumber);
            }
        }

        if (
            raffleStorage.GetRaffleEntriesLength(_raffleId) ==
            raffleStorage.GetRaffleTicketsNumber(_raffleId)
        ) {
            getRandomNumber(_raffleId);
        }
    }

    function giveTickets(
        uint256 _raffleId,
        uint256 _ticketsNumber,
        address _to
    ) external onlyOwner checkTicketsAcquisition(_raffleId, _ticketsNumber) {
        for (uint256 i = 0; i < _ticketsNumber; i++) {
            raffleEntriesPositionById[_to][_raffleId].push(
                raffleStorage.GetRaffleEntriesLength(_raffleId)
            );
            raffleStorage.AddRaffleEntry(_raffleId, _to);
        }
    }

    function withdrawSubscription(uint256 _raffleId) public {
        require(
            _beforeWithdraw(_raffleId),
            "You cannot withdraw your tickets!"
        );

        uint256 ticketsPrice = _getTicketsValue(
            _raffleId,
            raffleEntriesPositionById[_msgSender()][_raffleId].length
        );

        _giveFunds(
            _msgSender(),
            raffleStorage.GetRaffleTokenContract(_raffleId),
            ticketsPrice
        );

        uint256 ticketsRemovedFromBuyer = 0;
        address previousBuyer = address(0);
        while (raffleEntriesPositionById[_msgSender()][_raffleId].length < 0) {
            address buyer = raffleStorage.RemoveRaffleEntry(
                _raffleId,
                raffleEntriesPositionById[_msgSender()][_raffleId][
                    raffleEntriesPositionById[_msgSender()][_raffleId].length -
                        1
                ]
            );
            if (previousBuyer != buyer) {
                previousBuyer = buyer;
                ticketsRemovedFromBuyer = 0;
            }
            raffleEntriesPositionById[buyer][_raffleId][
                raffleEntriesPositionById[buyer][_raffleId].length -
                    ticketsRemovedFromBuyer.add(1)
            ] = raffleEntriesPositionById[_msgSender()][_raffleId][
                raffleEntriesPositionById[_msgSender()][_raffleId].length - 1
            ];
            raffleEntriesPositionById[_msgSender()][_raffleId].pop();
        }
    }

    function withdrawOwnerFunds(uint256 _raffleId, uint256 _amount)
        external
        onlyOwner
    {
        require(
            keccak256(bytes(raffleStorage.GetRaffleType(_raffleId))) ==
                keccak256(bytes("ended"))
        );
        _giveFunds(
            owner(),
            raffleStorage.GetRaffleTokenContract(_raffleId),
            _amount
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.7;

import "./Context.sol";

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

pragma solidity ^0.8.7;

//SPDX-License-Identifier: Unlicensed

interface IRaffleWorldStorage {
    /**
     * @dev Emitted when a new raffle has been added
     */
    event NewRaffle(
        uint256 indexed raffleId,
        address tokenContract,
        uint256 ticketPrice,
        uint256 ticketsNumber,
        string raffleType,
        uint256 raffleStartDate,
        uint256 lockDays,
        string raffleName
    );

    /**
     * @dev Emitted when a raffle has been activated
     */
    event RaffleActivated(uint256 indexed raffleId);

    /**
     * @dev Emitted when a raffle has been canceled
     */
    event RaffleCanceled(uint256 indexed raffleId);

    /**
     * @dev Emitted when the token contract for a raffle has been changed for a raffle
     */
    event TokenContractAddressChanged(
        uint256 indexed raffleId,
        address newTokenContractAddress
    );

    /**
     * @dev Emitted when the price of a ticket for a raffle has been changed for a raffle
     */
    event TicketPriceChanged(uint256 indexed raffleId, uint256 ticketPrice);

    /**
     * @dev Emitted when the number of tickets has been changed for a raffle
     */
    event TicketsNumberChanged(uint256 indexed raffleId, uint256 ticketsNumber);

    /**
     * @dev Emitted when the type of a raffle has been changed for a raffle
     */
    event TypeChanged(uint256 indexed raffleId, string raffleType);

    /**
     * @dev Emitted when the start date has been changed for a raffle
     */
    event StartDateChanged(uint256 indexed raffleId, uint256 startDate);

    /**
     * @dev Emitted when the lock days have been changed for raffle
     */
    event LockDaysChanged(uint256 indexed raffleId, uint256 lockDays);

    /**
     * @dev Emitted when the name of the raffle has been changed for raffle
     */
    event NameChanged(uint256 indexed raffleId, string name);

    /**
     * @dev Emitted when a partner is being set for a raffle
     */
    event PartnerAdded(
        uint256 indexed raffleId,
        string partnerName,
        address partnerAddress,
        uint256 partnerAmount
    );

    /**
     * @dev Emitted when a partner is being removed from a raffle
     */
    event PartnerReseted(uint256 indexed raffleId);

    /**
     * @dev Emitted when a prize is being added for a raffle
     */
    event PrizeAdded(
        uint256 indexed raffleId,
        address nftAddress,
        uint256 nftId
    );

    /**
     * @dev Emitted when a prize is being removed from a raffle
     */
    event PrizeRemoved(
        uint256 indexed raffleId,
        address nftAddress,
        uint256 nftId
    );

    /**
     * @dev Emitted when a winner has been computed for a raffle
     */
    event WinnerComputed(
        uint256 indexed raffleId,
        address indexed winner,
        address nftAddress,
        uint256 nftId
    );

    /**
     * @dev Emitted when a new discount is being added for a raffle
     */
    event DiscountAdded(
        uint256 indexed raffleId,
        uint256 minTickets,
        uint256 percentage
    );

    /**
     * @dev Emitted when a discount is being removed from a raffle
     */
    event DiscountRemoved(
        uint256 indexed raffleId,
        uint256 minTickets,
        uint256 percentage
    );

    /**
     * @dev Emitted when an entry is being added for a raffle
     */
    event TicketBought(uint256 indexed raffleId, address buyer);

    /**
     * @dev Emitted when an user is withdrawing a ticket
     */
    event TicketWithdrawed(
        uint256 indexed raffleId,
        address buyer,
        uint256 index
    );

    /**
     * @dev used to create and activate a new raffle for a raffle
     */
    function AddRaffle(
        address _tokenContract,
        uint256 _ticketPrice,
        uint256 _ticketsNumber,
        string memory _raffleType,
        uint256 _raffleStartDate,
        uint256 _lockDays,
        string memory _raffleName
    ) external;

    function GetRaffleStatus(uint256 _raffleId)
        external
        view
        returns (string memory);

    /**
     * @dev used to cancel an active raffle
     */
    function CancelRaffle(uint256 _raffleId) external;

    /**
     * @dev used to mark raffle as ended
     */
    function EndRaffle(uint256 _raffleId) external;

    /**
     * @dev returns true if the raffle is canceled, false otherwise
     */
    function IsCanceled(uint256 _raffleId) external view returns (bool);

    /**
     * @dev used to set the address of the token used by the raffle as currency
     */
    function SetRaffleTokenContract(uint256 _raffleId, address _tokenContract)
        external;

    /**
     * @dev returns the address of the token used by the raffle as currency
     */
    function GetRaffleTokenContract(uint256 _raffleId)
        external
        view
        returns (address);

    /**
     * @dev uset to set the raffle ticketPrice
     * @dev you need to take in consideration the decimals of the token
     */
    function SetRaffleTicketPrice(uint256 _raffleId, uint256 _ticketPrice)
        external;

    /**
     * @dev returns the price of 1 ticket for the specified raffle
     */
    function GetRaffleTicketPrice(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev used to change the number of tickets for the specified raffle
     */
    function SetRaffleTicketsNumber(uint256 _raffleId, uint256 _ticketsNumber) external;

    /**
     * @dev returns the number of tickets that the specified raffle has
     */
    function GetRaffleTicketsNumber(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev used to set the raffle type
     * type can be: bronze, silver, gold, diamond
     */
    function SetRaffleType(uint256 _raffleId, string memory _raffleType)
        external;

    /**
     * @dev returns the type of the specified raffle
     */
    function GetRaffleType(uint256 _raffleId)
        external
        view
        returns (string memory);

    /**
     * @dev used to set the raffle start date
     */
    function SetRaffleStartDate(uint256 _raffleId, uint256 _raffleStartDate)
        external;

    /**
     * @dev returns the start date of the specified raffle
     */
    function GetRaffleStartDate(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev used to set the number of days before one can withdraw his tickets from the specified raffle
     */
    function SetRaffleLockDays(uint256 _raffleId, uint256 _lockDays) external;

    /**
     * @dev returns the number of days before one can withdraw his tickets from the specified raffle
     */
    function GetRaffleLockDays(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev used to set the raffle name for the specified raffle
     */
    function SetRaffleName(uint256 _raffleId, string memory _raffleName)
        external;

    /**
     * @dev returns the name of the specified raffle
     */
    function GetRaffleName(uint256 _raffleId)
        external
        view
        returns (string memory);

    /**
     * @dev used to set the raffle partner
     */
    function SetRafflePartner(
        uint256 _raffleId,
        string memory _partnerName,
        address _partnerAddress,
        uint256 _partnerAmount
    ) external;

    /**
     * @dev reset the raffle partner
     * default: name: Raffle World, adress: 0x0, amount: 0
     */
    function ResetRafflePartner(uint256 _raffleId) external;

    /**
     * @dev returns the details of the specified raffle partner
     */
    function GetRafflePartner(uint256 _raffleId)
        external
        view
        returns (
            string memory,
            address,
            uint256
        );

    /**
     * @dev return the number of raffles with the passed type
     */
    function GetRafflesLength(string memory _raffleType)
        external
        view
        returns (uint256);

    /**
     * @dev return the number of active raffles with the passed type
     */
    function GetActiveRafflesLength(string memory _raffleType)
        external
        view
        returns (uint256);

    /**
     * @dev adds a new prize for the specified raffle
     */
    function AddRafflePrize(
        uint256 _raffleId,
        address _nftAddress,
        uint256 _nftId
    ) external;

    /**
     * @dev removes a prize from the specified raffle
     */
    function RemoveRafflePrize(uint256 _raffleId, uint256 _index) external;

    /**
     * @dev returns the prize from { _index } poistion for the specified raffle
     */
    function GetRafflePrize(uint256 _raffleId, uint256 _index)
        external
        view
        returns (
            address,
            address,
            uint256
        );

    /**
     * @dev returns the number of the prizes that a raffle has
     */
    function GetRafflePrizesLength(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev adds the winner of the prize indicated by {{ _index }} for the specified raffle 
     */
    function AddRaffleWinner(uint256 _raffleId, uint256 _prizeIndex, uint256 _ticketIndex) external;

    /**
     * @dev adds a new discount to the specified raffle
     */
    function AddRaffleDiscount(
        uint256 _raffleId,
        uint256 _minTickets,
        uint256 _percentage
    ) external;

    /**
     * @dev removes a discount from the speicified raffle
     */
    function RemoveRaffleDiscount(uint256 _raffleId, uint256 _index) external;

    /**
     * @dev returns the discount form the { _discountIndex } position for the specified raffle
     */
    function GetRaffleDiscount(uint256 _raffleId, uint256 _index)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev return the number of discounts for that a raffle has
     */
    function GetRaffleDiscountsLength(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev returns the maximum discount that can be applied based on the number of tickets for the specified raffle
     */
    function GetMaximumApplicableDiscount(
        uint256 _raffleId,
        uint256 _ticketsNumber
    ) external view returns (uint256);

    /**
     * @dev adds a new entry to the specified raffle
     */
    function AddRaffleEntry(
        uint256 _raffleId,
        address _buyer
    ) external;

    /**
     * @dev removes an entry for the specified raffle
     */
    function RemoveRaffleEntry(uint256 _raffleId, uint256 _index) external returns(address);

    /**
     * @dev returns the number of entries that a raffle has
     */
    function GetRaffleEntriesLength(uint256 _raffleId)
        external
        view
        returns (uint256);

    /**
     * @dev returns the timestamp when the ticket has been bought
     */
    function GetBuyTimeOfTicket(uint256 _raffleId, uint256 _index) external view returns(uint256);

    /**
     * @dev returns the address of the buyer of the ticket with index {{ _index }} from the specified raffle
     */
    function GetBuyer(uint256 _raffleId, uint256 _index) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.7;

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