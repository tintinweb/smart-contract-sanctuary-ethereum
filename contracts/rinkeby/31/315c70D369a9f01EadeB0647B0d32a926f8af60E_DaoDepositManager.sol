// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDealManager.sol";
import "./interfaces/IModuleBase.sol";

/**
 * @title                   PrimeDeals Dao Deposit Manager
 * @notice                  Smart contract to manage the
                            deposits, withdraws and vestings of a DAO
 */
contract DaoDepositManager {
    /// DAO address to which this DaoDepositContract is linked
    address public dao;
    /// Address of the DealManager implementation
    IDealManager public dealManager;
    /// token address => balance
    mapping(address => uint256) public tokenBalances;
    /// token address => deal module address => deal module id => balance
    mapping(address => mapping(address => mapping(uint32 => uint256)))
        public availableDealBalances;
    /// token address => balance
    mapping(address => uint256) public vestedBalances;
    /// deal module address => deal id => deposits array
    mapping(address => mapping(uint256 => Deposit[])) public deposits;
    /// Array of vestings where the index is the vesting ID
    Vesting[] public vestings;
    /// Array of all the token addresses that are vested
    address[] public vestedTokenAddresses;
    /// token address => amount
    mapping(address => uint256) public vestedTokenAmounts;
    /// deal module address => deal id => token counter
    mapping(address => mapping(uint256 => uint256)) public tokensPerDeal;

    struct Deposit {
        /// The depositor of the tokens
        address depositor;
        /// The address of the ERC20 token or ETH (ZERO address), that is deposited
        address token;
        /// Amount of the token being deposited
        uint256 amount;
        /// The amount already used for a Deal
        uint256 used;
        /// Unix timestamp of the deposit
        uint32 depositedAt;
    }

    struct Vesting {
        /// The address of the module to which this vesting is linked
        address dealModule;
        /// The ID for a specific deal, that is stored in the module
        uint32 dealId;
        /// The address of the ERC20 token or ETH (ZERO address)
        address token;
        /// The total amount being vested
        uint256 totalVested;
        /// The total amount of claimed vesting
        uint256 totalClaimed;
        /// The Unix timestamp when the vesting has been initiated
        uint32 startTime;
        /// The duration after which tokens can be claimed starting from the vesting start,
        /// in seconds
        uint32 cliff;
        /// The duration the tokens are vested, in seconds
        uint32 duration;
    }

    /**
     * @notice                  This event is emitted when a deposit is made
     * @param dealModule        The module address of which the dealId is part off
     * @param dealId            A specific deal, that is part of the dealModule, for which a
                                deposit is made
     * @param depositor         The address of the depositor
     * @param depositId         The ID of the deposit action (position in array)
     * @param token             The address of the ERC20 token or ETH (ZERO address)deposited
     * @param amount            The amount that is deposited
     */
    event Deposited(
        address indexed dealModule,
        uint32 indexed dealId,
        address indexed depositor,
        uint32 depositId,
        address token,
        uint256 amount
    );

    /**
     * @notice                  This event is emitted when a withdraw is made
     * @param dealModule        The module address of which the dealId is part off
     * @param dealId            A specific deal, that is part of the dealModule, for which a
                                withdraw is made
     * @param depositor         The address of the depositor of the funds that are withdrawn
     * @param depositId         The ID of the deposit action (position in array)
     * @param token             The address of the ERC20 token or ETH (ZERO address) withdrawn
     * @param amount            The amount that is withdrawn
     */
    event Withdrawn(
        address indexed dealModule,
        uint32 indexed dealId,
        address indexed depositor,
        uint32 depositId,
        address token,
        uint256 amount
    );

    /**
     * @notice                  This event is emitted when a vesting is started
     * @param dealModule        The module address of which the dealId is part off
     * @param dealId            A specific deal, that is part of the dealModule, for which a
                                vesting is started
     * @param vestingStart      The Unix timestamp of when the vesting has been initiated
     * @param vestingCliff      The vesting cliff, after which tokens can be claimed
     * @param vestingDuration   The duration the tokens are vested, in seconds
     * @param token             The address of the ERC20 token or ETH (ZERO address)
     * @param amount            The amount that is being vested
     */
    event VestingStarted(
        address indexed dealModule,
        uint32 indexed dealId,
        uint256 indexed vestingStart,
        uint32 vestingCliff,
        uint32 vestingDuration,
        address token,
        uint256 amount
    );

    /**
     * @notice              This event is emitted when a vesting is claimed
     * @param dealModule    The module address of which the dealId is part off
     * @param dealId        A specific deal, that is part of the dealModule, for which a
                            vesting is claimed
     * @param dao           The address of the DAO, to which the claimed vesting is sent
     * @param token         The address of the ERC20 token or ETH (ZERO address)
     * @param claimed       The amount that is being claimed
     */
    event VestingClaimed(
        address indexed dealModule,
        uint32 indexed dealId,
        address indexed dao,
        address token,
        uint256 claimed
    );

    /**
     * @notice              Initialize the DaoDepositManager
     * @param _dao          The DAO address to which this contract belongs
     */
    function initialize(address _dao) external {
        require(dao == address(0), "DaoDepositManager: Error 001");
        require(
            _dao != address(0) && _dao != address(this),
            "DaoDepositManager: Error 100"
        );
        dao = _dao;
        dealManager = IDealManager(msg.sender);
    }

    /**
     * @notice                      Sets a new address for the DealManager implementation
     * @param _newDaoDepositManager The address of the new DealManager
     */
    function setDealManagerImplementation(address _newDaoDepositManager)
        external
        onlyDealManager
    {
        require(
            _newDaoDepositManager != address(0) &&
                _newDaoDepositManager != address(this),
            "DaoDepositManager: Error 100"
        );
        dealManager = IDealManager(_newDaoDepositManager);
    }

    /**
     * @notice              Transfers the token amount to the DaoDepositManager and stores
                            the parameters in a Deposit structure.
     * @dev                 Note: if ETH is deposited, the token address should be ZERO (0)
     * @param _module       The address of the module for which is being deposited
     * @param _dealId       The dealId to which this deposit is part of
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @param _amount       The amount that is deposited
     */
    function deposit(
        address _module,
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) public payable {
        require(_amount > 0, "DaoDepositManager: Error 101");
        if (_token != address(0)) {
            _transferFrom(_token, msg.sender, address(this), _amount);
        } else {
            require(_amount == msg.value, "DaoDepositManager: 202");
        }

        tokenBalances[_token] += _amount;
        availableDealBalances[_token][_module][_dealId] += _amount;
        verifyBalance(_token);
        deposits[_module][_dealId].push(
            // solhint-disable-next-line not-rely-on-time
            Deposit(msg.sender, _token, _amount, 0, uint32(block.timestamp))
        );

        emit Deposited(
            _module,
            _dealId,
            msg.sender,
            uint32(deposits[_module][_dealId].length - 1),
            _token,
            _amount
        );
    }

    /**
     * @notice              Transfers multiple tokens and amounts to the DaoDepositManager and
                            stores the parameters for each deposit in a Deposit structure.
     * @dev                 Note: if ETH is deposited, the token address should be ZERO (0)
                            Note: when calling this function, it is only possible to have 1 ETH
                            deposit, meaning only 1  of the token addresses can be a ZERO address     
     * @param _module       The address of the module for which is being deposited
     * @param _dealId       The dealId to which the deposits are part of
     * @param _tokens       Array of addresses of the ERC20 tokens or ETH (ZERO address)
     * @param _amounts      Array of amounts that are deposited
     */
    function multipleDeposits(
        address _module,
        uint32 _dealId,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external payable {
        require(
            _tokens.length == _amounts.length,
            "DaoDepositManager: Error 102"
        );
        for (uint256 i; i < _tokens.length; ++i) {
            deposit(_module, _dealId, _tokens[i], _amounts[i]);
        }
    }

    /**
     * @notice              Registers deposits of ERC20 tokens or ETH that have been sent
                            to the contract directly, without envoking the method deposit().
                            The funds will be stored with the DAO address as the depositor address
     * @dev                 Note: if ETH has been sent, the token address for registering
                            should be ZERO (0)
     * @param _module       The address of the module for which is being deposited
     * @param _dealId       The dealId to which this deposit is part of
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     */
    function registerDeposit(
        address _module,
        uint32 _dealId,
        address _token
    ) public {
        uint256 currentBalance = getBalance(_token);
        uint256 total = tokenBalances[_token] + vestedBalances[_token];
        if (currentBalance > total) {
            uint256 amount = currentBalance - total;
            tokenBalances[_token] = currentBalance;
            availableDealBalances[_token][_module][_dealId] += amount;
            deposits[_module][_dealId].push(
                // solhint-disable-next-line not-rely-on-time
                Deposit(dao, _token, amount, 0, uint32(block.timestamp))
            );
            emit Deposited(
                _module,
                _dealId,
                dao,
                uint32(deposits[_module][_dealId].length - 1),
                _token,
                amount
            );
        }
        verifyBalance(_token);
    }

    /**
     * @notice              Registers multiple deposits of ERC20 tokens and/or ETH that have been
                            sent to the contract directly, without envoking the method deposit()
                            or multipleDeposits(). The funds will be stored with the DAO address
                            as the depositor address
     * @dev                 Note: if ETH has been sent, the token address for registering
                            should be ZERO (0)
     * @param _module       The address of the module for which is being deposited
     * @param _dealId       The dealId to which this deposit is part of
     * @param _tokens       An array of ERC20 token address and/or
                            ZERO address, symbolizing an ETH deposit
     */
    function registerDeposits(
        address _module,
        uint32 _dealId,
        address[] calldata _tokens
    ) external {
        for (uint256 i; i < _tokens.length; ++i) {
            registerDeposit(_module, _dealId, _tokens[i]);
        }
    }

    /**
     * @notice              Sends the token and amount, stored in the Deposit associated with the
                            depositId to the depositor
     * @dev                 Note: if the deposit has been registered through the function
                            registerDeposit(), withdrawing can only happen after the periode for
                            funding deal has been expired
     * @param _module       The address of the module to which the dealId is part of
     * @param _dealId       The dealId to for which the deposit has been made, that is being
                            withdrawn
     * @param _depositId    The ID of the deposit action (position in array)
     * @return address      The address of the depositor
     * @return address      The address of the ERC20 token or ETH (ZERO address)
     * @return uint256      The available amount that is withdrawn
     */
    function withdraw(
        address _module,
        uint32 _dealId,
        uint32 _depositId
    )
        external
        returns (
            address,
            address,
            uint256
        )
    {
        require(
            deposits[_module][_dealId].length > _depositId,
            "DaoDepositManager: Error 200"
        );
        Deposit storage d = deposits[_module][_dealId][_depositId];

        // Either the caller did the deposit or it's a dao deposit
        // and the caller facilitates the withdraw for the dao
        // (which is only possible after the deal expired)
        require(
            d.depositor == msg.sender ||
                (d.depositor == dao &&
                    IModuleBase(_module).hasDealExpired(_dealId)),
            "DaoDepositManager: Error 222"
        );

        uint256 freeAmount = d.amount - d.used;
        // Deposit can't be used by a module or withdrawn already
        require(freeAmount > 0, "DaoDepositManager: Error 240");
        d.used = d.amount;
        availableDealBalances[d.token][_module][_dealId] -= freeAmount;
        tokenBalances[d.token] -= freeAmount;
        _transfer(d.token, d.depositor, freeAmount);

        emit Withdrawn(
            _module,
            _dealId,
            d.depositor,
            _depositId,
            d.token,
            freeAmount
        );
        return (d.depositor, d.token, freeAmount);
    }

    /**
     * @notice              Sends the token and amount associated with the dealId into the Deal
                            module
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @param _amount       The amount that is sent to the module
     */
    function sendToModule(
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) external onlyModule {
        uint256 amountLeft = _amount;
        for (uint256 i; i < deposits[msg.sender][_dealId].length; ++i) {
            Deposit storage d = deposits[msg.sender][_dealId][i];
            if (d.token == _token) {
                uint256 freeAmount = d.amount - d.used;
                if (freeAmount > amountLeft) {
                    freeAmount = amountLeft;
                }
                amountLeft -= freeAmount;
                d.used += freeAmount;

                if (amountLeft == 0) {
                    _transfer(_token, msg.sender, _amount);
                    tokenBalances[_token] -= _amount;
                    availableDealBalances[_token][msg.sender][
                        _dealId
                    ] -= _amount;
                    // break out of the loop, since we sent the tokens
                    // we now jump to the require statement at the end
                    break;
                }
            }
        }
        require(amountLeft == 0, "DaoDepositManager: Error 262");
    }

    /**
     * @notice                  Starts the vesting periode for a given token plus amount,
                                associated to a dealId
     * @param _token            The address of the ERC20 token or ETH (ZERO address)
     * @param _amount           The total amount being vested
     * @param _vestingCliff     The duration after which tokens can be claimed starting from the
                                vesting start, in seconds
     * @param _vestingDuration  The duration the tokens are vested, in seconds
     */
    function startVesting(
        uint32 _dealId,
        address _token,
        uint256 _amount,
        uint32 _vestingCliff,
        uint32 _vestingDuration
    ) external payable onlyModule {
        require(_amount > 0, "DaoDepositManager: Error 101");
        require(
            _vestingCliff < _vestingDuration,
            "DaoDepositManager: Error 201"
        );

        if (_token != address(0)) {
            _transferFrom(_token, msg.sender, address(this), _amount);
        } else {
            require(_amount == msg.value, "DaoDepositManager: Error 202");
        }
        // no else path, since ETH will be sent by the module,
        // which is verified by the verifyBalance() call after
        // updating the vestedBalances

        vestedBalances[_token] += _amount;

        verifyBalance(_token);

        vestings.push(
            Vesting(
                msg.sender,
                _dealId,
                _token,
                _amount,
                0,
                // solhint-disable-next-line not-rely-on-time
                uint32(block.timestamp),
                _vestingCliff,
                _vestingDuration
            )
        );

        if (vestedTokenAmounts[_token] == 0) {
            vestedTokenAddresses.push(_token);
        }

        vestedTokenAmounts[_token] += _amount;

        // Outside of the if-clause above to catch the
        // unlikely edge-case of multiple vestings of the
        // same token for one deal. This is necessary
        // for deal-based vesting claims to work.
        ++tokensPerDeal[msg.sender][_dealId];

        emit VestingStarted(
            msg.sender,
            _dealId,
            // solhint-disable-next-line not-rely-on-time
            uint32(block.timestamp),
            _vestingCliff,
            _vestingDuration,
            _token,
            _amount
        );
    }

    /**
     * @notice              Claims all the possible ERC20 tokens and ETH, across all deals that are
                            part of this DaoDepositManager
     * @dev                 This function can be called to retrieve the claimable amounts,
                            to show in the frontend for example
     * @return tokens       Array of addresses of the claimed tokens
     * @return amounts      Array of amounts claimed, in the same order as the tokens array
     */
    function claimVestings()
        external
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 vestingCount = vestedTokenAddresses.length;
        tokens = new address[](vestingCount);
        amounts = new uint256[](vestingCount);

        // Copy storage array to memory, since the "original"
        // array might change during sendReleasableClaim() if
        // the amount of a token reaches zero
        for (uint256 i; i < vestingCount; ++i) {
            tokens[i] = vestedTokenAddresses[i];
        }

        for (uint256 i; i < vestings.length; ++i) {
            (address token, uint256 amount) = sendReleasableClaim(vestings[i]);
            for (uint256 j; j < vestingCount; ++j) {
                if (token == tokens[j]) {
                    amounts[j] += amount;
                }
            }
        }
        return (tokens, amounts);
    }

    /**
     * @notice              Claims all the possible ERC20 tokens and ETH, associated with
                            a single dealId
     * @dev                 This function can be called to retrieve the claimable amount,
                            to show in the frontend for example
     * @param _module       The module address of which the dealId is part off
     * @param _dealId       A specific deal, that is part of the dealModule
     * @return tokens       Array of addresses of the claimed tokens, in the same order as the
                            amounts array
     * @return amounts      Array of amounts claimed, in the same order as the tokens array
     */
    function claimDealVestings(address _module, uint32 _dealId)
        external
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 amountOfTokens = tokensPerDeal[_module][_dealId];

        tokens = new address[](amountOfTokens);
        amounts = new uint256[](amountOfTokens);
        uint256 counter;
        if (amountOfTokens != 0) {
            for (uint256 i; i < vestings.length; ++i) {
                Vesting storage v = vestings[i];
                if (v.dealModule == _module && v.dealId == _dealId) {
                    (tokens[counter], amounts[counter]) = sendReleasableClaim(
                        v
                    );
                    ++counter;
                }
            }
        }
        return (tokens, amounts);
    }

    /**
     * @notice              Sends the claimable amount of the token, associated with the Vesting
                            to the DAO address stored in the state.
     * @param vesting       Struct containing all the information related to vesting
     * @return token        Addresses of the claimed token
     * @return amount       Amount of the claimable token
     */
    function sendReleasableClaim(Vesting storage vesting)
        private
        returns (address token, uint256 amount)
    {
        if (vesting.totalClaimed < vesting.totalVested) {
            // Check cliff was reached
            // solhint-disable-next-line not-rely-on-time
            uint32 elapsedSeconds = uint32(block.timestamp) - vesting.startTime;

            if (elapsedSeconds < vesting.cliff) {
                return (vesting.token, 0);
            }
            if (elapsedSeconds >= vesting.duration) {
                amount = vesting.totalVested - vesting.totalClaimed;
                vesting.totalClaimed = vesting.totalVested;
                tokensPerDeal[vesting.dealModule][vesting.dealId]--;
            } else {
                amount =
                    (vesting.totalVested * uint256(elapsedSeconds)) /
                    uint256(vesting.duration);
                vesting.totalClaimed += amount;
            }

            token = vesting.token;
            vestedTokenAmounts[token] -= amount;

            // if the corresponding token doesn't have any
            // vested amounts in any vesting anymore,
            // we remove it from the array
            if (vestedTokenAmounts[token] == 0) {
                uint256 arrLen = vestedTokenAddresses.length;
                for (uint256 i; i < arrLen; ++i) {
                    if (vestedTokenAddresses[i] == token) {
                        // if it's not the last element
                        // move the last to the current slot
                        if (i != arrLen - 1) {
                            vestedTokenAddresses[i] = vestedTokenAddresses[
                                arrLen - 1
                            ];
                        }
                        // remove the last entry
                        vestedTokenAddresses.pop();
                        --arrLen;
                    }
                }
            }

            require(
                vesting.totalClaimed <= vesting.totalVested,
                "DaoDepositManager: Error 244"
            );
            vestedBalances[token] -= amount;
            _transfer(token, dao, amount);

            emit VestingClaimed(
                vesting.dealModule,
                vesting.dealId,
                dao,
                token,
                amount
            );
        }
    }

    /**
     * @notice              Verifies if the DaoDepositContract holds the balance as expected
     * @param _token        Address of the ERC20 token or ETH (ZERO address)
     */
    function verifyBalance(address _token) public view {
        require(
            getBalance(_token) >=
                tokenBalances[_token] + vestedBalances[_token],
            "DaoDepositManager: Error 245"
        );
    }

    /**
     * @notice              Returns all the members in the Deposit struct for a given depositId
     * @dev                 If ETH has been deposited, the token address returned
                            will show ZERO (0)
     * @param _module       The address of the module of which the dealId is part of
     * @param _dealId       The dealId to for which the deposit has been made
     * @param _depositId    The ID of the deposit action (position in array)
     * @return address      The depositor address
     * @return address      The address of the ERC20 token or ETH (ZERO address)
     * @return uint256      The amount that has been deposited
     * @return uint256      The amount already used in a deal
     * @return uint32       The Unix timestamp of the deposit
     */
    function getDeposit(
        address _module,
        uint32 _dealId,
        uint32 _depositId
    )
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint32
        )
    {
        Deposit memory d = deposits[_module][_dealId][_depositId];
        return (d.depositor, d.token, d.amount, d.used, d.depositedAt);
    }

    /**
     * @notice                  Returns all the members from all the Deposits within
                                a given range of depositIds
     * @dev                     If ETH has been deposited, the token address returned
                                will show ZERO (0)
     * @param _module           The address of the module of which the dealId is part of
     * @param _dealId           The dealId to for which the deposits have been made
     * @param _fromDepositId    First depositId (element in array) of the range IDs
     * @param _toDepositId      Last depositId (element in array) of the range of IDs
     * @return depositors       Array of addresses of the depositors in the deposit range
     * @return tokens           Array of token addresses or ETH (ZERO address) in the
                                deposit range
     * @return amounts          Array of amounts, sorted similar as tokens array, for the given
                                deposit range
     * @return usedAmounts      Array of amounts already used in a deal, for the given
                                deposit range
     * @return times            Array of Unix timestamps of the deposits, for the given
                                deposit range
     */
    function getDepositRange(
        address _module,
        uint32 _dealId,
        uint32 _fromDepositId,
        uint32 _toDepositId
    )
        external
        view
        returns (
            address[] memory depositors,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory usedAmounts,
            uint256[] memory times
        )
    {
        uint32 range = 1 + _toDepositId - _fromDepositId; // inclusive range
        depositors = new address[](range);
        tokens = new address[](range);
        amounts = new uint256[](range);
        usedAmounts = new uint256[](range);
        times = new uint256[](range);
        uint256 index = 0; // needed since the ids can start at > 0
        for (uint32 i = _fromDepositId; i <= _toDepositId; ++i) {
            (
                depositors[index],
                tokens[index],
                amounts[index],
                usedAmounts[index],
                times[index]
            ) = getDeposit(_module, _dealId, i);
            ++index;
        }
        return (depositors, tokens, amounts, usedAmounts, times);
    }

    /**
     * @notice              Returns the stored amount of an ERC20 token or ETH, for a given deal
     * @param _module       The address of the module to which the dealId is part of
     * @param _dealId       The dealId that relates to the ERC20 token or ETH balance
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @return uint256      The balance amount of the ERC20 token or ETH, specific to the dealId
     */
    function getAvailableDealBalance(
        address _module,
        uint32 _dealId,
        address _token
    ) external view returns (uint256) {
        return availableDealBalances[_token][_module][_dealId];
    }

    /**
     * @notice              Returns the total number of deposits made, for a given dealId
     * @param _module       The address of the module to which the dealId is part of
     * @param _dealId       The dealId for which deposits have been made
     * @return uint32       The total amount of deposits made, for a given dealId
     */
    function getTotalDepositCount(address _module, uint32 _dealId)
        external
        view
        returns (uint32)
    {
        return uint32(deposits[_module][_dealId].length);
    }

    /**
     * @notice              Returns the withdrawable amount of a specifc token and dealId,
                            for a given address
     * @dev                 If ETH has been deposited, the token address used should be ZERO (0)
     * @param _module       The address of the module of which the dealId is part of
     * @param _dealId       The dealId for which a deposit has been made, to check
                            for withdrawable amounts
     * @param _depositor    The address of the depositor that is able to withdraw,
                            deposited amounts
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @return uint256      The available amount that can be withdrawn by the depositor
     */
    function getWithdrawableAmountOfDepositor(
        address _module,
        uint32 _dealId,
        address _depositor,
        address _token
    ) external view returns (uint256) {
        uint256 freeAmount;
        for (uint256 i; i < deposits[_module][_dealId].length; ++i) {
            if (
                deposits[_module][_dealId][i].depositor == _depositor &&
                deposits[_module][_dealId][i].token == _token
            ) {
                freeAmount += (deposits[_module][_dealId][i].amount -
                    deposits[_module][_dealId][i].used);
            }
        }
        return freeAmount;
    }

    /**
     * @notice              Returns the balance the DaoDepositContract holds, for a given
                            ERC20 token or ETH (ZERO address)
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @return uint256      The balance the contracts holds for the _token parameter
     */
    function getBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        }
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice              Returns the vested balance the DaoDepositContract holds,
                            for a given ERC20 token or ETH (ZERO address)
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @return uint256      The vested balance the contracts holds for the _token parameter
     */
    function getVestedBalance(address _token) external view returns (uint256) {
        return vestedBalances[_token];
    }

    /**
     * @notice              Transfers the ERC20 token or ETH (ZERO address), to the _to address
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @param _to           Receiver address of the _amount of _token
     * @param _amount       The amount to be transferred to the _to address
     */
    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token != address(0)) {
            try IERC20(_token).transfer(_to, _amount) returns (bool success) {
                require(success, "DaoDepositManager: Error 241");
            } catch {
                revert("DaoDepositManager: Error 241");
            }
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (bool sent, ) = _to.call{value: _amount}("");
            require(sent, "DaoDepositManager: Error 242");
        }
    }

    /**
     * @notice              Transfers the ERC20 token or ETH (ZERO address),
                            from the _from address to the _to address
     * @param _token        The address of the ERC20 token or ETH (ZERO address)
     * @param _from         The address on behalve of which the contract transfers the _token
     * @param _to           Receiver address of the _amount of _token
     * @param _amount       The amount to be transferred to the _to address
     */
    function _transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        try IERC20(_token).transferFrom(_from, _to, _amount) returns (
            bool success
        ) {
            require(success, "DaoDepositManager: Error 241");
        } catch {
            revert("DaoDepositManager: Error 241");
        }
    }

    /**
     * @notice              Modifier that validates that the msg.sender
                            is the DealManager contract
     */
    modifier onlyDealManager() {
        require(
            msg.sender == address(dealManager),
            "DaoDepositManager: Error 221"
        );
        _;
    }

    /**
     * @notice              Modifier that validates that the msg.sender
                            is a Deals module
     */
    modifier onlyModule() {
        require(
            dealManager.addressIsModule(msg.sender),
            "DaoDepositManager: Error 220"
        );
        _;
    }

    fallback() external payable {}

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IDealManager {
    function createDaoDepositManager(address _dao) external;

    function hasDaoDepositManager(address _dao) external view returns (bool);

    function getDaoDepositManager(address _dao) external view returns (address);

    function owner() external view returns (address);

    function weth() external view returns (address);

    function addressIsModule(address _address) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IModuleBase {
    function moduleIdentifier() external view returns (bytes32);

    function dealManager() external view returns (address);

    function hasDealExpired(uint32 _dealId) external view returns (bool);
}