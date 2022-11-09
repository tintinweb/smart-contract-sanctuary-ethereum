// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IABBLegacy.sol";
import "./LibMintpass.sol";

/** This contract is used as a Proxy for FIAT Payments on Bowline.app.
 * Most projects can directly interact with the contract also for FIAT Payments,
 * however, if you as a creator want to cover the Conversion and Payment Fees
 * for a minter partly this is a required intermediary Contract.
 *
 * However, the rationale behind this contract is: A different wallet could verify
 * while the sender address is a cold wallet for example. 
 *
 * If you have further question on this contract feel Free to contact us on support[at]bowline.app.
 *
 */
contract BowlineFiatForwarder {
    address internal receivingContract =
        0xEdB1336bB53fa2516856Fc962e9AAd10DB3F2553;

    address internal VERIFIER_WALLET =
        0x8bCd863AF95bCDFBD3434810A99BCf87A0F0c41B;

    address internal TRANSACTION_WALLET =
        0x8bCd863AF95bCDFBD3434810A99BCf87A0F0c41B;

    bool internal providerCheckEnabled = false;

    address internal OWNER_WALLET;

    /**
     * @dev ERC721A Constructor
     */
    constructor() {
        OWNER_WALLET = msg.sender;
    }

    function mint(address _minter, uint256 _quantity)
        public
        payable
        onlyFiatWallets
    {
        IABBLegacy(receivingContract).mint{value: msg.value}(
            _minter,
            _quantity
        );
    }

    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable onlyFiatWallets {
        IABBLegacy(receivingContract).allowlistMint{value: msg.value}(
            quantity,
            mintpass,
            mintpassSignature
        );
    }

    function setFiatWallets(
        address _VERIFIER_WALLET,
        address _TRANSACTION_WALLET
    ) external onlyOwner {
        TRANSACTION_WALLET = _TRANSACTION_WALLET;
        VERIFIER_WALLET = _VERIFIER_WALLET;
    }

    function setPaymentProviderCheck(bool _providerCheckEnabled)
        external
        onlyOwner
    {
        providerCheckEnabled = _providerCheckEnabled;
    }

    modifier onlyFiatWallets() {
        if (providerCheckEnabled) {
            require(
                (msg.sender == VERIFIER_WALLET ||
                    msg.sender == TRANSACTION_WALLET),
                "Bowline Fiat Forwarder: Payment Provider is unkown."
            );
        }
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == OWNER_WALLET,
            "Bowline Fiat Forwarder: You need to be Owner to call this function."
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

    function redeemBottle(uint256 tokenId) external payable;

    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) external payable;
}

/** created with bowline.app **/