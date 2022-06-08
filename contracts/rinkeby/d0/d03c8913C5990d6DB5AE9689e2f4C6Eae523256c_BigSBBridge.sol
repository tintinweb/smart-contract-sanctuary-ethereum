pragma solidity 0.8.7;

import "./BigSBBridgeBase.sol";
import "./interfaces.sol";

contract BigSBBridge is BigSBBridgeBase {

    constructor(address _owner) BigSBBridgeBase(_owner) {
        _bridge_address = address(this);
    }

    mapping (bytes6 => mapping (address => uint256)) public allowedClaims;
    address private _bridge_address;

    function sendOutboundTransfer(bytes6 tokenName, uint256 amount) external override notZeroAddress(msg.sender) tokenSupported(tokenName) {
        require(amount > 0, "BigSBBridge: Zero transfer.");

        uint256 transferId = _getTransferId();
        outboundTransfers[transferId] = Transfer(transferId, msg.sender, amount, tokenName);

        require(IERC20(tokenAddressByName[tokenName]).transferFrom(msg.sender, _bridge_address, amount), "BigSBBridge: Token transfer failed");

        emit OutboundTransfer(transferId, msg.sender, amount, tokenName);
    }

    function receiveInboundTransfer(Transfer memory t) internal override notZeroAddress(msg.sender) notZeroAddress(t.account) tokenSupported(t.tokenName) {
        require(t.amount > 0, "BigSBBridge: Zero transfer.");
        require(inboundTransfers[t.id].amount == 0, "BigSBBridge: Transfer already completed.");

        inboundTransfers[t.id] = t;
        allowedClaims[t.tokenName][t.account] += t.amount;

        emit InboundTransfer(t.id, t.account, t.amount, t.tokenName);
    }

    function claim(bytes6 tokenName, uint256 amount) external override notZeroAddress(msg.sender) tokenSupported(tokenName) {
        require(amount > 0, "BigSBBridge: Zero claim.");
        require(allowedClaims[tokenName][msg.sender] >= amount, 'BigSBBridge: Claim too big.');

        allowedClaims[tokenName][msg.sender] -= amount;

        require(IERC20(tokenAddressByName[tokenName]).transfer(msg.sender, amount), "BigSBBridge: Token transfer failed");
        emit TokensClaimed(msg.sender, amount, tokenName);
    }
}