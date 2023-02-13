// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./IETHBulkRegistrar.sol";
import "./IETHRegistrarController.sol";
import "../bnbregistrar/IPriceOracle.sol";

contract ETHBulkRegistrarV1 is IETHBulkRegistrar {
    IETHRegistrarController public immutable registrarController;

    constructor(IETHRegistrarController _registrarController) {
        registrarController = _registrarController;
    }

    function bulkRentPrice(string[] calldata names, uint256 duration) external view override returns (uint256 total) {
        for (uint256 i = 0; i < names.length; i++) {
            IPriceOracle.Price memory price = registrarController.rentPrice(names[i], duration);
            total += (price.base + price.premium);
        }
        return total;
    }

    function bulkMakeCommitment(string[] calldata name, address owner, bytes32 secret) external view override returns (bytes32[] memory commitments) {
        commitments = new bytes32[](name.length);
        for (uint256 i = 0; i < name.length; i++) {
            commitments[i] = registrarController.makeCommitmentWithConfig(name[i], owner, secret, address(0), address(0));
        }
        return commitments;
    }

    function commitment(bytes32 commit) external view override returns (uint256) {
        return registrarController.commitments(commit);
    }

    function bulkCommit(bytes32[] calldata commitments) external override {
        for (uint256 i = 0; i < commitments.length; i++) {
            registrarController.commit(commitments[i]);
        }
    }

    function bulkRegister(string[] calldata names, address owner, uint duration, bytes32 secret) external override payable {
        uint256 cost = 0;
        for (uint256 i = 0; i < names.length; i++) {
            IPriceOracle.Price memory price;
            price = registrarController.rentPrice(names[i], duration);
            registrarController.register{value: (price.base + price.premium)}(names[i], owner, duration, secret);
            cost = cost + price.base + price.premium;
        }

        // Send any excess funds back
        payable(msg.sender).transfer(msg.value - cost);
    }
}

pragma solidity >=0.8.4;

interface IETHBulkRegistrar {
    function bulkRentPrice(string[] calldata names, uint256 duration) external view returns (uint256 total);
    
    function bulkRegister(string[] calldata names, address owner, uint duration, bytes32 secret) external payable;

    function bulkCommit(bytes32[] calldata commitments) external;

    function bulkMakeCommitment(string[] calldata name, address owner, bytes32 secret) external view returns (bytes32[] memory commitments);

    function commitment(bytes32 commit) external view returns(uint256);

}

pragma solidity >=0.8.4;

import "../bnbregistrar/IPriceOracle.sol";
interface IETHRegistrarController {
    
    function rentPrice(string memory, uint256)
        external
        view
        returns (IPriceOracle.Price memory);

    function available(string memory) external returns (bool);

    function makeCommitmentWithConfig(
        string memory,
        address,
        bytes32,
        address,
        address
    ) external pure returns (bytes32);

    function commit(bytes32) external;

    function register(
        string calldata,
        address,
        uint256,
        bytes32
    ) external payable;

    function renew(string calldata, uint256) external payable;

    function commitments(bytes32) external view returns (uint256);
}

pragma solidity >=0.8.4;

interface IPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return base premium tuple of base price + premium price
     */
    function price(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);

    function price(
        uint name_len,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);

}