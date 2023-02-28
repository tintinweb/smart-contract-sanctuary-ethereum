// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IBaal} from "contracts/interfaces/IBaal.sol";

contract Reaper {
    // Baal DAO
    IBaal public baal;

    function initialize(address _baal) external {
        // todo: set module under authority of shaman

        // set address of DAO
        baal = IBaal(_baal);

        // encode shaman proposal
        bytes memory shamanData;
        shamanData = _encodeShamanProposal(address(this), 2);

        // submit SHAMAN proposal
        bytes[] memory data = new bytes[](1);
        data[0] = shamanData;

        address[] memory targets = new address[](1);
        targets[0] = address(baal);

        _submitBaalProposal(_encodeMultiMetaTx(data, targets));
    }

    /*************************
     ENCODING
     *************************/

    /**
     * @dev Encoding function for Baal Shaman
     */
    function _encodeShamanProposal(address shaman, uint256 permission)
        internal
        pure
        returns (bytes memory)
    {
        address[] memory _shaman = new address[](1);
        _shaman[0] = shaman;

        uint256[] memory _permission = new uint256[](1);
        _permission[0] = permission;

        return
            abi.encodeWithSignature(
                "setShamans(address[],uint256[])",
                _shaman,
                _permission
            );
    }

    /**
     * @dev Format multiSend for encoded functions
     */
    function _encodeMultiMetaTx(bytes[] memory _data, address[] memory _targets)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory metaTx;

        for (uint256 i = 0; i < _data.length; i++) {
            metaTx = abi.encodePacked(
                metaTx,
                uint8(0),
                _targets[i],
                uint256(0),
                uint256(_data[i].length),
                _data[i]
            );
        }
        return abi.encodeWithSignature("multiSend(bytes)", metaTx);
    }

    /**
     * @dev Submit voting proposal to Baal DAO
     */
    function _submitBaalProposal(bytes memory multiSendMetaTx) internal {
        uint256 proposalOffering = baal.proposalOffering();
        require(msg.value == proposalOffering, "Missing tribute");

        string
            memory metaString = '{"proposalType": "ADD_SHAMAN", "title": "Reaper", "description": "Assign Reaper contract as a Manager-Shaman"}';

        baal.submitProposal{value: proposalOffering}(
            multiSendMetaTx,
            0,
            0,
            metaString
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBaal {
    function proposalOffering() external returns (uint256);

    function proposalCount() external returns (uint256);

    function avatar() external returns (address);

    function submitProposal(
        bytes calldata proposalData,
        uint32 expiration,
        uint256 baalGas,
        string calldata details
    ) external payable returns (uint256);

    function sharesToken() external returns (address);

    function isManager(address shaman) external view returns (bool);

    function mintShares(address[] calldata to, uint256[] calldata amount)
        external;
}