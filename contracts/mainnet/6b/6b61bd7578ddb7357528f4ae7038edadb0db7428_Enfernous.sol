// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IERC165.sol";

/// @title ERC-1155 Multi Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 is IERC165 {
    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_id` argument MUST be the token type being transferred.
    /// - The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_ids` argument MUST be the list of tokens being transferred.
    /// - The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    /// @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @dev MUST emit when the URI is updated for a token ID. URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    event URI(string _value, uint256 indexed _id);

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// - MUST revert on any other error.
    /// - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// - After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if length of `_ids` is not the same as length of `_values`.
    /// - MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// - MUST revert on any other error.
    /// - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _ids IDs of each token type (order and length must match _values array)
    /// @param _values Transfer amounts per token type (order and length must match _ids array)
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /// @notice Get the balance of an account's tokens.
    /// @param _owner The address of the token holder
    /// @param _id ID of the token
    /// @return The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _ids ID of the tokens
    /// @return The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner The owner of the tokens
    /// @param _operator Address of authorized operator
    /// @return True if the operator is approved, false if not
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct NCAParams {
    string seed;
    string bg;
    string fg1;
    string fg2;
    string matrix;
    string activation;
    string rand;
    string mods;
}

interface INeuralAutomataEngine {
    function baseScript() external view returns(string memory);

    function parameters(NCAParams memory _params) external pure returns(string memory);

    function p5() external view returns(string memory);

    function script(NCAParams memory _params) external view returns(string memory);

    function page(NCAParams memory _params) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NCAParams} from "./INeuralAutomataEngine.sol";

interface IZooOfNeuralAutomata {

    function updateEngine(address _engine) external;

    function updateContractURI(string memory _contractURI) external;

    function updateParams(uint256 _id, NCAParams memory _params) external;

    function updateMinter(uint256 _id, address _minter) external;

    function updateBurner(uint256 _id, address _burner) external;

    function updateBaseURI(uint256 _id, string memory _baseURI) external;

    function freeze(uint256 _id) external;

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;
    
}

//SPDX-License-Identifier: MIT
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////////////((((@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////(@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@(//@@@@@@@//////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@(////@@@@@///////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@(/////&@@@&/////////////////  /////////@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@%////////@@////////////////    //////////@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@//////////@%//////////////      /////////@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@#////////////////////////       ,/////////@@@@@@@@////@@@@@@@@@@@@@@
//@@@@@@@@@@@@////////////////////////        .///////////@@@@///////@@@@@@@@@@@@@
//@@@@@@@@@@@////////////////////////          ///////////////////////@@@@@@@@@@@@
//@@@@@@@@@@@////////////////////***            **/////////////////////@@@@@@@@@@@
//@@@@@@@@@@@/////////////////*****.             ****///////////////////@@@@@@@@@@
//@@@@@@@@@@@///////////////*******                ****/////////////////@@@@@@@@@@
//@@@@@@@@@@@/////////////**********                 ***////////////////@@@@@@@@@@
//@@@@@@@@@@@@///////////****.  ****,                  ***//////////////@@@@@@@@@@
//@@@@@@@@@@@@@/////////****,     ***                   ,**////////////@@@@@@@@@@@
//@@@@@@@@@@@@@@///////*****                             ***//////////@@@@@@@@@@@@
//@@@@@@@@@@@@@@@/////******                              ***////////@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%//*******                             .***///////@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@********..                         .*****////@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@*******,.....               .....******/(@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@******,,,,,.............,,,,******@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@******,,,,,,,,,,,,,******@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";
import {IERC1155} from "../../lib/forge-std/src/interfaces/IERC1155.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

contract Enfernous{

    address immutable zona;
    uint256 immutable startTime;

    address owner;
    uint256 public burned = 0;

    constructor(address _owner, address _zona, uint256 _startTime) {
        owner = _owner;
        zona = _zona;
        startTime = _startTime;
    }

    function mint(uint256 amount) external {
        require(startTime <= block.timestamp || msg.sender == owner);
        require(IERC1155(zona).balanceOf(msg.sender, 1) >= amount);
        require(burned + amount <= 512);

        burned += amount;

        IZooOfNeuralAutomata(zona).burn(msg.sender, 1, amount);
        IZooOfNeuralAutomata(zona).mint(msg.sender, 666, amount);
    }

}