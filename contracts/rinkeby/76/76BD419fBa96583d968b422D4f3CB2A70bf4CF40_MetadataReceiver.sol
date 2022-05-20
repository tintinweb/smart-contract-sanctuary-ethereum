//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IMetadata.sol";

contract MetadataReceiver is IMetadataReceiver {
    constructor() {}

    function emitBytes(bytes calldata metadata) external override {
        emit MetadataReceived(msg.sender, metadata);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMetadataReceiver {
    event MetadataReceived(address indexed sender, bytes metadata);

    function emitBytes(bytes calldata metadata) external;
}