// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./NonblockingLzApp.sol";
import "./LzLib.sol";

import "./IWETH.sol";
import "./ITokenBridge.sol";

contract TokenBridge is ITokenBridge, NonblockingLzApp, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint public constant BP_DENOMINATOR = 10000;
    uint8 public constant SHARED_DECIMALS = 6;

    uint16 public aptosChainId;

    uint public bridgeFeeBP;

    mapping(address => uint64) public tvlSDs; // token address => tvl
    mapping(address => bool) public supportedTokens;
    mapping(address => bool) public pausedTokens; // token address => paused
    mapping(address => uint) public ld2sdRates; // token address => rate
    address public weth;

    bool public useCustomAdapterParams;
    bool public globalPaused;
    bool public emergencyWithdrawEnabled;
    uint public emergencyWithdrawTime;

    modifier whenNotPaused(address _token) {
        require(!globalPaused && !pausedTokens[_token], "TokenBridge: paused");
        _;
    }

    modifier emergencyWithdrawUnlocked() {
        require(emergencyWithdrawEnabled && block.timestamp >= emergencyWithdrawTime, "TokenBridge: emergency withdraw locked");
        _;
    }

    constructor(
        address _layerZeroEndpoint,
        uint16 _aptosChainId
    ) NonblockingLzApp(_layerZeroEndpoint) {
        aptosChainId = _aptosChainId;
    }

    function sendToAptos(
        address _token,
        bytes32 _toAddress,
        uint _amountLD,
        LzLib.CallParams calldata _callParams,
        bytes calldata _adapterParams
    ) external payable override whenNotPaused(_token) nonReentrant {
        require(supportedTokens[_token], "TokenBridge: token is not supported");

        // lock token
        _amountLD = _removeDust(_token, _amountLD);
        _amountLD = _lockTokenFrom(_token, msg.sender, _amountLD);

        // add tvl
        uint64 amountSD = _LDtoSD(_token, _amountLD);
        require(amountSD > 0, "TokenBridge: amountSD must be greater than 0");
        tvlSDs[_token] += amountSD;

        // send to aptos
        _sendToken(_token, _toAddress, amountSD, _callParams, _adapterParams, msg.value);
        emit Send(_token, msg.sender, _toAddress, _amountLD);
    }

    function sendETHToAptos(
        bytes32 _toAddress,
        uint _amountLD,
        LzLib.CallParams calldata _callParams,
        bytes calldata _adapterParams
    ) external payable override whenNotPaused(weth) nonReentrant {
        address _weth = weth; // save gas
        require(_weth != address(0) && supportedTokens[_weth], "TokenBridge: ETH is not supported");
        _amountLD = _removeDust(_weth, _amountLD);
        require(_amountLD > 0, "TokenBridge: amount must be greater than 0");
        require(msg.value >= _amountLD, "TokenBridge: fee not enough");

        // wrap eth and add tvl
        IWETH(_weth).deposit{value: _amountLD}();
        uint64 amountSD = _LDtoSD(_weth, _amountLD);
        tvlSDs[_weth] += amountSD;

        // send to aptos
        _sendToken(_weth, _toAddress, amountSD, _callParams, _adapterParams, msg.value - _amountLD);
        emit Send(address(0), msg.sender, _toAddress, _amountLD);
    }

    function quoteForSend(LzLib.CallParams calldata _callParams, bytes calldata _adapterParams)
        external
        view
        returns (uint nativeFee, uint zroFee)
    {
        _checkAdapterParams(_adapterParams);
        bytes memory payload = _encodeSendPayload(address(0), bytes32(0), 0);
        bool payInZRO = _callParams.zroPaymentAddress != address(0);
        return
            lzEndpoint.estimateFees(aptosChainId, address(this), payload, payInZRO, _adapterParams);
    }

    // ---------------------- owner functions ----------------------
    function registerToken(address _token) external onlyOwner {
        require(_token != address(0), "TokenBridge: invalid token address");
        require(!supportedTokens[_token], "TokenBridge: token already registered");

        uint8 localDecimals = _tokenDecimals(_token);
        require(
            localDecimals >= SHARED_DECIMALS,
            "TokenBridge: decimals must be >= SHARED_DECIMALS"
        );

        supportedTokens[_token] = true;
        ld2sdRates[_token] = 10**(localDecimals - SHARED_DECIMALS);
        emit RegisterToken(_token);
    }

    function setBridgeFeeBP(uint _bridgeFeeBP) external onlyOwner {
        require(_bridgeFeeBP <= BP_DENOMINATOR, "TokenBridge: bridge fee > 100%");
        bridgeFeeBP = _bridgeFeeBP;
        emit SetBridgeBP(_bridgeFeeBP);
    }

    function setWETH(address _weth) external onlyOwner {
        require(_weth != address(0), "TokenBridge: invalid token address");
        weth = _weth;
        emit SetWETH(_weth);
    }

    function setGlobalPause(bool _paused) external onlyOwner {
        globalPaused = _paused;
        emit SetGlobalPause(_paused);
    }

    function setTokenPause(address _token, bool _paused) external onlyOwner {
        pausedTokens[_token] = _paused;
        emit SetTokenPause(_token, _paused);
    }

    function setAptosChainId(uint16 _aptosChainId) external onlyOwner {
        aptosChainId = _aptosChainId;
        emit SetAptosChainId(_aptosChainId);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function withdrawFee(
        address _token,
        address _to,
        uint _amountLD
    ) public onlyOwner {
        uint feeLD = accruedFeeLD(_token);
        require(_amountLD <= feeLD, "TokenBridge: fee not enough");

        IERC20(_token).safeTransfer(_to, _amountLD);
        emit WithdrawFee(_token, _to, _amountLD);
    }

    function withdrawTVL(
        address _token,
        address _to,
        uint64 _amountSD
    ) public onlyOwner emergencyWithdrawUnlocked {
        tvlSDs[_token] -= _amountSD;

        uint amountLD = _SDtoLD(_token, _amountSD);
        IERC20(_token).safeTransfer(_to, amountLD);
        emit WithdrawTVL(_token, _to, amountLD);
    }

    function withdrawEmergency(address _token, address _to) external onlyOwner {
        // modifier redundant for extra safety
        withdrawFee(_token, _to, accruedFeeLD(_token));
        withdrawTVL(_token, _to, tvlSDs[_token]);
    }

    function enableEmergencyWithdraw(bool enabled) external onlyOwner {
        emergencyWithdrawEnabled = enabled;
        emergencyWithdrawTime = enabled ? block.timestamp + 1 weeks : 0; // overrides existing lock time
        emit EnableEmergencyWithdraw(enabled, emergencyWithdrawTime);
    }

    // override the renounce ownership inherited by zeppelin ownable
    function renounceOwnership() public override onlyOwner {}

    // receive ETH from WETH
    receive() external payable {}

    function accruedFeeLD(address _token) public view returns (uint) {
        uint tvlLD = _SDtoLD(_token, tvlSDs[_token]);
        return IERC20(_token).balanceOf(address(this)) - tvlLD;
    }

    // ---------------------- internal functions ----------------------
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        require(_srcChainId == aptosChainId, "TokenBridge: invalid source chain id");

        (address token, address to, uint64 amountSD, bool unwrap) = _decodeReceivePayload(_payload);
        require(!globalPaused && !pausedTokens[token], "TokenBridge: paused");
        require(supportedTokens[token], "TokenBridge: token is not supported");

        // sub tvl
        uint64 tvlSD = tvlSDs[token];
        require(tvlSD >= amountSD, "TokenBridge: insufficient liquidity");
        tvlSDs[token] = tvlSD - amountSD;

        // pay fee
        uint amountLD = _SDtoLD(token, amountSD);
        (amountLD, ) = bridgeFeeBP > 0 ? _payFee(amountLD) : (amountLD, 0);

        // redeem token to receiver
        if (token == weth && unwrap) {
            _redeemETHTo(weth, payable(to), amountLD);
            emit Receive(address(0), to, amountLD);
        } else {
            to = to == address(0) ? address(0xdEaD) : to; // avoid failure in safeTransfer()
            IERC20(token).safeTransfer(to, amountLD);
            emit Receive(token, to, amountLD);
        }
    }

    function _redeemETHTo(
        address _weth,
        address payable _to,
        uint _amountLD
    ) internal {
        IWETH(_weth).withdraw(_amountLD);
        _to.transfer(_amountLD);
    }

    function _lockTokenFrom(
        address _token,
        address _from,
        uint _amountLD
    ) internal returns (uint) {
        // support token with transfer fee
        uint balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amountLD);
        uint balanceAfter = IERC20(_token).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function _tokenDecimals(address _token) internal view returns (uint8) {
        (bool success, bytes memory data) = _token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        require(success, "TokenBridge: failed to get token decimals");
        return abi.decode(data, (uint8));
    }

    function _payFee(uint _amountLD) internal view returns (uint amountAfterFee, uint fee) {
        fee = (_amountLD * bridgeFeeBP) / BP_DENOMINATOR;
        amountAfterFee = _amountLD - fee;
    }

    function _sendToken(
        address _token,
        bytes32 _toAddress,
        uint64 _amountSD,
        LzLib.CallParams calldata _callParams,
        bytes calldata _adapterParams,
        uint _fee
    ) internal {
        _checkAdapterParams(_adapterParams);
        bytes memory payload = _encodeSendPayload(_token, _toAddress, _amountSD);
        _lzSend(
            aptosChainId,
            payload,
            _callParams.refundAddress,
            _callParams.zroPaymentAddress,
            _adapterParams,
            _fee
        );
    }

    // send payload: packet type(1) + remote token(32) + receiver(32) + amount(8)
    function _encodeSendPayload(
        address _token,
        bytes32 _toAddress,
        uint64 _amountSD
    ) internal pure returns (bytes memory) {
        bytes32 tokenBytes32 = LzLib.addressToBytes32(_token);
        return
            abi.encodePacked(uint8(PacketType.SEND_TO_APTOS), tokenBytes32, _toAddress, _amountSD);
    }

    // receive payload: packet type(1) + remote token(32) + receiver(32) + amount(8) + unwrap flag(1)
    function _decodeReceivePayload(bytes memory _payload)
        internal
        pure
        returns (
            address token,
            address to,
            uint64 amountSD,
            bool unwrap
        )
    {
        require(_payload.length == 74, "TokenBridge: invalid payload length");
        PacketType packetType = PacketType(uint8(_payload[0]));
        require(packetType == PacketType.RECEIVE_FROM_APTOS, "TokenBridge: unknown packet type");
        assembly {
            token := mload(add(_payload, 33))
            to := mload(add(_payload, 65))
            amountSD := mload(add(_payload, 73))
        }
        unwrap = uint8(_payload[73]) == 1;
    }

    function _checkAdapterParams(bytes calldata _adapterParams) internal view {
        if (useCustomAdapterParams) {
            _checkGasLimit(aptosChainId, uint16(PacketType.SEND_TO_APTOS), _adapterParams, 0);
        } else {
            require(_adapterParams.length == 0, "TokenBridge: _adapterParams must be empty.");
        }
    }

    function _SDtoLD(address _token, uint64 _amountSD) internal view returns (uint) {
        return _amountSD * ld2sdRates[_token];
    }

    function _LDtoSD(address _token, uint _amountLD) internal view returns (uint64) {
        uint amountSD = _amountLD / ld2sdRates[_token];
        require(amountSD <= type(uint64).max, "TokenBridge: amountSD overflow");
        return uint64(amountSD);
    }

    function _removeDust(address _token, uint _amountLD) internal view returns (uint) {
        return _SDtoLD(_token, _LDtoSD(_token, _amountLD));
    }
}