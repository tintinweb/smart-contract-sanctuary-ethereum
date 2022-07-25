/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

contract BlockingContract {
    address private immutable deployer = msg.sender;

    address public proxyOwner;

    uint private gap;

    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    function fixStorage(address newOwner) external {
        require(msg.sender == deployer, "not deployer");

        proxyOwner = newOwner;

        initialized = true;
        initializing = false;
    }

    function setStorage(uint slot, bytes32 value) external {
        require(msg.sender == deployer || msg.sender == proxyOwner, "not owner");

        assembly {
            sstore(slot, value)
        }
    }

    function exec(address to, bytes calldata data) external {
        require(msg.sender == deployer || msg.sender == proxyOwner, "not owner");

        (bool ok, ) = to.call(data);
        require(ok, "not ok");
    }
}