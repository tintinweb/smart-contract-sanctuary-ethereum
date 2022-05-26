// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./MultiSignWalletProxy.sol";
import "./IMultiSignWalletFactory.sol";


contract MultiSignWalletFactory is IMultiSignWalletFactory {
    address payable immutable private walletImpl;
    event NewWallet(address indexed wallet);
    bytes4 internal constant _INITIALIZE = bytes4(keccak256(bytes("initialize(address[],uint256,bool,uint256,address[])")));
    constructor(address payable _walletImpl) {
        walletImpl = _walletImpl;
    }

    function create(address[] calldata _owners, uint _required, bytes32 salt, bool _securitySwitch, uint _inactiveInterval, address[] calldata _execptionTokens) public returns (address) {
        MultiSignWalletProxy wallet = new MultiSignWalletProxy{salt: salt}();
        (bool success, bytes memory data) = address(wallet).call(abi.encodeWithSelector(_INITIALIZE, _owners, _required, _securitySwitch, _inactiveInterval, _execptionTokens));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "create wallet failed");
        emit NewWallet(address(wallet));
        return address(wallet);
    }

    function getWalletImpl() external override view returns(address) {
        return walletImpl;
    }
}