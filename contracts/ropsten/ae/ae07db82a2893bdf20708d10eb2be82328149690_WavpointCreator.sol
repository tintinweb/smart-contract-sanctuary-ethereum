pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./BeaconProxy.sol";
import "./UpgradeableBeacon.sol";
import "./WavpointStash.sol";

contract WavpointCreator is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ECDSAUpgradeable for bytes32;

    // ============ Storage ============

    bytes32 public constant MINTER_TYPEHASH = keccak256('Deployer(address stashWallet)');
    CountersUpgradeable.Counter private atAtashId;
    // address used for signature verification, changeable by owner
    address public admin;
    bytes32 public DOMAIN_SEPARATOR;
    address public beaconAddress;
    // registry of created contracts
    address[] public wavpointStashContracts;

    // ============ Events ============

    /// Emitted when an Atash is created
    event CreatedAtash(uint256 stashId, string name, string symbol, address indexed stashAddress);

    // ============ Functions ============

    /// Initializes factory
    function initialize() public initializer {
        __Ownable_init_unchained();

        // set admin for stash deployment authorization
        admin = msg.sender;
        DOMAIN_SEPARATOR = keccak256(abi.encode(keccak256('EIP712Domain(uint256 chainId)'), block.chainid));

        // set up beacon with msg.sender as the owner
        UpgradeableBeacon _beacon = new UpgradeableBeacon(address(new WavpointStash()));
        _beacon.transferOwnership(msg.sender);
        beaconAddress = address(_beacon);

        // Set stash id start to be 1 not 0
        atAtashId.increment();
    }

    /// Creates a new stash contract as a factory with a deterministic address
    /// Important: None of these fields (except the Url fields with the same hash) can be changed after calling
    /// @param _name Name of the stash
    function createAtash(
        bytes calldata signature,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) public returns (address) {
        require((getSigner(signature) == admin), 'invalid authorization signature');

        BeaconProxy proxy = new BeaconProxy(
            beaconAddress,
            abi.encodeWithSelector(
                WavpointStash(address(0)).initialize.selector,
                msg.sender,
                atAtashId.current(),
                _name,
                _symbol,
                _baseURI
            )
        );

        // add to registry
        wavpointStashContracts.push(address(proxy));

        emit CreatedAtash(atAtashId.current(), _name, _symbol, address(proxy));

        atAtashId.increment();

        return address(proxy);
    }

    /// Get signer address of signature
    function getSigner(bytes calldata signature) public view returns (address) {
        require(admin != address(0), 'whitelist not enabled');
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, keccak256(abi.encode(MINTER_TYPEHASH, msg.sender)))
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        return recoveredAddress;
    }

    /// Sets the admin for authorizing stash deployment
    /// @param _newAdmin address of new admin
    function setAdmin(address _newAdmin) external {
        require(owner() == _msgSender() || admin == _msgSender(), 'invalid authorization');
        admin = _newAdmin;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}