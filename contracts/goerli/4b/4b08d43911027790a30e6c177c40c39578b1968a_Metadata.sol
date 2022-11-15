// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface of ERC-1155 token contract for raes
interface IFERC1155 {
    /// @dev Emitted when caller is not required address
    error InvalidSender(address _required, address _provided);
    /// @dev Emitted when owner signature is invalid
    error InvalidSignature(address _signer, address _owner);
    /// @dev Emitted when deadline for signature has passed
    error SignatureExpired(uint256 _timestamp, uint256 _deadline);
    /// @dev Emitted when royalty is set to value greater than 100%
    error InvalidRoyalty(uint256 _percentage);
    /// @dev Emitted when new controller is zero address
    error ZeroAddress();

    /// @dev Event log for updating the Controller of the token contract
    /// @param _newController Address of the controller
    event ControllerTransferred(address indexed _newController);
    /// @dev Event log for updating the metadata contract for a token type
    /// @param _metadata Address of the metadata contract that URI data is stored on
    /// @param _id ID of the token type
    event SetMetadata(address indexed _metadata, uint256 _id);
    /// @dev Event log for updating the royalty of a token type
    /// @param _receiver Address of the receiver of secondary sale royalties
    /// @param _id ID of the token type
    /// @param _percentage Royalty percent on secondary sales
    event SetRoyalty(
        address indexed _receiver,
        uint256 indexed _id,
        uint256 _percentage
    );
    /// @dev Event log for approving a spender of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    event SingleApproval(
        address indexed _owner,
        address indexed _operator,
        uint256 indexed _id,
        bool _approved
    );
    /// @notice Event log for Minting Raes of ID to account _to
    /// @param _to Address to mint rae tokens to
    /// @param _id Token ID to mint
    /// @param _amount Number of tokens to mint
    event MintRaes(address indexed _to, uint256 indexed _id, uint256 _amount);

    /// @notice Event log for Burning raes of ID from account _from
    /// @param _from Address to burn rae tokens from
    /// @param _id Token ID to burn
    /// @param _amount Number of tokens to burn
    event BurnRaes(address indexed _from, uint256 indexed _id, uint256 _amount);

    function INITIAL_CONTROLLER() external pure returns (address);

    function VAULT_REGISTRY() external pure returns (address);

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;

    function contractURI() external view returns (string memory);

    function controller() external view returns (address controllerAddress);

    function emitSetURI(uint256 _id, string memory _uri) external;

    function isApproved(
        address,
        address,
        uint256
    ) external view returns (bool);

    function metadata(uint256) external view returns (address);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external;

    function setContractURI(string memory _uri) external;

    function setMetadata(address _metadata, uint256 _id) external;

    function setRoyalties(
        uint256 _id,
        address _receiver,
        uint256 _percentage
    ) external;

    function totalSupply(uint256) external view returns (uint256);

    function transferController(address _newController) external;

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IFERC1155} from "../interfaces/IFERC1155.sol";

/// @title Metadata
/// @author Fractional Art
/// @notice Utility contract for storing metadata of an FERC1155 token
contract Metadata {
    /// @notice Address of FERC1155 token contract
    address immutable token;
    /// @dev Mapping of ID type to URI of metadata
    mapping(uint256 => string) private tokenMetadata;

    /// @notice Initializes token contract
    constructor(address _token) {
        token = _token;
    }

    /// @notice Sets the metadata of a given token ID type
    /// @dev Can only be set by the token controller
    /// @param _uri URI of the token metadata
    /// @param _id ID of the token type
    function setURI(uint256 _id, string memory _uri) external {
        address controller = IFERC1155(token).controller();
        if (msg.sender != controller)
            revert IFERC1155.InvalidSender(controller, msg.sender);

        tokenMetadata[_id] = _uri;
        IFERC1155(token).emitSetURI(_id, _uri);
    }

    /// @notice Gets the metadata of a token ID type
    /// @param _id ID of the token type
    /// @return URI of the token metadata
    function uri(uint256 _id) public view returns (string memory) {
        return tokenMetadata[_id];
    }
}