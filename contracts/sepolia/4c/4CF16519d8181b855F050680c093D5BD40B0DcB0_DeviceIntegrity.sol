/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DeviceIntegrity {
    struct StaticDevice {
        string networkInterface;
        string hostname;
        string osArchitecture;
        string logicalCPU;
        string osPlatform;
        string osVersion;
        string osRelease;
        string macAddress;
        string firmwareVersion;
        string userPassPhrase;
        string uuID;
    }

    struct DynamicParameters {
        uint256 minAvailableMemory;
        uint256 maxAvailableMemory;
        uint256 minCpuUsage;
        uint256 maxCpuUsage;
        uint256 minCpuPercentage;
        uint256 maxCpuPercentage;
        uint256 minNetworkBandwidth;
        uint256 maxNetworkBandwidth;
    }
    struct VerifyDynamicParameter{
        uint256 availableMemory;
        uint256 cpuUsage;
        uint256 cpuPercentage;
        uint256 networkBandwidth;

    }

    struct DeviceInfo {
        StaticDevice staticParams;
        DynamicParameters dynamicParams;
    }

    event Log(DeviceInfo device);

    mapping(bytes32 => DeviceInfo) public deviceInfo;
    mapping(bytes32 => bytes32) public deviceDNA;
    mapping(bytes32 => bool) public deviceExists;

    DeviceInfo[] devices;


    function generateDeviceDNA(
        bytes32 deviceId,
        StaticDevice memory staticParams
    ) public pure returns (bytes32) {
        bytes memory dna = abi.encodePacked(
            staticParams.networkInterface,
            staticParams.hostname,
            staticParams.osArchitecture,
            staticParams.logicalCPU,
            staticParams.osPlatform,
            staticParams.osVersion,
            staticParams.osRelease,
            staticParams.macAddress,
            staticParams.firmwareVersion,
            staticParams.userPassPhrase,
            staticParams.uuID
        );

        return keccak256(abi.encodePacked(dna, deviceId));
    }
    
    //for json
    function storeDevices(
        bytes32[] memory deviceIds,
        StaticDevice[] memory staticParams,
        DynamicParameters[] memory dynamicParams
    ) public {
        require(
            deviceIds.length == staticParams.length &&
                deviceIds.length == dynamicParams.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < deviceIds.length; i++) {
            storeDevice(deviceIds[i], staticParams[i], dynamicParams[i]);
        }
    }

    function verifyDeviceDNA(
        bytes32 deviceId,
        bytes32 _deviceDNA
    ) public view returns (bool) {
        return _deviceDNA == deviceDNA[deviceId];
    }

    function storeDevice(
        bytes32 deviceId,
        StaticDevice memory staticParams,
        DynamicParameters memory dynamicParams
    ) public {
        require(!deviceExists[deviceId], "Device ID already exists");

        DeviceInfo memory info;
        info.staticParams = staticParams;
        info.dynamicParams = dynamicParams;
        // being saved into blockchain
        deviceInfo[deviceId] = info;
        emit Log(info);
        devices.push(info);
        deviceDNA[deviceId] = generateDeviceDNA(
            deviceId,
            staticParams
        );
        deviceExists[deviceId] = true;
    }

    function checkDeviceIntegrity(
        bytes32 deviceId,
        StaticDevice memory staticParams,
        VerifyDynamicParameter memory verifydynamicParams
    ) public view returns (bool) {
        require(deviceExists[deviceId], "Device ID does not exist");

        DeviceInfo memory stored_device_info = deviceInfo[deviceId];
        //DynamicParameters memory dynamic_parameter;

         require(
            verifydynamicParams.availableMemory >= stored_device_info.dynamicParams.minAvailableMemory &&
                verifydynamicParams.availableMemory <=
                stored_device_info.dynamicParams.maxAvailableMemory,
            "Available memory is out of range"
        );
        require(
            verifydynamicParams.cpuUsage >= stored_device_info.dynamicParams.minCpuUsage &&
                verifydynamicParams.cpuUsage <= stored_device_info.dynamicParams.maxCpuUsage,
            "CPU usage is out of range"
        );
        require(
            verifydynamicParams.cpuPercentage >= stored_device_info.dynamicParams.minCpuPercentage &&
                verifydynamicParams.cpuPercentage <= stored_device_info.dynamicParams.maxCpuPercentage,
            "CPU percentage is out of range"
        );
        require(
            verifydynamicParams.networkBandwidth >= stored_device_info.dynamicParams.minNetworkBandwidth &&
                verifydynamicParams.networkBandwidth <= stored_device_info.dynamicParams.maxNetworkBandwidth,
            "NW bandwidth is out of range"
        );

        return
            verifyDeviceDNA(
                deviceId,
                generateDeviceDNA(deviceId, staticParams)
            );
    }

    function getDevices() public view returns (DeviceInfo[] memory) {
        return devices;
    }
}