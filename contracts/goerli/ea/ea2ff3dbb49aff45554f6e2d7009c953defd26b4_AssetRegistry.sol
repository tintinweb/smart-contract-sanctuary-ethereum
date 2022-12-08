// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
pragma solidity ^0.8.0;

import "tinlake-auth/auth.sol";

interface IAssetNFT {
    function mintTo(address usr) external returns (uint256);
}

contract AssetRegistry is Auth {
    IAssetNFT assets;

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "assetNFT") assets = IAssetNFT(addr);
        else revert();
    }

    function mint(address _to) public auth returns (uint256) {
        return assets.mintTo(_to);
    }
}