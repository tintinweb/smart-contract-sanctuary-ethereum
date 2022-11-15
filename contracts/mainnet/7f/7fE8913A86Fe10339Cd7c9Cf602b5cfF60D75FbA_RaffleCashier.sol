// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IPair.sol";
import "./IERC20.sol";
import "./IRouter.sol";
import "./IFactory.sol";
import "./TransferHelper.sol";
import "./AggregatorV3Interface.sol";

contract Owned {
    address public owner;

    event LogActualOwner(address sender, address oldOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner)
        external
        onlyOwner
        returns (bool success)
    {
        require(
            newOwner != address(0x0),
            "You are not the owner of the contract."
        );
        owner = newOwner;
        emit LogActualOwner(msg.sender, owner, newOwner);
        return true;
    }
}

contract RaffleCashier is Owned {
    IRouter public router;
    address public usdToken;
    address[] private adminUsers;
    address public immutable WETH;
    address public immutable FMON;
    address public treasuryAddress;
    address public megaVaultAddress;
    address public xPresidentsVaultAddress;
    uint256 public extraAmountToSend;
    uint16 private constant MAX_ADMINS = 10;
    mapping(address => bool) private _isBot;
    uint256 public feesAcumulatedForTreasuryInFMON;
    uint256 public feesAcumulatedForMegaVaultInFMON;
    uint256 public feesAcumulatedForXpresidentsVaultInFMON;
    mapping(address => bool) public isAdminUser;
    uint256 public prizePercentageToWinner = 800; // --> ((Raffle total prize) - (Operator fees))
    AggregatorV3Interface internal priceFeed;

    struct PlayersToReturnMoney {
        address player;
        address tokenUsedToPay;
        uint256 tokenAmountPayed;
    }

    struct OperatorFees {
        uint256 megaVault;
        uint256 treasury;
        uint256 xPresidentsVault;
    }

    struct RaffleOperator {
        bool isRunning;
        address raffleWinner;
        uint256 prizeAmountInUSD;
        bool isRaffleOperator;
        uint256 minNumberOfPlayers;
        uint256 currentNumOfRegisteredPlayers;
        mapping(uint256 => PlayersToReturnMoney) playersToReturnMoney;
    }

    mapping(address => RaffleOperator) public raffleOperator;
    // OperatorFees public operatorFees = OperatorFees (170, 15, 15);
    OperatorFees public operatorFees = OperatorFees(850, 75, 75);

    error TooManyAdminUsers();
    error OwnerCantBeRemoved();
    error AdminUsersCantBeEmpty();
    error AdminUserAlreadyAdded();
    error UserToRemoveIsNotAdmin();

    event FeesChanged();
    event AdminUserAdded(address indexed _adminUserAddress);
    event AdminUserRemoved(address indexed _adminUserAddress);
    event RaffleWinnerSetted(
        address indexed _raffleOperator,
        address indexed _winnerAddress
    );

    modifier onlyIfAdminUser() {
        require(isAdminUser[msg.sender] == true, "You are not authorized");
        _;
    }

    modifier onlyIfRunning(address _raffleOperator) {
        require(
            raffleOperator[_raffleOperator].isRunning == true,
            "Unauthorized"
        );
        _;
    }

    modifier onlyIfIsRaffleOperator(address _raffleOperator) {
        require(
            raffleOperator[_raffleOperator].isRaffleOperator == true &&
                raffleOperator[_raffleOperator].isRunning == false,
            "Unauthorized"
        );
        _;
    }

    constructor(
        address _routerAddress,
        address _treasuryAddress,
        address _megaVaultAddress,
        address _xPresidentsVaultAddress,
        address _WETH,
        address _FMON,
        address _usdToken
    ) {
        owner = msg.sender;
        adminUsers.push(msg.sender);
        isAdminUser[msg.sender] = true;

        IRouter _router = IRouter(_routerAddress);
        router = _router;
        treasuryAddress = _treasuryAddress;
        megaVaultAddress = _megaVaultAddress;
        xPresidentsVaultAddress = _xPresidentsVaultAddress;
        WETH = _WETH;
        FMON = _FMON;
        usdToken = _usdToken;
        // priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); // --> Goerli
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function isBot(address account) public view returns (bool _isABot) {
        return _isBot[account];
    }

    function getCurrentAdminUsers()
        external
        view
        onlyIfAdminUser
        returns (address[] memory _currentAdminUsers)
    {
        return adminUsers;
    }

    function getIfUserIsAdmin(address userToCheck)
        external
        view
        returns (bool _userIsAdmin)
    {
        return isAdminUser[userToCheck];
    }

    function getCurrentPriceOfTokenByETHInUSDC(address _tokenA)
        public
        view
        returns (uint256 _currentPriceOfTokenWithoutDecimalsInUSD)
    {
        // tokenA always the token which we want to know the price
        address _pair = IFactory(router.factory()).getPair(_tokenA, WETH);
        uint256 decimalsUSDC = IERC20(usdToken).decimals();
        uint256 decimalsToken0 = IERC20(IPair(_pair).token0()).decimals();
        uint256 decimalsToken1 = IERC20(IPair(_pair).token1()).decimals();
        (uint256 reserve0, uint256 reserve1, ) = IPair(_pair).getReserves();

        uint256 currentToken0PriceWithoutDecimals = (1 *
            10**decimalsToken0 *
            reserve1) / reserve0; // --> For 1 FMON is this ETH
        uint256 currentToken1PriceWithoutDecimals = (1 *
            10**decimalsToken1 *
            reserve0) / reserve1; // --> For 1 ETH is this FMON

        uint256 currentETHPrice = uint256(getETHLatestPrice());
        uint8 ETHPriceDecimals = getETHPriceDecimals();
        uint256 currentPriceETHInUSD = currentETHPrice / 10**ETHPriceDecimals;
        uint256 currentPriceETHInUSDWithoutDecimals = 1 *
            10**decimalsUSDC *
            currentPriceETHInUSD;

        // If token0 is ETH, token1 is FMON
        if (_tokenA == IPair(_pair).token0()) {
            _currentPriceOfTokenWithoutDecimalsInUSD =
                ((1 * 10**decimalsToken0) *
                    currentPriceETHInUSDWithoutDecimals) /
                currentToken1PriceWithoutDecimals;
        } else if (_tokenA == IPair(_pair).token1()) {
            _currentPriceOfTokenWithoutDecimalsInUSD =
                ((1 * 10**decimalsToken1) *
                    currentPriceETHInUSDWithoutDecimals) /
                currentToken0PriceWithoutDecimals;
        }
    }

    function getETHLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getETHPriceDecimals() public view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }

    function addAdminUser(address adminUserToAdd) external onlyOwner {
        // Already maxed, cannot add any more admin users.
        if (adminUsers.length == MAX_ADMINS) revert TooManyAdminUsers();
        if (isAdminUser[adminUserToAdd] == true) revert AdminUserAlreadyAdded();

        adminUsers.push(adminUserToAdd);
        isAdminUser[adminUserToAdd] = true;

        emit AdminUserAdded(adminUserToAdd);
    }

    function removeAdminUser(address adminUserToRemove)
        external
        onlyIfAdminUser
    {
        if (adminUsers.length == 1) revert AdminUsersCantBeEmpty();
        if (adminUserToRemove == owner) revert OwnerCantBeRemoved();
        if (!isAdminUser[adminUserToRemove]) revert UserToRemoveIsNotAdmin();

        uint256 lastAdminUserIndex = adminUsers.length - 1;
        for (uint256 i = 0; i < adminUsers.length; i++) {
            if (adminUsers[i] == adminUserToRemove) {
                address last = adminUsers[lastAdminUserIndex];
                adminUsers[i] = last;
                adminUsers.pop();
                break;
            }
        }

        isAdminUser[adminUserToRemove] = false;
        emit AdminUserRemoved(adminUserToRemove);
    }

    function addLiquidity(
        address _tokenToAddLiquidity,
        address _liquidityProvider,
        uint256 _liquidityToAdd
    ) external onlyOwner returns (bool _success) {
        TransferHelper.safeTransferFrom(
            _tokenToAddLiquidity,
            _liquidityProvider,
            address(this),
            _liquidityToAdd
        );
        return true;
    }

    function removeLiquidity(
        address _tokenToRemoveLiquidity,
        uint256 _liquidityToRemove,
        address _liquidityReceiver
    ) external onlyOwner returns (bool _removeLiquiditySuccess) {
        TransferHelper.safeTransfer(
            _tokenToRemoveLiquidity,
            _liquidityReceiver,
            _liquidityToRemove
        );
        return true;
    }

    function setAntibot(address account, bool state) external onlyIfAdminUser {
        require(_isBot[account] != state, "Value already set");
        _isBot[account] = state;
    }

    function updateMegaVaultWallet(address newWallet) external onlyIfAdminUser {
        require(megaVaultAddress != newWallet, "Wallet already set");
        megaVaultAddress = newWallet;
    }

    function updateXPresidentsVaultWallet(address newWallet)
        external
        onlyIfAdminUser
    {
        require(xPresidentsVaultAddress != newWallet, "Wallet already set");
        xPresidentsVaultAddress = newWallet;
    }

    function updateTreasuryWallet(address newWallet) external onlyIfAdminUser {
        require(treasuryAddress != newWallet, "Wallet already set");
        treasuryAddress = newWallet;
    }

    function setOperatorPercentages(
        uint256 _prizePercentageToWinner,
        uint256 _megaVault,
        uint256 _treasury,
        uint256 _xPresidentsVault
    ) external onlyIfAdminUser {
        require(
            _prizePercentageToWinner +
                _megaVault +
                _treasury +
                _xPresidentsVault ==
                1000,
            "Bad Request"
        );

        prizePercentageToWinner = _prizePercentageToWinner;
        operatorFees.megaVault = _megaVault;
        operatorFees.treasury = _treasury;
        operatorFees.xPresidentsVault = _xPresidentsVault;

        emit FeesChanged();
    }

    function setNewRaffleOperator(
        address _raffleOperator,
        uint256 _prizeAmountInUSD,
        uint256 _minNumberOfPlayers
    ) external onlyOwner returns (bool _success) {
        raffleOperator[_raffleOperator].isRunning = true;
        raffleOperator[_raffleOperator].isRaffleOperator = true;
        raffleOperator[_raffleOperator].currentNumOfRegisteredPlayers = 0;
        raffleOperator[_raffleOperator].prizeAmountInUSD = _prizeAmountInUSD;
        raffleOperator[_raffleOperator]
            .minNumberOfPlayers = _minNumberOfPlayers;
        return true;
    }

    function buyTicketsToPlay(
        uint256 _amountToBuyTickets,
        address _tokenToUseToBuyTickets
    ) public payable returns (bool _success) {
        TransferHelper.safeTransferFrom(
            _tokenToUseToBuyTickets,
            msg.sender,
            address(this),
            _amountToBuyTickets
        );
        return true;
    }

    function setPlayersToReturnMoney(
        address _raffleOperator,
        address _player,
        address _tokenUsedToPay,
        uint256 _tokenAmountPayed
    )
        public
        onlyIfAdminUser
        onlyIfIsRaffleOperator(_raffleOperator)
        returns (bool _success)
    {
        uint256 currentNumOfRegisteredPlayers = raffleOperator[_raffleOperator]
            .currentNumOfRegisteredPlayers;
        require(
            currentNumOfRegisteredPlayers <
                raffleOperator[_raffleOperator].minNumberOfPlayers,
            "Bad Request"
        );

        raffleOperator[_raffleOperator].currentNumOfRegisteredPlayers++;
        raffleOperator[_raffleOperator]
            .playersToReturnMoney[currentNumOfRegisteredPlayers]
            .player = _player;
        raffleOperator[_raffleOperator]
            .playersToReturnMoney[currentNumOfRegisteredPlayers]
            .tokenUsedToPay = _tokenUsedToPay;
        raffleOperator[_raffleOperator]
            .playersToReturnMoney[currentNumOfRegisteredPlayers]
            .tokenAmountPayed = _tokenAmountPayed;
        return true;
    }

    function setRaffleOperatorWinner(
        address _raffleOperator,
        address _raffleWinnerPlayer
    ) external onlyIfAdminUser returns (bool _success) {
        raffleOperator[_raffleOperator].raffleWinner = _raffleWinnerPlayer;
        raffleOperator[_raffleOperator].isRunning = false;

        emit RaffleWinnerSetted(_raffleOperator, _raffleWinnerPlayer);
        return true;
    }

    function distributeRaffleOperatorPrize(
        address _raffleOperator,
        address _raffleWinnerPlayer,
        uint256 _operatorPrizeToDistributeInUSD // with decimals, USD
    )
        public
        onlyIfAdminUser
        onlyIfIsRaffleOperator(_raffleOperator)
        returns (bool _transferSuccess)
    {
        require(
            _raffleWinnerPlayer == raffleOperator[_raffleOperator].raffleWinner,
            "Unauthorized"
        );
        require(
            _operatorPrizeToDistributeInUSD <=
                raffleOperator[_raffleOperator].prizeAmountInUSD,
            "Bad Request"
        );

        uint256 currentPriceOfFMONByETHInUSDC = getCurrentPriceOfTokenByETHInUSDC(
                FMON
            );
        uint256 decimalsFMON = IERC20(FMON).decimals();
        uint256 decimalsUSDC = IERC20(usdToken).decimals();
        uint256 currentFMONBalanceOfCashier = IERC20(FMON).balanceOf(
            address(this)
        );

        uint256 operatorPriceToDistributeInFMON = ((_operatorPrizeToDistributeInUSD *
                1 *
                10**decimalsUSDC) * (1 * 10**decimalsFMON)) /
                currentPriceOfFMONByETHInUSDC;
        uint256 prizeToDeliverToWinnerInFMON = (operatorPriceToDistributeInFMON *
                prizePercentageToWinner) / 1000;
        uint256 prizeToDeliverToOperatorInFMON = operatorPriceToDistributeInFMON -
                prizeToDeliverToWinnerInFMON;

        if (currentFMONBalanceOfCashier < prizeToDeliverToWinnerInFMON) {
            TransferHelper.safeTransfer(
                FMON,
                _raffleWinnerPlayer,
                currentFMONBalanceOfCashier
            );

            extraAmountToSend =
                prizeToDeliverToWinnerInFMON -
                currentFMONBalanceOfCashier;
            TransferHelper.safeTransferFrom(
                FMON,
                treasuryAddress,
                _raffleWinnerPlayer,
                extraAmountToSend
            );
        } else {
            TransferHelper.safeTransfer(
                FMON,
                _raffleWinnerPlayer,
                prizeToDeliverToWinnerInFMON
            );
        }

        currentFMONBalanceOfCashier = IERC20(FMON).balanceOf(address(this)); // Updated balance

        if (currentFMONBalanceOfCashier < prizeToDeliverToOperatorInFMON) {
            sendFeesToOperator(currentFMONBalanceOfCashier);
        } else {
            sendFeesToOperator(prizeToDeliverToOperatorInFMON);
        }

        return true;
    }

    function sendFeesToOperator(uint256 _prizeToDeliverToOperatorInFMON)
        internal
        returns (bool _success)
    {
        uint256 prizeToDeliverToTreasuryInFMON = (_prizeToDeliverToOperatorInFMON *
                operatorFees.treasury) / 1000;
        feesAcumulatedForTreasuryInFMON += prizeToDeliverToTreasuryInFMON;

        uint256 prizeToDeliverToMegaVaultInFMON = (_prizeToDeliverToOperatorInFMON *
                operatorFees.megaVault) / 1000;
        feesAcumulatedForMegaVaultInFMON += prizeToDeliverToMegaVaultInFMON;

        uint256 prizeToDeliverToXPresidentsVaultInFMON = (_prizeToDeliverToOperatorInFMON *
                operatorFees.xPresidentsVault) / 1000;
        feesAcumulatedForXpresidentsVaultInFMON += prizeToDeliverToXPresidentsVaultInFMON;

        return true;
    }

    function cancelRaffleOperator(address _raffleOperator)
        public
        onlyOwner
        onlyIfRunning(_raffleOperator)
        returns (bool _success)
    {
        uint256 currentNumOfRegisteredPlayers = raffleOperator[_raffleOperator]
            .currentNumOfRegisteredPlayers;
        require(
            currentNumOfRegisteredPlayers <
                raffleOperator[_raffleOperator].minNumberOfPlayers,
            "Bad Request"
        );

        if (currentNumOfRegisteredPlayers > 0) {
            returnMoneyToOwners(_raffleOperator);
        }

        raffleOperator[_raffleOperator].isRunning = false;
        return true;
    }

    function returnMoneyToOwners(address _raffleOperator)
        internal
        onlyOwner
        onlyIfRunning(_raffleOperator)
        returns (bool _success)
    {
        for (
            uint256 i = 0;
            i < raffleOperator[_raffleOperator].currentNumOfRegisteredPlayers;
            ++i
        ) {
            TransferHelper.safeTransfer(
                raffleOperator[_raffleOperator]
                    .playersToReturnMoney[i]
                    .tokenUsedToPay,
                raffleOperator[_raffleOperator].playersToReturnMoney[i].player,
                raffleOperator[_raffleOperator]
                    .playersToReturnMoney[i]
                    .tokenAmountPayed
            );
        }

        raffleOperator[_raffleOperator].isRunning = false;
        return true;
    }

    function distributeFeesToTreasury()
        public
        onlyOwner
        returns (bool _success)
    {
        TransferHelper.safeTransfer(
            FMON,
            treasuryAddress,
            feesAcumulatedForTreasuryInFMON
        );
        feesAcumulatedForTreasuryInFMON = 0;
        return true;
    }

    function distributeFeesToMegaVault()
        public
        onlyOwner
        returns (bool _success)
    {
        TransferHelper.safeTransfer(
            FMON,
            megaVaultAddress,
            feesAcumulatedForMegaVaultInFMON
        );
        feesAcumulatedForMegaVaultInFMON = 0;
        return true;
    }

    function distributeFeesToXPresidentsVault()
        public
        onlyOwner
        returns (bool _success)
    {
        TransferHelper.safeTransfer(
            FMON,
            xPresidentsVaultAddress,
            feesAcumulatedForXpresidentsVaultInFMON
        );
        feesAcumulatedForXpresidentsVaultInFMON = 0;
        return true;
    }
}