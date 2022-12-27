// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IETHRegistrarController.sol";
import "./interfaces/IChainlinkAggregatorV3.sol";

contract NamehashController {
    address public immutable treasury;
    IETHRegistrarController public immutable ensController;

    constructor(address _treasury, address _ensController) {
        treasury = _treasury;
        ensController = IETHRegistrarController(_ensController);
    }

    receive() external payable {}

    fallback() external payable {}

    function register(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) public payable {
        // register in ENS
        ensController.registerWithConfig{value: msg.value}(
            name,
            owner,
            duration,
            secret,
            resolver,
            addr
        );
    }

    function withdraw() public {
        // withdraw to treasury
        payable(treasury).transfer(address(this).balance);
    }

    function getPrice(address priceFeed) public view returns (int256) {
        (, int256 price, , , ) = IChainlinkAggregatorV3(priceFeed)
            .latestRoundData();
        return price;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IETHRegistrarController {
    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;

    function renew(string calldata, uint256) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}