/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IBridged20 {
    function mint(address _to, uint256 amount) external;
}

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Message registry
     */
    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Gateway is Ownable {
    uint256 public endpointGatewayERC20;
    IStarknetCore public starknetCore;
    uint256 constant BRIDGE_MODE_WITHDRAW = 1;


    // Bootstrap
    constructor(address _starknetCore) {
        require(
            _starknetCore != address(0),
            "Gateway/invalid-starknet-core-address"
        );

        starknetCore = IStarknetCore(_starknetCore);
    }

    mapping(address => bool) private _isDeployed;
    mapping(uint256 => address) private _DepositedOwnerList;
    mapping(address => mapping(uint256 => uint256)) private _listeTokensIDAmount;


    event Deployed(address addr);

    function setEndpointGateway(uint256 _endpointGateway20) external onlyOwner{
        endpointGatewayERC20 = _endpointGateway20;
    }


    // Utils
    function addressToUint(address value)
        internal
        pure
        returns (uint256 convertedValue)
    {
        convertedValue = uint256(uint160(address(value)));
    }

    // Bridging back from Starknet
    function finalizeWithdrawal(
        address _l1TokenOwner,
        IBridged20 _l1TokenContract,
        uint256 _l2TokenContract,
        uint256 _amount
    ) external onlyOwner{
        uint256 size = 5;
        uint256[] memory payload = new uint256[](size);
        // build withdraw message payload
        payload[0] = BRIDGE_MODE_WITHDRAW;
        payload[1] = addressToUint(_l1TokenOwner);
        payload[2] = addressToUint(address(_l1TokenContract));
        payload[3] = _l2TokenContract;
        payload[4] = _amount;
        // consum withdraw message
        starknetCore.consumeMessageFromL2(endpointGatewayERC20, payload);
        mintFromStarknet(address(_l1TokenContract),_l1TokenOwner,_amount);
    }

    function mintFromStarknet(address newContractAddress,address _l1TokenOwner,uint256 _amount)
        internal
    {
        IBridged20 bridge = IBridged20(newContractAddress);
        bridge.mint(_l1TokenOwner, _amount);
    }

}