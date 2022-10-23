// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./MyContract.sol";

contract Ape is MyContract {

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./MyContract.sol";

contract Yessy is MyContract {

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

import "./MyContract.sol";

contract Vyper is MyContract {

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

import "./MyContract.sol";

contract VisibleFriends is MyContract {

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

import "./MyContract.sol";

contract Three is MyContract {

    struct ArtConstructorParameters {
        address initialRoyaltyReceiver;
        string contractName;
        string contractSymbol;
        string initialContractURI;
        uint96 initialRoyaltyFees;
    }

    ArtConstructorParameters public sArtConstructorArguments;

    constructor(ArtConstructorParameters memory _artConstructorArguments) {
        sArtConstructorArguments = _artConstructorArguments;
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

import "./MyContract.sol";

contract Ten is MyContract {

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

import "./MyContract.sol";

contract Sunday is MyContract {

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

import "./MyContract.sol";

contract Solidity is MyContract {

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

import "./MyContract.sol";

contract SolVy is MyContract {

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

import "./MyContract.sol";

contract Rarible is MyContract {
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

import "./MyContract.sol";

contract One is MyContract {

    uint256 public sOne;

    constructor(uint256 _one) {
        sOne = _one;
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

import "./MyContract.sol";

contract NFT1 is MyContract {
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

import "./MyContract.sol";

contract MyContract77 is MyContract {
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

import "./MyContract.sol";

contract MyContract21 is MyContract {
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

import "./MyContract.sol";

contract Johny is MyContract {

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

import "./MyContract.sol";

contract InvisibleFriends is MyContract {

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

import "./MyContract.sol";

contract Huff is MyContract {

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

import "./MyContract.sol";

contract Hi is MyContract {

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

import "./MyContract.sol";

contract Goerli is MyContract {

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

import "./MyContract.sol";

contract Fadfseqaaxxaz is MyContract {

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

import "./MyContract.sol";

contract Fadfseqaaxxa is MyContract {

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

import "./MyContract.sol";

contract Fadfseqaaxx is MyContract {

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

import "./MyContract.sol";

contract Fadfseqaax is MyContract {

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

import "./MyContract.sol";

contract Fadfseqaa is MyContract {

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

import "./MyContract.sol";

contract Fadfseqa is MyContract {

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

import "./MyContract.sol";

contract Fadfseq is MyContract {

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

import "./MyContract.sol";

contract Fadfs is MyContract {

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

import "./MyContract.sol";

contract FFAS is MyContract {

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

import "./MyContract.sol";

contract FDFS is MyContract {

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

import "./MyContract.sol";

contract Eererv is MyContract {

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

import "./MyContract.sol";

contract Eerer is MyContract {

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

import "./MyContract.sol";

contract ContractTwo is MyContract {

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

import "./MyContract.sol";

contract ContractOne is MyContract {

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

import "./MyContract.sol";

contract Contract is MyContract {

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

import "./MyContract.sol";

contract Asfasfqjazxc is MyContract {

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

import "./MyContract.sol";

contract Asfasfqjazx is MyContract {

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

import "./MyContract.sol";

contract Asfasfqjaz is MyContract {

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

import "./MyContract.sol";

contract Asfasfqja is MyContract {

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

import "./MyContract.sol";

contract Asfasfqj is MyContract {

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

import "./MyContract.sol";

contract Asfasfq is MyContract {

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