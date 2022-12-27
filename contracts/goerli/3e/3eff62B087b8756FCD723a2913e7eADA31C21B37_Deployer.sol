// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract Deployer {

    event Deployed(address addr);

    function deployContract(bytes memory _data) external returns (address) {
        return _deploy(_data);
    }

    function deployASP(
        bytes memory _votingAlgData,
        bytes memory _sidechainPinningBytecode,
        bytes memory _sidechainPinningEncodedParams
    ) public returns (address) {
        address votingAlgAddr = _deploy(_votingAlgData);

        bytes memory sidechainPinningData = abi.encodePacked(
            _sidechainPinningBytecode,
            abi.encode(votingAlgAddr),
            _sidechainPinningEncodedParams
        );
        address sidechainPinningAddr = _deploy(sidechainPinningData);
        return address(sidechainPinningAddr);
    }

    function _deploy(bytes memory _data) private returns (address) {
        address addr;
        assembly {
            addr := create(0, add(_data, 0x20), mload(_data))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr);

        return addr;
    }
}