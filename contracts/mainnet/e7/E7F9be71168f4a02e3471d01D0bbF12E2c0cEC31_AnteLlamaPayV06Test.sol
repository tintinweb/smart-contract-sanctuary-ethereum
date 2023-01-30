// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "../libraries/ante-v06-core/AnteTest.sol";

interface ILlamaPayFactory {
    function getLlamaPayContractByToken(address _token) external view returns (address, bool);
}

interface ILlamaPay {
    function payers(address _payer) external view returns (uint40, uint216);
}

/// @title  LlamaPay never goes backwards in time test
/// @notice Ante Test to check that lastPayerUpdate <= block.timestamp holds
///         for any LlamaPay payer/token. Uses the setter functions provided to
///         set the LlamaPay instance and payer to check.
///         Note: may no longer hold after 231,800 A.D. due to holding timestamp in uint40
contract AnteLlamaPayV06Test is
    AnteTest("LlamaPay never pays future payments early (lastPayerUpdate[anyone] <= block.timestamp) (V06)")
{
    // Eth Mainnet: https://etherscan.io/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // Polygon: https://polygonscan.com/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // BSC: https://bscscan.com/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // Fantom: https://ftmscan.com/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // Arbitrum: https://arbiscan.io/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // Optimism: https://optimistic.etherscan.io/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // Gnosis/xDai: https://gnosisscan.io/address/0xde1C04855c2828431ba637675B6929A684f84C7F
    // Avax C-Chain: https://snowtrace.io/address/0x7D507B4C2d7e54dA5731F643506996Da8525f4A3
    // https://docs.llamapay.io/technical-stuff/contracts for more chains
    ILlamaPayFactory internal factory;

    address public tokenAddress;
    address public payerAddress;

    constructor(address _llamaPayFactoryAddress) {
        factory = ILlamaPayFactory(_llamaPayFactoryAddress);

        protocolName = "LlamaPay"; // <3
        testedContracts.push(_llamaPayFactoryAddress);
        testedContracts.push(address(0)); // LlamaPay instance once set
    }

    function getStateTypes() external pure override returns (string memory) {
        return "address,address";
    }

    function getStateNames() external pure override returns (string memory) {
        return "tokenAddress,payerAddress";
    }

    /// @notice Checks that lastPayerUpdate[payer] <= block.timestamp for a
    ///         given payer and LlamaPay instance. Uses the setter functions
    ///         provided to set the token address and payer address to check.
    /// @return true if lastPayerUpdate[payer] <= block.timestamp for the
    ///         LlamaPay instance and payer checked
    function checkTestPasses() public view override returns (bool) {
        // If a valid LlamaPay instance is specified, check it
        (address predictedAddress, bool isDeployed) = factory.getLlamaPayContractByToken(tokenAddress);
        if (isDeployed) {
            (uint40 lastPayerUpdate, ) = ILlamaPay(predictedAddress).payers(payerAddress);

            // We don't need to worry about checking if the payer exists in the
            // payer mapping for this LlamaPay instance since 0 < block.timestamp
            return (lastPayerUpdate <= block.timestamp);
        }

        // If invalid LlamaPay address passed in, test will still pass
        return true;
    }

    function _setState(bytes memory _state) internal override {
        // Could check that valid payer mapping exists, but also, an invalid
        // payer address doesn't fail the test so no risk of false positive.
        (address _tokenAddress, address _payerAddress) = abi.decode(_state, (address, address));

        // Check that LlamaPay instance exists for the token
        (address predictedAddress, bool isDeployed) = factory.getLlamaPayContractByToken(_tokenAddress);
        require(isDeployed, "ANTE: LlamaPay instance not deployed for that token");
        testedContracts[1] = predictedAddress;
        tokenAddress = _tokenAddress;
        payerAddress = _payerAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "./interfaces/IAnteTest.sol";

/// @title Ante V0.6 Ante Test smart contract
/// @notice Abstract inheritable contract that supplies syntactic sugar for writing Ante Tests
/// @dev Usage: contract YourAnteTest is AnteTest("String descriptor of test") { ... }
abstract contract AnteTest is IAnteTest {
    /// @inheritdoc IAnteTest
    address public override testAuthor;
    /// @inheritdoc IAnteTest
    string public override testName;
    /// @inheritdoc IAnteTest
    string public override protocolName;
    /// @inheritdoc IAnteTest
    address[] public override testedContracts;

    /// @dev testedContracts and protocolName are optional parameters which should
    /// be set in the constructor of your AnteTest
    /// @param _testName The name of the Ante Test
    constructor(string memory _testName) {
        testAuthor = msg.sender;
        testName = _testName;
    }

    /// @inheritdoc IAnteTest
    function setStateAndCheckTestPasses(bytes memory _state) external override returns (bool) {
        if (_state.length > 0) {
            _setState(_state);
        }
        return checkTestPasses();
    }

    /// @notice Returns the testedContracts array of addresses
    /// @return The list of tested contracts as an array of addresses
    function getTestedContracts() external view returns (address[] memory) {
        return testedContracts;
    }

    /// @inheritdoc IAnteTest
    function setTestAuthor(address _testAuthor) external {
        require(msg.sender == testAuthor, "Only the current testAuthor can set a new test author");
        require(_testAuthor != address(0), "ANTE: Test author cannot be the zero address");
        address previousAuthor = testAuthor;
        testAuthor = _testAuthor;

        emit TestAuthorChanged(previousAuthor, _testAuthor);
    }

    /// @inheritdoc IAnteTest
    function getStateTypes() external pure virtual override returns (string memory) {
        return "";
    }

    /// @inheritdoc IAnteTest
    function getStateNames() external pure virtual override returns (string memory) {
        return "";
    }

    /// @inheritdoc IAnteTest
    function checkTestPasses() public virtual override returns (bool passes) {}

    /// @notice Function containing the logic to set the AnteTest state
    function _setState(bytes memory) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

/// @title The interface for the Ante V0.6 Ante Test
/// @notice The Ante V0.6 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Emitted when the test author is changed
    /// @param previousAuthor The address of the previous author
    /// @param newAuthor The address of the new author
    event TestAuthorChanged(address indexed previousAuthor, address indexed newAuthor);

    /// @notice Function containing the logic to set the AnteTest state and call checkTestPasses
    /// @param _state The encoded data required to set the test state
    /// @return A single bool indicating if the Ante Test passes/fails
    function setStateAndCheckTestPasses(bytes memory _state) external returns (bool);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);

    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Sets the author of the Ante Test
    /// @dev This can only be called by the current author, which is the deployer initially
    /// @param _testAuthor The address of the test author
    function setTestAuthor(address _testAuthor) external;

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Returns a string of comma delimited types used for setting the AnteTest state
    /// @return The types of the state variables
    function getStateTypes() external pure returns (string memory);

    /// @notice Returns a string of comma delimited names used for setting the AnteTest state
    /// @return The names of the state variables
    function getStateNames() external pure returns (string memory);
}