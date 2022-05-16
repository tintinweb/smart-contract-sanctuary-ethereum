// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../interfaces/IFNFTHandler.sol";

contract FNFTHandlerMigrator {

    address private immutable FNFT_HANDLER;
    address private immutable OWNER;

    constructor(address _handler) {
        FNFT_HANDLER = _handler;
        OWNER = msg.sender;
    }

    function batchMint(address[][] memory recipients, uint[][] memory balances, uint[] memory ids, uint[] memory supplies) external {
        require(msg.sender == OWNER, "!AUTH");
        for(uint i = 0; i < recipients.length; i++) {
            address[] memory recips = recipients[i];
            uint[] memory bals = balances[i];
            uint id = ids[i];
            IFNFTHandler(FNFT_HANDLER).mintBatchRec(recips, bals, id, supplies[i], '0x0');
        }
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
}