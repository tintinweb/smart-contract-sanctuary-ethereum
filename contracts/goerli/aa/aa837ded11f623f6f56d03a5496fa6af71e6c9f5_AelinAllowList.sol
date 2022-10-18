// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library AelinAllowList {
    struct InitData {
        address[] allowListAddresses;
        uint256[] allowListAmounts;
    }

    struct AllowList {
        address[] allowListAddresses;
        uint256[] allowListAmounts;
        mapping(address => uint256) amountPerAddress;
        bool hasAllowList;
    }

    function initialize(InitData calldata _init, AllowList storage _self) external {
        if (_init.allowListAddresses.length > 0 || _init.allowListAmounts.length > 0) {
            require(
                _init.allowListAddresses.length == _init.allowListAmounts.length,
                "allowListAddresses and allowListAmounts arrays should have the same length"
            );
            _self.allowListAddresses = _init.allowListAddresses;
            _self.allowListAmounts = _init.allowListAmounts;
            for (uint256 i; i < _init.allowListAddresses.length; ++i) {
                _self.amountPerAddress[_init.allowListAddresses[i]] = _init.allowListAmounts[i];
            }
            _self.hasAllowList = true;
            emit AllowlistAddress(_init.allowListAddresses, _init.allowListAmounts);
        }
    }

    event AllowlistAddress(address[] indexed allowListAddresses, uint256[] allowlistAmounts);
}