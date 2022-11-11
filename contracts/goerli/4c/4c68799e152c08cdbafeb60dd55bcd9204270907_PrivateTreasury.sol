// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Interface for the solidity verifier produced by verif-manager.circom
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view returns (bool);
}

/// @title Private treasuries
/// @notice Platform for managing treasuries with balance & withdrawal privacy
/// @dev This is a POC that has not undergone any audits.
contract PrivateTreasury {
    address public constant VERIFIER_ADDR =
        0x70F1d626BC30DE8379636b3eAE8981298796e928;
    IVerifier verifierContract = IVerifier(VERIFIER_ADDR);

    struct Point {
        bytes32 x;
        bytes32 y;
    }

    struct Treasury {
        Point pk;
        string label;
    }

    struct Deposit {
        Point P;
        Point Q;
        uint256 v;
        bool spent;
    }

    /// @dev Directory of treasuries can be stored off-chain
    Treasury[] public directory;

    /// @dev Should be stored in a Merkle Tree instead of an array
    Deposit[] public deposits;

    /// @notice Treasury creation
    /// @param pk Public key generated from Babyjubjub
    /// @param label Name given to treasury, use only as descriptor, not lookup
    function create(Point calldata pk, string calldata label) external {
        directory.push(Treasury(pk, label));
    }

    /// @notice Contribute to a treasury on the platform
    /// @param P Pubkey of contributor (ρ * G, where ρ is contributor's privKey)
    /// @param Q ρ * treasuryPubKey, a val that can only be derived using
    ///          α * P (where α is the treasury's private key)
    function deposit(Point calldata P, Point calldata Q) external payable {
        require(msg.value > 0, "Deposited ether value must be > 0.");
        deposits.push(Deposit(P, Q, msg.value, false));
    }

    /// @notice Enable managers to withdraw deposits belonging to their treasury
    /// @param depIdx Index of target deposit to withdraw in deposits[]
    /// @param a pi_a in proof
    /// @param b pi_b in proof
    /// @param c pi_c in proof
    /// @param publicSignals Public signals associated with the proof
    function withdraw(
        uint256 depIdx,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory publicSignals
    ) external payable {
        require(
            verifierContract.verifyProof(a, b, c, publicSignals),
            "Invalid withdrawal proof"
        );
        require(depIdx < deposits.length, "Invalid requested deposit index");

        Deposit storage tgtDep = deposits[depIdx];
        require(!tgtDep.spent, "Deposit already spent");

        require(
            bytes32(publicSignals[0]) == tgtDep.P.x,
            "Public signals for proof don't match P for the target deposit"
        );
        require(
            bytes32(publicSignals[1]) == tgtDep.P.y,
            "Public signals for proof don't match P for the target deposit"
        );
        require(
            bytes32(publicSignals[2]) == tgtDep.Q.x,
            "Public signals for proof don't match Q for the target deposit"
        );
        require(
            bytes32(publicSignals[3]) == tgtDep.Q.y,
            "Public signals for proof don't match Q for the target deposit"
        );

        payable(msg.sender).transfer(tgtDep.v);
        tgtDep.spent = true;
    }

    /// @notice Access length of deposits
    function getNumDeposits() external view returns (uint256) {
        return deposits.length;
    }

    /// @notice Access length of directory
    function getDirectoryLength() external view returns (uint256) {
        return directory.length;
    }
}