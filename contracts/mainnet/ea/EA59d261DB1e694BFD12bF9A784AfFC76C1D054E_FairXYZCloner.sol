// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IFairXYZDeployer {
    function initialize(uint256 maxTokens_, uint256 nftPrice_, string memory name_, string memory symbol_,
                        bool burnable_, uint256 maxMintsPerWallet_, address interfaceAddress_,
                        string[] memory URIs_, uint96 royaltyPercentage_, address[] memory royaltyReceivers_) external;
}

interface IFairXYZWallets {
    function viewSigner() view external returns(address);
    function viewWithdraw() view external returns(address);
}

contract FairXYZCloner {

    address public implementation;

    address public interfaceAddress;

    mapping(address => address[]) public allClones;

    event NewClone(address _newClone, address _owner);

    constructor(address _implementation, address _interface) {
        require(_implementation != address(0), "Cannot set to 0 address!");
        require(_interface != address(0), "Cannot set to 0 address!");
        implementation = _implementation;
        interfaceAddress = _interface;
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address _implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    function _clone(uint256 maxTokens, uint256 nftPrice, string memory name, string memory symbol, bool burnable, 
                    uint256 maxMintsPerWallet, string[] memory URIs_, uint96 royaltyPercentage, address[] memory royaltyReceivers) external {

        address identicalChild = clone(implementation);
        allClones[msg.sender].push(identicalChild);
        IFairXYZDeployer(identicalChild).initialize(maxTokens, nftPrice, name, symbol, burnable, maxMintsPerWallet, 
                                                    interfaceAddress, URIs_, royaltyPercentage, royaltyReceivers);
        emit NewClone(identicalChild, msg.sender);
    }

    function returnClones(address _owner) external view returns (address[] memory){
        return allClones[_owner];
    }

}