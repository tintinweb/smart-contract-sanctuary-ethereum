// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IABBLegacy.sol";
import "./LibMintpass.sol";

/** This contract is used as a Proxy for FIAT Payments on Bowline.app.
 * The Contract itself is quite generic and changes from project to project.
 * Payments are initiated by a off chain payment validator.
 *
 * If you have further question on this contract feel Free to contact us on support[at]bowline.app.
 *
 */
contract BowlineFiatGateway {
    address public receivingContract;

    address internal VERIFIER_WALLET;

    address internal TRANSACTION_WALLET;

    uint256 public MINT_LIMIT = 50;
    uint256 public gatewayMints;

    address internal OWNER_WALLET;

    constructor() {
        OWNER_WALLET = msg.sender;
        VERIFIER_WALLET = msg.sender;
        TRANSACTION_WALLET = msg.sender;
    }

    function mint(address _minter, uint256 _quantity)
        public
        onlyFiatGateway
    {
        require(MINT_LIMIT >= gatewayMints + _quantity, "Bowline Fiat Gateway: Mint Limit Reached");
        require(receivingContract != address(0), "Bowline Fiat Gateway: No Receiving Contract defined");

        IABBLegacy(receivingContract).fiatMint(_minter, _quantity);
        gatewayMints += _quantity;
    }

    function setGatewayWallets(
        address _VERIFIER_WALLET,
        address _TRANSACTION_WALLET
    ) external onlyOwner {
        TRANSACTION_WALLET = _TRANSACTION_WALLET;
        VERIFIER_WALLET = _VERIFIER_WALLET;
    }

    function setMintLimit(uint256 _MINT_LIMIT)
        external
        onlyOwner
    {
        MINT_LIMIT = _MINT_LIMIT;
    }

    function setReceivingContract(address _receivingContract)
        external
        onlyOwner
    {
        receivingContract = _receivingContract;
    }

    modifier onlyFiatGateway() {
        require(
            (msg.sender == VERIFIER_WALLET || msg.sender == TRANSACTION_WALLET),
            "Bowline Fiat Gateway: Payment Provider is unkown."
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == OWNER_WALLET,
            "Bowline Fiat Gateway: You need to be Owner to call this function."
        );

        _;
    }
}

/** created with bowline.app **/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Mintpass Struct definition used to validate EIP712.
 *
 * {minterAddress} is the mintpass owner (It's reommenced to
 * check if it matches msg.sender in your call function)
 * {minterCategory} determines what type of minter is calling:
 * (1, default) AllowList
 */
library LibMintpass {
    bytes32 private constant MINTPASS_TYPE =
        keccak256(
            "Mintpass(address wallet,uint256 tier)"
        );

    struct Mintpass {
        address wallet;
        uint256 tier;
    }

    function mintpassHash(Mintpass memory mintpass) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINTPASS_TYPE,
                    mintpass.wallet,
                    mintpass.tier
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibMintpass.sol";

interface IABBLegacy {
    function mint(address minter, uint256 quantity) external payable;

    function fiatMint(address minter, uint256 quantity) external;

    function redeemBottle(uint256 tokenId) external payable;

    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) external payable;
}

/** created with bowline.app **/