pragma solidity 0.8.13;

/// @title DAppDirectory
/// @notice Pentagon Retail's dApp directory.
/// @author David Lucid <[email protected]>
contract DAppDirectory {
    /// @notice Struct for a dApp.
    struct DApp {
        string name;
        string tagline;
        address admin; // Admin can add upgrades to directoryStructureIpfsHashes
        bytes iconIpfsHash;
    }

    /// @notice Array of all dApps.
    DApp[] public dApps;

    /// @notice Arrays of IPFS hashes (`index.html hash` and directory structure hash) for each version of each dApp.
    mapping(uint256 => bytes[]) public dAppIpfsHashes;

    /// @notice Function to add a new dApp.
    function addDApp(
        string calldata name,
        string calldata tagline,
        address admin,
        bytes calldata iconIpfsHash,
        bytes memory _dAppIpfsHashes
    ) external returns (uint256) {
        dApps.push(DApp(name, tagline, admin, iconIpfsHash));
        dAppIpfsHashes[dApps.length - 1].push(_dAppIpfsHashes);
        return dApps.length - 1;
    }

    /// @notice Function to get an array of dApps.
    function getDApps()
        external
        view
        returns (
            DApp[] memory,
            uint256[] memory,
            bytes[] memory
        )
    {
        bytes[] memory _dAppIpfsHashes = new bytes[](dApps.length);
        uint256[] memory versions = new uint256[](dApps.length);

        for (uint256 i = 0; i < dApps.length; i++) {
            uint256 version = dAppIpfsHashes[i].length - 1;
            versions[i] = version;
            _dAppIpfsHashes[i] = dAppIpfsHashes[i][version];
        }

        return (dApps, versions, _dAppIpfsHashes);
    }

    /// @notice Function to get a dApp's latest version index and code.
    function getLatestDAppVersion(uint256 dAppId)
        external
        view
        returns (uint256, bytes memory)
    {
        uint256 version = dAppIpfsHashes[dAppId].length - 1;
        return (version, dAppIpfsHashes[dAppId][version]);
    }

    /// @notice Function to update a dApp's metadata.
    function updateDAppMetadata(
        uint256 dAppId,
        string calldata name,
        string calldata tagline,
        address admin,
        bytes calldata iconIpfsHash
    ) external {
        require(
            msg.sender == dApps[dAppId].admin,
            "Only dApp admin can update this dApp's metadata."
        );
        dApps[dAppId] = DApp(name, tagline, admin, iconIpfsHash);
    }

    /// @notice Function to update a dApp's code.
    function updateDAppCode(uint256 dAppId, bytes memory _dAppIpfsHashes)
        external
        returns (uint256)
    {
        require(
            msg.sender == dApps[dAppId].admin,
            "Only dApp admin can update this dApp's code."
        );
        dAppIpfsHashes[dAppId].push(_dAppIpfsHashes);
        return dAppIpfsHashes[dAppId].length - 1;
    }
}