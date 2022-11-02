// SPDX-License-Identifier: MIT
pragma solidity =0.8;

import "./Owned.sol";
import "./RaffleCashier.sol";
import "./RaffleOperator.sol";
import "./RaffleWinnerNumberGenerator.sol";

contract RaffleManager is Owned {
    address[] private adminUsers;
    address public raffleCashier;
    address public treasuryAddress;
    address public megaVaultAddress;
    address[] public rafflesAddresses;
    uint256 public currentRaffleId = 0;
    address public xPresidentsVaultAddress;
    uint16 private constant MAX_ADMINS = 10;
    address public raffleWinnerNumberGenerator;
    mapping(address => bool) public isAdminUser;
    uint256 private constant RAFFLE_IN_PROGRESS = 3200000;

    error TooManyAdminUsers();
    error OwnerCantBeRemoved();
    error AdminUsersCantBeEmpty();
    error AdminUserAlreadyAdded();
    error UserToRemoveIsNotAdmin();

    event AdminUserAdded(address indexed adminUserAddress);
    event AdminUserRemoved(address indexed adminUserAddress);
    event RaffleFinished(address indexed raffleOperatorContract);
    event RaffleRestarted(address indexed raffleOperatorContract);
    event RaffleCashierCreated(
        address indexed raffleCashierContract,
        bytes32 indexed raffleCashierSalt
    );
    event RaffleCreated(
        address indexed raffleOperatorContract,
        bytes32 indexed raffleSalt,
        uint256 currentRafflesLength
    );
    event RaffleWinnerNumberGeneratorCreated(
        address indexed raffleWinnerNumberGeneratorContract,
        bytes32 indexed raffleWinnerNumberGeneratorSalt
    );

    modifier onlyIfAdminUser() {
        require(isAdminUser[msg.sender] == true, "You are not authorized");
        _;
    }

    constructor(
        uint64 _subscriptionId,
        address _routerAddress,
        address _treasuryAddress,
        address _megaVaultAddress,
        address _xPresidentsVaultAddress,
        address _WETH,
        address _FMON
    ) {
        owner = msg.sender;
        adminUsers.push(msg.sender);
        isAdminUser[msg.sender] = true;
        treasuryAddress = _treasuryAddress;
        megaVaultAddress = _megaVaultAddress;
        xPresidentsVaultAddress = _xPresidentsVaultAddress;

        raffleCashier = createRaffleCashier(_routerAddress, _WETH, _FMON);
        raffleWinnerNumberGenerator = createRaffleWinnerNumberGenerator(
            address(this),
            _subscriptionId
        );
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

    function allRafflesLength()
        external
        view
        returns (uint256 _rafflesAddressesQuantity)
    {
        return rafflesAddresses.length;
    }

    function updateMegaVaultWallet(address newWallet) external onlyOwner {
        require(megaVaultAddress != newWallet, "Wallet already set");
        megaVaultAddress = newWallet;
    }

    function updateXPresidentsVaultWallet(address newWallet)
        external
        onlyOwner
    {
        require(xPresidentsVaultAddress != newWallet, "Wallet already set");
        xPresidentsVaultAddress = newWallet;
    }

    function updateTreasuryWallet(address newWallet) external onlyOwner {
        require(treasuryAddress != newWallet, "Wallet already set");
        treasuryAddress = newWallet;
    }

    function approveRouterToSwapToken(address _tokenToApprove)
        external
        onlyIfAdminUser
        returns (bool _approvalSuccess)
    {
        RaffleCashier(raffleCashier).approveRouterToSwapToken(_tokenToApprove);
        return true;
    }

    function addUSDCLiquidity(address _USDC, uint256 _liquidityToAdd)
        external
        onlyOwner
        returns (bool _removeLiquiditySuccess)
    {
        require(_USDC != address(0), "FmoneyRaffleV1: ZERO_USDC_ADDRESS");
        require(
            _liquidityToAdd > 0,
            "Please set the quantity of liquidity that you want to add"
        );
        RaffleCashier(raffleCashier).addUSDCLiquidity(
            _USDC,
            msg.sender,
            _liquidityToAdd
        );
        return true;
    }

    function removeUSDCLiquidity(address _USDC, uint256 _liquidityToRemove)
        external
        onlyOwner
        returns (bool _removeLiquiditySuccess)
    {
        RaffleCashier(raffleCashier).removeUSDCLiquidity(
            _USDC,
            _liquidityToRemove,
            msg.sender
        );
        return true;
    }

    function changeRouterToBuyTickets(address _newRouterAddress)
        external
        onlyOwner
        returns (bool _success)
    {
        RaffleCashier(raffleCashier).changeRouterToMakeSwap(_newRouterAddress);
        return true;
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

    function createRaffleCashier(
        address _routerAddress,
        address _WETH,
        address _FMON
    ) internal returns (address _raffleCashier) {
        bytes32 salt = keccak256(abi.encodePacked(_routerAddress));

        RaffleCashier _raffleCashierContract = new RaffleCashier{salt: salt}(
            _routerAddress,
            _WETH,
            _FMON
        );

        emit RaffleCashierCreated(address(_raffleCashierContract), salt);
        return address(_raffleCashierContract);
    }

    function createRaffleWinnerNumberGenerator(
        address _raffleManagerAddress,
        uint64 _subscriptionId
    ) internal returns (address _raffleWinnerNumberGenerator) {
        bytes32 salt = keccak256(
            abi.encodePacked(_raffleManagerAddress, _subscriptionId)
        );

        RaffleWinnerNumberGenerator _raffleWinnerNumberGeneratorContract = new RaffleWinnerNumberGenerator{
                salt: salt
            }(_raffleManagerAddress, _subscriptionId);

        emit RaffleWinnerNumberGeneratorCreated(
            address(_raffleWinnerNumberGeneratorContract),
            salt
        );
        return address(_raffleWinnerNumberGeneratorContract);
    }

    function createRaffle(
        address _USDC,
        uint256 _dateOfDraw,
        string memory _raffleName,
        uint16 _minNumberOfPlayers,
        uint16 _maxNumberOfPlayers,
        string memory _raffleSymbol,
        uint16 _percentageOfPrizeToOperator,
        uint256 _priceOfTheRaffleTicketInUSDC
    ) external onlyIfAdminUser returns (address _raffleOperatorAddress) {
        require(_USDC != address(0), "FmoneyRaffleV1: ZERO_USDC_ADDRESS");

        bytes32 salt = keccak256(
            abi.encodePacked(
                _USDC,
                _dateOfDraw,
                _raffleName,
                _minNumberOfPlayers,
                _maxNumberOfPlayers,
                _raffleSymbol,
                _percentageOfPrizeToOperator,
                _priceOfTheRaffleTicketInUSDC,
                raffleWinnerNumberGenerator,
                raffleCashier
            )
        );

        RaffleOperator _raffleOperatorContract = new RaffleOperator{salt: salt}(
            _USDC,
            _dateOfDraw,
            owner,
            _raffleName,
            _minNumberOfPlayers,
            _maxNumberOfPlayers,
            _raffleSymbol,
            _percentageOfPrizeToOperator,
            _priceOfTheRaffleTicketInUSDC,
            raffleWinnerNumberGenerator,
            raffleCashier
        );

        rafflesAddresses.push(address(_raffleOperatorContract));
        currentRaffleId++;

        emit RaffleCreated(
            address(_raffleOperatorContract),
            salt,
            rafflesAddresses.length
        );
        return address(_raffleOperatorContract);
    }

    function drawRaffle(address _raffleOperatorContract)
        external
        onlyIfAdminUser
        returns (bool _raffleIsInProgress)
    {
        uint256 _dateOfDraw = RaffleOperator(_raffleOperatorContract)
            .dateOfDraw();
        uint32 _maxNumberOfPlayers = RaffleOperator(_raffleOperatorContract)
            .maxNumberOfPlayers();
        uint32 _minNumberOfPlayers = RaffleOperator(_raffleOperatorContract)
            .minNumberOfPlayers();
        address payable[] memory _ticketBuyers = RaffleOperator(
            _raffleOperatorContract
        ).getRaffleTicketBuyers();

        if (_ticketBuyers.length < _maxNumberOfPlayers) {
            require(block.timestamp >= _dateOfDraw, "The draw is not yet.");
        }

        if (_ticketBuyers.length == 0) {
            RaffleOperator(_raffleOperatorContract).runSwitch(false); // We close the raffle because there is no players
            return true;
        }

        if (_ticketBuyers.length < _minNumberOfPlayers) {
            RaffleOperator(_raffleOperatorContract).returnMoneyToOwners(); // We close the raffle because there is less players
            return true;
        }

        RaffleWinnerNumberGenerator(raffleWinnerNumberGenerator).launchRaffle(
            _raffleOperatorContract
        );
        return true;
    }

    function getRaffleWinner(address _raffleOperatorContract)
        external
        onlyOwner
        returns (uint256 _raffleWinnerNumber)
    {
        _raffleWinnerNumber = RaffleWinnerNumberGenerator(
            raffleWinnerNumberGenerator
        ).getRaffleWinnerNumber(_raffleOperatorContract);
        require(
            _raffleWinnerNumber != RAFFLE_IN_PROGRESS,
            "Raffle in progress."
        );
        RaffleOperator(_raffleOperatorContract).setRaffleWinner(
            _raffleWinnerNumber
        );
    }
}