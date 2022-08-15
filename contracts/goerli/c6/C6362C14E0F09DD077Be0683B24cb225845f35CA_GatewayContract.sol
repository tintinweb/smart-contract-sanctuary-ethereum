// SPDX-License-Identifier: MIT.

pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IStarknetCore {
    // Consumes a message that was sent from an L2 contract. Returns the hash of the message
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);
}

contract RecoveryContract {
    address public recipient;
    address public gatewayContract;
    uint256 public minBlocks;
    bool public isActive;

    constructor(
        address _recipient,
        uint256 _minBlocks,
        address _gatewayContract
    ) {
        recipient = _recipient;
        minBlocks = _minBlocks;
        gatewayContract = _gatewayContract;
        isActive = false;
    }

    function claimAssets(address[] calldata erc20contracts, address to)
        external
    {
        require(msg.sender == recipient, "Only recipient");
        require(isActive == true, "Not active");
        for (uint256 i = 0; i < erc20contracts.length; i++) {
            uint256 balance = IERC20(erc20contracts[i]).balanceOf(
                address(this)
            );
            IERC20(erc20contracts[i]).transfer(to, balance);
        }
    }

    function activateRecovery(uint256 blocks) external {
        require(msg.sender == gatewayContract, "Not gateway");
        require(!isActive, "Already active");
        require(blocks >= minBlocks, "Inactivity too short");
        isActive = true;
        emit ActiveRecovery(address(this), recipient, block.timestamp);
    }

    event ActiveRecovery(
        address contractAddress,
        address recipient,
        uint256 activationTime
    );
}

contract GatewayContract {
    // The StarkNet core contract
    IStarknetCore starknetCore;
    address public owner;
    uint256 public l2StorageProverAddress;
    bool public proverAddressIsSet = false;
    mapping(address => address) public eoaToRecoveryContract;

    constructor(IStarknetCore _starknetCore) {
        starknetCore = _starknetCore;
        owner = msg.sender;
    }

    function setProverAddress(uint256 _l2StorageProverAddress) external {
        require(msg.sender == owner, "Only owner");
        l2StorageProverAddress = _l2StorageProverAddress;
        proverAddressIsSet = true;
    }

    function receiveFromStorageProver(uint256 userAddress, uint256 blocks)
        external
    {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = userAddress;
        payload[1] = blocks;

        assert(proverAddressIsSet == true);

        starknetCore.consumeMessageFromL2(l2StorageProverAddress, payload);

        address conversion = address(uint160(userAddress));
        address _recoveryContractAddress = eoaToRecoveryContract[conversion];
        RecoveryContract(_recoveryContractAddress).activateRecovery(blocks);
    }

    function deployRecoveryContract(address recipient, uint256 minBlocks)
        external
    {
        require(
            eoaToRecoveryContract[msg.sender] == address(0x0),
            "Recovery contract exists"
        );
        address _recoveryContractAddress = address(
            new RecoveryContract(recipient, minBlocks, address(this))
        );
        eoaToRecoveryContract[msg.sender] = _recoveryContractAddress;
        emit NewRecoveryContract(
            msg.sender,
            _recoveryContractAddress,
            block.timestamp,
            minBlocks
        );
    }

    event NewRecoveryContract(
        address EOA,
        address recoveryContract,
        uint256 creationDate,
        uint256 minBlocks
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}