// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;

import { IENS } from "./interfaces/IENS.sol";
import { IObject } from "./interfaces/IObject.sol";

contract ObjectController  {
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address private phiMapAddress;
    /* --------------------------------- ****** --------------------------------- */
    /* --------------------------------- APPROVE -------------------------------- */
    event SuccessApproveSet(address indexed sender,address[] addresses);
    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(address _phiMapAddress){
       phiMapAddress = _phiMapAddress;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    APPROVE                                 */
    /* -------------------------------------------------------------------------- */
    /*
     * @title setApproveForBasicObject
     * @notice Functions for addresses
     * @param addresses : addresses objects
     */
    function setApproveForBasicObjects(address[] memory addresses) external {
        bool check;
        for (uint256 i = 0; i < addresses.length; i++) {
            IObject _object = IObject(addresses[i]);
            (bool success, ) = addresses[i].delegatecall(abi.encodeWithSignature("setApprovalForAll(address,bool)",address(phiMapAddress), true));
            require(success);
        }
        emit SuccessApproveSet(msg.sender,addresses);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.8;

interface IENS {
    function resolver(bytes32 node) external view returns (Resolver);

    function owner(bytes32 node) external view returns (address);
}

abstract contract Resolver {
    function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.8;

interface IObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }
    // define object struct
    struct Objects {
        string tokenURI;
        Size size;
        address payable creator;
        uint256 maxClaimed;
        uint256 price;
        bool forSale;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function isApprovedForAll(address account, address operator) external returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function mintBatchObject(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}