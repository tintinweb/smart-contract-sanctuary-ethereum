// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

interface IBDD {
    function contractOwnerUpdateMaximumCreationPrice(uint256 _newMaximumCreationPrice) external;
    function anyoneCreatePixel(string memory _color) external payable;
    function transferOwnership(address newOwner) external;
    function maximumCreationPrice() external view returns (uint256);
}


contract BillionDollarMinter {

    /// @notice The ImmutablesArt contract
    IBDD public immutable bdd;

    /// @notice The owner address
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    error NotApproved();
    error NotOwner();

    constructor() {
        //bdd = IBDD(0xDE41fD6dfa8194A1B32A91cB1313402007A31173); // mainnet
        bdd = IBDD(0x18292b233b235B9aC96F3b367e1ea4a35D0C5ED4); // rinkeby

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function mintPixel(string memory _color) external payable {
        if (msg.sender != owner) revert NotOwner();
        uint256 _origPrice = bdd.maximumCreationPrice();
        bdd.contractOwnerUpdateMaximumCreationPrice(0);
        bdd.anyoneCreatePixel(_color);
        bdd.contractOwnerUpdateMaximumCreationPrice(_origPrice);
    } 

    function returnContract() external {
        if (msg.sender != owner) revert NotOwner();
        bdd.transferOwnership(owner);
    }

    /// @notice Transfer ownership of this contract to a new address
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /// @notice Call a contract with the specified data
    function call(address contractAddress, bytes calldata data) external payable returns (bytes memory) {
        if (msg.sender != owner) revert NotOwner();
        (bool success, bytes memory returndata) = contractAddress.call{value: msg.value}(data);
        require(success);
        return returndata;
    }

    /// @notice Query if this contract implements an interface
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165,
            interfaceId == 0x7f5828d0; // ERC-173.
    }

    receive() external payable {}
    fallback() external payable {}
}