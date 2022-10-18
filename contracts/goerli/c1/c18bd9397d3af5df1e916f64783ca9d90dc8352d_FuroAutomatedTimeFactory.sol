// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./base/BaseFuroAutomatedFactory.sol";
import {FuroAutomatedTime} from "./FuroAutomatedTime.sol";

contract FuroAutomatedTimeFactory is BaseFuroAutomatedFactory {
    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------
    FuroStream internal immutable furoStream;
    FuroVesting internal immutable furoVesting;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _furoStream Address of the furoStream contract
    ///@param _furoVesting Address of the furoVesting contract
    ///@param _gelatoOps Address of the gelato OPS to create new tasks
    ///@param _implementation Address of the implementation to clone from
    constructor(
        address _bentoBox,
        address _furoStream,
        address _furoVesting,
        address _gelatoOps,
        address payable _implementation
    ) BaseFuroAutomatedFactory(_bentoBox, _gelatoOps, _implementation) {
        furoStream = FuroStream(_furoStream);
        furoVesting = FuroVesting(_furoVesting);
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    ///@notice Contract creation logic
    function _createFuroAutomated(bytes calldata data)
        internal
        override
        returns (BaseFuroAutomated furoAutomated, bytes memory initData)
    {
        (
            uint256 id,
            address token,
            address withdrawTo,
            uint32 withdrawPeriod,
            bool vesting,
            bool toBentoBox,
            bytes memory taskData
        ) = abi.decode(
                data,
                (uint256, address, address, uint32, bool, bool, bytes)
            );

        furoAutomated = FuroAutomatedTime(
            address(implementation).clone(
                abi.encodePacked(
                    address(bentoBox),
                    address(this),
                    address(ops),
                    ops.gelato(),
                    vesting ? address(furoVesting) : address(furoStream),
                    msg.sender,
                    token,
                    vesting,
                    id
                )
            )
        );

        if (vesting) {
            furoVesting.safeTransferFrom(
                msg.sender,
                address(furoAutomated),
                id
            );
        } else {
            furoStream.safeTransferFrom(msg.sender, address(furoAutomated), id);
        }

        initData = abi.encode(withdrawTo, withdrawPeriod, toBentoBox, taskData);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {IOps} from "./../interfaces/IOps.sol";
import {FuroStream} from "./../furo/FuroStream.sol";
import {FuroVesting} from "./../furo/FuroVesting.sol";
import {BaseFuroAutomated} from "./BaseFuroAutomated.sol";
import {ClonesWithImmutableArgs} from "./../clonesWithImmutableArgs/ClonesWithImmutableArgs.sol";

abstract contract BaseFuroAutomatedFactory {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event CreateFuroAutomated(BaseFuroAutomated indexed clone, bytes data);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    IBentoBoxMinimal internal immutable bentoBox;
    IOps public immutable ops;
    BaseFuroAutomated public immutable implementation;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    ///@param _bentoBox Address of the BentoBox contract
    ///@param _ops Address of the gelato OPS to create new tasks
    ///@param _implementation Address of the implementation to clone from
    constructor(
        address _bentoBox,
        address _ops,
        address payable _implementation
    ) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        ops = IOps(_ops);
        implementation = BaseFuroAutomated(_implementation);
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    ///@notice Deploy a new automated furoAutomated contract clone
    ///@param data Abi encoded variables for the clone creation
    ///@return furoAutomated Address of the clone created
    function createFuroAutomated(bytes calldata data)
        external
        payable
        returns (BaseFuroAutomated furoAutomated)
    {
        bytes memory initData;
        (furoAutomated, initData) = _createFuroAutomated(data);

        furoAutomated.init(initData);

        if (msg.value > 0) {
            furoAutomated.fund{value: msg.value}();
        }

        emit CreateFuroAutomated(furoAutomated, data);
    }

    ///@notice Contract creation logic
    ///@param data abi encoded variables for the clone creation
    ///@return furoAutomated Address of the clone created
    ///@return initData Abi encoded data for initiating the newly created clone
    function _createFuroAutomated(bytes calldata data)
        internal
        virtual
        returns (BaseFuroAutomated furoAutomated, bytes memory initData);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./base/BaseFuroAutomated.sol";
import {FuroStream} from "./furo/FuroStream.sol";
import {FuroVesting} from "./furo/FuroVesting.sol";

contract FuroAutomatedTime is BaseFuroAutomated {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ToEarlyToWithdraw();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event TaskUpdate(
        address withdrawTo,
        uint32 withdrawPeriod,
        bool toBentoBox,
        bytes taskData
    );
    event TaskCancel(address to);
    event TaskExecute(uint256 amount);

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    function vesting() public pure returns (bool) {
        return _getArgBool(140);
    }

    function id() public pure returns (uint256) {
        return _getArgUint256(141);
    }

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    address public withdrawTo;
    uint32 public withdrawPeriod;
    uint128 public lastWithdraw;
    bool public toBentoBox;
    bytes public taskData;

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Init contract variables and set lastWithdraw
    function _init(bytes calldata data) internal override {
        _updateTask(data);
        lastWithdraw = uint128(block.timestamp);
    }

    ///@notice Update contract variables
    function _updateTask(bytes calldata data) internal override {
        (
            address _withdrawTo,
            uint32 _withdrawPeriod,
            bool _toBentoBox,
            bytes memory _taskData
        ) = abi.decode(data, (address, uint32, bool, bytes));
        withdrawTo = _withdrawTo;
        withdrawPeriod = _withdrawPeriod;
        toBentoBox = _toBentoBox;
        taskData = _taskData;
        emit TaskUpdate(_withdrawTo, _withdrawPeriod, _toBentoBox, _taskData);
    }

    ///@notice Cancel Gelato task, send back Furo NFT and send back native token
    function _cancelTask(bytes calldata data) internal override {
        address to = abi.decode(data, (address));

        if (vesting()) {
            FuroVesting(furo()).safeTransferFrom(address(this), to, id());
        } else {
            FuroStream(furo()).safeTransferFrom(address(this), to, id());
        }
        to.call{value: address(this).balance}("");
        emit TaskCancel(to);
    }

    /// -----------------------------------------------------------------------
    /// Keepers functions
    /// -----------------------------------------------------------------------

    ///@notice Check if enough time has passed since last withdraw
    ///@return canExec True if enough time has passed
    ///@return execPayload The amount of shares to withdraw
    function checkTask()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        if (lastWithdraw + withdrawPeriod < block.timestamp) {
            uint256 sharesToWithdraw;
            if (vesting() == false) {
                (, sharesToWithdraw) = FuroStream(furo()).streamBalanceOf(id());
            }
            return (
                true,
                abi.encodeWithSelector(
                    this.executeTask.selector,
                    sharesToWithdraw
                )
            );
        }
    }

    ///@notice Function called by Gelato keepers if enough time has passed since last withdraw
    ///@param execPayload Amount of sharesToWitdraw if it's a stream
    function _executeTask(bytes calldata execPayload) internal override {
        uint256 sharesToWithdraw = abi.decode(execPayload, (uint256));

        //check if not too early
        if (lastWithdraw + withdrawPeriod > block.timestamp) {
            revert ToEarlyToWithdraw();
        }

        if (vesting()) {
            FuroVesting(furo()).withdraw(id(), "", true);
            //can't compute in checkTask as it can increase between check and execution which could result in a very small amount of token burn
            sharesToWithdraw = bentoBox().balanceOf(token(), address(this)); //use less gas than vestBalance()
            _transferToken(
                token(),
                address(this),
                withdrawTo,
                sharesToWithdraw,
                toBentoBox
            );
            if (taskData.length > 0) {
                ITasker(withdrawTo).onTaskReceived(taskData);
            }
        } else {
            FuroStream(furo()).withdrawFromStream(
                id(),
                sharesToWithdraw,
                withdrawTo,
                toBentoBox,
                taskData
            );
        }

        lastWithdraw = uint128(block.timestamp);
        emit TaskExecute(sharesToWithdraw);
    }
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IOps {
    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256, address);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function cancelTask(bytes32 _taskId) external;
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
pragma solidity ^0.8.16;

import {Clone} from "./../clonesWithImmutableArgs/Clone.sol";
import {IBentoBoxMinimal} from "./../interfaces/IBentoBoxMinimal.sol";
import {ITasker} from "./../interfaces/ITasker.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {IOps} from "./../interfaces/IOps.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseFuroAutomated is Clone, ERC721TokenReceiver {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Funded(uint256 amount);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotFactory();
    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    function bentoBox() internal pure returns (IBentoBoxMinimal) {
        return IBentoBoxMinimal(_getArgAddress(0));
    }

    function factory() internal pure returns (address) {
        return _getArgAddress(20);
    }

    function ops() public pure returns (address) {
        return _getArgAddress(40);
    }

    function gelato() public pure returns (address) {
        return _getArgAddress(60);
    }

    function furo() public pure returns (address) {
        return _getArgAddress(80);
    }

    function owner() public pure returns (address) {
        return _getArgAddress(100);
    }

    function token() public pure returns (address) {
        return _getArgAddress(120);
    }

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    bytes32 public taskId; //Gelato OPS taskId hash

    /// -----------------------------------------------------------------------
    /// modifiers
    /// -----------------------------------------------------------------------

    modifier onlyFactory() {
        if (msg.sender != factory()) {
            revert NotFactory();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner()) {
            revert NotOwner();
        }
        _;
    }

    /// -----------------------------------------------------------------------
    /// external functions
    /// -----------------------------------------------------------------------

    ///@notice Called on contract creation by factory to init variables
    ///@param data Abi encoded data for initiating the newly created clone
    function init(bytes calldata data) external onlyFactory {
        _init(data);

        taskId = IOps(ops()).createTaskNoPrepayment(
            address(this),
            this.executeTask.selector,
            address(this),
            abi.encodeWithSelector(this.checkTask.selector),
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE //native token
        );
    }

    ///@notice init() implementation logic
    function _init(bytes calldata data) internal virtual;

    ///@notice Update the contracts data/params
    ///@param data Abi encoded data neeeded to update the contract
    function updateTask(bytes calldata data) external onlyOwner {
        _updateTask(data);
    }

    ///@notice updateTask() implementation logic
    function _updateTask(bytes calldata data) internal virtual;

    ///@notice Cancel the gelato task and send back Furo NFT and Native tokens
    ///@param data Abi encoded data neeeded to cancel the task
    function cancelTask(bytes calldata data) external onlyOwner {
        _cancelTask(data);

        IOps(ops()).cancelTask(taskId);
    }

    ///@notice cancelTask() implementation logic
    function _cancelTask(bytes calldata data) internal virtual;

    ///@notice Gelato keeper function to check if should execute
    function checkTask()
        external
        view
        virtual
        returns (bool canExec, bytes memory execPayload);

    ///@notice Gelato keeper execute function
    ///@param execPayload Abi encoded data neeeded to execute
    function executeTask(bytes calldata execPayload) external {
        _executeTask(execPayload);

        //pay gelato ops
        (uint256 fee, address feeToken) = IOps(ops()).getFeeDetails();
        _transfer(fee, feeToken);
    }

    ///@notice executeTask() logic implementation
    ///@param execPayload Abi encoded data neeeded to execute
    function _executeTask(bytes calldata execPayload) internal virtual;

    ///@notice Fund the contract, should be used over a transfer
    function fund() external payable {
        emit Funded(msg.value);
    }

    ///@notice In case user wants to refill the contract without frontend/directly
    receive() external payable {
        emit Funded(msg.value);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    ///@notice Helper function to transfer/withdraw tokens from bentobox
    ///@param tokenAddress Address of the token to transfer
    ///@param from Address sending the tokens
    ///@param to Address receiving the tokens
    ///@param shares Shares to transfer/deposit
    ///@param toBentoBox True if stays in bentobox, false if withdraws from bentobox
    function _transferToken(
        address tokenAddress,
        address from,
        address to,
        uint256 shares,
        bool toBentoBox
    ) internal {
        if (toBentoBox) {
            bentoBox().transfer(tokenAddress, from, to, shares);
        } else {
            bentoBox().withdraw(tokenAddress, from, to, 0, shares);
        }
    }

    ///@notice Gelato compatible transfer function to pay fees
    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool success, ) = gelato().call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato(), _amount);
        }
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address payable instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x41 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                       | –
                mstore(
                    ptr,
                    0x6100000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                     | –
                // 81          | DUP2                  | r 0 r                   | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
                // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
                // f3          | RETURN                |                         | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (55 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 3d          | RETURNDATASIZE        | 0 0                     | –
                // 3d          | RETURNDATASIZE        | 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
                // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0           | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f33d3d3d3d363d3d376100000000000000000000000000000000
                )
                mstore(add(ptr, 0x13), shl(240, extraLength))

                // 60 0x37     | PUSH1 0x37            | 0x37 extra 0 0 0 0      | [0, cds) = calldata // 0x37 (55) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x37 extra 0 0 0 0  | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x15),
                    0x6037363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x35     | PUSH1 0x35            | 0x35 sucess 0 rds       | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
                // fd          | REVERT                | –                       | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
                // f3          | RETURN                | –                       | [0, rds) = return data
                mstore(
                    add(ptr, 0x34),
                    0x5af43d3d93803e603557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x41;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
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

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (uint256[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        uint256 el;
        arr = new uint256[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            assembly {
                // solhint-disable-next-line no-inline-assembly
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type bool
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgBool(uint256 argOffset) internal pure returns (bool arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ITasker {
    function onTaskReceived(bytes calldata data) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ITokenURIFetcher {
    function fetchTokenURIData(uint256 id)
        external
        view
        returns (string memory);
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}