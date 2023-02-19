// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./wagers/IWagerModule.sol";

/**
 @title IEquityModule
 @author Henry Wrightman

 @notice Interface for wager equity
 */

interface IEquityModule {
    function acceptEquity(bytes memory equityData) external payable;

    function acceptCounterEquity(
        bytes memory partyTwoData,
        Wager memory wager
    ) external payable returns (Wager memory);

    function settleEquity(
        bytes memory parties,
        bytes memory equityData,
        address recipient
    ) external returns (uint256);

    function voidEquity(bytes memory parties, bytes memory equityData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../wagers/IWagerModule.sol";

/**
 @title IWagerOracleModule
 @author Henry Wrightman

 @notice interface for wager's oracle module (e.g ChainLinkOracleModule)
 */

interface IWagerOracleModule {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracleModule.sol";

/**
 @title IWagerModule
 @author Henry Wrightman

 @notice Interface for wagers
 */

interface IWagerModule {
    // -- methods --
    function settle(
        Wager memory wager
    ) external returns (Wager memory, address);
}

// -- structs --
struct Wager {
    bytes parties; // party data; |partyOne|partyTwo|
    bytes partyOneWagerData; // wager data for wager module to discern; e.g |wagerStart|wagerValue|
    bytes partyTwoWagerData;
    bytes equityData; // wager equity data; |WagerType|ercContractAddr(s)|amount(s)|tokenId(s)|
    bytes blockData; // blocktime data; |created|expiration|enterLimit|
    bytes result; // wager outcome
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracleModule oracleModule; // oracle module semantics
    address oracleSource; // oracle source
    bytes supplementalOracleData; // supplemental wager oracle data
}

// -- wager type
enum WagerType {
    oneSided,
    twoSided
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IEquityModule.sol";
import "../interfaces/wagers/IWagerModule.sol";

/**
 @title EquityModule
 @author Henry Wrightman

 @notice equity module to handle equity data & settlements for a registry

 TODO: make gated only by registry
 */

contract EquityModule is IEquityModule {
    bytes4 private ERC721_ID = 0x80ac58cd;

    /// @notice acceptEquity
    /// @dev handles the creator party's equity creating a wager
    /// @param equityData wager's equity data
    function acceptEquity(bytes memory equityData) external payable override {
        (
            ,
            address[2] memory ercInterfaces,
            uint256 amount,
            uint256[2] memory ids
        ) = decodeWagerEquity(equityData);
        require(msg.value == amount, "W9");

        if (ercInterfaces[0] != address(0)) {
            (bool success, bytes memory addressData) = ercInterfaces[0].call(
                abi.encodeWithSignature("getApproved(uint256)", ids[0])
            );
            require(
                success && abi.decode(addressData, (address)) == address(this),
                "W20"
            );
            (bool valid, ) = ercInterfaces[0].call(
                abi.encodeWithSignature("supportsInterface(bytes4)", ERC721_ID)
            );
            require(valid, "W22");
        }
    }

    /// @notice acceptCounterEquity
    /// @dev handles the counter party's equity entering a wager
    /// @param partyTwoEquityData party two's equity data
    /// @param wager wager being entered
    /// @return wager updated wager w accepted counter party & their equity
    function acceptCounterEquity(
        bytes memory partyTwoEquityData,
        Wager memory wager
    ) external payable override returns (Wager memory) {
        (address ercInterface, uint256 id) = abi.decode(
            partyTwoEquityData,
            (address, uint256)
        );
        (
            WagerType style,
            address[2] memory ercInterfaces,
            uint256 amount,
            uint256[2] memory ids
        ) = decodeWagerEquity(wager.equityData);
        if (ercInterfaces[0] == address(0)) {
            require(msg.value == amount, "W9");
            require(ercInterface == address(0), "W21");
        }
        if (ercInterface != address(0)) {
            (bool success, bytes memory addressData) = ercInterface.call(
                abi.encodeWithSignature("getApproved(uint256)", id)
            );
            require(
                success && abi.decode(addressData, (address)) == address(this),
                "W20"
            );
            (bool valid, ) = ercInterface.call(
                abi.encodeWithSignature("supportsInterface(bytes4)", ERC721_ID)
            );
            require(valid, "W22");
        }
        wager.equityData = abi.encode(
            style,
            [ercInterfaces[0], ercInterface],
            amount,
            [ids[0], id]
        );
        return wager;
    }

    /// @notice settleEquity
    /// @dev handles the equity settlment of a wager being settled
    /// @param parties wager parties
    /// @param equityData wager equity data
    /// @param recipient address of recipient recieving settled funds
    /// @return settledAmount uint256 amount settled
    function settleEquity(
        bytes memory parties,
        bytes memory equityData,
        address recipient
    ) external override returns (uint256) {
        (
            WagerType style,
            address[2] memory ercInterfaces,
            uint256 amount,
            uint256[2] memory ids
        ) = decodeWagerEquity(equityData);
        uint256 winnings = style == WagerType.twoSided ? (amount * 2) : amount;
        if (ercInterfaces[0] == address(0)) {
            (bool sent, ) = recipient.call{value: winnings, gas: 3600}("");
            require(sent, "W11");
        } else {
            (address partyOne, address partyTwo) = decodeParties(parties);
            bytes memory data = abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                partyOne == recipient ? partyTwo : partyOne,
                recipient,
                partyOne == recipient ? ids[1] : ids[0]
            );
            (bool sent, ) = ercInterfaces[partyOne == recipient ? 0 : 1].call(
                data
            );
            require(sent, "W11");
        }
        return winnings;
    }

    /// @notice voidEquity
    /// @dev handles the equity distribution of a wager being voided
    /// @param parties wager parties
    /// @param equityData wager equity data
    function voidEquity(
        bytes memory parties,
        bytes memory equityData
    ) external override {
        (
            WagerType style,
            address[2] memory ercInterfaces,
            uint256 amount,

        ) = decodeWagerEquity(equityData);
        (address partyOne, address partyTwo) = decodeParties(parties);

        if (ercInterfaces[0] == address(0)) {
            (bool sent, ) = partyOne.call{value: amount}("");
            require(sent, "W6");
            if (partyTwo != address(0) && style == WagerType.twoSided) {
                (bool sentTwo, ) = partyTwo.call{value: amount}("");
                require(sentTwo, "W6");
            }
        }
    }

    /// @notice decodeWagerEquity
    /// @dev Wager's equitiy data consists of <style> (WagerStyle) <ercInterface> (address) <amount> (uint256) [** potentially <ids> (uint256) **]
    /// @param data wager equity data be decoded
    /// @return style WagerType (int) oneSided vs twoSided
    /// @return ercContracts address[1] ; 2 address slots for NFTs
    /// @return amount uint256 amount
    /// @return ids uint256[1] ; 2 id slots for NFTs
    function decodeWagerEquity(
        bytes memory data
    )
        public
        pure
        returns (
            WagerType style,
            address[2] memory ercContracts,
            uint256 amount,
            uint256[2] memory ids
        )
    {
        (style, ercContracts, amount, ids) = abi.decode(
            data,
            (WagerType, address[2], uint256, uint256[2])
        );
    }

    /// @notice decodeParties
    /// @dev Wager's party data consists of <partyOne> (address) and <partyTwo> address
    /// @param data wager address data be decoded
    /// @return partyOne address
    /// @return partyTwo address
    function decodeParties(
        bytes memory data
    ) public pure returns (address partyOne, address partyTwo) {
        (partyOne, partyTwo) = abi.decode(data, (address, address));
    }
}