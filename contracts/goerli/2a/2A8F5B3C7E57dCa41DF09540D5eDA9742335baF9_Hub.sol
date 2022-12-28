// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Rain_Interface {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

contract Hub {
    bytes32 public constant DEFAULT_ADMIN_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    address public rainTokenAddress;
    // su address => coin address
    mapping(address => address) suToCoinMapping;
    mapping(address => bytes32[]) suToHashMapping;

    modifier onlyAdmin() {
        require(
            Rain_Interface(rainTokenAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                msg.sender
            ),
            "Not Admin"
        );
        _;
    }

    modifier onlySU() {
        require(suToCoinMapping[msg.sender] != address(0), "Not SU");
        _;
    }

    event NewPairAdded(address su, address coin);
    event NewHashAdded(address su, bytes32 suHash);

    event PairUpdated(address su, address coin);
    event RainAddressUpdated(address newRainAddress);
    event SuAddressUpdated(address oldSu, address newSu);

    constructor(address _rainTokenAddress) {
        rainTokenAddress = _rainTokenAddress;
    }

    function addSuToCoin(address _su, address _coin) external onlyAdmin {
        suToCoinMapping[_su] = _coin;
        emit NewPairAdded(_su, _coin);
    }

    function addHash(address _su, bytes32 _new_hash) external onlySU {
        suToHashMapping[_su].push(_new_hash);
        emit NewHashAdded(_su, _new_hash);
    }

    function updateSuAddress(address _oldSuAddress, address _newSuAddress)
        external
        onlyAdmin
    {
        require(
            suToCoinMapping[_oldSuAddress] != address(0),
            "SU address not found"
        );

        address suCoin = suToCoinMapping[_oldSuAddress];
        bytes32[] memory suHashes = suToHashMapping[_oldSuAddress];

        suToCoinMapping[_newSuAddress] = suCoin;
        suToHashMapping[_newSuAddress] = suHashes;

        delete suToCoinMapping[_oldSuAddress];
        delete suToHashMapping[_oldSuAddress];

        emit SuAddressUpdated(_oldSuAddress, _newSuAddress);
    }

    function setRainAddress(address newRainTokenAddress) external onlyAdmin {
        rainTokenAddress = newRainTokenAddress;
        emit RainAddressUpdated(newRainTokenAddress);
    }

    function getCoinFromAddress(address _su) external view returns (address) {
        return suToCoinMapping[_su];
    }

    function getSuHashFromIndex(address _su, uint256 _index)
        external
        view
        returns (bytes32)
    {
        if (suToHashMapping[_su].length >= _index + 1) {
            return suToHashMapping[_su][_index];
        } else {
            return bytes32(0);
        }
    }
}