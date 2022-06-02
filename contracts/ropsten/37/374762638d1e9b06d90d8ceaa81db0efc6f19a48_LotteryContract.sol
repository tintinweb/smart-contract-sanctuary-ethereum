// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./VRFConsumerBase.sol";

import "./IERC20.sol";



contract LotteryContract is VRFConsumerBase {
    
    
 string private contractName = "Lottery Contract";
    address private admin;
    // Start: Configration for game
    uint256 private totalTickets = 1050; // total tickets in one round
    uint256 private oneTicketPrice = 10**18; // 1 Matic / Ether / BNB
    uint256 private oneWinnerReward = 450*10**18; // 450 matic / Ether / BNB
    uint256 private totalWinnerCount = 2; // for one round

    // End: Configration for game

    // Start:

    uint256 private CurrentGameCount; // which game round is currently going on
    mapping(uint256 => uint256) private onlySoldTicketOfGame; // gamecount => how many tickets  sold (only) (like 1,2,3,4...)
    mapping(uint256 => uint256) private totalTicketOfGame; // gamecount => there are how many tickets (like 1,2,3,4...)

    bool private canPlayerBuyTicket = false;

    mapping(uint256 => address[]) private playersOfGame; // gamecount => players in the game

    struct UserTicket {
        uint256 ticket; // ticket no
        string by; // user get ticket by Refferal , Buy
    }
    mapping(address => mapping(uint256 => UserTicket[]))
        private ticketsOfUserInGame; // owner=>(gamecount=>tickets)

    mapping(uint256 => mapping(uint256 => address)) private inGameOwnerOfTicket; // gamecount=>(ticket=>owner)

    struct RandomVariables {
        uint256 First;
        uint256 Secound;
    }

    // can't see anyone
    mapping(uint256 => uint256) private private_random_variable_forgame; // gamecount=>random variable for this game and this will private

    struct WinnerPlayer {
        address Player1;
        address Player2;
        uint256 Ticket1;
        uint256 Ticket2;
        uint256 Time;
    }
    mapping(uint256 => WinnerPlayer) private winnerPlayerOfGame;

    //start:  events----
    event TransferRewardToWinnerEvent(
        uint256 amount,
        address winner,
        uint256 date
    );
    event FailedTransferRewardToWinnerEvent(
        uint256 amount,
        address winner,
        uint256 date
    );

    //End:  events----
    

    // Start chainlink
    bytes32 internal keyHash =
        0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256 internal fee = 0.0001 * 10**18;

    constructor()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {
        admin = msg.sender;
        CurrentGameCount = 1;
        canPlayerBuyTicket = true;
    }
    
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "This function only owner can call");
        _;
    }

    modifier onlyWhenGameIsGoingOn() {
        require(
            canPlayerBuyTicket == true,
            "Game will start soon... Please try again."
        );
        _;
    }

    function buyTicket() public payable onlyWhenGameIsGoingOn {
        require(msg.value >= oneTicketPrice, "Please Pay full entry Fee");
        require(
            onlySoldTicketOfGame[CurrentGameCount] < totalTickets,
            "All tickets of this game are sold. Please try in next game"
        );
        _buyTicket_withWithout_refferal();
    }

    function buyTicketUsingReferral(address _referral)
        public
        payable
        onlyWhenGameIsGoingOn
    {
        require(msg.value >= oneTicketPrice, "Please Pay full entry Fee");
        require(
            onlySoldTicketOfGame[CurrentGameCount] < totalTickets,
            "All tickets of this game are sold. Please try in next game"
        );
        // send ticket to who refer this guy
        if (isPlayerAddressAdded(_referral)) {
            totalTicketOfGame[CurrentGameCount] += 1;

            ticketsOfUserInGame[_referral][CurrentGameCount].push(
                UserTicket(totalTicketOfGame[CurrentGameCount], "Refferal")
            );
            inGameOwnerOfTicket[CurrentGameCount][
                totalTicketOfGame[CurrentGameCount]
            ] = _referral;
        }
        _buyTicket_withWithout_refferal();
    }

    function _buyTicket_withWithout_refferal() private {
        if (!isPlayerAddressAdded(msg.sender)) {
            playersOfGame[CurrentGameCount].push(msg.sender);
        }

        if (onlySoldTicketOfGame[CurrentGameCount] == 1) {
            getRandomNumberChainlink();
        }

        onlySoldTicketOfGame[CurrentGameCount] += 1;
        totalTicketOfGame[CurrentGameCount] += 1;

        ticketsOfUserInGame[msg.sender][CurrentGameCount].push(
            UserTicket(totalTicketOfGame[CurrentGameCount], "Buy")
        );
        inGameOwnerOfTicket[CurrentGameCount][
            totalTicketOfGame[CurrentGameCount]
        ] = msg.sender;

        if (onlySoldTicketOfGame[CurrentGameCount] == totalTickets) {
            // stop game, find winner, transfer money and start game again
            canPlayerBuyTicket = false;
            _findRandomVariablesAndWinners();
        }
    }

    function getRandomNumberChainlink() private returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness)
        internal
        override
    {
        private_random_variable_forgame[CurrentGameCount] = randomness;
    }

    function _findRandomVariablesAndWinners() private {
        uint256 _firstRandomVariable = private_random_variable_forgame[
            CurrentGameCount
        ];

        uint256 _firstWinnerTicket = (_firstRandomVariable %
            totalTicketOfGame[CurrentGameCount]) + 1;
        address _firstWinner = inGameOwnerOfTicket[CurrentGameCount][
            _firstWinnerTicket
        ];

        //selecting secound winner
        bool runLoop = true;
        uint256 _secoundRandomVariable;
        uint256 _secoundWinnerTicket;
        address _secoundWinner;
        if (all_players_are_not_same()) {
            for (uint256 i = 1; runLoop; i++) {
                _secoundRandomVariable = _firstRandomVariable / 2 + i;
                _secoundWinnerTicket =
                    (_secoundRandomVariable %
                        totalTicketOfGame[CurrentGameCount]) +
                    1;
                _secoundWinner = inGameOwnerOfTicket[CurrentGameCount][
                    _secoundWinnerTicket
                ];
                if (_firstWinner != _secoundWinner) {
                    runLoop = false;
                }
            }
        } else {
            _secoundRandomVariable = _firstRandomVariable / 2;
            _secoundWinnerTicket =
                (_secoundRandomVariable % totalTicketOfGame[CurrentGameCount]) +
                1;
            _secoundWinner = inGameOwnerOfTicket[CurrentGameCount][
                _secoundWinnerTicket
            ];
        }

        winnerPlayerOfGame[CurrentGameCount] = WinnerPlayer(
            _firstWinner,
            _secoundWinner,
            _firstWinnerTicket,
            _secoundWinnerTicket,
            block.timestamp
        );

        // sendMoneyToWinners();
        if (_firstWinner != address(0)) {
            (bool sent, ) = payable(_firstWinner).call{value: oneWinnerReward}(
                ""
            );

            if (sent) {
                emit TransferRewardToWinnerEvent(
                    oneWinnerReward,
                    _firstWinner,
                    block.timestamp
                );
            } else {
                emit FailedTransferRewardToWinnerEvent(
                    oneWinnerReward,
                    _firstWinner,
                    block.timestamp
                );
            }
        }
        if (_secoundWinner != address(0)) {
            (bool sent2, ) = payable(_secoundWinner).call{
                value: oneWinnerReward
            }("");
            if (sent2) {
                emit TransferRewardToWinnerEvent(
                    oneWinnerReward,
                    _secoundWinner,
                    block.timestamp
                );
            } else {
                emit FailedTransferRewardToWinnerEvent(
                    oneWinnerReward,
                    _secoundWinner,
                    block.timestamp
                );
            }
        }

        // start new game
        canPlayerBuyTicket = true;
        CurrentGameCount += 1;
    }

    // Start: Helping functions
    function isPlayerAddressAdded(address _player) private view returns (bool) {
        for (uint256 i = 0; i < playersOfGame[CurrentGameCount].length; i++) {
            if (playersOfGame[CurrentGameCount][i] == _player) {
                return true;
            }
        }
        return false;
    }

    function all_players_are_not_same() private view returns (bool) {
        if (1 < playersOfGame[CurrentGameCount].length) {
            address _oneAddress = playersOfGame[CurrentGameCount][0];
            for (
                uint256 i = 1;
                i < playersOfGame[CurrentGameCount].length;
                i++
            ) {
                if (playersOfGame[CurrentGameCount][i] != _oneAddress) {
                    return true;
                }
            }
        }
        return false;
    }

    // End: Helping functions

    // *********Start: Admin Functions

    function isAdmin() public view returns (bool) {
        if (msg.sender == admin) {
            return true;
        } else {
            return false;
        }
    }

    function knowAdminBalance() public view onlyAdmin returns (uint256) {
        return address(this).balance;
    }

    function withdrawAdminBalance(address payable _owner, uint256 _amount)
        public
        onlyAdmin
        returns (bool)
    {
        (bool sent, ) = _owner.call{value: _amount}("");

        return sent;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function knowAdminBalanceOfToken(IERC20 _tokenAddress)
        public
        view
        onlyAdmin
        returns (uint256)
    {
        return _tokenAddress.balanceOf(address(this));
    }

    function withdrawAdminBalanceOfToken(
        IERC20 _tokenAddress,
        address payable _owner
    ) public onlyAdmin {
        _tokenAddress.transfer(_owner, knowAdminBalanceOfToken(_tokenAddress));
    }

    // *********End: Admin Functions

    // Functions for get data

    // --start: Configration for game

    function getTotalTickets() public view returns (uint256) {
        return totalTickets;
    }

    function getOneTicketPrice() public view returns (uint256) {
        return oneTicketPrice;
    }

    function getOneWinnerReward() public view returns (uint256) {
        return oneWinnerReward;
    }

    function getTotalWinnerCount() public view returns (uint256) {
        return totalWinnerCount;
    }

    // --End: Configration for game

    //

    function getCurrentGameCount() public view returns (uint256) {
        return CurrentGameCount;
    }

    function getCanPlayerBuyTicket() public view returns (bool) {
        return canPlayerBuyTicket;
    }

    function getOnlySoldTicketOfGame(uint256 _gamecount)
        public
        view
        returns (uint256)
    {
        return onlySoldTicketOfGame[_gamecount];
    }

    function getTotalTicketOfGame(uint256 _gamecount)
        public
        view
        returns (uint256)
    {
        return totalTicketOfGame[_gamecount];
    }

    function getAllTicketsOfUserInGame(address _user, uint256 _gamecount)
        public
        view
        returns (UserTicket[] memory)
    {
        return ticketsOfUserInGame[_user][_gamecount];
    }

    function getInGameOwnerOfTicket(uint256 _gamecount, uint256 _ticket)
        public
        view
        returns (address)
    {
        return inGameOwnerOfTicket[_gamecount][_ticket];
    }

    function getWinnerPlayerOfGame(uint256 _gamecount)
        public
        view
        returns (WinnerPlayer memory)
    {
        return winnerPlayerOfGame[_gamecount];
    }
    
}