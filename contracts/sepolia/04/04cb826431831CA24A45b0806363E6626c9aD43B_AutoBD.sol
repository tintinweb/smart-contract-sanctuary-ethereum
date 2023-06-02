// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAPI3 {
    function burn(uint256 amount) external;

    function transferFrom(address from, address to, uint256 amount)
        external
        returns (bool);

    function updateBurnerStatus(bool burnerStatus) external;
}

contract AutoBD {
    error TransferReverted();
    error NoSuchCommit();
    error OutOfDatePrice();

    event Commited(
        bytes32 indexed commitedHash, uint256 stakedAmount/* , int224 api3Price */
    );
    event Revealed(bytes32 indexed commitedHash, uint8 chain, string project);

    IAPI3 internal constant iAPI3Token =
        IAPI3(0xD5c6e7676aa6753930F5576D69F809094BfA294f);

    mapping(bytes32 => bool) public commits;

    constructor() {
        iAPI3Token.updateBurnerStatus(true);
    }

    function commit(uint256 amount, bytes32 commitHash) public {
        if (!iAPI3Token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferReverted();
        }
        iAPI3Token.burn(amount);
        bytes32 commitHash_ = keccak256(abi.encodePacked(amount, commitHash));
        commits[commitHash_] = true;

        emit Commited(commitHash_, amount);
    }

    function reveal(
        uint8 chain,
        string memory project,
        string memory secret,
        uint256 amount
    ) public {
        bytes32 commitHash = keccak256(
            abi.encodePacked(
                amount,
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        chain,
                        keccak256(abi.encodePacked(project)),
                        keccak256(abi.encodePacked(secret))
                    )
                )
            )
        );
        if (!commits[commitHash]) revert NoSuchCommit();
        commits[commitHash] = false;
        emit Revealed(commitHash, chain, project);
    }
}