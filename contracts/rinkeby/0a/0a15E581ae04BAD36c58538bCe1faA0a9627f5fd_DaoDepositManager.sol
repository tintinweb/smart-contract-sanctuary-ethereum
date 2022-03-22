// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDealManager.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IModuleBase.sol";

contract DaoDepositManager {
    address public dao;
    IDealManager public dealManager;

    // token address => balance
    mapping(address => uint256) public tokenBalances;
    // token address => deal module address => deal module id => balance
    mapping(address => mapping(address => mapping(uint32 => uint256)))
        public availableDealBalances;
    // token address => balance
    mapping(address => uint256) public vestedBalances;

    // deal module address => deal id => deposits array
    mapping(address => mapping(uint256 => Deposit[])) public deposits;

    Vesting[] public vestings;
    address[] public vestedTokenAddresses;
    // token address => amount
    mapping(address => uint256) public vestedTokenAmounts;
    // deal module address => deal id => token counter
    mapping(address => mapping(uint256 => uint256)) public tokensPerDeal;

    struct Deposit {
        address depositor;
        address token;
        uint256 amount;
        uint256 used;
        uint32 depositedAt;
    }

    struct Vesting {
        address dealModule;
        uint32 dealId;
        address token;
        uint256 totalVested;
        uint256 totalClaimed;
        uint32 startTime;
        uint32 cliff;
        uint32 duration;
    }

    event Deposited(
        address indexed dealModule,
        uint32 indexed dealId,
        address indexed depositor,
        uint256 depositId,
        address token,
        uint256 amount
    );

    event Withdrawn(
        address indexed dealModule,
        uint32 indexed dealId,
        address indexed depositor,
        uint32 depositId,
        address token,
        uint256 amount
    );

    event VestingStarted(
        address indexed dealModule,
        uint32 indexed dealId,
        uint256 indexed vestingStart,
        uint32 vestingCliff,
        uint32 vestingDuration,
        address token,
        uint256 amount
    );

    event VestingClaimed(
        address indexed dealModule,
        uint32 indexed dealId,
        address indexed dao,
        address token,
        uint256 claimed
    );

    /**
     * @dev                     Initialize the DaoDepositManager
     * @param _dao              The DAO address to which this contract belongs
     */
    function initialize(address _dao) external {
        require(dao == address(0), "D2D-DEPOSIT-ALREADY-INITIALIZED");
        require(_dao != address(0), "D2D-DEPOSIT-INVALID-DAO-ADDRESS");
        dao = _dao;
        dealManager = IDealManager(msg.sender);
    }

    /**
     * @dev                     Sets a new address for the DealManager implementation
     * @param _newDaoDepositManager  The address of the new DealManager
     */
    function setDealManagerImplementation(address _newDaoDepositManager)
        external
        onlyDealManager
    {
        dealManager = IDealManager(_newDaoDepositManager);
    }

    /**
     * @dev                     Transfers the token amount to the DaoDepositManager and
     *                          stores the parameters in a Deposit structure
     * @param _module           The address of the module for which is being deposited
     * @param _dealId           The dealId to which this deposit is part of
     * @param _token            The address of the token that is deposited
     * @param _amount           The amount that is deposited
     */
    function deposit(
        address _module,
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) public payable {
        require(
            (_token != address(0) && _amount > 0) ||
                (_token == address(0) && msg.value > 0),
            "D2D-DEPOSIT-INVALID-TOKEN-AMOUNT"
        );
        if (_token != address(0)) {
            _transferTokenFrom(_token, msg.sender, address(this), _amount);
        } else {
            _amount = msg.value;
            _token = dealManager.weth();
            IWETH(_token).deposit{value: _amount}();
        }

        tokenBalances[_token] += _amount;
        availableDealBalances[_token][_module][_dealId] += _amount;
        verifyBalance(_token);
        // solhint-disable-next-line not-rely-on-time
        deposits[_module][_dealId].push(
            Deposit(msg.sender, _token, _amount, 0, uint32(block.timestamp))
        );

        emit Deposited(
            _module,
            _dealId,
            msg.sender,
            deposits[_module][_dealId].length - 1,
            _token,
            _amount
        );
    }

    function multipleDeposits(
        address _module,
        uint32 _dealId,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external payable {
        // solhint-disable-next-line reason-string
        require(
            _tokens.length == _amounts.length,
            "D2D-DEPOSIT-ARRAY-LENGTH-MISMATCH"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            deposit(_module, _dealId, _tokens[i], _amounts[i]);
        }
    }

    function registerDeposit(
        address _module,
        uint32 _dealId,
        address _token
    ) public {
        uint256 currentBalance = 0;
        if (_token != address(0)) {
            currentBalance = IERC20(_token).balanceOf(address(this));
        } else {
            _token = dealManager.weth();
            currentBalance = address(this).balance;
        }
        if (currentBalance > tokenBalances[_token]) {
            uint256 amount = currentBalance - tokenBalances[_token];
            tokenBalances[_token] = currentBalance;
            if (_token == address(0)) {
                IWETH(_token).deposit{value: amount}();
            }
            availableDealBalances[_token][_module][_dealId] += amount;
            deposits[_module][_dealId].push(
                Deposit(dao, _token, amount, 0, uint32(block.timestamp))
            );
            emit Deposited(
                _module,
                _dealId,
                dao,
                deposits[_module][_dealId].length - 1,
                _token,
                amount
            );
        }
        verifyBalance(_token);
    }

    function registerDeposits(
        address _module,
        uint32 _dealId,
        address[] calldata _tokens
    ) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            registerDeposit(_module, _dealId, _tokens[i]);
        }
    }

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
            "D2D-DEPOSIT-INVALID-DEPOSIT-ID"
        );
        Deposit storage d = deposits[_module][_dealId][_depositId];

        // Either the caller did the deposit or it's a dao deposit
        // and the caller facilitates the withdraw for the dao
        // (which is only possible after the deal expired)

        require(
            d.depositor == msg.sender ||
                (d.depositor == dao &&
                    IModuleBase(_module).hasDealExpired(_dealId)),
            "D2D-WITHDRAW-NOT-AUTHORIZED"
        );

        uint256 freeAmount = d.amount - d.used;
        // Deposit can't be used by a module or withdrawn already
        require(freeAmount > 0, "D2D-DEPOSIT-NOT-WITHDRAWABLE");
        d.used = d.amount;
        availableDealBalances[d.token][_module][_dealId] -= freeAmount;
        tokenBalances[d.token] -= freeAmount;

        // If it's a token
        if (d.token != dealManager.weth()) {
            _transferToken(d.token, d.depositor, freeAmount);
            // Else if it's Ether
        } else {
            IWETH(dealManager.weth()).withdraw(freeAmount);
            require(
                address(this).balance >= freeAmount,
                "D2D-DEPOSIT-INVALID-AMOUNT"
            );
            (bool sent, ) = d.depositor.call{value: freeAmount}("");
            require(sent, "D2D-DEPOSIT-FAILED-TO-SEND-ETHER");
        }

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

    function sendToModule(
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) external onlyModule returns (bool) {
        uint256 amountLeft = _amount;
        for (uint256 i = 0; i < deposits[msg.sender][_dealId].length; i++) {
            if (deposits[msg.sender][_dealId][i].token == _token) {
                uint256 freeAmount = deposits[msg.sender][_dealId][i].amount -
                    deposits[msg.sender][_dealId][i].used;
                if (freeAmount > amountLeft) {
                    freeAmount = amountLeft;
                }
                amountLeft -= freeAmount;
                deposits[msg.sender][_dealId][i].used += freeAmount;
                if (amountLeft == 0) {
                    if (_token == address(0)) {
                        IWETH(dealManager.weth()).withdraw(_amount);
                        (bool sent, ) = msg.sender.call{value: _amount}("");
                        require(sent, "D2D-DEPOSIT-FAILED-TO-SEND-ETHER");
                    } else {
                        _transferToken(_token, msg.sender, _amount);
                        tokenBalances[_token] -= _amount;
                    }
                    availableDealBalances[_token][msg.sender][
                        _dealId
                    ] -= _amount;
                    return true;
                }
            }
        }
        return false;
    }

    function startVesting(
        uint32 _dealId,
        address _token,
        uint256 _amount,
        uint32 _vestingCliff,
        uint32 _vestingDuration
    ) external onlyModule {
        // solhint-disable-next-line reason-string
        require(
            _token != address(0),
            "D2D-DEPOSIT-VESTING-INVALID-TOKEN-ADDRESS"
        );
        // solhint-disable-next-line reason-string
        require(_amount > 0, "D2D-DEPOSIT-VESTING-INVALID-AMOUNT");
        // solhint-disable-next-line reason-string
        require(
            _vestingCliff < _vestingDuration,
            "D2D-DEPOSIT-VESTINGCLIFF-BIGGER-THAN-DURATION"
        );

        _transferTokenFrom(_token, msg.sender, address(this), _amount);
        vestedBalances[_token] += _amount;

        vestings.push(
            Vesting(
                msg.sender,
                _dealId,
                _token,
                _amount,
                0,
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
        tokensPerDeal[msg.sender][_dealId]++;

        emit VestingStarted(
            msg.sender,
            _dealId,
            uint32(block.timestamp),
            _vestingCliff,
            _vestingDuration,
            _token,
            _amount
        );
    }

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
        for (uint256 i = 0; i < vestingCount; i++) {
            tokens[i] = vestedTokenAddresses[i];
        }

        for (uint256 i = 0; i < vestings.length; i++) {
            (address token, uint256 amount) = sendReleasableClaim(vestings[i]);
            for (uint256 j = 0; j < vestingCount; j++) {
                if (token == tokens[j]) {
                    amounts[j] += amount;
                }
            }
        }
        return (tokens, amounts);
    }

    function claimDealVestings(address _module, uint32 _dealId)
        external
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 amountOfTokens = tokensPerDeal[_module][_dealId];
        tokens = new address[](amountOfTokens);
        amounts = new uint256[](amountOfTokens);
        uint256 counter = 0;
        for (uint256 i = 0; i < vestings.length; i++) {
            if (
                vestings[i].dealModule == _module &&
                vestings[i].dealId == _dealId
            ) {
                (tokens[counter], amounts[counter]) = sendReleasableClaim(
                    vestings[i]
                );
                counter++;
            }
        }
    }

    function sendReleasableClaim(Vesting memory vesting)
        private
        returns (address token, uint256 amount)
    {
        if (vesting.totalClaimed < vesting.totalVested) {
            // Check cliff was reached
            uint256 elapsedSeconds = uint32(block.timestamp) -
                vesting.startTime;

            if (elapsedSeconds < vesting.cliff) {
                return (address(0), 0);
            }
            if (elapsedSeconds >= vesting.duration) {
                amount = vesting.totalVested - vesting.totalClaimed;
                vesting.totalClaimed = vesting.totalVested;
                tokensPerDeal[vesting.dealModule][vesting.dealId]--;
            } else {
                amount =
                    (vesting.totalVested * elapsedSeconds) /
                    vesting.duration;
                vesting.totalClaimed += amount;
            }

            token = vesting.token;
            vestedTokenAmounts[token] -= amount;

            // if the corresponding token doesn't have any
            // vested amounts in any vesting anymore,
            // we remove it from the array
            if (vestedTokenAmounts[token] == 0) {
                uint256 arrLen = vestedTokenAddresses.length;
                for (uint256 i = 0; i < arrLen; i++) {
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
                    }
                }
            }

            // solhint-disable-next-line reason-string
            require(
                vesting.totalClaimed <= vesting.totalVested,
                "D2D-VESTING-CLAIM-AMOUNT-MISMATCH"
            );
            vestedBalances[token] -= amount;
            if (token != dealManager.weth()) {
                _transferToken(token, dao, amount);
            } else {
                IWETH(dealManager.weth()).withdraw(amount);
                (bool sent, ) = dao.call{value: amount}("");
                require(sent, "D2D-DEPOSIT-FAILED-TO-SEND-ETHER");
            }

            emit VestingClaimed(
                vesting.dealModule,
                vesting.dealId,
                dao,
                token,
                amount
            );
        }
    }

    function verifyBalance(address _token) public view {
        if (_token == address(0)) {
            _token = dealManager.weth();
        }

        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(
            balance >= tokenBalances[_token] + vestedBalances[_token],
            "D2D-DEPOSIT-BALANCE-INVALID"
        );
    }

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
            uint256
        )
    {
        Deposit memory d = deposits[_module][_dealId][_depositId];
        return (
            d.depositor,
            d.token == dealManager.weth() ? address(0) : d.token,
            d.amount,
            d.used,
            d.depositedAt
        );
    }

    function getDepositRange(
        address _module,
        uint32 _dealId,
        uint32 _fromDepositId,
        uint32 _toDepositId
    )
        external
        view
        returns (
            address[] memory senders,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory usedAmounts,
            uint256[] memory times
        )
    {
        uint32 range = 2 + _toDepositId - _fromDepositId; // inclusive range
        senders = new address[](range);
        tokens = new address[](range);
        amounts = new uint256[](range);
        usedAmounts = new uint256[](range);
        times = new uint256[](range);
        for (uint32 i = _toDepositId; i <= _fromDepositId; i++) {
            (
                senders[i],
                tokens[i],
                amounts[i],
                usedAmounts[i],
                times[i]
            ) = getDeposit(_module, _dealId, i);
        }
        return (senders, tokens, amounts, usedAmounts, times);
    }

    function getAvailableDealBalance(
        address _module,
        uint32 _dealId,
        address _token
    ) external view returns (uint256) {
        return availableDealBalances[_token][_module][_dealId];
    }

    function getTotalDepositCount(address _module, uint32 _dealId)
        external
        view
        returns (uint256)
    {
        return deposits[_module][_dealId].length;
    }

    function getWithdrawableAmountOfUser(
        address _module,
        uint32 _dealId,
        address _user,
        address _token
    ) external view returns (uint256) {
        uint256 freeAmount = 0;
        for (uint256 i = 0; i < deposits[_module][_dealId].length; i++) {
            if (
                deposits[_module][_dealId][i].depositor == _user &&
                deposits[_module][_dealId][i].token == _token
            ) {
                freeAmount += (deposits[_module][_dealId][i].amount -
                    deposits[_module][_dealId][i].used);
            }
        }
        return freeAmount;
    }

    function getBalance(address _token) external view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        }
        return tokenBalances[_token];
    }

    function getVestedBalance(address _token) external view returns (uint256) {
        return vestedBalances[_token];
    }

    function _transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(
            IERC20(_token).transfer(_to, _amount),
            "D2D-TOKEN-TRANSFER-FAILED"
        );
    }

    function _transferTokenFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(
            IERC20(_token).transferFrom(_from, _to, _amount),
            "D2D-TOKEN-TRANSFER-FAILED"
        );
    }

    modifier onlyDealManager() {
        // solhint-disable-next-line reason-string
        require(
            msg.sender == address(dealManager),
            "D2D-DEPOSIT-ONLY-BASE-CONTRACT-CAN-ACCESS"
        );
        _;
    }

    modifier onlyModule() {
        require(dealManager.addressIsModule(msg.sender), "D2D-NOT-MODULE");
        _;
    }
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
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IModuleBase {
    function moduleIdentifier() external view returns (bytes32);

    function dealManager() external view returns (address);

    function hasDealExpired(uint32 _dealId) external view returns (bool);
}