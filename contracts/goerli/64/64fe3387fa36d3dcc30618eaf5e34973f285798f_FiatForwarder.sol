// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IABBLegacy.sol";
import "./LibMintpass.sol";

contract FiatForwarder {
    address internal receivingContract =
        0xEdB1336bB53fa2516856Fc962e9AAd10DB3F2553;

    /**
     * @dev ERC721A Constructor
     */
    constructor() {}

    function mint(address _minter, uint256 _quantity) public payable {
        IABBLegacy(receivingContract).mint{value: msg.value}(
            _minter,
            _quantity
        );
    }

    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable {
        IABBLegacy(receivingContract).allowlistMint{value: msg.value}(
            quantity,
            mintpass,
            mintpassSignature
        );
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