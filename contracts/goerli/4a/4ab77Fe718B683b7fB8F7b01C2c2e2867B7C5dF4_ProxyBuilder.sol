// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "./GoerliAuthAddresses.sol";

contract AuthHelper is MainnetAuthAddresses {
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

contract MainnetAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xB796e94Ae948399643EF108B64E1b241dB8a31EC;
    address internal constant FACTORY_ADDRESS = 0x4E176206497e66997eDCf3a9d1A7726f347985fD;
    address internal constant ADMIN_ADDR = 0xb1f69ff04C164EbD21aa015061B46e5be2a744e4;
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

import "./GoerliCoreAddresses.sol";

contract CoreHelper is MainnetCoreAddresses {
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

contract MainnetCoreAddresses {
    address internal constant REGISTRY_ADDR = 0x5764DF37135fCA7c246a0eEE9D3BD5DCD381157e;
    address internal constant PROXY_AUTH_ADDR = 0x745e6184f4fd1aa642251B94eA54bB0DC83005C4;
    address internal constant IMMUNA_LOGGER_ADDR = 0xfF37fe44C53338BF92aD4dD6ba89b9d91b7c16bb;
    address internal constant SUB_STORAGE_ADDR = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
    address internal constant STRATEGY_STORAGE_ADDR = 0x82d4E54807125AF8eD82F57cC62e3EA1728b73Ba;
    address constant internal RECIPE_EXECUTOR_ADDR = 0x06063d16b0eA4b8B4fD40eab4576e2649dbAFEB4;
    address constant internal REGISTRY_PROXY_ADDR = 0x46759093D8158db8BB555aC7C6F98070c56169ce;
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