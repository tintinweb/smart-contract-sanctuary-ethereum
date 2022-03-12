// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBaseContract.sol";
import "./interfaces/IWETH.sol";

contract DepositContract {
    address public dao;
    IBaseContract public baseContract;

    mapping(address => uint256) public tokenBalances;
    mapping(address => mapping(bytes32 => uint256))
        public availableModuleBalances;
    mapping(address => uint256) public vestedBalances;

    // Contains the module descriptor and the ID of the swap/action
    // so we can identify deposits for each individual interaction
    // e.g. keccak256(abi.encode("TOKEN_SWAP_MODULE", 42));
    // for a deposit for a token swap with the id 42
    mapping(bytes32 => Deposit[]) public deposits;

    Vesting[] public vestings;

    struct Deposit {
        address sender;
        address token;
        uint256 amount;
        uint256 used;
        uint256 time;
    }

    struct Vesting {
        bytes32 actionId;
        address token;
        uint256 totalVested;
        uint256 totalClaimed;
        uint256 startTime;
        uint256 cliff;
        uint256 duration;
    }

    event Deposited(
        bytes32 processID,
        uint256 depositID,
        address token,
        uint256 amount,
        address sender
    );

    event Withdrawn(
        bytes32 processID,
        uint256 depositID,
        address to,
        address token,
        uint256 amount
    );

    event VestingStarted(
        bytes32 processID,
        address token,
        uint256 amount,
        uint256 vestingStart,
        uint256 vestingCliff,
        uint256 vestingDuration
    );

    event VestingClaimed(
        bytes32 actionId,
        address token,
        uint256 claimed,
        address dao
    );

    function initialize(address _dao) external {
        require(dao == address(0), "D2D-DEPOSIT-ALREADY-INITIALIZED");
        require(_dao != address(0), "D2D-DEPOSIT-INVALID-DAO-ADDRESS");
        dao = _dao;
        baseContract = IBaseContract(msg.sender);
    }

    function migrateBaseContract(address _newBaseContract)
        external
        onlyBaseContract
    {
        baseContract = IBaseContract(_newBaseContract);
    }

    function deposit(
        bytes32 _processID,
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
            _token = baseContract.weth();
            IWETH(_token).deposit{value: _amount}();
        }

        tokenBalances[_token] += _amount;
        availableModuleBalances[_token][_processID] += _amount;
        verifyBalance(_token);
        // solhint-disable-next-line not-rely-on-time
        deposits[_processID].push(
            Deposit(msg.sender, _token, _amount, 0, block.timestamp)
        );

        emit Deposited(
            _processID,
            deposits[_processID].length,
            _token,
            _amount,
            msg.sender
        );
    }

    function multipleDeposits(
        bytes32 _processID,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external payable {
        // solhint-disable-next-line reason-string
        require(
            _tokens.length == _amounts.length,
            "D2D-DEPOSIT-ARRAY-LENGTH-MISMATCH"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            deposit(_processID, _tokens[i], _amounts[i]);
        }
    }

    function registerDeposit(bytes32 _processID, address _token) public {
        uint256 currentBalance = 0;
        if (_token != address(0)) {
            currentBalance = IERC20(_token).balanceOf(address(this));
        } else {
            _token = baseContract.weth();
            currentBalance = address(this).balance;
        }
        if (currentBalance > tokenBalances[_token]) {
            uint256 amount = currentBalance - tokenBalances[_token];
            tokenBalances[_token] = currentBalance;
            if (_token == address(0)) {
                IWETH(_token).deposit{value: amount}();
            }
            availableModuleBalances[_token][_processID] += amount;
            deposits[_processID].push(
                Deposit(dao, _token, amount, 0, block.timestamp)
            );
            emit Deposited(
                _processID,
                deposits[_processID].length,
                _token,
                amount,
                dao
            );
        }
        verifyBalance(_token);
    }

    function registerDeposits(bytes32 _processID, address[] calldata _tokens)
        external
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            registerDeposit(_processID, _tokens[i]);
        }
    }

    function withdraw(bytes32 _processID, uint256 _depositID)
        external
        returns (
            address,
            address,
            uint256
        )
    {
        require(
            deposits[_processID].length >= _depositID,
            "D2D-DEPOSIT-INVALID-DEPOSIT-ID"
        );
        Deposit storage d = deposits[_processID][_depositID];
        // Either the caller did the deposit or it's a dao deposit
        // and the caller is the dao or a representative
        require(d.sender == msg.sender, "D2D-WITHDRAW-NOT-AUTHORIZED");

        uint256 freeAmount = d.amount - d.used;
        // Deposit can't be used by a module or withdrawn already
        require(freeAmount > 0, "D2D-DEPOSIT-NOT-WITHDRAWABLE");
        d.used = d.amount;
        availableModuleBalances[d.token][_processID] -= freeAmount;
        tokenBalances[d.token] -= freeAmount;

        // If it's a token
        if (d.token != baseContract.weth()) {
            _transferToken(d.token, d.sender, freeAmount);
            // Else if it's Ether
        } else {
            IWETH(baseContract.weth()).withdraw(freeAmount);
            require(
                address(this).balance >= freeAmount,
                "D2D-DEPOSIT-INVALID-AMOUNT"
            );
            (bool sent, ) = d.sender.call{value: freeAmount}("");
            require(sent, "D2D-DEPOSIT-FAILED-TO-SEND-ETHER");
        }

        emit Withdrawn(_processID, _depositID, d.sender, d.token, freeAmount);
        return (d.sender, d.token, freeAmount);
    }

    function sendToModule(
        bytes32 _processID,
        address _token,
        uint256 _amount
    ) external onlyModule returns (bool) {
        uint256 amountLeft = _amount;
        for (uint256 i = 0; i < deposits[_processID].length; i++) {
            if (deposits[_processID][i].token == _token) {
                uint256 freeAmount = deposits[_processID][i].amount -
                    deposits[_processID][i].used;
                if (freeAmount > amountLeft) {
                    freeAmount = amountLeft;
                }
                amountLeft -= freeAmount;
                deposits[_processID][i].used += freeAmount;
                if (amountLeft == 0) {
                    if (_token == address(0)) {
                        IWETH(baseContract.weth()).withdraw(_amount);
                        (bool sent, ) = msg.sender.call{value: _amount}("");
                        require(sent, "D2D-DEPOSIT-FAILED-TO-SEND-ETHER");
                    } else {
                        _transferToken(_token, msg.sender, _amount);
                        tokenBalances[_token] -= _amount;
                    }
                    availableModuleBalances[_token][_processID] -= _amount;
                    return true;
                }
            }
        }
        return false;
    }

    function startVesting(
        bytes32 _actionId,
        address _token,
        uint256 _amount,
        uint256 _vestingCliff,
        uint256 _vestingDuration
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
                _actionId,
                _token,
                _amount,
                0,
                block.timestamp,
                _vestingCliff,
                _vestingDuration
            )
        );
        emit VestingStarted(
            _actionId,
            _token,
            _amount,
            block.timestamp,
            _vestingCliff,
            _vestingDuration
        );
    }

    function claimVestings() external returns (uint256 amount) {
        for (uint256 i = 0; i < vestings.length; i++) {
            amount += sentReleasableClaim(vestings[i]);
        }
    }

    function sentReleasableClaim(Vesting memory vesting)
        private
        returns (uint256 amount)
    {
        if (vesting.totalClaimed < vesting.totalVested) {
            // Check cliff was reached
            uint256 elapsedSeconds = block.timestamp - vesting.startTime;

            if (elapsedSeconds < vesting.cliff) {
                return 0;
            }
            if (elapsedSeconds >= vesting.duration) {
                amount = vesting.totalVested - vesting.totalClaimed;
                vesting.totalClaimed = vesting.totalVested;
            } else {
                amount =
                    (vesting.totalVested * elapsedSeconds) /
                    vesting.duration;
                vesting.totalClaimed += amount;
            }
            // solhint-disable-next-line reason-string
            require(
                vesting.totalClaimed <= vesting.totalVested,
                "D2D-VESTING-CLAIM-AMOUNT-MISMATCH"
            );
            vestedBalances[vesting.token] -= amount;
            if (vesting.token != baseContract.weth()) {
                _transferToken(vesting.token, dao, amount);
            } else {
                IWETH(baseContract.weth()).withdraw(amount);
                (bool sent, ) = dao.call{value: amount}("");
                require(sent, "D2D-DEPOSIT-FAILED-TO-SEND-ETHER");
            }
            emit VestingClaimed(vesting.actionId, vesting.token, amount, dao);
        }
    }

    function claimDealVestings(bytes32 _id) external returns (uint256 amount) {
        for (uint256 i = 0; i < vestings.length; i++) {
            if (vestings[i].actionId == _id) {
                amount = sentReleasableClaim(vestings[i]);
            }
        }
    }

    function verifyBalance(address _token) public view {
        if (_token == address(0)) {
            _token = baseContract.weth();
        }

        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(
            balance >= tokenBalances[_token] + vestedBalances[_token],
            "D2D-DEPOSIT-BALANCE-INVALID"
        );
    }

    function getDeposit(bytes32 _processID, uint256 _depositID)
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
        Deposit memory d = deposits[_processID][_depositID];
        return (
            d.sender,
            d.token == baseContract.weth() ? address(0) : d.token,
            d.amount,
            d.used,
            d.time
        );
    }

    function getDepositRange(
        bytes32 _processID,
        uint256 _fromDepositID,
        uint256 _toDepositID
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
        uint256 range = 2 + _toDepositID - _fromDepositID; // inclusive range
        senders = new address[](range);
        tokens = new address[](range);
        amounts = new uint256[](range);
        usedAmounts = new uint256[](range);
        times = new uint256[](range);
        for (uint256 i = _toDepositID; i <= _fromDepositID; i++) {
            (
                senders[i],
                tokens[i],
                amounts[i],
                usedAmounts[i],
                times[i]
            ) = getDeposit(_processID, i);
        }
        return (senders, tokens, amounts, usedAmounts, times);
    }

    function getAvailableProcessBalance(bytes32 _processID, address _token)
        external
        view
        returns (uint256)
    {
        return availableModuleBalances[_token][_processID];
    }

    function getTotalDepositCount(bytes32 _processID)
        external
        view
        returns (uint256)
    {
        return deposits[_processID].length;
    }

    function getWithdrawableAmountOfUser(
        bytes32 _processID,
        address _user,
        address _token
    ) external view returns (uint256) {
        uint256 freeAmount = 0;
        for (uint256 i = 0; i < deposits[_processID].length; i++) {
            if (
                deposits[_processID][i].sender == _user &&
                deposits[_processID][i].token == _token
            ) {
                freeAmount += (deposits[_processID][i].amount -
                    deposits[_processID][i].used);
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

    function getProcessID(string memory _module, uint256 _id)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_module, _id));
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

    modifier onlyBaseContract() {
        // solhint-disable-next-line reason-string
        require(
            msg.sender == address(baseContract),
            "D2D-DEPOSIT-ONLY-BASE-CONTRACT-CAN-ACCESS"
        );
        _;
    }

    modifier onlyModule() {
        require(baseContract.addressIsModule(msg.sender), "D2D-NOT-MODULE");
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

interface IBaseContract {
    function createDepositContract(address _dao) external;

    function hasDepositContract(address _dao) external view returns (bool);

    function getDepositContract(address _dao) external view returns (address);

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