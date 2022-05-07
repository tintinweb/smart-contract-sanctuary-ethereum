pragma solidity 0.8.13;

/// @title DPDRepository
/// @notice The Decentralized Programmable Data (DPD) Repository stores data content identifiers, versions, authorized owners, and upgraders.
/// @author David Lucid <[email protected]>
contract DPDRepository {
    /// @notice Struct for a DPD.
    struct DPD {
        bytes cid;
        address owner;
    }

    /// @notice DPD CIDs and owners mapped by DPD ID.
    DPD[] public dpds;

    /// @notice Versions mapped by DPD ID.
    /// @dev Excluded from DPD struct to avoid allocation memory unnecessarily.
    mapping(uint256 => uint256) public versions;

    /// @notice Updaters mapped by DPD ID.
    /// @dev Excluded from DPD struct to avoid allocation memory unnecessarily.
    mapping(uint256 => address) public updaters;

    /// @notice Event emitted when a new DPD is added to the repository.
    event DPDAdded(uint256 indexed dpdId, address owner, address updater, bytes cid);

    /// @notice Event emitted when a new DPD is added to the repository.
    event DPDUpdated(uint256 indexed dpdId, uint256 indexed version, bytes cid);

    /// @notice Event emitted when a DPD's owner is changed.
    event DPDOwnerChanged(uint256 indexed dpdId, address newOwner);

    /// @notice Event emitted when a DPD's upgrader is changed.
    event DPDUpdaterChanged(uint256 indexed dpdId, address newUpdater);

    /// @notice Function to add a new DPD.
    /// @param cid DPD CID (content identifier).
    /// @param owner DPD owner address.
    /// @param updater DPD updater address.
    function addDpd(bytes calldata cid, address owner, address updater) external returns (uint256) {
        dpds.push(DPD(cid, owner));
        uint256 dpdId = dpds.length - 1;
        updaters[dpdId] = updater;
        emit DPDAdded(dpdId, owner, updater, cid);
        return dpdId;
    }

    /// @notice Function to update a DPD's CID.
    /// @param dpdId DPD's ID in this repository.
    /// @param cid New DPD CID (content identifier).
    function updateDpd(uint256 dpdId, bytes memory cid) external returns (uint256) {
        address updater = updaters[dpdId];
        require(msg.sender == updater || (msg.sender == dpds[dpdId].owner && updater == address(0)), "Only DPD updater (or owner if no updater) can update this DPD.");
        dpds[dpdId].cid = cid;
        uint256 newVersion = versions[dpdId]++;
        emit DPDUpdated(dpdId, newVersion, cid);
        return newVersion;
    }

    /// @notice Function to set a DPD's owner.
    /// @param dpdId DPD's ID in this repository.
    /// @param newOwner New owner address for this DPD.
    function setDpdOwner(uint256 dpdId, address newOwner) external {
        require(msg.sender == dpds[dpdId].owner, "Only DPD owner can update this DPD's owner.");
        dpds[dpdId].owner = newOwner;
        emit DPDOwnerChanged(dpdId, newOwner);
    }

    /// @notice Function to set a DPD's upgrader.
    /// @param dpdId DPD's ID in this repository.
    /// @param newUpdater New updater address for this DPD.
    function setDpdUpdater(uint256 dpdId, address newUpdater) external {
        require(msg.sender == dpds[dpdId].owner, "Only DPD owner can update this DPD's updater.");
        updaters[dpdId] = newUpdater;
        emit DPDUpdaterChanged(dpdId, newUpdater);
    }
}