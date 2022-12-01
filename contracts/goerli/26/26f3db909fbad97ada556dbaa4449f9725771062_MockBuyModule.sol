// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBuyActions {
    function buy(
        address nftContract,
        uint256 tokenID,
        uint256 value,
        address to,
        bytes calldata callData
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions that the ship can take
interface IBuyEvents {
    event NFTBought(
        uint256 timestamp,
        uint256 price,
        address nftContract,
        uint256 nftTokenID
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "szns/interfaces/buy/IBuyEvents.sol";
import "szns/interfaces/buy/IBuyActions.sol";

contract MockBuyModule is IBuyEvents, IBuyActions {
    function buy(
        address nftContract,
        uint256 tokenID,
        uint256 value,
        address to,
        bytes calldata callData
    ) external {
        emit NFTBought(block.timestamp, value, nftContract, tokenID);
    }
}