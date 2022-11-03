// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./Finalizable.sol";
import "./RaffleManager.sol";
import "./RaffleCashier.sol";
import "./ERC721URIStorage.sol";
import "./RaffleWinnerNumberGenerator.sol";

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

contract RaffleOperator is Finalizable, ERC721URIStorage {
    uint256 public dateOfDraw;
    bool public prizeClaimed;
    uint256 public drawLaunchedAt;
    address public immutable USDC;
    address public raffleMegaVault;
    uint256 public raffleTotalPrize;
    address public raffleWinnerPlayer; // The address of the owner of the NFT token that claim the prize
    uint16 public minNumberOfPlayers;
    uint16 public maxNumberOfPlayers;
    uint256[] public currentSpotsBought;
    address payable[] public ticketBuyers; // The player that buy the ticket to enter, can be different to the winner because can sell the ticket to other person
    address public xPresidentsVaultAddress;
    uint256 public raffleWinnerPositionNumber;
    uint16 public percentageOfPrizeToOperator;
    uint256 public priceOfTheRaffleTicketInUSDC;
    uint256 public raffleCostsDeliveredToOperator;
    mapping(address => bool) public isTicketBuyer;
    uint256 public rafflePotPrizeDeliveredToWinner;

    RaffleCashier raffleCashierInstance;
    RaffleManager raffleManagerInstance;
    RaffleWinnerNumberGenerator raffleWinnerNumberGeneratorInstance;

    constructor(
        address _USDC,
        uint256 _dateOfDraw,
        address _raffleMegaVault,
        string memory _raffleName,
        uint16 _minNumberOfPlayers,
        uint16 _maxNumberOfPlayers,
        string memory _raffleSymbol,
        uint16 _percentageOfPrizeToOperator,
        uint256 _priceOfTheRaffleTicketInUSDC,
        address _raffleWinnerNumberGeneratorAddress,
        address _raffleCashier
    ) ERC721(_raffleName, _raffleSymbol) {
        USDC = _USDC;
        owner = msg.sender;
        dateOfDraw = _dateOfDraw;
        raffleMegaVault = _raffleMegaVault;
        minNumberOfPlayers = _minNumberOfPlayers;
        maxNumberOfPlayers = _maxNumberOfPlayers;
        raffleManagerInstance = RaffleManager(msg.sender);
        raffleCashierInstance = RaffleCashier(_raffleCashier);
        percentageOfPrizeToOperator = _percentageOfPrizeToOperator;
        priceOfTheRaffleTicketInUSDC = _priceOfTheRaffleTicketInUSDC;
        raffleWinnerNumberGeneratorInstance = RaffleWinnerNumberGenerator(
            _raffleWinnerNumberGeneratorAddress
        );
    }

    function getRaffleTicketPlayerBySpotTicketId(uint256 _raffleSpotToSearch)
        external
        view
        returns (address _rafflePlayerBySpotTicketId)
    {
        return ownerOf(_raffleSpotToSearch);
    }

    function getRaffleTicketBuyers()
        external
        view
        returns (address payable[] memory _raffleBuyers)
    {
        return ticketBuyers;
    }

    function getRaffleTicketOwners()
        external
        view
        returns (
            address[] memory _ticketOwners,
            uint256[] memory _currentRafflePlayerNumbers
        )
    {
        _currentRafflePlayerNumbers = raffleWinnerNumberGeneratorInstance
            .getPlayerNumbers(address(this));
        _ticketOwners = new address[](_currentRafflePlayerNumbers.length);

        for (uint256 i = 0; i < _currentRafflePlayerNumbers.length; ++i) {
            _ticketOwners[i] = ownerOf(_currentRafflePlayerNumbers[i]);
        }
    }

    function getCurrentSpotsBought()
        external
        view
        returns (uint256[] memory _currentSpotsBought)
    {
        return currentSpotsBought;
    }

    function getIfAddressPlay(address _addressToCheck)
        external
        view
        returns (bool _addressPlay)
    {
        return (_balances[_addressToCheck] > 0);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyIfRunning {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyIfRunning {
        safeTransferFrom(from, to, tokenId, "");
    }

    function setDateOfTheLaunch() public returns (bool success) {
        require(
            msg.sender == address(raffleWinnerNumberGeneratorInstance),
            "Unauthorized"
        );
        drawLaunchedAt = block.timestamp;
        return true;
    }

    function buyTicketsToPlay(
        uint256 _amountToBuyTickets,
        uint256[] memory _raffleTicketIds,
        string[] memory _raffleTicketTokenURIs,
        address _tokenToUseToBuyTickets
    ) public payable onlyIfRunning returns (bool success) {
        require(
            dateOfDraw - 600 >= block.timestamp,
            "The buying of the tickets for the raffle is closed."
        ); // 10 minutes
        require(
            ticketBuyers.length < maxNumberOfPlayers,
            "The maximum number of players was reached."
        );
        require(
            _raffleTicketIds.length == _raffleTicketTokenURIs.length,
            "tokenIds and tokenURIs length mismatch"
        );

        if (_tokenToUseToBuyTickets == USDC) {
            require(
                _amountToBuyTickets ==
                    (_raffleTicketIds.length * priceOfTheRaffleTicketInUSDC),
                "The amount to buy ticket is not correct."
            );

            uint256 balanceOfUSDCOfSender = IERC20(USDC).balanceOf(msg.sender);
            require(
                balanceOfUSDCOfSender >=
                    (_raffleTicketIds.length * priceOfTheRaffleTicketInUSDC),
                "You dont have USDC balance to buy tickets."
            );

            raffleCashierInstance.transferAmountToBuyTickets(
                USDC,
                msg.sender,
                address(this),
                _amountToBuyTickets
            );
        } else {
            // All amounts are without decimals
            uint256 decimalsOfToken = IERC20(_tokenToUseToBuyTickets)
                .decimals();
            uint256 balanceOfTokenOfSender = IERC20(_tokenToUseToBuyTickets)
                .balanceOf(msg.sender);

            uint256 currentPriceOfTokenByETHInUSDC = raffleCashierInstance
                .getCurrentPriceOfTokenByETHInUSDC(
                    _tokenToUseToBuyTickets,
                    USDC
                );
            uint256 amountOfTokensRequiredToBuy = ((priceOfTheRaffleTicketInUSDC *
                    (1 * 10**decimalsOfToken)) /
                    currentPriceOfTokenByETHInUSDC) * _raffleTicketIds.length;

            require(
                _amountToBuyTickets >= amountOfTokensRequiredToBuy,
                "The amount to buy ticket is not correct."
            );
            require(
                balanceOfTokenOfSender >= amountOfTokensRequiredToBuy,
                "You dont have token balance to buy tickets."
            );

            raffleCashierInstance.transferAmountOfUSDFromLiquidityToBuyTickets(
                USDC,
                msg.sender,
                address(this),
                _tokenToUseToBuyTickets,
                _amountToBuyTickets,
                _raffleTicketIds.length * priceOfTheRaffleTicketInUSDC
            );
        }

        for (uint256 i = 0; i < _raffleTicketIds.length; ++i) {
            require(
                _raffleTicketIds[i] != 0,
                "All the ticket ids has to be different from 0."
            );
            require(
                _raffleTicketIds[i] <= maxNumberOfPlayers,
                "Tickets cannot be greater than the number of players."
            );

            giveRaffleTicket(
                msg.sender,
                _raffleTicketIds[i],
                _raffleTicketTokenURIs[i]
            );
            raffleWinnerNumberGeneratorInstance.setNewRafflePlayingSpot(
                address(this),
                _raffleTicketIds[i]
            );

            ticketBuyers.push(payable(msg.sender));
            isTicketBuyer[msg.sender] = true;
            currentSpotsBought.push(_raffleTicketIds[i]);
        }

        return true;
    }

    function giveRaffleTicket(
        address buyer,
        uint256 newRaffleTicketId,
        string memory tokenURI
    ) internal returns (uint256) {
        require(!_exists(newRaffleTicketId), "Raffle ticket id already sold.");

        _mint(buyer, newRaffleTicketId);
        _setTokenURI(newRaffleTicketId, tokenURI);

        return newRaffleTicketId;
    }

    function returnMoneyToOwners()
        public
        onlyOwner
        onlyIfRunning
        returns (bool _raffleIsFinished)
    {
        for (uint256 i = 0; i < currentSpotsBought.length; ++i) {
            address spotOwner = ownerOf(currentSpotsBought[i]);
            TransferHelper.safeTransfer(
                USDC,
                spotOwner,
                priceOfTheRaffleTicketInUSDC
            );
        }

        running = false;
        return true;
    }

    function setRaffleWinner(uint256 _raffleWinnerNumber)
        public
        onlyOwner
        onlyIfRunning
        returns (bool _raffleIsFinished)
    {
        raffleWinnerPlayer = ownerOf(_raffleWinnerNumber);
        raffleTotalPrize = IERC20(USDC).balanceOf(address(this));

        sendRaffleCostsToOperator();
        claimRafflePrizePot(raffleWinnerPlayer);

        raffleWinnerPositionNumber = _raffleWinnerNumber;
        running = false;
        return true;
    }

    function sendRaffleCostsToOperator() internal returns (bool _success) {
        raffleCostsDeliveredToOperator = ((raffleTotalPrize *
            percentageOfPrizeToOperator) / 100);
        uint256 raffleCostsDeliveredToMegaVault = (raffleCostsDeliveredToOperator *
                85) / 100;
        uint256 raffleCostsDeliveredToProject = (raffleCostsDeliveredToOperator *
                15) / 100;

        TransferHelper.safeTransfer(
            USDC,
            address(raffleManagerInstance.megaVaultAddress()),
            raffleCostsDeliveredToMegaVault
        );
        TransferHelper.safeTransfer(
            USDC,
            address(raffleManagerInstance.treasuryAddress()),
            raffleCostsDeliveredToProject / 2
        );
        TransferHelper.safeTransfer(
            USDC,
            address(raffleManagerInstance.xPresidentsVaultAddress()),
            raffleCostsDeliveredToProject / 2
        );
        return true;
    }

    function claimRafflePrizePot(address _raffleWinnerPlayer)
        internal
        returns (bool _success)
    {
        require(!prizeClaimed, "The prize was already claimed.");

        uint16 percentageOfThePotToTheWinner = 100 -
            percentageOfPrizeToOperator;
        rafflePotPrizeDeliveredToWinner = ((raffleTotalPrize *
            percentageOfThePotToTheWinner) / 100);

        TransferHelper.safeTransfer(
            USDC,
            address(raffleCashierInstance),
            rafflePotPrizeDeliveredToWinner
        );
        raffleCashierInstance.transferPrizeToWinner(
            address(this),
            USDC,
            _raffleWinnerPlayer,
            rafflePotPrizeDeliveredToWinner
        );

        prizeClaimed = true;
        return true;
    }
}