// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

interface IERC1155Rescue {
    function rescueBag(bytes32 bagId, address to) external;

    function getBagId(
        address solver,
        uint256[] calldata tokenIds,
        uint256[] calldata tokenAmounts
    ) external pure returns (bytes32);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "../interfaces/IERC1155Rescue.sol";

contract ERC1155Unsafe {
    IERC1155Rescue rescue;

    constructor(IERC1155Rescue _rescue) {
        rescue = _rescue;
    }

    function rescueBag(bytes32 bagId, address to) external {
        rescue.rescueBag(bagId, to);
    }
}