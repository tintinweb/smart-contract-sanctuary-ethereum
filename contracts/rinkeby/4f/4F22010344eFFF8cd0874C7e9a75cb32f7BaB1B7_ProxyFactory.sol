// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./proxy.sol";

contract ProxyFactory {
    event ContractInstantiation(address sender, address instantiation);
    constructor(address _proxyAddress){
        require(_proxyAddress != address(0));
        proxyAddress = _proxyAddress;
    }

    Proxy[] walletProxies;
    address proxyAddress;
    function create()
        public
        returns (Proxy walletProxy)
    {
        bool success;
        walletProxy = new Proxy(proxyAddress);
        (success, ) = address(walletProxy).call(abi.encodeWithSignature("initialize(address)", msg.sender));
        walletProxies.push(walletProxy);
        emit ContractInstantiation(msg.sender, address(walletProxy));
        return walletProxy;
    }

    function update(address newProxy) public {
        require(newProxy != address(0));
        for (uint i = 0; i < walletProxies.length; i++){
            walletProxies[i].updateAddress(newProxy);
        }
        proxyAddress = newProxy;
    }

    function getCreatedWalletProxies() public view returns (address[] memory){
        address[] memory ret = new address[](walletProxies.length);
        for (uint i = 0; i < walletProxies.length; i++) {
            ret[i] = address(walletProxies[i]);
        }
        return ret;
    }
}