// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/***************************
 *      Aura Raffle        *
 *  Community prize vault  *
 *    By: Aura Exchange    *
 **************************/

 import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

contract AuraRaffle {
    address public owner;
    address public deployer;
    address payable[] public players;
    uint public AuraRaffleId;
    mapping (uint => address payable) public AuraRaffleHistory;

    constructor() {
        deployer = msg.sender;
        owner = msg.sender;
        AuraRaffleId = 1;
    }

    function getWinnerByAuraRaffle(uint auraRaffle) public view returns (address payable) {
        return AuraRaffleHistory[auraRaffle];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > 25 ether);

        // address of player entering AuraRaffle
        players.push(payable(msg.sender));
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

        function _canSetPlatformFeeInfo() internal virtual returns (bool) {
        return msg.sender == deployer;
    }

    function pickWinner() public onlyowner {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance);

        AuraRaffleHistory[AuraRaffleId] = players[index];
        AuraRaffleId++;
        

        // reset the state of the contract
        players = new address payable[](0);
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPlatformFee.sol";

/**
 *  @title   Platform Fee
 *  @notice  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about platform fees, if desired.
 */

abstract contract PlatformFee is IPlatformFee {
    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;

    /// @dev The flat amount collected by the contract as fees on primary sales.
    uint256 private flatPlatformFee;

    /// @dev Fee type variants: percentage fee and flat fee
    PlatformFeeType private platformFeeType;

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view override returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /// @dev Returns the platform fee bps and recipient.
    function getFlatPlatformFeeInfo() public view returns (address, uint256) {
        return (platformFeeRecipient, flatPlatformFee);
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeType() public view returns (PlatformFeeType) {
        return platformFeeType;
    }

    /**
     *  @notice         Updates the platform fee recipient and bps.
     *  @dev            Caller should be authorized to set platform fee info.
     *                  See {_canSetPlatformFeeInfo}.
     *                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.
     *
     *  @param _platformFeeRecipient   Address to be set as new platformFeeRecipient.
     *  @param _platformFeeBps         Updated platformFeeBps.
     */
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external override {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Sets the platform fee recipient and bps
    function _setupPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        if (_platformFeeBps > 10_000) {
            revert("Exceeds max bps");
        }

        platformFeeBps = uint16(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @notice Lets a module admin set a flat fee on primary sales.
    function setFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) external {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }

        _setupFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }

    /// @dev Sets a flat fee on primary sales.
    function _setupFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) internal {
        flatPlatformFee = _flatFee;
        platformFeeRecipient = _platformFeeRecipient;

        emit FlatPlatformFeeUpdated(_platformFeeRecipient, _flatFee);
    }

    /// @notice Lets a module admin set platform fee type.
    function setPlatformFeeType(PlatformFeeType _feeType) external {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        platformFeeType = _feeType;

        emit PlatformFeeTypeUpdated(_feeType);
    }

    /// @dev Sets platform fee type.
    function _setupPlatformFeeType(PlatformFeeType _feeType) internal {
        platformFeeType = _feeType;

        emit PlatformFeeTypeUpdated(_feeType);
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about platform fees, if desired.
 */

interface IPlatformFee {
    /// @dev Fee type variants: percentage fee and flat fee
    enum PlatformFeeType {
        Bps,
        Flat
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when the flat platform fee is updated.
    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    /// @dev Emitted when the platform fee type is updated.
    event PlatformFeeTypeUpdated(PlatformFeeType feeType);
}