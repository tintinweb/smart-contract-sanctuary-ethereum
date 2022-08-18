/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC1820Client.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


import "../interface/ERC1820Implementer.sol";

import "../IERC1400.sol";

/**
 * @notice Interface to the extension types
 */
interface IExtensionTypes {
  enum CertificateValidation {
    None,
    NonceBased,
    SaltBased
  }
}

interface IERC1400Extended {
    // Not a real interface but added here for functions which don't belong to IERC1400

    function owner() external view returns (address);

    function controllers() external view returns (address[] memory);

    function totalPartitions() external view returns (bytes32[] memory);

    function getDefaultPartitions() external view returns (bytes32[] memory);

    function totalSupplyByPartition(bytes32 partition) external view returns (uint256);
}

abstract contract IERC1400TokensValidatorExtended is IExtensionTypes {
    // Not a real interface but added here for functions which don't belong to IERC1400TokensValidator

    function retrieveTokenSetup(address token) external virtual view returns (CertificateValidation, bool, bool, bool, bool, address[] memory);

    function spendableBalanceOfByPartition(address token, bytes32 partition, address account) external virtual view returns (uint256);

    function isAllowlisted(address token, address account) public virtual view returns (bool);

    function isBlocklisted(address token, address account) public virtual view returns (bool);
}

/**
 * @title BatchReader
 * @dev Proxy contract to read multiple information from the smart contract in a single contract call.
 */
