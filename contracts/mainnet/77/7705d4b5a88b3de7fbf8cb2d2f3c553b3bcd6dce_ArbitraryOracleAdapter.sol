// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IOracle.sol";

contract ArbitraryOracleAdapter is IOracle {
    int256 lastestAnswer;
    /// @dev asset name
    string public assetName;

    /// @dev asset symbol
    string public assetSymbol;
    /// @dev admin allowed to update price oracle
    /// @notice the asset with the price oracle
    address public immutable asset;
    address public owner;
    /// @notice The admin

    /// @dev new owner
    address internal newOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        int256 _price,
        address _owner
    ) {
        assetName = _assetName;
        assetSymbol = _assetSymbol;
        asset = _asset;
        lastestAnswer = _price;
        owner = _owner;
    }

    function setPrice(int256 _newPrice) external onlyOwner {
        int256 _lastPrice = lastestAnswer;
        lastestAnswer = _newPrice;
        emit PriceSetted(_lastPrice, _newPrice);
    }

    function latestAnswer() external view override returns (int256) {
        return lastestAnswer;
    }

    function viewPriceInUSD() external view returns (int256) {
        return lastestAnswer;
    }

    /// @notice accept transfer of control
    function acceptOwnership() external {
        require(msg.sender == newOwner, "invalid owner");

        // emit event before state change to do not trigger null address
        emit OwnershipAccepted(owner, newOwner, block.timestamp);

        owner = newOwner;
        newOwner = address(0);
    }

    /// @notice Transfer control from current owner address to another
    /// @param _newOwner The new team
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_NEW_OWNER");
        newOwner = _newOwner;
        emit TransferControl(_newOwner, block.timestamp);
    }

    event OwnershipAccepted(address prevOwner, address newOwner, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event PriceSetted(int256 prevPrice, int256 newPrice);
}