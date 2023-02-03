// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibChainInfo } from "../libraries/LibChainInfo.sol";
import { IChainInfo } from "../interfaces/IChainInfo.sol";

contract ChainInfoFacet is IChainInfo {
    function chainName() external view returns (string memory) {
        return LibChainInfo.chainName();
    }

    function isProxyChain() external view returns (bool) {
        return LibChainInfo.isProxyChain();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IChainInfo {
    function chainName() external view returns (string memory);

    function isProxyChain() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library LibChainInfo {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("LibChainInfo.storage");

    struct ChainInfoStorage {
        string chainName;
        bool isProxyChain;
    }

    function diamondStorage() internal pure returns (ChainInfoStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function chainName() internal view returns (string memory) {
        return diamondStorage().chainName;
    }

    function setChainName(string memory _chainName) internal {
        diamondStorage().chainName = _chainName;
    }

    function isProxyChain() internal view returns (bool) {
        return diamondStorage().isProxyChain;
    }

    function setIsProxyChain(bool _isProxyChain) internal {
        diamondStorage().isProxyChain = _isProxyChain;
    }
}