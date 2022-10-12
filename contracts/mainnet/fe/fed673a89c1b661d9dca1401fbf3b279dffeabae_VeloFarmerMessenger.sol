/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

contract VeloFarmerMessenger {
    ICrossDomainMessenger constant crossDomainMessenger = ICrossDomainMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    address public veloFed;

    address public gov;
    address public pendingGov;
    address public guardian;
    address public chair;

    uint32 public gasLimit = 750_000;

    constructor(address gov_, address chair_, address guardian_, address veloFed_) {
        gov = gov_;
        chair = chair_;
        guardian = guardian_;
        veloFed = veloFed_;
    } 

    modifier onlyGov {
        if (msg.sender != gov) revert OnlyGov();
        _;
    }

    modifier onlyGovOrGuardian {
        if (msg.sender != gov || msg.sender != guardian) revert OnlyGov();
        _;
    }

    modifier onlyPendingGov {
        if (msg.sender != pendingGov) revert OnlyPendingGov();
        _;
    }

    modifier onlyChair {
        if (msg.sender != chair) revert OnlyChair();
        _;
    }

    error OnlyGov();
    error OnlyGovOrGuardian();
    error OnlyPendingGov();
    error OnlyChair();

    //Helper functions

    function sendMessage(bytes memory message) internal {
        crossDomainMessenger.sendMessage(address(veloFed), message, gasLimit);
    }

    //Gov Messaging functions

    function setMaxSlippageDolaToUsdc(uint newSlippage_) public onlyGovOrGuardian {
        sendMessage(abi.encodeWithSignature("setMaxSlippageDolaToUsdc(uint256)", newSlippage_));
    }

    function setMaxSlippageUsdcToDola(uint newSlippage_) public onlyGovOrGuardian {
        sendMessage(abi.encodeWithSignature("setMaxSlippageUsdcToDola(uint256)", newSlippage_));
    }

    function setMaxSlippageLiquidity(uint newSlippage_) public onlyGovOrGuardian {
        sendMessage(abi.encodeWithSignature("setMaxSlippageLiquidity(uint256)", newSlippage_));
    }

    function setPendingGov(address newPendingGov_) public onlyGov {
        sendMessage(abi.encodeWithSignature("setPendingGov(address)", newPendingGov_));
    }

    function claimGov() public onlyGov {
        sendMessage(abi.encodeWithSignature("claimGov()"));
    }

    function changeTreasury(address newTreasury_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeTreasury(address)", newTreasury_));
    }

    function changeChair(address newChair_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeChair(address)", newChair_));
    }

    function changeL2Chair(address newChair_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeL2Chair(address)", newChair_));
    }

    function changeOptiFed(address optiFed_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeOptiFed(address)", optiFed_));
    }

    //Chair messaging functions

    function claimVeloRewards() public onlyChair {
        sendMessage(abi.encodeWithSignature("claimVeloRewards()"));
    }

    function claimRewards(address[] calldata addrs) public onlyChair {
        sendMessage(abi.encodeWithSignature("claimRewards(address)", addrs));
    }

    function swapAndDeposit(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("swapAndDeposit(uint256)", dolaAmount));
    }

    function deposit(uint dolaAmount, uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("deposit(uint256,uint256)", dolaAmount, usdcAmount));
    }

    function withdrawLiquidity(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawLiquidity(uint256)", dolaAmount));
    }

    function withdrawLiquidityAndSwapToDola(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawLiquidityAndSwapToDOLA(uint256)", dolaAmount));
    }

    function withdrawToL1OptiFed(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawToL1OptiFed(uint256)", dolaAmount));
    }

    function withdrawToL1OptiFed(uint dolaAmount, uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawToL1OptiFed(uint256,uint256)", dolaAmount, usdcAmount));
    }

    function withdrawTokensToL1(address l2Token, address to, uint amount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawTokensToL1(address,address,uint256)", l2Token, to, amount));
    }

    function swapUSDCtoDOLA(uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("swapUSDCtoDOLA(uint256)", usdcAmount));
    }

    function swapDOLAtoUSDC(uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("swapDOLAtoUSDC(uint256)", usdcAmount));
    }

    function resign() public onlyChair {
        sendMessage(abi.encodeWithSignature("resign()"));
    }

    //Gov functions

    function setGasLimit(uint32 newGasLimit_) public onlyGov {
        gasLimit = newGasLimit_;
    }

    function setPendingMessengerGov(address newPendingGov_) public onlyGov {
        pendingGov = newPendingGov_;
    }

    function claimMessengerGov() public onlyPendingGov {
        gov = pendingGov;
        pendingGov = address(0);
    }

    function changeMessengerChair(address newChair_) public onlyGov {
        chair = newChair_;
    }
}