pragma solidity ^0.6.12;
//SPDX-License-Identifier: Unlicensed

//library contracts
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

//chain link
import "./VRFConsumerBase.sol";

contract RaffleSumantria is Ownable, VRFConsumerBase {
    event SetRequiredRaffleLink(
        address indexed user,
        uint256 _requireRaffleLink
    );
    event AddRaffle(
        address indexed user,
        address _tokenContract,
        uint256 _ticketPrice,
        uint256 _ticketsNumber,
        uint256 _prizeAmount,
        string _raffleType,
        uint256 _raffleStartDate,
        uint256 _lockDays,
        string _raffleName,
        bool _canceled,
        string _status
    );
    event SetRafflePrizeAmount(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _prizeAmount
    );
    event SetRaffleDiscountLevels(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _ticketsNo,
        uint256 discountPercentage
    );
    event SetRaffleCanceledStatus(
        address indexed user,
        uint256 indexed _raffleId,
        bool _canceled
    );
    event Winner(
        address indexed winner,
        uint256 indexed _raffleId,
        uint256 _amount
    );

    modifier beforeRaffleStart(uint256 _raffleId) {
        require(
            block.timestamp < raffles[_raffleId].raffleStartDate,
            "You cannot update raffle params after it started!"
        );
        _;
    }

    modifier checkTicketsAcquisition(uint256 _raffleId, uint256 _ticketsNo) {
        require(raffles[_raffleId].canceled == false, "Raffle is canceled!");
        require(
            keccak256(bytes(raffles[_raffleId].status)) !=
                keccak256(bytes("ended")),
            "Raffle has ended!"
        );
        require(
            raffleEntries[_raffleId].length.add(_ticketsNo) <=
                raffles[_raffleId].ticketsNumber,
            "You need to buy less tickets!"
        );
        require(
            raffles[_raffleId].raffleStartDate < block.timestamp,
            "Raffle has not started yet!"
        );
        _;
    }

    struct DiscountLevel {
        uint256 ticketsNumber;
        uint256 discountPercentage;
    }

    struct WinnerStructure {
        uint256 index;
        uint256 percentage;
        address winnerAddress;
    }

    struct RaffleRefferals {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
        uint256 diamond;
        uint256 totalRefferals;
        uint256 ticketsGivenByAdmin;
    }

    struct RaffleRandom {
        uint256 raffleId;
        uint256 random;
    }

    struct RaffleEntry {
        address buyer;
        uint256 buy_time;
    }

    struct RaffleIndices {
        uint256 raffles_index;
        uint256 active_raffles_index;
        uint256 raffles_by_type_index;
        uint256 active_raffles_by_type_index;
    }

    mapping(uint256 => DiscountLevel[]) public discountLevels;
    mapping(uint256 => WinnerStructure[]) public winnerStructure;
    mapping(uint256 => RaffleEntry[]) public raffleEntries;
    mapping(address => mapping(uint256 => uint256[]))
        public raffleEntriesPositionById;
    mapping(address => RaffleRefferals) public refferals;
    mapping(bytes32 => RaffleRandom) public randomRequests;
    mapping(uint256 => RaffleIndices) public rafflesIndices;

    struct Raffle {
        address tokenContract;
        uint256 ticketPrice;
        uint256 ticketsNumber;
        uint256 prizeAmount;
        string raffleType;
        uint256 raffleStartDate;
        uint256 lockDays;
        string raffleName;
        bool canceled;
        string status;
        uint256 totalPercentage;
    }

    uint256 public requiredRaffleLink = 0;
    uint256 public activeRaffles = 0;
    uint256 public rafflesNumber = 0;
    Raffle[] public raffles;
    uint256[] public active_raffles;
    uint256[] public bronze_raffles;
    uint256[] public active_bronze_raffles;
    uint256[] public silver_raffles;
    uint256[] public active_silver_raffles;
    uint256[] public gold_raffles;
    uint256[] public active_gold_raffles;
    uint256[] public diamond_raffles;
    uint256[] public active_diamond_raffles;

    address private immutable linkTokenContractAddress;
    IERC20 private immutable linkToken;

    address private immutable vrfCoordinatorAddress;

    bytes32 private keyHash;
    uint256 public randomResult;

    constructor(
        bytes32 _keyHash,
        address _vrfCoordinatorAddress,
        address _linkTokenContractAddress,
        uint256 _requiredRaffleLink
    )
        public
        VRFConsumerBase(_vrfCoordinatorAddress, _linkTokenContractAddress)
    {
        keyHash = _keyHash;
        linkTokenContractAddress = _linkTokenContractAddress;
        linkToken = IERC20(_linkTokenContractAddress);
        vrfCoordinatorAddress = _vrfCoordinatorAddress;
        requiredRaffleLink = _requiredRaffleLink;
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

    /*
        Check if raffle type is valid and raffle start date is in future 
    */
    function _checkRaffleParams(
        string memory _raffleType,
        uint256 _raffleStartDate
    ) internal view returns (bool) {
        bool raffleTypeValidity = false;
        if (keccak256(bytes(_raffleType)) == keccak256(bytes("bronze")))
            raffleTypeValidity = true;
        else if (keccak256(bytes(_raffleType)) == keccak256(bytes("silver")))
            raffleTypeValidity = true;
        else if (keccak256(bytes(_raffleType)) == keccak256(bytes("gold")))
            raffleTypeValidity = true;
        else if (keccak256(bytes(_raffleType)) == keccak256(bytes("diamond")))
            raffleTypeValidity = true;
        bool raffleStartDayValidity = false;
        if (_raffleStartDate >= block.timestamp) raffleStartDayValidity = true;
        return raffleTypeValidity && raffleStartDayValidity;
    }

    /*
        Add a raffle to the coresponding array 
    */
    function addRaffle(
        address _tokenContract,
        uint256 _ticketPrice,
        uint256 _ticketsNumber,
        uint256 _prizeAmount,
        string memory _raffleType,
        uint256 _raffleStartDate,
        uint256 _lockDays,
        string memory _raffleName
    ) external onlyOwner {
        //check if raffle type and raffle start date are valid
        require(
            _checkRaffleParams(_raffleType, _raffleStartDate) == true,
            "Raffle type or start date wrong!"
        );

        //check if the contract has enough link tokens to add the raffle
        uint256 requiredLinkAmount = activeRaffles.add(1).mul(
            requiredRaffleLink
        );
        require(
            requiredLinkAmount <= linkToken.balanceOf(address(this)),
            "Not enough LINK Tokens to add raffle!"
        );
        rafflesNumber = rafflesNumber.add(1);
        //add raffle to the main array
        raffles.push(
            Raffle({
                tokenContract: _tokenContract,
                ticketPrice: _ticketPrice,
                ticketsNumber: _ticketsNumber,
                prizeAmount: _prizeAmount,
                raffleType: _raffleType,
                raffleStartDate: _raffleStartDate,
                lockDays: _lockDays,
                raffleName: _raffleName,
                canceled: false,
                status: "ongoing",
                totalPercentage: 0
            })
        );

        //activate the raffle
        _activateRaffle(raffles.length - 1);

        rafflesIndices[raffles.length - 1].raffles_index = raffles.length - 1;

        //add the raffle to the coresponding array and set the index
        if (
            keccak256(bytes(raffles[raffles.length - 1].raffleType)) ==
            keccak256(bytes("bronze"))
        ) {
            bronze_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                bronze_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[raffles.length - 1].raffleType)) ==
            keccak256(bytes("silver"))
        ) {
            silver_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                silver_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[raffles.length - 1].raffleType)) ==
            keccak256(bytes("gold"))
        ) {
            gold_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                gold_raffles.length -
                1;
        } else {
            diamond_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                diamond_raffles.length -
                1;
        }

        emit AddRaffle(
            _msgSender(),
            _tokenContract,
            _ticketPrice,
            _ticketsNumber,
            _prizeAmount,
            _raffleType,
            _raffleStartDate,
            _lockDays,
            _raffleName,
            false,
            "ongoing"
        );
    }

    /*
        set the canceled status to false and add the raffle to the coresponding arrays
    */
    function _activateRaffle(uint256 _raffleId) internal {
        raffles[_raffleId].canceled = false;

        //increment the active raf
        activeRaffles = activeRaffles.add(1);
        active_raffles.push(_raffleId);
        rafflesIndices[_raffleId].active_raffles_index =
            active_raffles.length -
            1;

        if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("bronze"))
        ) {
            active_bronze_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_bronze_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("silver"))
        ) {
            active_silver_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_silver_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("gold"))
        ) {
            active_gold_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_gold_raffles.length -
                1;
        } else {
            active_diamond_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_diamond_raffles.length -
                1;
        }
    }

    /*
        set the canceled status to true and removes the raffle from the coresponding arrays
    */
    function _cancelRaffle(uint256 _raffleId) internal {
        raffles[_raffleId].canceled = true;

        active_raffles[
            rafflesIndices[_raffleId].active_raffles_index
        ] = active_raffles[
            rafflesIndices[active_raffles[active_raffles.length - 1]]
                .active_raffles_index
        ];
        rafflesIndices[active_raffles[active_raffles.length - 1]]
            .active_raffles_index = rafflesIndices[_raffleId]
            .active_raffles_index;
        rafflesIndices[_raffleId].active_raffles_index = uint256(-1);

        activeRaffles = activeRaffles.sub(1);
        active_raffles.pop();

        if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("bronze"))
        ) {
            active_bronze_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_bronze_raffles[active_bronze_raffles.length - 1];
            rafflesIndices[
                active_bronze_raffles[active_bronze_raffles.length - 1]
            ].active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_bronze_raffles.pop();
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("silver"))
        ) {
            active_silver_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_silver_raffles[active_silver_raffles.length - 1];
            rafflesIndices[
                active_silver_raffles[active_silver_raffles.length - 1]
            ].active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_silver_raffles.pop();
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("gold"))
        ) {
            active_gold_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_gold_raffles[active_gold_raffles.length - 1];
            rafflesIndices[active_gold_raffles[active_gold_raffles.length - 1]]
                .active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_gold_raffles.pop();
        } else {
            active_diamond_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_diamond_raffles[active_diamond_raffles.length - 1];
            rafflesIndices[
                active_diamond_raffles[active_diamond_raffles.length - 1]
            ].active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_diamond_raffles.pop();
        }
    }

    function setRequiredRaffleLink(uint256 _requiredRaffleLink)
        external
        onlyOwner
    {
        requiredRaffleLink = _requiredRaffleLink;
        emit SetRequiredRaffleLink(_msgSender(), _requiredRaffleLink);
    }

    function setRaffleName(uint256 _raffleId, string memory _name)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        raffles[_raffleId].raffleName = _name;
    }

    function setRafflePrizeAmount(uint256 _raffleId, uint256 _prizeAmount)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        require(_prizeAmount > 0, "Prize should be greater than 0!");
        raffles[_raffleId].prizeAmount = _prizeAmount;
        emit SetRafflePrizeAmount(_msgSender(), _raffleId, _prizeAmount);
    }

    function setRaffleTicketPrice(uint256 _raffleId, uint256 _ticketPrice)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        require(_ticketPrice > 0, "Ticket price should be greater than 0!");
        raffles[_raffleId].ticketPrice = _ticketPrice;
    }

    function setRaffleTicketsNumber(uint256 _raffleId, uint256 _ticketsNumber)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        raffles[_raffleId].ticketsNumber = _ticketsNumber;
    }

    function setRaffleStartDate(uint256 _raffleId, uint256 _raffleStartDate)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        require(
            _raffleStartDate > block.timestamp,
            "Start date should be in the future!"
        );
        raffles[_raffleId].raffleStartDate = _raffleStartDate;
    }

    function setRaffleLockDays(uint256 _raffleId, uint256 _lockDays)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        raffles[_raffleId].lockDays = _lockDays;
    }

    function setRaffleDiscountLevels(
        uint256 _raffleId,
        uint256 _ticketsNo,
        uint256 _discountPercentage
    ) external onlyOwner {
        bool existed = false;
        for (uint256 i = 0; i < discountLevels[_raffleId].length; i++) {
            if (discountLevels[_raffleId][i].ticketsNumber == _ticketsNo) {
                if (_discountPercentage == 0) {
                    discountLevels[_raffleId][i] = discountLevels[_raffleId][
                        discountLevels[_raffleId].length.sub(1)
                    ];
                    discountLevels[_raffleId].pop();
                } else {
                    discountLevels[_raffleId][i]
                        .discountPercentage = _discountPercentage;
                }
                existed = true;
                break;
            }
        }
        if (existed == false) {
            discountLevels[_raffleId].push(
                DiscountLevel({
                    ticketsNumber: _ticketsNo,
                    discountPercentage: _discountPercentage
                })
            );
        }
        emit SetRaffleDiscountLevels(
            _msgSender(),
            _raffleId,
            _ticketsNo,
            _discountPercentage
        );
    }

    function setRaffleWinnerStructure(
        uint256 _raffleId,
        uint256 _index,
        uint256 _percentage
    ) external beforeRaffleStart(_raffleId) onlyOwner {
        bool existed = false;
        uint256 totalPercentage = raffles[_raffleId].totalPercentage;
        for (uint256 i = 0; i < winnerStructure[_raffleId].length; i++) {
            if (winnerStructure[_raffleId][i].index == _index) {
                if (_percentage == 0) {
                    raffles[_raffleId].totalPercentage = raffles[_raffleId]
                        .totalPercentage
                        .sub(winnerStructure[_raffleId][i].percentage);
                    winnerStructure[_raffleId][i] = winnerStructure[_raffleId][
                        winnerStructure[_raffleId].length.sub(1)
                    ];
                    winnerStructure[_raffleId].pop();
                } else {
                    totalPercentage = totalPercentage.sub(
                        winnerStructure[_raffleId][i].percentage
                    );
                    totalPercentage = totalPercentage.add(_percentage);
                    require(
                        totalPercentage <= 10000,
                        "Total percentage should be less or equal with 100"
                    );
                    raffles[_raffleId].totalPercentage = raffles[_raffleId]
                        .totalPercentage
                        .sub(winnerStructure[_raffleId][i].percentage);
                    winnerStructure[_raffleId][i].percentage = _percentage;
                    raffles[_raffleId].totalPercentage = raffles[_raffleId]
                        .totalPercentage
                        .add(_percentage);
                }
                existed = true;
                break;
            }
        }
        if (existed == false) {
            totalPercentage = totalPercentage.add(_percentage);
            require(
                totalPercentage <= 10000,
                "Total percentage should be less or equal with 100"
            );
            raffles[_raffleId].totalPercentage = raffles[_raffleId]
                .totalPercentage
                .add(_percentage);
            winnerStructure[_raffleId].push(
                WinnerStructure({
                    index: _index,
                    percentage: _percentage,
                    winnerAddress: address(0x00)
                })
            );
        }
    }

    function getRafflesLength(string memory _raffleType)
        public
        view
        returns (uint256)
    {
        if (keccak256(bytes(_raffleType)) == keccak256(bytes("bronze"))) {
            return bronze_raffles.length;
        } else if (
            keccak256(bytes(_raffleType)) == keccak256(bytes("silver"))
        ) {
            return silver_raffles.length;
        } else if (keccak256(bytes(_raffleType)) == keccak256(bytes("gold"))) {
            return gold_raffles.length;
        } else {
            require(
                keccak256(bytes(_raffleType)) == keccak256(bytes("diamond")),
                "Raffle: incorrect raffle type!"
            );
            return diamond_raffles.length;
        }
    }

    function getActiveRafflesLength(string memory _raffleType)
        public
        view
        returns (uint256)
    {
        if (keccak256(bytes(_raffleType)) == keccak256(bytes("bronze"))) {
            return active_bronze_raffles.length;
        } else if (
            keccak256(bytes(_raffleType)) == keccak256(bytes("silver"))
        ) {
            return active_silver_raffles.length;
        } else if (keccak256(bytes(_raffleType)) == keccak256(bytes("gold"))) {
            return active_gold_raffles.length;
        } else {
            require(
                keccak256(bytes(_raffleType)) == keccak256(bytes("diamond")),
                "Incorrect raffle type!"
            );
            return active_diamond_raffles.length;
        }
    }

    function getWinnerStructure(uint256 _raffleIndex, uint256 _structureIndex)
        external
        view
        returns (uint256 percentage, address winnerAddress)
    {
        return (
            winnerStructure[_raffleIndex][_structureIndex].percentage,
            winnerStructure[_raffleIndex][_structureIndex].winnerAddress
        );
    }

    function boughtRaffleTicketsByUser(address _user, uint256 _raffleId)
        external
        view
        returns (uint256)
    {
        return raffleEntriesPositionById[_user][_raffleId].length;
    }

    function boughtRaffleTickets(uint256 _raffleId)
        external
        view
        returns (uint256)
    {
        return raffleEntries[_raffleId].length;
    }

    function getPrizesNumber(uint256 _raffleId)
        external
        view
        returns (uint256)
    {
        return winnerStructure[_raffleId].length;
    }

    function _addRaffleWinner(
        uint256 _raffleId,
        uint256 _winIndex,
        uint256 _winnerIndex
    ) internal {
        winnerStructure[_raffleId][_winIndex].winnerAddress = raffleEntries[
            _raffleId
        ][_winnerIndex].buyer;
    }

    function _sendRaffleWinnerMoney(uint256 _raffleId, uint256 _winIndex)
        internal
    {
        uint256 amount = winnerStructure[_raffleId][_winIndex]
            .percentage
            .mul(raffles[_raffleId].prizeAmount)
            .div(raffles[_raffleId].totalPercentage);

        address winner = winnerStructure[_raffleId][_winIndex].winnerAddress;
        emit Winner(winner, _raffleId, amount);
        _giveFunds(winner, raffles[_raffleId].tokenContract, amount);
    }

    function setRaffleCanceledStatus(uint256 _raffleId, bool _canceled)
        external
        onlyOwner
    {
        if (_canceled == true) _cancelRaffle(_raffleId);
        else _activateRaffle(_raffleId);
        emit SetRaffleCanceledStatus(_msgSender(), _raffleId, _canceled);
    }

    function _getTicketsValue(uint256 _raffleId, uint256 _ticketsNo)
        internal
        view
        returns (uint256)
    {
        uint256 discount = 0;
        for (uint256 i = 0; i < discountLevels[_raffleId].length; i++) {
            if (discountLevels[_raffleId][i].ticketsNumber <= _ticketsNo) {
                discount = discountLevels[_raffleId][i].discountPercentage;
            } else {
                break;
            }
        }
        if (discount == 0)
            return raffles[_raffleId].ticketPrice.mul(_ticketsNo);
        discount = raffles[_raffleId]
            .ticketPrice
            .mul(_ticketsNo)
            .mul(discount)
            .div(10000);
        return raffles[_raffleId].ticketPrice.mul(_ticketsNo) - discount;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _raffleId)
        public
        returns (bytes32 requestId)
    {
        require(
            raffleEntries[_raffleId].length == raffles[_raffleId].ticketsNumber,
            "Raffle: not all tickets were bought!"
        );
        requestId = requestRandomness(keyHash, requiredRaffleLink);
        randomRequests[requestId] = RaffleRandom({
            raffleId: _raffleId,
            random: 0
        });
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        randomRequests[requestId].random = randomness;
        _decideRaffle(requestId);
    }

    function _decideRaffle(bytes32 _requestId) internal {
        //getting the number of digits that raffle entries has
        uint256 _raffleId = randomRequests[_requestId].raffleId;
        uint256 random = randomRequests[_requestId].random;
        uint256 entries = raffleEntries[_raffleId].length;
        raffles[_raffleId].status = "ended";
        if (entries != 0) {
            for (uint256 i = 0; i < winnerStructure[_raffleId].length; i++) {
                uint256 index = uint256(keccak256(abi.encode(random, i))).mod(
                    raffleEntries[_raffleId].length
                );
                _addRaffleWinner(_raffleId, i, index);
                _sendRaffleWinnerMoney(_raffleId, i);
            }
        }
    }

    function subscribeToRaffle(
        uint256 _raffleId,
        uint256 _ticketsNo,
        address _refferedBy
    ) external payable checkTicketsAcquisition(_raffleId, _ticketsNo) {
        uint256 ticketsValue = _getTicketsValue(_raffleId, _ticketsNo);
        _receiveFunds(raffles[_raffleId].tokenContract, ticketsValue);

        for (uint256 i = 0; i < _ticketsNo; i++) {
            raffleEntriesPositionById[_msgSender()][_raffleId].push(
                raffleEntries[_raffleId].length
            );
            raffleEntries[_raffleId].push(
                RaffleEntry({buyer: _msgSender(), buy_time: block.timestamp})
            );
        }

        if (_refferedBy != address(0) && _refferedBy != _msgSender()) {
            refferals[_refferedBy].totalRefferals = refferals[_refferedBy]
                .totalRefferals
                .add(_ticketsNo);
            if (
                keccak256(bytes(raffles[_raffleId].raffleType)) ==
                keccak256(bytes("bronze"))
            ) {
                refferals[_refferedBy].bronze = refferals[_refferedBy]
                    .bronze
                    .add(_ticketsNo);
            } else if (
                keccak256(bytes(raffles[_raffleId].raffleType)) ==
                keccak256(bytes("silver"))
            ) {
                refferals[_refferedBy].silver = refferals[_refferedBy]
                    .silver
                    .add(_ticketsNo);
            } else if (
                keccak256(bytes(raffles[_raffleId].raffleType)) ==
                keccak256(bytes("gold"))
            ) {
                refferals[_refferedBy].gold = refferals[_refferedBy].gold.add(
                    1
                );
            } else {
                refferals[_refferedBy].diamond = refferals[_refferedBy]
                    .diamond
                    .add(_ticketsNo);
            }
        }

        if (
            raffleEntries[_raffleId].length == raffles[_raffleId].ticketsNumber
        ) {
            getRandomNumber(_raffleId);
        }
    }

    function giveTickets(
        uint256 _raffleId,
        uint256 _ticketsNo,
        address _to
    ) external onlyOwner checkTicketsAcquisition(_raffleId, _ticketsNo) {
        for (uint256 i = 0; i < _ticketsNo; i++) {
            raffleEntriesPositionById[_to][_raffleId].push(
                raffleEntries[_raffleId].length
            );
            raffleEntries[_raffleId].push(
                RaffleEntry({buyer: _to, buy_time: block.timestamp})
            );
        }

        refferals[_to].ticketsGivenByAdmin = refferals[_to]
            .ticketsGivenByAdmin
            .add(_ticketsNo);

        if (
            raffleEntries[_raffleId].length == raffles[_raffleId].ticketsNumber
        ) {
            getRandomNumber(_raffleId);
        }
    }

    function _beforeWithdraw(uint256 _raffleId) internal view returns (bool) {
        require(
            raffleEntriesPositionById[_msgSender()][_raffleId].length != 0,
            "You don't have any tickets!"
        );
        if (
            keccak256(bytes(raffles[_raffleId].status)) ==
            keccak256(bytes("ended"))
        ) return false;
        if (raffles[_raffleId].canceled == true) {
            return true;
        }
        uint256 length = raffleEntriesPositionById[_msgSender()][_raffleId]
            .length;
        uint256 time_of_last_subscribtion = raffleEntries[_raffleId][
            raffleEntriesPositionById[_msgSender()][_raffleId][length - 1]
        ].buy_time;
        if (
            time_of_last_subscribtion + raffles[_raffleId].lockDays <=
            block.timestamp
        ) {
            return true;
        }
        return false;
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
            raffles[_raffleId].tokenContract,
            ticketsPrice.sub(ticketsPrice.div(10))
        );

        while (raffleEntriesPositionById[_msgSender()][_raffleId].length != 0) {
            uint256 sender_last_ticket_index = raffleEntriesPositionById[
                _msgSender()
            ][_raffleId][
                raffleEntriesPositionById[_msgSender()][_raffleId].length - 1
            ];
            raffleEntries[_raffleId][sender_last_ticket_index] = raffleEntries[_raffleId][
                raffleEntries[_raffleId].length - 1
            ];
            address last_guy = raffleEntries[_raffleId][
                raffleEntries[_raffleId].length - 1
            ].buyer;
            uint256 max = 0;
            uint256 pos = 0;
            if (sender_last_ticket_index < raffleEntries[_raffleId].length) {
                for (
                    uint256 i = 0;
                    i < raffleEntriesPositionById[last_guy][_raffleId].length;
                    i++
                ) {
                    if (
                        raffleEntriesPositionById[last_guy][_raffleId][i] > max
                    ) {
                        max = raffleEntriesPositionById[last_guy][_raffleId][i];
                        pos = i;
                    }
                }
                raffleEntriesPositionById[last_guy][_raffleId][
                    pos
                ] = sender_last_ticket_index;
            }
            raffleEntriesPositionById[_msgSender()][_raffleId].pop();
            raffleEntries[_raffleId].pop();
        }
    }

    function withdrawOwnerFunds(uint256 _raffleId, uint256 _amount)
        external
        onlyOwner
    {
        require(
            keccak256(bytes(raffles[_raffleId].status)) ==
                keccak256(bytes("ended"))
        );
        _giveFunds(owner(), raffles[_raffleId].tokenContract, _amount);
    }
}