// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "../ModuleBaseWithFee.sol";

/**
 * @title PrimeDeals Token Swap Module
 * @dev   Smart contract to handle token swap
 *        interactions for PrimeDeals
 */
contract TokenSwapModule is ModuleBaseWithFee {
    TokenSwap[] public tokenSwaps;
    mapping(bytes => uint32) public metadataToDealId;

    /**
     * @dev
     * pathFrom Description:
     * Used to storing how many tokens does each DAO send to the module
     *
     * Example on how the values are stored:
     * token -> DAO -> amount
     * [[123, 0, 123], [0, 123, 0]]
     * token 1: DAO 1 sends 123, DAO 2 sends 0, DAO 3 sends 123, etc.
     */

    /**
     * @dev
     * pathTo:
     * Used for storing how many tokens does each DAO receive from the module
     * includes vesting. For each DAO there is a tuple of four values:
     * instant amount, vested amount, vesting cliff, vesting duration.
     * The start time will be the block.timestamp when executing the deal.
     * This timestamp + vestingDuration can be used to calculate the vesting end.
     *
     * Example on how the values are stored:
     * token -> DAO -> tuple(4)
     * [[instantAmount_dao1, vestedAmount_dao1, vestingCliff_dao1,
     * vestingDuration_dao1, instantAmount_dao2, ...], [...]]
     */

    struct TokenSwap {
        // The participating DAOs
        address[] daos;
        // The tokens involved in the swap
        address[] tokens;
        // the token flow from the DAOs to the module
        uint256[][] pathFrom;
        // the token flow from the module to the DAO
        uint256[][] pathTo;
        // unix timestamp of the deadline
        uint32 deadline;
        // unix timestamp of the execution
        uint32 executionDate;
        // hash of the deal information.
        bytes metadata;
        // status of the deal
        Status status;
    }

    event TokenSwapCreated(
        address indexed module,
        uint32 indexed dealId,
        bytes indexed metadata,
        address[] daos,
        address[] tokens,
        uint256[][] pathFrom,
        uint256[][] pathTo,
        uint32 deadline
    );

    event TokenSwapExecuted(address indexed module, uint32 indexed dealId);

    constructor(address _dealmanager) ModuleBaseWithFee(_dealmanager) {}

    /**
      * @dev                Create a new token swap action
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _pathFrom    Two-dimensional array containing the tokens flowing from the
                            DAOs into the module:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Contains absolute numbers of tokens
      * @param _pathTo      Two-dimensional array containing the tokens flowing from the
                            module to the DAOs:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Contains a tuple(4) consisting of instant amount, vested 
                                amount, vesting start, vesting end which then makes this 
                                array look like:
                                [[instantAmount_dao1, vestedAmount_dao1, vestingStart_dao1,
                                vestingEnd_dao1, instantAmount_dao2, ...], [...]]
      * @param _deadline    Time until which this action can be executed (unix timestamp)
      * @return             The dealId of the new action
    */
    function _createSwap(
        address[] memory _daos,
        address[] memory _tokens,
        uint256[][] memory _pathFrom,
        uint256[][] memory _pathTo,
        bytes memory _metadata,
        uint32 _deadline
    ) internal returns (uint32) {
        if (tokenSwaps.length >= 1) {
            require(
                _metadataDoesNotExist(_metadata),
                "Module: metadata already exists"
            );
        }
        require(_daos.length >= 2, "Module: at least 2 daos required");
        require(_tokens.length >= 1, "Module: at least 1 token required");
        require(
            _tokens.length == _pathFrom.length &&
                _pathFrom.length == _pathTo.length &&
                _pathFrom[0].length == _daos.length &&
                _pathTo[0].length / 4 == _daos.length,
            "Module: invalid array lengths"
        );

        TokenSwap memory ts = TokenSwap(
            _daos,
            _tokens,
            _pathFrom,
            _pathTo,
            _deadline,
            0,
            _metadata,
            Status.ACTIVE
        );
        tokenSwaps.push(ts);

        uint32 dealId = uint32(tokenSwaps.length - 1);

        metadataToDealId[_metadata] = dealId;

        emit TokenSwapCreated(
            address(this),
            dealId,
            _metadata,
            _daos,
            _tokens,
            _pathFrom,
            _pathTo,
            _deadline
        );
        return dealId;
    }

    /**
      * @dev                Create a new token swap action and automatically
                            creates Dao Deposit Manager for each DAO that does not have one
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _pathFrom    Two-dimensional array containing the tokens flowing from the
                            DAOs into the module:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Contains absolute numbers of tokens
      * @param _pathTo      Two-dimensional array containing the tokens flowing from the
                            module to the DAOs:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Contains a tuple(4) consisting of instant amount, vested 
                                amount, vesting start, vesting end which then makes this 
                                array look like:
                                [[instantAmount_dao1, vestedAmount_dao1, vestingStart_dao1,
                                vestingEnd_dao1, instantAmount_dao2, ...], [...]]
      * @param _deadline    Time until which this action can be executed (unix timestamp)
    */
    function createSwap(
        address[] calldata _daos,
        address[] calldata _tokens,
        uint256[][] calldata _pathFrom,
        uint256[][] calldata _pathTo,
        bytes calldata _metadata,
        uint32 _deadline
    ) external returns (uint32) {
        for (uint256 i = 0; i < _daos.length; i++) {
            if (!dealManager.hasDaoDepositManager(_daos[i])) {
                dealManager.createDaoDepositManager(_daos[i]);
            }
        }
        return (
            _createSwap(
                _daos,
                _tokens,
                _pathFrom,
                _pathTo,
                _metadata,
                _deadline
            )
        );
    }

    /**
      * @dev            Checks whether a token swap action can be executed
                        (which is the case if all DAOs have deposited)
      * @param _dealId  The dealId of the action (position in the array)
      * @return         A bool flag indiciating whether the action can be executed
    */
    function checkExecutability(uint32 _dealId)
        public
        view
        validDealId(_dealId)
        returns (bool)
    {
        TokenSwap memory ts = tokenSwaps[_dealId];
        if (ts.status != Status.ACTIVE) {
            return false;
        }
        if (ts.deadline < uint32(block.timestamp)) {
            return false;
        }
        for (uint256 i = 0; i < ts.tokens.length; i++) {
            for (uint256 j = 0; j < ts.pathFrom[i].length; j++) {
                // for each token and each pathFrom entry for this
                // token, check whether the corresponding DAO
                // has deposited the corresponding amount into their
                // deposit contract
                uint256 bal = IDaoDepositManager(
                    dealManager.getDaoDepositManager(ts.daos[j])
                ).getAvailableDealBalance(address(this), _dealId, ts.tokens[i]);
                if (bal < ts.pathFrom[i][j]) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @dev            Executes a token swap action
     * @param _dealId  The dealId of the action (position in the array)
     */
    function executeSwap(uint32 _dealId)
        external
        validDealId(_dealId)
        activeStatus(_dealId)
    {
        TokenSwap storage ts = tokenSwaps[_dealId];

        require(ts.deadline >= uint32(block.timestamp), "Module: swap expired");
        require(checkExecutability(_dealId), "Module: swap not executable");

        // transfer the tokens from the deposit manager of the DAOs
        // into this module
        uint256[] memory amountsIn = _pullTokensIntoModule(
            _dealId,
            ts.daos,
            ts.tokens,
            ts.pathFrom
        );

        // distribute the tokens from this module to the DAOs
        // and (if applicable) and their vesting contracts
        uint256[] memory amountsOut = _distributeTokens(ts, _dealId);

        // verify whether the amounts being pulled and pushed match
        for (uint256 i = 0; i < ts.tokens.length; i++) {
            require(amountsIn[i] == amountsOut[i], "Module: amount mismatch");
        }

        ts.status = Status.DONE;
        ts.executionDate = uint32(block.timestamp);
        emit TokenSwapExecuted(address(this), _dealId);
    }

    /**
      * @dev                Distributes the tokens based on the supplied
                            information to the DAOs or their vesting contracts
      * @param _ts          TokenSwap object containing all the information
                            of the action
      * @param _dealId      The dealId of the action (position in the array)
      * @return amountsOut  The two min values for the token amounts _ts
    */
    function _distributeTokens(TokenSwap memory _ts, uint32 _dealId)
        internal
        returns (uint256[] memory amountsOut)
    {
        amountsOut = new uint256[](_ts.tokens.length);
        // Distribute tokens from the module
        for (uint256 i = 0; i < _ts.tokens.length; i++) {
            for (uint256 k = 0; k < _ts.pathTo[i].length / 4; k++) {
                // every 4 values, the values for a new dao start
                // value 0 = instant amount
                // value 1 = vested amount
                // value 2 = vesting cliff
                // value 3 = vesting duration
                if (_ts.pathTo[i][k * 4] > 0) {
                    amountsOut[i] += _ts.pathTo[i][k * 4];
                    _transferTokenWithFee(
                        _ts.tokens[i],
                        _ts.daos[k],
                        _ts.pathTo[i][k * 4]
                    );
                }
                if (_ts.pathTo[i][k * 4 + 1] > 0) {
                    amountsOut[i] += _ts.pathTo[i][k * 4 + 1];
                    uint256 amount = _payFeeAndReturnRemainder(
                        _ts.tokens[i],
                        _ts.pathTo[i][k * 4 + 1]
                    );
                    _approveDaoDepositManager(
                        _ts.tokens[i],
                        _ts.daos[k],
                        amount
                    );
                    IDaoDepositManager(
                        dealManager.getDaoDepositManager(_ts.daos[k])
                    ).startVesting(
                            _dealId,
                            _ts.tokens[i],
                            amount, // amount
                            uint32(_ts.pathTo[i][k * 4 + 2]), // start
                            uint32(_ts.pathTo[i][k * 4 + 3]) // end
                        );
                }
            }
        }
    }

    function getTokenswapFromMetadata(bytes memory _metadata)
        public
        view
        validMetadata(_metadata)
        returns (TokenSwap memory swap)
    {
        return tokenSwaps[metadataToDealId[_metadata]];
    }

    function hasDealExpired(uint32 _dealId)
        external
        view
        override
        returns (bool)
    {
        return
            tokenSwaps[_dealId].status != Status.ACTIVE ||
            tokenSwaps[_dealId].deadline < uint32(block.timestamp);
    }

    function _metadataDoesNotExist(bytes memory _metadata)
        internal
        view
        returns (bool)
    {
        uint256 dealId = metadataToDealId[_metadata];
        return (dealId == 0 &&
            keccak256(tokenSwaps[dealId].metadata) != keccak256(_metadata) &&
            _metadata.length > 0);
    }

    modifier validMetadata(bytes memory _metadata) {
        uint256 dealId = metadataToDealId[_metadata];
        require(
            dealId != 0 ||
                keccak256(tokenSwaps[dealId].metadata) == keccak256(_metadata),
            "Module: metadata does not exist"
        );
        _;
    }

    modifier validDealId(uint32 _dealId) {
        require(_dealId < tokenSwaps.length, "Module: dealId doesn't exist");
        _;
    }

    modifier activeStatus(uint32 _dealId) {
        require(
            tokenSwaps[_dealId].status == Status.ACTIVE,
            "Module: dealId not active"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./ModuleBase.sol";

/**
 * @title PrimeDeals Module Base Fee Extension
 * @dev   Smart contract to extend the module
          base with a fee mechanim
 */
contract ModuleBaseWithFee is ModuleBase {
    // Wallet that is receiving the fees
    address public feeWallet;

    // Fee in basis points (1% = 10000)
    uint32 public feeInBasisPoints;

    /**
     * @dev                        Constructor
     * @param _dealManager         The address of Dealmanager implementation
     */
    constructor(address _dealManager) ModuleBase(_dealManager) {}

    /**
     * @notice                  This event is emitted when the fee wallet address is updated
     * @param oldFeeWallet      Address of the old fee wallet
     * @param newFeeWallet      Address of the new fee wallet
     */
    event FeeWalletChanged(
        address indexed oldFeeWallet,
        address indexed newFeeWallet
    );

    /**
     * @notice                  This event is emitted when the fee is updated
     * @param oldFee            Old fee amount in basis points (1% = 1000)
     * @param newFee            New fee in basis points (1% = 1000) that is updated
     */
    event FeeChanged(uint32 indexed oldFee, uint32 indexed newFee);

    /**
     * @dev                 Sets a new fee wallet
     * @param _feeWallet    Address of the new fee wallet
     */
    function setFeeWallet(address _feeWallet) external {
        require(msg.sender == dealManager.owner(), "Fee: not authorized");
        emit FeeWalletChanged(feeWallet, _feeWallet);
        feeWallet = _feeWallet;
    }

    /**
     * @dev                         Sets a new fee
     * @param _feeInBasisPoints     Fee amount in basis points (1% = 10000)
     */
    function setFee(uint32 _feeInBasisPoints) external {
        require(msg.sender == dealManager.owner(), "Fee: not authorized");
        require(_feeInBasisPoints <= 10000, "Fee: can't be more than 100%");
        emit FeeChanged(feeInBasisPoints, _feeInBasisPoints);
        feeInBasisPoints = _feeInBasisPoints;
    }

    /**
     * @dev             Pays the fee in a token and returns the remainder
     * @param _token    Token in which the transfer happens
     * @param _amount   Amount of the transfer
     * @return          Remaining amount after the fee payment
     */
    function _payFeeAndReturnRemainder(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        if (feeWallet != address(0) && feeInBasisPoints > 0) {
            uint256 fee = (_amount * feeInBasisPoints) / 10000;
            _transferToken(_token, feeWallet, fee);

            return _amount - fee;
        }
        return _amount;
    }

    /**
     * @dev             Transfers a token amount with automated fee payment
     * @param _token    Token in which the transfer happens
     * @param _to       Target of the transfer
     * @param _amount   Amount of the transfer
     */
    function _transferTokenWithFee(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        _transferToken(_token, _to, _payFeeAndReturnRemainder(_token, _amount));
    }

    /**
     * @dev             Transfers a token amount from someone with 
                        automated fee payment
     * @param _token    Token in which the transfer happens
     * @param _from     Source of the transfer
     * @param _to       Target of the transfer
     * @param _amount   Amount of the transfer
     */
    function _transferFromTokenWithFee(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        _transferFromToken(
            _token,
            _from,
            _to,
            _payFeeAndReturnRemainder(_token, _amount)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IDaoDepositManager.sol";
import "../interfaces/IDealManager.sol";

/**
 * @title PrimeDeals Module Base
 * @dev   Smart contract to serve as the
          basis for each module
 */
contract ModuleBase {
    // Address of the DealManager implementation
    IDealManager public dealManager;

    // @notics      Status of a deal
    // NULL         Uninitialized deal
    // ACTIVE       Deal has been created and is ready to be funded
    // CANCELLED    Deal has been canceld and is no longer valid
    // DONE         Deal has been executed
    enum Status {
        NULL,
        ACTIVE,
        CANCELLED,
        DONE
    }

    /**
     * @dev                            Constructor
     * @param _dealManager             The address of DealManager implementation
     */
    constructor(address _dealManager) {
        require(
            _dealManager != address(0),
            "Module: invalid base contract address"
        );
        dealManager = IDealManager(_dealManager);
    }

    /**
      * @dev                Sends tokens from a DAO deposit manager to the module
      * @param _dealId      ID of the action this is related to
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _path        Double nested array containing the amounts of tokens for each
                            token for each dao to be send
      * @return amountsIn   Array containing the total amounts sent per token
    */
    function _pullTokensIntoModule(
        uint32 _dealId,
        address[] memory _daos,
        address[] memory _tokens,
        uint256[][] memory _path
    ) internal returns (uint256[] memory amountsIn) {
        amountsIn = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_path[i].length == _daos.length, "Module: length mismatch");
            for (uint256 j = 0; j < _path[i].length; j++) {
                if (_path[i][j] > 0) {
                    amountsIn[i] += _path[i][j];
                    IDaoDepositManager(
                        dealManager.getDaoDepositManager(_daos[j])
                    ).sendToModule(_dealId, _tokens[i], _path[i][j]);
                }
            }
        }
    }

    /**
     * @dev            Calls the approval function of a token
     * @param _token   Address of the token
     * @param _to      Target of the approval
     * @param _amount  Amount to be approved
     */
    function _approveToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(IERC20(_token).approve(_to, _amount), "Module: approve failed");
    }

    /**
     * @dev            Calls the approval function of a token
                       for the deposit manager of a DAO
     * @param _token   Address of the token
     * @param _dao     DAO whose deposit manager is the target
     * @param _amount  Amount to be approved
     */
    function _approveDaoDepositManager(
        address _token,
        address _dao,
        uint256 _amount
    ) internal {
        _approveToken(_token, dealManager.getDaoDepositManager(_dao), _amount);
    }

    /**
     * @dev            Transfers an amount of tokens
     * @param _token   Address of the token
     * @param _to      Target of the transfer
     * @param _amount  Amount to be sent
     */
    function _transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(
            IERC20(_token).transfer(_to, _amount),
            "Module: transfer failed"
        );
    }

    /**
     * @dev            Transfers an amount of tokens from an address
     * @param _token   Address of the token
     * @param _from    Source of the transfer
     * @param _to      Target of the transfer
     * @param _amount  Amount to be sent
     */
    function _transferFromToken(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(
            IERC20(_token).transferFrom(_from, _to, _amount),
            "Module: transfer from failed"
        );
    }

    function hasDealExpired(uint32 _dealId)
        external
        view
        virtual
        returns (bool)
    {}
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IDaoDepositManager {
    function initialize(address _dao) external;

    function migrateBaseContract(address _newDaoDepositManager) external;

    function deposit(
        address _dealModule,
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) external payable;

    function multipleDeposits(
        address _dealModule,
        uint32 _dealId,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external payable;

    function registerDeposit(
        address _dealModule,
        uint32 _dealId,
        address _token
    ) external;

    function registerDeposits(
        address _dealModule,
        uint32 _dealId,
        address[] calldata _tokens
    ) external;

    function withdraw(
        address _dealModule,
        uint32 _dealId,
        uint32 _depositId,
        address _sender
    )
        external
        returns (
            address,
            address,
            uint256
        );

    function sendToModule(
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) external returns (bool);

    function startVesting(
        uint32 _dealId,
        address _token,
        uint256 _amount,
        uint32 _vestingCliff,
        uint32 _vestingDuration
    ) external;

    function claimVestings() external;

    function verifyBalance(address _token) external view;

    function getDeposit(
        address _dealModule,
        uint32 _dealId,
        uint32 _depositId
    )
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function getAvailableDealBalance(
        address _dealModule,
        uint32 _dealId,
        address _token
    ) external view returns (uint256);

    function getTotalDepositCount(address _dealModule, uint32 _dealId)
        external
        view
        returns (uint256);

    function getWithdrawableAmountOfUser(
        address _dealModule,
        uint32 _dealId,
        address _user,
        address _token
    ) external view returns (uint256);

    function getBalance(address _token) external view returns (uint256);

    function getVestedBalance(address _token) external view returns (uint256);
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