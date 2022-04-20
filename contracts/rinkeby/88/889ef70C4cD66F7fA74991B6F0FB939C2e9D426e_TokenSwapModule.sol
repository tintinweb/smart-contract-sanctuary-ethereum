// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "../ModuleBaseWithFee.sol";

/**
 * @title                   PrimeDeals Token Swap Module
 * @notice                  Smart contract to handle token swap
                            interactions for PrimeDeals
 */
contract TokenSwapModule is ModuleBaseWithFee {
    uint32 lastDealId;
    // mapping of token swaps where the key is a dealId
    mapping(uint32 => TokenSwap) public tokenSwaps;
    /// Metadata => deal ID
    mapping(bytes32 => uint32) public metadataToDealId;

    /**
     * @dev
     * pathFrom Description:
     * Used to storing how many tokens does each DAO send to the module
     *
     * Example on how the values are stored:
     * token -> DAO -> amount
     * [[123, 0, 123], [0, 123, 0]]
     * token 1: DAO 1 sends 123, DAO 2 sends 0, DAO 3 sends 123, etc.
     *
     * pathTo Description:
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
        /// The participating DAOs
        address[] daos;
        /// The tokens involved in the swap
        address[] tokens;
        /// The token flow from the DAOs to the module, see above
        uint256[][] pathFrom;
        /// The token flow from the module to the DAO, see above
        uint256[][] pathTo;
        /// Amount of time in seconds the token swap can be executed
        uint32 deadline;
        /// Unix timestamp of the execution
        uint32 executionDate;
        /// Hash of the deal information.
        bytes32 metadata;
        // boolean to check if the deal has been executed
        bool isExecuted;
    }

    /**
     * @notice              This event is emitted when a token swap is created
     * @param module        Address of this module
     * @param dealId        Deal id for the created token swap
     * @param metadata      Unique ID that is generated throught the Prime Deals frontend
     * @param daos          Array containing the DAOs that are involed in creating the token swap
     * @param tokens        Array containing the tokens that are involed in creating the token swap
     * @param pathFrom      Two-dimensional array containing the tokens flowing from the
                            DAOs into the module
     * @param pathTo        Two-dimensional array containing the tokens flowing from the
                            module to the DAOs
     * @param deadline      The amount of time between the creation of the swap and the time when
                            it can no longer be executed, in seconds
     */
    event TokenSwapCreated(
        address indexed module,
        uint32 indexed dealId,
        bytes32 indexed metadata,
        address[] daos,
        address[] tokens,
        uint256[][] pathFrom,
        uint256[][] pathTo,
        uint32 deadline
    );

    /**
     * @notice              This event is emitted when a token swap is executed
     * @param module        Address of this module
     * @param dealId        Deal id for the executed token swap
     * @param metadata      Unique ID that is generated throught the Prime Deals frontend
     */
    event TokenSwapExecuted(
        address indexed module,
        uint32 indexed dealId,
        bytes32 indexed metadata
    );

    // solhint-disable-next-line no-empty-blocks
    constructor(address _dealManager) ModuleBaseWithFee(_dealManager) {}

    /**
      * @notice             Creates a new token swap action
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _pathFrom    Two-dimensional array containing the tokens flowing from the
                            DAOs into the module:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _pathTo      Two-dimensional array containing the tokens flowing from the
                            module to the DAOs:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _metadata    Unique ID that is generated throught the Prime Deals frontend
      * @param _deadline    The amount of time between the creation of the swap and the time when
                            it can no longer be executed, in seconds
      * @return uint32      The dealId of the new token swap
    */
    function _createSwap(
        address[] memory _daos,
        address[] memory _tokens,
        uint256[][] memory _pathFrom,
        uint256[][] memory _pathTo,
        bytes32 _metadata,
        uint32 _deadline
    ) internal returns (uint32) {
        require(_metadata != "", "TokenSwapModule: Error 101");
        require(_metadataDoesNotExist(_metadata), "TokenSwapModule: Error 203");
        require(_daos.length >= 2, "TokenSwapModule: Error 204");
        require(_tokens.length != 0, "TokenSwapModule: Error 205");
        require(_deadline > 0, "TokenSwapModule: Error 101");

        // Check outer arrays
        uint256 pathFromLen = _pathFrom.length;
        require(
            _tokens.length == pathFromLen && pathFromLen == _pathTo.length,
            "TokenSwapModule: Error 102"
        );

        // Check inner arrays
        uint256 daosLen = _daos.length;
        for (uint256 i; i < pathFromLen; ++i) {
            require(
                _pathFrom[i].length == daosLen &&
                    _pathTo[i].length == daosLen << 2,
                "TokenSwapModule: Error 102"
            );
        }

        TokenSwap memory ts = TokenSwap(
            _daos,
            _tokens,
            _pathFrom,
            _pathTo,
            // solhint-disable-next-line not-rely-on-time
            uint32(block.timestamp) + _deadline,
            0,
            _metadata,
            false
        );

        lastDealId = lastDealId + 1;

        tokenSwaps[lastDealId] = ts;

        metadataToDealId[_metadata] = lastDealId;

        emit TokenSwapCreated(
            address(this),
            lastDealId,
            _metadata,
            _daos,
            _tokens,
            _pathFrom,
            _pathTo,
            _deadline
        );
        return lastDealId;
    }

    /**
      * @notice             Create a new token swap action and automatically
                            creates Dao Deposit Manager for each DAO that does not have one
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _pathFrom    Two-dimensional array containing the tokens flowing from the
                            DAOs into the module:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _pathTo      Two-dimensional array containing the tokens flowing from the
                            module to the DAOs:
                              - First array level is for each token
                              - Second array level is for each dao
                              - Detailed overview on how to configure the array can be found at the
                                TokenSwap struct description
      * @param _metadata    Unique ID that is generated throught the Prime Deals frontend
      * @param _deadline    The amount of time between the creation of the swap and the time when
                            it can no longer be executed, in seconds
      * @return uin32       The dealId of the new token swap
    */
    function createSwap(
        address[] calldata _daos,
        address[] calldata _tokens,
        uint256[][] calldata _pathFrom,
        uint256[][] calldata _pathTo,
        bytes32 _metadata,
        uint32 _deadline
    ) external returns (uint32) {
        for (uint256 i; i < _daos.length; ++i) {
            address dao = _daos[i];
            if (!dealManager.hasDaoDepositManager(dao)) {
                dealManager.createDaoDepositManager(dao);
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
      * @notice             Checks whether a token swap action can be executed, which is the case
                            if all DAOs have deposited
      * @param _dealId      The dealId of the action (key to the mapping)
      * @return bool        A bool flag indiciating whether the action can be executed
    */
    function checkExecutability(uint32 _dealId)
        public
        view
        validDealId(_dealId)
        returns (bool)
    {
        TokenSwap memory ts = tokenSwaps[_dealId];
        if (hasDealExpired(_dealId)) {
            return false;
        }

        address[] memory t = ts.tokens;
        for (uint256 i; i < t.length; ++i) {
            uint256[] memory p = ts.pathFrom[i];
            for (uint256 j; j < p.length; ++j) {
                if (p[j] == 0) {
                    continue;
                }
                // for each token and each pathFrom entry for this
                // token, check whether the corresponding DAO
                // has deposited the corresponding amount into their
                // deposit contract
                uint256 bal = IDaoDepositManager(
                    dealManager.getDaoDepositManager(ts.daos[j])
                ).getAvailableDealBalance(address(this), _dealId, t[i]);
                if (bal < p[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @notice              Executes a token swap action
     * @param _dealId       The dealId of the action (key to the mapping)
     */
    function executeSwap(uint32 _dealId)
        external
        validDealId(_dealId)
        isNotExecuted(_dealId)
    {
        TokenSwap storage ts = tokenSwaps[_dealId];

        require(checkExecutability(_dealId), "TokenSwapModule: Error 265");

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
        for (uint256 i; i < ts.tokens.length; ++i) {
            require(
                amountsIn[i] == amountsOut[i],
                "TokenSwapModule: Error 103"
            );
        }

        ts.isExecuted = true;
        // solhint-disable-next-line not-rely-on-time
        ts.executionDate = uint32(block.timestamp);
        emit TokenSwapExecuted(address(this), _dealId, ts.metadata);
    }

    /**
      * @notice             Distributes the tokens based on the supplied information to the DAOs
                            or their vesting contracts
      * @param _ts          TokenSwap object containing all the information of the action
      * @param _dealId      The dealId of the action (key to the mapping)
      * @return amountsOut  The two min values for the token amounts _ts
    */
    function _distributeTokens(TokenSwap memory _ts, uint32 _dealId)
        internal
        returns (uint256[] memory amountsOut)
    {
        amountsOut = new uint256[](_ts.tokens.length);
        // Distribute tokens from the module
        for (uint256 i; i < _ts.tokens.length; ++i) {
            uint256[] memory pt = _ts.pathTo[i];
            address token = _ts.tokens[i];
            for (uint256 k; k < pt.length >> 2; ++k) {
                // every 4 values, the values for a new dao start
                // value 0 = instant amount
                // value 1 = vested amount
                // value 2 = vesting cliff
                // value 3 = vesting duration
                uint256 instant = pt[k << 2];
                uint256 vested = pt[(k << 2) + 1];

                if (instant > 0) {
                    amountsOut[i] += instant;
                    _transferWithFee(token, _ts.daos[k], instant);
                }

                if (vested > 0) {
                    amountsOut[i] += vested;
                    uint256 amount = _payFeeAndReturnRemainder(token, vested);
                    address daoDepositManager = dealManager
                        .getDaoDepositManager(_ts.daos[k]);
                    if (token != address(0)) {
                        _approveDaoDepositManager(token, _ts.daos[k], amount);
                    }

                    IDaoDepositManager(daoDepositManager).startVesting{
                        value: token == address(0) ? amount : 0
                    }(
                        _dealId,
                        token,
                        amount, // amount
                        uint32(pt[(k << 2) + 2]), // start
                        uint32(pt[(k << 2) + 3]) // end
                    );
                }
            }
        }
    }

    /**
     * @notice              Returns the TokenSwap struct associated with the metadata
     * @param _metadata     Unique ID that is generated throught the Prime Deals frontend
     * @return swap         Token swap struct associated with the metadata
     */
    function getTokenswapFromMetadata(bytes32 _metadata)
        public
        view
        returns (TokenSwap memory swap)
    {
        return tokenSwaps[metadataToDealId[_metadata]];
    }

    /**
     * @notice              Checks if the deal has been expired
     * @param _dealId       The dealId of the action (key to the mapping)
     * @return bool         A bool flag indiciating whether token swap has expired
     */
    function hasDealExpired(uint32 _dealId)
        public
        view
        override
        validDealId(_dealId)
        returns (bool)
    {
        TokenSwap memory swap = tokenSwaps[_dealId];
        return
            swap.isExecuted ||
            // solhint-disable-next-line not-rely-on-time
            swap.deadline < uint32(block.timestamp);
    }

    /**
     * @notice              Checks if the given metadata is Unique, and not already used
     * @param _metadata     Unique ID that is generated throught the Prime Deals frontend
     * @return bool         A bool flag indiciating whether the metadata is unique
     */
    function _metadataDoesNotExist(bytes32 _metadata)
        internal
        view
        returns (bool)
    {
        TokenSwap memory ts = getTokenswapFromMetadata(_metadata);
        return ts.metadata == 0;
    }

    /**
     * @notice              Modifier that validates if the given deal ID is valid
     * @param _dealId       The dealId of the action (key to the mapping)
     */
    modifier validDealId(uint32 _dealId) {
        require(
            tokenSwaps[_dealId].metadata != 0,
            "TokenSwapModule: Error 207"
        );
        _;
    }

    /**
     * @notice              Modifier that validates if token swap has not been executed
     * @param _dealId       The dealId of the action (key to the mapping)
     */
    modifier isNotExecuted(uint32 _dealId) {
        require(!tokenSwaps[_dealId].isExecuted, "TokenSwapModule: Error 266");
        _;
    }

    fallback() external payable {}

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./ModuleBase.sol";

/**
 * @title                   PrimeDeals Module Base Fee Extension
 * @notice                  Smart contract to extend the module
                            base with a fee mechanim
 */
contract ModuleBaseWithFee is ModuleBase {
    /// Wallet that is receiving the fees
    address public feeWallet;
    /// Fee in basis points (100% = 10000)
    uint32 public feeInBasisPoints;
    // Max fee 20%
    // solhint-disable-next-line var-name-mixedcase
    uint32 public immutable MAX_FEE = 2000;

    // Percentage precision to calculate the fee
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BPS = 10000;

    /**
     * @notice              Constructor
     * @param _dealManager  The address of Dealmanager implementation
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _dealManager) ModuleBase(_dealManager) {}

    /**
     * @notice              This event is emitted when the fee wallet address is updated
     * @param oldFeeWallet  Address of the old fee wallet
     * @param newFeeWallet  Address of the new fee wallet
     */
    event FeeWalletChanged(
        address indexed oldFeeWallet,
        address indexed newFeeWallet
    );

    /**
     * @notice              This event is emitted when the fee is updated
     * @param oldFee        Old fee amount in basis points (1% = 100)
     * @param newFee        New fee in basis points (1% = 100) that is updated
     */
    event FeeChanged(uint32 indexed oldFee, uint32 indexed newFee);

    /**
     * @notice              Sets a new fee wallet
     * @param _feeWallet    Address of the new fee wallet
     * @dev                 The fee system will be inactive if the feeWallet
                            is set to a zero-address
     */
    function setFeeWallet(address _feeWallet)
        external
        onlyDealManagerOwner(msg.sender)
    {
        require(
            _feeWallet != address(0) && _feeWallet != address(this),
            "ModuleBaseWithFee: Error 100"
        );
        if (feeWallet != _feeWallet) {
            feeWallet = _feeWallet;
            emit FeeWalletChanged(feeWallet, _feeWallet);
        }
    }

    /**
     * @notice                      Sets a new fee
     * @param _feeInBasisPoints     Fee amount in basis points (1% = 100)
     */
    function setFee(uint32 _feeInBasisPoints)
        external
        onlyDealManagerOwner(msg.sender)
    {
        require(_feeInBasisPoints <= MAX_FEE, "ModuleBaseWithFee: Error 264");
        if (feeInBasisPoints != _feeInBasisPoints) {
            feeInBasisPoints = _feeInBasisPoints;
            emit FeeChanged(feeInBasisPoints, _feeInBasisPoints);
        }
    }

    /**
     * @notice              Pays the fee in a token and returns the remainder
     * @param _token        Token in which the transfer happens
     * @param _amount       Amount of the transfer
     * @return uint256      Remaining amount after the fee payment
     */
    function _payFeeAndReturnRemainder(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        if (feeWallet != address(0) && feeInBasisPoints > 0) {
            uint256 fee = (_amount * feeInBasisPoints) / BPS;
            _transfer(_token, feeWallet, fee);

            return _amount - fee;
        }
        return _amount;
    }

    /**
     * @notice                  Transfers a token amount with automated fee payment
     * @param _token            Token in which the transfer happens
     * @param _to               Target of the transfer
     * @param _amount           Amount of the transfer
     * @return amountAfterFee   The amount minus the fee
     */
    function _transferWithFee(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountAfterFee) {
        amountAfterFee = _payFeeAndReturnRemainder(_token, _amount);
        _transfer(_token, _to, amountAfterFee);
    }

    /**
     * @notice                  Transfers a token amount from someone with automated fee payment
     * @param _token            Token in which the transfer happens
     * @param _from             Source of the transfer
     * @param _to               Target of the transfer
     * @param _amount           Amount of the transfer
     * @return amountAfterFee   The amount minus the fee
     */
    function _transferFromWithFee(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountAfterFee) {
        // if the transfer from does not touch this contract, we first
        // need to transfer it here, pay the fee, and then pass it on
        // if that is not the case, we can do the regular transferFrom
        if (_to != address(this)) {
            _transferFrom(_token, _from, address(this), _amount);
            amountAfterFee = _transferWithFee(_token, _to, _amount);
        } else {
            _transferFrom(_token, _from, _to, _amount);
            amountAfterFee = _payFeeAndReturnRemainder(_token, _amount);
        }
    }

    /**
     * @notice              Modifier that validates that the msg.sender
                            is the DealManager contract
     * @param _sender       Msg.sender of the function that is called
     */
    modifier onlyDealManagerOwner(address _sender) {
        require(_sender == dealManager.owner(), "ModuleBaseWithFee: Error 221");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IDaoDepositManager.sol";
import "../interfaces/IDealManager.sol";

/**
 * @title                   PrimeDeals Module Base
 * @notice                  Smart contract to serve as the
                            basis for each module
 */
contract ModuleBase {
    /// Address of the DealManager implementation
    IDealManager public immutable dealManager;

    /**
     * @notice              Constructor
     * @param _dealManager  The address of DealManager implementation
     */
    constructor(address _dealManager) {
        require(_dealManager != address(0), "ModuleBase: Error 100");
        dealManager = IDealManager(_dealManager);
    }

    /**
      * @notice             Sends tokens from a DAO deposit manager to the module
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
        require(_path.length == _tokens.length, "ModuleBase: Error 102");
        for (uint256 i; i < _tokens.length; ++i) {
            uint256[] memory tokenPath = _path[i];
            require(tokenPath.length == _daos.length, "ModuleBase: Error 102");
            for (uint256 j; j < tokenPath.length; ++j) {
                uint256 daoAmount = tokenPath[j];
                if (daoAmount > 0) {
                    amountsIn[i] += daoAmount;
                    IDaoDepositManager(
                        dealManager.getDaoDepositManager(_daos[j])
                    ).sendToModule(_dealId, _tokens[i], daoAmount);
                }
            }
        }
    }

    /**
     * @notice              Calls the approval function of a token
     * @param _token        Address of the token
     * @param _to           Target of the approval
     * @param _amount       Amount to be approved
     */
    function _approveToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(IERC20(_token).approve(_to, _amount), "ModuleBase: Error 243");
    }

    /**
     * @notice              Calls the approval function of a token
                            for the deposit manager of a DAO
     * @param _token        Address of the token
     * @param _dao          DAO whose deposit manager is the target
     * @param _amount       Amount to be approved
     */
    function _approveDaoDepositManager(
        address _token,
        address _dao,
        uint256 _amount
    ) internal {
        _approveToken(_token, dealManager.getDaoDepositManager(_dao), _amount);
    }

    /**
     * @notice              Transfers an amount of tokens
     * @param _token        Address of the token
     * @param _to           Target of the transfer
     * @param _amount       Amount to be sent
     */
    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token != address(0)) {
            try IERC20(_token).transfer(_to, _amount) returns (bool success) {
                require(success, "ModuleBase: Error 241");
            } catch {
                revert("ModuleBase: Error 241");
            }
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (bool sent, ) = _to.call{value: _amount}("");
            require(sent, "ModuleBase: Error 242");
        }
    }

    /**
     * @notice              Transfers an amount of tokens from an address
     * @param _token        Address of the token
     * @param _from         Source of the transfer
     * @param _to           Target of the transfer
     * @param _amount       Amount to be sent
     */
    function _transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_token != address(0), "ModuleBase: Error 263");

        try IERC20(_token).transferFrom(_from, _to, _amount) returns (
            bool success
        ) {
            require(success, "ModuleBase: Error 241");
        } catch {
            revert("ModuleBase: Error 241");
        }
    }

    /**
     * @notice              Checks if the deal has been expired
     * @param _dealId       The dealId of the action (position in the array)
     * @return bool         A bool flag indiciating whether deal has expired
     */
    function hasDealExpired(uint32 _dealId)
        public
        view
        virtual
        returns (bool)
    // solhint-disable-next-line no-empty-blocks
    {

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IDaoDepositManager {
    function dealManager() external returns (address);

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
    ) external;

    function startVesting(
        uint32 _dealId,
        address _token,
        uint256 _amount,
        uint32 _vestingCliff,
        uint32 _vestingDuration
    ) external payable;

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

    function getWithdrawableAmountOfDepositor(
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