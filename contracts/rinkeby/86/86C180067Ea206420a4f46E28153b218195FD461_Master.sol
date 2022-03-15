// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./IMaster.sol";
import "./ISatellite.sol";

contract Master is IMaster, ISatellite, ILayerZeroReceiver {
    uint16[] internal satelliteChainIds;

    uint16 internal thisChainId;

    mapping(uint16 => uint256) internal counters;
    mapping(uint16 => address) internal satellites;

    modifier onlySatellite(
        uint16 _srcChainId,
        bytes memory _srcAddress
    ) {
        address _srcAddr;
        // hacky way to convert bytes to address
        assembly {
            _srcAddr := mload(add(_srcAddress, 20))
        }
        require(satellites[_srcChainId] == _srcAddr, "Only authorized satellite contracts");
        _;
    }

/*
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
*/

    constructor(uint16 _thisChainId) {
        thisChainId = _thisChainId;
    }

    function updateSatellite(
        uint16 chainId,
        address satelliteAddr,
        bool status
    ) external /* onlyOwner() */ {
        if (status) {
            satellites[chainId] = satelliteAddr;
            satelliteChainIds.push(chainId);
        }
        else {
            delete satellites[chainId];
            for (uint i; i < satelliteChainIds.length; ++i) {
                // find the chainId that we are removing
                if (satelliteChainIds[i] == chainId) {
                    // swap the position of the index we want with the last index
                    satelliteChainIds[i] = satelliteChainIds[satelliteChainIds.length-1];
                    // pop the last index
                    satelliteChainIds.pop();
                }
            }
        }
    }

    function modifyCounter(
        uint8 action, // see libraries/helpers.sol/ModifyAction
        uint256 num
    ) external payable override {
        _updateCounter(action, thisChainId, num);
    }

    function getChainCounter(
        uint16 chainId
    ) external view override returns (uint256 counter) {
        return counters[chainId];
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external override onlySatellite(_srcChainId, _srcAddress) {
        uint256 selector = abi.decode(_payload, (uint16));
        if (selector == 0) { // update chainid counter
            ( , uint8 action, uint256 num) = abi.decode(_payload, (uint16, uint8, uint256));
            _updateCounter(action, _srcChainId, num);
        }
    }

    function _updateCounter(
        uint8 action,
        uint256 chainId,
        uint256 num
    ) internal {
        assembly {
            // store the key in memory
            mstore(0, chainId)
            // store the counter storage slot in memory
            mstore(32, counters.slot)
            // generate the hash of the key+storageslot
            let counterHash := keccak256(0, 64)
            // load the counter in local stack
            let scounter := sload(counterHash)
            // its possible a overflow/underflow happens and causes a revert here
            switch action
                case 0 { scounter := add(scounter, num) }
                case 1 { scounter := sub(scounter, num) }
                case 2 { scounter := mul(scounter, num) }
                case 3 { scounter := div(scounter, num) }
                default {
                    // revert with message
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x496E76616C696420616374696F6E) /* Invalid action */
                    revert(0, 0xe)
                }
            // save the counter as new state
            sstore(counterHash, scounter)
        }
    }
}