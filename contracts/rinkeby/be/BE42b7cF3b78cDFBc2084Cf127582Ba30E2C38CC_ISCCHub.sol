// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @dev Required interface of an ISCC Hub compliant contract.
 */
interface IISCCHub {
  function announce(string calldata iscc, string calldata url, string calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IISCCHub.sol";

contract ISCCHub is IISCCHub {

  event IsccDeclaration(string iscc, string url, string message, address declarer, address registrar);

  function announce(string calldata iscc, string calldata url, string calldata message) external override {
    require(tx.origin != msg.sender, "ISCCHub: announce() can only be called by Smart Contracts");
    require(bytes(iscc).length > 0, "ISCCHub: ISCC CODE can not be empty");
    require(bytes(iscc).length <= 96, "ISCCHub: ISCC CODE can not be larger than 96 bytes");
    require(bytes(url).length <= 128, "ISCCHub: ISCC URL is can not be larger than 128 bytes");
    require(bytes(message).length <= 128, "ISCCHub: ISCC MESSAGE can not be larger than 128 bytes");
    emit IsccDeclaration(iscc, url, message, tx.origin, msg.sender);
  }

}