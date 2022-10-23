// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./MyContract.sol";

contract Nosy is MyContract {

    struct ArtConstructorParameters {
        address initialRoyaltyReceiver;
        string contractName;
        string contractSymbol;
        string initialContractURI;
        uint96 initialRoyaltyFees;
    }

    ArtConstructorParameters public sArtConstructorParameters;

    constructor(ArtConstructorParameters memory _artConstructorParameters) {
        sArtConstructorParameters = _artConstructorParameters;
    }

    function getMul(uint256 _num1, uint256 _num2)
        external
        pure
        returns (uint256)
    {
        return _num1 * _num2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract MyContract {
    function getSum(uint256 _num1, uint256 _num2)
        external
        pure
        returns (uint256)
    {
        return _num1 + _num2;
    }
}