// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "./MainnetAuthAddresses.sol";

contract AuthHelper is MainnetAuthAddresses {
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

contract MainnetAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
    address internal constant ADMIN_ADDR = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9; // IMMUNA_TODO: Use our admin
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "../DS/DSGuard.sol";
import "../DS/DSAuth.sol";

import "./helpers/AuthHelper.sol";

/// @title ProxyPermission Proxy contract which works with DSProxy to give execute permission
contract ProxyPermission is AuthHelper {

    bytes4 public constant EXECUTE_SELECTOR = bytes4(keccak256("execute(address,bytes)"));

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function givePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        if (!guard.canCall(_contractAddr, address(this), EXECUTE_SELECTOR)) {
            guard.permit(_contractAddr, address(this), EXECUTE_SELECTOR);
        }
    }

    /// @notice Called in the context of DSProxy to remove authority of an address
    /// @param _contractAddr Auth address which will be removed from authority list
    function removePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());

        // if there is no authority, that means that contract doesn't have permission
        if (currAuthority == address(0)) {
            return;
        }

        DSGuard guard = DSGuard(currAuthority);
        guard.forbid(_contractAddr, address(this), EXECUTE_SELECTOR);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "./MainnetCoreAddresses.sol";

contract CoreHelper is MainnetCoreAddresses {
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

contract MainnetCoreAddresses {
    address internal constant REGISTRY_ADDR = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address internal constant PROXY_AUTH_ADDR = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
    address internal constant IMMUNA_LOGGER_ADDR = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address internal constant SUB_STORAGE_ADDR = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
    address internal constant STRATEGY_STORAGE_ADDR = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    address constant internal RECIPE_EXECUTOR_ADDR = 0x610178dA211FEF7D417bC0e6FeD39F05609AD788;
    address constant internal REGISTRY_PROXY_ADDR = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
    address constant internal PROXY_BUILDER_ADDR = 0xd977422c9eE9B646f64A4C4389a6C98ad356d8C4;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "../interfaces/IDSProxy.sol";
import "../interfaces/IProxyRegistry.sol";
import "./helpers/CoreHelper.sol";
import "../auth/ProxyPermission.sol";

contract ProxyBuilder is ProxyPermission, CoreHelper {
    function createEOAProxy() public {
        address proxy = address(IProxyRegistry(REGISTRY_PROXY_ADDR).proxies(msg.sender));
        if (address(proxy) == 0x0000000000000000000000000000000000000000) {
            proxy = IProxyRegistry(REGISTRY_PROXY_ADDR).build(msg.sender);
        }
    }

    function getProxy(address user) public view returns (address) {
        address proxy = address(IProxyRegistry(REGISTRY_PROXY_ADDR).proxies(user));
        return proxy;       
    }

    /// @notice Called in the context of DSProxy to authorize an address
    function giveImmunaPermission() public {
    	givePermission(PROXY_AUTH_ADDR);
    }

    /// @notice Called in the context of DSProxy to revoke an address
    function revokeImmunaPermission() public {
    	removePermission(PROXY_AUTH_ADDR);
    }

    // Check if immuna has proxy permission yet
    function checkImmunaPermission(address proxyAddress) public view returns (bool) {
        address currAuthority = address(DSAuth(proxyAddress).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            return false;
        }
        return guard.canCall(PROXY_AUTH_ADDR, address(this), EXECUTE_SELECTOR);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "./DSAuthority.sol";

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "Not authorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

abstract contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

abstract contract DSGuard {
    function canCall(
        address src_,
        address dst_,
        bytes4 sig
    ) public view virtual returns (bool);

    function permit(
        bytes32 src,
        bytes32 dst,
        bytes32 sig
    ) public virtual;

    function forbid(
        bytes32 src,
        bytes32 dst,
        bytes32 sig
    ) public virtual;

    function permit(
        address src,
        address dst,
        bytes32 sig
    ) public virtual;

    function forbid(
        address src,
        address dst,
        bytes32 sig
    ) public virtual;
}

abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

abstract contract IDSProxy {
    // function execute(bytes memory _code, bytes memory _data)
    //     public
    //     payable
    //     virtual
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public payable virtual returns (bytes32);

    function setCache(address _cacheAddr) public payable virtual returns (bool);

    function owner() public view virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

abstract contract IProxyRegistry {
    function proxies(address _owner) public virtual view returns (address);
    function build(address) public virtual returns (address);
}