contract BatchReader is IExtensionTypes, ERC1820Client, ERC1820Implementer {
    using SafeMath for uint256;

    string internal constant BALANCE_READER = "BatchReader";

    string constant internal ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";

    // Mapping from token to token extension address
    mapping(address => address) internal _extension;

    constructor() public {
        ERC1820Implementer._setInterface(BALANCE_READER);
    }

    /**
     * @dev Get batch of token supplies.
     * @return Batch of token supplies.
     */
    function batchTokenSuppliesInfos(address[] calldata tokens) external view returns (uint256[] memory, uint256[] memory, bytes32[] memory, uint256[] memory, uint256[] memory, bytes32[] memory) {
        uint256[] memory batchTotalSupplies = new uint256[](tokens.length);
        for (uint256 j = 0; j < tokens.length; j++) {
            batchTotalSupplies[j] = IERC20(tokens[j]).totalSupply();
        }

        (uint256[] memory totalPartitionsLengths, bytes32[] memory batchTotalPartitions, uint256[] memory batchPartitionSupplies) = batchTotalPartitions(tokens);

        (uint256[] memory defaultPartitionsLengths, bytes32[] memory batchDefaultPartitions) = batchDefaultPartitions(tokens);

        return (batchTotalSupplies, totalPartitionsLengths, batchTotalPartitions, batchPartitionSupplies, defaultPartitionsLengths, batchDefaultPartitions);
    }

    /**
     * @dev Get batch of token roles.
     * @return Batch of token roles.
     */
    function batchTokenRolesInfos(address[] calldata tokens) external view returns (address[] memory, uint256[] memory, address[] memory, uint256[] memory, address[] memory) {
        (uint256[] memory batchExtensionControllersLength, address[] memory batchExtensionControllers) = batchExtensionControllers(tokens);

        (uint256[] memory batchControllersLength, address[] memory batchControllers) = batchControllers(tokens);

        address[] memory batchOwners = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            batchOwners[i] = IERC1400Extended(tokens[i]).owner();
        }
        return (batchOwners, batchControllersLength, batchControllers, batchExtensionControllersLength, batchExtensionControllers);
    }

    /**
     * @dev Get batch of token controllers.
     * @return Batch of token controllers.
     */
    function batchControllers(address[] memory tokens) public view returns (uint256[] memory, address[] memory) {
        uint256[] memory batchControllersLength = new uint256[](tokens.length);
        uint256 controllersLength=0;

        for (uint256 i = 0; i < tokens.length; i++) {
            address[] memory controllers = IERC1400Extended(tokens[i]).controllers();
            batchControllersLength[i] = controllers.length;
            controllersLength = controllersLength.add(controllers.length);
        }

        address[] memory batchControllersResponse = new address[](controllersLength);

        uint256 counter = 0;
        for (uint256 j = 0; j < tokens.length; j++) {
            address[] memory controllers = IERC1400Extended(tokens[j]).controllers();

            for (uint256 k = 0; k < controllers.length; k++) {
                batchControllersResponse[counter] = controllers[k];
                counter++;
            }
        }

        return (batchControllersLength, batchControllersResponse);
    }

    /**
     * @dev Get batch of token extension controllers.
     * @return Batch of token extension controllers.
     */
    function batchExtensionControllers(address[] memory tokens) public view returns (uint256[] memory, address[] memory) {
        address[] memory batchTokenExtension = new address[](tokens.length);

        uint256[] memory batchExtensionControllersLength = new uint256[](tokens.length);
        uint256 extensionControllersLength=0;

        for (uint256 i = 0; i < tokens.length; i++) {
            batchTokenExtension[i] = interfaceAddr(tokens[i], ERC1400_TOKENS_VALIDATOR);

            if (batchTokenExtension[i] != address(0)) {
                (,,,,,address[] memory extensionControllers) = IERC1400TokensValidatorExtended(batchTokenExtension[i]).retrieveTokenSetup(tokens[i]);
                batchExtensionControllersLength[i] = extensionControllers.length;
                extensionControllersLength = extensionControllersLength.add(extensionControllers.length);
            } else {
                batchExtensionControllersLength[i] = 0;
            }
        }

        address[] memory batchExtensionControllersResponse = new address[](extensionControllersLength);

        uint256 counter = 0;
        for (uint256 j = 0; j < tokens.length; j++) {
            if (batchTokenExtension[j] != address(0)) {
                (,,,,,address[] memory extensionControllers) = IERC1400TokensValidatorExtended(batchTokenExtension[j]).retrieveTokenSetup(tokens[j]);

                for (uint256 k = 0; k < extensionControllers.length; k++) {
                    batchExtensionControllersResponse[counter] = extensionControllers[k];
                    counter++;
                }
            }
        }

        return (batchExtensionControllersLength, batchExtensionControllersResponse);
    }

    /**
     * @dev Get batch of token extension setup.
     * @return Batch of token extension setup.
     */
    function batchTokenExtensionSetup(address[] calldata tokens) external view returns (address[] memory, CertificateValidation[] memory, bool[] memory, bool[] memory, bool[] memory, bool[] memory) {
        (address[] memory batchTokenExtension, CertificateValidation[] memory batchCertificateActivated, bool[] memory batchAllowlistActivated, bool[] memory batchBlocklistActivated) = batchTokenExtensionSetup1(tokens);

        (bool[] memory batchGranularityByPartitionActivated, bool[] memory batchHoldsActivated) = batchTokenExtensionSetup2(tokens);
        return (batchTokenExtension, batchCertificateActivated, batchAllowlistActivated, batchBlocklistActivated, batchGranularityByPartitionActivated, batchHoldsActivated);
    }

    /**
     * @dev Get batch of token extension setup (part 1).
     * @return Batch of token extension setup (part 1).
     */
    function batchTokenExtensionSetup1(address[] memory tokens) public view returns (address[] memory, CertificateValidation[] memory, bool[] memory, bool[] memory) {
        address[] memory batchTokenExtension = new address[](tokens.length);
        CertificateValidation[] memory batchCertificateActivated = new CertificateValidation[](tokens.length);
        bool[] memory batchAllowlistActivated = new bool[](tokens.length);
        bool[] memory batchBlocklistActivated = new bool[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            batchTokenExtension[i] = interfaceAddr(tokens[i], ERC1400_TOKENS_VALIDATOR);

            if (batchTokenExtension[i] != address(0)) {
                (CertificateValidation certificateActivated, bool allowlistActivated, bool blocklistActivated,,,) = IERC1400TokensValidatorExtended(batchTokenExtension[i]).retrieveTokenSetup(tokens[i]);
                batchCertificateActivated[i] = certificateActivated;
                batchAllowlistActivated[i] = allowlistActivated;
                batchBlocklistActivated[i] = blocklistActivated;
            } else {
                batchCertificateActivated[i] = CertificateValidation.None;
                batchAllowlistActivated[i] = false;
                batchBlocklistActivated[i] = false;
            }
        }

        return (batchTokenExtension, batchCertificateActivated, batchAllowlistActivated, batchBlocklistActivated);
    }

    /**
     * @dev Get batch of token extension setup (part 2).
     * @return Batch of token extension setup (part 2).
     */
    function batchTokenExtensionSetup2(address[] memory tokens) public view returns (bool[] memory, bool[] memory) {
        address[] memory batchTokenExtension = new address[](tokens.length);
        bool[] memory batchGranularityByPartitionActivated = new bool[](tokens.length);
        bool[] memory batchHoldsActivated = new bool[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            batchTokenExtension[i] = interfaceAddr(tokens[i], ERC1400_TOKENS_VALIDATOR);

            if (batchTokenExtension[i] != address(0)) {
                (,,, bool granularityByPartitionActivated, bool holdsActivated,) = IERC1400TokensValidatorExtended(batchTokenExtension[i]).retrieveTokenSetup(tokens[i]);
                batchGranularityByPartitionActivated[i] = granularityByPartitionActivated;
                batchHoldsActivated[i] = holdsActivated;
            } else {
                batchGranularityByPartitionActivated[i] = false;
                batchHoldsActivated[i] = false;
            }
        }

        return (batchGranularityByPartitionActivated, batchHoldsActivated);
    }

    /**
     * @dev Get batch of ERC1400 balances.
     * @return Batch of ERC1400 balances.
     */
    function batchERC1400Balances(address[] calldata tokens, address[] calldata tokenHolders) external view returns (uint256[] memory, uint256[] memory, uint256[] memory, bytes32[] memory, uint256[] memory, uint256[] memory) {
        (,, uint256[] memory batchSpendableBalancesOfByPartition) = batchSpendableBalanceOfByPartition(tokens, tokenHolders);

        (uint256[] memory totalPartitionsLengths, bytes32[] memory batchTotalPartitions, uint256[] memory batchBalancesOfByPartition) = batchBalanceOfByPartition(tokens, tokenHolders);

        uint256[] memory batchBalancesOf = batchBalanceOf(tokens, tokenHolders);

        uint256[] memory batchEthBalances = batchEthBalance(tokenHolders);

        return (batchEthBalances, batchBalancesOf, totalPartitionsLengths, batchTotalPartitions, batchBalancesOfByPartition, batchSpendableBalancesOfByPartition);
    }

    /**
     * @dev Get batch of ERC20 balances.
     * @return Batch of ERC20 balances.
     */
    function batchERC20Balances(address[] calldata tokens, address[] calldata tokenHolders) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory batchBalancesOf = batchBalanceOf(tokens, tokenHolders);

        uint256[] memory batchEthBalances = batchEthBalance(tokenHolders);

        return (batchEthBalances, batchBalancesOf);
    }

    /**
     * @dev Get batch of ETH balances.
     * @return Batch of token ETH balances.
     */
    function batchEthBalance(address[] memory tokenHolders) public view returns (uint256[] memory) {
        uint256[] memory batchEthBalanceResponse = new uint256[](tokenHolders.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            batchEthBalanceResponse[i] = tokenHolders[i].balance;
        }

        return batchEthBalanceResponse;
    }

    /**
     * @dev Get batch of ERC721 balances.
     * @return Batch of ERC721 balances.
     */
    function batchERC721Balances(address[] calldata tokens, address[] calldata tokenHolders) external view returns (uint256[] memory, uint256[][][] memory) {
        uint256[][][] memory batchBalanceOfResponse = new uint256[][][](tokens.length);

        for (uint256 j = 0; j < tokens.length; j++) {
            IERC721Enumerable token = IERC721Enumerable(tokens[j]);
            uint256[][] memory batchBalance = new uint256[][](tokenHolders.length);
            
            for (uint256 i = 0; i < tokenHolders.length; i++) {
                address holder = tokenHolders[i];
                uint256 tokenCount = token.balanceOf(holder);

                uint256[] memory balance = new uint256[](tokenCount);

                for (uint256 k = 0; k < tokenCount; k++) {
                    balance[k] = token.tokenOfOwnerByIndex(holder, k);
                }

                batchBalance[i] = balance;
            }

            batchBalanceOfResponse[j] = batchBalance;
        }

        uint256[] memory batchEthBalances = batchEthBalance(tokenHolders);

        return (batchEthBalances, batchBalanceOfResponse);
    }

    /**
     * @dev Get batch of token balances.
     * @return Batch of token balances.
     */
    function batchBalanceOf(address[] memory tokens, address[] memory tokenHolders) public view returns (uint256[] memory) {
        uint256[] memory batchBalanceOfResponse = new uint256[](tokenHolders.length * tokens.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                batchBalanceOfResponse[i*tokens.length + j] = IERC20(tokens[j]).balanceOf(tokenHolders[i]);
            }
        }

        return batchBalanceOfResponse;
    }

    /**
     * @dev Get batch of partition balances.
     * @return Batch of token partition balances.
     */
    function batchBalanceOfByPartition(address[] memory tokens, address[] memory tokenHolders) public view returns (uint256[] memory, bytes32[] memory, uint256[] memory) {
        (uint256[] memory totalPartitionsLengths, bytes32[] memory batchTotalPartitions,) = batchTotalPartitions(tokens);
        
        uint256[] memory batchBalanceOfByPartitionResponse = new uint256[](tokenHolders.length * batchTotalPartitions.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            uint256 counter = 0;
            for (uint256 j = 0; j < tokens.length; j++) {
                for (uint256 k = 0; k < totalPartitionsLengths[j]; k++) {
                    batchBalanceOfByPartitionResponse[i*batchTotalPartitions.length + counter] = IERC1400(tokens[j]).balanceOfByPartition(batchTotalPartitions[counter], tokenHolders[i]);
                    counter++;
                }
            }
        }

        return (totalPartitionsLengths, batchTotalPartitions, batchBalanceOfByPartitionResponse);
    }

    /**
     * @dev Get batch of spendable partition balances.
     * @return Batch of token spendable partition balances.
     */
    function batchSpendableBalanceOfByPartition(address[] memory tokens, address[] memory tokenHolders) public view returns (uint256[] memory, bytes32[] memory, uint256[] memory) {
        (uint256[] memory totalPartitionsLengths, bytes32[] memory batchTotalPartitions,) = batchTotalPartitions(tokens);
        
        uint256[] memory batchSpendableBalanceOfByPartitionResponse = new uint256[](tokenHolders.length * batchTotalPartitions.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            uint256 counter = 0;
            for (uint256 j = 0; j < tokens.length; j++) {
                address tokenExtension = interfaceAddr(tokens[j], ERC1400_TOKENS_VALIDATOR);

                for (uint256 k = 0; k < totalPartitionsLengths[j]; k++) {
                    if (tokenExtension != address(0)) {
                        batchSpendableBalanceOfByPartitionResponse[i*batchTotalPartitions.length + counter] = IERC1400TokensValidatorExtended(tokenExtension).spendableBalanceOfByPartition(tokens[j], batchTotalPartitions[counter], tokenHolders[i]);
                    } else {
                        batchSpendableBalanceOfByPartitionResponse[i*batchTotalPartitions.length + counter] = IERC1400(tokens[j]).balanceOfByPartition(batchTotalPartitions[counter], tokenHolders[i]);
                    }
                    counter++;
                }
            }
        }

        return (totalPartitionsLengths, batchTotalPartitions, batchSpendableBalanceOfByPartitionResponse);
    }

    /**
     * @dev Get batch of token partitions.
     * @return Batch of token partitions.
     */
    function batchTotalPartitions(address[] memory tokens) public view returns (uint256[] memory, bytes32[] memory, uint256[] memory) {
        uint256[] memory batchTotalPartitionsLength = new uint256[](tokens.length);
        uint256 totalPartitionsLength=0;

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32[] memory totalPartitions = IERC1400Extended(tokens[i]).totalPartitions();
            batchTotalPartitionsLength[i] = totalPartitions.length;
            totalPartitionsLength = totalPartitionsLength.add(totalPartitions.length);
        }

        bytes32[] memory batchTotalPartitionsResponse = new bytes32[](totalPartitionsLength);
        uint256[] memory batchPartitionSupplies = new uint256[](totalPartitionsLength);

        uint256 counter = 0;
        for (uint256 j = 0; j < tokens.length; j++) {
            bytes32[] memory totalPartitions = IERC1400Extended(tokens[j]).totalPartitions();

            for (uint256 k = 0; k < totalPartitions.length; k++) {
                batchTotalPartitionsResponse[counter] = totalPartitions[k];
                batchPartitionSupplies[counter] = IERC1400Extended(tokens[j]).totalSupplyByPartition(totalPartitions[k]);
                counter++;
            }
        }

        return (batchTotalPartitionsLength, batchTotalPartitionsResponse, batchPartitionSupplies);
    }

    /**
     * @dev Get batch of token default partitions.
     * @return Batch of token default partitions.
     */
    function batchDefaultPartitions(address[] memory tokens) public view returns (uint256[] memory, bytes32[] memory) {
        uint256[] memory batchDefaultPartitionsLength = new uint256[](tokens.length);
        uint256 defaultPartitionsLength=0;

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes32[] memory defaultPartitions = IERC1400Extended(tokens[i]).getDefaultPartitions();
            batchDefaultPartitionsLength[i] = defaultPartitions.length;
            defaultPartitionsLength = defaultPartitionsLength.add(defaultPartitions.length);
        }

        bytes32[] memory batchDefaultPartitionsResponse = new bytes32[](defaultPartitionsLength);

        uint256 counter = 0;
        for (uint256 j = 0; j < tokens.length; j++) {
            bytes32[] memory defaultPartitions = IERC1400Extended(tokens[j]).getDefaultPartitions();

            for (uint256 k = 0; k < defaultPartitions.length; k++) {
                batchDefaultPartitionsResponse[counter] = defaultPartitions[k];
                counter++;
            }
        }

        return (batchDefaultPartitionsLength, batchDefaultPartitionsResponse);
    }

    /**
     * @dev Get batch of validation status.
     * @return Batch of validation status.
     */
    function batchValidations(address[] memory tokens, address[] memory tokenHolders) public view returns (bool[] memory, bool[] memory) {
        bool[] memory batchAllowlisted = batchAllowlisted(tokens, tokenHolders);
        bool[] memory batchBlocklisted = batchBlocklisted(tokens, tokenHolders);

        return (batchAllowlisted, batchBlocklisted);
    }

    /**
     * @dev Get batch of allowlisted status.
     * @return Batch of allowlisted status.
     */
    function batchAllowlisted(address[] memory tokens, address[] memory tokenHolders) public view returns (bool[] memory) {
        bool[] memory batchAllowlistedResponse = new bool[](tokenHolders.length * tokens.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                address tokenExtension = interfaceAddr(tokens[j], ERC1400_TOKENS_VALIDATOR);
                if (tokenExtension != address(0)) {
                    batchAllowlistedResponse[i*tokens.length + j] = IERC1400TokensValidatorExtended(tokenExtension).isAllowlisted(tokens[j], tokenHolders[i]);
                } else {
                    batchAllowlistedResponse[i*tokens.length + j] = false;
                }
            }
        }
        return batchAllowlistedResponse;
    }

    /**
     * @dev Get batch of blocklisted status.
     * @return Batch of blocklisted status.
     */
    function batchBlocklisted(address[] memory tokens, address[] memory tokenHolders) public view returns (bool[] memory) {
        bool[] memory batchBlocklistedResponse = new bool[](tokenHolders.length * tokens.length);

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                address tokenExtension = interfaceAddr(tokens[j], ERC1400_TOKENS_VALIDATOR);
                if (tokenExtension != address(0)) {
                    batchBlocklistedResponse[i*tokens.length + j] = IERC1400TokensValidatorExtended(tokenExtension).isBlocklisted(tokens[j], tokenHolders[i]);
                } else {
                    batchBlocklistedResponse[i*tokens.length + j] = false;
                }
            }
        }
        return batchBlocklistedResponse;
    }

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";


