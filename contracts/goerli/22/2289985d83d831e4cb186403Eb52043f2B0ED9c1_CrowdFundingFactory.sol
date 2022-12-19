// SPDX-License-Identifier: No license

pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./CrowdFunding.sol";

contract CrowdFundingFactory {
    address immutable CrowdFundingImplementation;

    constructor() {
        CrowdFundingImplementation = address(new CrowdFunding());
    }

    function createInstance(
        uint256 cap, 
        uint256 thresholdCap, 
        uint256 timeToMarketBlocks, 
        string calldata offerCode,
        string calldata paymentContractType) external returns (address) {
        address clone = Clones.clone(CrowdFundingImplementation);
        CrowdFunding(clone).initialize(
            cap,
            thresholdCap,
            timeToMarketBlocks,
            offerCode,
            paymentContractType);
        return clone;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: No license

pragma solidity 0.8.16;

interface PaymentChannel {
    function openChannel(
        address channelId,
        uint256 forDuration,
        address ephemeralConsumerAddress) external payable returns (bool);
}

contract CrowdFunding {

    address public provider;
    uint256 public cap;
    uint256 public thresholdCap;
    uint256 public initialBlock;
    uint256 public timeToMarketBlocks;
    string public offerCode;
    mapping (address => uint256) public nonces;
    mapping (address => mapping (uint256 => uint256)) public orders;
    bool internal deployed;
    string public paymentContractType;
    address public paymentContractAddress;
    PaymentChannel internal pc;

    event OfferCreation (address indexed provider, string indexed offerCode);
    event ChannelOpened(
        address indexed consumer,
        address indexed channelId,
        uint256 indexed expiration,
        address ephemeralConsumerAddress
    );

    function initialize (uint256 _cap,
                 uint256 _thresholdCap,
                 uint256 _timeToMarketBlocks,
                 string memory _offerCode,
                 string memory _paymentContractType) public {
        provider = msg.sender;
        cap = _cap;
        thresholdCap = _thresholdCap;
        initialBlock = block.number;
        timeToMarketBlocks = _timeToMarketBlocks;
        offerCode = _offerCode;
        paymentContractType = _paymentContractType;
        emit OfferCreation(msg.sender, offerCode);
    }

    function postOrder () external payable {
        require(address(this).balance <= cap, "Demand beyond cap");
        nonces[msg.sender] = nonces[msg.sender] + 1;
        orders[msg.sender][nonces[msg.sender]] = msg.value;
    }

    function deleteOrder (uint256 nonce) external {
        require(orders[msg.sender][nonce] > 0, "Nonce already deleted");
        require(!deployed, "Resource has been deployed, cannot delete");
        require((block.number - initialBlock) > timeToMarketBlocks, "Not reached time to market yet");
        uint amountToWithdraw = orders[msg.sender][nonce];
        orders[msg.sender][nonce] = 0;
        nonces[msg.sender] = nonces[msg.sender] - 1;
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function unlock (address newPaymentContractAddress) external {
        require(msg.sender == provider, "Only provider can unlock");
        require(newPaymentContractAddress != address(0), "Cannot unlock to null address");
        deployed = true;
        paymentContractAddress = newPaymentContractAddress;
        pc = PaymentChannel(paymentContractAddress);
    }

    function openChannel (uint256 nonce, address ephemeralAddress) external {
        require(deployed, "Resource has not been deployed, channel cannot be opened");
        require(orders[msg.sender][nonce] > 0, "Consumer without funds");
        require(ephemeralAddress != address(0), "Cannot open the chanel to a null address");
        require(pc.openChannel{ value: orders[msg.sender][nonce] }(ephemeralAddress, 1, ephemeralAddress), "Channel could not be opened");
        emit ChannelOpened(msg.sender,
                           ephemeralAddress,
                           1,
                           ephemeralAddress);
        /* (bool success, ) =  address(pc).call{ value: orders[msg.sender][nonce] }
        (abi.encodeWithSignature("openChannel(address,uint256,address)", "call openChannel",
                                  ephemeralAddress, 1, ephemeralAddress));
        if (!success) {
             revert();
        } */
    }

}