// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IFuroAutomatedTimeWithdraw.sol";
import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/IBentoBoxMinimal.sol";
import "./base/FuroStream.sol";
import "./base/FuroVesting.sol";
import "./interfaces/ITasker.sol";

contract FuroAutomatedTimeWithdraw is
    IFuroAutomatedTimeWithdraw,
    KeeperCompatibleInterface,
    ERC721TokenReceiver
{
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotOwner();
    error ToEarlyToWithdraw();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event TaskCreation(uint256 taskId);
    event TaskUpdate(uint256 taskId);
    event TaskCancel(uint256 taskId);
    event TaskExecution(uint256 taskId, uint256 timestamp);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal public immutable bentoBox;
    FuroStream internal immutable furoStream;
    FuroVesting internal immutable furoVesting;

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    ///@notice TaskId => Task struct
    mapping(uint256 => Task) internal tasks;

    ///@notice Task amount, used to increment the mapping
    uint256 internal taskCount;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _furoStream Address of the furoStream contract
    ///@param _furoVesting Address of the furoVesting contract
    constructor(
        address _bentoBox,
        address _furoStream,
        address _furoVesting
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
    }

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Transfer Furo NFT to the contract and create an automated time withdraw task
    ///@param streamId Furo stream/vest id
    ///@param streamToken Furo stream/vest token address
    ///@param streamWithdrawTo Furo stream/vest to withdraw to
    ///@param streamWithdrawPeriod Minimum time between 2 automatic withdraw
    ///@param toBentoBox True if should withdraw to BentoBox
    ///@param vesting True for vesting and false for a stream
    ///@param taskData Calldata to execute on each withdraw on streamWithdrawTo address
    function createTask(
        uint256 streamId,
        address streamToken,
        address streamWithdrawTo,
        uint32 streamWithdrawPeriod,
        bool toBentoBox,
        bool vesting,
        bytes calldata taskData
    ) external {
        if (vesting) {
            if (msg.sender != furoVesting.ownerOf(streamId)) {
                revert NotOwner();
            }
            furoVesting.safeTransferFrom(msg.sender, address(this), streamId);
        } else {
            if (msg.sender != furoStream.ownerOf(streamId)) {
                revert NotOwner();
            }
            furoStream.safeTransferFrom(msg.sender, address(this), streamId);
        }

        tasks[taskCount] = Task({
            streamId: streamId,
            streamToken: streamToken,
            streamOwner: msg.sender,
            streamWithdrawTo: streamWithdrawTo,
            streamWithdrawPeriod: streamWithdrawPeriod,
            streamLastWithdraw: uint128(block.timestamp),
            toBentoBox: toBentoBox,
            vesting: vesting,
            taskData: taskData
        });

        emit TaskCreation(taskCount);
        unchecked {
            taskCount += 1;
        }
    }

    ///@notice Update an existing automated time withdraw task
    ///@param taskId Id of the task
    ///@param streamWithdrawTo Furo stream/vest to withdraw to
    ///@param streamWithdrawPeriod Minimum time between 2 automatic withdraw
    ///@param toBentoBox True if should withdraw to BentoBox
    ///@param taskData Calldata to execute on each withdraw on streamWithdrawTo address
    function updateTask(
        uint256 taskId,
        address streamWithdrawTo,
        uint32 streamWithdrawPeriod,
        bool toBentoBox,
        bytes calldata taskData
    ) external {
        Task storage task = tasks[taskId];
        if (msg.sender != task.streamOwner) {
            revert NotOwner();
        }

        task.streamWithdrawTo = streamWithdrawTo;
        task.streamWithdrawPeriod = streamWithdrawPeriod;
        task.toBentoBox = toBentoBox;
        task.taskData = taskData;

        emit TaskUpdate(taskId);
    }

    ///@notice Cancel an existing automated time withdraw task and send back the Furo NFT
    ///@param taskId Id of the task
    ///@param to Address to send the Furo NFT to
    function cancelTask(uint256 taskId, address to) external {
        Task memory task = tasks[taskId];
        if (msg.sender != task.streamOwner) {
            revert NotOwner();
        }

        if (task.vesting) {
            furoVesting.safeTransferFrom(address(this), to, task.streamId);
        } else {
            furoStream.safeTransferFrom(address(this), to, task.streamId);
        }

        delete tasks[taskId];
        emit TaskCancel(taskId);
    }

    /// -----------------------------------------------------------------------
    /// Keepers functions
    /// -----------------------------------------------------------------------

    ///@notice Function checked by Chainlink keepers on each block to know if a task need to be executed
    ///@param checkData Start and Stop index to loop into the mapping looking for tasks to execute
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 index, uint256 stopIndex) = abi.decode(
            checkData,
            (uint256, uint256)
        );

        while (index < stopIndex) {
            Task memory task = tasks[index];

            if (
                task.streamLastWithdraw != 0 &&
                task.streamLastWithdraw + task.streamWithdrawPeriod <
                block.timestamp
            ) {
                uint256 sharesToWithdraw;
                if (!task.vesting) {
                    (, sharesToWithdraw) = furoStream.streamBalanceOf(
                        task.streamId
                    );
                }
                return (true, abi.encode(index, sharesToWithdraw));
            }

            unchecked {
                index += 1;
            }
        }
    }

    ///@notice Function called by Chainlink keepers if checkUpKeep return true, execute an automated time withdraw task
    ///@param performData TaskId and sharesToWitdraw from the Furo stream/vesting
    function performUpkeep(bytes calldata performData) external {
        (uint256 taskId, uint256 sharesToWithdraw) = abi.decode(
            performData,
            (uint256, uint256)
        );
        Task storage task = tasks[taskId];

        //check if not too early
        if (
            task.streamLastWithdraw != 0 &&
            task.streamLastWithdraw + task.streamWithdrawPeriod >
            block.timestamp
        ) {
            revert ToEarlyToWithdraw();
        }

        if (task.vesting) {
            furoVesting.withdraw(task.streamId, "", true);
            sharesToWithdraw = bentoBox.balanceOf(
                task.streamToken,
                address(this)
            ); //use less gas than vestBalance()
            _transferToken(
                task.streamToken,
                address(this),
                task.streamWithdrawTo,
                sharesToWithdraw,
                task.toBentoBox
            );
            if (task.taskData.length > 0) {
                ITasker(task.streamWithdrawTo).onTaskReceived(task.taskData);
            }
        } else {
            furoStream.withdrawFromStream(
                task.streamId,
                sharesToWithdraw,
                task.streamWithdrawTo,
                task.toBentoBox,
                task.taskData
            );
        }

        task.streamLastWithdraw = uint128(block.timestamp);
        emit TaskExecution(taskId, block.timestamp);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    ///@notice Helper function to transfer/withdraw tokens from bentobox
    ///@param token Address of the token to transfer
    ///@param from Address sending the tokens
    ///@param to Address receiving the tokens
    ///@param shares Shares to transfer/deposit
    ///@param toBentoBox True if stays in bentobox, false if withdraws from bentobox
    function _transferToken(
        address token,
        address from,
        address to,
        uint256 shares,
        bool toBentoBox
    ) internal {
        if (toBentoBox) {
            bentoBox.transfer(token, from, to, shares);
        } else {
            bentoBox.withdraw(token, from, to, 0, shares);
        }
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    ///@notice Getter function to get task infos
    ///@param taskId Id of the task
    ///@return Task Task struct containing all its informations
    function getTask(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Task {
    uint256 streamId;
    address streamToken;
    address streamOwner;
    address streamWithdrawTo;
    uint32 streamWithdrawPeriod; //minimum time between each withdrawal, uint32 allows up to around 136 years + save one slot
    uint128 streamLastWithdraw;
    bool toBentoBox;
    bool vesting; //true if vesting - false if stream
    bytes taskData;
}

interface IFuroAutomatedTimeWithdraw {
    function createTask(
        uint256 streamId,
        address streamToken,
        address streamWithdrawTo,
        uint32 streamWithdrawPeriod,
        bool toBentoBox,
        bool vesting,
        bytes calldata taskData
    ) external;

    function cancelTask(uint256 taskId, address to) external;

    function updateTask(
        uint256 taskId,
        address streamWithdrawTo,
        uint32 streamWithdrawPeriod,
        bool toBentoBox,
        bytes calldata taskData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../interfaces/IFuroStream.sol";

// Use the FuroStreamRouter to create Streams and do not create streams directly.

contract FuroStream is
    IFuroStream,
    ERC721("Furo Stream", "FUROSTREAM"),
    Multicall,
    BoringOwnable
{
    IBentoBoxMinimal public immutable bentoBox;
    address public immutable wETH;

    uint256 public streamIds;

    address public tokenURIFetcher;

    mapping(uint256 => Stream) public streams;

    // custom errors
    error NotSenderOrRecipient();
    error InvalidStartTime();
    error InvalidEndTime();
    error InvalidWithdrawTooMuch();
    error NotSender();
    error Overflow();

    constructor(address _bentoBox, address _wETH) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        wETH = _wETH;
        streamIds = 1000;
        bentoBox.registerProtocol();
    }

    function setTokenURIFetcher(address _fetcher) external onlyOwner {
        tokenURIFetcher = _fetcher;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return ITokenURIFetcher(tokenURIFetcher).fetchTokenURIData(id);
    }

    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        bentoBox.setMasterContractApproval(
            user,
            address(this),
            approved,
            v,
            r,
            s
        );
    }

    function createStream(
        address recipient,
        address token,
        uint64 startTime,
        uint64 endTime,
        uint256 amount, /// @dev in token amount and not in shares
        bool fromBentoBox
    )
        external
        payable
        override
        returns (uint256 streamId, uint256 depositedShares)
    {
        if (startTime < block.timestamp) revert InvalidStartTime();
        if (endTime <= startTime) revert InvalidEndTime();

        depositedShares = _depositToken(
            token,
            msg.sender,
            address(this),
            amount,
            fromBentoBox
        );

        streamId = streamIds++;

        _mint(recipient, streamId);

        streams[streamId] = Stream({
            sender: msg.sender,
            token: token == address(0) ? wETH : token,
            depositedShares: uint128(depositedShares), // @dev safe since we know bento returns u128
            withdrawnShares: 0,
            startTime: startTime,
            endTime: endTime
        });

        emit CreateStream(
            streamId,
            msg.sender,
            recipient,
            token,
            depositedShares,
            startTime,
            endTime,
            fromBentoBox
        );
    }

    function withdrawFromStream(
        uint256 streamId,
        uint256 sharesToWithdraw,
        address withdrawTo,
        bool toBentoBox,
        bytes calldata taskData
    ) external override returns (uint256 recipientBalance, address to) {
        address recipient = _ownerOf[streamId];
        if (msg.sender != streams[streamId].sender && msg.sender != recipient) {
            revert NotSenderOrRecipient();
        }
        Stream storage stream = streams[streamId];
        (, recipientBalance) = _streamBalanceOf(stream);
        if (recipientBalance < sharesToWithdraw)
            revert InvalidWithdrawTooMuch();
        stream.withdrawnShares += uint128(sharesToWithdraw);

        if (msg.sender == recipient && withdrawTo != address(0)) {
            to = withdrawTo;
        } else {
            to = recipient;
        }

        _transferToken(
            stream.token,
            address(this),
            to,
            sharesToWithdraw,
            toBentoBox
        );

        if (taskData.length != 0 && msg.sender == recipient)
            ITasker(to).onTaskReceived(taskData);

        emit Withdraw(
            streamId,
            sharesToWithdraw,
            withdrawTo,
            stream.token,
            toBentoBox
        );
    }

    function cancelStream(uint256 streamId, bool toBentoBox)
        external
        override
        returns (uint256 senderBalance, uint256 recipientBalance)
    {
        address recipient = _ownerOf[streamId];
        if (msg.sender != streams[streamId].sender && msg.sender != recipient) {
            revert NotSenderOrRecipient();
        }
        Stream memory stream = streams[streamId];
        (senderBalance, recipientBalance) = _streamBalanceOf(stream);

        delete streams[streamId];

        _transferToken(
            stream.token,
            address(this),
            recipient,
            recipientBalance,
            toBentoBox
        );
        _transferToken(
            stream.token,
            address(this),
            stream.sender,
            senderBalance,
            toBentoBox
        );

        emit CancelStream(
            streamId,
            senderBalance,
            recipientBalance,
            stream.token,
            toBentoBox
        );
    }

    function getStream(uint256 streamId)
        external
        view
        override
        returns (Stream memory)
    {
        return streams[streamId];
    }

    function streamBalanceOf(uint256 streamId)
        external
        view
        override
        returns (uint256 senderBalance, uint256 recipientBalance)
    {
        return _streamBalanceOf(streams[streamId]);
    }

    function _streamBalanceOf(Stream memory stream)
        internal
        view
        returns (uint256 senderBalance, uint256 recipientBalance)
    {
        if (block.timestamp <= stream.startTime) {
            senderBalance = stream.depositedShares;
            recipientBalance = 0;
        } else if (stream.endTime <= block.timestamp) {
            recipientBalance = stream.depositedShares - stream.withdrawnShares;
            senderBalance = 0;
        } else {
            uint64 timeDelta = uint64(block.timestamp) - stream.startTime;
            uint128 streamed = ((stream.depositedShares * timeDelta) /
                (stream.endTime - stream.startTime));
            recipientBalance = streamed - stream.withdrawnShares;
            senderBalance = stream.depositedShares - streamed;
        }
    }

    function updateSender(uint256 streamId, address sender) external override {
        Stream storage stream = streams[streamId];
        if (msg.sender != stream.sender) revert NotSender();
        stream.sender = sender;
    }

    function updateStream(
        uint256 streamId,
        uint128 topUpAmount,
        uint64 extendTime,
        bool fromBentoBox
    ) external payable override returns (uint256 depositedShares) {
        Stream storage stream = streams[streamId];
        if (msg.sender != stream.sender) revert NotSender();

        depositedShares = _depositToken(
            stream.token,
            stream.sender,
            address(this),
            topUpAmount,
            fromBentoBox
        );

        address recipient = _ownerOf[streamId];

        (uint256 senderBalance, uint256 recipientBalance) = _streamBalanceOf(
            stream
        );

        stream.startTime = uint64(block.timestamp);
        stream.withdrawnShares = 0;
        uint256 newDepositedShares = senderBalance + depositedShares;
        if (newDepositedShares > type(uint128).max) revert Overflow();
        stream.depositedShares = uint128(newDepositedShares);
        stream.endTime += extendTime;

        _transferToken(
            stream.token,
            address(this),
            recipient,
            recipientBalance,
            true
        );

        emit UpdateStream(streamId, topUpAmount, extendTime, fromBentoBox);
    }

    function _depositToken(
        address token,
        address from,
        address to,
        uint256 amount,
        bool fromBentoBox
    ) internal returns (uint256 depositedShares) {
        if (fromBentoBox) {
            depositedShares = bentoBox.toShare(token, amount, false);
            bentoBox.transfer(token, from, to, depositedShares);
        } else {
            (, depositedShares) = bentoBox.deposit{
                value: token == address(0) ? amount : 0
            }(token, from, to, amount, 0);
        }
    }

    function _transferToken(
        address token,
        address from,
        address to,
        uint256 share,
        bool toBentoBox
    ) internal {
        if (toBentoBox) {
            bentoBox.transfer(token, from, to, share);
        } else {
            bentoBox.withdraw(token, from, to, 0, share);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../interfaces/IFuroVesting.sol";

// Use the FuroStreamVesting to create Vesting and do not create vesting directly.

contract FuroVesting is
    IFuroVesting,
    ERC721("Furo Vesting", "FUROVEST"),
    Multicall,
    BoringOwnable
{
    IBentoBoxMinimal public immutable bentoBox;
    address public immutable wETH;

    address public tokenURIFetcher;

    mapping(uint256 => Vest) public vests;

    uint256 public vestIds;

    uint256 public constant PERCENTAGE_PRECISION = 1e18;

    // custom errors
    error InvalidStart();
    error NotOwner();
    error NotVestReceiver();
    error InvalidStepSetting();

    constructor(address _bentoBox, address _wETH) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        wETH = _wETH;
        vestIds = 1;
        bentoBox.registerProtocol();
    }

    function setTokenURIFetcher(address _fetcher) external onlyOwner {
        tokenURIFetcher = _fetcher;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return ITokenURIFetcher(tokenURIFetcher).fetchTokenURIData(id);
    }

    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        bentoBox.setMasterContractApproval(
            user,
            address(this),
            approved,
            v,
            r,
            s
        );
    }

    function createVesting(VestParams calldata vestParams)
        external
        payable
        override
        returns (
            uint256 depositedShares,
            uint256 vestId,
            uint128 stepShares,
            uint128 cliffShares
        )
    {
        if (vestParams.start < block.timestamp) revert InvalidStart();
        if (vestParams.stepPercentage > PERCENTAGE_PRECISION)
            revert InvalidStepSetting();
        if (vestParams.stepDuration == 0 || vestParams.steps == 0)
            revert InvalidStepSetting();

        depositedShares = _depositToken(
            address(vestParams.token),
            msg.sender,
            address(this),
            vestParams.amount,
            vestParams.fromBentoBox
        );
        stepShares = uint128(
            (vestParams.stepPercentage * depositedShares) / PERCENTAGE_PRECISION
        );
        cliffShares = uint128(
            depositedShares - (stepShares * vestParams.steps)
        );

        vestId = vestIds++;
        _mint(vestParams.recipient, vestId);

        vests[vestId] = Vest({
            owner: msg.sender,
            token: vestParams.token == address(0)
                ? IERC20(wETH)
                : IERC20(vestParams.token),
            start: vestParams.start,
            cliffDuration: vestParams.cliffDuration,
            stepDuration: vestParams.stepDuration,
            steps: vestParams.steps,
            cliffShares: cliffShares,
            stepShares: stepShares,
            claimed: 0
        });

        emit CreateVesting(
            vestId,
            IERC20(vestParams.token),
            msg.sender,
            vestParams.recipient,
            vestParams.start,
            vestParams.cliffDuration,
            vestParams.stepDuration,
            vestParams.steps,
            cliffShares,
            stepShares,
            vestParams.fromBentoBox
        );
    }

    function withdraw(
        uint256 vestId,
        bytes calldata taskData,
        bool toBentoBox
    ) external override {
        Vest storage vest = vests[vestId];
        address recipient = _ownerOf[vestId];
        if (recipient != msg.sender) revert NotVestReceiver();
        uint256 canClaim = _vestBalanceOf(vest) - vest.claimed;

        if (canClaim == 0) return;

        vest.claimed += uint128(canClaim);

        _transferToken(
            address(vest.token),
            address(this),
            recipient,
            canClaim,
            toBentoBox
        );

        if (taskData.length != 0) ITasker(recipient).onTaskReceived(taskData);

        emit Withdraw(vestId, vest.token, canClaim, toBentoBox);
    }

    function stopVesting(uint256 vestId, bool toBentoBox) external override {
        Vest memory vest = vests[vestId];

        if (vest.owner != msg.sender) revert NotOwner();

        uint256 amountVested = _vestBalanceOf(vest);
        uint256 canClaim = amountVested - vest.claimed;
        uint256 returnShares = (vest.cliffShares +
            (vest.steps * vest.stepShares)) - amountVested;

        delete vests[vestId];

        _transferToken(
            address(vest.token),
            address(this),
            _ownerOf[vestId],
            canClaim,
            toBentoBox
        );

        _transferToken(
            address(vest.token),
            address(this),
            msg.sender,
            returnShares,
            toBentoBox
        );
        emit CancelVesting(
            vestId,
            returnShares,
            canClaim,
            vest.token,
            toBentoBox
        );
    }

    function vestBalance(uint256 vestId)
        external
        view
        override
        returns (uint256)
    {
        Vest memory vest = vests[vestId];
        return _vestBalanceOf(vest) - vest.claimed;
    }

    function _vestBalanceOf(Vest memory vest)
        internal
        view
        returns (uint256 claimable)
    {
        uint256 timeAfterCliff = vest.start + vest.cliffDuration;

        if (block.timestamp < timeAfterCliff) {
            return claimable;
        }

        uint256 passedSinceCliff = block.timestamp - timeAfterCliff;

        uint256 stepPassed = Math.min(
            vest.steps,
            passedSinceCliff / vest.stepDuration
        );

        claimable = vest.cliffShares + (vest.stepShares * stepPassed);
    }

    function updateOwner(uint256 vestId, address newOwner) external override {
        Vest storage vest = vests[vestId];
        if (vest.owner != msg.sender) revert NotOwner();
        vest.owner = newOwner;
        emit LogUpdateOwner(vestId, newOwner);
    }

    function _depositToken(
        address token,
        address from,
        address to,
        uint256 amount,
        bool fromBentoBox
    ) internal returns (uint256 depositedShares) {
        if (fromBentoBox) {
            depositedShares = bentoBox.toShare(token, amount, false);
            bentoBox.transfer(token, from, to, depositedShares);
        } else {
            (, depositedShares) = bentoBox.deposit{
                value: token == address(0) ? amount : 0
            }(token, from, to, amount, 0);
        }
    }

    function _transferToken(
        address token,
        address from,
        address to,
        uint256 shares,
        bool toBentoBox
    ) internal {
        if (toBentoBox) {
            bentoBox.transfer(token, from, to, shares);
        } else {
            bentoBox.withdraw(token, from, to, 0, shares);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ITasker {
    function onTaskReceived(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./ITokenURIFetcher.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/ITasker.sol";
import "solmate/tokens/ERC721.sol";
import "./../utils/Multicall.sol";
import "./../utils/BoringOwnable.sol";

interface IFuroStream {
    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function createStream(
        address recipient,
        address token,
        uint64 startTime,
        uint64 endTime,
        uint256 amount, /// @dev in token amount and not in shares
        bool fromBento
    ) external payable returns (uint256 streamId, uint256 depositedShares);

    function withdrawFromStream(
        uint256 streamId,
        uint256 sharesToWithdraw,
        address withdrawTo,
        bool toBentoBox,
        bytes memory taskData
    ) external returns (uint256 recipientBalance, address to);

    function cancelStream(uint256 streamId, bool toBentoBox)
        external
        returns (uint256 senderBalance, uint256 recipientBalance);

    function updateSender(uint256 streamId, address sender) external;

    function updateStream(
        uint256 streamId,
        uint128 topUpAmount,
        uint64 extendTime,
        bool fromBentoBox
    ) external payable returns (uint256 depositedShares);

    function streamBalanceOf(uint256 streamId)
        external
        view
        returns (uint256 senderBalance, uint256 recipientBalance);

    function getStream(uint256 streamId) external view returns (Stream memory);

    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool fromBentoBox
    );

    event UpdateStream(
        uint256 indexed streamId,
        uint128 indexed topUpAmount,
        uint64 indexed extendTime,
        bool fromBentoBox
    );

    event Withdraw(
        uint256 indexed streamId,
        uint256 indexed sharesToWithdraw,
        address indexed withdrawTo,
        address token,
        bool toBentoBox
    );

    event CancelStream(
        uint256 indexed streamId,
        uint256 indexed senderBalance,
        uint256 indexed recipientBalance,
        address token,
        bool toBentoBox
    );

    struct Stream {
        address sender;
        address token;
        uint128 depositedShares;
        uint128 withdrawnShares;
        uint64 startTime;
        uint64 endTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./ITokenURIFetcher.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/ITasker.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "./../utils/Multicall.sol";
import "./../utils/BoringOwnable.sol";
import "./IERC20.sol";

interface IFuroVesting {
    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function createVesting(VestParams calldata vestParams)
        external
        payable
        returns (
            uint256 depositedShares,
            uint256 vestId,
            uint128 stepShares,
            uint128 cliffShares
        );

    function withdraw(
        uint256 vestId,
        bytes memory taskData,
        bool toBentoBox
    ) external;

    function stopVesting(uint256 vestId, bool toBentoBox) external;

    function vestBalance(uint256 vestId) external view returns (uint256);

    function updateOwner(uint256 vestId, address newOwner) external;

    struct VestParams {
        address token;
        address recipient;
        uint32 start;
        uint32 cliffDuration;
        uint32 stepDuration;
        uint32 steps;
        uint128 stepPercentage;
        uint128 amount;
        bool fromBentoBox;
    }

    struct Vest {
        address owner;
        IERC20 token;
        uint32 start;
        uint32 cliffDuration;
        uint32 stepDuration;
        uint32 steps;
        uint128 cliffShares;
        uint128 stepShares;
        uint128 claimed;
    }

    event CreateVesting(
        uint256 indexed vestId,
        IERC20 token,
        address indexed owner,
        address indexed recipient,
        uint32 start,
        uint32 cliffDuration,
        uint32 stepDuration,
        uint32 steps,
        uint128 cliffShares,
        uint128 stepShares,
        bool fromBentoBox
    );

    event Withdraw(
        uint256 indexed vestId,
        IERC20 indexed token,
        uint256 indexed amount,
        bool toBentoBox
    );

    event CancelVesting(
        uint256 indexed vestId,
        uint256 indexed ownerAmount,
        uint256 indexed recipientAmount,
        IERC20 token,
        bool toBentoBox
    );

    event LogUpdateOwner(uint256 indexed vestId, address indexed newOwner);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ITokenURIFetcher {
    function fetchTokenURIData(uint256 id)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function multicall(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(
                newOwner != address(0) || renounce,
                "Ownable: zero address"
            );

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(
            msg.sender == _pendingOwner,
            "Ownable: caller != pending owner"
        );

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}