/// Base client to interact with the registry.
contract ERC1820Client {
    IERC1820Registry constant ERC1820REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

pragma solidity ^0.8.0;

/// @title IERC1643 Document Management (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1643 {

    // Document Management
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function setDocument(bytes32 _name, string memory _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;
    function getAllDocuments() external view returns (bytes32[] memory);

    // Document Events
    event DocumentRemoved(bytes32 indexed name, string uri, bytes32 documentHash);
    event DocumentUpdated(bytes32 indexed name, string uri, bytes32 documentHash);

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;


contract ERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(bytes32 => bool) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/) // Comments to avoid compilation warnings for unused variables.
    external
    view
    returns(bytes32)
  {
    if(_interfaceHashes[interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  function _setInterface(string memory interfaceLabel) internal {
    _interfaceHashes[keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ****************** Document Management *******************
import "./interface/IERC1643.sol";

/**
 * @title IERC1400 security token standard
 * @dev See https://github.com/SecurityTokenStandard/EIP-Spec/blob/master/eip/eip-1400.md
 */
interface IERC1400 is IERC20, IERC1643 {

  // ******************* Token Information ********************
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256);
  function partitionsOf(address tokenHolder) external view returns (bytes32[] memory);

  // *********************** Transfers ************************
  function transferWithData(address to, uint256 value, bytes calldata data) external;
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data) external;

  // *************** Partition Token Transfers ****************
  function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external returns (bytes32);
  function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external returns (bytes32);
  function allowanceByPartition(bytes32 partition, address owner, address spender) external view returns (uint256);

  // ****************** Controller Operation ******************
  function isControllable() external view returns (bool);
  // function controllerTransfer(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorTransferByPartition"
  // function controllerRedeem(address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorRedeemByPartition"

  // ****************** Operator Management *******************
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function authorizeOperatorByPartition(bytes32 partition, address operator) external;
  function revokeOperatorByPartition(bytes32 partition, address operator) external;

  // ****************** Operator Information ******************
  function isOperator(address operator, address tokenHolder) external view returns (bool);
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool);

  // ********************* Token Issuance *********************
  function isIssuable() external view returns (bool);
  function issue(address tokenHolder, uint256 value, bytes calldata data) external;
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external;

  // ******************** Token Redemption ********************
  function redeem(uint256 value, bytes calldata data) external;
  function redeemFrom(address tokenHolder, uint256 value, bytes calldata data) external;
  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external;
  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata operatorData) external;

  // ******************* Transfer Validity ********************
  // We use different transfer validity functions because those described in the interface don't allow to verify the certificate's validity.
  // Indeed, verifying the ecrtificate's validity requires to keeps the function's arguments in the exact same order as the transfer function.
  //
  // function canTransfer(address to, uint256 value, bytes calldata data) external view returns (byte, bytes32);
  // function canTransferFrom(address from, address to, uint256 value, bytes calldata data) external view returns (byte, bytes32);
  // function canTransferByPartition(address from, address to, bytes32 partition, uint256 value, bytes calldata data) external view returns (byte, bytes32, bytes32);    

  // ******************* Controller Events ********************
  // We don't use this event as we don't use "controllerTransfer"
  //   event ControllerTransfer(
  //       address controller,
  //       address indexed from,
  //       address indexed to,
  //       uint256 value,
  //       bytes data,
  //       bytes operatorData
  //   );
  //
  // We don't use this event as we don't use "controllerRedeem"
  //   event ControllerRedemption(
  //       address controller,
  //       address indexed tokenHolder,
  //       uint256 value,
  //       bytes data,
  //       bytes operatorData
  //   );

  // ******************** Transfer Events *********************
  event TransferByPartition(
      bytes32 indexed fromPartition,
      address operator,
      address indexed from,
      address indexed to,
      uint256 value,
      bytes data,
      bytes operatorData
  );

  event ChangedPartition(
      bytes32 indexed fromPartition,
      bytes32 indexed toPartition,
      uint256 value
  );

  // ******************** Operator Events *********************
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
  event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
  event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

  // ************** Issuance / Redemption Events **************
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data);
  event IssuedByPartition(bytes32 indexed partition, address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes operatorData);

}

/**
 * Reason codes - ERC-1066
 *
 * To improve the token holder experience, canTransfer MUST return a reason byte code
 * on success or failure based on the ERC-1066 application-specific status codes specified below.
 * An implementation can also return arbitrary data as a bytes32 to provide additional
 * information not captured by the reason code.
 * 
 * Code	Reason
 * 0x50	transfer failure
 * 0x51	transfer success
 * 0x52	insufficient balance
 * 0x53	insufficient allowance
 * 0x54	transfers halted (contract paused)
 * 0x55	funds locked (lockup period)
 * 0x56	invalid sender
 * 0x57	invalid receiver
 * 0x58	invalid operator (transfer agent)
 * 0x59	
 * 0x5a	
 * 0x5b	
 * 0x5a	
 * 0x5b	
 * 0x5c	
 * 0x5d	
 * 0x5e	
 * 0x5f	token meta or info
 *
 * These codes are being discussed at: https://ethereum-magicians.org/t/erc-1066-ethereum-status-codes-esc/283/24
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}