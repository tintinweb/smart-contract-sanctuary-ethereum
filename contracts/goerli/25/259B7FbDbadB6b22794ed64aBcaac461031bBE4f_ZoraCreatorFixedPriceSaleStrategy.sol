// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICreatorCommands {
  enum CreatorActions {
    NO_OP,
    SEND_ETH,
    MINT
  }

  struct Command {
    CreatorActions method;
    bytes args;
  }

  struct CommandSet {
    Command[] commands;
    uint256 at;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorCommands} from "./ICreatorCommands.sol";


interface IMinter1155 {
    function requestMint(
        address sender,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVersionedContract {
  function contractVersion() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorCommands} from "../interfaces/ICreatorCommands.sol";

library SaleCommandHelper {
    function setSize(ICreatorCommands.CommandSet memory commandSet, uint256 size) pure internal {
        commandSet.commands = new ICreatorCommands.Command[](size);
    }

    /// todo: should tokenid be removed
    function mint(
        ICreatorCommands.CommandSet memory commandSet,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) pure internal {
        unchecked {
            commandSet.commands[commandSet.at++] = ICreatorCommands.Command({
                method: ICreatorCommands.CreatorActions.MINT,
                args: abi.encode(to, tokenId, quantity)
            });
        }
    }

    function transfer(
        ICreatorCommands.CommandSet memory commandSet,
        address to,
        uint256 amount
    ) pure internal {
        unchecked {
            commandSet.commands[commandSet.at++] = ICreatorCommands.Command({method: ICreatorCommands.CreatorActions.SEND_ETH, args: abi.encode(to, amount)});
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IVersionedContract} from "../interfaces/IVersionedContract.sol";
import {ICreatorCommands} from "../interfaces/ICreatorCommands.sol";
import {SaleCommandHelper} from "./SaleCommandHelper.sol";

abstract contract SaleStrategy is IMinter1155, IVersionedContract {
    function contractURI() external virtual returns (string memory);

    function contractName() external virtual returns (string memory);

    function contractVersion() external virtual returns (string memory);

    function resetSale(uint256 tokenId) external virtual;

    function _getKey(address mediaContract, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encode(mediaContract, tokenId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMinter1155} from "../../interfaces/IMinter1155.sol";
import {ICreatorCommands} from "../../interfaces/ICreatorCommands.sol";
import {TransferHelperUtils} from "../../utils/TransferHelperUtils.sol";
import {SaleStrategy} from "../SaleStrategy.sol";
import {SaleCommandHelper} from "../SaleCommandHelper.sol";

contract ZoraCreatorFixedPriceSaleStrategy is SaleStrategy {
    struct SalesConfig {
        uint64 saleStart;
        uint64 saleEnd;
        uint64 maxTokensPerAddress;
        uint96 pricePerToken;
        address fundsRecipient;
    }
    mapping(bytes32 => SalesConfig) internal salesConfigs;
    mapping(bytes32 => uint256) internal mintedPerAddress;

    using SaleCommandHelper for ICreatorCommands.CommandSet;

    function contractURI() external pure override returns (string memory) {
        // TODO(iain): Add contract URI configuration json for front-end
        return "";
    }

    function contractName() external pure override returns (string memory) {
        return "Fixed Price Sale Strategy";
    }

    function contractVersion() external pure override returns (string memory) {
        return "0.0.1";
    }

    error WrongValueSent();
    error SaleEnded();
    error SaleHasNotStarted();
    error MintedTooManyForAddress();
    error TooManyTokensInOneTxn();

    event SaleSet(address mediaContract, uint256 tokenId, SalesConfig salesConfig);

    function requestMint(
        address,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands) {
        address mintTo = abi.decode(minterArguments, (address));

        SalesConfig memory config = salesConfigs[_getKey(msg.sender, tokenId)];

        // If sales config does not exist this first check will always fail.

        // Check sale end
        if (block.timestamp > config.saleEnd) {
            revert SaleEnded();
        }

        // Check sale start
        if (block.timestamp < config.saleStart) {
            revert SaleHasNotStarted();
        }

        // Check value sent
        if (config.pricePerToken * quantity != ethValueSent) {
            revert WrongValueSent();
        }

        // Check minted per address limit
        if (config.maxTokensPerAddress > 0) {
            bytes32 key = keccak256(abi.encode(msg.sender, tokenId, mintTo));
            mintedPerAddress[key] += quantity;
            if (config.maxTokensPerAddress > mintedPerAddress[key]) {
                revert MintedTooManyForAddress();
            }
        }

        bool shouldTransferFunds = config.fundsRecipient != address(0);
        commands.setSize(shouldTransferFunds ? 2 : 1);

        // Mint command
        commands.mint(mintTo, tokenId, quantity);

        // Should transfer funds if funds recipient is set to a non-default address
        if (shouldTransferFunds) {
            commands.transfer(config.fundsRecipient, ethValueSent);
        }
    }

    function setSale(uint256 tokenId, SalesConfig memory salesConfig) external {
        salesConfigs[_getKey(msg.sender, tokenId)] = salesConfig;

        // Emit event
        emit SaleSet(msg.sender, tokenId, salesConfig);
    }

    function resetSale(uint256 tokenId) external override {
        delete salesConfigs[_getKey(msg.sender, tokenId)];

        // Deleted sale emit event
        emit SaleSet(msg.sender, tokenId, salesConfigs[_getKey(msg.sender, tokenId)]);
    }

    function sale(address tokenContract, uint256 tokenId) external view returns (SalesConfig memory) {
        return salesConfigs[_getKey(tokenContract, tokenId)];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library TransferHelperUtils {
    /// @dev Gas limit to send funds
    uint256 internal constant FUNDS_SEND_LOW_GAS_LIMIT = 110_000;

    // @dev Gas limit to send funds – usable for splits, can use with withdraws
    uint256 internal constant FUNDS_SEND_GAS_LIMIT = 310_000;

    function safeSendETHLowLimit(address recipient, uint256 value)
        internal
        returns (bool success)
    {
        (success, ) = recipient.call{
            value: value,
            gas: FUNDS_SEND_LOW_GAS_LIMIT
        }("");
    }

    function safeSendETH(address recipient, uint256 value)
        internal
        returns (bool success)
    {
        (success, ) = recipient.call{value: value, gas: FUNDS_SEND_GAS_LIMIT}(
            ""
        );
    }
}