/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Metrics {
    event stored (string device, uint48 metrics, uint32 timestamp);

    struct Metrics {
        string device;
        uint48 metrics;
        uint32 timestamp;
    }

    //Mapping address to an array with files
    mapping(address => Metrics[]) metrics;

    /// @dev Pings the metrics of a device at a given timestamp
    /// @param _device The device where metrics were received
    /// @param _timestamp The timestamp in **seconds**
    function pingMetrics(string memory _device, uint48 _metrics, uint32 _timestamp) public {
        metrics[msg.sender].push(Metrics({device: _device, metrics: _metrics, timestamp: _timestamp}));
        emit stored(_device, _metrics, _timestamp);
    }

    function getFile(uint n) public view returns(string memory, uint48, uint32) {
        Metrics memory metrics = metrics[msg.sender][n];
        return (metrics.device, metrics.metrics, metrics.timestamp);
    }

    function getLength() public view returns(uint) {
        return metrics[msg.sender].length;
    }
}