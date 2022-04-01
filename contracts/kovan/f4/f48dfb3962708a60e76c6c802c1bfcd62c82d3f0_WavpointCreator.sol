pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./BeaconProxy.sol";
import "./WavpointStashProxy.sol";
import "./WavpointStash.sol";

contract WavpointCreator is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ECDSAUpgradeable for bytes32;

    // ============ Storage ============
    
    CountersUpgradeable.Counter private atAtashId;
    // address used for signature verification, changeable by owner
    address public admin;
    address public beaconAddress;
    // registry of created contracts
    address[] public wavpointStashContracts;

    mapping(address => bool) public stashar;

    // ============ Events ============

    /// Emitted when an Atash is created
    event CreatedAtash(uint256 stashId, string name, string symbol, address indexed stashAddress);

    // ============ Functions ============

    /// Initializes factory
    function initialize() public initializer {
        __Ownable_init_unchained();

        // set admin for stash deployment authorization
        admin = msg.sender;
        stashar[msg.sender] = true;

        // set up beacon with msg.sender as the owner
        WavpointStashProxy _beacon = new WavpointStashProxy(address(new WavpointStash()));
        _beacon.transferOwnership(msg.sender);
        beaconAddress = address(_beacon);

        // Set stash id start to be 1 not 0
        atAtashId.increment();
    }

    function addStashar(address _stashar) public onlyOwner {
        stashar[_stashar] = true;
    }

    /// Creates a new stash contract as a factory with a deterministic address
    /// Important: None of these fields (except the Url fields with the same hash) can be changed after calling
    /// @param _name Name of the stash
    function createAtash(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) public returns (address) {
        require(stashar[msg.sender], 'invalid authorization');

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

        if (msg.sender != admin || msg.sender != owner()) {
            stashar[msg.sender] = false;
        }

        return address(proxy);
    }

    /// Sets the admin for authorizing stash deployment
    /// @param _newAdmin address of new admin
    function setAdmin(address _newAdmin) external {
        require(owner() == _msgSender() || admin == _msgSender(), 'invalid authorization');
        admin = _newAdmin;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}